module yeti16.devices.debugging;

import std.stdio;
import std.algorithm;
import yeti16.device;

class DebuggingDevice : Device {
	this() {
		name = "YETI-16 Debug Device";
	}

	override void Out(ushort dataIn) {
		writef("%c", cast(char) dataIn);
		stdout.flush();
	}

	override void Update() {
		
	}

	override void HandleEvent(SDL_Event* e) {
		
	}
}
