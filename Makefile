CC=nasm
LD=ld

CFLAGS=-f macho64
LDFLAGS=-no_pie -macosx_version_min 13.0 -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lSystem -lSDL2 -lSDL2_image 

SOURCES=$(wildcard src/**/*.asm src/*.asm)
OBJECTS=$(patsubst %.asm,%.o,$(SOURCES))

all: main

main: $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

%.o : %.asm
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(OBJECTS) main
