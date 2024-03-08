module yeti16.devices.graphics;

import yeti16.font;
import yeti16.device;
import yeti16.display;
import yeti16.palette;

class GraphicsDevice : Device {
	ushort[] outData;

	this() {
		name  = "YETI-16 Graphics Controller";
	}

	override void Out(ushort dataIn) {
		outData ~= dataIn;

		switch (outData[0]) {
			case 0x00: { // change graphics mode
				if (outData.length < 2) {
					return;
				}

				emu.display.SetMode(cast(ubyte) (outData[1] & 0xFF));
				outData = [];
				break;
			}
			case 0x01: { // load font
				auto mode = emu.display.videoModes[emu.display.mode];

				if (!mode.available) break;
				if (mode.type != VideoModeType.Text) break;

				uint fontAddr = 0x000434;

				foreach (i, ref b ; font8x8) {
					emu.WriteByte(cast(uint) (fontAddr + i), b);
				}
				outData = [];
				break;
			}
			case 0x02: { // load palette
				auto mode = emu.display.videoModes[emu.display.mode];

				if (!mode.available) break;

				uint    paletteAddr = 0x000404;
				ubyte[] palette;

				switch (mode.bpp) {
					case 4: palette = cast(ubyte[]) palette16;  break;
					case 8: palette = cast(ubyte[]) palette256; break;
					default: assert(0);
				}

				foreach (i, ref b ; palette) {
					emu.WriteByte(cast(uint) (paletteAddr + i), b);
				}
				outData = [];
				break;
			}
			case 0x03: { // set draw interrupt
				if (outData.length < 2) return;

				emu.display.drawInterrupt = cast(ubyte) (outData[1] & 0xFF);
				outData                   = [];
				break;
			}
			default: outData = []; // there's no real way to error :(
		}
	}

	override void Update() {
		
	}

	override void HandleEvent(SDL_Event* e) {
		
	}
}
