# Graphics controller
The graphics controller is always on port 0x02

## Protocol
The graphics controller lets you send commands through `out`, with the first piece
of data sent being the command ID

Commands are listed below:
### 0x00 - Change graphics mode
The next value sent is the new graphics mode

### 0x01 - Load font
Loads the default font into where the font is stored in the current mode

This will do nothing in video modes that aren't text mode

### 0x02 - Load palette
Loads the default palette where the palette is stored in the current mode

### 0x03 - Set draw interrupt
The next value is an interrupt that is called after the screen is rendered

Set to zero for no interrupt to be called
