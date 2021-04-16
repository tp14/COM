#ifndef _hash_h
#define _hash_h


#define SIZE 20

typedef struct node node;
typedef union value value;
typedef struct variable variable;
typedef struct varlist varlist;
typedef struct paramlist paramlist;
typedef struct data data;
typedef struct line line;

struct paramlist
{
    char* name;
    char type;
    int cod;
    int lineno;
};

struct varlist
{
    char* name;
    double value;
    int cod;
};


union value
{
    int ival;
    float fval;
    int bval;
};

struct variable
{
    char *name;
    char type;
    value value;
    int constante;
    variable *params;
    int numparams;
    int cod;
};

struct line
{
    int lineno;
    line *next;
};

struct data
{
    variable variable;
    char *symbol;
    char type;
    line *lines;
};

struct node
{
    data data;
    node *next;
};

node *chain[SIZE];

data *searchAndPick(data *);
void updateVariable(char *, double, int);
void declareVariables(char, int, int);
int insertList(char *, double);
void insertSymbol(char *, int);
int getkey(data *);
void init();
void insert(data *);
int del(data *);
int search(data *);
void printVar(variable *, int);
variable *getVar(char *name, int);
double getValue(variable *, int);
void insertLine(data *, int);
void tabela_de_simbolos(FILE *);
int insertParamList(char *, char , int );
void declareFunction(char *, char );
double setValue(variable *, double );
void checkFuncao(char *name, int lineno);
void insereArgs();
variable *getFun(char *name, int lineno);
int get_sequence();

#endif