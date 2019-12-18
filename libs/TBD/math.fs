target \ \ \ \ this file will be "included" in "meta" state => must switch to "target"
create math.scratch 0 ,
create math.scratchALo 0 ,
create math.scratchAHi 0 ,
create math.scratchBLo 0 ,
create math.scratchBHi 0 ,
\ partial products for 32x32=>64 multiplication
create math.scratchLL 0 ,
create math.scratchLH 0 ,
create math.scratchHL 0 ,
create math.scratch.A 0 ,
create math.scratch.B 0 ,
create math.scratchMidSum 0 ,

: math.negate    invert d# 1 + ;


\ input: A16 multiplicand
\ input: B32 multiplicand
\ output: product
: math.u16*u32 ( u16 u32 -- u32 )
    math.scratch !	\ store B32
    d# 16 lshift	\ adjust A16 for MSB check in 32 hardware bits
    d# 0 swap 		\ initialize acc
    __mul16step 	\ run multiplication
    drop		\ remove modified A
;

\ input: A32 multiplicand
\ input: B32 multiplicand
\ output: product [63:32]
\ output: product [31:0]
: math.u32*u32x2 ( u32 u32 -- u32 u32 )
    h# FFFF >r			\ 16 low bit mask on rstack
    dup r@ and math.scratchBLo !
    swap 			\ push back B, continue on A
    dup r> and math.scratchALo ! 

    d# 16 rshift math.scratchAHi ! 
    d# 16 rshift math.scratchBHi ! 
    	 			\ stack is now empty

    \ === cross terms ====				
    math.scratchALo @
    math.scratchBHi @
    math.u16*u32		\ mid product LH
    math.scratchLH !

    math.scratchAHi @
    math.scratchBLo @
    math.u16*u32		\ mid product HL
    math.scratchHL !	    

    \ === low result ===
    math.scratchALo @		\ LL
    math.scratchBLo @
    math.u16*u32
    math.scratchLL !

    \ === add cross terms to low result ===
    math.scratchLL @
    math.scratchLH @ d# 16 lshift +
    math.scratchHL @ d# 16 lshift +

    \ === high result ===					
    math.scratchAHi @		\ HH
    math.scratchBHi @
    math.u16*u32

    \ === add cross terms to high result ===
    math.scratchLH @ d# 16 rshift +
    math.scratchHL @ d# 16 rshift +

    \ === carry ===
    math.scratchLL @ d# 16 rshift
    math.scratchLH @ h# FFFF and
    math.scratchHL @ h# FFFF and
    +    
    +

    d# 16 rshift		\ carry = ((LL >> 16) + (LH+HL)[31:0]) >> 16
    + 				\ add carry to high result

    swap			\ return 0:lowRes, 1:highRes
;

: math.s32*s32x2xxx
	dup >r			\ save the input arguments
	swap dup >r		\ (reverses order, result is the same)

	math.u32*u32x2		\ start with unsigned multiplication	

	swap 			\ flip word order: correction will be applied to res[63:32]
	
	r> r@ swap dup >r swap \ input arguments on stack and return stack in reverse order
	d# 0 < if 
		r>		\ correction term
	else
		r> drop d# 0 	\ no correction term
	then

	swap			\ push back correction term
	d# 0 < if 
		r> +		\ add correction terms
	else
		r> drop		\ no correction term
	then

	math.negate		\ subtract correction term
	+

	swap 			\ un-flip word order
;

: math.s32*s32x2
	dup
	math.scratch.A !
	swap dup 
	math.scratch.B !

	math.u32*u32x2		\ start with unsigned multiplication	
	swap 			\ flip word order: correction will be applied to res[63:32]

	math.scratch.A @	
	d# 0 < if 
		math.scratch.B @
	else
		d# 0
	then
	math.scratch.B @
	d# 0 0 < if 
		math.scratch.A @
		+
	then

	math.negate		\ subtract correction term
	+

	swap 			\ un-flip word order
;

meta				\ undo "target" at head of file