module lThread;

import std.stdio;
import std.concurrency; 
import core.thread;

import std.format: format;
import LdObject;


alias LdOBJECT[string] Heap;


class oThread: LdOBJECT
{
    uint thread_count;
	Heap props;

	this(){
        this.thread_count = 0;

		this.props = [
            "Thread": new _Thread(this),
            "thread_count": new _thread_count(this),
		];
	}

    override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "thread (core module)"; }
}


class _thread_count: LdOBJECT {
    oThread base;

    this(oThread base){
        this.base = base;
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(this.base.thread_count);
    }

    override string __str__() { return "thread_count (thread method)"; }
}


class _Thread: LdOBJECT {
    oThread base;

    this(oThread base){
        this.base = base;
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){

        synchronized {
            auto new_thread = new Thread_obj(this.base.thread_count, new Thread({
                args[0](args[1].__array__, line, mem);
            }));

            this.base.thread_count+=1;

            return new_thread;
        }

        return RETURN.A;
    }

    override string __str__() { return "Thread (thread type)"; }
}


class Thread_obj: LdOBJECT {
    Thread th;
    Heap props;

    this(uint count, Thread th){
        this.th = th;
        this.props = [
            "start": new _Th_start(th),
            "join": new _Th_join(th),

            "sleep": new _Th_sleep(th),
            "is_alive": new _Th_is_alive(th),

            "name": new LdStr(format("thread-%d", count)),
        ];
    }

    override LdOBJECT[string] __props__(){ return props; }
 
    override string __str__() { return "Thread (thread object)"; }
}


class _Th_start: LdOBJECT {
    Thread th;
    this(Thread th){
        this.th = th;
    }
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        synchronized {
            th.start();
        }
        return RETURN.B;
    }

    override string __str__() { return "start (thread.Thread method)"; }
}

class _Th_join: LdOBJECT {
    Thread th;
    this(Thread th){
        this.th = th;
    }
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        synchronized {
            th.join(true);
        }
        return RETURN.B;
    }

    override string __str__() { return "join (thread.Thread method)"; }
}

class _Th_is_alive: LdOBJECT {
    Thread th;
    this(Thread th){
        this.th = th;
    }
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if(th.isRunning)
            return RETURN.B;
        return RETURN.C;
    }
    override string __str__() { return "is_alive (thread.Thread method)"; }
}

class _Th_sleep: LdOBJECT {
    Thread th;
    this(Thread th){
        this.th = th;
    }
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        synchronized {
            th.sleep(dur!"msecs"(cast(int)args[0].__num__));
        }

        return RETURN.A;
    }
    override string __str__() { return "sleep (thread.Thread method)"; }
}






