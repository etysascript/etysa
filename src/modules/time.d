module lTime;

import core.thread.osthread: Thread;
import std.format: format;
import std.conv: to;
import std.string: chomp;
import std.stdio;

import core.time: dur;
import core.stdc.time;

import LdObject;


alias LdOBJECT[string] Heap;


class oTime: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
			"sleep": new _sleep(),

            "time": new _time(),
            "ctime": new _ctime(),

            "mktime": new _mktime(),
            "asctime": new _asctime(),
            "difftime": new _difftime(),

            "gmtime": new _gmtime(),
            "localtime": new _localtime(),

            "clock": new _clock(),
            "CLOCKS_PER_SEC": new LdNum(CLOCKS_PER_SEC),
		];
	}

    override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "time (builtin module)"; }
}


class _localtime: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        time_t local_T = cast(time_t)(args[0].__num__);
        tm* date = localtime(&local_T);

        return new LdEnum(format("tm(year=%d, mon=%d, mday=%d, hour=%d, min=%d, sec=%d, wday=%d, yday=%d, isdst=%d)", date.tm_year, date.tm_mon, date.tm_mday, date.tm_hour, date.tm_min, date.tm_sec, date.tm_wday, date.tm_yday, date.tm_isdst), [
                "year": new LdNum(date.tm_year),
                "mon": new LdNum(date.tm_mon),
                "mday": new LdNum(date.tm_mday),
                "yday": new LdNum(date.tm_yday),
                "wday": new LdNum(date.tm_wday),
                "hour": new LdNum(date.tm_hour),
                "min": new LdNum(date.tm_min),
                "sec": new LdNum(date.tm_sec),
                "isdst": new LdNum(date.tm_isdst),
            ]);
    }

    override string __str__() { return "localtime (time method)"; }
}

class _gmtime: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        time_t rw = cast(time_t)args[0].__num__;
        tm* date = gmtime(&rw);

        return new LdEnum(format("tm(year=%d, mon=%d, mday=%d, hour=%d, min=%d, sec=%d, wday=%d, yday=%d, isdst=%d)", date.tm_year, date.tm_mon, date.tm_mday, date.tm_hour, date.tm_min, date.tm_sec, date.tm_wday, date.tm_yday, date.tm_isdst), [
                "year": new LdNum(date.tm_year),
                "mon": new LdNum(date.tm_mon),
                "mday": new LdNum(date.tm_mday),
                "yday": new LdNum(date.tm_yday),
                "wday": new LdNum(date.tm_wday),
                "hour": new LdNum(date.tm_hour),
                "min": new LdNum(date.tm_min),
                "sec": new LdNum(date.tm_sec),
                "isdst": new LdNum(date.tm_isdst),
            ]);
    }

    override string __str__() { return "gmtime (time method)"; }
}

class _clock: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(clock());
    }

    override string __str__() { return "clock (time method)"; }
}

class _mktime: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){

        tm st;  // tm* timeptr struct
        long stamp;

        foreach(k, v; args[0].__hash__) {
            switch (k) {
                case "year":
                    st.tm_year = cast(int)v.__num__;
                    break;
                case "mon":
                    st.tm_mon = cast(int)v.__num__;
                    break;
                case "mday":
                    st.tm_mday = cast(int)v.__num__;
                    break;
                case "hour":
                    st.tm_hour = cast(int)v.__num__;
                    break;
                case "min":
                    st.tm_min = cast(int)v.__num__;
                    break;
                case "sec":
                    st.tm_sec = cast(int)v.__num__;
                    break;
                case "wday":
                    st.tm_wday = cast(int)v.__num__;
                    break;
                case "yday":
                    st.tm_yday = cast(int)v.__num__;
                    break;
                case "isdst":
                    st.tm_isdst = cast(int)v.__num__;
                    break;
                default:
                    break;
            }
        }

        stamp = mktime(&st);
        return new LdNum(stamp);
    }

    override string __str__() { return "mktime (time method)"; }
}

class _asctime: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        tm st;  // tm* timeptr struct

        if (args.length) {
            foreach(k, v; args[0].__hash__) {
                switch (k) {
                    case "year":
                        st.tm_year = cast(int)v.__num__;
                        break;
                    case "mon":
                        st.tm_mon = cast(int)v.__num__;
                        break;
                    case "mday":
                        st.tm_mday = cast(int)v.__num__;
                        break;
                    case "hour":
                        st.tm_hour = cast(int)v.__num__;
                        break;
                    case "min":
                        st.tm_min = cast(int)v.__num__;
                        break;
                    case "sec":
                        st.tm_sec = cast(int)v.__num__;
                        break;
                    case "wday":
                        st.tm_wday = cast(int)v.__num__;
                        break;
                    case "yday":
                        st.tm_yday = cast(int)v.__num__;
                        break;
                    case "isdst":
                        st.tm_isdst = cast(int)v.__num__;
                        break;
                    default:
                        break;
                }
            }
        }

        return new LdStr(chomp(to!string(asctime(&st))));       
    }

    override string __str__() { return "asctime (time method)"; }
}

class _difftime: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(difftime(cast(time_t)args[0].__num__, cast(time_t)args[1].__num__));
    }

    override string __str__() { return "difftime (time method)"; }
}

class _ctime: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        time_t tm = cast(time_t)(args[0].__num__);
        return new LdStr(chomp(to!string(ctime(&tm))));
    }

    override string __str__() { return "ctime (time method)"; }
}

class _time: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(time(null));
    }

    override string __str__() { return "time (time method)"; }
}

class _sleep: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
       	Thread.getThis().sleep(dur!"msecs"(cast(int)args[0].__num__));
        return RETURN.A;
    }

    override string __str__() { return "sleep (time method)"; }
}
