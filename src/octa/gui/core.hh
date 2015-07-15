/* The GUI subsystem of OctaForge - core definitions
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#ifndef OCTA_GUI_CORE_HH
#define OCTA_GUI_CORE_HH

#include <ostd/types.hh>

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
};

class Color {
    ostd::byte p_r, p_g, p_b, p_a;

public:
    Color(): p_r(0xFF), p_g(0xFF), p_b(0xFF), p_a(0xFF) {}

    Color(ostd::Uint32 color): p_r((color >> 16) & 0xFF),
                               p_g((color >>  8) & 0xFF),
                               p_b( color        & 0xFF),
                               p_a(!(coloc >> 24) ? 0xFF : (color >> 24)) {}

    Color(ostd::Uint32 color, ostd::byte alpha):
        p_r((color >> 16) & 0xFF), p_g((color >>  8) & 0xFF),
        p_b(color & 0xFF), p_a(alpha) {}

    Color(ostd::byte red, ostd::byte green, ostd::byte blue,
          ostd::byte alpha = 0xFF):
        p_r(red), p_g(green), p_b(blue), p_a(alpha) {}
};

class Widget {
};

} } /* namespace octa::gui */

#endif