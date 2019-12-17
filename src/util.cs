using System;
using System.Collections.Generic;

static class util {
    static Dictionary<char, int> parseChar = new Dictionary<char, int>() { { '0', 0 }, { '1', 1 }, { '2', 2 }, { '3', 3 }, { '4', 4 }, { '5', 5 }, { '6', 6 }, { '7', 7 }, { '8', 8 }, { '9', 9 }, { 'A', 10 }, { 'B', 11 }, { 'C', 12 }, { 'D', 13 }, { 'E', 14 }, { 'F', 15 } };

    public static bool tryParseNum(string text, out UInt32 val) {
        text = text.ToUpper();
        val = 0;

        // === check minus sign ===
        bool negate = false;
        if(text.StartsWith("-")) {
            negate = true;
            text = text.Substring(1);
        }

        // === all numbers must start with 0..9 (includes 0x etc prefixes) ===
        char c1 = text[0];
        if((c1 < '0') || (c1 > '9'))
            return false;

        // === determine base ===
        UInt32 b = 10;
        if(text.StartsWith("0B")) { b = 2; text = text.Substring(2); } else if(text.StartsWith("0O")) { b = 8; text = text.Substring(2); } // octal, non-standard
                                                                       else if(text.StartsWith("0X")) { b = 16; text = text.Substring(2); }

        // === parse resulting value ===
        for(int ix = 0; ix < text.Length; ++ix) {
            val *= b;
            if(!parseChar.TryGetValue(text[ix], out int charVal)) throw new Exception("invalid character in number: >>>"+text+"<<<"); ;
            if(charVal >= b)
                throw new Exception("number digit out of range in >>>"+text+"<<<");
            val += (UInt32)charVal;
        }

        // === apply two's complement negation ===
        if(negate) {
            val = ~val + 1u;
        }
        return true;
    }

    public static string hex4(UInt16 val) {
        return String.Format("0x{0:X04}", val);
    }

    public static string hex8(UInt32 val) {
        return String.Format("0x{0:X08}", val);
    }


}