.code16
.global _start

_start:
    cli
    xorw %ax, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw $0x7C00, %sp
    sti

    # BIOS loads us with DL = boot drive, keep it
    movb %dl, boot_drive

    # Load kernel (1 sector) into 0x0000:0x8000
    movw $0x0000, %ax
    movw %ax, %es
    movw $0x8000, %bx

    movb $0x02, %ah          # INT 13h read sectors
    movb $0x01, %al          # number of sectors
    movb $0x00, %ch          # cylinder
    movb $0x02, %cl          # sector (starts at 1, so kernel = sector 2)
    movb $0x00, %dh          # head
    movb boot_drive, %dl     # drive
    int $0x13

    jc disk_error

    # Jump to kernel
    ljmp $0x0000, $0x8000

disk_error:
    hlt
    jmp disk_error

boot_drive:
    .byte 0

    # Boot signature
    .org 510
    .word 0xAA55
