#ifndef _jasmin_h
#define _jasmin_h

typedef struct codenode codenode;
typedef struct stacknode stacknode;
typedef struct functionnode functionnode;

codenode *first;

codenode *firstfunction;

struct codenode
{
    char *code;
    codenode *next;
};

stacknode *firststack;

struct stacknode
{
    int type;
    stacknode *next;
};




void addcode(char *);
void insert_in_file(char *);
void addstack(int);
int getstack(int);
void popstack();
void enablefunction();
void disablefunction();
void free_all();

#endif