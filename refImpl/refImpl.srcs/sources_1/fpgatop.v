module fpgatop(CLK12, uart_rxd_out, uart_txd_in);
   input wire CLK12;
   output wire uart_rxd_out;   
   input wire uart_txd_in;
   
   // ===========================================================
   // clock
   // ===========================================================      
   wire 			clk100;   
   wire 			clk200;
   wire 			vgaClk;   
   clk12_200 iClk1(.in12(CLK12), .out100(clk100), .out200(clk200), .out300());   

   // ===========================================================
   // CPU
   // ===========================================================      
   wire cpuClk = clk100;   
   wire io_rd, io_wr;
   wire [15:0] mem_addr;
   wire        mem_wr;
   reg [31:0]  mem_din = 32'd0;
   wire [31:0] dout;
   reg [31:0]  io_din = 0;
   reg [31:0] 			cpuReg[0:7];
   
   wire [12:0] addrCodeCpu; // CPU instruction pointer in units of 16 bit words
   
   wire [12:0] codeaddr_32bitWord = {1'b0, addrCodeCpu[12:1]};
   
   // === instruction word selection ===
   // convert 32-bit memory into double-length 16 bit code memory
   // note: the word selection must be delayed relative to the address indexing
   // to work with inferred BRAM
   reg [31:0]  instr32;
   wire [15:0] instr16;
   reg 	       instrSelHighWord = 0;  
   assign instr16 = instrSelHighWord ? instr32[31:16] : instr32[15:0];
   
   reg [31:0]  ram[0:8191];
   initial begin
      `include "main.v"
   end
   always @(posedge cpuClk) begin
      instrSelHighWord 	<= addrCodeCpu[0];
      instr32 		<= ram[{1'b0, addrCodeCpu[12:1]}];
      if (mem_wr)
	ram[mem_addr[14:2]] <= dout;
      mem_din <= ram[mem_addr[14:2]];
   end

   j1 #(.WIDTH(32)) ij1
     (.clk(cpuClk),
      .reset(1'b0),
      .io_rd(io_rd),
      .io_wr(io_wr),
      .mem_wr(mem_wr),
      .dout(dout),
      .mem_din(mem_din),
      .io_din(io_din),
      .mem_addr(mem_addr),
      .code_addr(addrCodeCpu),
      .insn(instr16));
   
   // === register bank ===
   // note: one register level delay because not timing critical
   reg 	       rbank_write = 1'b0;
   reg [2:0]   rbank_addr;
   reg [31:0]  rbank_data;   
   always @(posedge cpuClk) begin
      rbank_write <= io_wr;
      rbank_addr <= mem_addr[2:0];
      rbank_data <= dout;
      
      if (rbank_write)
	cpuReg[rbank_addr] <= rbank_data;
   end

   // ===========================================================
   // UART
   // ===========================================================      
   /*ASYNC_REG="true"*/reg uartInSync = 0;
   /*ASYNC_REG="true"*/reg uartIn = 0;
   /*DONT_TOUCH="true*/reg uartOut = 0;
   wire 			uartOut2;   
   always @(posedge clk100) begin
      uartInSync <= uart_txd_in;
      uartIn <= uartInSync;
      uartOut <= uartOut2;       
   end
   assign uart_rxd_out = uartOut;

   wire [7:0] uartRxByteIncoming;
   wire       uartRxStrobe;

   reg 	      uartRxByteValid = 0;   
   reg [7:0]  uartRxByte;

   reg [7:0]  uartTxByte;
   reg 	      uartTxStrobe = 0;
   wire       uartTxBusy;
  
   serialRx #(.nHalfBitCycles(5208)) uartRx (.clk(clk100), .in_rx(uartIn), .out_byte(uartRxByteIncoming), .out_strobe(uartRxStrobe));
   serialTx #(.nBitCycles(10416)) uartTx (.clk(clk100), .out_tx(uartOut2), .in_byte(uartTxByte), .in_strobe(uartTxStrobe), .out_busy(uartTxBusy));   
   always @(posedge clk100) begin
      uartTxStrobe <= 1'b0; // prelim. assignment
      
      if (uartRxStrobe) begin
	 uartRxByte <= uartRxByteIncoming;
	 uartRxByteValid <= 1'b1;	 
      end
      if (io_rd) begin
	 case (mem_addr)
	   // === UART reg: check for valid data ===
	   16'h1000:
	     io_din <= {31'd0, uartRxByteValid};

	   // === UART reg: get data ===
	   16'h1001:
	     begin
		io_din <= {24'd0, uartRxByte};
		uartRxByteValid <= 1'b0;	 
	     end

	   // === UART reg: Tx ready? ===
	   16'h1002:
	     io_din <= {31'd0, ~uartTxBusy};

	 endcase
      end // if (io_rd)      
      if (io_wr) begin
	 case(mem_addr)
	   // === UART reg: Tx write data ===
	   16'h1003: begin
	      uartTxByte <= dout;
	      uartTxStrobe <= 1'b1;	      	      
	   end
	 endcase
      end // if (io_wr)      
   end
endmodule
