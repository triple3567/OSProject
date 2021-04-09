# Simple Makefile

CC=/usr/bin/cc

all:  bison-config flex-config nutshell

flex-test: flex-config
	gcc -o lex_test_main.o lex_test_main.c lex.yy.c -lfl

bison-config:
	bison -d nutshparser.y

flex-config:
	flex nutshscanner.l

nutshell: 
	$(CC) nutshell.c nutshparser.tab.c lex.yy.c -o nutshell.o


clean:
	rm nutshparser.tab.c nutshparser.tab.h lex.yy.c lex_test_main.o nutshell.o
