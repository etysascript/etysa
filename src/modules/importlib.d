module importlib;

import std.format: format;
import std.stdio: writeln;

import core.stdc.stdlib: exit;

import std.algorithm.searching: endsWith, startsWith, find, canFind;
import std.algorithm.iteration: map, each;
import std.algorithm.mutation: remove;

import std.array: array, split, replace;
import std.file: exists, isFile, isDir, readText, dirEntries, SpanMode;

import std.path: buildPath, absolutePath, stripExtension, baseName, dirSeparator;
import LdParser, LdNode, LdBytes, LdIntermediate, LdExec;
import LdLexer: _Lex;

import LdObject;
import lLocals, lSys: oSys;

import LdFunction: RemoveTracks;
import LdType: LdModule;


alias LdOBJECT[string] HEAP;
HEAP imported_modules, _runtimeModules, _StartHeap;

LdModule[][string] Circular;
TRACE[] TRACEBACK;


void SETUP_HEAP(string[] args) {
	_StartHeap = [
		"#rtd": RETURN.B,
		"#rt": RETURN.A,
		"#bk": RETURN.B,
		"-traceback-": new LdArr([]),
	];

	_runtimeModules = [ "": new LdStr("") ];

	// enter in runtimeModule to modules_path
	oSys sys = new oSys(args, new LdHsh(_runtimeModules));
	auto _locals_functions = __locals_props__;

	lLocals.Required_Lib = [
				"sys": sys,
				"locals": new oLocals(_locals_functions),
			];

	// setting modules to imported_modules
	sys.__setProp__("modules", new LdHsh(imported_modules));

	LdOBJECT[string] Util_fns = [
		"type": _locals_functions["type"],
		
		"print": _locals_functions["print"],
		"input": _locals_functions["input"],
		
		"exit": _locals_functions["exit"],
		"super": _locals_functions["super"],

		"length": _locals_functions["length"],
		"eval": _locals_functions["eval"],

		"exec": _locals_functions["exec"],
		"Import": _locals_functions["Import"],

		"list_attrs": _locals_functions["list_attrs"],
		"get_attr": _locals_functions["get_attr"],
		"set_attr": _locals_functions["set_attr"],
		"del_attr": _locals_functions["del_attr"],

		"Str": _locals_functions["Str"],
		"List": _locals_functions["List"],
		"Map": _locals_functions["Map"],
		"Bytes": _locals_functions["Bytes"],
		"Num": _locals_functions["Num"],
	];

	Util_fns.keys().each!(i => essential_functions[i] = Util_fns[i]);
	rehash(essential_functions);
}


string inPath(string ph) {
	string md;

	foreach(i; lLocals.Required_Lib["sys"].__getProp__("path").__array__)
	{
		foreach(ext; ["", ".ets"]) {
			md = buildPath(i.__str__, format("%s%s", ph, ext));

			if(exists(md))
				return absolutePath(md);
		}
	}
	return "";
}

// JUST THE IMPORT STATEMENT
void import_module(string[string] _names, string[] save, HEAP* mem, uint line) {
	string _module;
	string[] done;

	LdOBJECT mod = null;

	foreach(i; save) {
		_module = inPath(_names[i]);
		
		if(!_module.length){
			RemoveTracks();
			TRACE error_tracks = {(*mem)["-file-"].__str__, line, "ImportError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("module '%s' is not found", _names[i]));
		}

		if(isFile(_module))
			mod = read_file_module([i, _module, (*mem)["-file-"].__str__, _names[i]], line);
		
		else if (isDir(_module))
			mod = read_dir_module([i, _module, (*mem)["-file-"].__str__, _names[i]], line);

		else {
			RemoveTracks();
			TRACE error_tracks = {(*mem)["-file-"].__str__, line, "ImportError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("module '%s' path should be a directory or file", _module));
		}
		
		done = i.split(dirSeparator);
		(*mem)[done[done.length - 1]] = mod;
	}
}

void cache(string htap, LdOBJECT mod) {
	imported_modules[htap] = mod;

	if(htap in Circular) {
		foreach(ref i; Circular[htap])
			i.props = mod.__props__;

		Circular.remove(htap);
	}
}

bool circular(string f) {
	if(f in Circular)
		return false;

	Circular[f] = [];
	return true;
}


void directory_library(string[4] htap, string[string]*attrs, string[]*order, HEAP*mem, int line){
	LdOBJECT mod = read_dir_module(htap, line);
	string _file;

	foreach(i; *order) {
		if(i == "*") {
			foreach(attr, value; mod.__props__){
				if (!(startsWith(attr, "__") && endsWith(attr, "__")))
					(*mem)[attr] = value;
			}
			continue;
		}

		if (i in mod.__props__)
			(*mem)[(*attrs)[i]] = mod.__props__[i];
		
		else {
			_file = buildPath(htap[1], i);

			if (!exists(_file)) {
				_file = format("%s.ets", _file);

				if(!exists(_file)) {
					RemoveTracks();
					TRACE error_tracks = {(*mem)["-file-"].__str__, line, "ImportError"};
					TRACEBACK ~= error_tracks;

					throw new Exception(format("module '%s' is not found in '%s' module directory", i, htap[0]));
				}
			}

			if(isFile(_file))
				(*mem)[(*attrs)[i]] = read_file_module([i, _file, htap[2], i]);

			else if(isDir(_file))
				(*mem)[(*attrs)[i]] = read_dir_module([i, _file, htap[2], i], line);

			else{
				RemoveTracks();
				TRACE error_tracks = {(*mem)["-file-"].__str__, line, "ImportError"};
				TRACEBACK ~= error_tracks;

				throw new Exception(format("Unsupported file '%s' format for importing.", i, htap[0]));
			}
		}
	}
}

// htap --> module path

LdOBJECT read_dir_module(string[4] htap, int line){
	LdModule mod;

	string[] list= dirEntries(htap[1], "*.ets", SpanMode.shallow, false).map!(i=>cast(string)i).array;
	string pack = buildPath(htap[1], "__export__.ets");

	if(pack in imported_modules)
		return imported_modules[pack];

	else if (canFind(list, pack))
		return read_file_module(["__export__", pack, htap[2], htap[3]], line);

	if(circular(htap[1])) {
		mod = new LdModule("__export__", pack, ["__spec__": new LdStr("Directory module"), "__path__": new LdStr(pack)]);

		cache(htap[1], mod);
		return mod;
	}

	mod = new LdModule("__export__", pack, ["__spec__": new LdStr("Directory module"),
						"__path__": new LdStr(pack)]);
	Circular[pack] ~= mod;
	return mod;
}

LdOBJECT read_file_module(string[4] htap, uint line=0){
	LdModule mod;

	if(htap[1] in imported_modules)
		return imported_modules[htap[1]];

	if(circular(htap[1])) {
		HEAP _scope = _StartHeap.dup;
		_scope["-file-"] = new LdStr(htap[1]);

		mod = new LdModule(htap[3], htap[1], *(new _Interpreter(new _GenInter(new _Parse(new _Lex(readText(htap[1])).TOKENS, htap[1]).ast).bytez, &_scope).heap));

		cache(htap[1], mod);

		return mod;
	}

	mod = new LdModule(htap[3], htap[1], ["__spec__": RETURN.A]);
	Circular[htap[1]] ~= mod;

	return mod;
}

void file_library(string[4] htap, string[string]*attrs, string[]*order, HEAP*mem, uint line){
	LdOBJECT mod = read_file_module(htap, line);

	HEAP props = mod.__props__;

	foreach(i; *order) {
		if (i == "*") {
			foreach(name, data; props) {
				if(!(endsWith(name, "__") && startsWith(name, "__")))
					(*mem)[name] = data;
			}
		
		} else if(i in props)
			(*mem)[(*attrs)[i]] = props[i];
	
		else {
			RemoveTracks();
			TRACE error_tracks = {(*mem)["-file-"].__str__, line, "ImportError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("attribute '%s' is not found in file module '%s'",
										 i, mod.__props__["__name__"].__str__));
		}
	}
}

void import_library(string fpath, string[string]*attrs, string[]*order, HEAP* mem, uint line) {
	string htap = inPath(fpath);

	if(!htap.length){
		TRACE error_tracks = {(*mem)["-file-"].__str__, line, "ImportError"};
		TRACEBACK ~= error_tracks;

		throw new Exception(format("module path '%s' is not found.", fpath));
	}

	if(isFile(htap))
		return file_library([fpath, htap, (*mem)["-file-"].__str__, fpath], attrs, order, mem, line);

	if(isDir(htap))
		return directory_library([fpath, htap, (*mem)["-file-"].__str__, fpath], attrs, order, mem, line);
}

