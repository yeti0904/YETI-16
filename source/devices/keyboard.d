module yeti16.devices.keyboard;

import std.stdio;
import std.string;
import yeti16.device;

enum Keycode : ushort {
	Escape = 256,
	F1,
	F2,
	F3,
	F4,
	F5,
	F6,
	F7,
	F8,
	F9,
	F10,
	F11,
	F12,
	Home,
	End,
	Insert,
	Delete,
	Backtick,
	N1,
	N2,
	N3,
	N4,
	N5,
	N6,
	N7,
	N8,
	N9,
	N0,
	Minus,
	Equals,
	Backspace,
	Tab,
	Q,
	W,
	E,
	R,
	T,
	Y,
	U,
	I,
	O,
	P,
	LeftSquare,
	RightSquare,
	CapsLock,
	A,
	S,
	D,
	F,
	G,
	H,
	J,
	K,
	L,
	Semicolon,
	SingleQuote,
	Hashtag,
	Enter,
	LShift,
	Backslash,
	Z,
	X,
	C,
	V,
	B,
	N,
	M,
	Comma,
	Dot,
	ForwardSlash,
	RShift,
	LControl,
	Alt,
	Space,
	AltGr,
	PrintScreen,
	RControl,
	PageUp,
	PageDown,
	Up,
	Down,
	Left,
	Right
}

private Keycode[SDL_Scancode] GetKeycodes() {
	return [
		SDL_SCANCODE_A:            Keycode.A,
		SDL_SCANCODE_B:            Keycode.B,
		SDL_SCANCODE_C:            Keycode.C,
		SDL_SCANCODE_D:            Keycode.D,
		SDL_SCANCODE_E:            Keycode.E,
		SDL_SCANCODE_F:            Keycode.F,
		SDL_SCANCODE_G:            Keycode.G,
		SDL_SCANCODE_H:            Keycode.H,
		SDL_SCANCODE_I:            Keycode.I,
		SDL_SCANCODE_J:            Keycode.J,
		SDL_SCANCODE_K:            Keycode.K,
		SDL_SCANCODE_L:            Keycode.L,
		SDL_SCANCODE_M:            Keycode.M,
		SDL_SCANCODE_N:            Keycode.N,
		SDL_SCANCODE_O:            Keycode.O,
		SDL_SCANCODE_P:            Keycode.P,
		SDL_SCANCODE_Q:            Keycode.Q,
		SDL_SCANCODE_R:            Keycode.R,
		SDL_SCANCODE_S:            Keycode.S,
		SDL_SCANCODE_T:            Keycode.T,
		SDL_SCANCODE_U:            Keycode.U,
		SDL_SCANCODE_V:            Keycode.V,
		SDL_SCANCODE_W:            Keycode.W,
		SDL_SCANCODE_Y:            Keycode.Y,
		SDL_SCANCODE_X:            Keycode.X,
		SDL_SCANCODE_Z:            Keycode.Z,
		SDL_SCANCODE_ESCAPE:       Keycode.Escape,
		SDL_SCANCODE_F1:           Keycode.F1,
		SDL_SCANCODE_F2:           Keycode.F2,
		SDL_SCANCODE_F3:           Keycode.F3,
		SDL_SCANCODE_F4:           Keycode.F4,
		SDL_SCANCODE_F5:           Keycode.F5,
		SDL_SCANCODE_F6:           Keycode.F6,
		SDL_SCANCODE_F7:           Keycode.F7,
		SDL_SCANCODE_F8:           Keycode.F8,
		SDL_SCANCODE_F9:           Keycode.F9,
		SDL_SCANCODE_F10:          Keycode.F10,
		SDL_SCANCODE_F11:          Keycode.F11,
		SDL_SCANCODE_F12:          Keycode.F12,
		SDL_SCANCODE_HOME:         Keycode.Home,
		SDL_SCANCODE_END:          Keycode.End,
		SDL_SCANCODE_INSERT:       Keycode.Insert,
		SDL_SCANCODE_DELETE:       Keycode.Delete,
		SDL_SCANCODE_GRAVE:        Keycode.Backtick,
		SDL_SCANCODE_1:            Keycode.N1,
		SDL_SCANCODE_2:            Keycode.N2,
		SDL_SCANCODE_3:            Keycode.N3,
		SDL_SCANCODE_4:            Keycode.N4,
		SDL_SCANCODE_5:            Keycode.N5,
		SDL_SCANCODE_6:            Keycode.N6,
		SDL_SCANCODE_7:            Keycode.N7,
		SDL_SCANCODE_8:            Keycode.N8,
		SDL_SCANCODE_9:            Keycode.N9,
		SDL_SCANCODE_0:            Keycode.N0,
		SDL_SCANCODE_MINUS:        Keycode.Minus,
		SDL_SCANCODE_EQUALS:       Keycode.Equals,
		SDL_SCANCODE_BACKSPACE:    Keycode.Backspace,
		SDL_SCANCODE_TAB:          Keycode.Tab,
		SDL_SCANCODE_LEFTBRACKET:  Keycode.LeftSquare,
		SDL_SCANCODE_RIGHTBRACKET: Keycode.RightSquare,
		SDL_SCANCODE_CAPSLOCK:     Keycode.CapsLock,
		SDL_SCANCODE_SEMICOLON:    Keycode.Semicolon,
		SDL_SCANCODE_APOSTROPHE:   Keycode.SingleQuote,
		SDL_SCANCODE_NONUSHASH:    Keycode.Hashtag,
		SDL_SCANCODE_RETURN:       Keycode.Enter,
		SDL_SCANCODE_LSHIFT:       Keycode.LShift,
		SDL_SCANCODE_BACKSLASH:    Keycode.Backslash,
		SDL_SCANCODE_COMMA:        Keycode.Comma,
		SDL_SCANCODE_PERIOD:       Keycode.Dot,
		SDL_SCANCODE_SLASH:        Keycode.ForwardSlash,
		SDL_SCANCODE_RSHIFT:       Keycode.RShift,
		SDL_SCANCODE_LCTRL:        Keycode.LControl,
		SDL_SCANCODE_LALT:         Keycode.Alt,
		SDL_SCANCODE_SPACE:        Keycode.Space,
		SDL_SCANCODE_RALT:         Keycode.AltGr,
		SDL_SCANCODE_PRINTSCREEN:  Keycode.PrintScreen,
		SDL_SCANCODE_RCTRL:        Keycode.RControl,
		SDL_SCANCODE_PAGEUP:       Keycode.PageUp,
		SDL_SCANCODE_PAGEDOWN:     Keycode.PageDown,
		SDL_SCANCODE_UP:           Keycode.Up,
		SDL_SCANCODE_DOWN:         Keycode.Down,
		SDL_SCANCODE_LEFT:         Keycode.Left,
		SDL_SCANCODE_RIGHT:        Keycode.Right
	];
}

private static Keycode[SDL_Scancode] keys;

class KeyboardDevice : Device {
	bool asciiTranslation;
	bool enableEvents = false;

	this() {
		name = "YETI-16 Keyboard";
		keys = GetKeycodes();
	}

	override void Out(ushort dataIn) {
		switch (dataIn) {
			case 0x00: { // enable ASCII translation
				asciiTranslation = true;
				SDL_StartTextInput();
				break;
			}
			case 0x01: { // disable ASCII translation
				asciiTranslation = false;
				SDL_StopTextInput();
				break;
			}
			case 0x02: { // enable keyboard events
				enableEvents = true;
				writeln("Keyboard events enabled");
				break;
			}
			case 0x03: { // disable keyboard events
				enableEvents = false;
				writeln("Keyboard events disabled");
				break;
			}
			default: break; // no errors!!
		}
	}

	override void Update() {

	}

	override void HandleEvent(SDL_Event* e) {
		if (!enableEvents) return;

		switch (e.type) {
			case SDL_TEXTINPUT: {
				foreach (ref ch ; e.text.text.fromStringz()) {
					data ~= 0x00; // ASCII key event
					data ~= ch;
				}
				break;
			}
			case SDL_KEYDOWN: {
				auto key = e.key.keysym.scancode in keys;

				if (key is null) break;

				data ~= 0x01; // key down event
				data ~= *key;
				break;
			}
			case SDL_KEYUP: {
				auto key = e.key.keysym.scancode in keys;

				if (key is null) break;

				data ~= 0x02; // key up event
				data ~= *key;
				break;
			}
			default: break;
		}
	}
}
