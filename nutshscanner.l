%{    
    #include "nutshparser.tab.h"
%}

DIGIT [0-9]
QUOTE ["]
META [/</>/|/"/&]
%%

[ \t\r\n]+ {/* WHITE_SPACE*/};
"." return DOT;
".." return DOT_DOT;
[~] return TILDE;
{META} return METACHARACTER;

[A-Za-z0-9]+ return WORD;

. return UNDEFINED;

%%

int yywrap(void)
{
    return 1;
}
