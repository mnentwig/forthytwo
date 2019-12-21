#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
// xor-style LFSR pseudorandom sequences
#define SHIFT64(x)x ^= x << 13; x ^= x >> 7; x ^= x << 17;
#define SHIFT32(x)x ^= x << 13;	x ^= x >> 17; x ^= x << 5;

int32_t sqrtS7Q24 ( int32_t x ){  
    uint32_t t, q, b, r;
    //uint64_t r;
    r = x;
    b = 0x40000000;
    q = 0;
    // input has 8 integer bits
    // output must be adjusted by half the amount
    int nFrac = 4;
    while( b > 0x08 ){
      t = q + b;
      if( r >= t ){
	r -= t;
	q += (b << 1);
      }
      if (r & 0x80000000){
	// adjust fixed point position
	r >>= 1;
	q >>= 1;
	b >>= 1;
	--nFrac;
      }
      r <<= 1;
      b >>= 1;
    }
    q >>= nFrac;
    return q;
}

int main(void){
  uint32_t arg1 = 0x12345678;
  uint32_t arg2 = 0x98765432;
  //    uint64_t arg1 = 0x0123456789abcdef;
  //uint64_t arg2 = 0x456789abcdef0123;
    
  int ix;
  for (ix = 0; ix < 100; ++ix){
      // arg1 = 0xFFFFFFFF; arg2 = 0xFFFFFFFF;
      uint32_t prod32x32 = arg1 * arg2;
      uint32_t prod16x32 = (arg1 & 0xFFFF) * arg2;
      uint64_t prod32x32x2 = (uint64_t)(arg1) * (uint64_t)(arg2);
      uint32_t prod32x32Lo = prod32x32x2;
      uint32_t prod32x32Hi = (prod32x32x2 >> 32);

      int64_t B = ((int64_t)((int32_t)arg1)) * ((int64_t)((int32_t)arg2));
      uint64_t C = (int64_t)B;
      uint32_t D = C;
      uint32_t E = C >> 32;
      printf("%08x %08x %08x %08x %08x %08x %08x %08x",
	     arg1, 
	     arg2, 
	     prod32x32,
	     prod16x32, 
	     prod32x32Lo, 
	     prod32x32Hi,
	     D, 
	     E);

      int32_t rsqrt = sqrtS7Q24(arg1);
      printf(" %08x ", rsqrt);
      printf("\r\n");

      // === update shift registers ===
      SHIFT32(arg1); SHIFT32(arg2);
    }
  return EXIT_SUCCESS;
}
