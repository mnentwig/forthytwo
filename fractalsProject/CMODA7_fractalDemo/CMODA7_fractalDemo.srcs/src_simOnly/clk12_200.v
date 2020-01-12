/* verilator lint_off UNUSED */

// clock model. CPU and fractal engine run at the same frequency (they differ in FPGA implementation)
module clk12_200 (in12, out100, out200, out300);
   input wire in12;
   output wire out100 = in12;
   output wire out200 = in12;
   output reg  out300 = 1'b0;      
endmodule
