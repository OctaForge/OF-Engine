/* The GUI subsystem of OctaForge - core implementation
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#include "octa/gui/core.hh"

#include "cube.hh"

namespace octa { namespace gui {

/* cliparea */

void ClipArea::scissor() {
}

/* projection */

void Projection::calc(float *, float *) {
}

void Projection::adjust_layout() {
}

void Projection::projection() {
}

void Projection::calc_scissor(bool, float &, float &, float &, float &) {
}

void Projection::draw(float, float) {
}

void Projection::draw() {
    draw(p_obj->x(), p_obj->y());
}

/* color */

ostd::byte Color::set_red(ostd::byte v) {
    auto old = p_r;
    p_r = v;
    red_changed.emit(old);
    return old;
}

ostd::byte Color::set_green(ostd::byte v) {
    auto old = p_g;
    p_g = v;
    green_changed.emit(old);
    return old;
}

ostd::byte Color::set_blue(ostd::byte v) {
    auto old = p_b;
    p_b = v;
    blue_changed.emit(old);
    return old;
}

ostd::byte Color::set_alpha(ostd::byte v) {
    auto old = p_a;
    p_a = v;
    blue_changed.emit(old);
    return old;
}

void Color::init() const {
    gle::colorub(p_r, p_g, p_b, p_a);
}

void Color::attrib() const {
    gle::attribub(p_r, p_g, p_b, p_a);
}

void Color::def() const {
    gle::defcolor(4, GL_UNSIGNED_BYTE);
}

/* widget */

void Widget::layout() {
    p_w = p_h = 0;
    loop_children([this](Widget *o) {
        o->p_x = o->p_y = 0;
        o->layout();
        this->p_w = ostd::max(this->p_w, o->p_x + o->p_w);
        this->p_h = ostd::max(this->p_h, o->p_y + o->p_h);
    });
}

void Widget::adjust_layout(float px, float py, float pw, float ph) {
    switch (p_adjust & ALIGN_HMASK) {
    case ALIGN_LEFT   : p_x = px;                  break;
    case ALIGN_HCENTER: p_x = px + (pw - p_w) / 2; break;
    case ALIGN_RIGHT  : p_x = px +  pw - p_w;      break;
    }

    switch (p_adjust & ALIGN_VMASK) {
    case ALIGN_BOTTOM : p_y = py;                  break;
    case ALIGN_VCENTER: p_y = py + (ph - p_h) / 2; break;
    case ALIGN_TOP    : p_y = py +  ph - p_h;      break;
    }

    if (p_adjust & CLAMP_MASK) {
        if (p_adjust & CLAMP_LEFT  ) p_x = px;
        if (p_adjust & CLAMP_RIGHT ) p_w = px + pw - p_x;
        if (p_adjust & CLAMP_BOTTOM) p_y = py;
        if (p_adjust & CLAMP_TOP   ) p_h = py + ph - p_y;
    }

    adjust_children();
}

} } /* namespace octa::gui */