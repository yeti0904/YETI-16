module yeti16.devices.graphics;

import yeti16.font;
import yeti16.device;
import yeti16.display;
import yeti16.palette;

private enum State {
	None,
	GraphicsMode
}

class GraphicsDevice : Device {
	State state;

	this() {
		name  = "YETI-16 Graphics Controller";
		state = State.None;
	}

	override void Out(ushort dataIn) {
		final switch (state) {
			case State.None: {
				switch (dataIn) {
					case 0x00: { // change graphics mode
						state = State.GraphicsMode;
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
						break;
					}
					default: break; // there's no real way to error :(
				}
				break;
			}
			case State.GraphicsMode: {
				emu.display.SetMode(cast(ubyte) (dataIn & 0xFF));
				state = State.None;
				break;
			}
		}
	}

	override void Update() {
		
	}

	override void HandleEvent(SDL_Event* e) {
		
	}
}
