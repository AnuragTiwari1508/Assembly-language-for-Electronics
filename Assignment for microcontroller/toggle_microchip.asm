;===============================================================================
; AVR Assembly Program to Toggle All Pins of Port C - Microchip Studio Version
; Target Microcontroller: ATmega32
; Clock Frequency: 8MHz
; Created: September 3, 2025
;
; Hardware Requirements:
; - ATmega32 microcontroller
; - 8 LEDs connected to PORTC pins (PC0-PC7)
; - 220Ω resistors for current limiting
;===============================================================================

.include "m32def.inc"     ; Include ATmega32 definitions

; Register definitions
.def temp = r16           ; Temporary register
.def outer_count = r17    ; Outer loop counter
.def inner_count = r18    ; Inner loop counter

; Constants for delay calculation
.equ DELAY_OUTER = 120    ; Outer loop count (~10ms at 8MHz)
.equ DELAY_INNER = 166    ; Inner loop count

; Reset vector
.cseg
.org 0x0000
    rjmp START           ; Jump to main program

; Main program starts at 0x0020 to avoid interrupt vector conflicts
.org 0x0020
START:
    ; Initialize Stack Pointer
    ldi temp, HIGH(RAMEND)
    out SPH, temp
    ldi temp, LOW(RAMEND)
    out SPL, temp

    ; Configure PORTC as output (all pins)
    ldi temp, 0xFF       ; Set all pins as output
    out DDRC, temp
    
    ; Initialize PORTC to OFF state
    ldi temp, 0x00
    out PORTC, temp

MAIN_LOOP:
    ; Pattern 1: Alternate pins HIGH (10101010)
    ldi temp, 0xAA
    out PORTC, temp
    rcall DELAY_10MS     ; 10ms delay

    ; Pattern 2: Alternate pins LOW (01010101)  
    ldi temp, 0x55
    out PORTC, temp
    rcall DELAY_10MS     ; 10ms delay

    ; Repeat the pattern
    rjmp MAIN_LOOP

;===============================================================================
; Delay Subroutine - Approximately 10ms at 8MHz
; Uses nested loops for precise timing
; Formula: Delay = (OUTER * INNER * 4) / F_CPU
;===============================================================================
DELAY_10MS:
    push outer_count     ; Save registers
    push inner_count

    ldi outer_count, DELAY_OUTER
OUTER_LOOP:
    ldi inner_count, DELAY_INNER
INNER_LOOP:
    ; Each iteration takes ~4 clock cycles
    ; dec = 1 cycle, brne = 2 cycles (when taken), 1 cycle (when not taken)
    dec inner_count
    brne INNER_LOOP      ; Branch if not equal to zero
    
    dec outer_count
    brne OUTER_LOOP      ; Branch if not equal to zero

    pop inner_count      ; Restore registers
    pop outer_count
    ret                  ; Return to caller

;===============================================================================
; Alternative Patterns (Optional Usage)
;===============================================================================

; Pattern for all LEDs ON
ALL_ON:
    ldi temp, 0xFF
    out PORTC, temp
    ret

; Pattern for all LEDs OFF
ALL_OFF:
    ldi temp, 0x00
    out PORTC, temp
    ret

; Pattern for running light (shift left)
RUNNING_LIGHT:
    push temp
    ldi temp, 0x01       ; Start with one LED
SHIFT_LOOP:
    out PORTC, temp
    rcall DELAY_10MS
    lsl temp             ; Logical shift left
    brcc SHIFT_LOOP      ; Continue until carry set
    pop temp
    ret
