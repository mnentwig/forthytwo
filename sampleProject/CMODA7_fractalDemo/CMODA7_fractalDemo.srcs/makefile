# makefile for verilator simulation
# (not FPGA build, use Vivado GUI)

FIRMWAREPATH=../../out
FORTHYTWO=../../../bin/forthytwo.exe 

# this is the generic refImpl simulator
SIM=../../../bin/sim.exe
VOPTS=--x-assign 1 --x-initial 0

all: sim.exe simVcd.exe

# build minimal simulation firmware and copy as main.v into fpgatop dir
# Verilator will find it via its include file
# Vivado does not see this file, as it is not part of the Vivado project
mainIncl.v: sim_main.txt
	${FORTHYTWO} sim_main.txt
	cp out/sim_main.v mainIncl.v

# Build the Verilator simulator
sim.exe: sim_main.cpp mainIncl.v fpgatop.v mandel.v
	verilator -Wno-fatal ${VOPTS} -I${FIRMWAREPATH} -Isrc_simOnly -I../../../J1B -cc fpgatop.v mandel.v --exe sim_main.cpp
	make -j -C obj_dir -f Vfpgatop.mk Vfpgatop
	cp obj_dir/Vfpgatop.exe sim.exe

simVcd.exe: sim_main.cpp mainIncl.v fpgatop.v mandel.v
	verilator -Wno-fatal ${VOPTS} --trace -I${FIRMWAREPATH} -Isrc_simOnly -I../../../J1B -cc fpgatop.v mandel.v --exe sim_mainTrace.cpp
	make -j -C obj_dir -f Vfpgatop.mk Vfpgatop
	cp obj_dir/Vfpgatop.exe simVcd.exe

# run the minimal firmware on the generic simulator (prints IOWR:xyz)
fwTest: mainIncl.v
	${SIM} out/sim_main.hex

clean: 
# Remove Verilator build directory
	rm -Rf obj_dir
# Remove copied sim firmware
	rm -f mainIncl.v
# Remove forthytwo build directory
	rm -Rf out
# (Emacs backup files)
	find . -name *~ -exec rm {} \;
# copied simulator
	rm -f sim.exe
	rm -f simVcd.exe

PHONY: clean fwTest
