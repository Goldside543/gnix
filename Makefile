AS = x86_64-linux-gnu-as --32
LD = x86_64-linux-gnu-ld -m elf_i386

# Files
BOOT_SRC = bootloader/boot.s
BOOT_BIN = bootloader/boot.bin

KERNEL_SRC = kernel/kernel.s
KERNEL_BIN = kernel/kernel.bin

OS_IMG = os.img

# Targets
all: $(OS_IMG)

# Bootloader
$(BOOT_BIN): $(BOOT_SRC)
	$(AS) $(BOOT_SRC) -o bootloader/boot.o
	$(LD) -Ttext 0x7C00 --oformat binary bootloader/boot.o -o bootloader/boot.bin

# Kernel
$(KERNEL_BIN): $(KERNEL_SRC)
	$(AS) $(KERNEL_SRC) -o kernel/kernel.o
	$(LD) -Ttext 0x8000 --oformat binary kernel/kernel.o -o $(KERNEL_BIN)

# OS image
$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(OS_IMG).img bs=512 count=2880
	mkfs.fat -F 12 $(OS_IMG)
	dd if=$(BOOT_BIN) of=$(OS_IMG) conv=notrunc
	dd if=$(KERNEL_BIN) of=$(OS_IMG) bs=512 seek=1 conv=notrunc

# Clean
clean:
	rm -f bootloader/*.o bootloader/*.elf bootloader/*.bin \
	       kernel/*.o kernel/*.elf kernel/*.bin \
	       $(OS_IMG)

.PHONY: all clean
