/* verilator lint_off UNUSED */

// simulation model: VGA clock is 50 % of clk100 

module clk100_148p5 (in100, out148p5);   
   input wire in100;
   reg [1:0]  counter = 0;
   //output reg out148p5 = 0;
   //always @(posedge in100) begin
   //   counter <= counter + 1;
   //   out148p5 <= counter[0];
   //end
   output wire out148p5 = in100;
   
endmodule
