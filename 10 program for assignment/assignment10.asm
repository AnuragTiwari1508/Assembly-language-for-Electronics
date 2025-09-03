; ====================================================================
; ASSIGNMENT 10: ADVANCED DATA LOGGER WITH EEPROM STORAGE
; ====================================================================
; Description: Multi-sensor data logger with EEPROM storage and serial communication
; Hardware: ATmega32 + Temperature Sensor + Light Sensor + EEPROM + UART
; Difficulty: Expert Level
; Learning Objective: EEPROM operations, UART communication, data logging, sensors
; Author: Assembly Language Course
; Date: September 2025
; ====================================================================

.include "m32def.inc"

; ====================================================================
; HARDWARE CONNECTIONS
; ====================================================================
; Temperature Sensor (LM35):
;   OUT     → PA0/ADC0 (Pin 40)
;   VCC     → 5V
;   GND     → GND
;
; Light Sensor (LDR):
;   LDR     → PA1/ADC1 (Pin 39) and VCC through 10kΩ
;   PA1     → GND through 10kΩ (voltage divider)
;
; EEPROM (24C256 or internal):
;   SDA     → PC1/SDA (Pin 15)
;   SCL     → PC0/SCL (Pin 14)
;   VCC     → 5V
;   GND     → GND
;
; UART Communication:
;   TXD     → PD1 (Pin 15) - to computer/display
;   RXD     → PD0 (Pin 14) - from computer
;
; Status Display:
;   LCD RS  → PB0 (Pin 1)
;   LCD EN  → PB1 (Pin 2)
;   LCD D4-D7 → PB4-PB7 (Pins 5,6,7,8)
;
; Control Buttons:
;   START/STOP → PD2 (Pin 16) with pull-up
;   VIEW DATA  → PD3 (Pin 17) with pull-up
;
; Status LEDs:
;   POWER      → PC2 (Pin 16) - Green
;   LOGGING    → PC3 (Pin 17) - Blue
;   ERROR      → PC4 (Pin 18) - Red
;
; ATmega32 Setup:
;   VCC     → 5V regulated
;   GND     → GND
;   AVCC    → 5V with filtering
;   AREF    → 5V with 100nF capacitor
;   RESET   → 10kΩ to VCC
;   XTAL1   → 16MHz Crystal + 22pF to GND
;   XTAL2   → 16MHz Crystal + 22pF to GND
; ====================================================================

.equ F_CPU = 16000000       ; 16MHz Crystal
.equ BAUD = 9600           ; UART baud rate
.equ UBRR_VALUE = (F_CPU/16/BAUD-1) ; UART baud rate register value

; System States
.equ STATE_IDLE = 0         ; System idle, ready to start
.equ STATE_LOGGING = 1      ; Actively logging data
.equ STATE_VIEWING = 2      ; Displaying logged data
.equ STATE_TRANSMITTING = 3 ; Sending data via UART

; EEPROM Addresses
.equ EEPROM_START = 0x0000  ; Start of data storage
.equ EEPROM_SIZE = 1024     ; Total EEPROM size (1KB)
.equ RECORD_SIZE = 8        ; Size of each data record (timestamp + temp + light + checksum)
.equ MAX_RECORDS = (EEPROM_SIZE/RECORD_SIZE) ; Maximum number of records

; Button Definitions
.equ BTN_START_STOP = 2     ; PD2
.equ BTN_VIEW_DATA = 3      ; PD3

; LED Definitions  
.equ LED_POWER = 2          ; PC2
.equ LED_LOGGING = 3        ; PC3
.equ LED_ERROR = 4          ; PC4

; Register Definitions
.def temp = r16             ; Temporary register
.def temp2 = r17            ; Second temporary
.def system_state = r18     ; Current system state
.def log_counter = r19      ; Number of logged records
.def current_temp = r20     ; Current temperature reading
.def current_light = r21    ; Current light level reading
.def eeprom_addr_low = r22  ; EEPROM address low byte
.def eeprom_addr_high = r23 ; EEPROM address high byte
.def timestamp_low = r24    ; Timestamp low byte
.def timestamp_high = r25   ; Timestamp high byte

; ====================================================================
; INTERRUPT VECTORS
; ====================================================================
.org 0x0000
    rjmp MAIN               ; Reset
.org 0x0004
    rjmp EXT_INT0_ISR       ; External interrupt 0 (Start/Stop button)
.org 0x0006  
    rjmp EXT_INT1_ISR       ; External interrupt 1 (View data button)
.org 0x0016
    rjmp TIMER0_OVF_ISR     ; Timer0 overflow (logging interval)
.org 0x001E
    rjmp USART_RXC_ISR      ; UART receive complete

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
    
    ; Initialize all subsystems
    rcall INIT_PORTS
    rcall INIT_ADC
    rcall INIT_UART
    rcall INIT_TIMER0
    rcall INIT_EXTERNAL_INTERRUPTS
    rcall LCD_INIT
    
    ; Initialize system variables
    ldi system_state, STATE_IDLE
    clr log_counter
    clr timestamp_low
    clr timestamp_high
    
    ; Show startup screen
    rcall DISPLAY_STARTUP
    rcall POWER_ON_SELF_TEST
    
    ; Enable global interrupts
    sei
    
    ; Turn on power LED
    sbi PORTC, LED_POWER

; ====================================================================
; MAIN LOOP
; ====================================================================
MAIN_LOOP:
    ; Handle current system state
    cpi system_state, STATE_IDLE
    breq HANDLE_IDLE_STATE
    
    cpi system_state, STATE_LOGGING
    breq HANDLE_LOGGING_STATE
    
    cpi system_state, STATE_VIEWING
    breq HANDLE_VIEWING_STATE
    
    cpi system_state, STATE_TRANSMITTING
    breq HANDLE_TRANSMIT_STATE
    
    rjmp MAIN_LOOP

; ====================================================================
; STATE HANDLERS
; ====================================================================
HANDLE_IDLE_STATE:
    ; Display idle screen
    rcall DISPLAY_IDLE_STATUS
    
    ; Check for sensor readings to display current values
    rcall READ_ALL_SENSORS
    rcall UPDATE_CURRENT_DISPLAY
    
    ; Small delay
    rcall DELAY_500MS
    
    rjmp MAIN_LOOP

HANDLE_LOGGING_STATE:
    ; Display logging status
    rcall DISPLAY_LOGGING_STATUS
    
    ; Blink logging LED
    rcall BLINK_LOGGING_LED
    
    ; Check if EEPROM is full
    rcall CHECK_EEPROM_CAPACITY
    
    rjmp MAIN_LOOP

HANDLE_VIEWING_STATE:
    ; Display stored data records
    rcall DISPLAY_DATA_RECORDS
    
    ; Allow user to scroll through records
    rcall HANDLE_DATA_NAVIGATION
    
    rjmp MAIN_LOOP

HANDLE_TRANSMIT_STATE:
    ; Transmit all data via UART
    rcall TRANSMIT_ALL_DATA
    
    ; Return to idle state
    ldi system_state, STATE_IDLE
    rjmp MAIN_LOOP

; ====================================================================
; HARDWARE INITIALIZATION
; ====================================================================
INIT_PORTS:
    ; Configure ADC pins as inputs (PA0, PA1)
    cbi DDRA, 0             ; Temperature sensor input
    cbi DDRA, 1             ; Light sensor input
    
    ; Configure LCD pins as outputs (PB0-PB1, PB4-PB7)
    ldi temp, 0xF3          ; PB7-PB4, PB1-PB0 as outputs
    out DDRB, temp
    
    ; Configure LED pins as outputs (PC2-PC4)
    ldi temp, 0x1C          ; PC4-PC2 as outputs
    out DDRC, temp
    
    ; Configure button pins as inputs with pull-ups (PD2-PD3)
    cbi DDRD, BTN_START_STOP
    cbi DDRD, BTN_VIEW_DATA
    sbi PORTD, BTN_START_STOP ; Enable pull-up
    sbi PORTD, BTN_VIEW_DATA  ; Enable pull-up
    
    ; Configure UART pins
    sbi DDRD, 1             ; TXD as output
    cbi DDRD, 0             ; RXD as input
    
    ret

INIT_ADC:
    ; Configure ADC for temperature and light sensors
    ; AVCC reference, right-adjusted result
    ldi temp, (1<<REFS0)
    out ADMUX, temp
    
    ; Enable ADC, prescaler 128 (125kHz @ 16MHz)
    ldi temp, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    out ADCSRA, temp
    
    ret

INIT_UART:
    ; Set baud rate
    ldi temp, high(UBRR_VALUE)
    out UBRRH, temp
    ldi temp, low(UBRR_VALUE)
    out UBRRL, temp
    
    ; Enable transmitter and receiver, enable RX interrupt
    ldi temp, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)
    out UCSRB, temp
    
    ; Set frame format: 8 data bits, 1 stop bit, no parity
    ldi temp, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
    out UCSRC, temp
    
    ret

INIT_TIMER0:
    ; Configure Timer0 for logging intervals (every 10 seconds)
    ; Prescaler 1024, overflow interrupt
    ldi temp, (1<<CS02)|(1<<CS00)
    out TCCR0, temp
    
    ; Enable overflow interrupt
    ldi temp, (1<<TOIE0)
    out TIMSK, temp
    
    ret

INIT_EXTERNAL_INTERRUPTS:
    ; Configure INT0 and INT1 for falling edge (button press)
    ldi temp, (1<<ISC01)|(1<<ISC11)
    out MCUCR, temp
    
    ; Enable external interrupts
    ldi temp, (1<<INT0)|(1<<INT1)
    out GICR, temp
    
    ret

; ====================================================================
; SENSOR READING FUNCTIONS
; ====================================================================
READ_ALL_SENSORS:
    rcall READ_TEMPERATURE
    rcall READ_LIGHT_LEVEL
    ret

READ_TEMPERATURE:
    ; Select ADC0 for temperature sensor
    ldi temp, (1<<REFS0)    ; ADC0, AVCC reference
    out ADMUX, temp
    
    ; Start conversion
    sbi ADCSRA, ADSC
    
    ; Wait for completion
TEMP_ADC_WAIT:
    sbic ADCSRA, ADSC
    rjmp TEMP_ADC_WAIT
    
    ; Read result and convert to temperature
    in temp, ADCL           ; Read low byte first
    in temp2, ADCH          ; Read high byte
    
    ; Convert to temperature (LM35: 10mV/°C, 5V ref, 10-bit ADC)
    ; Temperature = (ADC * 5000mV) / (1024 * 10mV/°C) = ADC * 0.488
    ; Simplified: Temperature ≈ ADC / 2
    
    lsr temp2               ; Divide by 2
    ror temp
    
    mov current_temp, temp
    ret

READ_LIGHT_LEVEL:
    ; Select ADC1 for light sensor
    ldi temp, (1<<REFS0)|(1<<MUX0) ; ADC1, AVCC reference
    out ADMUX, temp
    
    ; Start conversion
    sbi ADCSRA, ADSC
    
    ; Wait for completion
LIGHT_ADC_WAIT:
    sbic ADCSRA, ADSC
    rjmp LIGHT_ADC_WAIT
    
    ; Read result
    in temp, ADCL
    in temp2, ADCH
    
    ; Convert to light level (0-100%)
    ; Light% = (ADC * 100) / 1023 ≈ ADC / 10
    
    ; Simple division by 10
    lsr temp2
    ror temp
    lsr temp2
    ror temp
    lsr temp2
    ror temp                ; Divide by 8 (close to 10)
    
    mov current_light, temp
    ret

; ====================================================================
; DATA LOGGING FUNCTIONS
; ====================================================================
LOG_DATA_RECORD:
    ; Create and store a complete data record
    
    ; Read current sensor values
    rcall READ_ALL_SENSORS
    
    ; Calculate EEPROM address for current record
    rcall CALCULATE_EEPROM_ADDRESS
    
    ; Write timestamp
    rcall EEPROM_WRITE_BYTE_AT_ADDR
    mov temp, timestamp_low
    rcall EEPROM_WRITE_BYTE
    
    rcall INCREMENT_EEPROM_ADDR
    mov temp, timestamp_high
    rcall EEPROM_WRITE_BYTE
    
    ; Write temperature
    rcall INCREMENT_EEPROM_ADDR
    mov temp, current_temp
    rcall EEPROM_WRITE_BYTE
    
    ; Write light level
    rcall INCREMENT_EEPROM_ADDR
    mov temp, current_light
    rcall EEPROM_WRITE_BYTE
    
    ; Calculate and write checksum
    rcall CALCULATE_RECORD_CHECKSUM
    rcall INCREMENT_EEPROM_ADDR
    rcall EEPROM_WRITE_BYTE
    
    ; Increment record counter and timestamp
    inc log_counter
    inc timestamp_low
    brne LOG_TIMESTAMP_DONE
    inc timestamp_high
    
LOG_TIMESTAMP_DONE:
    ret

CALCULATE_EEPROM_ADDRESS:
    ; Calculate address = EEPROM_START + (log_counter * RECORD_SIZE)
    clr eeprom_addr_high
    mov eeprom_addr_low, log_counter
    
    ; Multiply by RECORD_SIZE (8) - left shift 3 times
    lsl eeprom_addr_low
    rol eeprom_addr_high
    lsl eeprom_addr_low
    rol eeprom_addr_high
    lsl eeprom_addr_low
    rol eeprom_addr_high
    
    ; Add EEPROM_START offset
    ldi temp, low(EEPROM_START)
    add eeprom_addr_low, temp
    ldi temp, high(EEPROM_START)
    adc eeprom_addr_high, temp
    
    ret

INCREMENT_EEPROM_ADDR:
    ; Increment EEPROM address
    inc eeprom_addr_low
    brne ADDR_INC_DONE
    inc eeprom_addr_high
ADDR_INC_DONE:
    ret

CALCULATE_RECORD_CHECKSUM:
    ; Simple checksum = timestamp_low XOR timestamp_high XOR temp XOR light
    mov temp, timestamp_low
    eor temp, timestamp_high
    eor temp, current_temp
    eor temp, current_light
    ret

CHECK_EEPROM_CAPACITY:
    ; Check if EEPROM is getting full
    cpi log_counter, (MAX_RECORDS-10) ; Warn when 10 records left
    brlo CAPACITY_OK
    
    ; Show warning
    rcall DISPLAY_MEMORY_WARNING
    
    ; Check if completely full
    cpi log_counter, MAX_RECORDS
    brlo CAPACITY_OK
    
    ; Memory full - stop logging
    ldi system_state, STATE_IDLE
    cbi PORTC, LED_LOGGING
    sbi PORTC, LED_ERROR
    
CAPACITY_OK:
    ret

; ====================================================================
; EEPROM FUNCTIONS
; ====================================================================
EEPROM_WRITE_BYTE_AT_ADDR:
    ; Write byte to EEPROM at specified address
    ; Address already in eeprom_addr_high:eeprom_addr_low
    ; Data in temp
    
    ; Wait for previous write to complete
EEPROM_WRITE_WAIT:
    sbic EECR, EEWE
    rjmp EEPROM_WRITE_WAIT
    
    ; Set address
    out EEARH, eeprom_addr_high
    out EEARL, eeprom_addr_low
    
    ; Set data
    out EEDR, temp
    
    ; Start write sequence
    sbi EECR, EEMWE         ; Master write enable
    sbi EECR, EEWE          ; Write enable
    
    ret

EEPROM_WRITE_BYTE:
    ; Write byte to EEPROM (address already set)
    out EEDR, temp
    sbi EECR, EEMWE
    sbi EECR, EEWE
    ret

EEPROM_READ_BYTE:
    ; Read byte from EEPROM at current address
    ; Returns data in temp
    
    ; Wait for previous operation
EEPROM_READ_WAIT:
    sbic EECR, EEWE
    rjmp EEPROM_READ_WAIT
    
    ; Set address
    out EEARH, eeprom_addr_high
    out EEARL, eeprom_addr_low
    
    ; Start read
    sbi EECR, EERE
    
    ; Read data
    in temp, EEDR
    
    ret

; ====================================================================
; UART COMMUNICATION
; ====================================================================
UART_SEND_BYTE:
    ; Send byte in temp via UART
UART_SEND_WAIT:
    sbis UCSRA, UDRE        ; Wait for transmit buffer empty
    rjmp UART_SEND_WAIT
    
    out UDR, temp           ; Send data
    ret

UART_SEND_STRING:
    ; Send string pointed by Z register
UART_STRING_LOOP:
    lpm temp, Z+
    tst temp
    breq UART_STRING_DONE
    rcall UART_SEND_BYTE
    rjmp UART_STRING_LOOP
UART_STRING_DONE:
    ret

TRANSMIT_ALL_DATA:
    ; Transmit all logged data via UART
    ldi ZH, high(DATA_HEADER*2)
    ldi ZL, low(DATA_HEADER*2)
    rcall UART_SEND_STRING
    
    ; Transmit record count
    mov temp, log_counter
    rcall UART_SEND_DECIMAL
    
    ; Send newline
    ldi temp, 13            ; CR
    rcall UART_SEND_BYTE
    ldi temp, 10            ; LF
    rcall UART_SEND_BYTE
    
    ; Transmit each record
    clr r26                 ; Record index
    
TRANSMIT_RECORD_LOOP:
    cp r26, log_counter
    brsh TRANSMIT_DONE
    
    ; Calculate address for this record
    mov log_counter, r26    ; Temporarily use for address calc
    rcall CALCULATE_EEPROM_ADDRESS
    
    ; Read and transmit record data
    rcall TRANSMIT_SINGLE_RECORD
    
    ; Next record
    inc r26
    rjmp TRANSMIT_RECORD_LOOP
    
TRANSMIT_DONE:
    mov log_counter, r26    ; Restore log counter
    
    ; Send end marker
    ldi ZH, high(DATA_END*2)
    ldi ZL, low(DATA_END*2)
    rcall UART_SEND_STRING
    
    ret

TRANSMIT_SINGLE_RECORD:
    ; Transmit one data record from EEPROM
    
    ; Read timestamp
    rcall EEPROM_READ_BYTE
    rcall UART_SEND_DECIMAL
    ldi temp, ','
    rcall UART_SEND_BYTE
    
    rcall INCREMENT_EEPROM_ADDR
    rcall EEPROM_READ_BYTE
    rcall UART_SEND_DECIMAL
    ldi temp, ','
    rcall UART_SEND_BYTE
    
    ; Read temperature
    rcall INCREMENT_EEPROM_ADDR
    rcall EEPROM_READ_BYTE
    rcall UART_SEND_DECIMAL
    ldi temp, ','
    rcall UART_SEND_BYTE
    
    ; Read light level
    rcall INCREMENT_EEPROM_ADDR
    rcall EEPROM_READ_BYTE
    rcall UART_SEND_DECIMAL
    
    ; Skip checksum byte
    rcall INCREMENT_EEPROM_ADDR
    
    ; Send newline
    ldi temp, 13
    rcall UART_SEND_BYTE
    ldi temp, 10
    rcall UART_SEND_BYTE
    
    ret

UART_SEND_DECIMAL:
    ; Convert temp to decimal and send via UART
    push r27
    push r28
    
    clr r27                 ; Hundreds
    clr r28                 ; Tens
    
    ; Count hundreds
UART_DEC_HUNDREDS:
    cpi temp, 100
    brlo UART_DEC_TENS_START
    subi temp, 100
    inc r27
    rjmp UART_DEC_HUNDREDS
    
UART_DEC_TENS_START:
    ; Count tens
UART_DEC_TENS:
    cpi temp, 10
    brlo UART_DEC_SEND
    subi temp, 10
    inc r28
    rjmp UART_DEC_TENS
    
UART_DEC_SEND:
    ; Send hundreds (if non-zero)
    tst r27
    breq UART_DEC_SKIP_HUNDREDS
    
    subi r27, -'0'
    mov temp, r27
    rcall UART_SEND_BYTE
    
UART_DEC_SKIP_HUNDREDS:
    ; Send tens
    subi r28, -'0'
    mov temp, r28
    rcall UART_SEND_BYTE
    
    ; Send units
    subi temp, -'0'
    rcall UART_SEND_BYTE
    
    pop r28
    pop r27
    ret

; ====================================================================
; DISPLAY FUNCTIONS
; ====================================================================
DISPLAY_STARTUP:
    rcall LCD_CLEAR
    ldi ZH, high(STARTUP_TITLE*2)
    ldi ZL, low(STARTUP_TITLE*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(VERSION_INFO*2)
    ldi ZL, low(VERSION_INFO*2)
    rcall LCD_PRINT_STRING
    
    rcall DELAY_2S
    ret

POWER_ON_SELF_TEST:
    ; Perform basic self-test
    rcall LCD_CLEAR
    ldi ZH, high(SELFTEST_MSG*2)
    ldi ZL, low(SELFTEST_MSG*2)
    rcall LCD_PRINT_STRING
    
    ; Test LEDs
    sbi PORTC, LED_POWER
    rcall DELAY_200MS
    sbi PORTC, LED_LOGGING
    rcall DELAY_200MS
    sbi PORTC, LED_ERROR
    rcall DELAY_200MS
    
    ; Turn off test LEDs
    cbi PORTC, LED_LOGGING
    cbi PORTC, LED_ERROR
    
    ; Test sensors
    rcall READ_ALL_SENSORS
    
    rcall LCD_LINE2
    ldi ZH, high(SELFTEST_OK*2)
    ldi ZL, low(SELFTEST_OK*2)
    rcall LCD_PRINT_STRING
    
    rcall DELAY_1S
    ret

DISPLAY_IDLE_STATUS:
    rcall LCD_CLEAR
    ldi ZH, high(IDLE_MSG*2)
    ldi ZL, low(IDLE_MSG*2)
    rcall LCD_PRINT_STRING
    
    ; Show record count
    ldi ZH, high(RECORDS_MSG*2)
    ldi ZL, low(RECORDS_MSG*2)
    rcall LCD_PRINT_STRING
    
    mov temp, log_counter
    rcall LCD_SEND_DECIMAL
    
    ret

DISPLAY_LOGGING_STATUS:
    rcall LCD_CLEAR
    ldi ZH, high(LOGGING_MSG*2)
    ldi ZL, low(LOGGING_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(RECORD_NUM_MSG*2)
    ldi ZL, low(RECORD_NUM_MSG*2)
    rcall LCD_PRINT_STRING
    
    mov temp, log_counter
    rcall LCD_SEND_DECIMAL
    
    ret

UPDATE_CURRENT_DISPLAY:
    rcall LCD_LINE2
    
    ; Display temperature
    ldi ZH, high(TEMP_PREFIX*2)
    ldi ZL, low(TEMP_PREFIX*2)
    rcall LCD_PRINT_STRING
    
    mov temp, current_temp
    rcall LCD_SEND_DECIMAL
    
    ldi temp, 'C'
    rcall LCD_SEND_DATA
    ldi temp, ' '
    rcall LCD_SEND_DATA
    
    ; Display light level
    ldi ZH, high(LIGHT_PREFIX*2)
    ldi ZL, low(LIGHT_PREFIX*2)
    rcall LCD_PRINT_STRING
    
    mov temp, current_light
    rcall LCD_SEND_DECIMAL
    
    ldi temp, '%'
    rcall LCD_SEND_DATA
    
    ret

DISPLAY_DATA_RECORDS:
    ; Display stored data records on LCD
    ; (Implementation would show scrollable record view)
    rcall LCD_CLEAR
    ldi ZH, high(VIEWING_DATA_MSG*2)
    ldi ZL, low(VIEWING_DATA_MSG*2)
    rcall LCD_PRINT_STRING
    
    ; Show total records
    rcall LCD_LINE2
    mov temp, log_counter
    rcall LCD_SEND_DECIMAL
    ldi ZH, high(TOTAL_RECORDS_MSG*2)
    ldi ZL, low(TOTAL_RECORDS_MSG*2)
    rcall LCD_PRINT_STRING
    
    ret

DISPLAY_MEMORY_WARNING:
    rcall LCD_CLEAR
    ldi ZH, high(MEMORY_WARNING_MSG*2)
    ldi ZL, low(MEMORY_WARNING_MSG*2)
    rcall LCD_PRINT_STRING
    
    rcall LCD_LINE2
    ldi ZH, high(MEMORY_WARNING2_MSG*2)
    ldi ZL, low(MEMORY_WARNING2_MSG*2)
    rcall LCD_PRINT_STRING
    
    ret

HANDLE_DATA_NAVIGATION:
    ; Handle navigation through stored data
    ; (Simplified - would implement scrolling through records)
    rcall DELAY_1S
    ret

; ====================================================================
; LED CONTROL
; ====================================================================
BLINK_LOGGING_LED:
    ; Blink the logging LED
    static_counter_blink: .byte 1
    
    lds temp, static_counter_blink
    inc temp
    sts static_counter_blink, temp
    
    andi temp, 0x0F         ; Blink every 16 cycles
    brne BLINK_DONE
    
    ; Toggle logging LED
    in temp, PORTC
    ldi temp2, (1<<LED_LOGGING)
    eor temp, temp2
    out PORTC, temp
    
BLINK_DONE:
    ret

; ====================================================================
; INTERRUPT SERVICE ROUTINES
; ====================================================================
EXT_INT0_ISR:
    ; Start/Stop button pressed
    push temp
    in temp, SREG
    push temp
    
    ; Toggle between idle and logging states
    cpi system_state, STATE_IDLE
    breq START_LOGGING
    
    cpi system_state, STATE_LOGGING
    breq STOP_LOGGING
    
    rjmp EXT_INT0_DONE
    
START_LOGGING:
    ldi system_state, STATE_LOGGING
    sbi PORTC, LED_LOGGING
    rjmp EXT_INT0_DONE
    
STOP_LOGGING:
    ldi system_state, STATE_IDLE
    cbi PORTC, LED_LOGGING
    
EXT_INT0_DONE:
    ; Debounce delay
    rcall DELAY_50MS
    
    pop temp
    out SREG, temp
    pop temp
    reti

EXT_INT1_ISR:
    ; View data button pressed
    push temp
    in temp, SREG
    push temp
    
    ; Switch to viewing state
    ldi system_state, STATE_VIEWING
    
    ; Debounce delay
    rcall DELAY_50MS
    
    pop temp
    out SREG, temp
    pop temp
    reti

TIMER0_OVF_ISR:
    ; Timer overflow - log data if in logging state
    push temp
    in temp, SREG
    push temp
    
    ; Check if we're in logging state
    cpi system_state, STATE_LOGGING
    brne TIMER0_DONE
    
    ; Log a data record
    rcall LOG_DATA_RECORD
    
TIMER0_DONE:
    pop temp
    out SREG, temp
    pop temp
    reti

USART_RXC_ISR:
    ; UART receive interrupt
    push temp
    in temp, SREG
    push temp
    
    ; Read received character
    in temp, UDR
    
    ; Check for commands
    cpi temp, 'D'           ; Download data command
    breq CMD_DOWNLOAD
    
    cpi temp, 'R'           ; Reset command
    breq CMD_RESET
    
    rjmp USART_DONE
    
CMD_DOWNLOAD:
    ldi system_state, STATE_TRANSMITTING
    rjmp USART_DONE
    
CMD_RESET:
    ; Reset system
    clr log_counter
    ldi system_state, STATE_IDLE
    
USART_DONE:
    pop temp
    out SREG, temp
    pop temp
    reti

; ====================================================================
; LCD FUNCTIONS (Simplified Implementation)
; ====================================================================
LCD_INIT:
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
    cbi PORTB, 0            ; RS = 0
    rcall LCD_WRITE_NIBBLES
    ret

LCD_SEND_DATA:
    sbi PORTB, 0            ; RS = 1
    rcall LCD_WRITE_NIBBLES
    cbi PORTB, 0
    ret

LCD_WRITE_NIBBLES:
    push temp2
    
    ; Upper nibble to PB7-PB4
    mov temp2, temp
    swap temp2
    andi temp2, 0xF0
    
    in r0, PORTB
    andi r0, 0x0F
    or r0, temp2
    out PORTB, r0
    
    sbi PORTB, 1            ; EN high
    rcall DELAY_1MS
    cbi PORTB, 1            ; EN low
    
    ; Lower nibble to PB7-PB4
    andi temp, 0x0F
    swap temp
    
    in r0, PORTB
    andi r0, 0x0F
    or r0, temp
    out PORTB, r0
    
    sbi PORTB, 1            ; EN high
    rcall DELAY_1MS
    cbi PORTB, 1            ; EN low
    
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
    breq LCD_PRINT_DONE
    rcall LCD_SEND_DATA
    rjmp LCD_PRINT_LOOP
LCD_PRINT_DONE:
    ret

LCD_SEND_DECIMAL:
    ; Convert temp to decimal and display on LCD
    push r29
    push r30
    
    clr r29                 ; Tens
    clr r30                 ; Units counter
    
    ; Count tens
LCD_DEC_TENS_LOOP:
    cpi temp, 10
    brlo LCD_DEC_DISPLAY
    subi temp, 10
    inc r29
    rjmp LCD_DEC_TENS_LOOP
    
LCD_DEC_DISPLAY:
    ; Display tens (if > 0)
    tst r29
    breq LCD_DEC_UNITS
    
    subi r29, -'0'
    mov r30, temp           ; Save units
    mov temp, r29
    rcall LCD_SEND_DATA
    mov temp, r30           ; Restore units
    
LCD_DEC_UNITS:
    ; Display units
    subi temp, -'0'
    rcall LCD_SEND_DATA
    
    pop r30
    pop r29
    ret

; ====================================================================
; DELAY ROUTINES
; ====================================================================
DELAY_1MS:
    push r31
    ldi r31, 250
DELAY_1MS_LOOP:
    nop
    nop
    nop
    nop
    dec r31
    brne DELAY_1MS_LOOP
    pop r31
    ret

DELAY_10MS:
    push r31
    ldi r31, 10
DELAY_10MS_LOOP:
    rcall DELAY_1MS
    dec r31
    brne DELAY_10MS_LOOP
    pop r31
    ret

DELAY_50MS:
    push r31
    ldi r31, 50
DELAY_50MS_LOOP:
    rcall DELAY_1MS
    dec r31
    brne DELAY_50MS_LOOP
    pop r31
    ret

DELAY_200MS:
    rcall DELAY_50MS
    rcall DELAY_50MS
    rcall DELAY_50MS
    rcall DELAY_50MS
    ret

DELAY_500MS:
    rcall DELAY_200MS
    rcall DELAY_200MS
    rcall DELAY_100MS
    ret

DELAY_100MS:
    rcall DELAY_50MS
    rcall DELAY_50MS
    ret

DELAY_1S:
    rcall DELAY_500MS
    rcall DELAY_500MS
    ret

DELAY_2S:
    rcall DELAY_1S
    rcall DELAY_1S
    ret

; ====================================================================
; STRING CONSTANTS
; ====================================================================
STARTUP_TITLE:
    .db "Data Logger v2.0", 0

VERSION_INFO:
    .db "Multi-Sensor", 0

SELFTEST_MSG:
    .db "Self Test...", 0

SELFTEST_OK:
    .db "System Ready", 0

IDLE_MSG:
    .db "Ready to Log ", 0

RECORDS_MSG:
    .db "Recs:", 0

LOGGING_MSG:
    .db "Logging Data...", 0

RECORD_NUM_MSG:
    .db "Record #", 0

VIEWING_DATA_MSG:
    .db "Data Review", 0

TOTAL_RECORDS_MSG:
    .db " Total Records", 0

MEMORY_WARNING_MSG:
    .db "Memory Warning!", 0

MEMORY_WARNING2_MSG:
    .db "Space Low", 0

TEMP_PREFIX:
    .db "T:", 0

LIGHT_PREFIX:
    .db " L:", 0

DATA_HEADER:
    .db "DATA LOG START", 13, 10, "Records: ", 0

DATA_END:
    .db "DATA LOG END", 13, 10, 0

; ====================================================================
; END OF PROGRAM
; ====================================================================
