FORTHYTWO=../bin/forthytwo.exe

bootloader.v: 
	${FORTHYTWO} bootloader.txt
	mv out/bootloader.v .

clean:
	rm -Rf out

forceclean: clean
	rm -f bootloader.v

.PHONY: clean forceclean
