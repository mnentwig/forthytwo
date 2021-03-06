﻿using System;
using System.Collections.Generic;

/// <summary>one token in the preprocessor output</summary>
public class token {
    /// <summary>payload data</summary>
    public string body;
    /// <summary>include files that led to this token being generated</summary>
    public List<string> fileref;
    /// <summary>line number in the file containing the token </summary>
    public int lineBase0;
    public string annotation;

    public Exception buildException(Exception e) {
        return new Exception("'" + e.Message + "' at " + this.getAnnotation());
    }

    public Exception buildException(string msg) {
        return this.buildException(new Exception(msg));
    }

    public token() { }

    public token(string newBody, token tRef, string annotation = null) {
        this.body = newBody;
        this.lineBase0 = tRef.lineBase0;
        this.fileref = tRef.fileref;
        this.annotation = annotation;
    }

    public token(token tSrc, string annotation = null) {
        this.body = tSrc.body;
        this.lineBase0 = tSrc.lineBase0;
        this.fileref = tSrc.fileref;
        if(this.annotation == null)
            this.annotation = annotation;
        else if(annotation != null)
            this.annotation = this.annotation + ";" + annotation;
        annotation = null;
    }

    public string getAnnotation() {
        List<string> rev = new List<string>(this.fileref); rev.Reverse();
        string annot = this.annotation != null ? this.annotation + ";" : "";
        annot = annot + "line " + (this.lineBase0 + 1) + " in " + String.Join(" included by ", rev.ToArray());
        return annot;
    }
}

/// <summary>ASCII-level manipulation, include handling, tokenization of input files</summary>
public static class preprocessor {
    static char[] whitespace = new char[] { '\r', '\n', '\t', ' ' };
    public static void parse(string fileContent, List<string> filerefs, string currentDirectory, List<token>tokens, Dictionary<string, UInt32> defines, HashSet<string> includeOnce) {

        // === newline processing ===
        fileContent = " " + fileContent + System.Environment.NewLine; // sentinels
        fileContent = fileContent.Replace(System.Environment.NewLine, " #newline ");
        fileContent = fileContent.Replace("\n", " #newline ");
        fileContent = fileContent.Replace("\t", " ");

        // ===================================================
        // carve out collect atomic sections (strings, comments) 
        // ===================================================
        int cursor = 0;
        string[] groups = new string[] { // opener-closer pairs
            " \"", "\" ",
            " /*", "*/",
            "//", "#newline",
            " #include(", ") "};
        Stack<int> blkStart = new Stack<int>();
        Stack<int> blkEnd = new Stack<int>();
        while(true) {
            int ixStart = int.MaxValue;
            int grpFound = -1;
            for(int ixGrp = 0; ixGrp < groups.Length; ixGrp += 2) {
                string gOpen = groups[ixGrp];
                int ix = fileContent.IndexOf(gOpen, cursor);
                if((ix >= 0) && (ix < ixStart)) {
                    ixStart = ix;
                    grpFound = ixGrp;
                }
            }

            if(grpFound < 0)
                break;
            string gClose = groups[grpFound + 1];
            int ixClose = fileContent.IndexOf(gClose, ixStart+groups[grpFound].Length);
            if(ixClose < 0)
                failAtChar(filerefs[filerefs.Count-1], fileContent, ixStart, "unterminated delimiter: >>>" + groups[grpFound] + "<<<. Expecting >>>" + gClose+"<<<");

            if(groups[grpFound+1] == "#newline") {
                // do not include final token
                cursor = ixClose;
            } else {
                // include final token
                cursor = ixClose + gClose.Length;
            }
            blkStart.Push(ixStart);
            blkEnd.Push(cursor);
        }

        // ===================================================
        // === replace atomic sections in backwards order with generated token
        // ===================================================
        Dictionary<string, string> atomicSections = new Dictionary<string, string>();
        int tokenCount = 0;
        while(blkStart.Count > 0) {
            string token = "#parsertoken"+(tokenCount++);
            int a = blkStart.Pop();
            int b = blkEnd.Pop();
            atomicSections[token] = fileContent.Substring(a, b-a).Trim(); // must trim as delimiters may include whitespace
            fileContent = fileContent.Substring(0, a) + " " + token + " " + fileContent.Substring(b);
        }

        List<string> tokens1 = new List<string>(fileContent.Split(whitespace, StringSplitOptions.RemoveEmptyEntries));

        // ===================================================
        // === restore atomic sections
        // ===================================================
        List<string> tokens2 = new List<string>();
        int nRepl = 0;
        foreach(string t in tokens1) {
            if(atomicSections.ContainsKey(t)) {
                tokens2.Add(atomicSections[t]);
                ++nRepl;
            } else
                tokens2.Add(t);
        }
        if(nRepl != atomicSections.Count) throw new Exception("internal parser error");
        tokens1 = tokens2; tokens2 = null;

        // ===================================================
        // === fill in line number ===
        // ===================================================
        List<token> tokens3 = new List<token>();
        int lineNumBase0 = 0;
        foreach(string t in tokens1)
            if(t == "#newline")
                ++lineNumBase0;
            else if(t.StartsWith("//")) {
                // === suppress single-line comments
            } else if(t.StartsWith("/*")) {
                // === suppress multi-line comments 
                int cc = 0;
                while(true) {
                    int ixnl = t.IndexOf("#newline", cc);
                    if(ixnl < 0)
                        break;
                    ++lineNumBase0;
                    cc = ixnl + 1;
                }
            } else
                tokens3.Add(new token { body = t, fileref = filerefs, lineBase0 = lineNumBase0 });
        tokens2 = null;

        // ===================================================
        // === process "include..." directive ===
        // ===================================================
        if(tokens == null)
            tokens = new List<token>();
        List<string> defKeys = new List<string>(defines.Keys);
        foreach(token t in tokens3) {
            try {
                // === #abc defining commands ===
                foreach(string def in defKeys) {
                    if(t.body.StartsWith(def)) {
                        if(!t.body.EndsWith(")"))
                            throw new Exception(filerefs[filerefs.Count-1] + "line " + t.lineBase0 +":"+def+" without closing bracket");
                        string arg = t.body.Substring(def.Length, t.body.Length - def.Length - 1);
                        UInt32 valNum;
                        if(!util.tryParseNum(arg, out valNum, enableFloat: false))
                            throw new Exception(filerefs[filerefs.Count-1] + "line " + t.lineBase0 +":"+def+" cannot parse argument");
                        defines[def] = valNum;
                        goto tokenDone;
                    }
                }

                string preprocTokenKey;
                string preprocTokenArg;
                char preprocTokenDelimiter;
                if(util.parsePreprocToken(t.body, out preprocTokenKey, out preprocTokenArg, out preprocTokenDelimiter)) {
                    switch(preprocTokenKey) {
                        case "#include":
                            if(preprocTokenDelimiter != '(') throw new Exception(preprocTokenKey+" expects round bracket delimiters");
                            string dirAndFilename = preprocTokenArg;
                            string filename = System.IO.Path.GetFileName(dirAndFilename);

                            // === determine search path for included file ===
                            string newSearchPath;
                            if(System.IO.Path.IsPathRooted(dirAndFilename)) {
                                // === absolute path ===
                                newSearchPath = System.IO.Path.GetDirectoryName(dirAndFilename);
                            } else {
                                // === relative path ===
                                // add to current directory
                                newSearchPath = System.IO.Path.Combine(currentDirectory, System.IO.Path.GetDirectoryName(dirAndFilename));
                            }

                            // === read file contents ===
                            string includeFile = System.IO.Path.GetFullPath(System.IO.Path.Combine(newSearchPath, filename));
                            if(!includeOnce.Contains(includeFile.ToUpper())) {
                                //Console.WriteLine("include "+System.IO.Path.GetFullPath(includeFile));
                                List<string> filerefInc = new List<string>(filerefs);
                                filerefInc.Add(includeFile);
                                string incContent;
                                try {
                                    incContent = System.IO.File.ReadAllText(System.IO.Path.Combine(newSearchPath, filename));
                                } catch(Exception e) {
                                    throw t.buildException(e);
                                }
                                parse(incContent, filerefInc, newSearchPath, tokens, defines, includeOnce);
                            }

                            goto tokenDone;
                        default:
                            break;
                    }
                } // if preproc token with args

                if(t.body == "#include_once") {
                    string thisFile = filerefs[filerefs.Count-1];
                    includeOnce.Add(System.IO.Path.GetFullPath(thisFile).ToUpper());
                    goto tokenDone;
                }
                               
                // === drop newlines ===
                if(t.body == "#newline")
                    goto tokenDone;
                tokens.Add(t);
            } catch(Exception e) {
                throw t.buildException(e);
            }

        tokenDone: { }
        }

        // add end-of-file token
        tokens.Add(new token() { fileref = filerefs, body = "#EOF", lineBase0 = lineNumBase0 });
        tokens3 = null;
    }

    static void failAtChar(string filename, string fileContents, int charIndex, string message) {
        fileContents = fileContents.Substring(0, charIndex);
        int lineNum = 0;
        int cursor = 0;
        while(true) {
            cursor = fileContents.IndexOf("#newline", cursor);
            if(cursor < 0) break;
            ++lineNum;
            ++cursor;
            if(cursor == fileContents.Length) break;
        }
        throw new Exception("parser error "+filename+" ("+(lineNum+1)+"): "+message);
    }
}