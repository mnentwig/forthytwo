/* verilator lint_off DECLFILENAME */
module fpgatop(CLK12, pioA, PMOD, uart_rxd_out, uart_txd_in, RGBLED, LED, BTN);
   input wire CLK12;
   output wire uart_rxd_out;   
   input wire  uart_txd_in;
   output reg [2:0] RGBLED;
   output reg [1:0] LED;
   input wire [1:0] BTN;

   initial RGBLED =3'b111;
   
   (* dont_touch = "true" *)output reg [5:1]pioA;
   (* dont_touch = "true" *)output reg [7:0]PMOD;
      
   wire 			clk100;   
   wire 			clk200;
   wire 			vgaClk;
   
   //parameter vgaX = 640; parameter vgaY = 480;
   parameter vgaX = 1920; parameter vgaY = 1080;

   wire 			unused;   
   clk12_200 iClk1(.in12(CLK12), .out100(clk100), .out200(clk200), .out300(unused));
   clk100_148p5 iClk2(.in100(clk100), .out148p5(vgaClk));   
   wire cpuClk = clk100;   

   // === import asynchronous button signal ===
   /*ASYNC_REG="true"*/reg [1:0] 			btna;
   /*ASYNC_REG="true"*/reg [1:0] 			btnb;
   always @(posedge clk100) begin
      btna <= BTN;
      btnb <= btna;
   end
   
   wire 			vgaRed;
   wire 			vgaGreen;   
   wire 			vgaBlue;
   wire 			vgaHsync;
   wire 			vgaVsync;
   
   wire [3:0] 			frameCount;
   
   reg [31:0] 			cpuReg[0:7];

   // for simulation only
   initial cpuReg[0] = 32'hc0000020;
   initial cpuReg[2] = 32'hc0000020;
   initial cpuReg[1] = 32'h00111357;
   initial cpuReg[3] = 32'h001e5e6d;
   initial cpuReg[4] = 50;
   initial cpuReg[5] = 0;
   
   top #(.vgaX(vgaX), .vgaY(vgaY)) iTop
     (.clk(clk200), .o_frameCount(frameCount),
      .i_run(cpuReg[5][0]),
      .vgaClk(vgaClk), .o_RED(vgaRed), .o_GREEN(vgaGreen), .o_BLUE(vgaBlue), .o_HSYNC(vgaHsync), .o_VSYNC(vgaVsync), 
      .i_x0(cpuReg[0]), .i_dx(cpuReg[1]), .i_y0(cpuReg[2]), .i_dy(cpuReg[3]), .i_maxiter(cpuReg[4][7:0]));   
   
   // === register VGA signals to suppress combinational hazards, especially on HSYNC/VSYNC ===
   always @(posedge vgaClk) begin
      pioA[1] <= vgaRed;
      pioA[2] <= vgaGreen;
      pioA[3] <= vgaBlue;
      pioA[4] <= vgaHsync;
      pioA[5] <= vgaVsync;
      PMOD[0] <= vgaRed;
      PMOD[1] <= vgaRed;
      PMOD[2] <= vgaRed;
      PMOD[3] <= vgaGreen;
      PMOD[4] <= vgaGreen;
      PMOD[5] <= vgaGreen;
      PMOD[6] <= vgaBlue;
      PMOD[7] <= vgaBlue;      
   end

   // ===========================================================
   // CPU
   // ===========================================================      
   wire io_rd, io_wr;
   wire [15:0] mem_addr;
   wire        mem_wr;
   reg [31:0]  mem_din = 32'd0;
   wire [31:0] dout;
   reg [31:0]  io_din;
   
   wire [12:0] addrCodeCpu; // CPU instruction pointer in units of 16 bit words

   // === instruction word selection ===
   // convert 32-bit memory into double-length 16 bit code memory
   // note: the word selection must be delayed relative to the address indexing
   // to work with inferred BRAM
   reg [31:0]  instr32 = 0; // this provides BRA:0x0000 as first instruction, regardless of RAM contents
   reg 	       instrSelHighWord = 0;  
   wire [15:0] instr16;
   assign instr16 = instrSelHighWord ? instr32[31:16] : instr32[15:0];
   
   reg [31:0]  ram[0:8191] /* verilator public_flat */;
   initial begin
`include "main.v"
   end
   always @(posedge cpuClk) begin
      instrSelHighWord 	<= addrCodeCpu[0];
      instr32 		<= ram[{1'b0, addrCodeCpu[12:1]}];
      //$display("PC:", addrCodeCpu, " instr:", instr32, " instr16:", instr16);   

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
   reg [15:0]   rbank_addr;
   reg [31:0]  rbank_data;   
   always @(posedge cpuClk) begin
      rbank_write <= io_wr;
      rbank_addr <= mem_addr;
      rbank_data <= dout;
      
      if (rbank_write && ((rbank_addr & 16'hFFF0) == 16'h2000))
	cpuReg[rbank_addr[2:0]] <= rbank_data;
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

	   // === frame count register ===
	   16'h3000:
	     io_din <= {28'd0, frameCount};
	   16'h3004:
	     io_din <= {30'd0, btnb};
  	   default: begin end
	 endcase
      end // if (io_rd)      
      if (io_wr) begin
	 case(mem_addr)
	   // === UART reg: Tx write data ===
	   16'h1003: begin
	      uartTxByte <= dout[7:0];
	      uartTxStrobe <= 1'b1;	      	      
	   end
	   16'h3001: begin
	      RGBLED <= ~dout[2:0];	      
	      LED <= dout[4:3];	     	      
	   end
	   default: begin end
	 endcase
      end // if (io_wr)      
   end
endmodule
