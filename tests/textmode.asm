ldsi a 2
ldsi b 0x00 ; set video mode command
out a b
ldsi b 0x10 ; video mode 0x10, 80x40 text mode
out a b

ldsi b 0x01 ; load font
out a b

ldsi b 0x02 ; load palette
out a b

lda ab 0x000C34 ; set first cell's attribute to white on black
ldsi c 0x0F
wrb ab c

lda ab 0x000C35 ; write : to first cell
ldsi c 58
wrb ab c

lda ab 0x000C36 ; set second cell's attribute to white on black
ldsi c 0x0F
wrb ab c

lda ab 0x000C37 ; write 3 to second cell
ldsi c 51
wrb ab c

end:
	jmpb end
