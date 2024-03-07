; requires a disk to be connected or it will crash
ldsi a 0xF7 ; Disk device
ldsi b 0x01 ; Read sector
ldsi c 0
out a b ; Read sector
out a c ; Sector low
out a c ; Sector high
cpp gh bs
ldi d program
addp gh d
addp bs d
out a h ; Memory address low
out a g ; Memory address high

program:
	hlt
