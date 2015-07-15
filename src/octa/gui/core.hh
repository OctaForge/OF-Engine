/* The GUI subsystem of OctaForge - core definitions
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#ifndef OCTA_GUI_CORE_HH
#define OCTA_GUI_CORE_HH

#include <ostd/types.hh>
#include <ostd/vector.hh>

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

    ostd::byte red(ostd::byte nr);
    ostd::byte green(ostd::byte nr);
    ostd::byte blue(ostd::byte nr);
    ostd::byte alpha(ostd::byte nr);
};

class Widget {
    Widget *p_parent;
    ostd::Vector<Widget *> p_children;

    float p_x, p_y, p_w, p_h;

    ostd::byte p_adjust;

    bool p_floating, p_visible, p_disabled;

public:
    Widget(): p_parent(nullptr), p_x(0), p_y(0), p_w(0), p_h(0),
        p_adjust(ALIGN_CENTER) {}

    float x() const { return p_x; }
    float y() const { return p_y; }

    float width() const { return p_w; }
    float height() const { return p_h; }
};

} } /* namespace octa::gui */

#endif