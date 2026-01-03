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
;  Use Project Properties ?
;  pic-as Global Options ?
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
    movlw   0b00001000
    tris    GPIO

;===========================================================
;  MAIN LOOP ? BLINK LED ON GP1
;===========================================================
loop:
    bsf     GPIO, GPIO_GP1_POSITION
    call    delay

    bcf     GPIO, GPIO_GP1_POSITION
    call    delay

    goto    loop

;===========================================================
;  This produces roughly:
;    ~250 × 250 × ~3 cycles ? ~187,500 cycles
;    At 4 MHz ? ~187 ms
;
;  So this is shorter than 250 ms ? which you will observe
;  that the ASM blink is a little faster than the C code.
;===========================================================
delay:
    movlw   250
    movwf   0x10        ; Outer loop

d1:
    movlw   250
    movwf   0x11        ; Inner loop

d2:
    decfsz  0x11, f
    goto    d2

    decfsz  0x10, f
    goto    d1

    retlw   0


;===========================================================
;  END OF PROGRAM
;===========================================================
    end     resetVec
