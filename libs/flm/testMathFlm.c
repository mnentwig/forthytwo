#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>
// xor-style LFSR pseudorandom sequences
#define SHIFT64(x)x ^= x << 13; x ^= x >> 7; x ^= x << 17;
#define SHIFT32(x)x ^= x << 13;	x ^= x >> 17; x ^= x << 5;


//|VAR:testMath.arg1=0x12345678 // state of LFSR1 pseudorandom number
//|VAR:testMath.arg2=0x98765432 // state of LFSR2 pseudorandom number

//| // runs an XOR-style LFSR permutation on the stack value
//|:testMath.LFSR32
//|	dup 13 core.lshift core.xor
//|	dup 17 core.rshift core.xor
//|	dup 5 core.lshift core.xor
//|;

//| // applies LFSR32 on two variables
//|:__advanceBothLfsr 
//|	'testMath.arg1 @ testMath.LFSR32 'testMath.arg1 ! 
//|	'testMath.arg2 @ testMath.LFSR32 'testMath.arg2 ! 
//|;

//| // recalls both LFSR variables
//| :__pushBothLfsr
//| 	'testMath.arg1 @ 
//|	'testMath.arg2 @
//|;


double flm2double(int32_t val){
  int32_t exponent = (val << 26) >>> 26;
  int32_t mantissa = val >>> 6;
  double val = (double)mantissa;
  val = val * pow(2.0, exponent);
}
// bla
double double2flm(double val){
  uint32_t exponent = 0;
  if (val > 0){
    while (val >= (int32_t)0x7C00000){
      val /= 2; ++exponent;
    }
    while (val 
  } else {
    while (val < (int32_t)0xFC000000){
      val /= 2; ++exponent;
    }
  }
}

int main(void){
  uint32_t arg1 = 0x12345678;
  uint32_t arg2 = 0x98765432;
  //    uint64_t arg1 = 0x0123456789abcdef;
  //uint64_t arg2 = 0x456789abcdef0123;
    
  int ix;
  for (ix = 0; ix < 100; ++ix){

      printf("%08x %08x %08x %08x %08x %08x %08x %08x",
	     arg1, 
	     arg2, 
	     sum);

      int32_t rsqrt = sqrtS7Q24(arg1);
      printf(" %08x ", rsqrt);
      printf("\r\n");

      // === update shift registers ===
      SHIFT32(arg1); SHIFT32(arg2);
    }
  return EXIT_SUCCESS;
}
