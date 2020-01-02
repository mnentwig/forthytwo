# Verilator paths for building the simulator under mingw
# Not needed if you have a working sim(_trace).exe file
VERILATOR=verilator_bin.exe
VINCLUDE=/usr/share/verilator/include

# target compiler binary
# Build forthytwo.exe externally, e.g. using Visual Studio. The .sln file uses a post-build command to copy the executable to bin/
FORTHYTWO=bin/forthytwo.exe

# generic target platform simulator
SIM=bin/sim.exe
SIMTRACE=bin/simVcd.exe

all: 	bin/sim.exe testLibs testMath2

# runs sanity check selftests by simulating included libraries
testLibs: libs/test.txt
	@echo "=== basic feature test ==="
	${FORTHYTWO} libs/test.txt
	${SIM} libs/out/test.hex > libs/out/testResult.txt
	diff -w libs/testResultRef.txt libs/out/testResult.txt
	@echo "[OK] test passed"

# runs sanity checks specifically on the math library (not floating point)
testMath2:
	@echo "=== math library test ==="	
# run J1 sim
	${FORTHYTWO} libs/selftest/testMath.txt
	${SIM} libs/selftest/out/testMath.hex > testMathResult_sim.txt
# run reference C code
	gcc -Wall -o testMath.exe libs/selftest/testMath.c
	./testMath.exe > testMathResult_C.txt
	diff -w testMathResult_sim.txt testMathResult_C.txt
	@echo "no difference - test passed"

# test the floating point library. Very slow
testFlmMath:
	@echo "=== FLM floating point math library check ==="	
	make -C libs/flm

# currently unused
main:
	${FORTHYTWO} main.txt
	${SIM} out/main.hex

# build the simulators
bin/sim.exe:
	 make -C J1B

# removes Verilator-generated files but not the binary itself
clean:
	rm -f *~
	rm -Rf obj_dir
	rm -f *.vcd
	rm -Rf libs/out
	rm -f libs/*~
	rm -Rf out

# removes also simulator binaries
realclean: clean
	rm -f bin/sim.exe
	rm -f bin/sim_trace.exe

.PHONY: clean sim testMath all testFlmMath testLibs
