/* The GUI subsystem of OctaForge - core implementation
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#include "octa/gui/core.hh"

#include "cube.hh"

namespace octa { namespace gui {

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

} } /* namespace octa::gui */