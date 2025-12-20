.code16
.global _start

# ----------------------------
# FAT12 constants (1.44MB)
# ----------------------------
.set FAT_START,    1
.set FAT_SECTORS,  9
.set ROOT_START,   FAT_START + FAT_SECTORS*2
.set ROOT_SECTORS, 14
.set DATA_START,   ROOT_START + ROOT_SECTORS

# Memory layout (segment 0)
.set FAT_BUF,   0xA000
.set ROOT_BUF,  0xB000
.set PROG_SEG,  0xC000

# ----------------------------
# Kernel entry
# ----------------------------
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
    call load_root
    call find_file
    jc halt

    call load_com
    call run_com

halt:
    cli
    hlt
    jmp halt

# ----------------------------
# BIOS disk read
# IN:
#   AX = LBA
#   CX = sector count
#   ES:BX = buffer
# ----------------------------
disk_read:
    pusha
.next:
    pushw %ax

    xorw %dx, %dx
    movw $18, %cx
    divw %cx
    incb %dl
    movb %dl, %cl

    xorw %dx, %dx
    movw $2, %cx
    divw %cx

    movb %dl, %dh
    movb %al, %ch

    movb $0x02, %ah
    movb $1, %al
    int $0x13
    jc disk_fail

    popw %ax
    incw %ax
    addw $512, %bx
    loop .next

    popa
    ret

disk_fail:
    cli
    hlt

# ----------------------------
# Load FAT tables
# ----------------------------
load_fat:
    movw $FAT_START, %ax
    movw $(FAT_SECTORS*2), %cx
    movw $FAT_BUF, %bx
    pushw %ax
    xorw %ax, %ax
    movw %ax, %es
    popw %ax
    call disk_read
    ret

# ----------------------------
# Load root directory
# ----------------------------
load_root:
    movw $ROOT_START, %ax
    movw $ROOT_SECTORS, %cx
    movw $ROOT_BUF, %bx
    pushw %ax
    xorw %ax, %ax
    movw %ax, %es
    popw %ax
    call disk_read
    ret

# ----------------------------
# FAT12 next cluster
# IN:  AX = cluster
# OUT: AX = next cluster
# ----------------------------
fat_next:
    movw %ax, %bx
    addw %ax, %bx
    shrw $1, %bx

    movw $FAT_BUF, %si
    addw %bx, %si
    movw (%si), %ax

    testb $1, %bl
    jz .even
    shrw $4, %ax
    ret

.even:
    andw $0x0FFF, %ax
    ret

# ----------------------------
# Find HELLO.COM
# OUT: AX = start cluster
# ----------------------------
find_file:
    movw $ROOT_BUF, %si
    movw $224, %cx
.next_file:
    cmpb $0, (%si)
    je .fail

    pushw %si
    movw $filename, %di
    movw $11, %cx
    repe cmpsb
    popw %si
    je .found

    addw $32, %si
    loop .next_file

.fail:
    stc
    ret

.found:
    movw 26(%si), %ax
    clc
    ret

# ----------------------------
# Load .COM file
# IN: AX = start cluster
# ----------------------------
load_com:
    movw $0x0100, %bx
    movw $PROG_SEG, %ax
    movw %ax, %es

.next_cluster:
    cmpw $0x0FF8, %ax
    jae .done

    pushw %ax
    subw $2, %ax
    addw $DATA_START, %ax
    movw $1, %cx
    call disk_read
    popw %ax

    call fat_next
    jmp .next_cluster

.done:
    ret

# ----------------------------
# Execute .COM
# ----------------------------
run_com:
    cli
    movw $PROG_SEG, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw $0xFFFE, %sp
    sti
    ljmp $PROG_SEG, $0x0100

# ----------------------------
# Data
# ----------------------------
message:
    .asciz "Microspace booted. Loading HELLO.COM...\r\n"

filename:
    .ascii "HELLO   COM"
