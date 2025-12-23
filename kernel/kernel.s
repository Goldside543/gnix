.code16
.global _start

.set PROG_SEG,  0xC000
.set MAP_BUF,   0xA000

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
    call load_fat
    call find_file
    jc halt

    call load_com
    call run_com

halt:
    cli
    hlt
    jmp halt

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

load_fat:
    xorw %ax, %ax
    movw %ax, %es
    movw $MAP_BUF, %bx

    movb $0, %ch
    movb $0, %dh
    movb $3, %cl

    call disk_read_chs
    ret

find_file:
    pushw %ds
    xorw %ax, %ax
    movw %ax, %ds

    movw $MAP_BUF, %si
    movw $32, %cx          # 512 / 16 = 32 entries

.next:
    cmpb $0, (%si)
    je .fail

    pushw %si
    movw %si, %di
    movw $filename, %si
    movw $11, %cx
    repe cmpsb
    popw %si
    je .found

    addw $16, %si
    loop .next

.fail:
    popw %ds
    stc
    ret

.found:
    movb 11(%si), %ch
    movb 12(%si), %dh
    movb 13(%si), %cl
    popw %ds
    clc
    ret

load_com:
    movw $PROG_SEG, %ax
    movw %ax, %es
    movw $0x0100, %bx

    movw $4, %cx        # 4 sectors per file

.next_sector:
    call disk_read_chs
    jc .fail

    addw $512, %bx
    incb %cl
    cmpb $19, %cl
    jb .cont

    movb $1, %cl
    xorb $1, %dh
    jnz .cont
    incb %ch

.cont:
    loop .next_sector
    ret

.fail:
    stc
    ret

run_com:
    cli
    movw $PROG_SEG, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw $0xFFFE, %sp
    sti
    ljmp $PROG_SEG, $0x0100

message:
    .asciz "Microspace booted. Loading HELLO.COM...\r\n"

filename:
    .ascii "HELLO   COM"
