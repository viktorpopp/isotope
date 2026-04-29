export SHELL := bash
export MAKEFLAGS += --warn-undefined-variables
export MAKEFLAGS += --no-builtin-rules

.ONESHELL:
.DELETE_ON_ERROR:

export ASM ?= nasm
export LD ?= ld

export BUILD_DIR ?= $(abspath build)
export TARGET ?= $(BUILD_DIR)/floppy.img

-include config.mk

.PHONY: all
all: $(TARGET)

.PHONY: run
run:
	qemu-system-i386								\
		-cpu 486,fpu=off							\
		-drive file=$(TARGET),format=raw,if=floppy

.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)

.PHONY: stage1
stage1:
	$(MAKE) -C boot/stage1

.PHONY: stage2
stage2:
	$(MAKE) -C boot/stage2

$(TARGET): stage1 stage2
	dd if=/dev/zero of=$(TARGET) bs=512 count=2880
	mkfs.fat -F 12 -n "ISOTOPE " $(TARGET)
	mcopy -i $(BUILD_DIR)/floppy.img $(BUILD_DIR)/boot/stage2.bin "::stage2.bin"
	dd if=$(BUILD_DIR)/boot/stage1.bin of=$(TARGET) conv=notrunc
