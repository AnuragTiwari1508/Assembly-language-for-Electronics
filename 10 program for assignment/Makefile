# ====================================================================
# MAKEFILE FOR ASSEMBLY LANGUAGE ASSIGNMENTS
# Compatible with AVR-GCC toolchain and Microchip Studio
# ====================================================================

# Microcontroller Configuration
MCU = atmega32
F_CPU = 8000000UL
FORMAT = ihex

# Toolchain Configuration
CC = avr-gcc
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
SIZE = avr-size
AVRDUDE = avrdude

# Compiler Flags
CFLAGS = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -Os -Wall -Wstrict-prototypes
CFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
LDFLAGS = -mmcu=$(MCU)

# Assembly Flags
ASFLAGS = -mmcu=$(MCU) -DF_CPU=$(F_CPU)

# Programming Configuration (adjust for your programmer)
PROGRAMMER = usbasp
PORT = usb
AVRDUDE_FLAGS = -p $(MCU) -c $(PROGRAMMER) -P $(PORT)

# Source Files (all assignments)
ASSIGNMENTS = assignment1 assignment2 assignment3 assignment4 assignment5 \
              assignment6 assignment7 assignment8 assignment9 assignment10

# Default target - build all assignments
.PHONY: all
all: $(ASSIGNMENTS)

# Individual assignment targets
.PHONY: $(ASSIGNMENTS)
$(ASSIGNMENTS): %: %.hex %.lst

# Rules for building hex files from assembly source
%.hex: %.elf
	@echo "Creating hex file for $*..."
	$(OBJCOPY) -O $(FORMAT) -R .eeprom $< $@
	@echo "Hex file created: $@"

# Rules for building elf files from assembly source
%.elf: %.asm
	@echo "Assembling and linking $*..."
	$(CC) $(ASFLAGS) -o $@ $<
	@echo "ELF file created: $@"

# Rules for creating listing files
%.lst: %.elf
	@echo "Creating listing file for $*..."
	$(OBJDUMP) -h -S $< > $@
	@echo "Listing file created: $@"

# Show size information
%.size: %.elf
	@echo "Size information for $*:"
	$(SIZE) $<

# Clean build files
.PHONY: clean
clean:
	@echo "Cleaning build files..."
	rm -f *.elf *.hex *.lst *.map *.o
	@echo "Clean complete."

# Program specific assignment to microcontroller
.PHONY: program1 program2 program3 program4 program5 program6 program7 program8 program9 program10
program1: assignment1.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program2: assignment2.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program3: assignment3.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program4: assignment4.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program5: assignment5.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program6: assignment6.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program7: assignment7.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program8: assignment8.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program9: assignment9.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

program10: assignment10.hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$<:i

# Verify programming
.PHONY: verify
verify: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:v:$<:i

# Read fuses (useful for debugging)
.PHONY: readfuses
readfuses:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h

# Set fuses for external crystal (8MHz)
.PHONY: setfuses8mhz
setfuses8mhz:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U lfuse:w:0xef:m -U hfuse:w:0xc9:m

# Set fuses for external crystal (16MHz)
.PHONY: setfuses16mhz
setfuses16mhz:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U lfuse:w:0xff:m -U hfuse:w:0xc9:m

# Build and size report for all assignments
.PHONY: report
report: all
	@echo "=== BUILD REPORT ==="
	@for assignment in $(ASSIGNMENTS); do \
		echo "--- $$assignment ---"; \
		if [ -f $$assignment.elf ]; then \
			$(SIZE) $$assignment.elf; \
		else \
			echo "$$assignment not built"; \
		fi; \
		echo; \
	done

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all          - Build all assignments"
	@echo "  assignment1  - Build assignment 1 (LED blinker)"
	@echo "  assignment2  - Build assignment 2 (Traffic light)"
	@echo "  assignment3  - Build assignment 3 (7-segment counter)"
	@echo "  assignment4  - Build assignment 4 (PWM LED control)"
	@echo "  assignment5  - Build assignment 5 (Temperature monitor)"
	@echo "  assignment6  - Build assignment 6 (Servo control)"
	@echo "  assignment7  - Build assignment 7 (Digital clock)"
	@echo "  assignment8  - Build assignment 8 (Keypad security)"
	@echo "  assignment9  - Build assignment 9 (Ultrasonic sensor)"
	@echo "  assignment10 - Build assignment 10 (Data logger)"
	@echo ""
	@echo "  program1-10  - Program specific assignment to MCU"
	@echo "  clean        - Remove all build files"
	@echo "  report       - Show size report for all assignments"
	@echo "  setfuses8mhz - Set fuses for 8MHz crystal"
	@echo "  setfuses16mhz- Set fuses for 16MHz crystal"
	@echo "  readfuses    - Read current fuse settings"
	@echo "  verify       - Verify programming"
	@echo "  help         - Show this help message"

# Dependency tracking
-include $(ASSIGNMENTS:%=%.d)

# Pattern rule for dependency generation
%.d: %.asm
	@echo "Generating dependencies for $*..."
	@$(CC) -MM $(ASFLAGS) $< > $@

# Special targets that don't correspond to files
.PHONY: all clean help report readfuses verify $(ASSIGNMENTS)

# Default goal
.DEFAULT_GOAL := all
