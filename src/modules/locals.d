module lLocals;

import std.stdio;

import std.string: chomp;
import std.algorithm.iteration: each;

import std.algorithm.searching: find;
import std.format: format;

import core.stdc.stdio: printf;
import core.stdc.stdlib: exit;

import LdParser, LdNode, LdBytes, LdIntermediate, LdExec;
import LdLexer: _Lex;

import std.algorithm.comparison: cmp;
import std.file: exists, isFile, readText;

import std.path: absolutePath;

import LdObject;
import importlib: _StartHeap, LdModule, imported_modules, circular, Circular, cache;
import LdFunction: AddTrace;

// included to locals
import lList: oList;
import lMap: oMap;
import lNumber: oNumber;

import LdString: oStr;
import LdChar: oBytes;

alias LdOBJECT[string] HEAP; 


class oLocals: LdOBJECT
{
	LdOBJECT[string] props;

	this(LdOBJECT[string] props){
		this.props = props;
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "locals (native module)"; }
}


static LdOBJECT[string] __locals_props__(){
	return [
			"print": new _Print(),
			"input": new _Input(),

			"super": new _Super(),
			"length": new _Length(),

			"type": new _Type(),
			"exit": new _Exit(),

			"eval": new _Eval(),
			"exec": new _Exec(),
			"Import": new __Import__(),

			"list_attrs": new _ListProperties(),
			"get_attr": new _GetProperty(),
			"set_attr": new _SetProperty(),
			"del_attr": new _DeleteProperty(),

			"Str": new oStr(),
			"List": new oList(),
			"Map": new oMap(),
			"Bytes": new oBytes(),
			"Num": new oNumber(),
		];
}


static void cprints(string i) {
	printf("%.*s ", cast(int)i.length, i.ptr);
}

class _Print: LdOBJECT
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		args.each!(n => cprints(n.__str__));
		printf("\n");

		return RETURN.A;
	}

	override string __str__(){ return "locals.print (method)"; }
}


// importing core modules

import lTime: oTime;
import lBase64: oBase64;

import lMath: oMath;
import lSocket: oSocket;
import lFs: oFs;

import lJson: oJson;
import lPath: oPath;

import lPromises: oPromises;

import lDtypes: oDtypes;
import lRandom: oRandom;

import lRegex: oRegex;
import lProcess: oSubProcess;

import Os: oS;
import Websock: oWebsock;

import lUrl: oUrl;
import lThread: oThread;


const string[] _Core_Lib = ["base64", "locals", "dtypes", "fs", "json", "math", "os", "promises", "path", "process", "random", "regex", "socket", "sys", "sqlite3", "thread", "time", "url", "websocket"];

LdOBJECT[string] Required_Lib;


LdOBJECT import_core_library(string X){
	switch (X) {
		case "base64":
			return new oBase64();
		case "dtypes":
			return new oDtypes();
		case "fs":
			return new oFs();
		case "json":
			return new oJson();
		case "path":
			return new oPath();
		case "regex":
			return new oRegex();
		case "random":
			return new oRandom();
		case "socket":
			return new oSocket();
		case "process":
			return new oSubProcess();
		case "thread":
			return new oThread();
		case "promises":
			return new oPromises();
		case "sqlite3":
			return RETURN.A;
		case "time":
			return new oTime();
		case "os":
			return new oS();
		case "url":
			return new oUrl();
		case "websocket":
			return new oWebsock();
		default:
			return new oMath();
	}
}


class _Input: LdOBJECT
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		if (args.length)
			write(args[0].__str__);

		return new LdStr(chomp(readln()));
	}

	override string __str__(){ return "locals.input (method)"; }
}


class _Super: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		if (args.length < 2)
			throw new Exception("TypeError: super() expects 2 args, [type, object]");

		return args[0].__super__(args[1]);
	}

	override string __str__(){ return "locals.super (method)"; }
}


class _Length: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		return new LdNum(args[0].__length__);
	}

	override string __str__(){ return "locals.length (method)"; } 
}

class _Type: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		return new LdStr(args[0].__type__);
	}

	override string __str__(){ return "locals.type (method)"; } 
}


string[] sort_strings(string[] n) {
	if (!n.length)
		return n;

    string temp;

    for(size_t i = 0; i < (n.length-1); i++){
        size_t n_min = i;

        for(size_t j = i + 1; j < n.length; j++)
            if (cmp(n[j], n[n_min]) < 0){
                n_min = j;
            }

        if (n_min != i) {
            temp = n[i];
            n[i] = n[n_min];
            n[n_min] = temp;
        }
    }
    return n;
}

class _ListProperties: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		LdOBJECT[] arr;
		(sort_strings(args[0].__props__.keys())).each!(i => arr ~= new LdStr(i));
		return new LdArr(arr);
	}

	override string __str__(){ return "locals.list_attrs (method)"; } 
}


class _GetProperty: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		if (args[1].__str__ in args[0].__props__)
			return args[0].__props__[args[1].__str__];

		AddTrace((*mem)["-file-"].__str__, line, "ReferenceError");
		throw new Exception(format("type '%s' has no attribute '%s'.", args[0].__type__, args[1].__str__));

		return RETURN.A;
	}

	override string __str__(){ return "locals.get_attr (method)"; } 
}

class _SetProperty: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		args[0].__setProp__(args[1].__str__, args[2]);
		return RETURN.A;
	}

	override string __str__(){ return "locals.set_attr (method)"; } 
}

class _DeleteProperty: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		args[0].__deleteProp__(args[1].__str__);
		return RETURN.A;
	}

	override string __str__(){ return "locals.del_attr (method)"; } 
}


class _Exit: LdOBJECT 
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		exit(0);
		return RETURN.A;
	}

	override string __str__(){ return "locals.exit (method)"; } 
}




TOKEN[] man_tokens(string code) {
	TOKEN[] toks;

	TOKEN A = {"#eval", "ID", 0, 1, 1}; toks ~= A;
	TOKEN B = {"=", "=", 0, 1, 1}; toks ~= B;

	return (toks ~ new _Lex(code).TOKENS);
}

class _Eval: LdOBJECT
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null) {
		LdByte[] bin = new _GenInter ( new _Parse( man_tokens(args[0].__str__), "eval.io" ).ast ).bytez;

		return (*(new _Interpreter(bin, mem).heap))["#eval"];
	}

	override string __str__(){ return "locals.eval (method)"; }
}

class _Exec: LdOBJECT
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null) {
		LdByte[] bin = new _GenInter ( new _Parse( new _Lex(args[0].__str__).TOKENS, "eval.io" ).ast ).bytez;
		new _Interpreter(bin, mem);

		return RETURN.A;
	}

	override string __str__(){ return "locals.exec (method)"; }
}

//string 


class __Import__: LdOBJECT
{
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null) {
		string importFile = args[0].__str__;

		if (!(exists(importFile) && isFile(importFile))) {
			if (importFile in Required_Lib)
				return Required_Lib[importFile];

			if (find(_Core_Lib, importFile).length) {
				auto x = import_core_library(importFile);
				Required_Lib[importFile] = x;

				return x;
			}

			throw new Exception(format("ImportError: builtin module '%s' is not found", importFile));
		}

		string fullFilePath = absolutePath(importFile);

		if (fullFilePath in imported_modules)
			return imported_modules[fullFilePath];

		if(circular(fullFilePath)) {
			HEAP _scope = _StartHeap.dup;
			_scope["-file-"] = new LdStr(fullFilePath);

			LdByte[] bin = new _GenInter ( new _Parse( new _Lex(readText(fullFilePath)).TOKENS, fullFilePath ).ast ).bytez;

			auto fetchedImport = new LdModule(importFile, fullFilePath, *(new _Interpreter(bin, &_scope).heap));

			cache(fullFilePath, fetchedImport);
			return fetchedImport;
		}

		auto fetchedImport = new LdModule(importFile, fullFilePath, ["__path__": new LdStr(fullFilePath), "__module__":RETURN.A]);
		Circular[fullFilePath] ~= fetchedImport;

		return fetchedImport;
	}

	override string __str__(){ return "locals.__import__ (method)"; }
}

