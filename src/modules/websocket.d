module Websock;

import std.stdio;
import std.socket;
import std.conv;
import std.digest.sha;
import std.base64;
import std.regex;
import std.bitmanip;
import std.random;
import std.array;
import std.format: format;

import std.path: buildPath;
import std.file: write, exists, isDir;

import core.thread.osthread: Thread;
import core.time: dur;
import core.stdc.time;

import LdObject;
import lJson: _Parse;

alias LdOBJECT[string] HEAP;

class oWebsock: LdOBJECT {
	HEAP props;

	this(){
		this.props = [ "Websocket": new _WebsocketServer(),];
	}

	override string __type__(){
		return "websocket module";
	}

	override LdOBJECT[string] __props__(){ return props; }
	override string __str__(){ return "websocket (native module)"; }
}


class _WebsocketServer: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
    	return new _Websocket();
    }
    override string __str__() { return "websocket.Websocket (type)";}
}


enum BUFF_SIZE = 64000;
enum MAX_MSGLEN = 65535;


class _Websocket: LdOBJECT {
	HEAP props;
	Socket ws, client;

	LdOBJECT[] onopen, onmessage;
	HEAP*[] onmessage_file;
	uint[] onmessage_line;

	bool isopen;

	this(){
		this.client = client;
		this.ws = new TcpSocket();
		this.isopen = false;

		version(all){
			this.onopen = onopen;
			this.onmessage = onmessage;
			this.onmessage_file = onmessage_file;
			this.onmessage_line = onmessage_line;
		}

		this.props = [
			"on": new _wsOn_event(this),
			"connect": new _wsConnect(this),

			"send": new _wsSend(this),
			"start": new _wsStart(this),

			"close": new _wsClose(this),
			"isopen": new _wsIsopen(this),
		];
	}

	void event_listener(){
		char[BUFF_SIZE] buffer;

		while (true) {
			auto len = this.client.receive(buffer);

			if (len <= 0) {
				if (this.isopen)
					throw new Exception("ERROR: websocket client disconnected or encounted an error.");

				break;
			}
			
			this.on_message(buffer[0..len]);
		}
	}

	void on_message(char[] data){
		ubyte[] bytes = cast(ubyte[])data;

		bool fin = (bytes[0] & 0b10000000) != 0;
		bool mask = (bytes[1] & 0b10000000) != 0;

	    int opcode = bytes[0] & 0b00001111;
	    int offset = 2;

	    size_t msglen = bytes[1] & 0b01111111;

	    if (msglen == 126) {
	    	msglen = bytes.peek!ushort(2);
	        offset = 4;
	    
	    } else if (msglen == 127) {
	        msglen = bytes.peek!size_t(2);
	        offset = 10;
	    }

	    // to text
	    ubyte[] decoded = new ubyte[msglen];
        ubyte[] masks = [bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3]];
        offset += 4;

        for (size_t i = 0; i < msglen; ++i)
            decoded[i] = cast(ubyte)(bytes[offset + i] ^ masks[i % 4]);

        LdOBJECT processed = new LdChr(cast(char[])decoded);

        // executing callback onmessage functions
        for(size_t i=0; i < onmessage.length; i++)
        	onmessage[i]([processed], onmessage_line[i], onmessage_file[i]);
 
    }

	override LdOBJECT[string] __props__(){
		return props;
	}

	override string __str__(){ return "websocket.Websocket (object)"; }
}


class _wsConnect: LdOBJECT {
	_Websocket ws;

	this(_Websocket ws){
		this.ws = ws;
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		this.ws.ws.bind(new InternetAddress(args[0].__str__, cast(ushort)args[1].__num__));
			 ws.ws.blocking = true;
			 ws.ws.listen(1);

		ws.props["hostname"] = new LdStr(args[0].__str__);
		ws.props["port"] = new LdNum(args[1].__num__);

		return RETURN.A;
	}

	override string __str__(){ return "connect (websocket.Websocket method)"; }
}


class _wsSend: LdOBJECT {
	_Websocket ws;

	this (_Websocket ws){
		this.ws = ws;
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		char[] data = args[0].__chars__;
		
		char[] op = [129];
	    auto len = appender!(const ubyte[])();

        if (data.length < 126)
        	op ~= cast(ubyte)data.length;

        else if (data.length < MAX_MSGLEN+1) {
			op ~= 126;
			len.append!ushort(cast(ushort)data.length);

        } else {
        	op ~= 127;
        	len.append!ulong(data.length);
        }

        op ~= cast(char[])len.data ~ data;
        this.ws.client.send(op);

		return RETURN.A;
	}

	override string __str__(){ return "send (websock.Open method)"; }
}


class _wsOn_event: LdOBJECT {
	_Websocket ws;

	this (_Websocket ws){
		this.ws = ws;
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){

		if (args[0].__str__ == "open")
			ws.onopen ~= args[1];
		else{
			ws.onmessage ~= args[1];
			ws.onmessage_file ~= mem;
			ws.onmessage_line ~= line;
		}

		return RETURN.A;
	}

	override string __str__(){ return "on (websocket.Websocket method)"; }
}


class _wsClose: LdOBJECT {
	_Websocket ws;

	this (_Websocket ws){
		this.ws = ws;
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		this.ws.client.shutdown(SocketShutdown.BOTH);
		ws.client.close();

		ws.ws.shutdown(SocketShutdown.BOTH);
		ws.ws.close();

		ws.isopen = false;
		return RETURN.A;
	}

	override string __str__(){ return "close (websocket.Websocket method)"; }
}

class _wsIsopen: LdOBJECT {
	_Websocket ws;

	this (_Websocket ws){
		this.ws = ws;
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		if (this.ws.isopen)
			return RETURN.B;

		return RETURN.C;
	}

	override string __str__(){ return "isopen (websocket.Websocket method)"; }
}


class _wsStart: LdOBJECT {
	_Websocket ws;

	this (_Websocket ws){
		this.ws = ws;
	}

	override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
		string http_version = "1.1";

		if (args.length)
			http_version = args[0].__str__;

		this.ws.client = Connect_with_client(this.ws.ws, http_version);

		// executing callback onopen functions
		foreach(LdOBJECT i; ws.onopen)
			i([], line, mem);

		this.ws.event_listener();
		return RETURN.A;
	}

	override string __str__(){ return "start (websock.Open method)"; }
}


Socket Connect_with_client(Socket ws, string http_version){
	char[] msg;
	char[BUFF_SIZE] buffer;

	// get client websocket
	Socket client = ws.accept();

	auto data = client.receive(buffer);
	msg = buffer[0..data];

	auto sec = match(cast(string)msg, "Sec-WebSocket-Key: (.*)");
    string swka;
    
    bool valid_ws = false;

	foreach(i; sec){
    	if(i.length > 1){
    		valid_ws = true;
    		swka = i[1];
    	}
    	break;
    }

    if (valid_ws){
	    swka ~= "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	    
	    ubyte[20] swkaSha1 = sha1Of(swka);
	    string swkaSha1Base64 = Base64.encode(swkaSha1);

	    string res = (
	        format("HTTP/%s 101 Switching Protocols\r\n", http_version) ~
	        "Connection: Upgrade\r\n" ~
	        "Upgrade: websocket\r\n" ~
	        "Sec-WebSocket-Accept: " ~ swkaSha1Base64 ~ 
	        "\r\n\r\n"
	    );

		client.send(cast(char[])res);				

	} else
		throw new Exception("websocketError: aborted, client didn't show websockets supports.");

	return client;
}

