# forthytwo
A FORTH-free compiler / macro assembler for the J1 embedded processor

__under construction / partly untested__
This page: At the time of writing a (largely) unordered collection of notes

## Introduction / Summary

The J1 embedded CPU is an outstanding processor for embedded FPGA applications, remarkable for its minimum size, simplicity and accessibility through Verilator simulation. Unfortunately, the same cannot be said for the Forth-based development environment, a recursion of rabbit holes to trap unwary programmers attempting a non-trivial modification to the system.

Forthytwo starts from a clean slate - it is fully independent of the original build system.
The input language is very similar to FORTH thanks to the stack machine processor architecture. It makes no claims of formal compatibility.

With few exceptions (e.g. 0x1 or 0X1 will be accepted) it is case sensitive.

### Hardware version
forthytwo targets the J1b CPU (16 bit opcodes, 32 bit data). Note that some of the opcodes differ from older version (e.g. there is no "-1" instruction). If in doubt, compare with "basewords.fs" from the original J1b repo.

### building 
* Visual Studio: Open .sln file, "Build solution"
* Mono on Windows: use "Open Mono command prompt" from windows start menu. Navigate to folder containing "buildFromMonoPrompt.bat" and run from command line
* Mono on Linux: Use same .bat file contents (one-liner) with slash instead of backslash

### Convention
In this document, >>><<< is used for code-related punctuation. For example, a double-colon >>>::<<< in combination with a label starts a macro, as in >>>::thisIsMyMacro<<<.
As a general guideline, directives involving compiler "magic" e.g. IF-ELSE-ENDIF generation, BRA(nch) label resolution or VAR(iable) creation use upper case.

### Usage
Build the C# project (Visual Studio, mono or any C# compiler should be sufficient) and run forthytwo.exe, giving the top level source file as arguments (or several).
The path of the source file defines the top level folder for including other files.

Output is generated at the location of the first input file in a (possibly new) folder out/
The mySource.hex output can be read using the unmodified J1B Verilator simulation.

The mySource.lst output provides a human-readable description of the generated output.

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
- not compatible with IEEE single precision
- simplified (no implied "1" for mantissa, no NAN or INF
- simulator has dedicated IO register 0x4000 to print a float value
- no internal rounding, minimal code size
- documentation TBD

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


