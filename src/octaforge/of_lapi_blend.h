extern int paintingblendmap;
void clearblendbrushes();
void delblendbrush(const char *name);
void addblendbrush(const char *name, const char *imgname);
void nextblendbrush(int dir);
void setblendbrush(const char *name);
types::String getblendbrushname(int n);
int curblendbrush();
void rotateblendbrush(int val);
void paintblendmap(bool msg);
void clearblendmapsel();
void invertblendmapsel();
void invertblendmap();
void showblendmap();
void optimizeblendmap();
void resetblendmap();

extern int& nompedit;

namespace lapi_binds
{
#ifdef CLIENT
    void _lua_clearblendbrushes(             ) { clearblendbrushes(); }
    void _lua_delblendbrush    (const char *n) { delblendbrush   (n); }

    void _lua_addblendbrush(const char *n, const char *img)
    {
        addblendbrush(n ? n : "", img ? img : "");
    }

    void _lua_nextblendbrush(int d)
    {
        nextblendbrush(d);
    }

    void _lua_setblendbrush(const char *n)
    {
        setblendbrush(n ? n : "");
    }

    types::String _lua_getblendbrushname(int n)
    {
        return getblendbrushname(n);
    }

    int _lua_curblendbrush()
    {
        return curblendbrush();
    }

    void _lua_rotateblendbrush(int v)
    {
        rotateblendbrush(v);
    }

    void _lua_paintblendmap()
    {
        if (addreleaseaction(
            lapi::state.get<lua::Function>("CAPI", "paintblendmap")
        ))
        {
            if (!paintingblendmap)
            {
                paintblendmap(true);
                paintingblendmap = totalmillis;
            }
        }
        else stoppaintblendmap();
    }

    void _lua_clearblendmapsel () { clearblendmapsel (); }
    void _lua_invertblendmapsel() { invertblendmapsel(); }
    void _lua_invertblendmap   () { invertblendmap   (); }
    void _lua_showblendmap     () { showblendmap     (); }
    void _lua_optimizeblendmap () { optimizeblendmap (); }

    void _lua_clearblendmap()
    {
        if (noedit(true) || (nompedit && multiplayer())) return;
        resetblendmap();
        showblendmap ();
    }
#else
    LAPI_EMPTY(clearblendbrushes)
    LAPI_EMPTY(delblendbrush)
    LAPI_EMPTY(addblendbrush)
    LAPI_EMPTY(nextblendbrush)
    LAPI_EMPTY(setblendbrush)
    LAPI_EMPTY(getblendbrushname)
    LAPI_EMPTY(curblendbrush)
    LAPI_EMPTY(rotateblendbrush)
    LAPI_EMPTY(paintblendmap)
    LAPI_EMPTY(clearblendmapsel)
    LAPI_EMPTY(invertblendmapsel)
    LAPI_EMPTY(invertblendmap)
    LAPI_EMPTY(showblendmap)
    LAPI_EMPTY(optimizeblendmap)
    LAPI_EMPTY(clearblendmap)
#endif

    void reg_blend(lua::Table& t)
    {
        LAPI_REG(clearblendbrushes);
        LAPI_REG(delblendbrush);
        LAPI_REG(addblendbrush);
        LAPI_REG(nextblendbrush);
        LAPI_REG(setblendbrush);
        LAPI_REG(getblendbrushname);
        LAPI_REG(curblendbrush);
        LAPI_REG(rotateblendbrush);
        LAPI_REG(paintblendmap);
        LAPI_REG(clearblendmapsel);
        LAPI_REG(invertblendmapsel);
        LAPI_REG(invertblendmap);
        LAPI_REG(showblendmap);
        LAPI_REG(optimizeblendmap);
        LAPI_REG(clearblendmap);
    }
}
