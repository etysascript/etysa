module LdBytes;

import std.stdio;
import std.conv: to;
import core.stdc.stdlib;

import std.algorithm.iteration: each;
import std.algorithm.mutation: remove;

import std.file: exists;
import std.string: strip, chomp;
import std.format: format;
import std.array: replicate;

import LdObject;
import importlib: TRACEBACK;

import LdNode: TRACE;
import LdFunction;
import LdExec;


alias LdOBJECT[string] HEAP;

HEAP essential_functions;

class LdByte {
	LdByte[string] hash;

	LdOBJECT opCall(HEAP* _heap){ return new LdOBJECT(); }

	LdByte[] opCode(){ return []; }

	short type(){ return 1; }
}


class Op_Var: LdByte {
	LdByte value;
	string key;

	this(string key, LdByte value){
		this.value = value;
		this.key = key;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		(*_heap)[key] = value(_heap);
		return RETURN.A;
	}
}


class Op_VarMult: LdByte {
	LdByte value;
	string[] vars;

	this(string[] vars, LdByte value){
		this.value = value;
		this.vars = vars;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		auto data = value(_heap).__array__;

		if (data.length < vars.length){
			throw new Exception("TypeError: values cannot be less than vars in multi assign.");
		}

		for(short i; i<vars.length; i++)
			(*_heap)[vars[i]] = data[i];

		return RETURN.A;
	}
}


class Op_Delvar: LdByte {
	string[] vars;

	this(string[] vars){
		this.vars = vars;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		vars.each!(i => ((*_heap).remove(i)));
		return RETURN.A;
	}
}


class Op_Id: LdByte {
	string key, file;
	uint line, pos;

	this(string key, string file, uint line, uint pos){
		this.key = key;
		this.file = file;
		this.line = line;
		this.pos = pos;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (key in *_heap)
			return (*_heap)[key];

		else if (key in essential_functions)
			return essential_functions[key];

		TRACE error_tracks = {this.file, this.line, "ReferenceError"};
		TRACEBACK ~= error_tracks;

		throw new Exception(format("'%s' is not defined", key));
		return RETURN.A;
	}
}

class Op_Format: LdByte {
	LdByte[] arr;

	this(LdByte[] arr){
		this.arr = arr;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		string st;
		arr.each!(i => st ~= i(_heap).__str__);

		return new LdStr(st);
	}
}


class Op_FnDef: LdByte {
	string name, file;
	LdByte[] code;
	string[] params;
	LdByte[] defaults;

	this(string name, string file, string[] params, LdByte[] defaults, LdByte[] code){
		this.code = code;
		this.name = name;
		this.file = file;
		this.params = params;
		this.defaults = defaults;
	}

	override LdOBJECT opCall(HEAP* _heap){
		LdOBJECT[] defs;

		foreach(LdByte i; defaults)
			defs ~= i(_heap);

		auto fn = new LdFn(name, file, params, defs, code, *_heap);

		if(name == "")
			return fn;

		(*_heap)[name] = fn;
		return RETURN.A;
	}
}


class Op_Return: LdByte {
	LdByte value;

	this(LdByte value){
		this.value = value;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		(*_heap)["#rt"] = this.value(_heap);
		(*_heap)["#rtd"] = RETURN.C;
		(*_heap)["#bk"] = RETURN.C;

		return RETURN.A;
	}
}


class Op_Args: LdByte {
	LdByte args;

	this(LdByte args){
		this.args = args;
	}

	override LdOBJECT opCall(HEAP* _heap){
		return args(_heap);
	}

	override short type(){ return 0; }
}

class Op_FnCall: LdByte {
	LdByte fn_ref;
	LdByte[] args;
	uint line, pos;

	this(LdByte fn_ref, LdByte[] args, uint line, uint pos){
		this.fn_ref = fn_ref;
		this.pos = pos;

		this.line = line;
		this.args = args;
	}

	override LdOBJECT opCall(HEAP* _heap){
		LdOBJECT fnz = fn_ref(_heap);

		LdOBJECT[] params;
		LdOBJECT per;

		foreach(LdByte i; args){
			if (i.type)
				params ~= i(_heap);
			else {
				per = i(_heap);
				params ~= per.__array__;
			}
		}

		return fnz(params, line, _heap);
	}
}


class Op_If: LdByte {
	LdByte exe;
	LdByte[] code;

	this(LdByte exe, LdByte[] code){
		this.exe = exe;
		this.code = code;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return exe(_heap);
	}

	override LdByte[] opCode(){
		return this.code;
	}
}


class Op_IfCase: LdByte {
	LdByte[] ifs;

	this(LdByte[] ifs){
		this.ifs = ifs;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		foreach(LdByte fi; ifs){
			if(fi(_heap).__true__){
				new _Interpreter(fi.opCode, _heap);
				break;
			}
		}

		return RETURN.A;
	}
}


class Op_While: LdByte {
	LdByte base;
	LdByte[] code;

	this(LdByte base, LdByte[] code){
		this.base = base;
		this.code = code;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		while((*_heap)["#bk"].__true__ && base(_heap).__true__)
			new _Interpreter(code, _heap);

		if((*_heap)["#rtd"].__true__)
			(*_heap)["#bk"] = RETURN.B;

		return RETURN.A;
	}
}


class Op_For: LdByte {
	string var;
	LdByte defo;

	LdByte condi;
	short incre;

	LdByte[] code;

	this(string var, LdByte defo, LdByte condi, string inc, LdByte[] code){
		this.var = var;
		this.defo = defo;
		this.condi = condi;

		if (inc == "++")
			this.incre = 1;
		else
			this.incre = -1;

		this.code = code;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		long i = cast(long)defo(_heap).__num__;
		(*_heap)[var] = new LdNum(i);

		while (condi(_heap).__true__) {
			new _Interpreter(code, _heap);

			if((*_heap)["#bk"].__true__ && condi(_heap).__true__) {
				i += incre;
				(*_heap)[var] = new LdNum(i);
			} else
				break;
		}

		if((*_heap)["#rtd"].__true__)
			(*_heap)["#bk"] = RETURN.B;

		return RETURN.A;
	}
}


class Op_ForEach: LdByte {
	string var;
	LdByte value;
	LdByte[] code;

	this(string var, LdByte value, LdByte[] code){
		this.var = var;
		this.value = value;
		this.code = code;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		auto data = value(_heap);

		if (data.__type__ == "list" && data.__array__.length) {
			LdOBJECT[] listz = data.__array__;

			(*_heap)[var] = listz[0];

			for(size_t item=1; item < (listz.length+1); item++) {
				new _Interpreter(code, _heap);

				if((*_heap)["#bk"].__true__)
					(*_heap)[var] = listz[item];
				else
					break;				
			}
		
		} else if (data.__type__ == "string" && data.__str__.length) {
			string word = data.__str__;

			(*_heap)[var] = new LdStr(to!string(word[0]));

			for(size_t item=1; item < (word.length+1); item++) {
				new _Interpreter(code, _heap);

				if((*_heap)["#bk"].__true__)
					(*_heap)[var] = new LdStr(to!string(word[item]));
				else
					break;				
			}
		}
		return RETURN.A;
	}
}


class Op_Break: LdByte {
	override LdOBJECT opCall(HEAP* _heap){
		(*_heap)["#bk"] = RETURN.C;
		return RETURN.A;
	}
}


class Op_Continue: LdByte {
	override LdOBJECT opCall(HEAP* _heap){
		return RETURN.A;
	}
}


import std.file: readText, exists, isFile;
import LdParser, LdLexer, LdIntermediate;

static void addFls(LdOBJECT[] fls, HEAP* _heap) {
	LdByte[] bcode;
	
	foreach(i; fls) {
		if(exists(i.__str__) && isFile(i.__str__)) {
			bcode = new _GenInter(new _Parse(new _Lex(readText(i.__str__)).TOKENS, i.__str__).ast).bytez;
			new _Interpreter(bcode, _heap);
		}
	}
}

class Op_Include: LdByte {
	LdByte modules;

	this(LdByte modules){
		this.modules = modules;
	}

	override LdOBJECT opCall(HEAP* _heap){
		addFls(modules(_heap).__array__, _heap);
		return RETURN.A;
	}
}


import importlib: import_module, import_library;


class Iimport: LdByte {
	string[string] modules;
	string[] save;
	uint line;

	this(string[string] modules, string[] save, uint line){
		this.modules = modules;
		this.save = save;
		this.line = line;
	}

	override LdOBJECT opCall(HEAP* _heap){ 
		AddTrace((*_heap)["-file-"].__str__, line);
		
		import_module(modules, save, _heap, line);

		RemoveTracks();
		return RETURN.A;
	}
}

class Ifrom: LdByte {
	string fpath;
	string[] order;
	string[string] attrs;
	uint line;

	this(string _path, string[string] attrs, string[] order, uint line){
		this.fpath = _path;
		this.attrs = attrs;
		this.order = order;
		this.line = line;
	}

	override LdOBJECT opCall(HEAP* _heap){
		AddTrace((*_heap)["-file-"].__str__, line);

		import_library(fpath, &attrs, &order, _heap, line);

		RemoveTracks();
		return RETURN.A;
	}
}


// remove traces overlapped by try
void emptyTraces(ushort index){
	TRACEBACK = TRACEBACK[0..index];
}


class Op_Try: LdByte {
	string handle;
	LdByte[][] code;

	this(string handle, LdByte[][] code){
		this.code = code;
		this.handle = handle;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		ushort at_Try = 0;
		
		try{
			at_Try = cast(ushort)TRACEBACK.length;
			new _Interpreter(code[0], _heap);
			
		} catch (Exception e) {
			auto track = TRACEBACK[TRACEBACK.length-1];

			if (handle) {
				(*_heap)[handle] = new LdEnum(
					track.type, [
						"message": new LdStr(e.msg),
						"line": new LdNum(track.line),
						"file": new LdStr(track.file),
					]);

   				emptyTraces(at_Try);
				new _Interpreter(code[1], _heap);
			} else
    			emptyTraces(at_Try);
		}

		return RETURN.A;
	}
}


class Op_Throw: LdByte {
	uint line;
	string _file;
	LdByte value;

	this(LdByte value, string _file, uint line){
		this.line = line;
		this.value = value;
		this._file = _file;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		LdOBJECT expect = value(_heap);

		TRACE error_tracks = {this._file, this.line, expect.__type__};
		TRACEBACK ~= error_tracks;

		if ("error" in expect.__props__)
			throw new Exception(expect.__getProp__("error").__str__);

		throw new Exception("error occured");
		return RETURN.A;
	}
}

