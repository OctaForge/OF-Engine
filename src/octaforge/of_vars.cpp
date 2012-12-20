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
    bool persistvars = false, overridevars = false, changed = false;

    #define VAR_INIT(v, t, vt, name, cb, fl) \
        t *v = new t;         \
        v->type      = vt;    \
        v->name      = name;  \
        v->flags     = fl;    \
        v->emits     = false; \
        v->has_value = true;  \
        v->callback = cb;

    Int_Variable *new_int_full(const char *name, int flags,
        void (*cb)(), int *stor, int min, int def, int max) {
        VAR_INIT(v, Int_Variable, TYPE_I, name, cb, flags);

        v->min_v = min;
        v->def_v = def;
        v->max_v = max;

        if (!stor) {
            v->cur_v.i    = def;
        } else {
            v->has_value  = false;
            v->cur_v.p    = stor;
            *(v->cur_v.p) = def;
        }

        return v;
    }

    Float_Variable *new_float_full(const char *name, int flags,
        void (*cb)(), float *stor, float min, float def, float max) {
        VAR_INIT(v, Float_Variable, TYPE_F, name, cb, flags);

        v->min_v = min;
        v->def_v = def;
        v->max_v = max;

        if (!stor) {
            v->cur_v.f    = def;
        } else {
            v->has_value  = false;
            v->cur_v.p    = stor;
            *(v->cur_v.p) = def;
        }

        return v;
    }

    String_Variable *new_string_full(const char *name, int flags,
        void (*cb)(), char **stor, const char *def) {
        VAR_INIT(v, String_Variable, TYPE_S, name, cb, flags);

        v->def_v = newstring(def);

        if (!stor) {
            v->cur_v.s    = newstring(def);
        } else {
            v->has_value  = false;
            v->cur_v.p    = stor;
            *(v->cur_v.p) = newstring(def);
        }

        return v;
    }

    Int_Alias *new_int(const char *name, int val) {
        VAR_INIT(v, Int_Alias, TYPE_I, name, NULL, FLAG_ALIAS);
        v->cur_v = val;
        return v;
    }

    Float_Alias *new_float(const char *name, float val) {
        VAR_INIT(v, Float_Alias, TYPE_F, name, NULL, FLAG_ALIAS);
        v->cur_v = val;
        return v;
    }

    String_Alias *new_string(const char *name, const char *val) {
        VAR_INIT(v, String_Alias, TYPE_S, name, NULL, FLAG_ALIAS);
        v->cur_v = newstring(val);
        return v;
    }

    int reg_int(const char *name, int flags, void (*cb)(), int *stor,
        int min, int def, int max) {
        Int_Variable *v = new_int_full(newstring(name), flags, cb, stor,
            min, def, max);

        reg_var((Variable*)v);
        return stor ? *stor : def;
    }

    float reg_float(const char *name, int flags, void (*cb)(), float *stor,
        float min, float def, float max) {
        Float_Variable *v = new_float_full(newstring(name), flags, cb, stor,
            min, def, max);

        reg_var((Variable*)v);
        return stor ? *stor : def;
    }

    char *reg_string(const char *name, int flags, void (*cb)(),
        char **stor, const char *def) {
        String_Variable *v = new_string_full(newstring(name), flags, cb,
            stor, def);

        reg_var((Variable*)v);
        return stor ? *stor : (char*)def;
    }

    int reg_int(const char *name, int val) {
        Int_Alias *v = new_int(newstring(name), val);

        reg_var((Variable*)v);
        return val;
    }

    float reg_float(const char *name, float val) {
        Float_Alias *v = new_float(newstring(name), val);

        reg_var((Variable*)v);
        return val;
    }

    char *reg_string(const char *name, const char *val) {
        String_Alias *v = new_string(newstring(name), val);

        reg_var((Variable*)v);
        return v->cur_v;
    }

    Variable *reg_var(Variable *var) {
        if (!variables) variables = new Variable_Map;
        variables->insert((char*)var->name, var);
        return var;
    }

    void destroy(Variable *var) {
        if (var->type == TYPE_S) {
            if (var->flags & FLAG_ALIAS) {
                String_Alias *s = (String_Alias*)var;
                delete[] s->cur_v;
            } else {
                String_Variable *s = (String_Variable*)var;
                delete[] s->def_v;
                if (s->has_value) {
                    delete[] s->cur_v.s;
                } else {
                    delete[] *(s->cur_v.p);
                }
            }
        }
    }

    void reset_i(Int_Variable *var) {
        if (var->has_value) {
            var->cur_v.i = var->def_v;
        } else {
            *(var->cur_v.p) = var->def_v;
        }
    }

    void reset_f(Float_Variable *var) {
        if (var->has_value) {
            var->cur_v.f = var->def_v;
        } else {
            *(var->cur_v.p) = var->def_v;
        }
    }

    void reset_s(String_Variable *var) {
        if (var->has_value) {
            delete[] var->cur_v.s;
            var->cur_v.s = var->def_v ? newstring(var->def_v) : NULL;
        } else {
            char **p = var->cur_v.p;
            delete[] *p;
            *p = var->def_v ? newstring(var->def_v) : NULL;
        }
    }

    void reset(Variable *var) {
        if (!((var->flags) & FLAG_OVERRIDEN) || ((var->flags) & FLAG_ALIAS))
            return;

        if (var->type == TYPE_I) {
            reset_i((Int_Variable*)var);
        } else if (var->type == TYPE_F) {
            reset_f((Float_Variable*)var);
        } else {
            reset_s((String_Variable*)var);
        }

        var->flags ^= FLAG_OVERRIDEN;
    }

    void set(Variable *v, int val, bool call_cb, bool clamp_v) {
        if (!v || v->type != TYPE_I) return;

        if ((v->flags) & FLAG_ALIAS) {
            Int_Alias *var = (Int_Alias*)v;
            var->cur_v     = val;
            changed        = true;
            return;
        }

        Int_Variable *var = (Int_Variable*)v;

        if (((var->flags) & FLAG_OVERRIDE) || overridevars) {
            var->flags |= FLAG_OVERRIDEN;
        }

        if (clamp_v && (val < var->min_v || val > var->max_v)) {
            logger::log(logger::ERROR,
                "Variable %s only accepts values of range %d to %d.\n",
                var->name, var->min_v, var->max_v);
            val = clamp(val, var->min_v, var->max_v);
        }
        if (var->has_value) {
            var->cur_v.i = val;
        } else {
            *(var->cur_v.p) = val;
        }

        if (var->callback && call_cb) {
            var->callback();
        }

        if (var->emits) {
            lapi::state.get<lua::Object>("signal", "emit").push();
            lua_getglobal  (lapi::state.state(), "EV");
            lua_pushstring (lapi::state.state(), var->name);
            lua_pushliteral(lapi::state.state(), "_changed");
            lua_concat     (lapi::state.state(), 2);
            lua_pushinteger(lapi::state.state(), val);
            lua_pushinteger(lapi::state.state(), var->min_v);
            lua_pushinteger(lapi::state.state(), var->def_v);
            lua_pushinteger(lapi::state.state(), var->max_v);
            lua_call       (lapi::state.state(), 6, 0);
        }

        changed = true;
    }

    void set(Variable *v, float val, bool call_cb, bool clamp_v) {
        if (!v || v->type != TYPE_F) return;

        if ((v->flags) & FLAG_ALIAS) {
            Float_Alias *var = (Float_Alias*)v;
            var->cur_v       = val;
            changed          = true;
            return;
        }

        Float_Variable *var = (Float_Variable*)v;

        if (((var->flags) & FLAG_OVERRIDE) || overridevars) {
            var->flags |= FLAG_OVERRIDEN;
        }

        if (clamp_v && (val < var->min_v || val > var->max_v)) {
            logger::log(logger::ERROR,
                "Variable %s only accepts values of range %f to %f.\n",
                var->name, var->min_v, var->max_v);
            val = clamp(val, var->min_v, var->max_v);
        }
        if (var->has_value) {
            var->cur_v.f = val;
        } else {
            *(var->cur_v.p) = val;
        }

        if (var->callback && call_cb) {
            var->callback();
        }

        if (var->emits) {
            lapi::state.get<lua::Object>("signal", "emit").push();
            lua_getglobal  (lapi::state.state(), "EV");
            lua_pushstring (lapi::state.state(), var->name);
            lua_pushliteral(lapi::state.state(), "_changed");
            lua_concat     (lapi::state.state(), 2);
            lua_pushnumber (lapi::state.state(), val);
            lua_pushnumber (lapi::state.state(), var->min_v);
            lua_pushnumber (lapi::state.state(), var->def_v);
            lua_pushnumber (lapi::state.state(), var->max_v);
            lua_call       (lapi::state.state(), 6, 0);
        }

        changed = true;
    }

    void set(Variable *v, const char *val, bool call_cb) {
        if (!v || v->type != TYPE_S) return;

        if ((v->flags) & FLAG_ALIAS) {
            String_Alias *var = (String_Alias*)v;
            delete[] var->cur_v;
            var->cur_v        = val ? newstring(val) : NULL;
            changed           = true;
            return;
        }

        String_Variable *var = (String_Variable*)v;

        if (((var->flags) & FLAG_OVERRIDE) || overridevars) {
            var->flags |= FLAG_OVERRIDEN;
        }

        if (var->has_value) {
            delete[] var->cur_v.s;
            var->cur_v.s = val ? newstring(val) : NULL;
        } else {
            char **s = var->cur_v.p;
            delete[] *s;
            *s = val ? newstring(val) : NULL;
        }

        if (var->callback && call_cb) {
            var->callback();
        }

        if (var->emits) {
            lapi::state.get<lua::Object>("signal", "emit").push();
            lua_getglobal  (lapi::state.state(), "EV");
            lua_pushstring (lapi::state.state(), var->name);
            lua_pushliteral(lapi::state.state(), "_changed");
            lua_concat     (lapi::state.state(), 2);
            lua_pushstring (lapi::state.state(), val);
            lua_pushstring (lapi::state.state(), var->def_v);
            lua_call       (lapi::state.state(), 4, 0);
        }

        changed = true;
    }

    void set(const char *v, int val, bool call_cb, bool clamp_v) {
        set(get(v), val, call_cb, clamp_v);
    }

    void set(const char *v, float val, bool call_cb, bool clamp_v) {
        set(get(v), val, call_cb, clamp_v);
    }

    void set(const char *v, const char *val, bool call_cb) {
        set(get(v), val, call_cb);
    }

    void clear() {
        if (!variables || variables->is_empty())
            return;

        Variable_Map *tmp = new Variable_Map;

        Variable_Map::it end(variables->end());

        for (Variable_Map::it it = variables->begin(); it != end; ++it) {
            if (!(it->second->flags & FLAG_ALIAS)) {
                reset(it->second);
                tmp->insert(it->first, it->second);
            } else {
                destroy(it->second);
                delete  it->first;
                delete  it->second;
            }
        }

        delete variables;
        variables = tmp;
    }

    void flush() {
        if (!variables) {
            return;
        }

        Variable_Map::it end(variables->end());
        for (Variable_Map::it it = variables->begin(); it != end; ++it) {
            destroy(it->second);
            delete  it->first;
            delete  it->second;
        }
        delete variables;
        variables = NULL;
    }

    Variable *get(const char *name) {
        if (!variables || !name) return NULL;

        Variable_Map::cit it = variables->find((char*)name);
        if (it != variables->end()) return it->second;
        else return NULL;
    }

    int get_int(Variable *v) {
        if (v->type != TYPE_I) return 0;
        if (v->flags & FLAG_ALIAS) {
            return ((Int_Alias*)v)->cur_v;
        }
        Int_Variable *var = (Int_Variable*)v;
        return var->has_value ? var->cur_v.i : *(var->cur_v.p);
    }

    float get_float(Variable *v) {
        if (v->type != TYPE_F) return 0.0f;
        if (v->flags & FLAG_ALIAS) {
            return ((Float_Alias*)v)->cur_v;
        }
        Float_Variable *var = (Float_Variable*)v;
        return var->has_value ? var->cur_v.f : *(var->cur_v.p);
    }

    const char *get_string(Variable *v) {
        if (v->type != TYPE_S) return NULL;
        if (v->flags & FLAG_ALIAS) {
            return ((String_Alias*)v)->cur_v;
        }
        String_Variable *var = (String_Variable*)v;
        return var->has_value ? var->cur_v.s : *(var->cur_v.p);
    }
} /* end namespace varsystem */
