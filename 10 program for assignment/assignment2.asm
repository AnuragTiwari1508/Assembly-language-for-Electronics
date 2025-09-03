; ====================================================================
; ASSIGNMENT 2: TRAFFIC LIGHT CONTROLLER
; ====================================================================
; Description: 3-LED traffic light system with proper timing sequence
; Hardware: ATmega32 + 3 LEDs (Red, Yellow, Green) + Resistors
; Difficulty: Beginner-Intermediate  
; Learning Objective: Sequential control, timing, state machines
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; Traffic Light LEDs:
;   PB0 (Pin 1)  → 220Ω → RED LED → GND
;   PB1 (Pin 2)  → 220Ω → YELLOW LED → GND  
;   PB2 (Pin 3)  → 220Ω → GREEN LED → GND
;
; ATmega32 Basic Setup:
;   VCC     → 5V
;   GND     → GND
;   RESET   → 10kΩ to VCC + Reset Button to GND
;   XTAL1   → 8MHz Crystal + 22pF to GND
;   XTAL2   → 8MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 8000000    ; 8MHz Crystal

; LED Pin Definitions
.equ RED_LED = 0        ; PB0
.equ YELLOW_LED = 1     ; PB1
.equ GREEN_LED = 2      ; PB2

; Traffic Light States
.equ STATE_RED = 1
.equ STATE_RED_YELLOW = 2
.equ STATE_GREEN = 3
.equ STATE_YELLOW = 4

; Register Definitions
.def temp = r16         ; Temporary register
.def state = r17        ; Current traffic light state

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
    
    ; Configure PB0, PB1, PB2 as outputs
    ldi temp, 0b00000111    ; Set PB0-PB2 as outputs
    out DDRB, temp
    
    ; Initialize all LEDs OFF
    ldi temp, 0b00000000
    out PORTB, temp
    
    ; Initialize state to RED
    ldi state, STATE_RED

; ====================================================================
; MAIN TRAFFIC LIGHT SEQUENCE
; ====================================================================
MAIN_LOOP:
    cpi state, STATE_RED
    breq RED_STATE
    
    cpi state, STATE_RED_YELLOW  
    breq RED_YELLOW_STATE
    
    cpi state, STATE_GREEN
    breq GREEN_STATE
    
    cpi state, STATE_YELLOW
    breq YELLOW_STATE
    
    ; Default to RED state if invalid
    ldi state, STATE_RED
    rjmp MAIN_LOOP

; ====================================================================
; TRAFFIC LIGHT STATES
; ====================================================================
RED_STATE:
    ; Turn ON RED LED only
    ldi temp, (1<<RED_LED)
    out PORTB, temp
    
    ; Wait 5 seconds
    rcall DELAY_5S
    
    ; Next state: RED + YELLOW
    ldi state, STATE_RED_YELLOW
    rjmp MAIN_LOOP

RED_YELLOW_STATE:
    ; Turn ON RED and YELLOW LEDs
    ldi temp, (1<<RED_LED)|(1<<YELLOW_LED)
    out PORTB, temp
    
    ; Wait 2 seconds
    rcall DELAY_2S
    
    ; Next state: GREEN
    ldi state, STATE_GREEN
    rjmp MAIN_LOOP

GREEN_STATE:
    ; Turn ON GREEN LED only
    ldi temp, (1<<GREEN_LED)
    out PORTB, temp
    
    ; Wait 5 seconds
    rcall DELAY_5S
    
    ; Next state: YELLOW
    ldi state, STATE_YELLOW
    rjmp MAIN_LOOP

YELLOW_STATE:
    ; Turn ON YELLOW LED only
    ldi temp, (1<<YELLOW_LED)
    out PORTB, temp
    
    ; Wait 2 seconds
    rcall DELAY_2S
    
    ; Next state: RED
    ldi state, STATE_RED
    rjmp MAIN_LOOP

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_1S:
    ; 1 second delay
    push r18
    push r19
    push r20
    
    ldi r18, 16         ; Outer loop
DELAY_1S_OUTER:
    ldi r19, 250        ; Middle loop
DELAY_1S_MIDDLE:
    ldi r20, 250        ; Inner loop
DELAY_1S_INNER:
    nop
    nop
    nop
    nop
    dec r20
    brne DELAY_1S_INNER
    
    dec r19
    brne DELAY_1S_MIDDLE
    
    dec r18
    brne DELAY_1S_OUTER
    
    pop r20
    pop r19
    pop r18
    ret

DELAY_2S:
    rcall DELAY_1S
    rcall DELAY_1S
    ret

DELAY_5S:
    rcall DELAY_1S
    rcall DELAY_1S
    rcall DELAY_1S
    rcall DELAY_1S
    rcall DELAY_1S
    ret

; ====================================================================
; END OF PROGRAM
; ====================================================================
