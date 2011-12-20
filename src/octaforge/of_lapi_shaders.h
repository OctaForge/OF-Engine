#ifdef CLIENT
void shader(int type, char *name, char *vs, char *ps);
void variantshader(int type, char *name, int row, char *vs, char *ps);
void setshader(char *name);
void addshaderparam(const char *name, int type, int n, float x, float y, float z, float w);
void altshader(char *origname, char *altname);
void fastshader(char *nice, char *fast, int detail);
void defershader(int type, const char *name, lua::Function contents);
Shader *useshaderbyname(const char *name);
bool isshaderdefined(const char *name);
bool isshadernative(const char *name);
void addpostfx(const char *name, int bind, int scale, const char *inputs, float x, float y, float z, float w);
void setpostfx(const char *name, float x, float y, float z, float w);
void clearpostfx();
#endif
namespace lapi_binds
{
#ifdef CLIENT
    void _lua_shader(int t, const char *n, const char *vs, const char *ps)
    {
        shader(t, (char*)n, (char*)vs, (char*)ps);
    }

    void _lua_variantshader(
        int t, const char *n, int row, const char *vs, const char *ps
    )
    {
        variantshader(t, (char*)n, row, (char*)vs, (char*)ps);
    }

    void _lua_setshader(const char *n) { setshader((char*)n); }

    void _lua_altshader(const char *n, const char *a)
    {
        altshader((char*)n, (char*)a);
    }

    void _lua_fastshader(const char *n, const char *f, int d)
    {
        fastshader((char*)n, (char*)f, d);
    }

    void _lua_defershader(int t, const char *n, lua::Function f)
    {
        defershader(t, n, f);
    }

    void _lua_forceshader(const char *n)
    {
        useshaderbyname(n);
    }

    bool _lua_isshaderdefined(const char *n) { return isshaderdefined(n); }
    bool _lua_isshadernative (const char *n) { return isshadernative (n); }

    void _lua_setvertexparam(int t, float x, float y, float z, float w)
    {
        addshaderparam(NULL, SHPARAM_VERTEX, t, x, y, z, w);
    }

    void _lua_setpixelparam(int t, float x, float y, float z, float w)
    {
        addshaderparam(NULL, SHPARAM_PIXEL, t, x, y, z, w);
    }

    void _lua_setuniformparam(
        const char *n, float x, float y, float z, float w
    )
    {
        addshaderparam(n, SHPARAM_UNIFORM, -1, x, y, z, w);
    }

    void _lua_setshaderparam(const char *n, float x, float y, float z, float w)
    {
        addshaderparam(n, SHPARAM_LOOKUP, -1, x, y, z, w);
    }

    void _lua_defvertexparam(
        const char *name, int n, float x, float y, float z, float w
    )
    {
        addshaderparam(name, SHPARAM_VERTEX, n, x, y, z, w);
    }

    void _lua_defpixelparam(
        const char *name, int n, float x, float y, float z, float w
    )
    {
        addshaderparam(name, SHPARAM_PIXEL, n, x, y, z, w);
    }

    void _lua_defuniformparam(
        const char *name, float x, float y, float z, float w
    )
    {
        addshaderparam(name, SHPARAM_UNIFORM, -1, x, y, z, w);
    }

    void _lua_addpostfx(
        const char *n, int b, int s, const char *i,
        float x, float y, float z, float w
    )
    {
        addpostfx(n, b, s, (i ? i : ""), x, y, z, w);
    }

    void _lua_setpostfx(const char *n, float x, float y, float z, float w)
    {
        setpostfx(n, x, y, z, w);
    }

    void _lua_clearpostfx() { clearpostfx(); }
#else
    LAPI_EMPTY(shader)
    LAPI_EMPTY(variantshader)
    LAPI_EMPTY(setshader)
    LAPI_EMPTY(altshader)
    LAPI_EMPTY(fastshader)
    LAPI_EMPTY(defershader)
    LAPI_EMPTY(forceshader)
    LAPI_EMPTY(isshaderdefined)
    LAPI_EMPTY(isshadernative)
    LAPI_EMPTY(setvertexparam)
    LAPI_EMPTY(setpixelparam)
    LAPI_EMPTY(setuniformparam)
    LAPI_EMPTY(setshaderparam)
    LAPI_EMPTY(defvertexparam)
    LAPI_EMPTY(defpixelparam)
    LAPI_EMPTY(defuniformparam)
    LAPI_EMPTY(addpostfx)
    LAPI_EMPTY(setpostfx)
    LAPI_EMPTY(clearpostfx)
#endif

    void reg_shaders(lua::Table& t)
    {
        LAPI_REG(shader);
        LAPI_REG(variantshader);
        LAPI_REG(setshader);
        LAPI_REG(altshader);
        LAPI_REG(fastshader);
        LAPI_REG(defershader);
        LAPI_REG(forceshader);
        LAPI_REG(isshaderdefined);
        LAPI_REG(isshadernative);
        LAPI_REG(setvertexparam);
        LAPI_REG(setpixelparam);
        LAPI_REG(setuniformparam);
        LAPI_REG(setshaderparam);
        LAPI_REG(defvertexparam);
        LAPI_REG(defpixelparam);
        LAPI_REG(defuniformparam);
        LAPI_REG(addpostfx);
        LAPI_REG(setpostfx);
        LAPI_REG(clearpostfx);
    }
}
