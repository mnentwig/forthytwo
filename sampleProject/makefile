FORTHYTWO=../bin/forthytwo.exe 
GCC=gcc
SIM=../bin/sim.exe

all: pointsImported.txt

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

sim:
	${FORTHYTWO} main.txt
	${SIM} out/main.hex


.PHONY: clean sim
