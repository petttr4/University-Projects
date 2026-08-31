.PHONY: default

CFLAGS = -I./symbolTableSrc -I./
VPATH = symbolTableSrc

FILES_TO_DELETE = constraints.tab.c constraints.lex.c constraints.output constraints symbolTable.o

default: constraints

constraints: constraints.lex.c constraints.tab.c symbolTable.o
	gcc -o constraints constraints.tab.c symbolTable.o $(CFLAGS) -lfl

constraints.lex.c: constraints_lexer.l 
	flex -s -o constraints.lex.c constraints_lexer.l 

constraints.tab.c : constraints.y
	bison -v -o constraints.tab.c constraints.y

symbolTable.o: symbolTable.c symbolTable.h
	gcc -c $(CFLAGS) $< 

clean:
	 rm -f $(FILES_TO_DELETE)






