.class public simple3 
.super java/lang/Object

.method public static main([Ljava/lang/String;)V
 .limit locals 30 
 .limit stack 30

ldc 2.3
iconst_1
i2f
fadd
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(F)V
iconst_4
ldc 4.5
swap
i2f
swap
fadd
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(F)V
return
.end method

