#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

int32_t sqrtF2F2 ( int32_t x ){  
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

int32_t double2fp(double val){
  return (int32_t)(val * pow(2.0, 24) + 0.5);
}
double fp2double(int32_t val){
  return (double)val * pow(2.0, -24);
}
int main(void){
  for (double vDouble = 1e-6; vDouble < 120.0; vDouble = vDouble * 1.001){
    int vFp = double2fp(vDouble);
    double rDouble = sqrt(vDouble);
    int rFp = sqrtF2F2(vFp);
    printf("%f %f %f\n", vDouble, fp2double(double2fp(rDouble)), fp2double(rFp));
  }
}
