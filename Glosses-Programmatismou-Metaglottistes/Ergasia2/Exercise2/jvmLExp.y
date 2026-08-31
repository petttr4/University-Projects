%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int code_line;
extern FILE *yyout;
int yylex();
int yyerror(const char *);
int no_errors = 0;

#define ERR_VAR_DECL(VAR,LINE) {fprintf(stderr,"Variable :: %s in code_line %d. ",VAR,LINE); yyerror("Var already defined");YYERROR;}
#define ERR_VAR_MISSING(VAR,LINE) {fprintf(stderr,"Variable %s NOT declared, in code_line %d.",VAR,LINE); yyerror("Variable Declation fault");YYERROR;}
#define ERR_TYPE_MISSMATCH(EXPECTED,LINE) {fprintf(stderr,"TYPE ERROR: Expected %s  in code_line %d.",EXPECTED,LINE); yyerror("Type missmatch");YYERROR;}

#include "jvmLangTypesFunctions.h"
#include "symbolTable.h"

ST_TABLE_TYPE symbolTable;
#include "codeFacilities.h"

/*forward declaration,defined in the epilogue after token names are available */
extern int g_paren_depth; /*maintained by the lexer on every ( and ) */
void skip_to_stmt_end(void);

/*
 * coerce_binary:emit type-conversion instructions for binary operations.
 * Stack layout (bottom -> top): [left_value]  [right_value]
 * Returns the result type (type_real if either operand is real).
 *
 * Case 1:left=real,right=int  → right (int) is on TOP -> just i2f
 * Case 2:left=int,right=real → left (int) is BELOW right -> swap,i2f,swap
 */
static ParType coerce_binary(ParType left, ParType right)
{
    if (left== type_integer && right== type_integer) return type_integer;
    if (left ==type_real && right==type_real)    return type_real;
    if (left ==type_real && right== type_integer) {
        insertINSTRUCTION("i2f");
    } else {
        insertINSTRUCTION("swap");
        insertINSTRUCTION("i2f");
        insertINSTRUCTION("swap");
    }
    return type_real;
}

/* Labels for conditional expressions, shared across mid-rule actions */
static int cond_l1, cond_l2, cond_l3;

%}

%define parse.error verbose

%union{
   int    intval;
   char  *lexical;
   struct {
       ParType type;
       char   *place;
   } se;
   RelationType relopIndex;
}

%token T_start  "start"
%token T_end    "end"
%token T_print  "print"
%token T_int    "int"
%token T_float  "float"
%token T_inc    "++"
%token T_plus   "+"
%token T_minus  "-"
%token T_mul    "*"
%token T_div    "/"
%token T_eq     "=="
%token T_gt     ">"
%token T_lt     "<"
%token T_assign "="
%token T_qmark  "?"
%token T_colon  ":"
%token T_lparen "("
%token T_rparen ")"

%token <lexical> T_id
%token <lexical> T_num
%token <lexical> T_fnum

%type <se>         expr
%type <relopIndex> relop

%%

program:
    T_start T_id
        {
            create_preample($2);
            symbolTable= NULL;
        }
    stmts T_end
        {
            insertINSTRUCTION("return");
            insertINSTRUCTION(".end method\n");
        }
    ;

stmts:
    /* empty */
    | stmts stmt
    ;

stmt:
    /*variable declaration: (int x) */
    T_lparen T_int T_id T_rparen
        {
            if (!addvar(&symbolTable, $3, type_integer))
                ERR_VAR_DECL($3, code_line);
        }

    /*variable declaration:(float y) */
    | T_lparen T_float T_id T_rparen
        {
            if (!addvar(&symbolTable, $3, type_real))
                ERR_VAR_DECL($3,code_line);
        }

    /*
     * Assignment: (= varname expr)
     *
     * The declared variable check is a mid-rule action executed before
     * expr is parsed.This ensures that if the variable is undeclared,
     * YYERROR fires while the bison stack still has only T_lparen T_assign T_id,
     * so the error-recovery rule can call skip_to_stmt_end() and
     * skip all remaining tokens of this statement (including nested parens).
     */
    | T_lparen T_assign T_id
        {
            if (!lookup(symbolTable,$3))
                ERR_VAR_MISSING($3,code_line);
        }
      expr T_rparen
        {
            ParType vartype= lookup_type(symbolTable, $3);
            int varpos= lookup_position(symbolTable, $3);
            if (vartype== type_integer && $5.type == type_real)
                insertINSTRUCTION("f2i");
            else if (vartype== type_real && $5.type == type_integer)
                insertINSTRUCTION("i2f");
            insertSTORE(vartype, varpos);
        }

    /* Print (print expr) */
    | T_lparen T_print expr T_rparen
        {
            insertINSTRUCTION("getstatic java/lang/System/out Ljava/io/PrintStream;");
            insertINSTRUCTION("swap");
            if ($3.type== type_integer)
                insertINVOKEVITRUAL("java/io/PrintStream/println",type_integer,type_void);
            else
                insertINVOKEVITRUAL("java/io/PrintStream/println",type_real, type_void);
        }

    /*
 * Error recovery: If a statement fails bison pops the stack until 
 * it hits the 'error' token.At that point the T_lparen of the failing statement is on the stack.
 * skip_to_stmt_end() consumes the rest of that statement (handling 
 * any nested parentheses) so we can resume parsing from the 
 * next statement safely.
 */
    | T_lparen error
        {
            yyclearin;skip_to_stmt_end(); yyerrok;
        }
    ;

relop:
    T_gt { $$= OP_GT; }
  | T_lt { $$ =OP_LT; }
  | T_eq {$$ = OP_EQ;}
  ;

/*
 *expressions in prefix form
 */
expr:
    /*Integer literal */
    T_num
        {
            pushInteger(atoi($1));
            $$.type = type_integer;
        }

    /*Float literal */
  | T_fnum
        {
            insertLDC($1);
            $$.type= type_real;
        }

    /* Variable load */
  | T_id
        {
            if (!lookup(symbolTable, $1))
                ERR_VAR_MISSING($1, code_line);
            ParType vt= lookup_type(symbolTable, $1);
            int vp= lookup_position(symbolTable, $1);
            insertLOAD(vt, vp);
            $$.type =vt;
        }

    /* Post-increment:var++
     *load old value onto stack then increase the variable in memory */
  | T_id T_inc
        {
            if (!lookup(symbolTable,$1))
                ERR_VAR_MISSING($1,code_line);
            if (lookup_type(symbolTable, $1)!= type_integer)
                ERR_TYPE_MISSMATCH("int", code_line);
            int vp= lookup_position(symbolTable, $1);
            insertLOAD(type_integer, vp);
            insertIINC(vp, 1);
            $$.type= type_integer;
        }

    /*pre-increment:++var
     * Increase the variable in memory first then load the new value */
  | T_inc T_id
        {
            if (!lookup(symbolTable, $2))
                ERR_VAR_MISSING($2,code_line);
            if (lookup_type(symbolTable, $2)!= type_integer)
                ERR_TYPE_MISSMATCH("int",code_line);
            int vp = lookup_position(symbolTable,$2);
            insertIINC(vp,1);
            insertLOAD(type_integer,vp);
            $$.type=type_integer;
        }

    /*Addition:+ expr expr */
  | T_plus expr expr
        {
            ParType rt= coerce_binary($2.type, $3.type);
            insertOPERATION(rt, "add");
            $$.type =rt;
        }

    /*subtraction:- expr expr */
  | T_minus expr expr
        {
            ParType rt= coerce_binary($2.type, $3.type);
            insertOPERATION(rt, "sub");
            $$.type =rt;
        }

    /*multiplication:* expr expr */
  | T_mul expr expr
        {
            ParType rt= coerce_binary($2.type, $3.type);
            insertOPERATION(rt, "mul");
            $$.type= rt;
        }

    /*division:/ expr expr */
  | T_div expr expr
        {
            ParType rt= coerce_binary($2.type, $3.type);
            insertOPERATION(rt, "div");
            $$.type =rt;
        }

/*
 * operator implementation (JVM bytecode)
 * Pattern: (relop lhs rhs ? true_val : false_val)
 *
 * Uses 3 labels (L1, L2, L3) for the jump logic.
 * Allocated at M1 in static globals (cond_l1/l2/l3).
 *
 * M1 (after relop lhs rhs):both operands are on the stack.
 *   -> Emit: if_icmp<relop> L1
 *   -> Emit: goto L2
 *   -> Emit: L1:
 *
 * M2 (after ? true_val):true_val is now on the stack.
 *   -> Emit: goto L3 (skip false branch)
 *   -> Emit: L2:
 *
 * Final (after : false_val )):false_val is on the stack.
 *   -> Emit: L3:
 */
  | T_lparen relop expr expr
        /* M1 */
        {
            cond_l1= Label();
            cond_l2 =Label();
            cond_l3= Label();
            insertICMPOP($2,cond_l1);
            insertGOTO(cond_l2);
            insertLabel(cond_l1);
        }
    T_qmark expr
        /* M2 */
        {
            insertGOTO(cond_l3);
            insertLabel(cond_l2);
        }
    T_colon expr T_rparen
        {
            insertLabel(cond_l3);
            $$.type= $7.type;
        }

    /* Parenthesised expression:( expr ) */
  | T_lparen expr T_rparen
        {
            $$= $2;
        }
    ;

%%

/*
 *skip_to_stmt_end:skip all tokens until the closing ')' of the current statement is consumed.The opening '(' has already been shifted by
 *bison,so we start at depth=1 and stop when depth reaches 0.This safely handles deeply nested parentheses.*/
void skip_to_stmt_end(void)
{
    /* g_paren_depth reflects how many '(' are still open,
       counting the outer statement paren plus any nested ones that
       were already consumed before the error occurred.We simply
       keep reading tokens (the lexer updates g_paren_depth itself)
       until we are back to the depth that existed before this
       statement's opening '(' was read for example depth 0. */
    int tok;
    while (g_paren_depth>0){
        tok =yylex();
        if (tok== 0) break;  /* EOF safety */
    }
}

int yyerror(const char * msg)
{
  fprintf(stderr,"ERROR: %s (line %d).\n", msg, code_line);
  no_errors++;
  return 0;
}

#include "jvmLExp.lex.c"

int main(int argc,char **argv){
   FILE* jasmin_file;
   ++argv,--argc;
   if ( argc>0 && (yyin = fopen( argv[0], "r"))== NULL)
    {
      fprintf(stderr,"File %s NOT FOUND in current directory.\n Using stdin.\n",argv[0]);
      yyin = stdin;
    }
   int result= yyparse();
   fprintf(stderr,"Errors found %d.\n",no_errors);
   if (no_errors == 0){
      if (argc > 1) {jasmin_file = fopen(argv[1], "w");}
      else {
          fprintf(stderr,"No second argument defined. Output to screen.\n\n");
          jasmin_file = stdout;
     }
     print_int_code(jasmin_file);
     fclose(jasmin_file);
     }
   if (no_errors != 0)
      fprintf(stderr,"No Code Generated.\n");
   print_symbol_table(symbolTable);
  return result;
}
