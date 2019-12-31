#include <stdio.h>
#include <stdint.h>
#include "Vj1b.h"
#include "verilated_vcd_c.h"

double flm2double(int32_t val){
  int32_t exponent = (val << 26) >> 26;
  int32_t mantissa = val >> 6;
  double res = (double)mantissa;
  res = res * pow(2.0, exponent);
  return res;
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vj1b* top = new Vj1b;

    if (argc != 2) {
      fprintf(stderr, "usage: sim <hex-file>\n");
      exit(1);
    }

    FILE *hex = fopen(argv[1], "r");
    uint64_t i;
    for (i = 0; i < 8192; i++) {
      unsigned int v;
      if (fscanf(hex, "%x\n", &v) != 1) {
        fprintf(stderr, "invalid hex value at line %d\n", i + 1);
        exit(1);
      }
      top->j1b__DOT__ram[i] = v;
    }

    top->resetq = 0;
    top->eval();
    top->resetq = 1;
    top->uart0_valid = 1;   // pretend to always have a character waiting

    for (i = 0; ; i++) {
      top->clk = 1;
      top->eval();
      top->clk = 0;
      top->eval();

      // IO write to 0x0000: exit
      if (top->j1b__DOT__io_wr_ && top->j1b__DOT__io_addr_ == 0){
	break;
      }

      if (top->uart0_wr) {
        // end character - finish
	if (top->uart_w == 4) 
	  break;
        putchar(top->uart_w);
      } else {
	// printf for flm floating point values
	if (top->j1b__DOT__io_wr_ && top->j1b__DOT__io_addr_ == 0x4000){
	  printf("%1.15f", flm2double(top->j1b__DOT__dout_));	
	} else if (top->j1b__DOT__io_wr_){
	  printf("IOW:%8x\t%08x\n", top->j1b__DOT__io_addr_, top->j1b__DOT__dout_);
	}
      }
      if (top->uart0_rd) {
        int c = getchar();
        if (c == EOF) break;
        top->uart0_data = (c == '\n') ? '\r' : c;
      }
    }
    fprintf(stderr, "NCYC:%li\n", i);
    delete top;

    exit(0);
}
