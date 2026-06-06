void putc(char c) {
    #asm
        mov bx, sp
        mov al, [bx+2]
        mov ah, #0x0E
        int 0x10
    #endasm
}
