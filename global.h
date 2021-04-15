#include <stdbool.h>

struct evTable {
   char var[128][100];
   char word[128][100];
};
struct aTable {
	char name[128][100];
	char word[128][100];
};
struct evTable varTable;
struct aTable aliasTable;

int aliasIndex, varIndex;
char* subAliases(char* name);
bool useAlias;

struct cmdTable {
   char* arg[128];
};
struct cmdTable argTable;