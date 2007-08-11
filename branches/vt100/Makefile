CC = arm-apple-darwin-cc
LD = $(CC)
LDFLAGS = -ObjC -framework CoreFoundation -framework Foundation \
          -framework UIKit -framework LayerKit -framework CoreGraphics
CFLAGS = -Wall
#-Werror

all:	Terminal

Terminal: main.o \
		MobileTerminal.o \
		ShellView.o \
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
		NSAttributedString.o \
		NSMutableAttributedString.o \
		NSAttributedString_manyAttributes.o \
		NSAttributedString_nilAttributes.o \
		NSAttributedString_oneAttribute.o \
		NSAttributedString_placeholder.o \
		NSMutableAttributedString_concrete.o \
		NSMutableString_proxyToMutableAttributedString.o \
		NSRangeEntries.o \
		NSTextStorage_concrete.o \
		NSTextStorage.o \
		SectionRecord.o \
		TerminalSection.o \
		NSAttributedString-HTML.o \
		TextStorageTerminal.o \
		NSTextStorageTerminal.o
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
	cp vanish.png Terminal.app/vanish.png
	cp bar.png Terminal.app/bar.png

clean:	
	rm -fr *.o Terminal Terminal.app
