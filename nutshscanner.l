%{
    #include "nutshscanner.h"
%}

DIGIT [0-9]
QUOTE ["]
NOTQUOTE[^"]
META [/</>/|/&]
%%

[ \t]+ return WHITE_SPACE;
[..] return DOT_DOT;
[/.] return DOT;
[~] return TILDE;
{META} return METACHARACTER;

[A-Za-z{DIGIT}]+ return WORD;

. return UNDEFINED;

