module yeti16.devices.serial;

import std.stdio;
import std.socket;
import std.algorithm;
import yeti16.util;
import yeti16.device;

class SerialDevice : Device {
	Socket    serverSocket;
	Socket    clientSocket;
	SocketSet serverSet;
	SocketSet clientSet;
	string[]  allowedIPs;
	ubyte[]   outData;

	this(ushort port, string[] pallowedIPs) {
		name = "YETI-16 Serial Device";

		serverSocket          = new Socket(AddressFamily.INET, SocketType.STREAM);
		serverSocket.blocking = false;
		serverSocket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 1);

		version (Posix) {
			serverSocket.setOption(
				SocketOptionLevel.SOCKET, cast(SocketOption) SO_REUSEPORT, 1
			);
		}

		serverSocket.bind(new InternetAddress("0.0.0.0", port));
		serverSocket.listen(1);
		writefln("Serial port listening on port %d", port);

		serverSet = new SocketSet();
		clientSet = new SocketSet();

		allowedIPs = pallowedIPs;
	}

	override void Out(ushort dataIn) {
		outData ~= cast(ushort) (dataIn & 0xFF);
	}

	override void Update() {
		serverSet.reset();
		clientSet.reset();

		serverSet.add(serverSocket);
		if (clientSocket) {
			clientSet.add(clientSocket);
		}

		bool   success = true;
		Socket newClient;
		try {
			newClient = serverSocket.accept();
		}
		catch (Throwable) {
			success = false;
		}

		if (success) {
			newClient.blocking = false;

			auto ip = newClient.remoteAddress.toAddrString();
			if (!allowedIPs.canFind(ip)) {
				newClient.close();
				goto next;
			}

			writefln("%s connected to the serial port", ip);

			if (clientSocket) {
				clientSocket.close();
			}
			clientSocket = newClient;
		}

		next:
		if (!clientSocket) return;

		if (clientSocket.SendData(outData)) {
			outData = [];
		}
		else {
			clientSocket.close();
			clientSocket = null;
		}

		if (clientSet.isSet(clientSocket)) {
			ubyte[] incoming = new ubyte[1024];
			long    received = clientSocket.receive(incoming);
			
			if ((received <= 0) || (received == Socket.ERROR)) {
				return;
			}

			incoming  = incoming[0 .. received];
			data     ~= incoming;
		}
	}

	override void HandleEvent(SDL_Event* e) {
		
	}
}
