Folder contents: a floating point library for the J1B target platform to be compiled with forthytwo.exe.

The file ../flm.txt is built from here.

# FLM floating point library
- 32 bit (26 bits signed mantissa, 6 bits signed exponent)
- custom float format ("flm format"), NOT compatible with IEEE 754 single precision even though both are 32 bit format
- conceptually simplified over IEEE 754 (no implied "1" for mantissa, no NAN or INF, fewer special case rules required for denormal numbers)
- may be considered 26 bit signed fixed point with a 6-bit signed attached exponent for the length of the fractional part
- no internal rounding - beware !

# Functions:
* flm.add: add two floats
* flm.mul: multiply two floats
* flm.div: divide two floats
* flm.negate: change sign of a float
* flm.int2flt: convert integer to float
* flm.flt2int: convert float to integer
* flm.sim.printFlm: prints float as %1.15 (using simulator printf, target code size is two instructions)
* (advanced)flm.unpack and flm.pack: split (recombine) to exponent and mantissa. Mantissa is right-aligned (6 bits after sign bit are unused)
* (advanced)flm.unpackUp6: like flm.unpack but the mantissa is left-aligned in 32 bits (shifted up 6 bits)
* (helper function)flm.rshiftArith (on signed integer type argument): Like core.rshift but MSB is padded with sign

Example: 0x00000040 is 1 (the rightmost 6 exponent bits form the number 0, the leftmost 26 bits form the signed number +1)

Special case:
0 is by definition 0x00000000 (special case, since any exponent would be mathematically correct)

Once the float library is included with >>>#include(myLibPath/flm.txt)<<<, the parser converts literal numbers with a decimal point as float e.g. 1.0 or 2.0e6 but not 2e6.
This feature may be enabled manually with >>>#ENABLE_FLOAT_LITERALS<<<

