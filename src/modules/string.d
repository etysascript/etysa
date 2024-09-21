module LdString;


import std.stdio;


import std.format: format;
import std.array: array, split, join, replace, replicate;

import std.uni;
import std.string;
import std.conv: to, text;

import std.algorithm.iteration: map, each;
import std.algorithm.searching: endsWith, startsWith, count, find;
import std.algorithm.comparison: cmp;

import LdObject;



class oStr: LdOBJECT
{
    LdOBJECT[string] props;

    this(){
        this.props = [
            "concat": new _Concat(),

            "strip": new _Strip(),
            "l_strip": new _L_Strip(),
            "r_strip": new _R_Strip(),

            "center": new _Center(),
            "l_justify": new _L_Justify(),
            "r_justify": new _R_Justify(),

            "replace": new _Replace(),
            "translate": new _Translate(),

            "split": new _Split(),
            "encode": new _Encode(),

            "join": new _Join(),
            "repeat": new _Repeat(),

            "upcase": new  _UpCase(),
            "lowcase": new  _LowCase(),

            "is_upcase": new  _Is_UpCase(),
            "is_lowcase": new  _Is_LowCase(),

            "caps": new _Capital(),

            "startswith": new _StartsWith(),
            "endswith": new _EndsWith(),

            "count": new _Count(),
            "is_numeric": new _Is_Numeric(),

            "find": new _Find(),
            "format": new _Format(),

            "indexof": new _IndexOf(),
            "index": new _Index(),

            "is_alpha": new _Is_Alpha(),
            "is_number": new _Is_Number(),

            "is_digit": new _Is_Digit(),
            "is_printable": new _Is_Printable(),

            "sort": new _Sort(),
        ];
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length){
            if (args[0].__type__ == "bytes")
                return new LdStr(text(args[0].__chars__));

            return new LdStr(args[0].__str__);
        }
        
        return new LdStr("");
    }

    override LdOBJECT[string] __props__(){ return props; }

    override string __str__(){ return "string (native module)"; }
}


class _Repeat: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(replicate(args[0].__str__, cast(size_t)args[1].__num__));
    }
    override string __str__() { return "string.repeat (method)"; }
}

class _Strip: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (args.length > 1)
            return new LdStr(strip(args[0].__str__, args[1].__str__));
        
        return new LdStr(strip(args[0].__str__));
    }
    override string __str__() { return "string.strip (method)"; }
}

class _L_Strip: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (args.length > 1)
            return new LdStr(stripLeft(args[0].__str__, args[1].__str__));
        
        return new LdStr(stripLeft(args[0].__str__));
    }
    override string __str__() { return "string.l_strip (method)"; }
}

class _R_Strip: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (args.length > 1)
            return new LdStr(stripRight(args[0].__str__, args[1].__str__));
        
        return new LdStr(stripRight(args[0].__str__));
    }
    override string __str__() { return "string.r_strip (method)"; }
}

class _Replace: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr((args[0].__str__).replace(args[1].__str__, args[2].__str__));
    }

    override string __str__() { return "string.replace (method)"; }
}

class _Translate: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        string[dchar] transTable;

        foreach(k, v; args[1].__hash__)
            transTable[k[0]] = v.__str__;

        if(args.length > 2)
            return new LdStr(translate(args[0].__str__, transTable, args[2].__str__));

        return new LdStr(translate(args[0].__str__, transTable));
    }

    override string __str__() { return "string.translate (method)"; }
}

class _Center: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length > 2)
            return new LdStr(center(args[0].__str__, cast(size_t)args[1].__num__, args[2].__str__[0]));

        return new LdStr(center(args[0].__str__, cast(size_t)args[1].__num__));
    }

    override string __str__() { return "string.center (method)"; }
}

class _L_Justify: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length > 2)
            return new LdStr(leftJustify(args[0].__str__, cast(size_t)args[1].__num__, args[2].__str__[0]));

        return new LdStr(leftJustify(args[0].__str__, cast(size_t)args[1].__num__));
    }

    override string __str__() { return "string.l_justify (method)"; }
}

class _R_Justify: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length > 2)
            return new LdStr(rightJustify(args[0].__str__, cast(size_t)args[1].__num__, args[2].__str__[0]));

        return new LdStr(rightJustify(args[0].__str__, cast(size_t)args[1].__num__));
    }

    override string __str__() { return "string.r_justify (method)"; }
}

class _Encode: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdChr(cast(char[])args[0].__str__);
    }

    override string __str__() { return "string.encode (method)"; }
}

class _Split: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        string[] arr;

        if (args.length > 1)
            arr = split(args[0].__str__, args[1].__str__);
        else
            arr = (args[0].__str__).split;

        return new LdArr(cast(LdOBJECT[])arr.map!(n => new LdStr(n)).array);
    }
    override string __str__() { return "string.split (method)"; }
}

class _Concat: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        string x;
        args.each!(i => x~=i.__str__);
        return new LdStr(x);
    }

    override string __str__() { return "string.concat (method)"; }
}

class _Join: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length > 1)
            return new LdStr(args[0].__array__.map!(i => i.__str__).join(args[1].__str__));

        return new LdStr(args[0].__array__.map!(i => i.__str__).join);
    }

    override string __str__() { return "string.join (method)"; }
}

class _UpCase: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(toUpper(args[0].__str__));
    }
    override string __str__() { return "string.upcase (method)"; }
}

class _LowCase: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(toLower(args[0].__str__));
    }
    override string __str__() { return "string.lowcase (method)"; }
}

class _Capital: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(capitalize(args[0].__str__));
    }
    override string __str__() { return "string.caps (method)"; }
}

class _Is_Numeric: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(isNumeric(args[0].__str__))
            return RETURN.B;

        return RETURN.C;
    }
    override string __str__() { return "string.is_numeric (method)"; }
}

class _StartsWith: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if((args[0].__str__).startsWith(args[1].__str__))
            return RETURN.B;

        return RETURN.C;
    }
    override string __str__() { return "string.startswith (method)"; }
}

class _EndsWith: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if((args[0].__str__).endsWith(args[1].__str__))
            return RETURN.B;

        return RETURN.C;
    }
    override string __str__() { return "string.endswith (method)"; }
}

class _Count: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(count(args[0].__str__, args[1].__str__));
    }
    override string __str__() { return "string.count (method)"; }
}

class _Find: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        size_t x = find(args[0].__str__, args[1].__str__).length;

        if (x==0)
            return new LdNum(-1);
        
        return new LdNum((args[0].__str__).length-x);
    }
    override string __str__() { return "string.find (method)"; }
}

class _IndexOf: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(indexOf(args[0].__str__, args[1].__str__));
    }
    override string __str__() { return "string.indexof (method)"; }
}

class _Index: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(args.length > 2)
            return new LdStr((args[0].__str__)[cast(size_t)args[1].__num__ .. cast(size_t)args[2].__num__]);

        return new LdStr(to!string(args[0].__str__[cast(size_t)args[1].__num__]));
    }
    override string __str__() { return "string.index (method)"; }
}

class _Format: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        auto s = split(args[0].__str__, "{}");
        string gen;

        for(size_t i; i < s.length-1; i++)
            gen ~= s[i] ~ args[i+1].__str__;

        gen ~= s[s.length-1];

        return new LdStr(gen);
    }
    override string __str__() { return "string.format (method)"; }
}

class _Is_Alpha: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        foreach(dchar i; args[0].__str__)
            if(!isAlpha(i))
                return RETURN.C;

        return RETURN.B;
    }
    override string __str__() { return "string.is_alpha (method)"; }
}

class _Is_Number: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        foreach(dchar i; args[0].__str__)
            if(!isNumber(i))
                return RETURN.C;

        return RETURN.B;
    }
    override string __str__() { return "string.is_number (method)"; }
}

// C Functions
import core.stdc.ctype: isdigit, isprint, isspace, isupper, islower;

class _Is_LowCase: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        foreach(dchar i; args[0].__str__)
            if(isupper(i))
                return RETURN.C;

        return RETURN.B;
    }
    override string __str__() { return "string.is_lowcase (method)"; }
}

class _Is_UpCase: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        foreach(dchar i; args[0].__str__)
            if(islower(i))
                return RETURN.C;

        return RETURN.B;
    }
    override string __str__() { return "string.is_upcase (method)"; }
}

class _Is_Digit: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        foreach(dchar i; args[0].__str__)
            if(!isdigit(i))
                return RETURN.C;

        return RETURN.B;
    }
    override string __str__() { return "string.is_digit (method)"; }
}

class _Is_Printable: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        foreach(dchar i; args[0].__str__)
            if(!isprint(i))
                return RETURN.C;

        return RETURN.B;
    }
    override string __str__() { return "string.is_printable (method)"; }
}

class _Is_Space: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        foreach(dchar i; args[0].__str__)
            if(!isspace(i))
                return RETURN.C;

        return RETURN.B;
    }
    override string __str__() { return "string.is_space (method)"; }
}


void sort_list(LdOBJECT[] n) {
    if(!n.length)
        return;
    
    LdOBJECT temp;

    for(size_t i = 0; i < (n.length-1); i++){
        size_t n_min = i;

        for(size_t j = i + 1; j < n.length; j++)
            if (cmp(n[j].__str__, n[n_min].__str__) < 0){
                n_min = j;
            }

        if (n_min != i) {
            temp = n[i];
            n[i] = n[n_min];
            n[n_min] = temp;
        }
    }
}


class _Sort: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        sort_list(args[0].__array__);
        return RETURN.B;
    }
    override string __str__() { return "string.sort (method)"; }
}

