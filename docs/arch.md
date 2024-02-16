# YETI-16 Mk2 architecture

## Registers
Registers are stored in 4 bits in parameters, and each register is 16-bits big
- (0) A - General purpose
- (1) B - General purpose
- (2) C - General purpose
- (3) D - General purpose
- (4) E - General purpose
- (5) F - General purpose
- (6) G - General purpose
- (7) H - General purpose

### Flags register
There is also an 8-bit flags register, but it can't be used as a parameter

Here are it's flags:
- (& 0b00000001) Zero  (Z) - set if the value is 0
- (& 0b00000010) Sign  (S) - set if the value is negative
- (& 0b00000100) Carry (C) - set if the last operation needed a carry

## Register pairs
Registers are used to create 32-bit values, but only 24-bit operations can be used
for them

Register pairs are stored in 4 bits
- (0) AB (A high, B low)
- (1) CD (C high, D low)
- (2) EF (E high, F low)
- (3) GH (G high, H low)
- (4) IP (Instruction Pointer)
- (5) SP (Stack Pointer) - Points to the last value on the stack, which grows down
- (6) BS (Base Pointer) - Points to where the program is loaded
- (7) DS (Destination) - General purpose
- (8) SR (Source) - General purpose

## Instructions
YETI-16 Mk2 uses an 8-bit opcode

Below is a table showing how instructions are layed out in binary

Values:
- S = source register
- R = result register
- D = immediate data
- P = source register pair
- O = destination register pair
- I = opcode

Syntax:
- [value] = Value at address `value`
- value > device = Outputs byte `value` into `device`
- dest < device = Reads a byte from `device` and saves in `dest`
- I/ = signed division (two's complement)

Functions:
- `data_available(device)` = Returns 1 if data is available to read on the device
- `device_active(device)` = Returns 1 if the given device exists

Note: emulators don't have to implement any instructions that aren't in this table

| Mnemonic | Binary representation                           | Does                                 | Flags affected |
| -------- | ----------------------------------------------- | ------------------------------------ | -------------- |
| NOP      | `00000000`                                      | Nothing                              |                |
| LDI      | `00100000 0000RRRR DDDDDDDD DDDDDDDD`           | `R = D`                              | Z, S           |
| LDSI     | `00100001 0000RRRR DDDDDDDD`                    | `R = D`                              | Z, S           |
| CPR      | `00100010 RRRRSSSS`                             | `R = S`                              | Z, S           |
| CPP      | `00100011 OOOOPPPP`                             | `O = P`                              | Z              |
| LDA      | `00100100 0000OOOO DDDDDDDD DDDDDDDD DDDDDDDD`  | `O = D`                              | Z              |
| SETZ     | `00100101`                                      | `Z = 1`                              | Z              |
| SETS     | `00100110`                                      | `S = 1`                              | S              |
| SETC     | `00100111`                                      | `C = 1`                              | C              |
| CLZ      | `00101000`                                      | `Z = 0`                              | Z              |
| CLS      | `00101001`                                      | `S = 0`                              | S              |
| CLC      | `00101010`                                      | `C = 0`                              | C              |
| GETF     | `00101011 0000RRRR`                             | `R = flags`                          |                |
| SETF     | `00101100 0000SSSS`                             | `flags = S`                          | Z, S, C        |
| WRB      | `01001000 OOOOSSSS`                             | `[byte O] = (S & 0xFF)`              |                |
| WRW      | `01001010 OOOOSSSS`                             | `[word O] = S`                       |                |
| WRA      | `01001100 OOOOPPPP`                             | `[addr O] = P`                       |                |
| RDB      | `01000000 RRRRPPPP`                             | `R = [byte P]`                       |                |
| RDW      | `01000010 RRRRPPPP`                             | `R = [word P]`                       |                |
| RDA      | `01000100 OOOOPPPP`                             | `O = [addr P]`                       |                |
| BWRB     | `01001001 OOOOSSSS`                             | `[byte O + BS] = (S & 0xFF)`         |                |
| BWRW     | `01001011 OOOOSSSS`                             | `[word O + BS] = S`                  |                |
| BWRA     | `01001101 OOOOPPPP`                             | `[addr O + BS] = P`                  |                |
| BRDB     | `01000001 RRRRPPPP`                             | `R = [byte P + BS]`                  |                |
| BRDW     | `01000011 RRRRPPPP`                             | `R = [word P + BS]`                  |                |
| BRDA     | `01000101 OOOOPPPP`                             | `O = [addr P + BS]`                  |                |
| PUSH     | `01011100 0000SSSS`                             | `stack.push(S)`                      |                |
| POP      | `01011101 0000RRRR`                             | `R = stack.pop()`                    |                |
| PUSHA    | `01011110 0000PPPP`                             | `stack.push(P)`                      |                |
| POPA     | `01011111 0000OOOO`                             | `O = stack.pop()`                    |                |
| ADD      | `01100000 RRRRSSSS`                             | `R = R + S`                          | Z, S, C        |
| SUB      | `01100001 RRRRSSSS`                             | `R = R - S`                          | Z, S, C        |
| MUL      | `01100010 RRRRSSSS`                             | `R = R * S`                          | Z, S, C        |
| DIV      | `01100011 RRRRSSSS`                             | `R = R / S`                          | Z, S           |
| IDIV     | `01100100 RRRRSSSS`                             | `R = R I/ S`                         | Z, S           |
| MOD      | `01100101 RRRRSSSS`                             | `R = R % S`                          | Z, S           |
| IMOD     | `01100110 RRRRSSSS`                             | `R = R I% S`                         | Z, S           |
| INC      | `01100111 0000RRRR`                             | `R = R + 1`                          | Z, C           |
| DEC      | `01101000 0000RRRR`                             | `R = R - 1`                          | Z, C           |
| INCP     | `01101001 0000OOOO`                             | `O = O + 1`                          | Z, C           |
| DECP     | `01101010 0000OOOO`                             | `O = O - 1`                          | Z, C           |
| ADDP     | `01101011 OOOOSSSS`                             | `O = O + S`                          | Z, C           |
| SUBP     | `01101100 OOOOSSSS`                             | `O = O - S`                          | Z, C           |
| DIFF     | `01101101 RRRRPPPP 0000OOOO`                    | `R = P - O`                          | Z, C, S        |
| CMP      | `01101110 RRRRSSSS`                             | `set_flags(R, S) # See notes`        | Z, C, S        |
| ICMP     | `01101111 RRRRSSSS`                             | `set_flags_signed(R, S) # See notes` | Z, C, S        |
| SHL      | `10000000 RRRRSSSS`                             | `R = R << S`                         | Z, C           |
| SHR      | `10000001 RRRRSSSS`                             | `R = R >> S`                         | Z              |
| AND      | `10000010 RRRRSSSS`                             | `R = R & S`                          | Z              |
| OR       | `10000011 RRRRSSSS`                             | `R = R \| S`                         | Z              |
| XOR      | `10000100 RRRRSSSS`                             | `R = R ^ S`                          | Z              |
| NOT      | `10000101 0000RRRR`                             | `R = ~R`                             | Z              |
| OUT      | `10100000 RRRRSSSS`                             | `R < S`                              |                |
| IN       | `10100001 RRRRSSSS`                             | `S > R`                              |                |
| CHK      | `10100010 0000SSSS`                             | `Z = data_available(S)`              | Z              |
| ACTV     | `10100011 0000SSSS`                             | `Z = data_available(S)`              | Z              |
| JMP      | `11000000 DDDDDDDD DDDDDDDD DDDDDDDD`           | `IP = D`                             |                |
| JMPB     | `11000001 DDDDDDDD DDDDDDDD DDDDDDDD`           | `IP = BS + D`                        |                |
| JZ       | `11000100 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (zero) IP = D`                   |                |
| JNZ      | `11000110 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (!zero) IP = D`                  |                |
| JS       | `11001000 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (sign) IP = D`                   |                |
| JNS      | `11001010 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (!sign) IP = D`                  |                |
| JC       | `11001100 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (carry) IP = D`                  |                |
| JNC      | `11001110 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (!carry) IP = D`                 |                |
| JZB      | `11000101 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (zero) IP = D + BS`              |                |
| JNZB     | `11000111 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (!zero) IP = D + BS`             |                |
| JSB      | `11001001 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (sign) IP = D + BS`              |                |
| JNSB     | `11001011 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (!sign) IP = D + BS`             |                |
| JCB      | `11001101 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (carry) IP = D + BS`             |                |
| JNCB     | `11001111 DDDDDDDD DDDDDDDD DDDDDDDD`           | `if (!carry) IP = D + BS`            |                |
| CALL     | `11111010 DDDDDDDD DDDDDDDD DDDDDDDD`           | `stack.push(IP), IP = D`             |                |
| CALLB    | `11111011 DDDDDDDD DDDDDDDD DDDDDDDD`           | `stack.push(IP), IP = D + BS`        |                |
| RET      | `11111100`                                      | `IP = stack.pop()`                   |                |
| INT      | `11111101 DDDDDDDD`                             | `stack.push(IP), IP = interrupts[D]` |                |
| HLT      | `11111110`                                      | Stops execution of the program       |                |

## Instruction groups
- Registers (LDI, CPR, CPP, LDA, LDSI)
- Memory (WRB, WRW, WRA, RDB, RDW, RDA, BWRB, BWRW, BWRA, BRDB, BRDW, BRDA, PUSH, POP, PUSHA, POPA)
- Arithmetic (ADD, SUB, MUL, DIV, MOD, INC, DEC, ADDP, SUBP, DIFF, INCP, DECP, CMP)
- Bitwise (SHL, SHR, AND, OR, XOR, NOT)
- IO (OUT, IN)
- Jumps (JMP, JMPB, JZ, JNZ, JS, JNS, JC, JNC, JZB, JNZB, JSB, JNSB, JCB, JNCB)
- Control (CALL, CALLB, RET, INT, HLT)

## set_flags/CMP/set_flags_signed/ICMP
The `CMP`/`ICMP` instruction uses the flags for different purposes, listed below:
- Zero flag, set if the 2 values are equal
- Sign flag, set if the left value is bigger than the right value
- Carry flag, set if the left value is lesser than the right value

## Jump instructions
The jump instructions are formatted like this:
- `110CCCNB`
Where:
- C = condition: 000 for none, 001 for zero, 010 for sign, 011 for carry
- N = not: if it's set then it will jump if the condition/flag is false
- B = if this is 1 then it will add the address to `BS`

## Read/write memory instructions
The read/write memory instructions are formatted like this:
- `0100OSSB`
Where:
- O = operation: 1 if write, 0 if read
- S = size: 0 if byte, 1 if word, 2 if address
- B = if this is 1 then it will add the address to `BS`

## Interrupts
Interrupts are stored in a table starting at 0x000004, this is the layout of each entry:

| Offset | Size (bytes) | Purpose           |
| ------ | ------------ | ----------------- |
| 000000 | 1            | Flags             |
| 000001 | 3            | Address           |

Flags:
- (& 0b00000001) Active flag - whether the interrupt is active or not

These interrupts are called for the following errors
- 0x00 - read/write to null (addresses from 0 to 4)
- 0x01 - divide by 0
- 0x02 - bad parameter
- 0x03 - called unactive interrupt

All interrupts from 0x00 to 0x1F are reserved
