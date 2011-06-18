/* based on newui by neal and eihrul, licensed under zlib */

#include "engine.h"
#include "textedit.h"
#include "scripting_system_lua.hpp"
#include "client_engine_additions.h"

using namespace lua;

namespace gui
{
    struct object;

    object *selected = NULL,
           *hovering = NULL,
           *focused  = NULL;
    float   hoverx   = 0,
            hovery   = 0,
            selectx  = 0,
            selecty  = 0;

    static inline bool isselected(const object *o)
    {
        return o == selected;
    }

    static inline bool ishovering(const object *o)
    {
        return o == hovering;
    }

    static inline bool isfocused(const object *o)
    {
        return o == focused;
    }

    static void setfocus(object *o)
    {
        focused = o;
    }

    static inline void clearfocus(const object *o)
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

    struct clip_area
    {
        float x1, y1, x2, y2;

        clip_area(float x, float y, float w, float h) : x1(x), y1(y), x2(x+w), y2(y+h) {}

        void intersect(const clip_area &c)
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

    static vector<clip_area> clipstack;

    static void pushclip(float x, float y, float w, float h)
    {
        if (clipstack.empty()) glEnable(GL_SCISSOR_TEST);

        clip_area &c = clipstack.add(clip_area(x, y, w, h));
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

    static vector<int> executelater;

    struct object
    {
        object *parent;
        float x, y, w, h;
        uchar adjust;
        vector<object *> children;

        object() : parent(NULL), x(0), y(0), w(0), h(0), adjust(ALIGN_HCENTER | ALIGN_VCENTER) {}
        virtual ~object()
        {
            clearfocus(this);
            children.deletecontents();
        }

        virtual int forks()      const { return  0; }
        virtual int choosefork() const { return -1; }

        #define loopchildren(o, body) do { \
            int numforks = forks(); \
            if (numforks > 0) \
            { \
                int i = choosefork(); \
                if (children.inrange(i)) \
                { \
                    object *o = children[i]; \
                    body; \
                } \
            } \
            for (int i = numforks; i < children.length(); i++) \
            { \
                object *o = children[i]; \
                body; \
            } \
        } while(0)


        #define loopchildrenrev(o, body) do { \
            int numforks = forks(); \
            for (int i = children.length()-1; i >= numforks; i--) \
            { \
                object *o = children[i]; \
                body; \
            } \
            if (numforks > 0) \
            { \
                int i = choosefork(); \
                if (children.inrange(i)) \
                { \
                    object *o = children[i]; \
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

        void adjustlayout(float px, float py, float pw, float ph)
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

        virtual object *target(float cx, float cy)
        {
            loopinchildrenrev(o, cx, cy,
            {
                object *c = o->target(ox, oy);
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

        virtual object *hover(float cx, float cy)
        {
            loopinchildrenrev(o, cx, cy,
            {
                object *c = o->hover(ox, oy);
                if (c == o) { hoverx = ox; hovery = oy; }
                if (c) return c;
            });

            return NULL;
        }

        virtual void hovering(float cx, float cy)
        {
        }

        virtual object *select(float cx, float cy)
        {
            loopinchildrenrev(o, cx, cy,
            {
                object *c = o->select(ox, oy);
                if (c == o) { selectx = ox; selecty = oy; }
                if (c) return c;
            });

            return NULL;
        }

        virtual bool allowselect(object *o)
        {
            return false;
        }

        virtual void selected(float cx, float cy) {}

        virtual const char *getname() const
        {
            return "";
        }

        bool isnamed(const char *name) const
        {
            return !strcmp(name, getname());
        }

        object *findname(const char *name, bool recurse = true, const object *exclude = NULL) const
        {
            loopchildren(o,
            {
                if (o != exclude && o->isnamed(name)) return o;
            });

            if (recurse) loopchildren(o,
            {
                if (o != exclude)
                {
                    object *found = o->findname(name);
                    if (found) return found;
                }
            });

            return NULL;
        }

        object *findsibling(const char *name) const
        {
            for (const object *prev = this, *cur = parent; cur; prev = cur, cur = cur->parent)
            {
                object *o = cur->findname(name, true, prev);
                if     (o) return o;
            }

            return NULL;
        }

        void remove(object *o)
        {
            children.removeobj(o);
            delete o;
        }
    };

    struct list : object
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

        void adjustchildren()
        {
            if (children.empty()) return;

            if (horizontal)
            {
                float childspace = (w - children.last()->x - children.last()->w) / max(children.length() - 1, 1),
                      offset     = 0;

                loopchildren(o,
                {
                    o->x = offset;
                    offset += o->w;
                    if (i < children.length()) offset += childspace;
                    o->adjustlayout(o->x, 0, offset - o->x, h);
                });
            }
            else
            {
                float childspace = (h - children.last()->y - children.last()->h) / max(children.length() - 1, 1),
                      offset     = 0;

                loopchildren(o,
                {
                    o->y = offset;
                    offset += o->h;
                    if (i < children.length()) offset += childspace;
                    o->adjustlayout(0, o->y, w, offset - o->y);
                });
            }
        }
    };

    struct table : object
    {
        int columns;
        float space;
        vector<float> widths, heights;

        table(int columns, float space = 0) : columns(columns), space(space) {}

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
            float offsetx = 0, offsety = 0, nexty = heights[0] + rspace;

            loopchildren(o,
            {
                o->x = offsetx;
                o->y = offsety;
                offsetx += widths[column];

                if (column < widths.length()) offsetx += cspace;

                o->adjustlayout(o->x, o->y, offsetx - o->x, nexty - o->y);
                column = (column + 1) % columns;

                if (!column)
                {
                    offsetx = 0;
                    offsety = nexty;
                    row++;

                    if (row < heights.length())
                    {
                        nexty += heights[row];
                        if (row < heights.length()) nexty += rspace;
                    }
                }
            });
        }
    };

    struct spacer : object
    {
        float spacew, spaceh;

        spacer(float spacew, float spaceh) : spacew(spacew), spaceh(spaceh) {}

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

    struct filler : object
    {
        float minw, minh;

        filler(float minw, float minh) : minw(minw), minh(minh) {}

        void layout()
        {
            object::layout();

            w = max(w, minw);
            h = max(h, minh);
        }
    };

    struct offsetter : object
    {
        float offsetx, offsety;

        offsetter(float offsetx, float offsety) : offsetx(offsetx), offsety(offsety) {}

        void layout()
        {
            object::layout();

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

    struct clipper : object
    {
        float clipw, cliph, virtw, virth;

        clipper(float clipw = 0, float cliph = 0) : clipw(clipw), cliph(cliph), virtw(0), virth(0) {}

        void layout()
        {
            object::layout();

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
                object::draw(sx, sy);
                popclip();
            }
            else object::draw(sx, sy);
        }
    };

    struct conditional : object
    {
        int cond;

        conditional(int cond) : cond(cond) {}
        ~conditional()
        {
            lua::engine.unref(cond);
        }

        int forks()      const { return 2; }
        int choosefork() const
        {
            lua::engine.getref(cond).call(0, 1);
            bool ret = lua::engine.get<bool>(-1);
            lua::engine.pop(1);

            return ret ? 0 : 1;
        }
    };

    struct button : object
    {
        int onselect;
        bool queued;

        button(int onselect) : onselect(onselect), queued(false) {}
        ~button()
        {
            lua::engine.unref(onselect);
        }

        int forks()      const { return 3; }
        int choosefork() const { return isselected(this) ? 2 : (ishovering(this) ? 1 : 0); }

        object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void selected(float cx, float cy)
        {
            executelater.add(onselect);
        }
    };

    struct conditional_button : button
    {
        int cond;

        conditional_button(int cond, int onselect) : button(onselect), cond(cond) {}
        ~conditional_button()
        {
            lua::engine.unref(cond);
        }

        int forks() const { return 4; }
        int choosefork() const
        {
            lua::engine.getref(cond).call(0, 1);
            bool ret = lua::engine.get<bool>(-1);
            lua::engine.pop(1);

            return ret ? 1 + button::choosefork() : 0;
        }

        void selected(float cx, float cy)
        {
            lua::engine.getref(cond).call(0, 1);
            bool ret = lua::engine.get<bool>(-1);
            lua::engine.pop(1);

            if (ret) button::selected(cx, cy);
        }
    };

    VAR(uitogglehside, 1, 0, 0);
    VAR(uitogglevside, 1, 0, 0);

    struct toggle : button
    {
        int cond;
        float split;

        toggle(int cond, int onselect, float split = 0) : button(onselect), cond(cond), split(split) {}
        ~toggle()
        {
            lua::engine.unref(cond);
        }

        int forks() const { return 4; }
        int choosefork() const
        {
            lua::engine.getref(cond).call(0, 1);
            bool ret = lua::engine.get<bool>(-1);
            lua::engine.pop(1);

            return (ret ? 2 : 0) + (ishovering(this) ? 1 : 0);
        }

        object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        object *select(float cx, float cy)
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

    struct scroller : clipper
    {
        float offsetx, offsety;

        scroller(float clipw = 0, float cliph = 0) : clipper(clipw, cliph), offsetx(0), offsety(0) {}

        object *target(float cx, float cy)
        {
            if (cx + offsetx >= virtw || cy + offsety >= virth) return NULL;
            return object::target(cx + offsetx, cy + offsety);
        }

        object *hover(float cx, float cy)
        {
            if (cx + offsetx >= virtw || cy + offsety >= virth) return NULL;
            return object::hover(cx + offsetx, cy + offsety);
        }

        object *select(float cx, float cy)
        {
            if (cx + offsetx >= virtw || cy + offsety >= virth) return NULL;
            return object::select(cx + offsetx, cy + offsety);
        }

        void draw(float sx, float sy)
        {
            if ((clipw && virtw > clipw) || (cliph && virth > cliph))
            {
                pushclip(sx, sy, w, h);
                object::draw(sx - offsetx, sy - offsety);
                popclip();
            }
            else object::draw(sx, sy);
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

        const char *getname() const { return "scroller"; }
    };

    struct scrollbar : object
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

        object *hover(float cx, float cy)
        {
            object *o = object::hover(cx, cy);
            if (o) return o;
            return target(cx, cy) ? this : NULL;
        }

        object *select(float cx, float cy)
        {
            object *o = object::select(cx, cy);
            if (o) return o;
            return target(cx, cy) ? this : NULL;
        }

        const char *getname() const { return "scrollbar"; }

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
                object *button = findname("scrollbutton", false);
                if (button && isselected(button))
                {
                    arrowdir = 0;
                    button->hovering(cx - button->x, cy - button->y);
                }
                else arrowdir = choosedir(cx, cy);
            }
        }

        bool allowselect(object *o)
        {
            return children.find(o) >= 0;
        }

        virtual void movebutton(object *o, float fromx, float fromy, float tox, float toy) = 0;
    };

    struct scroll_button : object
    {
        float offsetx, offsety;

        scroll_button() : offsetx(0), offsety(0) {}

        int forks()      const { return 3; }
        int choosefork() const { return isselected(this) ? 2 : (ishovering(this) ? 1 : 0); }

        object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void hovering(float cx, float cy)
        {
            if (isselected(this))
            {
                scrollbar *scroll = dynamic_cast<scrollbar *>(parent);
                if (!scroll) return;
                scroll->movebutton(this, offsetx, offsety, cx, cy);
            }
        }

        void selected(float cx, float cy)
        {
            offsetx = cx;
            offsety = cy;
        }

        const char *getname() const { return "scrollbutton"; }
    };

    struct hscrollbar : scrollbar
    {
        hscrollbar(float arrowsize = 0, float arrowspeed = 0) : scrollbar(arrowsize, arrowspeed) {}

        int choosedir(float cx, float cy) const
        {
            if (cx < arrowsize) return -1;
            else if (cx >= w - arrowsize) return 1;
            return 0;
        }

        void arrowscroll()
        {
            scroller *scroll = dynamic_cast<scroller *>(findsibling("scroller"));
            if (!scroll) return;
            scroll->addhscroll(arrowdir*arrowspeed*curtime/1000.0f);
        }

        void scrollto(float cx, float cy)
        {
            scroller *scroll = dynamic_cast<scroller *>(findsibling("scroller"));
            if (!scroll) return;
            scroll_button *btn = dynamic_cast<scroll_button *>(findname("scrollbutton", false));
            if (!btn) return;
            float bscale = (max(w - 2*arrowsize, 0.0f) - btn->w) / (1 - scroll->hscale()),
                  offset = bscale > 1e-3f ? (cx - arrowsize)/bscale : 0;
            scroll->sethscroll(offset*scroll->virtw);
        }

        void adjustchildren()
        {
            scroller *scroll = dynamic_cast<scroller *>(findsibling("scroller"));
            if (!scroll) return;
            scroll_button *btn = dynamic_cast<scroll_button *>(findname("scrollbutton", false));
            if (!btn) return;
            float bw = max(w - 2*arrowsize, 0.0f)*scroll->hscale();
            btn->w = max(btn->w, bw);
            float bscale = scroll->hscale() < 1 ? (max(w - 2*arrowsize, 0.0f) - btn->w) / (1 - scroll->hscale()) : 1;
            btn->x = arrowsize + scroll->hoffset()*bscale;
            btn->adjust &= ~ALIGN_HMASK;

            scrollbar::adjustchildren();
        }

        void movebutton(object *o, float fromx, float fromy, float tox, float toy)
        {
            scrollto(o->x + tox - fromx, o->y + toy);
        }
    };

    struct vscrollbar : scrollbar
    {
        vscrollbar(float arrowsize = 0, float arrowspeed = 0) : scrollbar(arrowsize, arrowspeed) {}

        int choosedir(float cx, float cy) const
        {
            if (cy < arrowsize) return -1;
            else if (cy >= h - arrowsize) return 1;
            return 0;
        }

        void arrowscroll()
        {
            scroller *scroll = dynamic_cast<scroller *>(findsibling("scroller"));
            if (!scroll) return;
            scroll->addvscroll(arrowdir*arrowspeed*curtime/1000.0f);
        }

        void scrollto(float cx, float cy)
        {
            scroller *scroll = dynamic_cast<scroller *>(findsibling("scroller"));
            if (!scroll) return;
            scroll_button *btn = dynamic_cast<scroll_button *>(findname("scrollbutton", false));
            if (!btn) return;
            float bscale = (max(h - 2*arrowsize, 0.0f) - btn->h) / (1 - scroll->vscale()),
                  offset = bscale > 1e-3f ? (cy - arrowsize)/bscale : 0;
            scroll->setvscroll(offset*scroll->virth);
        }

        void adjustchildren()
        {
            scroller *scroll = dynamic_cast<scroller *>(findsibling("scroller"));
            if (!scroll) return;
            scroll_button *btn = dynamic_cast<scroll_button *>(findname("scrollbutton", false));
            if (!btn) return;
            float bh = max(h - 2*arrowsize, 0.0f)*scroll->vscale();
            btn->h = max(btn->h, bh);
            float bscale = scroll->vscale() < 1 ? (max(h - 2*arrowsize, 0.0f) - btn->h) / (1 - scroll->vscale()) : 1;
            btn->y = arrowsize + scroll->voffset()*bscale;
            btn->adjust &= ~ALIGN_VMASK;

            scrollbar::adjustchildren();
        }

        void movebutton(object *o, float fromx, float fromy, float tox, float toy)
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

    struct slider : object
    {
        int minv, maxv;

        slider(int minv, int maxv) : minv(minv), maxv(maxv) {}

        int forks()      const { return 1; }
        int choosefork() const { return 0; }

        object *hover(float cx, float cy)
        {
            object *o = object::hover(cx, cy);
            if (o) return o;
            return target(cx, cy) ? this : NULL;
        }

        object *select(float cx, float cy)
        {
            object *o = object::select(cx, cy);
            if (o) return o;
            return target(cx, cy) ? this : NULL;
        }

        const char *getname() const { return "slider"; }

        virtual void slideto(float cx, float cy)
        {
        }

        void selected(float cx, float cy)
        {
            slideto(cx, cy);
        }

        void hovering(float cx, float cy)
        {
            object *btn = findname("sliderbutton", false);
            if (btn && isselected(btn))
                btn->hovering(cx - btn->x, cy - btn->y);
            else return;
        }

        bool allowselect(object *o)
        {
            return children.find(o) >= 0;
        }

        virtual void movebutton(object *o, float fromx, float fromy, float tox, float toy) = 0;
    };

    struct slider_button : object
    {
        float offsetx, offsety;

        slider_button() : offsetx(0), offsety(0) {}

        int forks()      const { return 3; }
        int choosefork() const { return isselected(this) ? 2 : (ishovering(this) ? 1 : 0); }

        object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void hovering(float cx, float cy)
        {
            if (isselected(this))
            {
                slider *sl = dynamic_cast<slider *>(parent);
                if (!sl) return;
                sl->movebutton(this, offsetx, offsety, cx, cy);
            }
        }

        void selected(float cx, float cy)
        {
            offsetx = cx;
            offsety = cy;
        }

        const char *getname() const { return "sliderbutton"; }
    };

    struct hslider : slider
    {
        hslider(const char *var, int minv, int maxv) : slider(minv, maxv), offset(0), var(var) {}

        float offset;
        const char *var;

        void slideto(float cx, float cy)
        {
            slider_button *btn = dynamic_cast<slider_button *>(findname("sliderbutton", false));
            if (!btn) return;

            float step      = w / (maxv - minv + 1);
            float curr_step = floor(min(max(cx, (float)0), w - btn->w) / step);

            var::get(var)->curv.i = (int)curr_step + minv;
        }

        void adjustchildren()
        {
            slider_button *btn = dynamic_cast<slider_button *>(findname("sliderbutton", false));
            if (!btn) return;
            btn->x = offset;
            btn->w = w / (maxv - minv + 1);
            btn->h = h;
            btn->adjust &= ~ALIGN_HMASK;

            slider::adjustchildren();
        }

        void movebutton(object *o, float fromx, float fromy, float tox, float toy)
        {
            slideto(o->x + tox - fromx, o->y + toy);
        }

        void draw(float sx, float sy)
        {
            float step = w / (maxv - minv + 1);
            offset     = (var::get(var)->curv.i - minv) * step;

            object::draw(sx, sy);
        }
    };

    struct vslider : slider
    {
        vslider(const char *var, int minv, int maxv) : slider(minv, maxv), offset(0), var(var) {}

        float offset;
        const char *var;

        void slideto(float cx, float cy)
        {
            slider_button *btn = dynamic_cast<slider_button *>(findname("sliderbutton", false));
            if (!btn) return;

            float step      = h / (maxv - minv + 1);
            float curr_step = floor(min(max(cy, (float)0), h - btn->h) / step);

            var::get(var)->curv.i = (int)curr_step + minv;
        }

        void adjustchildren()
        {
            slider_button *btn = dynamic_cast<slider_button *>(findname("sliderbutton", false));
            if (!btn) return;
            btn->y = offset;
            btn->h = h / (maxv - minv + 1);
            btn->w = w;
            btn->adjust &= ~ALIGN_VMASK;

            slider::adjustchildren();
        }

        void movebutton(object *o, float fromx, float fromy, float tox, float toy)
        {
            slideto(o->x + tox, o->y + toy - fromy);
        }

        void draw(float sx, float sy)
        {
            float step = h / (maxv - minv + 1);
            offset     = (var::get(var)->curv.i - minv) * step;

            object::draw(sx, sy);
        }
    };

    struct rectangle : filler
    {
        enum { SOLID = 0, MODULATE };

        int type;
        vec4 color;

        rectangle(int type, float r, float g, float b, float a, float minw = 0, float minh = 0) : filler(minw, minh), type(type), color(r, g, b, a) {}

        object *target(float cx, float cy)
        {
            object *o = object::target(cx, cy);
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

            object::draw(sx, sy);
        }
    };

    struct image : filler
    {
        Texture *tex;

        image(Texture *tex, float minw = 0, float minh = 0) : filler(minw, minh), tex(tex) {}

        object *target(float cx, float cy)
        {
            object *o = object::target(cx, cy);
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

            object::draw(sx, sy);
        }
    };

    VAR(thumbtime, 0, 25, 1000);
    static int lastthumbnail = 0;

    struct slot_viewer : filler
    {
        int slotnum;

        slot_viewer(int slotnum, float minw = 0, float minh = 0) : filler(minw, minh), slotnum(slotnum) {}

        object *target(float cx, float cy)
        {
            object *o = object::target(cx, cy);
            if (o || !texmru.inrange(slotnum)) return o;
            Slot &slot = lookupslot(texmru[slotnum], false);
            if (slot.sts.length() && (slot.loaded || slot.thumbnail)) return this;
            return NULL;
        }

        void drawslot(Slot &slot, float sx, float sy)
        {
            Texture *tex = notexture, *glowtex = NULL, *layertex = NULL;
            VSlot &vslot = *slot.variants;
            if (slot.loaded)
            {
                tex = slot.sts[0].t;
                if (slot.texmask&(1<<TEX_GLOW)) { loopv(slot.sts) if (slot.sts[i].type==TEX_GLOW) { glowtex = slot.sts[i].t; break; } }
                if (vslot.layer)
                {
                    Slot &layer = lookupslot(vslot.layer);
                    layertex = layer.sts[0].t;
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
            glBindTexture(GL_TEXTURE_2D, tex->id);
            glBegin(GL_QUADS);
            glTexCoord2fv(tc[0]); glVertex2f(sx,   sy);
            glTexCoord2fv(tc[1]); glVertex2f(sx+w, sy);
            glTexCoord2fv(tc[2]); glVertex2f(sx+w, sy+h);
            glTexCoord2fv(tc[3]); glVertex2f(sx,   sy+h);
            glEnd();

            if (glowtex)
            {
                glBlendFunc(GL_SRC_ALPHA, GL_ONE);
                glBindTexture(GL_TEXTURE_2D, glowtex->id);
                glColor3fv(vslot.glowcolor.v);
                glBegin(GL_QUADS);
                glTexCoord2fv(tc[0]); glVertex2f(sx,   sy);
                glTexCoord2fv(tc[1]); glVertex2f(sx+w, sy);
                glTexCoord2fv(tc[2]); glVertex2f(sx+w, sy+h);
                glTexCoord2fv(tc[3]); glVertex2f(sx,   sy+h);
                glEnd();
                glColor3f(1, 1, 1);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            }
            if (layertex)
            {
                glBindTexture(GL_TEXTURE_2D, layertex->id);
                glBegin(GL_QUADS);
                glTexCoord2fv(tc[0]); glVertex2f(sx+w/2, sy+h/2);
                glTexCoord2fv(tc[1]); glVertex2f(sx+w,   sy+h/2);
                glTexCoord2fv(tc[2]); glVertex2f(sx+w,   sy+h);
                glTexCoord2fv(tc[3]); glVertex2f(sx+w/2, sy+h);
                glEnd();
            }

            defaultshader->set();
        }

        void draw(float sx, float sy)
        {
            if (texmru.inrange(slotnum))
            {
                Slot &slot = lookupslot(texmru[slotnum], false);
                if (slot.sts.length())
                {
                    if (slot.loaded || slot.thumbnail) drawslot(slot, sx, sy);
                    else if (totalmillis-lastthumbnail >= thumbtime)
                    {
                        loadthumbnail(slot);
                        lastthumbnail = totalmillis;
                    }
                }
            }

            object::draw(sx, sy);
        }
    };

    struct cropped_image : image
    {
        float cropx, cropy, cropw, croph;

        cropped_image(Texture *tex, float minw = 0, float minh = 0, float cropx = 0, float cropy = 0, float cropw = 1, float croph = 1)
              : image(tex, minw, minh), cropx(cropx), cropy(cropy), cropw(cropw), croph(croph) {}

        object *target(float cx, float cy)
        {
            object *o = object::target(cx, cy);
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

            object::draw(sx, sy);
        }
    };

    struct stretched_image : image
    {
        stretched_image(Texture *tex, float minw = 0, float minh = 0) : image(tex, minw, minh) {}

        object *target(float cx, float cy)
        {
            object *o = object::target(cx, cy);
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

            object::draw(sx, sy);
        }
    };

    struct bordered_image : image
    {
        float texborder, screenborder;

        bordered_image(Texture *tex, float texborder, float screenborder) : image(tex), texborder(texborder), screenborder(screenborder) {}

        void layout()
        {
            object::layout();

            w = max(w, 2*screenborder);
            h = max(h, 2*screenborder);
        }

        object *target(float cx, float cy)
        {
            object *o = object::target(cx, cy);
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

            object::draw(sx, sy);
        }
    };

    // default size of text in terms of rows per screenful
    VARP(uitextrows, 1, 40, 200);

    struct label : object
    {
        char *str;
        float scale;
        vec color;

        label(const char *str, float scale = 1, float r = 1, float g = 1, float b = 1)
            : str(newstring(str)), scale(scale), color(r, g, b) {}
        ~label()
        {
            delete[] str;
        }

        float drawscale() const { return scale / (FONTH * uitextrows); }

        void draw(float sx, float sy)
        {
            float k = drawscale();
            glPushMatrix();
            glScalef(k, k, 1);
            draw_text(str, int(sx/k), int(sy/k), color.x * 255, color.y * 255, color.z * 255, 255);
            glColor3f(1, 1, 1);
            glPopMatrix();

            object::draw(sx, sy);
        }

        void layout()
        {
            object::layout();

            int tw, th;
            text_bounds(str, tw, th);
            float k = drawscale();
            w = max(w, tw*k);
            h = max(h, th*k);
        }

        void set(const char *text)
        {
            delete[] str;
            str = newstring(text);
        }
    };

    struct varlabel : object
    {
        var::cvar *ev;
        float scale;
        vec color;

        varlabel(var::cvar *ev, float scale = 1, float r = 1, float g = 1, float b = 1)
            : ev(ev), scale(scale), color(r, g, b) {}

        float drawscale() const { return scale / (FONTH * uitextrows); }

        char *getval()
        {
            switch (ev->type)
            {
                case var::VAR_I:
                {
                    static char s[64];
                    snprintf(s, sizeof(s), "%i", ev->curv.i);
                    return s;
                }
                case var::VAR_F:
                {
                    static char s[64];
                    snprintf(s, sizeof(s), "%f", ev->curv.f);
                    return s;
                }
                case var::VAR_S:
                {
                    return ev->curv.s;
                    break;
                }
                default: return NULL;
            }
        }

        void draw(float sx, float sy)
        {
            float k = drawscale();
            glPushMatrix();
            glScalef(k, k, 1);
            draw_text(getval(), int(sx/k), int(sy/k), color.x * 255, color.y * 255, color.z * 255, 255);
            glColor3f(1, 1, 1);
            glPopMatrix();

            object::draw(sx, sy);
        }

        void layout()
        {
            object::layout();

            int tw, th;
            text_bounds(getval(), tw, th);
            float k = drawscale();
            w = max(w, tw*k);
            h = max(h, th*k);
        }
    };

    struct text_editor : object
    {
        const char *name;
        float scale, offsetx, offsety;
        editor *edit;
        char *keyfilter, *fieldval;
        bool fieldmode, wasfocused;
        int onchange;

        text_editor(
            const char *name,
            int length, int height,
            float scale = 1,
            const char *initval = NULL,
            int mode = EDITORUSED,
            const char *keyfilter = NULL,
            bool password = false,
            bool fieldmode = false,
            int onchange = 0
        ) :
            name(name), scale(scale),
            offsetx(0), offsety(0),
            keyfilter(keyfilter ? newstring(keyfilter) : NULL), fieldval(NULL),
            fieldmode(fieldmode), wasfocused(false), onchange(onchange)
        {
            edit = useeditor(name, mode, false, initval, password);
            edit->linewrap = length<0;
            edit->maxx = edit->linewrap ? -1 : length;
            edit->maxy = height <= 0 ? 1 : -1;
            edit->pixelwidth = abs(length)*FONTW;
            if (edit->linewrap && edit->maxy==1)
            {
                int temp;
                text_bounds(edit->lines[0].text, temp, edit->pixelheight, edit->pixelwidth); //only single line editors can have variable height
            }
            else
                edit->pixelheight = FONTH*max(height, 1);
        }
        ~text_editor()
        {
            DELETEA(keyfilter);
            DELETEA(fieldval);
            if (edit->mode!=EDITORFOREVER) removeeditor(edit);
        }

        object *target(float cx, float cy)
        {
            object *o = object::target(cx, cy);
            return o ? o : this;
        }

        object *hover(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        object *select(float cx, float cy)
        {
            return target(cx, cy) ? this : NULL;
        }

        void hovering(float cx, float cy)
        {
            if (isselected(this) && isfocused(this))
            {
                bool dragged = max(fabs(cx - offsetx), fabs(cy - offsety)) > (FONTH/8.0f)*scale/float(FONTH*uitextrows);
                edit->hit(int(floor(cx*(FONTH*uitextrows)/scale - FONTW/2)), int(floor(cy*(FONTH*uitextrows)/scale)), dragged);
            }
        }

        void selected(float cx, float cy)
        {
            focuseditor(edit);
            setfocus(this);
            edit->mark(false);
            offsetx = cx;
            offsety = cy;
        }

        bool key(int code, bool isdown, int cooked)
        {
            if (object::key(code, isdown, cooked)) return true;
            if (!isfocused(this)) return false;
            switch(code)
            {
                case SDLK_RETURN:
                case SDLK_TAB:
                    if (cooked && edit->maxy != 1) break;
                case SDLK_ESCAPE:
                    if (cooked) setfocus(NULL);
                    return true;
                case SDLK_KP_ENTER:
                    if (cooked && edit->maxy == 1) setfocus(NULL);
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
                case -4:
                case -5:
                    break;

                default:
                    if (!cooked || code<32) return false;
                    if (keyfilter && !strchr(keyfilter, cooked)) return true;
                    break;
            }
            if (isdown) edit->key(code, cooked);
            return true;
        }

        void layout()
        {
            object::layout();

            if (edit->linewrap && edit->maxy==1)
            {
                int temp;
                text_bounds(edit->lines[0].text, temp, edit->pixelheight, edit->pixelwidth); //only single line editors can have variable height
            }
            w = max(w, (edit->pixelwidth + FONTW)*scale/float(FONTH*uitextrows));
            h = max(h, edit->pixelheight*scale/float(FONTH*uitextrows));
        }

        void handle_focus(bool focus)
        {
            if (!focus)
            {
                if (!fieldval)
                {
                    fieldval = newstring(edit->currentline().text);

                    /* we do have the variable here, no checks needed */
                    var::cvar *ev = var::get(name);
                    ev->set(fieldval, true);

                    lua::engine.getref(onchange);
                    if  (lua::engine.is<void*>(-1))
                         lua::engine.call(0, 0);
                    else lua::engine.pop(1);
                }
                else
                {
                    if (strcmp(edit->currentline().text, fieldval))
                    {
                        DELETEA(fieldval);
                        fieldval = newstring(edit->currentline().text);

                        var::cvar *ev = var::get(name);
                        ev->set(fieldval, true);

                        lua::engine.getref(onchange);
                        if  (lua::engine.is<void*>(-1))
                             lua::engine.call(0, 0);
                        else lua::engine.pop(1);
                    }
                }
            }
        }

        void draw(float sx, float sy)
        {
            /* abuse draw method to handle focusing */
            if (fieldmode)
            {
                if (this == focused && !wasfocused)
                {
                    handle_focus(true);
                    wasfocused = true;
                }
                else if (this != focused && wasfocused)
                {
                    /* handle this too, maybe for later .. */
                    handle_focus(false);
                    wasfocused = false;
                }
            }

            glPushMatrix();
            glTranslatef(sx, sy, 0);
            glScalef(scale/(FONTH*uitextrows), scale/(FONTH*uitextrows), 1);
            edit->draw(FONTW/2, 0, 0xFFFFFF, isfocused(this));
            glColor3f(1, 1, 1);
            glPopMatrix();

            object::draw(sx, sy);
        }
    };

    struct named_object : object
    {
        char *name;

        named_object(const char *name) : name(newstring(name)) {}
        ~named_object() { delete[] name; }

        const char *getname() const { return name; }
    };

    struct tag : named_object
    {
        tag(const char *name) : named_object(name) {}
    };

    struct window : named_object
    {
        int onhide;
        int nofocus;
        int realtime;

        window(const char *name, int onhide = 0, int nofocus = 0, int realtime = 0)
         : named_object(name), onhide(onhide), nofocus(nofocus), realtime(realtime)
        {}
        ~window() { lua::engine.unref(onhide); }

        void hidden()
        {
            if (onhide) lua::engine.getref(onhide).call(0, 0);
            resetcursor();
        }
    };

    struct world : object
    {
        bool focuschildren()
        {
            loopchildren(o,
            {
                window *w = (window*)o;
                if ((w && !w->nofocus) || (w && !GuiControl::isMouselooking())) return true;
            });
            return false;
        }

        void updatechildren()
        {
            loopchildren(o,
            {
                window *w = (window*)o;
                if (w && w->realtime)
                    lua::engine.getg("gui")
                        .t_getraw("show")
                        .push(w->name)
                        .call(1, 0)
                        .pop(1);
            });
        }

        void layout()
        {
            object::layout();

            float margin = max((float(screen->w)/screen->h - 1)/2, 0.0f);
            x = -margin;
            y = 0;
            w = 1 + 2*margin;
            h = 1;

            adjustchildren();
        }
    };

    world *world_inst = NULL;

    vector<object *> build;

    window *buildwindow(const char *name, int contents, int onhide = 0, int nofocus = 0, int realtime = 0)
    {
        window *win = new window(name, onhide, nofocus, realtime);
        build.add(win);
        lua::engine.getref(contents).call(0, 0);
        lua::engine.unref (contents);
        build.pop();
        return win;
    }

    bool hideui(const char *name)
    {
        window *win = dynamic_cast<window *>(world_inst->findname(name, false));
        if (win)
        {
            win->hidden();
            world_inst->remove(win);
        }
        return win!=NULL;
    }

    void addui(object *o, int children)
    {
        if (build.length())
        {
            o->parent = build.last();
            build.last()->children.add(o);
        }
        lua::engine.getref(children);
        if (lua::engine.is<void*>(-1))
        {
            build.add(o);
            lua::engine.call(0, 0);
            lua::engine.unref(children);
            build.pop();
        }
        else lua::engine.pop(1);
    }

    /* holds labels that are around */
    vector<label *> labels;

    /* COMMAND SECTION */

    void _bind_showui(lua_Engine e)
    {
        const char *name = e.get<const char*>(1);

        if (!e.is<void*>(2))
        {
            e.typeerror(2, "function");
            return;
        }
        int contents = e.push_index(2).ref();

        int onhide   = 0;
        if (e.is<void*>(3))
            onhide = e.push_index(3).ref();

        if (build.length())
        {
            e.push(false);
            return;
        }

        window *oldwindow = dynamic_cast<window *>(world_inst->findname(name, false));
        if (oldwindow)
        {
            oldwindow->hidden();
            world_inst->remove(oldwindow);
        }
        window *window = buildwindow(name, contents, onhide, e.get<int>(4), e.get<int>(5));
        world_inst->children.add(window);
        window->parent = world_inst;

        e.push(true);
    }

    void _bind_hideui(lua_Engine e)
    {
        e.push(hideui(e.get<const char*>(1)));
    }

    void _bind_replaceui(lua_Engine e)
    {
        const char *wname    = e.get<const char*>(1);
        const char *tname    = e.get<const char*>(2);

        if (!e.is<void*>(3))
        {
            e.typeerror(3, "function");
            return;
        }
        int contents = e.push_index(3).ref();

        if (build.length())
        {
            e.push(false);
            return;
        }

        window *win = dynamic_cast<window *>(world_inst->findname(wname, false));
        if (!win)
        {
            printf("A\n");
            e.push(false);
            return;
        }

        tag *tg = dynamic_cast<tag *>(win->findname(tname));
        if (!tg)
        {
            e.push(false);
            return;
        }

        tg->children.deletecontents();
        build.add(tg);
        lua::engine.getref(contents).call(0, 0);
        lua::engine.unref (contents);
        build.pop();

        e.push(true);
    }

    void _bind_uialign(lua_Engine e)
    {
        if (build.length())
        {
            build.last()->adjust = (build.last()->adjust & ~ALIGN_MASK)
                | ((clamp(e.get<int>(1), -1, 1)+2)<<ALIGN_HSHIFT)
                | ((clamp(e.get<int>(2), -1, 1)+2)<<ALIGN_VSHIFT);
        }
    }

    void _bind_uiclamp(lua_Engine e)
    {
        if (build.length())
        {
            build.last()->adjust = (build.last()->adjust & ~CLAMP_MASK)
                | (e.get<int>(1) ? CLAMP_LEFT : 0)
                | (e.get<int>(2) ? CLAMP_RIGHT : 0)
                | (e.get<int>(3) ? CLAMP_BOTTOM : 0)
                | (e.get<int>(4) ? CLAMP_TOP : 0);
        }
    }

    void _bind_uitag(lua_Engine e)
    {
        addui(new tag(e.get<const char*>(1)), e.push_index(2).ref());
    }

    void _bind_uivlist(lua_Engine e)
    {
        addui(new list(false, e.get<float>(1)), e.push_index(2).ref());
    }

    void _bind_uihlist(lua_Engine e)
    {
        addui(new list(true, e.get<float>(1)), e.push_index(2).ref());
    }

    void _bind_uitable(lua_Engine e)
    {
        addui(new table(e.get<int>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uispace(lua_Engine e)
    {
        addui(new spacer(e.get<float>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uifill(lua_Engine e)
    {
        addui(new filler(e.get<float>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uiclip(lua_Engine e)
    {
        addui(new clipper(e.get<float>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uiscroll(lua_Engine e)
    {
        addui(new scroller(e.get<float>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uihscrollbar(lua_Engine e)
    {
        addui(new hscrollbar(e.get<float>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uivscrollbar(lua_Engine e)
    {
        addui(new vscrollbar(e.get<float>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uiscrollbutton(lua_Engine e)
    {
        addui(new scroll_button, e.push_index(1).ref());
    }

    void _bind_uihslider(lua_Engine e)
    {
        const char *var = e.get<const char*>(1);
        var::cvar  *ev  = var::get(e.get<const char*>(1));
        if (!ev)    ev  = var::regvar(var, new var::cvar(var, e.get<int>(2)));

        int minv = e.get<int>(2) ? e.get<int>(2) : (ev->minv.i != -1 ? ev->minv.i : 0);
        int maxv = e.get<int>(3) ? e.get<int>(3) : (ev->maxv.i != -1 ? ev->maxv.i : 0);
        addui(new hslider(var, minv, maxv), e.push_index(4).ref());
    }

    void _bind_uivslider(lua_Engine e)
    {
        const char *var = e.get<const char*>(1);
        var::cvar  *ev  = var::get(e.get<const char*>(1));
        if (!ev)    ev  = var::regvar(var, new var::cvar(var, e.get<int>(2)));

        int minv = e.get<int>(2) ? e.get<int>(2) : (ev->minv.i != -1 ? ev->minv.i : 0);
        int maxv = e.get<int>(3) ? e.get<int>(3) : (ev->maxv.i != -1 ? ev->maxv.i : 0);
        addui(new vslider(var, minv, maxv), e.push_index(4).ref());
    }

    void _bind_uisliderbutton(lua_Engine e)
    {
        addui(new slider_button, e.push_index(1).ref());
    }

    void _bind_uioffset(lua_Engine e)
    {
        addui(new offsetter(e.get<float>(1), e.get<float>(2)), e.push_index(3).ref());
    }

    void _bind_uibutton(lua_Engine e)
    {
        addui(new button(e.push_index(1).ref()), e.push_index(2).ref());
    }

    void _bind_uicond(lua_Engine e)
    {
        addui(new conditional(e.push_index(1).ref()), e.push_index(2).ref());
    }

    void _bind_uicondbutton(lua_Engine e)
    {
        addui(new conditional_button(e.push_index(1).ref(), e.push_index(2).ref()), e.push_index(3).ref());
    }

    void _bind_uitoggle(lua_Engine e)
    {
        addui(new toggle(e.push_index(1).ref(), e.push_index(2).ref(), e.get<float>(3)), e.push_index(4).ref());
    }

    void _bind_uiimage(lua_Engine e)
    {
        addui(
            new image(
                textureload(
                    e.get<const char*>(1),
                    3, true, false
                ),
                e.get<float>(2),
                e.get<float>(3)
            ),
            e.push_index(4).ref()
        );
    }

    void _bind_uislotview(lua_Engine e)
    {
        addui(new slot_viewer(e.get<int>(1), e.get<float>(2), e.get<float>(3)), e.push_index(4).ref());
    }

    void _bind_uialtimage(lua_Engine e)
    {
        if (build.empty()) return;

        image *img = dynamic_cast<image *>(build.last());
        if (img && img->tex==notexture)
        {
            img->tex = textureload(e.get<const char*>(1), 3, true, false);
        }
    }

    void _bind_uicolor(lua_Engine e)
    {
        addui(
            new rectangle(
                rectangle::SOLID,
                e.get<float>(1),
                e.get<float>(2),
                e.get<float>(3),
                e.get<float>(4),
                e.get<float>(5),
                e.get<float>(6)
            ),
            e.push_index(7).ref()
        );
    }

    void _bind_uimodcolor(lua_Engine e)
    {
        addui(
            new rectangle(
                rectangle::MODULATE,
                e.get<float>(1),
                e.get<float>(2),
                e.get<float>(3),
                1,
                e.get<float>(4),
                e.get<float>(5)
            ),
            e.push_index(6).ref()
        );
    }

    void _bind_uistretchedimage(lua_Engine e)
    {
        addui(
            new stretched_image(
                textureload(
                    e.get<const char*>(1),
                    3, true, false
                ),
                e.get<float>(2),
                e.get<float>(3)
            ),
            e.push_index(4).ref()
        );
    }

    void _bind_uicroppedimage(lua_Engine e)
    {
        Texture *tex = textureload(e.get<const char*>(1), 3, true, false);
        const char *cropx = e.get<const char*>(4);
        const char *cropy = e.get<const char*>(5);
        const char *cropw = e.get<const char*>(6);
        const char *croph = e.get<const char*>(7);

        addui(
            new cropped_image(
                tex, e.get<float>(3), e.get<float>(4),
                strchr(cropx, 'p') ? atof(cropx) / tex->xs : atof(cropx),
                strchr(cropy, 'p') ? atof(cropy) / tex->ys : atof(cropy),
                strchr(cropw, 'p') ? atof(cropw) / tex->xs : atof(cropw),
                strchr(croph, 'p') ? atof(croph) / tex->ys : atof(croph)
            ),
            e.push_index(8).ref()
        );
    }

    void _bind_uiborderedimage(lua_Engine e)
    {
        Texture *tex = textureload(e.get<const char*>(1), 3, true, false);

        const char *texborder = e.get<const char*>(2);
        addui(
            new bordered_image(
                tex,
                strchr(texborder, 'p') ? atof(texborder) / tex->xs : atof(texborder),
                e.get<float>(3)
            ),
            e.push_index(4).ref()
        );
    }

    void _bind_uilabel(lua_Engine e)
    {
        float scale = e.get<float>(2);
        label *text  = new label(
            e.get<const char*>(1),
            (scale <= 0) ? 1 : scale,
            e.get<float>(3, 1),
            e.get<float>(4, 1),
            e.get<float>(5, 1)
        );

        labels.add(text);
        addui(text, e.push_index(6).ref());
        e.push(labels.length());
    }

    void _bind_uisetlabel(lua_Engine e)
    {
        label *text = labels[e.get<int>(1) - 1];
        if  (!text) return;

        text->set(e.get<const char*>(2));
    }

    void _bind_uivarlabel(lua_Engine e)
    {
        const char *var = e.get<const char*>(1);
        var::cvar  *ev  = var::get(e.get<const char*>(1));
        if (!ev)    ev  = var::regvar(var, new var::cvar(var, ""));

        float scale = e.get<float>(2);
        varlabel *text  = new varlabel(
            ev,
            (scale <= 0) ? 1 : scale,
            e.get<float>(3, 1),
            e.get<float>(4, 1),
            e.get<float>(5, 1)
        );
        addui(text, e.push_index(6).ref());
    }

    void _bind_uitexteditor(lua_Engine e)
    {
        int keep = e.get<int>(6);
        const char *filter = e.get<const char*>(7);
        addui(
            new text_editor(
                e.get<const char*>(1),
                e.get<int>(2),
                e.get<int>(3),
                e.get<float>(4, 1),
                e.get<const char*>(5),
                keep ? EDITORFOREVER : EDITORUSED,
                filter ? filter : NULL
            ),
            e.push_index(8).ref()
        );
    }

    void _bind_uifield(lua_Engine e)
    {
        const char *var = e.get<const char*>(1);
        var::cvar  *ev  = var::get(e.get<const char*>(1));
        if (!ev)    ev  = var::regvar(var, new var::cvar(var, ""));

        const char *filter = e.get<const char*>(5);
        addui(
            new text_editor(
                var,
                e.get<int>(2),
                0,
                e.get<float>(4, 1),
                ev->curv.s,
                EDITORFOCUSED,
                filter ? filter : NULL,
                e.get<bool>(6),
                true,
                e.push_index(3).ref()
            ),
            e.push_index(7).ref()
        );
    }

    FVAR(cursorsensitivity, 1e-3f, 1, 1000);

    float cursorx = 0.5f, cursory = 0.5f;

    void resetcursor()
    {
        if (editmode || world_inst->children.empty())
            cursorx = cursory = 0.5f;
    }

    bool movecursor(int &dx, int &dy)
    {
        if ((world_inst->children.empty() || !world_inst->focuschildren()) && GuiControl::isMouselooking()) return false;
        float scale = 500.0f / cursorsensitivity;
        cursorx = clamp(cursorx+dx*(screen->h/(screen->w*scale)), 0.0f, 1.0f);
        cursory = clamp(cursory+dy/scale, 0.0f, 1.0f);
        return true;
    }

    bool hascursor(bool targeting)
    {
        if (!world_inst->focuschildren()) return false;
        if (world_inst->children.length())
        {
            if (!targeting) return true;
            if (world_inst && world_inst->target(cursorx*world_inst->w, cursory*world_inst->h)) return true;
        }
        return false;
    }

    void getcursorpos(float &x, float &y)
    {
        if (world_inst->children.length() || !GuiControl::isMouselooking()) { x = cursorx; y = cursory; }
        else x = y = .5f;
    }

    bool keypress(int code, bool isdown, int cooked)
    {
        if (!hascursor(true)) return false;
        switch(code)
        {
            case -1:
            {
                if (isdown)
                {
                    selected = world_inst->select(cursorx*world_inst->w, cursory*world_inst->h);
                    if (selected)
                    {
                        /* apply changes in focused field */
                        text_editor *focus = dynamic_cast<text_editor *>(focused);
                        if (focus && focus->fieldmode)
                        {
                            focus->handle_focus(false);
                            focus->wasfocused = false;
                            setfocus(NULL);
                        }

                        selected->selected(selectx, selecty);
                    }
                }
                else selected = NULL;
                return true;
            }

            default:
                return world_inst->key(code, isdown, cooked);
        }
    }

    VAR(mainmenu, 1, 1, 0);
    void clearmainmenu()
    {
        if (mainmenu && (isconnected() || haslocalclients()))
        {
            mainmenu = 0;

            lua::engine.getg("gui")
                      .t_getraw("hide")
                      .push("main")
                      .call(1, 0);
            lua::engine.t_getraw("hide").push("vtab").call(1, 0);
            lua::engine.t_getraw("hide").push("htab").call(1, 0);
            lua::engine.pop(1);
        }
    }

    void setup()
    {
        world_inst = new world;
    }

    text_editor *textediting = NULL;

    static bool space = false;

    void update()
    {
        loopv(executelater)
        {
            lua::engine.getref(executelater[i]).call(0, 0);
        }
        executelater.setsize(0);

        if (mainmenu && !isconnected(true) && !world_inst->children.length())
            lua::engine.getg("gui").t_getraw("show").push("main").call(1, 0).pop(1);

        if ((editmode && !mainmenu) && !space)
        {
            lua::engine.getg("gui").t_getraw("show").push("space").call(1, 0);
            lua::engine.t_getraw("hide").push("vtab").call(1, 0);
            lua::engine.t_getraw("hide").push("htab").call(1, 0);
            lua::engine.pop(1);
            space = true;
            resetcursor();
        }
        else if ((!editmode || mainmenu) && space)
        {
            lua::engine.getg("gui").t_getraw("hide").push("space").call(1, 0);
            lua::engine.t_getraw("hide").push("vtab").call(1, 0);
            lua::engine.t_getraw("hide").push("htab").call(1, 0);
            lua::engine.pop(1);
            space = false;
            resetcursor();
        }

        world_inst->updatechildren();
        world_inst->layout();

        if (hascursor())
        {
            hovering = world_inst->hover(cursorx*world_inst->w, cursory*world_inst->h);
            if (hovering) hovering->hovering(hoverx, hovery);
        }
        else hovering = NULL;

        world_inst->layout();

        bool wastextediting = textediting!=NULL;
        textediting = dynamic_cast<text_editor *>(focused);
        if ((textediting!=NULL) != wastextediting)
        {
            SDL_EnableUNICODE(textediting!=NULL);
            keyrepeat(textediting!=NULL || editmode);
        }
    }

    void render()
    {
        if (world_inst->children.empty()) return;

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glMatrixMode(GL_PROJECTION);
        glPushMatrix();
        glLoadIdentity();
        glOrtho(world_inst->x, world_inst->x + world_inst->w, world_inst->y + world_inst->h, world_inst->y, -1, 1);

        glMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        glLoadIdentity();

        glColor3f(1, 1, 1);

        world_inst->draw();

        glMatrixMode(GL_PROJECTION);
        glPopMatrix();
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix();
        glEnable(GL_BLEND);
    }
}

struct change
{
    int type;
    const char *desc;

    change() {}
    change(int type, const char *desc) : type(type), desc(desc) {}
};
static vector<change> needsapply;

VARP(applydialog, 0, 1, 1);

void addchange(const char *desc, int type)
{
    if (!applydialog) return;
    loopv(needsapply) if (!strcmp(needsapply[i].desc, desc)) return;
    needsapply.add(change(type, desc));
    lua::engine.getg("gui")
               .t_getraw("show_changes")
               .call(0, 0)
               .pop(1);
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

void applychanges()
{
    int changetypes = 0;
    loopv(needsapply) changetypes |= needsapply[i].type;
    if (changetypes&CHANGE_GFX)
    {
        int ref = lua::engine.getg("engine").t_getraw("resetgl").ref();
        gui::executelater.add(ref);
        lua::engine.pop(1);
    }
    if (changetypes&CHANGE_SOUND)
    {
        int ref = lua::engine.getg("sound").t_getraw("reset").ref();
        gui::executelater.add(ref);
        lua::engine.pop(1);
    }
}

void _bind_clearchanges(lua_Engine e)
{
    clearchanges(CHANGE_GFX | CHANGE_SOUND);
}

void _bind_applychanges(lua_Engine e)
{
    applychanges();
}

void _bind_getchanges(lua_Engine e)
{
    e.t_new();
    loopv(needsapply)
    {
        e.t_set(i + 1, needsapply[i].desc);
    }
}

VAR(fonth, 512, 0, 0);

void consolebox(int x1, int y1, int x2, int y2)
{
    glPushMatrix();

    glScalef(.5, .5, 1);
    glTranslatef(x1, y1, 0);
    glColor4f(1, 0, 0, .8);
    glBegin(GL_TRIANGLE_STRIP);

    glVertex2i(x1, y1);
    glVertex2i(x2, y1);
    glVertex2i(x1, y2);
    glVertex2i(x2, y2);

    glEnd();

    glPopMatrix();
}
