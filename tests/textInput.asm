ldsi a 2
ldsi b 0x00 ; set video mode command
out a b
ldsi b 0x10 ; video mode 0x10, 80x40 text mode
out a b

ldsi b 0x01 ; load font
out a b

ldsi b 0x02 ; load palette
out a b

ldsi a 1    ; Keyboard device
ldsi b 0x02 ; Enable keyboard events
out a b
ldsi b 0x00 ; Enable ASCII translation
out a b
ldsi c 0x00 ; ASCII input event
ldsi g 0x07 ; White on black
lda ds 0x000C34 ; VRAM text buffer

loop:
	callb wait_dev
	in b a
	cmp b c
	jnzb ignore_event
	callb wait_dev
	in b a
	wrb ds g
	incp ds
	wrb ds b
	incp ds
	jmpb next

ignore_event:
	callb wait_dev
	in b a

next:
	jmpb loop

wait_dev:
	chk a
	jnzb wait_dev
	ret
