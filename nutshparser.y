%{
    #include <stdio.h>
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


%%

shell:
    shell WORD { //printf(">> "); 
                 printf("<<INPUT>> %s\n", yytext);
                 printf(">> ");  }
    |
    ;

quit:
    WORD { exit(0); }
%%

void yyerror(char *s)
{
    fprintf(stderr, "%s\n", s);
}       

