`default_nettype none
  module pixScanner(i_clk, 
		      i_startValid, o_startReady, i_xStart, i_yStart, i_dxCol, i_dyCol, i_dxRow, i_dyRow,
		      o_dataValid, i_dataReady, o_x, o_y, o_ref);
   parameter nRefBits = -1;
   parameter nX = -1;
   parameter nY = -1;

   input wire i_clk;

   // === input-side interface ===
   input wire i_startValid;
   output wire o_startReady;
   
   input wire signed [31:0] i_xStart;
   input wire signed [31:0] i_yStart;
   input wire signed [31:0] i_dxCol;
   input wire signed [31:0] i_dyCol;
   input wire signed [31:0] i_dxRow;
   input wire signed [31:0] i_dyRow;

   // === output-side interface ===
   output wire 		    o_dataValid;   
   input wire 		    i_dataReady;
   output wire signed [31:0] o_x;
   output wire signed [31:0] o_y;
   output reg [nRefBits-1:0] o_ref;
   
   // ---------------------------------------------------------------------------   
   reg [11:0] 			  refX; // sufficient up to 1920x1080
   reg [11:0] 			  refY;
   
   reg signed [31:0] 		  xStart;
   reg signed [31:0] 		  yStart;
   reg signed [31:0] 		  dxCol;
   reg signed [31:0] 		  dyCol;
   reg signed [31:0] 		  dxRow;
   reg signed [31:0] 		  dyRow;
   reg signed [31:0] 		  accXCol;
   reg signed [31:0] 		  accYCol;
   reg signed [31:0] 		  accXRow;
   reg signed [31:0] 		  accYRow;
   
   reg  			  state = 0;
   assign o_startReady = ~state;
   
   localparam INV = 128'dx;   
   assign o_dataValid = state;
   assign o_x = o_dataValid ? accXCol : INV;
   assign o_y = o_dataValid ? accYCol : INV;   
   always @(posedge i_clk) begin
      if (state == 1'b0) begin
	 if (i_startValid) begin
	    state <= 2'd1;
	    xStart <= i_xStart;
	    yStart <= i_yStart;
	    dxCol <= i_dxCol;
	    dyCol <= i_dyCol;
	    dxRow <= i_dxRow;
	    dyRow <= i_dyRow;
	    accXCol <= i_xStart;
	    accYCol <= i_yStart;
	    accXRow <= i_xStart;
	    accYRow <= i_yStart;
	    refX <= nX-1;
	    refY <= nY-1;
	    o_ref <= 0;	    
	 end // if (i_startValid)
      end else if (i_dataReady) begin
	 if ((refX == 0) && (refY == 0)) begin
	    // === done ===
	    state <= 2'd0;
	    dxCol <= INV;
	    dyCol <= INV;
	    dxRow <= INV;
	    dyRow <= INV;
	    accXCol <= INV;
	    accYCol <= INV;
	    accXRow <= INV;
	    accYRow <= INV;
	    refX <= INV;
	    refY <= INV;
	    o_ref <= INV;	    
	 end else if (refX == 0) begin
	       // === advance row ===
	    accXRow <= accXRow + dxRow;
	    accYRow <= accYRow + dyRow;
	    refY <= refY-1;
	    
	    // === reset column ===
	    accXCol <= accXRow + dxRow;
	    accYCol <= accYRow + dyRow;
	    refX <= nX-1;

	    o_ref <= o_ref + 1;	    
	 end else begin
	    // === advance column ===
	    accXCol <= accXCol + dxCol;
	    accYCol <= accYCol + dyCol;
	    refX <= refX - 1;

	    o_ref <= o_ref + 1;	    
	 end // else: !if(refX == 0)
      end // if (i_dataReady)      
   end // always @ (posedge i_clk)
endmodule

module trigger(i_clk, 
	       i_vgaPixRefLoopback, i_run, o_frameCount,
	       i_ready, o_valid);
   parameter nRefBits = -1; initial if (nRefBits < 0) $error("missing parameter");   
   
   input wire i_clk;
   input wire [nRefBits-1:0] i_vgaPixRefLoopback;
   input wire 		     i_run;
   output reg [3:0] 	     o_frameCount = 0;      
   
   input wire 		     i_ready;   
   output reg 		     o_valid = 0;
      
   reg 			     isRunning = 1'b0;
   reg [nRefBits-1:0] 	     pixRefPrev = 0;   
   reg 			     enabled = 1'b0; // register input for timing 

   wire 		     starting = o_valid & i_ready;
   
   always @(posedge i_clk) begin
      enabled <= i_run;
      o_valid <= enabled & ~isRunning & ~starting;

      if (starting) begin      
	 // === detect acknowledged trigger ===
	 // "Contract" with the CPU: Frame count increases after the 
	 // input data registers from the CPU have been read (which is on trigger)
	 o_frameCount <= o_frameCount + 1;
	 isRunning <= 1'b1;
      end
      
      if (isRunning) begin
	 // === detect electron beam return ===
	 pixRefPrev <= i_vgaPixRefLoopback;
	 if ((i_vgaPixRefLoopback == 0) && (pixRefPrev != 0)) begin
	    isRunning <= 1'b0;
	 end
      end
   end
endmodule

`ifdef SIM_PIXSCANNER
// ================================================
// testbench
// ================================================
module top();
   localparam nRefBits = 24;
   
   // === simulation clock ===
   reg clk = 0;
   always begin
      #10 clk <= 1;
      #10 clk <= 0;
   end

   localparam nX = 15;
   localparam nY = 16;
   
   initial begin 
      $dumpfile("c:/temp/out.lx2");
      $dumpvars(0, top);
   end
   wire [nRefBits-1:0] vgaPixRefLoopback;
   
   
   // === simulation start ====
   reg 		       run = 0;
   initial begin #100 run <= 1; end   
		      
   // === start generator === 
   wire startValid;
   wire startReady;      
   trigger #(.nRefBits(24)) iDut1 (.i_clk(clk), 
			    .i_vgaPixRefLoopback(vgaPixRefLoopback), .i_run(run), .o_frameCount(),
			    .i_ready(startReady), .o_valid(startValid));
      
   // === start generator === 
   wire [31:0] outX;
   wire [31:0] outY;
   wire [23:0] outRef;
   output wire 		    dataValid;   
   input wire 		    dataReady;
   pixScanner #(.nX(nX), .nY(nY), .nRefBits(24)) iDut2
   (.i_clk(clk), 
    .i_startValid(startValid), .o_startReady(startReady), 
    .i_xStart(32'h10000000), .i_yStart(32'h20000000), 
    .i_dxCol(32'h00000001), .i_dyCol(32'h00000010), 
    .i_dxRow(32'h00000100), .i_dyRow(32'h00001000),
    .o_dataValid(dataValid), .i_dataReady(dataReady), .o_x(outX), .o_y(outY), .o_ref(outRef));
   
   // randomize accept pattern
   reg [14:0] 		    accept = 15'b111100110010100;
   assign dataReady = accept[14];
   
   reg [31:0] 		     count = nX * nY - 1;
   
   always @ (posedge clk) begin
      accept <= {accept[13:0], accept[14]};      
      if (dataValid & dataReady) begin
	 $display("0x%08x", outX, " 0x%08x", outY);
	 if (count == 0)
	   $finish();	 
	 count <= count - 1;	 
      end
   end
endmodule // top
`endif