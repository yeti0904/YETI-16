module yeti16.device;

public import bindbc.sdl;
public import yeti16.emulator;

class Device {
	Emulator emu;
	string   name;
	ushort[] data; // read with IN

	abstract void Out(ushort dataIn);
	abstract void Update();
	abstract void HandleEvent(SDL_Event* e);
}
