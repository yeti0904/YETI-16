# Disk device
Disk devices can be on any port between ports 0xF7 and 0xFF

They have 1 kibibyte per sector, with a maximum of 2^32 sectors

## Disk status value
- 0 - Success
- 1 - Sector out of bounds
- 2 - No space in memory

## Protocol
### Out
Disk devices use commands, the first value you send to a disk is the command type

The commands are listed below

#### 0x00 - Get size
Sends the amount of sectors through `in` as a 32-bit number, which means it is sent
as two values

First it sends the low 2 bytes, and then the high 2 bytes

#### 0x01 - Read sector to memory
Parameters:
- Sector index, low 16 bits
- Sector index, high 16 bits
- Memory address, low 16 bits
- Memory address, high 16 bits

It then writes the contents of the sector (1024 bytes) to that memory address

It sends a disk status value through `in`

#### 0x02 - Write sector to memory
Parameters:
- Sector index, low 16 bits
- Sector index, high 16 bits
- Memory address, low 16 bits
- Memory address, high 16 bits

It then writes the contents of that area of memory (1024 bytes) to the sector
