# Computer Architecture and Organization

A repository created to make my college projects evolving computer architecture.
Most projects found here will be Assembly code

You can download <a href="https://downgit.github.io/#/home?url=https://github.com/nicolascoutochaves/computer-architecture/blob/master/Emulators.zip!" target="_blank" >here</a> the Assembler and the emulators for the Ramses and Cesar.

## Current Processors:

- Ramses
- Cesar
- Intel 8086


## Processor Specs:

### Ramses

- 8 bits data and address width;
- Data represented in two's complement
- 3 8-bit Registers: 2 general purpose (RA and RB) and one index register;
- 4 addressing modes: direct, indirect, indexed, imediate;
- 8 bits PC;
- 1 state register with 3 condition codes: negative, zero and carry

### Cesar

- 16 bits address width;
- 8 bits data width;
- Data represented in two's complement
- Stack processing;
- 8 16-bit registers: 6 general purpose registers (R0 to R5);
- 1 stack pointer register (R6);
- 1 PC register (R7);
- 8 addressing modes derivated of the following 4 modes: Register, Post-Increment Register, Predecrement Register, Indexed Register;
- 1 state register with 4 condition: negative, zero, carry and overflow;
- 2 I/O devices: keyboard and 26 char visor;
- Big Endian;

### Intel 8086

- Data width of 8, 16 bits
- Physical address width of 20 bits
- Data represented in two's complement
- 4 general-purpose 16-bit registers: AX, BX, CX, and DX, which can be read or written as 8-bit registers.
- 1 16-bit program pointer: IP - Instruction Pointer
- 1 stack pointer: SP - Stack Pointer
- 2 index registers: SI - Source Index and DI - Destination Index
- 1 flags register where flags like negative, zero, carry, and overflow (among others) are implemented
- 4 segment registers: CS, SS, DS, and ES.
- 17 addressing modes, derived from the combined sum of the following three elements:
    DISP: displacement;
    BASE: base register: BP or BX;
    INDEX: index register: SI and DI;
- Little Endian;


