# ====================================================================
# Makefile for Ultrasonic Mapping Robot - ATmega32
# ====================================================================

# Project settings
PROJECT = ultrasonic_mapping
MCU = atmega32
F_CPU = 16000000UL
PROGRAMMER = usbasp

# Compiler and tools
AS = avr-as
CC = avr-gcc
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
SIZE = avr-size
AVRDUDE = avrdude

# Source files
ASMSRC = ultrasonic_mapping.asm
INCSRC = mapping_definitions.inc advanced_mapping.asm

# Output files
TARGET = $(PROJECT)
HEX = $(TARGET).hex
ELF = $(TARGET).elf
LST = $(TARGET).lst

# Assembler flags
ASFLAGS = -mmcu=$(MCU) -I.

# AVRDUDE flags
AVRDUDE_FLAGS = -p $(MCU) -c $(PROGRAMMER) -U flash:w:$(HEX):i

# Default target
all: $(HEX) $(LST) size

# Create HEX file from ELF
$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

# Create ELF file from assembly source
$(ELF): $(ASMSRC) $(INCSRC)
	$(AS) $(ASFLAGS) -o $(ELF) $(ASMSRC)

# Create listing file
$(LST): $(ELF)
	$(OBJDUMP) -h -S $< > $@

# Show size information
size: $(ELF)
	@echo
	@echo "Size information:"
	$(SIZE) --format=avr --mcu=$(MCU) $<

# Upload to microcontroller
upload: $(HEX)
	$(AVRDUDE) $(AVRDUDE_FLAGS)

# Clean build files
clean:
	rm -f $(HEX) $(ELF) $(LST)
	@echo "Clean completed."

# Verify connection to programmer
verify:
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER)

# Read fuses (useful for debugging)
readfuses:
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) -U hfuse:r:-:h -U lfuse:r:-:h

# Set fuses for external 16MHz crystal
setfuses:
	@echo "Setting fuses for external 16MHz crystal..."
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) -U hfuse:w:0xC9:m -U lfuse:w:0xEF:m

# Help target
help:
	@echo "Available targets:"
	@echo "  all       - Build hex and listing files"
	@echo "  upload    - Upload firmware to microcontroller"
	@echo "  clean     - Remove build files"
	@echo "  verify    - Test programmer connection"
	@echo "  readfuses - Read current fuse settings"
	@echo "  setfuses  - Set fuses for 16MHz external crystal"
	@echo "  size      - Show size information"
	@echo "  help      - Show this help message"

.PHONY: all clean upload verify readfuses setfuses size help
