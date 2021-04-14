%{
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include "global.h"

int yylex();
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int exec_cmd(char** cmd, int arg_num);

%}

%union {char *string;}

%code {extern int cmd_num = 0;}
%code {extern char** args;}
%start cmd_line
%token <string> BYE CD STRING ALIAS SETENV END PRINTENV UNSETENV UNALIAS METACHARACTER


%%
cmd_line    :
	BYE END 		                {exit(1); return 1; }
    | CD END                        {runCD(varTable.word[1]); return 1;}
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
    | ALIAS END                     {printAlias(); return 1;}
    | SETENV STRING STRING END      {setEnv($2, $3); return 1;}
    | PRINTENV END                  {printEnv(); return 1;}
    | UNSETENV STRING END           {unsetEnv($2); return 1;}    
    | UNALIAS STRING END            {unalias($2); return 1;} 
    | cmds END                      {parse_cmd(cmd_num); cmd_num = 0; YYACCEPT;}                      
    ;
cmds:
    STRING                          {argTable.arg[cmd_num] = $1; cmd_num++;}
    | METACHARACTER                          {argTable.arg[cmd_num] = $1; cmd_num++;}
    | STRING cmds                   {argTable.arg[cmd_num] = $1; cmd_num++;}
    | METACHARACTER cmds            {printf("\nMETA %s\n", $1); argTable.arg[cmd_num] = $1; cmd_num++;}
    ;
%%

int yyerror(char *s)  {
  printf("%s\n",s);
  return 0;
  }

int parse_cmd(int arg_num)
{
    char** partition_cmd[256];
    int partition_arg = 0;
    printf("\nENTER PARSE\n");
    for(int i = 0; i < arg_num; i++)
    {
        printf("\nTable: %s\n", argTable.arg[i]);
        if(strcmp(argTable.arg[i], ">") == 0)
        {
            printf("\n>>>>\n");
        }
        partition_cmd[partition_arg++] = argTable.arg[i];        
        if(i == arg_num-1)
        {
            exec_cmd(partition_cmd, partition_arg);
        }
    }
}


int exec_cmd(char** cmd, int arg_num)
{
    /* different commands in different paths */
    char* path[256]; 
    strcpy(path, "/usr/bin/");
    strcat(path, argTable.arg[arg_num-1]);
    
    char* path2[256];
    strcpy(path2, "/bin/");
    strcat(path2, argTable.arg[arg_num-1]);

    /* creating and filling in array of arguments */
    char** exe = malloc(arg_num+2);

    int exe_index = arg_num-1;
    for(int i = 0; i < arg_num; i++)
    {
        exe[exe_index--] = argTable.arg[i];
    }

    /* select the correct path by determining if file exists in that directory */
    if(access(path, F_OK) == 0){
        exe[0] = path;
    }
    else if(access(path2, F_OK) == 0)
        exe[0] = path2;
    else
        return 0;

    exe[arg_num] = NULL;
    
    
    //for(int i = 0; i < arg_num+1; i++)
        //printf("\nexe[%d]: %s\n", i, exe[i]);

    /* fork to call execv to execute shell command
        waits to finish to display result before asking for next input */
    pid_t pid;
    int status;
    
    if((pid = fork()) < 0){
        printf("Fork failed\n");
        exit(1);
    }
    else if(pid == 0){
        if(status = execv(exe[0], exe) < 0){
            printf("Error exec failed\n");
            exit(1);
        }
    }
    else{
        waitpid(pid, &status, 0);
    }
    
    //free(exe);
    
    return 1;
}


int runCD(char* arg) {
	if (arg[0] != '/') { // arg is relative path
		char* temp;
		temp = malloc(1000);
		strcpy(temp, varTable.word[0]);
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
			strcpy(varTable.word[0], temp);
			printf("%s Directory not found\n", arg);
			return 1;
		}

		free(temp);
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

int setEnv(char* var, char* word){
    for (int i = 0; i < varIndex; i++){
        if (strcmp(varTable.var[i], var) == 0){
            strcpy(varTable.word[i], word);
            printf("Eviroment Variable %s Updated \n", var);
            return 1;
        }
    }

    strcpy(varTable.var[varIndex], var);
    strcpy(varTable.word[varIndex], word);
    varIndex++;
    printf("Eviroment Variable %s Added \n", var);
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

int printAlias(){
    for (int i = 0; i < aliasIndex; i++){
        printf("%s = %s\n", aliasTable.name[i], aliasTable.word[i]);
    }
    return 1;
}


