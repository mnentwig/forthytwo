all: ../bin/sim.exe ../bin/simVcd.exe

# fast simulator without tracing
../bin/sim.exe:
	verilator -Wall -cc simtop.v --exe sim_main.cpp
	make -j -C obj_dir -f Vsimtop.mk Vsimtop
	cp obj_dir/Vsimtop.exe ../bin/sim.exe

# simulator with VCD trace dump for gtkwave
../bin/simVcd.exe:
	verilator -Wall --trace -cc simtop.v --exe -DMYTRACINGFLAG sim_main.cpp
	make -j -C obj_dir -f Vsimtop.mk Vsimtop
	cp obj_dir/Vsimtop.exe ../bin/simVcd.exe

clean: 
	rm -Rf obj_dir
	rm -f *~
PHONY: clean