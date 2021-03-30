#include <stdio.h>
#include <string.h>
#include "nutshell.h"
//#include "nutshscanner.h"
#include "nutshparser.tab.h"

int getCommand()
{
    printf(">> ");
    yyparse();

    enum cmdResponse resp;
    printf("[ Command: ] %s\n", cmd);
    if(strcmp("bye", cmd) == 0)
        resp = BYE;
    else
        resp = OK;
    return resp;
}

int main()
{
	printf("Welcome to the Nutshell\n");


    while(1){
        int CMD;
        switch(CMD = getCommand())
        {
        case BYE:       exit(0);
        case OK:        printf("OK\n");
        }

    }
}
