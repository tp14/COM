all:
	bison trabalho_bison.y -d
	flex trabalho_flex.l
	gcc -o trab hash.c jasmin.c trabalho_bison.tab.c lex.yy.c -lm
	./trab
	clear
	java -jar jasmin-2.4/jasmin.jar bytecode.j
	java java_class 
	make clean

clean:
	rm -rf trab java_class.class lex.yy.c trabalho_bison.tab.c trabalho_bison.tab.h trabalho_bison.output

jasmin:
	java -jar jasmin-2.4/jasmin.jar bytecode.j
	java java_class 