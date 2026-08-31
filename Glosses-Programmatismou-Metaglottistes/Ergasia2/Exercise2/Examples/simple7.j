.class public simple7 
.super java/lang/Object

.method public static main([Ljava/lang/String;)V
 .limit locals 30 
 .limit stack 30

bipush 10
istore 2
iconst_3
iconst_5
iadd
iinc 2 1
iload 2
iadd
istore 1
iload 1
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(I)V
return
.end method

