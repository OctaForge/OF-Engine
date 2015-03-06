#ifndef OF_LAPI_H
#define OF_LAPI_H

namespace lua
{
    struct va_ref { va_list ap; };

    struct State {
        lua_State *state;

        State(bool dedicated, const char *dir);
        ~State();

        bool push_external(const char *name);

        bool call_external(const char *name, const char *args, ...);

        int call_external_ret_nopop(const char *name, const char *args,
        const char *retargs, ...);

        bool call_external_ret(const char *name, const char *args,
        const char *retargs, ...);

        void pop_external_ret(int n);

        void load_module(const char *name);
        int  load_file  (const char *fname);
        int  load_string(const char *str, const char *ch = NULL);
        bool exec_file  (const char *cfgfile, bool msg = true);

    private:
        static int capi_tostring(lua_State *L);
        static int capi_newindex(lua_State *L);
        static int capi_get(lua_State *L);
        static int panic(lua_State *L);

        void setup_ffi();
        void setup_binds(bool dedicated);

        int vcall_external(const char *name, const char *args, int retn, va_ref *ar);
        int vcall_external_ret(const char *name, const char *args,
        const char *retargs, va_ref *ar);
    };

    extern State *L;

    bool reg_fun     (const char *name, lua_CFunction fun);
    bool reg_cfun    (const char *name, const char *sig, void *fun);
    bool init        (bool dedicated, const char *dir = "media/scripts/core");
    void reset       ();
    void close       ();
    void assert_stack();
}

#define LUACOMMAND(name, fun) \
    static bool __dummy_##name = lua::reg_fun(#name, fun);

#define LUAICOMMANDN(name, state, body) \
    template<int N> struct _lfn_##name; \
    template<> struct _lfn_##name<__LINE__> { \
        static bool init; static int fun(lua_State*); \
    }; \
    bool _lfn_##name<__LINE__>::init = lua::reg_fun(#name, \
         _lfn_##name<__LINE__>::fun); \
    int  _lfn_##name<__LINE__>::fun(lua_State *state) { \
        body; \
    }

#define LUAICOMMAND(name, body) LUAICOMMANDN(name, L, body)

#define CLUACOMMAND(nm, rett, argt, fun) \
    static bool __dummyc_##nm = lua::reg_cfun(#nm, #rett "(*)" #argt, \
        (void*)fun);

#define CLUAICOMMAND(nm, rett, argt, body) \
    template<int N> struct _lcfn_##nm; \
    template<> struct _lcfn_##nm<__LINE__> { \
        static bool init; static rett fun argt; \
    }; \
    bool _lcfn_##nm<__LINE__>::init = lua::reg_cfun(#nm, #rett "(*)" #argt, \
         (void*)_lcfn_##nm<__LINE__>::fun); \
    rett _lcfn_##nm<__LINE__>::fun argt { \
        body; \
    }

#endif
