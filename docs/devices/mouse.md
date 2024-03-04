# Mouse device

The mouse device is always at port 0x03.

The mouse device's initial boundaries are (80, 50) [1/4 of screen size] and the mouse's initial position is (40, 25). A mouse move event will be sent by the mouse on device initialization.

If the mouse attempts to move outside of the boundaries, it should be moved to the relevant boundary.

## Protocol

### Out

The mouse has a command system, where every piece of data sent is a command

#### 0x00 - Reset mouse position to Floor(W/2), Floor(H/2)

Sets the mouse position to the middle of the screen. (ex. `0x00`) This command is not guaranteed to send an `in` event back.

#### 0x01 - Set boundary X

Set the X boundary of the mouse. The next value is the X boundary (ex. `0x0150`)

#### 0x02 - Set boundary Y

Set the Y boundary of the mouse. The next value is the Y boundary (ex. `0x0232`)

### 0x03 - Set mouse X

Set the mouse X position. The next value is the X position. (ex. `0x0301` moves the mouse to X = 0x01) This command is not guaranteed to send an `in` event.

### 0x04 - Set mouse Y

Set the mouse Y position. The next value is the X position. (ex. `0x0401` moves the mouse to Y = 0x01) This command is not guaranteed to send an `in` event.

### In

The mouse sends events through `in`, they all start with 1 value which is the event type

These are the events:

#### 0x01 - Mouse X moved

Sends when the mouse moved in the X direction. The next value is the X position.

Ex. `0x0101` means mouse moved to X = 0x01

#### 0x02 - Mouse Y moved

Sends when the mouse moved in the Y direction. The next value is the Y position.

Ex. `0x0201` means mouse moved to Y = 0x01

#### 0x03 - Mouse down

Sends when mouse button is pressed (ex. `0x0301` is a left click press)

The next value is the button code (ex. left click = 0x01, right click = 0x03, middle click = 0x02, 0x04+ are custom)

#### 0x04 - Mouse up

Sends when a mouse button is released (ex. `0x0401` is a left click release)

The next value is the button code (ex. left click = 0x01, right click = 0x03, middle click = 0x02, 0x04+ are custom)

#### 0x05 - Scroll Up

Sends when the mouse is scrolled up (ex. `0x0501` is a scroll up by 1)

The next value is the scroll amount (ex. scroll up by 1 = 0x01)

#### 0x06 - Scroll Down

Sends when the mouse is scrolled down (ex. `0x0601` is a scroll down by 1)

The next value is the scroll amount (ex. scroll down by 1 = 0x01)
