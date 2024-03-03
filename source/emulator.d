module yeti16.emulator;

import std.array;
import std.stdio;
import std.format;
import std.datetime.stopwatch;
import core.thread;
import bindbc.sdl;
import yeti16.device;
import yeti16.signed;
import yeti16.display;
import yeti16.devices.serial;
import yeti16.devices.graphics;
import yeti16.devices.keyboard;
import yeti16.devices.debugging;

enum Register : ubyte {
	A = 0,
	B = 1,
	C = 2,
	D = 3,
	E = 4,
	F = 5,
	G = 6,
	H = 7
}

enum RegPair : ubyte {
	AB = 0,
	CD = 1,
	EF = 2,
	GH = 3,
	IP = 4,
	SP = 5,
	BS = 6,
	DS = 7,
	SR = 8
}

enum Flag : ubyte {
	Zero    = 0b00000001,
	Sign    = 0b00000010,
	Carry   = 0b00000100
}

enum Instruction : ubyte {
	NOP   = 0b00000000,
	LDI   = 0b00100000,
	LDSI  = 0b00100001,
	CPR   = 0b00100010,
	CPP   = 0b00100011,
	LDA   = 0b00100100,
	SETZ  = 0b00100101,
	SETS  = 0b00100110,
	SETC  = 0b00100111,
	CLZ   = 0b00101000,
	CLS   = 0b00101001,
	CLC   = 0b00101010,
	GETF  = 0b00101011,
	SETF  = 0b00101100,
	WRB   = 0b01001000,
	WRW   = 0b01001010,
	WRA   = 0b01001100,
	RDB   = 0b01000000,
	RDW   = 0b01000010,
	RDA   = 0b01000100,
	BWRB  = 0b01001001,
	BWRW  = 0b01001011,
	BWRA  = 0b01001101,
	BRDB  = 0b01000001,
	BRDW  = 0b01000011,
	BRDA  = 0b01000101,
	PUSH  = 0b01011100,
	POP   = 0b01011101,
	PUSHA = 0b01011110,
	POPA  = 0b01011111,
	ADD   = 0b01100000,
	SUB   = 0b01100001,
	MUL   = 0b01100010,
	DIV   = 0b01100011,
	IDIV  = 0b01100100,
	MOD   = 0b01100101,
	IMOD  = 0b01100110,
	INC   = 0b01100111,
	DEC   = 0b01101000,
	INCP  = 0b01101001,
	DECP  = 0b01101010,
	ADDP  = 0b01101011,
	SUBP  = 0b01101100,
	DIFF  = 0b01101101,
	CMP   = 0b01101110,
	ICMP  = 0b01101111,
	SHL   = 0b10000000,
	SHR   = 0b10000001,
	AND   = 0b10000010,
	OR    = 0b10000011,
	XOR   = 0b10000100,
	NOT   = 0b10000101,
	OUT   = 0b10100000,
	IN    = 0b10100001,
	CHK   = 0b10100010,
	ACTV  = 0b10100011,
	JMP   = 0b11000000,
	JMPB  = 0b11000001,
	JZ    = 0b11000100,
	JNZ   = 0b11000110,
	JS    = 0b11001000,
	JNS   = 0b11001010,
	JC    = 0b11001100,
	JNC   = 0b11001110,
	JZB   = 0b11000101,
	JNZB  = 0b11000111,
	JSB   = 0b11001001,
	JNSB  = 0b11001011,
	JCB   = 0b11001101,
	JNCB  = 0b11001111,
	CALL  = 0b11111010,
	CALLB = 0b11111011,
	RET   = 0b11111100,
	INT   = 0b11111101,
	HLT   = 0b11111110
}

class Emulator {
	// registers
	ushort a;
	ushort b;
	ushort c;
	ushort d;
	ushort e;
	ushort f;
	ushort g;
	ushort h;
	ubyte  flags;

	// register pairs
	uint ip;
	uint sp;
	uint bs;
	uint ds;
	uint sr;

	// system stuff
	ubyte[0x1000000] ram;
	bool             halted;
	Display          display;
	Device[256]      devices;

	// config
	static const double speed = 20; // MHz

	this(bool enableSerial, string[] allowedIPs) {
		display     = new Display();
		display.emu = this;
		display.Init();

		devices[0] = new DebuggingDevice();
		devices[1] = new KeyboardDevice();
		devices[2] = new GraphicsDevice();

		if (enableSerial) {
			devices[0x20] = new SerialDevice(4040, allowedIPs);
		}

		writeln("Connected devices");
		size_t lastDevice;
		foreach (i, ref dev ; devices) {
			if (dev is null) continue;
			dev.emu = this;

			writefln(" - (%d) %s", i, dev.name);
			lastDevice = i;
		}

		writefln(" - (%d) Nvidia RTX 4090 Ti", lastDevice + 1);
	}

	~this() {
		display.Free();
	}

	bool GetFlag(ubyte flag) {
		return flags & flag? true : false;
	}

	bool GetFlag(Flag flag) {
		return GetFlag(cast(ubyte) flag);
	}

	void SetFlag(ubyte flag, bool on) {
		if (on) {
			flags |= flag;
		}
		else {
			flags &= ~flag;
		}
	}

	void SetFlag(Flag flag, bool on) {
		SetFlag(cast(ubyte) flag, on);
	}

	void SetValueFlags(ushort value) {
		SetFlag(Flag.Zero, value == 0);
		SetFlag(Flag.Sign, value & 0x8000? true : false);
	}

	void SetValueFlags(uint value) {
		SetFlag(Flag.Zero, value == 0);
	}

	ushort ReadRegister(Register reg) {
		switch (reg) {
			case Register.A: return a;
			case Register.B: return b;
			case Register.C: return c;
			case Register.D: return d;
			case Register.E: return e;
			case Register.F: return f;
			case Register.G: return g;
			case Register.H: return h;
			default:         assert(0); // TODO: error
		}
	}

	ushort ReadRegister(ubyte reg) {
		return ReadRegister(cast(Register) reg);
	}

	void WriteRegister(Register reg, ushort value) {
		switch (reg) {
			case Register.A: a = value; break;
			case Register.B: b = value; break;
			case Register.C: c = value; break;
			case Register.D: d = value; break;
			case Register.E: e = value; break;
			case Register.F: f = value; break;
			case Register.G: g = value; break;
			case Register.H: h = value; break;
			default:         assert(0); // TODO: error
		}
	}

	void WriteRegister(ubyte reg, ushort value) {
		WriteRegister(cast(Register) reg, value);
	}

	uint ReadRegPair(RegPair reg) {
		switch (reg) {
			case RegPair.AB: return (cast(uint) (a & 0xFF) << 16) | cast(uint) b;
			case RegPair.CD: return (cast(uint) (c & 0xFF) << 16) | cast(uint) d;
			case RegPair.EF: return (cast(uint) (e & 0xFF) << 16) | cast(uint) f;
			case RegPair.GH: return (cast(uint) (g & 0xFF) << 16) | cast(uint) h;
			case RegPair.IP: return ip;
			case RegPair.SP: return sp;
			case RegPair.BS: return bs;
			case RegPair.DS: return ds;
			case RegPair.SR: return sr;
			default:         assert(0); // TODO: error
		}
	}

	uint ReadRegPair(ubyte reg) {
		return ReadRegPair(cast(RegPair) reg);
	}

	void WriteRegPair(RegPair reg, uint value) {
		switch (reg) {
			case RegPair.AB: {
				a = cast(ushort) (value >> 16);
				b = cast(ushort) (value & 0xFFFF);
				break;
			}
			case RegPair.CD: {
				c = cast(ushort) (value >> 16);
				d = cast(ushort) (value & 0xFFFF);
				break;
			}
			case RegPair.EF: {
				e = cast(ushort) (value >> 16);
				f = cast(ushort) (value & 0xFFFF);
				break;
			}
			case RegPair.GH: {
				g = cast(ushort) (value >> 16);
				h = cast(ushort) (value & 0xFFFF);
				break;
			}
			case RegPair.IP: ip = value; break;
			case RegPair.SP: sp = value; break;
			case RegPair.BS: bs = value; break;
			case RegPair.DS: ds = value; break;
			case RegPair.SR: sr = value; break;
			default: assert(0); // TODO: error
		}
	}

	void WriteRegPair(ubyte reg, uint value) {
		return WriteRegPair(cast(RegPair) reg, value);
	}

	ubyte NextByte() {
		ubyte ret = ram[ip];
		++ ip;
		return ret;
	}

	ushort NextWord() {
		return (cast(ushort) NextByte()) | (cast(ushort) NextByte() << 8);
	}

	uint NextAddr() {
		return
			(cast(uint) NextByte()) | 
			(cast(uint) NextByte() << 8) |
			(cast(uint) NextByte() << 16);
	}

	ubyte Next1Nibble() {
		return NextByte() & 0x0F;
	}

	void Next2Nibbles(ubyte* n1, ubyte* n2) {
		auto value = NextByte();
		*n1        = (value & 0xF0) >> 4;
		*n2        = value & 0x0F;
	}

	ushort ReadWord(uint addr) {
		return (cast(ushort) ram[addr]) | (cast(ushort) ram[addr + 1] << 8);
	}

	void WriteWord(uint addr, ushort value) {
		ram[addr]     = cast(ubyte) (value & 0xFF);
		ram[addr + 1] = cast(ubyte) ((value & 0xFF00) >> 8);
	}

	uint ReadAddr(uint addr) {
		return (cast(uint) ram[addr]) | (cast(uint) ram[addr + 1] << 8) |
		       (cast(uint) ram[addr + 2] << 16);
	}

	void WriteAddr(uint addr, uint value) {
		ram[addr]     = cast(ubyte) (value & 0xFF);
		ram[addr + 1] = cast(ubyte) ((value & 0xFF00) >> 8);
		ram[addr + 2] = cast(ubyte) ((value & 0xFF0000) >> 16);
	}

	void LoadData(uint where, const ubyte[] data) {
		ram[where .. where + data.length] = data;
	}

	void Error(Char, A...)(in Char[] fmt, A args) {
		stderr.writeln(format(fmt, args));
		halted = true;
	}

	void DumpState() {
		writeln("YETI-16 State");
		writeln("=============");
		writefln("A  = %.4X", a);
		writefln("B  = %.4X", b);
		writefln("C  = %.4X", c);
		writefln("D  = %.4X", d);
		writefln("E  = %.4X", e);
		writefln("F  = %.4X", f);
		writefln("G  = %.4X", g);
		writefln("H  = %.4X", h);
		writefln("IP = %.6X", ip);
		writefln("SP = %.6X", sp);
		writefln("BS = %.6X", bs);
		writefln("DS = %.6X", ds);
		writefln("SR = %.6X", sr);
	}

	void RunInstruction() {
		ubyte op = NextByte();

		switch (op) {
			// group 0
			case Instruction.NOP: return;
			// register group
			case Instruction.LDI: {
				auto reg   = Next1Nibble();
				auto value = NextWord();
				WriteRegister(reg, value);
				SetValueFlags(value);
				break;
			}
			case Instruction.LDSI: {
				auto reg   = Next1Nibble();
				auto value = NextByte();
				WriteRegister(reg, value);
				SetValueFlags(value);
				break;
			}
			case Instruction.CPR: {
				ubyte dest;
				ubyte src;
				Next2Nibbles(&dest, &src);
				WriteRegister(dest, ReadRegister(src));
				SetValueFlags(ReadRegister(dest));
				break;
			}
			case Instruction.CPP: {
				ubyte dest;
				ubyte src;
				Next2Nibbles(&dest, &src);
				WriteRegPair(dest, ReadRegPair(src));
				SetValueFlags(ReadRegPair(dest));
				break;
			}
			case Instruction.LDA: {
				auto dest = Next1Nibble();
				WriteRegPair(dest, NextAddr());
				SetValueFlags(ReadRegPair(dest));
				break;
			}
			case Instruction.SETZ: SetFlag(Flag.Zero, true);   break;
			case Instruction.SETS: SetFlag(Flag.Sign, true);   break;
			case Instruction.SETC: SetFlag(Flag.Carry, true);  break;
			case Instruction.CLZ:  SetFlag(Flag.Zero, false);  break;
			case Instruction.CLS:  SetFlag(Flag.Sign, false);  break;
			case Instruction.CLC:  SetFlag(Flag.Carry, false); break;
			case Instruction.GETF: {
				auto dest = Next1Nibble();
				WriteRegister(dest, flags);
				break;
			}
			case Instruction.SETF: {
				auto src = Next1Nibble();
				flags = cast(ubyte) ReadRegister(src);
				break;
			}
			// memory group
			case Instruction.WRB:
			case Instruction.WRW:
			case Instruction.WRA:
			case Instruction.RDB:
			case Instruction.RDW:
			case Instruction.RDA:
			case Instruction.BWRB:
			case Instruction.BWRW:
			case Instruction.BWRA:
			case Instruction.BRDB:
			case Instruction.BRDW:
			case Instruction.BRDA: {
				ubyte operation = (op & 0b00001000) >> 3;
				ubyte size      = (op & 0b00000110) >> 1;
				ubyte addBS     = (op & 0b00000001);

				if (operation) { // write
					ubyte addrReg;
					ubyte valueReg;
					Next2Nibbles(&addrReg, &valueReg);
					auto addr = ReadRegPair(addrReg);

					if (addBS) {
						addr += bs;
					}

					switch (size) {
						case 0: {
							ram[addr] = cast(ubyte) ReadRegister(valueReg);
							SetValueFlags(ReadRegister(valueReg));
							break;
						}
						case 1: {
							WriteWord(addr, ReadRegister(valueReg));
							SetValueFlags(ReadRegister(valueReg));
							break;
						}
						case 2: {
							WriteAddr(addr, ReadRegPair(valueReg));
							SetValueFlags(ReadRegPair(valueReg));
							break;
						}
						default: assert(0); // TODO: error
					}
				}
				else { // read
					ubyte resultReg;
					ubyte addrReg;
					Next2Nibbles(&resultReg, &addrReg);
					auto addr = ReadRegPair(addrReg);

					if (addBS) {
						addr += bs;
					}

					switch (size) {
						case 0: {
							WriteRegister(resultReg, ram[addr]);
							SetValueFlags(ReadRegister(resultReg));
							break;
						}
						case 1: {
							WriteRegister(resultReg, ReadWord(addr));
							SetValueFlags(ReadRegister(resultReg));
							break;
						}
						case 2: {
							WriteRegPair(resultReg, ReadAddr(addr));
							SetValueFlags(ReadRegPair(resultReg));
							break;
						}
						default: assert(0); // TODO: error
					}
				}
				break;
			}
			case Instruction.PUSH: {
				auto reg = Next1Nibble();
				sp -= 2;
				WriteWord(sp, ReadRegister(reg));
				break;
			}
			case Instruction.POP: {
				auto reg = Next1Nibble();
				WriteRegister(reg, ReadWord(sp));
				sp += 2;
				break;
			}
			case Instruction.PUSHA: {
				auto reg = Next1Nibble();
				sp -= 3;
				WriteAddr(sp, ReadRegPair(reg));
				break;
			}
			case Instruction.POPA: {
				auto reg = Next1Nibble();
				WriteRegPair(reg, ReadAddr(sp));
				sp += 3;
				break;
			}
			// arithmetic group
			case Instruction.ADD: .. case Instruction.IMOD: {
				ubyte dest;
				ubyte operand;
				Next2Nibbles(&dest, &operand);

				auto v1 = ReadRegister(dest);
				auto v2 = ReadRegister(operand);

				uint res;

				final switch (op) {
					case Instruction.ADD: res = v1 + v2; break;
					case Instruction.SUB: res = v1 - v2; break;
					case Instruction.MUL: res = v1 * v2; break;
					case Instruction.DIV: res = v1 / v2; break;
					case Instruction.MOD: res = v1 % v2; break;
					case Instruction.IDIV: {
						WriteRegister(dest, ToUnsigned(ToSigned(v1) / ToSigned(v2)));
						break;
					}
					case Instruction.IMOD: {
						WriteRegister(dest, ToUnsigned(ToSigned(v1) % ToSigned(v2)));
						break;
					}
				}

				WriteRegister(dest, cast(ushort) (res & 0xFFFF));
				SetValueFlags(ReadRegister(dest));
				if (res & 0xFFFF0000) {
					SetFlag(Flag.Carry, true);
				}
				else {
					SetFlag(Flag.Carry, false);
				}
				break;
			}
			case Instruction.INC: {
				auto reg = Next1Nibble();

				if (ReadRegister(reg) == 0xFFFF) {
					SetFlag(Flag.Carry, true);
					SetFlag(Flag.Zero, true);
					WriteRegister(reg, 0);
				}
				else {
					SetFlag(Flag.Carry, false);
					SetFlag(Flag.Zero, false);
					WriteRegister(reg, cast(ushort) (ReadRegister(reg) + 1));
				}
				break;
			}
			case Instruction.DEC: {
				auto reg = Next1Nibble();

				if (ReadRegister(reg) == 0) {
					SetFlag(Flag.Carry, true);
					SetFlag(Flag.Zero, false);
					WriteRegister(reg, 0xFFFF);
				}
				else {
					SetFlag(Flag.Carry, false);
					WriteRegister(reg, cast(ushort) (ReadRegister(reg) - 1));

					if (ReadRegister(reg) == 0) {
						SetFlag(Flag.Zero, true);
					}
				}
				break;
			}
			case Instruction.INCP: {
				auto reg = Next1Nibble();

				if (ReadRegPair(reg) == 0xFFFFFF) {
					SetFlag(Flag.Carry, true);
					SetFlag(Flag.Zero, true);
					WriteRegPair(reg, 0);
				}
				else {
					SetFlag(Flag.Carry, false);
					SetFlag(Flag.Zero, false);
					WriteRegPair(reg, ReadRegPair(reg) + 1);
				}
				break;
			}
			case Instruction.DECP: {
				auto reg = Next1Nibble();

				if (ReadRegPair(reg) == 0) {
					SetFlag(Flag.Carry, true);
					SetFlag(Flag.Zero, false);
					WriteRegPair(reg, 0xFFFFFF);
				}
				else {
					SetFlag(Flag.Carry, false);
					WriteRegPair(reg, ReadRegPair(reg) - 1);

					if (ReadRegPair(reg) == 0) {
						SetFlag(Flag.Zero, true);
					}
				}
				break;
			}
			case Instruction.ADDP:
			case Instruction.SUBP: {
				ubyte dest;
				ubyte operand;
				Next2Nibbles(&dest, &operand);

				auto v1 = ReadRegPair(dest);
				auto v2 = ReadRegister(operand);

				uint res;

				final switch (op) {
					case Instruction.ADD: res = v1 + v2; break;
					case Instruction.SUB: res = v1 - v2; break;
				}

				WriteRegPair(dest, cast(ushort) (res & 0xFFFFFF));
				SetValueFlags(ReadRegPair(dest));
				SetFlag(Flag.Carry, res & 0xFF000000? true : false);
				break;
			}
			case Instruction.DIFF: {
				ubyte dest;
				ubyte v1;
				ubyte v2;
				Next2Nibbles(&dest, &v1);
				v2 = Next1Nibble();

				int res = cast(short) (
					cast(int) ReadRegPair(v1) - cast(int) ReadRegPair(v2)
				);
				WriteRegister(dest, ToUnsigned(cast(ushort) (res & 0xFFFF)));

				SetFlag(Flag.Zero, (res & 0xFFFF) == 0);
				SetFlag(Flag.Carry, res & 0xFFFF0000? true : false);
				SetFlag(Flag.Sign, res < 0);
				break;
			}
			case Instruction.CMP:
			case Instruction.ICMP: {
				ubyte v1;
				ubyte v2;
				Next2Nibbles(&v1, &v2);
				SetFlag(Flag.Zero, ReadRegister(v1) == ReadRegister(v2));

				if (op == Instruction.CMP) {
					SetFlag(Flag.Sign, ReadRegister(v1) > ReadRegister(v2));
					SetFlag(Flag.Carry, ReadRegister(v1) < ReadRegister(v2));
				}
				else {
					auto sv1 = ReadRegister(v1).ToSigned();
					auto sv2 = ReadRegister(v2).ToSigned();
					SetFlag(Flag.Sign, sv1 > sv2);
					SetFlag(Flag.Carry, sv1 < sv2);
				}
				break;
			}
			case Instruction.SHL: .. case Instruction.XOR: {
				ubyte dest;
				ubyte operand;
				Next2Nibbles(&dest, &operand);

				ushort res;
				auto   v1 = ReadRegister(dest);
				auto   v2 = ReadRegister(operand);

				final switch (op) {
					case Instruction.SHL: res = cast(ushort) (v1 << v2); break;
					case Instruction.SHR: res = cast(ushort) (v1 >> v2); break;
					case Instruction.AND: res = cast(ushort) (v1 & v2); break;
					case Instruction.OR:  res = cast(ushort) (v1 | v2); break;
					case Instruction.XOR: res = cast(ushort) (v1 ^ v2); break;
				}

				SetFlag(Flag.Zero, res == 0);
				WriteRegister(dest, res);
				break;
			}
			case Instruction.NOT: {
				auto val = Next1Nibble();
				WriteRegister(val, cast(ushort) ~ReadRegister(val));
				SetFlag(Flag.Zero, ReadRegister(val) == 0);
				break;
			}
			case Instruction.OUT: {
				ubyte devReg;
				ubyte valueReg;
				Next2Nibbles(&devReg, &valueReg);

				auto dev   = ReadRegister(devReg) & 0xFF;
				auto value = ReadRegister(valueReg);

				if (devices[dev] is null) assert(0); // TODO: error

				devices[dev].Out(value);
				break;
			}
			case Instruction.IN: {
				ubyte destReg;
				ubyte devReg;
				Next2Nibbles(&destReg, &devReg);

				auto dev = ReadRegister(devReg) & 0xFF;

				if (devices[dev] is null) assert(0); // TODO: error
				if (devices[dev].data.empty) assert(0); // TODO: error

				WriteRegister(destReg, devices[dev].data[0]);
				devices[dev].data = devices[dev].data[1 .. $];
				break;
			}
			case Instruction.CHK: {
				auto devReg = Next1Nibble();
				auto dev    = ReadRegister(devReg) & 0xFF;

				if (devices[dev] is null) assert(0); // TODO: error

				SetFlag(Flag.Zero, devices[dev].data.empty? 0 : 1);
				break;
			}
			case Instruction.ACTV: {
				auto devReg = Next1Nibble();
				auto dev    = ReadRegister(devReg) & 0xFF;

				SetFlag(Flag.Zero, devices[dev] is null? 0 : 1);
				break;
			}
			case Instruction.JMP: .. case Instruction.JNCB: {
				auto condition = (op & 0b00011100) >> 2;
				auto not       = (op & 0b00000010) >> 1;
				auto addBS     = op & 0b00000001;

				auto addr = NextAddr();
				if (addBS) {
					addr += bs;
				}

				bool doJump;
				switch (condition) {
					case 0: doJump = true; break;
					case 1: doJump = GetFlag(Flag.Zero); break;
					case 2: doJump = GetFlag(Flag.Sign); break;
					case 3: doJump = GetFlag(Flag.Carry); break;
					default: assert(0); // TODO: error
				}

				if (not) doJump = !doJump;

				if (doJump) {
					ip = addr;
				}
				break;
			}
			case Instruction.CALL:
			case Instruction.CALLB: {
				auto addr = NextAddr();
				sp -= 3;
				WriteAddr(sp, ip);

				if (op == Instruction.CALLB) {
					addr += bs;
				}
				ip = addr;
				break;
			}
			case Instruction.RET: {
				ip  = ReadAddr(sp);
				sp += 3;
				break;
			}
			case Instruction.INT: {
				uint interrupt = NextByte();

				ubyte iflags = ram[(interrupt * 4) + 4];

				if (!iflags) assert(0); // TODO: error

				auto addr  = ReadAddr((interrupt * 4) + 5);
				sp        -= 3;
				WriteAddr(sp, ip);
				ip = addr;
				break;
			}
			// control group
			case Instruction.HLT: {
				halted = true;
				return;
			}
			default: {
				Error("Invalid opcode %.2X", op);
			}
		}
	}

	void Run() {
		double frameTimeGoal = 1000.0 / 60.0;
		auto   instPerFrame  = cast(uint) ((Emulator.speed * 1000000) / 60);

		ip = 0x050000;
		sp = 0x0F0000;
		bs = ip;

		while (!halted) {
			auto sw = StopWatch(AutoStart.yes);

			SDL_Event e;
			while (SDL_PollEvent(&e)) {
				switch (e.type) {
					case SDL_QUIT: return;
					default: {
						foreach (ref dev ; devices) {
							if (dev is null) continue;
							dev.HandleEvent(&e);
						}
						break;
					}
				}
			}

			foreach (i ; 0 .. instPerFrame) {
				RunInstruction();
				if (halted) {
					break;
				}
			}

			foreach (ref dev ; devices) {
				if (dev is null) continue;

				dev.Update();
			}

			display.Render();
			sw.stop();

			double frameTime = sw.peek.total!("msecs");
			if (frameTimeGoal > frameTime) {
				Thread.sleep(dur!("msecs")(cast(long) (frameTimeGoal - frameTime)));
			}
		}
	}
}
