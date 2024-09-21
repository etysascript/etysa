module lSocket;


import std.socket;
import std.conv: to;

import std.uni: toLower;
import std.stdio: writeln;
import std.format: format;


import LdObject;

alias LdOBJECT[string] HEAP;

class oSocket: LdOBJECT {
	HEAP props;

	this(){
		this.props = [
			"Socket": new new_socket(),

            "get_addr": new GetAddr(),
			"get_addr_info": new GetAddrInfo(),

			"getHostByName": new GetHostByName(),
			"getHostByAddress": new GetHostByAddr(),

            "last_sock_error": new _Last_Socket_Error(),
            "would_block": new _Failed_Non_Blocking(),
		];
	}

	override LdOBJECT[string] __props__(){ return props; }

    override string __type__(){ return "builtin module";}

	override string __str__(){ return "socket (builtin module)"; }
}


class _Failed_Non_Blocking: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        if (wouldHaveBlocked())
            return RETURN.B;

        return RETURN.C;
    }
    override string __str__() { return "socket.would_block (method)"; }
}


class _Last_Socket_Error: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        return new LdStr(lastSocketError());
    }

    override string __str__() { return "socket.last_sock_error (method)"; }
}


immutable string[AddressFamily] AF = [
    AddressFamily.APPLETALK: "APPLETALK",
    AddressFamily.INET: "INET",
    AddressFamily.INET6: "INET6",
    AddressFamily.IPX: "IPX",
    AddressFamily.UNIX: "UNIX",
    AddressFamily.UNSPEC: "UNSPEC",
];


immutable string[SocketType] SOCK_TYPE = [
    SocketType.DGRAM: "DGRAM",
    SocketType.RAW: "RAW",
    SocketType.RDM: "RDM",
    SocketType.SEQPACKET: "SEQPACKET",
    SocketType.STREAM: "STREAM",
];


immutable string[ProtocolType] PROTO_TYPE = [
    ProtocolType.GGP: "GGP",
    ProtocolType.ICMP: "ICMP",
    ProtocolType.IDP: "IDP",
    ProtocolType.IGMP: "IGMP",
    ProtocolType.IP: "IP",
    ProtocolType.IPV6: "IPV6",
    ProtocolType.PUP: "PUP",
    ProtocolType.RAW: "RAW",
    ProtocolType.TCP: "TCP",
    ProtocolType.UDP: "UDP",
];


class GetAddr: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
    	Address[] addrs;

        if (args[1].__type__ == "None")
            addrs = getAddress(args[0].__str__);
        else
            addrs = getAddress(args[0].__str__, cast(ushort)(args[1].__num__));
        
        LdOBJECT[] info;

        foreach(a; addrs) {
            info ~= new LdEnum( a.toAddrString(),
                [ "hostname": new LdStr(a.toHostNameString()), 
                  "port": new LdStr(a.toPortString()),
                  "ip": new LdStr(a.toAddrString()),
                  "serv_name": new LdStr(a.toServiceNameString())
                ]
            );
        }

    	return new LdArr(info);
    }

    override string __str__() { return "socket.get_addr (method)"; }
}


class GetAddrInfo: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        AddressInfo[] addrs = getAddressInfo(args[0].__str__);
        LdOBJECT[] info;

        foreach(a; addrs) {
            info ~= new LdEnum( "addr_info",
                [ "sock_family": new LdStr(AF[a.family]), 
                  "sock_type": new LdStr(SOCK_TYPE[a.type]),
                  "protocol": new LdStr(PROTO_TYPE[a.protocol]),

                  "address": new LdEnum(a.address.toAddrString(),
                    [ "hostname": new LdStr(a.address.toHostNameString()), 
                      "port": new LdStr(a.address.toPortString()),
                      "ip": new LdStr(a.address.toAddrString()),
                      "serv_name": new LdStr(a.address.toServiceNameString())
                    ]),
                ]
            );
        }

        return new LdArr(info);
    }

    override string __str__() { return "socket.get_addr_info (method)"; }
}


class GetHostByName: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
    	auto addr = getAddress(args[0].__str__);

    	if(addr.length) {
	    	auto op_len = addr.length/2;

	    	if(op_len == 1)
	    		return new LdStr(addr[0].toAddrString);

	    	return new LdStr(addr[op_len-1].toAddrString);
	    }

	    return RETURN.A;
    }

    override string __str__() { return "socket.getHostByName (method)"; }
}


class GetHostByAddr: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
    	InternetHost ih = new InternetHost;
		ih.getHostByAddr(args[0].__str__);

		return new LdStr(ih.name);
    }

    override string __str__() { return "socket.getHostByAddress (method)"; }
}


class new_socket: LdOBJECT {
    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        if (args[1].__type__ == "None") {
            if (toLower(args[0].__str__) == "udp")
                return new _socket_obj(new UdpSocket());
            
            return new _socket_obj(new TcpSocket());

        } else if (args[2].__type__ == "None"){
        	return new _socket_obj(new Socket( cast(AddressFamily)(args[0].__num__),
        								   cast(SocketType)(args[1].__num__)) );
        }

    	return new _socket_obj( new Socket( cast(AddressFamily)args[0].__num__,
        						            cast(SocketType)args[1].__num__,
        						            cast(ProtocolType)args[2].__num__ ) );
    }

    override string __str__() { return "socket.Socket (object)";}
}


class _socket_obj: LdOBJECT {
    HEAP props;
    Socket socket;

    this(Socket socket){
        this.socket = socket;
        this.socket.blocking = true;

        this.props = [
        	"alive": new _IsAlive(socket),
        	"blocked": new _blocked(socket),

        	"bind": new _bind(socket),
        	"connect": new _connect(socket),

        	"listen": new _listen(socket),
        	"setBlocking": new _setblocking(socket),

        	"accept": new _accept(socket),
        	"send": new _send(socket),
        	"sendTo": new _sendto(socket),
            "recv": new _recv(socket),
        	"recvFrom": new _recvFrom(socket),

        	"setSocketOption": new _setsockopt(socket),
            "setKeepAlive": new _keep_alive(socket),

        	"shutDown": new _shutdown(socket),
        	"close": new _close(socket),

        	"hostname": new LdStr(socket.hostName),
        	"addressFamily": new LdNum(cast(double)socket.addressFamily),
        ];
    }
   	
   	override LdOBJECT[string] __props__(){ return props; }

	override string __str__(){ return format("socket.Socket (object af: %s)", socket.addressFamily); }
}


class _keep_alive: LdOBJECT {
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        socket.setKeepAlive(cast(int)args[0].__num__, cast(int)args[1].__num__);
        return RETURN.A;
    }
}

class _bind: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        socket.bind(new InternetAddress(args[0].__str__, cast(ushort)args[1].__num__));
        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.bind (method)"; }
}


class _connect: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        if (args.length > 1)
            this.socket.connect(new InternetAddress(args[0].__str__, cast(ushort)args[1].__num__));
       	else
        	throw new Exception("socket.connect takes a 'host-name' and 'port-number'.");

        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.connect (method)"; }
}


class _listen: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        socket.listen(cast(int)args[0].__num__);
        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.listen (method)"; }
}


class _setblocking: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        if(args[0].__true__)
            socket.blocking = true;
        else
            socket.blocking = false;

        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.setBlocking (method)"; }
}


class _accept: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        return new _socket_obj(socket.accept());
    }

    override string __str__() { return "socket.Socket.accept (method)"; }
}


class _send: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        socket.send(args[0].__chars__);
        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.send (method)"; }
}


class _sendto: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        socket.sendTo(args[0].__chars__);
        return new LdNone();
    }

    override string __str__() { return "socket.Socket.sendTo (method)"; }
}


class _recv: LdOBJECT
{
    Socket socket;
    char[64000] buffer;

    this(Socket socket){
    	this.buffer = buffer;
    	this.socket = socket;
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        auto data = socket.receive(buffer);

        if(data == -1)
        	return new LdChr([]);

        else if (data == 0)
        	throw new Exception("SocketError: remote side closed connection.");

        return new LdChr(buffer[0 .. data]);
    }

    override string __str__() { return "socket.Socket.recieve (method)"; }
}


class _recvFrom: LdOBJECT
{
    Socket socket;
    char[64000] buffer;

    this(Socket socket){
        this.buffer = buffer;
        this.socket = socket;
    }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        auto data = socket.receiveFrom(buffer);

        if(data == -1)
            return new LdChr([]);

        else if (data == 0)
            throw new Exception("SocketError: remote side closed connection.");

        return new LdChr(buffer[0 .. data]);
    }

    override string __str__() { return "socket.Socket.recv_from (method)"; }
}



class _shutdown: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        socket.shutdown(cast(SocketShutdown)args[0].__num__); 

        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.shutDown (method)"; }
}


class _close: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        socket.close();
        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.close (method)"; }
}


class _IsAlive: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        if (socket.isAlive())
            return RETURN.B;

        return RETURN.C;
    }

    override string __str__() { return "socket.Socket.alive (method)"; }
}


class _blocked: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
        if (socket.blocking)
            return RETURN.B;

        return RETURN.C;
    }

    override string __str__() { return "socket.Socket.blocked (method)"; }
}


class _setsockopt: LdOBJECT
{
    Socket socket;
    this(Socket socket){ this.socket = socket; }

    override LdOBJECT opCall(LdOBJECT[] args, uint line=0, HEAP* mem=null){
    	socket.setOption(
    		cast(SocketOptionLevel)args[0].__num__,
    		cast(SocketOption)args[1].__num__,
    		cast(int)args[2].__num__
    	);

        return RETURN.A;
    }

    override string __str__() { return "socket.Socket.setSocketOption (method)"; }
}

