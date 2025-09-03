; ====================================================================
; ASSIGNMENT 4: PWM LED BRIGHTNESS CONTROL
; ====================================================================
; Description: Control LED brightness using PWM with potentiometer input
; Hardware: ATmega32 + LED + Potentiometer + ADC
; Difficulty: Intermediate
; Learning Objective: PWM generation, ADC conversion, analog input processing
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; PWM LED:
;   OC1A/PD5 (Pin 19) → 220Ω → LED Anode
;   LED Cathode → GND
;
; Potentiometer (10kΩ):
;   PA0/ADC0 (Pin 40) → Potentiometer wiper
;   VCC → Potentiometer one end
;   GND → Potentiometer other end
;
; ATmega32 Basic Setup:
;   VCC     → 5V
;   GND     → GND
;   AVCC    → 5V (with 10μF capacitor to GND)
;   AREF    → 5V (with 100nF capacitor to GND)
;   RESET   → 10kΩ to VCC
;   XTAL1   → 8MHz Crystal + 22pF to GND
;   XTAL2   → 8MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 8000000    ; 8MHz Crystal

; Register Definitions
.def temp = r16         ; Temporary register
.def adc_low = r17      ; ADC result low byte
.def adc_high = r18     ; ADC result high byte
.def pwm_value = r19    ; PWM duty cycle value

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
    
    ; Initialize PWM
    rcall INIT_PWM
    
    ; Initialize ADC
    rcall INIT_ADC
    
    ; Configure PD5 (OC1A) as output for PWM
    sbi DDRD, 5

; ====================================================================
; MAIN LOOP - READ ADC AND UPDATE PWM
; ====================================================================
MAIN_LOOP:
    ; Start ADC conversion
    rcall ADC_READ
    
    ; Convert 10-bit ADC value to 8-bit PWM value
    ; ADC range: 0-1023, PWM range: 0-255
    ; Divide ADC result by 4 (right shift by 2)
    mov temp, adc_high
    lsl temp                ; Shift left to get upper bits
    lsl temp
    mov pwm_value, temp
    
    mov temp, adc_low
    lsr temp                ; Shift right to get lower bits  
    lsr temp
    lsr temp
    lsr temp
    lsr temp
    lsr temp
    or pwm_value, temp      ; Combine upper and lower parts
    
    ; Update PWM duty cycle
    out OCR1AL, pwm_value
    clr temp
    out OCR1AH, temp
    
    ; Small delay before next reading
    rcall DELAY_10MS
    
    rjmp MAIN_LOOP

; ====================================================================
; PWM INITIALIZATION
; ====================================================================
INIT_PWM:
    ; Configure Timer1 for Fast PWM, 8-bit mode
    ; WGM13:0 = 0101 (Fast PWM, 8-bit, TOP = 0x00FF)
    ; COM1A1:0 = 10 (Clear OC1A on compare match, set at BOTTOM)
    ldi temp, (1<<WGM10)|(1<<COM1A1)
    out TCCR1A, temp
    
    ; Set prescaler to 64 (CS12:0 = 011)
    ; PWM frequency = 8MHz / (64 * 256) = ~488 Hz
    ldi temp, (1<<WGM12)|(1<<CS11)|(1<<CS10)
    out TCCR1B, temp
    
    ; Initialize duty cycle to 0 (LED OFF)
    clr temp
    out OCR1AH, temp
    out OCR1AL, temp
    
    ret

; ====================================================================
; ADC INITIALIZATION
; ====================================================================
INIT_ADC:
    ; Configure ADC for single conversion mode
    ; REFS1:0 = 01 (AVCC with external capacitor at AREF)
    ; ADLAR = 0 (right adjust result)
    ; MUX4:0 = 00000 (ADC0/PA0)
    ldi temp, (1<<REFS0)
    out ADMUX, temp
    
    ; Enable ADC, set prescaler to 64
    ; ADC clock = 8MHz / 64 = 125kHz (within 50-200kHz range)
    ldi temp, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)
    out ADCSRA, temp
    
    ret

; ====================================================================
; ADC READ FUNCTION
; ====================================================================
ADC_READ:
    ; Start ADC conversion
    sbi ADCSRA, ADSC
    
    ; Wait for conversion complete
ADC_WAIT:
    sbic ADCSRA, ADSC   ; Skip if ADC conversion complete
    rjmp ADC_WAIT
    
    ; Read ADC result (10-bit)
    in adc_low, ADCL    ; Read low byte first
    in adc_high, ADCH   ; Read high byte second
    
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_10MS:
    ; 10ms delay
    push r20
    push r21
    
    ldi r20, 40         ; Outer loop
DELAY_10MS_OUTER:
    ldi r21, 250        ; Inner loop
DELAY_10MS_INNER:
    nop
    nop
    dec r21
    brne DELAY_10MS_INNER
    
    dec r20
    brne DELAY_10MS_OUTER
    
    pop r21
    pop r20
    ret

; ====================================================================
; END OF PROGRAM
; ====================================================================
