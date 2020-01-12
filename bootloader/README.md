Folder contents: simple bootloader for uploading code to an FPGA implementation

## Boot loader concept
The boot loader is built into FPGA BRAM initial contents via the bitstream. For the verilator simulator, it is loaded as application.
The application binary is then sent via UART using forthytwo.exe's out/*.bootBin output file.
To reload the application binary, the system needs to be reset externally (reprogram the FPGA or assert the J1 reset input, restart the simulator).
The application MUST include a replica of the bootloader IDENTICAL TO ROM at address zero0.
During application upload, the bootloader will simply overwrite itself redundantly with bitwise-identical data. The redundant copy of the bootloader effectively sets the address offset for the user application.
The bitstream upload contains a "magic" synchronization sequence. Any unexpected characters echo back an "x". This can be used to check the presence of the bootloader, simply hit any key in the terminal window.

## Boot loader workflow (FPGA)
- Compile bootloader.txt with forthytwo.exe, independently of the application
- Put the resulting bootloader.v file into FPGA BRAM (see sampleImpl)
- Program the FPGA. The bootloader is listening
- Open (e.g.) Teraterm, Menu:File/send File, check "binary" option, select myApplication.bootBin file.
- For design iteration, reprogram the FPGA (or use e.g. a button tó reset the J1 core) and repeat
- A convenient hack is to manually edit the first line of the generated Verilog file to turn a deployed binary in FPGA block ram back into the bootloader: Look up the address of bootloader.main and put it into the low word of ram[0] (a valid code address used as instruction is an unconditional branch to the same address). Switching back to bootloader.startApplication restores the application.
- The sample project (not the bootloader!) will print "ok" on successful upload and echo any characters from UART "plus 1".

## Boot loader workflow (Verilator simulator in refImpl)
- invoke sim.exe bootloader.hex myApplication.bootBin
- the simulator will internally create UART input reading from the .bootBin file and switch UART IO back to console at end of file.

## Simulator
- arg1: out/myProject.hex
- for bootloader project: arg1: out/myStandaloneBootloader.hex and arg2: out/myApplicationStartingWithTheBootloader.bootBin
- use simVcd.exe to create trace.vcd for review with gtkwave. By default, tracing is enabled but files tend to grow large quickly
- >>>system.sim.tracing.disable<<< and >>>system.sim.tracing.enable<<< disable and re-enable tracing, respectively.
- Unsurprisingly, sim.exe is considerably faster than simVcd.exe
