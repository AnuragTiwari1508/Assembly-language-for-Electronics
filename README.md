# Ultrasonic Sensor Mapping Robot - ATmega32

This project implements a comprehensive mapping robot using an ATmega32 microcontroller that creates maps using an ultrasonic sensor while autonomously navigating.

## 🤖 Project Overview

The robot performs the following functions:
- **Autonomous Navigation**: Moves around using differential drive motors
- **Distance Measurement**: Uses HC-SR04 ultrasonic sensor for obstacle detection
- **Map Creation**: Creates a 2D map of the environment as it explores
- **Obstacle Avoidance**: Implements intelligent path planning and obstacle avoidance
- **LCD Display**: Shows current status and position information

## 🔧 Hardware Requirements

### Core Components
- **ATmega32 Microcontroller** (16MHz crystal oscillator)
- **HC-SR04 Ultrasonic Sensor** (distance measurement)
- **L298N Motor Driver** (dual H-bridge for motor control)
- **2x DC Geared Motors** (for differential drive)
- **16x2 LCD Display** (status display)
- **Robot Chassis** (custom or commercial)

### Optional Components
- **SG90 Servo Motor** (for sensor rotation - 360° scanning)
- **Buzzer** (audio feedback)
- **LEDs** (status indicators)
- **Power Supply** (7.4V Li-Po or 9V battery with voltage regulator)

### Power Management
- **7805 Voltage Regulator** (5V supply for microcontroller and sensors)
- **Capacitors** (100µF, 10µF for power filtering)

## 📟 Pin Configuration

### ATmega32 Pin Assignments

| Pin | Function | Component | Description |
|-----|----------|-----------|-------------|
| **PB0** | Motor1_IN1 | L298N | Motor 1 Direction Control |
| **PB1** | Motor1_IN2 | L298N | Motor 1 Direction Control |
| **PB2** | Motor2_IN3 | L298N | Motor 2 Direction Control |
| **PB3** | Motor2_IN4 | L298N | Motor 2 Direction Control |
| **PD4** | Motor1_ENA | L298N | Motor 1 PWM Speed Control |
| **PD5** | Motor2_ENB | L298N | Motor 2 PWM Speed Control |
| **PD6** | TRIG_PIN | HC-SR04 | Ultrasonic Trigger |
| **PD7** | ECHO_PIN | HC-SR04 | Ultrasonic Echo (INT2) |
| **PC0-PC7** | LCD_DATA | 16x2 LCD | Data Bus |
| **PA0** | LCD_RS | 16x2 LCD | Register Select |
| **PA1** | LCD_EN | 16x2 LCD | Enable Signal |
| **PD3** | SERVO_PIN | SG90 | Servo Control (Optional) |

### Circuit Connections

#### Motor Driver (L298N)
```
L298N    ATmega32    Motors
IN1  →   PB0        Motor1 +
IN2  →   PB1        Motor1 -
IN3  →   PB2        Motor2 +
IN4  →   PB3        Motor2 -
ENA  →   PD4        (PWM)
ENB  →   PD5        (PWM)
VCC  →   5V
GND  →   GND
```

#### Ultrasonic Sensor (HC-SR04)
```
HC-SR04  ATmega32
VCC   →  5V
GND   →  GND
TRIG  →  PD6
ECHO  →  PD7
```

#### LCD Display (16x2)
```
LCD     ATmega32
VCC  →  5V
GND  →  GND
RS   →  PA0
EN   →  PA1
D4   →  PC4
D5   →  PC5
D6   →  PC6
D7   →  PC7
```

## 💻 Software Architecture

### Main Files
- **`ultrasonic_mapping.asm`** - Main program with core functionality
- **`mapping_definitions.inc`** - Constants, macros, and hardware definitions
- **`advanced_mapping.asm`** - Advanced mapping algorithms and path planning

### Key Features Implemented

#### 1. Sensor Management
- **Distance Measurement**: Accurate ultrasonic ranging
- **Sensor Scanning**: 360° environment scanning
- **Data Filtering**: Noise reduction and validation

#### 2. Motor Control
- **PWM Speed Control**: Variable speed control for both motors
- **Direction Control**: Forward, backward, left, right movements
- **Precise Timing**: Accurate movement durations

#### 3. Mapping Algorithm
- **Grid-Based Mapping**: 16x16 grid representation
- **Frontier Exploration**: Intelligent exploration of unknown areas
- **Obstacle Detection**: Real-time obstacle mapping
- **Path Planning**: A* inspired pathfinding

#### 4. Navigation System
- **Position Tracking**: Dead reckoning position estimation
- **Obstacle Avoidance**: Dynamic obstacle avoidance
- **Wall Following**: Wall-following behavior when needed

## 🚀 Getting Started

### Prerequisites
- **AVR Toolchain** (avr-gcc, avr-as, avrdude)
- **USB ASP Programmer** or similar AVR programmer
- **AVR Studio** or command-line tools

### Building the Project

1. **Clone or download** the project files
2. **Navigate** to the project directory
3. **Build** using make:
   ```bash
   make all
   ```
4. **Upload** to microcontroller:
   ```bash
   make upload
   ```

### Fuse Settings
Set fuses for 16MHz external crystal:
```bash
make setfuses
```

### Compilation Commands (Alternative)
```bash
# Assemble
avr-as -mmcu=atmega32 -o ultrasonic_mapping.elf ultrasonic_mapping.asm

# Convert to HEX
avr-objcopy -O ihex ultrasonic_mapping.elf ultrasonic_mapping.hex

# Upload
avrdude -p atmega32 -c usbasp -U flash:w:ultrasonic_mapping.hex:i
```

## 🎛️ Operation

### Startup Sequence
1. **Initialization**: All hardware components are initialized
2. **Calibration**: Initial sensor readings and motor tests
3. **Mapping Mode**: Robot begins autonomous exploration

### Mapping Process
1. **Scan Environment**: 360° ultrasonic scan
2. **Plan Movement**: Calculate next movement based on frontier exploration
3. **Execute Movement**: Move toward unexplored areas
4. **Update Map**: Record obstacles and visited areas
5. **Repeat**: Continue until exploration is complete

### LCD Display Information
- **Line 1**: Current position (X, Y) and direction
- **Line 2**: System status and distance readings

## 🔧 Customization

### Adjustable Parameters

#### In `mapping_definitions.inc`:
```assembly
.equ MOTOR_DEFAULT_SPEED = 180    ; Adjust robot speed
.equ MIN_SAFE_DISTANCE = 15       ; Obstacle detection threshold
.equ MAP_SIZE = 16                ; Map grid size
.equ GRID_SIZE_CM = 20            ; Real-world size per grid cell
```

#### Movement Timing:
```assembly
.equ FORWARD_TIME = 1000          ; Forward movement duration (ms)
.equ TURN_90_TIME = 600           ; 90-degree turn duration (ms)
```

### Adding New Features

#### Servo Scanning:
Add servo control for 360° sensor scanning:
```assembly
SERVO_SCAN:
    ; Control servo angle for better scanning coverage
    ; Implementation depends on servo library
```

#### UART Communication:
Add wireless communication for remote monitoring:
```assembly
INIT_UART:
    ; Initialize UART for data transmission
    ; Send map data to computer/mobile app
```

## 🐛 Troubleshooting

### Common Issues

1. **Robot moves erratically**
   - Check motor connections
   - Verify PWM frequency settings
   - Ensure adequate power supply

2. **Inaccurate distance readings**
   - Check HC-SR04 connections
   - Verify trigger pulse timing
   - Ensure 5V power supply

3. **LCD not displaying**
   - Verify LCD connections
   - Check contrast adjustment
   - Ensure proper initialization sequence

4. **Programming issues**
   - Verify fuse settings
   - Check programmer connection
   - Ensure correct MCU selection

### Debug Tips
- Use LED indicators for status debugging
- Monitor UART output if implemented  
- Test individual modules separately
- Verify power supply stability

## 📚 Algorithm Details

### Mapping Strategy
The robot uses a **frontier-based exploration** algorithm:
1. Identify frontier cells (unvisited cells adjacent to visited ones)
2. Select nearest frontier based on Manhattan distance
3. Plan path using simplified A* pathfinding
4. Execute movement with real-time obstacle avoidance

### Data Structures
- **Map Array**: 16x16 byte array where each byte represents:
  - Bit 0: Visited flag
  - Bit 1: Obstacle detected
  - Bit 2: Wall detected
  - Bit 3: Boundary marker

## 🔮 Future Enhancements

- **SLAM Implementation**: Simultaneous Localization and Mapping
- **Wireless Communication**: Real-time map transmission
- **Mobile App**: Remote control and monitoring
- **Multiple Sensor Fusion**: Add IMU, encoders, camera
- **Advanced Path Planning**: Implement full A* algorithm
- **Persistent Storage**: Save maps to EEPROM

## 📄 License

This project is open source. Feel free to modify and distribute according to your needs.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

---

**Happy Mapping! 🗺️🤖**
