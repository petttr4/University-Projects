%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "types.h"
%}

%option yylineno

ws      [ \t]+
newline \n|\x0A|\x0D\x0A
D       [0-9]
LETTER  [a-zA-Z]
ID      {LETTER}({LETTER}|{D}|_)*
INTEGER {D}+
FLOAT   {D}+\.{D}+

%%

{ws}      { /* do nothing */ }
{newline} { /* do nothing */ }

"var"        { return T_VAR; }
"par"        { return T_PAR; }
"set_of"     { return T_SET_OF; }
"bool"       { yylval.se.type = type_bool;    return T_BASE_TYPE; }
"int"        { yylval.se.type = type_integer; return T_BASE_TYPE; }
"float"      { yylval.se.type = type_float;   return T_BASE_TYPE; }
"constraint" { return T_CONSTRAINT; }
"solve"      { return T_SOLVE; }
"satisfy"    { return T_SATISFY; }
"maximize"   { return T_MAXIMIZE; }
"true"       { return T_TRUE; }
"false"      { return T_FALSE; }
"and"        { return T_AND; }
"or"         { return T_OR; }
"intersect"  { return T_INTERSECT; }
"union"      { return T_UNION; }
"diff"       { return T_DIFF; }
"subset"     { return T_SUBSET; }
"in"         { return T_IN; }

"==>"  { return T_IMPLIES; }
">="   { return T_GE; }
"=<"   { return T_LE; }
".."   { return T_DOTDOT; }
">"    { return '>'; }
"<"    { return '<'; }
"="    { return '='; }
"+"    { return '+'; }
"-"    { return '-'; }
"*"    { return '*'; }
"/"    { return '/'; }
":"    { return ':'; }
";"    { return ';'; }


{FLOAT}   { yylval.se.info = strdup(yytext); yylval.se.numtype = 1; return T_NUM; }
{INTEGER} { yylval.se.info = strdup(yytext); yylval.se.numtype = 0; return T_NUM; }
{ID}      { yylval.id = strdup(yytext); return T_ID; }


. { /* Do nothing */ }

%%
