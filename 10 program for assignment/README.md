# Assembly Language Assignments for Microcontroller Electronics

This repository contains 10 comprehensive assembly language assignments for ATmega32 microcontroller, progressing from beginner to expert level. Each assignment includes complete source code, Proteus simulation files, and detailed documentation.

## 📋 Table of Contents
- [Assignment Overview](#assignment-overview)
- [Hardware Requirements](#hardware-requirements)
- [Software Requirements](#software-requirements)
- [Quick Start Guide](#quick-start-guide)
- [Assignment Details](#assignment-details)
- [Proteus Simulation Guide](#proteus-simulation-guide)
- [Programming Guide](#programming-guide)
- [Troubleshooting](#troubleshooting)
- [Learning Objectives](#learning-objectives)

## 🎯 Assignment Overview

| Assignment | Name | Difficulty | Learning Focus |
|------------|------|------------|----------------|
| 1 | LED Blinker | Beginner | Basic GPIO control, delays |
| 2 | Traffic Light Controller | Beginner+ | State machines, timing |
| 3 | 7-Segment Counter | Intermediate | Input handling, display control |
| 4 | PWM LED Brightness | Intermediate | ADC, PWM generation |
| 5 | Temperature Monitor | Intermediate+ | Sensor interfacing, LCD |
| 6 | Servo Motor Control | Advanced | Precise PWM, motor control |
| 7 | Digital Clock with Alarm | Advanced | RTC, interrupts, UI |
| 8 | Keypad Security System | Advanced+ | Matrix scanning, security |
| 9 | Ultrasonic Distance Sensor | Expert | Timer capture, measurement |
| 10 | Data Logger System | Expert+ | EEPROM, UART, multi-sensor |

## 🔧 Hardware Requirements

### Essential Components (All Assignments):
- **ATmega32 Microcontroller** (40-pin DIP package)
- **8MHz Crystal** + 2x 22pF capacitors
- **16MHz Crystal** (for assignments 6, 9, 10)
- **32.768kHz Crystal** (for assignment 7)
- **5V Regulated Power Supply**
- **Breadboard** and connecting wires

### Assignment-Specific Components:

#### Assignment 1: LED Blinker
- 1x LED (any color)
- 1x 220Ω resistor

#### Assignment 2: Traffic Light
- 3x LEDs (Red, Yellow, Green)
- 3x 220Ω resistors

#### Assignment 3: 7-Segment Counter
- 1x 7-segment display (common cathode)
- 8x 220Ω resistors
- 1x Push button
- 1x 10kΩ pull-up resistor

#### Assignment 4: PWM LED Control
- 1x LED
- 1x 220Ω resistor
- 1x 10kΩ potentiometer
- 2x Capacitors (100nF, 10μF for ADC filtering)

#### Assignment 5: Temperature Monitor
- 1x LM35 temperature sensor
- 1x 16x2 LCD display
- 1x 10kΩ potentiometer (LCD contrast)
- Capacitors for ADC filtering

#### Assignment 6: Servo Motor Control
- 1x Servo motor (SG90 or similar)
- 1x 10kΩ potentiometer
- External 5V/1A power supply for servo

#### Assignment 7: Digital Clock
- 1x 16x2 LCD display
- 4x Push buttons (Set, Up, Down, Alarm)
- 4x 10kΩ pull-up resistors
- 1x Piezo buzzer
- 1x 32.768kHz RTC crystal

#### Assignment 8: Keypad Security
- 1x 4x4 matrix keypad
- 1x 16x2 LCD display
- 3x LEDs (Green, Red, Blue)
- 3x 220Ω resistors
- 1x Buzzer

#### Assignment 9: Ultrasonic Sensor
- 1x HC-SR04 ultrasonic sensor
- 1x 16x2 LCD display
- 3x LEDs (Green, Yellow, Red)
- 3x 220Ω resistors
- 1x Buzzer

#### Assignment 10: Data Logger
- 1x LM35 temperature sensor
- 1x LDR (light sensor) + 10kΩ resistor
- 1x 16x2 LCD display
- 3x Status LEDs
- 2x Control buttons
- 1x USB-to-Serial converter (for UART)

## 💻 Software Requirements

### Development Tools:
1. **Microchip Studio** (formerly Atmel Studio) - Latest version
   - Download: [Microchip Studio](https://www.microchip.com/mplab/microchip-studio)
   - Alternative: **AVR-GCC toolchain** + **Make**

2. **Proteus Design Suite 8.13+**
   - For circuit simulation and testing
   - Professional or Student version

3. **Programming Software:**
   - **AVRDUDE** - Command line programmer
   - **AVR ISP** or **USBasp** programmer hardware

### Optional Tools:
- **VSCode** with AVR extensions
- **Arduino IDE** (can be used for basic compilation)
- **Terminal/Command Prompt** for Make commands

## 🚀 Quick Start Guide

### Step 1: Setup Development Environment

1. **Install Microchip Studio:**
   ```bash
   # Download and install Microchip Studio
   # Create new ASM project targeting ATmega32
   ```

2. **Install AVR-GCC (Alternative):**
   ```bash
   # On Windows (using WinAVR or AVR-GCC)
   # On Linux:
   sudo apt-get install gcc-avr avr-libc avrdude

   # Verify installation:
   avr-gcc --version
   ```

3. **Setup Proteus:**
   - Install Proteus 8.13 or later
   - Ensure AVR libraries are available
   - Configure simulation settings

### Step 2: Build Your First Assignment

1. **Using Make (Recommended):**
   ```bash
   # Build all assignments
   make all

   # Build specific assignment
   make assignment1

   # Clean build files
   make clean

   # Show help
   make help
   ```

2. **Using Microchip Studio:**
   - Open assignment1.asm
   - Build → Build Solution (F7)
   - Check for errors in output window

3. **Manual Compilation:**
   ```bash
   # Compile assembly to ELF
   avr-gcc -mmcu=atmega32 -o assignment1.elf assignment1.asm

   # Create hex file
   avr-objcopy -O ihex -R .eeprom assignment1.elf assignment1.hex

   # Check size
   avr-size assignment1.elf
   ```

### Step 3: Simulate in Proteus

1. **Load Design:**
   - Open Proteus
   - File → Import → Select assignment1.dsn
   - Or manually build circuit using proteus_guide.md

2. **Load Program:**
   - Right-click ATmega32
   - Properties → Program File → assignment1.hex
   - Set Clock Frequency: 8000000

3. **Start Simulation:**
   - Click Play button
   - Observe LED blinking
   - Use probes for debugging

### Step 4: Program Real Hardware

1. **Setup Programmer:**
   ```bash
   # For USBasp programmer
   make program1

   # Manual programming
   avrdude -p atmega32 -c usbasp -U flash:w:assignment1.hex:i
   ```

2. **Set Fuses (Important!):**
   ```bash
   # For 8MHz external crystal
   make setfuses8mhz

   # For 16MHz external crystal  
   make setfuses16mhz

   # Read current fuses
   make readfuses
   ```

## 📚 Assignment Details

### Assignment 1: LED Blinker
**Objective:** Learn basic GPIO control and delay generation
**Files:** `assignment1.asm`, `assignment1.dsn`
**Circuit:** Simple LED connected to PB0 through 220Ω resistor
**Expected Behavior:** LED blinks ON for 500ms, OFF for 500ms

**Key Learning Points:**
- AVR assembly syntax
- Port configuration (DDR, PORT registers)
- Delay loop implementation
- Basic program structure

### Assignment 2: Traffic Light Controller
**Objective:** Implement a state machine for traffic light sequence
**Files:** `assignment2.asm`, `assignment2.dsn`
**Circuit:** 3 LEDs (Red, Yellow, Green) on PB0-PB2
**Sequence:** Red(5s) → Red+Yellow(2s) → Green(5s) → Yellow(2s) → Repeat

**Key Learning Points:**
- State machine programming
- Multiple output control
- Timing coordination
- Structured programming

### Assignment 3: 7-Segment Display Counter
**Objective:** Handle input and convert data for display
**Files:** `assignment3.asm`, `assignment3.dsn`
**Circuit:** 7-segment display + push button with debouncing
**Behavior:** Count 0-9 on each button press, reset at 10

**Key Learning Points:**
- Input polling and debouncing
- BCD to 7-segment conversion
- Lookup tables
- Input/output coordination

### Assignment 4: PWM LED Brightness Control
**Objective:** Generate PWM signals and read analog inputs
**Files:** `assignment4.asm`, `assignment4.dsn`
**Circuit:** LED controlled by PWM, potentiometer for ADC input
**Behavior:** LED brightness follows potentiometer position

**Key Learning Points:**
- ADC configuration and reading
- PWM generation using timers
- Analog signal processing
- Timer/counter programming

### Assignment 5: Temperature Monitoring with LCD
**Objective:** Interface sensors and display information
**Files:** `assignment5.asm`, `assignment5.dsn`
**Circuit:** LM35 temperature sensor + 16x2 LCD display
**Behavior:** Display current temperature in Celsius

**Key Learning Points:**
- LCD interfacing (4-bit mode)
- Sensor signal conditioning
- Temperature calculation
- Data formatting and display

### Assignment 6: Servo Motor Control System
**Objective:** Generate precise PWM for servo motor control
**Files:** `assignment6.asm`, `assignment6.dsn`
**Circuit:** Servo motor + potentiometer for position control
**Behavior:** Servo position follows potentiometer (0-180°)

**Key Learning Points:**
- Precise PWM timing (20ms period, 1-2ms pulse)
- Motor control principles
- Real-time control systems
- Power supply considerations

### Assignment 7: Digital Clock with Alarm
**Objective:** Create a full-featured real-time clock
**Files:** `assignment7.asm`, `assignment7.dsn`
**Circuit:** LCD + multiple buttons + buzzer + RTC crystal
**Features:** Time display, time setting, alarm with buzzer

**Key Learning Points:**
- Real-time clock implementation
- Interrupt-driven programming
- User interface design
- Multiple input handling

### Assignment 8: Keypad Security System
**Objective:** Implement matrix keypad scanning and security logic
**Files:** `assignment8.asm`, `assignment8.dsn`
**Circuit:** 4x4 keypad + LCD + status LEDs + buzzer
**Features:** Password entry, access control, lockout protection

**Key Learning Points:**
- Matrix keypad scanning
- String comparison
- Security system logic
- User feedback systems

### Assignment 9: Ultrasonic Distance Sensor
**Objective:** Precision timing measurement and distance calculation
**Files:** `assignment9.asm`, `assignment9.dsn`
**Circuit:** HC-SR04 sensor + LCD + warning LEDs + buzzer
**Features:** Distance measurement, proximity warnings, alert system

**Key Learning Points:**
- Timer input capture
- Precise time measurement
- Distance calculations
- Multi-level warning system

### Assignment 10: Advanced Data Logger
**Objective:** Multi-sensor data acquisition and storage system
**Files:** `assignment10.asm`, `assignment10.dsn`
**Circuit:** Multiple sensors + LCD + UART + status indicators
**Features:** Data logging, EEPROM storage, UART communication

**Key Learning Points:**
- Multi-sensor coordination
- Data storage strategies
- Serial communication
- Complex system integration

## 🔬 Proteus Simulation Guide

### Setting up Proteus for AVR Simulation:

1. **Component Library Setup:**
   - Ensure MICROCONTROLLERS.LIB is loaded
   - Check DEVICES.LIB for basic components
   - ACTIVE.LIB for sensors (LM35, etc.)

2. **ATmega32 Configuration:**
   ```
   Right-click ATmega32 → Properties:
   - Program File: Browse to .hex file
   - Clock Frequency: Match crystal (8MHz/16MHz)
   - Fuse Settings: CKOPT checked for external crystal
   ```

3. **Common Simulation Issues:**
   - **Crystal not oscillating:** Check connections and capacitors
   - **ADC not working:** Connect AVCC to VCC, add filtering caps
   - **LCD not displaying:** Verify all 6 connections, add contrast pot
   - **Timing issues:** Ensure clock frequency matches code

4. **Using Simulation Tools:**
   - **Digital Probe:** Monitor pin states
   - **Oscilloscope:** Analyze PWM signals
   - **Logic Analyzer:** Debug digital communication
   - **Graph:** Plot ADC readings over time

## 📡 Programming Guide

### Programming ATmega32 (Real Hardware):

1. **Hardware Programmer Setup:**
   ```
   Programmer Options:
   - USBasp (cheap, reliable)
   - AVR ISP mkII (official Atmel)
   - Arduino as ISP
   - USBASP v2.0 (supports all voltages)
   ```

2. **Fuse Settings:**
   ```bash
   # External 8MHz Crystal
   Low Fuse: 0xEF (External crystal, slow rising power)
   High Fuse: 0xC9 (SPIEN enabled, Brown-out 2.7V)
   
   # External 16MHz Crystal  
   Low Fuse: 0xFF (External crystal, fast rising power)
   High Fuse: 0xC9 (SPIEN enabled, Brown-out 2.7V)
   ```

3. **Programming Commands:**
   ```bash
   # Program flash memory
   avrdude -p atmega32 -c usbasp -U flash:w:assignment1.hex:i
   
   # Set fuses (IMPORTANT!)
   avrdude -p atmega32 -c usbasp -U lfuse:w:0xef:m -U hfuse:w:0xc9:m
   
   # Verify programming
   avrdude -p atmega32 -c usbasp -U flash:v:assignment1.hex:i
   
   # Read fuses
   avrdude -p atmega32 -c usbasp -U lfuse:r:-:h -U hfuse:r:-:h
   ```

## 🐛 Troubleshooting

### Common Issues and Solutions:

#### Compilation Errors:
```
Error: Unknown directive '.include'
Solution: Use #include for GCC, or .include for native assembler

Error: Undefined symbol 'RAMEND'
Solution: Ensure correct include file (.include "m32def.inc")

Error: Invalid instruction
Solution: Check AVR instruction set, verify register usage
```

#### Programming Errors:
```
Error: Device not responding
Solution: Check programmer connections, verify VCC, check fuses

Error: Wrong signature
Solution: Ensure correct MCU type (-p atmega32)

Error: Crystal not starting
Solution: Check crystal connections, verify load capacitors (22pF)
```

#### Simulation Issues:
```
Problem: No simulation activity
Solution: Check Program File is loaded, verify clock frequency

Problem: Incorrect timing
Solution: Match crystal frequency in simulation with code

Problem: ADC readings wrong
Solution: Connect AVCC to VCC, add reference capacitors
```

#### Hardware Issues:
```
Problem: Circuit not working after programming
Solution: Check power supply, verify all connections, test with multimeter

Problem: Inconsistent behavior
Solution: Add decoupling capacitors (100nF near MCU), check for loose connections

Problem: Programming fails
Solution: Check ISP connections (MISO, MOSI, SCK, RESET), verify programmer drivers
```

### Debug Checklist:
1. ✅ Power supply stable 5V ±5%
2. ✅ Crystal oscillating (check with scope)
3. ✅ Fuses set correctly
4. ✅ Program compiled without errors
5. ✅ All connections secure
6. ✅ Component orientations correct
7. ✅ Decoupling capacitors present

## 🎓 Learning Objectives

### By completing these assignments, you will master:

#### Programming Skills:
- AVR assembly language syntax
- Register and memory manipulation
- Control flow and loops
- Subroutine design
- Interrupt handling
- Timer/counter programming

#### Hardware Skills:
- Microcontroller pin configuration
- Digital I/O control
- Analog input processing
- PWM signal generation
- Serial communication
- Real-time system design

#### Electronics Knowledge:
- Circuit design and analysis
- Component selection
- Power supply design
- Signal conditioning
- PCB layout principles
- Debugging techniques

#### System Design:
- Requirements analysis
- State machine design
- User interface design
- Error handling
- System integration
- Documentation

## 📁 File Structure
```
10 program for assignment/
├── assignment1.asm          # LED Blinker source
├── assignment2.asm          # Traffic Light source
├── assignment3.asm          # 7-Segment Counter source
├── assignment4.asm          # PWM LED Control source
├── assignment5.asm          # Temperature Monitor source
├── assignment6.asm          # Servo Control source
├── assignment7.asm          # Digital Clock source
├── assignment8.asm          # Keypad Security source
├── assignment9.asm          # Ultrasonic Sensor source
├── assignment10.asm         # Data Logger source
├── Makefile                 # Build automation
├── README.md               # This file
├── proteus_guide.md        # Proteus simulation guide
├── proteus_circuits.md     # Circuit diagrams
└── proteus_design_files.md # Complete design files
```

## 🤝 Contributing

Feel free to improve these assignments by:
- Adding more detailed comments
- Optimizing code efficiency
- Adding new features
- Fixing bugs
- Improving documentation

## 📄 License

This educational project is released under MIT License. Feel free to use, modify, and distribute for educational purposes.

## 💡 Tips for Success

1. **Start Simple:** Begin with Assignment 1 and progress sequentially
2. **Understand Hardware:** Build circuits carefully, double-check connections
3. **Use Simulation:** Test in Proteus before building real circuits
4. **Read Datasheets:** ATmega32 datasheet is your best friend
5. **Practice Debugging:** Learn to use oscilloscope and logic analyzer
6. **Document Everything:** Keep notes on what works and what doesn't
7. **Ask Questions:** Join AVR forums and communities for help

## 🔗 Additional Resources

- [ATmega32 Datasheet](https://ww1.microchip.com/downloads/en/devicedoc/doc2503.pdf)
- [AVR Instruction Set Manual](https://ww1.microchip.com/downloads/en/DeviceDoc/AVR-InstructionSet-Manual-DS40002198.pdf)
- [Proteus Help Documentation](https://www.labcenter.com/support/)
- [AVR Freaks Community](https://www.avrfreaks.net/)
- [Microchip Developer Help](https://microchipdeveloper.com/8avr:start)

---

**Happy Learning and Happy Coding! 🚀**

*This comprehensive guide should get you started with assembly language programming for microcontrollers. Each assignment builds upon the previous one, creating a solid foundation in embedded systems programming.*
