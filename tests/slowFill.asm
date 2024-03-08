ldsi a 2 ; Graphics controller
ldsi b 2 ; Load palette
out a b

cpp ab bs
ldi c interrupt
addp ab c ; create address of interrupt
lda cd 0x000084
ldsi e 1 ; Interrupt flags
wrb cd e
incp cd
wra cd ab ; Write address to interrupt table

ldsi a 2 ; Graphics controller
ldsi b 3 ; Set draw interrupt
out a b
ldsi b 0x20 ; Draw interrupt
out a b

lda ds 0x000704
ldsi a 0

end:
	jmpb end

interrupt:
	wrb ds a
	incp ds
	inc a
	ret
