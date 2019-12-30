#include <stdlib.h>
#include <stdio.h>

// headers for flm.c
#include <math.h>
#include <stdint.h>

// double2flm: use the float library source for importing numbers
#include "../libs/flm/flm.c"

int main(void){  
  double valFloat;
  int count = 0;
  while (scanf("%lf", &valFloat) != EOF){
    
    int32_t valFlp = double2flm(valFloat);
    printf("VAR:myData%i=0x%08x // %f\n", (count++), valFlp, valFloat);
  }
  return EXIT_SUCCESS;
}
