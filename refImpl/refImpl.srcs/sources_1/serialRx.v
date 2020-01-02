// note: if rx is an external (asynchronous) input, it must be registered first
module serialRx(clk, in_rx, out_byte, out_strobe);
   input wire clk;
   input wire in_rx;
   parameter nHalfBitCycles = 0;
   reg [13:0] 	    count;   
   reg [3:0] 	    state = 0;
   reg [7:0] 	    data;
   output reg	    out_strobe;   
   output wire [7:0]     out_byte;
   
   assign out_byte = out_strobe ? data : 8'bx;
   
   always @(posedge clk) begin
      out_strobe <= 1'b0; // non-final
      
      if (state == 0) begin
	 if (!in_rx) begin
	    state <= 1;
	    count <= nHalfBitCycles;
	 end
      end else if (state == 10) begin
	 // stop bit
	 // wait for nominal sampling instant
	 if (count != 0)
	   count <= count - 32'd1;  
	 else if (in_rx) begin
	    // after nominal sampling instant, wait for line to go high
	    // => ready to signal next byte with falling edge
	    // => restart
	    state <= 4'd0;
	    count <= 32'bx;
	    data <= 8'bx;
	 end
      end else begin
	 if (count != 0) begin
	    // start bit
	    count <= count - 32'd1;  
	 end else begin
	    // data bits
	    data <= {in_rx, data[7:1]};
	    state <= state + 4'd1;
	    count <= 2*nHalfBitCycles;
	    if (state == 9) begin
	       // final data bit
	       out_strobe <= 1'b1;
	    end
	 end
      end
   end
endmodule
