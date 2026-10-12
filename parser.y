%{
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>

// CRITICAL: Define pointer type BEFORE including headers
#define YYSTYPE symbol_info*

#include "symbol_table.h"
#include "ast.h"
#include "three_addr_code.h"

extern FILE *yyin;
int yylex(void);
void yyerror(char *s);

// DEFINITIONS: These are the actual variables that the linker was missing
int lines = 1;
int errors = 0;
ofstream outlog, outerror, outcode;

symbol_table *symtbl = new symbol_table();
ProgramNode* ast_root = nullptr;
string varlist = "";
vector<string> paramlist, paramname;
%}

%token IF ELSE FOR WHILE INT FLOAT VOID RETURN PRINTLN ADDOP MULOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID INCOP DECOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program { 
    if($1) ast_root = (ProgramNode*)$1->get_ast_node(); 
} ;

program : program unit { 
            ProgramNode* prog = (ProgramNode*)$1->get_ast_node();
            if($2 && $2->get_ast_node()) prog->add_unit($2->get_ast_node());
            $$ = $1; 
        }
        | unit { 
            ProgramNode* prog = new ProgramNode();
            if($1 && $1->get_ast_node()) prog->add_unit($1->get_ast_node());
            $$ = new symbol_info("program", "program");
            $$->set_ast_node(prog);
        } ;

unit : var_declaration { $$ = $1; }
     | func_definition { $$ = $1; } ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {
            symtbl->Insert_in_table($2->getname(), "ID");
            symtbl->enter_scope(outlog);
            for(size_t i=0; i<paramname.size(); i++) {
                symtbl->Insert_in_table(paramname[i], "ID");
                symtbl->Lookup_in_table(paramname[i])->setidtype("var");
                symtbl->Lookup_in_table(paramname[i])->setvartype(paramlist[i]);
            }
        } compound_statement {
            FuncDeclNode* func = new FuncDeclNode($1->getname(), $2->getname());
            for(size_t i=0; i<paramlist.size(); i++) func->add_param(paramlist[i], paramname[i]);
            if($7 && $7->get_ast_node()) func->set_body((BlockNode*)$7->get_ast_node());
            $$ = new symbol_info("func", "func");
            $$->set_ast_node(func);
            paramlist.clear(); paramname.clear();
        } ;

parameter_list : parameters | { $$ = nullptr; } ;

parameters : parameters COMMA type_specifier ID { paramlist.push_back($3->getname()); paramname.push_back($4->getname()); }
           | type_specifier ID { paramlist.push_back($1->getname()); paramname.push_back($2->getname()); } ;

compound_statement : LCURL statements RCURL { 
            $$ = $2; 
            symtbl->exit_scope(outlog); 
        } 
        | LCURL RCURL {
            BlockNode* block = new BlockNode();
            $$ = new symbol_info("block", "block");
            $$->set_ast_node(block);
            symtbl->exit_scope(outlog);
        } ;

statements : statements statement {
            BlockNode* block = (BlockNode*)$1->get_ast_node();
            if($2 && $2->get_ast_node()) block->add_statement((StmtNode*)$2->get_ast_node());
            $$ = $1;
        }
        | statement {
            BlockNode* block = new BlockNode();
            if($1 && $1->get_ast_node()) block->add_statement((StmtNode*)$1->get_ast_node());
            $$ = new symbol_info("stmts", "stmts");
            $$->set_ast_node(block);
        } ;

statement : var_declaration { $$ = $1; }
          | expression_statement { $$ = $1; }
          | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
                $$ = new symbol_info("if", "stmt");
                $$->set_ast_node(new IfNode((ExprNode*)$3->get_ast_node(), (StmtNode*)$5->get_ast_node()));
          }
          | RETURN expression SEMICOLON {
                $$ = new symbol_info("ret", "stmt");
                $$->set_ast_node(new ReturnNode((ExprNode*)$2->get_ast_node()));
          } ;

var_declaration : type_specifier declaration_list SEMICOLON {
            DeclNode* decl = new DeclNode($1->getname());
            stringstream ss(varlist); string item;
            while(getline(ss, item, ',')) {
                if(item.empty()) continue;
                size_t pos = item.find("[");
                if(pos == string::npos) {
                    decl->add_var(item, 0);
                    symtbl->Insert_in_table(item, "ID");
                } else {
                    string name = item.substr(0, pos);
                    int sz = stoi(item.substr(pos+1, item.find("]")-pos-1));
                    decl->add_var(name, sz);
                    symtbl->Insert_in_table(name, "ID");
                }
            }
            $$ = new symbol_info("decl", "decl"); $$->set_ast_node(decl);
            varlist = "";
          } ;

declaration_list : declaration_list COMMA ID { varlist += "," + $3->getname(); }
                 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD { varlist += "," + $3->getname() + "[" + $5->getname() + "]"; }
                 | ID { varlist = $1->getname(); }
                 | ID LTHIRD CONST_INT RTHIRD { varlist = $1->getname() + "[" + $3->getname() + "]"; } ;

type_specifier : INT { $$ = new symbol_info("int", "type"); } 
               | FLOAT { $$ = new symbol_info("float", "type"); } 
               | VOID { $$ = new symbol_info("void", "type"); } ;

expression_statement : expression SEMICOLON { 
            $$ = new symbol_info("expr", "stmt"); 
            $$->set_ast_node(new ExprStmtNode((ExprNode*)$1->get_ast_node())); 
        } 
        | SEMICOLON { 
            $$ = new symbol_info("semi", "stmt"); 
            $$->set_ast_node(new ExprStmtNode(nullptr)); 
        } ;

variable : ID { 
            $$ = new symbol_info($1->getname(), "var"); 
            $$->set_ast_node(new VarNode($1->getname(), "int")); 
         }
         | ID LTHIRD expression RTHIRD {
            $$ = new symbol_info($1->getname(), "array");
            $$->set_ast_node(new VarNode($1->getname(), "int", (ExprNode*)$3->get_ast_node()));
         } ;

expression : logic_expression { $$ = $1; }
           | variable ASSIGNOP logic_expression {
            AssignNode* node = new AssignNode((VarNode*)$1->get_ast_node(), (ExprNode*)$3->get_ast_node(), "int");
            $$ = new symbol_info("assign", "expr"); $$->set_ast_node(node);
           } ;

logic_expression : rel_expression ;
rel_expression : simple_expression ;
simple_expression : term 
                  | simple_expression ADDOP term {
                    BinaryOpNode* node = new BinaryOpNode($2->getname(), (ExprNode*)$1->get_ast_node(), (ExprNode*)$3->get_ast_node(), "int");
                    $$ = new symbol_info("add", "expr"); $$->set_ast_node(node);
                  } ;

term : factor ;
factor : variable { $$ = $1; }
       | ID LPAREN argument_list RPAREN {
            FuncCallNode* node = new FuncCallNode($1->getname(), "int");
            if($3 && $3->get_ast_node()) {
                ArgumentsNode* args = (ArgumentsNode*)$3->get_ast_node();
                for(auto a : args->get_arguments()) node->add_argument(a);
            }
            $$ = new symbol_info("call", "expr"); $$->set_ast_node(node);
       }
       | CONST_INT { $$ = $1; $$->set_ast_node(new ConstNode($1->getname(), "int")); }
       | CONST_FLOAT { $$ = $1; $$->set_ast_node(new ConstNode($1->getname(), "float")); } ;

argument_list : arguments { $$ = $1; } | { ArgumentsNode* node = new ArgumentsNode(); $$ = new symbol_info("args", "args"); $$->set_ast_node(node); } ;
arguments : arguments COMMA expression {
                ArgumentsNode* node = (ArgumentsNode*)$1->get_ast_node();
                node->add_argument((ExprNode*)$3->get_ast_node());
                $$ = $1;
          }
          | expression {
                ArgumentsNode* node = new ArgumentsNode();
                node->add_argument((ExprNode*)$1->get_ast_node());
                $$ = new symbol_info("args", "args"); $$->set_ast_node(node);
          } ;

%%

void yyerror(char *s) {
    outlog << "Error at line " << lines << ": " << s << endl;
    outerror << "Error at line " << lines << ": " << s << endl;
    errors++;
}

int main(int argc, char *argv[]) {
    if(argc < 2) return 1;
    yyin = fopen(argv[1], "r");
    outlog.open("log.txt"); outerror.open("error.txt"); outcode.open("code.txt");
    symtbl->enter_scope(outlog);
    yyparse();
    if(ast_root && errors == 0) {
        ThreeAddrCodeGenerator tacGen(ast_root, outcode);
        tacGen.generate();
    }
    outlog << "Total lines: " << lines << "\nTotal errors: " << errors << endl;
    outlog.close(); outerror.close(); outcode.close();
    return 0;
}
