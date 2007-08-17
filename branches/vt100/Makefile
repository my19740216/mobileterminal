CC = arm-apple-darwin-cc
LD = $(CC)
LDFLAGS = -ObjC -framework CoreFoundation -framework Foundation \
          -framework UIKit -framework LayerKit -framework CoreGraphics \
		  -framework GraphicsServices
CFLAGS = -Wall -Werror

all:	dist

Terminal: main.o \
		MobileTerminal.o \
		KeyboardTarget.o \
		ShellView.o \
		GestureView.o \
		ShellKeyboard.o \
		SubProcess.o \
		ANSICharLineFilter.o \
		ANSIDefaultLineFilter.o \
		CharacterLineFilter.o \
		ControlCharLineFilter.o \
		DefaultLineFilter.o \
		EscapeLineFilter.o \
		XTermAltCharLineFilter.o \
		XTermDefaultLineFilter.o \
		XTermEscapeLineFilter.o \
		GSAttributedString.o \
		GSMutableAttributedString.o \
		GSAttributedString_manyAttributes.o \
		GSAttributedString_nilAttributes.o \
		GSAttributedString_oneAttribute.o \
		GSAttributedString_placeholder.o \
		GSMutableAttributedString_concrete.o \
		NSMutableString_proxyToMutableAttributedString.o \
		GSRangeEntries.o \
		GSTextStorage_concrete.o \
		GSTextStorage.o \
		SectionRecord.o \
		TerminalSection.o \
		GSAttributedString-HTML.o \
		TextStorageTerminal.o \
		GSTextStorageTerminal.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o:	%.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

package: Terminal
	rm -fr Terminal.app
	mkdir -p Terminal.app
	cp Terminal Terminal.app/Terminal
	cp Info.plist Terminal.app/Info.plist
	cp icon.png Terminal.app/icon.png
	cp Default.png Terminal.app/Default.png
	cp bar.png Terminal.app/bar.png

dist: package
	zip -r Terminal.zip Terminal.app/

clean:	
	rm -fr *.o Terminal Terminal.app
