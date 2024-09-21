module lPromises;

import std.parallelism;

import std.conv: to;
import std.stdio: writeln;

import LdObject;
alias LdOBJECT[string] Heap;



class oPromises: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
			"Promise": new _Promise(),
			"promisesThreads": new _PromisesThreads(),
			"promisesQueue": new _PromisesQueue(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "promises (native module)"; }
}


class _PromisesThreads: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	if (!args.length)
    		return new LdNum(defaultPoolThreads());

    	defaultPoolThreads(cast(uint)(args[0].__num__));
    	return RETURN.A;
    }

    override string __str__() { return "promises.promisesThreads (method)"; }
}


class _Promise: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		return new _iPromise(args);
    }

    override string __type__() { return "promises.Promise"; }
    override string __str__() { return "promises.Promise (type)"; }
}


LdOBJECT fnWrapper(LdOBJECT[] fn){
	LdOBJECT[] args;

	if (fn.length > 1)
		args = fn[1].__array__;

	return fn[0](args);
}


class _iPromise: LdOBJECT
{
	Heap props;

	this(LdOBJECT[] args){
		auto promise = task!fnWrapper(args);

		class _iStart: LdOBJECT {
			override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
				promise.executeInNewThread(); return RETURN.A;
		    }
			override string __str__(){ return "start (promises.Promise method)";  }
		}

		class _iFetch: LdOBJECT {
			override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
				if (args.length) {
					switch (args[0].__str__){
						case "spin":
							return promise.spinForce();
						case "work":
							return promise.workForce();
						default:
							break;
					}
				}
				return promise.yieldForce;
		    }
			override string __str__(){ return "fetch (promises.Promise method)";  }
		}

		class _iQueue: LdOBJECT {
			override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
				taskPool.put(promise);
				return RETURN.A;
		    }
			override string __str__(){ return "queue (promises.Promise method)";  }
		}

		class _iCompleted: LdOBJECT {
			override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
				taskPool.put(promise);
				return RETURN.A;
		    }
			override string __str__(){ return "completed (promises.Promise method)";  }
		}

		this.props = [
			"start": new _iStart(),
			"fetch": new _iFetch(),
			"queue": new _iQueue(),
			"completed": new _iCompleted(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }
	override string __type__() { return "promises.Promise"; }
	override string __str__(){ return "promises.Promise (object)";  }
}


class _PromisesQueue: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
			"complete": new _qComplete(),
			"stop": new _qStop(),
			"size": new _qSize(),
		];
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		return this;
	}

	override LdOBJECT[string] __props__(){ return props; }
	override string __str__(){ return "promises.promisesQueue (object)";  }
}


class _qComplete: LdOBJECT {
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		bool executeAll = true;

		if (args.length)
			executeAll = cast(bool)args[0].__true__;

		taskPool.finish(executeAll);
		return RETURN.A;
    }
	override string __str__(){ return "complete (promises.promiseQueue method)";  }
}

class _qStop: LdOBJECT {
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		taskPool.stop();
		return RETURN.A;
    }
	override string __str__(){ return "stop (promises.promiseQueue method)";  }
}

class _qSize: LdOBJECT {
	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		return new LdNum(taskPool.size);
    }
	override string __str__(){ return "size (promises.promiseQueue method)";  }
}

