#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "nutshell.h"
//#include "nutshscanner.h"
#include "nutshparser.tab.h"

void printPrompt()
{
    char dir[256];
    getcwd(dir,256);
    printf("user@computer:%s>> ", dir);
}

int getCommand()
{
    printPrompt();
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
