module yeti16.util;

import std.range;
import std.socket;
import std.bitmanip;

public import core.stdc.stdlib : exit;

alias NativeToYeti = nativeToLittleEndian;
alias YetiToNative = littleEndianToNative;

ubyte[] AddrNativeToYeti(uint addr) {
	return [
		cast(ubyte) (addr & 0xFF),
		cast(ubyte) ((addr & 0xFF00) >> 8),
		cast(ubyte) ((addr & 0xFF0000) >> 16)
	];
}

bool SendData(Socket socket, ubyte[] pdata) {
	ubyte[] data = pdata.dup;

	if (data.empty) return true;

	socket.blocking = true;

	while (data.length > 0) {
		auto len = socket.send(cast(void[]) data);

		if (len == Socket.ERROR) {
			return false;
		}

		data = data[len .. $];
	}

	socket.blocking = false;
	return true;
}
