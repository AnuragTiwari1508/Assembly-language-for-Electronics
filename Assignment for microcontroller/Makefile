#===============================================================================
# Makefile for Touch Security Alarm Assembly Code
# Target: ATmega32 microcontroller
# Compatible with Microchip Studio (formerly Atmel Studio)
#===============================================================================

# Project name and target microcontroller
PROJECT = touch_security_alarm
MCU = atmega32
F_CPU = 16000000UL

# Toolchain
CC = avr-gcc
AS = avr-as
LD = avr-ld
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
SIZE = avr-size

# Directories
SRC_DIR = .
BUILD_DIR = build

# Source files
ASM_SOURCES = $(PROJECT).asm

# Object files
OBJECTS = $(BUILD_DIR)/$(PROJECT).o

# Output files
ELF = $(BUILD_DIR)/$(PROJECT).elf
HEX = $(BUILD_DIR)/$(PROJECT).hex
LST = $(BUILD_DIR)/$(PROJECT).lst

# Compiler/Assembler flags
CFLAGS = -mmcu=$(MCU) -Os -Wall -Wextra
ASFLAGS = -mmcu=$(MCU) -x assembler-with-cpp -I.

# Linker flags  
LDFLAGS = -mmcu=$(MCU)

# Default target
all: $(HEX) $(LST) size

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Assemble source files
$(BUILD_DIR)/%.o: %.asm | $(BUILD_DIR)
	$(CC) $(ASFLAGS) -c -o $@ $<

# Link object files to create ELF
$(ELF): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^

# Create Intel HEX file from ELF
$(HEX): $(ELF)
	$(OBJCOPY) -O ihex -R .eeprom $< $@

# Create assembly listing
$(LST): $(ELF)
	$(OBJDUMP) -h -S $< > $@

# Display size information
size: $(ELF)
	$(SIZE) --format=avr --mcu=$(MCU) $<

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

# Flash the hex file to microcontroller (requires programmer)
flash: $(HEX)
	avrdude -p $(MCU) -c usbasp -U flash:w:$(HEX):i

# Show help
help:
	@echo "Available targets:"
	@echo "  all     - Build project (default)"
	@echo "  clean   - Remove build files"
	@echo "  flash   - Program microcontroller"
	@echo "  size    - Show memory usage"
	@echo "  help    - Show this help"

.PHONY: all clean flash size help
