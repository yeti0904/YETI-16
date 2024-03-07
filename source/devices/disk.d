module yeti16.devices.disk;

import std.file;
import std.stdio;
import yeti16.util;
import yeti16.device;

enum DiskStatus {
	Success       = 0,
	OutOfBounds   = 1,
	NoMemorySpace = 2
}

class DiskDevice : Device {
	File    file;
	ubyte[] outData;

	static const uint sectorSize = 512;

	this(string path) {
		file = File(path, "rb+");

		if (file.size() % sectorSize != 0) {
			stderr.writefln("Disk '%s' has incomplete sectors", path);
			exit(1);
		}
		if (file.size() / sectorSize > 0x100000000) {
			stderr.writefln("Disk '%s' is too big", path);
			stderr.writeln("and how do you have enough storage to make a disk too big for YETI-16???");
			exit(1);
		}
		name = "YETI-16 Disk";
	}

	void Send32Bit(uint value) {
		data ~= value & 0xFFFF;
		data ~= (value & 0xFFFF0000) >> 16;
	}

	uint Read32Bit(ushort low, ushort high) {
		return (cast(uint) low) | ((cast(uint) high) << 16);
	}

	uint GetSectorAmount() {
		return cast(uint) (file.size() / sectorSize);
	}

	override void Out(ushort dataIn) {
		outData ~= cast(ubyte) dataIn;

		switch (outData[0]) {
			case 0x00: {
				outData = [];
				Send32Bit(GetSectorAmount());
				break;
			}
			case 0x01: {
				if (outData.length < 4) return;
				auto sector = Read32Bit(outData[0], outData[1]);
				auto addr   = Read32Bit(outData[2], outData[3]) & 0xFFFFFF;
				outData     = [];

				if (addr >= 0xFFFE00) {
					data ~= DiskStatus.NoMemorySpace; // doesn't fit in memory
					return;
				}
				if (sector >= GetSectorAmount()) {
					data ~= DiskStatus.OutOfBounds; // sector out of bounds
					return;
				}

				file.seek(cast(long) sector);
				auto sectorContents = file.rawRead(new ubyte[sectorSize]);

				foreach (i, ref b ; sectorContents) {
					emu.WriteByte(cast(uint) (addr + i), b);
				}
				data ~= DiskStatus.Success;
				break;
			}
			case 0x02: {
				if (outData.length < 4) return;
				auto sector = Read32Bit(outData[0], outData[1]);
				auto addr   = Read32Bit(outData[2], outData[3]) & 0xFFFFFF;
				outData     = [];

				if (addr >= 0xFFFE00) {
					data ~= 2; // doesn't fit in memory
					return;
				}
				if (sector >= GetSectorAmount()) {
					data ~= 1; // sector out of bounds
					return;
				}

				file.seek(cast(long) sector);
				file.rawWrite(emu.ReadBytes(addr, addr + 512));
				data ~= DiskStatus.Success;
				break;
			}
			default: break; // no errors
		}
	}

	override void Update() {

	}

	override void HandleEvent(SDL_Event* e) {
		
	}
}
