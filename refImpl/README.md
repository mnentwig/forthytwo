Folder contents: An FPGA implementation of the "Zero" reference platform for the Digilent CMOD A7 board.

Porting it to a different board should be fairly straightforward. Note that the UART division ratio may need to be adjusted, if clock frequency changes.

# Running on FPGA

* Use Digilent CMOD-A7 module (35 size) or edit Vivado project
* Build and upload bitstream from Vivado
* Build the code by running "make" in refImpl.srcs
* Open Teraterm for serial connection to the board (standard 9600 baud rate)
* Use "send file" with "out/main.bootBin". Important: Use "Binary" option
* successful upload will show "ok"
* The running program echoes back any key pressed in teraterm with offset 1 e.g. "a" becomes "b".

# Running in the simulator
* use "make sim". Successful startup will show "ok" as above

# Notes on bootloader
By default, the example "main.txt" uses the bootloader, as this would be a typical starting point for development.

The compilated binary code is given twice to the simulator: First "out/boot.hex" to run the bootloader, then "out/main.bootBin" to simulate UART uploade.

For a minimal demo, remove >>>#include(bootloader.txt)<<< from "main.txt". Simulate with "simZero.exe out/main.hex". However, note that now the program cannot be loaded with the bootloader anymore, as it would overwrite the bootloader in memory during upload.

To disable the bootloader (for deployment), edit the first line in bootloader.txt into >>>BRA:bootloader.startApplication<<<, recompile the code and rebuild the FPGA bitstream.


