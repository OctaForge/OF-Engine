#ifndef OF_VARS_H
#define OF_VARS_H

namespace varsys
{
    enum {
        TYPE_I = 0,
        TYPE_F = 1,
        TYPE_S = 2
    };
    
    enum {
        FLAG_PERSIST   = 1 << 0,
        FLAG_OVERRIDE  = 1 << 1,
        FLAG_HEX       = 1 << 2,
        FLAG_READONLY  = 1 << 3,
        FLAG_OVERRIDEN = 1 << 4,
        FLAG_ALIAS     = 1 << 5
    };

    extern bool persistvars, overridevars, changed;

    /* common evar header */
    #define VAR_HDR \
        uchar       type;      \
        const char *name;      \
        int         flags;     \
        bool        emits;     \
        bool        has_value; \
        void      (*callback)();

    /* just the header, generic base var type */
    struct Variable {
        VAR_HDR;
    };

    struct Int_Variable {
        VAR_HDR;
    
        int min_v, def_v, max_v;
        union {
            int  i;
            int *p;
        } cur_v;
    };
    
    struct Float_Variable {
        VAR_HDR;
    
        float min_v, def_v, max_v;
        union {
            float  f;
            float *p;
        } cur_v;
    };
    
    struct String_Variable {
        VAR_HDR;
    
        char *def_v;
        union {
            char  *s;
            char **p;
        } cur_v;
    };
    
    struct Int_Alias {
        VAR_HDR;
        int cur_v;
    };
    
    struct Float_Alias {
        VAR_HDR;
        float cur_v;
    };
    
    struct String_Alias {
        VAR_HDR;
        char *cur_v;
    };

    typedef types::Map<char*, Variable*> Variable_Map;
    extern Variable_Map *variables;

    Int_Variable *new_int_full(const char *name, int flags,
        void (*cb)(), int *stor, int min, int def, int max);

    Float_Variable *new_float_full(const char *name, int flags,
        void (*cb)(), float *stor, float min, float def, float max);

    String_Variable *new_string_full(const char *name, int flags,
        void (*cb)(), char **stor, const char *def);

    Int_Alias    *new_int   (const char *name, int         val);
    Float_Alias  *new_float (const char *name, float       val);
    String_Alias *new_string(const char *name, const char *val);

    int reg_int(const char *name, int flags,
        void (*cb)(), int *stor, int min, int def, int max);

    float reg_float(const char *name, int flags,
        void (*cb)(), float *stor, float min, float def, float max);

    char *reg_string(const char *name, int flags,
        void (*cb)(), char **stor, const char *def);

    int   reg_int   (const char *name, int         val);
    float reg_float (const char *name, float       val);
    char *reg_string(const char *name, const char *val);

    Variable *reg_var(Variable *var);

    void destroy(Variable *var);

    void reset_i(Int_Variable    *var);
    void reset_f(Float_Variable  *var);
    void reset_s(String_Variable *var);

    void reset(Variable *var);

    void set(Variable *v, int val, bool call_cb = false,
        bool clamp_v = true);

    void set(Variable *v, float val, bool call_cb = false,
        bool clamp_v = true);

    void set(Variable *v, const char *val, bool call_cb = false);

    void set(const char *v, int val, bool call_cb = false,
        bool clamp_v = true);

    void set(const char *v, float val, bool call_cb = false,
        bool clamp_v = true);

    void set(const char *v, const char *val, bool call_cb = false);

    void clear();
    void flush();

    Variable *get(const char *name);

    int         get_int   (Variable *v);
    float       get_float (Variable *v);
    const char *get_string(Variable *v);
} /* end namespace varsys */

#define _VAR(name, global, min, cur, max, flags) \
    int global = varsys::reg_int(#name, flags, NULL, &global, \
        min, cur, max); \

#define VARN(name, global, min, cur, max) \
    _VAR(name, global, min, cur, max, 0)

#define VARNP(name, global, min, cur, max) \
    _VAR(name, global, min, cur, max, varsys::FLAG_PERSIST)

#define VARNR(name, global, min, cur, max) \
    _VAR(name, global, min, cur, max, varsys::FLAG_OVERRIDE)

#define VAR(name, min, cur, max) \
    _VAR(name, name, min, cur, max, 0)

#define VARP(name, min, cur, max) \
    _VAR(name, name, min, cur, max, varsys::FLAG_PERSIST)

#define VARR(name, min, cur, max) \
    _VAR(name, name, min, cur, max, varsys::FLAG_OVERRIDE)


#define _VARF(name, global, min, cur, max, body, flags) \
    void var_##name(); \
    int global = varsys::reg_int(#name, flags, var_##name, &global, \
        min, cur, max); \
    void var_##name() { body; }

#define VARFN(name, global, min, cur, max, body) \
    _VARF(name, global, min, cur, max, body, 0)

#define VARF(name, min, cur, max, body) \
    _VARF(name, name, min, cur, max, body, 0)

#define VARFP(name, min, cur, max, body) \
    _VARF(name, name, min, cur, max, body, varsys::FLAG_PERSIST)

#define VARFR(name, min, cur, max, body) \
    _VARF(name, name, min, cur, max, body, varsys::FLAG_OVERRIDE)


#define _HVAR(name, global, min, cur, max, flags) \
    int global = varsys::reg_int(#name, varsys::FLAG_HEX | flags, NULL, \
        &global, min, cur, max);

#define HVARN(name, global, min, cur, max) \
    _HVAR(name, global, min, cur, max, 0)

#define HVARNP(name, global, min, cur, max) \
    _HVAR(name, global, min, cur, max, varsys::FLAG_PERSIST)

#define HVARNR(name, global, min, cur, max) \
    _HVAR(name, global, min, cur, max, varsys::FLAG_OVERRIDE)

#define HVAR(name, min, cur, max) \
    _HVAR(name, name, min, cur, max, 0)

#define HVARP(name, min, cur, max) \
    _HVAR(name, name, min, cur, max, varsys::FLAG_PERSIST)

#define HVARR(name, min, cur, max) \
    _HVAR(name, name, min, cur, max, varsys::FLAG_OVERRIDE)


#define _HVARF(name, global, min, cur, max, body, flags) \
    void var_##name(); \
    int global = varsys::reg_int(#name, varsys::FLAG_HEX | flags, \
        var_##name, &global, min, cur, max); \
    void var_##name() { body; }

#define HVARFN(name, global, min, cur, max, body) \
    _HVARF(name, global, min, cur, max, body, 0)

#define HVARF(name, min, cur, max, body) \
    _HVARF(name, name, min, cur, max, body, 0)

#define HVARFP(name, min, cur, max, body) \
    _HVARF(name, name, min, cur, max, body, varsys::FLAG_PERSIST)

#define HVARFR(name, min, cur, max, body) \
    _HVARF(name, name, min, cur, max, body, varsys::FLAG_OVERRIDE)


#define _FVAR(name, global, min, cur, max, flags) \
    float global = varsys::reg_float(#name, flags, NULL, &global, \
        min, cur, max);

#define FVARN(name, global, min, cur, max) \
    _FVAR(name, global, min, cur, max, 0)

#define FVARNP(name, global, min, cur, max) \
    _FVAR(name, global, min, cur, max, varsys::FLAG_PERSIST)

#define FVARNR(name, global, min, cur, max) \
    _FVAR(name, global, min, cur, max, varsys::FLAG_OVERRIDE)

#define FVAR(name, min, cur, max) \
    _FVAR(name, name, min, cur, max, 0)

#define FVARP(name, min, cur, max) \
    _FVAR(name, name, min, cur, max, varsys::FLAG_PERSIST)

#define FVARR(name, min, cur, max) \
    _FVAR(name, name, min, cur, max, varsys::FLAG_OVERRIDE)


#define _FVARF(name, global, min, cur, max, body, flags) \
    void var_##name(); \
    float global = varsys::reg_float(#name, flags, var_##name, &global, \
        min, cur, max); \
    void var_##name() { body; }

#define FVARFN(name, global, min, cur, max, body) \
    _FVARF(name, global, min, cur, max, body, 0)

#define FVARF(name, min, cur, max, body) \
    _FVARF(name, name, min, cur, max, body, 0)

#define FVARFP(name, min, cur, max, body) \
    _FVARF(name, name, min, cur, max, body, varsys::FLAG_PERSIST)

#define FVARFR(name, min, cur, max, body) \
    _FVARF(name, name, min, cur, max, body, varsys::FLAG_OVERRIDE)


#define _SVAR(name, global, cur, flags) \
    char *global = varsys::reg_string(#name, flags, NULL, &global, cur);

#define SVARN(name, global, cur) \
    _SVAR(name, global, cur, 0)

#define SVARNP(name, global, cur) \
    _SVAR(name, global, cur, varsys::FLAG_PERSIST)

#define SVARNR(name, global, cur) \
    _SVAR(name, global, cur, varsys::FLAG_OVERRIDE)

#define SVAR(name, cur) \
    _SVAR(name, name, cur, 0)

#define SVARP(name, cur) \
    _SVAR(name, name, cur, varsys::FLAG_PERSIST)

#define SVARR(name, cur) \
    _SVAR(name, name, cur, varsys::FLAG_OVERRIDE)


#define _SVARF(name, global, cur, body, flags) \
    void var_##name(); \
    char *global = varsys::reg_string(#name, flags, var_##name, &global, \
        cur); \
    void var_##name() { body; }

#define SVARFN(name, global, cur, body) \
    _SVARF(name, global, cur, body, 0)

#define SVARF(name, cur, body) \
    _SVARF(name, name, cur, body, 0)

#define SVARFP(name, cur, body) \
    _SVARF(name, name, cur, body, varsys::FLAG_PERSIST)

#define SVARFR(name, cur, body) \
    _SVARF(name, name, cur, body, varsys::FLAG_OVERRIDE)

#define SETV(name, val) varsys::set(#name, val)
#define SETVF(name, val) varsys::set(#name, val, true)
#define SETVFN(name, val) varsys::set(#name, val, true, false)

#endif
