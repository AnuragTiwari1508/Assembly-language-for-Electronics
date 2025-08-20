# Hardware Setup and Circuit Diagram

## 🔌 Complete Parts List

### Microcontroller Section
- **1x ATmega32-16PU** (DIP-40 package)
- **1x 16MHz Crystal Oscillator**
- **2x 22pF Ceramic Capacitors** (for crystal)
- **1x 10kΩ Resistor** (reset pull-up)
- **1x Push Button** (reset switch)

### Power Supply Section
- **1x 7805 Voltage Regulator** (TO-220 package)
- **1x 100µF Electrolytic Capacitor** (input filter)
- **1x 10µF Electrolytic Capacitor** (output filter)
- **1x 9V Battery** or **7.4V Li-Po Battery**
- **1x Battery Connector/Holder**
- **1x Power Switch** (SPST)
- **1x Power LED** (with 330Ω resistor)

### Motor Drive Section
- **1x L298N Motor Driver Module**
- **2x DC Geared Motors** (6V, with wheels)
- **1x Robot Chassis** (acrylic/metal frame)
- **4x M3 Screws and Nuts** (motor mounting)

### Sensor Section
- **1x HC-SR04 Ultrasonic Sensor**
- **1x SG90 Servo Motor** (optional, for sensor rotation)
- **1x Servo Horn and Bracket**

### Display and Interface
- **1x 16x2 LCD Display** (HD44780 compatible)
- **1x 10kΩ Potentiometer** (contrast adjustment)
- **1x Buzzer** (5V active buzzer)
- **3x LEDs** (Red, Green, Blue for status)
- **3x 330Ω Resistors** (LED current limiting)

### Connectivity
- **1x Breadboard** or **Custom PCB**
- **Male-Female Jumper Wires** (40 pieces)
- **Male-Male Jumper Wires** (20 pieces)
- **2.54mm Pin Headers**
- **Screw Terminals** (for motor connections)

### Mechanical Parts
- **4x Wheels** (65mm diameter recommended)
- **1x Castor Wheel** (front/rear support)
- **M3 Standoffs and Screws**
- **Double-sided Tape/Velcro**
- **Cable Ties**

## 🔧 Assembly Instructions

### 1. Chassis Preparation
```
1. Attach motors to chassis using M3 screws
2. Mount wheels to motors
3. Install castor wheel for stability
4. Create mounting points for electronics
```

### 2. Power Circuit Assembly
```
VCC (9V Battery) → Switch → 7805 Input
7805 Output → 5V Rail (breadboard)
GND → Common Ground
```

**Power Circuit:**
```
+9V ──[Switch]──[100µF]──┤7805├──[10µF]──+5V
                    │      │        │
                   GND    GND      GND
```

### 3. Microcontroller Circuit
```
ATmega32 Pin Connections:
Pin 10 (VCC) → +5V
Pin 11 (GND) → GND  
Pin 9  (RESET) → 10kΩ → +5V
Pin 12 (XTAL1) → 16MHz Crystal
Pin 13 (XTAL2) → 16MHz Crystal
22pF capacitors from each crystal pin to GND
```

### 4. Motor Driver Connections
```
L298N Connections:
VCC → +5V (logic supply)
VS  → +9V (motor supply, direct from battery)
GND → Common Ground

Motor A:
OUT1, OUT2 → Left Motor
ENA → ATmega32 PD4 (PWM)
IN1 → ATmega32 PB0
IN2 → ATmega32 PB1

Motor B:
OUT3, OUT4 → Right Motor  
ENB → ATmega32 PD5 (PWM)
IN3 → ATmega32 PB2
IN4 → ATmega32 PB3
```

### 5. Sensor Connections
```
HC-SR04:
VCC → +5V
GND → GND
TRIG → ATmega32 PD6
ECHO → ATmega32 PD7

Servo (Optional):
Red → +5V
Black/Brown → GND
Yellow/Orange → ATmega32 PD3
```

### 6. LCD Display Setup
```
LCD Pin → ATmega32 Pin
VCC     → +5V
GND     → GND
RS      → PA0
EN      → PA1
D4      → PC4
D5      → PC5
D6      → PC6
D7      → PC7
V0 (Contrast) → 10kΩ potentiometer wiper
A (Backlight+) → +5V (through 330Ω resistor)
K (Backlight-) → GND
```

## 📐 Physical Layout Recommendations

### Electronics Placement
```
Top Level: LCD Display, Status LEDs
Middle Level: ATmega32, Breadboard, L298N
Bottom Level: Battery Pack, Power Switch

Sensor Mounting:
- Mount HC-SR04 on servo (if used)
- Position at front of robot
- Ensure clear 180° scanning range
```

### Weight Distribution
```
- Place heavy battery at bottom center
- Distribute electronics evenly
- Ensure stable center of gravity
- Test balance before final assembly
```

## ⚡ Power Consumption Analysis

### Current Requirements
```
Component               Current (mA)
ATmega32               20-30
HC-SR04                15
LCD Display            5-10  
L298N (quiescent)      10-15
LEDs (3x)              60
Servo SG90             100-600 (active)
DC Motors (2x)         500-1500 (under load)

Total (motors active): ~2000mA
Total (idle):          ~100mA
```

### Battery Life Estimation
```
9V Battery (500mAh):
- Continuous operation: ~15-20 minutes
- Intermittent operation: 1-2 hours

7.4V Li-Po (2200mAh):
- Continuous operation: ~1 hour
- Intermittent operation: 4-6 hours
```

## 🧪 Testing Procedures

### 1. Power System Test
```
1. Verify 5V regulated output
2. Check current consumption
3. Test battery voltage under load
4. Verify power LED operation
```

### 2. Microcontroller Test
```
1. Program simple LED blink
2. Test crystal oscillator (16MHz)
3. Verify all I/O pins
4. Test reset functionality
```

### 3. Motor System Test
```
1. Test individual motor directions
2. Verify PWM speed control
3. Check motor current consumption
4. Test turn accuracy and timing
```

### 4. Sensor Calibration
```
1. Measure known distances
2. Calibrate timing constants
3. Test maximum reliable range
4. Verify accuracy across temperature range
```

### 5. Integration Test
```
1. Test all systems together
2. Verify no electrical interference
3. Check mechanical stability
4. Test autonomous operation
```

## 🔍 Troubleshooting Guide

### Power Issues
```
Problem: Robot doesn't turn on
- Check battery voltage
- Verify power switch
- Test 7805 regulator output
- Check fuse (if installed)
```

### Motor Problems
```
Problem: Motors don't move
- Verify L298N connections
- Check motor power supply
- Test PWM signals with oscilloscope
- Ensure proper grounding
```

### Sensor Issues
```
Problem: Inaccurate distance readings
- Check 5V supply to sensor
- Verify trigger pulse timing (10µs)
- Test with known distances
- Check for electrical noise
```

### Programming Issues
```
Problem: Can't program ATmega32
- Verify programmer connections
- Check target power (5V)
- Confirm correct fuse settings
- Test with simple program first
```

## 📊 Performance Specifications

### Expected Performance
```
Map Resolution: 20cm x 20cm per grid cell
Mapping Area: 3.2m x 3.2m (16x16 grid)
Distance Accuracy: ±2cm (10cm-200cm range)
Maximum Speed: 30cm/second
Turn Accuracy: ±5 degrees
Battery Life: 1-4 hours (depending on battery)
Exploration Time: 10-30 minutes (area dependent)
```

### Operating Limits
```
Temperature: 0°C to 40°C
Humidity: <85% non-condensing
Maximum Slope: 15 degrees
Maximum Step Height: 1cm
Operating Voltage: 7V-12V input
```

This hardware setup provides a robust foundation for the ultrasonic mapping robot with room for future enhancements and modifications.
