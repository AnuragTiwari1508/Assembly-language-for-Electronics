# Proteus Simulation Guide for Ultrasonic Mapping Robot

## 🎯 How to Simulate in Proteus

### Required Components in Proteus:
```
1. ATmega32 (40-pin DIP)
2. Crystal Oscillator (16MHz)
3. HC-SR04 Ultrasonic Sensor
4. L298N Motor Driver
5. DC Motors (2x)
6. LCD 16x2
7. LEDs for status indication
8. Resistors (10kΩ, 330Ω)
9. Capacitors (22pF, 100µF, 10µF)
10. Power Supply (5V, 9V)
```

### Step-by-Step Proteus Setup:

#### 1. **Place Components:**
- ATmega32: Place from Microprocessor section
- HC-SR04: Search in library or create custom component
- L298N: Use H-Bridge model or create subcircuit
- LCD: Use LM016L (16x2 LCD model)

#### 2. **Connections as per circuit diagram:**
```
ATmega32 Pins:
PB0-PB3 → L298N (IN1-IN4)
PD4-PD5 → L298N (ENA, ENB) 
PD6     → HC-SR04 TRIG
PD7     → HC-SR04 ECHO
PC0-PC7 → LCD Data lines
PA0     → LCD RS
PA1     → LCD EN
```

#### 3. **Programming:**
- Right-click ATmega32
- Select "Edit Properties" 
- Set Program File to: `ultrasonic_mapping.hex`
- Set Processor Clock to: 16MHz

#### 4. **Simulation Settings:**
- Animation: Real Time
- Step Time: 1ms
- Debug: Enable if needed

### Expected Simulation Behavior:
1. **LCD Display**: Shows "Mapping Robot" on startup
2. **Motors**: Should show rotation based on PWM signals
3. **Ultrasonic**: Distance readings update on virtual scope
4. **LEDs**: Status indicators blink during operation
5. **Movement Pattern**: Robot follows mapping algorithm
