// This file: taken from https://github.com/jamesbowman/swapforth/tree/master/j1b/verilog
// license source: https://github.com/jamesbowman/swapforth/blob/master/LICENSE
//
// Copyright (c) 2015, James Bowman
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of swapforth nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// (modifications 2020 by Markus Nentwig)
`default_nettype none
  module j1(clk, reset, io_rd, io_wr, mem_addr, mem_wr, dout, mem_din, io_din, code_addr, insn);
   parameter WIDTH=32;   
   input wire 		  clk;
   input wire 		  reset;
   
   output wire 		  io_rd;
   output wire 		  io_wr;
   output wire [15:0] 	  mem_addr;
   output wire 		  mem_wr;
   output wire [WIDTH-1:0] dout;
   input wire [WIDTH-1:0]  mem_din;
   
   input wire [WIDTH-1:0]  io_din;
   
   output wire [12:0] 	   code_addr;
   input wire [15:0] 	   insn;
      
   wire [4:0] 		   depth;   
   reg [WIDTH-1:0] 	   st0;     // Top of data stack
   reg [WIDTH-1:0] 	   st0N;
   reg 			   dstkW = 1'b0;                // D stack write
   reg [1:0] 		   dspI, rspI;
   
   reg [12:0] 		   pc = 13'd0;
   reg [12:0] 		   pcN;   
   reg 			   rstkW = 1'b0;          // R stack write
   wire [WIDTH-1:0] 	   rstkD;   // R stack write value
   reg 			   reboot = 1;
   wire [12:0] 		   pc_plus_1 = pc + 1;
   
   assign mem_addr = st0[15:0];
   assign code_addr = {pcN};
   
   // The D and R stacks
   wire [WIDTH-1:0] 	   st1, rst0;
   stack2 #(.DEPTH(32)) dstack(.clk(clk), .rd(st1),  .we(dstkW), .wd(st0),   .delta(dspI), .depth(depth), .reset(reset));   
   wire [4:0] 		   unused;   
   stack2 #(.DEPTH(32)) rstack(.clk(clk), .rd(rst0), .we(rstkW), .wd(rstkD), .delta(rspI), .depth(unused), .reset(reset));
   
   always @*
     begin
	// Compute the new value of st0
	casez ({insn[15:8]})
	  8'b1??_?????: st0N = { {(WIDTH - 15){1'b0}}, insn[14:0] };    // literal
	  8'b000_?????: st0N = st0;                     // jump
	  8'b010_?????: st0N = st0;                     // call
	  8'b001_?????: st0N = st1;                     // conditional jump
	  8'b011_?0000: st0N = st0;                     // ALU operations...
	  8'b011_?0001: st0N = st1;
	  8'b011_?0010: st0N = st0 + st1;
	  8'b011_?0011: st0N = st0 & st1;
	  8'b011_?0100: st0N = st0 | st1;
	  8'b011_?0101: st0N = st0 ^ st1;
	  8'b011_?0110: st0N = ~st0;
	  8'b011_?0111: st0N = {WIDTH{(st1 == st0)}};
	  8'b011_?1000: st0N = {WIDTH{($signed(st1) < $signed(st0))}};
	  8'b011_?1001: st0N = st1 >> st0[4:0];
	  8'b011_?1010: st0N = st1 << st0[4:0];
	  8'b011_?1011: st0N = rst0;
	  8'b011_?1100: st0N = mem_din;
	  8'b011_?1101: st0N = io_din;
	  8'b011_?1110: st0N = {{(WIDTH - 5){1'b0}}, depth};
	  8'b011_?1111: st0N = {WIDTH{(st1 < st0)}};
	  default: st0N = {WIDTH{1'bx}};
	endcase
     end

   wire func_T_N =   (insn[6:4] == 1);
   wire func_T_R =   (insn[6:4] == 2);
   wire func_write = (insn[6:4] == 3);
   wire func_iow =   (insn[6:4] == 4);
   wire func_ior =   (insn[6:4] == 5);

   wire is_alu = (insn[15:13] == 3'b011);
   assign mem_wr = !reboot & is_alu & func_write;
   assign dout = st1;
   assign io_wr = !reboot & is_alu & func_iow;
   assign io_rd = !reboot & is_alu & func_ior;

   assign rstkD = (insn[13] == 1'b0) ? {{(WIDTH - 14){1'b0}}, pc_plus_1, 1'b0} : st0;
   
   always @*
     begin
	casez ({insn[15:13]})
	  3'b1??:   {dstkW, dspI} = {1'b1,      2'b01};
	  3'b001:   {dstkW, dspI} = {1'b0,      2'b11};
	  3'b011:   {dstkW, dspI} = {func_T_N,  insn[1:0]};
	  default:  {dstkW, dspI} = {1'b0,      2'b00000};
	endcase

	casez ({insn[15:13]})
	  3'b010:   {rstkW, rspI} = {1'b1,      2'b01};
	  3'b011:   {rstkW, rspI} = {func_T_R,  insn[3:2]};
	  default:  {rstkW, rspI} = {1'b0,      2'b00};
	endcase

	casez ({reboot, insn[15:13], insn[7], |st0})
	  6'b1_???_?_?:   pcN = 0;
	  6'b0_000_?_?,
	    6'b0_010_?_?,
	    6'b0_001_?_0:   pcN = insn[12:0];
	  6'b0_011_1_?:   pcN = rst0[13:1];
	  default:        pcN = pc_plus_1;
	endcase
     end

   always @(posedge clk)
     begin
	if (reset) begin
	   reboot <= 1'b1;
	   { pc, st0 } <= 0;
	end else begin
	   reboot <= 0;
	   { pc, st0 } <= { pcN, st0N };	   
	end
     end
endmodule
