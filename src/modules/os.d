module Os;


import core.stdc.stdlib: system, getenv, abort;
import std.string: toStringz;
import std.algorithm.iteration: map;

import core.thread.osthread: getpid;
import std.parallelism: totalCPUs;

import std.conv: to;
import std.array: array;

import std.file;
import std.path;

import LdObject;

alias LdOBJECT[string] Heap;


class oS: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
            "abort": new _Abort(),
            "arch": new _Arch(),

            "system": new _System(),
            "getenv": new _Getenv(),

			"platform": new LdStr(Platform),

            "getpid": new _Getpid(),
            "cpuCount": new _CpuCount(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "os (core module)"; }
}


class _Abort: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        abort();
        return RETURN.A;
    }

    override string __str__() { return "os.abort (method)"; }
}

class _CpuCount: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(totalCPUs);
    }

    override string __str__() { return "os.cpuCount (method)"; }
}


class _Getpid: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(getpid());
    }

    override string __str__() { return "os.getpid (method)"; }
}


class _Getenv: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(to!string(getenv(toStringz(args[0].__str__))));
    }

    override string __str__() { return "os.getenv (method)"; }
}


class _System: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdNum(system(toStringz(args[0].__str__)));
    }

    override string __str__() { return "os.system (method)"; }
}


class _Arch: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        version (X86_64){
            return new LdStr("X86_64");

        } version (X86) {
            return new LdStr("X86");
        }

        return new LdStr("not_found");
    }

    override string __str__() { return "os.arch (method)"; }
}


string Platform() {
    string plat = "not_found";

    version (Windows){
        plat = "windows";

    } version (linux){
        plat = "linux";

    } version (FreeBSD){
        plat = "freeBSD";

    } version (OpenBSD){
        plat = "openBSD";

    } version (NetBSD){
        plat = "netBSD";

    } version (DragonFlyBSD){
        plat = "dragonFlyBSD";

    } version (FreeBSD){
        plat = "freeBSD";

    } version (BSD){
        plat = "BSD";

    } version (OSX){
        plat = "OSX";

    } version (IOS){
        plat = "iOS";

    } version (Android){
        plat = "android";

    } version (Solaris){
        plat = "solaris";

    }
    return plat;
}

