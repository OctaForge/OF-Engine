#ifdef CLIENT
void newfont(const char *name, const char *tex, int defaultw, int defaulth);
void fontoffset(const char *c);
void fontscale(int scale);
void fonttex(const char *s);
void fontchar(
    int x, int y, int w, int h, int offsetx, int offsety, int advance
);
void fontskip(int n);
void fontalias(const char *dst, const char *src);

namespace gui
{
    bool _lua_hideui(const char *name);
    bool _lua_showui(
        const char *name, lua::Function contents,
        lua::Function onhide, bool nofocus
    );
    bool _lua_replaceui(
        const char *wname, const char *tname, lua::Function contents
    );
    void _lua_uialign(int h, int v);
    void _lua_uiclamp(int l, int r, int b, int t);
    void _lua_uiwinmover(lua::Function children);
    void _lua_uitag(const char *name, lua::Function children);
    void _lua_uivlist(float space, lua::Function children);
    void _lua_uihlist(float space, lua::Function children);
    void _lua_uitable(int columns, float space, lua::Function children);
    void _lua_uispace(float h, float v, lua::Function children);
    void _lua_uifill(float h, float v, lua::Function children);
    void _lua_uiclip(float h, float v, lua::Function children);
    void _lua_uiscroll(float h, float v, lua::Function children);
    void _lua_uihscrollbar(float h, float v, lua::Function children);
    void _lua_uivscrollbar(float h, float v, lua::Function children);
    void _lua_uiscrollbutton(lua::Function children);
    void _lua_uihslider(
        const char *var, int minv, int maxv, lua::Function children
    );
    void _lua_uivslider(
        const char *var, int minv, int maxv, lua::Function children
    );
    void _lua_uisliderbutton(lua::Function children);
    void _lua_uioffset(float h, float v, lua::Function children);
    void _lua_uibutton(lua::Function cb, lua::Function children);
    void _lua_uicond(lua::Function cb, lua::Function children);
    void _lua_uicondbutton(
        lua::Function cond, lua::Function cb, lua::Function children
    );
    void _lua_uitoggle(
        lua::Function cond,
        lua::Function cb,
        float split,
        lua::Function children
    );
    void _lua_uiimage(
        const char *path, float minw, float minh, lua::Function children
    );
    void _lua_uislotview(
        int slot, float minw, float minh, lua::Function children
    );
    void _lua_uialtimage(const char *path);
    void _lua_uicolor(
        float r, float g, float b, float a,
        float minw, float minh, lua::Function children
    );
    void _lua_uimodcolor(
        float r, float g, float b,
        float minw, float minh, lua::Function children
    );
    void _lua_uistretchedimage(
        const char *path, float minw, float minh, lua::Function children
    );
    void _lua_uicroppedimage(
        const char *path,
        float minw, float minh,
        const char *cropx,
        const char *cropy,
        const char *cropw,
        const char *croph,
        lua::Function children
    );
    void _lua_uiborderedimage(
        const char *path, const char *texborder,
        float screenborder, lua::Function children
    );
    int _lua_uilabel(
        const char *lbl, float scale,
        lua::Object r, lua::Object g, lua::Object b,
        lua::Function children
    );
    void _lua_uisetlabel(int ref, const char *lbl);
    void _lua_uivarlabel(
        const char *var, float scale,
        lua::Object r, lua::Object g, lua::Object b,
        lua::Function children
    );
    void _lua_uitexteditor(
        const char *name,
        int length,
        int height,
        float scale,
        const char *initval,
        bool keep,
        const char *filter,
        lua::Function children
    );
    void _lua_uifield(
        const char *var,
        int length,
        lua::Function onchange,
        float scale,
        const char *filter,
        bool password,
        lua::Function children
    );
};

void _lua_applychanges();
void _lua_clearchanges();
types::Vector<const char*> _lua_getchanges();
#endif
namespace lapi_binds
{
#ifdef CLIENT
    using namespace gui;

    void _lua_font(const char *name, const char *text, int dw, int dh)
    {
        newfont(name, text, dw, dh);
    }

    void _lua_fontoffset(const char *c) { fontoffset(c); }
    void _lua_fonttex   (const char *t) { fonttex   (t); }
    void _lua_fontscale (int         s) { fontscale (s); }

    void _lua_fontchar(int x, int y, int w, int h, int ox, int oy, int adv)
    {
        fontchar(x, y, w, h, ox, oy, adv);
    }

    void _lua_fontskip(int n) { fontskip(n); }

    void _lua_fontalias(const char *dst, const char *src)
    {
        fontalias(dst, src);
    }

    void _lua_menukeyclicktrig() { GuiControl::menuKeyClickTrigger(); }
#else
    LAPI_EMPTY(font)
    LAPI_EMPTY(fontoffset)
    LAPI_EMPTY(fonttex)
    LAPI_EMPTY(fontscale)
    LAPI_EMPTY(fontchar)
    LAPI_EMPTY(fontskip)
    LAPI_EMPTY(fontalias)
    LAPI_EMPTY(menukeyclicktrig)
    LAPI_EMPTY(hideui)
    LAPI_EMPTY(showui)
    LAPI_EMPTY(replaceui)
    LAPI_EMPTY(uialign)
    LAPI_EMPTY(uiclamp)
    LAPI_EMPTY(uiwinmover)
    LAPI_EMPTY(uitag)
    LAPI_EMPTY(uivlist)
    LAPI_EMPTY(uihlist)
    LAPI_EMPTY(uitable)
    LAPI_EMPTY(uispace)
    LAPI_EMPTY(uifill)
    LAPI_EMPTY(uiclip)
    LAPI_EMPTY(uiscroll)
    LAPI_EMPTY(uihscrollbar)
    LAPI_EMPTY(uivscrollbar)
    LAPI_EMPTY(uiscrollbutton)
    LAPI_EMPTY(uihslider)
    LAPI_EMPTY(uivslider)
    LAPI_EMPTY(uisliderbutton)
    LAPI_EMPTY(uioffset)
    LAPI_EMPTY(uibutton)
    LAPI_EMPTY(uicond)
    LAPI_EMPTY(uicondbutton)
    LAPI_EMPTY(uitoggle)
    LAPI_EMPTY(uiimage)
    LAPI_EMPTY(uislotview)
    LAPI_EMPTY(uialtimage)
    LAPI_EMPTY(uicolor)
    LAPI_EMPTY(uimodcolor)
    LAPI_EMPTY(uistretchedimage)
    LAPI_EMPTY(uicroppedimage)
    LAPI_EMPTY(uiborderedimage)
    LAPI_EMPTY(uilabel)
    LAPI_EMPTY(uisetlabel)
    LAPI_EMPTY(uivarlabel)
    LAPI_EMPTY(uitexteditor)
    LAPI_EMPTY(uifield)
    LAPI_EMPTY(applychanges)
    LAPI_EMPTY(clearchanges)
    LAPI_EMPTY(getchanges)
#endif

    void reg_gui(lua::Table& t)
    {
        LAPI_REG(font);
        LAPI_REG(fontoffset);
        LAPI_REG(fonttex);
        LAPI_REG(fontscale);
        LAPI_REG(fontchar);
        LAPI_REG(fontskip);
        LAPI_REG(fontalias);
        LAPI_REG(menukeyclicktrig);

        LAPI_REG(hideui);
        LAPI_REG(showui);
        LAPI_REG(replaceui);
        LAPI_REG(uialign);
        LAPI_REG(uiclamp);
        LAPI_REG(uiwinmover);
        LAPI_REG(uitag);
        LAPI_REG(uivlist);
        LAPI_REG(uihlist);
        LAPI_REG(uitable);
        LAPI_REG(uispace);
        LAPI_REG(uifill);
        LAPI_REG(uiclip);
        LAPI_REG(uiscroll);
        LAPI_REG(uihscrollbar);
        LAPI_REG(uivscrollbar);
        LAPI_REG(uiscrollbutton);
        LAPI_REG(uihslider);
        LAPI_REG(uivslider);
        LAPI_REG(uisliderbutton);
        LAPI_REG(uioffset);
        LAPI_REG(uibutton);
        LAPI_REG(uicond);
        LAPI_REG(uicondbutton);
        LAPI_REG(uitoggle);
        LAPI_REG(uiimage);
        LAPI_REG(uislotview);
        LAPI_REG(uialtimage);
        LAPI_REG(uicolor);
        LAPI_REG(uimodcolor);
        LAPI_REG(uistretchedimage);
        LAPI_REG(uicroppedimage);
        LAPI_REG(uiborderedimage);
        LAPI_REG(uilabel);
        LAPI_REG(uisetlabel);
        LAPI_REG(uivarlabel);
        LAPI_REG(uitexteditor);
        LAPI_REG(uifield);
        LAPI_REG(applychanges);
        LAPI_REG(clearchanges);
        LAPI_REG(getchanges);
    }
}
