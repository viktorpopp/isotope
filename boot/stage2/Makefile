# TODO: make this look better

SRCS := entry.asm main.c term.c
OBJS := $(patsubst %.c,$(BUILD_DIR)/boot/%.c.o,$(filter %.c,$(SRCS))) \
        $(patsubst %.asm,$(BUILD_DIR)/boot/%.asm.o,$(filter %.asm,$(SRCS)))
DEP := $(patsubst %.c,$(BUILD_DIR)/boot/%.c.d,$(filter %.c,$(SRCS)))

LIBGCC ?= $(shell $(CC) $(CFLAGS) -m32 -print-libgcc-file-name)

$(BUILD_DIR)/boot/stage2.bin: $(OBJS)
	@mkdir -p $(@D)
	$(LD) -m elf_i386 -no-pie -T linker.ld $^ $(LIBGCC) -o $@

$(BUILD_DIR)/boot/%.asm.o: %.asm
	@mkdir -p $(@D)
	$(ASM) -f elf -g $< -o $@

$(BUILD_DIR)/boot/%.c.o: %.c
	@mkdir -p $(@D)
	$(CC) \
		-Wall -Wextra -std=c23 -ffreestanding -m32 \
		-march=i486 \
		-fno-pie -fno-pic \
        -fno-stack-protector \
		-mno-mmx \
		-mno-3dnow \
		-mno-80387 \
		-mno-sse \
		-mno-sse2 \
		-mno-sse3 \
		-mno-ssse3 \
		-mno-sse4 \
		-I../../lib \
		-MMD -MP -MF $(BUILD_DIR)/$*.c.d -c -o $@ $<

-include $(DEP)
