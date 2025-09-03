; ====================================================================
; ASSIGNMENT 3: PUSH BUTTON COUNTER WITH 7-SEGMENT DISPLAY
; ====================================================================
; Description: Count button presses and display on 7-segment display (0-9)
; Hardware: ATmega32 + 7-Segment Display + Push Button + Resistors
; Difficulty: Intermediate
; Learning Objective: Input handling, debouncing, BCD to 7-segment conversion
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; 7-Segment Display (Common Cathode):
;   a → PC0 (Pin 14) through 220Ω resistor
;   b → PC1 (Pin 15) through 220Ω resistor
;   c → PC2 (Pin 16) through 220Ω resistor
;   d → PC3 (Pin 17) through 220Ω resistor
;   e → PC4 (Pin 18) through 220Ω resistor
;   f → PC5 (Pin 19) through 220Ω resistor
;   g → PC6 (Pin 22) through 220Ω resistor
;   dp → PC7 (Pin 23) through 220Ω resistor
;   COM → GND
;
; Push Button:
;   PD0 (Pin 14) → Push Button → GND
;   PD0 → 10kΩ Pull-up resistor → VCC
;
; ATmega32 Basic Setup:
;   VCC     → 5V
;   GND     → GND
;   RESET   → 10kΩ to VCC
;   XTAL1   → 8MHz Crystal + 22pF to GND
;   XTAL2   → 8MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 8000000    ; 8MHz Crystal
.equ BUTTON_PIN = 0     ; PD0

; Register Definitions
.def temp = r16         ; Temporary register
.def counter = r17      ; Button press counter (0-9)
.def button_state = r18 ; Current button state
.def last_button = r19  ; Previous button state

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
    
    ; Configure PORTC as output (7-segment display)
    ldi temp, 0xFF
    out DDRC, temp
    
    ; Configure PD0 as input (button)
    cbi DDRD, BUTTON_PIN
    sbi PORTD, BUTTON_PIN   ; Enable pull-up resistor
    
    ; Initialize variables
    clr counter             ; Start count at 0
    ldi last_button, 1      ; Assume button not pressed initially
    
    ; Display initial count (0)
    rcall UPDATE_DISPLAY

; ====================================================================
; MAIN LOOP - BUTTON SCANNING AND DEBOUNCING
; ====================================================================
MAIN_LOOP:
    ; Read current button state (0 = pressed, 1 = not pressed)
    in button_state, PIND
    andi button_state, (1<<BUTTON_PIN)
    
    ; Check for button press (transition from 1 to 0)
    cpi last_button, 1      ; Was button not pressed?
    brne CHECK_RELEASE      ; No, check for release
    
    cpi button_state, 0     ; Is button pressed now?
    brne MAIN_LOOP          ; No, continue scanning
    
    ; Button was just pressed - debounce
    rcall DELAY_50MS        ; Debounce delay
    
    ; Read button state again
    in button_state, PIND
    andi button_state, (1<<BUTTON_PIN)
    cpi button_state, 0
    brne MAIN_LOOP          ; False press, ignore
    
    ; Valid button press detected
    inc counter             ; Increment counter
    cpi counter, 10         ; Check if counter > 9
    brlo UPDATE_COUNT       ; Branch if counter < 10
    
    clr counter             ; Reset counter to 0 if >= 10
    
UPDATE_COUNT:
    rcall UPDATE_DISPLAY    ; Update 7-segment display
    
CHECK_RELEASE:
    ; Wait for button release
    mov last_button, button_state
    rjmp MAIN_LOOP

; ====================================================================
; 7-SEGMENT DISPLAY UPDATE
; ====================================================================
UPDATE_DISPLAY:
    ; Convert counter value to 7-segment pattern
    ldi ZH, high(SEVEN_SEG_TABLE*2)
    ldi ZL, low(SEVEN_SEG_TABLE*2)
    
    ; Add counter offset to table address
    clr temp
    add ZL, counter
    adc ZH, temp
    
    ; Read 7-segment pattern from table
    lpm temp, Z
    
    ; Output to PORTC
    out PORTC, temp
    
    ret

; ====================================================================
; DELAY ROUTINES  
; ====================================================================
DELAY_50MS:
    ; 50ms delay for debouncing
    push r20
    push r21
    
    ldi r20, 200        ; Outer loop
DELAY_50MS_OUTER:
    ldi r21, 250        ; Inner loop
DELAY_50MS_INNER:
    nop
    nop
    nop
    dec r21
    brne DELAY_50MS_INNER
    
    dec r20
    brne DELAY_50MS_OUTER
    
    pop r21
    pop r20
    ret

; ====================================================================
; 7-SEGMENT LOOKUP TABLE
; ====================================================================
; Common Cathode 7-Segment Display Patterns
; Bit order: DP-G-F-E-D-C-B-A
SEVEN_SEG_TABLE:
    .db 0b00111111  ; 0
    .db 0b00000110  ; 1  
    .db 0b01011011  ; 2
    .db 0b01001111  ; 3
    .db 0b01100110  ; 4
    .db 0b01101101  ; 5
    .db 0b01111101  ; 6
    .db 0b00000111  ; 7
    .db 0b01111111  ; 8
    .db 0b01101111  ; 9

; ====================================================================
; END OF PROGRAM
; ====================================================================
