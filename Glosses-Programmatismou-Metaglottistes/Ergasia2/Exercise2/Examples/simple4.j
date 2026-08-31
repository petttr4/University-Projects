.class public simple4 
.super java/lang/Object

.method public static main([Ljava/lang/String;)V
 .limit locals 30 
 .limit stack 30

ldc 10.5
fstore 1
fload 1
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(F)V
iconst_3
iconst_4
iadd
istore 2
iload 2
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(I)V
return
.end method

