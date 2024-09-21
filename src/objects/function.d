module LdFunction;

import std.algorithm.mutation: remove;

import std.stdio;
import std.format: format;
import std.array: join;

import core.stdc.stdlib: exit;

import LdObject, LdBytes2, LdBytes, LdExec;

import LdNode: TRACE;
import importlib: TRACEBACK;

alias LdOBJECT[string] store;


// formats fn_name in error to be exact 
string fnErrorName(LdOBJECT nm){
	if (nm.__type__ == "none")
		return "";

	return nm.__str__;
}

// string arguments or argument
string Arguments_Or(short num){
	if (num > 1)
		return format("%d needed arguments", num);

	return format("%d needed argument", num);
}

// add fn to Trace
void AddTrace(string file, uint line, string error=""){
	TRACE error_tracks = {file, line, error};
	TRACEBACK ~= error_tracks;
}

// removing successful fn from trace
void RemoveTracks(){
	remove(TRACEBACK, TRACEBACK.length-1);
	(TRACEBACK).length--;
}


class LdFn: LdOBJECT {	
	LdOBJECT ret;
	LdByte[] code;
	string[] params;
	short def_length;
	store heap, props;
	string name, file;
	LdOBJECT[] defaults;

	this(string name, string file, string[] params, LdOBJECT[] defaults, LdByte[] code, store heap){
		this.name = name;
		this.file = file;

		this.code = code;
		this.heap = heap;

		this.params = params;
		this.defaults = defaults;

		this.def_length = cast(short)(defaults.length);

		this.props = [
			"this": RETURN.A,
			"__args__": new LdHsh(null),
			"__look__": new LdStr(format("%s (method)", name)),
			"__name__": new LdStr(name),
			"__file__": new LdStr(file),
			"__parent__": new LdStr(""),
		];

		this.params_lists();
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		if(args.length < params.length) {
			short def = cast(short)((def_length - (params.length-args.length)));

			if (def < 0) {
				short miss = cast(short)(params.length - args.length);

				if ("__exec_path__" in this.props)
					AddTrace(props["__exec_path__"].__str__, line, "TypeError");
				else
					AddTrace((*mem)["-file-"].__str__, line, "TypeError");

				throw new Exception(format("fn '%s%s' is missing %s (%s)", props["__parent__"].__str__, props["__name__"].__str__, Arguments_Or(miss)
					, join(params[(params.length-miss)..params.length], ", ")));
			}

			// adding defaults
			args ~= defaults[def .. def_length];
		}

		// resetting for new function
		auto point = this.heap.dup;
		point["this"] = props["this"];
		point["#rt"] = RETURN.A;
		point["#rtd"] = RETURN.B;
		point["#bk"] = RETURN.B;

		for(size_t i = 0; i < params.length; i++)
			point[params[i]] = args[i];

		if ("__exec_path__" in this.props)
			AddTrace(props["__exec_path__"].__str__, line);
		else
			AddTrace((*mem)["-file-"].__str__, line);
		
		auto ret_val = (*(new _Interpreter(code, &point).heap))["#rt"];
		
		RemoveTracks();
		return ret_val;
	}

	void params_lists(){
		LdOBJECT[] parameters;

		foreach(i; this.params)
			parameters ~= new LdStr(i);

		this.props["__params__"] = new LdArr(parameters);
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __type__() { return "function"; }

	override string __str__(){ return props["__look__"].__str__; }
}
