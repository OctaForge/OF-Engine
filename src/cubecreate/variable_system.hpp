/*
 * variable_system.hpp, version 1
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

/**
 * @mainpage Engine Variables
 * 
 * @author q66 <quaker66@gmail.com>
 * @date 2011
 */

/**
 * @defgroup Engine_Variables_Group Engine Variables
 *
 * @{
 */

namespace var
{
    /// VAR_I, VAR_F and VAR_S represent types of engine variables (0, 1, 2)
    enum
    {
        VAR_I = 0,
        VAR_F,
        VAR_S
    };

    /**
     * @class cvar
     * Basic class representing engine variable.
     */
    class cvar
    {
    public:
        /**
         * Constructor for int variable.
         * Callback is a function taking one int argument.
         * @param vname Name of the variable.
         * @param minvi Minimal value of the variable.
         * @param curvi Default value of the variable.
         * @param maxvi Maximal value of the variable.
         * @param cb Optional callback called on value change.
         * @param persist Makes the variable persistent.
         * @param overridable Makes the variable overridable.
         */
        cvar(
            const char *vname,
            int minvi,
            int curvi,
            int maxvi,
            void (*cb)(int) = NULL,
            bool persist = false,
            bool overridable = false
        );
        /**
         * Constructor for float variable.
         * Callback is a function taking one float argument.
         * @param vname Name of the variable.
         * @param minvf Minimal value of the variable.
         * @param curvf Default value of the variable.
         * @param maxvf Maximal value of the variable.
         * @param cb Optional callback called on value change.
         * @param persist Makes the variable persistent.
         * @param overridable Makes the variable overridable.
         */
        cvar(
            const char *vname,
            float minvf,
            float curvf,
            float maxvf,
            void (*cb)(float) = NULL,
            bool persist = false,
            bool overridable = false
        );
        /**
         * Constructor for string variable.
         * Callback is a function taking one string argument.
         * @param vname Name of the variable.
         * @param curvs Default value of the variable.
         * @param cb Optional callback called on value change.
         * @param persist Makes the variable persistent.
         * @param overridable Makes the variable overridable.
         */
        cvar(
            const char *vname,
            const char *curvs,
            void (*cb)(const char*) = NULL,
            bool persist = false,
            bool overridable = false
        );
        /**
         * Constructor for int alias.
         * @param aname Name of the alias.
         * @param val Value of the alias.
         * @param reglua If true, register in lua immediately.
         */
        cvar(
            const char *aname,
            int val,
            bool reglua
        );
        /**
         * Constructor for float alias.
         * @param aname Name of the alias.
         * @param val Value of the alias.
         * @param reglua If true, register in lua immediately.
         */
        cvar(
            const char *aname,
            float val,
            bool reglua
        );
        /**
         * Constructor for string alias.
         * @param aname Name of the alias.
         * @param val Value of the alias.
         * @param reglua If true, register in lua immediately.
         */
        cvar(
            const char *aname,
            const char *val,
            bool reglua
        );
        /**
         * Destructor for cvar. Takes care of memory freeing
         * in case of string variable.
         */
        ~cvar();

        /**
         * @brief Get name of the variable.
         * @return Name of the variable. (string)
         * 
         * Gets name of the variable.
         */
        const char *gn();
        /**
         * @brief Get type of the variable.
         * @return Type of the variable. (int - VAR_I, VAR_F, VAR_S)
         * 
         * Gets type of the variable.
         */
        int gt();
        /**
         * @brief Get int value of the variable.
         * @return An int.
         * 
         * Gets int value of the variable.
         * @see gmni()
         * @see gmxi()
         * @see gf()
         * @see gs()
         */
        int gi();
        /**
         * @brief Get minimal int value of the variable.
         * @return An int.
         * 
         * Gets minimal int value of the variable.
         * @see gi()
         * @see gmxi()
         */
        int gmni();
        /**
         * @brief Get maximal int value of the variable.
         * @return An int.
         * 
         * Gets maximal int value of the variable.
         * @see gi()
         * @see gmni()
         */
        int gmxi();
        /**
         * @brief Get float value of the variable.
         * @return A float.
         * 
         * Gets float value of the variable.
         * @see gmnf()
         * @see gmxf()
         * @see gi()
         * @see gs()
         */
        float gf();
        /**
         * @brief Get minimal float value of the variable.
         * @return An int.
         * 
         * Gets minimal float value of the variable.
         * @see gf()
         * @see gmxf()
         */
        float gmnf();
        /**
         * @brief Get maximal float value of the variable.
         * @return An int.
         * 
         * Gets maximal float value of the variable.
         * @see gf()
         * @see gmnf()
         */
        float gmxf();
        /**
         * @brief Get string value of the variable.
         * @return A string (const char*).
         * 
         * Gets string value of the variable.
         * @see gi()
         * @see gf()
         */
        const char *gs();

        /**
         * @brief Set int value of the variable.
         * @param val The value to set.
         * @param luasync Try to sync it with Lua if true.
         * @param forcecb Force running callback.
         * @param clamp Clamp the value according to min and max values.
         * 
         * Sets int value of the variable.
         */
        void s(int val, bool luasync = true, bool forcecb = false, bool clamp = true);
        /**
         * @brief Set float value of the variable.
         * @param val The value to set.
         * @param luasync Try to sync it with Lua if true.
         * @param forcecb Force running callback.
         * @param clamp Clamp the value according to min and max values.
         * 
         * Sets float value of the variable.
         */
        void s(float val, bool luasync = true, bool forcecb = false, bool clamp = true);
        /**
         * @brief Set string value of the variable.
         * @param val The value to set.
         * @param luasync Try to sync it with Lua if true.
         * @param forcecb Force running callback.
         * @param clamp Dummy value. Does nothing.
         * 
         * Sets string value of the variable.
         */
        void s(const char *val, bool luasync = true, bool forcecb = false, bool clamp = true);
        /**
         * @brief Reset the variable.
         * 
         * Resets the variable to defaults.
         */
        void r();
        /**
         * @brief Is the variable persistent?
         * @return True if it is, otherwise false.
         * 
         * Gets if the variable is persistent.
         */
        bool ispersistent();
        /**
         * @brief Is the variable read only?
         * @return True if it is, otherwise false.
         * 
         * Gets if the variable is read only.
         */
        bool isreadonly();
        /**
         * @brief Is the variable overridable?
         * @return True if it is, otherwise false.
         * 
         * Gets if the variable is overridable.
         */
        bool isoverridable();
        /**
         * @brief Is the variable overriden?
         * @return True if it is, otherwise false.
         * 
         * Gets if the variable is overriden.
         */
        bool isoverriden();
        /**
         * @brief Is the variable alias?
         * @return True if it is, otherwise false.
         * 
         * Gets if the variable is alias.
         */
        bool isalias();

        /**
         * @brief Register Lua representation of int variable.
         * 
         * Registers Lua representation of int variable.
         * @see reglfv()
         * @see reglsv()
         */
        void regliv();
        /**
         * @brief Register Lua representation of float variable.
         * 
         * Registers Lua representation of float variable.
         * @see regliv()
         * @see reglsv()
         */
        void reglfv();
        /**
         * @brief Register Lua representation of string variable.
         * 
         * Registers Lua representation of string variable.
         * @see regliv()
         * @see reglfv()
         */
        void reglsv();
    private:
        /* This calls the callback properly, called from s() method. */
        void callcb(bool luasync, bool forcecb);

        /* Variable properties */
        bool persistent, hascb;
        const char *name;
        int type;
        bool readonly, override, overriden, alias;

        /* Unions for value storage (min, cur, max) */
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

        /* Union for callback storage. */
        union vcb_t
        {
            void (*i)(int);
            void (*f)(float);
            void (*s)(const char *);
        } vcb;
    };

    /// Variable table typedef (string, cvar*)
    typedef hashtable<const char*, cvar*> vartable;

    /// Variable and persistent variable tables.
    extern vartable *vars;
    /// Force persisting / overriding with these.
    extern bool persistvars, overridevars;

    /**
     * @brief Register an engine variable.
     * @param name Name of the variable.
     * @param var Pointer to variable.
     * @return The registered variable.
     * 
     * Register an engine variable into the system.
     * Wrapped in macros.
     */
    cvar *reg(const char *name, cvar *var);
    /**
     * @brief Fill vars table.
     * 
     * Fills the table of vars.
     */
    void fill();
    /**
     * @brief Fill Lua with EV's.
     * 
     * Fills Lua with engine variable representations.
     */
    void filllua();
    /**
     * @brief Reset values of all variables to defaults.
     * 
     * Resets values of all variables to their defaults.
     */
    void clear();
    /**
     * @brief Clear the variables completely.
     * 
     * Clears the vars table.
     */
    void flush();
    /**
     * @brief Sync int variable from Lua.
     * @param name Name of C++ var to set.
     * @param val Value to set.
     * 
     * This gets called when value in Lua is set.
     * C++ representation gets then set to same
     * value as in Lua EV system.
     */
    void syncfl(const char *name, int val);
    /**
     * @brief Sync float variable from Lua.
     * @param name Name of C++ var to set.
     * @param val Value to set.
     * 
     * This gets called when value in Lua is set.
     * C++ representation gets then set to same
     * value as in Lua EV system.
     */
    void syncfl(const char *name, float val);
    /**
     * @brief Sync string variable from Lua.
     * @param name Name of C++ var to set.
     * @param val Value to set.
     * 
     * This gets called when value in Lua is set.
     * C++ representation gets then set to same
     * value as in Lua EV system.
     */
    void syncfl(const char *name, const char *val);
    /**
     * @brief Get a variable, knowing its name.
     * @return Pointer to variable.
     * 
     * This method scans the table for var matching
     * @p name and returns it. If nothing is found,
     * NULL is returned.
     */
    cvar *get(const char *name);

    #define _EV_NODEF
    #define DEFVAR(name) extern cvar *_EV_##name;
    #include "variable_system_proto.hpp"

    #define VAR(name, min, cur, max) _EV_##name = reg(#name, new cvar(#name, (int)min, (int)cur, (int)max))
    #define VARP(name, min, cur, max) _EV_##name = reg(#name, new cvar(#name, (int)min, (int)cur, (int)max, NULL, true))
    #define VARR(name, min, cur, max) _EV_##name = reg(#name, new cvar(#name, (int)min, (int)cur, (int)max, NULL, false, true))
    #define VARF(name, min, cur, max, fun) _EV_##name = reg(#name, new cvar(#name, (int)min, (int)cur, (int)max, _varcb_##fun))
    #define VARFP(name, min, cur, max, fun) _EV_##name = reg(#name, new cvar(#name, (int)min, (int)cur, (int)max, _varcb_##fun, true))
    #define VARFR(name, min, cur, max, fun) _EV_##name = reg(#name, new cvar(#name, (int)min, (int)cur, (int)max, _varcb_##fun, false, true))

    #define FVAR(name, min, cur, max) _EV_##name = reg(#name, new cvar(#name, (float)min, (float)cur, (float)max))
    #define FVARP(name, min, cur, max) _EV_##name = reg(#name, new cvar(#name, (float)min, (float)cur, (float)max, NULL, true))
    #define FVARR(name, min, cur, max) _EV_##name = reg(#name, new cvar(#name, (float)min, (float)cur, (float)max, NULL, false, true))
    #define FVARF(name, min, cur, max, fun) _EV_##name = reg(#name, new cvar(#name, (float)min, (float)cur, (float)max, _varcb_##fun))
    #define FVARFP(name, min, cur, max, fun) _EV_##name = reg(#name, new cvar(#name, (float)min, (float)cur, (float)max, _varcb_##fun, true))
    #define FVARFR(name, min, cur, max, fun) _EV_##name = reg(#name, new cvar(#name, (float)min, (float)cur, (float)max, _varcb_##fun, false, true))

    #define SVAR(name, cur) _EV_##name = reg(#name, new cvar(#name, (const char*)cur))
    #define SVARP(name, cur) _EV_##name = reg(#name, new cvar(#name, (const char*)cur, NULL, true))
    #define SVARR(name, cur) _EV_##name = reg(#name, new cvar(#name, (const char*)cur, NULL, false, true))
    #define SVARF(name, cur, fun) _EV_##name = reg(#name, new cvar(#name, (const char*)cur, _varcb_##fun))
    #define SVARFP(name, cur, fun) _EV_##name = reg(#name, new cvar(#name, (const char*)cur, _varcb_##fun, true))
    #define SVARFR(name, cur, fun) _EV_##name = reg(#name, new cvar(#name, (const char*)cur, _varcb_##fun, false, true))
}
// end namespace var

/// Get int value of known variable.
#define GETIV(name) var::_EV_##name->gi()
/// Get float value of known variable.
#define GETFV(name) var::_EV_##name->gf()
/// Get string value of known variable.
#define GETSV(name) var::_EV_##name->gs()
/// Set value of a variable. Don't force callback, clamp the value and sync with Lua.
#define SETV(name, val) var::_EV_##name->s(val)
/// Set value of a variable. Don't force callback, don't clamp the value and sync with Lua.
#define SETVN(name, val) var::_EV_##name->s(val, true, false, false)
/// Set value of a variable. Force callback, clamp the value and sync with Lua.
#define SETVF(name, val) var::_EV_##name->s(val, true, true, true)
/// Set value of a variable. Force callback, don't clamp the value and sync with Lua.
#define SETVFN(name, val) var::_EV_##name->s(val, true, true, false)

/**
 * @}
 */
