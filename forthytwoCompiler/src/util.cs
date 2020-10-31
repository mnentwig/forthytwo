using System;
using System.Collections.Generic;
using System.Globalization;

static class util {


    static UInt32 double2flm(double val) {
        unchecked {
            Int32 exponent = 0;
            if(val > 0) {
                while(val > (Int32)0x01FFFFFF) {
                    val /= 2.0; ++exponent;
                    if(exponent == 31) break;
                }
                while(val < (Int32)0x01000000) {
                    val *= 2.0; --exponent;
                    if(exponent == -32) break;
                }
            } else {
                while(val < (Int32)0xFE000000) {
                    val /= 2.0; ++exponent;
                    if(exponent == 31) break;
                }
                while(val > (Int32)0xFEFFFFFF) {
                    val *= 2.0; --exponent;
                    if(exponent == -32) break;
                }
            }

            Int32 mantissa = (Int32)(val + 0.5);
            UInt32 res;

            res = (UInt32)((mantissa << 6) | (exponent & 0x3F));
            return res;
        }
    }

    static Dictionary<char, int> parseChar = new Dictionary<char, int>() { { '0', 0 }, { '1', 1 }, { '2', 2 }, { '3', 3 }, { '4', 4 }, { '5', 5 }, { '6', 6 }, { '7', 7 }, { '8', 8 }, { '9', 9 }, { 'A', 10 }, { 'B', 11 }, { 'C', 12 }, { 'D', 13 }, { 'E', 14 }, { 'F', 15 } };

    public static bool tryParseNum(string text, out UInt32 val, bool enableFloat) {
        string textOrig = text;
        text = text.ToUpper();
        val = 0;
        UInt64 _val = 0;

        if(enableFloat && text.Contains(".")) {
            double vDouble;
            if(Double.TryParse(text, NumberStyles.Number, CultureInfo.CreateSpecificCulture("en-US"), out vDouble)) {
                val = double2flm(vDouble);
                return true;
            }
        }


        // === check minus sign ===
        bool negate = false;
        if(text.StartsWith("-")) {
            if(text.Length < 2)
                return false; 
            negate = true;
            text = text.Substring(1);
        }

        // === all numbers must start with 0..9 (includes 0x etc prefixes) ===
        char c1 = text[0];
        if((c1 < '0') || (c1 > '9'))
            return false;

        // === determine base ===
        UInt32 b = 10;
        if(text.StartsWith("0B")) {
            b = 2; text = text.Substring(2);
        } else if(text.StartsWith("0O")) {
            b = 8; text = text.Substring(2); // octal, non-standard
        } else if(text.StartsWith("0X")) {
            b = 16; text = text.Substring(2);
        }

        // === parse resulting value ===
        for(int ix = 0; ix < text.Length; ++ix) {
            _val *= b;
            int charVal;
            if(!parseChar.TryGetValue(text[ix], out charVal)) throw new Exception("invalid character in number: >>>"+text+"<<<"); ;
            if(charVal >= b)
                throw new Exception("number digit out of range in >>>"+text+"<<<");
            _val += (UInt32)charVal;
        }

        // === apply two's complement negation ===
        if(negate) {
            if(_val > (UInt64)UInt32.MaxValue+1) throw new Exception("constant '"+textOrig+"' exceeds 32-bit range");
            val = (UInt32)(~_val + 1);
        } else {
            if(_val > UInt32.MaxValue) throw new Exception("constant '"+textOrig+"' exceeds 32-bit range");
            val = (UInt32)_val;
        }

        return true;
    }

    public static string hex4(UInt16 val) {
        return String.Format("0x{0:X04}", val);
    }

    public static string hex8(UInt32 val) {
        return String.Format("0x{0:X08}", val);
    }
    public static string hex8Verilog(UInt32 val) {
        return String.Format("32'h{0:X8}", val);
    }

    public static bool parsePreprocToken(string input, out string token, out string arg, out char delimiter) {
        token = null;
        arg = null;
        delimiter = (char)0;
        string delimiter2 = null;
        if (!input.StartsWith("#")) return false;

        int ixOpenDelimiter = input.IndexOf("("); // brackets?
        if(ixOpenDelimiter >= 0) {
            delimiter2 = ")";
        }  else {
            ixOpenDelimiter = input.IndexOf("\""); // double-quotes?
            if(ixOpenDelimiter >= 0)
                delimiter2 = "\"";
        }
        if(ixOpenDelimiter < 0) return false;

        token=input.Substring(0, ixOpenDelimiter);
        int ixClosingDelimiter = input.IndexOf(delimiter2, ixOpenDelimiter+1);
        if(ixClosingDelimiter <= ixOpenDelimiter) throw new Exception("preprocessor token '"+token+"' is missing closing delimiter '"+delimiter2+"'");
        arg = input.Substring(ixOpenDelimiter+1, ixClosingDelimiter-ixOpenDelimiter-1);
        delimiter = input[ixOpenDelimiter];
        return true;
    }
}