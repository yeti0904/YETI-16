module yeti16.app;

import std.stdio;
import yeti16.emulator;

void main() {
	ubyte[] program = [
		0b00100001, 0x00, 0x69, // LDSI A, 0x69
		0b11111110              // HLT
	];

	auto emulator = new Emulator();
	emulator.LoadProgram(0x1000, program);
	emulator.ip = 0x1000;

	while (!emulator.halted) {
		emulator.RunInstruction();
	}

	emulator.DumpState();
}
