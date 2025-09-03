;-----------------------------------------------------------------------------
; AVR Assembly Program to toggle all pins of Port C
; Target Microcontroller: ATmega32
; Clock Frequency: 8MHz
;-----------------------------------------------------------------------------

.include "m32def.inc" ; Include register definitions for the ATmega32

;-----------------------------------------------------------------------------
; Delay Subroutine (~10ms at 8MHz)
; Uses two nested loops to create the delay.
;-----------------------------------------------------------------------------
.equ DELAY_OUTER = 120    ; Outer loop count
.equ DELAY_INNER = 166    ; Inner loop count

DELAY_10MS:
    ; Use r16 and r17 as loop counters
    push r16
    push r17

    ldi r16, DELAY_OUTER
OUTER_LOOP:
    ldi r17, DELAY_INNER
INNER_LOOP:
    ; Each instruction takes 1 clock cycle (approximately)
    ; This creates a very precise delay
    dec r17
    brne INNER_LOOP
    dec r16
    brne OUTER_LOOP
    
    ; Restore registers and return
    pop r17
    pop r16
    ret

;-----------------------------------------------------------------------------
; Main Program
;-----------------------------------------------------------------------------
.org 0x0000
    rjmp START ; Jump to the main program entry point

; The following directive is crucial to avoid memory conflicts.
; It places the main code section at a new origin (address 0x0020),
; leaving space for the interrupt vector table.
.org 0x0020
START:
    ; Initialize Stack Pointer
    ; The stack must be set up for the 'ret' instruction in subroutines to work
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; Set all pins of Port C as outputs
    ; This is the equivalent of DDRC = 0xFF;
    ldi r16, 0xFF
    out DDRC, r16

MAIN_LOOP:
    ; Toggle Port C with a pattern (10101010)
    ; This is the equivalent of PORTC = 0xAA;
    ldi r16, 0xAA
    out PORTC, r16

    ; Call the 10ms delay subroutine
    rcall DELAY_10MS

    ; Toggle Port C with the inverse pattern (01010101)
    ; This is the equivalent of PORTC = 0x55;
    ldi r16, 0x55
    out PORTC, r16

    ; Call the 10ms delay subroutine
    rcall DELAY_10MS

    ; Jump back to the beginning of the main loop to repeat
    rjmp MAIN_LOOP
