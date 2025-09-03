; ====================================================================
; ASSIGNMENT 8: KEYPAD SECURITY SYSTEM
; ====================================================================
; Description: 4x4 keypad-based security system with LCD and LED indicators
; Hardware: ATmega32 + 4x4 Keypad + LCD + LEDs + Buzzer
; Difficulty: Advanced
; Learning Objective: Keypad scanning, string comparison, security logic
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; 4x4 Keypad Matrix:
;   Rows:    PC0, PC1, PC2, PC3 (Outputs)
;   Columns: PC4, PC5, PC6, PC7 (Inputs with pull-ups)
;
; 16x2 LCD Display:
;   RS      → PD0 (Pin 14)
;   EN      → PD1 (Pin 15)
;   D4-D7   → PD4-PD7 (Pins 16,19,20,21)
;
; Status LEDs:
;   GREEN   → PB0 (Pin 1) - System Armed
;   RED     → PB1 (Pin 2) - Access Denied
;   BLUE    → PB2 (Pin 3) - System Ready
;
; Buzzer:
;   Positive → PB3 (Pin 4) through transistor
;   Negative → GND
;
; ATmega32 Setup:
;   VCC     → 5V
;   GND     → GND
;   RESET   → 10kΩ to VCC
;   XTAL1   → 8MHz Crystal + 22pF to GND
;   XTAL2   → 8MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 8000000        ; 8MHz Crystal

; System States
.equ STATE_READY = 0        ; System ready for input
.equ STATE_INPUT = 1        ; Receiving password input
.equ STATE_GRANTED = 2      ; Access granted
.equ STATE_DENIED = 3       ; Access denied
.equ STATE_LOCKED = 4       ; System locked after failed attempts

; LED Definitions
.equ LED_GREEN = 0          ; PB0
.equ LED_RED = 1            ; PB1
.equ LED_BLUE = 2           ; PB2
.equ BUZZER = 3             ; PB3

; Password Settings
.equ PASS_LENGTH = 4        ; 4-digit password
.equ MAX_ATTEMPTS = 3       ; Maximum failed attempts

; Register Definitions
.def temp = r16             ; Temporary register
.def temp2 = r17            ; Second temporary
.def keypad_key = r18       ; Currently pressed key
.def system_state = r19     ; Current system state
.def pass_index = r20       ; Current password input position
.def attempt_count = r21    ; Failed attempt counter
.def row = r22              ; Keypad row counter
.def col = r23              ; Keypad column counter

; Memory locations for password storage
.equ PASS_BUFFER = 0x100    ; Password input buffer in SRAM
.equ CORRECT_PASS = 0x110   ; Correct password storage

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
    
    ; Initialize hardware
    rcall INIT_PORTS
    rcall LCD_INIT
    
    ; Set correct password (1234)
    rcall INIT_PASSWORD
    
    ; Initialize system state
    ldi system_state, STATE_READY
    clr pass_index
    clr attempt_count
    
    ; Display welcome message
    rcall DISPLAY_WELCOME
    rcall DELAY_2S
    
    ; Show ready state
    rcall SET_STATE_READY

; ====================================================================
; MAIN LOOP
; ====================================================================
MAIN_LOOP:
    ; Check system state and handle accordingly
    cpi system_state, STATE_READY
    breq HANDLE_READY
    
    cpi system_state, STATE_INPUT
    breq HANDLE_INPUT
    
    cpi system_state, STATE_GRANTED
    breq HANDLE_GRANTED
    
    cpi system_state, STATE_DENIED
    breq HANDLE_DENIED
    
    cpi system_state, STATE_LOCKED
    breq HANDLE_LOCKED
    
    rjmp MAIN_LOOP

; ====================================================================
; STATE HANDLERS
; ====================================================================
HANDLE_READY:
    ; Scan keypad for input
    rcall SCAN_KEYPAD
    
    ; If key pressed, start password entry
    cpi keypad_key, 0xFF
    breq MAIN_LOOP              ; No key pressed
    
    ; Key pressed - enter input state
    ldi system_state, STATE_INPUT
    clr pass_index
    rcall CLEAR_PASSWORD_BUFFER
    rcall DISPLAY_ENTER_PASSWORD
    
    ; Process first key
    rjmp PROCESS_KEY_INPUT

HANDLE_INPUT:
    ; Scan for more keys
    rcall SCAN_KEYPAD
    
    cpi keypad_key, 0xFF
    breq MAIN_LOOP              ; No new key
    
PROCESS_KEY_INPUT:
    ; Check for special keys
    cpi keypad_key, '*'
    breq RESET_PASSWORD_ENTRY
    
    cpi keypad_key, '#'
    breq VERIFY_PASSWORD
    
    ; Check if it's a digit (0-9)
    cpi keypad_key, '0'
    brlo INVALID_KEY
    cpi keypad_key, '9'+1
    brsh INVALID_KEY
    
    ; Valid digit - store in buffer
    rcall STORE_PASSWORD_DIGIT
    
    rjmp MAIN_LOOP

RESET_PASSWORD_ENTRY:
    ; Reset password entry
    clr pass_index
    rcall CLEAR_PASSWORD_BUFFER
    rcall DISPLAY_ENTER_PASSWORD
    rjmp MAIN_LOOP

VERIFY_PASSWORD:
    ; Check if we have enough digits
    cpi pass_index, PASS_LENGTH
    brne PASSWORD_TOO_SHORT
    
    ; Verify password
    rcall CHECK_PASSWORD
    
    ; Branch based on result
    sbrc temp, 0                ; If bit 0 set, password correct
    rjmp PASSWORD_CORRECT
    
    ; Password incorrect
    inc attempt_count
    cpi attempt_count, MAX_ATTEMPTS
    brsh LOCK_SYSTEM
    
    ; Show access denied
    ldi system_state, STATE_DENIED
    rjmp MAIN_LOOP

PASSWORD_TOO_SHORT:
    rcall DISPLAY_TOO_SHORT
    rcall DELAY_1S
    rcall DISPLAY_ENTER_PASSWORD
    rjmp MAIN_LOOP

PASSWORD_CORRECT:
    ; Reset attempt counter and grant access
    clr attempt_count
    ldi system_state, STATE_GRANTED
    rjmp MAIN_LOOP

LOCK_SYSTEM:
    ; Lock system after too many attempts
    ldi system_state, STATE_LOCKED
    rjmp MAIN_LOOP

INVALID_KEY:
    ; Invalid key pressed - ignore
    rjmp MAIN_LOOP

HANDLE_GRANTED:
    ; Show access granted
    rcall DISPLAY_ACCESS_GRANTED
    rcall SET_LED_GREEN
    rcall DELAY_5S
    
    ; Return to ready state
    ldi system_state, STATE_READY
    rcall SET_STATE_READY
    rjmp MAIN_LOOP

HANDLE_DENIED:
    ; Show access denied
    rcall DISPLAY_ACCESS_DENIED
    rcall SET_LED_RED
    rcall SOUND_DENIAL_ALARM
    rcall DELAY_3S
    
    ; Return to ready state
    ldi system_state, STATE_READY
    rcall SET_STATE_READY
    rjmp MAIN_LOOP

HANDLE_LOCKED:
    ; System locked - show warning
    rcall DISPLAY_SYSTEM_LOCKED
    rcall SET_LED_RED
    rcall SOUND_LOCK_ALARM
    
    ; Stay in locked state (would need admin override)
    rjmp MAIN_LOOP

; ====================================================================
; HARDWARE INITIALIZATION
; ====================================================================
INIT_PORTS:
    ; Configure keypad rows as outputs (PC0-PC3)
    ldi temp, 0x0F
    out DDRC, temp
    
    ; Set rows HIGH initially, enable pull-ups for columns
    ldi temp, 0xFF
    out PORTC, temp
    
    ; Configure LCD pins
    ldi temp, 0xF3              ; PD7-PD4, PD1, PD0
    out DDRD, temp
    
    ; Configure LED and buzzer pins as outputs
    ldi temp, 0x0F              ; PB0-PB3
    out DDRB, temp
    
    ret

INIT_PASSWORD:
    ; Store correct password "1234" in SRAM
    ldi XH, high(CORRECT_PASS)
    ldi XL, low(CORRECT_PASS)
    
    ldi temp, '1'
    st X+, temp
    ldi temp, '2'
    st X+, temp
    ldi temp, '3'
    st X+, temp
    ldi temp, '4'
    st X+, temp
    
    ret

; ====================================================================
; KEYPAD FUNCTIONS
; ====================================================================
SCAN_KEYPAD:
    ; Initialize key as not pressed
    ldi keypad_key, 0xFF
    
    ; Scan each row
    clr row
    
ROW_LOOP:
    ; Set current row LOW, others HIGH
    ldi temp, 0xFF
    lsl row
    com row
    and temp, row
    com row
    lsr row
    out PORTC, temp
    
    ; Small delay for signal settling
    rcall DELAY_1MS
    
    ; Read columns
    in temp, PINC
    andi temp, 0xF0             ; Mask column bits
    
    ; Check each column
    clr col
    
COL_LOOP:
    ; Check if current column is pressed (LOW)
    mov temp2, temp
    lsr temp2
    lsr temp2
    lsr temp2
    lsr temp2
    
    sbrc temp2, col             ; Skip if bit is clear (pressed)
    rjmp NEXT_COLUMN
    
    ; Key pressed - calculate key value
    rcall CALCULATE_KEY_VALUE
    
    ; Debounce - wait for key release
    rcall WAIT_KEY_RELEASE
    
    ; Restore all rows HIGH
    ldi temp, 0xFF
    out PORTC, temp
    
    ret

NEXT_COLUMN:
    inc col
    cpi col, 4
    brlo COL_LOOP
    
    inc row
    cpi row, 4
    brlo ROW_LOOP
    
    ; Restore all rows HIGH
    ldi temp, 0xFF
    out PORTC, temp
    
    ret

CALCULATE_KEY_VALUE:
    ; Calculate key based on row and column
    ; Row 0: 1,2,3,A  Row 1: 4,5,6,B  Row 2: 7,8,9,C  Row 3: *,0,#,D
    
    mov temp, row
    lsl temp
    lsl temp                    ; row * 4
    add temp, col               ; + column
    
    ; Use lookup table
    ldi ZH, high(KEYPAD_TABLE*2)
    ldi ZL, low(KEYPAD_TABLE*2)
    add ZL, temp
    ldi temp, 0
    adc ZH, temp
    
    lpm keypad_key, Z
    
    ret

WAIT_KEY_RELEASE:
    ; Wait until key is released
KEY_RELEASE_LOOP:
    ; Set current row LOW
    ldi temp, 0xFF
    mov temp2, row
    lsl temp2
    com temp2
    and temp, temp2
    out PORTC, temp
    
    rcall DELAY_10MS
    
    ; Read columns
    in temp, PINC
    andi temp, 0xF0
    
    ; Check if our column is released (HIGH)
    mov temp2, temp
    lsr temp2
    lsr temp2  
    lsr temp2
    lsr temp2
    
    sbrs temp2, col             ; Skip if bit is set (released)
    rjmp KEY_RELEASE_LOOP
    
    ret

; ====================================================================
; PASSWORD FUNCTIONS
; ====================================================================
CLEAR_PASSWORD_BUFFER:
    ; Clear password input buffer
    ldi XH, high(PASS_BUFFER)
    ldi XL, low(PASS_BUFFER)
    
    ldi temp2, PASS_LENGTH
CLEAR_LOOP:
    ldi temp, 0
    st X+, temp
    dec temp2
    brne CLEAR_LOOP
    
    ret

STORE_PASSWORD_DIGIT:
    ; Check if buffer is full
    cpi pass_index, PASS_LENGTH
    brsh BUFFER_FULL
    
    ; Store digit in buffer
    ldi XH, high(PASS_BUFFER)
    ldi XL, low(PASS_BUFFER)
    add XL, pass_index
    ldi temp, 0
    adc XH, temp
    
    st X, keypad_key
    
    ; Increment index
    inc pass_index
    
    ; Update display
    rcall UPDATE_PASSWORD_DISPLAY
    
BUFFER_FULL:
    ret

CHECK_PASSWORD:
    ; Compare input buffer with correct password
    ldi XH, high(PASS_BUFFER)
    ldi XL, low(PASS_BUFFER)
    ldi YH, high(CORRECT_PASS)
    ldi YL, low(CORRECT_PASS)
    
    ldi temp2, PASS_LENGTH
    ldi temp, 1                 ; Assume match initially
    
COMPARE_LOOP:
    ld r0, X+
    ld r1, Y+
    cp r0, r1
    breq CONTINUE_COMPARE
    
    ; Mismatch found
    ldi temp, 0
    
CONTINUE_COMPARE:
    dec temp2
    brne COMPARE_LOOP
    
    ret                         ; Result in temp (1=match, 0=no match)

; ====================================================================
; DISPLAY FUNCTIONS
; ====================================================================
DISPLAY_WELCOME:
    rcall LCD_CLEAR
    ldi ZH, high(WELCOME_MSG*2)
    ldi ZL, low(WELCOME_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(SECURITY_MSG*2)
    ldi ZL, low(SECURITY_MSG*2)
    rcall LCD_PRINT_STRING
    ret

DISPLAY_ENTER_PASSWORD:
    rcall LCD_CLEAR
    ldi ZH, high(ENTER_PASS_MSG*2)
    ldi ZL, low(ENTER_PASS_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(STARS_MSG*2)
    ldi ZL, low(STARS_MSG*2)
    rcall LCD_PRINT_STRING
    ret

UPDATE_PASSWORD_DISPLAY:
    ; Update password display with stars
    rcall LCD_LINE2
    
    ; Show stars for entered digits
    mov temp2, pass_index
UPDATE_STAR_LOOP:
    tst temp2
    breq UPDATE_DONE
    
    ldi temp, '*'
    rcall LCD_SEND_DATA
    
    dec temp2
    rjmp UPDATE_STAR_LOOP
    
UPDATE_DONE:
    ret

DISPLAY_ACCESS_GRANTED:
    rcall LCD_CLEAR
    ldi ZH, high(ACCESS_OK_MSG*2)
    ldi ZL, low(ACCESS_OK_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(WELCOME_IN_MSG*2)
    ldi ZL, low(WELCOME_IN_MSG*2)
    rcall LCD_PRINT_STRING
    ret

DISPLAY_ACCESS_DENIED:
    rcall LCD_CLEAR
    ldi ZH, high(ACCESS_DENIED_MSG*2)
    ldi ZL, low(ACCESS_DENIED_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(TRY_AGAIN_MSG*2)
    ldi ZL, low(TRY_AGAIN_MSG*2)
    rcall LCD_PRINT_STRING
    ret

DISPLAY_SYSTEM_LOCKED:
    rcall LCD_CLEAR
    ldi ZH, high(LOCKED_MSG*2)
    ldi ZL, low(LOCKED_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(CONTACT_ADMIN_MSG*2)
    ldi ZL, low(CONTACT_ADMIN_MSG*2)
    rcall LCD_PRINT_STRING
    ret

DISPLAY_TOO_SHORT:
    rcall LCD_CLEAR
    ldi ZH, high(TOO_SHORT_MSG*2)
    ldi ZL, low(TOO_SHORT_MSG*2)
    rcall LCD_PRINT_STRING
    ret

; ====================================================================
; LED AND STATE FUNCTIONS
; ====================================================================
SET_STATE_READY:
    ; Turn on blue LED, others off
    ldi temp, (1<<LED_BLUE)
    out PORTB, temp
    
    rcall DISPLAY_READY
    ret

SET_LED_GREEN:
    ; Turn on green LED, others off
    ldi temp, (1<<LED_GREEN)
    out PORTB, temp
    ret

SET_LED_RED:
    ; Turn on red LED, others off
    ldi temp, (1<<LED_RED)
    out PORTB, temp
    ret

DISPLAY_READY:
    rcall LCD_CLEAR
    ldi ZH, high(READY_MSG*2)
    ldi ZL, low(READY_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(PRESS_KEY_MSG*2)
    ldi ZL, low(PRESS_KEY_MSG*2)
    rcall LCD_PRINT_STRING
    ret

; ====================================================================
; ALARM FUNCTIONS
; ====================================================================
SOUND_DENIAL_ALARM:
    ; Quick beeps for denial
    push r24
    ldi r24, 3
    
DENIAL_BEEP_LOOP:
    sbi PORTB, BUZZER
    rcall DELAY_100MS
    cbi PORTB, BUZZER
    rcall DELAY_100MS
    
    dec r24
    brne DENIAL_BEEP_LOOP
    
    pop r24
    ret

SOUND_LOCK_ALARM:
    ; Continuous alarm for system lock
    push r24
    ldi r24, 20
    
LOCK_ALARM_LOOP:
    sbi PORTB, BUZZER
    rcall DELAY_50MS
    cbi PORTB, BUZZER
    rcall DELAY_50MS
    
    dec r24
    brne LOCK_ALARM_LOOP
    
    pop r24
    ret

; ====================================================================
; LCD FUNCTIONS (Simplified)
; ====================================================================
LCD_INIT:
    ; Basic LCD initialization
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
    cbi PORTD, 0                ; RS = 0
    rcall LCD_WRITE_BYTE
    ret

LCD_SEND_DATA:
    sbi PORTD, 0                ; RS = 1
    rcall LCD_WRITE_BYTE
    cbi PORTD, 0
    ret

LCD_WRITE_BYTE:
    ; Write 4-bit mode (simplified)
    push temp2
    
    ; Upper nibble
    mov temp2, temp
    swap temp2
    andi temp2, 0x0F
    swap temp2
    
    in r0, PORTD
    andi r0, 0x0F
    or r0, temp2
    out PORTD, r0
    
    sbi PORTD, 1                ; EN high
    rcall DELAY_1MS
    cbi PORTD, 1                ; EN low
    
    ; Lower nibble
    andi temp, 0x0F
    swap temp
    
    in r0, PORTD
    andi r0, 0x0F
    or r0, temp
    out PORTD, r0
    
    sbi PORTD, 1                ; EN high
    rcall DELAY_1MS
    cbi PORTD, 1                ; EN low
    
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
LCD_STRING_LOOP:
    lpm temp, Z+
    tst temp
    breq LCD_STRING_DONE
    rcall LCD_SEND_DATA
    rjmp LCD_STRING_LOOP
LCD_STRING_DONE:
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_1MS:
    push r26
    ldi r26, 250
DELAY_1MS_LOOP:
    nop
    nop
    nop
    nop
    dec r26
    brne DELAY_1MS_LOOP
    pop r26
    ret

DELAY_10MS:
    push r27
    ldi r27, 10
DELAY_10MS_LOOP:
    rcall DELAY_1MS
    dec r27
    brne DELAY_10MS_LOOP
    pop r27
    ret

DELAY_50MS:
    push r28
    ldi r28, 50
DELAY_50MS_LOOP:
    rcall DELAY_1MS
    dec r28
    brne DELAY_50MS_LOOP
    pop r28
    ret

DELAY_100MS:
    rcall DELAY_50MS
    rcall DELAY_50MS
    ret

DELAY_1S:
    push r29
    ldi r29, 10
DELAY_1S_LOOP:
    rcall DELAY_100MS
    dec r29
    brne DELAY_1S_LOOP
    pop r29
    ret

DELAY_2S:
    rcall DELAY_1S
    rcall DELAY_1S
    ret

DELAY_3S:
    rcall DELAY_1S
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
; LOOKUP TABLES
; ====================================================================
KEYPAD_TABLE:
    .db '1', '2', '3', 'A'
    .db '4', '5', '6', 'B'
    .db '7', '8', '9', 'C'
    .db '*', '0', '#', 'D'

; ====================================================================
; STRING CONSTANTS
; ====================================================================
WELCOME_MSG:
    .db "Security System", 0

SECURITY_MSG:
    .db "Version 1.0", 0

READY_MSG:
    .db "System Ready", 0

PRESS_KEY_MSG:
    .db "Press any key", 0

ENTER_PASS_MSG:
    .db "Enter Password:", 0

STARS_MSG:
    .db "****", 0

ACCESS_OK_MSG:
    .db "ACCESS GRANTED", 0

WELCOME_IN_MSG:
    .db "Welcome!", 0

ACCESS_DENIED_MSG:
    .db "ACCESS DENIED", 0

TRY_AGAIN_MSG:
    .db "Try Again", 0

LOCKED_MSG:
    .db "SYSTEM LOCKED", 0

CONTACT_ADMIN_MSG:
    .db "Contact Admin", 0

TOO_SHORT_MSG:
    .db "Password too short", 0

; ====================================================================
; END OF PROGRAM
; ====================================================================
