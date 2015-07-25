/* The GUI subsystem of OctaForge - core implementation
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#include <ostd/tuple.hh>

#include "octa/gui/core.hh"

#include "cube.hh"
#include "engine.hh"

namespace octa { namespace gui {

int generate_widget_type() {
    static int wtype = 0;
    return wtype++;
}

int draw_changed = 0;

static int blend_type = BLEND_ALPHA;

void blend_change(int type, ostd::uint src, ostd::uint dst) {
    if (blend_type != type) {
        blend_type = type;
        glBlendFunc(src, dst);
    }
}

void blend_reset() {
    blend_change(BLEND_ALPHA, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

void blend_mod() {
    blend_change(BLEND_MOD, GL_ZERO, GL_SRC_COLOR);
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
    hudmatrix.ortho(p_px, p_px + p_pw, p_py + p_ph, p_py, -1, 1);
    resethudmatrix();
    vec2 sscale = vec2(hudmatrix.a.x, hudmatrix.b.y).mul(0.5f);
    vec2 soffset = vec2(hudmatrix.d.x, hudmatrix.d.y).mul(0.5f).add(0.5f);
    p_ss_x = sscale.x, p_ss_y = sscale.y;
    p_so_x = soffset.x, p_so_y = soffset.y;
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

void Projection::draw(float sx, float sy) {
    Root *r = p_obj->root();
    r->set_projection(this);
    projection();
    hudshader->set();

    blend_type = BLEND_ALPHA;
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    gle::colorf(1.0f, 1.0f, 1.0f);

    draw_changed = 0;
    r->p_drawing = nullptr;

    p_obj->draw(sx, sy);
    p_obj->stop_draw();

    glDisable(GL_BLEND);
    r->set_projection(nullptr);
}

void Projection::draw() {
    draw(p_obj->x(), p_obj->y());
}

float Projection::calc_above_hud() {
    return 1 - (p_obj->y() * p_ss_y + p_so_y);
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

static const Widget::TypeTag widget_type;

ostd::Size Widget::get_type() {
    return widget_type.get();
}

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

void Widget::end_draw_change(int change) {
    end_draw();
    draw_changed &= ~change;
    if (draw_changed) {
        if (draw_changed & CHANGE_SHADER) {
            hudshader->set();
        }
        if (draw_changed & CHANGE_COLOR) {
            gle::colorf(1.0f, 1.0f, 1.0f);
        }
        if (draw_changed & CHANGE_BLEND) {
            blend_reset();
        }
    }
}

void Widget::change_draw(int change) {
    Root *r = root();
    if (!r->p_drawing) {
        start_draw();
        draw_changed = change;
    } else if (r->p_drawing->get_type() != get_type()) {
        r->p_drawing->end_draw_change(change);
        start_draw();
        draw_changed = change;
    }
    r->p_drawing = this;
}

void Widget::stop_draw() {
    Root *r = root();
    if (r->p_drawing) {
        r->p_drawing->end_draw_change(0);
        r->p_drawing = nullptr;
    }
}

void Widget::draw(float sx, float sy) {
    Root *r = root();
    loop_children([this, r, sx, sy](Widget *o) {
        if (!r->clip_is_fully_clipped(sx + o->p_x, sy + o->p_y,
                                      o->p_w, o->p_h) && o->p_visible) {
            o->draw(sx + o->p_x, sy + o->p_y);
        }
        return false;
    });
}

/* named widget */

static const Widget::TypeTag named_widget_type;

ostd::Size NamedWidget::get_type() {
    return named_widget_type.get();
}

/* tag */

static const Widget::TypeTag tag_type;

ostd::Size Tag::get_type() {
    return tag_type.get();
}

/* window */

static const Widget::TypeTag window_type;

ostd::Size Window::get_type() {
    return window_type.get();
}

/* overlay */

static const Widget::TypeTag overlay_type;

ostd::Size Overlay::get_type() {
    return overlay_type.get();
}

/* root */

static const Widget::TypeTag root_type;

ostd::Size Root::get_type() {
    return root_type.get();
}

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
        if (!o->p_floating) o->p_x = o->p_y = 0;
        this->set_projection(o->projection());
        o->layout();
        this->set_projection(nullptr);
        return false;
    });
    adjust_children();
}

void Root::clip_push(float x, float y, float w, float h) {
    if (p_clipstack.empty()) { glEnable(GL_SCISSOR_TEST); }
    ClipArea &c = p_clipstack.emplace_back(x, y, w, h);
    if (p_clipstack.size() >= 2) {
        c.intersect(p_clipstack[p_clipstack.size() - 2]);
    }
    c.scissor(this);
}

void Root::clip_pop() {
    p_clipstack.pop();
    if (p_clipstack.empty()) {
        glDisable(GL_SCISSOR_TEST);
    } else {
        p_clipstack.back().scissor(this);
    }
}

bool Root::clip_is_fully_clipped(float x, float y, float w, float h) {
    if (p_clipstack.empty()) return false;
    return p_clipstack.back().is_fully_clipped(x, y, w, h);
}

void Root::clip_scissor() {
    p_clipstack.back().scissor(this);
}

void Root::draw(float sx, float sy) {
    loop_children([this, sx, sy](Widget *o) {
        if (!this->clip_is_fully_clipped(sx + o->p_x, sy + o->p_y,
                                         o->p_w, o->p_h) && o->p_visible) {
            o->projection()->draw(sx + o->p_x, sy + o->p_y);
        }
        return false;
    });
}

} } /* namespace octa::gui */