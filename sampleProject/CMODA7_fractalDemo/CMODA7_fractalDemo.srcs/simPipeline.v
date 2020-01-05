`include "mandel.v"
module tb();   
   
   // === simulation clock ===
   reg clk = 1'b0;   
   always begin
      #5 clk <= 1'b1;
      #5 clk <= 1'b0;
   end

   parameter vgaX = 640; parameter vgaY = 480;

   localparam nResBits = 16;
   localparam nRefBits = 24;
   localparam nMemBits = 12;   
   
   // ================================================================================
   // fractal image generation
   // ================================================================================
   wire       GM_valid;
   wire [nResBits-1:0] GM_res;
   wire [nRefBits-1:0] GM_pixRef;
   reg [nRefBits-1:0]  vgaPixRefLoopback = 0;
   reg 		       run = 0;   
   
   generator #(.vgaX(vgaX), .vgaY(vgaY), .nResBits(nResBits), .nRefBits(nRefBits), .nMemBits(nMemBits)) iGenerator_G 
     (.clk(clk), .i_vgaPixRefLoopback(vgaPixRefLoopback),
      .o_valid(GM_valid), .i_ready(1'b1), .o_res(GM_res), .o_pixRef(GM_pixRef), .i_maxiter(8'd10), 
      .i_x0(32'hc0000020), .i_y0(32'hc0000020), .i_dx(32'h00111357*3), .i_dy(32'h001e5e6d*3), .i_run(run));
   
   initial begin
      #10000 run = 1;
      vgaPixRefLoopback <= 30000000;
   end
   
   initial begin 
      $dumpfile("c:/temp/out.lx2");
      $dumpvars(0, iGenerator_G); // all hierarchical variables
      //$dumpvars(1, iGenerator_G); // only toplevel variables
   end

   // ================================================================================
   // data logging
   // ================================================================================
   integer 		     outFile;   
   initial outFile = $fopen("output.txt","w");
   reg [31:0] 		     resCount = 0;   
   always @(posedge clk) if (GM_valid) begin 
      $fwrite(outFile, "%d %d\n", GM_pixRef, GM_res);
      resCount <= resCount + 1;
      if (resCount == vgaX*vgaY-1)
	$finish();
   end
endmodule
