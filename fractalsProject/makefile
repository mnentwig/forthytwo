FORTHYTWO=../bin/forthytwo.exe 
GCC=gcc
SIMZERO=../bin/simZero.exe

all: main.v

pointsImport.exe: pointsImport.c 
	@echo
	@echo "=== building data conversion utility ==="
	${GCC} -Wall -o pointsImport.exe pointsImport.c

pointsImported.txt: pointsImport.exe fractalPoints.txt
	@echo
	@echo "=== converting data table ==="
	./pointsImport.exe < fractalPoints.txt > pointsImported.txt

main.v: pointsImported.txt main.txt
	@echo
	@echo "=== compiling application ==="
	${FORTHYTWO} main.txt
	mv out/main.v .

sim: main.v
	${SIMZERO} out/main.hex

clean:
	rm -f pointsImported.txt
	rm -f pointsImport.exe
	rm -Rf out
	make -C CMODA7_fractalDemo/CMODA7_fractalDemo.srcs clean

forceclean:
	rm -f main.v
# Vivado cleanup. Putting this here as it is the closest makefile
	rm -Rf CMODA7_fractalDemo/CMODA7_fractalDemo.hw
	rm -Rf CMODA7_fractalDemo/CMODA7_fractalDemo.cache
	rm -Rf CMODA7_fractalDemo/CMODA7_fractalDemo.ip_user_files

.PHONY: clean forceclean sim
