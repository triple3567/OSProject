#include <stdio.h>
//#include "nutshscanner.h"
#include "nutshparser.tab.h"

int main()
{
	printf("Welcome to the Nutshell\n");
	while(1)
	{
		printf(">> ");

        yyparse();
	}
}
