# CSharp compiler from .NET framework
# You may need to change this, depending on what is installed on the system
# The compiler should be available from the .NET runtime (does not require developer package)
# Alternatively, use Visual studio to open forthytwo.sln and build.
CSC=/c/Windows/Microsoft.NET/Framework/v4.0.30319/csc.exe

# Verilator paths for building the simulator under mingw
# Not needed if you have a working sim(_trace).exe file
VERILATOR=verilator_bin.exe
VINCLUDE=/usr/share/verilator/include

# target compiler binary
# Build forthytwo.exe externally, e.g. using Visual Studio. The .sln file uses a post-build command to copy the executable to bin/
FORTHYTWO=bin/forthytwo.exe

# generic target platform simulator: Fast version
SIM=bin/sim.exe
# generic target platform simulator: Version with trace.vcd tracing enabled
SIMTRACE=bin/simVcd.exe

all: 	${FORTHYTWO} ${SIM} testLibs testMath2

# build the forthytwo.exe compiler from source
${FORTHYTWO}:	
	${CSC} /out:gumbo.exe src\main.cs src\preprocessor.cs src\compiler.cs src\lstFileWriter.cs src\util.cs

# build the generic target platform simulator. Also builds ${SIMTRACE}
${SIM}:
	 make -C J1B

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

# removes Verilator-generated files but not the binary itself
clean:
	rm -f *~
	rm -Rf obj_dir
	rm -f *.vcd
	rm -Rf libs/out
	rm -f libs/*~
	rm -Rf out
	rm -f testMath.exe
	rm -f testMathResult_C.txt
	rm -f testMathResult_sim.txt
	find . -name "*~" -exec rm {} \;
	find . -name "*.jou" -exec rm {} \;
	find . -name "*.log" -exec rm {} \;
	rm -Rf src/bin src/obj
	find . -name "*.dcp" -exec rm {} \;
	rm -Rf refImpl/refImpl.ip_user_files/sim_scripts
	rm -Rf sampleProject/CMODA7_fractalDemo/CMODA7_fractalDemo.ip_user_files/sim_scripts

gitListUntracked:
	git ls-files . --ignored --exclude-standard --others

# removes also simulator binaries and the compiler binary
realclean: clean
	rm -f ${SIM}
	rm -f ${SIMTRACE}
	rm -f ${FORTHYTWO}

.PHONY: clean sim testMath all testFlmMath testLibs gitListUntracked
