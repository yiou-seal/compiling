%{
#include <stdio.h>
#include <stdlib.h>

extern FILE *fp;
FILE * f1;

int yylex();
void push();
void yyerror(char *s);
void codegen_logical();
void codegen_algebric();
void codegen_assign();
void if_label1();
void if_label2();
void if_label3();
void while_start();
void while_rep();
void while_end();
void check();
void setType();
void STMT_DECLARE();
void intermediateCode();
%}

%token ID INT DOUBLE INTDEC INTOCT INTHEX REALDEC REALOCT REALHEX
%token WHILE DO
%token IF ELSE THEN

%left EQ
%left PLUS MINUS
%left MULTI RDIV
%left GT LT
%left LB RB
%left LC RC
%left SEMIC

  
%%
pgmstart 		: TYPE ID LB RB STMTS
				;

STMTS 			: LC STMT1 RC
//				|	STMT    //对于循环或if条件语句 没有花括号则代码体就一句  
				;

STMT1			: STMT  STMT1
				|
				;

STMT 			: STMT_DECLARE    //all types of statements
				| STMT_ASSGN  
				| STMT_IF
				| STMT_WHILE
				| SEMIC
				;

				

EXP 			: EXP GT{push();} EXP {codegen_logical();}
				| EXP LT{push();} EXP {codegen_logical();}
				| EXP PLUS {push();} EXP {codegen_algebric();}
				| EXP MINUS{push();} EXP {codegen_algebric();}
				| EXP MULTI{push();} EXP {codegen_algebric();}
				| EXP RDIV{push();} EXP {codegen_algebric();}
				| LB EXP RB
				| ID {check();push();}
				| NUM {push();}
				;

STMT_IF 		: IF LB EXP RB  {if_label1();} THEN STMTS ELSESTMT 
				;

ELSESTMT		: ELSE {if_label2();} STMTS {if_label3();}
				| {if_label3();}
				;

STMT_WHILE		: {while_start();} WHILE LB EXP RB {while_rep();} WHILEBODY  
				;

WHILEBODY		: STMTS {while_end();}
				;

STMT_DECLARE 	: TYPE {setType();}  ID {STMT_DECLARE();}  IDS	//声明语句 IDS控制是否初始化
				;

IDS 			: SEMIC
				| EQ NUM SEMIC
				;


STMT_ASSGN		: ID {push();} EQ {push();} EXP {codegen_assign();} SEMIC
				;


NUM				: INTOCT
				| INTDEC
				| INTHEX
				| REALDEC
				| REALHEX
				| REALOCT
				;

TYPE			:INT
				|DOUBLE
				;

%%

#include <ctype.h>
#include "lex.yy.c"

int count=0;
extern FILE* output;


char st[10000][100];
int top=0;
int i=0;
char temp[10] ="t";

int label[2000];
int lnum=0;
int ltop=0;
char type[100];
struct Table
{
	char id[200];
	char type[100];
}table[10000];
int tableCount=0;

void yyerror(char *s) {
	printf("Syntax Error in line number : %d : %s %s\n", yylineno, s, yytext );
}
    
void push()
{
	printf("before push\n");
  	strcpy(st[++top],yytext);
	printf("after push\n");
}

void codegen_logical()
{
 	sprintf(temp,"$t%d",i);			//2031 illegal hardware instruction
  	fprintf(f1,"%s\t=\t%s\t%s\t%s\n",temp,st[top-2],st[top-1],st[top]);
  	top-=2;
 	strcpy(st[top],temp);
 	i++;
}

void codegen_algebric()
{
 	sprintf(temp,"$t%d",i); // converts temp to reqd format
  	fprintf(f1,"%s\t=\t%s\t%s\t%s\n",temp,st[top-2],st[top-1],st[top]);
  	top-=2;
 	strcpy(st[top],temp);
 	i++;
}
void codegen_assign()
{
	fprintf(f1,"fuzhiyuju\n");
 	fprintf(f1,"%s\t=\t%s\n",st[top-2],st[top]);
 	top-=3;
}
 
void if_label1()
{
 	lnum++;
 	fprintf(f1,"\tif( not %s)",st[top]);
 	fprintf(f1,"\tgoto $L%d\n",lnum);
 	label[++ltop]=lnum;
}

void if_label2()
{
	int x;
	lnum++;
	x=label[ltop--]; 
	fprintf(f1,"\t\tgoto $L%d\n",lnum);
	fprintf(f1,"$L%d: \n",x); 
	label[++ltop]=lnum;
}

void if_label3()
{
	int y;
	y=label[ltop--];
	fprintf(f1,"$L%d: \n",y);
	top--;
}
void while_start()
{
	lnum++;
	label[++ltop]=lnum;
	fprintf(f1,"$L%d:\n",lnum);
}
void while_rep()
{
	lnum++;
 	fprintf(f1,"if( not %s)",st[top]);
 	fprintf(f1,"\tgoto $L%d\n",lnum);
 	label[++ltop]=lnum;
}
void while_end()
{
	int x,y;
	y=label[ltop--];
	x=label[ltop--];
	fprintf(f1,"\t\tgoto $L%d\n",x);
	fprintf(f1,"$L%d: \n",y);
	top--;
}

/* for symbol table*/

void check()
{
	char temp[200];
	strcpy(temp,yytext);
	int flag=0;
	for(i=0;i<tableCount;i++)
	{
		if(!strcmp(table[i].id,temp))
		{
			flag=1;
			break;
		}
	}
	if(!flag)
	{
		yyerror("Variable not declard");
		exit(0);
	}
}

void setType()
{
	strcpy(type,yytext);
}


void STMT_DECLARE()
{
	char temp[200];
	int i,flag;
	flag=0;
	strcpy(temp,yytext);
	printf("i am declare\n");
	fprintf(f1,"declareyuju\n");
	printf("yytext is %s",yytext);
	for(i=0;i<tableCount;i++)
	{
		if(!strcmp(table[i].id,temp))
			{
			flag=1;
			break;
				}
	}
	if(flag)
	{
		yyerror("reSTMT_DECLARE of ");
		exit(0);
	}
	else
	{
		strcpy(table[tableCount].id,temp);
		strcpy(table[tableCount].type,type);
		tableCount++;
	}
}

void intermediateCode()
{
	int Labels[100000];
	char buf[100];
	f1=fopen("output","r");
	int flag=0,lineno=1;
	memset(Labels,0,sizeof(Labels));
	while(fgets(buf,sizeof(buf),f1)!=NULL)
	{
		printf("buff is %s\n",buf);
		if(buf[0]=='$'&&buf[1]=='$'&&buf[2]=='L')
		{
			int k=atoi(&buf[3]);
			printf("hi, k is %d\n",k);
			Labels[k]=lineno;
		}
		else
		{
			lineno++;
		}
	}
	fclose(f1);
	f1=fopen("output","r");
	lineno=0;

	printf("\n\n\n*********************InterMediate Code***************************\n\n");
	while(fgets(buf,sizeof(buf),f1)!=NULL)
	{
		//printf("%s",buf);
		if(buf[0]=='$'&&buf[1]=='$'&&buf[2]=='L')
		{
			;
		}
		else
		{
			flag=0;
			lineno++;
			printf("%3d:\t",lineno);
			int len=strlen(buf),i,flag1=0;
			for(i=len-3;i>=0;i--)
			{
				if(buf[i]=='$'&&buf[i+1]=='$'&&buf[i+2]=='L')
				{
					flag1=1;
					break;
				}
			}
			if(flag1)
			{
				buf[i]='\0';
				int k=atoi(&buf[i+3]),j;
				//printf("%s",buf);
				for(j=0;j<i;j++)
					printf("%c",buf[j]);
				printf(" %d\n",Labels[k]);
			}
			else printf("%s",buf);
		}
	}
	printf("%3d:\tend\n",++lineno);
	fclose(f1);
}

int main(int argc, char *argv[])
{
	output = stdout;
	yyin = fopen(argv[1], "r");
	f1=fopen("output","w");
	fprintf(f1,"start");
	if (!f1) exit(1);
   	if(!yyparse())
		printf("\nParsing complete\n");
	else
	{
		printf("\nParsing failed\n");
		exit(0);
	}
	
	fclose(yyin);
	fclose(f1);

	for(int i = 0;i<10;i++){
	printf("%s \n",st[i]);
	}
	printf("\n");
	for(int j = 0;j<10;j++){
	printf("%d    ",label[i]);}

	//intermediateCode();
    return 0;
}
         
