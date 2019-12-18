all:
	bin/forthytwo.exe libs/test.txt
	bin/sim.exe libs/out/test.hex

testMath2:
# run J1 sim
	bin/forthytwo.exe libs/selftest/testMath.txt
	bin/sim.exe libs/selftest/out/testMath.hex > testMathResult_sim.txt
# run reference C code
	gcc -Wall -o testMath.exe libs/selftest/testMath.c
	./testMath.exe > testMathResult_C.txt
	diff -w testMathResult_sim.txt testMathResult_C.txt

# runs reference code on C against Fortran implementation
# make will fail here if diff observes that outputs don't match
testMath:
	gcc -Wall -o build/testMath.exe testMath.c
	${GFORTH} cross.fs basewords.fs testMath.fs
	./sim.exe build/testMath.hex > build/testMath_simOut.txt
	./build/testMath.exe > build/testMath_ref.txt
	diff -w build/testMath_simOut.txt build/testMath_ref.txt
	echo "no difference - test passed"


clean:
	rm -f *~
#	rm -Rf obj_dir
#	rm -f sim.exe
#	rm -Rf build/*
	rm bin/*

.PHONY: clean sim testMath all testMath2
