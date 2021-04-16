#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "hash.h"

varlist *lista;
paramlist *paramList;
int inserted = 0;
int paramInserted = 0;
int var_num = 1;


int args;

void init()
{
    int i;
    for (i = 0; i < SIZE; i++)
        chain[i] = NULL;
}

int get_sequence(){
    var_num+=2;
    return var_num-2;
}

void insertSymbol(char *symbol, int lineno){
    data newsym;
    newsym.type = 's';
    newsym.symbol = symbol;

    data *oldsym = searchAndPick(&newsym);

    if (oldsym != NULL)
    {
        insertLine(oldsym, lineno);
        return;
    }
    

    newsym.lines = malloc(sizeof(line));
    newsym.lines->lineno = lineno;
    newsym.lines->next = NULL;

    insert(&newsym);

};

void insertLine(data *data, int lineno){
    line *aux = data->lines;
    while (aux->next != NULL)
    {
        aux = aux->next;
    }
        
    aux->next = malloc(sizeof(line));
    aux->next->lineno = lineno;
    aux->next->next = NULL;
}

int insertParamList(char *name, char type, int lineno){
    if (paramList == NULL)
    {
        paramList = malloc(50 * sizeof(paramList));
    }
    paramList[paramInserted].name = name;
    paramList[paramInserted].type = type;
    paramList[paramInserted].lineno = lineno;
    paramList[paramInserted].cod = var_num;
    paramInserted++;
    var_num+=2;
    return var_num-2;
}


void declareFunction(char *name, char type){
    data newfun;
    newfun.type = 'f';
    newfun.variable.name = name;
    if (search(&newfun))
    {
        printf("Função já existe: %s, erro linha %d\n", name, paramList[0].lineno);
        exit(1);
    }
    
    newfun.variable.type = type;
    newfun.variable.constante = 0;
    newfun.lines = malloc(sizeof(line));
    newfun.lines->lineno = paramList[0].lineno;
    newfun.lines->next = NULL;

    newfun.variable.params = malloc (paramInserted * sizeof(variable));
    newfun.variable.numparams = paramInserted;

    for (size_t i = 0; i < paramInserted; i++)
    {
        if (paramList[i].type == '0')
        {
            newfun.variable.numparams = 0;
            break;
        }
        newfun.variable.params[i].name = paramList[i].name;
        newfun.variable.params[i].type = paramList[i].type;
        setValue(&newfun.variable.params[i], 0);
        insertList(paramList[i].name, 0);
        declareVariables(paramList[i].type, 0, paramList[i].lineno);
    }


    insert(&newfun);

    paramInserted = 0;
}

void insereArgs(){
    args++;
}

void checkFuncao(char *name, int lineno){
    data func;
    func.type = 'f';
    func.variable.name = name;
    data *funcao = searchAndPick(&func);

    if (funcao == NULL)
    {
        printf("funcao nao existe: %s, erro na linha %d\n", name, lineno);
        exit(1);
    }

    if(args != funcao->variable.numparams){
        printf("numero de parâmetros incorreto, funcao %s, linha %d\n", name, lineno);
        exit(1);
    }
    args = 0;

    insertLine(funcao, lineno);
    
}

void declareVariables(char type, int constant, int lineno){
    for (size_t i = 0; i < inserted; i++)
    {
        data newvar;
        newvar.type = 'v';
        newvar.variable.constante = constant;
        newvar.lines = malloc(sizeof(line));
        newvar.lines->lineno = lineno;
        newvar.lines->next = NULL;
        newvar.variable.name = lista[i].name;
        newvar.variable.type = type;
        newvar.variable.cod = lista[i].cod;
        switch (newvar.variable.type)
        {
        case 'i':
            newvar.variable.value.ival = lista[i].value;
            break;
        case 'f':
            newvar.variable.value.fval = lista[i].value;
            break;
        case 'b':
            newvar.variable.value.bval = lista[i].value;
            break;
        default:
            break;
        }
        
        int a = search(&newvar);
        if(a){
            fprintf(stderr,"Variável já declarada:  %s, linha %d\n", lista[i].name, lineno);
            exit(1);
        }
        else{
            insert(&newvar);
        }
    }

    inserted = 0;
}

int insertList(char *name, double value){
    if (lista == NULL)
    {
        lista = malloc(50 * sizeof(lista));
    }
    
    lista[inserted].name = name;
    lista[inserted].value = value;
    lista[inserted].cod = var_num;
    inserted++;
    var_num+=2;
    return var_num-2;
}

void updateVariable(char *name, double value, int lineno){
    data aux;
    aux.type = 'v';
    aux.variable.name = name;
    data *data = searchAndPick(&aux);

    if (!data)
    {
        printf("Variável não declarada: %s, linha %d\n", name, lineno);
        exit(1);
    }
    

    if (data->variable.constante)
    {
        printf("variável constante: %s, impossível modificar, linha %d\n", name, lineno);
        exit(1);
    }

    insertLine(data, lineno);
    
    switch (data->variable.type)
        {
        case 'i':
            data->variable.value.ival = value;
            break;
        case 'f':
            data->variable.value.fval = value;
            break;
        case 'b':
            data->variable.value.bval = value;
            break;
        default:
            break;
        }
}

int comparedata(data *data1, data *data2){
    if (data1->type == data2->type)
    {
        if (data1->type == 's')
        {
            return strcmp(data1->symbol, data2->symbol) == 0;
        }
        else{
            return (strcmp(data1->variable.name, data2->variable.name) == 0) ? 1 : 0;
        }
    }
    return 0;
}

int getkey(data *value)
{
    int intvalue;
    if (value->type == 's')
    {
        intvalue = 0;
        int i = 0;
        while (value->symbol[i] != '\0')
        {
            intvalue += value->symbol[i];
            i++;
        }
    }
    else{
            intvalue = 0;
            int i = 0;
            while (value->variable.name[i] != '\0')
            {
                intvalue += value->variable.name[i];
                i++;
            }
        }
    
    return intvalue % SIZE;
}

void insert(data *value)
{
    struct node *newNode = malloc(sizeof(struct node));
    newNode->data.symbol = value->symbol;
    newNode->data.type = value->type;
    newNode->data.lines = value->lines;
    memcpy(&newNode->data.variable, &value->variable, sizeof(value->variable));
    newNode->next = NULL;

    int key = getkey(value);

    if (chain[key] == NULL)
    {
        chain[key] = newNode;
    }
    else
    {
        struct node *temp = chain[key];
        while (temp->next)
        {
            temp = temp->next;
        }
        temp->next = newNode;
    }
}

int del(data *value)
{
    int key = getkey(value);
    struct node *temp = chain[key], *dealloc;
    if (temp != NULL)
    {
        if (comparedata(&temp->data, value))
        {
            dealloc = temp;
            temp = temp->next;
            free(dealloc);
            return 1;
        }
        else
        {
            while (temp->next)
            {
                if (comparedata(&temp->next->data, value))
                {
                    dealloc = temp->next;
                    temp->next = temp->next->next;
                    free(dealloc);
                    return 1;
                }
                temp = temp->next;
            }
        }
    }

    return 0;
}

int search(data *value)
{
    int key = getkey(value);
    struct node *temp = chain[key];
    while (temp)
    {
        if (comparedata(&temp->data, value))
            return 1;
        temp = temp->next;
    }
    return 0;
}

data *searchAndPick(data *value)
{
    int key = getkey(value);
    struct node *temp = chain[key];
    while (temp)
    {
        if (comparedata(&temp->data, value))
            return &temp->data;
        temp = temp->next;
    }
    return NULL;
}

data *getData(char *name, int lineno){
    data *aux = malloc(sizeof(data));
    aux->type = 'v';
    aux->variable.name = name;
    aux = searchAndPick(aux);
    if (aux == NULL)
    {
        printf("Variável não declarada: %s, linha %d\n", name, lineno);
        exit(1);
    }
    return aux;
    
}

void printVar(variable *var, int lineno){
    if (var->type == 'i')
    {
        printf("\t\t%d\n", var->value.ival);
    }
    else{
        if (var->type == 'f')
        {
            printf("\t\t%lf\n", var->value.fval);
        }
        else{
            printf("\t\t%s\n", (var->value.bval) ? "True" : "False");
        }
    }
    insertLine(getData(var->name, lineno), lineno);
}

variable *getVar(char *name, int lineno){
    data *aux;
    aux = getData(name, lineno);
    if (lineno != 0)
    {
        insertLine(aux, lineno);
    }
    
    return &aux->variable;
}


double getValue(variable *var, int lineno){
    switch (var->type)
    {
    case 'i':
        return var->value.ival;
        break;
    case 'f':
        return var->value.fval;
        break;
    case 'b':
        return var->value.bval;
        break;
    
    default:
        break;
    }
    insertLine(getData(var->name, lineno), lineno);
}

variable *getFun(char *name, int lineno){
    data *aux = malloc(sizeof(data));
    aux->type = 'f';
    aux->variable.name = name;
    aux = searchAndPick(aux);
    if (aux == NULL)
    {
        printf("Variável não declarada: %s, linha %d\n", name, lineno);
        exit(1);
    }
    return &aux->variable;
}

double setValue(variable *var, double value){
    switch (var->type)
    {
    case 'i':
        var->value.ival = value;
        break;
    case 'f':
        var->value.fval = value;
        break;
    case 'b':
        var->value.bval = value;
        break;
    
    default:
        break;
    }
}

void tabela_de_simbolos(FILE *f){
    fprintf(f, "Nome                          Tipo        Tipo(var)   Valor(var)  Linhas Reconhecidas   \n");
    for (size_t i = 0; i < 20; i++)
    {
        node *aux = chain[i];
        

        while (aux != NULL)
        {

            data *dataaux = &aux->data;
            char value[13];
            if (dataaux->type != 's')
            {
                if(dataaux->variable.type == 'i') sprintf(value, "%d", dataaux->variable.value.ival);
                if(dataaux->variable.type == 'f') sprintf(value, "%lf", dataaux->variable.value.fval);
                if(dataaux->variable.type == 'b') sprintf(value, "%s", (dataaux->variable.value.bval)? "True":"False");
            }
            fprintf(f, "%-30s%-12s%-12s%-12s", \
            (dataaux->type == 's') ? dataaux->symbol : dataaux->variable.name, \
            (dataaux->type == 's') ? "Simbolo" : (dataaux->type == 'f') ? "Funcao" : "Variavel", \
            (dataaux->type == 's') ? "N/A" : (dataaux->variable.type == 'i') ? "Inteiro" : (dataaux->variable.type == 'f') ? "Real" : "Booleano", \
            (dataaux->type == 's' || dataaux->type == 'f') ? "N/A" : value);
            while (dataaux->lines != NULL)
            {
                fprintf(f,"%d ", dataaux->lines->lineno);
                dataaux->lines = dataaux->lines->next;
            }
            fprintf(f,"\n");
            
            aux = aux->next;
        }
        
    }
}

