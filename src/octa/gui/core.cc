/* The GUI subsystem of OctaForge - core implementation
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#include "octa/gui/core.hh"

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

} } /* namespace octa::gui */