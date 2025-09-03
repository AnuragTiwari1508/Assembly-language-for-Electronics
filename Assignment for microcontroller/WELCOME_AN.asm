; ====================================================================
; ULTRASONIC DISTANCE DETECTOR WITH LCD DISPLAY - ATmega32
; ====================================================================
; Description: Displays "WELCOME TO ELECTROLITES!" when distance ≤ 100cm
; Hardware: ATmega32 + HC-SR04 + 16x2 LCD
; Author: Anurag Tiwari
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; HC-SR04 Ultrasonic Sensor:
;   VCC     → 5V
;   GND     → GND
;   TRIG    → PD6 (Pin 20)
;   ECHO    → PD7 (Pin 21) - INT2
;
; 16x2 LCD Display:
;   VSS     → GND
;   VDD     → 5V
;   V0      → 10kΩ POT (Contrast)
;   RS      → PA0 (Pin 40)
;   EN      → PA1 (Pin 39)
;   D4      → PC4 (Pin 18)
;   D5      → PC5 (Pin 19)
;   D6      → PC6 (Pin 22)
;   D7      → PC7 (Pin 23)
;   A       → 5V (Backlight)
;   K       → GND (Backlight)
;
; ATmega32:
;   XTAL1   → 16MHz Crystal + 22pF to GND
;   XTAL2   → 16MHz Crystal + 22pF to GND
;   RESET   → 10kΩ to VCC + Reset Button to GND
;   AVCC    → 5V
;   AREF    → 5V
;   VCC     → 5V
;   GND     → GND
; ====================================================================

; System Constants
.equ F_CPU = 16000000           ; 16MHz Crystal
.equ DISTANCE_THRESHOLD = 100   ; 100cm threshold
.equ SOUND_SPEED = 58           ; For HC-SR04 calculation

; Register Definitions
.def temp = r16                 ; Temporary register
.def temp2 = r17               ; Second temp register
.def distance_low = r18         ; Distance low byte
.def distance_high = r19        ; Distance high byte
.def echo_time_low = r20        ; Echo time low byte
.def echo_time_high = r21       ; Echo time high byte

; ====================================================================
; INTERRUPT VECTORS
; ====================================================================
.org 0x0000
    rjmp MAIN                   ; Reset Vector
.org 0x0002
    rjmp EXT_INT0_ISR          ; External Interrupt 0
.org 0x0004  
    rjmp EXT_INT1_ISR          ; External Interrupt 1
.org 0x0006
    rjmp ECHO_ISR              ; External Interrupt 2 (Echo Pin)

; Skip other interrupt vectors
.org 0x0046

; ====================================================================
; MAIN PROGRAM
; ====================================================================
MAIN:
    ; Initialize Stack Pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    
    ; Initialize Hardware
    rcall INIT_PORTS
    rcall INIT_TIMER
    rcall INIT_INTERRUPTS
    rcall LCD_INIT
    
    ; Display startup message
    rcall LCD_CLEAR
    ldi ZH, high(STARTUP_MSG*2)
    ldi ZL, low(STARTUP_MSG*2)
    rcall LCD_PRINT_STRING
    
    ; Enable global interrupts
    sei
    
    ; Display ready message on second line
    rcall LCD_LINE2
    ldi ZH, high(READY_MSG*2)
    ldi ZL, low(READY_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall DELAY_2S              ; Show startup message for 2 seconds

; ====================================================================
; MAIN LOOP
; ====================================================================
MAIN_LOOP:
    ; Clear display and show scanning message
    rcall LCD_CLEAR
    ldi ZH, high(SCANNING_MSG*2)
    ldi ZL, low(SCANNING_MSG*2)
    rcall LCD_PRINT_STRING
    
    ; Measure distance using ultrasonic sensor
    rcall MEASURE_DISTANCE
    
    ; Check if distance is <= 100cm
    rcall CHECK_DISTANCE_THRESHOLD
    
    ; Small delay before next measurement
    rcall DELAY_100MS
    
    rjmp MAIN_LOOP

; ====================================================================
; PORT INITIALIZATION
; ====================================================================
INIT_PORTS:
    ; Configure LCD pins as outputs
    sbi DDRA, 0                 ; PA0 (RS) as output
    sbi DDRA, 1                 ; PA1 (EN) as output
    
    ; Configure LCD data pins as outputs
    sbi DDRC, 4                 ; PC4 (D4) as output
    sbi DDRC, 5                 ; PC5 (D5) as output
    sbi DDRC, 6                 ; PC6 (D6) as output
    sbi DDRC, 7                 ; PC7 (D7) as output
    
    ; Configure ultrasonic sensor pins
    sbi DDRD, 6                 ; PD6 (TRIG) as output
    cbi DDRD, 7                 ; PD7 (ECHO) as input
    
    ; Initialize all outputs to low
    cbi PORTA, 0
    cbi PORTA, 1
    cbi PORTC, 4
    cbi PORTC, 5
    cbi PORTC, 6
    cbi PORTC, 7
    cbi PORTD, 6
    
    ret

; ====================================================================
; TIMER INITIALIZATION
; ====================================================================
INIT_TIMER:
    ; Timer1 Normal Mode for echo pulse measurement
    clr temp
    out TCCR1A, temp            ; Normal mode
    
    ; Timer1 with prescaler 8 (2MHz)
    ldi temp, (1<<CS11)
    out TCCR1B, temp
    
    ; Timer0 for general delays, prescaler 1024
    ldi temp, (1<<CS02)|(1<<CS00)
    out TCCR0, temp
    
    ret

; ====================================================================
; INTERRUPT INITIALIZATION
; ====================================================================
INIT_INTERRUPTS:
    ; Configure INT2 for echo pin (any logical change)
    ldi temp, (0<<ISC2)         ; Any logical change on INT2
    out MCUCSR, temp
    
    ; Enable INT2 interrupt
    ldi temp, (1<<INT2)
    out GICR, temp
    
    ret

; ====================================================================
; ULTRASONIC DISTANCE MEASUREMENT
; ====================================================================
MEASURE_DISTANCE:
    ; Send trigger pulse (10μs)
    sbi PORTD, 6                ; Trigger HIGH
    rcall DELAY_10US            ; Wait 10μs
    cbi PORTD, 6                ; Trigger LOW
    
    ; Reset timer for echo measurement
    clr temp
    out TCNT1H, temp
    out TCNT1L, temp
    
    ; Wait for echo pulse and measure duration
    rcall WAIT_FOR_ECHO
    
    ; Calculate distance from echo time
    rcall CALCULATE_DISTANCE
    
    ret

WAIT_FOR_ECHO:
    ; Wait for echo to go HIGH (start of pulse)
    ldi temp2, 0                ; Timeout counter
WAIT_ECHO_HIGH:
    sbis PIND, 7                ; Check if ECHO is HIGH
    rjmp ECHO_NOT_HIGH
    
    ; Echo went HIGH, start timer
    in echo_time_low, TCNT1L
    in echo_time_high, TCNT1H
    
    ; Wait for echo to go LOW (end of pulse)
WAIT_ECHO_LOW:
    sbic PIND, 7                ; Check if ECHO is still HIGH
    rjmp WAIT_ECHO_LOW
    
    ; Echo went LOW, stop timer
    in temp, TCNT1L
    sub temp, echo_time_low
    mov echo_time_low, temp
    
    in temp, TCNT1H
    sbc temp, echo_time_high
    mov echo_time_high, temp
    
    ret
    
ECHO_NOT_HIGH:
    inc temp2
    cpi temp2, 255              ; Timeout check
    brne WAIT_ECHO_HIGH
    
    ; Timeout occurred, set maximum distance
    ldi echo_time_low, 0xFF
    ldi echo_time_high, 0xFF
    
    ret

CALCULATE_DISTANCE:
    ; Convert echo time to distance
    ; Distance (cm) = Time (μs) / 58
    ; Since timer runs at 2MHz, each tick = 0.5μs
    ; So distance = (timer_ticks * 0.5) / 58 = timer_ticks / 116
    
    ; For simplicity, we'll use approximate calculation
    ; Distance ≈ timer_ticks / 100 (approximate)
    
    mov distance_low, echo_time_low
    mov distance_high, echo_time_high
    
    ; Divide by 100 (approximate)
    lsr distance_high
    ror distance_low
    lsr distance_high
    ror distance_low            ; Divide by 4
    
    ; Further approximation for /100
    lsr distance_high
    ror distance_low
    lsr distance_high
    ror distance_low
    lsr distance_high
    ror distance_low            ; Divide by 32 total (≈/100)
    
    ret

CHECK_DISTANCE_THRESHOLD:
    ; Check if distance <= 100cm
    cpi distance_low, DISTANCE_THRESHOLD
    brsh DISTANCE_TOO_FAR       ; Branch if distance >= 100cm
    
    ; Distance is <= 100cm, display welcome message
    rcall DISPLAY_WELCOME_MESSAGE
    ret
    
DISTANCE_TOO_FAR:
    ; Display current distance
    rcall DISPLAY_DISTANCE
    ret

; ====================================================================
; DISPLAY ROUTINES
; ====================================================================
DISPLAY_WELCOME_MESSAGE:
    ; Clear LCD and display welcome message
    rcall LCD_CLEAR
    
    ; Line 1: "WELCOME TO"
    ldi ZH, high(WELCOME_LINE1*2)
    ldi ZL, low(WELCOME_LINE1*2)
    rcall LCD_PRINT_STRING
    
    ; Line 2: "ELECTROLITES!"  
    rcall LCD_LINE2
    ldi ZH, high(WELCOME_LINE2*2)
    ldi ZL, low(WELCOME_LINE2*2)
    rcall LCD_PRINT_STRING
    
    ; Keep message displayed for 2 seconds
    rcall DELAY_2S
    
    ret

DISPLAY_DISTANCE:
    ; Display current distance on LCD
    rcall LCD_CLEAR
    
    ; Display "Distance: "
    ldi ZH, high(DISTANCE_MSG*2)
    ldi ZL, low(DISTANCE_MSG*2)
    rcall LCD_PRINT_STRING
    
    ; Convert distance to ASCII and display
    mov temp, distance_low
    rcall DISPLAY_NUMBER
    
    ; Display "cm"
    ldi ZH, high(CM_MSG*2)
    ldi ZL, low(CM_MSG*2)
    rcall LCD_PRINT_STRING
    
    ret

DISPLAY_NUMBER:
    ; Convert number in temp to ASCII and display
    ; Simple 2-digit display (0-99)
    
    clr temp2                   ; Tens counter
    
COUNT_TENS:
    cpi temp, 10
    brlo DISPLAY_DIGITS
    subi temp, 10
    inc temp2
    rjmp COUNT_TENS
    
DISPLAY_DIGITS:
    ; Display tens digit
    mov r22, temp2
    subi r22, -'0'              ; Convert to ASCII
    rcall LCD_SEND_DATA
    
    ; Display units digit
    subi temp, -'0'             ; Convert to ASCII
    rcall LCD_SEND_DATA
    
    ret

; ====================================================================
; LCD CONTROL ROUTINES
; ====================================================================
LCD_INIT:
    rcall DELAY_20MS            ; Wait for LCD to stabilize
    
    ; Initialize in 4-bit mode
    ldi temp, 0x02              ; Function set: 4-bit mode
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x28              ; Function set: 4-bit, 2 lines, 5x8 font
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x0C              ; Display ON, cursor OFF
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x06              ; Entry mode: increment cursor
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x01              ; Clear display
    rcall LCD_SEND_COMMAND
    
    rcall DELAY_2MS
    
    ret

LCD_SEND_COMMAND:
    rcall LCD_SEND_BYTE
    ret

LCD_SEND_DATA:
    sbi PORTA, 0                ; RS = 1 for data
    rcall LCD_SEND_BYTE
    cbi PORTA, 0                ; RS = 0
    ret

LCD_SEND_BYTE:
    ; Send upper nibble
    mov temp2, temp
    swap temp2                  ; Swap nibbles
    andi temp2, 0x0F           ; Mask lower nibble
    
    ; Clear data pins
    cbi PORTC, 4
    cbi PORTC, 5
    cbi PORTC, 6
    cbi PORTC, 7
    
    ; Set data pins based on upper nibble
    sbrc temp2, 0
    sbi PORTC, 4
    sbrc temp2, 1
    sbi PORTC, 5
    sbrc temp2, 2
    sbi PORTC, 6
    sbrc temp2, 3
    sbi PORTC, 7
    
    ; Pulse EN
    sbi PORTA, 1
    rcall DELAY_1MS
    cbi PORTA, 1
    rcall DELAY_1MS
    
    ; Send lower nibble
    andi temp, 0x0F            ; Mask upper nibble
    
    ; Clear data pins
    cbi PORTC, 4
    cbi PORTC, 5
    cbi PORTC, 6
    cbi PORTC, 7
    
    ; Set data pins based on lower nibble
    sbrc temp, 0
    sbi PORTC, 4
    sbrc temp, 1
    sbi PORTC, 5
    sbrc temp, 2
    sbi PORTC, 6
    sbrc temp, 3
    sbi PORTC, 7
    
    ; Pulse EN
    sbi PORTA, 1
    rcall DELAY_1MS
    cbi PORTA, 1
    rcall DELAY_1MS
    
    ret

LCD_CLEAR:
    ldi temp, 0x01
    rcall LCD_SEND_COMMAND
    rcall DELAY_2MS
    ret

LCD_LINE2:
    ldi temp, 0xC0              ; Move cursor to line 2
    rcall LCD_SEND_COMMAND
    ret

LCD_PRINT_STRING:
    ; Print string pointed by Z register (program memory)
LCD_PRINT_LOOP:
    lpm temp, Z+                ; Load character from program memory
    cpi temp, 0                 ; Check for null terminator
    breq LCD_PRINT_END
    rcall LCD_SEND_DATA
    rjmp LCD_PRINT_LOOP
LCD_PRINT_END:
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_10US:
    ; Delay ~10 microseconds at 16MHz
    ldi temp, 53
DELAY_10US_LOOP:
    dec temp
    brne DELAY_10US_LOOP
    ret

DELAY_1MS:
    ; Delay ~1 millisecond
    push r22
    ldi r22, 250
DELAY_1MS_OUTER:
    ldi temp, 16
DELAY_1MS_INNER:
    dec temp
    brne DELAY_1MS_INNER
    dec r22
    brne DELAY_1MS_OUTER
    pop r22
    ret

DELAY_2MS:
    rcall DELAY_1MS
    rcall DELAY_1MS
    ret

DELAY_20MS:
    push r23
    ldi r23, 20
DELAY_20MS_LOOP:
    rcall DELAY_1MS
    dec r23
    brne DELAY_20MS_LOOP
    pop r23
    ret

DELAY_100MS:
    push r23
    ldi r23, 100
DELAY_100MS_LOOP:
    rcall DELAY_1MS
    dec r23
    brne DELAY_100MS_LOOP
    pop r23
    ret

DELAY_2S:
    push r24
    ldi r24, 20
DELAY_2S_LOOP:
    rcall DELAY_100MS
    dec r24
    brne DELAY_2S_LOOP
    pop r24
    ret

; ====================================================================
; INTERRUPT SERVICE ROUTINES
; ====================================================================
EXT_INT0_ISR:
    reti

EXT_INT1_ISR:
    reti

ECHO_ISR:
    ; Echo pin interrupt (not used in polling method)
    reti

; ====================================================================
; STRING CONSTANTS (Program Memory)
; ====================================================================
STARTUP_MSG:
    .db "Ultrasonic Detector", 0

READY_MSG:
    .db "Ready...", 0

SCANNING_MSG:
    .db "Scanning...", 0

WELCOME_LINE1:
    .db "WELCOME TO", 0

WELCOME_LINE2:
    .db "ELECTROLITES!", 0

DISTANCE_MSG:
    .db "Distance: ", 0

CM_MSG:
    .db "cm", 0

; ====================================================================
; END OF PROGRAM
; ====================================================================
