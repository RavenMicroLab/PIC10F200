/*
 * File:   blink.c
 * Author: cstep
 *
 * PIC10F200 LED Blink Program
 *
 * Description:
 *   Demonstrates simple GPIO control on the PIC10F200.
 *   - GP2 is configured as an output driving an LED.
 *
 * Device: PIC10F200 (8-pin PDIP)
 * Compiler: XC8 (v3.10)
 *
 * Pin Configuration:
 *   Pin 1 (N/C)  - Not Connected
 *   Pin 2 (VDD)  - +5V Power
 *   Pin 3 (GP2)  - LED output (with current-limiting resistor)
 *   Pin 4 (GP1)  - Output (unused)
 *   Pin 5 (GP0)  - Output (unused)
 *   Pin 6 (N/C)  - Not Connected
 *   Pin 7 (VSS)  - GND
 *   Pin 8 (GP3)  - Input-only (MCLR/VPP), (unused)
 */

#include <xc.h>

#pragma config WDTE = OFF    // Disable watchdog timer
#pragma config CP   = OFF    // Disable code protection
#pragma config MCLRE = OFF   // Use GP3 is digital input, not MCLR

#define _XTAL_FREQ 4000000   // Internal RC oscillator ~4 MHz

int main(void) {
    
    OPTION = 0b11011111;   // Disable pull-ups, disable wake-on-change,
                           // Timer0 uses internal clock (GP2 stays digital output),
                           // Prescaler to WDT (unused)
    
    // Configure GPIO directions:
    // GP0/GP1/GP2 = outputs, GP3 = input-only
    TRISGPIO = 0b00001000;

    // Initialize output state
    GPIO = 0x00;          // Set all outputs low (initially LED off)

    while (1) {
        // Toggle LED on GP2
        GPIObits.GP2 = 1;    // LED ON
        __delay_ms(500);

        GPIObits.GP2 = 0;    // LED OFF
        __delay_ms(500);
    }

    return 0;
}
