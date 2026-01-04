;====================================================================
; File:   button.s
; Author: cstep
;
; PIC10F200 Button-Controlled LED Program
;
; Description:
;   Demonstrates simple GPIO control on the PIC10F200.
;   - GP3 is configured as an input with an external pull-up resistor.
;     The button pulls GP3 low when pressed (active-low).
;   - GP0/GP1/GP2 are all configured as outputs driving the LEDs.
;   - Normal state: Green + Red ON, Yellow OFF
;   - Button pressed: Yellow ON, Green + Red OFF
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
;  MAIN PROGRAM
;====================================================================
main:
    movlw   0b00001000     ; GP3 input, GP0/GP1/GP2 outputs
    tris    GPIO
    
    movlw   0b11011111
    option

    clrf    GPIO

loop:
    ; Check if GP3 is low (button pressed)
    btfsc   GPIO, GPIO_GP3_POSITION     ; Bit test GP3, skip if clear (0)
    goto    button_not_pressed          ; GP3 is high, button not pressed
    
    ; Button appears pressed, debounce with 20ms delay
    call    delay_20ms
    
    ; Check again after debounce
    btfsc   GPIO, GPIO_GP3_POSITION     ; Test GP3 again
    goto    button_released             ; Was just noise, button released
    
    ; Button confirmed pressed
    bcf     GPIO, GPIO_GP0_POSITION    ; Green LED OFF
    bcf     GPIO, GPIO_GP2_POSITION    ; Red LED OFF
    bsf     GPIO, GPIO_GP1_POSITION    ; Yellow LED ON
    goto    loop
    
button_released:
    ; Button was pressed but now released
    bcf     GPIO, GPIO_GP1_POSITION    ; Yellow LED OFF
    goto    loop
    
button_not_pressed:
    ; Button not pressed - normal state
    bsf     GPIO, GPIO_GP0_POSITION    ; Green LED ON
    bsf     GPIO, GPIO_GP2_POSITION    ; Red LED ON
    goto    loop

delay_20ms:
    movlw   10
    movwf   0x10        ; A = 10 (outer loop counter)

loopA:
    movlw   199
    movwf   0x11        ; B = 199 (middle loop counter)

loopB:
    movlw   10
    movwf   0x12        ; C = 10 (inner loop counter)

loopC:
    decfsz  0x12, f     ; inner loop: d3--
    goto    loopC       ; 2 cycles per iteration

    decfsz  0x11, f     ; middle loop: d2--
    goto    loopB       ; 2 cycles per iteration

    decfsz  0x10, f     ; outer loop: d1--
    goto    loopA       ; 2 cycles per iteration

    retlw   0           ; return from delay

;====================================================================
;  END OF PROGRAM
;====================================================================
    end     resetVec
