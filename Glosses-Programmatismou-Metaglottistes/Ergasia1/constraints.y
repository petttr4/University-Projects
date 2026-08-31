%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <stdbool.h>

int yylex();
void yyerror (const char * msg);
int yylineno;

#include "types.h" /* Περιέχει τους τύπους της γλώσσας */
#include "symbolTable.h" /* Περιέχει τις συναρτήσεις διαχείρισης του πίνακα συμβόλων */

/*Δείκτης για τον πίνακα συμβόλων*/
ST_TABLE_TYPE symbolTable;

/*Συνάρτηση η οποία κανονικοποιεί τους τύπους των παραμέτρων (par) στους αντίστοιχους  τύπους (var).Αυτό μας βολεύει στους ελέγχους καθώς μια ακέραια παράμετρος συμπεριφέρεται σημασιολογικά όπως μια ακέραια μεταβλητή.
*/
static ParType norm(ParType t) {
    if (t== type_par_int)       return type_integer;
    if (t==type_par_float)     return type_float;
    if (t==type_par_int_set)   return type_int_set;
    if (t==type_par_float_set) return type_float_set;
    return t;
}

/*Ελέγχει αν ένας τύπος είναι αριθμητικός (int ή float, var ή par) */
static int is_numeric(ParType t) {
    return (t==type_integer || t==type_float ||
            t==type_par_int || t==type_par_float);
}

/*Ελέγχει αν ένας τύπος είναι σύνολο (int set ή float set, var ή par) */
static int is_set(ParType t) {
    return (t==type_int_set || t==type_float_set ||
            t==type_par_int_set || t==type_par_float_set);
}

/*Επιστρέφει τον τύπο των στοιχείων που περιέχονται σε ένα σύνολο*/
static ParType set_elem(ParType t) {
    if (t==type_int_set   || t==type_par_int_set)   return type_integer;
    if (t==type_float_set || t==type_par_float_set) return type_float;
    return type_error;
}

/*Έλεγχος τύπων για αριθμητικές πράξεις.Επειδή η γλώσσα έχει αυστηρό σύστημα τύπων και απαγορεύει τις αυτόματες μετατροπές,από την εκφώνηση μας αναφέρατε ότι επιτρέπουμε πράξεις μόνο μεταξύ ίδιων τύπων*/
ParType typeDefinition(ParType a, ParType b) {
    a= norm(a); b =norm(b);
    if (a==type_integer && b==type_integer) return type_integer;
    if (a==type_float   && b==type_float)   return type_float;
    return type_error;
}

%}

/* Ενεργοποίηση αναλυτικότερων μηνυμάτων σφάλματος από Bison */
%define parse.error verbose

/* Η ένωση ορίζει τους τύπους δεδομένων που μπορούν να μεταφέρουν 
   τα tokens και τα non-terminals*/

%union {
    char *id;
    struct {
        char    *info;     /*κείμενο του token (π.χ. "3.14") */
        ParType  type;     /* τύπος της έκφρασης               */
        int      numtype;  /* 0=ακέραιος, 1=πραγματικός        */
    } se;
}

/* Ορισμός των λεκτικών μονάδων και σύνδεσή τους με τα keywords της γλώσσας */
%token T_VAR        "var"
%token T_PAR        "par"
%token T_SET_OF     "set_of"
%token T_CONSTRAINT "constraint"
%token T_SOLVE      "solve"
%token T_SATISFY    "satisfy"
%token T_MAXIMIZE   "maximize"
%token T_TRUE       "true"
%token T_FALSE      "false"
%token T_DOTDOT     ".."
%token T_GE         ">="
%token T_LE         "=<"

%token T_AND        "and"
%token T_OR         "or"
%token T_IMPLIES    "==>"

%token T_INTERSECT  "intersect"
%token T_UNION      "union"
%token T_DIFF       "diff"
%token T_SUBSET     "subset"
%token T_IN         "in"

/* Σύνδεση των tokens που κουβαλάνε τιμές με τα αντίστοιχα πεδία του union */
%token <se> T_BASE_TYPE
%token <se> T_NUM
%token <id> T_ID

/* Ορισμός προτεραιότητας και προσεταιριστικότητας τελεστών με βάση τις οδηγίες από την εκφώνηση*/
%nonassoc T_IMPLIES
%left     T_OR
%left     T_AND
%nonassoc '>' '<' '=' T_GE T_LE
%left  '+' '-'
%left  '*' '/'

/* Καθορισμός του τύπου της δομής union που επιστρέφουν τα non-terminals */
%type <se> Type Base_type Range_type
%type <se> NumExpression Arg
%type <se> BoolExpr BoolArg
%type <se> SetExpression

%%

/* Αρχικός κανόνας: Αρχικοποιεί τον πίνακα συμβόλων ως κενό και ξεκινά την ανάλυση */
Model : {symbolTable=NULL;} Items
     ;

Items : Item ';' Items 
      | error ';' Items /* Ανάνηψη από συντακτικό σφάλμα: προσπερνά το λάθος μέχρι το επόμενο ';' */
      | /* empty*/  /*Τερματισμός της αναδρομής (κενό) */
      ;

Item : VarPar_item
     | Constraint_item
     | Solve_item
     ;

/* -ΔΗΛΩΣΕΙΣ ΜΕΤΑΒΛΗΤΩΝ ΚΑΙ ΠΑΡΑΜΕΤΡΩΝ- */

VarPar_item
/*Δήλωση απλής μεταβλητής απόφασης π.χ var int: x; ή var set_a: newX; */
    : "var" Type ':' T_ID
        {
            ParType vtype= $2.type;
           /* Αν το Type επιστρέψει type_error αλλά έχει όνομα ($2.info), σημαίνει ότι 
               χρησιμοποιήθηκε ένα T_ID ως τύπος (ένα par set που ορίζει τύπο var). 
            */
            if (vtype== type_error && $2.info != NULL) {
                ParType pt = lookup_type(symbolTable, $2.info);
                if (pt== type_par_int_set)        vtype= type_int_set;
                else if (pt== type_par_float_set) vtype= type_float_set;
                else {
                    fprintf(stderr, "Wrong type specifier (line %d) %s\n",
                            yylineno, $2.info);
                    YYERROR;
                }
            }
/*Προσπάθεια εισαγωγής στον πίνακα συμβόλων. Αν αποτύχει, η μεταβλητή έχει ήδη δηλωθεί*/
            if (!addvar(&symbolTable, $4, vtype)) {
                fprintf(stderr, "Var %s Already Declared!\n", $4);
                YYERROR;
            }
        }

/*Δήλωση μεταβλητής συνόλου π.χ var set_of int : setX; */ 
    | "var" "set_of" Type ':' T_ID
        {
            ParType vtype;
            ParType inner= $3.type;
           /* Ανάλογα με τον εσωτερικό τύπο, καθορίζουμε αν είναι σύνολο ακεραίων ή πραγματικών */
            if (inner ==type_integer)     vtype= type_int_set;
            else if (inner ==type_float)  vtype= type_float_set;
            else if (inner ==type_bool) {
                fprintf(stderr, "Wrong Type in set delcaration %d\n", yylineno);
                YYERROR;
            } else {
             /* Διαχείριση περίπτωσης όπου χρησιμοποιείται alias (T_ID) μέσα στο set_of */
                if ($3.info !=NULL) {
                    ParType pt= lookup_type(symbolTable, $3.info);
                    if (pt ==type_par_int_set)        vtype= type_int_set;
                    else if (pt== type_par_float_set) vtype= type_float_set;
                    else {
                        fprintf(stderr, "Wrong type specifier (line %d) %s\n",
                                yylineno, $3.info);
                        YYERROR;
                    }
                } else {
                    fprintf(stderr, "Wrong Type in set delcaration %d\n", yylineno);
                    YYERROR;
                }
            }
            if (!addvar(&symbolTable, $5, vtype)) {
                fprintf(stderr, "Var %s Already Declared!\n", $5);
                YYERROR;
            }
        }

/*Δήλωση απλής παραμέτρου π.χ. par int: x; */
    | "par" Base_type ':' T_ID
        {
            ParType ptype;
            if ($2.type== type_integer)     ptype = type_par_int;
            else if ($2.type== type_float)  ptype = type_par_float;
            else {
                /* Το 'par bool' δεν υποστηρίζεται από τη γλώσσα βάσει του Πίνακα 1 */
                fprintf(stderr, "Wrong Type in set delcaration %d\n", yylineno);
                YYERROR;
            }
            if (!addvar(&symbolTable, $4, ptype)) {
                fprintf(stderr, "Var %s Already Declared!\n", $4);
                YYERROR;
            }
        }
/*Δήλωση παραμέτρου συνόλου με εύρος τιμών π.χ. par set_of 8..20 : set_a; */
    | "par" "set_of" Range_type ':' T_ID
        {
            ParType ptype;
            if ($3.type== type_integer)     ptype = type_par_int_set;
            else if ($3.type == type_float)  ptype = type_par_float_set;
            else { YYERROR; }
            if (!addvar(&symbolTable, $5, ptype)) {
                fprintf(stderr, "Var %s Already Declared!\n", $5);
                YYERROR;
            }
        }
    ;

Type
    : Base_type  { $$ = $1; }
    | Range_type { $$ = $1; }
    | T_ID
        {
            /* Όταν ένα T_ID χρησιμοποιείται ως τύπος, πρέπει να ελέγξουμε αν έχει δηλωθεί 
               προηγουμένως ως παράμετρος συνόλου (par set), αλλιώς έχουμε σημασιολογικό λάθος */
            if (lookup(symbolTable, $1)) {
                ParType pt = lookup_type(symbolTable, $1);
                if (pt != type_par_int_set && pt != type_par_float_set) {
                    fprintf(stderr, "Wrong type specifier (line %d) %s\n", yylineno, $1);
                    YYERROR;
                }
            } else {
                fprintf(stderr, "Undefined Variable %s\n", $1);
                YYERROR;
            }
            $$.info    = $1;
            $$.type    = type_error;
            $$.numtype = 0;
        }
    ;

Base_type : T_BASE_TYPE { $$ = $1; } ;

/* Κανόνας για εύρος τιμών ( 10..20 ή 1.5..2.5) */
Range_type
    : T_NUM ".." T_NUM
        {
          /* Έλεγχος αν και τα δύο άκρα είναι ακέραιοι */
            if ($1.numtype == 0 && $3.numtype == 0) {
                $$.type = type_integer;
                if (atoi($1.info) >= atoi($3.info)) {
                    fprintf(stderr,
                        "Wrong Ranges declared (line %d). Lower bound must be less than upper bound.\n",
                        yylineno);
                    YYERROR;
                }
           /* Έλεγχος αν και τα δύο άκρα είναι πραγματικοί αριθμοί */
            } else if ($1.numtype == 1 && $3.numtype == 1) {
                $$.type = type_float;
                if (atof($1.info) >= atof($3.info)) {
                    fprintf(stderr,
                        "Wrong Ranges declared (line %d). Lower bound must be less than upper bound.\n",
                        yylineno);
                    YYERROR;
                }
            } else {
              /*Σφάλμα αν έχουμε ανάμειξη τύπων*/
                fprintf(stderr,
                    "Wrong Ranges declared (line %d). Should be of same type.\n",
                    yylineno);
                YYERROR;
            }
            $$.info = NULL; $$.numtype = 0;
        }
    ;

/* -ΠΕΡΙΟΡΙΣΜΟΙ ΚΑΙ ΛΟΓΙΚΕΣ ΕΚΦΡΑΣΕΙΣ- */

Constraint_item : "constraint" BoolExpr ;

/*Λογικές εκφράσεις και έλεγχος τύπων (πρέπει και τα δύο μέλη να είναι boolean) */
BoolExpr
    : BoolExpr "==>" BoolExpr
        {
            if ($1.type != type_bool || $3.type != type_bool) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
            $$.type = type_bool;
        }
    | BoolExpr "or" BoolExpr
        {
            if ($1.type != type_bool || $3.type != type_bool) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
            $$.type = type_bool;
        }
    | BoolExpr "and" BoolExpr
        {
            if ($1.type != type_bool || $3.type != type_bool) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
            $$.type = type_bool;
        }
    | BoolArg { $$ = $1; }
    ;

BoolArg
/*Σύγκριση αριθμητικών εκφράσεων (π.χ x > y) */
    : NumExpression RelOp NumExpression
        {
            ParType l = norm($1.type), r = norm($3.type);
            /*πρέπει και τα δύο μέλη να είναι αριθμητικά και του ίδιου τύπου*/
            if (!is_numeric($1.type) || !is_numeric($3.type) || l != r) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
            $$.type = type_bool;
        }
    | SetExpression { $$ = $1; }
    | "true"  { $$.type = type_bool; $$.info = NULL; $$.numtype = 0; }
    | "false" { $$.type = type_bool; $$.info = NULL; $$.numtype = 0; }
    | T_ID
        {
            /* Έλεγχος αν ένα ID που χρησιμοποιείται αυτούσιο ως λογικό όρισμα είναι όντως δηλωμένο ως booλ*/
            if (!lookup(symbolTable, $1)) {
                fprintf(stderr, "Undefined Variable %s\n", $1);
                YYERROR;
            }
            $$.type = lookup_type(symbolTable, $1);
            if ($$.type != type_bool) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
            $$.info = $1; $$.numtype = 0;
        }
    ;

RelOp : '>' | '<' | '=' | T_GE | T_LE ;

/* -ΑΡΙΘΜΗΤΙΚΕΣ ΕΚΦΡΑΣΕΙΣ- */

NumExpression
    : NumExpression '+' NumExpression
        {
            $$.type = typeDefinition($1.type, $3.type);
            if ($$.type == type_error) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
        }
    | NumExpression '-' NumExpression
        {
            $$.type = typeDefinition($1.type, $3.type);
            if ($$.type == type_error) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
        }
    | NumExpression '*' NumExpression
        {
            $$.type = typeDefinition($1.type, $3.type);
            if ($$.type == type_error) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
        }
    | NumExpression '/' NumExpression
        {
            $$.type = typeDefinition($1.type, $3.type);
            if ($$.type == type_error) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
        }
    | Arg { $$ = $1; }
    ;

/* -ΕΚΦΡΑΣΕΙΣ ΣΥΝΟΛΩΝ- */
SetExpression
/*Σύνθετη περίπτωση subset με πράξη συνόλων( A subset B union C) */
    : Arg "subset" Arg Set_Ops Arg
        {
            if (!is_set($1.type) || !is_set($3.type) || !is_set($5.type)) {
                fprintf(stderr, "Args are not sets, line %d\n", yylineno);
                YYERROR;
            }
            /* Όλα τα σύνολα στην πράξη πρέπει να είναι του ιδίου τύπου */
            if (norm($1.type)!=norm($3.type) || norm($1.type)!=norm($5.type)) {
                fprintf(stderr, "Type mismatch in sets, line %d\n", yylineno);
                YYERROR;
            }
            $$.type = type_bool; $$.info = NULL; $$.numtype = 0;
        }
    
    /*Απλό subset μεταξύ δύο συνόλων π.χ A subset B */
    | Arg "subset" Arg
        {
            if (!is_set($1.type) || !is_set($3.type)) {
                fprintf(stderr, "Args are not sets, line %d\n", yylineno);
                YYERROR;
            }
            if (norm($1.type) != norm($3.type)) {
                fprintf(stderr, "Type mismatch in sets, line %d\n", yylineno);
                YYERROR;
            }
            $$.type = type_bool; $$.info = NULL; $$.numtype = 0;
        }

    /*Έλεγχος αν ένα στοιχείο ανήκει σε ένα σύνολο π.χ x in seta */
    | Arg "in" Arg
        {
            if (!is_set($3.type)) {
                fprintf(stderr, "Args are not sets, line %d\n", yylineno);
                YYERROR;
            }
            /* Ο τύπος του στοιχείου πρέπει να ταιριάζει με τον τύπο των στοιχείων του συνόλου (π.χ int με int_set) */
            if (norm($1.type) != set_elem($3.type)) {
                fprintf(stderr, "Type missmatch in line %d\n", yylineno);
                YYERROR;
            }
            $$.type = type_bool; $$.info = NULL; $$.numtype = 0;
        }
    ;

Set_Ops : "intersect" | "union" | "diff" ;

Arg
/*Αν το όρισμα είναι αριθμητικό literal (T_NUM) */
    : T_NUM
        {
            $$.info= $1.info;
            $$.numtype= $1.numtype;
            $$.type= ($1.numtype == 0) ? type_integer : type_float;
        }

    /* Αν το όρισμα είναι μεταβλητή (T_ID) ελέγχουμε αν υπάρχει στον πίνακα συμβόλων */
    | T_ID
        {
            if (!lookup(symbolTable, $1)) {
                fprintf(stderr, "Undefined Variable %s\n", $1);
                YYERROR;
            }
            $$.type= lookup_type(symbolTable, $1);
            $$.info =$1; $$.numtype = 0;
        }
    ;

/* -ΕΝΤΟΛΕΣ ΕΠΙΛΥΣΗΣ- */

Solve_item : "solve" SolutionType ;

SolutionType
    : "satisfy"
    | "maximize" T_ID
        {
            /*Στην περίπτωση μεγιστοποίησης,η μεταβλητή πρέπει να έχει δηλωθεί */
            if (!lookup(symbolTable,$2)) {
                fprintf(stderr,"Undefined Variable %s\n", $2);
                YYERROR;
            }
        }
    ;

%%
/*Ενσωμάτωση του κώδικα C που παράγει ο Flex για τη λεκτική ανάλυση */
#include "constraints.lex.c"

/*Συνάρτηση διαχείρισης συντακτικών λαθών */
void yyerror (const char * msg)
{
   fprintf(stderr,"Error(line %d) : %s\n", yylineno, msg); 
}

int main(int argc, char **argv) {
   ++argv, --argc;  /* Προσπέραση του ονόματος του εκτελέσιμου προγράμματος */
   if ( argc > 0 )
       yyin = fopen( argv[0], "r" );
   else
      yyin = stdin;

   int result = yyparse(); /* Εκκίνηση του συντακτικού αναλυτή */

/*Αν η ανάλυση ολοκληρώθηκε επιτυχώς χωρίς κανένα συντακτικό ή σημασιολογικό λάθος */
   if (result == 0 && yynerrs == 0)
      printf("Syntax OK!\n");
   else
      printf("There were %d errors in code. Failure!\n", yynerrs);
   return result;
}
