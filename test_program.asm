; ====================================================================
; SIMPLE TEST PROGRAM - LED BLINK AND MOTOR TEST
; ====================================================================
; This is a simplified version to test basic functionality
; You can verify this works by observing LED patterns and motor movements
; ====================================================================

.include "m32def.inc"

; ====================================================================
; CONSTANTS
; ====================================================================
.equ F_CPU = 16000000           ; 16MHz crystal

; ====================================================================
; REGISTER DEFINITIONS  
; ====================================================================
.def temp = r16                 ; Temporary register
.def counter = r17              ; Counter for delays

; ====================================================================
; RESET VECTOR
; ====================================================================
.org 0x0000
    rjmp MAIN                   ; Jump to main program

; ====================================================================
; MAIN PROGRAM
; ====================================================================
.org 0x0020

MAIN:
    ; Initialize stack pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    
    ; Initialize ports
    rcall INIT_PORTS
    
    ; Display startup pattern
    rcall STARTUP_SEQUENCE
    
    ; Main test loop
MAIN_LOOP:
    ; Test 1: LED Blink Pattern (shows program is running)
    rcall LED_PATTERN_TEST
    
    ; Test 2: Motor Direction Test (shows motor control works)
    rcall MOTOR_DIRECTION_TEST
    
    ; Test 3: PWM Speed Test (shows PWM generation works)
    rcall PWM_SPEED_TEST
    
    ; Test 4: Ultrasonic Trigger Test (shows sensor interface works)
    rcall ULTRASONIC_TEST
    
    ; Repeat the tests
    rjmp MAIN_LOOP

; ====================================================================
; INITIALIZATION ROUTINES
; ====================================================================

INIT_PORTS:
    ; Configure LED pins (PORTA) as outputs
    ldi temp, 0xFF
    out DDRA, temp              ; All PORTA pins as output
    
    ; Configure motor control pins (PORTB) as outputs  
    ldi temp, 0xFF
    out DDRB, temp              ; All PORTB pins as output
    
    ; Configure PWM pins as outputs
    sbi DDRD, 4                 ; PD4 (OC1B) - Motor1 PWM
    sbi DDRD, 5                 ; PD5 (OC1A) - Motor2 PWM
    
    ; Configure ultrasonic pins
    sbi DDRD, 6                 ; PD6 - Trigger (output)
    cbi DDRD, 7                 ; PD7 - Echo (input)
    
    ; Initialize all outputs to known state
    clr temp
    out PORTA, temp
    out PORTB, temp
    out PORTD, temp
    
    ret

STARTUP_SEQUENCE:
    ; Visual indication that program started
    ; Light up LEDs in sequence
    ldi temp, 0x01
    
STARTUP_LOOP:
    out PORTA, temp             ; Light current LED
    rcall DELAY_200MS           ; Wait 200ms
    lsl temp                    ; Shift to next LED
    cpi temp, 0x00              ; Check if we've cycled through all
    brne STARTUP_LOOP
    
    ; All LEDs on briefly
    ldi temp, 0xFF
    out PORTA, temp
    rcall DELAY_500MS
    
    ; All LEDs off
    clr temp
    out PORTA, temp
    rcall DELAY_200MS
    
    ret

; ====================================================================
; TEST ROUTINES
; ====================================================================

LED_PATTERN_TEST:
    ; Test 1: Alternating pattern to show program execution
    ldi temp, 0xAA              ; Pattern: 10101010
    out PORTA, temp
    rcall DELAY_500MS
    
    ldi temp, 0x55              ; Pattern: 01010101  
    out PORTA, temp
    rcall DELAY_500MS
    
    clr temp                    ; All off
    out PORTA, temp
    rcall DELAY_200MS
    
    ret

MOTOR_DIRECTION_TEST:
    ; Test 2: Motor direction control
    ; This will show different patterns on PORTB indicating motor directions
    
    ; Forward direction
    ldi temp, 0x0A              ; Pattern: 00001010 (Motor1 & Motor2 forward)
    out PORTB, temp
    rcall DELAY_1000MS
    
    ; Backward direction  
    ldi temp, 0x05              ; Pattern: 00000101 (Motor1 & Motor2 backward)
    out PORTB, temp
    rcall DELAY_1000MS
    
    ; Turn left
    ldi temp, 0x09              ; Pattern: 00001001 (Motor1 back, Motor2 forward)
    out PORTB, temp
    rcall DELAY_1000MS
    
    ; Turn right
    ldi temp, 0x06              ; Pattern: 00000110 (Motor1 forward, Motor2 back)
    out PORTB, temp
    rcall DELAY_1000MS
    
    ; Stop motors
    clr temp
    out PORTB, temp
    rcall DELAY_500MS
    
    ret

PWM_SPEED_TEST:
    ; Test 3: PWM generation test
    ; Initialize Timer1 for PWM
    
    ; Fast PWM mode
    ldi temp, (1<<WGM11)|(1<<WGM10)|(1<<COM1A1)|(1<<COM1B1)
    out TCCR1A, temp
    
    ldi temp, (1<<WGM12)|(1<<CS11)  ; Prescaler 8
    out TCCR1B, temp
    
    ; Test different PWM values
    ; 25% duty cycle
    ldi temp, 64
    out OCR1AH, 0
    out OCR1AL, temp
    out OCR1BH, 0
    out OCR1BL, temp
    rcall DELAY_1000MS
    
    ; 50% duty cycle
    ldi temp, 128
    out OCR1AL, temp
    out OCR1BL, temp
    rcall DELAY_1000MS
    
    ; 75% duty cycle
    ldi temp, 192
    out OCR1AL, temp
    out OCR1BL, temp
    rcall DELAY_1000MS
    
    ; 100% duty cycle
    ldi temp, 255
    out OCR1AL, temp
    out OCR1BL, temp
    rcall DELAY_1000MS
    
    ; Turn off PWM
    clr temp
    out TCCR1A, temp
    out OCR1AL, temp
    out OCR1BL, temp
    
    ret

ULTRASONIC_TEST:
    ; Test 4: Ultrasonic sensor trigger test
    ; Generate trigger pulses and show on LED
    
    ldi counter, 5              ; Send 5 trigger pulses
    
ULTRASONIC_LOOP:
    ; Trigger pulse (10us high)
    sbi PORTD, 6                ; Trigger high
    rcall DELAY_10US            ; Wait 10 microseconds
    cbi PORTD, 6                ; Trigger low
    
    ; Visual indication on LED
    ldi temp, 0x80              ; Light up LED7 to show trigger
    out PORTA, temp
    rcall DELAY_100MS
    
    clr temp
    out PORTA, temp
    rcall DELAY_100MS
    
    dec counter
    brne ULTRASONIC_LOOP
    
    ret

; ====================================================================
; DELAY ROUTINES (Calibrated for 16MHz)
; ====================================================================

DELAY_10US:
    ; ~10 microsecond delay
    ldi temp, 53
DELAY_10US_LOOP:
    dec temp
    brne DELAY_10US_LOOP
    ret

DELAY_100MS:
    ; ~100 millisecond delay
    ldi temp, 100
DELAY_100MS_LOOP:
    rcall DELAY_1MS
    dec temp
    brne DELAY_100MS_LOOP
    ret

DELAY_200MS:
    ; ~200 millisecond delay  
    ldi temp, 200
DELAY_200MS_LOOP:
    rcall DELAY_1MS
    dec temp
    brne DELAY_200MS_LOOP
    ret

DELAY_500MS:
    ; ~500 millisecond delay
    ldi temp, 250
DELAY_500MS_LOOP:
    rcall DELAY_2MS
    dec temp
    brne DELAY_500MS_LOOP
    ret

DELAY_1000MS:
    ; ~1 second delay
    ldi temp, 250
DELAY_1000MS_LOOP:
    rcall DELAY_4MS
    dec temp
    brne DELAY_1000MS_LOOP
    ret

DELAY_1MS:
    ; ~1 millisecond delay
    push r18
    ldi r18, 200
DELAY_1MS_OUTER:
    ldi temp, 20
DELAY_1MS_INNER:
    dec temp
    brne DELAY_1MS_INNER
    dec r18
    brne DELAY_1MS_OUTER
    pop r18
    ret

DELAY_2MS:
    rcall DELAY_1MS
    rcall DELAY_1MS
    ret

DELAY_4MS:
    rcall DELAY_2MS
    rcall DELAY_2MS
    ret

; ====================================================================
; END OF PROGRAM
; ====================================================================
