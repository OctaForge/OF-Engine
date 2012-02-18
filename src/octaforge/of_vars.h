#ifndef OF_VARS_H
#define OF_VARS_H

namespace varsys
{
    enum
    {
        TYPE_N = -1,
        TYPE_I =  0,
        TYPE_F =  1,
        TYPE_S =  2
    };

    enum
    {
        FLAG_PERSIST   = 1 << 0,
        FLAG_OVERRIDE  = 1 << 1,
        FLAG_HEX       = 1 << 2,
        FLAG_READONLY  = 1 << 3,
        FLAG_OVERRIDEN = 1 << 4,
        FLAG_ALIAS     = 1 << 5
    };

    extern bool persistvars, overridevars, changed;

    struct Variable
    {
        Variable(const char *name, void (*callback)(), int flags):
            p_name(name), p_flags(flags), p_callback(callback) {}

        virtual ~Variable() {}

        virtual int type() { return TYPE_N;  }
        const char *name() { return p_name;  }
        int        flags() { return p_flags; }

        virtual void reset()
        {
            if (!(Variable::p_flags&FLAG_OVERRIDEN))
                return;

            p_flags ^= FLAG_OVERRIDEN;
        }

    protected:

        const char *p_name;
        int         p_flags;

        void (*p_callback)();
    };

    struct Int_Variable: Variable
    {
        Int_Variable(
            const char *name, int min_v, int def_v, int max_v,
            int *storage, void (*callback)(), int flags
        ): Variable(name, callback, flags)
        {
            if (min_v > max_v)
            {
                Variable::p_flags |= FLAG_READONLY;
                p_min_value = max_v;
                p_max_value = min_v;
            }
            else
            {
                p_min_value = min_v;
                p_max_value = max_v;
            }

             p_value = storage;
            *p_value = p_old_value = def_v;
        }

        int type   () { return TYPE_I;      }
        int get    () { return *p_value;    }
        int get_min() { return p_min_value; }
        int get_max() { return p_max_value; }

        void set(int value, bool call_cb, bool clamp_value)
        {
            if ((Variable::p_flags&FLAG_OVERRIDE) || overridevars)
            {
                Variable::p_flags |= FLAG_OVERRIDEN;
                p_old_value = *p_value;
            }

            if (clamp_value && (value < p_min_value || value > p_max_value))
            {
                logger::log(
                    logger::ERROR,
                    "Variable %s only accepts values of range %d to %d.\n",
                    Variable::p_name, p_min_value, p_max_value
                );
                *p_value = clamp(value, p_min_value, p_max_value);
            }
            else *p_value = value;

            if (Variable::p_callback && call_cb)
                Variable::p_callback();

            changed = true;
        }

        void reset()
        {
            if (!(Variable::p_flags&FLAG_OVERRIDEN))
                return;

            *p_value = p_old_value;

            Variable::reset();
        }

    private:

        int  p_min_value, p_max_value, p_old_value;
        int *p_value;
    };

    struct Float_Variable: Variable
    {
        Float_Variable(
            const char *name, float min_v, float def_v, float max_v,
            float *storage, void (*callback)(), int flags
        ): Variable(name, callback, flags)
        {
            if (min_v > max_v)
            {
                Variable::p_flags |= FLAG_READONLY;
                p_min_value = max_v;
                p_max_value = min_v;
            }
            else
            {
                p_min_value = min_v;
                p_max_value = max_v;
            }

             p_value = storage;
            *p_value = p_old_value = def_v;
        }

        int type     () { return TYPE_F;      }
        float get    () { return *p_value;    }
        float get_min() { return p_min_value; }
        float get_max() { return p_max_value; }

        void set(float value, bool call_cb, bool clamp_value)
        {
            if ((Variable::p_flags&FLAG_OVERRIDE) || overridevars)
            {
                Variable::p_flags |= FLAG_OVERRIDEN;
                p_old_value = *p_value;
            }

            if (clamp_value && (value < p_min_value || value > p_max_value))
            {
                logger::log(
                    logger::ERROR,
                    "Variable %s only accepts values of range %f to %f.\n",
                    Variable::p_name, p_min_value, p_max_value
                );
                *p_value = clamp(value, p_min_value, p_max_value);
            }
            else *p_value = value;

            if (Variable::p_callback && call_cb)
                Variable::p_callback();

            changed = true;
        }

        void reset()
        {
            if (!(Variable::p_flags&FLAG_OVERRIDEN))
                return;

            *p_value = p_old_value;

            Variable::reset();
        }

    private:

        float  p_min_value, p_max_value, p_old_value;
        float *p_value;
    };

    struct String_Variable: Variable
    {
        String_Variable(
            const char *name, const char *def_v,
            char **storage, void (*callback)(), int flags
        ): Variable(name, callback, flags)
        {
            p_value = storage;

            *p_value = p_old_value = NULL;
            if (def_v)
            {
                *p_value    = newstring(def_v);
                p_old_value = newstring(def_v);
            }
        }

        ~String_Variable()
        {
            delete[] *p_value;
            delete[]  p_old_value;
        }

        int type       () { return TYPE_S; }
        const char *get() { return *p_value; }

        void set(const char *value, bool call_cb)
        {
            if ((Variable::p_flags&FLAG_OVERRIDE) || overridevars)
            {
                Variable::p_flags |= FLAG_OVERRIDEN;
                delete[] p_old_value;
                p_old_value = (*p_value ? newstring(*p_value) : NULL);
            }

            delete[] *p_value;
            *p_value = (value ? newstring(value) : NULL);

            if (Variable::p_callback && call_cb)
                Variable::p_callback();

            changed = true;
        }

        void reset()
        {
            if (!(Variable::p_flags&FLAG_OVERRIDEN))
                return;

            delete[] *p_value;
            *p_value = (p_old_value ? newstring(p_old_value) : NULL);

            Variable::reset();
        }

    private:

        char  *p_old_value;
        char **p_value;
    };

    struct Int_Alias: Variable
    {
        Int_Alias(const char *name, int value):
            Variable(name, NULL, FLAG_ALIAS), p_value(value)
        {
            if (persistvars) Variable::p_flags |= FLAG_PERSIST;
        }

        int type() { return TYPE_I;  }
        int get () { return p_value; }

        void set(int value)
        {
            if ((Variable::p_flags &  FLAG_PERSIST) && !persistvars)
                 Variable::p_flags ^= FLAG_PERSIST;

            p_value = value;
            changed = true;
        }

    private:

        int p_value;
    };

    struct Float_Alias: Variable
    {
        Float_Alias(const char *name, float value):
            Variable(name, NULL, FLAG_ALIAS), p_value(value)
        {
            if (persistvars) Variable::p_flags |= FLAG_PERSIST;
        }

        int  type() { return TYPE_F;  }
        float get() { return p_value; }

        void set(float value)
        {
            if ((Variable::p_flags &  FLAG_PERSIST) && !persistvars)
                 Variable::p_flags ^= FLAG_PERSIST;

            p_value = value;
            changed = true;
        }

    private:

        float p_value;
    };

    struct String_Alias: Variable
    {
        String_Alias(const char *name, const char *value):
            Variable(name, NULL, FLAG_ALIAS),
            p_value(value ? newstring(value) : NULL)
        {
            if (persistvars) Variable::p_flags |= FLAG_PERSIST;
        }

        ~String_Alias()
        {
            delete[] p_value;
        }

        int        type() { return TYPE_S;  }
        const char *get() { return p_value; }

        void set(const char *value)
        {
            if ((Variable::p_flags &  FLAG_PERSIST) && !persistvars)
                 Variable::p_flags ^= FLAG_PERSIST;

            delete[] p_value;
            p_value = (value ? newstring(value) : NULL);
            changed = true;
        }

    private:

        char *p_value;
    };

    typedef types::Map<const char*, Variable*> Variable_Map;
    extern Variable_Map *variables;

    int reg_ivar(
        const char *name, int min_v, int def_v, int max_v,
        int *storage, void (*callback)(), int flags
    );

    float reg_fvar(
        const char *name, float min_v, float def_v, float max_v,
        float *storage, void (*callback)(), int flags
    );

    char *reg_svar(
        const char *name, const char *def_v,
        char **storage, void (*callback)(), int flags
    );

    Variable *reg_var(const char *name, Variable *var);

    void clear();
    void flush();

    Variable *get(const char *name);

    int         get_int   (Variable *v);
    float       get_float (Variable *v);
    const char *get_string(Variable *v);

    void set(Variable *v, int   val, bool call_cb = false, bool clamp = true);
    void set(Variable *v, float val, bool call_cb = false, bool clamp = true);
    void set(Variable *v, const char *val, bool call_cb = false);

    void set(
        const char *name, int value, bool call_cb = false, bool clamp = true
    );

    void set(
        const char *name, float value, bool call_cb = false, bool clamp = true
    );

    void set(const char *name, const char *value, bool call_cb = false);

} /* end namespace varsystem */

#define _VAR(name, global, min, cur, max, flags) \
    int global = varsys::reg_ivar(#name, min, cur, max, &global, NULL, flags);

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
    int global = varsys::reg_ivar(#name, min, cur, max, &global, \
        var_##name, flags \
    ); \
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
    int global = varsys::reg_ivar(#name, min, cur, max, &global, NULL, \
        varsys::FLAG_HEX | flags \
    );

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
    int global = varsys::reg_ivar(#name, min, cur, max, &global, \
        var_##name, varsys::FLAG_HEX | flags \
    ); \
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
    float global = varsys::reg_fvar(#name, min, cur, max, &global, \
        NULL, flags \
    );

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
    float global = varsys::reg_fvar(#name, min, cur, max, &global, \
        var_##name, flags \
    ); \
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
    char *global = varsys::reg_svar(#name, cur, &global, NULL, flags);

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
    char *global = varsys::reg_svar(#name, cur, &global, var_##name, flags); \
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
