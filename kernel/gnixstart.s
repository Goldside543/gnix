.code16
.global _start
.extern kmain

_start:
    cli
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
    movl $0x90000, %esp
    sti

    movw $message, %si
    
.print:
    lodsb
    testb %al, %al
    jz .after_print
    movb $0x0E, %ah
    int $0x10
    jmp .print

message:
    .asciz "Welcome to Gnix.\r\n"

.after_print:
    movb $0x00, %ah
    clc
    movw $0x2401, %ax
    int $0x15
    cli
    lgdt gdt_pointer
    movl %cr0, %eax
    orl $1, %eax
    movl %eax, %cr0
    ljmp $0x08, $1f

.code32
1:
    movw $0x10, %ax                 
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss

    jmp kmain
    
gdt_start:
    .long 0x0, 0x0                  # Null Descriptor

gdt_code:                           # Kernel Code Descriptor (Selector 0x08)
    .short 0xFFFF, 0x0000
    .byte 0x00, 0x9A, 0xCF, 0x00

gdt_data:                           # Kernel Data Descriptor (Selector 0x10)
    .short 0xFFFF, 0x0000
    .byte 0x00, 0x92, 0xCF, 0x00
gdt_end:

gdt_pointer:
    .short gdt_end - gdt_start - 1  # Size of GDT
    .long gdt_start                 # Address of GDT
