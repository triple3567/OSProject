%{
    #include <stdio.h>
    #include "nutshell.h"
    void yyerror(char*);
    int yylex();
    extern char* yytext;
%}

%token WORD
%token WHITE_SPACE
%token DOT
%token DOT_DOT
%token TILDE
%token METACHARACTER
%token UNDEFINED
%token NEW_LINE

%%

shell:
    |
    shell WORD { printf("[ INPUT ] %s\n", yytext);
                 cmd = yytext;
                 YYACCEPT;
      
                 //char s[100];
                 //printf("%s\n", getcwd(s,100));
                 //chdir("..");
                 //printf("%s\n", getcwd(s,100)); 
                 } 
    ;

quit:
    WORD { exit(0); }
%%

void yyerror(char *s)
{
    fprintf(stderr, "%s\n", s);
}       

