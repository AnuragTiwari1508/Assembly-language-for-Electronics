; ====================================================================
; ASSIGNMENT 5: TEMPERATURE MONITORING WITH LCD
; ====================================================================
; Description: Read LM35 temperature sensor and display on LCD
; Hardware: ATmega32 + LM35 + 16x2 LCD + ADC
; Difficulty: Intermediate-Advanced
; Learning Objective: ADC, LCD interfacing, temperature calculation, data display
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; LM35 Temperature Sensor:
;   VCC → 5V
;   GND → GND
;   OUT → PA1/ADC1 (Pin 39)
;
; 16x2 LCD Display:
;   VSS     → GND
;   VDD     → 5V
;   V0      → 10kΩ POT (Contrast)
;   RS      → PD0 (Pin 14)
;   EN      → PD1 (Pin 15)
;   D4      → PD4 (Pin 16)
;   D5      → PD5 (Pin 19)
;   D6      → PD6 (Pin 20)
;   D7      → PD7 (Pin 21)
;   A       → 5V (Backlight)
;   K       → GND (Backlight)
;
; ATmega32 Basic Setup:
;   VCC     → 5V
;   GND     → GND
;   AVCC    → 5V (with 10μF capacitor)
;   AREF    → 5V (with 100nF capacitor)
;   RESET   → 10kΩ to VCC
;   XTAL1   → 8MHz Crystal + 22pF to GND
;   XTAL2   → 8MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 8000000    ; 8MHz Crystal

; Register Definitions
.def temp = r16         ; Temporary register
.def temp2 = r17        ; Second temporary register
.def adc_low = r18      ; ADC result low byte
.def adc_high = r19     ; ADC result high byte
.def temperature = r20  ; Temperature value in Celsius
.def tens = r21         ; Temperature tens digit
.def units = r22        ; Temperature units digit

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
    
    ; Initialize LCD
    rcall LCD_INIT
    
    ; Initialize ADC
    rcall ADC_INIT
    
    ; Display startup message
    rcall LCD_CLEAR
    ldi ZH, high(TITLE_MSG*2)
    ldi ZL, low(TITLE_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(STARTUP_MSG*2)
    ldi ZL, low(STARTUP_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall DELAY_2S

; ====================================================================
; MAIN LOOP - TEMPERATURE MONITORING
; ====================================================================
MAIN_LOOP:
    ; Read temperature from LM35
    rcall READ_TEMPERATURE
    
    ; Convert ADC value to temperature
    rcall CONVERT_TO_CELSIUS
    
    ; Display temperature on LCD
    rcall DISPLAY_TEMPERATURE
    
    ; Wait 1 second before next reading
    rcall DELAY_1S
    
    rjmp MAIN_LOOP

; ====================================================================
; ADC INITIALIZATION FOR LM35
; ====================================================================
ADC_INIT:
    ; Configure ADC for LM35 on ADC1 (PA1)
    ; REFS1:0 = 01 (AVCC reference)
    ; MUX4:0 = 00001 (ADC1)
    ldi temp, (1<<REFS0)|(1<<MUX0)
    out ADMUX, temp
    
    ; Enable ADC, prescaler 64 (125kHz ADC clock)
    ldi temp, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)
    out ADCSRA, temp
    
    ret

; ====================================================================
; TEMPERATURE READING
; ====================================================================
READ_TEMPERATURE:
    ; Start ADC conversion
    sbi ADCSRA, ADSC
    
    ; Wait for conversion complete
TEMP_WAIT:
    sbic ADCSRA, ADSC
    rjmp TEMP_WAIT
    
    ; Read ADC result
    in adc_low, ADCL
    in adc_high, ADCH
    
    ret

CONVERT_TO_CELSIUS:
    ; LM35 outputs 10mV per degree Celsius
    ; With 5V reference: ADC = (Temperature * 10mV) / (5000mV / 1024)
    ; Temperature = (ADC * 5000) / (1024 * 10) = ADC * 0.488
    ; Approximation: Temperature ≈ (ADC * 500) / 1024 ≈ ADC / 2
    
    ; Simple conversion: Temperature = ADC_high * 2 + (ADC_low >> 7)
    mov temperature, adc_high
    lsl temperature         ; Multiply by 2
    
    ; Add contribution from low byte (upper bit only)
    mov temp, adc_low
    lsr temp
    lsr temp
    lsr temp
    lsr temp
    lsr temp
    lsr temp
    lsr temp                ; Keep only MSB
    add temperature, temp
    
    ; Limit temperature to reasonable range (0-99°C)
    cpi temperature, 100
    brlo TEMP_OK
    ldi temperature, 99
    
TEMP_OK:
    ret

; ====================================================================
; TEMPERATURE DISPLAY
; ====================================================================
DISPLAY_TEMPERATURE:
    ; Clear LCD and show temperature
    rcall LCD_CLEAR
    
    ; Display "Temperature:"
    ldi ZH, high(TEMP_LABEL*2)
    ldi ZL, low(TEMP_LABEL*2)
    rcall LCD_PRINT_STRING
    
    ; Move to second line
    rcall LCD_LINE2
    
    ; Convert temperature to decimal digits
    clr tens
    mov temp, temperature
    
COUNT_TENS:
    cpi temp, 10
    brlo DISPLAY_DIGITS
    subi temp, 10
    inc tens
    rjmp COUNT_TENS
    
DISPLAY_DIGITS:
    mov units, temp
    
    ; Display tens digit
    mov temp, tens
    subi temp, -'0'         ; Convert to ASCII
    rcall LCD_SEND_DATA
    
    ; Display units digit
    mov temp, units
    subi temp, -'0'         ; Convert to ASCII
    rcall LCD_SEND_DATA
    
    ; Display "°C"
    ldi ZH, high(CELSIUS_MSG*2)
    ldi ZL, low(CELSIUS_MSG*2)
    rcall LCD_PRINT_STRING
    
    ret

; ====================================================================
; LCD CONTROL ROUTINES
; ====================================================================
LCD_INIT:
    ; Configure LCD pins as outputs
    sbi DDRD, 0             ; RS
    sbi DDRD, 1             ; EN
    sbi DDRD, 4             ; D4
    sbi DDRD, 5             ; D5
    sbi DDRD, 6             ; D6
    sbi DDRD, 7             ; D7
    
    ; Wait for LCD to power up
    rcall DELAY_50MS
    
    ; Initialize in 4-bit mode
    ldi temp, 0x02
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x28          ; 4-bit, 2 lines, 5x8 font
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x0C          ; Display ON, cursor OFF
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x06          ; Entry mode: increment cursor
    rcall LCD_SEND_COMMAND
    
    ldi temp, 0x01          ; Clear display
    rcall LCD_SEND_COMMAND
    
    rcall DELAY_10MS
    ret

LCD_SEND_COMMAND:
    cbi PORTD, 0            ; RS = 0 for command
    rcall LCD_SEND_BYTE
    ret

LCD_SEND_DATA:
    sbi PORTD, 0            ; RS = 1 for data
    rcall LCD_SEND_BYTE
    cbi PORTD, 0            ; RS = 0
    ret

LCD_SEND_BYTE:
    ; Send upper nibble
    mov temp2, temp
    swap temp2              ; Swap nibbles
    andi temp2, 0x0F
    
    ; Clear data pins
    andi temp2, 0x0F
    in r23, PORTD
    andi r23, 0x0F          ; Clear upper nibble
    or temp2, r23           ; Combine with lower nibble
    out PORTD, temp2
    
    ; Pulse EN
    sbi PORTD, 1
    rcall DELAY_1MS
    cbi PORTD, 1
    rcall DELAY_1MS
    
    ; Send lower nibble
    andi temp, 0x0F
    in r23, PORTD
    andi r23, 0x0F          ; Clear upper nibble
    swap temp               ; Move to upper nibble
    or temp, r23            ; Combine
    out PORTD, temp
    
    ; Pulse EN
    sbi PORTD, 1
    rcall DELAY_1MS
    cbi PORTD, 1
    rcall DELAY_1MS
    
    ret

LCD_CLEAR:
    ldi temp, 0x01
    rcall LCD_SEND_COMMAND
    rcall DELAY_10MS
    ret

LCD_LINE2:
    ldi temp, 0xC0          ; Move to line 2
    rcall LCD_SEND_COMMAND
    ret

LCD_PRINT_STRING:
    ; Print string from program memory (Z register)
LCD_PRINT_LOOP:
    lpm temp, Z+
    cpi temp, 0
    breq LCD_PRINT_END
    rcall LCD_SEND_DATA
    rjmp LCD_PRINT_LOOP
LCD_PRINT_END:
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_1MS:
    push r24
    ldi r24, 250
DELAY_1MS_LOOP:
    nop
    nop
    nop
    dec r24
    brne DELAY_1MS_LOOP
    pop r24
    ret

DELAY_10MS:
    push r25
    ldi r25, 10
DELAY_10MS_LOOP:
    rcall DELAY_1MS
    dec r25
    brne DELAY_10MS_LOOP
    pop r25
    ret

DELAY_50MS:
    push r25
    ldi r25, 50
DELAY_50MS_LOOP:
    rcall DELAY_1MS
    dec r25
    brne DELAY_50MS_LOOP
    pop r25
    ret

DELAY_1S:
    push r26
    ldi r26, 20
DELAY_1S_LOOP:
    rcall DELAY_50MS
    dec r26
    brne DELAY_1S_LOOP
    pop r26
    ret

DELAY_2S:
    rcall DELAY_1S
    rcall DELAY_1S
    ret

; ====================================================================
; STRING CONSTANTS
; ====================================================================
TITLE_MSG:
    .db "Temperature", 0

STARTUP_MSG:
    .db "Monitor v1.0", 0

TEMP_LABEL:
    .db "Current Temp:", 0

CELSIUS_MSG:
    .db " C", 0

; ====================================================================
; END OF PROGRAM
; ====================================================================
