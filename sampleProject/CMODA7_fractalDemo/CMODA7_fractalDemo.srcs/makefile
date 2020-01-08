# makefile for verilator simulation
# (not FPGA build, use Vivado GUI)

FIRMWAREPATH=./out
FORTHYTWO=../../../bin/forthytwo.exe 

# this is the generic refImpl simulator
SIM_GENERIC=../../../bin/sim.exe
# custom simulators with RTL included
SIM=sim.exe
SIMVCD=simVcd.exe

VOPTS=--x-assign 1 --x-initial 0

IVERILOG=/c/users/gk/Dropbox/bin/iverilog10/bin/iverilog.exe
VVP=/c/users/gk/Dropbox/bin/iverilog10/bin/vvp.exe

all: ${SIM} ${SIMVCD}

# ===================================================
# minimal firmware for quick simulations
# ===================================================
# builds minimal simulation firmware. Copy as main.v into Verilator include path
# Note: Vivado does not see this file, as it is not part of the Vivado project
out/sim_main.hex: sim_main.txt
	${FORTHYTWO} sim_main.txt
	cp out/sim_main.v out/main.v

# ===================================================
# Build the Verilator simulator
# ===================================================
# Note: compiles in the minimal firmware
${SIM}: sim_main.cpp out/sim_main.hex fpgatop.v mandel.v
	verilator -Wno-fatal ${VOPTS} -I${FIRMWAREPATH} -Isrc_simOnly -I../../../J1B -cc fpgatop.v mandel.v pixScanner.v --exe sim_main.cpp
	make -j -C obj_dir -f Vfpgatop.mk Vfpgatop
	cp obj_dir/Vfpgatop.exe sim.exe

${SIMVCD}: sim_main.cpp out/sim_main.hex fpgatop.v mandel.v
	verilator -Wno-fatal ${VOPTS} --trace -I${FIRMWAREPATH} -Isrc_simOnly -I../../../J1B -cc fpgatop.v mandel.v pixScanner.v --exe sim_mainTrace.cpp
	make -j -C obj_dir -f Vfpgatop.mk Vfpgatop
	cp obj_dir/Vfpgatop.exe simVcd.exe

# ===================================================
# run simulations with RTL and minimal firmware
# ===================================================
# Note: The .hex file overwrites the memory contents that were compiled into the simulator
runSim: ${SIM} out/sim_main.hex
	${SIM} out/sim_main.hex
runSimVcd: ${SIMVCD} out/sim_main.hex
	rm -f trace.vcd
	${SIMVCD} out/sim_main.hex

# run the minimal firmware on the generic simulator (prints IOWR:xyz)
fwTest: out/sim_main.hex
	${SIM_GENERIC} out/sim_main.hex

simPipeline:
	${IVERILOG} -Wall simPipeline.v
	${VVP} a.out -lxt2

simPixScanner:
	${IVERILOG} -Wall -DSIM_PIXSCANNER pixScanner.v
	${VVP} a.out -lxt2 | tee simOut.txt
	diff simOut.txt simOutRef_pixScanner.txt
	@echo "result as expected"
clean: 
# Remove Verilator build directory
	rm -Rf obj_dir
# Remove forthytwo build directory
	rm -Rf out
# (Emacs backup files)
	find . -name "*~" -exec rm {} \;
# copied simulator
	rm -f sim.exe
	rm -f simVcd.exe
# iverilog compilation result
	rm -f a.out
# iverilog simulation result
	rm -f c:/temp/out.lx2
# simPixScanner result
	rm -f simOut.txt
	rm -f output.txt

PHONY: clean fwTest runSim runSimVcd
