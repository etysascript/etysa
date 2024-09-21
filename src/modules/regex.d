module lRegex;


import std.regex: matchAll, regex, split, splitter, replaceAll, matchFirst, replaceFirst, escaper;
import std.algorithm.iteration: each;
import std.typecons : Yes;
import std.conv: to;

import LdObject;


alias LdOBJECT[string] Heap;


class oRegex: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
            "sub": new _Substitute(),
            "search": new _Search(),
            "findall": new _Findall(),
			"split": new _Split(),
            "escape": new _Escape(),
			
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "regex (native module)"; }
}


class _Findall: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        LdOBJECT[] found;
        
        matchAll(args[1].__str__, regex(args[0].__str__)).each!(i => found ~= new LdStr(i.front));

        return new LdArr(found);
    }

    override string __str__() { return "regex.findall (method)"; }
}


class _Split: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        LdOBJECT[] found;

        if (args.length > 2 && args[2].__true__){
            splitter!(Yes.keepSeparators)(args[1].__str__, regex(args[0].__str__)).each!(i => found ~= new LdStr(i));
        
        } else {
            split(args[1].__str__, regex(args[0].__str__)).each!(i => found ~= new LdStr(i));
        }
        
        return new LdArr(found);
    }

    override string __str__() { return "regex.split (method)"; }
}

class _Substitute: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (args.length > 3){
            string sub = args[1].__str__;
            string substitute = args[2].__str__;

            size_t count = cast(size_t)args[3].__num__;
            auto _pattern = regex(args[0].__str__);

            for(size_t i = 0; i < count; i++){
                sub = replaceFirst(sub, _pattern, substitute);
            }

            return new LdStr(sub);
        }

        return new LdStr(replaceAll(args[1].__str__, regex(args[0].__str__), args[2].__str__));
    }

    override string __str__() { return "regex.sub (method)"; }
}


class _Search: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (matchFirst(args[1].__str__, regex(args[0].__str__)).empty)
            return RETURN.C;

        return RETURN.B;
    }

    override string __str__() { return "regex.search (method)"; }
}


class _Escape: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(to!string(escaper(args[0].__str__)));
    }

    override string __str__() { return "regex.escape (method)"; }
}
