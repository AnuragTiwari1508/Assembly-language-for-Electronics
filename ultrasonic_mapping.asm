; ====================================================================
; ULTRASONIC SENSOR MAPPING ROBOT - ATmega32
; ====================================================================
; Description: This program controls a robot with ultrasonic sensor
;              to create a basic map by moving and measuring distances
;
; Hardware Configuration:
; - ATmega32 microcontroller @ 16MHz
; - HC-SR04 Ultrasonic Sensor
; - L298N Motor Driver
; - 2 DC Motors for movement
; - Servo motor for sensor rotation (optional)
; - LCD Display for debugging
;
; Pin Connections:
; PORTB.0 - Motor1 Direction (IN1)
; PORTB.1 - Motor1 Direction (IN2)  
; PORTB.2 - Motor2 Direction (IN3)
; PORTB.3 - Motor2 Direction (IN4)
; PORTD.4 - Motor1 PWM (ENA)
; PORTD.5 - Motor2 PWM (ENB)
; PORTD.6 - Ultrasonic Trigger
; PORTD.7 - Ultrasonic Echo (INT2)
; PORTC   - LCD Data pins
; PORTA.0 - LCD RS
; PORTA.1 - LCD Enable
; ====================================================================

.include "m32def.inc"

; ====================================================================
; CONSTANTS AND DEFINITIONS
; ====================================================================
.equ F_CPU = 16000000           ; 16MHz crystal
.equ BAUD = 9600               ; Baud rate for UART (if needed)
.equ UBRR_VAL = (F_CPU/(16*BAUD))-1

; Motor control constants
.equ MOTOR_SPEED = 150         ; PWM value for motor speed
.equ TURN_DELAY = 500          ; Delay for turning (ms)
.equ MOVE_DELAY = 1000         ; Delay for forward movement (ms)

; Distance thresholds
.equ MIN_DISTANCE = 20         ; Minimum safe distance (cm)
.equ MAX_DISTANCE = 200        ; Maximum reliable distance (cm)

; ====================================================================
; REGISTER DEFINITIONS
; ====================================================================
.def temp = r16                ; Temporary register
.def temp2 = r17               ; Second temporary register  
.def distance_low = r18        ; Distance measurement low byte
.def distance_high = r19       ; Distance measurement high byte
.def robot_x = r20             ; Robot X position
.def robot_y = r21             ; Robot Y position
.def robot_dir = r22           ; Robot direction (0=N, 1=E, 2=S, 3=W)
.def map_data = r23            ; Current map data byte
.def scan_angle = r24          ; Current scanning angle

; ====================================================================
; INTERRUPT VECTORS
; ====================================================================
.org 0x0000
    rjmp MAIN                  ; Reset vector
.org 0x0006
    rjmp ECHO_ISR              ; INT2 interrupt for echo pin

; ====================================================================
; SRAM VARIABLES
; ====================================================================
.dseg
.org SRAM_START
echo_start_time: .byte 2       ; Timer value when echo starts
echo_end_time: .byte 2         ; Timer value when echo ends
map_array: .byte 64            ; 8x8 map array (can be expanded)
current_pos_x: .byte 1         ; Current X position
current_pos_y: .byte 1         ; Current Y position

; ====================================================================
; CODE SECTION
; ====================================================================
.cseg
.org 0x0020

MAIN:
    ; Initialize stack pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    
    ; Initialize hardware
    rcall INIT_PORTS
    rcall INIT_TIMERS
    rcall INIT_INTERRUPTS
    rcall INIT_LCD
    rcall INIT_VARIABLES
    
    ; Display startup message
    ldi ZH, high(STARTUP_MSG*2)
    ldi ZL, low(STARTUP_MSG*2)
    rcall LCD_PRINT_STRING
    
    ; Enable global interrupts
    sei
    
    ; Main mapping loop
MAPPING_LOOP:
    ; Scan surroundings
    rcall SCAN_360
    
    ; Analyze scan data and decide movement
    rcall ANALYZE_SCAN
    
    ; Move based on analysis
    rcall EXECUTE_MOVEMENT
    
    ; Update position
    rcall UPDATE_POSITION
    
    ; Store map data
    rcall STORE_MAP_DATA
    
    ; Small delay before next iteration
    rcall DELAY_100MS
    
    rjmp MAPPING_LOOP

; ====================================================================
; HARDWARE INITIALIZATION ROUTINES
; ====================================================================

INIT_PORTS:
    ; Configure motor control pins as outputs
    ldi temp, 0xFF
    out DDRB, temp             ; PORTB as output for motor directions
    
    ; Configure PWM pins as outputs
    sbi DDRD, 4                ; PD4 (OC1B) - Motor1 PWM
    sbi DDRD, 5                ; PD5 (OC1A) - Motor2 PWM
    
    ; Configure ultrasonic pins
    sbi DDRD, 6                ; PD6 - Trigger (output)
    cbi DDRD, 7                ; PD7 - Echo (input)
    
    ; Configure LCD pins
    ldi temp, 0xFF
    out DDRC, temp             ; PORTC for LCD data
    sbi DDRA, 0                ; PA0 - LCD RS
    sbi DDRA, 1                ; PA1 - LCD Enable
    
    ; Initialize all outputs to low
    clr temp
    out PORTB, temp
    out PORTC, temp
    out PORTA, temp
    out PORTD, temp
    
    ret

INIT_TIMERS:
    ; Timer1 - Fast PWM mode for motor control
    ldi temp, (1<<WGM13)|(1<<WGM12)|(1<<WGM11)|(1<<WGM10)
    out TCCR1A, temp
    ldi temp, (1<<CS11)        ; Prescaler 8
    out TCCR1B, temp
    
    ; Set PWM frequency
    ldi temp, high(1999)       ; TOP value for ~1kHz PWM
    out ICR1H, temp
    ldi temp, low(1999)
    out ICR1L, temp
    
    ; Timer0 - For general delays
    ldi temp, (1<<CS02)|(1<<CS00)  ; Prescaler 1024
    out TCCR0, temp
    
    ret

INIT_INTERRUPTS:
    ; Configure INT2 for echo pin (falling edge)
    ldi temp, (1<<ISC2)
    out MCUCSR, temp
    
    ; Enable INT2 interrupt
    ldi temp, (1<<INT2)
    out GICR, temp
    
    ret

INIT_LCD:
    ; LCD initialization sequence
    rcall DELAY_20MS
    
    ; 8-bit mode, 2 lines, 5x8 font
    ldi temp, 0x38
    rcall LCD_COMMAND
    
    ; Display on, cursor off
    ldi temp, 0x0C
    rcall LCD_COMMAND
    
    ; Clear display
    ldi temp, 0x01
    rcall LCD_COMMAND
    
    ; Entry mode: increment cursor
    ldi temp, 0x06
    rcall LCD_COMMAND
    
    ret

INIT_VARIABLES:
    ; Initialize robot position to center of map
    ldi temp, 4
    mov robot_x, temp
    mov robot_y, temp
    
    ; Initialize direction (facing north)
    clr robot_dir
    
    ; Clear map array
    ldi ZH, high(map_array)
    ldi ZL, low(map_array)
    clr temp
    ldi temp2, 64
    
CLEAR_MAP_LOOP:
    st Z+, temp
    dec temp2
    brne CLEAR_MAP_LOOP
    
    ret

; ====================================================================
; ULTRASONIC SENSOR ROUTINES
; ====================================================================

MEASURE_DISTANCE:
    ; Send trigger pulse (10us)
    sbi PORTD, 6               ; Trigger high
    rcall DELAY_10US
    cbi PORTD, 6               ; Trigger low
    
    ; Wait for echo response (timeout after ~30ms)
    ldi temp2, 200             ; Timeout counter
    
WAIT_ECHO_START:
    sbis PIND, 7               ; Wait for echo to go high
    rjmp ECHO_NOT_HIGH
    rjmp ECHO_STARTED
    
ECHO_NOT_HIGH:
    dec temp2
    brne WAIT_ECHO_START
    ; Timeout - return max distance
    ldi distance_low, low(MAX_DISTANCE)
    ldi distance_high, high(MAX_DISTANCE)
    ret
    
ECHO_STARTED:
    ; Start timer measurement
    in temp, TCNT0
    sts echo_start_time, temp
    
WAIT_ECHO_END:
    sbic PIND, 7               ; Wait for echo to go low
    rjmp WAIT_ECHO_END
    
    ; Stop timer measurement
    in temp, TCNT0
    sts echo_end_time, temp
    
    ; Calculate distance
    rcall CALCULATE_DISTANCE
    
    ret

CALCULATE_DISTANCE:
    ; Load start and end times
    lds temp, echo_start_time
    lds temp2, echo_end_time
    
    ; Calculate time difference
    sub temp2, temp
    
    ; Convert to distance (simplified)
    ; Distance = (time * 343) / (2 * 1000000) * prescaler
    ; Simplified for 16MHz with prescaler 1024
    lsr temp2                  ; Divide by 2
    lsr temp2                  ; Divide by 4
    lsr temp2                  ; Divide by 8 (approximate)
    
    mov distance_low, temp2
    clr distance_high
    
    ret

SCAN_360:
    ; Perform 360-degree scan
    clr scan_angle
    
SCAN_LOOP:
    ; Measure distance at current angle
    rcall MEASURE_DISTANCE
    
    ; Store measurement in temporary array (simplified)
    ; In a real implementation, you'd store this data
    
    ; Rotate sensor (if servo is available)
    ; This would control a servo motor
    
    ; Increment angle
    ldi temp, 45               ; 45-degree increments
    add scan_angle, temp
    
    ; Check if full rotation completed
    cpi scan_angle, 360
    brlo SCAN_LOOP
    
    ret

; ====================================================================
; MOTOR CONTROL ROUTINES
; ====================================================================

MOVE_FORWARD:
    ; Set both motors to move forward
    ldi temp, (1<<PB0)|(1<<PB2)
    out PORTB, temp
    
    ; Set PWM values for both motors
    ldi temp, MOTOR_SPEED
    out OCR1AH, 0
    out OCR1AL, temp           ; Motor 1 speed
    out OCR1BH, 0
    out OCR1BL, temp           ; Motor 2 speed
    
    ; Enable PWM outputs
    ldi temp, (1<<COM1A1)|(1<<COM1B1)
    out TCCR1A, temp
    
    ; Move for specified time
    ldi temp2, low(MOVE_DELAY)
    ldi temp, high(MOVE_DELAY)
    rcall DELAY_MS
    
    ; Stop motors
    rcall STOP_MOTORS
    
    ret

MOVE_BACKWARD:
    ; Set both motors to move backward
    ldi temp, (1<<PB1)|(1<<PB3)
    out PORTB, temp
    
    ; Set PWM values
    ldi temp, MOTOR_SPEED
    out OCR1AL, temp
    out OCR1BL, temp
    
    ; Enable PWM
    ldi temp, (1<<COM1A1)|(1<<COM1B1)
    out TCCR1A, temp
    
    ; Move for specified time
    ldi temp2, low(MOVE_DELAY)
    ldi temp, high(MOVE_DELAY)
    rcall DELAY_MS
    
    rcall STOP_MOTORS
    ret

TURN_LEFT:
    ; Left motor backward, right motor forward
    ldi temp, (1<<PB1)|(1<<PB2)
    out PORTB, temp
    
    ; Set PWM values
    ldi temp, MOTOR_SPEED
    out OCR1AL, temp
    out OCR1BL, temp
    
    ; Enable PWM
    ldi temp, (1<<COM1A1)|(1<<COM1B1)
    out TCCR1A, temp
    
    ; Turn for specified time
    ldi temp2, low(TURN_DELAY)
    ldi temp, high(TURN_DELAY)
    rcall DELAY_MS
    
    rcall STOP_MOTORS
    
    ; Update direction
    dec robot_dir
    cpi robot_dir, 255         ; Check for underflow
    brne TURN_LEFT_END
    ldi robot_dir, 3           ; Wrap to 3 (West)
    
TURN_LEFT_END:
    ret

TURN_RIGHT:
    ; Left motor forward, right motor backward
    ldi temp, (1<<PB0)|(1<<PB3)
    out PORTB, temp
    
    ; Set PWM values
    ldi temp, MOTOR_SPEED
    out OCR1AL, temp
    out OCR1BL, temp
    
    ; Enable PWM
    ldi temp, (1<<COM1A1)|(1<<COM1B1)
    out TCCR1A, temp
    
    ; Turn for specified time
    ldi temp2, low(TURN_DELAY)
    ldi temp, high(TURN_DELAY)
    rcall DELAY_MS
    
    rcall STOP_MOTORS
    
    ; Update direction
    inc robot_dir
    cpi robot_dir, 4
    brne TURN_RIGHT_END
    clr robot_dir              ; Wrap to 0 (North)
    
TURN_RIGHT_END:
    ret

STOP_MOTORS:
    ; Disable PWM outputs
    clr temp
    out TCCR1A, temp
    
    ; Set all motor pins low
    clr temp
    out PORTB, temp
    out OCR1AL, temp
    out OCR1BL, temp
    
    ret

; ====================================================================
; NAVIGATION AND MAPPING ROUTINES
; ====================================================================

ANALYZE_SCAN:
    ; Simple obstacle avoidance algorithm
    ; If obstacle detected in front, turn
    ; If no obstacle, move forward
    
    ; Check front distance
    cpi distance_low, MIN_DISTANCE
    brsh NO_OBSTACLE_FRONT
    
    ; Obstacle detected - turn right
    rcall TURN_RIGHT
    ret
    
NO_OBSTACLE_FRONT:
    ; Path is clear - move forward
    rcall MOVE_FORWARD
    ret

EXECUTE_MOVEMENT:
    ; This routine would contain more sophisticated
    ; path planning based on the complete scan data
    
    ; For now, just execute the decision from ANALYZE_SCAN
    ret

UPDATE_POSITION:
    ; Update robot position based on direction and movement
    cpi robot_dir, 0           ; North
    breq UPDATE_NORTH
    cpi robot_dir, 1           ; East
    breq UPDATE_EAST
    cpi robot_dir, 2           ; South
    breq UPDATE_SOUTH
    ; West
    dec robot_x
    rjmp UPDATE_END
    
UPDATE_NORTH:
    inc robot_y
    rjmp UPDATE_END
    
UPDATE_EAST:
    inc robot_x
    rjmp UPDATE_END
    
UPDATE_SOUTH:
    dec robot_y
    
UPDATE_END:
    ; Bounds checking (0-7 for 8x8 grid)
    cpi robot_x, 8
    brlo X_OK
    ldi robot_x, 7
X_OK:
    cpi robot_y, 8
    brlo Y_OK
    ldi robot_y, 7
Y_OK:
    
    ret

STORE_MAP_DATA:
    ; Store current position and obstacle data in map array
    ; Calculate array index: index = y * 8 + x
    mov temp, robot_y
    lsl temp                   ; *2
    lsl temp                   ; *4
    lsl temp                   ; *8
    add temp, robot_x
    
    ; Load map array base address
    ldi ZH, high(map_array)
    ldi ZL, low(map_array)
    add ZL, temp
    adc ZH, r1                 ; Add carry if any
    
    ; Store position as visited (bit 0)
    ld temp, Z
    ori temp, 0x01
    st Z, temp
    
    ; Store obstacle information if distance is small
    cpi distance_low, MIN_DISTANCE
    brsh NO_OBSTACLE_STORE
    
    ; Mark obstacle (bit 1)
    ori temp, 0x02
    st Z, temp
    
NO_OBSTACLE_STORE:
    ret

; ====================================================================
; LCD DISPLAY ROUTINES
; ====================================================================

LCD_COMMAND:
    ; Send command to LCD
    out PORTC, temp            ; Put command on data bus
    cbi PORTA, 0               ; RS = 0 for command
    sbi PORTA, 1               ; Enable high
    rcall DELAY_1MS
    cbi PORTA, 1               ; Enable low
    rcall DELAY_1MS
    ret

LCD_DATA:
    ; Send data to LCD
    out PORTC, temp            ; Put data on data bus
    sbi PORTA, 0               ; RS = 1 for data
    sbi PORTA, 1               ; Enable high
    rcall DELAY_1MS
    cbi PORTA, 1               ; Enable low
    rcall DELAY_1MS
    ret

LCD_PRINT_STRING:
    ; Print string pointed to by Z register
LCD_PRINT_LOOP:
    lpm temp, Z+               ; Load character from program memory
    cpi temp, 0                ; Check for null terminator
    breq LCD_PRINT_END
    rcall LCD_DATA             ; Send character to LCD
    rjmp LCD_PRINT_LOOP
    
LCD_PRINT_END:
    ret

; ====================================================================
; INTERRUPT SERVICE ROUTINES
; ====================================================================

ECHO_ISR:
    ; Echo pin interrupt service routine
    ; This could be used for more precise timing
    ; Currently using polling method
    reti

; ====================================================================
; DELAY ROUTINES
; ====================================================================

DELAY_10US:
    ; Delay approximately 10 microseconds at 16MHz
    ldi temp, 53               ; Loop counter for ~10us
DELAY_10US_LOOP:
    dec temp
    brne DELAY_10US_LOOP
    ret

DELAY_1MS:
    ; Delay approximately 1 millisecond
    ldi temp, 200
DELAY_1MS_OUTER:
    ldi temp2, 20
DELAY_1MS_INNER:
    dec temp2
    brne DELAY_1MS_INNER
    dec temp
    brne DELAY_1MS_OUTER
    ret

DELAY_20MS:
    ; Delay approximately 20 milliseconds
    ldi temp, 20
DELAY_20MS_LOOP:
    rcall DELAY_1MS
    dec temp
    brne DELAY_20MS_LOOP
    ret

DELAY_100MS:
    ; Delay approximately 100 milliseconds
    ldi temp, 100
DELAY_100MS_LOOP:
    rcall DELAY_1MS
    dec temp
    brne DELAY_100MS_LOOP
    ret

DELAY_MS:
    ; Delay for temp:temp2 milliseconds
    ; temp = high byte, temp2 = low byte
DELAY_MS_OUTER:
    push temp2
    
DELAY_MS_MIDDLE:
    rcall DELAY_1MS
    dec temp2
    brne DELAY_MS_MIDDLE
    
    pop temp2
    dec temp
    brne DELAY_MS_OUTER
    ret

; ====================================================================
; CONSTANT DATA
; ====================================================================

STARTUP_MSG:
    .db "Mapping Robot", 0x00
    
MAP_MSG:
    .db "Mapping...", 0x00
    
POSITION_MSG:
    .db "Pos: ", 0x00

; ====================================================================
; END OF PROGRAM
; ====================================================================
