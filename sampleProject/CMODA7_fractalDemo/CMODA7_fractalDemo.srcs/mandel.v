// Mandelbrot set generator
// (c) Markus Nentwig 2019

// VGA: See https://faculty-web.msoe.edu/johnsontimoj/EE3921/files3921/vga.pdf

// note: standard handshaking protocol (valid / ready), see https://inst.eecs.berkeley.edu/~cs150/Documents/Interfaces.pdf
`default_nettype none
  /* verilator lint_off DECLFILENAME */
  
  module binaryToGray(i_bin, o_gray);
   parameter nBits = -1;
   input wire [nBits-1:0] i_bin;
   output wire [nBits-1:0] o_gray;
   assign o_gray = i_bin ^ (i_bin >> 1); 
endmodule

module grayToBinary(i_gray, o_bin);
   parameter nBits = -1;
   input wire [nBits-1:0] i_gray;
   output wire [nBits-1:0] o_bin;
   generate
      genvar 		   ix;
      for (ix = 0; ix < nBits; ix = ix + 1) begin
	 assign o_bin[ix] = ^i_gray[nBits-1:ix];
      end
   endgenerate
endmodule

module FIFO(i_clk, 
	    i_inboundValid, o_inboundReady, i_inboundData,
	    o_outboundValid, i_outboundReady, o_outboundData);
   parameter nBits = -1;
   parameter nLevels = 2;
   localparam cWidth = nLevels <= 4 ? 2 : nLevels <= 8 ? 3 : nLevels <= 16 ? 4 : 16;
   
   input wire i_clk;
   input wire i_inboundValid;
   output wire o_inboundReady;
   input wire [nBits-1:0] i_inboundData;   
   output wire 		  o_outboundValid;
   input wire 		  i_outboundReady;   
   output wire [nBits-1:0] o_outboundData;
   localparam INV = 128'dx;
   
   reg [cWidth-1:0] 	   posIn = 0;
   reg [cWidth-1:0] 	   posOut = 0;
   reg [cWidth:0] 	   level = 0;
   reg [nBits-1:0] 	   FIFO_mem [0:nLevels-1];
   wire [cWidth-1:0] 	   posInOnPush = posIn == nLevels-1 ? 0 : posIn + 1;
   wire [cWidth-1:0] 	   posOutOnPop = posOut == nLevels-1 ? 0 : posOut + 1;
   wire 		   push = i_inboundValid & o_inboundReady;
   wire 		   pop = o_outboundValid & i_outboundReady;
   
   assign o_inboundReady = level != nLevels;
   assign o_outboundValid = (level != 0);
   assign o_outboundData = o_outboundValid ? FIFO_mem[posOut] : INV;
   
   always @(posedge i_clk) begin
      if (push) begin 
	 FIFO_mem[posIn] <= i_inboundData;
	 posIn <= posInOnPush;
      end
      if (pop) begin
	 FIFO_mem[posOut] <= INV;
	 posOut <= posOutOnPop;	 
      end
      case ({push, pop})
	2'b10: level <= level + 1;
	2'b01: level <= level - 1;
	default: begin end
      endcase
   end
endmodule

module CDC(iA_clk, iA_data,
	   iB_clk, oB_data);
   parameter nBits = -1; initial if (nBits < 0) $error("missing parameter");

   input wire iA_clk;
   input wire [nBits-1:0] iA_data;

   input wire 		  iB_clk;
   output reg [nBits-1:0] oB_data = 0;
   
   wire [nBits-1:0] 	  d0;   
   reg [nBits-1:0] 	  d1 = 0;
   // ASYNC_REG in multi-bit context gives a warning. This may be disregarded (using Gray code for the very same reason)
   (*ASYNC_REG = "true"*) reg [nBits-1:0]  d2 = 0;
   (*ASYNC_REG = "true"*) reg [nBits-1:0]  d3 = 0;
   wire [nBits-1:0] 	  d4;
   reg [nBits-1:0] 	  d5 = 0;
   
   binaryToGray #(.nBits(nBits)) i1 (.i_bin(iA_data), .o_gray(d0));
   grayToBinary #(.nBits(nBits)) i2(.i_gray(d3), .o_bin(d4));
   
   always @(posedge iA_clk) begin
      d1 <= d0;      
   end
   always @(posedge iB_clk) begin
      d2 <= d1; // synchronizer 1
      d3 <= d2; // synchronizer 2
      d5 <= d4; // need at least one reg here to close timing (this path goes all the way across the design)
      oB_data <= d5; // additional reg to simplify P&R
   end
endmodule

module vga(i_clk, i_run, o_blank, o_HSYNC, o_VSYNC, o_pix);
   parameter nX = -1; initial if (nX < 0) $error("missing parameter");
   parameter nY = -1; initial if (nY < 0) $error("missing parameter");
   parameter nRefBits = -1; initial if (nRefBits < 0) $error("missing parameter");
   
   input wire i_clk;
   input wire i_run;   
   output wire o_blank;   
   output reg  o_HSYNC; // init value assigned below
   output reg  o_VSYNC; // init value assigned below
   output reg [nRefBits-1:0] o_pix = 0;
   
   localparam res1920x1080 = ((nX == 1920) && (nY == 1080));
   localparam res640x480 = ((nX == 640) && (nY == 480));
   localparam INV = 32'dx;
   
   // note: according to the VGA standard section 3.5, HSYNC is asserted on deassertion of VSYNC (a new line starts with HSYNC)
   // row content is [hsync, back porch, image, front porch]
   localparam x_sync = res1920x1080 ? 44 : res640x480 ? 96 : INV;
   localparam x_bp = res1920x1080 ? 148 : res640x480 ? 40 : INV;   
   localparam x_img = res1920x1080 ? 1920 : res640x480 ? 640 : INV;   
   localparam x_fp = res1920x1080 ? 88 : res640x480 ? 8 : INV; 
   
   localparam y_bp = res1920x1080 ? 36 : res640x480 ? 25 : INV;
   localparam y_img = res1920x1080 ? 1080 : res640x480 ? 480 : INV;
   localparam y_fp = res1920x1080 ? 4 : res640x480 ? 2 : INV;
   localparam y_sync = res1920x1080 ? 5 : res640x480 ? 2 : INV;
   
   localparam hsyncAsserted = res1920x1080 ? 1 : res640x480 ? 0 : INV;
   localparam vsyncAsserted = res1920x1080 ? 1 : res640x480 ? 0 : INV;   
   localparam hsyncDeasserted = ~hsyncAsserted;   
   localparam vsyncDeasserted = ~vsyncAsserted;

   reg [11:0] 		     x = 0;
   reg [11:0] 		     y = 0;
   
   reg 			     blankH = 1;
   reg 			     blankV = 1;
   assign o_blank = blankH | blankV;   
   initial begin
      o_HSYNC = hsyncDeasserted;
      o_VSYNC = vsyncDeasserted;
   end
   
   wire [11:0] xPlus1 = x + 12'd1;
   wire [11:0] yPlus1 = y + 12'd1;
   always @(posedge i_clk) begin
      x <= xPlus1; // prelim. assignment
      o_pix <= (blankH | blankV) ? o_pix : o_pix + 1; // prelim. assignment      
      case (xPlus1)
	x_sync: 
	  o_HSYNC <= hsyncDeasserted;
	x_sync + x_bp: 
	  blankH <= 0;
	x_sync + x_bp + x_img: 
	  blankH <= 1;
	x_sync + x_bp + x_img + x_fp: 
	  begin 
	     o_HSYNC <= hsyncAsserted;
	     x <= 0;
	     y <= yPlus1; // prelim. assignment	   
	     case (yPlus1)
	       y_fp: o_VSYNC <= vsyncAsserted;
	       y_fp + y_sync: o_VSYNC <= vsyncDeasserted;
	       y_fp + y_sync + y_bp: blankV <= 0;
	       y_fp + y_sync + y_bp + y_img : begin
		  blankV <= 1;
		  o_pix <= 0;
		  y <= 0;		
	       end	     
	       default: begin end
	     endcase
	     //$display("vga y=", y, " o_pix=", o_pix);
	  end
	default: begin end
      endcase

      if (~i_run) begin
	 o_HSYNC <= hsyncDeasserted;
	 o_VSYNC <= vsyncDeasserted;
	 x <= 0;
	 y <= 0;
	 o_pix <= 0;	 
      end
   end
endmodule

module dpmem(i_clkA, i_weA, i_addrA, i_dataA,
	     i_clkB, i_addrB, o_dataB, 
	     // bypass with equivalent delay to port B read
	     i_bypassB, o_bypassB);
   parameter NBITADDR = 0; // number of address bits
   parameter NBITDATA = 0; // number of data bits
   parameter NBITBYPASS = 0; // number of bypass bits
   
   input wire i_clkA;
   input wire i_weA;
   input wire [NBITADDR-1:0] i_addrA;
   input wire [NBITDATA-1:0] i_dataA;

   input wire 		     i_clkB;
   input wire [NBITADDR-1:0] i_addrB;
   output reg [NBITDATA-1:0] o_dataB;
   input wire [NBITBYPASS-1:0] i_bypassB;   
   output reg [NBITBYPASS-1:0] o_bypassB;
   reg [NBITDATA-1:0] 	       mem [0:2**NBITADDR-1];   
   
   // register level will be absorbed into BRAM
   reg 			       weA = 0;
   reg [NBITADDR-1:0] 	       addrA;
   reg [NBITDATA-1:0] 	       dataA;
   
   always @(posedge i_clkA) begin
      weA 	<= i_weA;
      addrA 	<= i_addrA;
      dataA 	<= i_dataA;
      
      if (weA) 
	mem[addrA] <= dataA;
   end
   
   // register level will be absorbed into BRAM
   reg [NBITDATA-1:0] 	     dataB2;
   reg [NBITBYPASS-1:0]      bypassB2;

   always @(posedge i_clkB) begin
      dataB2 	<= mem[i_addrB];	 
      o_dataB 	<= dataB2;
      bypassB2 	<= i_bypassB;
      o_bypassB <= bypassB2;
   end
endmodule

// scans all pixels sequentially
module pixelScanner(i_clk, 
		    i_startValid, o_startReady, i_xStart, i_yStart, i_dx, i_dy, 
		    o_dataValid, i_dataReady, o_x, o_y, o_ref,
		    o_frameCount);
   parameter nBits = -1; initial if (nBits < 0) $error("missing parameter");
   parameter nRefBits = -1; initial if (nRefBits < 0) $error("missing parameter");
   parameter fracbitsDelta = -1;  initial if (fracbitsDelta < 0) $error("missing parameter");
   parameter nX = -1; initial if (nX < 0) $error("missing parameter");
   parameter nY = -1; initial if (nY < 0) $error("missing parameter");

   input wire i_clk;

   // === input-side interface ===
   input wire i_startValid;
   output wire o_startReady;   
   input wire signed [nBits-1:0] i_xStart;
   input wire signed [nBits-1:0] i_yStart;
   input wire signed [nBits-1:0] i_dx;
   input wire signed [nBits-1:0] i_dy;

   // === output-side interface ===
   output wire 			 o_dataValid;   
   input wire 			 i_dataReady;
   output wire signed [nBits-1:0] o_x;
   output wire signed [nBits-1:0] o_y;
   output reg [nRefBits-1:0] 	  o_ref;
   output wire [3:0] 		  o_frameCount;
   
   reg [11:0] 			  refX; // sufficient up to 1920x1080
   reg [11:0] 			  refY;
   
   reg signed [nBits-1:0] 	  xStart;
   reg signed [nBits-1:0] 	  yStart;
   reg signed [nBits-1:0] 	  dx;
   reg signed [nBits-1:0] 	  dy;
   reg signed [nBits+fracbitsDelta-1:0] accX;
   reg signed [nBits+fracbitsDelta-1:0] accY;
   
   reg 					running = 0;
   
   localparam INV = 128'dx;   
   assign o_startReady = ~running & (~i_startValid);
   assign o_dataValid = running;   
   assign o_x = o_dataValid ? xStart + (accX >>> fracbitsDelta) : INV;
   assign o_y = o_dataValid ? yStart + (accY >>> fracbitsDelta) : INV;
   
   reg [3:0] 				frameCount = 0;   
   assign o_frameCount = frameCount;
   always @(posedge i_clk) begin
      if (~running) begin
	 if (i_startValid) begin
	    xStart <= i_xStart;
	    yStart <= i_yStart;
	    dx <= i_dx;
	    dy <= i_dy;
	    
	    accX <= 64'd0;
	    accY <= 64'd0;
	    refX <= 0;
	    refY <= 0;

	    o_ref <= 0;	    
	    running <= 1;

	    // "Contract" with the CPU: Frame count increases after the 
	    // input data registers from the CPU have been read
	    frameCount <= frameCount + 1;	    
	 end
      end else begin
	 if (i_dataReady) begin
	    // === outbound data was accepted ("running" implies "o_dataValid") ===
	    if (refX < nX-1) begin
	       o_ref <= o_ref + 1;
	       refX <= refX + 1;	    
	       accX <= accX + dx;
	    end else if (refY < nY-1) begin
	       o_ref <= o_ref + 1;
	       refX <= 0;
	       accX <= 64'd0;
	       refY <= refY + 1;	    
	       accY <= accY + dy;
	    end else begin
	       running <= 0;
	       o_ref <= INV;	       
	       refX <= INV;
	       accX <= INV;
	       refY <= INV;
	       accY <= INV;
	       xStart <= INV;
	       yStart <= INV;
	       dx <= INV;
	       dy <= INV;	       
	    end
	 end
      end
   end
endmodule

// tests whether i_val is outside -2:+2 interval (limits treated as outside)
module clipPlusMinus2(i_val, o_clipPlus, o_clipMinus);
   parameter nBits = -1;
   parameter nFracBits = -1;
   input wire [nBits-1:0] i_val;
   output wire 		  o_clipPlus;
   output wire 		  o_clipMinus;
   
   localparam intMsb = nBits-1;
   localparam intLsb = nFracBits;
   localparam intLsbTest = intLsb + 1; // testing against 2
   
   wire 		  isPositive = ~i_val[nBits-1];      
   assign o_clipPlus = isPositive & |i_val[intMsb:intLsbTest];

   wire 		  isNegative = ~isPositive;
   assign o_clipMinus = isNegative & ~&i_val[intMsb:intLsbTest];   
endmodule

// calculates Mandelbrot set iterations
// note, the order of points at the output depends on the iteration length (refX/Y identifies points)
// [note 4]: The valid/ready logic is combinational through the block (use external FIFO to decouple)
module julia (i_clk, 
	      i_inputValid, o_inputReady, i_x0, i_y0, i_pixRef,
	      o_resultValid, i_resultReady, o_result, o_pixRef, 
	      i_maxiter, i_pixRefLimit);
   // === parameters ===
   parameter nBitsIn = -1; initial if (nBitsIn < 0) $error("missing parameter");  
   parameter nFracBitsIn = -1; initial if (nFracBitsIn < 0) $error("missing parameter");
   parameter nBitsInternal = -1; initial if (nBitsInternal < 0) $error("missing parameter");  
   parameter nFracBitsInternal = -1; initial if (nFracBitsInternal < 0) $error("missing parameter");   
   parameter nResBits=-1; initial if (nResBits < 0) $error("missing parameter");
   parameter nRefBits=-1; initial if (nRefBits < 0) $error("missing parameter");  

   // === constants ===
   localparam nPipeline=12; // 18 / 3 / 11 / 16 works with 0.5 ns to spare
   localparam FIRST = 0;   
   localparam LAST = nPipeline-1;   
   localparam PL1 = 3; // xx, yy, xy are calculated at this pipeline level
   localparam PL2 = 7; // next round X, Y are calculated at this pipeline level
   localparam PL3 = 10;
   localparam INV = 128'dx;

   // === ports ===
   input wire i_clk;
   input wire i_inputValid;
   output wire o_inputReady;
   input wire signed [nBitsIn-1:0] i_x0;
   input wire signed [nBitsIn-1:0] i_y0;
   input wire [nRefBits-1:0] 	   i_pixRef;
   output wire 			   o_resultValid;   
   input wire signed 		   i_resultReady;   
   output wire [nResBits-1:0] 	   o_result;
   output wire [nRefBits-1:0] 	   o_pixRef;
   input wire [7:0] 		   i_maxiter;   
   input wire [nRefBits-1:0] 	   i_pixRefLimit;
   
   // === PL state: lifetime over n iterations ===
   reg signed [nBitsInternal-1:0]  x[LAST:FIRST];
   reg signed [nBitsInternal-1:0]  y[LAST:FIRST];
   reg signed [nBitsIn-1:0] 	   x0[LAST:FIRST];
   reg signed [nBitsIn-1:0] 	   y0[LAST:FIRST];
   reg [nResBits-1:0] 		   res[LAST:FIRST];
   reg [2:0] 			   state[LAST:FIRST];
   reg [nRefBits-1:0] 		   pixRef[LAST:FIRST];
   
   // === PL state: lifetime within 1 iteration ===
   reg signed [2*nBitsInternal-1:0] xx[LAST:FIRST];
   reg signed [2*nBitsInternal-1:0] yy[LAST:FIRST];
   reg signed [2*nBitsInternal-1:0] xy[LAST:FIRST];
   reg signed [2*nBitsInternal-1:0] magSquared[LAST:FIRST];
   reg 				    sat[LAST:FIRST];   
   
   localparam ST_IDLE = 3'b001;
   localparam ST_RUN = 3'b010;
   localparam ST_DONE = 3'b100;
   
   genvar 			    ix;
   // === init pipeline to idle ===
   for (ix = FIRST; ix <= LAST; ix = ix + 1)
     initial state[ix] = ST_IDLE;

   // === input new data to pipeline? [note 4] ===
   wire 			    plEnter = i_inputValid & o_inputReady;

   assign o_resultValid = (state[LAST] == ST_DONE) & // have result for output
			  (pixRef[LAST] < i_pixRefLimit); // flow control
   assign o_result = res[LAST];
   assign o_pixRef = pixRef[LAST];   
   
   // === output result from pipeline? [note 4] ===
   wire 			    plExit = o_resultValid & 
				    i_resultReady; // downstream sink accepts

   assign o_inputReady = (state[LAST] == ST_IDLE) // no data looping around
     | plExit; // or looping data exits
   
   // === input data clipping ===
   // necessary because internal bit width is not sufficient for input values outside -2..2 interval
   // any |x| or |y| > 2 causes immediate iteration exit
   // note, >= is a cheaper approximation to > but the difference is a corner case (4 pixels max)
   localparam clipLvl = 2;

   wire 			    clipInA;
   wire 			    clipInB;
   wire 			    clipInC;
   wire 			    clipInD;
   clipPlusMinus2 #(.nBits(nBitsIn), .nFracBits(nFracBitsIn)) iClipInX (.i_val(i_x0), .o_clipPlus(clipInA), .o_clipMinus(clipInB));
   clipPlusMinus2 #(.nBits(nBitsIn), .nFracBits(nFracBitsIn)) iClipInY (.i_val(i_y0), .o_clipPlus(clipInC), .o_clipMinus(clipInD));
   wire 			    inputDiverges = clipInA | clipInB | clipInC | clipInD;
   
   // === pipeline: first row ===
   always @(posedge i_clk) begin
      x0[FIRST] 	<= plEnter ? i_x0 	: x0[LAST];		 
      y0[FIRST] 	<= plEnter ? i_y0 	: y0[LAST];		 
      pixRef[FIRST] 	<= plEnter ? i_pixRef 	: pixRef[LAST];
      x[FIRST] 		<= plEnter ? (i_x0 >>> (nFracBitsIn - nFracBitsInternal)) : x[LAST];
      y[FIRST] 		<= plEnter ? (i_y0 >>> (nFracBitsIn - nFracBitsInternal)) : y[LAST];
      res[FIRST] 	<= plEnter ? 0 : res[LAST];
      state[FIRST] 	<= plEnter ? (inputDiverges ? ST_DONE : ST_RUN) : (plExit ? ST_IDLE : state[LAST]);
      
      xx[FIRST] 	<= INV;
      yy[FIRST] 	<= INV;
      xy[FIRST] 	<= INV;
      magSquared[FIRST] <= INV;
   end

   // [note 1]: nextY is is offset by 1 bit, calculated as xy + y0/2.
   // [note 2]: doubling nextY gives 2*xy + y0
   // [note 3]: scaling input up to utilize additional precision in multiplier output 
   
   // === pipeline: 2nd, ... rows ===   
   wire signed [2*nBitsInternal-1:0] xx_PL1 = x[PL1-1] * x[PL1-1];
   wire signed [2*nBitsInternal-1:0] yy_PL1 = y[PL1-1] * y[PL1-1];
   wire signed [2*nBitsInternal-1:0] xy_PL1 = x[PL1-1] * y[PL1-1];

   wire signed [2*nBitsInternal-1:0] x0_PL2 = x0[PL2-1] <<< (2*nFracBitsInternal - nFracBitsIn); // [note 3]
   wire signed [2*nBitsInternal-1:0] halfY0_PL2 = y0[PL2-1] <<< (2*nFracBitsInternal - nFracBitsIn /*note 2*/ -1); // [note 3]

   wire signed [2*nBitsInternal-1:0] nextX_PL2 = xx[PL2-1] - yy[PL2-1] + x0_PL2;
   wire signed [2*nBitsInternal-1:0] nextY_PL2 = (xy[PL2-1] + /*note 1*/halfY0_PL2);

   wire 			     clipA;
   wire 			     clipB;
   wire 			     clipC;
   wire 			     clipD;
   
   clipPlusMinus2 #(.nBits(2*nBitsInternal), .nFracBits(2*nFracBitsInternal)) iClipX (.i_val(nextX_PL2), .o_clipPlus(clipA), .o_clipMinus(clipB));
   clipPlusMinus2 #(.nBits(2*nBitsInternal), .nFracBits(2*nFracBitsInternal /*note 1*/ - 1)) iClipY (.i_val(nextY_PL2), .o_clipPlus(clipC), .o_clipMinus(clipD)); 
   
   wire 			     nextSat_PL2 = clipA | clipB | clipC | clipD;
   
   wire signed [2*nBitsInternal-1:0] magSquared_PL2 = xx[PL2-1] + yy[PL2-1];
   
   generate
      for (ix = FIRST+1; ix <= LAST; ix=ix+1) begin
	 always @(posedge i_clk) begin
	    // default: shift through pipeline
	    // (possibly prelim. assignments)
	    x0[ix] 	<= x0[ix-1];
	    y0[ix] 	<= y0[ix-1];
	    pixRef[ix] 	<= pixRef[ix-1];
	    x[ix] 	<= x[ix-1];
	    y[ix] 	<= y[ix-1];
	    res[ix] 	<= res[ix-1];
	    state[ix] 	<= state[ix-1];
	    xx[ix] 	<= xx[ix-1];
	    yy[ix] 	<= yy[ix-1];
	    xy[ix] 	<= xy[ix-1];
	    sat[ix] 	<= sat[ix-1];
	    magSquared[ix] <= magSquared[ix-1];
	    case (ix)
	      PL1: begin
		 xx[ix] <= xx_PL1;
		 yy[ix] <= yy_PL1;
		 xy[ix] <= xy_PL1;
 	      end
	      
	      PL2: begin
		 magSquared[ix] 	<= magSquared_PL2;
		 x[ix] 			<= nextX_PL2 >>> nFracBitsInternal;
		 y[ix] 			<= nextY_PL2 >>> (nFracBitsInternal/*note 2: multiply by 2*/-1); // 2*x*y + y0. First double y0 then use half the sum
		 sat[ix] 		<= nextSat_PL2;		 
	      end
	      
	      PL3: begin
		 if (state[ix-1] == ST_RUN) begin
		    if (magSquared[ix-1] > (4 <<< (2*nFracBitsInternal))) begin
		       state[ix] 	<= ST_DONE;
		       x[ix] 		<= INV;
		       y[ix] 		<= INV;
		    end else if (res[ix-1] == i_maxiter) begin
		       state[ix] 	<= ST_DONE;
		       res[ix] 		<= res[ix-1] + 1;		       
		       x[ix] 		<= INV;
		       y[ix] 		<= INV;
		    end else if (sat[ix-1]) begin
		       state[ix] 	<= ST_DONE;
		       res[ix] 		<= res[ix-1] + 1;  // +1 because the next iteration would exit
		       x[ix] 		<= INV;
		       y[ix] 		<= INV;
		    end else
		      res[ix] 		<= res[ix-1] + 1;
		 end
	      end
	    endcase
	 end
      end
   endgenerate   
endmodule

module generator(clk, i_maxiter, o_frameCount, i_vgaPixRefLoopback,
		 o_valid, i_ready, o_res, o_pixRef,
		 i_x0, i_y0, i_dx, i_dy);
   // === parameters ===
   parameter nResBits = -1; initial if (nResBits < 0) $error("missing parameter");   
   parameter nRefBits = -1; initial if (nRefBits < 0) $error("missing parameter");   
   parameter nMemBits = -1; initial if (nMemBits < 0) $error("missing parameter");   
   parameter vgaX = -1; initial if (vgaX < 0) $error("missing parameter");   
   parameter vgaY = -1; initial if (vgaY < 0) $error("missing parameter");   

   // === constants ===
   localparam nBitsGen = 22;
   localparam nFracBitsGen = 19; // range [-2..2], one bit for sign (might drop one bit later?)
   localparam nAddFracBits = 8;   
   localparam INV = 32'dx;

   // === ports ===
   input wire clk;
   input wire [7:0] 		    i_maxiter;   
   output wire [3:0] 		    o_frameCount;   
   input wire [nRefBits-1:0] i_vgaPixRefLoopback/*verilator public_flat*/;
   output wire 		     o_valid;
   input wire 		     i_ready;
   output wire [nResBits-1:0] o_res;
   output wire [nRefBits-1:0] o_pixRef;

   input wire signed [nBitsGen-1:0] i_x0;
   input wire signed [nBitsGen-1:0] i_y0;
   input wire signed [nBitsGen-1:0] i_dx;
   input wire signed [nBitsGen-1:0] i_dy;
   
   reg 				    AB_startValid = 0;
   wire 			    AB_startReady;

   // === start logic ===
   reg 				    electronBeamReturned = 0; // break timing-critical path
   always @(posedge clk) begin
      electronBeamReturned <= (i_vgaPixRefLoopback == 0);      
      AB_startValid <= AB_startReady & electronBeamReturned;
   end
   
   // === feed all image pixels ===
   wire 		     BK_dataValid;
   wire 		     BK_dataReady;   
   wire signed [nBitsGen-1:0] BK_dataX;
   wire signed [nBitsGen-1:0] BK_dataY;
   wire signed [nRefBits-1:0] BK_ref;
   pixelScanner #(.nBits(nBitsGen), .nX(vgaX), .nY(vgaY), .nRefBits(nRefBits), .fracbitsDelta(nAddFracBits)) B_pixelScanner
     (.i_clk(clk), 
      .i_startValid(AB_startValid), .o_startReady(AB_startReady), .i_xStart(i_x0), .i_yStart(i_y0), .i_dx(i_dx), .i_dy(i_dy),
      .o_dataValid(BK_dataValid), .i_dataReady(BK_dataReady), .o_x(BK_dataX), .o_y(BK_dataY), .o_ref(BK_ref), .o_frameCount(o_frameCount));

   wire 		      KC_dataValid;
   wire 		      KC_dataReady;   
   wire signed [nBitsGen-1:0] KC_dataX;
   wire signed [nBitsGen-1:0] KC_dataY;
   wire signed [nRefBits-1:0] KC_ref;
   FIFO #(.nBits(2*nBitsGen + nRefBits), .nLevels(2)) FIFO_K
     (.i_clk(clk), 
      .i_inboundValid(BK_dataValid), .o_inboundReady(BK_dataReady), .i_inboundData({BK_dataX, BK_dataY, BK_ref}),
      .o_outboundValid(KC_dataValid), .i_outboundReady(KC_dataReady), .o_outboundData({KC_dataX, KC_dataY, KC_ref}));
   
   // ================================================================================
   // === circular queue: distribute input data to fractal calc ===
   // ================================================================================
   localparam NENG = 2*15;
   reg signed [nBitsGen-1:0]  BCQ_X[1:NENG+1];
   reg signed [nBitsGen-1:0]  BCQ_Y[1:NENG+1];
   reg signed [nRefBits-1:0]  BCQ_ref[1:NENG+1];
   reg [1:NENG+1] 	      BCQ_V = 0;   
   wire [1:NENG] 	      BCQ_ready;
   
   assign KC_dataReady = /*nothing loops around*/~BCQ_V[NENG+1];
   integer 		      a;
   always @(posedge clk) begin
      for (a = 1; a <= NENG; a = a + 1) begin	 
	 if (BCQ_V[a] & BCQ_ready[a]) begin
	    // entry is taken out by fractal calc
	    BCQ_X[a + 1] 	<= INV;
	    BCQ_Y[a + 1] 	<= INV;
	    BCQ_ref[a + 1] 	<= INV;
	    BCQ_V[a + 1] 	<= 0;
	 end else begin
	    // keep entry in shift registers
	    BCQ_X[a+1] 		<= BCQ_X[a];
	    BCQ_Y[a+1] 		<= BCQ_Y[a];
	    BCQ_ref[a+1] 	<= BCQ_ref[a];
	    BCQ_V[a+1] 		<= BCQ_V[a];
	 end
      end
      if (KC_dataReady & KC_dataValid) begin
	 // load new input
	 BCQ_X[1] 	<= KC_dataX;
	 BCQ_Y[1] 	<= KC_dataY;
	 BCQ_ref[1] 	<= KC_ref;
	 BCQ_V[1] 	<= 1;	 
      end else begin
	 // circulate existing data
	 BCQ_X[1] 	<= BCQ_X[NENG+1];
	 BCQ_Y[1] 	<= BCQ_Y[NENG+1];
	 BCQ_ref[1] 	<= BCQ_ref[NENG+1];
	 BCQ_V[1] 	<= BCQ_V[NENG+1];
      end
   end
   
   // ================================================================================
   // [C]: parallel fractal calc
   // ================================================================================
   wire [1:NENG]	     CD_valid;
   wire [1:NENG] 	     CD_ready;
   wire [nResBits-1:0] 	     CD_res[1:NENG];
   wire [nRefBits-1:0] 	     CD_ref[1:NENG];   
   genvar 		     ix;   
   generate
      for (ix = 1; ix <= NENG; ix = ix + 1)
	julia #(.nBitsIn(nBitsGen), .nFracBitsIn(nFracBitsGen), .nBitsInternal(18), .nFracBitsInternal(14+1+1), .nRefBits(nRefBits), .nResBits(nResBits)) C_fractalEngine
		(.i_clk(clk), .i_maxiter(i_maxiter), .i_pixRefLimit(i_vgaPixRefLoopback + (1 << nMemBits)),
		 .i_x0(BCQ_X[ix]), .i_y0(BCQ_Y[ix]), .i_pixRef(BCQ_ref[ix]), .i_inputValid(BCQ_V[ix]), .o_inputReady(BCQ_ready[ix]),
		 .o_resultValid(CD_valid[ix]), .i_resultReady(CD_ready[ix]), .o_result(CD_res[ix]), .o_pixRef(CD_ref[ix]));
   endgenerate
   
   // ================================================================================
   // === [D]: collect output from parallel fractal calc ===
   // ================================================================================
   reg [nRefBits-1:0] 	     DQueue_ref[0:NENG];
   reg [nResBits-1:0] 	     DQueue_res[0:NENG];
   reg [0:NENG] 	     DQueue_V = 0;   

   genvar 		     b;   
   for (b = 1; b <= NENG; b = b + 1) begin
      // ready to accept data when the previous slot is empty
      // (if used, it will circulate)
      assign CD_ready[b] = ~DQueue_V[b-1];
   end

   wire DE_valid;
   wire DE_ready;
   wire [nRefBits-1:0] DE_ref;
   wire [nResBits-1:0] DE_res;

   assign DE_valid = DQueue_V[NENG];
   assign DE_ref = DQueue_ref[NENG];
   assign DE_res = DQueue_res[NENG];   
   
   always @(posedge clk) begin
      for (a = 1; a <= NENG; a = a + 1) begin
	 if (CD_ready[a] & CD_valid[a]) begin
	    // load new data
	    DQueue_ref[a] 	<= CD_ref[a];
	    DQueue_res[a] 	<= CD_res[a];
	    DQueue_V[a] 	<= 1;
	 end else begin
	    // circulate existing data
	    DQueue_ref[a] 	<= DQueue_ref[a-1];
	    DQueue_res[a] 	<= DQueue_res[a-1];
	    DQueue_V[a] 	<= DQueue_V[a-1];	    
	 end
      end
      if (DE_valid & DE_ready) begin
	 // result at NENG exits
	 DQueue_ref[0] 		<= INV;
	 DQueue_res[0] 		<= INV;
	 DQueue_V[0] 		<= 0;	 
      end else begin
	 // result loops around
	 DQueue_ref[0] <= DQueue_ref[NENG];
	 DQueue_res[0] <= DQueue_res[NENG];
	 DQueue_V[0] <= DQueue_V[NENG];
      end      
   end
   
   // ================================================================================
   // output FIFO (decouple stiff combinational path along pipeline)
   // TBD omit?
   // ================================================================================
   FIFO #(.nBits(nRefBits+nResBits), .nLevels(4)) FIFO_E
     (.i_clk(clk), .i_inboundValid(DE_valid), .o_inboundReady(DE_ready), .i_inboundData({DE_res, DE_ref}),
      .o_outboundValid(o_valid), .i_outboundReady(i_ready), .o_outboundData({o_res, o_pixRef}));

   // debug pattern generation
   //wire [nRefBits-1:0] EF_DEBUG_res;
   //grayToBinary #(.nBits(nRefBits)) g2b (.i_gray(EF_pixRef), .o_bin(EF_DEBUG_res));
   //assign o_res = EF_DEBUG_res;   
endmodule

module top(clk, vgaClk, o_frameCount, i_vgaRun,
	   o_RED, o_GREEN, o_BLUE, o_HSYNC, o_VSYNC, 
	   i_x0, i_y0, i_dx, i_dy, i_maxiter);   
   
   parameter vgaX = 640;
   parameter vgaY = 480;
   
   input wire clk;
   input wire vgaClk;

   output wire [3:0] o_frameCount;
   input wire 	     i_vgaRun;   
   
   output reg 	     o_RED;
   output reg 	     o_GREEN;
   output reg 	     o_BLUE;
   output reg 	     o_HSYNC;
   output reg 	     o_VSYNC;   
   
   // interface to CPU
   input wire signed [31:0] i_x0;
   input wire signed [31:0] i_y0;
   input wire signed [31:0] i_dx;
   input wire signed [31:0] i_dy;
   input wire [7:0] 	    i_maxiter;   
   
   localparam nResBits = 6;
   localparam nRefBits = 24;
   localparam nMemBits = 12;
   
   // ================================================================================
   // fractal image generation
   // ================================================================================
   wire 		    GM_valid/*verilator public_flat*/;
   wire [nResBits-1:0] 	    GM_res/*verilator public_flat*/;
   wire [nRefBits-1:0] 	    GM_pixRef/*verilator public_flat*/;
   wire [nRefBits-1:0] 	    vgaPixRefLoopback/*verilator public_flat*/;
   
   generator #(.vgaX(vgaX), .vgaY(vgaY), .nResBits(nResBits), .nRefBits(nRefBits), .nMemBits(nMemBits)) iGenerator_G 
     (.clk(clk), .i_vgaPixRefLoopback(vgaPixRefLoopback),
      .o_valid(GM_valid), .i_ready(1'b1), .o_res(GM_res), .o_pixRef(GM_pixRef), 
      .i_x0(i_x0), .i_y0(i_y0), .i_dx(i_dx), .i_dy(i_dy), .o_frameCount(o_frameCount), .i_maxiter(i_maxiter));
   
   // ================================================================================
   // VGA scan generation 
   // ================================================================================
   wire 		    vgaBlank;
   wire 		    vgaHsync;
   wire 		    vgaVsync;   
   wire [nRefBits-1:0] 	    vgaPixRef;
   vga #(.nX(vgaX), .nY(vgaY), .nRefBits(nRefBits)) iVga
     (.i_clk(vgaClk), .i_run(i_vgaRun),
      .o_blank(vgaBlank), .o_HSYNC(vgaHsync), .o_VSYNC(vgaVsync), .o_pix(vgaPixRef));
   
   // ================================================================================
   // loop back electron beam position to fractal clock domain for flow control
   // ================================================================================
   CDC #(.nBits(nRefBits)) iCdc 
     (.iA_clk(vgaClk), .iA_data(vgaPixRef), 
      .iB_clk(clk), .oB_data(vgaPixRefLoopback));   
   
   // ================================================================================
   // look up data under electron beam from buffer mem
   // ================================================================================
   wire [nResBits-1:0] 	    vgaRes2;
   wire 		    vgaBlank2;
   wire 		    vgaHsync2;
   wire 		    vgaVsync2;
   dpmem #(.NBITADDR(nMemBits), .NBITDATA(nResBits), .NBITBYPASS(3)) F_videoMem
     (.i_clkA(clk), .i_weA(GM_valid), .i_addrA(GM_pixRef[nMemBits-1:0]), .i_dataA(GM_res),
      .i_clkB(vgaClk), .i_addrB(vgaPixRef[nMemBits-1:0]), .o_dataB(vgaRes2), 
      .i_bypassB({vgaBlank, vgaHsync, vgaVsync}), .o_bypassB({vgaBlank2, vgaHsync2, vgaVsync2}));
   
   // ================================================================================
   // vga color mapping and blanking
   // ================================================================================
   reg 			    lastVsync = 0;   
   reg [7:0] 		    cycle = 40; // offset color map to make maxiter black
   wire [2:0] 		    vgaRes3 = vgaRes2 + cycle[5:3];   
   wire [2:0] 		    vgaRes4 = {vgaRes3[2], vgaRes3[2] ^ vgaRes3[1], vgaRes3[1] ^ vgaRes3[0]};   
   always @(posedge vgaClk) begin
      lastVsync <= vgaVsync2;
      if (0 & {lastVsync, vgaVsync2} == 2'b01)
	cycle <= cycle - 1;
      
      o_RED 	<= vgaBlank2 ? 0 : vgaRes4[0];
      o_GREEN 	<= vgaBlank2 ? 0 : vgaRes4[1];
      o_BLUE 	<= vgaBlank2 ? 0 : vgaRes4[2];
      o_HSYNC 	<= vgaHsync2;
      o_VSYNC 	<= vgaVsync2;      
   end   
endmodule   
