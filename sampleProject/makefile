FORTHYTWO=../bin/forthytwo.exe 
GCC=gcc
SIM=../bin/sim.exe

all: out/main.hex

pointsImport.exe: pointsImport.c 
	@echo
	@echo "=== building data conversion utility ==="
	${GCC} -Wall -o pointsImport.exe pointsImport.c

pointsImported.txt: pointsImport.exe fractalPoints.txt
	@echo
	@echo "=== converting data table ==="
	./pointsImport.exe < fractalPoints.txt > pointsImported.txt

clean:
	rm -f pointsImported.txt
	rm -f pointsImport.exe
	rm -f *~
	rm -Rf out

out/main.hex: pointsImported.txt main.txt
	${FORTHYTWO} main.txt

sim: out/main.hex
	${SIM} out/main.hex

.PHONY: clean sim
