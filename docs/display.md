# Display

## Palette structure
This is the same for both text and bitmap modes
| Offset (bytes) | Value |
| -------------- | ----- |
| 0              | Red   |
| 1              | Green |
| 2              | Blue  |

## Font format
The font is stored as 8 bytes for each of the 256 characters (as they are 8x8)

## Text data format
Each cell is stored as 2 bytes, with the following data:
| Offset (bytes) | Value      |
| -------------- | ---------- |
| 0              | Attributes |
| 1              | Character  |

The high nibble of the attribute is the background colour, and the low nibble is the
foreground colour

## Video modes
Mode 0x00 is the default

| Mode | Type   | Resolution or cell size | Colour depth (bpp) | Palette address | Font address | Data address |
| ---- | ------ | ----------------------- | ------------------ | --------------- | ------------ | ------------ |
| 0x00 | Bitmap | 320x200                 | 8                  | 0x000404        | N/A          | 0x000704     |
| 0x10 | Text   | 80x40                   | 4                  | 0x000404        | 0x000434     | 0x000C34     |
| 0x11 | Text   | 40x40                   | 4                  | 0x000404        | 0x000434     | 0x000C34     |
| 0x12 | Text   | 40x20                   | 4                  | 0x000404        | 0x000434     | 0x000C34     |
| 0x13 | Text   | 20x20                   | 4                  | 0x000404        | 0x000434     | 0x000C34     |
