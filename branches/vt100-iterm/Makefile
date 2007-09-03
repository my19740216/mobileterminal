CC=/usr/local/arm-apple-darwin/bin/gcc
CFLAGS=-fsigned-char -Wall -Werror
LDFLAGS=-Wl,-syslibroot,$(HEAVENLY) -lobjc \
        -framework CoreFoundation -framework Foundation \
        -framework UIKit -framework LayerKit -framework CoreGraphics \
        -framework GraphicsServices -lcurses

all:	Terminal

Terminal: main.o MobileTerminal.o  ShellKeyboard.o SubProcess.o \
	ShellIO.o VT100Screen.o VT100Terminal.o PTYTextView.o  \
        NSString-Additions.o
	$(CC) $(LDFLAGS) -o $@ $^

%.o:	%.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

package: Terminal
	rm -fr Terminal.app
	mkdir -p Terminal.app
	cp Terminal Terminal.app/Terminal
	cp Info.plist Terminal.app/Info.plist
	cp icon.png Terminal.app/icon.png
	cp Default.png Terminal.app/Default.png

dist: package
	zip -r Terminal.zip Terminal.app/

clean:	
	rm -fr *.o Terminal Terminal.app Terminal.zip
