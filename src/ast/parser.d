module LdParser;

import std.stdio;
import std.conv;
import std.algorithm;
import std.string;
import std.file;

import std.path: buildPath;

import std.format: format;
import core.stdc.stdlib;

import LdLexer: _Lex;
import LdNode;


class _Parse{
	int pos;
	bool end;

	TOKEN tok;
	Node[] ast;
	
	string file;
	TOKEN[] toks;
	
	Node[] defaults;

	this(TOKEN[] toks, string file){
		this.end = true;
		this.toks = toks;
		this.file = file;

		this.ast = ast;

		this.pos = -1;
		this.defaults = defaults;
		this.tok = tok;
		this.next();
		this.parse();
	}

	void next(){
		this.pos += 1;

		if (this.pos < this.toks.length)
			this.tok = this.toks[this.pos];
		else
			this.end = false;
	}

	void prev(){
		this.pos -= 1;
		this.tok = this.toks[this.pos];
	}

	void SyntaxError(string err, string errtype="syntax", int lineno=0){
		if (!lineno)
			lineno = this.tok.line;

		writeln(format("  Trace (\"%s\", %d)", this.file, lineno));

		if (exists(this.file)){
			File file = File(this.file, "r");
			
			if (!lineno)
				for(int i = 0; i < this.tok.line-1; i++)
					file.readln();
			else
				for(int i = 0; i < lineno-1; i++)
					file.readln();

			writeln("    ", strip(file.readln));
			
			for(int i = 0; i < this.tok.loc; i++)
				write(' ');

			writeln("   ^");
			file.close();
		}

		writeln("SyntaxError: ", err);

		if (this.file == "__stdin__")
			throw new Exception("syntax error occured");

		exit(0);
	}

	Node listdata(){
		this.next();
		Node[] list;

		while (this.end && this.tok.type != "]") {
			if (find("NL,", this.tok.type).length) {
				this.next();
			} else {
				list ~= this.eval("NL,]");
			}
		}

		return new ListNode(list);
	}

	Node tupledata(){
		this.next();
		Node[] list;
		string last = "NL";

		while (this.end && this.tok.type != ")") {
			if (find("NL,", this.tok.type).length) {
				last = this.tok.type;
				this.next();
			} else {
				list ~= this.eval("NL,)");
			}
		}

		if (list.length == 1 && last != ","){
			return list[0];
		}

		return new ListNode(list);
	}

	void skip_whitespace(){
		while(this.end && find("NL", this.tok.type).length){
			this.next();
		}
	}

	Node objectdata(){
		this.next();
		string[] keys;
		Node[] values;

		while (this.end && this.tok.type != "}") {
			if (find("NL,", this.tok.type).length)
				this.next();

			else {
				if (!find("IDSTRNUM", this.tok.type).length){
					this.SyntaxError("Invalid key '"~this.tok.value~ "' for dict value");
				}

				keys ~= this.tok.value;
				this.next();

				if (this.tok.type != ":"){
					this.SyntaxError("Expected ':' not '"~this.tok.value~"' to assign dict value.");
				}

				this.next();
				this.skip_whitespace();
				values ~= this.eval("NL,}");
			}
		}

		return new DictNode(keys, values);
	}

	Node enumdata(){
		this.next();
		this.skip_whitespace();

		if(this.tok.type != "{" || !(this.end))
			this.SyntaxError(format("Invalid syntax '%s' expected '{' after enum declaration.", tok.type));

		this.next();

		string[] keys;
		Node[] values;

		while (this.end && this.tok.type != "}") {
			if (find("NL,", this.tok.type).length)
				this.next();

			else if (this.tok.type == "ID") {
				keys ~= this.tok.value;
				this.next();

				skip_whitespace();

				if (this.tok.type == "=") {
					this.next();
					this.skip_whitespace();
					values ~= this.eval("NL,}");

				} else if (canFind(",}", tok.type))
					values ~= new NullNode();

				else
					this.SyntaxError(format("Unexcepted syntax '%s' when setting enum data", tok.value));

			} else
				this.SyntaxError(format("Invalid key '%s' for enum value", this.tok.value));
		}

		return new EnumNode(keys, values);
	}

	Node extractdata_functional(Node ret){
		next();
		string value = tok.value;
		next();

		Node[] args = [ret];

		if (tok.type == "(")
			args ~= getArgs();

		return new GetFnNode(value, args);
	}

	Node extractdata(Node ret){
		this.next();
		string value = this.tok.value;
		auto _line = this.tok.line;

		this.next();

		if (this.tok.type == "="){
			this.next();
			return new GetNode(ret, value, 1, this.eval("NL;"), _line);

		} else {
			return new GetNode(ret, value, 0, null, _line);
		}
	}

	Node Index(Node ret){
		this.next();
		short index_kind = 0;
		Node[2] value;

		int line = this.tok.line;

		if (tok.type == ".."){
			this.next();
			index_kind = 2;

			value[0] = this.eval("]");
		} else {
			value[0] = this.eval("..]");

			if (tok.type == ".."){
				this.next();

				if (this.tok.type == "]")
					index_kind = 3;
				else{
					value[1] = this.eval("]");
					index_kind = 1;
				}
			}
		}

		this.next();

		// incase of assigning data
		if (canFind("AA=", tok.type)) {
			// error getting multiple indexes, only occurs at like '[...][1] = ..'
			if (index_kind)
				SyntaxError(format("invalid operation '%s' at multi indexing.", tok.value));

			string change_sign = tok.value;
			this.next();

			value[1] = eval("NL;");
			return new IndexNode(ret, value, index_kind, change_sign, 1, line);
		}

		return new IndexNode(ret, value, index_kind, "", 0, line);
	}

	Node formatdata(){
		string[] strs;
		Node[] forms;

		string st;
		string chars = this.tok.value;
		ulong len = this.tok.value.length;
		int i, count;

		while (i < len){
			if (chars[i] != '{'){
				st ~= chars[i];
				i += 1;
			} else {
				if (st.length){
					forms ~= new StrOp(st);
					st = "";
				}
				i += 1;
				count = 1;

				while (i < len){
					if (chars[i] == '{')
						count += 1;
					else if (chars[i] == '}'){
						count -= 1;
						if (!count)
							break;
					}
					st ~= chars[i];
					i += 1;
				}

				i += 1;
				if (st.length){
					forms ~= new _Parse(new _Lex("ODYESSY = " ~ st ~ ';').TOKENS, "format.io").ast[0].expr;
					st = "";
				}
			}
		}

		if (st.length)
			forms ~= new StrOp(st);

		return new FormatNode(forms);
	}

	Node if_assignNode(string end){
		this.next();
		Node[3] expr;

		expr[0] = this.eval("ARR");
		this.next();

		expr[1] = this.eval(":");
		this.next();

		expr[2] = this.eval(end);
		this.prev();
		return new IfAssignNode(expr);
	}

	TOKEN[] getCode(){
		TOKEN[] code;

		if (tok.type != "DO")
			this.SyntaxError("Missing 'do' to demacate code block.");

		int indent = this.tok.tab;
		this.next();
		skip_whitespace();

		while (this.end && (tok.tab > indent || tok.type == "NL")) {
			code ~= this.tok;
			this.next();
		}

		if(code.length) {
			TOKEN N = {"", "NL", tok.tab, tok.line, tok.loc};
			code ~= N;
		}

		if (!(code.length))
			this.SyntaxError("Poor indenting, expected indented code for the block.");

		return code;
	}

	TOKEN[] getParenCode(){
		TOKEN[] code;

		if (tok.type != "DO")
			this.SyntaxError("Missing 'do' to demacate code block.");

		this.next();
		skip_whitespace();

		if (tok.type == "{"){
			short incre = 1;
			this.next();

			while (this.end){
				if (tok.type == "{")
					incre += 1;
				else if (tok.type == "}")
					incre -= 1;

				if (incre == 0)
					break;

				code ~= this.tok;
				this.next();
			}
		} else
			this.SyntaxError("Expected { to demacate code block.");

		if(code.length) {
			TOKEN N = {"", "NL", tok.tab, tok.line, tok.loc};
			code ~= N;
		}
		return code;
	}

	Node unknownFnNode(){
		this.next();
		return new FunctionNode(["", format("%s:%d", this.file, tok.line)] ~ this.getParams(), this.defaults, new _Parse(this.getParenCode(), this.file).ast);
	}

	Node negative_data(){
		string op = tok.type;
		this.next();

		Node ret;

		if (tok.type == "ID")
			ret = new IdNode([tok.value, this.file], tok.line, tok.loc);

		else if (tok.type == "NUM") {
			double number = to!double(tok.value);
			ret = new NumOp(number);

		} else{
			SyntaxError("invalid token '" ~ tok.type ~"' after -/+ sign");
		}

		return new BinaryNode(new NumOp(0), op, ret);
	}

	Node factor(string end){
		Node ret;
		if (tok.type == "ID")
			ret = new IdNode([tok.value, this.file], tok.line, tok.loc);

		else if (tok.type == "STR")
			ret = new StrOp(tok.value);
			
		else if (tok.type == "NUM"){
			double number = to!double(tok.value);
			ret = new NumOp(number);

		} else if (tok.type == "TRUE")
			ret = new TrueNode();
			
		else if (tok.type == "FALSE")
			ret = new FalseNode();
			
		else if (tok.type == "NONE")
			ret = new NullNode();
			
		else if (tok.type == "[")
			ret = listdata();

		else if (tok.type == "{")
			ret = objectdata();

		else if (tok.type == "ENUM")
			ret = enumdata();

		else if (tok.type == "(")
			ret = tupledata();

		else if (tok.type == "FMT")
			ret = formatdata();
		
		else if (tok.type == "IF")
			ret = if_assignNode(end);

		else if (canFind("-+", tok.type))
			ret = negative_data();

		else if(tok.type == "MO"){
			this.next();
			ret = new ArgsNode(tok.line, this.file, eval(end));
			prev();
		}

		else if (tok.type == "LFN") {
			ret = unknownFnNode();

		} else {
			prev();
			SyntaxError("invalid token '" ~ tok.value ~"' in expression");
		}

		this.next();

		while (this.end && canFind(".([AA", tok.type)){
			if (tok.type == "(")
				ret = new CallNode(ret, getArgs(), tok.line, tok.loc);
			
			else if (tok.type == ".")
				ret = extractdata(ret);

			else if (tok.type == "..")
				ret = extractdata_functional(ret);

			else if (tok.type == "AA"){ 
				string op = tok.value;
				next();

				Node expr = eval("NL;");
				ret = new BinaryNode(ret, op, expr);

			} else
				ret = Index(ret);
		}
		
		return ret;
	}
	
	Node term(string end){
		Node val = this.factor(end);

		while (this.end && canFind("*/%", this.tok.type)){
			string op = this.tok.type;
			this.next();

			Node right = this.factor(end);
			val = new BinaryNode(val, op, right, this.tok.line); 
		}

		return val;
	}

	Node expr(string end){
		Node val = this.term(end);

		while (this.end && canFind("+-", this.tok.type)){
			string op = this.tok.type;
			this.next();

			Node right = this.term(end);
			val = new BinaryNode(val, op, right); 
		}

		return val;
	}

	Node eqexpr(string end){
		Node val = this.expr(end);

		while (this.end && find("==<=>=!=IN^&|<<>>", this.tok.type).length){
			string op = this.tok.type;
			this.next();

			Node right = this.expr(end);
			val = new BinaryNode(val, op, right); 
		}

		return val;
	}

	Node notexpr(string end){
		if (this.tok.type == "NOT"){
			string op = this.tok.type;
			this.next();
			return new BinaryNode(new StrOp(""), op, this.eqexpr(end)); 
		}

		return this.eqexpr(end);
	}

	Node eval(string end){
		Node val = this.notexpr(end);

		while (this.end && !find(end, this.tok.type).length && find("ANDOR", this.tok.type).length){
			string op = this.tok.type;
			this.next();

			Node right = this.notexpr(end);
			val = new BinaryNode(val, op, right);
		}

		if (!find(end, this.tok.type).length){
			this.SyntaxError("Unexpected syntax '" ~ this.tok.value ~ "' in expression.");
		}

		return val;
	}

	Node[] getArgs(){
		Node[] args;
		next();

		while (this.end && this.tok.type != ")"){
			if (find("NL,;", this.tok.type).length)
				this.next();
			else
				args ~= eval("NL,)");
		}

		next();
		return args;
	}

	string[] getParams(){
		string[] params;
		bool assigned = false;
		this.defaults = [];

		if (this.tok.type == "("){
			this.next();

			while (this.end && this.tok.type != ")"){
				if (this.tok.type == "ID"){
					params ~= this.tok.value;
					this.next();

					if (this.tok.type == "=" || this.tok.type == ":"){
						assigned = true;
						this.next();
						this.defaults ~= this.eval("NL,)");

					} else if (assigned) {
						this.prev();
						this.SyntaxError("Non-default parameter can't come after a default parameter.");
					}

				} else if (!find("NL,", this.tok.type).length){
					this.SyntaxError("Unexpected syntax '" ~ this.tok.value ~ "' while parsing function params.");

				} else {
					this.next();
				}
			}
			this.next();
		}

		return params;
	}

	void multiVarAssigns(){
		string[] vars = [];

		while(this.end && !canFind("=", tok.type)){
			if (tok.type == "ID")
				vars ~= tok.value;

			else if (!canFind(",NL", tok.type))
				this.SyntaxError("Unexpected syntax '" ~ this.tok.value ~ "' in multi variable assign.");

			this.next();
		}

		if(this.tok.type != "=")
			this.SyntaxError("Unexpected syntax '" ~ this.tok.value ~ "' expects '=' to assign multi variables.");

		this.next();
		this.ast ~= new MultiVarNode(vars, this.eval(";NL"));
	}

	void parse_identifier() {
		TOKEN id = tok;
		next();

		if (tok.type == "="){
			this.next();
			this.ast ~= new VarNode(id.value, this.eval("NL;"));

		} else if (canFind(".([ANDORNOT==<=>=!=IN+-*/%", tok.type)) {
			this.prev();
			this.ast ~= eval("NL;");
			this.next();

		} else if (canFind("NL;", tok.type)){
			this.ast ~= new IdNode([id.value, this.file], id.line, id.loc);

		} else if (canFind("AA", tok.type)){
			this.prev();
			Node Val = new IdNode([tok.value, this.file], tok.line, tok.loc);
			next();

			string op = tok.value;
			next();

			Node expr = eval("NL;");
			this.ast ~= new VarNode(id.value, new BinaryNode(Val, op, expr));

		} else if (canFind(",", tok.type)) {
			this.prev();
			this.multiVarAssigns();

		} else {
			this.SyntaxError("Unexpected syntax '" ~ this.tok.value ~ "' after ID token.");
		}
	}

	void parse_function(){
		this.next();
		string name = tok.value;

		this.next();
		this.ast ~= new FunctionNode([name, format("%s:%d", this.file, tok.line)] ~ this.getParams(), this.defaults, new _Parse(this.getCode(), this.file).ast);
	}

	void parse_class(){
		this.next();

		if (this.tok.type != "ID")
			this.SyntaxError(format("Expected a 'word' for a class_name not '%s'.", this.tok.value));

		string name = this.tok.value;
		this.next();

		Node[] inherits;

		if (this.tok.type == "("){
			inherits = this.getArgs();
		}

		this.ast ~= new ClassNode(
				name, this.file, inherits, new _Parse(this.getCode(), this.file).ast);
	}

	void parse_return(){
		this.next();

		if (this.end && !find("NL;", this.tok.type).length)
			this.ast ~= new ReturnNode(this.eval("NL;"));
		else
			this.ast ~= new ReturnNode(new NullNode());

		this.next();
	}

	void parse_delvar(){
		this.next();
		string[] vars;

		while (end && !canFind("NL;", this.tok.type)) {
			if (this.tok.type == "ID")
				vars ~= this.tok.value;
			else if (tok.type == ","){}
			else
				SyntaxError(format("Unexpected syntax, expected 'variable name' not token '%s'", tok.type));

			next();
		}

		next();
		this.ast ~= new DelNode(vars);
	}

	void parse_if(){
		bool repeat = false;
		Node expr;
		Node[] statements;

		while (this.end){
			if (canFind("ELIFELSE", this.tok.type)){
				if (this.tok.type == "ELSE"){
					expr = new NumOp(1);
					this.next();

				} else {
					if (this.tok.type == "IF" && repeat){
						break;
					}
					this.next();
					expr = this.eval("DO");
				}

				statements ~= new IfNode(expr,
					new _Parse(this.getCode(), this.file).ast);
				repeat = true;

			} else if (this.tok.type == "NL"){
				this.next();

			} else {
				break;
			}
		}

		this.ast ~= new IfStatementNode(statements);
	}

	void parse_while(){
		this.next();
		this.ast ~= new WhileNode(this.eval("DO"), new _Parse(this.getCode(), this.file).ast);
	}

	void parse_for(){
		this.next();

		if(tok.type == "(") {
			this.next();

			if(tok.type != "ID")
				SyntaxError("Expected an ID after 'for' not '"~tok.value~"'.");

			string id = tok.value;
			next();

			Node defo;

			if(tok.type == ";")
				defo = new NumOp(0);
			
			else if (tok.type == "=") {
				this.next();
				defo = eval(";");
			}
			this.next();
			
			// condition
			Node condi = this.eval(";");
			next();

			if(tok.value != id)
				SyntaxError("Expected var "~id~"' that was used to start the for-loop.");
			next();

			if (this.tok.type != "BB")
				SyntaxError("Expected '--' or '++' to guide on how to increment loop.");

			string incre = tok.value;
			next();

			if (this.tok.type == ")")
				next();

			this.ast ~= new ForNode(id, defo, condi, incre, new _Parse(this.getCode(), this.file).ast);
			return;
		}

		if (tok.type != "ID")
			SyntaxError("Expected an ID after 'for' not '"~tok.value~"'.");

		string var = this.tok.value;
		this.next();

		if (this.tok.type != "IN")
			SyntaxError(format("Expected 'in' after 'for loop' variable not '%s'", tok.value));
		this.next();

		this.ast ~= new ForEachNode(var, this.eval("DO"), new _Parse(this.getCode(), this.file).ast);
	}

	void parse_enum(){
		this.ast ~= this.eval("NL;");
	}

	void parse_switch(){
		this.next();
		bool bk = false;
		bool brk = false;
		Node key = this.eval("NL:{ARR");
		Node[] cs;
		Node[] case_toks;
		Node value;
		TOKEN[] toks;

		if (this.tok.type == "ARR"){
			this.next();

			if (this.tok.type == "BREAK"){
				bk = true;
				this.next();

			} else
				this.SyntaxError("Expected only the 'break' token.");
		}

		if (find("DO", this.tok.type).length){
			this.next();
		}

		while (this.end){
			if (find("CASE DF", this.tok.type).length){
				if (this.tok.type == "CASE"){
					this.next();
					value = this.eval("DO");

				} else {
					this.next();
					value = key;
				}


				toks = this.getCode();
				case_toks = new _Parse(toks, this.file).ast;

				if (bk){
					cs ~= new CsNode(value, case_toks, true);
				} else {
					foreach(TOKEN i; toks.reverse){
						if (i.type != "NL"){
							if (i.type == "BREAK"){
								brk = true;
							}
							break;
						}
					}
					cs ~= new CsNode(value, case_toks, brk);
					brk = false;					
				}

			} else if(this.tok.type != "NL"){
				break;

			} else {
				this.next();
			}
		}

		this.ast ~= new SwNode(key, cs);
	}

	void parse_include(){
		this.next();
		this.ast ~= new IncludeNode(this.eval("NL;"), this.tok.line, this.tok.loc);
		this.next();
	}

	void parse_import(){
		int ln = tok.line;
		next();

		string look;
		string[] name, save;
		string[string] mods;

		while(end && !(find("NL;", tok.type).length)) {

			if(tok.type == "ID")
				name ~= tok.value;

			else if (tok.type == "AS") {
				next();
				if (name.length) {
					if (tok.type != "ID")
						this.SyntaxError(format("Expected an 'ID' after 'as' not '%s' the 'break' token.", tok.value));
					
					mods[tok.value] ~= buildPath(name);
					save ~= tok.value;

					name.length = 0;
				} else
					this.SyntaxError("Cannot as empty path to module.");

			} else if (tok.type == ",") {
				if (name.length) {
					
					mods[name[name.length - 1]] = buildPath(name);
					save ~= name[name.length - 1];

					name.length = 0;
				}
			} else if(tok.type != ".")
				this.SyntaxError(format("Unknown syntax '%s' in import statement.", tok.type));

			next();
		}
		if (name.length) {
			mods[name[name.length - 1]] = buildPath(name);
			save ~= name[name.length - 1];
		}
		
		next();
		ast ~= new ImportNode(mods, save, ln);
	}

	void parse_from(){
		int ln = tok.line;
		this.next();

		string fpath;

		if(tok.type == ".") {
			fpath = ".";
			next();
		}

		while (end && tok.type != "IM")
		{
			if(tok.type == "ID")
				fpath = buildPath(fpath, tok.value);
			else if(tok.type != ".")
				SyntaxError("Unexpected syntax in from-import statement.");
			next();
		}
		if (tok.type != "IM")
			SyntaxError(format("Expected an 'import' after from not '%s'.", tok.value));
		this.next();

		string[string] attrs;
		string[] order;
		string at;

		while(end && !canFind("NL;", tok.type))
		{
			if (canFind("ID*", tok.type)) {
				at = tok.value;
				next();

				if(tok.type != "AS") {
					attrs[at] = at;
					order ~= at;
					continue;
				}
				next();

				if(tok.type != "ID")
					SyntaxError(format("Unexpected '%s' after 'as', must be a name.", tok.value));

				attrs[at] = tok.value;
				order ~= at;
				next();
			
			} else if (tok.type != ",")
				SyntaxError(format("Unexpected '%s' after 'import', must be a name separated by ',' .", tok.value));
			else
				next();
		}

		ast ~= new FromNode(fpath, attrs, order, ln);
	}

	void parse_try(){
		this.next();
		Node[] nodz;

		nodz ~= new ListNode(new _Parse(this.getCode(), this.file).ast);

		if (this.tok.type == "CATCH"){
			this.next();

			if (this.tok.type != "ID")
				this.SyntaxError(format("Expected an identifier after 'except' not '%s'.", tok.value));

			string id = this.tok.value;

			this.next();
			nodz ~= new CatchNode(id, new _Parse(this.getCode(), this.file).ast);
		}

		this.ast ~= new TryNode(nodz);
	}

	void parse_throw(){
		this.next();
		
		this.ast ~= new ThrowNode(tok.line, this.file, this.eval("NL;"));
	}

	void parse(){
		while (this.end){
			if (this.tok.type == "ID"){
				this.parse_identifier();

			} else if (this.tok.type == "RET") {
				this.parse_return();

			} else if (this.tok.type == "IF") {
				this.parse_if();

			} else if (this.tok.type == "SWITCH"){
				this.parse_switch();

			} else if (this.tok.type == "WHILE") {
				this.parse_while();

			} else if (this.tok.type == "ENUM") {
				this.parse_enum();

			} else if(this.tok.type == "FOR"){
				this.parse_for();

			} else if (this.tok.type == "BREAK") {
				this.ast ~= new BreakNode();
				this.next();

			} else if (this.tok.type == "CONT") {
				this.ast ~= new ContinueNode();
				this.next();

			} else if (this.tok.type == "DEL") {
				this.parse_delvar();

			} else if (this.tok.type == "FN") {
				this.parse_function();

			} else if (this.tok.type == "CL"){
				this.parse_class();

			} else if (this.tok.type == "IM") {
				this.parse_import();

			} else if (this.tok.type == "FR") {
				this.parse_from();

			} else if (this.tok.type == "INC") {
				this.parse_include();

			} else if (this.tok.type == "TRY") {
				this.parse_try();

			} else if (this.tok.type == "THROW") {
				this.parse_throw();

			} else if ((this.tok.type == "NL") | (this.tok.type == ";")){
				this.next();

			} else if (this.tok.type == "PS") {
				this.next();

			} else {
				this.ast ~= this.eval("NL;");
				this.next();
			}
		}
	}
}

