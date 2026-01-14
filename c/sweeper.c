/*
 * File:   sweeper.c
 * Author: cstep
 *
 * PIC10F200 Sweeper Game
 *
 * Description:
 *   Single-button timing game: a three-LED sweep moves from
 *   Green, Yellow, Red, Yellow, Green in a continuous pattern.
 *   Press the button exactly when the sweep is on Green to advance
 *   the level and speed up. Three correct hits trigger a win
 *   celebration (all LEDs flash). Any miss triggers a red flash
 *   and resets the level/speed.
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

void main(void)
{
    OPTION = 0b11011111;      // GP2 as output
    TRISGPIO = 0b00001000;    // GP3 input, others output
    GPIO = 0;

    unsigned char pos = 0;
    signed char dir = 1;
    unsigned char level = 0;

    while(1)
    {
        // Show LED for current position
        if (pos == 0)      GPIO = 0b00000001;   // green
        else if (pos == 1) GPIO = 0b00000010;   // yellow
        else               GPIO = 0b00000100;   // red (pos=2)

        // Button check
        if (BUTTON == 0)
        {
            __delay_ms(20);
            if (BUTTON == 0)
            {
                if (pos == 0)
                {
                    level++;
                    if (level >= 3)
                    {
                        // Win celebration: all LEDs flash
                        for (unsigned char i = 0; i < 4; i++)
                        {
                            GPIO = 0b00000111;   // all LEDs ON
                            __delay_ms(120);
                            GPIO = 0;            // all LEDs OFF
                            __delay_ms(120);
                        }
                        level = 0;
                    }
                }
                else
                {
                    level = 0;
                    // Fail flash
                    for (unsigned char i=0;i<3;i++)
                    {
                        GPIO = 0b00000100;
                        __delay_ms(150);
                        GPIO = 0;
                        __delay_ms(150);
                    }
                }

                while (BUTTON == 0);
                __delay_ms(40);
            }
        }

        // Move sweep
        pos += dir;
        if (pos >= 2) dir = -1;
        else if (pos == 0) dir = 1;

        // Speed by level
        if (level == 0)      __delay_ms(250);
        else if (level == 1) __delay_ms(200);
        else                 __delay_ms(150);
    }
}

