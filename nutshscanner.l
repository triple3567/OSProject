%{
#include "nutshparser.tab.h"
#include "global.h"
#include <string.h>
#include <dirent.h> 
#include <fnmatch.h>
#include <stdbool.h>
#include <pwd.h>

//#define unput(c) {yytchar= (c); if(yytchar=='\n') {yylineno--; *yysptr++=yytchar;}
char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}
bool ifAlias(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return true;
        }
    }
    return false;
}
char* subEnvVar(char* name){
    printf("Before Env Sub = %s\n", yytext);

    for (int i = 0; i < varIndex; i++){
        if (strcmp(varTable.var[i], name) == 0){
             printf("Enviroment Variable %s = %s\n", name, varTable.word[i]);
            return varTable.word[i];
        }
    }
    return name;
}
bool containsEnvVar(char* name){
    char* openCurly;
    char* closedCurly;
    char* moneySign;
    
    moneySign = strchr(name, '$');
    openCurly = strchr(name, '{');
    closedCurly = strchr(name, '}');

    if (openCurly == NULL || closedCurly == NULL || moneySign == NULL){
        return false;
    }

    int moneySignPos = (int)(moneySign - name);
    int openCurlyPos = (int)(openCurly - name);
    int closedCurlyPos = (int)(closedCurly - name);
    if( openCurlyPos - moneySignPos != 1 ){
        return false;
    }
    else if( closedCurlyPos - openCurlyPos <= 1){
        return false;
    }

    char* envVarName = malloc(closedCurlyPos - openCurlyPos - 1);
    envVarName[0] = '\0';
    int j = 0;
    for(int i = openCurlyPos + 1; i < closedCurlyPos; i++){
        envVarName[j] = name[i];
        j++;
    }

    for (int i = 0; i < varIndex; i++){
        if (strcmp(varTable.var[i], envVarName) == 0){
            return true;
        }
    }    
    return false;
}

char* replaceEnvVar(char* word){
    char* openCurly;
    char* closedCurly;
    char* moneySign;
    
    moneySign = strchr(word, '$');
    openCurly = strchr(word, '{');
    closedCurly = strchr(word, '}');

    int moneySignPos = (int)(moneySign - word);
    int openCurlyPos = (int)(openCurly - word);
    int closedCurlyPos = (int)(closedCurly - word);

    char* envVarName = malloc(closedCurlyPos - openCurlyPos - 1);
    envVarName[0] = '\0';
    int j = 0;
    for(int i = openCurlyPos + 1; i < closedCurlyPos; i++){
        envVarName[j] = word[i];
        j++;
    }

    char* subEnvWord;
    for (int i = 0; i < varIndex; i++){
        if (strcmp(varTable.var[i], envVarName) == 0){
            subEnvWord = strdup(varTable.word[i]);
            break;
        }
    }    
    ;
    char* newWord = malloc(strlen(word) + strlen(subEnvWord));
    newWord[0] = '\0';
    int k = 0;
    for(int i = 0; i < moneySignPos; i++){
        newWord[k] = word[i];
        k++;
    }

    for(int i = 0; i < strlen(subEnvWord); i++){
        newWord[k] = subEnvWord[i];
        k++;
    }

    for(int i = closedCurlyPos + 1; i < strlen(word); i++){
        newWord[k] = word[i];
        k++;
    }

    printf("after env var sub: %s\n", newWord);
    return newWord;
}

bool ifWildcard(char* word){
    char compare1 = '?';
    char compare2 = '*';
    for (int i = 0; i < strlen(word); i++){
        if (word[i] == compare1 || word[i] == compare2){
            return true;
        }
    }
    return false;
}
char* subWildCard(char* word){
    char files[128][100];
    int files_index = 0;
    int allocation = 0;

    DIR *d;
    struct dirent *dir;
    d = opendir(varTable.word[0]);
    if (d) {
        while ((dir = readdir(d)) != NULL) {

            if (fnmatch(word, dir->d_name, 0) == 0){
                strcpy(files[files_index], dir->d_name);
                allocation += strlen(dir->d_name) + 1;
                files_index++;
            }
            
        }
    closedir(d);
    }

    printf("FILES MATCHED = %i\n", files_index);
    char* yy_string;
    yy_string = malloc(allocation + 1000);
    yy_string[0] = '\0';
    for(int i = 0; i < files_index; i++){
        strcat(yy_string, files[i]);
        if (i != files_index - 1){
            strcat(yy_string, " ");
        }
    }
    printf("yy_string = %s\n", yy_string);

    
    return yy_string;
}


%}



%array
%option noyywrap

CHAR            [$\{\}~\:\?\*.A-Za-z0-9!\/_-][$\{\}~\:\?\*.A-Za-z0-9!\/_-]*
ANYCHAR         [\}\:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][\}\:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
META            [/</>/|/&]

%x string_condition
%x env_var_condition
%%

<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext);return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

[\~]{CHAR}*            { 
                        char* home = strdup(varTable.word[1]);
                        char* yycopy = malloc(strlen(yytext) - 1);
                        for (int i = 1; i < strlen(yytext); i++){
                            yycopy[i - 1] = yytext[i];
                        }

                        char* potentialUsername = malloc(1000);
                        potentialUsername[0] = '\0';
                        
                        int count;
                        for (count = 0; count < strlen(yycopy); count++){
                            if( yycopy[count] == '/'){
                                break;
                            }

                            potentialUsername[count] = yycopy[count];
                        }
                        
                        struct passwd* user;
                        user = getpwnam(potentialUsername);


                        if(user != NULL){                 
                            char* userHome = strdup(user->pw_dir);
                            char* val = malloc(strlen(userHome) + (strlen(yycopy) - count + 1));
                            val[0] = '\0';

                            int pos = strlen(userHome);
                            strcat(val, userHome);
                            for(; count < strlen(yycopy); count++){
                                val[pos] = yycopy[count];
                                pos++;
                            }

                            yylval.string = strdup(val);
                            printf("Found user home %s\n", yylval.string);

                            free(val);
                            free(userHome);
                        }
                        else{
                            char* new_str = malloc(strlen(yycopy) + strlen(home));
                            new_str[0] = '\0';
                            strcat(new_str,home);
                            strcat(new_str,yycopy);
                            yylval.string = strdup(new_str);    
                            free(new_str);                 
                        }
                        free(home);
                        free(yycopy);                     
                        free(potentialUsername);
                        return STRING;
                    }
[ ]		            { }
bye                 { return BYE; }
cd		            { return CD;}
alias		        { return ALIAS; }
setenv              { return SETENV; }
printenv            { return PRINTENV;}
unsetenv            { return UNSETENV;}
unalias             { useAlias = false; return UNALIAS;}
"\n"		        { return END; }
{META}              { yylval.string = strdup(yytext); return METACHARACTER;}
[\"]                { BEGIN(string_condition); }
{CHAR}+              {if(ifAlias(yytext) && useAlias) {
                        printf("yytext before sub: %s\n", yytext);
                        // source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                    } 
                    else if (ifWildcard(yytext)) {
                            char *yycopy = strdup( subWildCard(yytext));
                            for ( int i = strlen(subWildCard(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                            free( yycopy );
                        }
                    else if(containsEnvVar(yytext)){
                        char *yycopy = strdup(replaceEnvVar(yytext));
                        for (int i = strlen(yycopy) - 1; i >= 0; i--){
                            unput( yycopy[i] );
                        }
                        free( yycopy );
                    }
                    else {
                        printf("yytext: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        return STRING;
                    }
};
                     
%%