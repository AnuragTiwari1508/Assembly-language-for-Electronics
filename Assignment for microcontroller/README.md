# Touch Sensor Based Security Alarm System - Circuit Layout

## 3D Circuit Layout Description

```
                              ATmega328P
                            ┌────────────┐
                            │            │
        Touch Sensor    ──► │PD0     PB0│ ──► LED (Red)
        (Capacitive)        │           │
                           │        PB1│ ──► Buzzer
                     +5V ─► │VCC    GND│ ──► GND
                           └────────────┘

Components Required:
------------------
1. ATmega328P Microcontroller
2. Touch Sensor Module (TTP223B or similar)
3. LED (Red) with 220Ω resistor
4. Buzzer (5V)
5. Capacitors: 
   - 22pF (2x) for crystal
   - 100nF for decoupling
6. 16MHz Crystal
7. Power supply (5V)

Connections:
-----------
1. Touch Sensor:
   - VCC → 5V
   - GND → GND
   - OUT → PD0 (ATmega328P pin 2)

2. LED:
   - Anode → 220Ω resistor → PB0 (ATmega328P pin 14)
   - Cathode → GND

3. Buzzer:
   - Positive → PB1 (ATmega328P pin 15)
   - Negative → GND

4. Power:
   - VCC → 5V
   - GND → GND

Note: The touch sensor uses capacitive sensing technology to detect human touch. When someone touches the sensor pad, 
it triggers an interrupt on PD0, which then activates both the LED and buzzer in the programmed pattern.
```

For simulation in Proteus:
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
