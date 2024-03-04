module yeti16.devices.mouse;

import std.stdio;
import std.string;
import std.math.rounding;
import std.algorithm.comparison;
import yeti16.device;


class MouseDevice : Device {
	ubyte mouseX  = 40;
	ubyte mouseY  = 25;
	ubyte mouseBx = 80;
	ubyte mouseBy = 40;

	this() {
		name = "YETI-16 Mouse";
	}

	override void Out(ushort dataIn) {
		switch (dataIn & 0xff00)   {
			case 0x0000: { // Reset mouse pos to center
				mouseX = cast(ubyte) floor(cast(float) mouseBx / 2.0);
				mouseY = cast(ubyte) floor(cast(float) mouseBy / 2.0);
				break;
			}
			case 0x0100: { // Set X bound
				mouseBx = (dataIn & 0x00ff);
				break;
			}
			case 0x0200: { // Set Y bound
				mouseBy = (dataIn & 0x00ff);
				break;
			}
			case 0x0300: { // Set X pos
				mouseX = (dataIn & 0x00ff);
				break;
			}
			case 0x0400: { // Set Y pos
				mouseY = (dataIn & 0x00ff);
				break;
			}
			default: break; // no errors!!
		}
	}

	override void Update() {
		
	}

	override void HandleEvent(SDL_Event* e) {
		switch (e.type) {
			case SDL_MOUSEMOTION: {	
				ubyte newMouseX = cast(ubyte) min(max(e.motion.x, 0), 320) / 4;
				ubyte newMouseY = cast(ubyte) min(max(e.motion.x, 0), 200) / 4;

				if (mouseX != newMouseX) {
					data ~= 0x01;
					data ~= newMouseX;
				}

				if (mouseY != newMouseY) {
					data ~= 0x02;
					data ~= newMouseY;
				}

				mouseX = newMouseX;
				mouseY = newMouseY;
				break;
			}
			case SDL_MOUSEBUTTONDOWN: {
				data ~= 0x03;
				data ~= cast(ubyte) e.button.button;
				break;
			}
			case SDL_MOUSEBUTTONUP: {
				data ~= 0x04;
				data ~= cast(ubyte) e.button.button;
				break;
			}
			case SDL_MOUSEWHEEL: {
				int scroll = e.wheel.y;

				if (scroll == 0) break;

				if (scroll > 0) {
					data ~= 0x05;
					data ~= cast(ubyte) scroll;
				} 
				else {
					data ~= 0x06;
					data ~= cast(ubyte) -scroll;
				}

				break;
			}
			default: break;
		}
	}
}
