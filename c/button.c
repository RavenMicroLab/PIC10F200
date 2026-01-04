/*
 * File:   button.c
 * Author: cstep
 *
 * PIC10F200 Button-Controlled LED Program
 *
 * Description:
 *   Demonstrates simple GPIO control on the PIC10F200.
 *   - GP3 is configured as an input with an external pull-up resistor.
 *     The button pulls GP3 low when pressed (active-low).
 *   - GP0/GP1/GP2 are all configured as outputs driving the LEDs.
 *   - Normal state: Green + Red ON, Yellow OFF
 *   - Button pressed: Yellow ON, Green + Red OFF
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

int main(void) {
    OPTION = 0b11011111;     // Disable pull-ups, disable wake-on-change,
                             // Timer0 uses internal clock (GP2 stays digital output),
                             // Prescaler to WDT (unused)
    
    TRISGPIO = 0b11111000;   // GP3 input, GP0/GP1/GP2 outputs
    GPIO = 0x00;

    while (1) {
        if (GPIObits.GP3 == 0) {   // Button pressed -> GP3 low
            __delay_ms(20);        // Debounce
            if (GPIObits.GP3 == 0) {
                GPIObits.GP0 = 0;  // Green LED OFF
                GPIObits.GP2 = 0;  // Red LED OFF
                GPIObits.GP1 = 1;  // Yellow LED ON
            } else {
                GPIObits.GP1 = 0;  // Yellow LED OFF
             }
        } else {
            GPIObits.GP0 = 1;      // Green LED ON
            GPIObits.GP2 = 1;      // Red LED ON
        }
    }
    return 0;
}

