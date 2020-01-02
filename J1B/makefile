all: ../bin/sim.exe ../bin/simVcd.exe

# fast simulator without tracing
../bin/sim.exe: sim_main.cpp simtop.v j1.v 
	verilator -Wall -cc simtop.v --exe sim_main.cpp
	make -j -C obj_dir -f Vsimtop.mk Vsimtop
	cp obj_dir/Vsimtop.exe ../bin/sim.exe
	rm -Rf obj_dir

# simulator with VCD trace dump for gtkwave
../bin/simVcd.exe: sim_main.cpp simtop.v j1.v
	verilator -Wall --trace -cc simtop.v --exe sim_main_trace.cpp
	make -j -C obj_dir -f Vsimtop.mk Vsimtop
	cp obj_dir/Vsimtop.exe ../bin/simVcd.exe
	rm -Rf obj_dir

clean: 
	rm -Rf obj_dir
	rm -f *~
realclean:
	rm -f ../bin/sim.exe
	rm -f ../bin/simVcd.exe
PHONY: clean realclean