# ====================================================================
# PROTEUS CIRCUIT DIAGRAMS FOR 10 ASSEMBLY ASSIGNMENTS
# Compatible with Proteus 8.13 and later versions
# ====================================================================

## Assignment 1: LED Blinker Circuit

### Components List:
- ATmega32 (ATMEGA32-P)
- LED (LED-RED)
- Resistor 220Ω (RES-220R)
- Crystal 8MHz (CRYSTAL-8MHZ)
- Capacitors 22pF x2 (CAP-22PF)
- Resistor 10kΩ (RES-10K) for reset pull-up
- Power Supply +5V (POWER)
- Ground (GND)

### Connections:
```
ATmega32 Connections:
Pin 1 (PB0)  → 220Ω Resistor → LED Anode
LED Cathode  → GND
Pin 9 (XTAL1) → 8MHz Crystal → Pin 10 (XTAL2)
Pin 9 (XTAL1) → 22pF → GND
Pin 10 (XTAL2) → 22pF → GND
Pin 11 (VCC) → +5V
Pin 32 (GND) → GND
Pin 11 (VCC) → 10kΩ → Pin 9 (RESET)
```

### Proteus Import Data (Assignment 1):
```proteus
ISIS SCHEMATIC FILE
VERSION=8.13
SHEET=A4

COMPONENT ATMEGA32-P U1
POSITION=400,300
ROTATION=0

COMPONENT LED-RED D1
POSITION=600,200
ROTATION=0

COMPONENT RES-220R R1
POSITION=500,200
ROTATION=0

COMPONENT CRYSTAL-8MHZ X1
POSITION=300,400
ROTATION=90

COMPONENT CAP-22PF C1
POSITION=280,420
ROTATION=0

COMPONENT CAP-22PF C2
POSITION=320,420
ROTATION=0

COMPONENT RES-10K R2
POSITION=350,150
ROTATION=0

COMPONENT POWER V1
POSITION=200,100
VALUE=+5V

COMPONENT GROUND G1
POSITION=200,500

WIRE U1.1 R1.1
WIRE R1.2 D1.A
WIRE D1.K G1
WIRE U1.9 X1.1
WIRE U1.10 X1.2
WIRE U1.9 C1.1
WIRE C1.2 G1
WIRE U1.10 C2.1
WIRE C2.2 G1
WIRE U1.11 V1
WIRE U1.32 G1
WIRE U1.9 R2.1
WIRE R2.2 V1
```

## Assignment 2: Traffic Light Controller Circuit

### Components List:
- ATmega32 (ATMEGA32-P)
- LED Red (LED-RED)
- LED Yellow (LED-YELLOW)
- LED Green (LED-GREEN)
- Resistors 220Ω x3 (RES-220R)
- Crystal 8MHz (CRYSTAL-8MHZ)
- Capacitors 22pF x2 (CAP-22PF)
- Resistor 10kΩ (RES-10K)

### Proteus Import Data (Assignment 2):
```proteus
ISIS SCHEMATIC FILE
VERSION=8.13
SHEET=A4

COMPONENT ATMEGA32-P U1
POSITION=400,300

COMPONENT LED-RED D1
POSITION=600,150
ROTATION=0

COMPONENT LED-YELLOW D2
POSITION=600,200
ROTATION=0

COMPONENT LED-GREEN D3
POSITION=600,250
ROTATION=0

COMPONENT RES-220R R1
POSITION=500,150

COMPONENT RES-220R R2
POSITION=500,200

COMPONENT RES-220R R3
POSITION=500,250

WIRE U1.1 R1.1
WIRE R1.2 D1.A
WIRE D1.K G1
WIRE U1.2 R2.1
WIRE R2.2 D2.A
WIRE D2.K G1
WIRE U1.3 R3.1
WIRE R3.2 D3.A
WIRE D3.K G1
```

## Assignment 3: 7-Segment Display Counter

### Components List:
- ATmega32 (ATMEGA32-P)
- 7-Segment Display Common Cathode (7SEG-CC)
- Resistors 220Ω x8 (RES-220R)
- Push Button (BUTTON)
- Resistor 10kΩ pull-up (RES-10K)

### Proteus Import Data (Assignment 3):
```proteus
COMPONENT 7SEG-CC U2
POSITION=600,300

COMPONENT BUTTON SW1
POSITION=200,400

WIRE U1.14 R4.1 (PC0 to segment a)
WIRE R4.2 U2.14
WIRE U1.15 R5.1 (PC1 to segment b)
WIRE R5.2 U2.13
...continuing for all 7 segments
```

## Assignment 4: PWM LED Brightness Control

### Components List:
- ATmega32 (ATMEGA32-P)
- LED (LED-RED)
- Potentiometer 10kΩ (POT-10K)
- Resistor 220Ω (RES-220R)

### Proteus Import Data (Assignment 4):
```proteus
COMPONENT POT-10K RV1
POSITION=200,350

WIRE RV1.2 U1.40 (PA0 - ADC input)
WIRE RV1.1 V1 (+5V)
WIRE RV1.3 G1 (GND)
WIRE U1.19 R1.1 (PD5/OC1A - PWM output)
```

## Assignment 5: Temperature Monitor with LCD

### Components List:
- ATmega32 (ATMEGA32-P)
- LM35 Temperature Sensor (LM35)
- LCD 16x2 (LCD-16X2)
- Potentiometer 10kΩ for contrast (POT-10K)

### Proteus Import Data (Assignment 5):
```proteus
COMPONENT LM35 U3
POSITION=200,300

COMPONENT LCD-16X2 U4
POSITION=700,300

WIRE U3.OUT U1.39 (PA1 - ADC1)
WIRE U4.4 U1.14 (LCD RS to PD0)
WIRE U4.6 U1.15 (LCD EN to PD1)
WIRE U4.11 U1.16 (LCD D4 to PD4)
WIRE U4.12 U1.19 (LCD D5 to PD5)
WIRE U4.13 U1.20 (LCD D6 to PD6)
WIRE U4.14 U1.21 (LCD D7 to PD7)
```
