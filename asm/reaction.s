;====================================================================
; File:   reaction.s
; Author: cstep
;
; PIC10F200 Reaction Game
;
; Description:
;   Single-button reaction-timer: a Yellow ready cue arms the player.
;   A short pre-start wait follows; pressing during the wait shows Red
;   (false start) and restarts. When Green lights, a 1s window counts in
;   4 ms steps until the button (GP3, active-low) is pressed. Fast /
;   medium / slow feedback is shown on Green / Yellow / Red. Timing is
;   tuned for the 4 MHz internal RC.
;
; Device: PIC10F200 (8-pin PDIP)
; Compiler: pic-as (v3.10)
;
; Pin Configuration:
;   Pin 1 (N/C)  - Not Connected
;   Pin 2 (VDD)  - +5V Power
;   Pin 3 (GP2)  - Red LED output (with current-limiting resistor)
;   Pin 4 (GP1)  - Yellow LED output (with current-limiting resistor)
;   Pin 5 (GP0)  - Green LED output (with current-limiting resistor)
;   Pin 6 (N/C)  - Not Connected
;   Pin 7 (VSS)  - Ground
;   Pin 8 (GP3)  - Button input (active-low, external pull-up to VDD)
;====================================================================

    processor 10F200
    #include <xc.inc>

;====================================================================
;  CONFIGURATION BITS
;====================================================================
    config WDTE = OFF
    config CP   = OFF
    config MCLRE = OFF

;====================================================================
;  RESET VECTOR (placed at 0x000 by linker option)
;
;  IMPORTANT:
;  Use Project Properties -> pic-as Global Options ->
;  Additional Options: -Wl,-presetVec=0h
;
;  This ensures the reset vector goes at 0x000 and does NOT
;  overwrite the calibration word at 0x0FF.
;====================================================================
    psect   resetVec, class=CODE, delta=2

resetVec:
    goto    main

;====================================================================
;  DEFINITIONS
;====================================================================
; STATUS register bit definitions (if not included in xc.inc)
#ifndef C
C               equ 0           ; Carry bit in STATUS register
#endif

;====================================================================
;  VARIABLE DEFINITIONS
;====================================================================
    psect   mainCode, class=CODE, delta=2

; General purpose registers
counter         equ 0x10        ; General counter for delays
wait_counter    equ 0x11        ; Wait counter for false start period
reaction_timer  equ 0x12        ; Reaction time counter
loop_a          equ 0x13        ; Loop counters for delays
loop_b          equ 0x14
loop_c          equ 0x15

;====================================================================
;  MAIN PROGRAM
;====================================================================
main:
    ; Initialize GPIO directions
    movlw   0b00001000      ; GP3 input, GP0/GP1/GP2 outputs
    tris    GPIO
    
    ; Configure OPTION register
    movlw   0b11011111      ; GP2 as GPIO, WDT prescale, weak pulls disabled
    option

game_loop:
    ; Turn off all LEDs
    clrf    GPIO
    
    ; Idle pause between rounds (1000ms)
    call    delay_1000ms
    
    ; Yellow flash (ready cue)
    bsf     GPIO, GPIO_GP1_POSITION     ; Yellow LED ON
    call    delay_1000ms
    clrf    GPIO                        ; All LEDs OFF
    call    delay_1000ms

    ; False-start guard period (~500ms in ~4ms steps)
    movlw   125
    movwf   wait_counter

false_start_check:
    ; Check if button is pressed during wait period
    btfss   GPIO, GPIO_GP3_POSITION     ; Skip if button NOT pressed (GP3 high)
    goto    false_start                 ; Button pressed - false start!
    
    ; Delay ~4ms
    call    delay_4ms
    
    ; Decrement wait counter
    decfsz  wait_counter, f
    goto    false_start_check
    
    ; Wait period completed, start reaction timing
    goto    start_reaction

false_start:
    ; Show red LED for false start
    bcf     GPIO, GPIO_GP0_POSITION     ; Green OFF
    bcf     GPIO, GPIO_GP1_POSITION     ; Yellow OFF  
    bsf     GPIO, GPIO_GP2_POSITION     ; Red ON
    call    delay_300ms
    clrf    GPIO                        ; All LEDs OFF
    call    delay_400ms
    goto    game_loop                   ; Restart round

start_reaction:
    ; Turn on green LED - reaction window starts
    bsf     GPIO, GPIO_GP0_POSITION     ; Green LED ON
    clrf    reaction_timer              ; Reset reaction timer
    
reaction_timing_loop:
    ; Check if button is pressed
    btfss   GPIO, GPIO_GP3_POSITION     ; Skip if button NOT pressed
    goto    button_pressed              ; Button was pressed!
    
    ; Check if timer has reached maximum (250 * 4ms = 1000ms)
    movlw   250
    subwf   reaction_timer, w           ; W = reaction_timer - 250
    btfss   STATUS, C                   ; Skip if carry set (timer >= 250)
    goto    continue_timing             ; Timer still under 250
    
    ; Timeout reached
    goto    show_result

continue_timing:
    ; Increment reaction timer and delay 4ms
    incf    reaction_timer, f
    call    delay_4ms
    goto    reaction_timing_loop

button_pressed:
    ; Button was pressed, turn off all LEDs and settle
    clrf    GPIO
    call    delay_100ms

show_result:
    ; Show result based on reaction time
    ; Fast: < 40 counts (160ms) = Green
    ; Medium: < 80 counts (320ms) = Yellow  
    ; Slow: >= 80 counts = Red
    
    movlw   40
    subwf   reaction_timer, w           ; W = reaction_timer - 40
    btfss   STATUS, C                   ; Skip if carry set (timer >= 40)
    goto    fast_reaction               ; Fast reaction (timer < 40)
    
    movlw   80
    subwf   reaction_timer, w           ; W = reaction_timer - 80
    btfss   STATUS, C                   ; Skip if carry set (timer >= 80)
    goto    medium_reaction             ; Medium reaction (timer < 80)
    
    ; Slow reaction or timeout
    bsf     GPIO, GPIO_GP2_POSITION     ; Red LED ON
    goto    result_delay

fast_reaction:
    bsf     GPIO, GPIO_GP0_POSITION     ; Green LED ON
    goto    result_delay

medium_reaction:
    bsf     GPIO, GPIO_GP1_POSITION     ; Yellow LED ON

result_delay:
    call    delay_1500ms
    clrf    GPIO                        ; All LEDs OFF
    goto    game_loop                   ; Start next round

;====================================================================
;  DELAY ROUTINES
;====================================================================

; Delay approximately 4ms
delay_4ms:
    movlw   4                           ; 4 * 1000 cycles = 4000 cycles
    movwf   loop_a
delay_4ms_outer:
    movlw   249                         ; Inner loop: 249 cycles
    movwf   loop_b
delay_4ms_inner:
    decfsz  loop_b, f                   ; 1 cycle (2 cycles when skip)
    goto    delay_4ms_inner             ; 2 cycles
    decfsz  loop_a, f                   ; 1 cycle (2 cycles when skip)  
    goto    delay_4ms_outer             ; 2 cycles
    retlw   0

; Delay approximately 100ms  
delay_100ms:
    movlw   25                          ; 25 * 4ms = 100ms
    movwf   counter
delay_100ms_loop:
    call    delay_4ms
    decfsz  counter, f
    goto    delay_100ms_loop
    retlw   0

; Delay approximately 300ms
delay_300ms:
    movlw   75                          ; 75 * 4ms = 300ms
    movwf   counter
delay_300ms_loop:
    call    delay_4ms
    decfsz  counter, f
    goto    delay_300ms_loop
    retlw   0

; Delay approximately 400ms
delay_400ms:
    movlw   100                         ; 100 * 4ms = 400ms
    movwf   counter
delay_400ms_loop:
    call    delay_4ms
    decfsz  counter, f
    goto    delay_400ms_loop
    retlw   0

; Delay approximately 1000ms
delay_1000ms:
    movlw   250                         ; 250 * 4ms = 1000ms
    movwf   counter
delay_1000ms_loop:
    call    delay_4ms
    decfsz  counter, f
    goto    delay_1000ms_loop
    retlw   0

; Delay approximately 1500ms
delay_1500ms:
    call    delay_1000ms
    call    delay_400ms
    call    delay_100ms
    retlw   0

;====================================================================
;  END OF PROGRAM
;====================================================================
    end     resetVec


