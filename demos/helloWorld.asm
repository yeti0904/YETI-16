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
lda cd msg
ldsi e 0
ldsi g 0x0F

loop:
	brdb f cd ; Read character
	cmp f e   ; Check if end of string
	jzb end   ; Stop printing if end of string
	wrb ab g  ; Write attribute
	incp ab
	wrb ab f  ; Write character
	incp ab
	incp cd   ; Next character
	jmpb loop

end:
	jmpb end

msg:
	db "Hello, world!" 0
