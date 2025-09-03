# Touch Security Alarm System - Assembly Language

## Overview
This project implements a touch-based security alarm system using ATmega32 microcontroller in assembly language. When a touch is detected, the system triggers an LED and buzzer alarm sequence.

## Quick Start

### Compilation (Command Line)
```bash
make clean && make
```

### Files Generated
- `build/touch_security_alarm.hex` - Ready to program to microcontroller
- `build/touch_security_alarm.elf` - Executable file
- `build/touch_security_alarm.lst` - Assembly listing

### Hardware Requirements
- ATmega32 microcontroller
- Touch sensor → PD2 (INT0)
- LED → PB0 (with 220Ω resistor)
- Buzzer → PB1
- 16MHz crystal oscillator
- 5V power supply

### Code Versions
1. **`touch_security_alarm.asm`** - GCC AVR compatible (compiles with command line)
2. **`touch_security_alarm_microchip.asm`** - Microchip Studio compatible

### Memory Usage
- Program: 224 bytes (0.7% of ATmega32 flash memory)
- Data: 0 bytes
- Total space available for expansion: 99.3%

### Programming
```bash
# Using USBasp programmer
avrdude -p atmega32 -c usbasp -U flash:w:build/touch_security_alarm.hex:i
```

## How It Works
1. System initializes and waits in low-power mode
2. Touch sensor triggers external interrupt (INT0)
3. Interrupt handler turns on LED and calls alarm routine
4. Buzzer beeps 5 times with LED indication
5. System returns to standby mode

## Error-Free Compilation
✅ Successfully compiles without errors  
✅ Generates proper HEX file  
✅ Compatible with Microchip Studio  
✅ Memory efficient implementation  
✅ Proper interrupt handling  

For detailed setup instructions, see `MICROCHIP_STUDIO_SETUP.md`

## Circuit Connections

```
                              ATmega32
                            ┌────────────┐
                            │            │
        Touch Sensor    ──► │PD2     PB0│ ──► LED (Red)
        (Capacitive)        │   INT0    │     + 220Ω
                           │        PB1│ ──► Buzzer
                     +5V ─► │VCC    GND│ ──► GND
                           └────────────┘
```

### Components Required:
1. ATmega32 Microcontroller
2. Touch Sensor Module (TTP223B or similar)
3. LED (Red) with 220Ω resistor
4. Buzzer (5V)
5. 16MHz Crystal with 22pF capacitors
6. 100nF decoupling capacitor
7. Power supply (5V)

For detailed circuit diagram and Proteus simulation, refer to `CIRCUIT_DIAGRAM_WELCOME_Codes.md`
1. Start Proteus VSM
2. Place the components as shown in the diagram above
3. Load the compiled HEX file into ATmega328P
4. Run the simulation
5. Click on the touch sensor pad to test the alarm system

The system will respond with:
- Immediate LED illumination
- 5 sequential buzzer beeps
- Return to monitoring state

Safety features:
- Built-in pullup resistors are enabled
- Hardware debouncing through interrupt configuration
- Protected I/O pins through current-limiting resistors
