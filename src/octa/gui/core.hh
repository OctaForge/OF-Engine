/* The GUI subsystem of OctaForge - core definitions
 *
 * This file is part of OctaForge. See COPYING.md for futher information.
 */

#ifndef OCTA_GUI_CORE_HH
#define OCTA_GUI_CORE_HH

#include <ostd/types.hh>
#include <ostd/event.hh>
#include <ostd/vector.hh>
#include <ostd/string.hh>
#include <ostd/algorithm.hh>

namespace octa { namespace gui {

void draw_quad(float x, float y, float w, float h,
               float tx = 0, float ty = 0, float tw = 1, float th = 1);

void draw_quadtri(float x, float y, float w, float h,
                  float tx = 0, float ty = 0, float tw = 1, float th = 1);

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

enum class Orientation {
    horizontal, vertical
};

enum {
    CHANGE_SHADER = 1 << 0,
    CHANGE_COLOR  = 1 << 1,
    CHANGE_BLEND  = 1 << 2
};

enum {
    BLEND_ALPHA,
    BLEND_MOD
};

extern int draw_changed;

void blend_change(int type, ostd::uint src, ostd::uint dst);
void blend_reset();
void blend_mod();

class Widget;
class Root;

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

    void scissor(Root *r);
};

class Projection {
    Widget *p_obj;
    float p_px = 0, p_py = 0, p_pw = 0, p_ph = 0;
    float p_ss_x = 0, p_ss_y = 0, p_so_x = 0, p_so_y = 0;

public:
    Projection(Widget *obj): p_obj(obj) {}

    void calc(float &pw, float &ph);
    void calc() {
        float pw, ph;
        calc(pw, ph);
    }

    void adjust_layout();

    void projection();

    void calc_scissor(float x1, float y1, float x2, float y2,
                      int &sx1, int &sy1, int &sx2, int &sy2,
                      bool clip = false);

    void draw(float sx, float sy);
    void draw();

    float calc_above_hud();
};

class Color {
    ostd::byte p_r, p_g, p_b, p_a;

public:
    ostd::Signal<Color> red_changed   = this;
    ostd::Signal<Color> green_changed = this;
    ostd::Signal<Color> blue_changed  = this;
    ostd::Signal<Color> alpha_changed = this;

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

    void set_red(ostd::byte v) {
        p_r = v;
        red_changed.emit();
    }

    void set_green(ostd::byte v) {
        p_g = v;
        green_changed.emit();
    }

    void set_blue(ostd::byte v) {
        p_b = v;
        blue_changed.emit();
    }

    void set_alpha(ostd::byte v){
        p_a = v;
        blue_changed.emit();
    }

    void init() const;
    void attrib() const;
    void def() const;

    void get_final_rgba(const Widget *o, ostd::byte &r, ostd::byte &g,
                        ostd::byte &b, ostd::byte &a);
};

/* widget */

class Widget {
protected:
    Widget *p_parent = nullptr;
    mutable Root *p_root = nullptr;
    mutable Projection *p_proj = nullptr;

    ostd::Vector<Widget *> p_children;

    float p_x = 0, p_y = 0, p_w = 0, p_h = 0;

    ostd::byte p_adjust = ALIGN_CENTER;

    bool p_floating = false, p_visible = true, p_disabled = false;

public:
    friend class Root;

    struct TypeTag {
        TypeTag() {}
        ostd::Size get() const { return (ostd::Size)this; }
    };

    ostd::Signal<Widget> floating_changed = this;
    ostd::Signal<Widget> visible_changed = this;
    ostd::Signal<Widget> disabled_changed = this;

    Widget() {}

    virtual ostd::Size get_type();

    Root *root() const {
        if (p_root) return p_root;
        if (p_parent) {
            Root *r = p_parent->root();
            p_root = r;
            return r;
        }
        return nullptr;
    }

    Projection *projection(bool nonew = false) const {
        if (p_proj || nonew || ((Widget *)p_root == this)) return p_proj;
        p_proj = new Projection((Widget *)this);
        return p_proj;
    }

    void set_projection(Projection *proj) {
        p_proj = proj;
    }

    float x() const { return p_x; }
    float y() const { return p_y; }

    void set_x(float v) { p_x = v; }
    void set_y(float v) { p_y = v; }

    float width() const { return p_w; }
    float height() const { return p_h; }

    bool floating() const { return p_floating; }
    bool visible()  const { return p_visible; }
    bool disabled() const { return p_disabled; }

    void set_floating(bool v) {
        p_floating = v;
        floating_changed.emit();
    }

    void set_visible(bool v) {
        p_visible = v;
        visible_changed.emit();
    }

    void set_disabled(bool v) {
        p_disabled = v;
        disabled_changed.emit();
    }

    template<typename F>
    bool loop_children(F fun) {
        for (auto o: p_children.iter())
            if (fun(o)) return true;
        return false;
    }

    template<typename F>
    bool loop_children(F fun) const {
        for (auto o: p_children.iter())
            if (fun(o)) return true;
        return false;
    }

    template<typename F>
    bool loop_children_r(F fun) {
        for (auto o: p_children.iter().reverse())
            if (fun(o)) return true;
        return false;
    }

    template<typename F>
    bool loop_children_r(F fun) const {
        for (auto o: p_children.iter().reverse())
            if (fun(o)) return true;
        return false;
    }

    virtual void layout();

    void adjust_children(float px, float py, float pw, float ph) {
        loop_children([px, py, pw, ph](Widget *o) {
            o->adjust_layout(px, py, pw, ph);
            return false;
        });
    }

    virtual void adjust_children() {
        adjust_children(0, 0, p_w, p_h);
    }

    virtual void adjust_layout(float px, float py, float pw, float ph);

    virtual bool grabs_input() const { return true; }

    virtual void start_draw() {}
    virtual void end_draw() {}

    void end_draw_change(int change);
    void change_draw(int change = 0);
    void stop_draw();

    virtual void draw(float sx, float sy);

    void draw() {
        draw(p_x, p_y);
    }

    virtual bool is_root() {
        return false;
    }
};

/* named widget */

class NamedWidget: public Widget {
    ostd::String p_name;

public:
    ostd::Signal<const NamedWidget> name_changed = this;

    NamedWidget(ostd::String s): p_name(ostd::move(s)) {}

    virtual ostd::Size get_type();

    const ostd::String &name() const { return p_name; }

    void set_name(ostd::String s) {
        p_name = ostd::move(s);
        name_changed.emit();
    }
};

/* tag */

class Tag: public NamedWidget {
public:
    static int type;
    using NamedWidget::NamedWidget;

    virtual ostd::Size get_type();
};

/* window */

class Window: public NamedWidget {
    bool p_input_grab, p_above_hud;

public:
    ostd::Signal<const Window> input_grab_changed = this;
    ostd::Signal<const Window> above_hud_changed  = this;

    Window(ostd::String name, bool input_grab = true, bool above_hud = false):
        NamedWidget(ostd::move(name)), p_input_grab(input_grab),
        p_above_hud(above_hud) {}

    virtual ostd::Size get_type();

    bool input_grab() const { return p_input_grab; }
    bool above_hud() const { return p_above_hud; }

    void set_input_grab(bool v) {
        p_input_grab = v;
        input_grab_changed.emit();
    }

    void set_above_hud(bool v) {
        p_above_hud = v;
        above_hud_changed.emit();
    }

    bool grabs_input() const { return input_grab(); }
};

/* overlay */

class Overlay: public Window {
public:
    using Window::Window;

    virtual ostd::Size get_type();

    bool grabs_input() const { return false; }
};

/* root */

class Root: public Widget {
    ostd::Vector<Window *> p_windows;
    ostd::Vector<ClipArea> p_clipstack;

    Widget *p_drawing = nullptr;

    float p_curx = 0.499, p_cury = 0.499;
    bool p_has_cursor = false;

public:
    friend class Widget;
    friend class Projection;

    Root(): Widget() {
        this->p_root = this;
    }

    virtual ostd::Size get_type();

    int get_pixel_w(bool force_aspect = false) const;
    int get_pixel_h() const;

    float get_aspect(bool force = false) const;

    bool grabs_input() const {
        return loop_children_r([](const Widget *o) {
            return o->grabs_input();
        });
    }

    void adjust_children();

    void layout_dim() {
        p_x = p_y = 0;
        p_w = get_aspect(true);
        p_h = 1.0f;
    }

    void layout();

    void clip_push(float x, float y, float w, float h);

    void clip_pop();

    bool clip_is_fully_clipped(float x, float y, float w, float h);

    void clip_scissor();

    bool is_root() {
        return true;
    }

    void draw(float sx, float sy);
};

} } /* namespace octa::gui */

#endif