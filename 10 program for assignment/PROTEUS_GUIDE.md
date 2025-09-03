
# How to Open .pdsprj Files in Proteus 8.13

## Method 1: Direct Opening
1. Open Proteus 8.13 ISIS (Schematic Editor)
2. Go to File → Open Project
3. Navigate to the assignment folder
4. Select the .pdsprj file (assignment1.pdsprj, assignment2.pdsprj, etc.)
5. Click Open

## Method 2: Double-Click
Simply double-click on any .pdsprj file in Windows Explorer - it will automatically open in Proteus 8.13.

## Important Notes:

### File Format Compatibility
- `.pdsprj` files are native Proteus project format
- Compatible with Proteus 8.x versions
- Should not show corruption errors (unlike .DSN format)

### HEX File Requirements
Each project expects a corresponding .hex file:
- assignment1.pdsprj needs assignment1.hex
- assignment2.pdsprj needs assignment2.hex
- And so on...

### Creating HEX Files
To generate the required .hex files for simulation:
1. Navigate to the assignment folder in terminal
2. Run: `make all`
3. This will compile all .asm files to .hex files
4. The .hex files will be placed in the same directory

### Circuit Components Included
Each .pdsprj file contains:
- ATmega32 microcontroller (pre-configured with program file)
- Required components (LEDs, LCD, sensors, etc.)
- Proper connections and wiring
- Power supply connections (VCC/GND)
- Crystal oscillator (8MHz) for timing

### Simulation Steps
1. Open the .pdsprj file
2. Ensure the corresponding .hex file exists
3. Click the Play button (►) to start simulation
4. Use the interactive components (buttons, potentiometers)
5. Observe outputs on LEDs, LCD displays, etc.

### Troubleshooting
If simulation doesn't work:
- Check if .hex file exists in same folder
- Verify component connections in ISIS
- Ensure ATmega32 program property points to correct .hex file
- Check power supply connections (VCC = +5V, GND)

## Assignment-Specific Notes:

### Assignment 1-3: Basic GPIO
- Simple LED controls and 7-segment displays
- Good for learning basic simulation

### Assignment 4-6: Advanced Peripherals  
- PWM motor control, LCD displays, ADC sensors
- Test with potentiometers and sensor inputs

### Assignment 7-10: Complex Systems
- Interrupt timers, keypads, UART, EEPROM
- May require virtual terminal for UART communication

All projects are ready to simulate immediately after opening in Proteus 8.13!
