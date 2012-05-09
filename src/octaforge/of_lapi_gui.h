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

    void _lua_draw_text(
        const char *str, float sx, float sy, float k, vec color, float wrap
    )
    {
            glPushMatrix();
            glScalef(k, k, 1);
            draw_text(
                str, int(sx/k), int(sy/k),
                color.x * 255, color.y * 255, color.z * 255, 255,
                -1, wrap <= 0 ? -1 : wrap/k
            );
            glColor3f(1, 1, 1);
            glPopMatrix();
    }

    void _lua_draw_rect(
        float sx, float sy, float w, float h, vec4 color, bool mod
    )
    {
        if (mod) glBlendFunc(GL_ZERO, GL_SRC_COLOR);
        glDisable(GL_TEXTURE_2D);
        notextureshader->set();
        glColor4fv(color.v);
        glBegin(GL_QUADS);
        glVertex2f(sx,     sy);
        glVertex2f(sx + w, sy);
        glVertex2f(sx + w, sy + h);
        glVertex2f(sx,     sy + h);
        glEnd();
        glColor3f(1, 1, 1);
        glEnable(GL_TEXTURE_2D);
        defaultshader->set();
        if (mod) glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }

    void _lua_menukeyclicktrig() { GuiControl::menuKeyClickTrigger(); }

    struct Clip_Area
    {
        float x1, y1, x2, y2;

        Clip_Area(float x, float y, float w, float h) : x1(x), y1(y), x2(x+w), y2(y+h) {}

        void intersect(const Clip_Area &c)
        {
            x1 = max(x1, c.x1);
            y1 = max(y1, c.y1);
            x2 = max(x1, min(x2, c.x2));
            y2 = max(y1, min(y2, c.y2));

        }

        bool isfullyclipped(float x, float y, float w, float h)
        {
            return x1 == x2 || y1 == y2 || x >= x2 || y >= y2 || x+w <= x1 || y+h <= y1;
        }

        void scissor()
        {
            float margin = max((float(screen->w)/screen->h - 1)/2, 0.0f);

            int sx1 = clamp(int(floor((x1+margin)/(1 + 2*margin)*screen->w)), 0, screen->w),
                sy1 = clamp(int(floor(y1*screen->h)), 0, screen->h),
                sx2 = clamp(int(ceil((x2+margin)/(1 + 2*margin)*screen->w)), 0, screen->w),
                sy2 = clamp(int(ceil(y2*screen->h)), 0, screen->h);

            glScissor(sx1, screen->h - sy2, sx2-sx1, sy2-sy1);
        }
    };

    vector<Clip_Area> clipstack;

    void _lua_pushclip(float x, float y, float w, float h)
    {
        if (clipstack.empty()) glEnable(GL_SCISSOR_TEST);

        Clip_Area &c = clipstack.add(Clip_Area(x, y, w, h));
        if (clipstack.length() >= 2) c.intersect(clipstack[clipstack.length()-2]);

        c.scissor();
    }

    void _lua_popclip()
    {
        clipstack.pop();

        if  (clipstack.empty()) glDisable(GL_SCISSOR_TEST);
        else clipstack.last ().scissor();
    }

    bool _lua_isfullyclipped(float x, float y, float w, float h)
    {
        if    (clipstack.empty()) return false;
        return clipstack.last ().isfullyclipped(x, y, w, h);
    }

    void _lua_draw_ui(float x, float y, float w, float h, lua::Function draw)
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glMatrixMode(GL_PROJECTION);
        glPushMatrix();
        glLoadIdentity();
        glOrtho(x, x + w, y + h, y, -1, 1);

        glMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        glLoadIdentity();

        glColor3f(1, 1, 1);

        draw();

        glMatrixMode(GL_PROJECTION);
        glPopMatrix();
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix();
        glEnable(GL_BLEND);
    }

#else
    LAPI_EMPTY(font)
    LAPI_EMPTY(fontoffset)
    LAPI_EMPTY(fonttex)
    LAPI_EMPTY(fontscale)
    LAPI_EMPTY(fontchar)
    LAPI_EMPTY(fontskip)
    LAPI_EMPTY(fontalias)
    LAPI_EMPTY(draw_text)
    LAPI_EMPTY(draw_rect)
    LAPI_EMPTY(menukeyclicktrig)
    LAPI_EMPTY(pushclip)
    LAPI_EMPTY(popclip)
    LAPI_EMPTY(isfullyclipped)
    LAPI_EMPTY(draw_ui)
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
        LAPI_REG(draw_text);
        LAPI_REG(draw_rect);
        LAPI_REG(menukeyclicktrig);
        LAPI_REG(pushclip);
        LAPI_REG(popclip);
        LAPI_REG(isfullyclipped);
        LAPI_REG(draw_ui);
    }
}
