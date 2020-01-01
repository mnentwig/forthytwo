module serialTx(clk, out_tx, in_byte, in_strobe, out_busy);
   parameter nBitCycles = 0;

   input wire clk;
   output wire out_tx;
   input wire [7:0] in_byte;
   input       wire in_strobe;
   output      wire out_busy;
   
   reg [31:0] count;   
   reg [3:0]  state = 0;   
   reg [7:0]  data;   
   
   assign out_tx = (state == 0) ? 1'b1:    // ready
		   (state == 1) ? 1'b0:    // start bit
		   (state == 10) ? 1'b1:    // stop bit
		   data[0];                // data bits    
   assign out_busy = (state != 0);   
   
   always @(posedge clk) begin
      // correctly timed, in_strobe appears only during idle state (0)
      // however, if echoing data from a UART, small timing error may cause 
      // a new byte to start already during the stop bit
      // This implementation does not prevent retriggering at any time,
      // but this will cause garbled data.
      if (in_strobe) begin
	 count <= nBitCycles;
	 state <= 1;
	 data <= in_byte;
      end else if (state != 0) begin
	 if (count == 0) begin
	    count <= nBitCycles; // (non-final)
	    state <= state + 4'd1; // (non-final)
	    case (state)
	      1: begin 
		 // startbit
	      end
	      default: begin 
		 // data bits
		 data <= {1'bx, data[7:1]};	       
	      end
	      10: begin
		 // stop bit
		 state <= 4'd0;
		 count <= 32'bx;
		 data <= 8'bx;
	      end
	    endcase
	 end else begin
	    count <= count - 1'd1;
	 end
      end
   end
endmodule
