#include <stdio.h>
#include "nutshscanner.h"

int yylex();
extern char* yytext;



int main(int argc, char *argv[])
{	

	printf("Welcome to the Nutshell\n");
	while(1)
	{
		printf(">> ");
		int token = yylex();
		if(token == 0) break;

		if(token == WORD){
			printf("WORD\n");
		}
		else if(token == WHITE_SPACE){
			printf("white space\n");
		}
		else if(token == DOT){
			printf("DOT\n");
		}
		else if(token == DOT_DOT){
			printf("DOT DOT\n");
		}
		else if(token == METACHARACTER){
			printf("METACHARACTER\n");
		}
		else if(token == TILDE){
			printf("TILDE\n");
		}

		printf("<<INPUT READ>>  %s\n", yytext);

	}

	return 0;
};
