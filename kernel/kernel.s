.code16
.global _start

# ----------------------------
# Constants (floppy FAT12)
# ----------------------------
FAT_START      = 1
FAT_SECTORS    = 9
ROOT_START     = FAT_START + FAT_SECTORS*2
ROOT_SECTORS   = 14
DATA_START     = ROOT_START + ROOT_SECTORS

# Memory layout
FAT_BUF        = 0xA000
ROOT_BUF       = 0xB000
PROG_SEG       = 0xC000

# ----------------------------
# Kernel entry
# ----------------------------
_start:
    cli
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
    sti

    # Print banner
    movw $message, %si
.print:
    lodsb
    testb %al, %al
    jz .after_print
    movb $0x0E, %ah
    int $0x10
    jmp .print

.after_print:
    # Load FAT + root directory
    call load_fat
    call load_root

    # Find file
    call find_file
    jc halt

    # AX = starting cluster
    call load_com
    call run_com

halt:
    cli
    hlt
    jmp halt

# ----------------------------
# BIOS disk read (LBA -> CHS)
# IN: AX = LBA, CX = count, ES:BX = buffer
# ----------------------------
disk_read:
    pusha
.next:
    pushw ax

    xorw dx, dx
    movw cx, 18
    divw cx
    incw dx
    movb cl, dl

    xorw dx, dx
    movw cx, 2
    divw cx

    movb dh, dl
    movb ch, al

    movb ah, 0x02
    movb al, 1
    int 0x13
    jc disk_fail

    popw ax
    incw ax
    addw bx, 512
    loop .next

    popa
    ret

disk_fail:
    cli
    hlt

# ----------------------------
# Load FAT
# ----------------------------
load_fat:
    movw ax, FAT_START
    movw cx, FAT_SECTORS*2
    movw bx, FAT_BUF
    movw es, 0
    call disk_read
    ret

# ----------------------------
# Load root directory
# ----------------------------
load_root:
    movw ax, ROOT_START
    movw cx, ROOT_SECTORS
    movw bx, ROOT_BUF
    movw es, 0
    call disk_read
    ret

# ----------------------------
# FAT12 cluster follow
# IN: AX = cluster
# OUT: AX = next cluster
# ----------------------------
fat_next:
    movw bx, ax
    addw bx, ax
    shrw bx, 1
    movw si, FAT_BUF
    addw si, bx
    movw ax, [si]
    testb bl, 1
    jz .even
    shrw ax, 4
    ret
.even:
    andw ax, 0x0FFF
    ret

# ----------------------------
# Find .COM in root dir
# OUT: AX = start cluster
# ----------------------------
find_file:
    movw si, ROOT_BUF
    movw cx, 224
.next:
    cmpb byte ptr [si], 0
    je .fail
    pushw si
    movw di, filename
    movw bx, 11
    repe cmpsb
    popw si
    je .found
    addw si, 32
    loop .next
.fail:
    stc
    ret
.found:
    movw ax, [si+26]
    clc
    ret

# ----------------------------
# Load .COM file
# IN: AX = start cluster
# ----------------------------
load_com:
    movw bx, 0x0100
    movw es, PROG_SEG
.next_cluster:
    cmpw ax, 0xFF8
    jae .done
    pushw ax
    subw ax, 2
    addw ax, DATA_START
    movw cx, 1
    call disk_read
    popw ax
    call fat_next
    jmp .next_cluster
.done:
    ret

# ----------------------------
# Execute .COM
# ----------------------------
run_com:
    cli
    movw ax, PROG_SEG
    movw ds, ax
    movw es, ax
    movw ss, ax
    movw sp, 0xFFFE
    sti
    jmp PROG_SEG:0x0100

# ----------------------------
# Data
# ----------------------------
message:
    .asciz "Microspace booted. Loading program...\r\n"

filename:
    .ascii "HELLO   COM"
