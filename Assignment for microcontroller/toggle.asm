;===============================================================================
; AVR Assembly Program to Toggle All Pins of Port C - GCC AVR Version
; Target Microcontroller: ATmega32
; Clock Frequency: 8MHz
; Created: September 3, 2025
;===============================================================================

#include <avr/io.h>

.section .text
.global main

; Constants for delay calculation
#define DELAY_OUTER 120    ; Outer loop count (~10ms at 8MHz)
#define DELAY_INNER 166    ; Inner loop count

; Reset vector
.org 0x0000
    rjmp main           ; Jump to main program

; Main program starts at 0x0020 to avoid interrupt vector conflicts
.org 0x0020
main:
    ; Initialize Stack Pointer
    ldi r16, hi8(RAMEND)
    sts SPH, r16
    ldi r16, lo8(RAMEND)
    sts SPL, r16

    ; Configure PORTC as output (all pins)
    ldi r16, 0xFF       ; Set all pins as output
    sts DDRC, r16
    
    ; Initialize PORTC to OFF state
    ldi r16, 0x00
    sts PORTC, r16

main_loop:
    ; Pattern 1: Alternate pins HIGH (10101010)
    ldi r16, 0xAA
    sts PORTC, r16
    rcall delay_10ms    ; 10ms delay

    ; Pattern 2: Alternate pins LOW (01010101)
    ldi r16, 0x55
    sts PORTC, r16
    rcall delay_10ms    ; 10ms delay

    ; Repeat the pattern
    rjmp main_loop

;===============================================================================
; Delay Subroutine - Approximately 10ms at 8MHz
; Uses nested loops for precise timing
;===============================================================================
delay_10ms:
    push r17            ; Save registers
    push r18

    ldi r17, DELAY_OUTER
outer_loop:
    ldi r18, DELAY_INNER
inner_loop:
    ; Each iteration takes ~4 clock cycles
    dec r18
    brne inner_loop     ; Branch if not equal to zero
    
    dec r17
    brne outer_loop     ; Branch if not equal to zero

    pop r18             ; Restore registers
    pop r17
    ret                 ; Return to caller
