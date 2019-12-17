using System;
using System.Text;
using System.Collections.Generic;
class lstFileWriter_cl {
    /// <summary>value in code memory</summary>
    public Dictionary<UInt32, UInt16> codeMemContent = new Dictionary<UInt32, UInt16>();
    /// <summary>Mnemonic that generated code word</summary>
    public Dictionary<UInt32, string> codeMemMnemonic = new Dictionary<UInt32, string>();
    /// <summary>Annotations</summary>
    public Dictionary<UInt32, string> codeMemAnnotation = new Dictionary<UInt32, string>();
    /// <summary>code labels by memory location</summary>
    public Dictionary<UInt32, string> codeMemLabels = new Dictionary<UInt32, string>();
    /// <summary>value in data memory</summary>
    public Dictionary<UInt32, UInt32> dataMemContent = new Dictionary<UInt32, UInt32>();
    /// <summary>annotations for data memory location (label name)</summary>
    public Dictionary<UInt32, string> datMemAnnotation = new Dictionary<UInt32, string>();

	/// <summary>appends code annotation for a given address</summary>
    void codeAnnot(UInt16 addr, string annot) {
        if((annot == null) || (annot == ""))
            return;
        if(!this.codeMemAnnotation.ContainsKey(addr))
            this.codeMemAnnotation[addr] = annot;
        else
            this.codeMemAnnotation[addr] += ";" + annot;
    }

    public void annotateCode(UInt32 addr, UInt16 val, string mnem, string annot) {
        this.codeMemContent[addr] = val;
        this.codeMemMnemonic[addr] = mnem;
        if(annot != null)
            this.codeMemAnnotation[addr] = annot;
    }

    public void annotateCodeLabel(UInt32 addr, string annotation) {
        if(!this.codeMemLabels.ContainsKey(addr))
            this.codeMemLabels[addr] = annotation;
        else
            this.codeMemLabels[addr] += " " + annotation;
    }

    public void annotateData(UInt32 addr, UInt32 val, string annotation) {
        this.datMemAnnotation[addr] = annotation;
        this.dataMemContent[addr] = val;
    }

    public void dumpLst(string filename) {
        StringBuilder sb = new StringBuilder();

        List<UInt32> addrList = new List<UInt32>(this.codeMemContent.Keys);
        addrList.Sort();

        sb.AppendLine("=== code memory ===");
        sb.AppendLine("address is in 16-bit units, as it appears in J1 PC register");
        foreach(UInt32 addr in addrList) {
            sb.Append(util.hex4((UInt16)addr));
            sb.Append(" ");
            sb.Append(util.hex4(this.codeMemContent[addr]));
            sb.Append(" ");
            sb.Append(this.codeMemMnemonic[addr]);
            sb.Append("\t");
            if(this.codeMemLabels.ContainsKey(addr))
                sb.Append("LABEL:" + this.codeMemLabels[addr]);
            else
                sb.Append("\t");
            sb.Append("\t");

            if(this.codeMemAnnotation.ContainsKey(addr))
                sb.Append(this.codeMemAnnotation[addr]);
            sb.AppendLine();
        }

        sb.AppendLine();
        sb.AppendLine("=== data memory ===");
        sb.AppendLine("address is in 8-bit units, as it appears in J1 mem_addr register");

        addrList = new List<UInt32>(this.datMemAnnotation.Keys);
        addrList.Sort();
        foreach(UInt32 addr in addrList) {
            sb.Append(util.hex4((UInt16)addr));
            sb.Append(" ");
            sb.Append(util.hex8(this.dataMemContent[addr]));
            sb.Append(" ");
            if(this.datMemAnnotation.ContainsKey(addr))
                sb.Append(this.datMemAnnotation[addr]);
            sb.AppendLine();
        }
        System.IO.File.WriteAllText(filename, sb.ToString());
    }
}
