.class public simple5 
.super java/lang/Object

.method public static main([Ljava/lang/String;)V
 .limit locals 30 
 .limit stack 30

ldc 10.5
fstore 1
iconst_4
fload 1
swap
i2f
swap
fadd
f2i
istore 2
iload 2
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(I)V
return
.end method

