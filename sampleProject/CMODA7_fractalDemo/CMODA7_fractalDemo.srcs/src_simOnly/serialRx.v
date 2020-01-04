/* verilator lint_off UNUSED */
module serialRx(clk, in_rx, out_byte, out_strobe);
   input wire clk;
   input wire in_rx;
   parameter nHalfBitCycles = 0;
   output reg	    out_strobe = 0;   
   output wire [7:0]     out_byte = 8'd0;
endmodule // serialRx
/* verilator lint_on UNUSED */
