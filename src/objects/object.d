module LdObject;

import std.stdio;
import std.conv: to;

import std.string: chomp;
import std.format: format;

import std.array: join;
import std.algorithm.iteration: map;

import std.json: JSONValue, toJSON;

import importlib: TRACEBACK;


class LdOBJECT {
	LdOBJECT[string] hash, props;

	LdOBJECT[]* __ptr__(){ return null; }

	string __str__(){ return "null";}

	string __json__(){ return __str__; }

	double __num__(){ return 0; }

	bool __stop_iteration__(){ return true; }
	
	size_t __length__(){ return 0; }

	LdOBJECT[] __array__(){ return []; }

	LdOBJECT[string] __property__ (){ return hash; }

	LdOBJECT[string] __hash__ (){ return __props__; }

	LdOBJECT[string] __props__(){ return hash; }

	char[] __chars__() { return []; }

	string __type__(){ return "unnamed"; }

	LdOBJECT __index__(LdOBJECT arg) {return new LdOBJECT(); }

	LdOBJECT __getProp__(string prop) {
		if (prop in __props__)
			return __props__[prop];

		throw new Exception(format("ReferenceError: '%s' has no attribute '%s'", __type__, prop));
	}

	LdOBJECT __setProp__(string prop, LdOBJECT value){
		__props__[prop] = value;
        return new LdOBJECT();
    }

    void __deleteProp__(string prop) {
    	__props__.remove(prop);
    }

	LdOBJECT __super__(LdOBJECT self){ return new LdOBJECT(); }

	void __assign__(LdOBJECT index, LdOBJECT value){ __props__[index.__str__] = value; }


	//LdOBJECT opCall(LdOBJECT[] args) { return new LdOBJECT(); }

	LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		throw new Exception(format("TypeError: '%s' is not a function", __type__));
		return new LdOBJECT();
	}

	double __true__() { return 0; }

}

alias LdOBJECT[string] HEAP;


enum RETURN {
	D = new LdOBJECT(),
	A = new LdNone(),
	B = new LdTrue(),
	C = new LdFalse(),
}


class LdTrue: LdOBJECT {
	override string __str__(){ return "True"; }
	override string __type__(){ return "boolean"; }
	override double __true__() { return 1; }
}

class LdFalse: LdOBJECT{
	override string __type__(){ return "boolean"; }
	override string __str__(){ return "False"; }
}

class LdNone: LdOBJECT {
	override string __type__(){ return "None"; }
	override string __str__(){ return "None"; }
}


class LdStop_Iterator: LdOBJECT {
	override string __str__(){ return "stop-Iterator (core method)"; }

	override bool __stop_iteration__() { return false; }
}




class LdNum: LdObject.LdOBJECT {
	double num;
	
	this(double num){
		this.num = num;
	}

	override double __num__(){ return num; }

	override string __str__(){ return to!string(num); }

	override string __type__(){ return "number"; }

	override double __true__(){ return num; }
}


class LdChr: LdOBJECT
{
	char[] _chars;
	
	this(char[] _chars){
		this._chars = _chars;
	}

	override char[] __chars__(){
		return _chars;
	}

	override string __type__(){
		return "bytes";
	}

	override size_t __length__(){
        return _chars.length;
    }

    override LdOBJECT __index__(LdOBJECT arg){
        return new LdChr([_chars[cast(size_t)arg.__num__]]);
    }

	override string __str__(){
		return cast(string)_chars;
	}

	override double __true__(){
		return cast(double)_chars.length;
	}

	override string __json__(){
        return __str__;
    }
}


class LdHsh: LdOBJECT
{
	LdOBJECT[string] hash;
	
	this(LdOBJECT[string] hash){
		this.hash = hash;
	}

	override LdOBJECT __index__(LdOBJECT arg){
		if (!(arg.__str__ in hash))
			throw new Exception(format("IndexError: '%s' is not in dictionary.", arg.__str__));

		return hash[arg.__str__];
	}

	override void __assign__(LdOBJECT index, LdOBJECT value){
		this.hash[index.__str__] = value;
	}

	override string __type__(){
		return "map";
	}

	override double __true__(){
		return cast(double)hash.length;
	}

	override size_t __length__(){
        return hash.length;
    }

	override string __str__(){
		string view = "{";

		foreach(k, v; hash)
			view ~= format(" %s: %s,", k, v.__json__);

		return chomp(view, ",") ~ " }";
	}

	override LdOBJECT[string] __hash__(){ return hash; }
}


class LdEnum: LdOBJECT
{
	string name; LdOBJECT[string] props;
	
	this(string name, LdOBJECT[string] props){
		this.name = name;
		this.props = props;
	}

	override string __type__(){
		return "enum";
	}

	override HEAP __props__(){ return props; }

	override string __str__(){ return name; }
}


// ARRAYS
class LdArr: LdOBJECT {
	LdOBJECT[] arr;
	HEAP props;
	
	this(LdOBJECT[] arr){
		this.arr = arr;
	}

	override LdOBJECT[]* __ptr__(){
		return &arr;
	}

	override LdOBJECT[] __array__(){
		return this.arr;
	}

	override size_t __length__(){
        return arr.length;
    }

    override string __type__(){
		return "list";
	}

	override double __true__(){
		return cast(double)arr.length;
	}

	override LdOBJECT __index__(LdOBJECT arg){
		return this.arr[cast(size_t)arg.__num__];
	}

	override void __assign__(LdOBJECT index, LdOBJECT value){
		this.arr[cast(size_t)index.__num__] = value;
	}

	override string __str__(){
		return '[' ~ arr.map!(n => n.__json__).join(", ") ~ ']';
	}
}


// STRINGS
class LdStr: LdOBJECT
{
    string _str;
    LdOBJECT[string] props;
    
    this(string _str){
    	this._str = _str;
    }

    override string __str__(){
        return _str;
    }

    override LdOBJECT __index__(LdOBJECT arg){
        return new LdStr(to!string(_str[cast(size_t)arg.__num__]));
    }

    override string __type__(){
    	return "string";
    }

    override size_t __length__(){
        return _str.length;
    }

    override double __true__(){
        return cast(double)_str.length;
    }

    override string __json__(){
    	//const js = JSONValue(_str);
        //return toJSON(js);
        return '\''~_str~'\'';
    }

}
