\ \ \ \ note: 
meta 
s" system.fs" included
s" math.fs" included
target

: quit
	h# 0 h# 0 io! \ \ \ \ terminate simulation
;
	
create testMath.arg1 $12345678 ,
create testMath.arg2 $98765432 ,

: LFSR32 
	dup d# 13 lshift xor
	dup d# 17 rshift xor
	dup d# 5 lshift xor
;

: __advanceLfsr 
	testMath.arg1 @ LFSR32 testMath.arg1 ! 
	testMath.arg2 @ LFSR32 testMath.arg2 ! 
;

: __pushBothLfsr
	testMath.arg1 @ 
	testMath.arg2 @
;
: main
	d# 100 math.negate \ \ \ \ initialize loop variable
	begin		
		\ h# FFFFFFFF dup testMath.arg1 !	testMath.arg2 !


		\ \ \ \ write col1:arg1; col2:arg2
		__pushBothLfsr
		swap system.emit.hex8 system.emit.space system.emit.hex8 system.emit.space

		\ \ \ \ write col3: u32*u32
		__pushBothLfsr
		math.u32*u32
		system.emit.hex8 system.emit.space

		\ \ \ \ write col4 u16*u32
		__pushBothLfsr
		swap h# FFFF and swap \ \ \ \ mask arg1 to 16 bit
		math.u16*u32
		system.emit.hex8 system.emit.space

		\ \ \ \ wire col5 (L) and col 6 (H) of u32xu32x2
		__pushBothLfsr
		math.u32*u32x2
		system.emit.hex8 system.emit.space
		system.emit.hex8 system.emit.space

		\ \ \ \ wire col7 (L) and col 8 (H) of s32xs32x2
		__pushBothLfsr
		math.s32*s32x2
		system.emit.hex8 system.emit.space
		system.emit.hex8 system.emit.space

		\ \ \ \ end of results file line
		system.emit.cr

		__advanceLfsr
		d# 1 + dup d# 0 = \ \ \ \ increase loop var and exit on 0
	until
	drop 	\ remove loop variable

	\ sanity check: stack must be empty
	depths d# 0 = invert if 
		system.panic 
	then
	quit
;
