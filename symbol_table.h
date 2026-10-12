#include "scope_table.h"

class symbol_table {
private:
    scope_table *curr_scope = NULL;
    int scope_size = 10;
    int ID = 0;

public:
    void enter_scope(ostream& outlog) {
        ID++;
        scope_table *new_scope = new scope_table(scope_size, ID);
        new_scope->set_prnt(curr_scope);
        curr_scope = new_scope;
        outlog << "New ScopeTable with ID " << curr_scope->getID() << " created" << endl << endl;
    }

    void exit_scope(ostream& outlog) {
        outlog << "Scopetable with ID " << curr_scope->getID() << " removed" << endl << endl;
        scope_table *tmp = curr_scope;
        curr_scope = curr_scope->get_prnt();
        delete tmp;
    }

    bool Insert_in_table(string name, string type) {
        return curr_scope->Insert_in_scope(name, type);
    }

    symbol_info* Lookup_in_table(string name) {
        scope_table *tmp = curr_scope;
        while(tmp) {
            symbol_info *s = tmp->Lookup_in_scope(name);
            if(s) return s;
            tmp = tmp->get_prnt();
        }
        return NULL;
    }

    void Print_all_scope(ostream& outlog) {
        scope_table *tmp = curr_scope;
        while(tmp) {
            tmp->Print_scope(outlog);
            tmp = tmp->get_prnt();
        }
    }

    ~symbol_table() { while(curr_scope) { scope_table *tmp = curr_scope; curr_scope = curr_scope->get_prnt(); delete tmp; } }
};
