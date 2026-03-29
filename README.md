This project implements an 8-bit binary counter displayed on an 8-digit 7-segment display controlled by the MAX7219 driver. 
Designed in VHDL, the system increments the binary value every second. 
It features a custom Finite State Machine (FSM) for SPI communication

##  Development Environment
- **FPGA:** Gowin GW1NR series (Tang Nano 9K)
- **Display:** 8-Digit 7-Segment Display with MAX7219 Driver
- **IDE:** Gowin EDA
- **Programmer:** Gowin Programmer

##  Key Features
- **Real-time Binary Counting:** Increments every 1 second (f_clk = 54 MHz).
- **Efficient SPI Control:** Custom FSM handles initialization and data transmission.
- **Leading Zero Suppression:** Only active bits are displayed; unused digits remain off until needed.
- **Low Resource Usage:** Optimized for small FPGAs.

## Connection Diagram
```text
MAX7219 Pin      FPGA Pin (Tang Nano 9K)
-----------      -----------------------
VCC                       5V
GND                       GND 
DIN                       53
CS                        51 
CLK                       35 
```
##  Resource Usage Summary
```text
Resource          Usage        Utilization
--------          -----        -----------  
Logic (LUT/ALU)    187 / 8640   3%
Registers (FF)     111 / 6693   2%
I/O Ports          5 / 71       8%


