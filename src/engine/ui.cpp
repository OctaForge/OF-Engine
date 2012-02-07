/* based on newui by neal and eihrul, licensed under zlib */

#include "engine.h"
#include "textedit.h"
#include "of_lapi.h"
#include "client_engine_additions.h"

// a 'stack' where the last is the current focused editor
vector <editor*> editors;

editor *currentfocus()
{
    return editors.length() ? editors.last() : NULL;
}

editor *useeditor(const char *name, int mode, bool focus, const char *initval, bool password) // INTENSITY: password
{
    loopv(editors) if(strcmp(editors[i]->name, name) == 0) 
    {
        editor *e = editors[i];
        if(focus) { editors.add(e); editors.remove(i); } // re-position as last
        e->active = true;
        return e;
    }
    editor *e = new editor(name, mode, initval, password); // INTENSITY: Password
    if(focus) editors.add(e); else editors.insert(0, e); 
    return e;
}

static void focuseditor(editor *e)
{
    editors.removeobj(e);
    editors.add(e);
}

static void removeeditor(editor *e)
{
    editors.removeobj(e);
    DELETEP(e);
}

namespace gui
{
    struct World;

    World *world = NULL;

    struct Delayed_Update
    {
        enum
        {
            INT,
            FLOAT,
            STRING,
            ACTION
        } type;

        var::cvar *ev;
        lua::Function fun;

        union
        {
            int i;
            float f;
            char *s;
        } val;

        Delayed_Update() : type(ACTION), ev(NULL), fun(lua::Function()) { val.s = NULL; }
        Delayed_Update(const Delayed_Update& d): type(d.type), ev(d.ev), fun(d.fun)
        {
            switch (type)
            {
                case INT: val.i = d.val.i; break;
                case FLOAT: val.f = d.val.f; break;
                case STRING: val.s = newstring(d.val.s); break;
                case ACTION: val.s = NULL;
                default: break;
            }
        }
        ~Delayed_Update() { if((type == STRING || type == ACTION) && val.s) delete[] val.s; }

        void schedule(lua::Function f) { type = ACTION; fun = f; }
        void schedule(var::cvar *var, int i) { type = INT; ev = var; val.i = i; }
        void schedule(var::cvar *var, float f) { type = FLOAT; ev = var; val.f = f; }
        void schedule(var::cvar *var, const char *s) { type = STRING; ev = var; val.s = newstring(s); }

        int getint() const
        {
            switch(type)
            {
                case INT: return val.i;
                case FLOAT: return int(val.f);
                case STRING: return int(strtol(val.s, NULL, 0));
                default: return 0;
            }
        }

        float getfloat() const
        {
            switch(type)
            {
                case INT: return float(val.i);
                case FLOAT: return val.f;
                case STRING: return lapi::state.get<lua::Function>(
                    "tonumber"
                ).call<float>(val.s);
                default: return 0;
            }
        }

        const char *getstring() const
        {
            switch(type)
            {
                case INT: return lapi::state.get<lua::Function>(
                    "tostring"
                ).call<const char*>(val.i);
                case FLOAT: return lapi::state.get<lua::Function>(
                    "tostring"
                ).call<const char*>(val.f);
                case STRING: return val.s;
                default: return "";
            }
        }

        void run()
        {
            if (type == ACTION)
            {
                if (!fun.is_nil()) fun();
            }
            else if (ev) switch(ev->type)
            {
                case var::VAR_I: ev->set(getint(), true); break;
                case var::VAR_F: ev->set(getfloat(), true); break;
                case var::VAR_S: ev->set(getstring(), true); break;
            }
        }
    };

    static types::Vector<Delayed_Update> updatelater;

    template<class T> static void updateval(const char *var, T val, lua::Function onchange)
    {
        var::cvar *ev = var::get(var);
        if (!ev) return;

        Delayed_Update d;
        d.schedule(ev, val);
        updatelater.push_back(d);

        if (!onchange.is_nil())
        {
            Delayed_Update dd;
            dd.schedule(onchange);
            updatelater.push_back(dd);
        }
    }

    static float getfval(const char *var)
    {
        var::cvar *ev = var::get(var);
        if (!ev) return 0;

        switch (ev->type)
        {
            case var::VAR_I: return ev->curv.i;
            case var::VAR_F: return ev->curv.f;
            case var::VAR_S: return lapi::state.get<lua::Function>(
                "tonumber"
            ).call<float>(ev->curv.s);
            default: return 0;
        }
    }

    static const char *getsval(const char *var)
    {
        var::cvar *ev = var::get(var);
        if (!ev) return 0;

        switch (ev->type)
        {
            case var::VAR_I: return lapi::state.get<lua::Function>(
                "tostring"
            ).call<const char*>(ev->curv.i);
            case var::VAR_F: return lapi::state.get<lua::Function>(
                "tostring"
            ).call<const char*>(ev->curv.f);
            case var::VAR_S: return ev->curv.s;
            default: return 0;
        }
    }

    struct Object;

    Object *selected = NULL,
           *hovering = NULL,
           *focused  = NULL;
    float   hoverx   = 0,
            hovery   = 0,
            selectx  = 0,
            selecty  = 0;

    static inline bool isselected(const Object *o)
    {
        return o == selected;
    }

    static inline bool ishovering(const Object *o)
    {
        return o == hovering;
    }

    static inline bool isfocused(const Object *o)
    {
        return o == focused;
    }

    static void setfocus(Object *o)
    {
        focused = o;
    }

    static inline void clearfocus(const Object *o)
    {
        if (o == selected) selected = NULL;
        if (o == hovering) hovering = NULL;
        if (o ==  focused) focused  = NULL;
    }

    static void quad(float x, float y, float w, float h, float tx = 0, float ty = 0, float tw = 1, float th = 1)
    {
        glTexCoord2f(tx,      ty);      glVertex2f(x,     y);
        glTexCoord2f(tx + tw, ty);      glVertex2f(x + w, y);
        glTexCoord2f(tx + tw, ty + th); glVertex2f(x + w, y + h);
        glTexCoord2f(tx,      ty + th); glVertex2f(x,     y + h);
    }

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

    static vector<Clip_Area> clipstack;

    static void pushclip(float x, float y, float w, float h)
    {
        if (clipstack.empty()) glEnable(GL_SCISSOR_TEST);

        Clip_Area &c = clipstack.add(Clip_Area(x, y, w, h));
        if (clipstack.length() >= 2) c.intersect(clipstack[clipstack.length()-2]);

        c.scissor();
    }

    static void popclip()
    {
        clipstack.pop();

        if  (clipstack.empty()) glDisable(GL_SCISSOR_TEST);
        else clipstack.last ().scissor();
    }

    static bool isfullyclipped(float x, float y, float w, float h)
    {
        if    (clipstack.empty()) return false;
        return clipstack.last ().isfullyclipped(x, y, w, h);
    }

    enum
    {
        ALIGN_MASK    = 0xF,

        ALIGN_HMASK   = 0x3,
        ALIGN_HSHIFT  = 0,
        ALIGN_HNONE   = 0,
        ALIGN_LEFT    = 1,
        ALIGN_HCENTER = 2,
        ALIGN_RIGHT   = 3,

        ALIGN_VMASK   = 0xC,
        ALIGN_VSHIFT  = 2,
        ALIGN_VNONE   = 0<<2,
        ALIGN_BOTTOM  = 1<<2,
        ALIGN_VCENTER = 2<<2,
        ALIGN_TOP     = 3<<2,

        CLAMP_MASK    = 0xF0,
        CLAMP_LEFT    = 0x10,
        CLAMP_RIGHT   = 0x20,
        CLAMP_BOTTOM  = 0x40,
        CLAMP_TOP     = 0x80,

        NO_ADJUST     = ALIGN_HNONE | ALIGN_VNONE,
    };

    enum
    {
        TYPE_MISC = 0,
        TYPE_SCROLLER,
        TYPE_SCROLLBAR,
        TYPE_SCROLLBUTTON,
        TYPE_SLIDER,
        TYPE_SLIDERBUTTON,
        TYPE_IMAGE,
        TYPE_TAG,
        TYPE_WINDOW,
        TYPE_WINDOWMOVER,
        TYPE_TEXTEDITOR,
    };

    enum
    {
        ORIENT_HORIZ = 0,
        ORIENT_VERT,
    };

    struct Object
    {
        Object *parent;
        float x, y, w, h;
        uchar adjust;
        vector<Object *> children;

        Object() : parent(NULL), x(0), y(0), w(0), h(0), adjust(ALIGN_HCENTER | ALIGN_VCENTER) {}
        virtual ~Object()
        {
            clearfocus(this);
            children.deletecontents();
        }

        virtual void init() {}

        virtual int forks()      const { return  0; }
        virtual int choosefork() const { return -1; }

        #define loopchildren(o, body) do { \
            int numforks = forks(); \
            if (numforks > 0) \
            { \
                int i = choosefork(); \
                if (children.inrange(i)) \
                { \
                    Object *o = children[i]; \
                    body; \
                } \
            } \
            for (int i = numforks; i < children.length(); i++) \
            { \
                Object *o = children[i]; \
                body; \
            } \
        } while(0)


        #define loopchildrenrev(o, body) do { \
            int numforks = forks(); \
            for (int i = children.length()-1; i >= numforks; i--) \
            { \
                Object *o = children[i]; \
                body; \
            } \
            if (numforks > 0) \
            { \
                int i = choosefork(); \
                if (children.inrange(i)) \
                { \
                    Object *o = children[i]; \
                    body; \
                } \
            } \
        } while(0)

        #define loopinchildren(o, cx, cy, body) \
            loopchildren(o, \
            { \
                float o##x = cx - o->x; \
                float o##y = cy - o->y; \
                if   (o##x >= 0 && o##x < o->w && o##y >= 0 && o##y < o->h) \
                { \
                    body; \
                } \
            })

        #define loopinchildrenrev(o, cx, cy, body) \
            loopchildrenrev(o, \
            { \
                float o##x = cx - o->x; \
                float o##y = cy - o->y; \
                if   (o##x >= 0 && o##x < o->w && o##y >= 0 && o##y < o->h) \
                { \
                    body; \
                } \
            })

        virtual void layout()
        {
            w = h = 0;
            loopchildren(o,
            {
                o->x = o->y = 0;
                o->layout();
                w = max(w, o->x + o->w);
                h = max(h, o->y + o->h);
            });
        }

        void adjustchildrento(float px, float py, float pw, float ph)
        {
            loopchildren(o, o->adjustlayout(px, py, pw, ph));
        }

        virtual void adjustchildren()
        {
            adjustchildrento(0, 0, w, h);
        }

        virtual void adjustlayout(float px, float py, float pw, float ph)
        {
            switch (adjust&ALIGN_HMASK)
            {
                case ALIGN_LEFT:    x = px; break;
                case ALIGN_HCENTER: x = px + (pw - w) / 2; break;
                case ALIGN_RIGHT:   x = px + pw - w; break;
            }

            switch (adjust&ALIGN_VMASK)
            {
                case ALIGN_BOTTOM:  y = py; break;
                case ALIGN_VCENTER: y = py + (ph - h) / 2; break;
                case ALIGN_TOP:     y = py + ph - h; break;
            }

            if (adjust&CLAMP_MASK)
            {
                if (adjust&CLAMP_LEFT)   x = px;
                if (adjust&CLAMP_RIGHT)  w = px + pw - x;
                if (adjust&CLAMP_BOTTOM) y = py;
                if (adjust&CLAMP_TOP)    h = py + ph - y;
            }

            adjustchildren();
        }

        virtual Object *target(float cx, float cy)
        {
            loopinchildrenrev(o, cx, cy,
            {
                Object *c = o->target(ox, oy);
                if     (c) return c;
            });

            return NULL;
        }

        virtual bool key(int code, bool isdown, int cooked)
        {
            loopchildrenrev(o,
            {
                if (o->key(code, isdown, cooked)) return true;
            });

            return false;
        }

        virtual void draw(float sx, float sy)
        {
            loopchildren(o,
            {
                if (!isfullyclipped(sx + o->x, sy + o->y, o->w, o->h))
                    o->draw(sx + o->x, sy + o->y);
            });
        }

        void draw()
        {
            draw(x, y);
        }

        virtual Object *hover(float cx, float cy)
        {
            loopinchildrenrev(o, cx, cy,
            {
                Object *c = o->hover(ox, oy);
                if (c == o) { hoverx = ox; hovery = oy; }
                if (c) return c;
            });

            return NULL;
        }

        virtual void hovering(float cx, float cy)
        {
        }

        virtual void selecting(float cx, float cy)
        {
        }

        virtual Object *select(float cx, float cy)
        {
            loopinchildrenrev(o, cx, cy,
            {
                Object *c = o->select(ox, oy);
                if (c == o) { selectx = ox; selecty = oy; }
                if (c) return c;
            });

            return NULL;
        }

        virtual bool allowselect(Object *o)
        {
            return false;
        }

        virtual void selected(float cx, float cy) {}

        virtual const char *getname() const
        {
            return "";
        }

        virtual const int gettype() const
        {
            return TYPE_MISC;
        }

        bool isnamed(const char *name) const
        {
            return !strcmp(name, getname());
        }

        bool istype(int type) const
        {
            return (type == gettype());
        }

        Object *findname(int type, const char *name, bool recurse = true, const Object *exclude = NULL) const
        {
            loopchildren(o,
            {
                if(o != exclude &&
                    o->gettype() == type &&
                    (!name || o->isnamed(name))
                )
                    return o;
            });

            if (recurse) loopchildren(o,
            {
                if (o != exclude)
                {
                    Object *found = o->findname(type, name);
                    if (found) return found;
                }
            });

            return NULL;
        }

        Object *findsibling(int type, const char *name) const
        {
            for (const Object *prev = this, *cur = parent; cur; prev = cur, cur = cur->parent)
            {
                Object *o = cur->findname(type, name, true, prev);
                if     (o) return o;
            }

            return NULL;
        }

        void remove(Object *o)
        {
            children.removeobj(o);
            delete o;
        }
    };

    struct list : Object
    {
        bool horizontal;
        float space;

        list(bool horizontal, float space = 0) : horizontal(horizontal), space(space) {}

        void layout()
        {
            w = h = 0;
            if (horizontal)
            {
                loopchildren(o,
                {
                    o->x = w;
                    o->y = 0;
                    o->layout();
                    w += o->w;
                    h = max(h, o->y + o->h);
                });
                w += space*max(children.length() - 1, 0);
            }
            else
            {
                loopchildren(o,
                {
                    o->x = 0;
                    o->y = h;
                    o->layout();
                    h += o->h;
                    w = max(w, o->x + o->w);
                });
                h += space*max(children.length() - 1, 0);
            }
        }

        /* PAS merges */
        void adjustchildren()
        {
            if (children.empty()) return;

            if (horizontal)
            {
                float offset = 0;
                loopchildren(o,
                {
                    o->x = offset;
                    offset += o->w;
                    o->adjustlayout(o->x, 0, offset - o->x, h);
                    offset += space;
                });
            }
            else
            {
                float offset = 0;
                loopchildren(o,
                {
                    o->y = offset;
                    offset += o->h;
                    o->adjustlayout(0, o->y, w, offset - o->y);
                    offset += space;
                });
            }
        }
    };

    struct Table : Object
    {
        int columns;
        float space;
        vector<float> widths, heights;

        Table(int columns, float space = 0) : columns(columns), space(space) {}

        void layout()
        {
            widths.setsize(0);
            heights.setsize(0);

            int column = 0, row = 0;

            loopchildren(o,
            {
                o->layout();

                if (!widths.inrange(column)) widths.add(o->w);
                else if (o->w > widths[column]) widths[column] = o->w;

                if (!heights.inrange(row)) heights.add(o->h);
                else if (o->h > heights[row]) heights[row] = o->h;

                column = (column + 1) % columns;
                if (!column) row++;
            });

            w = h = 0;
            column = row = 0;
            float offset = 0;

            loopchildren(o,
            {
                o->x = offset;
                o->y = h;
                o->adjustlayout(o->x, o->y, widths[column], heights[row]);
                offset += widths[column];
                w = max(w, offset);
                column = (column + 1) % columns;

                if (!column)
                {
                    offset = 0;
                    h += heights[row];
                    row++;
                }
            });

            if (column) h += heights[row];

            w += space*max(widths.length() - 1, 0);
            h += space*max(heights.length() - 1, 0);
        }

        void adjustchildren()
        {
            if (children.empty()) return;

            float cspace = w, rspace = h;
            loopv(widths) cspace -= widths[i];
            loopv(heights) rspace -= heights[i];
            cspace /= max(widths.length() - 1, 1);
            rspace /= max(heights.length() - 1, 1);

            int column = 0, row = 0;
            float offsetx = 0, offsety = 0;

            loopchildren(o,
            {
                o->x = offsetx;
                o->y = offsety;
                o->adjustlayout(offsetx, offsety, widths[column], heights[row]);
                offsetx += widths[column] + cspace;
                column = (column + 1) % columns;

                if (!column)
                {
                    offsetx = 0;
                    offsety += heights[row] + rspace;
                    row++;
                }
            });
        }
    };

    struct Spacer : Object
    {
        float spacew, spaceh;

        Spacer(float spacew, float spaceh) : spacew(spacew), spaceh(spaceh) {}

        void layout()
        {
            w = spacew;
            h = spaceh;
            loopchildren(o,
            {
                o->x = spacew;
                o->y = spaceh;
                o->layout();
                w = max(w, o->x + o->w);
                h = max(h, o->y + o->h);
            });
            w += spacew;
            h += spaceh;
        }

        void adjustchildren()
        {
            adjustchildrento(spacew, spaceh, w - 2*spacew, h - 2*spaceh);
        }
    };

    struct Filler : Object
    {
        float minw, minh;

        Filler(float minw, float minh) : minw(minw), minh(minh) {}

        void layout()
        {
            Object::layout();

            w = max(w, minw);
            h = max(h, minh);
        }
    };

    struct Offsetter : Object
    {
        float offsetx, offsety;

        Offsetter(float offsetx, float offsety) : offsetx(offsetx), offsety(offsety) {}

        void layout()
        {
            Object::layout();

            loopchildren(o,
            {
                o->x += offsetx;
                o->y += offsety;
            });

            w += offsetx;
            h += offsety;
        }

        void adjustchildren()
        {
            adjustchildrento(offsetx, offsety, w - offsetx, h - offsety);
        }
    };

    struct Clipper : Object
    {
        float clipw, cliph, virtw, virth;

        Clipper(float clipw = 0, float cliph = 0) : clipw(clipw), cliph(cliph), virtw(0), virth(0) {}

        void layout()
        {
            Object::layout();

            virtw = w;
            virth = h;
            if (clipw) w = min(w, clipw);
            if (cliph) h = min(h, cliph);
        }

        void adjustchildren()
        {
            adjustchildrento(0, 0, virtw, virth);
        }

        void draw(float sx, float sy)
        {
            if ((clipw && virtw > clipw) || (cliph && virth > cliph))
            {
                pushclip(sx, sy, w, h);
                Object::draw(sx, sy);
                popclip();
            }
            else Object::draw(sx, sy);
        }
    };

    struct Conditional : Object
    {
        lua::Function cond;

        Conditional(const lua::Function& cond) : cond(cond) {}
        ~Conditional()
        {
            cond.clear();
        }

        int forks()      const { return 2; }
        int choosefork() const { return cond.call<bool>() ? 0 : 1; }
    };

    struct Button : Object
    {
        lua::Function onselect;
        bool queued;

        Button(const lua::Function& os) : onselect(os), queued(false) {}
        ~Button()
        {
            onselect.clear();
        }

        int forks()      const { return 3; }
        int choosefork() const { return isselected(this) ? 2 : (ishovering(this) ? 1 : 0); }

        Object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void selected(float cx, float cy)
        {
            Delayed_Update d;
            d.schedule(onselect);
            updatelater.push_back(d);
        }
    };

    struct Conditional_Button : Button
    {
        lua::Function cond;

        Conditional_Button(const lua::Function& cond, const lua::Function& onselect):
            Button(onselect), cond(cond) {}

        ~Conditional_Button()
        {
            cond.clear();
        }

        int forks() const { return 4; }
        int choosefork() const
        {
            return (cond.call<bool>() ? (1 + Button::choosefork()) : 0);
        }

        void selected(float cx, float cy)
        {
            if (cond.call<bool>())
                Button::selected(cx, cy);
        }
    };

    VAR(uitogglehside, 1, 0, 0);
    VAR(uitogglevside, 1, 0, 0);

    struct Toggle : Button
    {
        lua::Function cond;
        float split;

        Toggle(const lua::Function& cond, const lua::Function& onselect, float split = 0):
            Button(onselect), cond(cond), split(split) {}

        ~Toggle()
        {
            cond.clear();
        }

        int forks() const { return 4; }
        int choosefork() const
        {
            return (cond.call<bool>() ? 2 : 0) + (ishovering(this) ? 1 : 0);
        }

        Object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            if (target(cx, cy))
            {
                uitogglehside = cx < w*split ? 0 : 1;
                uitogglevside = cy < h*split ? 0 : 1;
                return this;
            }
            return NULL;
        }
    };

    struct Scroller : Clipper
    {
        float offsetx, offsety;
        bool canscroll;

        Scroller(float clipw = 0, float cliph = 0) : Clipper(clipw, cliph), offsetx(0), offsety(0) {}

        Object *target(float cx, float cy)
        {
            if (cx + offsetx >= virtw || cy + offsety >= virth) return NULL;
            return Object::target(cx + offsetx, cy + offsety);
        }

        Object *hover(float cx, float cy)
        {
            if(cx + offsetx >= virtw || cy + offsety >= virth)
            {
                canscroll = false;
                return NULL;
            }
            canscroll = true;
            return Object::hover(cx + offsetx, cy + offsety);
        }

        Object *select(float cx, float cy)
        {
            if (cx + offsetx >= virtw || cy + offsety >= virth) return NULL;
            return Object::select(cx + offsetx, cy + offsety);
        }

        bool key(int code, bool isdown, int cooked);

        void draw(float sx, float sy)
        {
            if ((clipw && virtw > clipw) || (cliph && virth > cliph))
            {
                pushclip(sx, sy, w, h);
                Object::draw(sx - offsetx, sy - offsety);
                popclip();
            }
            else Object::draw(sx, sy);
        }

        float hlimit()  const { return max(virtw - w, 0.0f); }
        float vlimit()  const { return max(virth - h, 0.0f); }
        float hoffset() const { return offsetx / max(virtw, w); }
        float voffset() const { return offsety / max(virth, h); }
        float hscale()  const { return w / max(virtw, w); }
        float vscale()  const { return h / max(virth, h); }

        void addhscroll(float hscroll) { sethscroll(offsetx + hscroll); }
        void addvscroll(float vscroll) { setvscroll(offsety + vscroll); }
        void sethscroll(float hscroll) { offsetx = clamp(hscroll, 0.0f, hlimit()); }
        void setvscroll(float vscroll) { offsety = clamp(vscroll, 0.0f, vlimit()); }

        const int gettype() const { return TYPE_SCROLLER; }
    };

    struct scrollbar : Object
    {
        float arrowsize, arrowspeed;
        int arrowdir;

        scrollbar(float arrowsize = 0, float arrowspeed = 0) : arrowsize(arrowsize), arrowspeed(arrowspeed), arrowdir(0) {}

        int forks()      const { return 5; }
        int choosefork() const
        {
            switch(arrowdir)
            {
                case -1: return isselected(this) ? 2 : (ishovering(this) ? 1 : 0);
                case  1: return isselected(this) ? 4 : (ishovering(this) ? 3 : 0);
            }
            return 0;
        }

        virtual int choosedir(float cx, float cy) const
        {
            return 0;
        }
        virtual int getorient() const = 0;

        Object *hover(float cx, float cy)
        {
            Object *o = Object::hover(cx, cy);
            if (o) return o;
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            Object *o = Object::select(cx, cy);
            if (o) return o;
            return target(cx, cy) ? this : NULL;
        }

        const int gettype() const { return TYPE_SCROLLBAR; }

        virtual void scrollto(float cx, float cy)
        {
        }

        void selected(float cx, float cy)
        {
            arrowdir = choosedir(cx, cy);
            if (!arrowdir) scrollto(cx, cy);
            else hovering(cx, cy);
        }

        virtual void arrowscroll()
        {
        }

        void hovering(float cx, float cy)
        {
            if (isselected(this))
            {
                if (arrowdir) arrowscroll();
            }
            else
            {
                Object *button = findname(TYPE_SCROLLBUTTON, NULL, false);
                if (button && isselected(button))
                {
                    arrowdir = 0;
                    button->hovering(cx - button->x, cy - button->y);
                }
                else arrowdir = choosedir(cx, cy);
            }
        }

        bool allowselect(Object *o)
        {
            return children.find(o) >= 0;
        }

        virtual void movebutton(Object *o, float fromx, float fromy, float tox, float toy) = 0;
    };

    bool Scroller::key(int code, bool isdown, int cooked)
    {
        if(Object::key(code, isdown, cooked)) return true;
        if(!canscroll)
            return false;

        if(code == -4 || code == -5)
        {
            scrollbar *slider = (scrollbar *) findsibling(TYPE_SCROLLBAR, NULL);
            if(!slider) return false;

            float adjust = (code == -4 ? -.2 : .2) * slider->arrowspeed;
            if(slider->getorient() == ORIENT_VERT)
                addvscroll(adjust);
            else
                addhscroll(adjust);
            return true;
        }
        return false;
    }

    struct Scroll_Button : Object
    {
        float offsetx, offsety;

        Scroll_Button() : offsetx(0), offsety(0) {}

        int forks()      const { return 3; }
        int choosefork() const { return isselected(this) ? 2 : (ishovering(this) ? 1 : 0); }

        Object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void hovering(float cx, float cy)
        {
            if (isselected(this) && parent->isnamed("scrollbar"))
            {
                scrollbar *scroll = (scrollbar*)parent;
                if (!scroll) return;
                scroll->movebutton(this, offsetx, offsety, cx, cy);
            }
        }

        void selected(float cx, float cy)
        {
            offsetx = cx;
            offsety = cy;
        }

        const int gettype() const { return TYPE_SCROLLBUTTON; }
    };

    struct Horizontal_Scrollbar : scrollbar
    {
        Horizontal_Scrollbar(float arrowsize = 0, float arrowspeed = 0) : scrollbar(arrowsize, arrowspeed) {}

        int choosedir(float cx, float cy) const
        {
            if (cx < arrowsize) return -1;
            else if (cx >= w - arrowsize) return 1;
            return 0;
        }

        int getorient() const
        {
            return ORIENT_HORIZ;
        }

        void arrowscroll()
        {
            Scroller *scroll = (Scroller*) findsibling(TYPE_SCROLLER, NULL);
            if (!scroll) return;
            scroll->addhscroll(arrowdir*arrowspeed*curtime/1000.0f);
        }

        void scrollto(float cx, float cy)
        {
            Scroller *scroll = (Scroller*) findsibling(TYPE_SCROLLER, NULL);
            if (!scroll) return;
            Scroll_Button *btn = (Scroll_Button*) findname(TYPE_SCROLLBUTTON, NULL, false);
            if (!btn) return;
            float bscale = (max(w - 2*arrowsize, 0.0f) - btn->w) / (1 - scroll->hscale()),
                  offset = bscale > 1e-3f ? (cx - arrowsize)/bscale : 0;
            scroll->sethscroll(offset*scroll->virtw);
        }

        void adjustchildren()
        {
            Scroller *scroll = (Scroller*) findsibling(TYPE_SCROLLER, NULL);
            if (!scroll) return;
            Scroll_Button *btn = (Scroll_Button*) findname(TYPE_SCROLLBUTTON, NULL, false);
            if (!btn) return;
            float bw = max(w - 2*arrowsize, 0.0f)*scroll->hscale();
            btn->w = max(btn->w, bw);
            float bscale = scroll->hscale() < 1 ? (max(w - 2*arrowsize, 0.0f) - btn->w) / (1 - scroll->hscale()) : 1;
            btn->x = arrowsize + scroll->hoffset()*bscale;
            btn->adjust &= ~ALIGN_HMASK;

            scrollbar::adjustchildren();
        }

        void movebutton(Object *o, float fromx, float fromy, float tox, float toy)
        {
            scrollto(o->x + tox - fromx, o->y + toy);
        }
    };

    struct Vertical_Scrollbar : scrollbar
    {
        Vertical_Scrollbar(float arrowsize = 0, float arrowspeed = 0) : scrollbar(arrowsize, arrowspeed) {}

        int choosedir(float cx, float cy) const
        {
            if (cy < arrowsize) return -1;
            else if (cy >= h - arrowsize) return 1;
            return 0;
        }

        int getorient() const
        {
            return ORIENT_VERT;
        }

        void arrowscroll()
        {
            Scroller *scroll = (Scroller*) findsibling(TYPE_SCROLLER, NULL);
            if (!scroll) return;
            scroll->addvscroll(arrowdir*arrowspeed*curtime/1000.0f);
        }

        void scrollto(float cx, float cy)
        {
            Scroller *scroll = (Scroller*) findsibling(TYPE_SCROLLER, NULL);
            if (!scroll) return;
            Scroll_Button *btn = (Scroll_Button*) findname(TYPE_SCROLLBUTTON, NULL, false);
            if (!btn) return;
            float bscale = (max(h - 2*arrowsize, 0.0f) - btn->h) / (1 - scroll->vscale()),
                  offset = bscale > 1e-3f ? (cy - arrowsize)/bscale : 0;
            scroll->setvscroll(offset*scroll->virth);
        }

        void adjustchildren()
        {
            Scroller *scroll = (Scroller*) findsibling(TYPE_SCROLLER, NULL);
            if (!scroll) return;
            Scroll_Button *btn = (Scroll_Button*) findname(TYPE_SCROLLBUTTON, NULL, false);
            if (!btn) return;
            float bh = max(h - 2*arrowsize, 0.0f)*scroll->vscale();
            btn->h = max(btn->h, bh);
            float bscale = scroll->vscale() < 1 ? (max(h - 2*arrowsize, 0.0f) - btn->h) / (1 - scroll->vscale()) : 1;
            btn->y = arrowsize + scroll->voffset()*bscale;
            btn->adjust &= ~ALIGN_VMASK;

            scrollbar::adjustchildren();
        }

        void movebutton(Object *o, float fromx, float fromy, float tox, float toy)
        {
            scrollto(o->x + tox, o->y + toy - fromy);
        }
    };

    static bool checkalphamask(Texture *tex, float x, float y)
    {
        if (!tex->alphamask)
        {
            loadalphamask(tex);
            if (!tex->alphamask) return true;
        }
        int tx = clamp(int(floor(x*tex->xs)), 0, tex->xs-1),
            ty = clamp(int(floor(y*tex->ys)), 0, tex->ys-1);
        if (tex->alphamask[ty*((tex->xs+7)/8) + tx/8] & (1<<(tx%8))) return true;
        return false;
    }

    struct Slider : Object
    {
        const char *var;
        float vmin, vmax;

        lua::Function onchange;
        float arrowsize;
        float stepsize;
        int steptime;

        int laststep;
        int arrowdir;

        Slider(const char *varname, float min = 0, float max = 0, lua::Function onchange = lua::Function(), float arrowsize = 0, float stepsize = 1, int steptime = 1000) :
        var(varname), vmin(min), vmax(max), onchange(onchange), arrowsize(arrowsize), stepsize(stepsize), steptime(steptime), laststep(0), arrowdir(0)
        {
            if (!var) var = "";
            var::cvar *ev = var::get(var);
            if (!ev)   ev = var::regvar(var, new var::cvar(var, vmin));

            if (vmin == 0 && vmax == 0)
            {
                if (ev->type == var::VAR_I)
                {
                    vmin = ev->minv.i;
                    vmax = ev->maxv.i;
                }
                else if (ev->type == var::VAR_F)
                {
                    vmin = ev->minv.f;
                    vmax = ev->maxv.f;
                }
            }
        }

        void dostep(int n)
        {
            int maxstep = fabs(vmax - vmin) / stepsize;
            int curstep = (getfval(var) - min(vmin, vmax)) / stepsize;
            int newstep = clamp(curstep + n, 0, maxstep);

            updateval(var, min(vmax, vmin) + newstep * stepsize, onchange);
        }

        void setstep(int n)
        {
            int steps = fabs(vmax - vmin) / stepsize;
            int newstep = clamp(n, 0, steps);

            updateval(var, min(vmax, vmin) + newstep * stepsize, onchange);
        }

        bool key(int code, bool isdown, int cooked)
        {
            if(Object::key(code, isdown, cooked)) return true;

            if(ishovering(this))
                goto scroll;
            loopchildren(o,
                if(ishovering(o))
                    goto scroll;
            );

            return false;

            scroll:

            switch(code)
            {
                case SDLK_UP:
                case SDLK_LEFT:
                    dostep(-1);
                    return true;
                case -4:
                    dostep(-3);
                    return true;
                case SDLK_DOWN:
                case SDLK_RIGHT:
                    dostep(1);
                    return true;
                case -5:
                    dostep(3);
                    return true;
            }
            return false;
        }

        int forks() const { return 5; }
        int choosefork() const
        {
            switch(arrowdir)
            {
                case -1: return isselected(this) ? 2 : (ishovering(this) ? 1 : 0);
                case 1: return isselected(this) ? 4 : (ishovering(this) ? 3 : 0);
            }
            return 0;
        }

        virtual int choosedir(float cx, float cy) const { return 0; }

        Object *hover(float cx, float cy)
        {
            Object *o = Object::hover(cx, cy);
            if(o) return o;
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            Object *o = Object::select(cx, cy);
            if(o) return o;
            return target(cx, cy) ? this : NULL;
        }

        const int gettype() const { return TYPE_SLIDER; }

        virtual void scrollto(float cx, float cy)
        {
        }

        void selected(float cx, float cy)
        {
            arrowdir = choosedir(cx, cy);
            if(!arrowdir) scrollto(cx, cy);
            else hovering(cx, cy);
        }

        void arrowscroll()
        {
            if(laststep + steptime > totalmillis)
                return;

            laststep = totalmillis;
            dostep(arrowdir);
        }

        void hovering(float cx, float cy)
        {
            if(isselected(this))
            {
                if(arrowdir) arrowscroll();
            }
            else
            {
                Object *button = findname(TYPE_SLIDERBUTTON, NULL, false);
                if(button && isselected(button))
                {
                    arrowdir = 0;
                    button->hovering(cx - button->x, cy - button->y);
                }
                else arrowdir = choosedir(cx, cy);
            }
        }

        bool allowselect(Object *o)
        {
            return children.find(o) >= 0;
        }

        virtual void movebutton(Object *o, float fromx, float fromy, float tox, float toy) = 0;
    };

    struct Slider_Button : Object
    {
        float offsetx, offsety;

        Slider_Button() : offsetx(0), offsety(0) {}

        int forks() const { return 3; }
        int choosefork() const { return isselected(this) ? 2 : (ishovering(this) ? 1 : 0); }

        Object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void hovering(float cx, float cy)
        {
            if(isselected(this))
            {
                if(!parent || parent->gettype() != TYPE_SLIDER) return;
                Slider *slider = (Slider *) parent;
                slider->movebutton(this, offsetx, offsety, cx, cy);
            }
        }

        void selected(float cx, float cy)
        {
            offsetx = cx;
            offsety = cy;
        }

        void layout()
        {
            float lastw = w, lasth = h;
            Object::layout();
            if(isselected(this))
            {
                w = lastw;
                h = lasth;
            }
        }

        const int gettype() const { return TYPE_SLIDERBUTTON; }
    };

    struct Horizontal_Slider : Slider
    {
        Horizontal_Slider(const char *varname, float vmin = 0, float vmax = 0, lua::Function onchange = lua::Function(), float arrowsize = 0, float stepsize = 1, int steptime = 1000) : Slider(varname, vmin, vmax, onchange, arrowsize, stepsize, steptime) {}

        int choosedir(float cx, float cy) const
        {
            if(cx < arrowsize) return -1;
            else if(cx >= w - arrowsize) return 1;
            return 0;
        }

        void scrollto(float cx, float cy)
        {
            Slider_Button *button = (Slider_Button *) findname(TYPE_SLIDERBUTTON, NULL, false);
            if(!button) return;

            float pos = clamp((cx - arrowsize - button->w / 2) / (w - 2 * arrowsize - button->w), 0.f, 1.f);

            int steps = fabs(vmax - vmin) / stepsize;
            int step = lroundf(steps * pos);

            setstep(step);
        }

        void adjustchildren()
        {
            Slider_Button *button = (Slider_Button *) findname(TYPE_SLIDERBUTTON, NULL, false);
            if(!button) return;

            int steps = fabs(vmax - vmin) / stepsize;
            int curstep = (getfval(var) - min(vmax, vmin)) / stepsize;
            float width = max(w - 2  *arrowsize, 0.0f);

            button->w = max(button->w, width / steps);
            button->x = arrowsize + (width - button->w) * curstep / steps;
            button->adjust &= ~ALIGN_HMASK;

            Slider::adjustchildren();
        }

        void movebutton(Object *o, float fromx, float fromy, float tox, float toy)
        {
            scrollto(o->x + o->w / 2 + tox - fromx, o->y + toy);
        }
    };

    struct Vertical_Slider : Slider
    {
        Vertical_Slider(const char *varname, float vmin = 0, float vmax = 0, lua::Function onchange = lua::Function(), float arrowsize = 0, float stepsize = 1, int steptime = 1000) : Slider(varname, vmin, vmax, onchange, arrowsize, stepsize, steptime) {}

        int choosedir(float cx, float cy) const
        {
            if(cy < arrowsize) return -1;
            else if(cy >= h - arrowsize) return 1;
            return 0;
        }

        void scrollto(float cx, float cy)
        {
            Slider_Button *button = (Slider_Button *) findname(TYPE_SLIDERBUTTON, NULL, false);
            if(!button) return;

            float pos = clamp((cy - arrowsize - button->h / 2) / (h - 2 * arrowsize - button->h), 0.f, 1.f);

            int steps = (max(vmax, vmin) - min(vmax, vmin)) / stepsize;
            int step = lroundf(steps * pos);
            setstep(step);
        }

        void adjustchildren()
        {
            Slider_Button *button = (Slider_Button *) findname(TYPE_SLIDERBUTTON, NULL, false);
            if(!button) return;

            int steps = (max(vmax, vmin) - min(vmax, vmin)) / stepsize + 1;
            int curstep = (getfval(var) - min(vmax, vmin)) / stepsize;
            float height = max(h - 2  *arrowsize, 0.0f);

            button->h = max(button->h, height / steps);
            button->y = arrowsize + (height - button->h) * curstep / steps;
            button->adjust &= ~ALIGN_VMASK;

            Slider::adjustchildren();
        }

        void movebutton(Object *o, float fromx, float fromy, float tox, float toy)
        {
            scrollto(o->x + o->h / 2 + tox, o->y + toy - fromy);
        }
    };

    struct Rectangle : Filler
    {
        enum { SOLID = 0, MODULATE };

        int type;
        vec4 color;

        Rectangle(int type, float r, float g, float b, float a, float minw = 0, float minh = 0) : Filler(minw, minh), type(type), color(r, g, b, a) {}

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            return o ? o : this;
        }

        void draw(float sx, float sy)
        {
            if (type==MODULATE) glBlendFunc(GL_ZERO, GL_SRC_COLOR);
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
            if (type==MODULATE) glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            Object::draw(sx, sy);
        }
    };

    struct Image : Filler
    {
        Texture *tex;

        Image(Texture *tex, float minw = 0, float minh = 0) : Filler(minw, minh), tex(tex) {}

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            if (o) return o;
            if (tex->bpp < 32) return this;
            return checkalphamask(tex, cx/w, cy/h) ? this : NULL;
        }

        void draw(float sx, float sy)
        {
            glBindTexture(GL_TEXTURE_2D, tex->id);
            glBegin(GL_QUADS);
            quad(sx, sy, w, h);
            glEnd();

            Object::draw(sx, sy);
        }

        const int gettype() const { return TYPE_IMAGE; }
    };

    VAR(thumbtime, 0, 25, 1000);
    static int lastthumbnail = 0;

    struct Slot_Viewer : Filler
    {
        int slotnum;

        Slot_Viewer(int slotnum, float minw = 0, float minh = 0) : Filler(minw, minh), slotnum(slotnum) {}

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            if (o || !texmru.inrange(slotnum)) return o;
            VSlot &vslot = lookupvslot(texmru[slotnum], false);
            if(vslot.slot->sts.length() && (vslot.slot->loaded || vslot.slot->thumbnail)) return this;
            return NULL;
        }

        void drawslot(Slot &slot, VSlot &vslot, float sx, float sy)
        {
            Texture *tex = notexture, *glowtex = NULL, *layertex = NULL;
            VSlot *layer = NULL;
            if (slot.loaded)
            {
                tex = slot.sts[0].t;
                if(slot.texmask&(1<<TEX_GLOW)) {
                    loopv(slot.sts) if(slot.sts[i].type==TEX_GLOW)
                    { glowtex = slot.sts[i].t; break; }
                }
                if (vslot.layer)
                {
                    layer = &lookupvslot(vslot.layer);
                    if(!layer->slot->sts.empty())
                        layertex = layer->slot->sts[0].t;
                }
            }
            else if (slot.thumbnail) tex = slot.thumbnail;
            float xt, yt;
            xt = min(1.0f, tex->xs/(float)tex->ys),
            yt = min(1.0f, tex->ys/(float)tex->xs);

            static Shader *rgbonlyshader = NULL;
            if (!rgbonlyshader) rgbonlyshader = lookupshaderbyname("rgbonly");
            rgbonlyshader->set();

            float tc[4][2] = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 0, 1 } };
            int xoff = vslot.xoffset, yoff = vslot.yoffset;
            if (vslot.rotation)
            {
                if ((vslot.rotation&5) == 1) { swap(xoff, yoff); loopk(4) swap(tc[k][0], tc[k][1]); }
                if (vslot.rotation >= 2 && vslot.rotation <= 4) { xoff *= -1; loopk(4) tc[k][0] *= -1; }
                if (vslot.rotation <= 2 || vslot.rotation == 5) { yoff *= -1; loopk(4) tc[k][1] *= -1; }
            }
            loopk(4) { tc[k][0] = tc[k][0]/xt - float(xoff)/tex->xs; tc[k][1] = tc[k][1]/yt - float(yoff)/tex->ys; }
            if(slot.loaded) glColor3fv(vslot.colorscale.v);
            glBindTexture(GL_TEXTURE_2D, tex->id);
            glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2fv(tc[0]); glVertex2f(sx,   sy);
            glTexCoord2fv(tc[1]); glVertex2f(sx+w, sy);
            glTexCoord2fv(tc[3]); glVertex2f(sx,   sy+h);
            glTexCoord2fv(tc[2]); glVertex2f(sx+w, sy+h);
            glEnd();

            if (glowtex)
            {
                glBlendFunc(GL_SRC_ALPHA, GL_ONE);
                glBindTexture(GL_TEXTURE_2D, glowtex->id);
                glColor3fv(vslot.glowcolor.v);
                glBegin(GL_TRIANGLE_STRIP);
                glTexCoord2fv(tc[0]); glVertex2f(sx,   sy);
                glTexCoord2fv(tc[1]); glVertex2f(sx+w, sy);
                glTexCoord2fv(tc[3]); glVertex2f(sx,   sy+h);
                glTexCoord2fv(tc[2]); glVertex2f(sx+w, sy+h);
                glEnd();
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            }
            if (layertex)
            {
                glBindTexture(GL_TEXTURE_2D, layertex->id);
                glColor3fv(layer->colorscale.v);
                glBegin(GL_TRIANGLE_STRIP);
                glTexCoord2fv(tc[0]); glVertex2f(sx+w/2, sy+h/2);
                glTexCoord2fv(tc[1]); glVertex2f(sx+w,   sy+h/2);
                glTexCoord2fv(tc[3]); glVertex2f(sx+w/2, sy+h);
                glTexCoord2fv(tc[2]); glVertex2f(sx+w,   sy+h);
                glEnd();
            }
            glColor3f(1, 1, 1);

            defaultshader->set();
        }

        void draw(float sx, float sy)
        {
            if (texmru.inrange(slotnum))
            {
                VSlot &vslot = lookupvslot(texmru[slotnum], false);
                Slot &slot = *vslot.slot;
                if (slot.sts.length())
                {
                    if(slot.loaded || slot.thumbnail) drawslot(slot, vslot, sx, sy);
                    else if (totalmillis-lastthumbnail >= thumbtime)
                    {
                        loadthumbnail(slot);
                        lastthumbnail = totalmillis;
                    }
                }
            }

            Object::draw(sx, sy);
        }
    };

    struct Cropped_Image : Image
    {
        float cropx, cropy, cropw, croph;

        Cropped_Image(Texture *tex, float minw = 0, float minh = 0, float cropx = 0, float cropy = 0, float cropw = 1, float croph = 1)
              : Image(tex, minw, minh), cropx(cropx), cropy(cropy), cropw(cropw), croph(croph) {}

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            if (o) return o;
            if (tex->bpp < 32) return this;
            return checkalphamask(tex, cropx + cx/w*cropw, cropy + cy/h*croph) ? this : NULL;
        }

        void draw(float sx, float sy)
        {
            glBindTexture(GL_TEXTURE_2D, tex->id);
            glBegin(GL_QUADS);
            quad(sx, sy, w, h, cropx, cropy, cropw, croph);
            glEnd();

            Object::draw(sx, sy);
        }
    };

    struct Stretched_Image : Image
    {
        Stretched_Image(Texture *tex, float minw = 0, float minh = 0) : Image(tex, minw, minh) {}

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            if (o) return o;
            if (tex->bpp < 32) return this;

            float mx, my;
            if (w <= minw) mx = cx/w;
            else if (cx < minw/2) mx = cx/minw;
            else if (cx >= w - minw/2) mx = 1 - (w - cx) / minw;
            else mx = 0.5f;
            if (h <= minh) my = cy/h;
            else if (cy < minh/2) my = cy/minh;
            else if (cy >= h - minh/2) my = 1 - (h - cy) / minh;
            else my = 0.5f;

            return checkalphamask(tex, mx, my) ? this : NULL;
        }

        void draw(float sx, float sy)
        {
            glBindTexture(GL_TEXTURE_2D, tex->id);
            glBegin(GL_QUADS);
            float splitw = (minw ? min(minw, w) : w) / 2,
                  splith = (minh ? min(minh, h) : h) / 2,
                  vy = sy, ty = 0;

            loopi(3)
            {
                float vh = 0, th = 0;
                switch(i)
                {
                    case 0: if (splith < h - splith) { vh = splith; th = 0.5f; } else { vh = h; th = 1; } break;
                    case 1: vh = h - 2*splith; th = 0; break;
                    case 2: vh = splith; th = 0.5f; break;
                }
                float vx = sx, tx = 0;
                loopj(3)
                {
                    float vw = 0, tw = 0;
                    switch(j)
                    {
                        case 0: if (splitw < w - splitw) { vw = splitw; tw = 0.5f; } else { vw = w; tw = 1; } break;
                        case 1: vw = w - 2*splitw; tw = 0; break;
                        case 2: vw = splitw; tw = 0.5f; break;
                    }
                    quad(vx, vy, vw, vh, tx, ty, tw, th);
                    vx += vw;
                    tx += tw;
                    if (tx >= 1) break;
                }
                vy += vh;
                ty += th;
                if (ty >= 1) break;
            }
            glEnd();

            Object::draw(sx, sy);
        }
    };

    struct Bordered_Image : Image
    {
        float texborder, screenborder;

        Bordered_Image(Texture *tex, float texborder, float screenborder) : Image(tex), texborder(texborder), screenborder(screenborder) {}

        void layout()
        {
            Object::layout();

            w = max(w, 2*screenborder);
            h = max(h, 2*screenborder);
        }

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            if (o) return o;
            if (tex->bpp < 32) return this;

            float mx, my;
            if (cx < screenborder) mx = cx/screenborder*texborder;
            else if (cx >= w - screenborder) mx = 1-texborder + (cx - (w - screenborder))/screenborder*texborder;
            else mx = texborder + (cx - screenborder)/(w - 2*screenborder)*(1 - 2*texborder);
            if (cy < screenborder) my = cy/screenborder*texborder;
            else if (cy >= h - screenborder) my = 1-texborder + (cy - (h - screenborder))/screenborder*texborder;
            else my = texborder + (cy - screenborder)/(h - 2*screenborder)*(1 - 2*texborder);

            return checkalphamask(tex, mx, my) ? this : NULL;
        }

        void draw(float sx, float sy)
        {
            glBindTexture(GL_TEXTURE_2D, tex->id);
            glBegin(GL_QUADS);
            float vy = sy, ty = 0;
            loopi(3)
            {
                float vh = 0, th = 0;
                switch(i)
                {
                    case 0: vh = screenborder; th = texborder; break;
                    case 1: vh = h - 2*screenborder; th = 1 - 2*texborder; break;
                    case 2: vh = screenborder; th = texborder; break;
                }
                float vx = sx, tx = 0;
                loopj(3)
                {
                    float vw = 0, tw = 0;
                    switch(j)
                    {
                        case 0: vw = screenborder; tw = texborder; break;
                        case 1: vw = w - 2*screenborder; tw = 1 - 2*texborder; break;
                        case 2: vw = screenborder; tw = texborder; break;
                    }
                    quad(vx, vy, vw, vh, tx, ty, tw, th);
                    vx += vw;
                    tx += tw;
                }
                vy += vh;
                ty += th;
            }
            glEnd();

            Object::draw(sx, sy);
        }
    };

    // default size of text in terms of rows per screenful
    VARP(uitextrows, 1, 40, 200);

    struct Label : Object
    {
        char *str;
        float scale;
        float wrap;
        vec color;

        Label(const char *str, float scale = 1, float wrap = -1, float r = 1, float g = 1, float b = 1)
            : str(newstring(str)), scale(scale), wrap(wrap), color(r, g, b) {}
        ~Label() { delete[] str; }

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            return o ? o : this;
        }

        float drawscale() const { return scale / (FONTH * uitextrows); }

        void draw(float sx, float sy)
        {
            float k = drawscale();
            glPushMatrix();
            glScalef(k, k, 1);
            draw_text(str, int(sx/k), int(sy/k), color.x * 255, color.y * 255, color.z * 255, 255, -1, wrap <= 0 ? -1 : wrap/k);
            glColor3f(1, 1, 1);
            glPopMatrix();

            Object::draw(sx, sy);
        }

        void layout()
        {
            Object::layout();

            int tw, th;
            float k = drawscale();
            text_bounds(str, tw, th, wrap <= 0 ? -1 : wrap/k);

            if(wrap <= 0)
                w = max(w, tw*k);
            else
                w = max(w, min(wrap, tw*k));
            h = max(h, th*k);
        }
    };

    struct Function_Label : Object
    {
        lua::Function cmd;
        float scale;
        float wrap;
        vec color;

        Function_Label(lua::Function cmd, float scale = 1, float wrap = -1, float r = 1, float g = 1, float b = 1) : cmd(cmd), scale(scale), wrap(wrap), color(r, g, b) {}

        float drawscale() const { return scale / (FONTH * uitextrows); }

        void draw(float sx, float sy)
        {
            const char *ret = (!cmd.is_nil()) ? cmd.call<const char*>() : "";

            float k = drawscale();
            glPushMatrix();
            glScalef(k, k, 1);
            draw_text(ret ? ret : "", int(sx/k), int(sy/k), color.x * 255, color.y * 255, color.z * 255, 255, -1, wrap <= 0 ? -1 : wrap/k);
            glColor3f(1, 1, 1);
            glPopMatrix();

            Object::draw(sx, sy);
        }

        void layout()
        {
            const char *ret = (!cmd.is_nil()) ? cmd.call<const char*>() : "";
            Object::layout();

            int tw, th;
            float k = drawscale();
            text_bounds(ret ? ret : "", tw, th, wrap <= 0 ? -1 : wrap/k);
            if(wrap <= 0)
                w = max(w, tw*k);
            else
                w = max(w, min(wrap, tw*k));
            h = max(h, th*k);
        }
    };

    enum
    {
        EDIT_IDLE = 0,
        EDIT_FOCUSED,
        EDIT_COMMIT,
    };
    struct Text_Editor;
    Text_Editor *textediting;
    int refreshrepeat = 0;

    struct Text_Editor : Object
    {
        int state, lastaction;
        float scale, offsetx, offsety;
        editor *edit;
        char *keyfilter;

        Text_Editor(const char *name, int length, int height, float scale = 1, const char *initval = NULL, int mode = EDITORUSED, const char *keyfilter = NULL, bool password = false) : state(EDIT_IDLE), lastaction(totalmillis), scale(scale), offsetx(0), offsety(0), keyfilter(keyfilter ? newstring(keyfilter) : NULL)
        {
            edit = useeditor(name, mode, false, initval, password);
            edit->linewrap = length<0;
            edit->maxx = edit->linewrap ? -1 : length;
            edit->maxy = height <= 0 ? 1 : -1;
            edit->pixelwidth = abs(length)*FONTW;
            if(edit->linewrap && edit->maxy==1)
            {
                int temp;
                text_bounds(edit->lines[0].text, temp, edit->pixelheight, edit->pixelwidth); //only single line editors can have variable height
            }
            else
                edit->pixelheight = FONTH*max(height, 1);
        }
        ~Text_Editor()
        {
            DELETEA(keyfilter);
            if(edit->mode!=EDITORFOREVER) removeeditor(edit);
            if(this == textediting) textediting = NULL;
            refreshrepeat++;
        }

        Object *target(float cx, float cy)
        {
            Object *o = Object::target(cx, cy);
            return o ? o : this;
        }

        Object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        virtual void commit() { state = EDIT_IDLE; }

        void hovering(float cx, float cy)
        {
            if(isselected(this) && isfocused(this))
            {
                bool dragged = max(fabs(cx - offsetx), fabs(cy - offsety)) > (FONTH/8.0f)*scale/float(FONTH*uitextrows);
                edit->hit(int(floor(cx*(FONTH*uitextrows)/scale - FONTW/2)), int(floor(cy*(FONTH*uitextrows)/scale)), dragged);
            }
        }

        void selected(float cx, float cy)
        {
            focuseditor(edit);
            state = EDIT_FOCUSED;
            setfocus(this);
            edit->mark(false);
            offsetx = cx;
            offsety = cy;
        }

        bool key(int code, bool isdown, int cooked)
        {
            if(Object::key(code, isdown, cooked)) return true;
            if(!isfocused(this)) return false;
            switch(code)
            {
                case SDLK_RETURN:
                    if(!cooked) return true;
                case SDLK_TAB:
                    if(edit->maxy != 1) break;
                case SDLK_ESCAPE:
                    setfocus(NULL);
                    return true;

                case SDLK_KP_ENTER:
                    if(cooked && edit->maxy == 1) setfocus(NULL);
                    return true;
                case SDLK_HOME:
                case SDLK_END:
                case SDLK_PAGEUP:
                case SDLK_PAGEDOWN:
                case SDLK_DELETE:
                case SDLK_BACKSPACE:
                case SDLK_UP:
                case SDLK_DOWN:
                case SDLK_LEFT:
                case SDLK_RIGHT:
                case SDLK_LSHIFT:
                case SDLK_RSHIFT:
                case SDLK_LCTRL:
                case SDLK_RCTRL:
                case SDLK_LMETA:
                case SDLK_RMETA:
                case -4:
                case -5:
                    break;
                case SDLK_a:
                case SDLK_x:
                case SDLK_c:
                case SDLK_v:
                    if(SDL_GetModState()) break;
                default:
                    if(!cooked || code<32) return false;
                    if(keyfilter && !strchr(keyfilter, cooked)) return true;
                    break;
            }
            if(isdown) edit->key(code, cooked);
            return true;
        }

        void layout()
        {
            Object::layout();

            if(edit->linewrap && edit->maxy==1)
            {
                int temp;
                text_bounds(edit->lines[0].text, temp, edit->pixelheight, edit->pixelwidth); //only single line editors can have variable height
            }
            w = max(w, (edit->pixelwidth + FONTW)*scale/float(FONTH*uitextrows));
            h = max(h, edit->pixelheight*scale/float(FONTH*uitextrows));
        }

        void draw(float sx, float sy)
        {
            glPushMatrix();
            glTranslatef(sx, sy, 0);
            glScalef(scale/(FONTH*uitextrows), scale/(FONTH*uitextrows), 1);
            edit->draw(FONTW/2, 0, 0xFFFFFF, isfocused(this));
            glColor3f(1, 1, 1);
            glPopMatrix();

            Object::draw(sx, sy);
        }

        const int gettype() const { return TYPE_TEXTEDITOR; }
    };

    struct Field : Text_Editor
    {
        char *var;
        lua::Function onchange;

        Field(const char *var, int length, lua::Function onchange, float scale = 1, const char *initval = NULL, const char *keyfilter = NULL, bool password = false) : Text_Editor(var, length, 0, scale, initval, EDITORUSED, keyfilter, password), var(newstring(var)), onchange(onchange) {}
        ~Field() { delete[] var; }

        void commit()
        {
            state = EDIT_COMMIT;
            lastaction = totalmillis;
            updateval(var, edit->lines[0].text, onchange);
        }

        bool key(int code, bool isdown, int cooked)
        {
            if(Object::key(code, isdown, cooked)) return true;
            if(!isfocused(this)) return false;

            switch(code)
            {
                case SDLK_ESCAPE:
                    state = EDIT_COMMIT;
                    return true;
                case SDLK_KP_ENTER:
                case SDLK_RETURN:
                case SDLK_TAB:
                    if(!cooked) return false;
                    commit();
                    setfocus(NULL);
                    return true;
                case SDLK_HOME:
                case SDLK_END:
                case SDLK_DELETE:
                case SDLK_BACKSPACE:
                case SDLK_LEFT:
                case SDLK_RIGHT:
                    break;

                default:
                    if(!cooked || code<32) return false;
                    if(keyfilter && !strchr(keyfilter, cooked)) return true;
                    break;
            }
            if(isdown) edit->key(code, cooked);
            return true;
        }

        void layout()
        {
            if(state == EDIT_COMMIT && lastaction != totalmillis)
            {
                edit->clear(getsval(var));
                state = EDIT_IDLE;
            }

            Text_Editor::layout();
        }
    };

    struct Named_Object : Object
    {
        char *name;

        Named_Object(const char *name) : name(newstring(name)) {}
        ~Named_Object() { delete[] name; }

        const char *getname() const { return name; }
    };

    struct Tag : Named_Object
    {
        Tag(const char *name) : Named_Object(name) {}

        const int gettype() const { return TYPE_TAG; }
    };

    struct Window : Named_Object
    {
        lua::Function onhide;
        bool nofocus;

        float customx, customy;

        Window(const char *name, const lua::Function& onhide = lua::Function(), bool nofocus = false)
         : Named_Object(name), onhide(onhide), nofocus(nofocus), customx(0), customy(0)
        {}
        ~Window() { onhide.clear(); }

        void hidden()
        {
            if (!onhide.is_nil()) onhide();
            resetcursor();
        }

        void adjustlayout(float px, float py, float pw, float ph)
        {
            Object::adjustlayout(px, py, pw, ph);

            if (!customx) customx = x;
            if (!customy) customy = y;

            if (customx != x) x = customx;
            if (customy != y) y = customy;
        }

        const int gettype() const { return TYPE_WINDOW; }
    };

    struct Window_Mover : Object
    {
        Window *win;

        Window_Mover() : win(NULL) {}

        int forks()      const { return 1; }
        int choosefork() const { return 0; }

        void init()
        {
            Object *par = parent;
            while (!par->istype(TYPE_WINDOW))
            {
                if  (!par->parent) break;
                par = par->parent;
            }

            if (par->istype(TYPE_WINDOW)) win = (Window*)par;
        }

        Object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        Object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void selecting(float cx, float cy)
        {
            if (win && isselected(this))
            {
                win->customx += cx;
                win->customy += cy;
            }
        }

        const int gettype() const { return TYPE_WINDOWMOVER; }
    };

    struct World : Object
    {
        bool focuschildren()
        {
            loopchildren(o,
            {
                Window *w = (Window*)o;
                if ((w && !w->nofocus) || (w && !GuiControl::isMouselooking())) return true;
            });
            return false;
        }

        void layout()
        {
            Object::layout();

            float margin = max((float(screen->w)/screen->h - 1)/2, 0.0f);
            x = -margin;
            y = 0;
            w = 1 + 2*margin;
            h = 1;

            adjustchildren();
        }
    };

    vector<Object *> build;

    Window *buildwindow(
        const char *name,
        const lua::Function& contents,
        const lua::Function& onhide = lua::Function(),
        bool nofocus = false
    )
    {
        Window *win = new Window(name, onhide, nofocus);
        build.add(win);
        contents();
        build.pop();
        return win;
    }

    bool _lua_hideui(const char *name)
    {
        Window *win = (Window *) world->findname(TYPE_WINDOW, name, false);
        if(win)
        {
            win->hidden();
            world->remove(win);
        }
        return win != NULL;
    }

    void addui(Object *o, const lua::Function& children)
    {
        if (build.length())
        {
            o->parent = build.last();
            build.last()->children.add(o);
        }
        if (!children.is_nil())
        {
            build.add(o);
            children();
            build.pop();
        }

        o->init();
    }

    /* COMMAND SECTION */

    bool _lua_showui(
        const char *name,
        lua::Function contents,
        lua::Function onhide,
        bool nofocus
    )
    {
        if (!name) name = "";
        if (contents.is_nil())
        {
            logger::log(logger::ERROR, "showui(\"%s\"): contents is nil\n");
            return false;
        }
        if (build.length()) return false;

        Window *oldwin = (Window *) world->findname(TYPE_WINDOW, name, false);
        if (oldwin)
        {
            oldwin->hidden();
            world->remove(oldwin);
        }

        Window *win = buildwindow(name, contents, onhide, nofocus);
        world->children.add(win);
        win->parent = world;

        return true;
    }

    bool _lua_replaceui(
        const char *wname, const char *tname, lua::Function contents
    )
    {
        if (!wname) wname = "";
        if (!tname) tname = "";
        if (contents.is_nil())
        {
            logger::log(logger::ERROR, "showui(\"%s\"): contents is nil\n");
            return false;
        }
        if (build.length()) return false;

        Window *win = (Window*) world->findname(TYPE_WINDOW, wname, false);
        if (!win) return false;

        Tag *tg = (Tag *) win->findname(TYPE_TAG, tname);
        if (!tg) return false;

        tg->children.deletecontents();
        build.add(tg);
        contents();
        build.pop();

        return true;
    }

    void _lua_uialign(int h, int v)
    {
        if (build.length())
        {
            build.last()->adjust = (build.last()->adjust & ~ALIGN_MASK)
                | ((clamp(h, -1, 1)+2)<<ALIGN_HSHIFT)
                | ((clamp(v, -1, 1)+2)<<ALIGN_VSHIFT);
        }
    }

    void _lua_uiclamp(int l, int r, int b, int t)
    {
        if (build.length())
        {
            build.last()->adjust = (build.last()->adjust & ~CLAMP_MASK)
                | (l ? CLAMP_LEFT : 0)
                | (r ? CLAMP_RIGHT : 0)
                | (b ? CLAMP_BOTTOM : 0)
                | (t ? CLAMP_TOP : 0);
        }
    }

    void _lua_uiwinmover(lua::Function children)
    {
        addui(new Window_Mover, children);
    }

    void _lua_uitag(const char *name, lua::Function children)
    {
        if (!name) name = "";
        addui(new Tag(name), children);
    }

    void _lua_uivlist(float space, lua::Function children)
    {
        addui(new list(false, space), children);
    }

    void _lua_uihlist(float space, lua::Function children)
    {
        addui(new list(true, space), children);
    }

    void _lua_uitable(int columns, float space, lua::Function children)
    {
        addui(new Table(columns, space), children);
    }

    void _lua_uispace(float h, float v, lua::Function children)
    {
        addui(new Spacer(h, v), children);
    }

    void _lua_uifill(float h, float v, lua::Function children)
    {
        addui(new Filler(h, v), children);
    }

    void _lua_uiclip(float h, float v, lua::Function children)
    {
        addui(new Clipper(h, v), children);
    }

    void _lua_uiscroll(float h, float v, lua::Function children)
    {
        addui(new Scroller(h, v), children);
    }

    void _lua_uihscrollbar(float h, float v, lua::Function children)
    {
        addui(new Horizontal_Scrollbar(h, v), children);
    }

    void _lua_uivscrollbar(float h, float v, lua::Function children)
    {
        addui(new Vertical_Scrollbar(h, v), children);
    }

    void _lua_uiscrollbutton(lua::Function children)
    {
        addui(new Scroll_Button, children);
    }

    void _lua_uihslider(
        const char *var, float vmin, float vmax, lua::Function onchange,
        float arrowsize, float stepsize, int steptime, lua::Function children
    )
    {
        addui(new Horizontal_Slider(
            var, vmin, vmax, onchange, arrowsize,
            stepsize ? stepsize : 1, steptime
        ), children);
    }

    void _lua_uivslider(
        const char *var, float vmin, float vmax, lua::Function onchange,
        float arrowsize, float stepsize, int steptime, lua::Function children
    )
    {
        addui(new Vertical_Slider(
            var, vmin, vmax, onchange, arrowsize,
            stepsize ? stepsize : 1, steptime
        ), children);
    }

    void _lua_uisliderbutton(lua::Function children)
    {
        addui(new Slider_Button, children);
    }

    void _lua_uioffset(float h, float v, lua::Function children)
    {
        addui(new Offsetter(h, v), children);
    }

    void _lua_uibutton(lua::Function cb, lua::Function children)
    {
        addui(new Button(cb), children);
    }

    void _lua_uicond(lua::Function cb, lua::Function children)
    {
        addui(new Conditional(cb), children);
    }

    void _lua_uicondbutton(
        lua::Function cond, lua::Function cb, lua::Function children
    )
    {
        addui(new Conditional_Button(cond, cb), children);
    }

    void _lua_uitoggle(
        lua::Function cond,
        lua::Function cb,
        float split,
        lua::Function children
    )
    {
        addui(new Toggle(cond, cb, split), children);
    }

    void _lua_uiimage(
        const char *path, float minw, float minh, lua::Function children
    )
    {
        addui(new Image(textureload(
            path ? path : "", 3, true, false
        ), minw, minh),children);
    }

    void _lua_uislotview(
        int slot, float minw, float minh, lua::Function children
    )
    {
        addui(new Slot_Viewer(slot, minw, minh), children);
    }

    void _lua_uialtimage(const char *path)
    {
        if (build.empty() || !build.last()->isnamed("image")) return;
        Image *img = (Image*)build.last();
        if (img && img->tex==notexture)
        {
            img->tex = textureload(path ? path : "", 3, true, false);
        }
    }

    void _lua_uicolor(
        float r, float g, float b, float a,
        float minw, float minh, lua::Function children
    )
    {
        addui(
            new Rectangle(Rectangle::SOLID, r, g, b, a, minw, minh),
            children
        );
    }

    void _lua_uimodcolor(
        float r, float g, float b,
        float minw, float minh, lua::Function children
    )
    {
        addui(
            new Rectangle(Rectangle::MODULATE, r, g, b, 1, minw, minh),
            children
        );
    }

    void _lua_uistretchedimage(
        const char *path, float minw, float minh, lua::Function children
    )
    {
        addui(new Stretched_Image(
            textureload(path ? path : "", 3, true, false), minw, minh
        ), children);
    }

    void _lua_uicroppedimage(
        const char *path,
        float minw, float minh,
        const char *cropx,
        const char *cropy,
        const char *cropw,
        const char *croph,
        lua::Function children
    )
    {
        Texture *tex = textureload(path ? path : "", 3, true, false);
        addui(
            new Cropped_Image(
                tex, minw, minh,
                strchr(cropx, 'p') ? atof(cropx) / tex->xs : atof(cropx),
                strchr(cropy, 'p') ? atof(cropy) / tex->ys : atof(cropy),
                strchr(cropw, 'p') ? atof(cropw) / tex->xs : atof(cropw),
                strchr(croph, 'p') ? atof(croph) / tex->ys : atof(croph)
            ),
            children
        );
    }

    void _lua_uiborderedimage(
        const char *path, const char *texborder,
        float screenborder, lua::Function children
    )
    {
        Texture *tex = textureload(path ? path : "", 3, true, false);
        addui(
            new Bordered_Image(
                tex,
                strchr(texborder, 'p') ? (
                    atof(texborder) / tex->xs
                ) : atof(texborder),
                screenborder
            ),
            children
        );
    }

    void _lua_uilabel(
        const char *lbl, float scale, float wrap,
        lua::Object r, lua::Object g, lua::Object b,
        lua::Function children
    )
    {
        addui(new Label(
            lbl ? lbl : "", (scale <= 0) ? 1 : scale, wrap,
            (r.is_nil() ? 1.0f : r.to<float>()),
            (g.is_nil() ? 1.0f : g.to<float>()),
            (b.is_nil() ? 1.0f : b.to<float>())
        ), children);
    }

    void _lua_uifunlabel(
        lua::Function cmd, float scale, float wrap,
        lua::Object r, lua::Object g, lua::Object b,
        lua::Function children
    )
    {
        addui(new Function_Label(
            cmd, (scale <= 0) ? 1 : scale, wrap,
            (r.is_nil() ? 1.0f : r.to<float>()),
            (g.is_nil() ? 1.0f : g.to<float>()),
            (b.is_nil() ? 1.0f : b.to<float>())
        ), children);
    }

    void _lua_uitexteditor(
        const char *name,
        int length,
        int height,
        float scale,
        const char *initval,
        bool keep,
        const char *filter,
        lua::Function children
    )
    {
        if (!name   ) name    = "";
        if (!initval) initval = "";
        addui(
            new Text_Editor(
                name, length, height, scale ? scale : 1.0f, initval,
                keep ? EDITORFOREVER : EDITORUSED, filter ? filter : NULL
            ),
            children
        );
    }

    void _lua_uifield(
        const char *var,
        int length,
        lua::Function onchange,
        float scale,
        const char *filter,
        bool password,
        lua::Function children
    )
    {
        if (!var) var = "";
        var::cvar *ev = var::get(var);
        if (!ev)   ev = var::regvar(var, new var::cvar(var, ""));

        addui(
            new Field(
                var, length, onchange, scale ? scale : 1.0f, ev->curv.s,
                filter ? filter : NULL, password
            ),
            children
        );
    }

    FVAR(cursorsensitivity, 1e-3f, 1, 1000);

    float cursorx = 0.5f, cursory = 0.5f;
    float prev_cx = 0.5f, prev_cy = 0.5f;

    void resetcursor()
    {
        if (editmode || world->children.empty())
            cursorx = cursory = 0.5f;
    }

    bool movecursor(int &dx, int &dy)
    {
        if ((world->children.empty() || !world->focuschildren()) && GuiControl::isMouselooking()) return false;
        float scale = 500.0f / cursorsensitivity;
        cursorx = clamp(cursorx+dx*(screen->h/(screen->w*scale)), 0.0f, 1.0f);
        cursory = clamp(cursory+dy/scale, 0.0f, 1.0f);
        return true;
    }

    bool hascursor(bool targeting)
    {
        if (!world->focuschildren()) return false;
        if (world->children.length())
        {
            if (!targeting) return true;
            if (world && world->target(cursorx*world->w, cursory*world->h)) return true;
        }
        return false;
    }

    void getcursorpos(float &x, float &y)
    {
        if(world->children.length() || !GuiControl::isMouselooking())
        {
            x = cursorx;
            y = cursory;
        }
        else x = y = 0.5f;
    }

    bool keypress(int code, bool isdown, int cooked)
    {
        if(!hascursor()) return false;
        switch(code)
        {
            case -1:
            {
                if(isdown)
                {
                    selected = world->select(cursorx*world->w, cursory*world->h);
                    if(selected) selected->selected(selectx, selecty);
                }
                else selected = NULL;
                return true;
            }

            default:
                return world->key(code, isdown, cooked);
        }
    }

    VAR(mainmenu, 1, 1, 0);
    void clearmainmenu()
    {
        if (mainmenu && (isconnected() || haslocalclients()))
        {
            mainmenu = 0;
            _lua_hideui("main");
            _lua_hideui("vtab");
            _lua_hideui("htab");
        }
    }

    void setup()
    {
        if (world)
        {
            delete world;
            build.deletecontents();
        }
        world = new World;
    }

    static bool space = false;

    void update()
    {
        for (size_t i = 0; i < updatelater.length(); ++i) updatelater[i].run();
        updatelater.clear();

        if (mainmenu && !isconnected(true) && !world->children.length())
            lapi::state.get<lua::Function>("LAPI", "GUI", "show")("main");

        if ((editmode && !mainmenu) && !space)
        {
            lapi::state.get<lua::Function>("LAPI", "GUI", "show")("space");
            _lua_hideui("vtab");
            _lua_hideui("htab");
            space = true;
            resetcursor();
        }
        else if ((!editmode || mainmenu) && space)
        {
            _lua_hideui("space");
            _lua_hideui("vtab");
            _lua_hideui("htab");
            space = false;
            resetcursor();
        }

        world->layout();

        if (hascursor())
        {
            hovering = world->hover(cursorx*world->w, cursory*world->h);
            if (hovering)
                hovering->hovering(hoverx, hovery);
            if (selected)
                selected->selecting(cursorx - prev_cx, cursory - prev_cy);
        }
        else
        {
            hovering = NULL;
            selected = NULL;
        }

        world->layout();

        bool wastextediting = textediting!=NULL;

        if(textediting && !isfocused(textediting) && textediting->state == EDIT_FOCUSED)
            textediting->commit();

        if(!focused || focused->gettype() != TYPE_TEXTEDITOR)
            textediting = NULL;
        else
            textediting = (Text_Editor *) focused;

        if(refreshrepeat || (textediting!=NULL) != wastextediting)
        {
            SDL_EnableUNICODE(textediting!=NULL);
            keyrepeat(textediting!=NULL || editmode);
            refreshrepeat = 0;
        }

        prev_cx = cursorx;
        prev_cy = cursory;
    }

    void render()
    {
        if (world->children.empty()) return;

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glMatrixMode(GL_PROJECTION);
        glPushMatrix();
        glLoadIdentity();
        glOrtho(world->x, world->x + world->w, world->y + world->h, world->y, -1, 1);

        glMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        glLoadIdentity();

        glColor3f(1, 1, 1);

        world->draw();

        glMatrixMode(GL_PROJECTION);
        glPopMatrix();
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix();
        glEnable(GL_BLEND);
    }
}

struct Change
{
    int type;
    const char *desc;

    Change() {}
    Change(int type, const char *desc) : type(type), desc(desc) {}
};
static vector<Change> needsapply;

VARP(applydialog, 0, 1, 1);

void addchange(const char *desc, int type)
{
    if (!applydialog) return;
    loopv(needsapply) if (!strcmp(needsapply[i].desc, desc)) return;
    needsapply.add(Change(type, desc));
    lapi::state.get<lua::Function>("LAPI", "GUI", "show_changes")();
}

void clearchanges(int type)
{
    loopv(needsapply)
    {
        if (needsapply[i].type&type)
        {
            needsapply[i].type &= ~type;
            if (!needsapply[i].type) needsapply.remove(i--);
        }
    }
}

void _lua_applychanges()
{
    int changetypes = 0;
    loopv(needsapply) changetypes |= needsapply[i].type;
    gui::Delayed_Update d;
    if (changetypes&CHANGE_GFX)
        d.schedule(
            lapi::state.get("LAPI", "Graphics", "reset")
        );
    if (changetypes&CHANGE_SOUND)
        d.schedule(
            lapi::state.get("LAPI", "Sound", "reset")
        );
    gui::updatelater.push_back(d);
}

void _lua_clearchanges()
{
    clearchanges(CHANGE_GFX | CHANGE_SOUND);
}

types::Vector<const char*> _lua_getchanges()
{
    types::Vector<const char*> ret;
    ret.reserve((size_t)needsapply.length());

    loopv(needsapply)
        ret.push_back(needsapply[i].desc);

    return ret;
}

VAR(fonth, 512, 0, 0);

HVARP(fullconcolor, 0, 0x4F4F4F, 0xFFFFFF);
FVARP(fullconblend, 0, .8, 1);

void consolebox(int x1, int y1, int x2, int y2)
{
    glPushMatrix();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_TEXTURE_2D);
    notextureshader->set();

    glTranslatef(x1, y1, 0);
    float r = ((fullconcolor >> 16) & 0xFF) / 255.f,
        g = ((fullconcolor >> 8) & 0xFF) / 255.f,
        b = (fullconcolor & 0xFF) / 255.f;
    glColor4f(r, g, b, fullconblend);
    glBegin(GL_TRIANGLE_STRIP);

    glVertex2i(x1, y1);
    glVertex2i(x2, y1);
    glVertex2i(x1, y2);
    glVertex2i(x2, y2);

    glEnd();
    glEnable(GL_TEXTURE_2D);
    defaultshader->set();

    glPopMatrix();
}
