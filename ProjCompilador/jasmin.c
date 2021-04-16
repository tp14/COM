#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "jasmin.h"

int funbool = 0;

void addcode(char *value)
{
    codenode *newnode = malloc(sizeof(codenode));
    newnode->code = malloc((strlen(value)+1) * sizeof(char *));
    strcpy(newnode->code, value);
    newnode->next = NULL;

    codenode *aux;
    if (funbool)
    {
        aux = firstfunction;
    } else{
        aux = first;
    }
    

    if (aux == NULL)
    {
        if (funbool)
        {
            firstfunction = newnode;
        } else{
            first = newnode;
        }
    }
    else
    {
        while (aux->next != NULL)
        {
            aux = aux->next;
        }
        aux->next = newnode;
    }
}

void insert_in_file(char *file_name)
{
    FILE *bytecode;

    bytecode = fopen(file_name, "w");

    codenode *aux;
    aux = first;

    while (aux->next != NULL)
    {
        fputs(aux->code, bytecode);
        aux = aux->next;
    }

    fputs(aux->code, bytecode);

    aux = firstfunction;

    if (aux != NULL)
    {
        while (aux->next != NULL)
        {
            fputs(aux->code, bytecode);
            aux = aux->next;
        }

        fputs(aux->code, bytecode);
    }
    

}
void addstack(int type){
    stacknode *newnode = malloc(sizeof(stacknode));
    newnode->type = type;
    newnode->next = NULL;

    newnode->next = firststack;
    firststack = newnode;
}

int getstack(int pos){
    stacknode *aux;
    aux = firststack;

    for (size_t i = 0; i < pos; i++)
    {
        aux=aux->next;
    }

    return aux->type;
}

void popstack(){
    stacknode *aux;
    aux = firststack;

    firststack = firststack->next;

    free(aux);
}

void free_all(){
    codenode *aux;
    codenode *freenode;

    aux = first->next;
    freenode = first;

    while (aux != NULL)
    {
        free(freenode->code);
        free(freenode);
        freenode = aux;
        aux = aux->next;
    }
    free(freenode->code);
    free(freenode);
}

void enablefunction(){
    funbool = 1;
}

void disablefunction(){
    funbool = 0;
}
