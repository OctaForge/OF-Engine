/*
 * variable_system.cpp, version 1
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

/*
 * ENGINE INCLUDES
 */

#include "cube.h"
#include "engine.h"
#include "game.h"

/*
 * CUBECREATE INCLUDES
 */

#include "world_system.h"
#include "message_system.h"
#ifdef CLIENT
    #include "client_system.h"
    #include "targeting.h"
#endif

// declare the variables
#ifdef _EV_NODEF
#undef _EV_NODEF
#endif
#ifdef DEFVAR
#undef DEFVAR
#endif
#define DEFVAR(name) cvar *_EV_##name = NULL;
#include "variable_system_proto.hpp"

namespace var
{
    /*
     * ENGINE VARIABLE
     */

    cvar::cvar(
        const char *vname,
        int minvi,
        int curvi,
        int maxvi,
        void (*cb)(int),
        bool persist,
        bool overridable
    ) : persistent(persist),
        name(vname),
        type(VAR_I),
        override(overridable),
        overriden(false),
        alias(false)
    {
        vcb.i = cb;
        if (minvi > maxvi)
        {
            readonly = true;
            oldv.i = curvi; minv.i = maxvi; curv.i = curvi; maxv.i = minvi;
        }
        else
        {
            readonly = false;
            oldv.i = curvi; minv.i = minvi; curv.i = curvi; maxv.i = maxvi;
        }
        hascb = cb ? true : false;
    }

    cvar::cvar(
        const char *vname,
        float minvf,
        float curvf,
        float maxvf,
        void (*cb)(float),
        bool persist,
        bool overridable
    ) : persistent(persist),
        name(vname),
        type(VAR_F),
        override(overridable),
        overriden(false),
        alias(false)
    {
        vcb.f = cb;
        if (minvf > maxvf)
        {
            readonly = true;
            oldv.f = curvf; minv.f = maxvf; curv.f = curvf; maxv.f = minvf;
        }
        else
        {
            readonly = false;
            oldv.f = curvf; minv.f = minvf; curv.f = curvf; maxv.f = maxvf;
        }
        hascb = cb ? true : false;
    }

    cvar::cvar(
        const char *vname,
        const char *curvs,
        void (*cb)(const char*),
        bool persist,
        bool overridable
    ) : persistent(persist),
        name(vname),
        type(VAR_S),
        readonly(false),
        override(overridable),
        overriden(false),
        alias(false)
    {
        vcb.s = cb; hascb = cb ? true : false;
        curv.s = (curvs ? newstring(curvs) : NULL);
        oldv.s = (curvs ? newstring(curvs) : NULL);
    }

    cvar::cvar(
        const char *aname,
        int val
    ) : hascb(false),
        name(aname),
        type(VAR_I),
        readonly(false),
        override(false),
        overriden(false),
        alias(true)
    {
        persistent = persistvars;
        vcb.i = NULL;
        minv.i = maxv.i = -1;
        curv.i = val; oldv.i = 0;
    }

    cvar::cvar(
        const char *aname,
        float val
    ) : hascb(false),
        name(aname),
        type(VAR_F),
        readonly(false),
        override(false),
        overriden(false),
        alias(true)
    {
        persistent = persistvars;
        vcb.f = NULL;
        minv.f = maxv.f = -1.0f;
        curv.f = val; oldv.f = 0.0f;
    }

    cvar::cvar(
        const char *aname,
        const char *val
    ) : hascb(false),
        name(aname),
        type(VAR_S),
        readonly(false),
        override(false),
        overriden(false),
        alias(true)
    {
        persistent = persistvars;
        vcb.s = NULL;
        curv.s = (val ? newstring(val) : NULL);
        oldv.s = NULL;
    }

    cvar::~cvar() { if (type == VAR_S) { DELETEA(curv.s); DELETEA(oldv.s); } }

    const char *cvar::gn()   { return name;   }
    int         cvar::gt()   { return type;   }
    int         cvar::gi()   { return curv.i; }
    int         cvar::gmni() { return minv.i; }
    int         cvar::gmxi() { return maxv.i; }
    float       cvar::gf()   { return curv.f; }
    float       cvar::gmnf() { return minv.f; }
    float       cvar::gmxf() { return maxv.f; }
    const char *cvar::gs()   { return curv.s; }

    void cvar::s(int val, bool forcecb, bool doclamp)
    {
        if (override || overridevars)
        {
            overriden = true;
            oldv.i = curv.i;
        }
        if (doclamp && (val < minv.i || val > maxv.i) && !alias)
        {
            Logging::log(
                Logging::ERROR,
                "Variable %s only accepts values of range %i to %i.\n",
                name, minv.i, maxv.i
            );
            curv.i = clamp(val, minv.i, maxv.i);
        }
        else curv.i = val;
        callcb(forcecb);
    }

    void cvar::s(float val, bool forcecb, bool doclamp)
    {
        if (override || overridevars)
        {
            overriden = true;
            oldv.f = curv.f;
        }
        if (doclamp && (val < minv.f || val > maxv.f) && !alias)
        {
            Logging::log(
                Logging::ERROR,
                "Variable %s only accepts values of range %f to %f.\n",
                name, minv.f, maxv.f
            );
            curv.f = clamp(val, minv.f, maxv.f);
        }
        else curv.f = val;
        callcb(forcecb);
    }

    void cvar::s(const char *val, bool forcecb, bool doclamp)
    {
        (void)doclamp;
        if (override || overridevars)
        {
            overriden = true;
            if (oldv.s) DELETEA(oldv.s);
            oldv.s = (curv.s ? newstring(curv.s) : NULL);
        }
        curv.s = (val ? newstring(val) : NULL);
        callcb(forcecb);
    }

    void cvar::r()
    {
        if (!overriden) return;
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
        overriden = false;
        callcb(false);
    }

    bool cvar::ispersistent()  { return persistent; }
    bool cvar::isreadonly()    { return readonly;   }
    bool cvar::isoverridable() { return override;   }
    bool cvar::isoverriden()   { return overriden;  }
    bool cvar::isalias()       { return alias;      }

    /*
     * PRIVATES
     */

    void cvar::callcb(bool forcecb)
    {
        switch (type)
        {
            case VAR_I:
            {
                if (hascb && forcecb && !alias) vcb.i(curv.i);
                break;
            }
            case VAR_F:
            {
                if (hascb && forcecb && !alias) vcb.f(curv.f);
                break;
            }
            case VAR_S:
            {
                if (hascb && forcecb && !alias) vcb.s(curv.s);
                break;
            }
            default: break;
        }
    }

    /*
     * STORAGE FOR VARIABLES
     */

    vartable *vars = NULL;
    bool persistvars = true, overridevars = false;

    cvar *reg(const char *name, cvar *var)
    {
        if (!vars) vars = new vartable;
        vars->access(name, var);
        return var;
    }

    void fill()
    {
        #include "variable_system_def.hpp"
    }

    void clear()
    {
        if (!vars) return;
        enumerate(*vars, cvar*, v, v->r(););
    }

    void flush()
    {
        if (vars)
        {
            enumerate(*vars,  cvar*, v, { if (v) delete v; });
            delete vars;
        }
    }

    cvar *get(const char *name) { if (vars && vars->access(name)) return *vars->access(name); else return NULL; }
}
// end namespace var
