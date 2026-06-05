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
    movw $message2, %si
    
.print2:
    lodsb
    testb %al, %al
    jz .after_print2
    movb $0x0E, %ah
    int $0x10
    jmp .print2

.after_print2:
    movb $0x00, %ah
    int $0x16
    movw $0x1000, %ax
    movw %ax, %es
    movw $0x0000, %bx
    movb $0x00, %ch
    movb $0x01, %cl
    movb $0x00, %dh
    call disk_read_chs
    jc .read_failed
    ljmp $0x1000, $0x0000

.read_failed:
    cli
    hlt
    jmp .read_failed

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
    .asciz "Welcome to Hotti, an OS where you run apps by hot swapping disks!\r\n"
message2:
    .asciz "Please insert an application disk and press any key.\r\n"
