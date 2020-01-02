// This file (c) Markus Nentwig 2020 MIT license

/* verilator lint_off WIDTH */
`default_nettype none
  module stack2
    (input wire 	    clk,
     output reg [31:0] rd,
     input wire        we,
     input wire [1:0]  delta,
     input wire [31:0] wd);
   parameter DEPTH = 18;
   
   reg [31:0] 	       ram[0:DEPTH-1];
   reg [4:0] 	       ptr = 0;

   // Note: Delta=2'b10 (-2) is invalid and not supported, as it would require twice the memory bandwidth
   wire [4:0] 	       ptrN = delta[1] ? ptr-1 : delta[0] ? ptr+1 : ptr;
   always @(posedge clk) begin
      rd <= ram[ptrN]; // preliminary assignment
      if (we) begin
	 ram[ptrN] <= wd;
	 rd <= wd; // write-first RAM operation  
      end
      ptr <= ptrN;
   end
endmodule
/* verilator lint_on WIDTH */