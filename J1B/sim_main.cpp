#include <stdio.h>
#include <stdint.h>
#include "Vsimtop.h"
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
  Vsimtop* top = new Vsimtop;
  
  if (argc < 2) {
    fprintf(stderr, "usage: sim <hex-file>\n");
    exit(1);
  }
  
#ifdef MYTRACINGFLAG
  // === tracing ===
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace(tfp, 99);  // Trace 99 levels of hierarchy
  tfp->open("trace.vcd");
#endif
  
    // === load memory contents ===
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
      top->simtop__DOT__ram[i] = v;
    }

    // === load firmware (optional) ===
    char fw[13072];
    int nBytesFw = 0;
    char* fwPtr = fw;
    if (argc > 2){
      FILE* hFirmware = fopen(argv[2], "rb");
      if (hFirmware == NULL){
	fprintf(stderr, "failed to open %s\r\n", argv[2]);
	return(EXIT_FAILURE);
      }
      nBytesFw = fread(fw, /*element bytesize*/1, /*read how many elements*/sizeof(fw), hFirmware);
      //printf("Firmware to UART: %i bytes\n", nBytesFw);
    }

    top->resetq = 0;
    top->eval();
    top->resetq = 1;

    int traceFlag = 1;
    for (i = 0; ; i++) {
      top->clk = 1;
      top->eval();
#ifdef MYTRACINGFLAG
      if (traceFlag) tfp->dump(2*i);
#endif
      top->clk = 0;
      top->eval();
#ifdef MYTRACINGFLAG
      if (traceFlag) tfp->dump(2*i+1);
#endif
      
      // === UART Rx is data ready? ===
      if (top->io_rd && top->memIo_addr == 0x1000)
	top->io_din = 1;

      // === UART Rx get data ===
      if (top->io_rd && top->memIo_addr == 0x1001){
	// === read firmware file ===
	if (nBytesFw > 0){
	  top->io_din = (unsigned char)*(fwPtr++);
	  --nBytesFw;
	} else {
	  top->io_din = getchar();
	}
	//printf("sim: %02x\n", top->io_din);
      }

      // === UART Tx ready to send? ===
      if (top->io_rd && top->memIo_addr == 0x1002)
	top->io_din = 1;

      // === UART Tx send ===
      if (top->io_wr && top->memIo_addr == 0x1003){
        putchar(top->dout);
      }
      
      // === end of simulation ===
      if (top->io_wr && top->memIo_addr == 0x1004)
	break;
     
      // === trace flag control ===
      if (top->io_wr && top->memIo_addr == 0x1005){
        traceFlag = top->dout;
      }
    }
    fprintf(stderr, "NCYC:%li\n", i);
#ifdef MYTRACINGFLAG
    tfp->close();
#endif
    delete top;

    exit(0);
}
