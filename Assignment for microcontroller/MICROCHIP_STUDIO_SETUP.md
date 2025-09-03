# Touch Security Alarm - Complete Setup Guide

## Project Files

### 1. Assembly Code Files
- **`touch_security_alarm.asm`** - GCC AVR Toolchain compatible version
- **`touch_security_alarm_microchip.asm`** - Microchip Studio compatible version
- **`Makefile`** - For command-line compilation with AVR-GCC

### 2. Generated Output Files (in `build/` directory)
- **`touch_security_alarm.hex`** - Intel HEX file for programming
- **`touch_security_alarm.elf`** - ELF executable file
- **`touch_security_alarm.lst`** - Assembly listing file
- **`touch_security_alarm.o`** - Object file

## Hardware Configuration
- **Microcontroller**: ATmega32
- **Clock Frequency**: 16 MHz (external crystal)
- **Touch Sensor**: Connected to PD2 (INT0)
- **LED**: Connected to PB0 (with 220Ω current limiting resistor)
- **Buzzer**: Connected to PB1

## Compilation Methods

### Method 1: Command Line (GCC AVR Toolchain)
```bash
# Clean and build
make clean
make

# Flash to microcontroller (requires programmer setup)
make flash

# Check memory usage
make size
```

### Method 2: Microchip Studio IDE
1. Open Microchip Studio
2. File → New → Project
3. Select "GCC C ASM Project"
4. Choose "ATmega32" as target device
5. Name the project "TouchSecurityAlarm"
6. Replace the generated ASM file with `touch_security_alarm_microchip.asm`
7. Build → Build Solution (F7)

## Project Configuration

### For Microchip Studio:
- **Device**: ATmega32
- **Toolchain**: GCC (GNU Compiler Collection)
- **Optimization**: -Os (Size optimization)
- **F_CPU**: 16000000UL

### Fuse Settings:
- **CKSEL**: External Crystal/Resonator High Freq; Start-up time: 16K CK + 64ms
- **SUT**: Start-up time as per CKSEL
- **BOOTRST**: Boot Flash section size = Boot Reset vector enabled

## Hardware Connections

```
ATmega32 Pin Connections:
┌─────────────────────────────┐
│        ATmega32            │
│                            │
│ PD2 (INT0) ←──── Touch     │
│                  Sensor    │
│                  (Active   │
│                   High)    │
│                            │
│ PB0 ───220Ω───→ LED        │
│                 (Anode)    │
│                            │
│ PB1 ───────────→ Buzzer    │
│                 (+ve)      │
│                            │
│ VCC ───────────→ +5V       │
│ GND ───────────→ GND       │
│                            │
│ XTAL1/XTAL2 ←──→ 16MHz     │
│                  Crystal   │
│                  + 22pF    │
│                  caps      │
└─────────────────────────────┘
```

## Code Features
- **Interrupt-driven**: Uses external interrupt INT0 for touch detection
- **Non-blocking**: Main loop remains free for other tasks
- **Multiple beeps**: Generates 5 beep alarm sequence
- **LED indication**: Visual feedback when alarm is triggered
- **Auto-reset**: System returns to standby mode after alarm sequence
- **Memory efficient**: Uses only 224 bytes of program memory (0.7% of ATmega32)

## Programming the Microcontroller

### Using AVR Programmer:
```bash
# Using USBasp programmer
avrdude -p atmega32 -c usbasp -U flash:w:build/touch_security_alarm.hex:i

# Using Arduino as ISP
avrdude -p atmega32 -c stk500v1 -P COM3 -b 19200 -U flash:w:build/touch_security_alarm.hex:i
```

### Using Microchip Studio:
1. Connect your programmer (AVRISP mkII, USBasp, etc.)
2. Tools → Device Programming
3. Select Interface and Device
4. Load the HEX file
5. Program the device

## Testing Procedure
1. **Power up** the ATmega32 with 5V supply
2. **Verify connections** - LED and buzzer should be OFF initially
3. **Touch the sensor** - LED should light up immediately
4. **Listen for alarm** - Buzzer should beep 5 times
5. **Check reset** - LED should turn OFF after alarm sequence
6. **Repeat test** - System should respond to subsequent touches

## Troubleshooting

### Common Issues:
1. **No response to touch**: Check INT0 (PD2) connection and pull-up resistor
2. **LED doesn't light**: Verify PB0 connection and current limiting resistor
3. **No buzzer sound**: Check PB1 connection and buzzer polarity
4. **Continuous alarm**: Touch sensor may be stuck HIGH - check sensor wiring

### Programming Issues:
1. **Compilation errors**: Ensure correct toolchain version and file paths
2. **Upload failures**: Verify programmer connections and fuse settings
3. **Memory errors**: Code size (224 bytes) should fit easily in ATmega32

## Memory Usage
- **Program Memory**: 224 bytes (0.7% of 32KB flash)
- **Data Memory**: 0 bytes (0.0% of 2KB SRAM)
- **EEPROM**: Not used

This leaves plenty of space for additional features or code expansion.
