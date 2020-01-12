BIN=../../bin
FORTHYTWO=${BIN}/forthytwo.exe 
SIMZERO=${BIN}/sim.exe

all:
	${FORTHYTWO} main.txt
sim:
	${SIMZERO} out/main.hex out/main.bootBin
clean:
	rm -Rf out

forceclean: clean

.PHONY: sim clean forceclean
