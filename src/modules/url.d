module lUrl;


import std.net.curl;
import std.typecons: Yes, No;
import std.stdio;
import std.format: format;

import LdObject;


alias LdOBJECT[string] Heap;


class oUrl: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
			"get": new _Get(),
			"put": new _Put(),
			"post": new _Post(),
			"readline": new _Readline(),
			"readchunks": new _Readchuncks(),
			"upload": new _Upload(),
			"download": new _Download(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "url (native module)"; }
}


class _Download: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	download(args[0].__str__, args[1].__str__);
        
        return RETURN.A;
    }
    override string __str__() { return "url.download (method)"; }
}

class _Upload: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	upload(args[0].__str__, args[1].__str__);
        
        return RETURN.A;
    }
    override string __str__() { return "url.upload (method)"; }
}

class _Get: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	return new LdChr(cast(char[])get(args[0].__str__));
        
        return RETURN.A;
    }
    override string __str__() { return "url.get (method)"; }
}


class _Post: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	if (args[1].__type__ == "dict") {
    		string[string] cnt;

    		foreach(string i,  v; args[0].__hash__)
    			cnt[i] = v.__str__;

    		return new LdChr(cast(char[])post(args[0].__str__, cnt));
    	}

    	return new LdChr(cast(char[])post(args[0].__str__, cast(ubyte[])args[1].__chars__));
    }
    override string __str__() { return "url.post (method)"; }
}


class _Put: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	return new LdChr(cast(char[])put(args[0].__str__, args[1].__chars__));
    }
    override string __str__() { return "url.put (method)"; }
}

class _Readline: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	LdOBJECT[] data;

    	char sep = '\n';
    	KeepTerminator keep = Yes.keepTerminator;

    	if(args.length > 1){
    		foreach(i, j; args[1].__props__) {

    			if (i == "sep")
    				if (j.__str__.length)
    					sep = j.__str__[0];

    			else if (i == "keep" && !(j.__true__))
    				keep = No.keepTerminator;
    		}
    	}

    	foreach(ln; byLine(args[0].__str__, keep, sep))
    		data ~= new LdChr(ln);

    	return new LdArr(data);
    }
    override string __str__() { return "url.readline (method)"; }
}


class _Readchuncks: LdOBJECT 
{
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	LdOBJECT[] data;

    	foreach(chunk; byChunk(args[0].__str__, cast(size_t)args[1].__num__))
    		data ~= new LdChr(cast(char[])chunk);

    	return new LdArr(data);
    }
    override string __str__() { return "url.readchuncks (method)"; }
}

