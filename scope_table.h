#include "symbol_info.h"
#include <iostream>
#include <fstream>
#include <string>

using namespace std;

class scope_table {
private:
    symbol_info** chains;
    int tbl_size;
    int num_chld = 0;
    int ID;
    scope_table *parent_scope = NULL;

    int hash_func(string symbol) {
        int sum = 0;
        for (int i = 0; i < symbol.size(); i++) sum += (int)symbol[i];
        return sum % tbl_size;
    }

public:
    scope_table(int n, int ID) {
        tbl_size = n;
        chains = new symbol_info*[n];
        for(int i = 0; i < n; i++) chains[i] = NULL;
        this->ID = ID;
    }

    void set_prnt(scope_table *table) {
        parent_scope = table;
        if(parent_scope != NULL) parent_scope->incrs_chld();
    }

    scope_table* get_prnt() { return parent_scope; }
    void incrs_chld() { num_chld++; }
    int getID() { return ID; }

    symbol_info* Lookup_in_scope(string name) {
        int hash_val = hash_func(name);
        symbol_info *curr_sym = chains[hash_val];
        while(curr_sym != NULL) {
            if (curr_sym->getname() == name) return curr_sym;
            curr_sym = curr_sym->get_next();
        }
        return NULL;
    }

    bool Insert_in_scope(string name, string type) {
        int hash_val = hash_func(name);
        if (Lookup_in_scope(name)) return false;
        symbol_info *new_sym = new symbol_info(name, type);
        new_sym->set_next(chains[hash_val]);
        chains[hash_val] = new_sym;
        return true;
    }

    // Changed from ofstream& to ostream& to fix macOS compilation error
    void Print_scope(ostream& outlog) {
        outlog << "ScopeTable # " << ID << endl;
        for(int i = 0; i < tbl_size; i++) {
            symbol_info *curr_sym = chains[i];
            if(curr_sym) {
                outlog << i << " --> ";
                while(curr_sym) {
                    outlog << "< " << curr_sym->getname() << " : " << curr_sym->gettype() << " > ";
                    curr_sym = curr_sym->get_next();
                }
                outlog << endl;
            }
        }
    }

    ~scope_table() {
        for(int i = 0; i < tbl_size; i++) {
            symbol_info *curr = chains[i];
            while(curr) {
                symbol_info *tmp = curr;
                curr = curr->get_next();
                delete tmp;
            }
        }
        delete[] chains;
    }
};
