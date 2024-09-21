module LdChar;


import std.stdio;
import std.format: format;

import std.array: array;

import std.algorithm.iteration: each, map;
import std.algorithm.mutation: remove, reverse;


import LdObject;


class oBytes: LdOBJECT
{
    LdOBJECT[string] props;

    this(){
        this.props = [
            "append": new _Append(),
            "decode": new _Decode(),

            "index": new _Index(),
        ];
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (!args.length)
            return new LdChr([]);

        return to_lqs_bytes(args[0]);
    }

    override LdOBJECT[string] __props__(){ return props; }

    override string __str__(){ return "bytes (native module)"; }
}


LdOBJECT to_lqs_bytes(LdOBJECT i) {
    if (i.__type__ == "string")
        return new LdChr(cast(char[])i.__str__);

    else if (i.__type__ == "list")
        return new LdChr(cast(char[])(i.__array__).map!(x => cast(ubyte)x.__num__).array);

    return i;
}



class _Decode: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(cast(string)(args[0].__chars__));
    }
    override string __str__() { return "bytes.decode (method)"; }
}

class _Append: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	char[] y;
    	args.each!(n => y ~= n.__chars__);

        return new LdChr(y);
    }

    override string __str__() { return "bytes.append (method)"; }
}


class _Index: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length > 2)
            return new LdChr((args[0].__chars__)[cast(size_t)args[1].__num__ .. cast(size_t)args[2].__num__]);

        return new LdChr([args[0].__chars__[cast(size_t)args[1].__num__]]);
    }

    override string __str__() { return "bytes.index (method)"; }
}



