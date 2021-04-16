%{

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "hash.h"
#include "jasmin.h"

extern int yylex();
extern int yyparse();
extern int yylineno;
extern FILE* yyin;
extern FILE* yyout;
// FILE* bytecode;

void yyerror(const char* s);

// tipo de variável para declarações
int variable_type=4;
//comeca em 3 pq 1 e 2 é usado pra scan
int labelCont=3;
// os dois ultimos pro scan pra n da conflito
int istoreScan = 998;
// string pra passar os parametros, int pra saber se é float ou int e int pra contar quantos
char param[500] = "";
int vPam[10], vPamTipo[10];
int contParam=0;
//vetor pra armanezar os label de for na sequencia, cont para os for e auxiliar pra passar o valor pra os valFor
int seqFor[20], contFor=0, auxFor=0, varforvalue[20];
// int para salva os valores iniciais das variaveis do for
int valFor[20], valFor2[20], valAuxFor=0;
// booleanos para verificação de expressões
int expression_type = 0;
int decl_cmp = 0;
// contagem de comparações
int cmpcont = 0;
// variáveis para o if
int seqif[20],  iflabel=0, ifcont = 0;
// variáveis para o while
int seqwhile[20],  whilelabel=0, whilecont = 0;
// booleanos para variáveis em while e for
int varinloop = 0, loopvar1 = 0, loopvar2 = 0;
char fix_ponto = ':';
%}

%union {
	int ival, lineno;
	float fval;
    char* sval;
    variable vval;
}

%define parse.error verbose

%token<ival> T_INT T_TRUE T_FALSE
%token<fval> T_REAL
%token<sval> T_STR T_VARIAVEL
%token<sval> T_TIPO_INT T_TIPO_REAL T_TIPO_BOOL T_TIPO_VOID
%token<ival> T_MAIS T_MENOS T_MULTIPLICA T_DIVIDE T_RESTO
%token<ival> T_ABRE_PAR T_FECHA_PAR T_ABRE_CH T_FECHA_CH
%token<ival> T_VIR T_PONTO_VIR
%token<ival> T_RECEBE T_IGUAL T_DIFERENTE 
%token<ival> T_MENOR T_MENOR_IGUAL T_MAIOR T_MAIOR_IGUAL
%token<ival> T_NEGAR T_AND T_OR
%token<ival> T_IF T_THEN T_ELSE T_WHILE T_DO T_FOR
%token<ival> T_FUN T_RETURN T_SCAN T_PRINT T_CONST
%token<ival> T_SIN T_COS T_LOG
%token<ival> T_NOVA_LINHA T_EXIT

%left T_ABRE_PAR T_FECHA_PAR 
%left T_SIN T_COS T_LOG
%left T_MAIS T_MENOS
%left T_MULTIPLICA T_DIVIDE T_RESTO

%type<fval>expressao valor_variavel chamada_funcao return
%type<vval>numero
%type<fval>comparacao
%type<sval>tipo tipo_fun

%start programa

%%

programa: 
        | programa comando
        ;

comando: constantes
        | declaracao_funcao
        | declaracao
        | estrutura 
        | atribuicao 
        | funcao
        | T_EXIT {exit(0);}
        | expressao T_PONTO_VIR 
        | comparacao T_PONTO_VIR 
        | T_NOVA_LINHA;

constantes: T_CONST T_TIPO_INT const_int | T_CONST T_TIPO_BOOL const_bool | T_CONST T_TIPO_REAL const_real;

const_int: T_VARIAVEL T_RECEBE T_INT T_PONTO_VIR {
        if(getstack(0) == 1){
            addcode("\n\td2i");
        }
        popstack();
        insertList($1, $3);
        declareVariables('i', 1, yylineno);
        char decl[] = "", num[20];
        strcat(decl, "\n\tistore ");
        sprintf(num, "%d", insertList($1, $2));
        strcat(decl, num);
        addcode(decl);
    };

const_bool: T_VARIAVEL T_RECEBE expressao T_PONTO_VIR 
    {   
        if(getstack(0) == 1){
            addcode("\n\td2i");
        }
        popstack();
        insertList($1, $3);
        declareVariables('b', 1, yylineno);
        char decl[] = "", num[20];
        strcat(decl, "\n\tistore ");
        sprintf(num, "%d", insertList($1, $2));
        strcat(decl, num);
        addcode(decl);
    }

const_real: T_VARIAVEL T_RECEBE T_REAL T_PONTO_VIR {
        if(getstack(0) == 1){
            addcode("\n\ti2d");
        }
        popstack();
        insertList($1, $3);
        declareVariables('f', 1, yylineno);
        char decl[] = "", num[20];
        strcat(decl, "\n\tdstore ");
        sprintf(num, "%d", insertList($1, $2));
        strcat(decl, num);
        addcode(decl);
    };

declaracao: tipo nomes T_PONTO_VIR 
{ 
    declareVariables($1[0], 0, yylineno); 
};

tipo: T_TIPO_INT {$$ = $1;variable_type=0;} | T_TIPO_REAL {$$ = $1;variable_type=1;} | T_TIPO_BOOL {$$ = $1;variable_type=2;};

nomes: T_VARIAVEL valor_variavel {
    
    char decl[] = "", num[20];
    if (variable_type == 1)
    {
        if(getstack(0) == 0){
            addcode("\n\ti2d");
        }
        popstack();
        strcat(decl, "\n\tdstore");
        sprintf(num, " %d", insertList($1, $2));
        strcat(decl, num);
    }
    else{
        if(getstack(0) == 1){
            addcode("\n\td2i");
        }
        popstack();
        strcat(decl, "\n\tistore");
        sprintf(num, " %d", insertList($1, $2));
        strcat(decl, num);
    }
    addcode(decl);

} 
| nomes T_VIR T_VARIAVEL valor_variavel {
    char num[20], decl[] = "";
    if (variable_type == 1)
    {
        if(decl_cmp){
            fprintf(stderr, "Variável não pode receber comparacoes, linha %d", yylineno);
            exit(1);
        }
        if(getstack(0) == 0){
            addcode("\n\ti2d");
        }
        popstack();
        strcat(decl, "\n\tdstore");
        sprintf(num, " %d", insertList($3, $4));
        strcat(decl,num);
    }
    if(variable_type == 0){
        if(decl_cmp){
            fprintf(stderr, "Variável não pode receber comparacoes, linha %d", yylineno);
            exit(1);
        }
        if(getstack(0) == 1){
            addcode("\n\td2i");
        }
        popstack();
        strcat(decl, "\n\tistore");
        sprintf(num, " %d", insertList($3, $4));
        strcat(decl,num);
    }
    if(variable_type == 2){
        if($4 > 0){
            addcode("\n\tpop\n\tldc 1");
            popstack();
            strcat(decl, "\n\tistore");
            sprintf(num, " %d", insertList($3, $4));
            strcat(decl,num);
        }
        if($4 < 0){
            addcode("\n\tpop\n\tldc -1");
            popstack();
            strcat(decl, "\n\tistore");
            sprintf(num, " %d", insertList($3, $4));
            strcat(decl,num);
        }
        if($4 == 0){
            addcode("\n\tpop\n\tldc 0");
            popstack();
            strcat(decl, "\n\tistore");
            sprintf(num, " %d", insertList($3, $4));
            strcat(decl,num);
        }
    }
    addcode(decl);
};

valor_variavel: {
    $$ = 0;
    decl_cmp = 0;
    if(variable_type == 1){
        addcode("\n\tdconst_0");
        addstack(1);
    }
    else{
        addcode("\n\tldc 0");
        addstack(0);
    }

    }
    | T_RECEBE expressao {
        $$ = $2;
        decl_cmp = 0;
        }
    | T_RECEBE comparacao {
        $$ = $2;
        decl_cmp = 1;
    };

atribuicao: T_VARIAVEL T_RECEBE expressao T_PONTO_VIR {
        updateVariable($1, $3, yylineno);
        char num[20], decl[] = "";
        if(getVar($1, 0)->type == 'f'){
            if(getstack(0) == 0){
                addcode("\n\ti2d");
            }
            popstack();
            strcat(decl, "\n\tdstore");
            sprintf(num, " %d", getVar($1, 0)->cod);
            strcat(decl,num);
        } 
        else{
            if(getstack(0) == 1){
                addcode("\n\td2i");
            }
            popstack();
            strcat(decl, "\n\tistore");
            sprintf(num, " %d", getVar($1, 0)->cod);
            strcat(decl,num);
        }
        addcode(decl);
    }
    |
    T_VARIAVEL T_RECEBE comparacao T_PONTO_VIR {
        if(getVar($1, 0)->type != 'b'){
            fprintf(stderr, "Apenas booleanos podem receber comparacoes");
            exit(1);
        }
        char num[20], decl[] = "";
        popstack();
        strcat(decl, "\n\tistore");
        sprintf(num, " %d", getVar($1, 0)->cod);
        strcat(decl,num);
        addcode(decl);
    }; 

expressao:
    expressao T_MAIS expressao {
        $$ = $1 + $3;
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            addcode("\n\tiadd");
        } else{
            addstack(1);
            addcode("\n\tdadd");
        }
    }
    | expressao T_MENOS expressao {
        $$ = $1 - $3;
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            addcode("\n\tisub");
        } else{
            addstack(1);
            addcode("\n\tdsub");
        }
    }
    | expressao T_MULTIPLICA expressao {
        $$ = $1 * $3;
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            addcode("\n\timul");
        } else{
            addstack(1);
            addcode("\n\tdmul");
        }
    }
    | expressao T_DIVIDE expressao {
        $$ = $1 / $3;
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            addcode("\n\tidiv");
        } else{
            addstack(1);
            addcode("\n\tddiv");
        }
    }
    | expressao T_RESTO expressao {
        $$ = fmod($1, $2);
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            addcode("\n\tirem");
        } else{
            addstack(1);
            addcode("\n\tdrem");
        }
    }
    | T_MENOS expressao {
        $$ = -1 * $2;
        expression_type = getstack(0);
        if(expression_type == 0){
            addcode("\n\tineg");
        } else{
            addcode("\n\tdneg");
        }
    }
    | T_ABRE_PAR expressao T_FECHA_PAR {$$ = ($2);} 
    | T_SIN T_ABRE_PAR expressao T_FECHA_PAR {
        $$ = sin($3);
        if(getstack(0) == 0){
            addcode("\n\ti2d");
        }
        addcode("\n\tinvokestatic java/lang/Math.sin(D)D");
        popstack();
        addstack(1);
    }
    | T_COS T_ABRE_PAR expressao T_FECHA_PAR {
        $$ = cos($3);
        if(getstack(0) == 0){
            addcode("\n\ti2d");
        }
        addcode("\n\tinvokestatic java/lang/Math.cos(D)D");
        popstack();
        addstack(1);
    }
    | T_LOG T_ABRE_PAR expressao T_FECHA_PAR {
        $$ = log($3);
        if(getstack(0) == 0){
            addcode("\n\ti2d");
        }
        addcode("\n\tinvokestatic java/lang/Math.log(D)D");
        popstack();
        addstack(1);
    }
    | T_INT {
        $$ = $1;
        char text[] = "\n\tldc ", num[20];
        sprintf(num, "%d", $1);
        strcat(text, num);
        addcode(text);
        addstack(0);
    }
    | chamada_funcao {$$ = $1;}
    | T_REAL {
        $$ = $1;
        char text[] = "\n\tldc ", num[20];
        sprintf(num, "%f", $1);
        strcat(text, num);
        addcode(text);
        addcode("\n\tf2d");
        addstack(1);
    }
    | T_VARIAVEL 
    {
        $$ = getValue(getVar($1, yylineno), 0);
        if(varinloop){
            if(loopvar1 == 0){
                loopvar1 = getVar($1, 0)->cod;
                varforvalue[contFor] = getValue(getVar($1, yylineno), 0);
            } else{
                if(loopvar2 == 0){
                    loopvar2 = getVar($1, 0)->cod;
                }
            }
        }
        char num[20], str[] = "";
        if (getVar($1, 0)->type == 'f'){
            strcat(str, "\n\tdload ");
            sprintf(num, "%d", getVar($1, 0)->cod);
            strcat(str,num);
            addstack(1);
        }else{
            strcat(str, "\n\tiload ");
            sprintf(num, "%d", getVar($1, 0)->cod);
            strcat(str,num);
            addstack(0);
        }
        addcode(str);
    }
    | T_TRUE {
        $$ = $1;
        char text[] = "\n\tldc ", num[20];
        sprintf(num, "%d", $1);
        strcat(text, num);
        addcode(text);
        addstack(0);
    }
    | T_FALSE {
        $$ = $1;
        char text[] = "\n\tldc ", num[20];
        sprintf(num, "%d", $1);
        strcat(text, num);
        addcode(text);
        addstack(0);
    }

chamada_funcao: T_VARIAVEL T_ABRE_PAR  T_FECHA_PAR {
        checkFuncao($1, yylineno); $$ = 0;
        addcode("\n\tinvokestatic java_class.");
        addcode($1);
        if(getFun($1,yylineno)->type == 'i' || getFun($1,yylineno)->type == 'b'){
            addcode("()I");
            addstack(0);}
        else if (getFun($1,yylineno)->type == 'f'){
            addcode("()D");
            addstack(1);}
        else{
            addcode("()V");
            addcode("\n\tldc 0");
            addstack(0);}
    }
    | T_VARIAVEL T_ABRE_PAR parametros T_FECHA_PAR {
        checkFuncao($1, yylineno); $$ = 0;
        addcode("\n\tinvokestatic java_class.");
        addcode($1);
        addcode("(");
        addcode(param);
        param[0] = '\0'; 
        if(getFun($1,yylineno)->type == 'i' || getFun($1,yylineno)->type == 'b'){
            addcode(")I");
            addstack(0);}
        else if (getFun($1,yylineno)->type == 'f'){
            addcode(")D");
            addstack(1);}
        else{
            addcode(")V");
            addcode("\n\tldc 0");
            addstack(0);}
    };

parametros: expressao {
        insereArgs();
        if(expression_type == 0)
            strcat(param, "I"); 
        else 
            strcat(param, "D");      
    }
    | parametros T_VIR expressao {
        insereArgs();
        if(expression_type == 0)
            strcat(param, "I"); 
        else 
            strcat(param, "D");       
    };

comparacao:
    expressao T_IGUAL expressao {
        $$ = $1 == $3;
        char num[20] = "";
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            sprintf(num, "\n\tif_icmpeq EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        } else{
            addstack(0);
            addcode("\n\tdcmpg");
            sprintf(num, "\n\tifeq EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        }
    }
    | T_NEGAR expressao {
        char num[20];
        $$ = !$2;
        if(getstack(0) == 1){
            fprintf(stderr, "Tentando negar um float, linha %d", yylineno);
            exit(1);
        }
        sprintf(num, "\n\tifeq EQ%d", cmpcont);
        addcode(num);
        addcode("\n\tldc 0");
        sprintf(num, "\n\tgoto END%d", cmpcont);
        addcode(num);
        sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
        addcode(num);
        addcode("\n\tldc 1");
        sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
        addcode(num);
        cmpcont++;
    }
    | expressao T_OR expressao {
        $$ = $1 || $3;
        if(getstack(0) == 1 || getstack(1) == 1){
            fprintf(stderr, "Or com float, linha %d", yylineno);
            exit(1);
        }
        popstack();
        addcode("\n\tior");
    }
    | expressao T_AND expressao {
        $$ = $1 && $3;
        if(getstack(0) == 1 || getstack(1) == 1){
            fprintf(stderr, "And com float, linha %d", yylineno);
            exit(1);
        }
        popstack();
        addcode("\n\tiand");
    }
    | expressao T_DIFERENTE expressao {
        char num[20];
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            sprintf(num, "\n\tif_icmpeq EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        } else{
            addstack(0);
            addcode("\n\tdcmpg");
            sprintf(num, "\n\tifeq EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        }
    }
    | expressao T_MENOR expressao {
        char num[20];
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            sprintf(num, "\n\tif_icmplt EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        } else{
            addstack(0);
            addcode("\n\tdcmpl");
            addcode("\n\tldc 0");
            sprintf(num, "\n\tif_icmplt EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        }
    }
    | expressao T_MENOR_IGUAL expressao {
        $$ = $1 <= $3;
        char num[20];
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            sprintf(num, "\n\tif_icmple EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        } else{
            addstack(0);
            addcode("\n\tdcmpl");
            addcode("\n\tldc 0");
            sprintf(num, "\n\tif_icmple EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        }
    }
    | expressao T_MAIOR expressao {
        $$ = $1>$3;
        char num[20];
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            sprintf(num, "\n\tif_icmpgt EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        } else{
            addstack(0);
            addcode("\n\tdcmpl");
            addcode("\n\tldc 0");
            sprintf(num, "\n\tif_icmpgt EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        }
    }
    | expressao T_MAIOR_IGUAL expressao {
        $$ = $1>=$3;
        $$ = $1 <= $3;
        char num[20];
        if(getstack(0) == 0){
            if(getstack(1) == 0){
                expression_type = 0;
            }
            else{
                expression_type = 1;
                addcode("\n\ti2d");
            }
        }else{
            if(getstack(1) == 0){
                expression_type = 1;
                addcode("\n\tswap\n\ti2d\n\tswap");
            }
            else{
                expression_type = 1;
            }
        }
        popstack();
        popstack();
        if(expression_type == 0){
            addstack(0);
            sprintf(num, "\n\tif_icmpge EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        } else{
            addstack(0);
            addcode("\n\tdcmpl");
            addcode("\n\tldc 0");
            sprintf(num, "\n\tif_icmpge EQ%d", cmpcont);
            addcode(num);
            addcode("\n\tldc 0");
            sprintf(num, "\n\tgoto END%d", cmpcont);
            addcode(num);
            sprintf(num, "\nEQ%d%c", cmpcont, fix_ponto);
            addcode(num);
            addcode("\n\tldc 1");
            sprintf(num, "\nEND%d%c", cmpcont, fix_ponto);
            addcode(num);
            cmpcont++;
        }
    };

estrutura:
    estrutura_if 
    | estrutura_for 
    | estrutura_while ; 

estrutura_if:
    T_IF T_ABRE_PAR comparacao T_FECHA_PAR {
        char num[20];
        // addcode("\n\tdup");
        sprintf(num, "\n\tifeq ELSE%d", iflabel);
        addcode(num);
        seqif[ifcont] = iflabel;
        ifcont++;
        iflabel++;
    } blocos {
        char num[20];
        sprintf(num, "\n\tgoto ENDIF%d", seqif[ifcont-1]);
        addcode(num);
        sprintf(num, "\nELSE%d:", seqif[ifcont-1]);
        addcode(num);
    } else
    {
        char num[20];
        sprintf(num, "\nENDIF%d:", seqif[ifcont-1]);
        ifcont--;
        addcode(num);
    };

else: 
    T_PONTO_VIR
    | T_ELSE blocos T_PONTO_VIR ;    

estrutura_for:
    T_FOR T_ABRE_PAR {varinloop = 1;} expressao {
        if(getstack(0) == 1) {
            fprintf(stderr, "Float em for, linha %d\n", yylineno);
            exit(1);
        }
        if(loopvar1 == 0){
            loopvar1 = -1;
        }
    } T_VIR expressao {
        if(getstack(0) == 1) {
            fprintf(stderr, "Float em for, linha %d\n", yylineno);
            exit(1);
        }
    } T_FECHA_PAR {
        varinloop = 0;
        char num[20];
        if(loopvar1 > 0){
            valAuxFor = loopvar1;
            
        } else{
            valAuxFor = get_sequence();
            addcode("\n\tswap");
            sprintf(num, "\n\tistore %d", valAuxFor);
            addcode(num);
            sprintf(num, "\n\tiload %d", valAuxFor);
            addcode(num);
            addcode("\n\tswap");
        }
        loopvar1 = 0;
        valFor[contFor] = valAuxFor;
        if(loopvar2 != 0){
            valAuxFor = loopvar2;
        } else{
            valAuxFor = get_sequence();
            sprintf(num, "\n\tistore %d", valAuxFor);
            addcode(num);
            sprintf(num, "\n\tiload %d", valAuxFor);
            addcode(num);
        }
        loopvar2 = 0;
        valFor2[contFor] = valAuxFor;

        popstack();
        popstack();
        seqFor[contFor] = labelCont;
        auxFor=contFor;
        contFor++;
        labelCont++;
        sprintf(num, "\nCmpLabel%d%c", seqFor[contFor-1], fix_ponto);
        addcode(num);
        addcode("\n\tswap");
        sprintf(num, "\n\tif_icmplt Label%d", seqFor[contFor-1]);
        addcode(num);
    } blocos {
        char num[20];      
        sprintf(num, "\n\tiload %d", valFor[auxFor]);
        addcode(num);
        addcode("\n\tldc 1");
        addcode("\n\tiadd");
        sprintf(num, "\n\tistore %d", valFor[auxFor]);
        addcode(num);
        sprintf(num, "\n\tiload %d", valFor[auxFor]);
        addcode(num);
        sprintf(num, "\n\tiload %d", valFor2[auxFor]);
        addcode(num);
        sprintf(num, "\n\tgoto CmpLabel%d", seqFor[contFor-1]);
        addcode(num);
        sprintf(num, "\nLabel%d%c", seqFor[contFor-1], fix_ponto);
        addcode(num);
        sprintf(num, "\n\tldc %d", varforvalue[contFor-1]);
        addcode(num);
        sprintf(num, "\n\tistore %d", valFor[auxFor]);
        addcode(num);
        auxFor--;
        contFor--;
    } T_PONTO_VIR;

estrutura_while:
    T_WHILE T_ABRE_PAR {
        char num[20];

        seqwhile[whilecont] = whilelabel;
        auxFor=whilecont;
        whilecont++;
        whilelabel++;
        sprintf(num, "\nCmpWhile%d%c", seqwhile[whilecont-1], fix_ponto);
        addcode(num);
    } comparacao T_FECHA_PAR {
        char num[20];
        popstack();
        sprintf(num, "\n\tifeq While%d", seqwhile[whilecont-1]);
        addcode(num);
    } blocos {
        char num[20];
        sprintf(num, "\n\tgoto CmpWhile%d", seqwhile[whilecont-1]);
        addcode(num);
        sprintf(num, "\n\tWhile%d:", seqwhile[whilecont-1]);
        addcode(num);
    } T_PONTO_VIR;

blocos: 
    T_ABRE_CH realiza T_FECHA_CH;

realiza: 
    comandos_blocos
    | realiza comandos_blocos;

comandos_blocos: constantes
        | declaracao
        | estrutura 
        | atribuicao 
        | funcao
        | T_EXIT {exit(0);}
        | expressao T_PONTO_VIR 
        | comparacao T_PONTO_VIR 
        | T_NOVA_LINHA;

declaracao_funcao:
    T_FUN tipo_fun T_VARIAVEL T_ABRE_PAR T_FECHA_PAR T_ABRE_CH {
        insertParamList("0", '0', yylineno);
        declareFunction($3, $2[0]);
        enablefunction();
        char fun[] = ".method public static ";
        strcat(fun, $3);
        if($2[0] == 'i' || $2[0] == 'b')
            strcat(fun,"()I");
        else if($2[0] == 'f')
            strcat(fun,"()D");
        else
            strcat(fun,"()V");
        strcat(fun, "\n\t.limit stack 1000\n\t.limit locals 1000");
        addcode(fun);
    } func_realiza return {
            if($2[0] == 'i' || $2[0] == 'b')
                addcode("\n\n\tireturn\n.end method\n\n");
            else if($2[0] == 'f')
                addcode("\n\n\tdreturn\n.end method\n\n");
            else
                addcode("\n\n\treturn\n.end method\n\n");

    }T_FECHA_CH T_PONTO_VIR {disablefunction();} 
    |T_FUN tipo_fun T_VARIAVEL T_ABRE_PAR{
        enablefunction();
        char fun[] = ".method public static ";
        strcat(fun, $3);
        strcat(fun, "(");
        addcode(fun);
    } argumento { 
        declareFunction($3, $2[0]);
        char fun[] = "", num[20];
        if($2[0] == 'i' || $2[0] == 'b')
            strcat(fun,")I");
        else if($2[0] == 'f')
            strcat(fun,")D");
        else
            strcat(fun,")V");
        strcat(fun, "\n\t.limit stack 1000\n\t.limit locals 1000");
        addcode(fun);
        int j=0;
        for(int i=0;i<contParam;i++){
            if(vPamTipo[i] == 1){
                sprintf(num, "\n\tiload %d", j);
                strcat(param, num);
                sprintf(num, "\n\tistore %d", vPam[i]+contParam*2);
                strcat(param, num);
                j++;
            }else{
                sprintf(num, "\n\tdload %d", j);
                strcat(param, num);
                sprintf(num, "\n\tdstore %d", vPam[i]+contParam*2);
                strcat(param, num);
                j+=2;
            }  
        }
        addcode(param);
        contParam=0;
        param[0] = '\0';
    } T_FECHA_PAR T_ABRE_CH func_realiza return{
        if($2[0] == 'i' || $2[0] == 'b'){
            addcode("\n\n\tireturn\n.end method\n\n");}
        else if($2[0] == 'f'){
            addcode("\n\n\tdreturn\n.end method\n\n");}
        else{
            addcode("\n\n\treturn\n.end method\n\n");}
        
    } T_FECHA_CH T_PONTO_VIR{
        disablefunction();
    } ;

func_realiza:
    | realiza;

return:
    T_RETURN expressao T_PONTO_VIR nova_linha {$$ = $2;} |  T_RETURN T_PONTO_VIR nova_linha {$$ = $2;};

tipo_fun: T_TIPO_INT {$$ = $1;} | T_TIPO_REAL {$$ = $1;} | T_TIPO_BOOL {$$ = $1;} | T_TIPO_VOID {$$ = $1;};

nova_linha:
    |T_NOVA_LINHA;

argumento:
    argumento T_VIR tipo T_VARIAVEL {
        int cod = insertParamList($4, $3[0], yylineno);
        vPam[contParam] = cod;
        if($3[0] == 'i' || $3[0] == 'b'){
            addcode("I");
            vPamTipo[contParam] = 1;
        }
        else {
            addcode("D");
            vPamTipo[contParam] = 0;
        }         
        contParam++;
    }
    |tipo T_VARIAVEL {
        int cod = insertParamList($2, $1[0], yylineno);
        vPam[contParam] = cod;
        if($1[0] == 'i' || $1[0] == 'b'){
            addcode("I");
            vPamTipo[contParam] = 1;
        }
        else {
            addcode("D");
            vPamTipo[contParam] = 0;
        }         
        contParam++;
    };
    
funcao:
    T_SCAN T_ABRE_PAR T_VARIAVEL T_FECHA_PAR T_PONTO_VIR
    {
    char num[20], decl[500] = "";
    strcat(decl, "\n\tldc 0");
    strcat(decl, "\n\tistore");
    sprintf(num, " %d", istoreScan);
    strcat(decl,num);
    strcat(decl,"\nLabel1:");
    strcat(decl,"\n\tgetstatic java/lang/System/in Ljava/io/InputStream;");
    strcat(decl,"\n\tinvokevirtual java/io/InputStream/read()I");
    strcat(decl, "\n\tistore");
    sprintf(num, " %d", istoreScan+1);
    strcat(decl,num);
    strcat(decl, "\n\tiload");
    sprintf(num, " %d", istoreScan+1);
    strcat(decl,num);
    strcat(decl, "\n\tldc 10\n\tisub\n\tifeq Label2\n\tiload");
    sprintf(num, " %d", istoreScan+1);
    strcat(decl,num);
    strcat(decl, "\n\tldc 32\n\tisub\n\tifeq Label2\n\tiload");
    sprintf(num, " %d", istoreScan+1);
    strcat(decl,num);
    strcat(decl, "\n\tldc 48\n\tisub\n\tldc 10\n\tiload");
    sprintf(num, " %d", istoreScan);
    strcat(decl,num);
    strcat(decl,"\n\timul\n\tiadd\n\tistore");
    sprintf(num, " %d", istoreScan);
    strcat(decl,num);
    strcat(decl,"\n\tgoto Label1\nLabel2:\n\tiload");
    sprintf(num, " %d", istoreScan);
    strcat(decl,num);
    strcat(decl, "\n\tistore");
    sprintf(num, " %d", getVar($3, 0)->cod);
    strcat(decl,num);
    addcode(decl);
    }  
    | T_PRINT T_ABRE_PAR numero T_FECHA_PAR T_PONTO_VIR
    {   
        if(variable_type != 4){
            if($3.type == 'f'){
                char num[20], load[]="\n\tdload ";
                sprintf(num, "%d", getVar($3.name, 0)->cod);
                strcat(load,num);
                addcode("\n\tgetstatic java/lang/System/out Ljava/io/PrintStream;");
                addcode(load);
                addcode("\n\tinvokevirtual java/io/PrintStream/println(D)V");
            }else{
                char num[20], load[]="\n\tiload ";
                sprintf(num, "%d", getVar($3.name, 0)->cod);
                strcat(load,num);
                addcode("\n\tgetstatic java/lang/System/out Ljava/io/PrintStream;");
                addcode(load);
                addcode("\n\tinvokevirtual java/io/PrintStream/println(I)V");
            }
            variable_type = 4;
        }else{
            char num[20], impr[] = "\n    getstatic java/lang/System/out Ljava/io/PrintStream;\n    ldc \"";
            if($3.type == 'f'){
                sprintf(num, "%f", $3.value.fval);
            }else{
                sprintf(num, "%d", $3.value.ival);
            }
            strcat(impr,num);
            strcat(impr, "\"\n    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V ");
            addcode(impr);
        }
    };
    
numero:
    T_INT { $$.type = 'i';$$.value.ival = $1; variable_type=4; }|T_REAL { $$.type = 'f';$$.value.fval = $1; variable_type=4; }
    | T_VARIAVEL{ $$ = *getVar($1, yylineno); variable_type=1;};

%%

int main() {
    init();

	yyin = fopen("input.mylang", "r");

    addcode(".class public java_class\n.super java/lang/Object\n\n");
    addcode(".method public <init>()V\n");
    addcode("\taload_0\n");
    addcode("\tinvokenonvirtual java/lang/Object/<init>()V\n");
    addcode("\treturn\n");
    addcode(".end method\n\n");
    addcode(".method public static main([Ljava/lang/String;)V\n");
    addcode("\t.limit stack 1000\n");
    addcode("\t.limit locals 1000\n");

	do {
		yyparse();
	} while(!feof(yyin));

    yyout = fopen("tabela_de_simbolos.out", "w");
    tabela_de_simbolos(yyout);
    fclose(yyout);	

    addcode("\n\n\treturn\n");
    addcode(".end method\n\n");

    insert_in_file("bytecode.j");

    free_all();

	return 0;
}

void yyerror(const char* s) {
	fprintf (stderr, "\t\t%s, linha %d\n", s, yylineno);
	exit(1);
}

