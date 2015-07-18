/* The GUI subsystem of OctaForge - core definitions
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#ifndef OCTA_GUI_CORE_HH
#define OCTA_GUI_CORE_HH

#include <ostd/types.hh>
#include <ostd/event.hh>
#include <ostd/vector.hh>
#include <ostd/algorithm.hh>

namespace octa { namespace gui {

enum {
    ALIGN_HMASK = 0x3,
    ALIGN_VMASK = 0xC,
    ALIGN_MASK  = ALIGN_HMASK | ALIGN_VMASK,

    CLAMP_MASK  = 0xF0,

    ALIGN_HSHIFT = 0,
    ALIGN_VSHIFT = 2,

    ALIGN_HNONE   = 0 << ALIGN_HSHIFT,
    ALIGN_LEFT    = 1 << ALIGN_HSHIFT,
    ALIGN_HCENTER = 2 << ALIGN_HSHIFT,
    ALIGN_RIGHT   = 3 << ALIGN_HSHIFT,

    ALIGN_VNONE   = 0 << ALIGN_VSHIFT,
    ALIGN_TOP     = 1 << ALIGN_VSHIFT,
    ALIGN_VCENTER = 2 << ALIGN_VSHIFT,
    ALIGN_BOTTOM  = 3 << ALIGN_VSHIFT,

    ALIGN_CENTER = ALIGN_HCENTER | ALIGN_VCENTER,
    ALIGN_NONE   = ALIGN_HNONE   | ALIGN_VNONE,

    CLAMP_LEFT   = 1 << 4,
    CLAMP_RIGHT  = 1 << 5,
    CLAMP_TOP    = 1 << 6,
    CLAMP_BOTTOM = 1 << 7
};

class Widget;

class ClipArea {
    float p_x1, p_y1, p_x2, p_y2;

public:
    ClipArea(float x, float y, float w, float h):
        p_x1(x), p_y1(y), p_x2(x + w), p_y2(y + h) {}

    void intersect(const ClipArea &c) {
        p_x1 = ostd::max(p_x1, c.p_x1);
        p_y1 = ostd::max(p_y1, c.p_y1);
        p_x2 = ostd::max(p_x1, ostd::min(p_x2, c.p_x2));
        p_y2 = ostd::max(p_y1, ostd::min(p_y2, c.p_y2));
    }

    bool is_fully_clipped(float x, float y, float w, float h) const {
        return (p_x1 == p_x2) || (p_y1 == p_y2) || (x >= p_x2) ||
               (y >= p_y2) || ((x + w) <= p_x1) || ((y + h) <= p_y1);
    }

    void scissor();
};

class Projection {
    Widget *p_obj;
    float p_px, p_py, p_pw, p_ph;

public:
    Projection(Widget *obj): p_obj(obj),
        p_px(0), p_py(0), p_pw(0), p_ph(0) {}

    void calc(float *pw = nullptr, float *ph = nullptr);

    void adjust_layout();

    void projection();

    void calc_scissor(bool clip, float &x1, float &y1, float &x2, float &y2);

    void draw(float sx, float sy);
    void draw();
};

class Color {
    ostd::byte p_r, p_g, p_b, p_a;

public:
    ostd::Signal<const Color, ostd::byte> red_changed   = this;
    ostd::Signal<const Color, ostd::byte> green_changed = this;
    ostd::Signal<const Color, ostd::byte> blue_changed  = this;
    ostd::Signal<const Color, ostd::byte> alpha_changed = this;

    Color(): p_r(0xFF), p_g(0xFF), p_b(0xFF), p_a(0xFF) {}

    Color(ostd::Uint32 color): p_r((color >> 16) & 0xFF),
                               p_g((color >>  8) & 0xFF),
                               p_b( color        & 0xFF),
                               p_a(!(color >> 24) ? 0xFF : (color >> 24)) {}

    Color(ostd::Uint32 color, ostd::byte alpha):
        p_r((color >> 16) & 0xFF), p_g((color >>  8) & 0xFF),
        p_b(color & 0xFF), p_a(alpha) {}

    Color(ostd::byte red, ostd::byte green, ostd::byte blue,
          ostd::byte alpha = 0xFF):
        p_r(red), p_g(green), p_b(blue), p_a(alpha) {}

    ostd::byte red  () const { return p_r; }
    ostd::byte green() const { return p_g; }
    ostd::byte blue () const { return p_b; }
    ostd::byte alpha() const { return p_a; }

    ostd::byte set_red(ostd::byte v);
    ostd::byte set_green(ostd::byte v);
    ostd::byte set_blue(ostd::byte v);
    ostd::byte set_alpha(ostd::byte v);

    void init() const;
    void attrib() const;
    void def() const;
};

class Widget {
    Widget *p_parent;
    ostd::Vector<Widget *> p_children;

    float p_x, p_y, p_w, p_h;

    ostd::byte p_adjust;

    bool p_floating, p_visible, p_disabled;

protected:
    static int generate_type() {
        static int wtype = 0;
        return wtype++;
    }

public:
    static int type;

    Widget(): p_parent(nullptr), p_x(0), p_y(0), p_w(0), p_h(0),
        p_adjust(ALIGN_CENTER) {}

    virtual int get_type() {
        return Widget::type;
    }

    float x() const { return p_x; }
    float y() const { return p_y; }

    float width() const { return p_w; }
    float height() const { return p_h; }

    template<typename F>
    void loop_children(F fun) {
        for (auto o: p_children.iter())
            fun(o);
    }

    template<typename F>
    void loop_children_rev(F fun) {
        for (auto o: p_children.iter().reverse())
            fun(o);
    }

    virtual void layout();

    void adjust_children(float px, float py, float pw, float ph) {
        loop_children([px, py, pw, ph](Widget *o) {
            o->adjust_layout(px, py, pw, ph);
        });
    }

    virtual void adjust_children() {
        adjust_children(0, 0, p_w, p_h);
    }

    virtual void adjust_layout(float px, float py, float pw, float ph);
};

int Widget::type = Widget::generate_type();

} } /* namespace octa::gui */

#endif