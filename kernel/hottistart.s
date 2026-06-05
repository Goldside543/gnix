.code16
.global _start

_start:
    cli
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
    sti

    movw $message, %si
.print:
    lodsb
    testb %al, %al
    jz .after_print
    movb $0x0E, %ah
    int $0x10
    jmp .print

.after_print:
    hlt
    jmp .after_print

# ----------------------------
# BIOS CHS read (1 sector)
# IN:
#   CH = cylinder
#   DH = head
#   CL = sector (1-based)
#   ES:BX = buffer
# ----------------------------
disk_read_chs:
    pusha
    movb $0x02, %ah
    movb $0x01, %al
    movb $0x00, %dl
    int $0x13
    jc .fail
    popa
    clc
    ret
.fail:
    popa
    stc
    ret

message:
    .asciz "Welcome to Hotti, the only (as far as I know) OS where you run apps by hot swapping disks!\r\n"
