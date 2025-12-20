.code16
.org 0x8000
.global _start

_start:
    cli
    movw $0x8000, %ax
    movw %ax, %ds
    movw %ax, %es
    sti

    movw $message, %si

print_loop:
    lodsb
    testb %al, %al
    jz done
    movb $0x0E, %ah
    movb $0x00, %bh
    movb $0x07, %bl
    int $0x10
    jmp print_loop

done:
    cli

message:
    .asciz "Hello, world!"

.fill 512 - (. - _start), 1, 0
