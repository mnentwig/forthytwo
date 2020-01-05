# forthytwo
J1 embedded processor with "batteries included": Compiler, simulator, reference design

## What is this?

The J1 embedded CPU is an outstanding processor for small embedded FPGA applications, remarkable for its minimum size, simplicity and accessibility through Verilator simulation. Unfortunately, the same cannot be said for the original Forth-based development environment, a recursion of rabbit holes to trap the unwary developer who thought he could just go and write code.

Forthytwo starts from a clean slate - it is fully independent of the original build system.
Since the J1 architecture is a FORTH-targeted stack machine architecture, the input language remains very similar to FORTH but no attempt is made to maintain formal compatibility.

## Mission statement
One-stop embedded 32-bit processor for FPGA or ASIC (if you dare). 
Keep it simple and stupid and clean and small so it can be customized as needed.

## Status
Functional but may benefit from more testing (especially the floating point library due to its complexity)

This page: At the time of writing a (largely) unordered collection of notes.

### Hardware version
forthytwo targets the J1b CPU (16 bit opcodes, 32 bit data). Note that some of the opcodes differ from older version (e.g. there is no "-1" instruction). If in doubt, compare with "basewords.fs" from the original J1b repo.
The original shift-register based stack seemed area inefficient (observed on Xilinx Artix) and was replaced with a RAM-and-pointer stack. This may cause some speed penalty, though (try stock J1B for an alternative).

### Result
A non-trivial design based on the floating point library has been tested successfully on a Xilinx Artix 7.
The J1B runs at 100 MHz with some margin (-1 speed grade, 125 MHz are reportedly achievable). 
The critical path is: instruction memory read => J1B "store" ALU opcode => data memory write. This is an architectural limitation.

On Xilinx Artix XC7A35, its resource use is
* 673 LUTs = 3.3% utilization with the default CPU configuration which is 32 stack levels in distributed RAM
* 526 LUTs if reducing the +/- 32 bit barrel shifter to +/- 1 bit (Note: this is not supported out of the box but straightforward to add).
* 453 LUTs if further allowing one BRAM18 for each of the two stacks
* some further reduction if the UART is left out
 
### Note on makefiles
Development by the author is done on Windows with minGW and default gmake (type "make" in any folder from the minGW command prompt).
Makefiles may need some system-dependent adjustments.

### building forthytwo.exe
Forthytwo.exe is built from the top level makefile, using the command line csc compiler from a .NET framework installation.
Alternatively, Visual Studio can be used by opening forthytwo.sln. If so, disable the respective part of the makefile or the .exe file will be overwritten.

### Convention
In this document, >>><<< is used for code-related punctuation. For example, a double-colon >>>::<<< in combination with a label starts a macro, as in >>>::thisIsMyMacro<<<.
As a general guideline, directives involving compiler "magic" e.g. IF-ELSE-ENDIF generation, BRA(nch) label resolution or VAR(iable) creation use upper case.

### Case sensitivity
With few exceptions (e.g. 0x1 or 0X1 are both hex numbers) it is case sensitive.

### Usage
Build the C# project (Visual Studio, mono or any C# compiler should be sufficient) and run forthytwo.exe, giving the top level source file as arguments (or several).
The path of the source file defines the top level folder for including other files.

Output is generated at the location of the first input file in a (possibly new) folder out/
* mySource.hex output can be read using the unmodified J1B Verilator simulation.
* mySource.v can be used in verilog. Note: in Vivado, set file type to "Verilog header" to avoid syntax errors, then: initial begin `include "mySource.h" end
* mySource.lst: generated output with human-readable annotations

### Note on whitespace characters (space, tab, newline)
* forthytwo makes heavy use of compound keywords such as >>>var:myVariable=1234<<< that may _not_ contain whitespace characters for formatting.
* Filenames in >>>#include(...)<<< _may_ contain space characters (use the exact operating system file name without "escaping" spaces). 
* There are no special rules for punctuation characters, e.g. >>>;<<< is no different from any other token and therefore must be separated by whitespace
* In code, whitespace characters serve no other role than token separation

### Note on symbol names
Any character sequence free of whitespaces that fails to parse as a number may be used as symbol. A symbol may be used only for one purpose (macro, code label, data label) at a time.
Redefining any symbol (built-in and user) is not possible and leads to an error.
Lower- and mixed case variants of built-in ALL-CAPS words are forbidden.

### Note on library.symbol naming scheme in the included libraries
The dot-separated hierarchical naming scheme (e.g. >>>core.drop<<< is an arbitrary coding convention to improve readibility and avoid name clashes. The dot itself has no special meaning to the compiler.

# Comments
C style single-line and block comments are supported, using // ... to the end of the line and /* ... */ respectively.
Block comments may be arbitrarily nested.

### >>>#include(file)<<< directive
Sources a file, equivalent to inserting it verbatim at the same line. Paths may be relative or absolute. 
For nested inclusions, the search path is always relative to the including file.

### >>>#include_once<<< directive
Prevents multiple inclusion of the current file (may be located anywhere in the file). See core.txt for an example.

### code and data segment addresses
TBD, right now hardcoded in main()

### Processor opcodes
The compiler defines all opcodes with a >>>core.<<< prefix e.g. >>>core.drop<<<, >>>core.swap<<<.
The include file cpu.txt creates some aliases for convenience (e.g. >>>drop<<<, >>>swap<<<).

### Macros
A macro is defined using >>>::macroNameGoesHere<<< (no space between >>>::<<< and the name) and ended with >>> ;<<<
E.g. >>>::dup3 dup dup dup ;<<<
Is is invoked via its label e.g. dup3 similar to a function call.
The >>>;<<< must be separated by whitespace.

### Function definitions
A function is defined with >>>:functionNameGoesHere<<< (again, no space) and ended with >>> ;<<<
Internally, the >>>:functionName<<< creates only a label (no assembly code is emitted). The semicolon is a macro equivalent to a >>>core.return<<< opcode.

### Function calls
\>>>functionName<<< emits a subroutine call to the label defined by >>>functionName<<<.

### Labels
Similar to a function, a code label (for low-level branch opcodes) is defined with >>>:labelNameGoesHere<<<. Again, it emits no assembly code by itself.
A common use case is to have multiple entry points for a function, using a common >>>core.return<<< instruction.
(TBD add hex1..hex8 DUPLICATE example)

### Branches
\>>>BRA:myLabel<<< (one word): Branch unconditionally to myLabel. Forward branches are permitted (two-pass compiler)

\>>>BZ:myLabel<<< (one word): Pops value and jumps to myLabel if all bits are zero.

\>>>CALL:myLabel<<< (one word): Jumps to myLabel and returns on the next >>>core.return<<< opcode.

### Conditionals 

\>>>IF ...code1... ELSE ... code2 ... ENDIF<<<
\>>>IF<<< pops one entry from the stack and executes code1 if at least one bit is set, or code2 otherwise. The ELSE keyword is optional.

### For loop: 
\>>>(myStartValueOnStack) (myLoopLimitOnStack) DO ...code1... LOOP<<<
Takes two parameters from the stack. 
Equivalent to C "for (signed int i = myCounterInitVal; i < myLoopLimit; ++i){ ... }

* _DIFFERENCE TO REGULAR FORTH:_ The loop variable i is provided to code1 on the stack and expected again on the stack at >>>LOOP<<<. It may be modified by the loop body.
* The comparison is performed at the start of the loop (that is, will iterate zero or more times)
* The comparison is signed.
* The loop limit is exclusive. For example, >>>0 3 DO ... LOOP<<< will iterate over 0, 1, and 2
* The construct uses the return stack for the loop limit

### BEGIN...WHILE...REPEAT loop:
The first ... code blocks puts a value on the stack that is consumed by WHILE. If all bits are zero, execution continues after REPEAT. Otherwise, the second ... code block is executed, then the loop is re-entered at BEGIN.

### BEGIN...AGAIN
Infinite loop. Use e.g. BRA: to exit
### Immediate values
Numbers may be decimal, binary (0b1001), octal (0O12345678) or hexadecimal (0xdeadbeef).

Any number appearing in the code is loaded to the data stack (note, the number of instructions differs on the value, since J1b can only load 15 bits at a time).

### VAR
\>>>VAR:myVariableName=12345678<<< allocates a 32-bit word in the data segment. Its address can be loaded with the single-quote built-in function >>>'myVariableName<<<. 

### single-quote "address-of"
The single-quote built-in >>>'myLabel<<< pushes the address of myLabel (code or variable).

# FLM floating point library
- 32 bit (26 bits signed mantissa, 6 bits signed exponent)
- custom float format ("flm format"), NOT compatible with IEEE 754 single precision even though both are 32 bit format
- conceptually simplified over IEEE 754 (no implied "1" for mantissa, no NAN or INF, fewer special case rules required for denormal numbers)
- may be considered 26 bit signed fixed point with a 6-bit signed attached exponent for the length of the fractional part
- no internal rounding
-- flm.add: add two floats
-- flm.mul: multiply two floats
-- flm.div: divide two floats
-- flm.negate: change sign of a float
-- flm.int2flt: convert integer to float
-- flm.flt2int: convert float to integer
-- flm.sim.printFlm: prints float as %1.15 (using simulator printf, target code size is two instructions)
-- (advanced)flm.unpack and flm.pack: split (recombine) to exponent and mantissa. Mantissa is right-aligned (6 bits after sign bit are unused)
-- (advanced)flm.unpackUp6: like flm.unpack but the mantissa is left-aligned in 32 bits (shifted up 6 bits)
-- (helper function)flm.rshiftArith (on signed integer type argument): Like core.rshift but MSB is padded with sign
-- Example: 0x00000040 is 1 (the rightmost 6 exponent bits form the number 0, the leftmost 26 bits form the signed number +1)
-- 0 is by definition 0x00000000 (special case, since any exponent would be mathematically correct)

Once the float library is included with >>>#include(myLibPath/flm.txt)<<<, the parser converts literal numbers with a decimal point as float e.g. 1.0 or 2.0e6 but not 2e6.
This feature may be enabled manually with >>>#ENABLE_FLOAT_LITERALS<<<

# known bugs
- the forthytwo.exe exit code is not recognized by mingw "make", therefore the makefile will continue. Forthytwo.exe deletes all output files at startup, so the error should show later as a non-existing file.
- obvious optimizations for smaller and faster code (single-opcode ALU+return, CALL+return => BRA) are not yet implemented

# boot loader
A minimal boot loader is included (164 bytes including UART get-/putChar)
It is recommended to create a copy for each application, with possible modifications (e.g. debug output) in mind.

## Boot loader concept
The boot loader is built into FPGA BRAM initial contents via the bitstream. For the verilator simulator, it is loaded as application.
The application binary is then sent via UART using forthytwo.exe's out/*.bootBin output file.
To reload the application binary, the system needs to be reset externally (reprogram the FPGA or assert the J1 reset input, restart the simulator).
The application MUST include a replica of the bootloader IDENTICAL TO ROM at address zero0.
During application upload, the bootloader will simply overwrite itself redundantly with bitwise-identical data. The redundant copy of the bootloader effectively sets the address offset for the user application.

## Boot loader workflow (FPGA)
- Compile bootloader.txt with forthytwo.exe, independently of the application
- Put the resulting bootloader.v file into FPGA BRAM (see sampleImpl)
- Program the FPGA. The bootloader is listening
- Open (e.g.) Teraterm, Menu:File/send File, check "binary" option, select myApplication.bootBin file.
- For design iteration, reprogram the FPGA (or use e.g. a button tó reset the J1 core) and repeat
- A convenient hack is to manually edit the first line of the generated Verilog file to turn a deployed binary in FPGA block ram back into the bootloader: Look up the address of bootloader.main and put it into the low word of ram[0] (a valid code address used as instruction is an unconditional branch to the same address). Switching back to bootloader.startApplication restores the application.
- The sample project (not the bootloader!) will print "ok" on successful upload and echo any characters from UART "plus 1".

## Boot loader workflow (Verilator simulator in refImpl)
- invoke sim.exe bootloader.hex myApplication.bootBin
- the simulator will internally create UART input reading from the .bootBin file and switch UART IO back to console at end of file.

## Simulator
- arg1: out/myProject.hex
- for bootloader project: arg1: out/myStandaloneBootloader.hex and arg2: out/myApplicationStartingWithTheBootloader.bootBin
- use simVcd.exe to create trace.vcd for review with gtkwave. By default, tracing is enabled but files tend to grow large quickly
- >>>system.sim.tracing.disable<<< and >>>system.sim.tracing.enable<<< disable and re-enable tracing, respectively.
- Unsurprisingly, sim.exe is considerably faster than simVcd.exe

# Verilator install
Verilator is needed to rebuild the simulator executable (e.g. if modifying the CPU or adding peripherals). 
These notes are for a Windows installation and are only relevant if Verilator standard install does not run through smoothly.
- Download MinGW installer
- select mingw-developer-toolkit-bin, mingw32-base-bin, mingw32-gcc-g++.bin, msys-base.bin. "Apply scheduled changes"
- (optional) edit c:/MinGW/msys/1.0/etc/profile, remove the last "cd $HOME"
- (optional) add "open msys here" shortcut: https://codeplea.com/open-msys-here
- edit include/verilatedos.h: comment out # define __USE_MINGW_ANSI_STDIO 1  // Force old MinGW (GCC 5 and older) to use C99 formats
- git checkout stable (maybe setup git user name and email at this time)
- autoconf
- ./configure --prefix /usr
- edit c:/mingw/include/stdio.h and temporarily comment out the implementation of vsnprintf (avoids duplicate symbol linker error) 
- make -j then make (it might require several attempts)
- make install
- (optional, suppresses warnings) edit c:/mingw/include/mingw.h, disable # warning "Direct definition of __USE_MINGW_ANSI_STDIO is deprecated."
- (optional, suppresses warnings) edit c:/MinGW/msys/1.0/share/verilator/include/vltstd/ and remove dllimport attribute
- (optional, suppresses warnings) edit respective verilatorxy.h files to first #undef MINGW_XYZ that would later cause a redefinition warning
- with those modifications, the simulator build should not show any warnings.

# J1 native opcodes
Compiler names for native J1B opcodes (see lib/core.txt). Those are visible e.g. in a generated out/mySource.lst file
* core.noop
* core.return
* core.plus
* core.xor
* core.and
* core.or
* core.invert
* core.equals
* core.lessThanSigned
* core.lessThanUnsigned
* core.swap
* core.dup
* core.drop
* core.over
* core.nip
* core.pushR
* core.fetchR
* core.popR
* core.rshift
* core.lshift

Memory / IO fetch and store require two opcodes each, as implemented in the Forth-style aliases @ and !
Note, those are macros, not subroutine calls (define with : instead of :: for a subroutine call which will be smaller but slower)

* core.fetch1 
* core.fetch2
* core.sto1
* core.sto2
* core.ioFetch1
* core.ioFetch2
* core.ioSto1 
* core.ioSto2

For immediate values, conditional / unconditional branch and subroutine call, all possible 16-bit opcodes have an alias using a four-digit hex number (lower case) as follows:

Explicit immediate value: 
* core.imm0xabcd

Explicit unconditional branch: 
* core.bra0xabcd

Explicit conditional branch: 
* core.bz0xabcd

Explicit call:
* core.call0xabcd

Generic 16-bit opcode (e.g. for optimized ALU variants with combined return):
* core.opcode0xabcd
