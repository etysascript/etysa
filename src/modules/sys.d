module lSys;

import std.file: getcwd, thisExePath;
import std.path: buildPath, dirName;
import std.stdio;

import LdObject;


alias LdOBJECT[string] HEAP;


class oSys: LdOBJECT
{
	HEAP props;

	this(string[] argv, LdOBJECT Modules){
		this.props = [
			"get_var": new Getvar(),
			"set_var": new Setvar(),

			"argv": Getargv(argv),
			"path": Getpath(),

			"modules_path": Modules,
			"executable": new LdStr(thisExePath),

		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "sys (native module)"; }
}



LdOBJECT Getargv(string[] arg)
{
	LdOBJECT[] arr;

	foreach(i; arg)
		arr ~= new LdStr(i);

	return new LdArr(arr);
}

LdOBJECT Getpath()
{
	return new LdArr([new LdStr(""), new LdStr(getcwd()), new LdStr(buildPath(getcwd(), "etysa_modules")), new LdStr(buildPath(dirName(thisExePath), "etysa_modules"))]);
}

class Getvar: LdOBJECT
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
    	return (*mem)[args[0].__str__];
    }

    override string __str__() { return "sys.get_var (method)"; }
}

class Setvar: LdOBJECT
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
    	(*mem)[args[0].__str__] = args[1];
    	return RETURN.A;
    }

    override string __str__() { return "sys.set_var (method)"; }
}
