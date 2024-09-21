module lConcurrency;

import std.stdio;
import std.concurrency;

import LdObject;


alias LdOBJECT[string] Heap;


class oConcurrency: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
			"send": new _Send(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "concurrency (native module)"; }
}




class _Pick: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	return choice(args[0].__array__);
    }

    override string __str__() { return "concurrency.spawn (method)"; }
}

