;===========================================================
; File:   blink.s
; Author: cstep
;
; PIC10F200 LED Blink Program
;
; Description:
;   Demonstrates simple GPIO control on the PIC10F200.
;   - GP2 is configured as an output driving an LED.
;
; Device: PIC10F200 (8-pin PDIP)
; Compiler: pic-as (v3.10)
;
; Pin Configuration:
;   Pin 1 (N/C)  - Not Connected
;   Pin 2 (VDD)  - +5V Power
;   Pin 3 (GP2)  - LED output (with current-limiting resistor)
;   Pin 4 (GP1)  - Output (unused)
;   Pin 5 (GP0)  - Output (unused)
;   Pin 6 (N/C)  - Not Connected
;   Pin 7 (VSS)  - Ground
;   Pin 8 (GP3)  - Input-only (MCLR/VPP), (unused)
;===========================================================   
    processor 10F200
    #include <xc.inc>

;===========================================================
;  CONFIGURATION BITS
;===========================================================
    config WDTE = OFF
    config CP   = OFF
    config MCLRE = OFF

;===========================================================
;  RESET VECTOR (placed at 0x000 by linker option)
;
;  IMPORTANT:
;  Use Project Properties -> pic-as Global Options ->
;  Additional Options: -Wl,-presetVec=0h
;
;  This ensures the reset vector goes at 0x000 and does NOT
;  overwrite the calibration word at 0x0FF.
;===========================================================
    psect   resetVec, class=CODE, delta=2

resetVec:
    goto    main

;===========================================================
;  MAIN PROGRAM
;===========================================================
main:
    movlw   0b00001000     ; GP3 input-only, GP0/1/2 outputs
    tris    GPIO
    
;===========================================================
;  OPTION REGISTER CONFIGURATION
;
;  The PIC10F200 OPTION register controls pull-ups, wake-up
;  behavior, Timer0 clocking, and prescaler routing.
;
;  Bit layout:
;     GPWU | GPPU | T0CS | T0SE | PSA | PS2 | PS1 | PS0
;
;  We use the following configuration:
;
;     GPWU = 1   Disable wake-on-change (no sleep wakeups)
;     GPPU = 1   Disable all weak pull-ups
;     T0CS = 0   Timer0 uses internal instruction clock
;                -> GP2 remains a normal digital output
;     T0SE = 0   Timer0 Source Edge Select bit 
;                -> Doesn't matter because T0CS=0
;     PSA  = 1   Prescaler assigned to WDT (unused)
;     PS2:PS0 = 000  Prescaler = 1:1 (unused)
;
;  Binary: 1100 1000
;  Hex:    0xC8
;
;  This is the cleanest "do nothing unusual" configuration:
;    - Ensures GP2 is NOT T0CKI
;    - No pull-ups
;    - No wake-on-change
;    - Timer0 and WDT left unused
;===========================================================
    movlw   0b11001000
    option

;===========================================================
;  MAIN LOOP - BLINK LED ON GP2
;===========================================================
loop:
    bsf     GPIO, GPIO_GP2_POSITION
    call    delay

    bcf     GPIO, GPIO_GP2_POSITION
    call    delay

    goto    loop

;===========================================================
;  The PIC10F200 employs a RISC architecture with only
;  33 single-word/single-cycle instructions.
;
;  All instructions are single cycle (1 microsecond) except
;  for program branches, which take two cycles.
    
;   This is overly complicated, but I wanted to get as close
;   to 500ms delay as possible. The loops take 499,968 cycles.
;   We then fall into the pad to get the last 32 cycles.
;
;   delay = 500,000 cycles (500ms) @ 4 MHz 
;   Triple-nested loops: A=59, B=55, C=50
;===========================================================

delay:
    movlw   59
    movwf   0x10        ; A = 59 (outer loop counter)

loopA:
    movlw   55
    movwf   0x11        ; B = 55 (middle loop counter)

loopB:
    movlw   50
    movwf   0x12        ; C = 50 (inner loop counter)

loopC:
    decfsz  0x12, f     ; inner loop: C--
    goto    loopC

    decfsz  0x11, f     ; middle loop: B--
    goto    loopB

    decfsz  0x10, f     ; outer loop: A--
    goto    loopA

    ; after the final decfsz A==0, we skip the last goto
    ; and fall through into the pad block below

pad:
    ; 32-cycle pad: 16 × (goto $+1), each 2 cycles
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1

    retlw   0	; return from delay

;===========================================================
;  END OF PROGRAM
;===========================================================
    end     resetVec
