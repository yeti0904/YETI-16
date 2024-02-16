# YETI-16 Mk2 memory layout

| Address (hex) | Size (bytes) | Purpose                                     |
| ------------- | ------------ | ------------------------------------------- |
| 000000        | 4            | Null                                        |
| 000004        | 1024         | Interrupt table (view arch.md for more info |
| 000404        | (variable)   | Video RAM                                   |
| 050000        |              | Start of program                            |
| 0F0000        |              | Start of stack and usable memory            |
