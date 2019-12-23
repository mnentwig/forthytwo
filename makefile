VERILATOR=verilator_bin.exe
VINCLUDE=/usr/share/verilator/include
all:
	bin/forthytwo.exe libs/test.txt
	bin/sim.exe libs/out/test.hex > libs/out/testResult.txt
	diff -w libs/testResultRef.txt libs/out/testResult.txt
	echo "no difference - test passed"


simulator:
	${VERILATOR} -Wall -cc J1B/j1b.v -Ij1B --exe sim_main.cpp
	g++ -I obj_dir -I ${VINCLUDE} -I ${VINCLUDE}/vltstd J1B/sim_main.cpp obj_dir/Vj1b.cpp obj_dir/Vj1b__Syms.cpp ${VINCLUDE}/verilated.cpp -o bin/sim.exe


# runs reference code on C against Fortran implementation
# make will fail here if diff observes that outputs don't match
testMath2:
# run J1 sim
	bin/forthytwo.exe libs/selftest/testMath.txt
	bin/sim.exe libs/selftest/out/testMath.hex > testMathResult_sim.txt
# run reference C code
	gcc -Wall -o testMath.exe libs/selftest/testMath.c
	./testMath.exe > testMathResult_C.txt
	diff -w testMathResult_sim.txt testMathResult_C.txt
	echo "no difference - test passed"

clean:
	rm -f *~
#	rm -Rf obj_dir
#	rm -f sim.exe
#	rm -Rf build/*
	rm bin/*

.PHONY: clean sim testMath all testMath2
