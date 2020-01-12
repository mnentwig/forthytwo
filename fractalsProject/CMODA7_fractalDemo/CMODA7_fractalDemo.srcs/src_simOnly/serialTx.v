/* verilator lint_off UNUSED */
module serialTx(clk, out_tx, in_byte, in_strobe, out_busy);
   parameter nBitCycles = 0;

   input wire clk;
   output wire out_tx = 0;
   input wire [7:0] in_byte;
   input       wire in_strobe;
   output      wire out_busy = 0;
endmodule
/* verilator lint_on UNUSED */
