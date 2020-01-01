BIN=../../bin
FORTHYTWO=${BIN}/forthytwo.exe 
SIM=${BIN}/sim.exe

all:
	${FORTHYTWO} bootloader.txt
	${FORTHYTWO} main.txt
	${SIM} out/bootloader.hex out/main.bootBin
clean:
	rm -Rf out
	rm *~

.PHONY: clean
