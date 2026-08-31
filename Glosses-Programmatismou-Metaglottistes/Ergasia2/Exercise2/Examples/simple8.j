.class public simple8 
.super java/lang/Object

.method public static main([Ljava/lang/String;)V
 .limit locals 30 
 .limit stack 30

bipush 8
istore 2
iload 2
bipush 10
if_icmplt #_1
goto #_2
#_1:
bipush 13
goto #_3
#_2:
bipush 23
#_3:
istore 1
iload 1
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(I)V
return
.end method

