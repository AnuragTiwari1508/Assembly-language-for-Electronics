; ====================================================================
; ULTRASONIC MAPPING ROBOT - DEFINITIONS AND MACROS
; ====================================================================
; File: mapping_definitions.inc
; Description: Additional definitions and macros for the mapping robot
; ====================================================================

; ====================================================================
; HARDWARE PIN DEFINITIONS
; ====================================================================

; Motor Driver Pins (L298N)
.equ MOTOR1_IN1 = PB0          ; Motor 1 Direction Pin 1
.equ MOTOR1_IN2 = PB1          ; Motor 1 Direction Pin 2
.equ MOTOR2_IN3 = PB2          ; Motor 2 Direction Pin 1
.equ MOTOR2_IN4 = PB3          ; Motor 2 Direction Pin 2
.equ MOTOR1_ENA = PD4          ; Motor 1 Enable (PWM)
.equ MOTOR2_ENB = PD5          ; Motor 2 Enable (PWM)

; Ultrasonic Sensor Pins (HC-SR04)
.equ TRIG_PIN = PD6            ; Trigger Pin
.equ ECHO_PIN = PD7            ; Echo Pin (connected to INT2)

; LCD Display Pins (16x2 LCD)
.equ LCD_RS = PA0              ; Register Select
.equ LCD_EN = PA1              ; Enable Pin
; Data pins are PORTC (PC0-PC7)

; Optional Servo Pin for sensor rotation
.equ SERVO_PIN = PD3           ; Servo control pin (OC2)

; ====================================================================
; SYSTEM CONSTANTS
; ====================================================================

; Timing Constants
.equ SOUND_SPEED = 343         ; Speed of sound in m/s
.equ CM_PER_MICROSECOND = 58   ; Conversion factor for HC-SR04

; Motor Control Constants
.equ MOTOR_MAX_SPEED = 255     ; Maximum PWM value
.equ MOTOR_MIN_SPEED = 100     ; Minimum PWM value
.equ MOTOR_DEFAULT_SPEED = 180 ; Default operating speed

; Movement Timing (in milliseconds)
.equ FORWARD_TIME = 1000       ; Time to move forward
.equ TURN_90_TIME = 600        ; Time for 90-degree turn
.equ TURN_180_TIME = 1200      ; Time for 180-degree turn

; Sensor Constants
.equ SENSOR_TIMEOUT = 30000    ; Sensor timeout in microseconds
.equ MIN_SAFE_DISTANCE = 15    ; Minimum safe distance in cm
.equ WALL_THRESHOLD = 10       ; Distance to consider as wall

; Map Constants
.equ MAP_SIZE = 16             ; Map size (16x16 grid)
.equ MAP_CENTER = 8            ; Center position of map
.equ GRID_SIZE_CM = 20         ; Each grid represents 20cm

; ====================================================================
; STATUS FLAGS AND STATES
; ====================================================================

; Robot States
.equ STATE_IDLE = 0
.equ STATE_SCANNING = 1
.equ STATE_MOVING = 2
.equ STATE_TURNING = 3
.equ STATE_MAPPING = 4

; Direction Definitions
.equ DIR_NORTH = 0
.equ DIR_EAST = 1
.equ DIR_SOUTH = 2
.equ DIR_WEST = 3

; Map Cell Status Bits
.equ MAP_VISITED = 0           ; Bit 0: Cell has been visited
.equ MAP_OBSTACLE = 1          ; Bit 1: Obstacle detected
.equ MAP_WALL = 2              ; Bit 2: Wall detected
.equ MAP_BOUNDARY = 3          ; Bit 3: Map boundary

; ====================================================================
; USEFUL MACROS
; ====================================================================

; Macro to set motor direction
.macro SET_MOTOR_DIRECTION
    ; Parameters: @0 = direction (0=forward, 1=backward, 2=left, 3=right)
    .if @0 == 0                ; Forward
        sbi PORTB, MOTOR1_IN1
        cbi PORTB, MOTOR1_IN2
        sbi PORTB, MOTOR2_IN3
        cbi PORTB, MOTOR2_IN4
    .elif @0 == 1              ; Backward
        cbi PORTB, MOTOR1_IN1
        sbi PORTB, MOTOR1_IN2
        cbi PORTB, MOTOR2_IN3
        sbi PORTB, MOTOR2_IN4
    .elif @0 == 2              ; Turn Left
        cbi PORTB, MOTOR1_IN1
        sbi PORTB, MOTOR1_IN2
        sbi PORTB, MOTOR2_IN3
        cbi PORTB, MOTOR2_IN4
    .elif @0 == 3              ; Turn Right
        sbi PORTB, MOTOR1_IN1
        cbi PORTB, MOTOR1_IN2
        cbi PORTB, MOTOR2_IN3
        sbi PORTB, MOTOR2_IN4
    .endif
.endmacro

; Macro to set PWM speed for both motors
.macro SET_MOTOR_SPEED
    ; Parameter: @0 = speed value (0-255)
    ldi temp, @0
    out OCR1AL, temp           ; Motor 1 speed
    out OCR1BL, temp           ; Motor 2 speed
.endmacro

; Macro to enable/disable motors
.macro MOTOR_CONTROL
    ; Parameter: @0 = 1 to enable, 0 to disable
    .if @0 == 1
        ldi temp, (1<<COM1A1)|(1<<COM1B1)
        out TCCR1A, temp
    .else
        clr temp
        out TCCR1A, temp
        out PORTB, temp        ; Turn off all motor pins
    .endif
.endmacro

; Macro for LCD cursor positioning
.macro LCD_SET_CURSOR
    ; Parameters: @0 = row (0-1), @1 = column (0-15)
    ldi temp, 0x80
    .if @0 == 1
        ori temp, 0x40         ; Second row offset
    .endif
    ori temp, @1               ; Add column offset
    rcall LCD_COMMAND
.endmacro

; Macro to convert binary to BCD for display
.macro BIN_TO_BCD
    ; Convert binary number in register to BCD
    ; Input in @0, result in @0 (tens) and @1 (units)
    clr @1
BCD_LOOP\@:
    cpi @0, 10
    brlo BCD_DONE\@
    subi @0, 10
    inc @1
    rjmp BCD_LOOP\@
BCD_DONE\@:
.endmacro

; ====================================================================
; ADVANCED MAPPING STRUCTURES
; ====================================================================

; Map cell structure (bit definitions)
; Bit 0: Visited
; Bit 1: Obstacle
; Bit 2: Wall
; Bit 3: Boundary
; Bit 4-5: Confidence level (0-3)
; Bit 6-7: Reserved

; Navigation commands
.equ CMD_STOP = 0
.equ CMD_FORWARD = 1
.equ CMD_BACKWARD = 2
.equ CMD_TURN_LEFT = 3
.equ CMD_TURN_RIGHT = 4
.equ CMD_SCAN = 5

; Sensor scan angles (in degrees)
.equ SCAN_ANGLE_STEP = 30      ; 30-degree increments
.equ SCAN_ANGLES = 12          ; 360/30 = 12 positions

; ====================================================================
; ERROR CODES
; ====================================================================
.equ ERR_NO_ERROR = 0
.equ ERR_SENSOR_TIMEOUT = 1
.equ ERR_MOTOR_FAULT = 2
.equ ERR_MAP_OVERFLOW = 3
.equ ERR_INVALID_POSITION = 4

; ====================================================================
; COMMUNICATION CONSTANTS (if using UART)
; ====================================================================
.equ UART_BUFFER_SIZE = 32
.equ CMD_START_BYTE = 0xAA
.equ CMD_END_BYTE = 0x55
.equ DATA_START_BYTE = 0xBB
.equ DATA_END_BYTE = 0x66
