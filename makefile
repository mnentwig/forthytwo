VERILATOR=verilator_bin.exe
VINCLUDE=/usr/share/verilator/include
# note: build forthytwo.exe externally, e.g. using Visual Studio. The .sln file uses a post-build command to copy the executable to bin/
FORTHYTWO=bin/forthytwo.exe
all: 	bin/sim.exe testLibs testMath2

testLibs:
	@echo "=== basic feature test ==="
	bin/forthytwo.exe libs/test.txt
	bin/sim.exe libs/out/test.hex > libs/out/testResult.txt
	diff -w libs/testResultRef.txt libs/out/testResult.txt
	@echo "[OK] test passed"

main:
	${FORTHYTWO} main.txt
	bin/sim.exe out/main.hex

bin/sim.exe:
	 make -C J1B



# runs reference code on C against Forth implementation
# make will fail here if diff observes that outputs don't match
testMath2:
	@echo "=== math library test ==="	
# run J1 sim
	${FORTHYTWO} libs/selftest/testMath.txt
	bin/sim.exe libs/selftest/out/testMath.hex > testMathResult_sim.txt
# run reference C code
	gcc -Wall -o testMath.exe libs/selftest/testMath.c
	./testMath.exe > testMathResult_C.txt
	diff -w testMathResult_sim.txt testMathResult_C.txt
	@echo "no difference - test passed"

clean:
	rm -f *~
	rm -Rf obj_dir

realclean: clean
	rm -f bin/sim.exe

.PHONY: clean sim testMath all testMath2 testLibs
