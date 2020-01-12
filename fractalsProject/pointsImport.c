#include <stdlib.h>
#include <stdio.h>

int main(void){  
  double valFloat;
  int count = 0;
  while (scanf("%lf", &valFloat) != EOF){
    printf("VAR:myData%i=%1.15f\n", (count++), valFloat); // "f" suffix denotes float for forthytwo.exe
  }
  return EXIT_SUCCESS;
}
