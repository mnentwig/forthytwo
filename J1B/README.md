Folder contents: 

* The J1B CPU by James Bowman (separate license, please see j1b.v)
* A stack implementation for distributed or block ram (the original stack is shift register based)
* A Verilator-based simulator with a minimal implementation (referred to as "Zero" platform)

For convenience, the resulting binaries ../bin/simZero.exe and ../bin/simZeroVcd.exe are provided pre-compiled. 

Rebuild is necessary for changes to the platform (not the executed code) or non-windows use but requires Verilator install.

# Verilator installation notes
Verilator is needed to rebuild the simulator executable (e.g. if modifying the CPU or adding peripherals). 

These notes are for a Windows installation and are only relevant if Verilator standard install does not run through smoothly.

- Download MinGW installer
- select mingw-developer-toolkit-bin, mingw32-base-bin, mingw32-gcc-g++.bin, msys-base.bin. "Apply scheduled changes"
- (optional) edit c:/MinGW/msys/1.0/etc/profile, remove the last "cd $HOME"
- (optional) add "open msys here" shortcut: https://codeplea.com/open-msys-here
- edit include/verilatedos.h: comment out # define __USE_MINGW_ANSI_STDIO 1  // Force old MinGW (GCC 5 and older) to use C99 formats
- git checkout stable (maybe setup git user name and email at this time)
- autoconf
- ./configure --prefix /usr
- edit c:/mingw/include/stdio.h and temporarily comment out the implementation of vsnprintf (avoids duplicate symbol linker error) 
- make -j then make (it might require several attempts)
- make install
- (optional, suppresses warnings) edit c:/mingw/include/mingw.h, disable # warning "Direct definition of __USE_MINGW_ANSI_STDIO is deprecated."
- (optional, suppresses warnings) edit c:/MinGW/msys/1.0/share/verilator/include/vltstd/ and remove dllimport attribute
- (optional, suppresses warnings) edit respective verilatorxy.h files to first #undef MINGW_XYZ that would later cause a redefinition warning
- with those modifications, the simulator build should not show any warnings.

