lda ab 1796
ldi c 15
ldi d 64000
ldi e 0

loop:
	wrb ab c
	incp ab
	dec d
	cmp d e
	jneb loop
end:
	jmpb end
