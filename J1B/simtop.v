`default_nettype none
`include "j1.v"

  module simtop(input wire clk,
		input wire 	   reset,
		output wire [15:0] memIo_addr,
		output wire 	   io_rd,
		output wire 	   io_wr,
		input wire [31:0]  io_din,
		output wire [31:0] dout);
   /* verilator lint_off UNUSED */
   
   wire 		mem_wr;
   reg [31:0] 		mem_din;
   wire [12:0] 		code_addr16bitWord;
   reg [15:0] 		insn;
   /* verilator lint_on UNUSED */

   wire [12:0] 		codeaddr_32bitWord = {1'b0, code_addr16bitWord[12:1]};

   reg [31:0] 		ram[0:8191] /* verilator public_flat */;
   always @(posedge clk) begin
      insn <= code_addr16bitWord[0] ? ram[codeaddr_32bitWord][31:16] : ram[codeaddr_32bitWord][15:0];
      if (mem_wr)
	ram[memIo_addr[14:2]] <= dout;
      mem_din <= ram[memIo_addr[14:2]];
   end

   j1 #(.WIDTH(32)) ij1
     (.clk(clk),
      .reset(reset),
      .io_rd(io_rd),
      .io_wr(io_wr),
      .mem_wr(mem_wr),
      .dout(dout),
      .mem_din(mem_din),
      .io_din(io_din),
      .mem_addr(memIo_addr),
      .code_addr(code_addr16bitWord),
      .insn(insn));
endmodule
