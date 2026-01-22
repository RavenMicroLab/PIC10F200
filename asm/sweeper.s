;====================================================================
; File:   sweeper.s
; Author: cstep
;
; PIC10F200 Sweeper Game
;
; Description:
;   Single-button timing game: a three-LED sweep moves from
;   Green, Yellow, Red, Yellow, Green in a continuous pattern.
;   Press the button exactly when the sweep is on Green to advance
;   the level and speed up. Three correct hits trigger a win
;   celebration (all LEDs flash). Any miss triggers a red flash
;   and resets the level/speed.
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
Z               equ 2           ; Zero bit in STATUS register
#endif

;====================================================================
;  VARIABLE DEFINITIONS
;====================================================================
    psect   mainCode, class=CODE, delta=2

; General purpose registers
position        equ 0x10        ; Current LED position (0=Green, 1=Yellow, 2=Red, 3=Yellow)
direction       equ 0x11        ; Direction of sweep (0=backward, 1=forward)
level           equ 0x12        ; Current level (0-2, 3 = win)
counter         equ 0x13        ; General counter for delays and loops
loop_a          equ 0x14        ; Loop counters for delays
loop_b          equ 0x15

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

    ; Initialize game variables
    clrf    GPIO            ; All LEDs OFF
    clrf    position        ; Start at position 0 (Green)
    movlw   1
    movwf   direction       ; Start moving forward
    clrf    level           ; Start at level 0

game_loop:
    ; Display LED for current position
    call    show_position
    
    ; Check button press
    call    check_button
    
    ; Move to next position
    call    move_sweep
    
    ; Speed delay based on level
    call    level_delay
    
    goto    game_loop

;====================================================================
;  SHOW POSITION - Display LED for current position
;====================================================================
show_position:
    ; Check if position == 0 (Green)
    movf    position, w
    btfsc   STATUS, Z                   
    goto    show_green                  
    
    ; Check if position == 1 (Yellow)
    movlw   1
    subwf   position, w                 ; W = position - 1
    btfsc   STATUS, Z
    goto    show_yellow                 
    
    ; Check if position == 2 (Red) 
    movlw   2
    subwf   position, w                 ; W = position - 2
    btfsc   STATUS, Z
    goto    show_red                    
    
    ; Position must be 3, show yellow
    goto    show_yellow

show_green:
    movlw   0b00000001                  ; Green LED only (GP0)
    movwf   GPIO
    retlw   0

show_yellow:
    movlw   0b00000010                  ; Yellow LED only (GP1)
    movwf   GPIO
    retlw   0

show_red:
    movlw   0b00000100                  ; Red LED only (GP2)
    movwf   GPIO
    retlw   0

;====================================================================
;  LEVEL DELAY - Variable speed based on level
;====================================================================
level_delay:
    movf    level, w
    btfsc   STATUS, Z                   ; Skip if level != 0
    goto    level_0_delay               ; Level 0
    
    movlw   1
    subwf   level, w                    ; W = level - 1
    btfsc   STATUS, Z                   ; Skip if level != 1
    goto    level_1_delay               ; Level 1
    
    ; Level 2 or higher - fastest speed
    movlw   150                         ; Outer loop count for ~150ms
    goto    do_delay

level_0_delay:
    movlw   250                         ; Outer loop count for ~250ms
    goto    do_delay

level_1_delay:
    movlw   200                         ; Outer loop count for ~200ms
    goto    do_delay

do_delay:
    movwf   loop_a
level_delay_outer:
    movlw   250                         ; Inner loop count
    movwf   loop_b
level_delay_inner:
    decfsz  loop_b, f
    goto    level_delay_inner
    decfsz  loop_a, f
    goto    level_delay_outer
    retlw   0

;====================================================================
;  MOVE SWEEP - Update position and direction  
;====================================================================
move_sweep:
    movf    direction, w
    btfsc   STATUS, Z                   ; Skip if direction != 0 
    goto    move_backward               ; Direction = 0, moving backward
    
    ; Moving forward (direction = 1)
    incf    position, f                 ; position++
    movlw   3
    subwf   position, w                 ; W = position - 3
    btfss   STATUS, C                   ; Skip if position >= 3
    retlw   0                           ; position < 3, continue forward
    
    ; Reached end, reverse direction
    clrf    direction                   ; direction = 0 (backward)
    movlw   2                           ; Set position to 2 (red)
    movwf   position
    retlw   0

move_backward:
    ; Moving backward (direction = 0)
    movf    position, w
    btfsc   STATUS, Z                   ; Skip if position != 0
    goto    change_to_forward           ; At position 0, change direction
    
    decf    position, f                 ; position--
    retlw   0

change_to_forward:
    movlw   1                           ; direction = 1 (forward)
    movwf   direction
    retlw   0

;====================================================================
;  CHECK BUTTON - Handle button press logic
;====================================================================
check_button:
    btfsc   GPIO, GPIO_GP3_POSITION     ; Skip if button pressed (GP3 low)
    retlw   0                           ; Button not pressed, return
    
    ; Button appears pressed, debounce
    call    simple_delay_short
    btfsc   GPIO, GPIO_GP3_POSITION     ; Check again
    retlw   0                           ; Was just noise
    
    ; Button confirmed pressed
    movf    position, w
    btfss   STATUS, Z                   ; Skip if position == 0 (Green)
    goto    button_miss                 ; Wrong position - miss!
    
button_hit:
    ; Correct hit on Green LED
    incf    level, f                    ; Increase level
    
    movlw   3
    subwf   level, w                    ; W = level - 3
    btfss   STATUS, C                   ; Skip if level >= 3
    goto    wait_button_release         ; Level still < 3
    
    ; Level reached 3 - Win celebration!
    call    win_celebration
    clrf    level                       ; Reset level
    goto    wait_button_release

button_miss:
    ; Wrong timing - reset level and show fail flash
    clrf    level
    call    fail_flash

wait_button_release:
    ; Wait for button to be released
wait_release_loop:
    btfss   GPIO, GPIO_GP3_POSITION     ; Skip if button released (GP3 high)
    goto    wait_release_loop           ; Keep waiting
    
    call    simple_delay_short          ; Debounce delay after release
    retlw   0

;====================================================================
;  WIN CELEBRATION - Flash all LEDs
;====================================================================
win_celebration:
    movlw   4                           ; Flash 4 times
    movwf   counter

win_flash_loop:
    movlw   0b00000111                  ; All LEDs ON
    movwf   GPIO
    call    celebration_delay
    
    clrf    GPIO                        ; All LEDs OFF
    call    celebration_delay
    
    decfsz  counter, f
    goto    win_flash_loop
    
    retlw   0

;====================================================================
;  FAIL FLASH - Flash red LED for miss
;====================================================================
fail_flash:
    movlw   3                           ; Flash 3 times
    movwf   counter

fail_flash_loop:
    movlw   0b00000100                  ; Red LED ON
    movwf   GPIO
    call    simple_delay
    
    clrf    GPIO                        ; Red LED OFF
    call    simple_delay
    
    decfsz  counter, f
    goto    fail_flash_loop
    
;====================================================================
;  DELAY ROUTINES
;====================================================================

;====================================================================
;  CELEBRATION DELAY - Short delay for win celebration (120ms)
;====================================================================
celebration_delay:
    movlw   120                         ; 120 loops for ~120ms
    movwf   loop_a
celebration_delay_outer:
    movlw   250
    movwf   loop_b
celebration_delay_inner:
    decfsz  loop_b, f
    goto    celebration_delay_inner
    decfsz  loop_a, f
    goto    celebration_delay_outer
    retlw   0

;====================================================================
;  SHORT DELAY - For debouncing
;====================================================================
simple_delay_short:
    movlw   20                          ; Short delay for debouncing
    movwf   loop_a
short_delay_outer:
    movlw   250
    movwf   loop_b
short_delay_inner:
    decfsz  loop_b, f
    goto    short_delay_inner
    decfsz  loop_a, f
    goto    short_delay_outer
    retlw   0

;====================================================================
;  SIMPLE DELAY - Based on working blink.s delay
;====================================================================
simple_delay:
    movlw   200                         ; Outer loop count (much larger)
    movwf   loop_a

delay_outer:
    movlw   250                         ; Inner loop count
    movwf   loop_b

delay_inner:
    decfsz  loop_b, f                   ; Inner loop
    goto    delay_inner

    decfsz  loop_a, f                   ; Outer loop
    goto    delay_outer

    retlw   0

;====================================================================
;  END OF PROGRAM
;====================================================================
    end     resetVec


