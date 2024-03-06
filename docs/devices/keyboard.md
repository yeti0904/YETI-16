# Keyboard device
The keyboard device is always at port 0x01

## Protocol
### Out
The keyboard has a command system, where every piece of data sent is a command

These are the commands:
#### 0x00 - Enable ASCII translation
Enables ASCII character input events

#### 0x01 - Disable ASCII translation
Disables ASCII character input events

#### 0x02 - Enable keyboard events
Enables sending keyboard events through `in`

#### 0x03 - Disable keyboard events
Disables sending keyboard events through `in`

### In
The keyboard sends events through `in`, they all start with 1 value which is the event
type

These are the events:
#### 0x00 - ASCII key event
Note: Only sends if ASCII translation is enabled

Sends when an ASCII character key is pressed

The next value is the ASCII character that was pressed

#### 0x01 - Key down
Sends when any key is pressed

The next value is the key code

#### 0x02 - Key up
Sends when a key is released

The next value is the key code

## Key codes
| Key               | Value (decimal) |
| ----------------- | --------------- |
| Escape            | 256             |
| F1                | 257             |
| F2                | 258             |
| F3                | 259             |
| F4                | 260             |
| F5                | 261             |
| F6                | 262             |
| F7                | 263             |
| F8                | 264             |
| F9                | 265             |
| F10               | 266             |
| F11               | 267             |
| F12               | 268             |
| Home              | 269             |
| End               | 270             |
| Insert            | 271             |
| Delete            | 272             |
| Backtick          | 273             |
| N1                | 274             |
| N2                | 275             |
| N3                | 276             |
| N4                | 277             |
| N5                | 278             |
| N6                | 279             |
| N7                | 280             |
| N8                | 281             |
| N9                | 282             |
| N0                | 283             |
| Minus             | 284             |
| Equals            | 285             |
| Backspace         | 286             |
| Tab               | 287             |
| Q                 | 288             |
| W                 | 289             |
| E                 | 290             |
| R                 | 291             |
| T                 | 292             |
| Y                 | 293             |
| U                 | 294             |
| I                 | 295             |
| O                 | 296             |
| P                 | 297             |
| LeftSquare        | 298             |
| RightSquare       | 299             |
| CapsLock          | 300             |
| A                 | 301             |
| S                 | 302             |
| D                 | 303             |
| F                 | 304             |
| G                 | 305             |
| H                 | 306             |
| J                 | 307             |
| K                 | 308             |
| L                 | 309             |
| Semicolon         | 310             |
| SingleQuote       | 311             |
| Hashtag           | 312             |
| Enter             | 313             |
| LShift            | 314             |
| Backslash         | 315             |
| Z                 | 316             |
| X                 | 317             |
| C                 | 318             |
| V                 | 319             |
| B                 | 320             |
| N                 | 321             |
| M                 | 322             |
| Comma             | 323             |
| Dot               | 324             |
| ForwardSlash      | 325             |
| RShift            | 326             |
| LControl          | 327             |
| Alt               | 328             |
| Space             | 329             |
| AltGr             | 330             |
| PrintScreen       | 331             |
| RControl          | 332             |
| PageUp            | 333             |
| PageDown          | 334             |
| Up                | 335             |
| Down              | 336             |
| Left              | 337             |
| Right             | 338             |
