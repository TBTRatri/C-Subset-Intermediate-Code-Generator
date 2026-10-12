%option noyywrap

%{
#include "symbol_info.h"
#include <iostream>
#include <string>

using namespace std;

// This MUST be defined before y.tab.h
#define YYSTYPE symbol_info*
#include "y.tab.h"

// Reference 'lines' and 'yylval' from the parser
extern int lines;
extern YYSTYPE yylval;
void yyerror(char *);
%}

delim    [ \t\v\r\f]
newline  \r?\n
ws       {delim}+
letter_  [A-Za-z_]
digit    [0-9]
id       {letter_}({letter_}|{digit})*
integers {digit}+
floats   {digit}*(\.{digit}+)|{digit}*(\.{digit}+)?((E|e)[-]?{digit}+)

%%

{ws}        { /* ignore whitespace */ }
{newline}   { lines++; }

"if"        { return IF; }
"else"      { return ELSE; }
"for"       { return FOR; }
"while"     { return WHILE; }
"int"       { return INT; }
"float"     { return FLOAT; }
"void"      { return VOID; }
"return"    { return RETURN; }
"printf"    { return PRINTLN; }

"+"|"-"     { yylval = new symbol_info(yytext, "ADDOP"); return ADDOP; }
"*"|"/"|"%" { yylval = new symbol_info(yytext, "MULOP"); return MULOP; }
"++"        { return INCOP; }
"--"        { return DECOP; }
"=="|"!="|"<"|">"|"<="|">=" { yylval = new symbol_info(yytext, "RELOP"); return RELOP; }
"="         { return ASSIGNOP; }
"&&"|"||"   { yylval = new symbol_info(yytext, "LOGICOP"); return LOGICOP; }
"!"         { return NOT; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LCURL; }
"}"         { return RCURL; }
"["         { return LTHIRD; }
"]"         { return RTHIRD; }
","         { return COMMA; }
";"         { return SEMICOLON; }

{id}        { yylval = new symbol_info(yytext, "ID"); return ID; }
{integers}  { yylval = new symbol_info(yytext, "CONST_INT"); return CONST_INT; }
{floats}    { yylval = new symbol_info(yytext, "CONST_FLOAT"); return CONST_FLOAT; }

.           { /* ignore unknown characters */ }

%%
