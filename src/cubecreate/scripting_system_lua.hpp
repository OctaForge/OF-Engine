/*
 * scripting_system_lua.hpp, version 1
 * Header file for Lua scripting system
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2010 q66
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

#ifndef LUAENGINE_HPP
#define LUAENGINE_HPP

/**
 * @mainpage Lua
 * 
 * @author q66 <quaker66@gmail.com>
 * @date 2011
 */

#include <cstdlib>
#include <cstring>
#include <lua.hpp>
#include <typeinfo>

/**
 * @defgroup Script_Engine_Lua_Group Scripting_Engine
 *
 * @{
 */

namespace lua
{
    class lua_Engine;
    /// A typedef for nice code when passing binding functions.
    typedef void (*lua_Binding) (lua_Engine);
    /// A hashtable typedef for params
    typedef hashtable<const char*, const char*> LE_params;

    /**
     * @struct LE_reg
     * A struct storing the binded function plus its name in Lua.
     */
    struct LE_reg
    {
        const char *n;
        lua_Binding f;
    };

    /**
     * @class lua_Engine
     * Base class storing engine state and various get/set/... functions.
     */
    class lua_Engine
    {
    public:
        /**
         * @brief Create the engine.
         * @return Instance of lua_Engine class.
         * 
         * Creates a state handler, initializes
         * a few parameters and loads Lua libraries.
         * Then, it sets up bindings.
         * Automatically done from constructor if needed.
         * @see destroy()
         */
        lua_Engine& create();
        /**
         * @brief Destroy the engine.
         * @return -1 usually, but can return others; see the description.
         * 
         * If the class was created from existing state handler, it means
         * that it was created inside function to bind;
         * In that case,
         * Destroy is meant to return number of values to return from the
         * function.
         * If it wasn't, then it frees the state handler and returns -1.
         * Automatically done from destructor if needed.
         * @see Create()
         */
        int destroy();
        /**
         * @brief Is the state handler allocated?
         * @return True if state handler is allocated, otherwise false.
         */
        bool hashandle();

        /**
         * @brief Check the element on stack for a type.
         * @param i Position of the value on stack.
         * @return True if it is needed type, otherwise false.
         * 
         * Checks the element on stack for provided type.
         * It gets called like this:
         * 
         * @code
         * bool r = e.is<int>(2);
         * @endcode
         * 
         * Supported types are int, double, float, bool,
         * const char*, void** (table), void* (function), void (nil).
         */
        template<typename T>
        bool is(int i)
        {
            if (!m_hashandle) return false;
            if (typeid(T) == typeid(int)
                    || typeid(T) == typeid(double)
                    || typeid(T) == typeid(float)
            ) return lua_isnumber(m_handle, i);
            else if (typeid(T) == typeid(bool))
                return lua_isboolean(m_handle, i);
            else if (typeid(T) == typeid(const char*))
                return lua_isstring(m_handle, i);
            else if (typeid(T) == typeid(void**))
                return lua_istable(m_handle, i);
            else if (typeid(T) == typeid(void*))
                return lua_isfunction(m_handle, i);
            else return lua_isnoneornil(m_handle, i);
            return false;
        }

        /**
         * @brief Get a value from the stack.
         * @param i Position of the value on stack.
         * @return The value got from stack.
         * 
         * Gets value of specified type from stack and returns it.
         * If something goes wrong, 0 gets returned for integers and doubles,
         * false gets returned for booleans and empty string for strings.
         * Allowed types: int, double, bool, const char*.
         * Example:
         * 
         * @code
         * int a = e.get<int>(1);
         * bool b = e.get<bool>(2);
         * double c = e.get<double>(3);
         * const char *d = e.get<const char*>(4);
         * @endcode
         */
        template<typename T>
        T get(int i)
        {
            if (!m_hashandle) return 0;
            else if (!lua_isnoneornil(m_handle, i))
            {
                int v = lua_tointeger(m_handle, i);
                if (!v && !lua_isnumber(m_handle, i))
                    typeerror(i, "integer");
                return v;
            }
            else return 0;
        }
        /**
         * @brief Get a value from the stack.
         * @param i Position of the value on stack.
         * @param d Default value to return if something goes wrong.
         * @return The value got from stack.
         * 
         * Same as previous, except that you can provide a default value to
         * return if something fails.
         */
        template<typename T>
        T get(int i, T d)
        {
            if (!m_hashandle) return 0;
            else if (!lua_isnoneornil(m_handle, i))
            {
                int v = lua_tointeger(m_handle, i);
                if (!v && !lua_isnumber(m_handle, i))
                    typeerror(i, "integer");
                return v;
            }
            else return 0;
        }

        /**
         * @brief Copy a value onto stack.
         * @param i Position of the value on stack.
         * @return Instance of lua_Engine class.
         * 
         * Gets a value from stack from index @p i,
         * copies it and pushes onto stack, leaving it on -1.
         */
        lua_Engine& push_index(int i);
        /**
         * @brief Push a value onto stack.
         * @param v The value to push.
         * @return Instance of lua_Engine class.
         * 
         * Pushes an integer value @p v onto stack.
         */
        lua_Engine& push(int v);
        /**
         * @brief Push a value onto stack.
         * @param v The value to push.
         * @return Instance of lua_Engine class.
         * 
         * Pushes a double precision floating point value @p v onto stack.
         */
        lua_Engine& push(double v);
        /**
         * @brief Push a value onto stack.
         * @param v The value to push.
         * @return Instance of lua_Engine class.
         * 
         * Pushes a floating point value @p v onto stack.
         */
        lua_Engine& push(float v);
        /**
         * @brief Push a value onto stack.
         * @param v The value to push.
         * @return Instance of lua_Engine class.
         * 
         * Pushes a boolean value @p v onto stack.
         */
        lua_Engine& push(bool v);
        /**
         * @brief Push a value onto stack.
         * @param v The value to push.
         * @return Instance of lua_Engine class.
         * 
         * Pushes a const char * value @p v onto stack.
         */
        lua_Engine& push(const char *v);
        /**
         * @brief Push a value onto stack.
         * @param v The value to push.
         * @return Instance of lua_Engine class.
         * 
         * Pushes a vec value @p v onto stack.
         */
        lua_Engine& push(vec v);
        /**
         * @brief Push a value onto stack.
         * @param v The value to push.
         * @return Instance of lua_Engine class.
         * 
         * Pushes a vec4 value @p v onto stack.
         */
        lua_Engine& push(vec4 v);
        /**
         * @brief Push a value onto stack.
         * @return Instance of lua_Engine class.
         * 
         * Pushes a nil value onto stack.
         */
        lua_Engine& push();

        /**
         * @brief Shift values on stack.
         * @return Instance of lua_Engine class.
         * 
         * Shifts indexes -1 and -2 on stack.
         */
        lua_Engine& shift();

        /**
         * @brief Get a Lua global variable onto stack.
         * @param n Name of the global to push.
         * @return Instance of lua_Engine class.
         * 
         * Gets a Lua global variable and pushes it onto stack.
         * @see setg()
         */
        lua_Engine& getg(const char *n);
        /**
         * @brief Create a Lua global variable.
         * @return Instance of lua_Engine class.
         * 
         * Gets a key on -2 position on stack and
         * a value on -1 position on stack and makes it
         * a Lua global variable. Both values get removed from stack.
         * @see getg()
         */
        lua_Engine& setg();

        /**
         * @brief Call a Lua function on stack.
         * @param a Number of arguments to pass to function.
         * @param r Optional parameter specifying number of return values.
         * @return Instance of lua_Engine class.
         * 
         * Gets a Lua function from stack from -1 and calls it.
         * Uses @p a to get number of arguments to be passed to function;
         * i.e. if you set @p a to 3, it'll get arguments from -1, -2, -3
         * and the function itself from -4. Parameter @p r is optional and
         * specifies exact number of return values from the called function;
         * If not set, then it gets autodetected.
         * Example:
         * 
         * @code
         * e.getg("foo").t_getraw("bar").push(10).push(15).call(2).pop();
         * @endcode
         */
        lua_Engine& call(int a, int r = LUA_MULTRET);
        /**
         * @brief Call a Lua function on stack.
         * @return Instance of lua_Engine class.
         * 
         * Variant of call function. Number of arguments is basically
         * number of values on stack minus 1 (because not all values are
         * arguments, the first pushed one is a function itself).
         * Number of returns is autodetected. Call this ONLY when you are
         * absolutely sure your stack is clear! (i.e. has only the function
         * plus arguments)
         * Example:
         * 
         * @code
         * e.pop().getg("foo").push(10).push(15).call().pop();
         * @endcode
         */
        lua_Engine& call();

        /**
         * @brief Runs a Lua script from file.
         * @param s Path to file containing the script.
         * @param msg Optional - if true (default), possible error message is printed.
         * @return True on success; false otherwise.
         * 
         * Loads a file and runs it, leaving all return values on stack.
         */
        bool execf(const char *s, bool msg = true);
        /**
         * @brief Runs a Lua script from string.
         * @param s The string containing a Lua script to run.
         * @param msg Optional - if true (default), possible error message is printed.
         * @return True on success; false otherwise.
         * 
         * Runs the string, leaving all return values on stack.
         */
        bool exec(const char *s, bool msg = true);
        /**
         * @brief Runs a Lua script from string, returning value as its result.
         * @param s The string containing a Lua script to run.
         * @param msg Optional - if true (default), possible error message is printed.
         * @return Value of specified type.
         * 
         * Runs the string and gets a value of needed type from -1,
         * assuming the script returns actual value.
         * USE ONLY WHEN YOU KNOW you're returning a value as a last
         * return value from the script! The returned value gets
         * removed from stack automatically, you don't have to take care of that.
         * Allowed types: int, double, bool, const char*.
         * Example:
         * 
         * @code
         * e.exec("foo"); // standard string, non-return
         * int a = e.exec<int>("return 5");
         * double b = e.exec<double>("return 3.14");
         * bool c = e.exec<bool>("return true");
         * const char *d = e.exec<const char*>("return 'blablah'");
         * @endcode
         */
        template<typename T>
        T exec(const char *s, bool msg = true)
        {
            if (!exec(s)) return 0;
            T ret = get<T>(-1);
            pop(1);
            return ret;
        }
        /**
         * @brief Parses a Lua script from file, but doesn't run it.
         * @param s Path to file containing the script.
         * @param msg Optional - if true (default), possible error message is printed.
         * @return True on success; false otherwise.
         * 
         * Parses a file containing a Lua script, but doesn't run it.
         * Useful for checking if the script has proper syntax.
         */
        bool loadf(const char *s, bool msg = true);
        /**
         * @brief Parses a Lua script from a string, but doesn't run it.
         * @param s A string containing the Lua script.
         * @param msg Optional - if true (default), possible error message is printed.
         * @return True on success; false otherwise.
         * 
         * Parses a string containing a Lua script, but doesn't run it.
         * Useful for checking if the script has proper syntax.
         */
        bool load(const char *s, bool msg = true);

        /**
         * @brief Creates a new Lua table and pushes it onto stack.
         * @return Instance of lua_Engine class.
         * 
         * Creates a new Lua table and pushes it onto stack.
         */
        lua_Engine& t_new();

        /**
         * @brief Get table element.
         * @param n Either integer index of table (array) or string (hashtable).
         * @return Instance of lua_Engine class.
         * 
         * Pushes element @p n of table present on -1 onto stack and leaves it there,
         * doesn't take care of clearing it out so you can use its value and clear
         * it yourself. If it's standard type, you can use the auto-clearing variants.
         * 
         * @see t_get()
         */
        template<typename T>
        lua_Engine& t_getraw(T n)
        {
            if (!m_hashandle) return *this;
            push(n);
            lua_gettable(m_handle, -2);
            return *this;
        }
        /**
         * @brief Get a table element, returning its value and clearing it out.
         * @param n Either integer index of table (array) or string (hashtable).
         * @return Table element value of specified type.
         * 
         * Pushes element @p n of table present on -1 onto stack, gets its non-string value
         * and clears it out of stack automatically. If something goes wrong, 0 is returned
         * in case of integers and doubles, false gets returned in case of booleans and
         * empty string in case of strings.
         * Allowed types: int, double, bool, const char*.
         * Example:
         * 
         * @code
         * e.getg("foo");
         * int a = e.t_get<int>("a"); // hashtable
         * double b = e.t_get<double>(2); // array
         * bool c = e.t_get<bool>("c");
         * const char *d = e.t_get<const char*>("d");
         * e.pop();
         * @endcode
         */
        template<typename T, typename U>
        T t_get(U n)
        {
            if (!m_hashandle) return 0;
            t_getraw(n);
            T r = get<T>(-1);
            pop(1);
            return r;
        }
        /**
         * @brief Get a table element, returning its value and clearing it out.
         * @param n Either integer index of table (array) or string (hashtable).
         * @param d Default value to return if something goes wrong.
         * @return Table element value of specified type.
         * 
         * Same as previous, except that you can provide a default value to
         * return if something fails.
         */
        template<typename T, typename U>
        T t_get(U n, T d)
        {
            if (!m_hashandle) return d;
            t_getraw(n);
            T r = get(-1, d);
            pop(1);
            return r;
        }

        /**
         * @brief Sets table element.
         * @return Instance of lua_Engine class.
         * 
         * Assuming there is table on -3, key on -2 and value on -1, it creates
         * or sets the element accordingly. Key and value get cleared out of
         * stack, but the table stays for further use.
         */
        lua_Engine& t_set();
        /**
         * @brief Sets table element.
         * @param n Either integer index of table (array) or string (hashtable).
         * @param v Value of the element to set. Can be int, double, bool, string.
         * @return Instance of lua_Engine class.
         * 
         * Assuming there is table on -1, it creates or sets the element accordingly.
         */
        template<typename T, typename U>
        lua_Engine& t_set(T n, U v)
        {
            if (!m_hashandle) return *this;
            push(n); push(v);
            lua_settable(m_handle, -3);
            return *this;
        }

        /**
         * @brief Move on to another table element.
         * @param i Index of table to perform next on.
         * @return True if there are elements remaining in the table, otherwise false.
         * 
         * Pops a key from the stack on -1 and pushes a key-value pair from the table
         * at index @p i. If there are no elements remaining, it returns false, otherwise
         * returns true.
         * Example:
         * 
         * @code
         * e.getg("mytbl"); // get the table onto stack
         * e.push(); // push a first key to feed TableNext (nil value)
         * while (e.t_next(-2)) // -2 is index of table on stack after pushing nil
         * {
         *     // we've got key now on -2 and value on -1
         *     const char *key = e.get<const char*>(-2);
         *     double val = e.get<double>(-1);
         *     // more code continues ...
         *     // clear the value from stack now; keep key for next iteration
         *     // (see the nil push before first t_next)
         *     e.pop(1);
         * }
         * @endcode
         */
        bool t_next(int i);

        /**
         * @brief Throws a Lua error.
         * @param m The log message.
         * @return Instance of lua_Engine class.
         * 
         * Throws a Lua error, setting message as @p m and if possible, prefixing it
         * with source and line number.
         */
        lua_Engine& error(const char *m);
        /**
         * @brief Throws a Lua type error.
         * @param n Number of argument which is of bad type.
         * @param t String containing name of the type it should be.
         * @return Instance of lua_Engine class.
         * 
         * Throws a Lua type error in format "Bad argument @p n to 'func'
         * (@p t expected, got rt).
         */
        lua_Engine& typeerror(int n, const char *t);
        /**
         * @brief Gets a Lua error message.
         * @return String containing the error.
         * 
         * Gets an error message from stack, returning it.
         */
        const char *geterror();
        /**
         * @brief Gets a last Lua error message.
         * @return Last error that happened in Lua.
         * 
         * Gets a last error message thrown from Lua. Doesn't actually
         * access the stack, because the lua_Engine is storing last error
         * always when a new one is thrown, so it simply gets it from
         * the class.
         */
        const char *geterror_last();

        /**
         * @brief Gets an unique reference number for stack element.
         * @return Integer reference value for the element.
         * 
         * Gets an element on -1 and returns its unique reference value.
         * The element on -1 gets cleared from the stack.
         */
        int ref();
        /**
         * @brief Gets an object of provided reference number and pushes it on stack.
         * @param r The reference number to get object from.
         * @return Instance of lua_Engine class.
         * 
         * Gets an object of reference number @p r and pushes it on stack,
         * leaving it there for further use.
         */
        lua_Engine& getref(int r);
        /**
         * @brief Releases a reference number.
         * @param r The reference number to release.
         * @return Instance of lua_Engine class.
         * 
         * Releases a reference @p r, freeing the number for use by another object.
         */
        lua_Engine& unref(int r);

        /**
         * @brief Clears a stack.
         * @param n Optional argument setting how many last elements to clear.
         * @return Instance of lua_Engine class.
         * 
         * If @p n is provided, last @p n elements get cleared from stack.
         * If it's not provided, all stack elements get cleared.
         */
        lua_Engine& pop(int n = 0);
        /**
         * @brief Gets an index of top element on stack (positive value)
         * @return Integer value containing the index of top item on stack.
         * 
         * Gets an index of top element on stack,returning a non-relative
         * positive value. Rarely required, as most of things to be done
         * with this are actually done automatically by engine class.
         */
        int gettop();

        /**
         * Constructor for lua_Engine.
         */
        lua_Engine();
        /**
         * Constructor for lua_Engine with existing state handler.
         * Useful for constructing temporary classes for use in binds.
         * @param l The state handler to create the class with.
         * @param dbg Optional parameter telling the class if to log debug messages.
         */
        lua_Engine(lua_State *l);

        ~lua_Engine();

        /**
         * Overloaded operator for setting non-Lua engine parameters.
         * Example:
         * 
         * @code
         * lua_Engine e;
         * e["foo"] = "bar";
         * Logging::log(Logging::INFO, "%s\n", e["foo"]);
         * @endcode
         */
        const char *&operator[](const char *n);

    private:
        /* The state handler for Lua's C API */
        lua_State *m_handle;

        /* Count of items to be returned from binded function */
        int m_retcount;

        /* Boolean storing if we have the handler allocated or not */
        bool m_hashandle;
        /* Do we want to run tests? */
        bool m_runtests;
        /* Did we run tests already? */
        bool m_rantests;

        /* Directory with Lua scripts to be used by SetupModule() */
        const char *m_scriptdir;
        /* Version to be exported to lua system */
        const char *m_version;
        /* Last error message from Lua */
        const char *m_lasterror;

        /* map containing non-lua engine params */
        LE_params *m_params;

        /* Loads all needed Lua modules */
        void setup_libs();
        /* Passing name and map of binds, this method registers a table of binds in Lua */
        void setup_namespace(const char *n, const LE_reg *r);
        /* Loads a "module" - that is a lua script in m_scriptDir. */
        void setup_module(const char *n, bool t = false);
        /* Registers the Lua namespaces, handles CubeCreate Lua modules and tests. */
        lua_Engine& bind();

        /* Static methods for Lua */
        static int l_disp (lua_State *L);
    };

    /*
     * some template specialization prototypes
     */
    template<> double         lua_Engine::get(int i);
    template<> float          lua_Engine::get(int i);
    template<> bool           lua_Engine::get(int i);
    template<> const char    *lua_Engine::get(int i);
    template<> LogicEntityPtr lua_Engine::get(int i);
    // specializations for with-default getters
    template<> double         lua_Engine::get(int i, double d);
    template<> float          lua_Engine::get(int i, float d);
    template<> bool           lua_Engine::get(int i, bool d);
    template<> const char    *lua_Engine::get(int i, const char *d);
    // specializations for pointers; temporary till stuff requiring this is rewritten
    template<> char          *lua_Engine::get(int i, char *d);
    template<> int           *lua_Engine::get(int i);
    template<> double        *lua_Engine::get(int i);
    template<> float         *lua_Engine::get(int i);
    template<> char          *lua_Engine::get(int i);

    /// Instance of the script engine.
    extern lua_Engine engine;

}
// end namespace lua

/**
 * @def LUA_TABLE_FOREACH
 * @brief Loops a Lua table on -1.
 * @param e The lua_Engine instance to use.
 * @param b Body to pass to every iteration.
 * 
 * Macro to loop a Lua table. Giving it the engine as first argument and the
 * body as second argument, it loops through every element of table, which
 * must be on -1, and runs the body for it. At every iteration, it's possible
 * to access the key at -2 and value at -1. No need to clear the stack, after
 * iteration, the values are cleared automatically.
 * You can loop both array and hashtable like this; just in the first case,
 * key will be integer and in the second case, key will be string.
 * Example:
 * 
 * @code
 * e.getg("foo");
 * LUA_TABLE_FOREACH(e, {
 *     // get the string key and integer value and print them
 *     Logging::log("Key: %s Value: %i\n", e.get<const char*>(-2), e.get<int>(-1));
 * });
 * e.pop(1);
 * @endcode
 */
#define LUA_TABLE_FOREACH(e, b) \
e.push(); \
while (e.t_next(-2)) \
{ \
    b; \
    e.pop(1); \
}

/**
 * @def LUA_BIND_DEF
 * @brief Define a Lua binding (C++ function exposed to Lua).
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param b Body to run when the function is called from Lua.
 * 
 * The macro serves as a helper when binding functions; it does some logging
 * for you and prefixes the name with _bind_. You can write your bindings
 * without this helper, but this greatly simplifies the syntax.
 */
#define LUA_BIND_DEF(n, b) \
void _bind_##n(lua_Engine e) \
{ \
    Logging::log(Logging::INFO, "Registering Lua function: %s\r\n", #n); \
    b; \
}

/**
 * @def LUA_BIND_STD
 * @brief Bind a single function to Lua.
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param f The function to bind.
 * @param ... Arguments to pass to the function.
 * 
 * The macro wraps over LUA_BIND_DEF, simplifying binding of a single function.
 */
#define LUA_BIND_STD(n, f, ...) LUA_BIND_DEF(n, f(__VA_ARGS__);)

/**
 * @def LUA_BIND_DUMMY
 * @brief Dummy binding for Lua.
 * @param n Name of the new dummy binding.
 * 
 * The macro does a dummy binding - registers it, but it will do nothing on call.
 */
#define LUA_BIND_DUMMY(n) LUA_BIND_DEF(n, {})

#ifdef CLIENT
/**
 * @def LUA_BIND_CLIENT
 * @brief Define a Lua binding for client.
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param b Body to run when the function is called from Lua.
 * 
 * The macro creates a binding in the same way as LUA_BIND_DEF,
 * but only for client. For server, dummy binding gets created.
 */
#define LUA_BIND_CLIENT(n, b) LUA_BIND_DEF(n, b)
#define LUA_BIND_SERVER(n, b) LUA_BIND_DUMMY(n)
/**
 * @def LUA_BIND_STD_CLIENT
 * @brief Bind a client function to Lua.
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param f The function to bind.
 * @param ... Arguments to pass to the function.
 * 
 * This creates a standard binding like LUA_BIND_STD, but only for client.
 * For server, dummy binding gets created. Useful for client-only functions.
 */
#define LUA_BIND_STD_CLIENT(n, f, ...) LUA_BIND_STD(n, f, __VA_ARGS__)
#define LUA_BIND_STD_SERVER(n, f, ...) LUA_BIND_DUMMY(n)
#else
#define LUA_BIND_CLIENT(n, b) LUA_BIND_DUMMY(n)
/**
 * @def LUA_BIND_SERVER
 * @brief Define a Lua binding for server.
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param b Body to run when the function is called from Lua.
 * 
 * The macro creates a binding in the same way as LUA_BIND_DEF,
 * but only for server. For client, dummy binding gets created.
 */
#define LUA_BIND_SERVER(n, b) LUA_BIND_DEF(n, b)
#define LUA_BIND_STD_CLIENT(n, f, ...) LUA_BIND_DUMMY(n)
/**
 * @def LUA_BIND_STD_SERVER
 * @brief Bind a server function to Lua.
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param f The function to bind.
 * @param ... Arguments to pass to the function.
 * 
 * This creates a standard binding like LUA_BIND_STD, but only for server.
 * For client, dummy binding gets created. Useful for server-only functions.
 */
#define LUA_BIND_STD_SERVER(n, f, ...) LUA_BIND_STD(n, f, __VA_ARGS__)
#endif

/**
 * @def LUA_BIND_LE
 * @brief Define a Lua binding with pre-created "self" variable of LogicEntityPtr type.
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param b Body to run when the function is called from Lua.
 * 
 * The macro wraps over LUA_BIND_DEF, but creates a "self" variable representing
 * LogicEntityPtr. The LogicEntityPtr is got using a table at first argument.
 * This is mainly used to simplify binding of API manipulating with entities in Lua.
 */
#define LUA_BIND_LE(n, b) \
LUA_BIND_DEF(n, { \
    Logging::log(Logging::INFO, "Registering Lua LogicEntityPtr function: %s\r\n", #n); \
    LogicEntityPtr self = e.get<LogicEntityPtr>(1); \
    b; \
})

/**
 * @def LUA_BIND_SE
 * @brief Define a Lua binding with pre-created "ref" integer variable.
 * @param n Name of the newly created function (it gets prefixed with _bind_).
 * @param b Body to run when the function is called from Lua.
 * 
 * The macro wraps over LUA_BIND_DEF, but creates a "ref" integer variable
 * representing unique reference number of first argument; This is used mainly
 * to simplify getting an object based on reference number from somewhere else.
 */
#define LUA_BIND_SE(n, b) \
LUA_BIND_DEF(n, { \
    Logging::log(Logging::INFO, "Getting reference unique ID for Lua function: %s\r\n", #n); \
    if (!e.is<void**>(1)) \
    { \
        e.typeerror(1, "table"); \
        return; \
    } \
    e.push_index(1); \
    int ref = e.ref(); \
    b; \
})

/**
 * @}
 */

#endif
