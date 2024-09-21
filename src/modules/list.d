module lList;


import std.stdio;
import std.conv: to;

import std.algorithm.mutation: remove, reverse;
import std.algorithm.searching: any;
import std.algorithm.sorting: sort;
import std.algorithm.iteration: map;

import std.array: insertInPlace, array;

import LdObject;



class oList: LdOBJECT
{
    LdOBJECT[string] props;

    this(){
        this.props = [
            "join": new _Join(),
            "extend": new _Extend(),

            "append": new _Append(),

            "clear": new _Clear(),
            "copy": new _Copy(),
            
            "insert": new _Insert(),
            "pop": new _Pop(),
            
            "index": new _Index(),
            "reverse": new _Reverse(),

            "sort": new _Sort(),
            "contains": new _Contains(),
        ];
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (!args.length)
            return new LdArr([]);

        return to_lqs_list(args[0]);
    }

    override LdOBJECT[string] __props__(){ return props; }

    override string __str__(){ return "list (native module)"; }
}

LdOBJECT to_lqs_list(LdOBJECT i){
    if (i.__type__ == "string")
        return new LdArr(cast(LdOBJECT[])(i.__str__).map!(x => new LdStr(to!string(x))).array);

    else if (i.__type__ == "bytes")
        return new LdArr(cast(LdOBJECT[])(i.__chars__).map!(x => new LdNum(x)).array);

    else if (i.__type__ == "dict")
        return new LdArr(cast(LdOBJECT[])(i.__hash__.keys).map!(x => new LdStr(x)).array);

    return i;
}



class _Join: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){ 
       	// adds and returns a new list
        return new LdArr(*(args[0].__ptr__) ~ *(args[1].__ptr__));
    }

    override string __str__() { return "list.join (method)"; }
}

class _Extend: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        // appends 2nd array to 1st array
        *(args[0].__ptr__) ~= *(args[1].__ptr__);
        return RETURN.A;
    }

    override string __str__() { return "list.extend (method)"; }
}

class _Insert: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	auto x = args[0].__array__;
        x.insertInPlace(cast(size_t)args[1].__num__, args[2]);

        *(args[0].__ptr__) = x;
        return RETURN.A;
    }

    override string __str__() { return "list.insert (method)"; }
}

class _Append: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	LdOBJECT[] *l = args[0].__ptr__;
    	*l ~= args[1];

		return RETURN.A;
    }

    override string __str__() { return "list.append (method)"; }
}

class _Index: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length > 2)
            return new LdArr((*(args[0].__ptr__))[cast(size_t)args[1].__num__ .. cast(size_t)args[2].__num__]);

        return (*(args[0].__ptr__))[cast(size_t)args[1].__num__];
    }

    override string __str__() { return "list.index (method)"; }
}


class _Clear: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	auto l = args[0].__ptr__;
    	(*l).length = 0;

		return RETURN.A;
    }

    override string __str__() { return "list.clear (method)"; }
}

class _Copy: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		return new LdArr(args[0].__array__.dup);
    }

    override string __str__() { return "list.copy (method)"; }
}

class _Reverse: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		reverse(args[0].__array__);
		return RETURN.A;
    }

    override string __str__() { return "list.reverse (method)"; }
}

class _Pop: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	LdOBJECT[] *l = args[0].__ptr__;
    	size_t i;

    	if (args.length > 1)
    		i = cast(size_t)args[1].__num__;
    	else
    		i = cast(size_t)((*l).length)-1;

        // keeping popped item
		auto popped = (*l)[i];
		remove(*l, i);

        // setting array to its new length
		(*l).length--;

		return popped;
    }

    override string __str__() { return "list.pop (method)"; }
}


void sorter(LdOBJECT[] n) {
    if(!n.length)
        return;
    
    LdOBJECT temp;
    
    for(size_t i = 0; i < (n.length-1); i++){
        size_t n_min = i;

        for(size_t j = i + 1; j < n.length; j++)
            if (n[j].__num__ < n[n_min].__num__)
                n_min = j;

        if (n_min != i) {
            temp = n[i];
            n[i] = n[n_min];
            n[n_min] = temp;
        }
    }
}

class _Sort: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        sorter(args[0].__array__);
        return RETURN.A;
    }

    override string __str__() { return "list.pop (method)"; }
}



class _Contains: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        //auto l = args[0].__array__;
        auto key = args[1];
        string _type = key.__type__;

        foreach(LdOBJECT i; args[0].__array__) {
            if (i.__type__ == _type && i.__str__ == key.__str__)
                return RETURN.B;       
        }

        return RETURN.C;
    }

    override string __str__() { return "list.contains (method)"; }
}

