CC		:=	gcc -m32
CC_FLAGS	:=	-Wall -g
ASM		:=	nasm
ASM_FLAGS	:=	-f elf -g
LINK		:=	ld

SRC_DIR		:=	src
OBJ_DIR		:=	obj
LIST_DIR	:=	list
BIN_DIR		:=	bin

all: calc # task2

calc:	calc.o 
	gcc -g -Wall -m32 -o calc calc.o 
	

	
calc.o: calc.s
	nasm -g -f elf -w+all -o calc.o calc.s 
	
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o calc
