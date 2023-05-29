CC=nasm
LD=ld

CFLAGS=-f macho64
LDFLAGS=-no_pie -macosx_version_min 13.0 -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lSystem -lSDL2 

SRC=src/main.asm
OBJ=main.o

all: $(OBJ)
	$(LD) $(LDFLAGS) -o main $(OBJ)

$(OBJ): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(OBJ)

clean:
	rm -f $(OBJ) main
