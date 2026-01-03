# PIC10F200 Examples

This repository contains code examples for the **PIC10F200** microcontroller, implemented in both **Assembly** and **C**.

## Overview

The PIC10F200 is an 8-bit microcontroller from Microchip with:
- 256 words of program memory
- 16 bytes of RAM
- 4 I/O pins (GP0-GP3)
- Internal 4 MHz oscillator
- 8-pin PDIP/SOT-23 package

## Software Implementations

### Prerequisites

- **MPLAB X IDE** (v5.0 or later)
- **XC8 Compiler** (for C version)
- **pic-as Assembler** (for Assembly version)
- PICkit 4/5 or similar programmer

## Notes

- The PIC10F200 has **no interrupts** and **no stack**, so programming is purely sequential
- The factory calibration value at address 0xFF must be preserved during programming
- The internal oscillator is approximately 4 MHz but can vary ±15% with temperature and voltage
- GP3 is input-only and cannot be used as an output

## License

This code is provided as-is for educational and demonstration purposes.

## Author

Created for learning and demonstration of PIC10F200 microcontroller programming.
