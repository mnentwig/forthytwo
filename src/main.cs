using System;
using System.Collections.Generic;

static class main {
    /// <summary>application entry point</summary>
    static int Main(string[] args) {
        string destHexFilename = null;
        string destVerilogFilename = null;
        string destLstFilename = null;
        string destBootBinFilename = null;
        try {
            //args = new string[] { "../../../main.txt" }; Console.WriteLine("DEBUG: hardcoded args");
            Dictionary<string,UInt32> defines = new Dictionary<string,uint>() { { "#MEMSIZE_BYTES(",8192*4 } };

            if(args.Length < 1) throw new Exception("no input files");

            // === preprocess all input files into token list ===
            List<token> tokens = new List<token>();
            foreach(string fname_ in args) {
                string fname = fname_;

                string dir = System.IO.Path.GetDirectoryName(fname);
                string fnameNoDir = System.IO.Path.GetFileName(fname);
                string dirOut = System.IO.Path.Combine(dir, "out");

                fname = System.IO.Path.Combine(dir, fnameNoDir);
                string fnameOut = System.IO.Path.Combine(dirOut, fnameNoDir);

                // === first source file determines the name of the output files ===
                if(destHexFilename == null) {
                    destHexFilename = System.IO.Path.ChangeExtension(fnameOut, "hex");
                    if(destHexFilename == fname) throw new Exception(".hex is not permitted as input file extension");
                    destVerilogFilename = System.IO.Path.ChangeExtension(fnameOut, "v");
                    if(destVerilogFilename == fname) throw new Exception(".v is not permitted as input file extension");
                    destLstFilename = System.IO.Path.ChangeExtension(fnameOut, "lst");
                    if(destLstFilename == fname) throw new Exception(".lst is not permitted as input file extension");
                    destBootBinFilename = System.IO.Path.ChangeExtension(fnameOut, "bootBin");
                    if(destBootBinFilename == fname) throw new Exception(".bootBin is not permitted as input file extension");

                    // === create output directory ===
                    System.IO.Directory.CreateDirectory(dirOut);

                    // === prevent stale output by deleting first ===
                    System.IO.File.Delete(destHexFilename);
                    System.IO.File.Delete(destVerilogFilename);
                    System.IO.File.Delete(destLstFilename);
                    System.IO.File.Delete(destBootBinFilename);
                }

                List<string> filerefs = new List<string>();
                string content = System.IO.File.ReadAllText(fname);
                filerefs.Add(fname);

                HashSet<string> includeOnce = new HashSet<string>();
                preprocessor.parse(content, filerefs, dir, tokens, defines, includeOnce);
            }

            // === compile ===
            compiler comp = new compiler(tokens,baseAddrCode_bytes :0,baseAddrData_bytes :4000,memSize_bytes :defines["#MEMSIZE_BYTES("]);

            // === write output files ===
            comp.dumpHex(destHexFilename);
            comp.dumpVerilog(destVerilogFilename);
            comp.dumpLst(destLstFilename);
            comp.dumpBootBin(destBootBinFilename);
            Environment.Exit(0);
            return 0; // EXIT_SUCCESS 
        } catch(Exception e) {            
            Console.Error.WriteLine("Error: "+e.Message);
            Environment.Exit(-1);
            return -1; // EXIT_FAILURE 
        }
    }
}

