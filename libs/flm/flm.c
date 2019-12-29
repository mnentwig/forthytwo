//|// ########################################################################
//|// # The file flm.txt is auto-generated by extractor.pl from flm.c
//|// # Its purpose is a system library for 32-bit pseudo-float math.
//|// # Public symbols are prefixed with the library name:
//|// # - flm.pack (build float from exponent and mantissa)
//|// # - flm.unpack (split float into exponent and mantissa)
//|// # - flm.add (add two floats)
//|// ########################################################################
//|// # (note, private symbol xyz is prefixed as __flm.xyz)

// C code in this fils is the reference implementation.

// "packed" format
// - 26-bit mantissa "M" including sign bit "S"
//   SMMMMMMM MMMMMMMM MMMMMMMM MMEEEEEE
// 84218421 84218421 84218421 84218421
// - 6-bit exponent (including exponent sign bit as MSB)
//
// normalization convention: The mantissa MSB (below the sign bit) is always active
// that is, set for positive, clear for negative numbers. Unlike IEEE float, it is NOT implied.
//
// "unpacked format": 6 additional mantissa MSBs "A" that must be normalized away before packing
// SAAAAAAM MMMMMMMM MMMMMMMM MMMMMMMM
// 84218421 84218421 84218421 84218421

// check for negative: if unpackedMantissa & 0x80000000
// negative_mustShiftDown : if unpackedMantissa & 0x7E000000 != 0x7E000000
// negative_mustShiftUp : if unpackedMantissa & 0x01000000 == 0
// positive_mustShiftDown: if unpackedMantissa & 0x7E000000 != 0
// positive_mustShiftUp: if unpackedMantissa & 0x01000000 == 0

int unpackedNegativeMantissa_mustShiftDown(int32_t mantissa){
  return (mantissa & 0x7E000000) != 0x7E000000;
}
//|::__unpackedNegativeMantissa_mustShiftDown 0x7E000000 dup >r core.and r> = core.invert ;

// =================================================================================================

int unpackedNegativeMantissa_mustShiftUp(int32_t mantissa){
  return mantissa & 0x01000000;
}
//|::__unpackedNegativeMantissa_mustShiftUp 0x01000000 core.and ;

// =================================================================================================

int unpackedPositiveMantissa_mustShiftDown(int32_t mantissa){
  return mantissa & 0x7E000000;
}
//|::__unpackedPositiveMantissa_mustShiftDown 0x7E000000 core.and ;

// =================================================================================================

int unpackedPositiveMantissa_mustShiftUp(int32_t mantissa){
  return (mantissa & 0x01000000) == 0;
}
//|::__unpackedPositiveMantissa_mustShiftUp 0x01000000 core.and 0 = ;

// =================================================================================================

void unpackedNormalize_negative(int32_t* mantissa, int32_t* exponent){
 again:
    if (unpackedNegativeMantissa_mustShiftDown(*mantissa)){
	*exponent = *exponent+1;
	*mantissa = *mantissa >> 1; // note: arithmetic shift
	goto again;
    }
    if (unpackedNegativeMantissa_mustShiftUp(*mantissa)){
      if ((*exponent & 0x2F) != 0x20){
	*exponent = *exponent-1;
	*mantissa = *mantissa << 1;
	goto again;
      }
    }
}
//|:__unpackedNormalize_negative
//|dup __unpackedNegativeMantissa_mustShiftDown 
//|IF
//|	swap 1 +
//|	swap 1 core.rshift
//|	0x80000000 core.or
//|	BRA:__unpackedNormalize_negative
//|ENDIF
//|dup __unpackedNegativeMantissa_mustShiftUp
//|IF
//| 	// check whether exponent is already at clip limit
//|	core.over 0x2F core.and 0x20 core.equals core.invert
//|	IF
//|		swap -1 +
//|		swap 1 core.lshift
//|		BRA:__unpackedNormalize_negative
//|	ENDIF
//|ENDIF
//|;

// =================================================================================================

void unpackedNormalize_positive(int32_t* mantissa, int32_t* exponent){
 again:
    if (unpackedPositiveMantissa_mustShiftDown(*mantissa)){
      *exponent = *exponent+1;
      *mantissa = *mantissa >> 1;
      goto again;
    }
    if (unpackedPositiveMantissa_mustShiftUp(*mantissa)){
      if ((*exponent & 0x2F) != 0x20){
	*exponent = *exponent-1;
	*mantissa = *mantissa << 1;
	goto again;
      }
    }
}

//|:__unpackedNormalize_positive
//|dup __unpackedPositiveMantissa_mustShiftDown 
//|IF
//|	swap 1 +
//|	swap 1 core.rshift
//|	BRA:__unpackedNormalize_positive
//|ENDIF
//|dup __unpackedPositiveMantissa_mustShiftUp
//|IF
//| 	// check whether exponent is already at clip limit
//|	core.over 0x2F core.and 0x20 core.equals core.invert
//|	IF
//|		swap -1 +
//|		swap 1 core.lshift
//|		BRA:__unpackedNormalize_positive
//|	ENDIF
//|ENDIF
//|;

// =================================================================================================

int32_t flm_rshiftArith(int32_t val, int32_t amount){
  if (amount < 32)
    return val >> amount;
  if (val < 0)
    return 0xFFFFFFFF;
  return 0;
}

//|// returns number with n bits set, starting from bit 31
//|::__flm.nMsbMask core.invert 33 + 
//|1 swap core.lshift 
//|0 core.invert + core.invert ;
//|
//|//arithmetic right shift (MSB replica stays in place)
//|:flm.rshiftArith
//|// special case:shift by 0 
//|core.dup 0 core.equals IF drop ; ENDIF
//|>r // store shift amount
//|r@ 32 core.lessThanSigned 
//|IF
//|	dup 0 <s 
//|	IF
//|		// shift and set new MSBs
//|		r@ __flm.nMsbMask swap r> core.rshift core.or ;
//|	ENDIF
//|	r> core.rshift ;
//|ENDIF
//|r> drop // clean up shift amount
//|0 core.lessThanSigned BZ:__flm.rshiftArithResultAllZero
//|0 core.invert ; // return 0xFFFFFFFF
//|:__flm.rshiftArithResultAllZero
//|0 ; // return 0x00000000
//|
// =================================================================================================

void unpackedNormalize(int32_t* mantissa, int32_t* exponent){
  if (*mantissa == 0){
    *exponent = 0;
    return;
  }
  
  // keep exponent in range
  while (*exponent < -32){
    ++*exponent; *mantissa = flm_rshiftArith(*mantissa, 1);
  }  
  while (*exponent > 31){
    --*exponent; *mantissa <<= 1; 
  }
  
  if (*mantissa & 0x80000000)
    unpackedNormalize_negative(mantissa, exponent);
  else
    unpackedNormalize_positive(mantissa, exponent);
}

//|// 1: exponent; 0: mantissa
//|:__flm.unpackedNormalize
//|dup 
//|IF // mantissa is non-zero? YES
//|	swap // 0: exponent; 1: mantissa
//|	// ===fix exponent below -32===
//|	BEGIN
//|		/*exponent*/ dup -32 core.lessThanSigned 
//|    	WHILE
//|		1 + swap 1 flm.rshiftArith swap
//|	REPEAT
//|	// ===fix exponent above 31===
//|	BEGIN
//|		/*exponent*/ dup 31 swap core.lessThanSigned 
//|    	WHILE
//|		/*-1*/ 0 core.invert + swap 1 core.lshift swap
//|	REPEAT
//|	swap // 0: mantissa; 1: exponent
//|	/*mantissa*/ dup 0x80000000 core.and 
//|	IF // mantissa is negative? YES
//|		__unpackedNormalize_negative     
//|	ELSE // mantissa is negative? NO
//|		__unpackedNormalize_positive
//|	ENDIF // mantissa is negative?
//|ELSE // mantissa is non-zero? NO
//|	swap drop 0
//|ENDIF // mantissa is zero?
//|;

// =================================================================================================

void flm_unpack(int32_t packed, int32_t* mantissa, int32_t* exponent){
  *exponent = packed & 0x3F;
  if (*exponent & 0x20)
    *exponent |= 0xFFFFFFC0;
  *mantissa = packed >> 6; // note, arithmetic shift
}

//|:flm.unpack
//|// === mask to return stack ===
//|0x0000003F >r
//|// === extract exponent ===
//|dup r@ core.and 
//|// === negative sign extension ===
//|dup 0x00000020 core.and IF
//|0xFFFFFFC0 core.or 
//|ENDIF
//|
//|// === extract mantissa ===
//|swap r> core.invert core.and
//|6 flm.rshiftArith ;
//|

void flm_unpackUp6(int32_t packed, int32_t* mantissa, int32_t* exponent){
  *exponent = packed & 0x3F;
  if (*exponent & 0x20)
    *exponent |= 0xFFFFFFC0;
  *mantissa = packed & ~0x3F;
}
//|:flm.unpackUp6
//|// === mask to return stack ===
//|0x0000003F >r
//|// === extract exponent ===
//|dup r@ core.and 
//|// === negative sign extension ===
//|dup 0x00000020 core.and IF
//|0xFFFFFFC0 core.or 
//|ENDIF
//|
//|// === extract mantissa, shifted 6 bits up ===
//|swap r> core.invert core.and ;
//|

// =================================================================================================

void flm_pack(int32_t mantissa, int32_t exponent, int32_t* packed){
  *packed = (mantissa << 6) | (exponent & 0x3F);
  //printf("flm_pack m:%08x e:%08x r:%08x\n", mantissa, exponent, *packed);
}
//|:flm.pack
//|6 core.lshift
//|swap
//|0x0000003F core.and
//|core.or
//|;

// =================================================================================================

// =================================================================================================

void flm_add(int32_t packedA, int32_t packedB, int32_t* result){
  int32_t mantissaA;
  int32_t exponentA;
  int32_t mantissaB;
  int32_t exponentB;
  flm_unpack(packedA, &mantissaA, &exponentA);
  flm_unpack(packedB, &mantissaB, &exponentB);
  //printf("flm_add mA:%08x eA: %08x mB:%08x eB:%08x\n", mantissaA, exponentA, mantissaB, exponentB);
  int32_t exponentResult = exponentA > exponentB ? exponentA : exponentB;
  int32_t deltaA = exponentResult-exponentA;
  int32_t deltaB = exponentResult-exponentB;
  //printf("shift A by %i: before %08x\n", deltaA, mantissaA); 

  mantissaA = flm_rshiftArith(mantissaA, deltaA);
  mantissaB = flm_rshiftArith(mantissaB, deltaB);

  //printf("flm_add (shifted) mA:%08x mB:%08x eCommon: %08x\n", mantissaA, mantissaB, exponentResult);
  int32_t mantissaResult = mantissaA + mantissaB;
  //printf("flm_add (prenorm) mR:%08x eR: %08x\n", mantissaResult, exponentResult);

  unpackedNormalize(&mantissaResult, &exponentResult);
  //printf("flm_add (postnorm) mR:%08x eR: %08x\n", mantissaResult, exponentResult);
  flm_pack(mantissaResult, exponentResult, result);
  //printf("flm_add res:%08x\n", *result);
}

//|VAR:__flm.mantissaA=0
//|VAR:__flm.mantissaB=0
//|VAR:__flm.exponentA=0
//|VAR:__flm.exponentB=0
//|
//|
//|:flm.add
//|flm.unpack
//|'__flm.mantissaA ! '__flm.exponentA !
//|flm.unpack
//|'__flm.mantissaB ! '__flm.exponentB !
//|
//|// === decide target exponent ===
//|'__flm.exponentA @ '__flm.exponentB @ <s 
//|IF
//|'__flm.exponentB @ 
//|ELSE
//|'__flm.exponentA @
//|ENDIF
//|>r
//|
//|'__flm.mantissaA @
//|'__flm.exponentA @ core.invert 1 + r@ + flm.rshiftArith
//|
//|'__flm.mantissaB @
//|'__flm.exponentB @ core.invert 1 + r@ + flm.rshiftArith
//|
//|// === mantissa A and B are now aligned, common exponent in r@ ===
//|core.plus
//|
//|r>		 // recall mantissa
//|swap		 // restore unpacked order
//|
//|__flm.unpackedNormalize
//|flm.pack
//|;

// =================================================================================================

void flm_mul(int32_t packedA, int32_t packedB, int32_t* result){
  int32_t mantissaA;
  int32_t exponentA;
  int32_t mantissaB;
  int32_t exponentB;
  flm_unpackUp6(packedA, &mantissaA, &exponentA);
  flm_unpackUp6(packedB, &mantissaB, &exponentB);
  //printf("flm_mul mA:%08x(%i) eA:%08x(%i) mB:%08x(%i) eB:%08x(%i)\n", mantissaA, mantissaA, exponentA, exponentA, mantissaB, mantissaB, exponentB, exponentB);
  int64_t prod = (int64_t)mantissaA * (int64_t)mantissaB;
  //printf("flm_mul p64:%016" PRIx64 "\n", (uint64_t)prod);
  int32_t mantissaResult;
  int32_t exponentResult;
  mantissaResult = prod >> 32;
  exponentResult = exponentA + exponentB + (32-6-6);
  //printf("flm_mul (prenorm) mr:%08x er:%08x\n", mantissaResult, exponentResult);

  unpackedNormalize(&mantissaResult, &exponentResult);
  //printf("flm_mul (postnorm) mr:%08x er:%08x\n", mantissaResult, exponentResult);
  flm_pack(mantissaResult, exponentResult, result);  
}

//|:flm.mul
//|flm.unpackUp6
//|'__flm.mantissaA ! '__flm.exponentA !
//|flm.unpackUp6
//|'__flm.mantissaB ! '__flm.exponentB !
//|
//|// === result exponent ===
//|'__flm.exponentA @ '__flm.exponentB @ + 20 +
//|// === result mantissa ===
//|'__flm.mantissaA @ '__flm.mantissaB @ math.s32*s32x2 drop
//|__flm.unpackedNormalize
//|flm.pack
//|;

void flm_div(int32_t packedA, int32_t packedB, int32_t* result){
  int32_t mantissaA;
  int32_t exponentA;
  int32_t mantissaB;
  int32_t exponentB;
  flm_unpackUp6(packedA, &mantissaA, &exponentA);
  flm_unpackUp6(packedB, &mantissaB, &exponentB);
  //printf("flm_div mA:%08x(%i) eA:%08x(%i) mB:%08x(%i) eB:%08x(%i)\n", mantissaA, mantissaA, exponentA, exponentA, mantissaB, mantissaB, exponentB, exponentB);

  // === convert to signed ===
  int negate = 0;
  if (mantissaA < 0){
    mantissaA = -mantissaA;
    ++negate;    
  }
  if (mantissaB < 0){
    mantissaB = -mantissaB;
    ++negate;    
  }

  uint32_t mask = 0x40000000;
  int32_t mantissaResult = 0;
  uint32_t a = mantissaA;
  uint32_t b = mantissaB;
  while ((mask != 0) && (a != 0)){
    if (a >= b){
      a -= b;
      mantissaResult |= mask;
    }
    mask >>= 1;
    a <<= 1;
  }

  if (negate & 1)
    mantissaResult = -mantissaResult;

  int exponentResult = exponentA - exponentB - 30;
  //printf("flm_div (prenorm) mr:%08x er:%08x\n", mantissaResult, exponentResult);

  unpackedNormalize(&mantissaResult, &exponentResult);
  //printf("flm_div (postnorm) mr:%08x er:%08x\n", mantissaResult, exponentResult);
  flm_pack(mantissaResult, exponentResult, result);  
}
