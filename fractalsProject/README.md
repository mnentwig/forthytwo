# FPGA fractal demo
Markus Nentwig, 20?? - 2020

Fractal generation is a popular FPGA design challenge. 
For example, Stanford university 
https://web.stanford.edu/class/ee183/handouts/lect7.pdf
used it as lab exercise already in 2002. I also remember some fractals demo from some trade fair around that time, and had the itch to try my hands on it ever since.

Well, I got around to it eventually. 

It took a long time.

## Motivation
An FPGA "fun" project adds one very unique design challenge: It needs to be sufficiently fun all along the way. 

Sometimes, you are your own worst enemy. After a long, tedious climb, you finally see a straight, obvious, logical route all the way downhill to the finish. 
And decide not to take it because it is, well, dull. Same as with hiking, it's not about getting from A to B in the most efficient manner. 
So you throw in some new ideas to make it more interesting. Repeat too many times.

Chasing the "fun factor" eventually evolved into unwritten requirements somewhere along those lines:

* Real time calculation: The Stanford lab exercise demanded it already in 2002.
* Full HD resolution (1920x1080) at 60 Hz. That's the monitor on my desk. Period.
* Use the FPGA in a sensible manner. The resulting implementation can achieve multiplier utilization close to 100 %, that's 18 billion multiplications per second (on 35-size Artix and an USB bus power budget of ~2 Watts).	
* Perform dynamic resource allocation. The fractals algorithm is somewhat unusual as the required number of iterations varies between points. Compared to a fixed number of iterations, complexity increases substantially (a random number of results may appear in one clock cycle, results are unordered) but so does performance.
* Limit to 18-bit multiplications because it is the native size for DSP48 blocks. It is straightforward to increase the internal bitwidth for higher resolution, but resource usage skyrockets.
* Be (reasonably) vendor-independent. Being halfway through a microblaze MCS implementation for the controls, the fun factor dropped below threshold so I abandoned it.
* Realistic CPU size: For a CPU-centric industrial (not "fun") design I see no alternative to the vendor's proprietary CPU offerings e.g. Microblaze or Zynq ARM. However, for a minimal controller I expect that it is small even if it makes no real difference on the large Xilinx FPGA - I may want to use the same technology on lower-tier FPGAs e.g. Lattice, and then CPU size and efficiency becomes more critical. James Bowman's J1B fits the bill for me, and its 32 bit extension is used heavily in this project.
* Reaching the conclusion (personal opinion!) that J1B's native gforth toolchain would never be accepted for a state-of-the-art industrial project, I ended up writing my own simple compiler / assembler "forthytwo.exe". This may seem over the top at first glance but it paves the way for e.g. floating-point math in hand-crafted assembler with manageable effort. I've seen ad-hoc compilers for large-volume ASIC custom microcontrollers based on Excel spreadsheets - maybe spinning your own compiler is not _that_ absurd, after all. I like it very much.
* Floating point math for the controls: Fixed point is great for raw throughput but gets tedious for performance-uncritical code.
* CPU Bootloader on plain UART (meaning no proprietary Xilinx JTAG). The included bootloader implements robust synchronization and efficient binary upload.
* No esoteric tools, not relying on Linux. On a clean Windows PC, the build system can be set up by installing MinGW (developer settings), Vivado and Verilator. See my install notes for the latter. Use e.g. Teraterm with the bootloader.
* Batteries-included project so you can pull it out of the hat and reuse it by deleting what is not needed (this more on the microcontroller side, as the fractals part is quite problem-specific)

## Ready/valid design pattern notes
The calculation engine relies heavily on the valid/ready handshaking paradigm, which is used consistently throughout the chain.

### Ready / valid combinational path problem
In a typical processing block, data moves in lock-step through a sequence of registers. 
When cascading any number of such blocks, via ready-/valid interfaces, the "ready" signal forms a combinational path from the end to the beginning of the chain. This can cause problems with timing closure.
The problem is clear to see when considering what happens when the end of the processing chain signals "not ready" (to accept data). 
The data over the whole length of the pipeline has nowhere to go, therefore the whole chain must be stopped within a single clock cycle.

The solution is to break the chain into multiple segments using FIFOs (2 slots is enough).
There's a catch: I could design an "optimized" FIFO that will accept data even if full, when an element is taken from the output in the same clock cycle.
This "optimization" would introduce exactly the combinational path the FIFO is supposed to break, thus it would be useless for decoupling the combinational chain.
In other words, the input of the FIFO may not use the output-side "ready" signal combinationally.

### Ready / valid flow control
The data flow in a ready-/valid chain can be interrupted at any point simply by inserting a block that forces both valid and ready signal to zero.
This block may be combinational and may depend on an observed data value. 
This pattern is used to stop the calculation engine from running too far ahead of the monitor's electron beam.

## RTL implementation

### Clock domain
There are three clock domains: 
* The calculation engine (most of the design) at 200 MHz. This could be pushed higher but makes the design more difficult to work with.
* The VGA monitor signals at a pixel frequency of 148.5 MHz
* The J1B CPU at 100 MHz, because its critical path is too slow for 200 MHz operation.

### Data flow
__Note: Names in the picture correspond to the Verilog implementation__

![Top level diagram](../wwwSrc/systemDiagram.png "Top level diagram")

Block "vga" **100** creates the VGA monitor timing. One of its outputs is the number of the pixel currently under the electron beam.

The pixel position passes via Gray coding through a clock domain crossing **110** into the "trigger" block **120**.
Here, the start of a new frame is detected when the pixel position returns to zero. 
This happens immediately after the last visible pixel has been shown so the VSYNC interval is available to pre-compute image data to the capacity of the buffer RAM **???**.

Detection of a new frame start triggers the following "pixScanner" **130**. This block has received fractal coordinates from CPU **140** and scans them row by row.

Pixels are scanned by two pairs of increments, one for the electron beam moving right and one for moving down. This allows rotating the picture by any angle.

The block provides a frame counter which is polled by CPU **140** to start computing the next frame coordinates as soon as the previous ones have been stored.

Generated pixel coordinates move forward into FIFO **150**. This is solely to decouple the combinational accept/ready paths. 
It does not improve throughput since the pixel scanner is already capable of generating one value per clock cycle.

"Pixel coordinates" comprise the X and Y parameter in fractal space and the pixel position, equivalent to its counterpart from vga block **100**. 
The latter is necessary because data will need to be re-ordered later.

The pixel coordinates now move into a cyclic distribution queue **170**. Its purpose is to serve pixel coordinates to the parallel "julia" (fractal) calculation engines **180**.
If one calculation engine is ready to accept a new job, the value will drop out of the queue, otherwise it will move right through slots **170** and eventually cycle back to the head of the queue.

The queue **160** will only accept new input from FIFO_K **150** when no data is looping around. Use of the ready/valid protocol makes the implementation of this feature relatively straightforward.

Calculation engines **180** will iterate the Mandelbrot set algorithm ("escape time" algorithm, see Wikipedia: https://en.wikipedia.org/wiki/Mandelbrot_set). 

With default settings (easily changed), the implementation uses 15 "julia" engines **180**. Each of them uses 12 pipeline levels (that is, each engine cycles between 12 independent calculations).

The calculation engines **180** may not run too far ahead of the electron beam position, since there is only limited downstream buffer space (much less than a full frame).
Therefore, a flow control mechanism **190** in the calculation engines checks each entry's pixel number against the electron beam and prevents it from leaving the calculation engine **180**.
If denied exit, the value will continue dummy iterations through the calculation engine.

Similar to the circular distribution queue **160**, results are collected into circular collection queue **190**. If a slot **200** is empty, it will accept a result from calculation engine **180**, otherwise the calculation engine will continue dummy iterations on the result.

Exiting data from collection queue **190** move into FIFO_E **210** and then into dual port memory **220**. This FIFO exists for historical reasons and could be removed from the design.

Dual port memory **220** is indexed on its second port by the electron beam position from "vga" block **100**. The dp-memory implements the crossing for data into the VGA pixel clock domain. 
Output from the RAM, together with HSYNC and VSYNC signals, is forwarded to the monitor output.

### The "julia" calculation engine
To be continued

