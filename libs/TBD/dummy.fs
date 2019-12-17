meta 
s" system.fs" included
s" math.fs" included
target

header quit : quit
    begin
	system.key
    again
;
	
header main : main
	
	h# FFFFFFFe
	h# 2
	math.s32*s32x2
\ system.panic
	h# 0 h# 0 io! \ \ \ \ terminate simulation
	quit
;
