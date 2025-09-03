# ====================================================================
# PROTEUS 8.13 SIMULATION GUIDE FOR ASSEMBLY ASSIGNMENTS
# Complete Setup Guide for Circuit Simulation
# ====================================================================

## Table of Contents
1. [Proteus 8.13 Setup](#proteus-setup)
2. [Creating New Projects](#new-projects)
3. [Component Library](#component-library)
4. [Circuit Import Methods](#import-methods)
5. [Simulation Configuration](#simulation-config)
6. [Troubleshooting Guide](#troubleshooting)
7. [Assignment-Specific Instructions](#assignment-instructions)

---

## 1. Proteus 8.13 Setup {#proteus-setup}

### System Requirements:
- Windows 7/8/10/11 (32-bit or 64-bit)
- Minimum 4GB RAM (8GB recommended)
- 2GB free disk space
- DirectX 9.0c or later

### Installation Steps:
1. Download Proteus 8.13 Professional
2. Run installer as Administrator
3. Select "Full Installation" for all components
4. Install with default libraries enabled
5. Apply license (if using licensed version)

### Important Proteus Settings for AVR:
```
Tools → System Settings → Animation
- Enable "Realtime Animation"
- Set Speed to "Maximum"

Tools → System Settings → General
- Enable "Auto-backup every 5 minutes"
- Set Grid to 0.1 inches

Debug → AVR CPU Model
- Select "ATmega32"
- Clock Frequency: As per crystal (8MHz/16MHz)
```

---

## 2. Creating New Projects {#new-projects}

### Step-by-Step Project Creation:

1. **Start New Project:**
   ```
   File → New Project
   - Select "Schematic Capture"
   - Choose "A4 Landscape" sheet size
   - Name: "Assignment_X_Circuit"
   ```

2. **Set Project Properties:**
   ```
   Edit → Project Settings
   - Title: Assignment X - [Description]
   - Author: Your Name
   - Company: Electronics Course
   - Comments: Add circuit description
   ```

3. **Configure Simulation:**
   ```
   Debug → Use Simulation Schematic
   - Enable "Real-time simulation"
   - Set Animation quality to "High"
   ```

---

## 3. Component Library {#component-library}

### Essential AVR Components:

#### Microcontrollers:
```
Library: MICROCONTROLLERS
- ATMEGA32-P (40-pin DIP package)
- ATMEGA32-A (TQFP package)
- ATMEGA16-P (40-pin DIP package)
```

#### Basic Components:
```
Library: DEVICES
- LED-RED, LED-YELLOW, LED-GREEN
- RES (Resistors: 220R, 1K, 10K)
- CAP (Capacitors: 22pF, 100nF, 10uF)
- CRYSTAL (8MHz, 16MHz, 32.768kHz)

Library: ACTIVE
- LM35 (Temperature sensor)
- LDR (Light dependent resistor)

Library: ELECTROMECHANICAL
- BUTTON (Push button)
- POT-LIN (Linear potentiometer)
- BUZZER (Piezo buzzer)
- SERVO (SG90 servo motor)

Library: DISPLAYS
- 7SEG-CC (7-segment common cathode)
- 7SEG-CA (7-segment common anode)
- LCD016X2 (16x2 character LCD)

Library: CONNECTORS
- KEYPAD4X4 (4x4 matrix keypad)
```

### Adding Components:
1. Click "Pick from Library" (P key)
2. Search component name (e.g., "ATMEGA32")
3. Select correct package (DIP/TQFP)
4. Place on schematic

---

## 4. Circuit Import Methods {#import-methods}

### Method 1: Manual Circuit Creation

1. **Place ATmega32:**
   - Position at center of schematic
   - Right-click → Properties → Set clock frequency

2. **Add Power Connections:**
   ```
   VCC (Pin 11) → POWER terminal (+5V)
   GND (Pin 32) → GROUND terminal
   AVCC (Pin 30) → VCC (for ADC projects)
   ```

3. **Add Crystal Circuit:**
   ```
   XTAL1 (Pin 13) → Crystal Pin 1
   XTAL2 (Pin 12) → Crystal Pin 2
   Both crystal pins → 22pF capacitors → GND
   ```

4. **Wire Connections:**
   - Use "Wire" tool (W key)
   - Click start pin, click end pin
   - Add junctions where needed

### Method 2: Using Proteus Design Files

If you have .DSN files:
1. File → Open Design
2. Select .DSN file
3. Components will be loaded automatically

### Method 3: Import from Text (For Advanced Users)

Some assignments include import data that can be used with:
1. File → Import → Netlist
2. Select format "Generic"
3. Paste component and connection data

---

## 5. Simulation Configuration {#simulation-config}

### AVR Microcontroller Setup:

1. **Right-click ATmega32 → Edit Properties:**
   ```
   Program File: Browse to .hex file
   Processor Clock Frequency: 8000000 (for 8MHz)
   CKOPT Fuse: Checked (for crystal > 1MHz)
   ```

2. **Load Assembly Program:**
   ```
   File → Open → Select your .hex file
   OR
   Build .hex from .asm using AVR Studio/Microchip Studio
   ```

3. **Set Debug Options:**
   ```
   Debug → AVR CPU Model → ATmega32
   Debug → Set Simulation Speed → Maximum
   ```

### Starting Simulation:
1. Click "Play" button (or F12)
2. Monitor digital/analog pins
3. Use oscilloscope for timing analysis
4. Add breakpoints for debugging

---

## 6. Troubleshooting Guide {#troubleshooting}

### Common Issues and Solutions:

#### Issue 1: "No hex file specified"
```
Solution:
- Right-click microcontroller
- Properties → Program File
- Browse to compiled .hex file
- Ensure .hex file is in same directory as .dsn
```

#### Issue 2: "Crystal not oscillating"
```
Solution:
- Check crystal connections to XTAL1/XTAL2
- Verify 22pF capacitors to ground
- Check CKOPT fuse setting
- Ensure crystal frequency matches code
```

#### Issue 3: "ADC not working"
```
Solution:
- Connect AVCC to VCC
- Add 100nF capacitor from AVCC to GND
- Connect AREF to VCC (with 100nF cap)
- Check ADC input voltage range (0-5V)
```

#### Issue 4: "LCD not displaying"
```
Solution:
- Check all 6 data/control connections
- Add contrast pot (10kΩ) to V0 pin
- Verify power connections (VDD/VSS)
- Check initialization timing in code
```

#### Issue 5: "Simulation too slow"
```
Solution:
- Debug → Animation Options → Set to Maximum
- Reduce animation quality
- Close unnecessary probe windows
- Disable real-time mode if not needed
```

---

## 7. Assignment-Specific Instructions {#assignment-instructions}

### Assignment 1: LED Blinker
```
Components: ATmega32, LED, 220Ω resistor
Key Points:
- Connect LED anode to PB0 through 220Ω
- Set processor clock to 8MHz
- Load assignment1.hex file
- Expected: LED blinks every 1 second
```

### Assignment 2: Traffic Light
```
Components: ATmega32, 3 LEDs (Red/Yellow/Green), 3x 220Ω
Key Points:
- Red LED → PB0, Yellow → PB1, Green → PB2
- Sequence: Red(5s) → Red+Yellow(2s) → Green(5s) → Yellow(2s)
- Total cycle: 14 seconds
```

### Assignment 3: 7-Segment Counter
```
Components: ATmega32, 7-segment display, push button, resistors
Key Points:
- 7-segment connected to PORTC (PC0-PC6)
- Button connected to PD0 with pull-up resistor
- Each press increments display (0-9)
```

### Assignment 4: PWM Brightness
```
Components: ATmega32, LED, potentiometer
Key Points:
- Potentiometer wiper → PA0 (ADC0)
- LED → PD5 (OC1A) through 220Ω
- Turn pot to see LED brightness change
```

### Assignment 5: Temperature Monitor
```
Components: ATmega32, LM35, LCD 16x2
Key Points:
- LM35 output → PA1 (ADC1)
- LCD connected in 4-bit mode to PORTD
- Temperature displayed in Celsius
```

### Assignment 6: Servo Control
```
Components: ATmega32, servo motor, potentiometer
Key Points:
- Servo signal → PD5 (OC1A)
- External 5V supply for servo
- Potentiometer controls servo position (0-180°)
```

### Assignment 7: Digital Clock
```
Components: ATmega32, LCD, buttons, buzzer, 32.768kHz crystal
Key Points:
- Use 32kHz crystal for accurate timekeeping
- Multiple buttons for time setting
- Alarm function with buzzer output
```

### Assignment 8: Keypad Security
```
Components: ATmega32, 4x4 keypad, LCD, LEDs
Key Points:
- Keypad rows → PC0-PC3 (outputs)
- Keypad columns → PC4-PC7 (inputs with pull-ups)
- Default password: "1234"
```

### Assignment 9: Ultrasonic Sensor
```
Components: ATmega32, HC-SR04, LCD, LEDs, buzzer
Key Points:
- TRIG → PD6, ECHO → PD7 (ICP1)
- Use Timer1 input capture for accurate measurement
- Distance thresholds: >50cm (green), 20-50cm (yellow), <20cm (red)
```

### Assignment 10: Data Logger
```
Components: ATmega32, LM35, LDR, LCD, LEDs, UART
Key Points:
- Most complex project with multiple subsystems
- EEPROM storage simulation
- UART communication for data download
- Multiple sensors and real-time logging
```

---

## Quick Reference Commands

### Proteus Shortcuts:
```
P - Pick component from library
W - Wire tool
T - Text tool
R - Rotate component
Del - Delete selected
Ctrl+S - Save project
F12 - Start/Stop simulation
Esc - Cancel current operation
```

### File Extensions:
```
.DSN - Proteus design file
.PWI - Proteus workspace
.HEX - Compiled assembly program
.ASM - Assembly source code
.LST - Assembly listing file
```

### Simulation Controls:
```
Play - Start simulation
Pause - Pause simulation
Stop - Stop simulation
Step - Single step execution
Reset - Reset microcontroller
```

---

## Support and Resources

### Documentation:
- Proteus Help: F1 key or Help menu
- AVR Instruction Set: Available in help
- Component Datasheets: Right-click component → Datasheet

### Online Resources:
- Labcenter Electronics (Proteus official site)
- AVR Microchip documentation
- Assembly language tutorials

### Getting Help:
1. Check this guide first
2. Consult Proteus help system
3. Review component datasheets
4. Check circuit connections
5. Verify .hex file compilation

---

**Note:** This guide is optimized for Proteus 8.13. Some features may vary in different versions. Always ensure your .hex files are compiled correctly before simulation.
