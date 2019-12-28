FORTHYTWO=../../bin/forthytwo.exe 
GCC=gcc
SIM=../../bin/sim.exe
all: flm.txt
flm.txt: flm.c
	cat flm.c | perl extractor.pl > flm.txt
	${GCC} -Wall -o flm.exe flm.c
	${FORTHYTWO} flm.txt
	${SIM} out/flm.hex > out/simOutput.txt
	./flm.exe > out/refOutput.txt
	diff -w out/simOutput.txt out/refOutput.txt
	echo "output identical - test passed"

clean:
	rm -f flm.txt
#forthytwo-generated output directory
	rm -Rf out/
.PHONY: clean

