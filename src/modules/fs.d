module lFs;


/*
This module has all possible functions 
that deal with functions got from many
sectors, the lies of os.

But a sister module path is present
withh functions to handle os path
string, thank you


May the Almighty God bless us all.
Please pray everyday. Jesus loves u.

*/




import std.file;
import std.stdio: File, writeln;

import std.conv: to;

import std.array: array;
import std.format: format;
import std.path: baseName;
import std.typecons: No, Yes;
import std.algorithm.searching: canFind;
import std.algorithm.iteration: each, map;

import std.datetime: SysTime;

import LdObject;


alias LdOBJECT[string] Heap;


class oFs: LdOBJECT
{
	Heap props;

	this(){
		this.props = [
			"readFile": new _ReadFile(),
			"writeFile": new _WriteFile(),

			"appendFile": new _AppendFile(),
			"openFile": new _OpenFileStream(),
			
			"read": new _Read(),
			"fileSize": new _FileSize(),

			"rm": new _Rm(),
			"rmdir": new _Rmdir(),

			"mkdir": new _Mkdir(),
			"chdir": new _Chdir(),

			"pwd": new _Pwd(),
			"readdir": new _Readdir(),

			"exists": new _Exists(),
			"dir": new _IsDir(),

			"file": new _IsFile(),
			"symlink": new _IsLink(),

			"rename": new _Rename(),
			"copyFile": new _CopyFile(),

			"walkdir": new _Walkdir(),
			"tempdir": new _Tempdir(),

			"fdata": new _FData(),
			"fchmod": new _FChmod(),

			"ftime": new _Ftime(),
		];

		version (Posix) {
			this.props["mkSymlink"] = new _MkSymLink();
			this.props["readSymlink"] = new _ReadSymlink();
		}
	}

	override LdOBJECT[string] __props__(){ return props; }

	override string __type__(){ return "native module";}

	override string __str__(){ return "fs (native module)"; }
}


version (Posix) {
	class _MkSymLink: LdOBJECT {
	    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
	       	symlink(args[0].__str__, args[1].__str__);
	       	return RETURN.A;
	    }

	    override string __str__() { return "fs.mksymlink (method)"; }
	}

	class _ReadSymlink: LdOBJECT {
	    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
	       	return new LdStr(std.file.readLink(args[0].__str__));
	    }

	    override string __str__() { return "fs.readSymlink (method)"; }
	}
}

version (Windows){
	class _Ftime: LdOBJECT {
	    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
	    	SysTime accessTime, modTime, mkTime;

			getTimesWin(args[0].__str__, mkTime, accessTime, modTime);

			long a = (cast(long)(mkTime.toUnixTime));
			long b = (cast(long)(accessTime.toUnixTime));
			long c = (cast(long)(modTime.toUnixTime));

	       	return new LdEnum("ftime", ["make": new LdEnum(a), "access": new LdNum(b), "amend": new LdNum(c)]);
	    }

	    override string __str__() { return "fs.ftime (method)"; }
	}

} else {
	class _Ftime: LdOBJECT {
	    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
	    	SysTime accessTime, modTime;

			getTimes(args[0].__str__, accessTime, modTime);

			long a = (cast(long)(accessTime.toUnixTime));
			long b = (cast(long)(modTime.toUnixTime));

	       	return new LdEnum("ftime", ["access": new LdNum(a), "amend": new LdNum(b)]);
	    }

	    override string __str__() { return "fs.ftime (method)"; }
	}
}


class _Read: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
       	return new LdStr(readText(args[0].__str__));
    }

    override string __str__() { return "fs.read (method)"; }
}

class _FData: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
       	return new LdNum(getAttributes(args[0].__str__));
    }

    override string __str__() { return "fs.fdata (method)"; }
}

class _FChmod: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	setAttributes(args[0].__str__, cast(uint)(args[1].__num__));
    	return RETURN.A;
    }

    override string __str__() { return "fs.fchmod (method)"; }
}

class _ReadFile: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {

		if (args.length > 1)
			return new LdChr(cast(char[])read(args[0].__str__, cast(size_t)args[1].__num__));

		return new LdChr(cast(char[])read(args[0].__str__));
    }

    override string __str__() { return "fs.readFile (method)"; }
}

class _WriteFile: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	write(args[0].__str__, args[1].__chars__);
       	return RETURN.A;
    }

    override string __str__() { return "fs.writeFile (method)"; }
}

class _AppendFile: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
       	append(args[0].__str__, args[1].__chars__);
		return RETURN.A;
    }

    override string __str__() { return "fs.appendFile (method)"; }
}

class _FileSize: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		return new LdNum(getSize(args[0].__str__));
    }

    override string __str__() { return "fs.fileSize (method)"; }
}

class _CopyFile: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	PreserveAttributes preserve = preserveAttributesDefault;

    	if (args.length > 2){
			if (args[2].__true__)
				preserve = Yes.preserveAttributes;
			else
				preserve = No.preserveAttributes;
    	}

    	copy(args[0].__str__, args[1].__str__, preserve);
    	return RETURN.A;
    }

    override string __str__() { return "fs.copyFile (method)"; }
}

class _Rm: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	std.file.remove(args[0].__str__);
    	return RETURN.A;
    }

    override string __str__() { return "fs.rm (method)"; }
}

class _Rmdir: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	rmdirRecurse(args[0].__str__);
    	return RETURN.A;
    }
    override string __str__() { return "fs.rmdir (method)"; }
}

class _Mkdir: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	mkdirRecurse(args[0].__str__);
    	return RETURN.A;
    }
    override string __str__() { return "fs.mkdir (method)"; }
}

class _Rename: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	rename(args[0].__str__, args[1].__str__);
    	return RETURN.A;
    }
    override string __str__() { return "fs.rename (method)"; }
}

class _Chdir: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        chdir(args[0].__str__);
        return RETURN.A;
    }
    override string __str__() { return "fs.chdir (method)"; }
}

class _Pwd: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(getcwd);
    }
    override string __str__() { return "fs.pwd (method)"; }
}

class _Readdir: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        string directory;

        if (args.length)
            directory = args[0].__str__;
        else
            directory = getcwd();

        LdOBJECT[] paths = cast(LdOBJECT[])dirEntries(directory, SpanMode.shallow, false).map!(i => new LdStr(baseName(i))).array;
        return new LdArr(paths);
    }

    override string __str__() { return "fs.readdir (method)"; }
}

class _Tempdir: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        return new LdStr(tempDir);
    }
    override string __str__() { return "fs.tempdir (method)"; }
}

class _Walkdir: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        string directory;

        if (args.length)
            directory = args[0].__str__;
        else
            directory = getcwd();

        LdOBJECT[] paths = cast(LdOBJECT[])dirEntries(directory, SpanMode.depth, false).map!(i => new LdStr(i)).array;
        return new LdArr(paths);
    }

    override string __str__() { return "fs.walkdir (method)"; }
}

class _Exists: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	if (exists(args[0].__str__))
    		return RETURN.B;

    	return RETURN.C;
    }

    override string __str__() { return "fs.exists (method)"; }
}

class _IsFile: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	if (isFile(args[0].__str__))
    		return RETURN.B;

    	return RETURN.C;
    }
    override string __str__() { return "fs.file (method)"; }
}

class _IsDir: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
    	if (isDir(args[0].__str__))
    		return RETURN.B;

    	return RETURN.C;
    }
    override string __str__() { return "fs.isdir (method)"; }
}

class _IsLink: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        if (isSymlink(args[0].__str__))
            return RETURN.B;

        return RETURN.C;
    }
    override string __str__() { return "fs.islink (method)"; }
}


class _OpenFileStream: LdOBJECT  {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		if (args.length > 1)
			return new _OpenFileObject(args[0].__str__, args[1].__str__);

		return new _OpenFileObject(args[0].__str__);
    }

    override string __type__() { return "fs.openFile"; }

    override string __str__() { return "fs.openFile (type)"; }
}


class _OpenFileObject: LdOBJECT
{
	File x;
	Heap props;
	string name, mode;

	this(string name, string mode="r"){
		this.name = name;
		this.mode = mode;

		this.x = File(name, mode);

		this.props = [
			"close": new _close(x),
			"flush": new _flush(x),

			"write": new _write(x, mode),
			"writeline": new _writeline(x, mode),

			"tell": new _tell(x),
			"size": new _size(x),

			"seek": new _seek(x),
			"rewind": new _rewind(x),

			"read": new _read(x, mode),
			"readLine": new _readLine(x, mode),

			"closed": new _IsClosed(x),
			"blocks": new _blocks(x, mode),

			"name": new LdStr(name),
			"mode": new LdStr(mode),
		];
	}

	override string __type__() { return "fs.openFile"; }

	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return "fs.openFile (object)"; }
}

// x represents the file OBJECT

class _blocks: LdOBJECT {
	File x;
	string fileMode;

	this(File x, string fileMode){
		this.x = x;
		this.fileMode = fileMode;
	}

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	auto chunk = x.byChunk(cast(size_t)args[0].__num__);

    	LdEnum stop_generator = new LdEnum("stopGenerator", ["stop": RETURN.B]);

		foreach (ubyte[] b; chunk){
			if (!(stop_generator.__props__["stop"].__true__))
				break;

			args[1]([new LdChr(cast(char[])b), stop_generator]);    /// callback function with [one argument data]
		}

		return RETURN.A;
    }

    override string __str__() { return "fs.openFile.blocks method)"; }
}


class _readLine: LdOBJECT {
	File x;  string fileMode;
	char[] buf;

	this(File x, string fileMode){
		this.x = x;
		this.fileMode = fileMode;
		this.buf = buf;
	}

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	if (args.length)
    		buf = x.readln!(char[])(args[0].__str__[0]);
		else
    		buf = x.readln!(char[])();

    	if(canFind(fileMode, 'b'))
    		return new LdChr(buf);

    	return new LdStr(cast(string)buf);
    }

    override string __str__() { return "fs.openFile.readLine (method)"; }
}

class _IsClosed: LdOBJECT {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	if (x.isOpen)
			return RETURN.B;
		
		return RETURN.C;
    }

    override string __str__() { return "fs.openFile.opened (method)"; }
}

class _Sync: LdOBJECT {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		x.sync();
		return RETURN.A;
    }

    override string __str__() { return "fs.openFile.sync (method)"; }
}

class _read: LdOBJECT {
	File x;
	char[8192] buffer;
	string fileMode;

	this(File x, string fileMode){
		this.x = x;
		this.fileMode = fileMode;
		this.buffer=buffer;
	}

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	char[] data = x.rawRead(buffer);
    	int len = cast(int)data.length;

    	if(args.length) {
    		int inlen = cast(int)args[0].__num__;

    		if(inlen < len)
    			len = inlen;
    	}

    	if(canFind(fileMode, 'b'))
    		return new LdChr(data[0..len]);

    	return new LdStr(cast(string)data[0..len]);
    }

    override string __str__() { return "fs.openFile.read (method)"; }
}

class _seek: LdOBJECT  {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		if (args.length == 1)
			x.seek(cast(long)args[0].__num__, 2);
		else
			x.seek(cast(long)args[0].__num__, cast(int)args[1].__num__);

		return RETURN.A;
    }

    override string __str__() { return "fs.openFile.seek (method)"; }
}

class _tell: LdOBJECT {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		return new LdNum(x.tell);
    }

    override string __str__() { return "fs.openFile.tell (method)"; }
}

class _rewind: LdOBJECT {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	x.rewind();
    	return RETURN.A;
    }

    override string __str__() { return "fs.openFile.rewind (method)"; }
}

class _size: LdOBJECT {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
		return new LdNum(x.size);
    }

    override string __str__() { return "fs.openFile.size (method)"; }
}

class _write: LdOBJECT  {
	File x; string fileMode;

	this(File x, string fileMode){
		this.x = x;
		this.fileMode = fileMode;
	}

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	if(canFind(fileMode, 'b'))
    		x.rawWrite(args[0].__chars__);
    	else
    		x.write(args[0].__str__);

		return RETURN.A;
    }

    override string __str__() { return "fs.openFile.write (method)"; }
}

class _writeline: LdOBJECT  {
	File x; string fileMode;

	this(File x, string fileMode){
		this.x = x;
		this.fileMode = fileMode;
	}

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	if(canFind(fileMode, 'b'))
    		x.writeln(args[0].__chars__);
    	else
    		x.writeln(args[0].__str__);

		return RETURN.A;
    }

    override string __str__() { return "fs.openFile.writeLine (method)"; }
}

class _flush: LdOBJECT {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	x.flush();
		return RETURN.A;
    }

    override string __str__() { return "fs.openFile.flush (method)"; }
}

class _close: LdOBJECT {
	File x;
	this(File x){ this.x = x; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null) {
    	x.close();
		return RETURN.A;
    }

    override string __str__() { return "fs.openFile.close (method)"; }
}