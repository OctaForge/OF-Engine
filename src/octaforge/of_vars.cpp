#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"
#ifdef CLIENT
    #include "client_system.h"
    #include "targeting.h"
#endif

namespace varsys
{
    Variable_Map *variables = NULL;
    bool persistvars = true, overridevars = false, changed = false;

    int reg_ivar(
        const char *name, int min_v, int def_v, int max_v,
        int *storage, void (*callback)(), int flags
    )
    {
        Int_Variable *nvar = new Int_Variable(
            name, min_v, def_v, max_v, storage, callback, flags
        );
        reg_var(name, nvar);
        return *storage;
    }

    float reg_fvar(
        const char *name, float min_v, float def_v, float max_v,
        float *storage, void (*callback)(), int flags
    )
    {
        Float_Variable *nvar = new Float_Variable(
            name, min_v, def_v, max_v, storage, callback, flags
        );
        reg_var(name, nvar);
        return *storage;
    }

    char *reg_svar(
        const char *name, const char *def_v,
        char **storage, void (*callback)(), int flags
    )
    {
        String_Variable *nvar = new String_Variable(
            name, def_v, storage, callback, flags
        );
        reg_var(name, nvar);
        return *storage;
    }

    Variable *reg_var(const char *name, Variable *v)
    {
        if (!variables) variables = new Variable_Map;
        variables->insert(name, v);
        return v;
    }

    void clear()
    {
        if (!variables || variables->is_empty())
            return;

        Variable_Map *tmp = new Variable_Map;

        Variable_Map::it end(variables->end());

        for (Variable_Map::it it = variables->begin(); it != end; ++it)
        {
            if (!(it->second->flags()&FLAG_ALIAS))
            {
                it->second->reset();
                tmp->insert(*it);
            }
            else delete it->second;
        }

        delete variables;
        variables = tmp;
    }

    void flush()
    {
        if (variables)
        {
            Variable_Map::it end(variables->end());

            for (Variable_Map::it it = variables->begin(); it != end; ++it)
                delete it->second;

            delete variables;
        }
    }

    Variable *get(const char *name)
    {
        if (!variables || !name) return NULL;

        Variable_Map::cit it = variables->find(name);
        if (it != variables->end()) return it->second;
        else return NULL;
    }

    int get_int(Variable *v)
    {
        if (v->type () != TYPE_I) return 0;
        if (v->flags()&FLAG_ALIAS)
            return ((Int_Alias*)v)->get();
        return  ((Int_Variable*)v)->get();
    }

    float get_float(Variable *v)
    {
        if (v->type () != TYPE_F) return 0;
        if (v->flags()&FLAG_ALIAS)
            return ((Float_Alias*)v)->get();
        return  ((Float_Variable*)v)->get();
    }

    const char *get_string(Variable *v)
    {
        if (v->type () != TYPE_S) return 0;
        if (v->flags()&FLAG_ALIAS)
            return ((String_Alias*)v)->get();
        return  ((String_Variable*)v)->get();
    }

    void set(Variable *v, int val, bool call_cb, bool clamp)
    {
        if (v->type() != TYPE_I)
            return;

        if (v->flags()&FLAG_ALIAS)
            ((Int_Alias*)v)->set(val);
        else
            ((Int_Variable*)v)->set(val, call_cb, clamp);
    }

    void set(Variable *v, float val, bool call_cb, bool clamp)
    {
        if (v->type() != TYPE_F)
            return;

        if (v->flags()&FLAG_ALIAS)
            ((Float_Alias*)v)->set(val);
        else
            ((Float_Variable*)v)->set(val, call_cb, clamp);
    }

    void set(Variable *v, const char *val, bool call_cb)
    {
        if (v->type() != TYPE_S)
            return;

        if (v->flags()&FLAG_ALIAS)
            ((String_Alias*)v)->set(val);
        else
            ((String_Variable*)v)->set(val, call_cb);
    }

    void set(const char *name, int value, bool call_cb, bool clamp)
    {
        Variable *var = get(name);
        if (!var) return;
        set(var, value, call_cb, clamp);
    }

    void set(const char *name, float value, bool call_cb, bool clamp)
    {
        Variable *var = get(name);
        if (!var) return;
        set(var, value, call_cb, clamp);
    }

    void set(const char *name, const char *value, bool call_cb)
    {
        Variable *var = get(name);
        if (!var) return;
        set(var, value, call_cb);
    }
} /* end namespace varsystem */
