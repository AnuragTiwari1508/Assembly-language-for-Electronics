; ====================================================================
; ASSIGNMENT 7: DIGITAL CLOCK WITH ALARM
; ====================================================================
; Description: Real-time digital clock with settable alarm and buzzer
; Hardware: ATmega32 + 16x2 LCD + Buttons + Buzzer + Crystal
; Difficulty: Advanced
; Learning Objective: Timer interrupts, RTC, user interface, state machines
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; 16x2 LCD Display:
;   RS      → PD0 (Pin 14)
;   EN      → PD1 (Pin 15)  
;   D4      → PD4 (Pin 16)
;   D5      → PD5 (Pin 19)
;   D6      → PD6 (Pin 20)
;   D7      → PD7 (Pin 21)
;
; Control Buttons:
;   SET     → PB0 (Pin 1) with 10kΩ pull-up
;   UP      → PB1 (Pin 2) with 10kΩ pull-up
;   DOWN    → PB2 (Pin 3) with 10kΩ pull-up
;   ALARM   → PB3 (Pin 4) with 10kΩ pull-up
;
; Buzzer:
;   Positive → PC0 (Pin 14) through 220Ω resistor
;   Negative → GND
;
; ATmega32 Setup:
;   VCC     → 5V
;   GND     → GND
;   RESET   → 10kΩ to VCC
;   XTAL1   → 32.768kHz Crystal + 22pF to GND (for RTC)
;   XTAL2   → 32.768kHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 32768          ; 32.768kHz Crystal for RTC

; Clock States
.equ STATE_DISPLAY = 0      ; Normal time display
.equ STATE_SET_HOUR = 1     ; Setting hour
.equ STATE_SET_MIN = 2      ; Setting minute
.equ STATE_SET_ALARM_HOUR = 3
.equ STATE_SET_ALARM_MIN = 4

; Button Definitions
.equ BTN_SET = 0            ; PB0
.equ BTN_UP = 1             ; PB1  
.equ BTN_DOWN = 2           ; PB2
.equ BTN_ALARM = 3          ; PB3

; Register Definitions
.def temp = r16             ; Temporary register
.def temp2 = r17            ; Second temporary
.def clock_state = r18      ; Current state
.def hours = r19            ; Current hour (0-23)
.def minutes = r20          ; Current minute (0-59)
.def seconds = r21          ; Current second (0-59)
.def alarm_hour = r22       ; Alarm hour
.def alarm_min = r23        ; Alarm minute
.def alarm_enabled = r24    ; Alarm enable flag
.def button_flags = r25     ; Button press flags

; ====================================================================
; INTERRUPT VECTORS
; ====================================================================
.org 0x0000
    rjmp MAIN               ; Reset
.org 0x0014
    rjmp TIMER2_OVF         ; Timer2 overflow (1 second tick)

; ====================================================================
; MAIN PROGRAM
; ====================================================================
.org 0x0040
MAIN:
    ; Initialize Stack Pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    
    ; Initialize hardware
    rcall INIT_PORTS
    rcall INIT_TIMER
    rcall LCD_INIT
    
    ; Initialize clock variables
    ldi hours, 12           ; Start at 12:00:00
    ldi minutes, 0
    ldi seconds, 0
    ldi alarm_hour, 7       ; Default alarm 07:00
    ldi alarm_min, 0
    clr alarm_enabled
    ldi clock_state, STATE_DISPLAY
    
    ; Display startup message
    rcall DISPLAY_STARTUP
    rcall DELAY_2S
    
    ; Enable interrupts
    sei

; ====================================================================
; MAIN LOOP
; ====================================================================
MAIN_LOOP:
    ; Check button presses
    rcall CHECK_BUTTONS
    
    ; Handle current state
    cpi clock_state, STATE_DISPLAY
    breq HANDLE_DISPLAY
    
    cpi clock_state, STATE_SET_HOUR
    breq HANDLE_SET_HOUR
    
    cpi clock_state, STATE_SET_MIN
    breq HANDLE_SET_MIN
    
    cpi clock_state, STATE_SET_ALARM_HOUR
    breq HANDLE_SET_ALARM_HOUR
    
    cpi clock_state, STATE_SET_ALARM_MIN
    breq HANDLE_SET_ALARM_MIN
    
    rjmp MAIN_LOOP

; ====================================================================
; STATE HANDLERS
; ====================================================================
HANDLE_DISPLAY:
    ; Display current time
    rcall DISPLAY_TIME
    
    ; Check if SET button pressed
    sbrc button_flags, BTN_SET
    rjmp ENTER_SET_MODE
    
    ; Check if ALARM button pressed
    sbrc button_flags, BTN_ALARM
    rjmp TOGGLE_ALARM
    
    ; Check for alarm condition
    rcall CHECK_ALARM
    
    rjmp MAIN_LOOP

ENTER_SET_MODE:
    ; Clear button flag
    cbr button_flags, (1<<BTN_SET)
    
    ; Enter hour setting mode
    ldi clock_state, STATE_SET_HOUR
    rcall DISPLAY_SET_HOUR
    rjmp MAIN_LOOP

TOGGLE_ALARM:
    ; Clear button flag
    cbr button_flags, (1<<BTN_ALARM)
    
    ; Toggle alarm enable
    sbrc alarm_enabled, 0
    rjmp DISABLE_ALARM
    
    ; Enable alarm
    ldi alarm_enabled, 1
    rjmp ALARM_TOGGLE_DONE
    
DISABLE_ALARM:
    clr alarm_enabled
    
ALARM_TOGGLE_DONE:
    rcall DISPLAY_ALARM_STATUS
    rcall DELAY_1S
    rjmp MAIN_LOOP

HANDLE_SET_HOUR:
    ; Handle hour setting
    sbrc button_flags, BTN_UP
    rjmp INCREMENT_HOUR
    
    sbrc button_flags, BTN_DOWN  
    rjmp DECREMENT_HOUR
    
    sbrc button_flags, BTN_SET
    rjmp NEXT_SET_STATE
    
    rjmp MAIN_LOOP

INCREMENT_HOUR:
    cbr button_flags, (1<<BTN_UP)
    inc hours
    cpi hours, 24
    brlo UPDATE_HOUR_DISPLAY
    clr hours
    
UPDATE_HOUR_DISPLAY:
    rcall DISPLAY_SET_HOUR
    rjmp MAIN_LOOP

DECREMENT_HOUR:
    cbr button_flags, (1<<BTN_DOWN)
    dec hours
    brpl UPDATE_HOUR_DISPLAY
    ldi hours, 23
    rjmp UPDATE_HOUR_DISPLAY

NEXT_SET_STATE:
    cbr button_flags, (1<<BTN_SET)
    ldi clock_state, STATE_SET_MIN
    rcall DISPLAY_SET_MIN
    rjmp MAIN_LOOP

HANDLE_SET_MIN:
    ; Handle minute setting (similar to hour)
    sbrc button_flags, BTN_UP
    rjmp INCREMENT_MIN
    
    sbrc button_flags, BTN_DOWN
    rjmp DECREMENT_MIN
    
    sbrc button_flags, BTN_SET
    rjmp EXIT_SET_MODE
    
    rjmp MAIN_LOOP

INCREMENT_MIN:
    cbr button_flags, (1<<BTN_UP)
    inc minutes
    cpi minutes, 60
    brlo UPDATE_MIN_DISPLAY
    clr minutes
    
UPDATE_MIN_DISPLAY:
    rcall DISPLAY_SET_MIN
    rjmp MAIN_LOOP

DECREMENT_MIN:
    cbr button_flags, (1<<BTN_DOWN)
    dec minutes
    brpl UPDATE_MIN_DISPLAY
    ldi minutes, 59
    rjmp UPDATE_MIN_DISPLAY

EXIT_SET_MODE:
    cbr button_flags, (1<<BTN_SET)
    clr seconds              ; Reset seconds when time is set
    ldi clock_state, STATE_DISPLAY
    rjmp MAIN_LOOP

HANDLE_SET_ALARM_HOUR:
HANDLE_SET_ALARM_MIN:
    ; Similar implementations for alarm setting
    rjmp MAIN_LOOP

; ====================================================================
; HARDWARE INITIALIZATION
; ====================================================================
INIT_PORTS:
    ; Configure LCD pins as outputs
    ldi temp, 0xF3          ; PD7-PD4, PD1, PD0 as outputs
    out DDRD, temp
    
    ; Configure buttons as inputs with pull-ups
    clr temp
    out DDRB, temp          ; All inputs
    ldi temp, 0x0F          ; Enable pull-ups PB0-PB3
    out PORTB, temp
    
    ; Configure buzzer pin as output
    sbi DDRC, 0             ; PC0 as output for buzzer
    
    ret

INIT_TIMER:
    ; Configure Timer2 for 1-second interrupts using 32.768kHz crystal
    ; Use Timer2 in asynchronous mode with external 32.768kHz crystal
    
    ; Set Timer2 to async mode with external crystal
    ldi temp, (1<<AS2)
    out ASSR, temp
    
    ; Wait for async mode to stabilize
    rcall DELAY_100MS
    
    ; Set Timer2 for CTC mode, prescaler 128
    ; 32768 Hz / 128 = 256 Hz
    ; For 1 second: need 256 counts
    ldi temp, 255           ; TOP value for ~1 second
    out OCR2, temp
    
    ; Enable Timer2 overflow interrupt
    ldi temp, (1<<TOIE2)
    out TIMSK, temp
    
    ; Start Timer2 with prescaler 128
    ldi temp, (1<<CS22)|(1<<CS20)
    out TCCR2, temp
    
    ret

; ====================================================================
; BUTTON HANDLING
; ====================================================================
CHECK_BUTTONS:
    push temp
    
    ; Read button states (active low)
    in temp, PINB
    com temp                ; Invert for active high logic
    andi temp, 0x0F         ; Mask button bits
    
    ; Store new button presses only
    or button_flags, temp
    
    ; Debouncing delay
    rcall DELAY_10MS
    
    pop temp
    ret

; ====================================================================
; DISPLAY FUNCTIONS
; ====================================================================
DISPLAY_TIME:
    ; Display current time in HH:MM:SS format
    rcall LCD_CLEAR
    
    ; Display "Time: "
    ldi ZH, high(TIME_LABEL*2)
    ldi ZL, low(TIME_LABEL*2)
    rcall LCD_PRINT_STRING
    
    ; Display hours
    mov temp, hours
    rcall DISPLAY_TWO_DIGITS
    
    ; Display ":"
    ldi temp, ':'
    rcall LCD_SEND_DATA
    
    ; Display minutes
    mov temp, minutes
    rcall DISPLAY_TWO_DIGITS
    
    ; Display ":"
    ldi temp, ':'
    rcall LCD_SEND_DATA
    
    ; Display seconds
    mov temp, seconds
    rcall DISPLAY_TWO_DIGITS
    
    ; Second line - alarm status
    rcall LCD_LINE2
    rcall DISPLAY_ALARM_INFO
    
    ret

DISPLAY_TWO_DIGITS:
    ; Display number in temp as two digits
    push temp2
    
    clr temp2               ; Tens counter
COUNT_TENS_DISP:
    cpi temp, 10
    brlo SHOW_DIGITS
    subi temp, 10
    inc temp2
    rjmp COUNT_TENS_DISP
    
SHOW_DIGITS:
    ; Display tens
    mov r0, temp2
    subi r0, -'0'
    mov temp, r0
    rcall LCD_SEND_DATA
    
    ; Display units (temp already has units)
    subi temp, -'0'
    rcall LCD_SEND_DATA
    
    pop temp2
    ret

DISPLAY_SET_HOUR:
    rcall LCD_CLEAR
    ldi ZH, high(SET_HOUR_MSG*2)
    ldi ZL, low(SET_HOUR_MSG*2)
    rcall LCD_PRINT_STRING
    
    mov temp, hours
    rcall DISPLAY_TWO_DIGITS
    ret

DISPLAY_SET_MIN:
    rcall LCD_CLEAR
    ldi ZH, high(SET_MIN_MSG*2)
    ldi ZL, low(SET_MIN_MSG*2)
    rcall LCD_PRINT_STRING
    
    mov temp, minutes
    rcall DISPLAY_TWO_DIGITS
    ret

DISPLAY_STARTUP:
    rcall LCD_CLEAR
    ldi ZH, high(STARTUP_MSG*2)
    ldi ZL, low(STARTUP_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(VERSION_MSG*2)
    ldi ZL, low(VERSION_MSG*2)
    rcall LCD_PRINT_STRING
    ret

DISPLAY_ALARM_STATUS:
    rcall LCD_LINE2
    
    sbrc alarm_enabled, 0
    rjmp SHOW_ALARM_ON
    
    ldi ZH, high(ALARM_OFF_MSG*2)
    ldi ZL, low(ALARM_OFF_MSG*2)
    rcall LCD_PRINT_STRING
    ret
    
SHOW_ALARM_ON:
    ldi ZH, high(ALARM_ON_MSG*2)
    ldi ZL, low(ALARM_ON_MSG*2)
    rcall LCD_PRINT_STRING
    ret

DISPLAY_ALARM_INFO:
    ; Show alarm time if enabled
    sbrs alarm_enabled, 0
    ret
    
    ldi ZH, high(ALARM_INFO_MSG*2)
    ldi ZL, low(ALARM_INFO_MSG*2)
    rcall LCD_PRINT_STRING
    
    mov temp, alarm_hour
    rcall DISPLAY_TWO_DIGITS
    
    ldi temp, ':'
    rcall LCD_SEND_DATA
    
    mov temp, alarm_min
    rcall DISPLAY_TWO_DIGITS
    
    ret

; ====================================================================
; ALARM FUNCTIONS
; ====================================================================
CHECK_ALARM:
    ; Check if alarm should trigger
    sbrs alarm_enabled, 0
    ret                     ; Alarm not enabled
    
    ; Check if current time matches alarm time
    cp hours, alarm_hour
    brne ALARM_CHECK_DONE
    
    cp minutes, alarm_min
    brne ALARM_CHECK_DONE
    
    ; Check if it's exactly 0 seconds (trigger once per minute)
    tst seconds
    brne ALARM_CHECK_DONE
    
    ; Trigger alarm
    rcall SOUND_ALARM
    
ALARM_CHECK_DONE:
    ret

SOUND_ALARM:
    ; Sound buzzer for alarm
    push r26
    
    ldi r26, 10             ; Beep 10 times
ALARM_BEEP_LOOP:
    sbi PORTC, 0            ; Buzzer on
    rcall DELAY_200MS
    
    cbi PORTC, 0            ; Buzzer off
    rcall DELAY_200MS
    
    dec r26
    brne ALARM_BEEP_LOOP
    
    pop r26
    ret

; ====================================================================
; TIMER2 INTERRUPT (1 SECOND TICK)
; ====================================================================
TIMER2_OVF:
    ; Save registers
    push temp
    in temp, SREG
    push temp
    
    ; Increment seconds
    inc seconds
    cpi seconds, 60
    brlo TIMER_DONE
    
    ; Seconds overflow - increment minutes
    clr seconds
    inc minutes
    cpi minutes, 60
    brlo TIMER_DONE
    
    ; Minutes overflow - increment hours
    clr minutes
    inc hours
    cpi hours, 24
    brlo TIMER_DONE
    
    ; Hours overflow - reset to 0
    clr hours
    
TIMER_DONE:
    ; Restore registers
    pop temp
    out SREG, temp
    pop temp
    reti

; ====================================================================
; LCD FUNCTIONS (simplified versions)
; ====================================================================
LCD_INIT:
    ; Initialize LCD (basic 4-bit mode setup)
    rcall DELAY_50MS
    
    ldi temp, 0x02
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x28
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x0C
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x06
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x01
    rcall LCD_SEND_COMMAND
    
    rcall DELAY_10MS
    ret

LCD_SEND_COMMAND:
    cbi PORTD, 0            ; RS = 0
    rcall LCD_WRITE_NIBBLES
    ret

LCD_SEND_DATA:
    sbi PORTD, 0            ; RS = 1  
    rcall LCD_WRITE_NIBBLES
    cbi PORTD, 0            ; RS = 0
    ret

LCD_WRITE_NIBBLES:
    ; Write upper nibble
    push temp2
    mov temp2, temp
    swap temp2
    andi temp2, 0x0F
    
    ; Set data lines
    in r0, PORTD
    andi r0, 0x0F
    swap temp2
    or r0, temp2
    out PORTD, r0
    
    ; Pulse EN
    sbi PORTD, 1
    rcall DELAY_1MS
    cbi PORTD, 1
    
    ; Write lower nibble
    andi temp, 0x0F
    
    in r0, PORTD
    andi r0, 0x0F
    swap temp
    or r0, temp
    out PORTD, r0
    
    ; Pulse EN
    sbi PORTD, 1
    rcall DELAY_1MS
    cbi PORTD, 1
    
    pop temp2
    ret

LCD_CLEAR:
    ldi temp, 0x01
    rcall LCD_SEND_COMMAND
    rcall DELAY_10MS
    ret

LCD_LINE2:
    ldi temp, 0xC0
    rcall LCD_SEND_COMMAND
    ret

LCD_PRINT_STRING:
LCD_PRINT_LOOP:
    lpm temp, Z+
    tst temp
    breq LCD_PRINT_END
    rcall LCD_SEND_DATA
    rjmp LCD_PRINT_LOOP
LCD_PRINT_END:
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_1MS:
    push r27
    ldi r27, 8              ; Adjusted for 32kHz
DELAY_1MS_LOOP:
    nop
    nop
    nop
    nop
    dec r27
    brne DELAY_1MS_LOOP
    pop r27
    ret

DELAY_10MS:
    push r28
    ldi r28, 10
DELAY_10MS_LOOP:
    rcall DELAY_1MS
    dec r28
    brne DELAY_10MS_LOOP
    pop r28
    ret

DELAY_50MS:
    push r29
    ldi r29, 50
DELAY_50MS_LOOP:
    rcall DELAY_1MS
    dec r29
    brne DELAY_50MS_LOOP
    pop r29
    ret

DELAY_100MS:
    rcall DELAY_50MS
    rcall DELAY_50MS
    ret

DELAY_200MS:
    rcall DELAY_100MS
    rcall DELAY_100MS
    ret

DELAY_1S:
    push r30
    ldi r30, 10
DELAY_1S_LOOP:
    rcall DELAY_100MS
    dec r30
    brne DELAY_1S_LOOP
    pop r30
    ret

DELAY_2S:
    rcall DELAY_1S
    rcall DELAY_1S
    ret

; ====================================================================
; STRING CONSTANTS
; ====================================================================
STARTUP_MSG:
    .db "Digital Clock", 0

VERSION_MSG:
    .db "v1.0 Ready", 0

TIME_LABEL:
    .db "Time: ", 0

SET_HOUR_MSG:
    .db "Set Hour: ", 0

SET_MIN_MSG:
    .db "Set Min: ", 0

ALARM_ON_MSG:
    .db "Alarm: ON", 0

ALARM_OFF_MSG:
    .db "Alarm: OFF", 0

ALARM_INFO_MSG:
    .db "Alarm: ", 0

; ====================================================================
; END OF PROGRAM
; ====================================================================
