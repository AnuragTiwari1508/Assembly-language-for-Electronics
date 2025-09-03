; ====================================================================
; ASSIGNMENT 9: ULTRASONIC DISTANCE SENSOR WITH OBSTACLE DETECTION
; ====================================================================
; Description: HC-SR04 distance measurement with LCD display and LED warning system
; Hardware: ATmega32 + HC-SR04 + LCD + LEDs + Buzzer
; Difficulty: Advanced
; Learning Objective: Timer capture, distance calculation, multi-sensor integration
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; HC-SR04 Ultrasonic Sensor:
;   VCC     → 5V
;   GND     → GND
;   TRIG    → PD6 (Pin 20)
;   ECHO    → PD7/ICP1 (Pin 21) - Input Capture Pin
;
; 16x2 LCD Display:
;   RS      → PA0 (Pin 40)
;   EN      → PA1 (Pin 39)
;   D4-D7   → PC4-PC7 (Pins 18,19,22,23)
;
; Warning System:
;   GREEN LED   → PB0 (Pin 1) - Safe distance (>50cm)
;   YELLOW LED  → PB1 (Pin 2) - Caution (20-50cm)
;   RED LED     → PB2 (Pin 3) - Danger (<20cm)
;   BUZZER      → PB3 (Pin 4) - Alert sound
;
; ATmega32 Setup:
;   VCC     → 5V
;   GND     → GND
;   RESET   → 10kΩ to VCC
;   XTAL1   → 16MHz Crystal + 22pF to GND
;   XTAL2   → 16MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 16000000       ; 16MHz Crystal

; Distance Thresholds (in cm)
.equ DANGER_DISTANCE = 20   ; Red zone
.equ CAUTION_DISTANCE = 50  ; Yellow zone
.equ MAX_DISTANCE = 400     ; Maximum measurable distance

; LED/Buzzer Definitions
.equ LED_GREEN = 0          ; PB0
.equ LED_YELLOW = 1         ; PB1
.equ LED_RED = 2            ; PB2
.equ BUZZER = 3             ; PB3

; Register Definitions
.def temp = r16             ; Temporary register
.def temp2 = r17            ; Second temporary
.def distance_low = r18     ; Distance low byte
.def distance_high = r19    ; Distance high byte
.def capture_low = r20      ; Timer capture low byte
.def capture_high = r21     ; Timer capture high byte
.def measurement_ready = r22 ; Flag for measurement complete
.def warning_level = r23    ; Current warning level (0-3)
.def buzzer_counter = r24   ; Buzzer timing counter

; ====================================================================
; INTERRUPT VECTORS
; ====================================================================
.org 0x0000
    rjmp MAIN               ; Reset
.org 0x0010
    rjmp TIMER1_CAPT        ; Timer1 Input Capture
.org 0x0012
    rjmp TIMER1_OVF         ; Timer1 Overflow

; ====================================================================
; MAIN PROGRAM
; ====================================================================
.org 0x0040
MAIN:
    ; Initialize Stack Pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    
    ; Initialize hardware
    rcall INIT_PORTS
    rcall INIT_TIMER1
    rcall LCD_INIT
    
    ; Initialize variables
    clr measurement_ready
    clr warning_level
    clr buzzer_counter
    
    ; Display startup message
    rcall DISPLAY_STARTUP
    rcall DELAY_2S
    
    ; Enable global interrupts
    sei

; ====================================================================
; MAIN LOOP
; ====================================================================
MAIN_LOOP:
    ; Start ultrasonic measurement
    rcall TRIGGER_MEASUREMENT
    
    ; Wait for measurement to complete
    rcall WAIT_FOR_MEASUREMENT
    
    ; Calculate distance from captured time
    rcall CALCULATE_DISTANCE
    
    ; Determine warning level
    rcall DETERMINE_WARNING_LEVEL
    
    ; Update display
    rcall UPDATE_DISPLAY
    
    ; Update warning indicators
    rcall UPDATE_WARNING_SYSTEM
    
    ; Wait before next measurement
    rcall DELAY_100MS
    
    rjmp MAIN_LOOP

; ====================================================================
; HARDWARE INITIALIZATION
; ====================================================================
INIT_PORTS:
    ; Configure trigger pin as output
    sbi DDRD, 6             ; PD6 (TRIG) as output
    cbi PORTD, 6            ; Initialize LOW
    
    ; Configure echo pin as input (ICP1)
    cbi DDRD, 7             ; PD7 (ECHO/ICP1) as input
    
    ; Configure LCD pins
    sbi DDRA, 0             ; PA0 (RS) as output
    sbi DDRA, 1             ; PA1 (EN) as output
    ldi temp, 0xF0          ; PC4-PC7 as outputs
    out DDRC, temp
    
    ; Configure LED and buzzer pins
    ldi temp, 0x0F          ; PB0-PB3 as outputs
    out DDRB, temp
    
    ; Initialize all indicators OFF
    clr temp
    out PORTB, temp
    
    ret

INIT_TIMER1:
    ; Configure Timer1 for input capture
    ; Normal mode, prescaler 8 (2MHz timer frequency)
    clr temp
    out TCCR1A, temp
    
    ; Set prescaler to 8, enable noise canceler, rising edge
    ldi temp, (1<<ICNC1)|(1<<ICES1)|(1<<CS11)
    out TCCR1B, temp
    
    ; Enable input capture and overflow interrupts
    ldi temp, (1<<TICIE1)|(1<<TOIE1)
    out TIMSK, temp
    
    ret

; ====================================================================
; ULTRASONIC MEASUREMENT
; ====================================================================
TRIGGER_MEASUREMENT:
    ; Clear measurement ready flag
    clr measurement_ready
    
    ; Reset Timer1 counter
    clr temp
    out TCNT1H, temp
    out TCNT1L, temp
    
    ; Generate 10μs trigger pulse
    sbi PORTD, 6            ; TRIG HIGH
    rcall DELAY_10US        ; Wait 10μs
    cbi PORTD, 6            ; TRIG LOW
    
    ret

WAIT_FOR_MEASUREMENT:
    ; Wait until measurement is ready
WAIT_LOOP:
    tst measurement_ready
    breq WAIT_LOOP
    ret

CALCULATE_DISTANCE:
    ; Convert timer capture value to distance
    ; Timer runs at 2MHz (0.5μs per tick)
    ; Sound speed: 343 m/s = 58.3 μs/cm (round trip)
    ; Distance = (capture_time * 0.5μs) / 58.3μs/cm
    ; Simplified: Distance ≈ capture_time / 116
    
    ; Load captured time
    mov temp, capture_low
    mov temp2, capture_high
    
    ; Divide by 116 (approximately)
    ; Use successive division by powers of 2
    ; 116 ≈ 128, so divide by 128 (right shift by 7)
    
    ; Combine high and low bytes for 16-bit division
    lsr temp2               ; Divide high byte
    ror temp                ; Rotate into low byte
    lsr temp2
    ror temp
    lsr temp2
    ror temp
    lsr temp2
    ror temp
    lsr temp2
    ror temp
    lsr temp2
    ror temp
    lsr temp2
    ror temp                ; 7 shifts = divide by 128
    
    ; Store result
    mov distance_low, temp
    mov distance_high, temp2
    
    ; Limit to maximum reasonable distance
    cpi distance_low, low(MAX_DISTANCE)
    ldi temp, high(MAX_DISTANCE)
    cpc distance_high, temp
    brlo DISTANCE_OK
    
    ; Limit to max distance
    ldi distance_low, low(MAX_DISTANCE)
    ldi distance_high, high(MAX_DISTANCE)
    
DISTANCE_OK:
    ret

DETERMINE_WARNING_LEVEL:
    ; Determine warning level based on distance
    ; 0 = No warning (>50cm)
    ; 1 = Green LED (>50cm)  
    ; 2 = Yellow LED (20-50cm)
    ; 3 = Red LED + Buzzer (<20cm)
    
    ; Check for danger zone (<20cm)
    cpi distance_low, DANGER_DISTANCE
    ldi temp, 0
    cpc distance_high, temp
    brsh CHECK_CAUTION
    
    ; Danger zone
    ldi warning_level, 3
    ret
    
CHECK_CAUTION:
    ; Check for caution zone (20-50cm)
    cpi distance_low, CAUTION_DISTANCE
    ldi temp, 0
    cpc distance_high, temp
    brsh SAFE_ZONE
    
    ; Caution zone
    ldi warning_level, 2
    ret
    
SAFE_ZONE:
    ; Safe zone (>50cm)
    ldi warning_level, 1
    ret

; ====================================================================
; DISPLAY FUNCTIONS
; ====================================================================
UPDATE_DISPLAY:
    ; Clear display and show distance
    rcall LCD_CLEAR
    
    ; Display "Distance: "
    ldi ZH, high(DISTANCE_LABEL*2)
    ldi ZL, low(DISTANCE_LABEL*2)
    rcall LCD_PRINT_STRING
    
    ; Display distance value
    rcall DISPLAY_DISTANCE_VALUE
    
    ; Display "cm"
    ldi ZH, high(CM_UNIT*2)
    ldi ZL, low(CM_UNIT*2)
    rcall LCD_PRINT_STRING
    
    ; Display warning status on line 2
    rcall LCD_LINE2
    rcall DISPLAY_WARNING_STATUS
    
    ret

DISPLAY_DISTANCE_VALUE:
    ; Convert distance to decimal and display
    ; Handle up to 3 digits (0-399)
    
    mov temp, distance_low
    clr temp2               ; Hundreds counter
    
    ; Count hundreds
COUNT_HUNDREDS:
    cpi temp, 100
    brlo COUNT_TENS_START
    subi temp, 100
    inc temp2
    rjmp COUNT_HUNDREDS
    
COUNT_TENS_START:
    ; Display hundreds (if > 0)
    tst temp2
    breq SKIP_HUNDREDS
    
    subi temp2, -'0'        ; Convert to ASCII
    mov r0, temp2
    mov temp2, temp         ; Save tens+units
    mov temp, r0
    rcall LCD_SEND_DATA
    mov temp, temp2         ; Restore
    
SKIP_HUNDREDS:
    ; Count tens
    clr temp2
COUNT_TENS_LOOP:
    cpi temp, 10
    brlo DISPLAY_FINAL_DIGITS
    subi temp, 10
    inc temp2
    rjmp COUNT_TENS_LOOP
    
DISPLAY_FINAL_DIGITS:
    ; Display tens digit
    subi temp2, -'0'
    mov r0, temp2
    mov temp2, temp         ; Save units
    mov temp, r0
    rcall LCD_SEND_DATA
    
    ; Display units digit
    mov temp, temp2
    subi temp, -'0'
    rcall LCD_SEND_DATA
    
    ret

DISPLAY_WARNING_STATUS:
    ; Display warning message based on level
    cpi warning_level, 3
    breq DISPLAY_DANGER
    
    cpi warning_level, 2
    breq DISPLAY_CAUTION
    
    cpi warning_level, 1
    breq DISPLAY_SAFE
    
    ; No warning
    ldi ZH, high(NO_OBJECT_MSG*2)
    ldi ZL, low(NO_OBJECT_MSG*2)
    rcall LCD_PRINT_STRING
    ret
    
DISPLAY_DANGER:
    ldi ZH, high(DANGER_MSG*2)
    ldi ZL, low(DANGER_MSG*2)
    rcall LCD_PRINT_STRING
    ret
    
DISPLAY_CAUTION:
    ldi ZH, high(CAUTION_MSG*2)
    ldi ZL, low(CAUTION_MSG*2)
    rcall LCD_PRINT_STRING
    ret
    
DISPLAY_SAFE:
    ldi ZH, high(SAFE_MSG*2)
    ldi ZL, low(SAFE_MSG*2)
    rcall LCD_PRINT_STRING
    ret

DISPLAY_STARTUP:
    rcall LCD_CLEAR
    ldi ZH, high(STARTUP_MSG*2)
    ldi ZL, low(STARTUP_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(INIT_MSG*2)
    ldi ZL, low(INIT_MSG*2)
    rcall LCD_PRINT_STRING
    ret

; ====================================================================
; WARNING SYSTEM
; ====================================================================
UPDATE_WARNING_SYSTEM:
    ; Turn off all indicators first
    clr temp
    out PORTB, temp
    
    ; Set appropriate indicator based on warning level
    cpi warning_level, 3
    breq ACTIVATE_DANGER
    
    cpi warning_level, 2
    breq ACTIVATE_CAUTION
    
    cpi warning_level, 1
    breq ACTIVATE_SAFE
    
    ; No warning - all off
    ret
    
ACTIVATE_DANGER:
    ; Red LED + Buzzer
    ldi temp, (1<<LED_RED)
    out PORTB, temp
    rcall SOUND_DANGER_ALARM
    ret
    
ACTIVATE_CAUTION:
    ; Yellow LED
    ldi temp, (1<<LED_YELLOW)
    out PORTB, temp
    ret
    
ACTIVATE_SAFE:
    ; Green LED
    ldi temp, (1<<LED_GREEN)
    out PORTB, temp
    ret

SOUND_DANGER_ALARM:
    ; Generate warning beeps for danger zone
    inc buzzer_counter
    
    ; Beep pattern: 200ms on, 200ms off
    cpi buzzer_counter, 20  ; ~200ms at 10ms intervals
    brlo BUZZER_ON
    
    cpi buzzer_counter, 40  ; ~400ms total cycle
    brlo BUZZER_OFF
    
    ; Reset counter
    clr buzzer_counter
    
BUZZER_ON:
    sbi PORTB, BUZZER
    ret
    
BUZZER_OFF:
    cbi PORTB, BUZZER
    ret

; ====================================================================
; INTERRUPT SERVICE ROUTINES
; ====================================================================
TIMER1_CAPT:
    ; Input Capture ISR - Echo pulse received
    push temp
    in temp, SREG
    push temp
    
    ; Read captured value
    in capture_low, ICR1L
    in capture_high, ICR1H
    
    ; Set measurement ready flag
    ldi temp, 1
    mov measurement_ready, temp
    
    ; Restore registers
    pop temp
    out SREG, temp
    pop temp
    reti

TIMER1_OVF:
    ; Timer overflow - measurement timeout
    push temp
    in temp, SREG
    push temp
    
    ; Set maximum distance for timeout
    ldi capture_low, 0xFF
    ldi capture_high, 0xFF
    
    ; Set measurement ready
    ldi temp, 1
    mov measurement_ready, temp
    
    ; Restore registers
    pop temp
    out SREG, temp
    pop temp
    reti

; ====================================================================
; LCD FUNCTIONS (Simplified versions)
; ====================================================================
LCD_INIT:
    rcall DELAY_50MS
    
    ldi temp, 0x02          ; 4-bit mode
    rcall LCD_SEND_COMMAND
    ldi temp, 0x28          ; 4-bit, 2 lines
    rcall LCD_SEND_COMMAND
    ldi temp, 0x0C          ; Display on
    rcall LCD_SEND_COMMAND
    ldi temp, 0x06          ; Entry mode
    rcall LCD_SEND_COMMAND
    ldi temp, 0x01          ; Clear
    rcall LCD_SEND_COMMAND
    
    rcall DELAY_10MS
    ret

LCD_SEND_COMMAND:
    cbi PORTA, 0            ; RS = 0
    rcall LCD_WRITE_NIBBLES
    ret

LCD_SEND_DATA:
    sbi PORTA, 0            ; RS = 1
    rcall LCD_WRITE_NIBBLES
    cbi PORTA, 0
    ret

LCD_WRITE_NIBBLES:
    push temp2
    
    ; Upper nibble
    mov temp2, temp
    swap temp2
    andi temp2, 0x0F
    swap temp2              ; Move to upper nibble position
    
    in r0, PORTC
    andi r0, 0x0F           ; Preserve lower nibble
    or r0, temp2
    out PORTC, r0
    
    sbi PORTA, 1            ; EN high
    rcall DELAY_1MS
    cbi PORTA, 1            ; EN low
    
    ; Lower nibble
    andi temp, 0x0F
    swap temp               ; Move to upper nibble position
    
    in r0, PORTC
    andi r0, 0x0F
    or r0, temp
    out PORTC, r0
    
    sbi PORTA, 1            ; EN high
    rcall DELAY_1MS
    cbi PORTA, 1            ; EN low
    
    pop temp2
    ret

LCD_CLEAR:
    ldi temp, 0x01
    rcall LCD_SEND_COMMAND
    rcall DELAY_10MS
    ret

LCD_LINE2:
    ldi temp, 0xC0
    rcall LCD_SEND_COMMAND
    ret

LCD_PRINT_STRING:
LCD_STRING_LOOP:
    lpm temp, Z+
    tst temp
    breq LCD_STRING_END
    rcall LCD_SEND_DATA
    rjmp LCD_STRING_LOOP
LCD_STRING_END:
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_10US:
    ; 10 microsecond delay at 16MHz
    push r25
    ldi r25, 53             ; Calibrated for 16MHz
DELAY_10US_LOOP:
    dec r25
    brne DELAY_10US_LOOP
    pop r25
    ret

DELAY_1MS:
    push r26
    ldi r26, 100            ; Calibrated for 16MHz
DELAY_1MS_OUTER:
    push r27
    ldi r27, 40
DELAY_1MS_INNER:
    nop
    nop
    dec r27
    brne DELAY_1MS_INNER
    pop r27
    dec r26
    brne DELAY_1MS_OUTER
    pop r26
    ret

DELAY_10MS:
    push r28
    ldi r28, 10
DELAY_10MS_LOOP:
    rcall DELAY_1MS
    dec r28
    brne DELAY_10MS_LOOP
    pop r28
    ret

DELAY_50MS:
    push r29
    ldi r29, 5
DELAY_50MS_LOOP:
    rcall DELAY_10MS
    dec r29
    brne DELAY_50MS_LOOP
    pop r29
    ret

DELAY_100MS:
    rcall DELAY_50MS
    rcall DELAY_50MS
    ret

DELAY_2S:
    push r30
    ldi r30, 20
DELAY_2S_LOOP:
    rcall DELAY_100MS
    dec r30
    brne DELAY_2S_LOOP
    pop r30
    ret

; ====================================================================
; STRING CONSTANTS
; ====================================================================
STARTUP_MSG:
    .db "Ultrasonic Radar", 0

INIT_MSG:
    .db "Initializing...", 0

DISTANCE_LABEL:
    .db "Distance: ", 0

CM_UNIT:
    .db " cm", 0

SAFE_MSG:
    .db "SAFE ZONE", 0

CAUTION_MSG:
    .db "CAUTION!", 0

DANGER_MSG:
    .db "DANGER! STOP!", 0

NO_OBJECT_MSG:
    .db "No Object", 0

; ====================================================================
; END OF PROGRAM
; ====================================================================
