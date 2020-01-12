# developed on MinGW for "make" command

# Tools:
# CSharp compiler from .NET framework
# You may need to change this, depending on what is installed on the system
# The compiler should be available from the .NET runtime (does not require developer package)
# Alternatively, use Visual studio to open forthytwo.sln and build.
CSC=/c/Windows/Microsoft.NET/Framework/v4.0.30319/csc.exe

# make targets
FORTHYTWO=../bin/forthytwo.exe

# build the forthytwo.exe compiler from source
${FORTHYTWO}:	
	${CSC} /out:temp.exe src\main.cs src\preprocessor.cs src\compiler.cs src\lstFileWriter.cs src\util.cs
	mv temp.exe ${FORTHYTWO}
clean:
	rm -Rf src/obj
	rm -Rf src/bin

# Force rebuild. Usually we don't remove ${FORTHYTWO} as the binary is checked in on git for immediate use
forceclean:
	rm -f ${FORTHYTWO}

.PHONY: clean forceclean
