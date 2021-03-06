PRJ_NAME   = Position-Tracker
CC         = arm-none-eabi-gcc
SRCDIR     = src
INCDIR	   = inc
INCSRC	   = $(wildcard $(INCDIR)/*.c)
INCASRC	   = $(wildcard $(INCDIR)/*.s)
SRC        = $(wildcard $(SRCDIR)/*.c)
ASRC       = $(wildcard $(SRCDIR)/*.s)
OBJ        = $(SRC:.c=.o) $(ASRC:.s=.o) $(INCSRC:.c=.o) $(INCASRC:.s=.o) 
OBJCOPY    = arm-none-eabi-objcopy
OBJDUMP    = arm-none-eabi-objdump
PROGRAMMER = openocd
PGFLAGS    = -f openocd.cfg -c "program $(PRJ_NAME).elf verify reset" -c shutdown
DEVICE     = STM32F1
OPT       ?= -g3
LIBPATHS   = libopencm3
CFLAGS     = -fdata-sections -ffunction-sections -Wall -mcpu=cortex-m3 -mlittle-endian -mthumb -I $(LIBPATHS)/include/ -D$(DEVICE) $(OPT)
ASFLAGS    =  $(CFLAGS)
LDSCRIPT   = $(LIBPATHS)/lib/stm32/f1/stm32f103x8.ld
LDFLAGS    = -T $(LDSCRIPT) -lm -L$(LIBPATHS)/lib -lopencm3_stm32f1 --static -nostartfiles -Wl,--gc-sections --specs=nano.specs --specs=nosys.specs
LIBOPENCM3 = $(LIBPATHS)/lib/libopencm3_stm32f1.a

.PHONY: all clean flash burn hex bin

all: $(PRJ_NAME).elf

$(LIBOPENCM3):
	make -C libopencm3 TARGETS=stm32/f1 $(MAKEFLAGS)

$(PRJ_NAME).elf: $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $@ $(LDFLAGS)
	arm-none-eabi-size $(PRJ_NAME).elf

%.o: %.c $(LIBOPENCM3)
	$(CC) -MMD -c $(CFLAGS) $< -o $@

%.o: %.s $(LIBOPENCM3)
	$(CC) -MMD -c $(ASFLAGS) $< -o $@

-include $(SRCDIR)/*.d
-include $(INCDIR)/*.d

clean:
	rm -f $(OBJ) $(PRJ_NAME).elf $(PRJ_NAME).hex $(PRJ_NAME).bin $(SRCDIR)/*.d $(INCDIR)/*.d

distclean: clean
	make -C libopencm3 clean

flash: $(PRJ_NAME).elf
	$(PROGRAMMER) $(PGFLAGS)

burn: $(PRJ_NAME).elf
	$(PROGRAMMER) $(PGFLAGS)

hex: $(PRJ_NAME).elf
	$(OBJCOPY) -O ihex $(PRJ_NAME).elf $(PRJ_NAME).hex

bin: $(PRJ_NAME).elf
	$(OBJCOPY) -O binary $(PRJ_NAME).elf $(PRJ_NAME).bin
