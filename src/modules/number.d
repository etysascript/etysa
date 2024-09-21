module lNumber;


import std.stdio;
import std.conv: to;

import std.algorithm.searching: canFind;
import std.algorithm.comparison: max, min;

import std.math: round, pow;
import core.stdc.stdlib: strtol;

import std.format: format;
import std.string: isNumeric, toStringz;

import LdObject;



class oNumber: LdOBJECT
{
    LdOBJECT[string] props;

    this(){
        this.props = [
            "max": new _Max(),
            "min": new _Min(),

            "int_str": new _Int_string(),
        ];
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length)
            return toNum(args[0]);
        
        return new LdNum(0);
    }

    override LdOBJECT[string] __props__(){ return props; }

    override string __str__(){ return "number (native module)"; }
}

LdNum toNum(LdOBJECT x){
    if (x.__type__ == "string"){
        string y = x.__str__;

        if (isNumeric(y)){
            double ret = to!double(y);
            return new LdNum(ret); 

        } else {
            throw new Exception(format("ValueError: could not convert string to number: '%s'", y));
        }

    } else if (x.__type__ == "bytes"){
        char[] y = x.__chars__;

        try {
            double ret = to!double(y);
            return new LdNum(ret); 
        
        } catch (Exception e)
            throw new Exception(format("ValueError: could not convert bytes to number: '%c'", y));

    } else if (canFind("boolean number", x.__type__))
        return new LdNum(x.__true__);

    throw new Exception(format("TypeError: argument must be of type ['string', 'bytes', 'boolean'] not: '%s'", x.__type__));

    return null;
}


class _Max: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(max(args[0].__num__, args[1].__num__));
    }
    override string __str__() { return "number.max (method)"; }
}

class _Min: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(min(args[0].__num__, args[1].__num__));
    }
    override string __str__() { return "number.lin (method)"; }
}

class _Int_string: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(strtol(toStringz(args[0].__str__), null, cast(int)args[1].__num__));
    }
    override string __str__() { return "number.int_str (method)"; }
}
