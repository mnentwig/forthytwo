//|// ########################################################################
//|// # The file flm_test.txt is auto-generated by extractor.pl from flm_test.c
//|// # Its purpose is to test the flm library against its reference implementation.
//|// # No code from this file is required for regular use of the library.
//|// ########################################################################

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
// pow
#include <math.h>
// PRIx64
#include <inttypes.h>

// xor-style LFSR pseudorandom sequences
#define SHIFT32(x)x ^= x << 13;	x ^= x >> 17; x ^= x << 5;

//|//address 0 (reset vector)
//|BRA:main // skip over code from included files
//|#include(../core.txt)
//|#include(../system.txt)
//|#include(../system.ASCII.txt)
//|#include(../math.txt)

#include "flm.c"
//|#include(../flm.txt)

static uint32_t arg1 = 0x12345678;
//|VAR:testMath.arg1=0x12345678 // state of LFSR1 pseudorandom number

static uint32_t arg2 = 0x98765432;
//|VAR:testMath.arg2=0x98765432 // state of LFSR2 pseudorandom number

//|// XOR-style LFSR permutation on the stack value
//|:testMath.LFSR32
//|	dup 13 core.lshift core.xor
//|	dup 17 core.rshift core.xor
//|	dup 5 core.lshift core.xor
//|;
//|
//|// applies LFSR32 on two variables
//|:__advanceBothLfsr 
//|	'testMath.arg1 @ testMath.LFSR32 'testMath.arg1 ! 
//|	'testMath.arg2 @ testMath.LFSR32 'testMath.arg2 ! 
//|;
//|
//|// recalls both LFSR variables
//|:__pushBothLfsr
//| 	'testMath.arg1 @ 
//|	'testMath.arg2 @
//|;
//|

#include "flm_testAlg.c"

int main(void){
  // check C compiler handling of signed int 32 right shift (relying on arithmetic shift)
  assert((((int32_t)0x80000000) >> 31) == 0xFFFFFFFF);

  //flm_plotResults2(); return EXIT_SUCCESS;

#if 1
  flm_testAlgAdd();
  flm_testAlgMul();
  flm_testAlgDiv();
#else
  printf("testAlg disabled (faster debug) - this print causes the test to fail\n");
#endif
  //return EXIT_SUCCESS;
  int ix;
  int32_t exponent; int32_t mantissa;
  int32_t res;  
  //|:main

  //|// ====================================================
  //|// simulator: dedicated "printf" for float
  //|// ====================================================
  //|12345 flm.int2flt flm.sim.printFlm system.emit.cr
  printf("%1.15f\n", 12345.0);

  // exit(EXIT_SUCCESS);
  // xxxx |system.sim.terminate

  //|// ====================================================
  //|// flm.rshiftArith
  //|// ====================================================
  for (ix = 0; ix < 50; ++ix){
    //|0 50 DO >r
    printf("%08x ", flm_rshiftArith(0x40000000, ix));
    //|0x40000000 r@ flm.rshiftArith system.emit.hex8 system.emit.space

    printf("%08x\n", flm_rshiftArith(0x80000000, ix));
    //|0x80000000 r@ flm.rshiftArith system.emit.hex8 system.emit.cr
  }
  //|r> LOOP
  
  // === random pattern test ===
  for (ix = 0; ix < 10000; ++ix){
    //|0 10000 DO >r
    
    printf("%08x %08x ", arg1, arg2);
    //|// ====================================================
    //|// LFSR raw values
    //|// ====================================================
    //|__pushBothLfsr
    //|swap system.emit.hex8 system.emit.space 
    //|system.emit.hex8 system.emit.space
    
    //|// ====================================================
    //|// flm_add
    //|// ====================================================
    flm_add(arg1, arg2, &res);

    //|__pushBothLfsr
    //|flm.add

    //|system.emit.hex8 system.emit.space
    printf("%08x ", res);      

    //|// ====================================================
    //|// flm_mul
    //|// ====================================================
    flm_mul(arg1, arg2, &res);
    //|__pushBothLfsr
    //|flm.mul

    //|system.emit.hex8 system.emit.space
    printf("%08x ", res);      

    //|// ====================================================
    //|// flm_div
    //|// ====================================================
     flm_div(arg1, arg2, &res);
    //|__pushBothLfsr
    //|flm.div

    //|system.emit.hex8 system.emit.space
    printf("%08x ", res);    

    //|// ====================================================
    //|// end of line
    //|// ====================================================
    //|system.emit.cr
    printf("\n");

    // === update shift registers ===
    SHIFT32(arg1); SHIFT32(arg2);
    //|__advanceBothLfsr    

  } // for i
  //|r> LOOP


  // === test special normalization case zero ===
  mantissa = 0x00000000; exponent=1; unpackedNormalize(&mantissa, &exponent);
  printf("%08x %08x\n", mantissa, exponent);
  //|1 0x00000000 __flm.unpackedNormalize
  //|system.emit.hex8 system.emit.space 
  //|system.emit.hex8 system.emit.cr

  // === simple generic normalization test case for debugging ===
  mantissa = 0x00000001; exponent=1; unpackedNormalize(&mantissa, &exponent);
  printf("%08x %08x\n", mantissa, exponent);
  //|1 0x00000001 __flm.unpackedNormalize
  //|system.emit.hex8 system.emit.space 
  //|system.emit.hex8 system.emit.cr

  // === test normalization ===
  for (ix = 0; ix < 32; ++ix){
    //|0 32 DO
    //|>r
    exponent = 0;
    //|0
    mantissa = 1 << ix;
    //|1 r@ core.lshift
    unpackedNormalize(&mantissa, &exponent);
    //|__flm.unpackedNormalize

    printf("%08x %08x\n", mantissa, exponent);
    //|system.emit.hex8 system.emit.space 
    //|system.emit.hex8 system.emit.cr
  }
  //|r>
  //|LOOP

  mantissa = 0x00000002; exponent=1; unpackedNormalize(&mantissa, &exponent);
  printf("%08x %08x\n", mantissa, exponent);
  //|1 0x00000002 __flm.unpackedNormalize
  //|system.emit.hex8 system.emit.space 
  //|system.emit.hex8 system.emit.cr

  // === test flm.add ===
  int ix1; //|VAR:ix1=0
  int ix2; //|VAR:ix2=0
  int ix3; //|VAR:ix3=0
  for (ix1 = 0; ix1 < 64; ++ix1){
    //|0 64 DO dup 'ix1 ! >r

    for (ix2 = 0; ix2 < 64; ++ix2){
      //|0 64 DO dup 'ix2 ! >r

      for (ix3 = 23; ix3 < 26; ++ix3){
	//|23 26 DO dup 'ix3 ! >r
	
	int32_t packed1 = (0x40 << ix3) | ix1;
	//| 0x40 'ix3 @ core.lshift 'ix1 @ core.or
	
	int32_t packed2 = 0x40 | ix2;
	//| 0x40 'ix2 @ core.or
	
	int32_t res;
	flm_add(packed1, packed2, &res);
	//|flm.add
	
	printf("a%08x\n", res);      
	//|system.ascii.a system.emit system.emit.hex8 system.emit.cr
	
      } // for ix3
      //|r> LOOP
      
    } // for ix2
    //|r> LOOP
    
  } // for ix1
  //|r> LOOP
  
  return EXIT_SUCCESS;
  //|system.sim.terminate
}
