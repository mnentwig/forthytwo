/* verilator lint_off UNUSED */

// simulation model: VGA clock is 50 % of clk100 

module clk100_148p5 (in100, out148p5);   
   input wire in100;
   output reg out148p5 = 1'b0;
   always @(posedge in100)
     out148p5 <= ~out148p5;
//   output wire out148p5 = in100;
   
endmodule
