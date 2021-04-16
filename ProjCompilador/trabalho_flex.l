%option noyywrap

%{
#include <stdio.h>
#include "hash.h"
#include "jasmin.h"

#define YY_DECL int yylex()

#include "trabalho_bison.tab.h"

%}

DIGITO		[0-9]
LETRA       [A-Za-z]

%%

[ \t]	; // ignore todos os espaços em branco
\n							                    {yylineno++;return T_NOVA_LINHA;}
"//".*                                          ;
"if"						                	{insertSymbol(strdup(yytext), yylineno); return T_IF;}
"then"						                    {insertSymbol(strdup(yytext), yylineno); return T_THEN;}
"else"						                    {insertSymbol(strdup(yytext), yylineno); return T_ELSE;}
"while"						                    {insertSymbol(strdup(yytext), yylineno); return T_WHILE;}
"do"					                    	{insertSymbol(strdup(yytext), yylineno); return T_DO;}
"for"						                    {insertSymbol(strdup(yytext), yylineno); return T_FOR;}
"fun"                                           {insertSymbol(strdup(yytext), yylineno); return T_FUN;}
"return"                                        {insertSymbol(strdup(yytext), yylineno); return T_RETURN;}
"scan_int"                                      {insertSymbol(strdup(yytext), yylineno); return T_SCAN;}
"print"                                         {insertSymbol(strdup(yytext), yylineno); return T_PRINT;}
"const"                                         {insertSymbol(strdup(yytext), yylineno); return T_CONST;}
"true"                                          {insertSymbol(strdup(yytext), yylineno); yylval.ival = 1; return T_TRUE; }
"false"                                         {insertSymbol(strdup(yytext), yylineno); yylval.ival = 0; return T_FALSE; }
"int"                                           {insertSymbol(strdup(yytext), yylineno); yylval.sval = strdup(yytext); return T_TIPO_INT;}
"float"                                         {insertSymbol(strdup(yytext), yylineno); yylval.sval = strdup(yytext); return T_TIPO_REAL;}
"bool"                                          {insertSymbol(strdup(yytext), yylineno); yylval.sval = strdup(yytext); return T_TIPO_BOOL;}
"void"                                          {insertSymbol(strdup(yytext), yylineno); yylval.sval = strdup(yytext); return T_TIPO_VOID;}
"sin"                                           {insertSymbol(strdup(yytext), yylineno); return T_SIN;}
"cos"                                           {insertSymbol(strdup(yytext), yylineno); return T_COS;}
"log"                                           {insertSymbol(strdup(yytext), yylineno); return T_LOG;}
"exit"                                          {insertSymbol(strdup(yytext), yylineno); return T_EXIT;}
{DIGITO}+					                    {yylval.ival = atoi(yytext); return T_INT;}
{DIGITO}+\.{DIGITO}+ 		                    {yylval.fval = atof(yytext); return T_REAL;}
{LETRA}({LETRA}|{DIGITO})*				        {yylval.sval = strdup(yytext); return T_VARIAVEL; }
("\""|"\'").*("\""|"\'")	                    {yylval.sval = strdup(yytext); return T_STR;}
"+"							                    {insertSymbol(strdup(yytext), yylineno); return T_MAIS;}
"-"							                    {insertSymbol(strdup(yytext), yylineno); return T_MENOS;}
"*"							                    {insertSymbol(strdup(yytext), yylineno); return T_MULTIPLICA;}
"/"							                    {insertSymbol(strdup(yytext), yylineno); return T_DIVIDE;}
"%"                                             {insertSymbol(strdup(yytext), yylineno); return T_RESTO;}
"("							                    {insertSymbol(strdup(yytext), yylineno); return T_ABRE_PAR;}
")"	                                            {insertSymbol(strdup(yytext), yylineno); return T_FECHA_PAR;}
"{"							                    {insertSymbol(strdup(yytext), yylineno); return T_ABRE_CH;}
"}"							                    {insertSymbol(strdup(yytext), yylineno); return T_FECHA_CH;}						                    
","                                             {insertSymbol(strdup(yytext), yylineno); return T_VIR;}
";"                                             {insertSymbol(strdup(yytext), yylineno); yylval.lineno = yylineno;return T_PONTO_VIR;}
":"							                    {insertSymbol(strdup(yytext), yylineno); return T_RECEBE;}
"=="						                    {insertSymbol(strdup(yytext), yylineno); return T_IGUAL;}
"!="						                    {insertSymbol(strdup(yytext), yylineno); return T_DIFERENTE;}
"<"							                    {insertSymbol(strdup(yytext), yylineno); return T_MENOR;}
"<="						                    {insertSymbol(strdup(yytext), yylineno); return T_MENOR_IGUAL;}
">"							                    {insertSymbol(strdup(yytext), yylineno); return T_MAIOR;}
">="						                    {insertSymbol(strdup(yytext), yylineno); return T_MAIOR_IGUAL;}
"!"							                    {insertSymbol(strdup(yytext), yylineno); return T_NEGAR;}
"&&"						                    {insertSymbol(strdup(yytext), yylineno); return T_AND;}
"||"						                	{insertSymbol(strdup(yytext), yylineno); return T_OR;}

.							                    {printf("Caracter misterioso... %s\n", yytext);}
%%
