/*
 * of_vars.cpp, version 1
 * Source file for engine varsystem
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

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"
#ifdef CLIENT
    #include "client_system.h"
    #include "targeting.h"
#endif

namespace var
{
    cvar::cvar(
        const char *n,
        int min,
        int cur,
        int max,
        int *&stor,
        void (*fun)(),
        int fl
    ) : name(n),
        type(VAR_I),
        flags(fl),
        vfun(fun)
    {
        if (min > max)
        {
            flags |= VAR_READONLY;
            minv.i = max;
            maxv.i = min;
        }
        else
        {
            minv.i = min;
            maxv.i = max;
        }
        oldv.i = curv.i = cur;
        stor = &curv.i;
    }

    cvar::cvar(
        const char *n,
        float min,
        float cur,
        float max,
        float *&stor,
        void (*fun)(),
        int fl
    ) : name(n),
        type(VAR_F),
        flags(fl),
        vfun(fun)
    {
        if (min > max)
        {
            flags |= VAR_READONLY;
            minv.f = max;
            maxv.f = min;
        }
        else
        {
            minv.f = min;
            maxv.f = max;
        }
        oldv.f = curv.f = cur;
        stor = &curv.f;
    }

    cvar::cvar(
        const char *n,
        const char *cur,
        char **&stor,
        void (*fun)(),
        int fl
    ) : name(n),
        type(VAR_S),
        flags(fl),
        vfun(fun)
    {
        curv.s = (cur ? newstring(cur) : NULL);
        oldv.s = (cur ? newstring(cur) : NULL);
        stor = &curv.s;
    }

    cvar::cvar(
        const char *n,
        int v
    ) : name(n),
        type(VAR_I),
        flags(0),
        vfun(NULL)
    {
        flags |= VAR_ALIAS;
        if (persistvars) flags |= VAR_PERSIST;

        minv.i = maxv.i = -1;
        oldv.i = curv.i = v;
    }

    cvar::cvar(
        const char *n,
        float v
    ) : name(n),
        type(VAR_F),
        flags(0),
        vfun(NULL)
    {
        flags |= VAR_ALIAS;
        if (persistvars) flags |= VAR_PERSIST;

        minv.f = maxv.f = -1.0f;
        oldv.f = curv.f = v;
    }

    cvar::cvar(
        const char *n,
        const char *v
    ) : name(n),
        type(VAR_S),
        flags(0),
        vfun(NULL)
    {
        flags |= VAR_ALIAS;
        if (persistvars) flags |= VAR_PERSIST;

        curv.s = (v ? newstring(v) : NULL);
        oldv.s = NULL;
    }

    cvar::~cvar()
    {
        if (type == VAR_S)
        {
            DELETEA(curv.s);
            DELETEA(oldv.s);
        }
    }

    void cvar::set(int v, bool dofun, bool _clamp)
    {
        if ((flags&VAR_OVERRIDE) || overridevars)
        {
            flags |= VAR_OVERRIDEN;
            oldv.i = curv.i;
        }

        if ((flags&VAR_ALIAS) && (flags&VAR_PERSIST) && !persistvars)
             flags ^= VAR_PERSIST;

        if (_clamp && (v < minv.i || v > maxv.i) && (flags&VAR_ALIAS) == 0)
        {
            logger::log(
                logger::ERROR,
                "Variable %s only accepts values of range %i to %i.\n",
                name, minv.i, maxv.i
            );
            curv.i = clamp(v, minv.i, maxv.i);
        }
        else curv.i = v;
        if (vfun && dofun) vfun();
    }

    void cvar::set(float v, bool dofun, bool _clamp)
    {
        if ((flags&VAR_OVERRIDE) || overridevars)
        {
            flags |= VAR_OVERRIDEN;
            oldv.f = curv.f;
        }

        if ((flags&VAR_ALIAS) && (flags&VAR_PERSIST) && !persistvars)
             flags ^= VAR_PERSIST;

        if (_clamp && (v < minv.f || v > maxv.f) && (flags&VAR_ALIAS) == 0)
        {
            logger::log(
                logger::ERROR,
                "Variable %s only accepts values of range %f to %f.\n",
                name, minv.f, maxv.f
            );
            curv.f = clamp(v, minv.f, maxv.f);
        }
        else curv.f = v;
        if (vfun && dofun) vfun();
    }

    void cvar::set(const char *v, bool dofun)
    {
        if ((flags&VAR_OVERRIDE) || overridevars)
        {
            flags |= VAR_OVERRIDEN;
            if (oldv.s) DELETEA(oldv.s);
            oldv.s = (curv.s ? newstring(curv.s) : NULL);
        }

        if ((flags&VAR_ALIAS) && (flags&VAR_PERSIST) && !persistvars)
             flags ^= VAR_PERSIST;

        curv.s = (v ? newstring(v) : NULL);
        if (vfun && dofun) vfun();
    }

    void cvar::reset()
    {
        if ((flags&VAR_OVERRIDEN) == 0) return;
        switch (type)
        {
            case VAR_I: curv.i = oldv.i; break;
            case VAR_F: curv.f = oldv.f; break;
            case VAR_S:
            {
                DELETEA(curv.s);
                curv.s = (oldv.s ? newstring(oldv.s) : NULL);
                break;
            }
            default: break;
        }
        flags ^= VAR_OVERRIDEN;
    }

    vartable *vars = NULL;
    bool persistvars = true, overridevars = false;

    int& regivar(const char *name, int minv, int curv, int maxv, int *stor, void (*fun)(), int flags)
    {
        var::cvar *nvar = new var::cvar(name, minv, curv, maxv, stor, fun, flags);
        regvar(name, nvar);
        return *stor;
    }

    float& regfvar(const char *name, float minv, float curv, float maxv, float *stor, void (*fun)(), int flags)
    {
        var::cvar *nvar = new var::cvar(name, minv, curv, maxv, stor, fun, flags);
        regvar(name, nvar);
        return *stor;
    }

    char *&regsvar(const char *name, const char *curv, char **stor, void (*fun)(), int flags)
    {
        var::cvar *nvar = new var::cvar(name, curv, stor, fun, flags);
        regvar(name, nvar);
        return *stor;
    }

    cvar *regvar(const char *name, var::cvar *var)
    {
        if (!vars) vars = new vartable;
        vars->access(name, var);
        return var;
    }

    void clear()
    {
        if (!vars) return;
        enumerate(*vars, cvar*, v, v->reset(););
    }

    void flush()
    {
        if (vars)
        {
            enumerate(*vars,  cvar*, v, { if (v) delete v; });
            delete vars;
        }
    }

    cvar *get(const char *name)
    {
        if (vars && vars->access(name))
            return *vars->access(name);
        else return NULL;
    }
} /* end namespace var */
