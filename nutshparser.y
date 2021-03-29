%{
    #include <stdio.h>
    void yyerror(char*);
    int yylex();
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
    shell WORD { printf(">> "); }
    |
    ;

%%

void yyerror(char *s)
{
    fprintf(stderr, "%s\n", s);
}       

