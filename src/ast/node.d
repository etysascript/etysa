module LdNode;


struct TOKEN{
	string value, type;
	int tab, line, loc;
}

struct TRACE{
	string file;
	int line;
	string type = "SystemError";
}


// 1 	number
// 2 	string
// 3 	list
// 4 	dict
// 5 	bin-op
// 7 	fn-call
// 8 	.getattr
// 9 	index
// 10   function
// 11   class
// 12	return
// 13	if
// 14	if-statement
// 16	while
// 18	for
// 21	break
// 26	id
// 27	format
// 28	assign
// 30	include
// 31	true
// 32	false
// 33	none
// 35	continue
// 36	from
// 37	.getattr_functional
// 38   enum
// 39   throw
// 40   delete variable
// 41	multi assign
// 42	fncall multi args

class Node{
	string str(){ return "undef"; }

	double f64(){ return 0.1; }

	int exe(){ return 0; }

	int line(){ return 0; }

	int index(){ return 0; }

	Node[] leftRight(){ return []; }

	Node expr(){ return new Node; }

	int type(){ return 0; }

	Node expr2(){ return new Node; }

	Node[] params(){ return [new Node]; }

	string[] args(){ return []; }

	string[string] strs(){ return strs; }
}

class BinaryNode: Node{
	Node left;
	string op;
	Node right;
	int pos, loc;

	this(Node left, string op, Node right, int pos = 0, int loc = 0){
		this.left = left;
		this.op = op;
		this.right = right;
		this.pos = pos;
		this.loc = loc;
	}

	override Node[] leftRight(){
		return [this.left, this.right];
	}

	override string str(){
		return this.op;
	}

	override int line(){
		return this.pos;
	}

	override int index(){
		return this.loc;
	}

	override int type(){
		return 5;
	}
}


class CallNode: Node{
	int ln, loc;
	Node ast;
	Node[] args;

	this(Node ast, Node[] args, int ln = 0, int loc = 0){
		this.ast = ast;
		this.args = args;
		this.ln = ln;
		this.loc = loc;
	}

	override Node expr(){ return this.ast; }

	override Node[] params(){ return this.args;	}

	override int type(){ return 7; }

	override int line(){ return this.ln; }

	override int index(){ return this.loc; }
}


class IfAssignNode: Node{
	Node[3] forms;

	this(Node[3] forms){
		this.forms = forms;
	}

	override Node[] params(){
		return this.forms;
	}

	override int type(){
		return 28;
	}
}

class GetNode: Node{
	int assign, _line;
	Node ast;
	string key;
	Node value;

	this(Node ast, string key, int assign, Node value, int _line){
		this.ast = ast;
		this.key = key;
		this.assign = assign;
		this.value = value;
		this._line = _line;
	}

	override int exe(){
		return this.assign;
	}

	override Node expr(){
		return this.ast;
	}

	override Node expr2(){
		return this.value;
	}

	override string str(){
		return this.key;
	}

	override int line(){
		return this._line;
	}

	override int type(){
		return 8;
	}
}

class GetFnNode: Node{
	Node[] args;
	string key;

	this(string key, Node[] args){
		this.key = key;
		this.args = args;
	}

	override string str(){
		return this.key;
	}

	override Node[] leftRight(){
		return this.args;
	} 

	override int type(){
		return 37;
	}
}

class IndexNode: Node{
	int _line;
	Node value;
	Node[2] keys;
	string change_sign;
	short kind, ischanging;

	this(Node value, Node[] keys, short kind, string change_sign="", short ischanging, int _line){
		this.value = value;
		this.keys = keys;
		this.kind=kind;
		this.change_sign = change_sign;
		this.ischanging = ischanging;
		this._line = _line;
	}

	override Node expr(){ return this.value; }

	override int index(){ return this.kind;	}

	override Node[] params(){ return this.keys;	}

	override string str(){ return this.change_sign;	}

	override int exe(){	return this.ischanging; }

	override int line(){ return this._line; }

	override int type(){ return 9; }
}

class DictNode: Node{
	string[] keys;
	Node[] values;

	this(string[] keys, Node[] values){
		this.keys = keys;
		this.values = values;
	}

	override string[] args(){ return this.keys;	}

	override Node[] params(){ return this.values; }

	override int type(){ return 4; }
}

class EnumNode: Node{
	string[] keys;
	Node[] values;

	this(string[] keys, Node[] values){
		this.keys = keys;
		this.values = values;
	}

	override string[] args(){ return this.keys;	}

	override Node[] params(){ return this.values; }

	override int type(){ return 38; }
}

class IncludeNode: Node{
	Node modules;
	int loc, pos;

	this(Node modules, int pos = 0, int loc = 0){
		this.modules = modules;
		this.pos = pos;
		this.loc = loc;
	}

	override Node expr(){
		return this.modules;
	}


	override int line(){
		return this.pos;
	}

	override int index(){
		return this.loc;
	}

	override int type(){
		return 30;
	}
}

class ForNode: Node{
	Node condi;
	Node defo;
	string var, incre;
	Node[] code;

	this(string var, Node defo, Node condi, string incre, Node[] code){
		this.var = var;
		this.defo = defo;
		this.condi = condi;
		this.incre = incre;
		this.code = code;
	}

	override string[] args(){
		return [var, incre];
	}
	
	override Node[] leftRight(){
		return [defo, condi];
	}

	override Node[] params(){
		return this.code;
	}

	override int type(){
		return 18;
	}
}

class ForEachNode: Node{
	Node value;
	Node[] code;
	string var;

	this(string var, Node value, Node[] code){
		this.var = var;
		this.code = code;
		this.value = value;
	}

	override string str(){
		return var;
	}

	override Node expr(){
		return this.value;
	}

	override Node[] params(){
		return this.code;
	}

	override int type(){
		return 42;
	}
}

class WhlNode: Node{
	Node ast;

	this(Node ast){
		this.ast = ast;
	}

	override Node expr(){
		return this.ast;
	}

	override int type(){
		return 15;
	}
}


class WhileNode: Node{
	Node ast;
	Node[] code;

	this(Node ast, Node[] code){
		this.ast = ast;
		this.code = code;
	}

	override Node expr(){
		return this.ast;
	}

	override Node[] params(){
		return this.code; // ~ new WhlNode(this.ast);
	}

	override int type(){
		return 16;
	}
}

class IfStatementNode: Node{
	Node[] code;

	this(Node[] code){
		this.code = code;
	}

	override Node[] params(){
		return this.code;
	}

	override int type(){
		return 14;
	}
}


class IfNode: Node{
	Node ast;
	Node[] code;

	this(Node ast, Node[] code){
		this.ast = ast;
		this.code = code;
	}

	override Node expr(){
		return this.ast;
	}

	override Node[] params(){
		return this.code;
	}

	override int type(){
		return 13;
	}
}


class ReturnNode: Node{
	Node ast;

	this(Node ast){
		this.ast = ast;
	}

	override Node expr(){
		return this.ast;
	}

	override int type(){
		return 12;
	}
}

class DelNode: Node{
	string[] vars;

	this(string[] vars){
		this.vars = vars;
	}

	override string[] args() {
		return vars;
	}

	override int type(){
		return 40;
	}
}

class MultiVarNode: Node{
	Node ast;
	string[] vars;

	this(string[] vars, Node ast){
		this.ast = ast;
		this.vars = vars;
	}

	override string[] args() {
		return vars;
	}

	override Node expr(){
		return this.ast;
	}

	override int type(){
		return 41;
	}
}

class ClassNode: Node{
	string name, file;
	Node[] inherits;
	Node[] code;

	this(string name, string file, Node[] inherits, Node[] code){
		this.name = name;
		this.file = file;
		this.inherits = inherits;
		this.code = code;
	}

	override string[] args(){
		return [name, file];
	}

	override Node[] params(){
		return this.code;
	}

	override Node[] leftRight(){
		return this.inherits;
	}

	override int type(){
		return 11;
	}
}


class FunctionNode: Node{
	Node[] code;
	Node[] defaults;
	string[] parameters;

	this(string[] parameters, Node[] defaults, Node[] code){
		// parameters holds even function name and file

		this.parameters = parameters;
		this.defaults = defaults;
		this.code = code;
	}

	override Node[] params(){
		return this.code;
	}

	override Node[] leftRight(){
		return this.defaults;
	}

	override string[] args(){
		return this.parameters;
	}

	override int type(){
		return 10;
	}
}

class IdNode: Node{
	int pos, loc;
	string[] var_file;

	this(string[] var_file, int pos = 0, int loc = 0){
		this.pos = pos;
		this.loc = loc;
		this.var_file = var_file;
	}

	override string[] args(){
		return this.var_file;
	}

	override int line(){
		return this.pos;
	}

	override int index(){
		return this.loc;
	}

	override int type(){
		return 26;
	}
}


class NumOp: Node {
	double n;
	this(double n){ this.n = n; }

	override double f64(){ return n; }

	override int type(){ return 1; }
}


class StrOp: Node{
	string s;
	this(string s){ this.s = s; }

	override string str(){ return s; }

	override int type(){ return 2; }
}


class FormatNode: Node{
	Node[] forms;

	this(Node[] forms){
		this.forms = forms;
	}

	override Node[] params(){
		return this.forms;
	}

	override int type(){
		return 27;
	}
}

class ListNode: Node{
	Node[] list;

	this(Node[] list){
		this.list = list;
	}

	override Node[] params(){
		return this.list;
	}

	override int type(){
		return 3;
	}
}

class ImportNode: Node{
	string[string] modules;
	string[] save;
	int ln;

	this(string[string] modules, string[] save, uint ln){
		this.save = save;
		this.modules = modules;
		this.ln = ln;
	}
	override string[] args(){ return save; }

	override string[string] strs(){ return modules; }

	override int line(){
		return this.ln;
	}

	override int type(){ return 29; }
}

class FromNode: Node{
	string fpath;
	string[] order;
	string[string] attrs;
	int ln;

	this(string fpath, string[string] attrs, string[] order, int ln){
		this.fpath = fpath;
		this.attrs = attrs;
		this.order = order;
		this.ln = ln;
	}

	override string str(){ return fpath; }

	override string[] args() { return order; }

	override string[string] strs(){ return attrs; }

	override int line(){
		return this.ln;
	}

	override int type(){ return 36; }
}

class TrueNode: Node{
	override int type(){
		return 31;
	}
}

class FalseNode: Node{
	override int type(){
		return 32;
	}
}

class NullNode: Node{
	override int type(){
		return 33;
	}
}


class VarNode: Node{
	string key;
	Node ast;

	this(string key, Node ast){
		this.key = key;
		this.ast = ast;
	}

	override string str(){
		return this.key;
	}

	override Node expr(){
		return this.ast;
	}

	override int type(){
		return 6;
	}
}

class notNode: Node{
	Node ast;

	this(Node ast){
		this.ast = ast;
	}

	override Node expr(){
		return this.ast;
	}

	override int type(){
		return 34;
	}
}

class FrNode: Node{
	string keys;

	this(string keys){
		this.keys = keys;
	}

	override string str(){
		return this.keys;
	}

	override int type(){
		return 17;
	}
}

class SwNode: Node{
	Node ast;
	Node[] code;

	this(Node ast, Node[] code){
		this.ast = ast;
		this.code = code;
	}

	override Node expr(){
		return this.ast;
	}

	override Node[] params(){
		return this.code;
	}

	override int type(){
		return 19;
	}
}


class CsNode: Node{
	bool bk;
	Node ast;
	Node[] code;

	this(Node ast, Node[] code, bool bk){
		this.bk = bk;
		this.ast = ast;
		this.code = code;
	}

	override Node expr(){
		return this.ast;
	}

	override Node[] params(){
		return this.code;
	}

	override int type(){
		return 20;
	}
}

class BreakNode: Node{
	override int type(){
		return 21;
	}
}


class ContinueNode: Node{
	override int type(){
		return 35;
	}
}


class ERROR{
	Node[] traceback;
	
	this(){
		this.traceback = traceback;
	}
}

class Locate: Node{
	int pos, loc;
	string file;

	this(int pos, string file, int loc = 0){
		this.file = file;
		this.pos = pos;
		this.loc = loc;
	}

	override string str(){
		return this.file;
	}

	override int line(){
		return this.pos;
	}

	override int index(){
		return this.loc;
	}

	override int type(){
		return 23;
	}
}


class CatchNode: Node{
	string id;
	Node[] code;

	this(string id, Node[] code){
		this.id = id;
		this.code = code;
	}

	override Node[] params(){
		return this.code;
	}

	override string str(){
		return this.id;
	}

	override int type(){
		return 24;
	}
}

class TryNode: Node{
	Node[] code;

	this(Node[] code){
		this.code = code;
	}

	override Node[] params(){
		return this.code;
	}

	override int type(){
		return 25;
	}
}

class ThrowNode: Node{
	Node ast;
	int _line;
	string file;

	this(int _line, string file, Node ast){
		this.ast = ast;
		this.file = file;
		this._line = _line;
	}

	override Node expr(){
		return this.ast;
	}

	override string str(){
		return this.file;
	}

	override int line(){
		return this._line;
	}

	override int type(){
		return 39;
	}
}

class ArgsNode: Node{
	Node ast;
	int _line;
	string file;

	this(int _line, string file, Node ast){
		this.ast = ast;
		this.file = file;
		this._line = _line;
	}

	override Node expr(){
		return this.ast;
	}

	override string str(){
		return this.file;
	}

	override int line(){
		return this._line;
	}

	override int type(){
		return 42;
	}
}

