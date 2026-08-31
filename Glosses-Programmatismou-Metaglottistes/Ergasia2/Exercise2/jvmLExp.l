/*
Grammar with semantics and type checking.
Lexical Analyser - jvmLExp.l
*/

%{
#include <stdlib.h>
#include <string.h>
int code_line = 1;
int g_paren_depth = 0;  /* tracks '(' / ')' nesting, used for error recovery */
%}

DIGITS   [0-9]
LETTER   [a-zA-Z]
VARIABLE {LETTER}({LETTER}|{DIGITS}|_)*
FLOAT    {DIGITS}+\.{DIGITS}+
INT      {DIGITS}+
newline  \n|\x0A|\x0D\x0A

%%

"start"  {return T_start;}
"end"    { return T_end; }
"print"  { return T_print;}
"int"    { return T_int; }
"float"  { return T_float;}
"++"     { return T_inc;}
"+"      { return T_plus; }
"-"      { return T_minus;}
"*"      { return T_mul; }
"/"      { return T_div;}
"=="     { return T_eq;}
">"      { return T_gt;}
"<"      { return T_lt; }
"="      { return T_assign;}
"?"      { return T_qmark; }
":"      { return T_colon; }
"("      { g_paren_depth++; return T_lparen; }
")"      { g_paren_depth--; return T_rparen; }

{FLOAT}  { yylval.lexical = strdup(yytext); return T_fnum;}
{INT}    { yylval.lexical = strdup(yytext); return T_num;}

{VARIABLE} { yylval.lexical = strdup(yytext); return T_id; }

{newline}  { code_line++;}
[ \t]      { /* nothing */ }
.          {
    printf("Lexical Analysis: Unexpected String! :: (%s) . in line %d. \n", yytext, code_line);
}

%%
