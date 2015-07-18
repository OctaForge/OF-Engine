/* The GUI subsystem of OctaForge - core implementation
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#include "octa/gui/core.hh"

#include "cube.hh"
#include "engine.hh"

namespace octa { namespace gui {

int generate_widget_type() {
    static int wtype = 0;
    return wtype++;
}

/* cliparea */

void ClipArea::scissor(Root *r) {
    int sx1, sy1, sx2, sy2;
    r->projection()->calc_scissor(p_x1, p_y1, p_x2, p_y2, sx1, sy1, sx2, sy2);
    glScissor(sx1, sy1, sx2 - sx1, sy2 - sy1);
}

/* projection */

void Projection::calc(float &pw, float &ph) {
    Root *r = p_obj->root();
    float aspect = r->get_aspect(true);
    p_ph = ostd::max(ostd::max(p_obj->height(),
        (p_obj->width() / aspect)), 1.0f);
    p_pw = aspect * p_ph;
    p_px = p_py = 0;
    pw = p_pw;
    ph = p_ph;
}

void Projection::adjust_layout() {
    float pw, ph;
    calc(pw, ph);
    p_obj->adjust_layout(0, 0, pw, ph);
}

void Projection::projection() {
}

void Projection::calc_scissor(float x1, float y1, float x2, float y2,
                              int &sx1, int &sy1, int &sx2, int &sy2,
                              bool clip) {
    Root *r = p_obj->root();
    vec2 sscale(p_ss_x, p_ss_y);
    vec2 soffset(p_so_x, p_so_y);
    vec2 s1 = vec2(x1, y2).mul(sscale).add(soffset),
         s2 = vec2(x2, y1).mul(sscale).add(soffset);
    int hudw = r->get_pixel_w(), hudh = r->get_pixel_h();
    sx1 = int(floor(s1.x * hudw + 0.5f));
    sy1 = int(floor(s1.y * hudh + 0.5f));
    sx2 = int(floor(s2.x * hudw + 0.5f));
    sy2 = int(floor(s2.y * hudh + 0.5f));
    if (clip) {
        sx1 = clamp(sx1, 0, hudw);
        sy1 = clamp(sy1, 0, hudh);
        sx2 = clamp(sx2, 0, hudw);
        sy2 = clamp(sy2, 0, hudh);
    }
}

void Projection::draw(float, float) {
}

void Projection::draw() {
    draw(p_obj->x(), p_obj->y());
}

/* color */

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

int Widget::type = generate_widget_type();

void Widget::layout() {
    p_w = p_h = 0;
    loop_children([this](Widget *o) {
        if (!o->floating()) o->p_x = o->p_y = 0;
        o->layout();
        this->p_w = ostd::max(this->p_w, o->p_x + o->p_w);
        this->p_h = ostd::max(this->p_h, o->p_y + o->p_h);
        return false;
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

/* named widget */

int NamedWidget::type = generate_widget_type();

/* tag */

int Tag::type = generate_widget_type();

/* window */

int Window::type = generate_widget_type();

/* overlay */

int Overlay::type = generate_widget_type();

/* root */

int Root::type = generate_widget_type();

int Root::get_pixel_w(bool force_aspect) const {
    if (!force_aspect) return hudw;
    float asp = get_aspect();
    if (asp) return int(ceil(hudw * asp));
    return hudw;
}

int Root::get_pixel_h() const {
    return hudh;
}

float Root::get_aspect(bool force) const {
    if (forceaspect) return forceaspect;
    return float(get_pixel_w()) / get_pixel_h();
}

void Root::adjust_children() {
    loop_children([this](Widget *o) {
        Projection *p = o->projection();
        this->set_projection(p);
        p->adjust_layout();
        this->set_projection(nullptr);
        return false;
    });
}

void Root::layout() {
    layout_dim();
    loop_children([this](Widget *o) {
        if (!o->floating()) {
            o->set_x(0);
            o->set_y(0);
        }
        this->set_projection(o->projection());
        o->layout();
        this->set_projection(nullptr);
        return false;
    });
    adjust_children();
}

} } /* namespace octa::gui */