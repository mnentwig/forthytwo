# build tools
FORTHYTWO=../../bin/forthytwo.exe 
GCC=gcc
SIMZERO=../../bin/simZero.exe

# build target
FLM=../flm.txt
FLMTESTEXE=flm_test.exe

all: ${FLM}
${FLM}: flm.c flm_test.c flm_testAlg.c
	@echo "=== separate the FORTH code in flm.c from its reference implementation ==="
	cat flm.c | perl extractor.pl > ${FLM}


test: ${FLM}  flm_test.c
	@echo "=== build the reference implementation flm.exe ==="
	${GCC} -Wall -O -o flm_test.exe flm_test.c

	@echo "=== run reference implementation ==="
	rm -Rf out
	mkdir out
	./flm_test.exe > out/refOutput.txt

	@echo "=== separate the FORTH code in flm_test.c from its reference implementation ==="
	cat flm_test.c | perl extractor.pl > flm_test.txt

	@echo "=== compile test ==="
	${FORTHYTWO} flm_test.txt

	@echo "=== run simulation ==="
	${SIMZERO} out/flm_test.hex > out/simOutput.txt

	@echo "=== compare the results ==="
	diff -w out/simOutput.txt out/refOutput.txt
	@echo "=== output identical - test passed ==="

# run simulator with console output
debug:
	${FORTHYTWO} flm_test.txt
	${SIM} out/flm_test.hex

clean:	
	rm -Rf out/
	rm -f flm_test.txt
	rm -f flm_test.exe

# extracted library is checked in on git
forceclean: clean
	rm -f ${FLMTXT}

.PHONY: test debug clean realclean 
