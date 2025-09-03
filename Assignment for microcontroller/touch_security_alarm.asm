;===============================================================================
; Touch Sensor Based Security Alarm System
; Created: September 3, 2025
;
; Hardware Requirements:
; - ATmega32 microcontroller
; - Touch sensor (connected to PORTD.2 - INT0)
; - LED (connected to PORTA.0)
; - Buzzer (connected to PORTA.1)
;===============================================================================

.include "m32def.inc"     ; Include ATmega32 definitions

; Register definitions
.def temp = r16           ; Temporary register
.def touch_state = r17    ; Touch sensor state
.def delay_count1 = r18   ; Delay counter 1
.def delay_count2 = r19   ; Delay counter 2

; Reset and Interrupt vectors
.cseg
.org 0x0000              ; Reset vector
    rjmp RESET           ; Jump to reset handler
.org 0x0002              ; External Interrupt 0 vector
    rjmp EXT_INT0        ; Jump to external interrupt handler

RESET:
    ; Initialize Stack Pointer
    ldi temp, HIGH(RAMEND)
    out SPH, temp
    ldi temp, LOW(RAMEND)
    out SPL, temp

    ; Configure PORTB (LED and Buzzer outputs)
    ldi temp, (1<<PB0)|(1<<PB1)    ; Set PB0 (LED) and PB1 (Buzzer) as outputs
    out DDRB, temp
    
    ; Configure PORTD (Touch sensor input)
    ldi temp, 0x00       ; Set PORTD.0 as input
    out DDRD, temp
    ldi temp, (1<<PD0)   ; Enable pull-up on PD0
    out PORTD, temp

    ; Configure External Interrupt 0
    ldi temp, (1<<ISC01)|(1<<ISC00) ; Configure INT0 for rising edge
    sts EICRA, temp
    ldi temp, (1<<INT0)  ; Enable INT0
    out EIMSK, temp

    sei                  ; Enable global interrupts

MAIN_LOOP:
    rjmp MAIN_LOOP       ; Infinite loop

EXT_INT0:
    ; Touch detected - Activate alarm
    sbi PORTB, 0         ; Turn on LED
    rcall ALARM_SOUND    ; Generate alarm sound
    reti                 ; Return from interrupt

ALARM_SOUND:
    push temp            ; Save temp register
    ldi temp, 5          ; Number of beeps

BEEP_LOOP:
    sbi PORTB, 1         ; Turn on buzzer
    rcall DELAY          ; Delay
    cbi PORTB, 1         ; Turn off buzzer
    rcall DELAY          ; Delay
    dec temp
    brne BEEP_LOOP
    
    pop temp             ; Restore temp register
    ret

DELAY:                   ; Delay subroutine
    push delay_count1
    push delay_count2
    
    ldi delay_count1, 255
OUTER_LOOP:
    ldi delay_count2, 255
INNER_LOOP:
    dec delay_count2
    brne INNER_LOOP
    dec delay_count1
    brne OUTER_LOOP
    
    pop delay_count2
    pop delay_count1
    ret
