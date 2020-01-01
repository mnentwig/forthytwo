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

    if (argc < 2) {
      fprintf(stderr, "usage: sim <hex-file>\n");
      exit(1);
    }

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
      top->j1b__DOT__ram[i] = v;
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

    for (i = 0; ; i++) {
      top->clk = 1;
      top->eval();
      top->clk = 0;
      top->eval();
      
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
    }
    fprintf(stderr, "NCYC:%li\n", i);
    delete top;

    exit(0);
}
