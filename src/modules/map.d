module lMap;


import std.algorithm;
import std.array;
import std.range;

import LdObject;



class oMap: LdOBJECT
{
    LdOBJECT[string] props;

    this(){
        this.props = [
            "copy": new _Copy(),
            "keys": new _Keys(),

            "get": new _Get(),
            "values": new _Values(),

            "clear": new _Clear(),
            "pop": new _Pop(),

            "update": new _Update(),
            "rehash": new _Rehash(),

            "has": new _Has(),
        ];
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdHsh(assocArray(zip(args[0].__array__.map!(i => i.__str__), args[1].__array__)));
    }

    override LdOBJECT[string] __props__(){ return props; }

    override string __type__(){ return "builtin module"; }

    override string __str__(){ return "Map (builtin module)"; }
}


class _Clear: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        clear(args[0].__hash__);
        return RETURN.A;
    }
    override string __str__() { return "Map.clear (method)"; }
}

class _Get: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return (args[0].__hash__).get(args[1].__str__, RETURN.A);
    }
    override string __str__() { return "Map.get (method)"; }
}

class _Pop: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        auto pop = args[0].__hash__[args[1].__str__];
        (args[0].__hash__).remove(args[1].__str__);

        return pop;
    }

    override string __str__() { return "Map.pop (method)"; }
}

class _Update: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        auto dt = args[0].__hash__;
        args[1].__hash__.keys().each!(i => dt[i] = args[1].__hash__[i]);
        
        rehash(dt);
        return RETURN.A;
    }

    override string __str__() { return "Map.update (method)"; }
}

class _Copy: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdHsh(args[0].__hash__.dup);
        return RETURN.A;
    }

    override string __str__() { return "Map.copy (method)"; }
}

class _Keys: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdArr(cast(LdOBJECT[])(args[0].__hash__.keys).map!(a => new LdStr(a)).array);
    }

    override string __str__() { return "Map.keys (method)"; }
}

class _Values: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdArr(args[0].__hash__.values());
    }

    override string __str__() { return "Map.values (method)"; }
}

class _Rehash: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        rehash(args[0].__hash__);
        return RETURN.A;
    }

    override string __str__() { return "Map.rehash (method)"; }
}

class _Has: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (args[1].__str__ in args[0].__hash__)
            return RETURN.B;

        return RETURN.C;
    }

    override string __str__() { return "Map.has (method)"; }
}