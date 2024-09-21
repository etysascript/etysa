module lProcess;

import std.process;
import std.array: split;
import std.string: toStringz;
import std.format: format;
import std.file: readText;
import std.stdio;

import LdObject;

alias LdOBJECT[string] Heap;


class oSubProcess: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
            "run": new _Run(),
            "Popen": new _Popen(),
            "browse": new _Browse(),
            "pid": new LdNum(thisProcessID),

            "spawn": new _Spawn(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "process (core module)"; }
}


class _Run: LdOBJECT  {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	string env = null;

        auto ps = execute(split(args[0].__str__));
        
        return new LdEnum(format("%d(%s)", ps.status, args[0].__str__), ["status": new LdNum(ps.status), "output": new LdStr(ps.output)]);
    }

    override string __str__() { return "process.run (method)"; }
}

class _Browse: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	browse(args[0].__str__);
    	return RETURN.A;
    }

    override string __str__() { return "process.browse (method)"; }
}

class _Wait: LdOBJECT {
	Pid pid;
	this(Pid pid){ this.pid = pid; }

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		return new LdNum(wait(this.pid));
	}

	override string __str__(){ return "Popen.wait (process method)"; }
}

class _Kill: LdOBJECT {
	Pid pid;
	this(Pid pid){ this.pid = pid; }

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		if(args.length)
			kill(this.pid, cast(int)args[0].__num__);
		else
			kill(this.pid);

		return RETURN.A;
	}

	override string __str__(){ return "Popen.kill (process method)"; }
}

class _Fetch: LdOBJECT {
	Pid pro;
	string output, err;

	this(Pid pro, string[] files){
		this.output = files[0];
		this.err = files[1];
		this.pro = pro;
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		try
			return new LdArr([new LdStr(readText(output)), new LdStr(readText(err))]);
		catch (Exception e) {}

		return new LdArr([RETURN.A, RETURN.A]);
	}

	override string __str__(){ return "Popen.fetch (process method)"; }
}



class _Pro: LdOBJECT {
	Heap props;
	File[string] files;

	this(Pid pro, File[string] files){
		this.props = [
            "kill": new _Kill(pro),
            "wait": new _Wait(pro),
            "fetch": new _Fetch(pro, [files["stdout"].name, files["stderr"].name]),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

    override string __str__() { return "process.Popen (object)"; }
}


class _Popen: LdOBJECT {
	double shell;
	File[string] files;

	this(){
		this.files = ["stdin": stdin, "stderr": stderr, "stdout": stdout];
        this.shell = 0;
	}

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        string cmd = args[0].__str__;

        if (args.length > 1 && args[1].__type__ == "enum") {
            auto opt = args[1].__props__;

            foreach (string i; opt.keys()){
                if (i in this.files)
                    this.files[i] = File(opt[i].__str__, "w+");
                    
                else if (i == "shell")
                    this.shell = opt[i].__true__;
            }
        }

        if (this.shell)
            return new _Pro(spawnShell(cmd, files["stdin"], files["stdout"], files["stderr"]), files);

        return new _Pro(spawnProcess(split(cmd), files["stdin"], files["stdout"], files["stderr"]), files);
    }

    override string __str__() { return "process.Popen (method)"; }
}


class _Spawn: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new _PID(spawnProcess(split(args[0].__str__)));
    }

    override string __str__() { return "process.spawn (type)"; }
    override string __type__() { return "process.spawn"; }
}

class _PID: LdOBJECT {
	Heap props;

	this(Pid pid){
		this.props = [
            "kill": new _spawn_Kill(pid),
            "wait": new _spawn_Wait(pid),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

    override string __str__() { return "process.spawn (object)"; }
    override string __type__() { return "process.spawn"; }
}


class _spawn_Wait: LdOBJECT {
	Pid pid;
	this(Pid pid){ this.pid = pid; }

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		return new LdNum(wait(this.pid));
	}

	override string __str__(){ return "process.spawn.wait (process method)"; }
}

class _spawn_Kill: LdOBJECT {
	Pid pid;
	this(Pid pid){ this.pid = pid; }

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
		if(args.length)
			kill(this.pid, cast(int)args[0].__num__);
		else
			kill(this.pid);

		return RETURN.A;
	}

	override string __str__(){ return "process.spawn.kill (process method)"; }
}
