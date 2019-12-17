target \ \ \ \ this file will be "included" in "meta" state => must switch to "target"

create system.scratch 0 ,

\ implement the "minus" operator in software
: - invert d# 1 + + ;

\ UART data register
$1000 constant system.UART-D

\ UART constant register
$2000 constant system.UART-STATUS
: system.emit : emit
    begin
	 d# 1
	 system.UART-STATUS io@ 
	 and 
	 d# 0
	  =
	 invert
    until
    system.UART-D io!
;

: system.key?
    d# 2
    system.UART-STATUS io@ and 0 = invert
;

: system.key
    begin
        system.key?
    until
    system.UART-D io@
;

: system.finish begin d# 0 until ;

: system.emit.space h# 20 system.emit ;
: system.emit.cr h# d system.emit h# a system.emit ;

: system.emit.hex8 dup d# 16 rshift DOUBLE
: system.emit.hex4 dup d# 8 rshift DOUBLE
: system.emit.hex2 dup d# 4 rshift DOUBLE
: system.emit.hex1
    h# f and
    dup d# 10 < if
        [char] 0
    else
        d# 87 \ \ \ \ 'a'-10 (use lower case for C sprintf compatibility)
    then
    +
    emit
;

\ writes "d=%02h " with %02h = stack depth
\ note, "d" is the corresponding symbol in j1.v
: system.emit.stackdepth 
    [char] d system.emit 
    [char] = system.emit
    depths system.emit.hex2 \ "depths" is CPU opcode
    system.emit.space
;

\ writes n stack levels as sprintf("%02x:%08x\r\n", stacklevel, stackvalue)
\ n is consumed; the stack remains otherwise unchanged
: system.emit.hex8.nodrop.n \ (n -- )    
    dup system.scratch ! \ \ \ \ save number of requested levels

    \ === iterate over stack levels and dump    
    begin
	d# 1 - \ \ \ \  decrease counter
        dup d# 0 < invert while \ \ \ \  exit if counted beyond level 0

	\ \ \ \  write stack level count
	dup system.scratch @ swap invert + \ \ \ \ nLevels - counter - 1 (x invert is "1-x")
	system.emit.hex2 [char] : system.emit

        \ \ \ \  write word on stack
	swap >r r@ system.emit.hex8 system.emit.space

    repeat
    drop \ \ \ \  remove counter
   
    \ \ \ \  restore stack content
    system.scratch @ \ \ \ \  initialize counter with number of levels to restore
    begin
        d# 1 - \ \ \ \  decrease counter
        dup d# 0 < invert while \ \ \ \  exit if counted beyond level 0
        r> swap \ \ \ \  recall stored value from return stack and move over counter
    repeat
    
    drop \ \ \ \  remove counter

    system.emit.cr \ \ \ \ append newline
;

\ same as system.emit.hex8.nodrop.n for all stack levels
: system.emit.hex8.nodrop.all \ ( -- )    
	depths system.emit.hex8.nodrop.n
;

\ stackdump and shutdown
: system.panic
	\ \ \ \ write string "panic\r\n"
	[char] p system.emit
	[char] a system.emit
	[char] n system.emit
	[char] i system.emit
	[char] c system.emit
	system.emit.cr

	\ \ \ \ dump stack
	system.emit.hex8.nodrop.all 

	\ \ \ \ terminate simulation
	h# 0 h# 0 io!
	begin again
;

meta \ \ \ \ undo "target" at head of file