module lSqlite3;

pragma(lib, "sqlite3");



import std.stdio;

import std.conv;
import std.string;
import std.path;
import etc.c.sqlite3;
import LdObject;


alias LdOBJECT[string] HEAP;



class oSqlite3: LdOBJECT
{
    HEAP props;

    this(){
        this.props = [
            "open": new _Open_Database(),
        ];
    }

    override LdOBJECT[string] __props__(){ return props; }

    override string __str__(){ return "list (native module)"; }
}



class _Open: LdOBJECT {
    HEAP props;
    int status_code;
    string name;
    sqlite3* db;

    this(string name){
        this.name = name;
        this.db = db;
        this.status_code = status_code;

        this.status_code = sqlite3_open(toStringz(name), &this.db);

        this.props = [
            "execute": new sqlExecute(this.db),

            //"run": new sqlRun(this.db),
            
            //"errorMessage": new sqlErrMessage(this.db),
            //"errorCode": new sqlErrorCode(this.db),

            "close": new sqlClose(this.db),
            //"status": new Number(this.status_code),
            "interrupt": new sqlInterrupt(this.db),

            "changes": new sqlChanges(this.db),
            "total_changes": new sqlTotalChanges(this.db),
        ];
    }

    
    override HEAP __props__(){ return props; }

    override string __str__(){ return std.path.baseName(this.name) ~ " (sqlite3 database object)";}
}


class _Open_Database: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){ 
        return new _Open(args[0].__str__);
    }

    override string __str__() { return "sqlite3.open (method)"; }
}



class sqlClose: LdOBJECT {
    sqlite3* db;

    this(sqlite3* db){
        this.db = db;
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        sqlite3_close(this.db);
        return RETURN.A;
    }

    override string __str__() { return "close (sqlite3.open method)"; }
}


extern(C) int callback(void* none, int length, char** values, char** columns){
    LdOBJECT[]* cols = cast(LdOBJECT[]*)none;
    LdOBJECT[] rows;

    for(int i = 0; i < length; i++) {
        rows ~= new LdStr(to!string(values[i] ? values[i] : "NULL"));
    }
    
    (*cols) ~= new LdArr(rows);
    return 0;
}



class sqlExecute: LdOBJECT {
    sqlite3* db;

    this(sqlite3* db){
        this.db = db;
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null) {
        char* message;
        LdOBJECT[] data;

        int status_code = sqlite3_exec(this.db, toStringz(args[0].__str__), &callback, &data, &message);

        return new LdEnum("sql-data (message, status, data)", [
            "message": new LdStr(to!string(message)),
            "status": new LdNum(status_code),
            "data": new LdArr(data) ]
        );
    }
    override string __str__() { return "execute (sqlite3.open method)"; }
}


class sqlChanges: LdOBJECT {
    sqlite3* db;
    
    this(sqlite3* db){ this.db = db; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){ 
        return new LdNum(sqlite3_changes(this.db));
    }

    override string __str__() { return "changes (sqlite3.open method)"; }
}


class sqlTotalChanges: LdOBJECT {
    sqlite3* db;
    
    this(sqlite3* db){ this.db = db; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){ 
        return new LdNum(sqlite3_total_changes(this.db));
    }

    override string __str__() { return "total_changes (sqlite3.open method)"; }
}


class sqlInterrupt: LdOBJECT {
    sqlite3* db;
    
    this(sqlite3* db){ this.db = db; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){
        sqlite3_interrupt(this.db);
        return RETURN.A;
    }

    override string __str__() { return "interrupt (sqlite3.open method)"; }
}

//class _: LdOBJECT {
//    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, LdOBJECT[string]* mem=null){ 

//        return ;
//    }

//    override string __str__() { return ""; }
//}

