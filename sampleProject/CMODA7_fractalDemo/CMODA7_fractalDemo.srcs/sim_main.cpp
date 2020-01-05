#include <stdio.h>
#include <stdint.h>
#include "Vfpgatop.h"
#include "verilated_vcd_c.h"

double flm2double(int32_t val){
  int32_t exponent = (val << 26) >> 26;
  int32_t mantissa = val >> 6;
  double res = (double)mantissa;
  res = res * pow(2.0, exponent);
  return res;
}

int main(int argc, char **argv){
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);
  Vfpgatop* top = new Vfpgatop;

  // === load memory contents ===
  if (argc >= 2) {
    FILE *hex = fopen(argv[1], "r");
    if (hex == NULL){
      fprintf(stderr, "failed to open %s\r\n", argv[1]);
      return(EXIT_FAILURE);
    }
    uint64_t i;
    for (i = 0; i < 8192; i++) {
      unsigned int v;
      if (fscanf(hex, "%x\n", &v) != 1) {
        fprintf(stderr, "invalid hex value at line %d\n", i + 1);
        exit(1);
      }
      top->fpgatop__DOT__ram[i] = v;
    }
  }
  
  int lastPixRef = 0;

  char* done = (char*)calloc(4000000, 1);
#ifdef MYTRACINGFLAG
  // === tracing ===
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace(tfp, 99);  // Trace 99 levels of hierarchy
  tfp->open("trace.vcd");
#endif
  
  int traceFlag = 1;
  int i;
  for (i = 0; ; i++) {
    top->CLK12 = 1;
    top->eval();
#ifdef MYTRACINGFLAG
      if (traceFlag) tfp->dump(2*i);
#endif
      top->CLK12 = 0;
      top->eval();
#ifdef MYTRACINGFLAG
      if (traceFlag) tfp->dump(2*i+1);
#endif
      
      //printf("%i\n", top->fpgatop__DOT__iTop__DOT__vgaPixRefLoopback);
      if (top->fpgatop__DOT__iTop__DOT__GM_valid){	
	if ((top->fpgatop__DOT__iTop__DOT__GM_pixRef == 0) && (lastPixRef != 0))
	  break;
	lastPixRef = top->fpgatop__DOT__iTop__DOT__GM_pixRef;
	printf("%i\t%i\t%i\n", 
	       top->fpgatop__DOT__iTop__DOT__GM_pixRef, top->fpgatop__DOT__iTop__DOT__GM_res, 
	       top->fpgatop__DOT__iTop__DOT__iGenerator_G__DOT__i_vgaPixRefLoopback);
	if (done[lastPixRef])
	  break;
	done[lastPixRef] = 1;	
      }      
    } // for i
 breakMainLoop:
    fprintf(stderr, "NCYC:%li\n", i);
#ifdef MYTRACINGFLAG
    tfp->close();
#endif
    delete top;

    exit(0);
}
