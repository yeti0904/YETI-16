# Display

## Palette structure
| Offset (bytes) | Value |
| 0              | Red   |
| 1              | Green |
| 2              | Blue  |

## Video modes
Mode 0x00 is the default

| Mode | Type   | Resolution | Colour depth (bpp) | Palette address | Font address | Data address |
| ---- | ------ | ---------- | ------------------ | --------------- | ------------ | ------------ |
| 0x00 | Bitmap | 320x200    | 8                  | 0x000404        | N/A          | 0x000704     |
