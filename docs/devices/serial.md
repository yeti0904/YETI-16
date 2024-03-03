# Serial device
The serial device can be enabled in the emulator with the command line flag
`--serial`

Run YETI-16 without any flags for more info

If the serial port is enabled, the device is always at port 0x20

## Protocol
Any data sent to the device with `out` is sent to a connected client, any data
received from `in` is data sent from a connected client

Data sent with `out` while no client is connected is stored in a buffer until a client
connects
