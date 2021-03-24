#include <stdio.h>
#include "nutshscanner.h"

int yylex();
extern char* yytext;



int main(int argc, char *argv[])
{	

	printf("Welcome to the Nutshell\n");
	while(1)
	{
		int token = yylex();
		if(token == 0) break;

		if(token == WORD){
			printf("WORD");
		}
		else if(token == WHITE_SPACE){
			printf("white space");
		}
	}

	return 0;
};