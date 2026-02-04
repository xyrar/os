# Tools
CC      = c99
LD      = ld
NASM    = nasm

# Flags
CFLAGS  = -m32 -nostdlib -nostdinc -fno-builtin -fno-pie -MMD
LDFLAGS_KERNEL = -Tkernel/kernel.ld -m elf_i386
NASMFLAGS = -f bin

# Sources
KERNEL_SRCS = $(wildcard kernel/*.c)
KERNEL_OBJS = $(KERNEL_SRCS:.c=.o)

.PHONY: all clean test boot kernel

all: os.img

os.img: boot/boot.bin kernel/kernel.bin
	dd if=boot/boot.bin of=os.img bs=512 count=1 seek=0 conv=notrunc status=none
	dd if=kernel/kernel.bin of=os.img bs=512 seek=1 conv=notrunc status=none
	truncate -s 1440K os.img

### --- Bootloader Build (with NASM) ---

boot: boot/boot.bin

boot/boot.bin: boot/boot.asm
	$(NASM) $(NASMFLAGS) -o $@ $<

### --- Kernel Build (with C compiler) ---

kernel: kernel/kernel.bin

kernel/kernel.bin: $(KERNEL_OBJS)
	$(LD) $(LDFLAGS_KERNEL) -o $@ $^
	chmod -x $@

kernel/%.o: kernel/%.c
	$(CC) -c $(CFLAGS) -o $@ $<

### --- Utilities ---

clean:
	rm -f boot/*.o boot/*.bin kernel/*.o kernel/*.bin kernel/*.d os.img

test: os.img
	qemu-system-x86_64 -drive file=os.img,if=ide,index=0,format=raw -display sdl

# Include auto-generated dependency files
-include $(KERNEL_OBJS:.o=.d)
