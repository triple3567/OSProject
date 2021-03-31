%{
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"

int yylex();
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS END PRINTENV UNSETENV UNALIAS

%%
cmd_line    :
	BYE END 		                {exit(1); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
    | PRINTENV END                  {printEnv(); return 1;}
    | UNSETENV STRING END           {unsetEnv($2); return 1;}    
    | UNALIAS STRING END            {unalias($2); return 1;}  

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int runCD(char* arg) {
	if (arg[0] != '/') { // arg is relative path
		strcat(varTable.word[0], "/");
		strcat(varTable.word[0], arg);

		if(chdir(varTable.word[0]) == 0) {
			strcpy(aliasTable.word[0], varTable.word[0]);
			strcpy(aliasTable.word[1], varTable.word[0]);
			char *pointer = strrchr(aliasTable.word[1], '/');
			while(*pointer != '\0') {
				*pointer ='\0';
				pointer++;
			}
		}
		else {
			//strcpy(varTable.word[0], varTable.word[0]); // fix
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(aliasTable.word[0], arg);
			strcpy(aliasTable.word[1], arg);
			strcpy(varTable.word[0], arg);
			char *pointer = strrchr(aliasTable.word[1], '/');
			while(*pointer != '\0') {
			*pointer ='\0';
			pointer++;
			}
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
	return 1;
}

int runSetAlias(char *name, char *word) {
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, word) == 0){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}
	strcpy(aliasTable.name[aliasIndex], name);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

	return 1;
}

int printEnv(){
    for (int i = 0; i < varIndex; i++){
        printf("%s = %s\n", varTable.var[i], varTable.word[i]);
    }
    return 1;
}

int unsetEnv(char *variable){
    int var_location = -1;
    for (int i = 0; i < varIndex; i++){
        if(strcmp(varTable.var[i], variable) == 0){
            var_location = i;
        }
    }

    if (var_location != -1){
        strcpy(varTable.var[var_location], "");
        strcpy(varTable.word[var_location], "");

        for(int i = var_location + 1; i < varIndex; i++){
            strcpy(varTable.var[i - 1], varTable.var[i]);
            strcpy(varTable.word[i - 1], varTable.word[i]);
        }
        strcpy(varTable.var[varIndex - 1], "");
        strcpy(varTable.word[varIndex - 1], "");


        varIndex--;
    }
    return 1;
}

int unalias(char *variable){
    int var_location = -1;
    for (int i = 0; i < aliasIndex; i++){
        if(strcmp(aliasTable.name[i], variable) == 0){
            var_location = i;
        }
    }

    if (var_location != -1){
        strcpy(aliasTable.name[var_location], "");
        strcpy(aliasTable.word[var_location], "");

        for(int i = var_location + 1; i < aliasIndex; i++){
            strcpy(aliasTable.name[i - 1], aliasTable.name[i]);
            strcpy(aliasTable.word[i - 1], aliasTable.word[i]);
        }
        strcpy(aliasTable.name[aliasIndex - 1], "");
        strcpy(aliasTable.word[aliasIndex - 1], "");


        aliasIndex--;
    }

    useAlias = true;
    return 1;
}