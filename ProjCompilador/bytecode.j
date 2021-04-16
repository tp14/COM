.class public java_class
.super java/lang/Object

.method public <init>()V
	aload_0
	invokenonvirtual java/lang/Object/<init>()V
	return
.end method

.method public static main([Ljava/lang/String;)V
	.limit stack 1000
	.limit locals 1000

	ldc 0
	istore 1
	ldc 10
	istore 3
	iload 1
	iload 3
	if_icmplt EQ0
	ldc 0
	goto END0
EQ0:
	ldc 1
END0:
	ifeq ELSE0
    getstatic java/lang/System/out Ljava/io/PrintStream;
    ldc "1"
    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V 
	iload 1
	iload 3
CmpLabel3:
	swap
	if_icmplt Label3
    getstatic java/lang/System/out Ljava/io/PrintStream;
    ldc "2"
    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V 
CmpWhile0:
	iload 1
	ldc 10
	if_icmpeq EQ1
	ldc 0
	goto END1
EQ1:
	ldc 1
END1:
	ifeq While0
	iload 1
	ldc 1
	iadd
	istore 1
    getstatic java/lang/System/out Ljava/io/PrintStream;
    ldc "3"
    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V 
	goto CmpWhile0
	While0:
	iload 1
	ldc 1
	iadd
	istore 1
	iload 1
	iload 3
	goto CmpLabel3
Label3:
	ldc 0
	istore 1
	goto ENDIF0
ELSE0:
ENDIF0:

	return
.end method

