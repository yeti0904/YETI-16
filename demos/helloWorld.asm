ldsi a 2
ldsi b 0x00 ; set video mode command
out a b
ldsi b 0x10 ; video mode 0x10, 80x40 text mode
out a b

ldsi b 0x01 ; load font
out a b

ldsi b 0x02 ; load palette
out a b

lda ab 0x000C34
ldi c 3200
ldsi d 0x47 ; white on blue
ldsi e 0
clear:
	wrb ab d
	dec c
	incp ab
	incp ab
	cmp c e
	jnzb clear

lda ab 0x000C34
lda cd msg
ldsi e 0
ldsi g 0x0F

loop:
	brdb f cd ; Read character
	cmp f e   ; Check if end of string
	jzb end   ; Stop printing if end of string
	incp ab   ; Skip attribute
	wrb ab f  ; Write character
	incp ab
	incp cd   ; Next character
	jmpb loop

end:
	jmpb end

msg:
	db "Hello, world!" 0
