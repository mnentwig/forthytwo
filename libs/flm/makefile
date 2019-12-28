FORTHYTWO=../../bin/forthytwo.exe 
GCC=gcc
SIM=../../bin/sim.exe
all: buildLib testLib
buildLib: flm.c flm_test.c
# separate the FORTH code in flm.c from its reference implementation
	cat flm.c | perl extractor.pl > ../flm.txt
# separate the FORTH code in flm_test.c from its reference implementation
	cat flm_test.c | perl extractor.pl > flm_test.txt

testLib: buildLib
# build the reference implementation flm.exe
	${GCC} -Wall -O -o flm_test.exe flm_test.c
# build the simulation
	${FORTHYTWO} flm_test.txt
# run reference implementation
	./flm_test.exe > out/refOutput.txt
# run simulation
	${SIM} out/flm_test.hex > out/simOutput.txt
# compare the results
	diff -w out/simOutput.txt out/refOutput.txt
	echo "output identical - test passed"

# run simulator with console output after manually editing flm.txt
debug:
	${FORTHYTWO} flm.txt
	${SIM} out/flm.hex

clean:
# output product
	rm -f ../flm.txt
#forthytwo-generated output directory
	rm -Rf out/
.PHONY: buildLib testLib clean debug

