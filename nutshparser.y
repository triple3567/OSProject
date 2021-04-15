%{
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
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
    | STRING cmds                   {argTable.arg[cmd_num] = $1; cmd_num++;}
    | METACHARACTER cmds            {argTable.arg[cmd_num] = $1; cmd_num++;}
    ;
%%

int yyerror(char *s)  {
  printf("%s\n",s);
  return 0;
  }

int get_path(char* cmd, char* path_out)
{
    char* path[256]; 
    strcpy(path, "/usr/bin/");
    strcat(path, cmd);

    char* path2[256];
    strcpy(path2, "/bin/");
    strcat(path2, cmd);

    if(access(path, F_OK) == 0){
        path_out = path;
    }
    else if(access(path2, F_OK) == 0)
        path_out = path2;
    else
        path_out = cmd;
    return 1;
}

int build_table(int arg_num)
{
    char** reverse = malloc(sizeof(char)*(arg_num+1));
    int exe_index = arg_num-1;
    for(int i = 0; i < arg_num; i++)
    {
        reverse[exe_index--] = argTable.arg[i];
        argTable.arg[i] = NULL;
    }
    reverse[arg_num] = NULL;

    //for(int i = 0; i < arg_num; i++)
        //printf("\ni: %d r: %s", i, reverse[i]);

    int partition_arg = 0;
    char** partition_cmd[256];
    char* out_file = NULL;
    char* in_file = NULL;
    int fd_in;
    int fd_out;
    
    for(int i = 0; i < arg_num; i++)
    {
        //printf("\nENTER %d\n", i);
        if(strcmp(reverse[i], ">") == 0)
        {
            int pid;
            pid = fork();

            if(pid == 0){
            out_file = reverse[++i];

            if(fd_out = open(out_file, O_WRONLY | O_CREAT, 0644) < 0){
                perror("Unable to open file");
                exit(1);
            }
            dup2(fd_out, STDOUT_FILENO);
            dup2(fd_out, STDERR_FILENO);
            close(fd_out);
            }
            continue;
        }
        partition_cmd[partition_arg++] = reverse[i];
    }
    //partition_cmd[partition_arg] = NULL;

    exec_cmd(partition_cmd, partition_arg);
    return 1;
}

int parse_cmd(int arg_num)
{
    char** partition_cmd[256];
    int partition_arg = 0;

    char** reverse[arg_num];
    int exe_index = arg_num-1;
    for(int i = 0; i < arg_num; i++)
    {
        reverse[exe_index--] = argTable.arg[i];
    }

    char* in_file = NULL;
    char* out_file = NULL;
    bool entered = true;
    
    for(int i = 0; i < arg_num; i++)
    {
        if(strcmp(reverse[i], ">") == 0)
        {
            out_file = reverse[++i];
            entered = false;

            //for(int j = 0; j < partition_arg; j++)
                    //printf("\n >>>>> pi: %d arg: %s\n", j, partition_cmd[j]);  

            int pid = fork();

            if(pid == 0)
            {
                if(out_file != NULL)
                {
                    int fd;
                    if((fd = open(out_file, O_WRONLY | O_CREAT | O_TRUNC, 0644)) < 0)
                    {
                        perror("Unable to open file");
                        exit(1);
                    }
                    dup2(fd, STDOUT_FILENO);
                    //dup2(fd, STDERR_FILENO);
                    close(fd);
                }
  
                exec_cmd(partition_cmd, partition_arg);
                exit(1);
            }
        }
        else if(strcmp(reverse[i], "<") == 0)
        {
            in_file = reverse[++i];
            entered = false;
            int pid = fork();

            //for(int j = 0; j < partition_arg; j++)
                    //printf("\n <<<<< pi: %d arg: %s\n", j, partition_cmd[j]);  

            if(pid == 0)
            {
                if(out_file != NULL)
                {
                    int fd;
                    if(fd = open(in_file, O_RDONLY) < 0)
                    {
                        perror("Unable to open file");
                        exit(1);
                    }
                    dup2(fd, STDIN_FILENO);
                    //dup2(fd, STDERR_FILENO);
                    close(fd);
                }
                exec_cmd(partition_cmd, partition_arg);
                exit(1);
            }
            
            //for(int j = 0; j < partition_arg; j++)
                //partition_cmd[i] = NULL; 
            //partition_arg = 0;
        }

        partition_cmd[partition_arg++] = reverse[i];   
        //printf("\narg num: %d\n", partition_arg);
        //for(int j = 0; j < partition_arg; j++)
            //printf("\ni: %d arg: %s\n", j, partition_cmd[j]);    
        if(i == arg_num-1 && entered)
        {
            //printf("\nENTERED\n");
            exec_cmd(partition_cmd, partition_arg);
        }
    }
}


int exec_cmd(char** cmd, int arg_num)
{
    /* different commands in different paths */
    char* path[256]; 
    strcpy(path, "/usr/bin/");
    strcat(path, cmd[0]);
    //strcat(path, argTable.arg[arg_num-1]);

    char* path2[256];
    strcpy(path2, "/bin/");
    strcat(path2, cmd[0]);
    //strcat(path2, argTable.arg[arg_num-1]);

    /* creating and filling in array of arguments */
    //char** exe = malloc(sizeof(char)*(arg_num+2));
    /*
    for(int i = 0; i < arg_num; i++)
    {
        exe[i] = cmd[i];
    }*/

    /* select the correct path by determining if file exists in that directory */
    if(access(path, F_OK) == 0){
        cmd[0] = path;
    }
    else if(access(path2, F_OK) == 0)
        cmd[0] = path2;
    
    cmd[arg_num] = NULL;
    
    
    //for(int i = 0; i < arg_num+1; i++)
       //printf("\nexe[%d]: %s\n", i, cmd[i]);

    /* fork to call execv to execute shell command
        waits to finish to display result before asking for next input */
    pid_t pid;
    int status;
    
    if((pid = fork()) < 0){
        printf("Fork failed\n");
        exit(1);
    }
    else if(pid == 0){
        if(status = execv(cmd[0], cmd) < 0){
            perror("Error exec failed\n");
            exit(1);
        }
    }
    else{
        waitpid(pid, &status, 0);
    }
    
    //free(cmd);
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


