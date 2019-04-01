CC      := riscv64-unknown-elf-gcc
OBJDUMP := riscv64-unknown-elf-objdump
OBJCOPY := riscv64-unknown-elf-objcopy

# Allow users to override the number of time to run a benchmark.
RUNS ?= 1

# Allow users to override the UART's baud rate.
UART_BAUD_RATE ?= 115200

# Make sure user explicitly defines the target GFE platform.
ifeq ($(GFE_TARGET),P1)
	RISCV_FLAGS := -march=rv32imac -mabi=ilp32
	# 50 MHz clock
	CLOCKS_PER_SEC := 50000000
else ifeq ($(GFE_TARGET),P2)
	RISCV_FLAGS := -march=rv64imafdc -mabi=lp64d
	# 50 MHz clock
	CLOCKS_PER_SEC := 50000000
else ifeq ($(GFE_TARGET),P3)
$(error P3 target has not been tested yet, use P1 or P2)
else
$(error Please define GFE_TARGET to P1, P2, or P3 (e.g. make GFE_TARGET=P1))
endif

# Define sources and compilation outputs.
COMMON_DIR := ..
LINKER_SCRIPT := $(COMMON_DIR)/test.ld
COMMON_ASM_SRCS := \
	$(COMMON_DIR)/crt.S
COMMON_C_SRCS := \
	$(COMMON_DIR)/syscalls.c \
	$(COMMON_DIR)/uart_16550.c \
	$(COMMON_DIR)/cvt.c \
	$(COMMON_DIR)/ee_printf.c
COMMON_OBJS := \
	$(patsubst %.c,%.o,$(notdir $(COMMON_C_SRCS))) \
	$(patsubst %.S,%.o,$(notdir $(COMMON_ASM_SRCS)))
OBJS := $(COMMON_OBJS) $(OBJS)

# Define compile and load/link flags.
CFLAGS := \
	$(RISCV_FLAGS) \
	-DBARE_METAL \
	-DCLOCKS_PER_SEC=$(CLOCKS_PER_SEC) \
	-DRUNS=$(RUNS) \
	-DUART_BAUD_RATE=$(UART_BAUD_RATE) \
	-O2 \
	-Wall \
	-mcmodel=medany \
	-static \
	-std=gnu99 \
	-ffast-math \
	-fno-common \
	-fno-builtin-printf \
	-I$(COMMON_DIR)
ASFLAGS := $(CFLAGS)
LDFLAGS := \
	-static \
	-nostdlib \
	-nostartfiles \
	-lm \
	-lc \
	-lgcc \
	-T $(LINKER_SCRIPT)

all: main.elf

%.o: %.s
	$(CC) $(ASFLAGS) -c -o $@ $<

%.o: ../%.S
	$(CC) $(ASFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: ../%.c
	$(CC) $(CFLAGS) -c -o $@ $<

main.elf: $(OBJS) $(COMMON_C_SRCS) $(COMMON_ASM_SRCS)
	$(CC) $(CFLAGS) $(OBJS) -o main.elf $(LDFLAGS)
	$(OBJDUMP) --disassemble-all main.elf > main.lst
	$(OBJCOPY) main.elf main.bin -O binary

clean: more_clean
	rm -rf *.o *.elf output* *.lst *.bin *~
