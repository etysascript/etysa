module LdBytes2;


import std.conv;
import std.stdio;

import core.stdc.stdlib;

import std.algorithm.iteration: map;
import std.algorithm.searching: find;
import std.format: format;
import std.array: array, join;

import LdObject, LdType, LdBytes;

import LdNode: TRACE;
import importlib: TRACEBACK;


alias LdOBJECT[string] HEAP;


// NUMBERS 1  1.5 100_000

class Op_Num: LdByte {
	LdOBJECT _num;

	this(double number){
		this._num = new LdNum(number);
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return this._num;
	}
}

class Op_Add: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(left(_heap).__num__ + right(_heap).__num__);
	}
}

class Op_Minus: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(left(_heap).__num__ - right(_heap).__num__);
	}
}

class Op_Times: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(left(_heap).__num__ * right(_heap).__num__);
	}
}

class Op_Divide: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(left(_heap).__num__ / right(_heap).__num__);
	}
}

class Op_Remainder: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(left(_heap).__num__ % right(_heap).__num__);
	}
}

class Op_Equals: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (left(_heap).__str__ == right(_heap).__str__)
			return RETURN.B;

		return RETURN.C;
	}
}

class Op_Less: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (left(_heap).__num__ < right(_heap).__num__)
			return RETURN.B;

		return RETURN.C;
	}
}

class Op_Great: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (left(_heap).__num__ > right(_heap).__num__)
			return RETURN.B;

		return RETURN.C;
	}
}

class Op_Lequals: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (left(_heap).__num__ <= right(_heap).__num__)
			return RETURN.B;

		return RETURN.C;
	}
}

class Op_Gequals: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (left(_heap).__num__ >= right(_heap).__num__)
			return RETURN.B;

		return RETURN.C;
	}
}

class Op_B_AND: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(((cast(int)left(_heap).__num__)) & (cast(int)(right(_heap).__num__)));
	}
}

class Op_B_OR: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(((cast(int)left(_heap).__num__)) | (cast(int)(right(_heap).__num__)));
	}
}

class Op_B_XOR: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(((cast(int)left(_heap).__num__)) ^ (cast(int)(right(_heap).__num__)));
	}
}

class Op_B_Lshift: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(((cast(int)left(_heap).__num__)) << (cast(int)(right(_heap).__num__)));
	}
}

class Op_B_Rshift: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return new LdNum(((cast(int)left(_heap).__num__)) >> (cast(int)(right(_heap).__num__)));
	}
}


class Op_NOTequals: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (left(_heap).__str__ != right(_heap).__str__)
			return RETURN.B;

		return RETURN.C;
	}
}



// STRINGS 'hello', "world"

class Op_Str: LdByte {
	LdOBJECT _str;

	this(string st){
		this._str = new LdStr(st);
	}

	override LdOBJECT opCall(HEAP* _heap) {
		return _str;
	}
}


class Op_Array: LdByte {
	LdByte[] items;

	this(LdByte[] items){
		this.items = items;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		LdOBJECT[] arr;

		foreach(LdByte i; items)
			arr ~= i(_heap);

		return new LdArr(arr);
	}
}


// HASH  {.:.}

class Op_Hash: LdByte {
	string[] keys;
	LdByte[] values;

	this(string[] keys, LdByte[] values){
		this.keys = keys;
		this.values = values;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		LdOBJECT[string] hash;

		for(int i = 0; i < keys.length; i++)
			hash[keys[i]] = values[i](_heap);

		return new LdHsh(hash);
	}
}

class Op_IfAssign: LdByte {
	LdByte[3] keys;

	this(LdByte[3] keys){
		this.keys = keys;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if (keys[0](_heap).__true__)
			return keys[1](_heap);

		return keys[2](_heap);
	}
}


// ENUM  {.=.}

class Op_Enum: LdByte {
	string[] keys;
	LdByte[] values;

	this(string[] keys, LdByte[] values){
		this.keys = keys;
		this.values = values;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		LdOBJECT[string] hash;
		string name;

		for(int i = 0; i < keys.length; i++)
			hash[keys[i]] = values[i](_heap);

		return new LdEnum(format("Enum(%s)", join(keys, ", ")), hash);
	}
}


// INDEXING [1,'a'][1]  x[2] = 1

class Op_Index_Iterator: LdByte {
	int line;
	LdByte value, index;

	this(LdByte value, LdByte index, int line){
		this.value = value;
		this.index = index;
		this.line = line;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		auto data = value(_heap);

		if (data.__type__ == "map") {
			string key = index(_heap).__str__;

			if (key in data.__hash__)
				return data.__hash__[key];

			TRACE error_tracks = {(*_heap)["-file-"].__str__, this.line, "KeyError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("'%s' is not a key in the 'map'.", key));
		}

		auto index_pos = index(_heap).__num__;
		auto keep_old_index = index_pos;

		auto len = data.__length__;

		// [negative]--> [...][-1] index to end position like py.
		if(index_pos < 0)
			index_pos = len + index_pos;

		// -a & big index error
		if ((index_pos >= len) | (index_pos < 0)) {
			TRACE error_tracks = {(*_heap)["-file-"].__str__, this.line, "IndexError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("'%s' is out of '%s' range.", keep_old_index, data.__type__));
		}

		return data.__index__(new LdNum(index_pos));
	}
}

class Op_Index_Iterator_Exec: LdByte {
	int line;
	string sign;
	LdByte key, index, value;

	this(LdByte[3] data, string sign, int line){
		this.key = data[0];
		this.index = data[1];
		this.value = data[2];

		this.line = line;
		this.sign = sign;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		LdOBJECT ety_key = key(_heap);
		
		if (ety_key.__type__ == "list"){
			size_t index_pos = cast(size_t)index(_heap).__num__;
			size_t keep_old_index = index_pos;

			auto len = ety_key.__length__;

			// [negative]--> [...][-1] index to end position like py.
			if(index_pos < 0)
				index_pos = len + index_pos;

			// ensure neg and greater index are thrown
			if ((index_pos >= len) | (index_pos < 0)){
				TRACE error_tracks = {(*_heap)["-file-"].__str__, this.line, "IndexError"};
				TRACEBACK ~= error_tracks;

				throw new Exception(format("'%s' is out of '%s' range.", keep_old_index, ety_key.__type__));
			}

			// new data
			LdOBJECT Ndata = this.value(_heap);

			if (this.sign == "=")
				ety_key.__array__[index_pos] = Ndata;
			else {
				// old/present data
				LdOBJECT Odata = ety_key.__array__[index_pos];

				if (sign == "+")
					ety_key.__array__[index_pos] = new LdNum(Odata.__num__ + Ndata.__num__);

				else if (sign == "-")
					ety_key.__array__[index_pos] = new LdNum(Odata.__num__ - Ndata.__num__);

				else if (sign == "*")
					ety_key.__array__[index_pos] = new LdNum(Odata.__num__ * Ndata.__num__);

				else if (sign == "/")
					ety_key.__array__[index_pos] = new LdNum(Odata.__num__ / Ndata.__num__);
			}

		// handling changing dictionary data
		} else if (ety_key.__type__ == "map"){

			if (this.sign == "=")
				ety_key.__hash__[index(_heap).__str__] = this.value(_heap);

			else {
				string map_key = index(_heap).__str__;

				if (!(map_key in ety_key.__hash__)){
					TRACE error_tracks = {(*_heap)["-file-"].__str__, this.line, "KeyError"};
					TRACEBACK ~= error_tracks;

					throw new Exception(format("'%s' is not a key in the 'map'.", map_key));
				}

				LdOBJECT Ndata = this.value(_heap);

				// old/present data
				LdOBJECT Odata = ety_key.__hash__[map_key];

				if (sign == "+")
					ety_key.__hash__[map_key] = new LdNum(Odata.__num__ + Ndata.__num__);

				else if (sign == "-")
					ety_key.__hash__[map_key] = new LdNum(Odata.__num__ - Ndata.__num__);

				else if (sign == "*")
					ety_key.__hash__[map_key] = new LdNum(Odata.__num__ * Ndata.__num__);

				else if (sign == "/")
					ety_key.__hash__[map_key] = new LdNum(Odata.__num__ / Ndata.__num__);
			}

		// incase not a dictionary or a list
		} else{
			TRACE error_tracks = {(*_heap)["-file-"].__str__, this.line, "TypeError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("type '%s' does not supprt index assigning.", ety_key.__type__));
		}

		return RETURN.A;
	}
}


class Op_Index_Iterator_Multi: LdByte {
	int line;
	short kind;
	LdByte value;
	LdByte[2] index;

	this(LdByte value, short kind, LdByte[2] index, int line){
		this.value = value;
		this.index = index;
		this.kind = kind;
		this.line = line;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		size_t start, end;

		LdOBJECT data = value(_heap);
		size_t len = data.__length__;

		if (kind == 1){
			start = cast(size_t)(index[0](_heap).__num__);
			end = cast(size_t)(index[1](_heap).__num__);

		} else if (kind == 2){
			start = 0;
			end = cast(size_t)(index[0](_heap).__num__);

		} else {
			start = cast(size_t)(index[0](_heap).__num__);
			end = len;
		}

		// incase a[-1] like python.
		if(start < 0) { start = len + start;}
		if(end < 0) { end = len + end; }

		if((start < 0) | (start > len)) { start = 0;}
		if((end < 0) | (end < start)) { end = len;}

		if (data.__type__ == "list")
			return new LdArr(data.__array__[start..end]);

		else if (data.__type__ == "string")
			return new LdStr(data.__str__[start..end]);

		else if (data.__type__ == "bytes")
			return new LdChr(data.__chars__[start..end]);

		else {
			TRACE error_tracks = {(*_heap)["-file-"].__str__, this.line, "IndexError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("type '%s' cannot be indexed.", data.__type__));
		}

		return data.__index__(new LdNum(start));
	}
}


class Op_PiAssign: LdByte {
	LdByte key, index, value;

	this(LdByte key, LdByte index, LdByte value){
		this.key = key;
		this.index = index;
		this.value = value;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		key(_heap).__assign__(index(_heap), value(_heap));
		return RETURN.A;
	}
}


class Op_Pobj: LdByte {
	string name, file;
	string[] props;
	LdByte[] herits, code;

	this(string name, string file, LdByte[] herits, string[] props, LdByte[] code){
		this.name = name;
		this.file = file;
		this.code = code;
		this.props = props;
		this.herits = herits;
	}

	override LdOBJECT opCall(HEAP* _heap){
		LdOBJECT[] inherits;

		foreach(LdByte i; herits)
			inherits ~= i(_heap);

		return new LdTyp(name, file, inherits, props, code, *_heap);
	}
}


// GETTING ATTRIBUTE x.y x.y = 3

class Op_Pdot: LdByte {
	uint line;
	LdByte obj;
	string prop;

	this(LdByte obj, string prop, uint line){
		this.obj = obj;
		this.prop = prop;
		this.line = line;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		auto data = obj(_heap);

		if(prop in data.__props__)
			return data.__props__[prop];
		else {
			TRACE error_tracks = {(*_heap)["-file-"].__str__, this.line, "ReferenceError"};
			TRACEBACK ~= error_tracks;

			throw new Exception(format("%s has no attribute '%s'", data.__type__, prop));
		}

		return RETURN.A;
	}
}

class Op_Pdot_2: LdByte {
	string key;
	LdByte[] args;

	this(string key, LdByte[] args){
		this.key = key;
		this.args = args;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		auto fn = (*_heap)[key];
		LdOBJECT[] par = args.map!(i => i(_heap)).array;

		return fn(par);
	}
}


class Op_PdotAssign: LdByte {
	LdByte obj, value;
	string prop;

	this(LdByte obj, string prop, LdByte value){
		this.obj = obj;
		this.prop = prop;
		this.value = value;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		obj(_heap).__setProp__(prop, value(_heap));
		return RETURN.A;
	}
}


// BOOLEANS  true false and none

class Op_True: LdByte {
	override LdOBJECT opCall(HEAP* _heap) {
		return RETURN.B;
	}
}

class Op_False: LdByte {
	override LdOBJECT opCall(HEAP* _heap) {
		return RETURN.C;
	}
}

class Op_None: LdByte {
	override LdOBJECT opCall(HEAP* _heap) {
		return RETURN.A;
	}
}


// NOT OR and AND

class Op_Not: LdByte {
	LdByte value;

	this(LdByte value){
		this.value = value;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if(!value(_heap).__true__)
			return RETURN.B;

		return RETURN.C;
	}
}

class Op_Or: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		auto firstOption = left(_heap);

		if (firstOption.__true__)
			return firstOption;

		return right(_heap);
	}
}

class Op_And: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		auto option = left(_heap);

		if (!(option.__true__))
			return option;

		return right(_heap);
	}
}

class Op_In: LdByte {
	LdByte left, right;

	this(LdByte left, LdByte right){
		this.left = left;
		this.right = right;
	}

	override LdOBJECT opCall(HEAP* _heap) {
		if(find(right(_heap).__str__, left(_heap).__str__).length)
			return RETURN.B;

		return RETURN.C;
	}
}

