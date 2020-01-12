FORTHYTWO=../bin/forthytwo.exe
SIMZERO=../bin/simZero.exe
testBasic:
	@echo "=== basic feature test ==="
	${FORTHYTWO} selftest/testBasic.txt
	${SIMZERO} selftest/out/testBasic.hex > selftest/out/testResult.txt
	diff -w selftest/testResultRef.txt selftest/out/testResult.txt
	@echo "[OK] test passed"

# runs sanity checks specifically on the math library (not floating point)
testMath:
	@echo "=== math library test: J1B implementation ==="	
	${FORTHYTWO} selftest/testMath.txt
	${SIMZERO} selftest/out/testMath.hex > testMathResult_sim.txt
	@echo "=== math library test: reference C implementation ==="	
	gcc -Wall -o testMath.exe selftest/testMath.c
	./testMath.exe > testMathResult_C.txt
	diff -w testMathResult_sim.txt testMathResult_C.txt
	@echo "no difference - test passed"

# test the floating point library. Very slow
testFlm:
	make -C flm test

clean:
	rm -f testMathResult_C.txt
	rm -f testMathResult_sim.txt
	rm -Rf out
	rm -Rf selftest/out
	rm -f testMath.exe

forceclean:
	make -C flm forceclean

.PHONY: testBasic testMath testFlm clean forceclean