# Opcode Odyssey

A basic game developed using x86 assembly for MacOS. This project is intended as a learning exercise for understanding assembly language. 

## Getting Started

### Prerequisites

You'll need to have the following installed to run Opcode Odyssey:

1. NASM: The Netwide Assembler, a portable 80x86 and x86-64 assembler.

2. SDL2: A cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D.

### Installation

1. First, clone this repository to your local machine using `git clone`.

2. Compile the code using the provided Makefile. Open your terminal, navigate to the project directory and run:

```bash
make all
```
This will generate the object file `main.o` and the executable `main`.

## How to Play

Run the executable `main` in your terminal:

```bash
./main
```

## Game Controls

The player controls are quite simple and are based on the keyboard keys:

- `A`: Move player to the left.
- `D`: Move player to the right.
- `S`: Move player down.
- `W`: Move player up.

## Code Description

The code is structured in assembly with the following sections:

1. `.data`: This section contains the initialized data such as window variables, player image path, and debug messages.

2. `.bss`: This section includes variables which are not initialized yet. It includes window settings and player variables.

3. `.text`: This is the code section. It contains the main function, which initializes SDL, creates the window and player, enters the main game loop, and performs cleanup at the end. The game loop handles events and player input, updates the screen, and checks for the end of the game.

## Built With

- [NASM](https://www.nasm.us/) - The Netwide Assembler, NASM, is an 80x86 and x86-64 assembler designed for portability and modularity.

- [SDL2](https://www.libsdl.org/) - A cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D.

## Authors

- Lukas Bergström

## Acknowledgments

The System V AMD64 calling convention is used in this game (find more details [here](https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI))

## Clean Up

To remove the object and executable files, run:

```bash
make clean
```
This will remove `main.o` and `main` files.

## Future Work

Any suggestions for improvements are welcome.