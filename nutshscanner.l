%{
    #include "nutshscanner.h"
%}

DIGIT [0-9]
QUOTE ["]



%%

[ \t\n]+ return WHITE_SPACE;
[/.] return DOT;
[.][.] return DOT_DOT;
[A-Za-z{DIGIT}]+ return WORD;
