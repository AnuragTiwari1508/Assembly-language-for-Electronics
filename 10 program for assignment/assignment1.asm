; ====================================================================
; ASSIGNMENT 1: LED BLINKER - BASIC GPIO CONTROL
; ====================================================================
; Description: Simple LED blinker program that toggles an LED connected to PB0
; Hardware: ATmega32 + LED + Resistor (220Ω)
; Difficulty: Beginner
; Learning Objective: Basic GPIO control, delay loops, and program structure
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; LED Circuit:
;   PB0 (Pin 1) → 220Ω Resistor → LED Anode
;   LED Cathode → GND
;
; ATmega32 Basic Setup:
;   VCC     → 5V
;   GND     → GND
;   RESET   → 10kΩ to VCC + Reset Button to GND
;   XTAL1   → 8MHz Crystal + 22pF to GND
;   XTAL2   → 8MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 8000000    ; 8MHz Crystal

; Register Definitions
.def temp = r16         ; Temporary register
.def delay_counter = r17 ; Delay counter

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
    
    ; Configure PB0 as output
    sbi DDRB, 0         ; Set PB0 as output
    cbi PORTB, 0        ; Initially turn off LED
    
; ====================================================================
; MAIN LOOP
; ====================================================================
MAIN_LOOP:
    ; Turn LED ON
    sbi PORTB, 0        ; Set PB0 HIGH
    rcall DELAY_500MS   ; Wait 500ms
    
    ; Turn LED OFF  
    cbi PORTB, 0        ; Set PB0 LOW
    rcall DELAY_500MS   ; Wait 500ms
    
    rjmp MAIN_LOOP      ; Repeat forever

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_500MS:
    ; Delay approximately 500ms at 8MHz
    push r18
    push r19
    push r20
    
    ldi r18, 8          ; Outer loop (8 iterations)
DELAY_500MS_OUTER:
    ldi r19, 250        ; Middle loop (250 iterations)
DELAY_500MS_MIDDLE:
    ldi r20, 250        ; Inner loop (250 iterations)
DELAY_500MS_INNER:
    nop                 ; No operation (1 cycle)
    nop                 ; No operation (1 cycle)
    dec r20             ; Decrement inner counter
    brne DELAY_500MS_INNER ; Branch if not zero
    
    dec r19             ; Decrement middle counter
    brne DELAY_500MS_MIDDLE ; Branch if not zero
    
    dec r18             ; Decrement outer counter
    brne DELAY_500MS_OUTER ; Branch if not zero
    
    pop r20
    pop r19
    pop r18
    ret

; ====================================================================
; END OF PROGRAM
; ====================================================================
