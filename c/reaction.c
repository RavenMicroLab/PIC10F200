/*
 * File:   reaction.c
 * Author: cstep
 *
 * PIC10F200 Reaction Game
 *
 * Description:
 *   Single-button reaction-timer: a Yellow ready cue arms the player.
 *   A short pre-start wait follows; pressing during the wait shows Red
 *   (false start) and restarts. When Green lights, a 1s window counts in
 *   4 ms steps until the button (GP3, active-low) is pressed. Fast /
 *   medium / slow feedback is shown on Green / Yellow / Red. Timing is
 *   tuned for the 4 MHz internal RC.
 * 
 * Device: PIC10F200 (8-pin PDIP)
 * Compiler: XC8
 *
 * Pin Configuration:
 *   Pin 1 (N/C)  - Not Connected
 *   Pin 2 (VDD)  - +5V Power
 *   Pin 3 (GP2)  - Red LED output (with current-limiting resistor)
 *   Pin 4 (GP1)  - Yellow LED output (with current-limiting resistor)
 *   Pin 5 (GP0)  - Green LED output (with current-limiting resistor)
 *   Pin 6 (N/C)  - Not Connected
 *   Pin 7 (VSS)  - Ground
 *   Pin 8 (GP3)  - Button input (active-low, external pull-up to VDD)
 */
#include <xc.h>

#pragma config WDTE = OFF
#pragma config CP = OFF
#pragma config MCLRE = OFF

#define _XTAL_FREQ 4000000
#define BUTTON GPIObits.GP3

#define LEDS_OFF()     do { GPIObits.GP0 = 0; GPIObits.GP1 = 0; GPIObits.GP2 = 0; } while(0)
#define LED_GREEN()    do { GPIObits.GP0 = 1; GPIObits.GP1 = 0; GPIObits.GP2 = 0; } while(0)
#define LED_YELLOW()   do { GPIObits.GP0 = 0; GPIObits.GP1 = 1; GPIObits.GP2 = 0; } while(0)
#define LED_RED()      do { GPIObits.GP0 = 0; GPIObits.GP1 = 0; GPIObits.GP2 = 1; } while(0)
#define LED_ALL()      do { GPIObits.GP0 = 1; GPIObits.GP1 = 1; GPIObits.GP2 = 1; } while(0)

void main(void)
{
    OPTION = 0b11011111;      // GP2 as GPIO, WDT prescale, weak pulls disabled
    TRISGPIO = 0b00001000;    // GP3 input, GP0-2 outputs
    LEDS_OFF();               // all LEDs off

    unsigned char t;
    unsigned char wait;

    while(1)
    {
        __delay_ms(1000);     // idle pause between rounds
        
        // Yellow flash (ready cue)
        LED_YELLOW();
        __delay_ms(1000);
        LEDS_OFF();
        __delay_ms(1000);
        
        // False-start guard: short wait; button press here shows red and restarts
        wait = 125; // ~500 ms in 4 ms steps
        while(wait--) {
            if (BUTTON == 0) {
                LED_RED();
                __delay_ms(300);
                LEDS_OFF();
                __delay_ms(400);
                goto next_round;
            }
            __delay_ms(4);
        }

        // Green on: start reaction timing window (max ~1s)
        LED_GREEN();
        t = 0;
        while (BUTTON && t < 250) {
            t++;
            __delay_ms(4);
        }
        LEDS_OFF();
        __delay_ms(100);      // settle before showing result

        // Show result based on elapsed counts (4 ms each)
        // Easier thresholds: Fast <160 ms, Medium <320 ms, else Slow
        if (t < 40)
            LED_GREEN();      // Fast - green
        else if (t < 80)
            LED_YELLOW();     // Medium - yellow
        else
            LED_RED();        // Slow - red
            
        __delay_ms(1500);
        LEDS_OFF();

    next_round:
        ;
    }
}
