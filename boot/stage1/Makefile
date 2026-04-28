$(BUILD_DIR)/boot/stage1.bin: $(BUILD_DIR)/boot/stage1.o
	@printf "  LD $@\n"
	@$(LD) -m elf_i386 -T linker.ld $^ -o $@

$(BUILD_DIR)/boot/stage1.o: bootsect.asm
	@printf "  AS $@\n"
	@mkdir -p $(@D)
	@$(ASM) -f elf $^ -o $@
