AS = x86_64-linux-gnu-as --32
LD = x86_64-linux-gnu-ld -m elf_i386
CC = gcc
CFLAGS = --std=gnu17 -g -m32 -Werror -ffreestanding -fno-stack-protector

# Files
BOOT_SRC = bootloader/boot.s
BOOT_BIN = bootloader/boot.bin

KERNEL_ASM_SRC = kernel/gnixstart.s
KERNEL_C_SRC = kernel/pentry.c
KERNEL_BIN = kernel/gnixkrnl.bin

OS_IMG = os.img

# Targets
all: $(OS_IMG)

# Bootloader
$(BOOT_BIN): $(BOOT_SRC)
	$(AS) $(BOOT_SRC) -o bootloader/boot.o
	$(LD) -Ttext 0x7C00 --oformat binary bootloader/boot.o -o bootloader/boot.bin

# Kernel
$(KERNEL_BIN): $(KERNEL_ASM_SRC) $(KERNEL_C_SRC)
	$(AS) $(KERNEL_ASM_SRC) -o kernel/hottistart.o
	$(CC) $(CFLAGS) $(KERNEL_C_SRC) -o kernel/pkernel.o
	$(LD) -Ttext 0x8000 --oformat binary kernel/hottistart.o kernel/pkernel.o -o $(KERNEL_BIN)

# OS image
$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(OS_IMG) bs=512 count=2880
	dd if=$(BOOT_BIN) of=$(OS_IMG) bs=512 count=1 conv=notrunc
	dd if=$(KERNEL_BIN) of=$(OS_IMG) bs=512 seek=1 conv=notrunc

# Clean
clean:
	rm -f bootloader/*.o bootloader/*.elf bootloader/*.bin \
		kernel/*.o kernel/*.elf kernel/*.bin \
		$(OS_IMG)

.PHONY: all clean
