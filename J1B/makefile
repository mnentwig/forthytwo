# developed on MinGW for "make" command

# make target: "Zero" reference design fast simulator
SIMZERO=../bin/simZero.exe

# make target: "Zero" reference design simulator with tracing
SIMZERO_VCD=../bin/simZeroVcd.exe

all:  ${SIMZERO} ${SIMZERO_VCD}

${SIMZERO}: sim_main.cpp simtop.v j1.v 
# there may have been issues when "make" got confused with stale obj_dir contents => remove
	rm -Rf obj_dir
	verilator -Wall -cc simtop.v --exe sim_main.cpp
	make -j -C obj_dir -f Vsimtop.mk Vsimtop
	cp obj_dir/Vsimtop.exe ${SIMZERO}

${SIMZERO_VCD}: sim_main.cpp simtop.v j1.v
# there may have been issues when "make" got confused with stale obj_dir contents => remove
	rm -Rf obj_dir
	verilator -Wall --trace -cc simtop.v --exe sim_main_trace.cpp
	make -j -C obj_dir -f Vsimtop.mk Vsimtop
	cp obj_dir/Vsimtop.exe ${SIMZERO_VCD}

clean: 
	rm -Rf obj_dir

forceclean:
	rm -f ${SIMZERO}
	rm -f ${SIMZERO_VCD}

PHONY: clean forceclean
