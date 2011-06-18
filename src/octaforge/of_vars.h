/*
 * of_vars.h, version 1
 * Header file for engine varsystem
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#ifndef OF_VARS_H
#define OF_VARS_H

namespace var
{
    enum
    {
        VAR_I = 0,
        VAR_F,
        VAR_S
    };

    enum
    {
        VAR_PERSIST = 1 << 0,
        VAR_OVERRIDE = 1 << 1,
        VAR_HEX = 1 << 2,
        VAR_READONLY = 1 << 3,
        VAR_OVERRIDEN = 1 << 4,
        VAR_ALIAS = 1 << 5
    };

    struct cvar
    {
        cvar(
            const char *n,
            int min,
            int cur,
            int max,
            int *&stor,
            void (*fun)(),
            int fl
        );
        cvar(
            const char *n,
            float min,
            float cur,
            float max,
            float *&stor,
            void (*fun)(),
            int fl
        );
        cvar(
            const char *n,
            const char *cur,
            char **&stor,
            void (*fun)(),
            int fl
        );
        cvar(
            const char *n,
            int v,
            bool temporary = false
        );
        cvar(
            const char *n,
            float v,
            bool temporary = false
        );
        cvar(
            const char *n,
            const char *v,
            bool temporary = false
        );
        ~cvar();

        void set(int v, bool dofun = false, bool _clamp = true);
        void set(float v, bool dofun = false, bool _clamp = true);
        void set(const char *v, bool dofun = false);

        void reset();

        const char *name;
        int type;
        int flags;

        union gval_t
        {
            int i;
            float f;
            char *s;
        };
        gval_t oldv, curv;

        union nsval_t
        {
            int i;
            float f;
        };
        nsval_t minv, maxv;

        void (*vfun)();
    };

    typedef hashtable<const char*, cvar*> vartable;

    extern vartable *vars;
    extern bool persistvars, overridevars;

    int&   regivar(const char *name, int minv, int curv, int maxv, int *stor, void (*fun)(), int flags);
    float& regfvar(const char *name, float minv, float curv, float maxv, float *stor, void (*fun)(), int flags);
    char *&regsvar(const char *name, const char *curv, char **stor, void (*fun)(), int flags);
    cvar  *regvar (const char *name, var::cvar *var);

    void clear();
    void flush();
    cvar *get(const char *name);
} /* end namespace var */

#define _VAR(name, global, min, cur, max, flags)  int &global = var::regivar(#name, min, cur, max, &global, NULL, flags)
#define VARN(name, global, min, cur, max) _VAR(name, global, min, cur, max, 0)
#define VARNP(name, global, min, cur, max) _VAR(name, global, min, cur, max, var::VAR_PERSIST)
#define VARNR(name, global, min, cur, max) _VAR(name, global, min, cur, max, var::VAR_OVERRIDE)
#define VAR(name, min, cur, max) _VAR(name, name, min, cur, max, 0)
#define VARP(name, min, cur, max) _VAR(name, name, min, cur, max, var::VAR_PERSIST)
#define VARR(name, min, cur, max) _VAR(name, name, min, cur, max, var::VAR_OVERRIDE)
#define _VARF(name, global, min, cur, max, body, flags)  void var_##name(); int &global = var::regivar(#name, min, cur, max, &global, var_##name, flags); void var_##name() { body; }
#define VARFN(name, global, min, cur, max, body) _VARF(name, global, min, cur, max, body, 0)
#define VARF(name, min, cur, max, body) _VARF(name, name, min, cur, max, body, 0)
#define VARFP(name, min, cur, max, body) _VARF(name, name, min, cur, max, body, var::VAR_PERSIST)
#define VARFR(name, min, cur, max, body) _VARF(name, name, min, cur, max, body, var::VAR_OVERRIDE)

#define _HVAR(name, global, min, cur, max, flags)  int &global = var::regivar(#name, min, cur, max, &global, NULL, var::VAR_HEX | flags)
#define HVARN(name, global, min, cur, max) _HVAR(name, global, min, cur, max, 0)
#define HVARNP(name, global, min, cur, max) _HVAR(name, global, min, cur, max, var::VAR_PERSIST)
#define HVARNR(name, global, min, cur, max) _HVAR(name, global, min, cur, max, var::VAR_OVERRIDE)
#define HVAR(name, min, cur, max) _HVAR(name, name, min, cur, max, 0)
#define HVARP(name, min, cur, max) _HVAR(name, name, min, cur, max, var::VAR_PERSIST)
#define HVARR(name, min, cur, max) _HVAR(name, name, min, cur, max, var::VAR_OVERRIDE)
#define _HVARF(name, global, min, cur, max, body, flags)  void var_##name(); int &global = var::regivar(#name, min, cur, max, &global, var_##name, var::VAR_HEX | flags); void var_##name() { body; }
#define HVARFN(name, global, min, cur, max, body) _HVARF(name, global, min, cur, max, body, 0)
#define HVARF(name, min, cur, max, body) _HVARF(name, name, min, cur, max, body, 0)
#define HVARFP(name, min, cur, max, body) _HVARF(name, name, min, cur, max, body, var::VAR_PERSIST)
#define HVARFR(name, min, cur, max, body) _HVARF(name, name, min, cur, max, body, var::VAR_OVERRIDE)

#define _FVAR(name, global, min, cur, max, flags)  float &global = var::regfvar(#name, min, cur, max, &global, NULL, flags)
#define FVARN(name, global, min, cur, max) _FVAR(name, global, min, cur, max, 0)
#define FVARNP(name, global, min, cur, max) _FVAR(name, global, min, cur, max, var::VAR_PERSIST)
#define FVARNR(name, global, min, cur, max) _FVAR(name, global, min, cur, max, var::VAR_OVERRIDE)
#define FVAR(name, min, cur, max) _FVAR(name, name, min, cur, max, 0)
#define FVARP(name, min, cur, max) _FVAR(name, name, min, cur, max, var::VAR_PERSIST)
#define FVARR(name, min, cur, max) _FVAR(name, name, min, cur, max, var::VAR_OVERRIDE)
#define _FVARF(name, global, min, cur, max, body, flags)  void var_##name(); float &global = var::regfvar(#name, min, cur, max, &global, var_##name, flags); void var_##name() { body; }
#define FVARFN(name, global, min, cur, max, body) _FVARF(name, global, min, cur, max, body, 0)
#define FVARF(name, min, cur, max, body) _FVARF(name, name, min, cur, max, body, 0)
#define FVARFP(name, min, cur, max, body) _FVARF(name, name, min, cur, max, body, var::VAR_PERSIST)
#define FVARFR(name, min, cur, max, body) _FVARF(name, name, min, cur, max, body, var::VAR_OVERRIDE)

#define _SVAR(name, global, cur, flags)  char *&global = var::regsvar(#name, cur, &global, NULL, flags)
#define SVARN(name, global, cur) _SVAR(name, global, cur, 0)
#define SVARNP(name, global, cur) _SVAR(name, global, cur, var::VAR_PERSIST)
#define SVARNR(name, global, cur) _SVAR(name, global, cur, var::VAR_OVERRIDE)
#define SVAR(name, cur) _SVAR(name, name, cur, 0)
#define SVARP(name, cur) _SVAR(name, name, cur, var::VAR_PERSIST)
#define SVARR(name, cur) _SVAR(name, name, cur, var::VAR_OVERRIDE)
#define _SVARF(name, global, cur, body, flags)  void var_##name(); char *&global = var::regsvar(#name, cur, &global, var_##name, flags); void var_##name() { body; }
#define SVARFN(name, global, cur, body) _SVARF(name, global, cur, body, 0)
#define SVARF(name, cur, body) _SVARF(name, name, cur, body, 0)
#define SVARFP(name, cur, body) _SVARF(name, name, cur, body, var::VAR_PERSIST)
#define SVARFR(name, cur, body) _SVARF(name, name, cur, body, var::VAR_OVERRIDE)

#define SETV(name, val) var::get(#name)->set(val)
#define SETVF(name, val) var::get(#name)->set(val, true)
#define SETVFN(name, val) var::get(#name)->set(val, true, false)

#endif
