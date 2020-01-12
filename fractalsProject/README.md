# FPGA fractal demo
Markus Nentwig, 20?? - 2020

### Youtube video:

_Note: the actual on-screen image is free of glitches and artifacts but camera recording quality is limited_
<a href="http://www.youtube.com/watch?feature=player_embedded&v=XnHhH9rjF9c
" target="_blank"><img src="http://img.youtube.com/vi/XnHhH9rjF9c/0.jpg" 
alt="FPGA demo" width="240" height="180" border="10" /></a>

Fractal generation is a popular FPGA design exercise. 
For example, Stanford university used it as [lab assignment](https://web.stanford.edu/class/ee183/handouts/lect7.pdf) already in 2002. 
It must have been around that time that I saw a similar demo on some trade fair, and had the itch to try my hands on it ever since.

Well, I got around to it eventually. 

It took a long time.

## Motivation
An FPGA "fun" project adds a very unique design challenge: It needs to be sufficiently _fun_ all along the way. 

Sometimes, I can be my own worst enemy. The long and tedious climb finally opens up into a straight, obvious, logical route all the way downhill to the end.
And I decide not to take it because it is, well, _dull_. The same as with hiking, it's not just getting from A to B that matters. 

So I throw in some new ideas to keep it interesting. 

Repeat too many times.

## Overview
The semi-eternal chase after the "fun factor" eventually evolved into unwritten requirements somewhere along those lines:

* Real time calculation: The Stanford lab exercise demanded it already in 2002.
* Full HD resolution (1920x1080) at 60 Hz. That's the monitor on my desk. No excuses.
* Use the FPGA in a sensible manner. The resulting implementation can achieve multiplier utilization close to 100 %, that's 18 billion multiplications per second (on 35-size Artix and an USB bus power budget of ~2 Watts).	
* Perform dynamic resource allocation. The fractals algorithm is somewhat unusual as the required number of iterations varies between points. Compared to simply setting a fixed number of iterations, complexity increases substantially (a random number of results may appear in one clock cycle, results are unordered) but so does performance.
* Limit to 18-bit multiplications because it is the native width for Xilinx 6/7 series DSP48 blocks. It is straightforward to increase the internal bitwidth for higher resolution, but resource usage skyrockets.
* Be (reasonably) vendor-independent. Being halfway through a microblaze MCS implementation for the controls, the fun factor dropped below threshold so I abandoned it.
* Realistic CPU size: For a CPU-centric industrial (as opposed to "for-fun") design I see no alternative to the vendor's proprietary CPU offerings e.g. Microblaze or Zynq ARM. However, for a minimal softcore controller I expect fairly small size even if it makes no real difference on the relatively large Xilinx FPGA (e.g. I may want to reuse all the work on cheaper FPGAs e.g. Lattice. Suddenly, CPU size and efficiency become a lot more interesting). 
James Bowman's J1B fits the bill for me, and its 32 bit extension is used heavily in this project.
* Now, nothing before the word "but" counts: Reaching the conclusion (personal opinion) that J1B's native gforth toolchain would never be acceptable for a "modern" industrial project, I ended up writing my own simple compiler / assembler "forthytwo.exe". This may seem over the top at first glance but it paves the way for e.g. floating-point math in hand-crafted assembly language, still with manageable effort. 
And I've seen ad-hoc assemblers for large-volume ASIC microcontroller code via Excel spreadsheets - maybe spinning your own compiler is not _that_ absurd, after all.
* Floating point math for the controls: Fixed point is great for raw throughput but gets tedious for performance-uncritical code.
* CPU Bootloader on plain UART (meaning no proprietary Xilinx JTAG). The included bootloader implements robust synchronization and efficient binary upload.
* No esoteric tools, not relying on Linux. On a clean Windows PC, the build system can be set up by installing MinGW (developer settings), Vivado and Verilator. See my install notes for the latter. Use e.g. Teraterm with the bootloader.
* Batteries-included project so you can pull it out of the hat and reuse it by deleting what is not needed (this more on the microcontroller side, as the fractals part is quite problem-specific)

## Ready/valid design pattern notes
The calculation engine relies heavily on the [valid/ready handshaking paradigm](https://inst.eecs.berkeley.edu/~cs150/Documents/Interfaces.pdf), which is used consistently throughout the chain.

Here, it is critical, for a simple reason: 
The 200 MHz clock rate of the fractal generator is less than two times the VGA pixel rate. Therefore, any "sub-optimal" handshaking scheme that needs one idle clock cycle to recover would break the design.

### Ready / valid combinational path problem
In a typical processing block, data moves in lock-step through a sequence of registers. 
When cascading any number of such blocks via ready-/valid interfaces, the "ready" signal forms a combinational path from the end to the beginning of the chain. This can make timing closure difficult or impossible.
The problem is clear to see when considering what happens when the end of the processing chain signals "not ready" (to accept data):
The data over the whole length of the pipeline has nowhere to go, therefore the whole chain must be stopped within a single clock cycle.

The solution is to break the chain into multiple segments using FIFOs (2 slots is enough).
There's a catch: I could design an "optimized" FIFO that will accept data even if full, as long as an element is taken from the output in the same clock cycle.
This "optimization" would introduce exactly the combinational path the FIFO is supposed to break, thus it would be useless for decoupling the combinational chain.
In other words, the input of the FIFO may not use the output-side "ready" signal combinationally.

### Ready / valid flow control
The data flow in a ready-/valid chain can be interrupted at any point simply by inserting a block that forces both valid and ready signal to zero.
This block may be combinational and may depend on an observed data value. 
This pattern is used to stop the calculation engine from running too far ahead of the monitor's electron beam.

## RTL implementation

### Clock domain
There are three clock domains: 
* The calculation engine (most of the design) at 200 MHz. This could be pushed higher but would make the design more difficult to work with. Right now, there is no reason for doing so, and the chip already runs quite hot.
* The VGA monitor signals at a pixel frequency of 148.5 MHz
* The J1B CPU at 100 MHz, because its critical path is too slow for 200 MHz operation.

### Data flow
_Note: Names in the picture correspond to the Verilog implementation_

![Top level diagram](https://github.com/mnentwig/forthytwo/blob/master/fractalsProject/wwwSrc/systemDiagram.png "Top level diagram")

Block "vga" **100** creates the VGA monitor timing. One of its outputs is the number of the pixel currently under the electron beam.

The pixel position passes via Gray coding through a clock domain crossing **110** into the "trigger" block **120**.
Here, the start of a new frame is detected when the pixel position returns to zero. 
This happens immediately after the last visible pixel has been sent to the display so the front porch / VSYNC / back porch time intervals can be used to pre-compute image data, up to the capacity of the buffer RAM **220**.

Detection of a new frame start triggers the following "pixScanner" **130**. This block has already received fractal coordinates from CPU **140** and scans them row by row, using two pairs of increments: a first delta X/Y pair for the electron beam moving right (colums) and a second pair for moving down (rows). Using appropriate deltas, the picture can be rotated by any angle.

The block keeps a frame counter, which is polled by CPU **140** to start computing the next frame coordinates as soon as the previous ones have been stored.

Generated pixel coordinates move forward into FIFO **150**. This is solely to decouple the combinational accept/ready paths. 
It does not improve throughput since the pixel scanner is already capable of generating one output per clock cycle.

"Pixel coordinates" are formed by the X and Y location in fractal space and the linear pixel position, equivalent to its counterpart from vga block **100**. 
The latter is necessary because results will need to be re-ordered.

The pixel coordinates now move into a cyclic distribution queue **170**. Its purpose is to serve pixel coordinates to the parallel "julia" (fractal) calculation engines **180**.
If one calculation engine is ready to accept a new job, the value will drop out of the queue, otherwise it will move right through slots **170** and eventually cycle back to the head of the queue.

Queue **160** will only accept new input from FIFO_K **150** when no data is looping around. Use of the ready/valid protocol makes the implementation of this feature relatively straightforward.

Calculation engines **180** will iterate the Mandelbrot set algorithm ("escape time" algorithm, see Wikipedia: https://en.wikipedia.org/wiki/Mandelbrot_set). 

With default settings (easily changed), the implementation uses 30 "julia" engines **180**. Each of them is formed by 12 pipeline levels. In other words, each engine juggles up to 12 independent calculations at a time.
Each "julia" engine performs three parallel multiplications (xx, yy, xy), using 90 multipliers in total, with one operation per cycle each under full load.

Since buffer space downstream is fairly limited - much less than a full frame - the calculation engines **180** must be prevented from running too far ahead of the electron beam position. 
Therefore, a flow control mechanism **190** is built into the calculation engines. It checks each entry's pixel number against the electron beam and prevents it from leaving calculation engine **180**.
If denied exit, the value will continue dummy iterations through the calculation engine. The clock domain crossing **110** delays the pixel position by a few clock cycles relative to the actual image generation, therefore flow control will always (conservatively) lag behind a few pixels.

Similar to the circular distribution queue **160**, results are collected into circular collection queue **190**. If a slot **200** is empty, it will accept a result from calculation engine **180**, otherwise the calculation engine will continue dummy iterations on the result.

Exiting data from collection queue **190** move into FIFO_E **210** and then into dual port memory **220**. This FIFO is not strictly necessary anymore: Since dual port ram **220** will always be ready to accept data, it could be replaced with a cheaper register.

Dual port memory **220** is indexed on its second port by the electron beam position from "vga" block **100**. The dp-memory implements the crossing for data into the VGA pixel clock domain. 
Output from the RAM, together with HSYNC and VSYNC signals, is finally forwarded to the monitor output.

While not shown in the picture, buttons and LEDs are accessible via a register attached to the CPU's IO port.

### The "julia" calculation engine
To be continued

