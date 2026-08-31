.class public simple9 
.super java/lang/Object

.method public static main([Ljava/lang/String;)V
 .limit locals 30 
 .limit stack 30

bipush 10
istore 2
bipush 10
iload 2
iconst_0
if_icmpgt #_1
goto #_2
#_1:
bipush 20
goto #_3
#_2:
bipush 50
#_3:
iadd
iconst_2
idiv
istore 1
iload 1
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(I)V
return
.end method

