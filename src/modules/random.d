module lRandom;


import std.random: randomShuffle, uniform, randomSample, choice;
import std.algorithm.iteration: each;

import LdObject;


alias LdOBJECT[string] Heap;


class oRandom: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
			"shuffle": new _Shuffle(),
			"sample": new _Sample(),

			"random": new _Random(),
			"uniform": new _Uniform(),


			"pick": new _Pick(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "random (native module)"; }
}




class _Pick: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	return choice(args[0].__array__);
    }

    override string __str__() { return "random.pick (method)"; }
}



class _Sample: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	LdOBJECT[] arr;

    	randomSample(randomShuffle(args[0].__array__.dup), cast(int)args[1].__num__).each!(i => arr ~= i);

        return new LdArr(arr);
    }

    override string __str__() { return "random.sample (method)"; }
}

class _Shuffle: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        randomShuffle(args[0].__array__);
        return  RETURN.A;
    }

    override string __str__() { return "random.shuffle (method)"; }
}

class _Random: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(uniform(0.0000000001, 1));
    }

    override string __str__() { return "random.random (method)"; }
}

class _Uniform: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(uniform(args[0].__num__, args[1].__num__));
    }

    override string __str__() { return "random.uniform (method)"; }
}
