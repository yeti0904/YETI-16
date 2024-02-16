module yeti16.display;

import std.file;
import std.path;
import std.stdio;
import std.string;
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
	Vec2!int      size;

	this(VideoModeType ptype, Vec2!int psize) {
		available = true;
		type      = ptype;
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
		videoModes[0x00] = VideoMode(VideoModeType.Bitmap, Vec2!int(320, 200));
	}

	void Init() {
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
				break;
			}
		}

		SDL_UpdateTexture(texture, null, pixels.ptr, resolution.x * 4);
		SDL_RenderCopy(renderer, texture, null, null);
		SDL_RenderPresent(renderer);
	}
}
