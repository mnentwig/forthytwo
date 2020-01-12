# make targets
FORTHYTWO=bin/forthytwo.exe
SIMZERO=../bin/simZero.exe
SIMZERO_VCD=../bin/simZeroVcd.exe
FLM=libs/flm.txt

all: 	info
info: 
	@echo "use one of the following targets:"
	@echo "- make forthytwo"
	@echo "  Builds the development system (compiler, simulator, float lib)"
	@echo "  Note: may not be necessary if files are shipped pre-built for Windows"
	@echo "- test"
	@echo "  Runs forthytwo.exe library self tests on simulator"
	@echo "- make refImpl"
	@echo "  generates BRAM contents for building the refImpl FPGA project in Vivado"
	@echo "- make fractals"
	@echo "  generates BRAM contents for building the fractals FPGA project in Vivado"
	@echo "- make clean"
	@echo "  removes generated files that are not shipped pre-built"
	@echo "- make forceclean"
	@echo "  removes also pre-built files (e.g. to test make system)"
	@echo "- make cleanup"
	@echo "  general housekeeping. Please run Vivado reset_project first in all FPGA projects"
	@echo "  "
	@echo "  "
	@echo "  "

forthytwo: ${FORTHYTWO} ${SIMZERO} ${SIMZERO_VCD} ${FLM} refImpl

${SIMZERO}: 
	@echo "=== building generic sim ${SIMZERO} ==="
	make -C J1B ${SIMZERO}

${SIMZERO_VCD}: 
	make -C J1B ${SIMZERO_VCD}

${FORTHYTWO}:
	@echo "=== building compiler ${FORTHYTWO} ==="
	make -C forthytwoCompiler

${FLM}: # floating point library must be stripped from its C reference implementation
	@echo "=== building ${FLM} floating point library ==="
	make -C libs/flm ${FLM}

bootloader: ${FORTHYTWO}
	make -C bootloader

refImpl: ${FORTHYTWO}
	make -C refImpl/refImpl.srcs

fractals: ${FORTHYTWO}
	make -C fractalsProject

test: ${FORTHYTWO} ${SIMZERO} 
	@echo "=== testing basic CPU / language features ==="
	make -C libs testBasic
	@echo "=== testing integer math ==="
	make -C libs testMath
	@echo "=== testing floating point library (this may take a while) ==="
	make -C libs testFlm

clean:
	@echo "=== cleaning generated files except those shipped pre-built ==="
	make -C forthytwoCompiler clean
	make -C J1B clean
	make -C libs clean
	make -C bootloader clean
	make -C fractalsProject clean
	make -C fractalsProject/fractalsRefImpl clean
	make -C refImpl/refImpl.srcs clean

forceclean: clean
	@echo "=== cleaning files that would be shipped pre-built ==="
	make -C forthytwoCompiler forceclean
	make -C J1B forceclean
	make -C libs forceclean
	make -C bootloader forceclean
	make -C fractalsProject forceclean
	make -C refImpl/refImpl.srcs forceclean

cleanup:
	find . -name "obj_dir" -exec rm -Rf {} \;
	find . -name "out" -exec rm -Rf {} \;
	find . -name "*.vcd" -exec rm -f {} \;
	find . -name "*~" -exec rm -f {} \;
	find . -name "*.jou" -exec rm -f {} \;
	find . -name "*.log" -exec rm -f {} \;
	find . -name "*.dcp" -exec rm -f {} \;
	find . -name ".vs" -exec rm -Rf {} \;
	rm -Rf refImpl/refImpl.ip_user_files/sim_scripts
	rm -Rf sampleProject/CMODA7_fractalDemo/CMODA7_fractalDemo.ip_user_files/sim_scripts

gitListUntracked:
	# git ls-files . --ignored --exclude-standard --others
	git ls-files . --others

.PHONY: info forthytwo bootloader refImpl fractals clean forceclean gitListUntracked test
