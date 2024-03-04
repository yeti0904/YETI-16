module yeti16.display;

import std.file;
import std.path;
import std.stdio;
import std.string;
import std.process;
import bindbc.sdl;
import yeti16.util;
import yeti16.types;
import yeti16.palette;
import yeti16.emulator;

enum VideoModeType {
	Bitmap,
	Text
}

struct VideoMode {
	bool available = false;
	
	VideoModeType type;
	ubyte         bpp;
	Vec2!int      size;

	this(VideoModeType ptype, ubyte pbpp, Vec2!int psize) {
		available = true;
		type      = ptype;
		bpp       = pbpp;
		size      = psize;
	}
}

class Display {
	Emulator       emu;
	SDL_Window*    window;
	SDL_Renderer*  renderer;
	SDL_Texture*   texture;
	uint[]         pixels;
	Vec2!int       resolution = Vec2!int(320, 200);
	ubyte          mode;
	VideoMode[256] videoModes;

	this() {
		videoModes[0x00] = VideoMode(VideoModeType.Bitmap, 8, Vec2!int(320, 200));
		videoModes[0x10] = VideoMode(VideoModeType.Text,   4, Vec2!int(80,  40));
		videoModes[0x11] = VideoMode(VideoModeType.Text,   4, Vec2!int(40,  40));
		videoModes[0x12] = VideoMode(VideoModeType.Text,   4, Vec2!int(40,  20));
		videoModes[0x13] = VideoMode(VideoModeType.Text,   4, Vec2!int(20,  20));
	}

	void Init() {
		// make SDL use wayland if wayland is running
		if (environment.get("XDG_SESSION_TYPE", "") == "wayland") {
			environment["SDL_VIDEODRIVER"] = "wayland";
		}

		string appPath = dirName(thisExePath());
	
		version (Windows) {
			if (!exists(appPath ~ "/SDL2.dll")) {
				stderr.writeln("SDL2 required");
				exit(1);
			}
		
			auto res = loadSDL(format("%s/SDL2.dll", appPath).toStringz());
		}
		else {
			auto res = loadSDL();
		}
	
		if (res != sdlSupport) {
			stderr.writeln("No SDL support");
			exit(1);
		}

		if (SDL_Init(SDL_INIT_VIDEO) < 0) {
			stderr.writefln("Failed to initialise SDL: %s", GetError());
			exit(1);
		}

		window = SDL_CreateWindow(
			toStringz("YETI-16"), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
			640, 400, SDL_WINDOW_RESIZABLE
		);

		if (window is null) {
			stderr.writefln("Failed to create window: %s", GetError());
			exit(1);
		}

		renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

		if (renderer is null) {
			stderr.writefln("Failed to create renderer: %s", GetError());
			exit(1);
		}

		texture = SDL_CreateTexture(
			renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING,
			resolution.x, resolution.y
		);

		if (texture is null) {
			stderr.writefln("Failed to create texture: %s", GetError());
			exit(1);
		}

		pixels = new uint[](resolution.x * resolution.y);
		SDL_RenderSetLogicalSize(renderer, resolution.x, resolution.y);

		emu.LoadData(0x000404, palette256);
	}

	void Free() {
		if (texture)  SDL_DestroyTexture(texture);
		if (renderer) SDL_DestroyRenderer(renderer);
		if (window)   SDL_DestroyWindow(window);
		SDL_Quit();
	}

	string GetError() {
		return cast(string) SDL_GetError().fromStringz();
	}

	uint ColourToInt(ubyte r, ubyte g, ubyte b) {
		return r | (g << 8) | (b << 16) | (255 << 24);
	}

	void DrawPixel(uint x, uint y, ubyte r, ubyte g, ubyte b) {
		if ((x > resolution.x) || (y > resolution.y)) return;
		pixels[(y * resolution.x) + x] = ColourToInt(r, g, b);
	}

	void SetMode(ubyte pmode) {
		mode = pmode;
		writefln("Setting video mode to %.2X", mode);

		if (!videoModes[mode].available) return;

		final switch (videoModes[mode].type) {
			case VideoModeType.Bitmap: {
				resolution = videoModes[mode].size;
				break;
			}
			case VideoModeType.Text: {
				resolution = Vec2!int(
					videoModes[mode].size.x * 8,
					videoModes[mode].size.y * 8
				);
				break;
			}
		}

		pixels = new uint[](resolution.x * resolution.y);
		SDL_DestroyTexture(texture);
		texture = SDL_CreateTexture(
			renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING,
			resolution.x, resolution.y
		);

		if (texture is null) {
			stderr.writefln("Failed to create texture: %s", GetError());
			exit(1);
		}

		SDL_RenderSetLogicalSize(renderer, resolution.x, resolution.y);
	}

	void Render() {
		auto deathColour = SDL_Colour(255, 0, 0, 255);
		auto mode        = videoModes[mode];

		if (!mode.available) {
			SDL_SetRenderDrawColor(
				renderer, deathColour.r, deathColour.g, deathColour.b, 255
			);
			SDL_RenderClear(renderer);
			SDL_RenderPresent(renderer);
			return;
		}

		final switch (mode.type) {
			case VideoModeType.Bitmap: {
				uint paletteAddr = 0x000404;
				uint pixelAddr   = 0x000704;
				uint pixelEnd    = pixelAddr + cast(uint) (resolution.x * resolution.y);

				SDL_SetRenderDrawColor(
					renderer, emu.ram[paletteAddr], emu.ram[paletteAddr + 1],
					emu.ram[paletteAddr + 2], 255
				);
				SDL_RenderClear(renderer);

				for (uint i = pixelAddr; i < pixelEnd; ++ i) {
					uint  offset   = i - pixelAddr;
					ubyte colour   = emu.ram[i];
					pixels[offset] = ColourToInt(
						emu.ram[paletteAddr + (colour * 3)],
						emu.ram[paletteAddr + (colour * 3) + 1],
						emu.ram[paletteAddr + (colour * 3) + 2]
					);
				}
				break;
			}
			case VideoModeType.Text: {
				uint paletteAddr = 0x000404;
				uint fontAddr    = 0x000434;
				uint dataAddr    = 0x000C34;

				auto cellDim = mode.size;

				SDL_SetRenderDrawColor(
					renderer, emu.ram[paletteAddr], emu.ram[paletteAddr + 1],
					emu.ram[paletteAddr + 2], 255
				);
				SDL_RenderClear(renderer);

				for (uint y = 0; y < cellDim.y; ++ y) {
					for (uint x = 0; x < cellDim.x; ++ x) {
						uint    chAddr = dataAddr + (((y * cellDim.x) + x) * 2);
						char    ch     = emu.ram[chAddr + 1];
						ubyte[] chFont = emu.ram[
							fontAddr + (ch * 8) .. fontAddr + ((ch * 8) + 8)
						];

						ubyte attr  = emu.ram[chAddr];
						uint  fgCol = attr & 0x0F;
						uint  bgCol = (attr & 0xF0) >> 4;

						auto fg = SDL_Color(
							emu.ram[paletteAddr + (fgCol * 3)],
							emu.ram[paletteAddr + (fgCol * 3) + 1],
							emu.ram[paletteAddr + (fgCol * 3) + 2],
							255
						);
						auto bg = SDL_Color(
							emu.ram[paletteAddr + (bgCol * 3)],
							emu.ram[paletteAddr + (bgCol * 3) + 1],
							emu.ram[paletteAddr + (bgCol * 3) + 2],
							255
						);

						for (uint cx = 0; cx < 8; ++ cx) {
							for (uint cy = 0; cy < 8; ++ cy) {
								auto pixelPos = Vec2!uint((x * 8) + cx, (y * 8) + cy);

								ubyte set = chFont[cy] & (1 << cx);

								if (set) {
									DrawPixel(pixelPos.x, pixelPos.y, fg.r, fg.g, fg.b);
								}
								else {
									DrawPixel(pixelPos.x, pixelPos.y, bg.r, bg.g, bg.b);
								}
							}
						}
					}
				}
				break;
			}
		}

		SDL_UpdateTexture(texture, null, pixels.ptr, resolution.x * 4);
		SDL_RenderCopy(renderer, texture, null, null);
		SDL_RenderPresent(renderer);
	}
}
