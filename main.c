#include <stdio.h>
#include "nutshscanner.h"

int yylex();
extern char* yytext;

int main()
{	


	printf("Welcome to the Nutshell\n");
	while(1)
	{
		int token = yylex();
		if(token == 0) break;

		if(token == WORD){
			printf("WORD");
		}
	}

	return 0;
};