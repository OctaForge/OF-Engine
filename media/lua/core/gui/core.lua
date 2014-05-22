--[[!<
    A basic widget set. This module in particular implements the core of the
    whole system. All modules are documented, but not all methods in each
    widget are documented - only those of a significant meaning to the user
    are (as the other ones have no use for the user). It also manages the HUD.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local ffi = require("ffi")
local capi = require("capi")
local cs = require("core.engine.cubescript")
local math2 = require("core.lua.math")
local table2 = require("core.lua.table")
local signal = require("core.events.signal")
local logger = require("core.logger")
local Vec2 = require("core.lua.geom").Vec2

local gl_scissor_enable, gl_scissor_disable, gl_scissor, gl_blend_enable,
gl_blend_disable, gl_blend_func, gle_attrib2f, gle_color3f, gle_color4ub,
gle_attrib4ub, gle_defcolorub, gle_disable, hudmatrix_ortho, hudmatrix_reset,
shader_hud_set, hud_get_w, hud_get_h, hud_get_ss_x, hud_get_ss_y, hud_get_so_x,
hud_get_so_y, isconnected, text_get_res, text_font_get_h, aspect_get,
editing_get, console_scale_get, input_get_free_cursor, input_cursor_get_x,
input_cursor_get_y, input_cursor_exists_update in capi

local set_external = require("core.externals").set

local var_get, var_set = cs.var_get, cs.var_set

-- external locals
local max   = math.max
local min   = math.min
local clamp = math2.clamp
local floor = math.floor
local ceil  = math.ceil
local emit  = signal.emit
local pairs, ipairs = pairs, ipairs

local tremove = table.remove
local tinsert = table.insert

--! Module: core
local M = {}

local consts = require("core.gui.constants")

--[[! Enum: gl
    Forwarded from the "constants" module.
]]
M.gl = consts.gl
local gl = M.gl

--[[! Enum: key
    Forwarded from the "constants" module.
]]
M.key = consts.key
local key = M.key

--[[! Enum: mod
    Forwarded from the "constants" module.
]]
M.mod = consts.mod
local mod = M.mod

-- initialized after Root is created
local root, clicked, hovering, focused
local hover_x, hover_y, click_x, click_y = 0, 0, 0, 0
local clicked_code

local adjust = {:
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

    CLAMP_LEFT    = 1 << 4,
    CLAMP_RIGHT   = 1 << 5,
    CLAMP_TOP     = 1 << 6,
    CLAMP_BOTTOM  = 1 << 7,
:}
M.adjust = adjust

local wtypes_by_name = {}
local wtypes_by_type = {}

local lastwtype = 0

--[[!
    Registers a widget class.

    Arguments:
        - name - the widget class name.
        - base - the widget class base widget class (defaults to $Widget).
        - obj - the body with custom contents.
        - ftype - the "type" field, by default it just assigns is a new type.
]]
M.register_class = function(name, base, obj, ftype)
    if not ftype then
        lastwtype = lastwtype + 1
        ftype = lastwtype
    end
    base = base or wtypes_by_type[1]
    obj = obj or {}
    obj.type = ftype
    obj.name = name
    obj = base:clone(obj)
    wtypes_by_name[name] = obj
    wtypes_by_type[ftype] = obj
    return obj
end
local register_class = M.register_class

--[[!
    Given either a name or type, this function returns the widget class
    with that name or type.
]]
M.get_class = function(n)
    if type(n) == "string" then
        return wtypes_by_name[n]
    else
        return wtypes_by_type[n]
    end
end
local get_class = M.get_class

--[[!
    Loops widget children, executing the function given in the second
    argument with the child passed to it. If the widget has states,
    it first acts on the current state and then on the actual children
    from 1 to N. If the selected state is not available, it tries "default".

    See also $loop_children_r.
]]
M.loop_children = function(self, fun)
    local ch = self.children
    local vr = self.vstates
    local st = self.states

    local s = self:choose_state()
    if s != nil then
        local  w = st[s] or st["default"]
        if not w then w = vr[s] or vr["default"] end
        if w then
            local a, b = fun(w)
            if a != nil then return a, b end
        end
    end

    for i = 1, #vr do
        local a, b = fun(vr[i])
        if    a != nil then return a, b end
    end

    for i = 1, #ch do
        local a, b = fun(ch[i])
        if    a != nil then return a, b end
    end
end
local loop_children = M.loop_children

--[[!
    Loops widget children in reverse order, executing the function
    given in the second argument with the child passed to it. First
    goes over all children in reverse order and then if the widget
    has states, it acts on the current state. If the selected state
    is not available, it tries "default".

    See also $loop_children.
]]
M.loop_children_r = function(self, fun)
    local ch = self.children
    local vr = self.vstates
    local st = self.states

    for i = #ch, 1, -1 do
        local a, b = fun(ch[i])
        if    a != nil then return a, b end
    end

    for i = #vr, 1, -1 do
        local a, b = fun(vr[i])
        if    a != nil then return a, b end
    end

    local s = self:choose_state()
    if s != nil then
        local  w = st[s] or st["default"]
        if not w then w = vr[s] or vr["default"] end
        if w then
            local a, b = fun(w)
            if a != nil then return a, b end
        end
    end
end
local loop_children_r = M.loop_children_r

--[[!
    Similar to $loop_children, takes some extra assumptions - executes only
    for those children that cover the given coordinates. The function is
    executed, passing the computed coordinates alongside the object to
    the function. The computed coordinates represent position of a cursor
    within the object - "cx - o.x" and "cy - o.y" respectively (the ox, oy
    coords of 0, 0 represent the top-left corner).

    Arguments:
        - o - the widget.
        - cx, cy - the cursor x and y position.
        - fun - the function to execute.
        - ins - when not given, assumed true; when false, it executes the
          function for every child, even if the cursor is not inside the
          child.
        - useproj - false by default, when true, it tries to get the
          projection of every child and then multiplies cx, cy with
          projection values - useful when treating windows (we need
          proper scaling on these and thus also proper input).

    See also:
        - $loop_in_children_r
]]
M.loop_in_children = function(self, cx, cy, fun, ins, useproj)
    return loop_children(self, function(o)
        local ox, oy
        if useproj then
            local proj = o:get_projection()
            ox, oy = (cx * proj.pw - o.x), (cy * proj.ph - o.y)
        else
            ox, oy = cx - o.x, cy - o.y
        end
        if ins == false or (ox >= 0 and ox < o.w and oy >= 0 and oy < o.h) then
            local a, b = fun(o, ox, oy)
            if    a != nil then return a, b end
        end
    end)
end
local loop_in_children = M.loop_in_children

--[[!
    See $loop_in_children and $loop_children_r. This is equal to above,
    just using $loop_children_r instead.
]]
M.loop_in_children_r = function(self, cx, cy, fun, ins, useproj)
    return loop_children_r(self, function(o)
        local ox, oy
        if useproj then
            local proj = o:get_projection()
            ox, oy = (cx * proj.pw - o.x), (cy * proj.ph - o.y)
        else
            ox, oy = cx - o.x, cy - o.y
        end
        if ins == false or (ox >= 0 and ox < o.w and oy >= 0 and oy < o.h) then
            local a, b = fun(o, ox, oy)
            if    a != nil then return a, b end
        end
    end)
end
local loop_in_children_r = M.loop_in_children_r

ffi.cdef [[
    typedef struct clip_area_t {
        float x1, y1, x2, y2;
    } clip_area_t;
]]

local ffi_new = ffi.new

--[[!
    Represents a clip area defined by four points, x1, y1, x2, y2. The latter
    refer to x1+w and y1+h respectively.
]]
M.Clip_Area = ffi.metatype("clip_area_t", {
    __new = function(self, x, y, w, h)
        return ffi_new("clip_area_t", x, y, x + w, y + h)
    end,

    __index = {
        --[[!
            Intersects the clip area with another one. Writes into self.
        ]]
        intersect = function(self, c)
            self.x1 = max(self.x1, c.x1)
            self.y1 = max(self.y1, c.y1)
            self.x2 = max(self.x1, min(self.x2, c.x2))
            self.y2 = max(self.y1, min(self.y2, c.y2))
        end,

        --[[!
            Given x, y, w, h, checks if the area specified by the coordinates
            is fully clipped by the clip area.
        ]]
        is_fully_clipped = function(self, x, y, w, h)
            return self.x1 == self.x2 or self.y1 == self.y2 or x >= self.x2 or
                   y >= self.y2 or (x + w) <= self.x1 or (y + h) <= self.y1
        end,

        scissor = function(self, root)
            local sx1, sy1, sx2, sy2 = root:get_projection()
                :calc_scissor(self.x1, self.y1, self.x2, self.y2)
            gl_scissor(sx1, sy1, sx2 - sx1, sy2 - sy1)
        end
    }
})
local Clip_Area = M.Clip_Area

--[[!
    An utility function for drawing quads, takes x, y, w, h and optionally
    tx, ty, tw, th (defaulting to 0, 0, 1, 1).
]]
M.draw_quad = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    gle_attrib2f(x,     y)     gle_attrib2f(tx,      ty)
    gle_attrib2f(x + w, y)     gle_attrib2f(tx + tw, ty)
    gle_attrib2f(x + w, y + h) gle_attrib2f(tx + tw, ty + th)
    gle_attrib2f(x,     y + h) gle_attrib2f(tx,      ty + th)
end
local quad = M.draw_quad

--[[!
    An utility function for drawing quads, takes x, y, w, h and optionally
    tx, ty, tw, th (defaulting to 0, 0, 1, 1). Used with triangle strip.
]]
M.draw_quadtri = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    gle_attrib2f(x,     y)     gle_attrib2f(tx,      ty)
    gle_attrib2f(x + w, y)     gle_attrib2f(tx + tw, ty)
    gle_attrib2f(x,     y + h) gle_attrib2f(tx,      ty + th)
    gle_attrib2f(x + w, y + h) gle_attrib2f(tx + tw, ty + th)
end
local quadtri = M.draw_quadtri

local gen_setter = function(name)
    local sname = name .. "_changed"
    return function(self, val)
        self[name] = val
        emit(self, sname, val)
    end
end
M.gen_setter = gen_setter

--! Defines the possible orientations on widgets - HORIZONTAL and VERTICAL.
M.orient = {:
    HORIZONTAL = 0, VERTICAL = 1
:}
local orient = M.orient

local Projection = table2.Object:clone {
    __ctor = function(self, obj)
        self.obj = obj
        self.px, self.py, self.pw, self.ph = 0, 0, 0, 0
    end,

    calc = function(self)
        local aspect = hud_get_w() / hud_get_h()
        local obj = self.obj
        local ph = max(max(obj.h, obj.w / aspect), 1)
        local pw = aspect * ph
        self.px, self.py = 0, 0
        self.pw, self.ph = pw, ph
        return pw, ph
    end,

    adjust_layout = function(self)
        self.obj:adjust_layout(0, 0, self:calc())
    end,

    projection = function(self)
        local px, py, pw, ph in self
        hudmatrix_ortho(px, px + pw, py + ph, py, -1, 1)
        hudmatrix_reset()
        self.ss_x, self.ss_y = hud_get_ss_x(), hud_get_ss_y()
        self.so_x, self.so_y = hud_get_so_x(), hud_get_so_y()
    end,

    calc_scissor = function(self, x1, y1, x2, y2)
        local sscale  = Vec2(self.ss_x, self.ss_y)
        local soffset = Vec2(self.so_x, self.so_y)
        local s1 = Vec2(x1, y2):mul(sscale):add(soffset)
        local s2 = Vec2(x2, y1):mul(sscale):add(soffset)
        local hudw, hudh = hud_get_w(), hud_get_h()
        return clamp(floor(s1.x * hudw), 0, hudw),
               clamp(floor(s1.y * hudh), 0, hudh),
               clamp(ceil (s2.x * hudw), 0, hudw),
               clamp(ceil (s2.y * hudh), 0, hudh)
    end,

    draw = function(self, sx, sy)
        local root = self.obj:get_root()
        root:set_projection(self)
        self:projection()
        shader_hud_set()

        gl_blend_enable()
        gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        gle_color3f(1, 1, 1)

        local obj = self.obj
        obj:draw(sx or obj.x, sy or obj.y)

        gl_blend_disable()
        root:set_projection(nil)
    end,

    calc_above_hud = function(self)
        return 1 - (self.obj.y * self.ss_y + self.so_y)
    end
}

ffi.cdef [[
    typedef struct color_t {
        uchar r, g, b, a;
    } color_t;
]]

local color_ctors = {
    [0] = function(self) return ffi_new(self, 0xFF, 0xFF, 0xFF, 0xFF) end,
    [1] = function(self, c)
        c = c or 0xFFFFFFFF
        local a = c >> 24
        return ffi_new(self, (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF,
            (a == 0) and 0xFF or a)
    end,
    [2] = function(self, c, a)
        c = c or 0xFFFFFF
        return ffi_new(self, (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF,
            a or 0xFF)
    end,
    [3] = function(self, r, g, b)
        return ffi_new(self, r or 0xFF, g or 0xFF, b or 0xFF, 0xFF)
    end
}

local color_defctor = function(self, r, g, b, a)
    return ffi_new(self, r or 0xFF, g or 0xFF, b or 0xFF, a or 0xFF)
end

--[[!
    A color structure used for color attributes in all widgets that support
    them. Has fields r, g, b, a ranging from 0 to 255.
]]
M.Color = ffi.metatype("color_t", {
    --[[!
        Depending on the number of arguments, this initializes the color.

        With zero argments, everything is initialized to 0xFF (255). With
        one argument, the argument is treated as a hex color. That means
        you can specify it either as 0xRRGGBB or 0xAARRGGBB. If you use
        the former, the alpha defaults to 0xFF.

        With two arguments, the first argument is a hex color in 0xRRGGBB
        and the second argument is the alpha. With three or four arguments
        you're providing the r, g, b and possibly a values. If only three
        arguments are provided, the alpha defaults to 0xFF.

        Note that if you provide nil or false in place of any argument,
        it'll default all color channels it affects to 0xFF.

        The set_(r|g|b|a) methods emit the "(r|g|b|a)_changed" signals
        on this structure, passing the new value to the emit call.
    ]]
    __new = function(self, ...)
        local nargs = select("#", ...)
        return (color_ctors[nargs] or color_defctor)(self, ...)
    end,

    __index = {
        --! Sets the color (like glColor4f).
        init = function(self)
            gle_color4ub(self.r, self.g, self.b, self.a)
        end,

        --! Like above, but used as an attribute.
        attrib = function(self)
            gle_attrib4ub(self.r, self.g, self.b, self.a)
        end,

        --! Defines the color attribute as 4 unsigned bytes.
        def = function() gle_defcolorub(4) end,

        --! Function: set_r
        set_r = gen_setter "r",
        --! Function: set_g
        set_g = gen_setter "g",
        --! Function: set_b
        set_b = gen_setter "b",
        --! Function: set_a
        set_a = gen_setter "a"
    }
})

local Widget, Window

--[[!
    The basic widget class every other derives from. Provides everything
    needed for a working widget class, but doesn't do anything by itself.

    The widget has several basic properties described below.

    Properties are not made for direct setting from the outside environment.
    Those properties that are meant to be set have a setter method called
    set_PROPNAME. Unless documented otherwise, those functions emit the
    PROPNAME_changed signal with the given value passed to emit. Some
    properties that you don't set and are set from the internals also
    emit signals so you can handle extra events. That is typically documented.

    Several properties can be initialized via kwargs (align_h, align_v,
    clamp, clamp_h, clamp_v, clamp_l, clamp_r, clamp_b, clamp_t, floating,
    variant, states, signals, container and __init, which is a function called
    at the end of the constructor if it exists). Array members of kwargs are
    children.

    Left/right/top/bottom clamping is false by default. If the "clamp" value
    is defined and not false in kwargs, they all turn true.

    After that, the values "clamp_h" and "clamp_v" are checked - the former
    enables/disables left/right clamping, the latter enables/disables
    top/bottom clamping.

    After these are checked, the individual values "clamp_l", "clamp_r",
    "clamp_t", "clamp_b" are checked, turning on/off the individual directions.

    Widgets instances can have states - they're named references to widgets
    and are widget type specific. For example a button could have states
    "default" and "clicked", each being a reference to different
    appareance of a button depending on its state.

    For widget-global behavior, there are "variants". Variants are named.
    They store different kinds of states. For example variant "foo" could
    store specifically themed states and variant "bar" differently themed
    states.

    When selecting the current state of a widget instance, it first tries
    the "states" member (which is local to the widget instance). If such
    state is found, it's used. Otherwise the widget-global "__variants"
    table is tried, getting the variant self.variant (or "default" if none).

    Note that self.variant can also have the "false" value, in this case
    no variant is used at all (not even "default").

    Every variant can have a member "__properties" which is an array of
    extra properties specific to the variant. You can initialize them
    via kwargs just like all other properties and the appropriate
    setters are defined.

    There can also be "__init" on every variant which is a function that
    is called with self as an argument after initialization of the variant.

    Note that you can't override existing properties (as in, either self[name]
    or self["set_" .. name] exists) and if you set a different variant, all
    custom properties are discarded and replaced. Properties starting with an
    underscore are not allowed (reserved for private fields).

    The property "container" is a reference to another widget that is used
    as a target for appending/prepending/insertion and is fully optional.

    The property "tab_next" is a reference to another widget that is focused
    when the tab key is pressed while this widget is focused. Only works when
    the property is actually set to a valid widget reference.

    Each widget class also contains an "__instances" table storing a set
    of all instances of the widget class.

    Properties:
        - x, y, w, h - the widget dimensions.
        - adjust - the widget clamping and alignment as a set of bit flags.
        - children - an array of widget children.
        - floating - false by default, when true the widget is freely movable.
        - parent - the parent widget.
        - variant - the current widget variant.
        - variants, states - See above.
        - container - see above.
]]
M.Widget = register_class("Widget", table2.Object, {
    --[[!
        Builds a widget instance from scratch. The optional kwargs
        table contains properties that should be set on the resulting
        widget.
    ]]
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}

        local instances = rawget(self.__proto, "__instances")
        if not instances then
            instances = {}
            rawset(self.__proto, "__instances", instances)
        end
        instances[self] = self

        local variants = rawget(self.__proto, "__variants")
        if not variants then
            variants = {}
            rawset(self.__proto, "__variants", variants)
        end

        self.managed_objects = {}
        self.managed_properties = {}

        self.x, self.y, self.w, self.h = 0, 0, 0, 0

        self.adjust = adjust.ALIGN_CENTER

        -- alignment and clamping
        local align_h = kwargs.align_h or 0
        local align_v = kwargs.align_v or 0

        -- double negation turns the value into an equivalent boolean
        local cl = not not kwargs.clamp
        local clamp_l, clamp_r, clamp_b, clamp_t = cl, cl, cl, cl

        local clh, clv = kwargs.clamp_h, kwargs.clamp_v
        if clh != nil then clamp_l, clamp_r = not not clh, not not clh end
        if clv != nil then clamp_t, clamp_b = not not clv, not not clv end

        local cll, clr, clt, clb = kwargs.clamp_l, kwargs.clamp_r,
            kwargs.clamp_t, kwargs.clamp_b
        if cll != nil then clamp_l = not not cll end
        if clr != nil then clamp_r = not not clr end
        if clt != nil then clamp_t = not not clt end
        if clb != nil then clamp_b = not not clb end

        self.floating = kwargs.floating or false
        self.visible  = (kwargs.visible != false) and true or false

        self:align(align_h, align_v)
        self:clamp(clamp_l, clamp_r, clamp_b, clamp_t)

        if kwargs.signals then
            for k, v in pairs(kwargs.signals) do
                signal.connect(self, k, v)
            end
        end

        self.init_clone = kwargs.init_clone

        -- extra kwargs
        local variant = kwargs.variant
        if variant != false then
            local dstates = variants[variant or "default"]
            local props = dstates and dstates.__properties or nil
            if props then for i, v in ipairs(props) do
                assert(v:sub(1, 1) != "_", "invalid property " .. v)
                assert(not self["set_" .. v] and self[v] == nil,
                    "cannot override existing property " .. v)
                self[v] = kwargs[v]
            end end
        end

        -- disable asserts, already checked above
        self:set_variant(variant, true)

        -- prepare for children
        local ch, states
        local cont = self.container
        if cont then
            ch, states = cont.children, cont.states
        else
            cont = self
            ch, states = {}, {}
            self.children, self.states = ch, states
        end
        local clen = #ch

        -- children
        for i, v in ipairs(kwargs) do
            ch[clen + i] = v
            v.parent = cont
            v._root  = cont._root
        end
        self.children = ch

        -- states
        local ks = kwargs.states
        if ks then for k, v in pairs(ks) do
            states[k] = v
            v.parent = cont
            v._root  = cont._root
        end end
        self.states = states

        -- and init
        if  kwargs.__init then
            kwargs.__init(self)
        end
    end,

    --[[!
        Clears a widget including its children recursively. Calls the
        "destroy" signal. Removes itself from its widget class' instances
        set. Does nothing if already cleared.
    ]]
    clear = function(self)
        if self._cleared then return end
        self:clear_focus()

        local children = self.children
        for k, v in ipairs(children) do v:clear() end
        local states = self.states
        for k, v in pairs(states) do v:clear() end
        local vstates = self.vstates
        for k, v in pairs(vstates) do v:clear() end
        local mobjs = self.managed_objects
        for k, v in pairs(mobjs) do v:clear() end
        self.container = nil

        emit(self, "destroy")
        local insts = rawget(self.__proto, "__instances")
        if insts then
            insts[self] = nil
        end

        self._cleared = true
    end,

    --[[!
        Creates a deep clone of the widget, that is, where each child
        is again a clone of the original child, down the tree. Useful
        for default widget class states, where we need to clone
        these per-instance.
    ]]
    deep_clone = function(self, obj, initc)
        local ch, rch = {}, self.children
        local st, rst = {}, self.states
        local vs, rvs = {}, self.vstates
        local ic = initc and self.init_clone or nil
        local cl = self:clone { children = ch, states = st, vstates = vs }
        for i = 1, #rch do
            local c = rch[i]
            local chcl = c:deep_clone(obj, true)
            chcl.parent = cl
            chcl._root  = cl._root
            ch[i] = chcl
        end
        for k, v in pairs(rst) do
            local vcl = v:deep_clone(obj, true)
            vcl.parent = cl
            vcl._root  = cl._root
            st[k] = vcl
        end
        for k, v in pairs(rvs) do
            local vcl = v:deep_clone(obj, true)
            vcl.parent = cl
            vcl._root  = cl._root
            vs[k] = vcl
        end
        if ic then ic(cl, obj) end
        return cl
    end,

    --[[!
        Sets the variant this widget instance uses. If not provided, "default"
        is set implicitly.
    ]]
    set_variant = function(self, variant, disable_asserts)
        self.variant = variant
        local old_vstates = self.vstates
        if old_vstates then for k, v in pairs(old_vstates) do
            v:clear()
        end end
        local manprops = self.managed_properties
        for i = #manprops, 1, -1 do
            self[manprops[i]], manprops[i] = nil, nil
        end
        local vstates = {}
        self.vstates = vstates
        if variant == false then return nil end
        local variants = rawget(self.__proto, "__variants")
        local dstates = variants[variant or "default"]
        if dstates then
            local notvariants = {
                ["__properties"] = true, ["__init"] = true
            }
            for k, v in pairs(dstates) do
                if notvariants[k] then continue end
                local ic = v.init_clone
                local cl = v:deep_clone(self)
                vstates[k] = cl
                cl.parent = self
                cl._root  = self._root
                if ic then ic(cl, self) end
            end
            local props = dstates.__properties
            if props then for i, v in ipairs(props) do
                local nm = "set_" .. v
                if not disable_asserts then
                    assert(v:sub(1, 1) != "_", "invalid property " .. v)
                    assert(not self[nm] and self[v] == nil,
                        "cannot override existing property " .. v)
                end
                self[nm] = gen_setter(v)
                manprops[#manprops + 1] = nm
            end end
            local init = dstates.__init
            if init then init(self) end
        end
        local cont = self.container
        if cont and cont._cleared then self.container = nil end
    end,

    --[[!
        Call on the widget class. Updates the state widget on the widget class
        and every instance of it. Destroys the old state of that name (if any)
        on the class and on every instance. If the instance already uses a
        different state (custom), it's left alone.

        Using this you can update the look of all widgets of certain type
        with ease.

        See also $state_changed.

        Arguments:
            - sname - the state name.
            - sval - the state widget.
            - variant - optional (defaults to "default").
    ]]
    update_class_state = function(self, sname, sval, variant)
        variant = variant or "default"
        local dstates = rawget(self, "__variants")
        if not dstates then
            dstates = {}
            rawset(self, "__variants", dstates)
        end
        local variant = dstates[variant]
        if not variant then
            variant = {}
            dstates[variant] = variant
        end
        local oldstate = variant[sname]
        variant[sname] = sval
        oldstate:clear()

        local insts = rawget(self, "__instances")
        if insts then for v in pairs(insts) do
            local sts = v.vstates
            if v.variant == variant then
                local st = sts[sname]
                -- update only on widgets actually using the default state
                if st and st.__proto == oldstate then
                    local ic = sval.init_clone
                    local nst = sval:deep_clone(v)
                    nst.parent = v
                    nst._root  = v._root
                    sts[sname] = nst
                    st:clear()
                    if ic then ic(nst, v) end
                    v:state_changed(sname, nst)
                end
            end
            local cont = v.container
            if cont and cont._cleared then v.container = nil end
        end end
    end,

    --[[!
        Given an associative array of states (and optionally variant), it
        calls $update_class_state for each.
    ]]
    update_class_states = function(self, states, variant)
        for k, v in pairs(states) do
            self:update_class_state(k, v, variant)
        end
    end,

    --[[!
        Given the state name an a widget, this sets the state of that name
        for the individual widget (unlike $update_class_state). That is
        useful when you need widgets with custom appearance but you don't
        want all widgets to have it. This function destroys the old state
        if any.

        See also $state_changed.
    ]]
    update_state = function(self, state, obj)
        local states = self.states
        local ostate = states[state]
        if ostate then ostate:clear() end
        states[state] = obj
        obj.parent = self
        obj._root  = self._root
        local cont = self.container
        if cont and cont._cleared then self.container = nil end
        self:state_changed(state, obj)
        return obj
    end,

    --! Given an associative array of states, it calls $update_state for each.
    update_states = function(self, states)
        for k, v in pairs(states) do
            self:update_state(k, v)
        end
    end,

    --[[!
        Called with the state name and the state widget everytime
        $update_state or $update_class_state updates a widget's state.
        Useful for widget class and instance specific things such as updating
        labels on buttons. By default does nothing.
    ]]
    state_changed = function(self, sname, obj)
    end,

    --[[!
        Returns the state that should be currently used. By default
        returns nil.
    ]]
    choose_state = function(self) return nil end,

    --[[!
        Takes care of widget positioning and sizing. By default calls
        recursively.
    ]]
    layout = function(self)
        self.w = 0
        self.h = 0

        loop_children(self, function(o)
            if not o.floating then o.x, o.y = 0, 0 end
            o:layout()
            self.w = max(self.w, o.x + o.w)
            self.h = max(self.h, o.y + o.h)
        end)
    end,

    --[[!
        Adjusts layout of children widgets. Takes additional optional
        parameters px (0), py (0), pw (self.w), ph (self.h). Basically
        calls $adjust_layout on each child with those parameters.
    ]]
    adjust_children = function(self, px, py, pw, ph)
        px, py, pw, ph = px or 0, py or 0, pw or self.w, ph or self.h
        loop_children(self, function(o) o:adjust_layout(px, py, pw, ph) end)
    end,

    --[[!
        Layout adjustment hook for self. Adjusts x, y, w, h of the widget
        according to its alignment and clamping. When everything is done,
        calls $adjust_children with no parameters.
    ]]
    adjust_layout = function(self, px, py, pw, ph)
        local x, y, w, h, a = self.x, self.y,
            self.w, self.h, self.adjust

        local adj = a & adjust.ALIGN_HMASK

        if adj == adjust.ALIGN_LEFT then
            x = px
        elseif adj == adjust.ALIGN_HCENTER then
            x = px + (pw - w) / 2
        elseif adj == adjust.ALIGN_RIGHT then
            x = px + pw - w
        end

        adj = a & adjust.ALIGN_VMASK

        if adj == adjust.ALIGN_TOP then
            y = py
        elseif adj == adjust.ALIGN_VCENTER then
            y = py + (ph - h) / 2
        elseif adj == adjust.ALIGN_BOTTOM then
            y = py + ph - h
        end

        if (a & adjust.CLAMP_MASK) != 0 then
            if (a & adjust.CLAMP_LEFT ) != 0 then x = px end
            if (a & adjust.CLAMP_RIGHT) != 0 then
                w = px + pw - x
            end

            if (a & adjust.CLAMP_TOP   ) != 0 then y = py end
            if (a & adjust.CLAMP_BOTTOM) != 0 then
                h = py + ph - y
            end
        end

        self.x, self.y, self.w, self.h = x, y, w, h
        self:adjust_children()
    end,

    --[[!
        Given the cursor coordinates, this function should return the
        targeted widget. Returns nil if there is nothing or nothing
        targetable. By default this just loops the children in reverse
        order, calls target on each and returns the result of the first
        target call that actually returns something.
    ]]
    target = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c = o.visible and o:target(ox, oy) or nil
            if c then return c end
        end)
    end,

    --[[!
        Called on keypress.  By default it doesn't define any behavior so it
        just loops children in reverse order and returns true if any key calls
        on the children return true or false if they don't. It also handles
        tab-cycling behavior when the tab_next field is defined.

        Arguments:
            - code - the keycode pressed.
            - isdown - true if it was pressed, false if it was released.

        See also:
            - $key_raw
            - $key_hover
            - $text_input
    ]]
    key = function(self, code, isdown)
        local tn = self.tab_next
        if tn and code == key.TAB and self:is_focused() then
            if isdown then tn:set_focused(true) end
            return true
        end
        return loop_children_r(self, function(o)
            if o.visible and o:key(code, isdown) then return true end
        end) or false
    end,

    --[[!
        A "raw" key handler that is used in the very beginning of the keypress
        handler. By default, it iterates the children (backwards), tries
        key_raw on each and if that returns true, it returns true too,
        otherwise it goes on (if nothing returned true, it returns false).
        If this returns false, the keypress handler continues normally.

        See also:
            - $key
            - $key_hover
            - $text_input
    ]]
    key_raw = function(self, code, isdown)
        return loop_children_r(self, function(o)
            if o.visible and o:key_raw(code, isdown) then return true end
        end) or false
    end,

    --[[!
        Called on text input on the widget. Returns true of the input was
        accepted and false otherwise. The default version loops children
        (backwards) and tries on each until it hits true.

        See also:
            - $key
            - $key_raw
            - $key_hover
    ]]
    text_input = function(self, str)
        return loop_children_r(self, function(o)
            if o.visible and o:text_input(str) then return true end
        end) or false
    end,

    --[[!
        Occurs on keypress (any key) when hovering over a widget. The default
        just tries to key_hover on its parent (returns false as a fallback).
        Called after $key_raw (if possible) and before mouse clicks and
        root $key.

        See also:
            - $key
            - $key_raw
            - $key_hover
    ]]
    key_hover = function(self, code, isdown)
        local parent = self.parent
        if parent then
            return parent:key_hover(code, isdown)
        end
        return false
    end,

    --[[!
        Called in the drawing phase. By default just loops all the children
        and draws on these (assuming they're not fully clipped).

        Arguments:
            - sx, sy - the left and upper side coordinates of the widget,
              optional (if not present, they default to "x" and "y" properties
              of the current widget).
    ]]
    draw = function(self, sx, sy)
        sx = sx or self.x
        sy = sy or self.y
        local root = self:get_root()

        loop_children(self, function(o)
            local ox = o.x
            local oy = o.y
            local ow = o.w
            local oh = o.h
            if not root:clip_is_fully_clipped(sx + ox, sy + oy, ow, oh)
            and o.visible then
                o:draw(sx + ox, sy + oy)
            end
        end)
    end,

    --[[!
        Given the cursor coordinates, this function returns the widget
        currently hovered on. By default it just loops children in
        reverse order using $loop_in_children_r and calls hover recursively
        on each (and returns the one that first returns a non-nil value).
        If the hover call returns itself, it means we're hovering on the
        widget the method was called on and the current hover coords
        are set up appropriately.

        See also:
            - $click
    ]]
    hover = function(self, cx, cy)
        local isw = (self == root)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o.visible and o:hover(ox, oy) or nil
            if    c == o then
                hover_x = ox
                hover_y = oy
            end
            if isw or c then return c end
        end, true, isw)
    end,

    --[[!
        Called every frame on the widget that's being hovered on (assuming
        it exists). It takes the coordinates we're hovering on. By default
        it emits the "hovering" signal on itself, passing the coordinates
        to it.

        See also:
             - $leaving
             - $holding
    ]]
    hovering = function(self, cx, cy)
        emit(self, "hovering", cx, cy)
    end,

    --[[!
        Called when a mouse cursor is leaving widget hover. Takes the cx
        and cy arguments like $hovering (they're the last position in the
        widget the cursor was hovering on) and emits the "leaving" signal,
        passing those arguments to it.
    ]]
    leaving = function(self, cx, cy)
        emit(self, "leaving", cx, cy)
    end,

    hold = function(self, cx, cy, obj)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            if o == obj then return ox, oy end
            if o.visible then return o:hold(ox, oy, obj) end
        end, false, self == root)
    end,

    --[[!
        See $hovering. It's the same, but called only when the widget
        is being held.
    ]]
    holding = function(self, cx, cy, code)
        emit(self, "holding", cx, cy, code)
    end,

    --[[!
        See $hover. It's identical, only for the click event. This also
        takes the currently clicked mouse button as the last argument.
    ]]
    click = function(self, cx, cy, code)
        local isw = (self == root)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o.visible and o:click(ox, oy, code) or nil
            if    c == o then
                click_x = ox
                click_y = oy
            end
            if isw or c then return c end
        end, true, isw)
    end,

    --[[!
        Called once on the widget that was clicked. By emits the "clicked"
        signal on itself. Takes the click coords as arguments and passes
        them to the signal. Also takes the clicked mouse button code
        and passes it as well.

        See also:
            - $released
    ]]
    clicked = function(self, cx, cy, code)
        emit(self, "clicked", cx, cy, code)
    end,

    --[[!
        See $clicked. Emits the "released" signal with the same arguments
        as the "clicked" signal above. The coordinates are calculated by
        the time of button release, so they're up to date.
    ]]
    released = function(self, cx, cy, code)
        emit(self, "released", cx, cy, code)
    end,

    --[[!
        Returns true if the widget takes input in regular cursor mode. That
        is the default behavior. However, that is not always convenient as
        sometimes you want on-screen widgets that take input in free cursor
        mode only.
    ]]
    grabs_input = function(self) return true end,

    --[[!
        Finds a child widget.

        Arguments:
            - otype - the child type to find.
            - name - if the widget is named, this is taken into consideration.
            - recurse - if true (true by default), this will search recursively
              in children of the children.
            - exclude - a reference to a widget that should be excluded, this
              is optional. Note that this is never passed in recursively.

        See also:
            - $find_children
            - $find_sibling
    ]]
    find_child = function(self, otype, name, recurse, exclude)
        recurse = (recurse == nil) and true or recurse
        local o = loop_children(self, function(o)
            if o != exclude and o.type == otype and
            (not name or name == o.obj_name) then
                return o
            end
        end)
        if o then return o end
        if recurse then
            o = loop_children(self, function(o)
                if o != exclude then
                    local found = o:find_child(otype, name)
                    if    found != nil then return found end
                end
            end)
        end
        return o
    end,

    --[[!
        See $find_child. Takes an extra argument (optional) which is an
        array. Unlike the above, this finds all possible matches and appends
        them to the given array (if not given, a new array is created). This
        returns the array. If the array is given and not empty, it's not
        erased (all matches append).
    ]]
    find_children = function(self, otype, name, recurse, exclude, ret)
        local ch = ret or {}
        recurse = (recurse == nil) and true or recurse
        loop_children(self, function(o)
            if o != exclude and o.type == otype and
            (not name or name == o.obj_name) then
                ch[#ch + 1] = o
            end
        end)
        if recurse then
            loop_children(self, function(o)
                if o != exclude then
                    o:find_child(otype, name, true, nil, ch)
                end
            end)
        end
        return ch
    end,

    --[[!
        Finds a sibling of a widget. A sibling is basically defined as any
        child of the parent widget that isn't self (searched recursively),
        then any child of the parent widget of that parent widget and so on.

        Arguments:
            - otype - the sibling type.
            - name - the sibling name (if named).

        See also:
            - $find_siblings
            - $find_child
    ]]
    find_sibling = function(self, otype, name)
        local prev = self
        local cur  = self.parent

        while cur do
            local o = cur:find_child(otype, name, true, prev)
            if    o then return o end

            prev = cur
            cur  = cur.parent
        end
    end,

    --! See $find_sibling. Equivalent to $find_children.
    find_siblings = function(self, otype, name, ret)
        local ch   = ret or {}
        local prev = self
        local cur  = self.parent

        while cur do
            cur:find_children(otype, name, true, prev, ch)
            prev = cur
            cur  = cur.parent
        end
        return ch
    end,

    --[[!
        Replaces a widget that has been tagged (inside a tag, the tag itself
        persists).

        Arguments:
            - tname - the tag name (name of a $Tag instance).
            - obj - the widget to replace the original with.
            - fun - optionally a function called at the end with "obj"
              as an argument.

        Returns:
            True if the replacement was successful, false otherwise.
    ]]
    replace = function(self, tname, obj, fun)
        local tag = self:find_child(Tag.type, tname)
        if not tag then return false end
        tag:destroy_children()
        tag:append(obj)
        if fun then fun(obj) end
        return true
    end,

    --[[!
        Removes the given widget from the widget's children. Alternatively,
        the argument can be the index of the child in the list. Returns true
        on success and false on failure.

        If the last argument "detach" is true, this doesn't clear the widget
        and instead of returning true or false, it returns the widget or nil.
    ]]
    remove = function(self, o, detach)
        if type(o) == "number" then
            if #self.children < o then
                if detach then return nil end
                return false
            end
            local r = tremove(self.children, o)
            if detach then return r end
            r:clear()
            return true
        end
        for i = 1, #self.children do
            if o == self.children[i] then
                local r = tremove(self.children, i)
                if detach then return r end
                r:clear()
                return true
            end
        end
        if detach then return nil end
        return false
    end,

    --! Removes itself from its parent using $remove.
    destroy = function(self)
        self.parent:remove(self)
    end,

    --! Detaches itself from its parent using $remove.
    detach = function(self)
        self.parent:remove(self, true)
    end,

    --[[!
        Destroys all the children using regular $clear. Emits a signal
        "children_destroy" afterwards on self.
    ]]
    destroy_children = function(self)
        local ch = self.children
        for i = 1, #ch do
            ch[i]:clear()
        end
        self.children = {}
        emit(self, "children_destroy")
    end,

    --[[!
        Aligns the widget given the horizontal alignment and the vertical
        alignment. Those can be -1 (top, left), 0 (center) and 1 (bottom,
        right).
    ]]
    align = function(self, h, v)
        self.adjust = (self.adjust & ~adjust.ALIGN_MASK)
            | ((clamp(h, -1, 1) + 2) << adjust.ALIGN_HSHIFT)
            | ((clamp(v, -1, 1) + 2) << adjust.ALIGN_VSHIFT)
    end,

    --[[!
        Sets the widget clamping, given the left, right, top and bottom
        clamping. The values can be either true or false.
    ]]
    clamp = function(self, l, r, t, b)
        self.adjust = (self.adjust & ~adjust.CLAMP_MASK)
            | (l and adjust.CLAMP_LEFT   or 0)
            | (r and adjust.CLAMP_RIGHT  or 0)
            | (t and adjust.CLAMP_TOP    or 0)
            | (b and adjust.CLAMP_BOTTOM or 0)
    end,

    --[[! Function: get_alignment
        Returns the horizontal and vertical alignment of the widget in
        the same format as $align arguments.

        See also:
            - $align
            - $get_clamping
    ]]
    get_alignment = function(self)
        local a   = self.adjust
        local adj = a & adjust.ALIGN_HMASK
        local hal = (adj == adjust.ALIGN_LEFT) and -1 or
            (adj == adjust.ALIGN_HCENTER and 0 or 1)

        adj = a & adjust.ALIGN_VMASK
        local val = (adj == adjust.ALIGN_BOTTOM) and 1 or
            (adj == adjust.ALIGN_VCENTER and 0 or -1)

        return hal, val
    end,

    --[[!
        Returns the left, right, bottom, top clamping as either true or false.

        See also:
            - $clamp
            - $get_alignment
    ]]
    get_clamping = function(self)
        local a   = self.adjust
        local adj = a & adjust.CLAMP_MASK
        if    adj == 0 then
            return 0, 0, 0, 0
        end

        return (a & adjust.CLAMP_LEFT  ) != 0, (a & adjust.CLAMP_RIGHT) != 0,
               (a & adjust.CLAMP_BOTTOM) != 0, (a & adjust.CLAMP_TOP  ) != 0
    end,

    --! Function: set_floating
    set_floating = gen_setter "floating",

    --! Function: set_visible
    set_visible = gen_setter "visible",

    --! Function: set_container
    set_container = function(self, val)
        if self.container then self.container.parent = nil end
        self.container = val
        if val then val.parent = self end
        emit(self, "container_changed", val)
    end,

    --! Function: set_init_clone
    set_init_clone = gen_setter "init_clone",

    --! Function: set_tab_next
    set_tab_next = gen_setter "tab_next",

    --[[! Function: insert
        Inserts a widget at the given position in the widget's children.

        Arguments:
            - pos - the position.
            - obj - the widget object.
            - fun - optional function called with "obj" as an argument after
              it has been inserted.
            - force_ch - forces insertion into "real" children even with the
              widget "container" property set.

        Returns:
            The given widget.

        See also:
            - $append
            - $prepend
    ]]
    insert = function(self, pos, obj, fun, force_ch)
        local children = force_ch and self.children
            or (self.container or self).children
        tinsert(children, pos, obj)
        obj.parent = self
        obj._root  = self._root
        if fun then fun(obj) end
        return obj
    end,

    --[[! Function: append
        Like $insert, but appends to the end of the children list.
    ]]
    append = function(self, obj, fun, force_ch)
        local children = force_ch and self.children
            or (self.container or self).children
        children[#children + 1] = obj
        obj.parent = self
        obj._root  = self._root
        if fun then fun(obj) end
        return obj
    end,

    --[[! Function: prepend
        Like $insert, but prepends (inserts to the beginning of the list).
    ]]
    prepend = function(self, obj, fun, force_ch)
        local children = force_ch and self.children
            or (self.container or self).children
        tinsert(children, 1, obj)
        obj.parent = self
        obj._root  = self._root
        if fun then fun(obj) end
        return obj
    end,

    --[[!
        Given a menu object (any widget), this shows the menu with this widget
        as the parent.

        As for on-hover menus - you need to show your on-hover menu every time
        the "hovering" signal is activated, because it gets dropped next frame.

        Note that the this widget becomes the menu's parent, thus this widget
        becomes responsible for it (if it gets destroyed, it destroys the
        menu as well), that is, unless the menu changes parent in the meantime.

        Arguments:
            - obj - the menu object.
            - at_cursor - instead of using special positioning for menus
              and submenus, this shows the menu at cursor position.
            - clear_on_drop - clears the menu when dropped if true, the
              default behavior is that the menu remains alive until its parent
              is destroyed. If you can avoid using this, please do so, as
              it's more expensive. For example when creating on-hover menus,
              instead of setting the argument to true and creating a new widget
              every call of "hovering", create a permanent reference to the
              menu elsewhere instead.
    ]]
    show_menu = function(self, obj, at_cursor, clear_on_drop)
        local root = self:get_root()
        root:_menu_init(obj, self, #root._menu_stack + 1, at_cursor,
            clear_on_drop)
        return obj
    end,

    --[[!
        Returns this widget's menu assuming it has one.
    ]]
    get_menu = function(self) return self._menu end,

    --[[!
        Given a tooltip object (any widget), this shows the tooltip with this
        widget as the parent. The same precautions as for $show_menu apply.
        There is no at_cursor argument (because that's how it behaves by
        default).

        You typically want to call this in the "hovering" signal of a widget.
        Make sure to actually create the tooltip object beforehand, somewhere
        where it's done just once (for example in the user constructor).
        Alternatively, you can pass clear_on_drop as true and create it
        everytime, but that's not recommended.

        Arguments:
            - obj - the tooltip object.
            - clear_on_drop - see $show_menu.

        See also:
            - $show_menu
    ]]
    show_tooltip = function(self, obj, clear_on_drop)
        self:get_root():_tooltip_init(obj, self, clear_on_drop)
        return obj
    end,

    --[[! Function: is_field
        Returns true if this widget is a textual field, by default false.
    ]]
    is_field = function() return false end,

    --[[!
        Returns the parent of this widget (or nil if no parent).
        This is just a plain hash table read, no complex retrieval.
    ]]
    get_parent = function(self)
        return self.parent
    end,

    --[[!
        Returns the root window of this widget. Note that this might do a more
        complex retrieval if root is unassigned and might modify parents (if
        it has to ask parents for root and they don't have it, it uses a
        recursive approach).
    ]]
    get_root = function(self)
        local  rt = self._root
        if not rt then
            -- a recursive approach makes sure parents will
            -- have their roots assigned (for later use - faster)
            local par = self:get_parent()
            if par then
                rt = par:get_root()
                self._root = rt
                return rt
            end
        end
        return rt
    end,

    --[[!
        Clears any kind of focus for this widget.
    ]]
    clear_focus = function(self)
        if self == clicked  then clicked  = nil end
        if self == hovering then hovering = nil end
        if self == focused  then focused  = nil end
    end,

    --[[!
        If the button code is given, this returns true or false depending on
        whether the current widget is clicked in its root and was clicked
        using the given button; otherwise, returns the code of the button
        that it was clicked with if it's clicked, or false if it's not
        clicked at all.
    ]]
    is_clicked = function(self, btn)
        if btn then
            return (self == clicked) and (btn == clicked_code)
        elseif self == clicked then
            return clicked_code
        else
            return false
        end
    end,

    --[[!
        Returns true or false depending on whether the widget is being
        hovered on in its root.
    ]]
    is_hovering = function(self) return self == hovering end,

    --[[!
        If the given parameter is true, this widget gets the focus within
        the root.
    ]]
    set_focused = function(self, foc)
        if foc then focused = self end
    end,

    --[[!
        Returns true or false depending on whether the widget is focused
        in its root.
    ]]
    is_focused = function(self)
        return self == focused
    end,

    --[[!
        Returns false, as normal widgets are not roots.
    ]]
    is_root = function(self)
        return false
    end,

    --[[!
        Gets the widget's projection. If it doesn't exist it tries to create
        a new one unless the parameter is true. Returns the projection or
        nil.
    ]]
    get_projection = function(self, nonew)
        local proj = self._projection
        if proj or nonew then return proj end
        proj = Projection(self)
        self._projection = proj
        return proj
    end,

    --[[!
        Sets the widget's projection to some forced value. Returns the
        projection.
    ]]
    set_projection = function(self, proj)
        self._projection = proj
        return proj
    end
})
Widget = M.Widget

--[[!
    Named widgets are regular widgets thave have a name that is specific
    to instance.

    Properties:
        - obj_name - can be passed in kwargs as "name".
]]
M.Named_Widget = register_class("Named_Widget", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.obj_name = kwargs.name
        return Widget.__ctor(self, kwargs)
    end,

    --! Function: set_obj_name
    set_obj_name = gen_setter "obj_name"
})
local Named_Widget = M.Named_Widget

--[[!
    Tags are special named widgets. They can contain more widgets. They're
    particularly useful when looking up certain part of a GUI structure or
    replacing something inside without having to iterate through and finding
    it manually.
]]
M.Tag = register_class("Tag", Named_Widget)
local Tag = M.Tag

--[[!
    This is a regular window. It's nothing more than a special case of named
    widget. You can derive custom window types from this (see $Overlay) but
    you have to make sure the widget type stays the same (pass Window.type
    as the last argument to $register_class).

    Properties:
        - input_grab - true by default, specifies whether this window grabs
          input. If it's false, the window takes input only in free cursor
          mode.
]]
M.Window = register_class("Window", Named_Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        local ig = kwargs.input_grab
        self.input_grab = ig == nil and true or ig
        self.above_hud = kwargs.above_hud or false
        return Named_Widget.__ctor(self, kwargs)
    end,

    --! Equivalent to win.parent:hide_window(win.obj_name).
    hide = function(self)
        return self.parent:hide_window(self.obj_name)
    end,

    grabs_input = function(self) return self.input_grab end,

    --! Function: set_input_grab
    set_input_grab = gen_setter "input_grab",

    --! Function: set_above_hud
    set_above_hud = gen_setter "above_hud"
})
Window = M.Window

--[[!
    Overlays are windows that take no input under no circumstances. There is no
    difference otherwise. This overloads {{$Widget.grabs_input}} (returns
    false), {{$Widget.target}} (returns nil), {{$Widget.hover}} (returns nil)
    and {{$Widget.click}} (returns nil).

    There is one default overlay - the HUD. You can retrieve it using $get_hud.
    Its layout is managed separately, it takes root's dimensions. You can
    freely append into it. It gets cleared everytime you leave the map and it
    doesn't display when mainmenu is active.
]]
M.Overlay = register_class("Overlay", Window, {
    grabs_input = function(self) return false end,

    target = function() end,
    hover  = function() end,
    click  = function() end
}, Window.type)
local Overlay = M.Overlay

--[[!
    A root is a structure that derives from $Widget and holds windows.
    It defines the base for calculating dimensions of child widgets as
    well as input hooks. It also provides some window management functions.
    By default the system creates one default root that holds all the
    primary windows. In the future it will be possible to create new
    roots for different purposes (e.g. in-game GUI on a surface) but
    that is not supported at this point.
]]
M.Root = register_class("Root", Widget, {
    __ctor = function(self)
        self.windows     = {}
        self.cursor_x    = 0.499
        self.cursor_y    = 0.499
        self.has_cursor  = false
        self._root       = self
        self._clip_stack = {}
        self._menu_stack = {}
        self._menu_nhov  = nil
        self._tooltip    = nil
        return Widget.__ctor(self)
    end,

    --[[!
        This custom overload of {{$Widget.grabs_input}} loops children
        (in reverse order) and calls grabs_input on each. If any of them
        returns true, this also returns true, otherwise it returns false.
    ]]
    grabs_input = function(self)
        return loop_children_r(self, function(o)
            if o:grabs_input() then return true end
        end) or false
    end,

    adjust_children = function(self)
        loop_children(self, function(o)
            local proj = self:set_projection(o:get_projection())
            proj:adjust_layout()
            self:set_projection(nil)
        end)
    end,

    layout_dim = function(self)
        local sw, sh = hud_get_w(), hud_get_h()
        local faspect = aspect_get()
        if faspect != 0 then sw = ceil(sh * faspect) end
        self.x, self.y = 0, 0
        self.w, self.h = sw / sh, 1
    end,

    --[[!
        Overloads {{$Widget.layout}}. Calculates proper root dimensions
        (takes forced aspect set using an engine variable forceaspect into
        account), then layouts every child (using correct projection separate
        for every window) and then adjusts children.
    ]]
    layout = function(self)
        self:layout_dim()

        loop_children(self, function(o)
            if not o.floating then o.x, o.y = 0, 0 end
            self:set_projection(o:get_projection())
            o:layout()
            self:set_projection(nil)
        end)

        self:adjust_children()
    end,

    draw = function(self, sx, sy)
        sx = sx or self.x
        sy = sy or self.y

        loop_children(self, function(o)
            local ox = o.x
            local oy = o.y
            local ow = o.w
            local oh = o.h
            if not self:clip_is_fully_clipped(sx + ox, sy + oy, ow, oh)
            and o.visible then
                o:get_projection():draw(sx + ox, sy + oy)
            end
        end)
    end,

    build_window = function(self, name, win, fun)
        local old = self:find_child(Window.type, name, false)
        if old then self:remove(old) end
        win = win { name = name }
        win.parent = self
        win._root  = self._root
        local children = self.children
        children[#children + 1] = win
        if fun then fun(win) end
        return win
    end,

    --[[!
        Creates a window, but doesn't show it. At the time of creation the
        structure is not built, it merely creates a callback that it stores.
        The window is actually built when shown, and destroyed when hidden.

        If there already is a window of that name, it returns the old build
        hook. You can call it with no arguments to show the window. If you
        pass true as the sole argument, it returns whether the window is
        currently visible. If you pass false to it, it marks the window
        as invisible/destroyed (without actually hiding anything, unlike
        <hide_window> which destroys it AND marks it). Don't actually rely
        on this, it's only intended for the internals.

        Arguments:
            - name - the window name.
            - win - the window object type (for example $Window or $Overlay).
            - fun - the function to call after the window has been built
              (with the window as an argument).
    ]]
    new_window = function(self, name, win, fun)
        local old = self.windows[name]
        local visible = false
        self.windows[name] = function(vis)
            if vis == true then
                return visible
            elseif vis == false then
                visible = false
                return nil
            end
            self:build_window(name, win, fun)
            visible = true
        end
        return old
    end,

    --[[!
        Triggers a window build. The window has to exist, if it doesn't,
        this just returns true. Otherwise builds the window and returns
        true.
    ]]
    show_window = function(self, name)
        local  g = self.windows[name]
        if not g then return false end
        g()
        return true
    end,

    --! Returns the window build hook (the same one $show_window calls).
    get_window = function(self, name)
        return self.windows[name]
    end,

    --[[!
        Hides a window - that is, destroys it. It can be re-built anytime
        later. Returns true if it actually destroyed anything, false otherwise.
    ]]
    hide_window = function(self, name)
        local old = self:find_child(Window.type, name, false)
        if old then self:remove(old) end
        local win = self.windows[name]
        if not win then
            logger.log(logger.ERROR, "no such window: " .. name)
            return false
        end
        win(false) -- set visible to false
        return old != nil
    end,

    --[[!
        This finds a window of the given name in the children and returns
        `win:replace(tname, obj, fun)`. It's merely a convenient wrapper.

        Arguments:
            - wname - the window name.
            - tname - the tag name.
            - obj - the object.
            - fun - the optional function (see {{$Widget.replace}}).

        Returns:
            The result of replacing, and false if the window doesn't exist.
    ]]
    replace_in_window = function(self, wname, tname, obj, fun)
        local win = self:find_child(Window.type, wname, false)
        if not win then return false end
        return win:replace(tname, obj, fun)
    end,

    --[[!
        Given a window name, this returns true if that window is currently
        shown and false otherwise.
    ]]
    window_visible = function(self, name)
        return self.windows[name](true)
    end,

    above_hud = function(self)
        local y, ch = 1, self.children
        for i = 1, #ch do
            local w = ch[i]
            if w.above_hud then
                y = min(y, w:get_projection():calc_above_hud())
            end
        end
        return y
    end,

    --[[!
        Sets the root's cursor position, given the global pointer
        coordinates. By default this simply copies the given values.
    ]]
    set_cursor = function(self, x, y)
        self.cursor_x = x
        self.cursor_y = y
    end,

    --[[!
        Returns whether the current root has a cursor. If the argument
        is true, this does an update (re-checks, updates the value and
        emits an internal signal).
    ]]
    cursor_exists = function(self, update)
        local cec = self.has_cursor
        if not update then return cec end
        local bce = cec
        cec = self:grabs_input() or self:target(self.cursor_x * self.w,
            self.cursor_y * self.h) ~= nil
        if bce ~= cec then
            self.has_cursor = cec
            emit(self, "__has_cursor_changed", cec)
        end
        return cec
    end,

    --[[!
        Returns true as roots are alway roots.
    ]]
    is_root = function(self)
        return true
    end,

    --[[!
        Gets the widget's projection. Unlike regular projection getter,
        this doesn't attempt to create a new projection if one doesn't
        exist as roots typically don't have projections.
    ]]
    get_projection = function(self)
        return self._projection
    end,

    --! Pushes a clip area into the root's clip stack and scissors.
    clip_push = function(self, x, y, w, h)
        local cs = self._clip_stack
        local l = #cs
        if    l == 0 then gl_scissor_enable() end

        local c = Clip_Area(x, y, w, h)

        l = l + 1
        cs[l] = c

        if l >= 2 then c:intersect(cs[l - 1]) end
        c:scissor(self)
    end,

    --[[!
        Pops a clip area out of the clip stack and scissors (assuming there
        is anything left on the clip stack).
    ]]
    clip_pop = function(self)
        local cs = self._clip_stack
        tremove(cs)

        local l = #cs
        if    l == 0 then gl_scissor_disable()
        else cs[l]:scissor(self)
        end
    end,

    --[[!
        See $Clip_Area.is_fully_clipped. Works on the last clip area on the
        clip stack.
    ]]
    clip_is_fully_clipped = function(self, x, y, w, h)
        local cs = self._clip_stack
        local l = #cs
        if    l == 0 then return false end
        return cs[l]:is_fully_clipped(x, y, w, h)
    end,

    --[[!
        Scissors the last area in the clip stack.
    ]]
    clip_scissor = function(self)
        local cs = self._clip_stack
        cs[#cs]:scissor(self)
    end,

    _tooltip_init = function(self, o, op, clear_on_drop)
        op.managed_objects[o] = o
        local oldop = o.parent
        if oldop then oldop.managed_objects[o] = nil end

        self._tooltip  = o
        o.parent       = op
        o._root        = self
        op._root       = self
        self:set_projection(o:get_projection())
        o:layout()
        self:set_projection(nil)

        o._clear_on_drop = clear_on_drop

        local x, y = self.cursor_x * self.w + 0.01, self.cursor_y + 0.01
        local tw, th = o.w, o.h
        if (x + tw * 0.95) > self.w then
            x = x - tw + 0.02
            if x <= 0 then x = 0.02 end
        end
        if (y + th * 0.95) > 1 then
            y = y - th + 0.02
        end
        o.x, o.y = max(0, x), max(0, y)
    end,

    _menus_drop = function(self, n)
        local ms = self._menu_stack
        local msl = #ms
        n = n or msl
        for i = msl, msl - n + 1, -1 do
            local o = tremove(ms)
            local op = o.parent
            if o._clear_on_drop then
                o:clear()
                op.managed_objects[o] = nil
            end
            op._menu = nil
        end
    end,

    _menu_init = function(self, o, op, i, at_cursor, clear_on_drop)
        if self._menu_nhov == 0 then
            self:_menus_drop()
            i = 1
        end

        op.managed_objects[o] = o
        local oldop = o.parent
        if oldop then oldop.managed_objects[o] = nil end

        local ms = self._menu_stack
        ms[i]     = o
        o.is_menu = true
        o.parent  = op
        o._root   = self
        op._root  = self
        op._menu  = o

        o._clear_on_drop = clear_on_drop

        local prevo = (i > 1) and ms[i - 1] or nil

        -- initial layout to guess the bounds
        local proj = self:set_projection(o:get_projection())
        o:layout()
        proj:calc()
        local pw, ph = proj.pw, proj.ph
        self:set_projection(nil)

        -- parent projection (for correct offsets)
        local fw, fh
        if not prevo then
            local win = o.parent
            while true do
                local p = win.parent
                if not p.parent then break end
                win = p
            end
            local proj = win:get_projection()
            fw, fh = pw / proj.pw, ph / proj.ph
        else
            local proj = prevo:get_projection()
            fw, fh = pw / proj.pw, ph / proj.ph
        end

        -- ow/h: menu w/h, opw/h: menu parent w/h (e.g. menubutton)
        local ow, oh, opw, oph = o.w, o.h, op.w * fw, op.h * fh

        local cx, cy = self.cusror_x, self.cursor_y

        -- when spawning menus right on the cursor
        if at_cursor then
            -- compute cursor coords in terms of widget position
            local x, y = cx * pw, cy * ph
            -- adjust y so that it's always visible as whole
            if (y + oh) > ph then y = max(0, y - oh) end
            -- adjust x if clipped on the right
            if (x + ow) > pw then
                x = max(0, x - ow)
            end
            -- set position and return
            o.x, o.y = max(0, x), max(0, y)
            return
        end

        local dx, dy = hovering and hover_x * fw or click_x * fw,
                       hovering and hover_y * fh or click_y * fh
        -- omx, omy: the base position of the new menu
        local omx, omy = cx * pw - dx, cy * ph - dy

        -- a submenu - uses different alignment - submenus are put next to
        -- their spawners, regular menus are put under their spawners
        if i != 1 then
            -- when the current y + height of menu exceeds the screen height,
            -- move the menu up by its height minus the spawner height, make
            -- sure it's at least 0 (so that it's not accidentally moved above
            -- the screen)
            if omy + oh > ph then
                omy = max(0, omy - oh + oph)
            end
            -- when the current x + width of the spawner + width of the menu
            -- exceeds the screen width, move it to the left by its width,
            -- making sure the x is at least 0
            if (omx + opw + ow) > pw then
                omx = max(0, omx - ow)
            -- else offset by spawner width
            else
                omx += opw
            end
        -- regular menu
        else
            -- when current y + height of spawner + height of menu exceeds the
            -- screen height, move the menu up by its height, make sure
            -- it's > 0
            if omy + oph + oh > ph then
                omy = max(0, omy - oh)
            -- otherwise move down a bit (by the button height)
            else
                omy += oph
            end
            -- adjust x here - when the current x + width of the menu exceeds
            -- the screen width, perform adjustments
            if (omx + ow) > pw then
                -- if the menu spawner width exceeds the screen width too,
                -- put the menu to the right
                if (omx + opw) > pw then
                    omx = max(0, pw - ow)
                -- else align it with the spawner
                else omx = max(0, omx - ow + opw) end
            end
        end
        o.x, o.y = max(0, omx), max(0, omy)
    end
})
local Root = M.Root

root = Root()

signal.connect(root, "__has_cursor_changed", function(self, val)
    input_cursor_exists_update(val)
end)

local hud = Overlay { name = "hud" }
hud._root = root

--! Returns the HUD overlay.
M.get_hud = function()
    return hud
end

local menu_click = function(o, cx, cy, code)
    local proj = o:get_projection()
    local ox, oy = cx * proj.pw - o.x, cy * proj.ph - o.y
    if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
        local cl = o:click(ox, oy, code)
        if cl == o then click_x, click_y = ox, oy end
        return true, cl
    else
        return false
    end
end

local menu_hover = function(o, cx, cy)
    local proj = o:get_projection()
    local ox, oy = cx * proj.pw - o.x, cy * proj.ph - o.y
    if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
        local cl = o:hover(ox, oy)
        if cl == o then hover_x, hover_y = ox, oy end
        return true, cl
    else
        return false
    end
end

local menu_hold = function(o, cx, cy, obj)
    local proj = o:get_projection()
    local ox, oy = cx * proj.pw - o.x, cy * proj.ph - o.y
    if obj == o then return ox, oy end
    return o:hold(ox, oy, obj)
end

local mousebuttons = {
    [key.MOUSELEFT] = true, [key.MOUSEMIDDLE]  = true, [key.MOUSERIGHT] = true,
    [key.MOUSEBACK] = true, [key.MOUSEFORWARD] = true
}

set_external("input_keypress", function(code, isdown)
    if not root:cursor_exists() or not root.visible then
        return false
    end
    if root:key_raw(code, isdown) then
        return true
    end
    if hovering and hovering:key_hover(code, isdown) then
        return true
    end
    if mousebuttons[code] then
        if isdown then
            clicked_code = code
            local clicked_try
            local ck, cl
            local ms = root._menu_stack
            if #ms > 0 then
                for i = #ms, 1, -1 do
                    ck, cl = menu_click(ms[i], root.cursor_x,
                        root.cursor_y, code)
                    if ck then
                        clicked_try = cl
                        break
                    end
                end
                if not ck then root:_menus_drop() end
            end
            if ck then
                clicked = clicked_try
            else
                clicked = root:click(root.cursor_x, root.cursor_y, code)
            end
            if clicked then
                clicked:clicked(click_x, click_y, code)
            else
                clicked_code = nil
            end
        else
            if clicked then
                local hx, hy
                local ms = root._menu_stack
                if #ms > 0 then for i = #ms, 1, -1 do
                    hx, hy = menu_hold(ms[i], root.cursor_x,
                        root.cursor_y, clicked)
                    if hx then break end
                end end
                if not hx then
                    hx, hy = root:hold(root.cursor_x, root.cursor_y, clicked)
                end
                clicked:released(hx, hy, code)
            end
            clicked_code, clicked = nil, nil
        end
        return true
    end
    return root:key(code, isdown)
end)

set_external("input_text", function(str)
    return root:text_input(str)
end)

local draw_hud = false

local mmenu = var_get("mainmenu")
signal.connect(cs, "mainmenu_changed", function(self, v)
    mmenu = v
end)

set_external("gui_clear", function()
    var_set("hidechanges", 0)
    if mmenu != 0 and isconnected() then
        var_set("mainmenu", 0, true, false) -- no clamping, readonly var
        root:destroy_children()
        if draw_hud then
            hud:destroy_children()
            draw_hud = false
        end
        local tooltip = root._tooltip
        if tooltip and tooltip._clear_on_drop then
            tooltip:clear()
            tooltip.parent.managed_objects[tooltip] = nil
        end
        root._tooltip = nil
        root:_menus_drop()
    end
end)

--[[! Variable: uitextrows
    Specifies how many rows of text of scale 1 can fit on the screen. Defaults
    to 40. You can change this to tweak the font scale and thus the whole UI
    scale.
]]
cs.var_new_checked("uitextrows", cs.var_type.int, 1, 40, 200,
    cs.var_flags.PERSIST)

local uitextrows = var_get("uitextrows")
signal.connect(cs, "uitextrows_changed", function(self, n)
    uitextrows = n
end)

--! See $uitextrows. This is a fast getter for it.
M.get_text_rows = function()
    return uitextrows
end

local uitextscale, uicontextscale = 0, 0

M.get_text_scale = function(con)
    return con and uicontextscale or uitextscale
end

local calc_text_scale = function()
    uitextscale = 1 / uitextrows
    local tw, th = hud_get_w(), hud_get_h()
    local forceaspect = aspect_get()
    if forceaspect != 0 then tw = ceil(th * forceaspect) end
    tw, th = text_get_res(tw, th)
    uicontextscale = text_font_get_h() * console_scale_get() / th
end

set_external("gui_update", function()
    root:set_cursor(input_cursor_get_x(), input_cursor_get_y())

    if mmenu != 0 and not root:window_visible("main") and
    not isconnected(true) then
        root:show_window("main")
    end

    draw_hud = (mmenu == 0 and editing_get() == 0) and hud.visible or false

    local wvisible = root.visible

    local tooltip = root._tooltip
    if tooltip and tooltip._clear_on_drop then
        tooltip:clear()
        tooltip.parent.managed_objects[tooltip] = nil
    end
    tooltip, root._tooltip = nil, nil

    calc_text_scale()

    if root:cursor_exists() and wvisible then
        local hovering_try
        local hk, hl
        local nhov = 0
        local ms = root._menu_stack
        if #ms > 0 then
            for i = #ms, 1, -1 do
                hk, hl = menu_hover(ms[i], root.cursor_x,
                    root.cursor_y)
                if hk then
                    hovering_try = hl
                    if hl then nhov = i end
                    break
                end
            end
        end
        local oldhov, oldhx, oldhy = hovering, hover_x, hover_y
        if hk then
            hovering = hovering_try
        else
            hovering = root:hover(root.cursor_x, root.cursor_y)
        end
        if oldhov and oldhov != hovering then
            oldhov:leaving(oldhx, oldhy)
        end
        if hovering then
             local msl = #ms
            if msl > 0 and nhov > 0 and msl > nhov then
                root:_menus_drop(msl - nhov)
            end
            root._menu_nhov = nhov
            hovering:hovering(hover_x, hover_y)
            root._menu_nhov = nil
        end

        if clicked then
            local hx, hy
            if #ms > 0 then for i = #ms, 1, -1 do
                hx, hy = menu_hold(ms[i], root.cursor_x,
                    root.cursor_y, clicked)
                if hx then break end
            end end
            if not hx then
                hx, hy = root:hold(root.cursor_x, root.cursor_y, clicked)
            end
            clicked:holding(hx, hy, clicked_code)
        end
    else
        hovering, clicked = nil, nil
    end

    if wvisible then root:layout() end

    tooltip = root._tooltip
    if tooltip then
        local proj = root:set_projection(tooltip:get_projection())
        tooltip:layout()
        proj:calc()
        tooltip:adjust_children()
        root:set_projection(nil)
    end

    local ms = root._menu_stack
    for i = 1, #ms do
        local o = ms[i]
        local proj = root:set_projection(o:get_projection())
        o:layout()
        proj:calc()
        o:adjust_children()
        root:set_projection(nil)
    end

    if draw_hud then
        local proj = root:set_projection(hud:get_projection())
        hud:layout()
        hud.x, hud.y, hud.w, hud.h = 0, 0, root.w, root.h
        proj:calc()
        hud:adjust_children()
        root:set_projection(nil)
    end

    root:cursor_exists(true)
end)

M.__draw_window = function(win)
    calc_text_scale()
    root:layout_dim()
    win.x, win.y, win.parent, win._root = 0, 0, root, root
    local proj = root:set_projection(win:get_projection())
    win:layout()
    proj:adjust_layout()
    proj:draw()
    root:set_projection(nil)
end

set_external("gui_render", function()
    local w = root
    if draw_hud or (w.visible and #w.children != 0) then
        w:draw()
        local tooltip = w._tooltip
        local ms = w._menu_stack
        for i = 1, #ms do   ms[i]:get_projection():draw() end
        if tooltip   then tooltip:get_projection():draw() end
        if draw_hud  then     hud:get_projection():draw() end
        gle_disable()
    end
end)

set_external("gui_above_hud", function()
    return root:above_hud()
end)

local needsapply = {}

--[[! Variable: applydialog
    An engine variable that controls whether the "apply" dialog will show
    on changes that need restart of some engine subsystem. Defaults to 1.
]]
cs.var_new_checked("applydialog", cs.var_type.int, 0, 1, 1,
    cs.var_flags.PERSIST)
cs.var_new("hidechanges", cs.var_type.int, 0, 0, 1)

set_external("change_add", function(desc, ctype)
    if var_get("applydialog") == 0 then return end

    for i, v in pairs(needsapply) do
        if v.desc == desc then return end
    end

    needsapply[#needsapply + 1] = { ctype = ctype, desc = desc }
    local win = root:get_window("changes")
    if win and (var_get("hidechanges") == 0) then win() end
end)

local CHANGE_GFX     = 1 << 0
local CHANGE_SOUND   = 1 << 1
local CHANGE_SHADERS = 1 << 2

local changes_clear = function(ctype)
    ctype = ctype or (CHANGE_GFX | CHANGE_SOUND | CHANGE_SHADERS)

    needsapply = table2.filter(needsapply, function(i, v)
        if (v.ctype & ctype) == 0 then
            return true
        end

        v.ctype = (v.ctype & ~ctype)
        if v.ctype == 0 then
            return false
        end

        return true
    end)
end
set_external("changes_clear", changes_clear)
M.changes_clear = changes_clear

M.changes_apply = function()
    local changetypes = 0
    for i, v in pairs(needsapply) do
        changetypes |= v.ctype
    end

    if (changetypes & CHANGE_GFX) != 0 then
        cs.execute("resetgl")
    elseif (changetypes & CHANGE_SHADERS) != 0 then
        cs.execute("resetshaders")
    end
    if (changetypes & CHANGE_SOUND) != 0 then
        cs.execute("resetsound")
    end
end

M.changes_get = function()
    return table2.map(needsapply, function(v) return v.desc end)
end

--! Gets the default GUI root widget.
M.get_root = function()
    return root
end

return M
