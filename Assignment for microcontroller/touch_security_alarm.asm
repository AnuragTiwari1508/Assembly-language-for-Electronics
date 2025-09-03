;===============================================================================
; Touch Sensor Based Security Alarm System  
; Created: September 3, 2025
;
; Hardware Requirements:
; - ATmega32 microcontroller
; - Touch sensor (connected to PORTD.2 - INT0)
; - LED (connected to PORTB.0)
; - Buzzer (connected to PORTB.1)
;===============================================================================

#include <avr/io.h>

.section .text
.global main

; Reset vector
.org 0x0000
    rjmp main           ; Jump to main function

; External Interrupt 0 vector (INT0)
.org 0x0002  
    rjmp ext_int0       ; Jump to interrupt handler

main:
    ; Initialize Stack Pointer
    ldi r16, hi8(RAMEND)
    sts SPH, r16         ; Use sts for extended I/O
    ldi r16, lo8(RAMEND)
    sts SPL, r16         ; Use sts for extended I/O

    ; Configure PORTB (LED and Buzzer outputs)
    ldi r16, 0x03        ; Set PB0 (LED) and PB1 (Buzzer) as outputs
    sts DDRB, r16        ; Use sts for extended I/O
    
    ; Configure PORTD (Touch sensor input)
    ldi r16, 0x00        ; Set PORTD.2 as input
    sts DDRD, r16        ; Use sts for extended I/O  
    ldi r16, 0x04        ; Enable pull-up on PD2 (INT0)
    sts PORTD, r16       ; Use sts for extended I/O

    ; Configure External Interrupt 0 (for ATmega32)
    ldi r16, 0x03        ; Configure INT0 for rising edge (ISC01|ISC00)
    sts MCUCR, r16       ; Use sts for extended I/O
    ldi r16, 0x40        ; Enable INT0
    sts GICR, r16        ; Use sts for extended I/O

    sei                  ; Enable global interrupts

main_loop:
    rjmp main_loop      ; Infinite loop

; External Interrupt 0 Handler
ext_int0:
    ; Touch detected - Activate alarm
    ldi r16, 0x01       ; Load bit pattern for PB0
    sts PORTB, r16      ; Turn on LED
    rcall alarm_sound   ; Generate alarm sound
    reti                ; Return from interrupt

alarm_sound:
    push r16            ; Save temp register
    ldi r16, 5          ; Number of beeps

beep_loop:
    ; Turn on buzzer (PB1)
    ldi r17, 0x03       ; LED + Buzzer on
    sts PORTB, r17
    rcall delay_routine ; Delay
    
    ; Turn off buzzer, keep LED on
    ldi r17, 0x01       ; LED on, Buzzer off  
    sts PORTB, r17
    rcall delay_routine ; Delay
    
    dec r16
    brne beep_loop
    
    pop r16             ; Restore temp register
    ret

delay_routine:          ; Delay subroutine
    push r18
    push r19
    
    ldi r18, 200        ; Outer loop counter
outer_loop:
    ldi r19, 200        ; Inner loop counter
inner_loop:
    nop                 ; No operation
    dec r19
    brne inner_loop
    dec r18
    brne outer_loop
    
    pop r19
    pop r18
    ret
