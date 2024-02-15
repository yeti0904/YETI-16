module yeti16.util;

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
