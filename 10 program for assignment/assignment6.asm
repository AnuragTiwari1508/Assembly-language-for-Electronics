; ====================================================================
; ASSIGNMENT 6: SERVO MOTOR CONTROL SYSTEM
; ====================================================================
; Description: Control servo motor position using potentiometer input
; Hardware: ATmega32 + Servo Motor + Potentiometer + PWM
; Difficulty: Intermediate-Advanced  
; Learning Objective: PWM for servo control, precise timing, motor control
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; Servo Motor (SG90 or similar):
;   Orange/Signal → PD5/OC1A (Pin 19)
;   Red/VCC       → 5V (External 5V supply recommended)
;   Brown/GND     → GND
;
; Potentiometer (10kΩ):
;   PA0/ADC0 (Pin 40) → Potentiometer wiper  
;   VCC → Potentiometer one end
;   GND → Potentiometer other end
;
; Power Supply:
;   ATmega32: 5V regulated supply
;   Servo: 5V/1A external supply (shared GND with ATmega32)
;
; ATmega32 Basic Setup:
;   VCC     → 5V
;   GND     → GND  
;   AVCC    → 5V (with 10μF capacitor)
;   AREF    → 5V (with 100nF capacitor)
;   RESET   → 10kΩ to VCC
;   XTAL1   → 8MHz Crystal + 22pF to GND
;   XTAL2   → 8MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 8000000        ; 8MHz Crystal

; Servo Control Constants
.equ SERVO_MIN = 1000       ; 1ms pulse (0 degrees)
.equ SERVO_CENTER = 1500    ; 1.5ms pulse (90 degrees)  
.equ SERVO_MAX = 2000       ; 2ms pulse (180 degrees)

; Register Definitions
.def temp = r16             ; Temporary register
.def temp2 = r17            ; Second temporary register
.def adc_low = r18          ; ADC result low byte
.def adc_high = r19         ; ADC result high byte
.def servo_pos_low = r20    ; Servo position low byte
.def servo_pos_high = r21   ; Servo position high byte

; ====================================================================
; RESET VECTOR
; ====================================================================
.org 0x0000
    rjmp MAIN

; ====================================================================
; MAIN PROGRAM
; ====================================================================
.org 0x0020
MAIN:
    ; Initialize Stack Pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    
    ; Initialize servo PWM
    rcall SERVO_INIT
    
    ; Initialize ADC for potentiometer
    rcall ADC_INIT
    
    ; Configure PD5 as output for servo signal
    sbi DDRD, 5
    
    ; Set servo to center position initially
    ldi servo_pos_low, low(SERVO_CENTER)
    ldi servo_pos_high, high(SERVO_CENTER)
    rcall UPDATE_SERVO_POSITION

; ====================================================================
; MAIN LOOP - READ POTENTIOMETER AND CONTROL SERVO
; ====================================================================
MAIN_LOOP:
    ; Read potentiometer value
    rcall ADC_READ
    
    ; Convert ADC value (0-1023) to servo pulse width (1000-2000 μs)
    rcall CONVERT_ADC_TO_SERVO
    
    ; Update servo position
    rcall UPDATE_SERVO_POSITION
    
    ; Small delay for stability
    rcall DELAY_20MS
    
    rjmp MAIN_LOOP

; ====================================================================
; SERVO PWM INITIALIZATION  
; ====================================================================
SERVO_INIT:
    ; Configure Timer1 for servo PWM (20ms period)
    ; Use CTC mode with TOP = ICR1
    ; PWM frequency = 8MHz / (64 * 2500) = 50Hz (20ms period)
    
    ; Set TOP value for 20ms period
    ldi temp, high(2500)        ; ICR1 = 2500 for 20ms at 64 prescaler
    out ICR1H, temp
    ldi temp, low(2500)
    out ICR1L, temp
    
    ; Configure Timer1 - Fast PWM mode, ICR1 as TOP
    ; WGM13:0 = 1110, COM1A1:0 = 10 (Clear on match, set at bottom)
    ldi temp, (1<<WGM11)|(1<<COM1A1)
    out TCCR1A, temp
    
    ; Set prescaler to 64
    ldi temp, (1<<WGM13)|(1<<WGM12)|(1<<CS11)|(1<<CS10)
    out TCCR1B, temp
    
    ret

; ====================================================================
; ADC INITIALIZATION
; ====================================================================
ADC_INIT:
    ; Configure ADC for potentiometer on ADC0
    ; REFS1:0 = 01 (AVCC reference)
    ; MUX4:0 = 00000 (ADC0)
    ldi temp, (1<<REFS0)
    out ADMUX, temp
    
    ; Enable ADC, prescaler 64
    ldi temp, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)
    out ADCSRA, temp
    
    ret

; ====================================================================
; ADC READING
; ====================================================================
ADC_READ:
    ; Start conversion
    sbi ADCSRA, ADSC
    
    ; Wait for completion
ADC_WAIT:
    sbic ADCSRA, ADSC
    rjmp ADC_WAIT
    
    ; Read result
    in adc_low, ADCL
    in adc_high, ADCH
    
    ret

; ====================================================================
; ADC TO SERVO POSITION CONVERSION
; ====================================================================
CONVERT_ADC_TO_SERVO:
    ; Convert 10-bit ADC (0-1023) to servo range (1000-2000)
    ; Formula: servo_pos = 1000 + (ADC * 1000) / 1023
    ; Simplified: servo_pos = 1000 + ADC (approximately)
    
    ; Start with base value (1000)
    ldi servo_pos_low, low(SERVO_MIN)
    ldi servo_pos_high, high(SERVO_MIN)
    
    ; Add ADC value (limited to prevent overflow)
    ; Use only upper 8 bits of ADC for simplicity
    mov temp, adc_high
    lsr temp                    ; Divide by 2 to get ~500 range
    
    ; Add to servo position
    add servo_pos_low, temp
    ldi temp, 0
    adc servo_pos_high, temp
    
    ; Ensure position is within valid range (1000-2000)
    ; Check if position > 2000
    ldi temp, high(SERVO_MAX)
    cpi servo_pos_high, high(SERVO_MAX)
    brlo SERVO_POS_OK
    brne SERVO_LIMIT_MAX
    
    ldi temp, low(SERVO_MAX)  
    cpi servo_pos_low, low(SERVO_MAX)
    brlo SERVO_POS_OK
    
SERVO_LIMIT_MAX:
    ; Limit to maximum
    ldi servo_pos_low, low(SERVO_MAX)
    ldi servo_pos_high, high(SERVO_MAX)
    
SERVO_POS_OK:
    ret

; ====================================================================
; SERVO POSITION UPDATE
; ====================================================================
UPDATE_SERVO_POSITION:
    ; Convert microsecond value to timer counts
    ; Timer runs at 8MHz/64 = 125kHz (8μs per count)
    ; servo_pos (μs) / 8 = timer counts
    
    ; Divide by 8 (right shift by 3)
    mov temp, servo_pos_low
    mov temp2, servo_pos_high
    
    ; Shift right 3 positions to divide by 8
    lsr temp2
    ror temp
    lsr temp2  
    ror temp
    lsr temp2
    ror temp
    
    ; Update OCR1A with calculated value
    out OCR1AH, temp2
    out OCR1AL, temp
    
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_20MS:
    ; 20ms delay
    push r23
    push r24
    
    ldi r23, 80             ; Outer loop
DELAY_20MS_OUTER:
    ldi r24, 250            ; Inner loop  
DELAY_20MS_INNER:
    nop
    nop
    dec r24
    brne DELAY_20MS_INNER
    
    dec r23
    brne DELAY_20MS_OUTER
    
    pop r24
    pop r23
    ret

; ====================================================================
; END OF PROGRAM
; ====================================================================
