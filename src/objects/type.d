module LdType;

import std.stdio;
import std.array: join, replace;
import std.format: format;
import std.algorithm.searching: startsWith, endsWith;

import LdObject, LdBytes2, LdBytes, LdExec;
import LdFunction: RemoveTracks, AddTrace;


alias LdOBJECT[string] HEAP;


class LdTyp: LdOBJECT {
	LdByte[] code;
	string[] attrs;
	string name, file;				
	LdOBJECT[] inherit;
	HEAP heap, block_memory, props;

	this(string name, string file, LdOBJECT[] inherit, string[] attrs, LdByte[] code, HEAP heap){
		this.heap = heap;
		this.name = name;
		this.file = file;
		this.code = code;
		this.attrs = attrs;
		this.props = props;
		this.inherit = inherit;
		this.block_memory = block_memory;

		// INHERITING PROPERTIES STEP
		foreach(LdOBJECT res; inherit) {
			foreach(string var, LdOBJECT value; res.__props__ )
				if (!(var.startsWith("__") && var.endsWith("__")))
					this.props[var] = value;
		}

		this.props["__name__"] = new LdStr(name);
		this.props["__file__"] = new LdStr(file);
		this.props["__inherits__"] = new LdArr( inherit );

		foreach(string var, LdOBJECT value; this.__property__)
			this.props[var] = value;

		// adding the object to its very scope
		this.heap[name] = this;
	}

	override LdOBJECT[string] __property__(){
		HEAP type_scope;
		LdOBJECT type_var;

		HEAP type_memory = heap.dup;
		this.block_memory = *(new _Interpreter(code, &type_memory).heap);

		foreach(string i; attrs){
			type_var = this.block_memory[i];

			if (type_var.__type__ == "function") {
				type_var.__setProp__("__parent__", new LdStr(format("%s.", name)));
				type_var.__setProp__("__look__", new LdStr(format("%s.%s (type method)", name, type_var.__props__["__name__"].__str__)));
			}
			type_scope[i] = type_var;
		}
		return type_scope;
	}

	override LdOBJECT __super__(LdOBJECT self){
		//return new Ld_Super_Object(name, attrs, code, heap, self);
		return new Ld_Super_Object(this, self);
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		return new Ld_New_Object(this, args, line, (*mem)["-file-"].__str__);
	}

	override string __type__(){ return name; }

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return name ~ " (type)"; }
}


class Ld_New_Object: LdOBJECT {
	HEAP props;
	LdTyp _type;
	string _file;
	
	this(LdTyp _type, LdOBJECT[] _args, uint line, string _file) {
		this._type = _type;
		this._file = _file;

		this.props = [
			"__look__": new LdStr(format("%s (object)", _type.name)),
		];

		// build object properties
		this.build_new_attrs();

		// initialization function
		if ("__start__" in props) {
			auto new_heap = _type.heap.dup;
			props["__start__"](_args, line, &new_heap);
		}
	}

	void build_new_attrs() {
		auto new_attrs = this._type.props.dup;

		HEAP type_memory = _type.heap.dup;
		string object_fn_name;

		foreach(LdByte code_block; _type.code) {
			if (typeid(code_block) == typeid(Op_FnDef)){
				object_fn_name = (cast(Op_FnDef)code_block).name;

				new_attrs[object_fn_name] = (*(new _Interpreter([code_block], &type_memory).heap))[object_fn_name];
			
			} else if (typeid(code_block) == typeid(Op_Pobj)) {
				object_fn_name = (cast(Op_Pobj)code_block).name;
				
				new_attrs[object_fn_name] = (*(new _Interpreter([code_block], &type_memory).heap))[object_fn_name];
			}
		}

		foreach(string key, LdOBJECT value; new_attrs){
			if (value.__type__ == "function") {
				value.__setProp__("this", this);
				value.__setProp__("__parent__", new LdStr(format("%s.", _type.name)));
				value.__setProp__("__look__", new LdStr(format("%s.%s (object method)", _type.name, value.__props__["__name__"].__str__)));

				if(value.__props__["__name__"].__str__ == "__start__")
					value.__props__["__exec_path__"] = new LdStr(this._file);
			}

			props[key] = value;
		}
	}

	override string __type__(){ return _type.name; }

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return props["__look__"].__str__; }
}


class Ld_Super_Object: LdOBJECT {
	LdTyp _type;
	LdOBJECT _self;
	LdOBJECT[string] props;
	
	this(LdTyp _type, LdOBJECT _self){
		this._type = _type;
		this._self = _self;

		this.props = [
			"__name__": _type.__props__["__name__"],
			"__look__": new LdStr(format("%s (object)", _type.name)),
		];

		// build object properties
		this.build_new_attrs();
	}

	void build_new_attrs(){
		auto new_attrs = this._type.props.dup;

		HEAP type_memory = _type.block_memory.dup;
		string object_fn_name;

		foreach(LdByte code_block; _type.code) {
			if (typeid(code_block) == typeid(Op_FnDef)){
				object_fn_name = (cast(Op_FnDef)code_block).name;

				new_attrs[object_fn_name] = (*(new _Interpreter([code_block], &type_memory).heap))[object_fn_name];
			
			} else if (typeid(code_block) == typeid(Op_Pobj)) {
				object_fn_name = (cast(Op_Pobj)code_block).name;
				
				new_attrs[object_fn_name] = (*(new _Interpreter([code_block], &type_memory).heap))[object_fn_name];
			}
		}

		foreach(string key, LdOBJECT value; new_attrs){
			if (value.__type__ == "function") {
				value.__setProp__("this", _self);
				value.__setProp__("__look__", new LdStr(join( 
					[_type.name, ".", value.__getProp__("__name__").__str__, " (object method)"])
				));
			}
			props[key] = value;
		}
	}

	override string __type__(){ return _type.name; }

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return props["__look__"].__str__; }
}

// MODULES

import std.path: dirSeparator;

class LdModule: LdOBJECT {
	string name, _path;
	LdOBJECT[string] props;
	
	this(string name, string _path, LdOBJECT[string] data) {
		this.name = name.replace(cast(string)dirSeparator, ".");
		this._path = _path;

		this.props = [
			"__path__": new LdStr(_path),
			"__name__": new LdStr(name),
			"__spec__": new LdStr("non-circular module")
		];

		foreach(key, fn; data){

			if (fn.__type__ == "function") {
				fn.__setProp__("__look__", new LdStr(
					format("%s.%s (method)", name, fn.__getProp__("__name__").__str__)));

			} else if (startsWith(key, "#") || startsWith(key, "-"))
				continue;

			props[key] = fn;
		}
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __type__(){ return "module"; }

	override string __str__(){ return format("%s (module at '%s')", name, _path); }
}
