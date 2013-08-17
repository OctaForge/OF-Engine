--[[! File: lua/core/gui/core.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        A basic widget set. This module in particular implements the core
        of the whole system. All modules are documented, but not all methods
        in each widgets are documented - only those of a significant meaning
        to the user are (as the other ones have no use for the user).
        It also manages the HUD.
]]

local capi = require("capi")
local cs = require("core.engine.cubescript")
local math2 = require("core.lua.math")
local table2 = require("core.lua.table")
local signal = require("core.events.signal")
local logger = require("core.logger")

local gl_scissor_enable, gl_scissor_disable, gl_scissor, gl_blend_enable,
gl_blend_disable, gl_blend_func, gle_attrib2f, gle_color3f, gle_disable,
hudmatrix_ortho, hudmatrix_reset, shader_hud_set, hud_get_w, hud_get_h,
hud_get_ss_x, hud_get_ss_y, hud_get_so_x, hud_get_so_y, isconnected in capi

local set_external = capi.external_set

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

local M = {}

local consts = require("core.gui.constants")

--[[! Variable: gl
    Forwarded from the "constants" module.
]]
local gl = consts.gl
M.gl = gl

--[[! Variable: key
    Forwarded from the "constants" module.
]]
local key = consts.key
M.key = key

--[[! Variable: mod
    Forwarded from the "constants" module.
]]
local mod = consts.mod
M.mod = mod

local update_later = {}

--[[! Function: update_var
    Schedules an engine variable update for the next frame. Takes the
    variable name and the value to set.
]]
local update_var = function(varn, val)
    if not cs.var_exists(varn) then
        return nil
    end
    update_later[#update_later + 1] = { varn, val }
end
M.update_var = update_var

-- initialized after World is created
local world, clicked, hovering, focused
local hover_x, hover_y, click_x, click_y = 0, 0, 0, 0
local cursor_x, cursor_y, prev_cx, prev_cy = 0.5, 0.5, 0.5, 0.5

--[[! Function: is_clicked
    Given a widget, this function returns true if that widget is clicked
    and false otherwise.
]]
local is_clicked = function(o) return (o == clicked) end
M.is_clicked = is_clicked

--[[! Function: is_hovering
    Given a widget, this function returns true if that widget is being
    hovered on and false otherwise.
]]
local is_hovering = function(o) return (o == hovering) end
M.is_hovering = is_hovering

--[[! Function: is_clicked
    Given a widget, this function returns true if that widget is focused
    and false otherwise.
]]
local is_focused = function(o) return (o == focused) end
M.is_focused = is_focused

--[[! Function: has_menu
    Given a widget, this function return true if that widget has a menu
    opened and false otherwise.
]]
local has_menu = function(o) return o.has_menu == true end
M.has_menu = has_menu

--[[! Function: set_focus
    Gives the given GUI widget focus.
]]
local set_focus = function(o) focused = o end
M.set_focus = set_focus

--[[! Function: clear_focus
    Given a widget, this function clears all focus from it (that is,
    clicked, hovering, focused).
]]
local clear_focus = function(o)
    if o == clicked  then clicked  = nil end
    if o == hovering then hovering = nil end
    if o == focused  then focused  = nil end
end
M.clear_focus = clear_focus

local ALIGN_MASK    = 0xF

local ALIGN_HMASK   = 0x3
local ALIGN_HSHIFT  = 0
local ALIGN_HNONE   = 0
local ALIGN_LEFT    = 1
local ALIGN_HCENTER = 2
local ALIGN_RIGHT   = 3

local ALIGN_VMASK   = 0xC
local ALIGN_VSHIFT  = 2
local ALIGN_VNONE   = 0 << 2
local ALIGN_TOP     = 1 << 2
local ALIGN_VCENTER = 2 << 2
local ALIGN_BOTTOM  = 3 << 2

local CLAMP_MASK    = 0xF0
local CLAMP_LEFT    = 0x10
local CLAMP_RIGHT   = 0x20
local CLAMP_TOP     = 0x40
local CLAMP_BOTTOM  = 0x80

local NO_ADJUST     = ALIGN_HNONE | ALIGN_VNONE

local wtypes_by_name = {}
local wtypes_by_type = {}

local lastwtype = 0

--[[! Function: register_class
    Registers a widget class. Takes the widget class name, its base (if
    not given, Widget), its body (empty if not given, otherwise regular
    object body like with clone operation) and optionally a forced type
    (by default assigns the widget a new type available under the "type"
    field, using this you can override it and make it set a specific
    value). Returns the widget class.
]]
local register_class = function(name, base, obj, ftype)
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
M.register_class = register_class

--[[! Function: get_class
    Given either a name or type, this function returns the widget class
    with that name or type.
]]
local get_class = function(n)
    if type(n) == "string" then
        return wtypes_by_name[n]
    else
        return wtypes_by_type[n]
    end
end
M.get_class = get_class

--[[! Function: loop_children
    Loops widget children, executing the function given in the second
    argument with the child passed to it. If the widget has states,
    it first acts on the current state and then on the actual children
    from 1 to N.
]]
local loop_children = function(self, fun)
    local ch = self.children
    local vr = self.vstates
    local st = self.states

    if st or vr then
        local s = self:choose_state()
        local  w = st and st[s]
        if not w then
            w = vr and vr[s]
        end
        if w then
            local r = fun(w)
            if r != nil then return r end
        end
    end

    for i = 1, #vr do
        local r = fun(vr[i])
        if    r != nil then return r end
    end

    for i = 1, #ch do
        local r = fun(ch[i])
        if    r != nil then return r end
    end
end
M.loop_children = loop_children

--[[! Function: loop_children_r
    Loops widget children in reverse order, executing the function
    given in the second argument with the child passed to it. First
    goes over all children in reverse order and then if the widget
    has states, it acts on the current state.
]]
local loop_children_r = function(self, fun)
    local ch = self.children
    local vr = self.vstates
    local st = self.states

    for i = #ch, 1, -1 do
        local r = fun(ch[i])
        if    r != nil then return r end
    end

    for i = #vr, 1, -1 do
        local r = fun(vr[i])
        if    r != nil then return r end
    end

    if st then
        local s = self:choose_state()
        local  w = st and st[s]
        if not w then
            w = vr and vr[s]
        end
        if w then
            local r = fun(w)
            if r != nil then return r end
        end
    end
end
M.loop_children_r = loop_children_r

--[[! Function: loop_in_children
    Similar to above, but takes 4 arguments. The first argument is a widget,
    the other two arguments are x and y position and the last argument
    is the function. The function is executed only for those children
    that cover the given x, y coords.
]]
local loop_in_children = function(self, cx, cy, fun)
    return loop_children(self, function(o)
        local ox = cx - o.x
        local oy = cy - o.y

        if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
            local r = fun(o, ox, oy)
            if    r != nil then return r end
        end
    end)
end
M.loop_in_children = loop_in_children

--[[! Function: loop_in_children
    See above. Reverse order.
]]
local loop_in_children_r = function(self, cx, cy, fun)
    return loop_children_r(self, function(o)
        local ox = cx - o.x
        local oy = cy - o.y

        if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
            local r = fun(o, ox, oy)
            if    r != nil then return r end
        end
    end)
end
M.loop_in_children_r = loop_in_children_r

local clip_stack = {}

--[[! Function: clip_area_intersect
    Intersects the given clip area with another one. Writes into the
    first one.
]]
local clip_area_intersect = function(self, c)
    self[1] = max(self[1], c[1])
    self[2] = max(self[2], c[2])
    self[3] = max(self[1], min(self[3], c[3]))
    self[4] = max(self[2], min(self[4], c[4]))
end
M.clip_area_intersect = clip_area_intersect

--[[! Function: clip_area_is_fully_clipped
    Given a clip area and x, y, w, h, checks if the area specified by
    the coordinates is fully clipped by the clip area.
]]
local clip_area_is_fully_clipped = function(self, x, y, w, h)
    return self[1] == self[3] or self[2] == self[4] or x >= self[3] or
           y >= self[4] or (x + w) <= self[1] or (y + h) <= self[2]
end
M.clip_area_is_fully_clipped = clip_area_is_fully_clipped

--[[! Function: clip_push
    Pushes a clip area into the clip stack and scissors.
]]
local clip_push = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then gl_scissor_enable() end

    local c = { x, y, x + w, y + h }

    l = l + 1
    clip_stack[l] = c

    if l >= 2 then clip_area_intersect(c, clip_stack[l - 1]) end
    clip_area_scissor(c)
end
M.clip_push = clip_push

--[[! Function: clip_pop
    Pops a clip area out of the clip stack and scissors (assuming there
    is anything left on the clip stack).
]]
local clip_pop = function()
    tremove(clip_stack)

    local l = #clip_stack
    if    l == 0 then gl_scissor_disable()
    else clip_area_scissor(clip_stack[l])
    end
end
M.clip_pop = clip_pop

--[[! Function: is_fully_clipped
    See <clip_area_is_fully_clipped>. Works on the last clip area on the
    clip stack.
]]
local is_fully_clipped = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then return false end
    return clip_area_is_fully_clipped(clip_stack[l], x, y, w, h)
end
M.is_fully_clipped = is_fully_clipped

--[[! Function: clip_area_scissor
    Scissors an area given a clip area. If nothing is given, the area
    last in the clip stack is used.
]]
local clip_area_scissor = function(self)
    self = self or clip_stack[#clip_stack]
    local sx1, sy1, sx2, sy2 =
        world:calc_scissor(self[1], self[2], self[3], self[4])
    gl_scissor(sx1, sy1, sx2 - sx1, sy2 - sy1)
end
M.clip_area_scissor = clip_area_scissor

--[[! Function: draw_quad
    An utility function for drawing quads, takes x, y, w, h and optionally
    tx, ty, tw, th (defaulting to 0, 0, 1, 1).
]]
local quad = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    gle_attrib2f(x,     y)     gle_attrib2f(tx,      ty)
    gle_attrib2f(x + w, y)     gle_attrib2f(tx + tw, ty)
    gle_attrib2f(x + w, y + h) gle_attrib2f(tx + tw, ty + th)
    gle_attrib2f(x,     y + h) gle_attrib2f(tx,      ty + th)
end
M.draw_quad = quad

--[[! Function: draw_quadtri
    An utility function for drawing quads, takes x, y, w, h and optionally
    tx, ty, tw, th (defaulting to 0, 0, 1, 1). Used with triangle strip.
]]
local quadtri = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    gle_attrib2f(x,     y)     gle_attrib2f(tx,      ty)
    gle_attrib2f(x + w, y)     gle_attrib2f(tx + tw, ty)
    gle_attrib2f(x,     y + h) gle_attrib2f(tx,      ty + th)
    gle_attrib2f(x + w, y + h) gle_attrib2f(tx + tw, ty + th)
end
M.draw_quadtri = quadtri

local gen_setter = function(name)
    local sname = name .. "_changed"
    return function(self, val)
        self[name] = val
        emit(self, sname, val)
    end
end
M.gen_setter = gen_setter

--[[! Variable: orient
    Defines the possible orientations on widgets - HORIZONTAL and VERTICAL.
]]
local orient = {
    HORIZONTAL = 0, VERTICAL = 1
}
M.orient = orient

local Widget, Window

--[[! Struct: Widget
    The basic widget class every other derives from. Provides everything
    needed for a working widget class, but doesn't do anything by itself.

    Basic properties are x, y, w, h, adjust (clamping and alignment),
    children (an array of widgets), floating (whether the widget is freely
    movable), parent (the parent widget), variant, variants, states, tooltip
    (a widget), menu (a widget) and container (a widget).

    Properties are not made for direct setting from the outside environment.
    Those properties that are meant to be set have a setter method called
    set_PROPNAME. Unless documented otherwise, those functions emit the
    PROPNAME_changed signal with the given value passed to emit. Some
    properties that you don't set and are set from the internals also
    emit signals so you can handle extra events. That is typically documented.

    Several properties can be initialized via kwargs (align_h, align_v,
    clamp_l, clamp_r, clamp_b, clamp_t, floating, variant, states, signals,
    tooltip, menu, container and init, which is a function called at the end
    of the constructor if it exists). Array members of kwargs are children.

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
    state is found, it's used. Otherwise the global "variants" table is
    tried, getting the variant self.variant (or "default" if none).

    Along with "variants", the global widget class can contain "properties".
    These allow to define per-variant special attributes for widgets (each
    comes with a setter that emits the appropriate signal). The tablle
    "properties" maps a variant name to an array of property names.

    Note that you can't override existing properties (as in, either self[name]
    or self["set_" .. name] exists) and if you set a different variant, all
    custom properties are discarded and replaced. Properties starting with an
    underscore are not allowed (reserved for private fields).

    The property "container" is a reference to another widget that is used
    as a target for appending/prepending/insertion and is fully optional.

    Each widget class also contains an "instances" table storing a set
    of all instances of the widget class.
]]
Widget = register_class("Widget", table2.Object, {
    --[[! Constructor: __init
        Builds a widget instance from scratch. The optional kwargs
        table contains properties that should be set on the resulting
        widget.
    ]]
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        local instances = rawget(self.__proto, "instances")
        if not instances then
            instances = {}
            rawset(self.__proto, "instances", instances)
        end
        instances[self] = self

        self.x, self.y, self.w, self.h = 0, 0, 0, 0

        self.adjust = ALIGN_HCENTER | ALIGN_VCENTER

        -- alignment and clamping
        local align_h = kwargs.align_h or 0
        local align_v = kwargs.align_v or 0
        local clamp_l = kwargs.clamp_l or false
        local clamp_r = kwargs.clamp_r or false
        local clamp_b = kwargs.clamp_b or false
        local clamp_t = kwargs.clamp_t or false

        self.floating = kwargs.floating or false
        self.visible  = (kwargs.visible != false) and true or false

        self:align(align_h, align_v)
        self:clamp(clamp_l, clamp_r, clamp_b, clamp_t)

        if kwargs.signals then
            for k, v in pairs(kwargs.signals) do
                signal.connect(self, k, v)
            end
        end

        self.tooltip = kwargs.tooltip or false
        self.menu    = kwargs.menu    or false

        self.init_clone = kwargs.init_clone

        local ch = {}
        for i, v in ipairs(kwargs) do
            ch[i] = v
            v.parent = self
        end

        self.children = ch

        if  kwargs.pre_init then
            kwargs.pre_init(self)
        end

        -- states
        local states = {}
        local ks = kwargs.states
        if ks then
            for k, v in pairs(ks) do
                states[k] = v
                states[k].parent = self
            end
        end
        self.states = states

        local variant = kwargs.variant

        -- extra kwargs
        local props = rawget(self.__proto, "properties")
        props = props and props[variant or "default"] or nil
        if props then for i, v in ipairs(props) do
            assert(v:sub(1, 1) != "_", "invalid property " .. v)
            assert(not self["set_" .. v] and self[v] == nil,
                "cannot override existing property " .. v)
            self[v] = kwargs[v]
        end end

        -- disable asserts, already checked above
        self:set_variant(variant, true)

        -- and init
        if  kwargs.init then
            kwargs.init(self)
        end
    end,

    --[[! Function: clear
        Clears a widget including its children recursively. Calls the
        "destroy" signal. Removes itself from its widget class' instances
        set. Does nothing if already cleared. Also clears the container,
        menu and tooltip if present (and if self is their parent).
    ]]
    clear = function(self)
        if self._cleared then return nil end
        clear_focus(self)

        local children = self.children
        if children then
            for k, v in ipairs(children) do v:clear() end
        end
        local states = self.states
        if states then
            for k, v in pairs(states) do v:clear() end
        end
        local vstates = self.vstates
        if vstates then
            for k, v in pairs(vstates) do v:clear() end
        end

        local container, menu, tooltip in self
        self.container, self.menu, self.tooltip = nil, nil, nil
        if container and container.parent == self then container:clear() end
        if menu      and menu.parent      == self then      menu:clear() end
        if tooltip   and tooltip.parent   == self then   tooltip:clear() end

        emit(self, "destroy")
        local insts = rawget(self.__proto, "instances")
        if insts then
            insts[self] = nil
        end

        self._cleared = true
    end,

    --[[! Function: deep_clone
        Creates a deep clone of the widget, that is, where each child
        is again a clone of the original child, down the tree. Useful
        for default widget class states, where we need to clone
        these per-instance.
    ]]
    deep_clone = function(self, obj, initc)
        local ch, rch = {}, self.children
        local ic = initc and self.init_clone or nil
        local cl = self:clone { children = ch }
        for i = 1, #rch do
            local c = rch[i]
            local chcl = c:deep_clone(obj, true)
            chcl.parent = cl
            ch[i] = chcl
        end
        if ic then ic(cl, obj) end
        return cl
    end,

    --[[! Function: set_variant
        Sets the variant this widget instance uses. If not provided, "default"
        is set implicitly.
    ]]
    set_variant = function(self, variant, disable_asserts)
        self.variant = variant
        local vstates = {}
        local old_vstates = self.vstates
        if old_vstates then
            for k, v in pairs(old_vstates) do
                v:clear()
            end
        end
        local dstates = rawget(self.__proto, "variants")
        dstates = dstates and dstates[variant or "default"] or nil
        if dstates then
            for k, v in pairs(dstates) do
                local ic = v.init_clone
                local cl = v:deep_clone(self)
                vstates[k] = cl
                cl.parent = self
                if ic then ic(cl, self) end
            end
        end
        local oldprops = self.defprops
        if oldprops then for i, v in ipairs(oldprops) do
            self["set_" .. v], self[v] = nil, nil
        end end
        local defprops = {}
        local props = rawget(self.__proto, "properties")
        props = props and props[variant or "default"] or nil
        if props then for i, v in ipairs(props) do
            local nm = "set_" .. v
            if not disable_asserts then
                assert(v:sub(1, 1) != "_", "invalid property " .. v)
                assert(not self[nm] and self[v] == nil,
                    "cannot override existing property " .. v)
            end
            self[nm] = gen_setter(v)
        end end
        local cont = self.container
        if cont and cont._cleared then self.container = nil end
        self.vstates  = vstates
        self.defprops = defprops
    end,

    --[[! Function: update_class_state
        Call on the widget class. Takes the state name and the state
        widget and optionally variant (defaults to "default") and updates it
        on the class and on every instance of the class. Destroys the old state
        of that name (if any) on the class and on every instance. If the
        instance already uses a different state (custom), it's left alone.

        Using this you can update the look of all widgets of certain type
        with ease.
    ]]
    update_class_state = function(self, sname, sval, variant)
        variant = variant or "default"
        local dstates = rawget(self, "variants")
        if not dstates then
            dstates = {}
            rawset(self, "variants", dstates)
        end
        local variant = dstates[variant]
        if not variant then
            variant = {}
            dstates[variant] = variant
        end
        local oldstate = variant[sname]
        variant[sname] = sval
        oldstate:clear()

        local insts = rawget(self, "instances")
        if insts then for v in pairs(insts) do
            local sts = v.vstates
            if sts and v.variant == variant then
                local st = sts[sname]
                -- update only on widgets actually using the default state
                if st and st.__proto == oldstate then
                    local ic = sval.init_clone
                    local nst = sval:deep_clone(v)
                    nst.parent = v
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

    --[[! Function: update_class_states
        Given an associative array of states (and optionally variant), it
        calls <update_class_state> for each.
    ]]
    update_class_states = function(self, states, variant)
        for k, v in pairs(states) do
            self:update_class_state(k, v, variant)
        end
    end,

    --[[! Function: update_state
        Given the state name an a widget, this sets the state of that name
        for the individual widget (unlike <update_class_state>). That is
        useful when you need widgets with custom appearance but you don't
        want all widgets to have it. This function destroys the old state
        if any.
    ]]
    update_state = function(self, state, obj)
        local states = self.states
        local ostate = states[state]
        if ostate then ostate:clear() end
        states[state] = obj
        obj.parent = self
        local cont = self.container
        if cont and cont._cleared then self.container = nil end
        self:state_changed(state, obj)
        return obj
    end,

    --[[! Function: update_states
        Given an associative array of states, it calls <update_state>
        for each.
    ]]
    update_states = function(self, states)
        for k, v in pairs(states) do
            self:update_state(k, v)
        end
    end,

    --[[! Function: state_changed
        Called with the state name and the state widget everytime
        <update_state> or <update_class_state> updates a widget's state.
        Useful for widget class and instance specific things such as updating
        labels on buttons. By default does nothing.
    ]]
    state_changed = function(self, sname, obj)
    end,

    --[[! Function: choose_state
        Returns the state that should be currently used. By default
        returns nil.
    ]]
    choose_state = function(self) return nil end,

    --[[! Function: layout
        Takes care of widget positioning and sizing. By default calls
        recursively.
    ]]
    layout = function(self)
        self.w = 0
        self.h = 0

        loop_children(self, function(o)
            o.x = 0
            o.y = 0
            o:layout()
            self.w = max(self.w, o.x + o.w)
            self.h = max(self.h, o.y + o.h)
        end)
    end,

    --[[! Function: adjust_children
        Adjusts layout of children widgets. Takes additional optional
        parameters px (0), py (0), pw (self.w), ph (self.h). Basically
        calls <adjust_layout> on each child with those parameters.
    ]]
    adjust_children = function(self, px, py, pw, ph)
        px, py, pw, ph = px or 0, py or 0, pw or self.w, ph or self.h
        loop_children(self, function(o) o:adjust_layout(px, py, pw, ph) end)
    end,

    --[[! Function: adjust_layout
        Layout adjustment hook for self. Adjusts x, y, w, h of the widget
        according to its alignment and clamping. When everything is done,
        calls <adjust_children> with no parameters.
    ]]
    adjust_layout = function(self, px, py, pw, ph)
        local x, y, w, h, a = self.x, self.y,
            self.w, self.h, self.adjust

        local adj = a & ALIGN_HMASK

        if adj == ALIGN_LEFT then
            x = px
        elseif adj == ALIGN_HCENTER then
            x = px + (pw - w) / 2
        elseif adj == ALIGN_RIGHT then
            x = px + pw - w
        end

        adj = a & ALIGN_VMASK

        if adj == ALIGN_TOP then
            y = py
        elseif adj == ALIGN_VCENTER then
            y = py + (ph - h) / 2
        elseif adj == ALIGN_BOTTOM then
            y = py + ph - h
        end

        if (a & CLAMP_MASK) != 0 then
            if (a & CLAMP_LEFT ) != 0 then x = px end
            if (a & CLAMP_RIGHT) != 0 then
                w = px + pw - x
            end

            if (a & CLAMP_TOP   ) != 0 then y = py end
            if (a & CLAMP_BOTTOM) != 0 then
                h = py + ph - y
            end
        end

        self.x, self.y, self.w, self.h = x, y, w, h

        if self.floating then
            local fx = self.fx
            local fy = self.fy

            if not fx then self.fx, fx = x, x end
            if not fy then self.fy, fy = y, y end

            self.x = fx
            self.y = fy
        end

        self:adjust_children()
    end,

    --[[! Function: target
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

    --[[! Function: key
        Called on keypress. Takes the keycode (see <key>) and a boolean
        value that is true when the key is down and false when it's up.
        By default it doesn't define any behavior so it just loops children
        in reverse order and returns true if any key calls on the children
        return true or false if they don't.
    ]]
    key = function(self, code, isdown)
        return loop_children_r(self, function(o)
            if o.visible and o:key(code, isdown) then return true end
        end) or false
    end,

    --[[! Function: key_raw
        A "raw" key handler that is used in the very beginning of the keypress
        handler. By default, it iterates the children (backwards), tries
        key_raw on each and if that returns true, it returns true too,
        otherwise it goes on (if nothing returned true, it returns false).
        If this returns false, the keypress handler continues normally.
    ]]
    key_raw = function(self, code, isdown)
        return loop_children_r(self, function(o)
            if o.visible and o:key_raw(code, isdown) then return true end
        end) or false
    end,

    --[[! Function: text_input
        Called on text input on the widget. Returns true of the input was
        accepted and false otherwise. The default version loops children
        (backwards) and tries on each until it hits true.
    ]]
    text_input = function(self, str)
        return loop_children_r(self, function(o)
            if o.visible and o:text_input(str) then return true end
        end) or false
    end,

    --[[! Function: key_hover
        Similar to above. Occurs on mouse scroll events and on arrow
        key presses on the focused or hovering widget. Those keys do not
        react otherwise.
    ]]
    key_hover = function(self, code, isdown)
        return loop_children_r(self, function(o)
            if o.visible and o:key_hover(code, isdown) then return true end
        end) or false
    end,

    --[[! Function: draw
        Called in the drawing phase, taking x (left side) and y (upper
        side) coordinates as arguments (or nothing, in that case they
        default to p_x and p_y). By default just loops all the children
        and draws on these (assuming they're not fully clipped).
    ]]
    draw = function(self, sx, sy)
        sx = sx or self.x
        sy = sy or self.y

        loop_children(self, function(o)
            local ox = o.x
            local oy = o.y
            local ow = o.w
            local oh = o.h
            if not is_fully_clipped(sx + ox, sy + oy, ow, oh)
            and o.visible then
                o:draw(sx + ox, sy + oy)
            end
        end)
    end,

    --[[! Function: hover
        Given the cursor coordinates, this function returns the widget
        currently hovered on. By default it just loops children in
        reverse order using <loop_in_children> and calls hover recursively
        on each (and returns the one that first returns a non-nil value).
        If the hover call returns itself, it means we're hovering on the
        widget the method was called on and the current hover coords
        are set up appropriately.
    ]]
    hover = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o.visible and o:hover(ox, oy) or nil
            if    c == o then
                hover_x = ox
                hover_y = oy
            end
            if c then return c end
        end)
    end,

    --[[! Function: hovering
        Called each frame on the widget that's being hovered on (assuming
        it exists). It takes the coordinates we're hovering on. By default
        does nothing, but it can be overloaded.
    ]]
    hovering = function(self, cx, cy)
    end,

    --[[! Function: pressing
        Called on the widget when something is clicked. The arguments
        passed on it are cursor coord deltas compared to the last frame
        (on full width/height scale dependent on the aspect ratio, not
        from 0 to 1).
    ]]
    pressing = function(self, cx, cy)
    end,

    --[[! Function: click
        See <hover>. It's identical, only for the click event.
    ]]
    click = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o.visible and o:click(ox, oy) or nil
            if    c == o then
                click_x = ox
                click_y = oy
            end
            if c then return c end
        end)
    end,

    --[[! Function: clicked
        Called once on the widget that was clicked. By default schedules
        the "click" signal on that widget for emission. Takes the click
        coords as arguments and passes them later to the signal.
    ]]
    clicked = function(self, cx, cy)
        update_later[#update_later + 1] = { self, "click",
            cx / self.w, cy / self.w }
    end,

    --[[! Function: grabs_input
        Returns true if the widget takes input in regular cursor mode. That
        is the default behavior. However, that is not always convenient as
        sometimes you want on-screen widgets that take input in free cursor
        mode only.
    ]]
    grabs_input = function(self) return true end,

    --[[! Function: find_child
        Given a widget type it filds a child widget of that type and returns
        it. Additional optional arguments can be given - the widget name
        (assuming the widget is named), a boolean option specifying whether
        the search is recursive (it always is by default) and a reference
        to a widget that is excluded.
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

    --[[! Function: find_children
        See above. Returns all the possible matches.
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

    --[[! Function: find_sibling
        Finds a sibling of a widget. A sibling is basically defined as any
        child of the parent widget that isn't self (searched recursively),
        then any child of the parent widget of that parent widget and so on.
        Takes type and name.
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

    --[[! Function: find_siblings
        See above. Returns all the possible matches.
    ]]
    find_siblings = function(self, otype, name)
        local ch   = {}
        local prev = self
        local cur  = self.parent

        while cur do
            cur:find_children(otype, name, true, prev, ch)
            prev = cur
            cur  = cur.parent
        end
        return ch
    end,

    --[[! Function: replace
        Given a tag name, finds a tag of that name in the children, destroys
        all children of that tag and appends the given widget to the tag.
        Optionally calls a function given as the last argument with the
        widget being the sole argument of it.
    ]]
    replace = function(self, tname, obj, fun)
        local tag = self:find_child(Tag.type, tname)
        if not tag then return false end
        tag:destroy_children()
        tag:append(obj)
        if fun then fun(obj) end
        return true
    end,

    --[[! Function: remove
        Removes the given widget from the widget's children. Alternatively,
        the argument can be the index of the child in the list. Returns true
        on success and false on failure.
    ]]
    remove = function(self, o)
        if type(o) == "number" then
            if #self.children < n then
                return false
            end
            tremove(self.children, n):clear()
            return true
        end
        for i = 1, #self.children do
            if o == self.children[i] then
                tremove(self.children, i):clear()
                return true
            end
        end
        return false
    end,

    --[[! Function: destroy
        Removes itself from its parent.
    ]]
    destroy = function(self)
        self.parent:remove(self)
    end,

    --[[! Function: destroy_children
        Destroys all the children using regular <clear>. Emits a signal
        "children_destroy" afterwards.
    ]]
    destroy_children = function(self)
        local ch = self.children
        for i = 1, #ch do
            ch[i]:clear()
        end
        self.children = {}
        emit(self, "children_destroy")
    end,

    --[[! Function: align
        Aligns the widget given the horizontal alignment and the vertical
        alignment. Those can be -1 (top, left), 0 (center) and 1 (bottom,
        right).
    ]]
    align = function(self, h, v)
        self.adjust = (self.adjust & ~ALIGN_MASK)
            | ((clamp(h, -1, 1) + 2) << ALIGN_HSHIFT)
            | ((clamp(v, -1, 1) + 2) << ALIGN_VSHIFT)
    end,

    --[[! Function: clamp
        Sets the widget clamping, given the left, right, top and bottom
        clamping. The values can be either true or false.
    ]]
    clamp = function(self, l, r, t, b)
        self.adjust = (self.adjust & ~CLAMP_MASK)
            | (l and CLAMP_LEFT   or 0)
            | (r and CLAMP_RIGHT  or 0)
            | (t and CLAMP_TOP    or 0)
            | (b and CLAMP_BOTTOM or 0)
    end,

    --[[! Function: get_alignment
        Returns the horizontal and vertical alignment of the widget in
        the same format as <align> arguments.
    ]]
    get_alignment = function(self)
        local a   = self.adjust
        local adj = a & ALIGN_HMASK
        local hal = (adj == ALIGN_LEFT) and -1 or
            (adj == ALIGN_HCENTER and 0 or 1)

        adj = a & ALIGN_VMASK
        local val = (adj == ALIGN_BOTTOM) and 1 or
            (adj == ALIGN_VCENTER and 0 or -1)

        return hal, val
    end,

    --[[! Function: get_clamping
        Returns the left, right, bottom, top clamping as either true or false.
    ]]
    get_clamping = function(self)
        local a   = self.adjust
        local adj = a & CLAMP_MASK
        if    adj == 0 then
            return 0, 0, 0, 0
        end

        return (a & CLAMP_LEFT  ) != 0, (a & CLAMP_RIGHT) != 0,
               (a & CLAMP_BOTTOM) != 0, (a & CLAMP_TOP  ) != 0
    end,

    --[[! Function: set_floating ]]
    set_floating = gen_setter "floating",

    --[[! Function: set_visible ]]
    set_visible = gen_setter "visible",

    --[[! Function: set_tooltip ]]
    set_tooltip = gen_setter "tooltip",

    --[[! Function: set_menu ]]
    set_menu = gen_setter "menu",

    --[[! Function: set_container ]]
    set_container = gen_setter "container",

    --[[! Function: set_init_clone ]]
    set_init_clone = gen_setter "init_clone",

    --[[! Function: insert
        Given a position in the children list, a widget and optionally a
        function, this inserts the given widget in the position and calls
        the function with the widget as an argument. Finally, the last
        argument allows you to enforce insertion into the "real" children
        array instead of a custom container (even if it's defined).
    ]]
    insert = function(self, pos, obj, fun, force_ch)
        local children = force_ch and self.children
            or (self.container or self).children
        tinsert(children, pos, obj)
        obj.parent = self
        if fun then fun(obj) end
        return obj
    end,

    --[[! Function: append
        Given a widget and optionally a function, this inserts the given
        widget in the end of the child list and calls the function with the
        widget as an argument. Finally, the last argument allows you to
        enforce insertion into the "real" children array instead of a custom
        container (even if it's defined).
    ]]
    append = function(self, obj, fun, force_ch)
        local children = force_ch and self.children
            or (self.container or self).children
        children[#children + 1] = obj
        obj.parent = self
        if fun then fun(obj) end
        return obj
    end,

    --[[! Function: prepend
        Given a widget and optionally a function, this inserts the given
        widget in the beginning of the child list and calls the function
        with the widget as an argument. Finally, the last argument allows
        you to enforce insertion into the "real" children array instead of
        a custom container (even if it's defined).
    ]]
    prepend = function(self, obj, fun, force_ch)
        local children = force_ch and self.children
            or (self.container or self).children
        tinsert(children, 1, obj)
        obj.parent = self
        if fun then fun(obj) end
        return obj
    end,

    --[[! Function: is_field
        Returns true if this widget is a textual field, by default false.
    ]]
    is_field = function() return false end,

    --[[! Function: get_window
        Gets the window this widget belongs to. Windows return themselves.
        Overlays are windows too.
    ]]
    get_window = function(self)
        if self.type == Window.type then
            return self
        end
        local  w = self.window
        if not w then
            w = self.parent
            while w and w.type != Window.type do
                w = w.parent
            end
            self.window = w
        end
        return w
    end
})

--[[! Struct: Named_Widget
    Named widgets are regular widgets thave have a name under the property
    obj_name. The name can be passed via constructor kwargs as "name".
]]
local Named_Widget = register_class("Named_Widget", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.obj_name = kwargs.name
        return Widget.__init(self, kwargs)
    end,

    --[[! Function: set_obj_name ]]
    set_obj_name = gen_setter "obj_name"
})

--[[! Struct: Tag
    Tags are special named widgets. They can contain more widgets. They're
    particularly useful when looking up certain part of a GUI structure or
    replacing something inside without having to iterate through and finding
    it manually.
]]
local Tag = register_class("Tag", Named_Widget)
M.Tag = Tag

--[[! Struct: Window
    This is a regular window. It's nothing more than a special case of named
    widget. You can derive custom window types from this (see <Overlay>) but
    you have to make sure the widget type stays the same (pass Window.type
    as the last argument to <register_class>).

    This also overloads grabs_input, returning the input_grab property which
    can be set via kwargs or later via set_input_grab. It defaults to true,
    which means it always grabs input, no matter what. If it's false, the
    window lets either the other widgets or the engine control the input
    and you can click, hover etc. in it only in free cursor mode (useful
    for windows that are always shown in say, editing mode).
]]
Window = register_class("Window", Named_Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        local ig = kwargs.input_grab
        self.input_grab = ig == nil and true or ig
        return Named_Widget.__init(self, kwargs)
    end,

    grabs_input = function(self) return self.input_grab end,

    --[[! Function: set_input_grab ]]
    set_input_grab = gen_setter "input_grab"
})
M.Window = Window

--[[! Struct: Overlay
    Overlays are windows that take no input under no circumstances.
    There is no difference otherwise. This overloads grabs_input
    (returns false), target (returns nil), hover (returns nil) and
    click (returns nil).

    There is one default overlay - the HUD. You can retrieve it using
    <get_hud>. Its layout is managed separately, it takes world's
    dimensions. You can freely append into it. It gets cleared
    everytime you leave the map and it doesn't display when
    mainmenu is active.
]]
local Overlay = register_class("Overlay", Window, {
    grabs_input = function(self) return false end,

    target = function() end,
    hover  = function() end,
    click  = function() end
}, Window.type)
M.Overlay = Overlay

--[[! Struct: World
    A world is a structure that derives from <Widget> and holds windows.
    It defines the base for calculating dimensions of child widgets as
    well as input hooks. It also provides some window management functions.
    By default the system creates one default world that holds all the
    primary windows. In the future it will be possible to create new
    worlds for different purposes (e.g. in-game GUI on a surface) but
    that is not supported at this point.

    It adds a property to Widget, margin. It specifies the left/right margin
    compared to the height. For example if the aspect ratio is 16:10, then
    the world width is 1.6 and height is 1 and thus margin is 0.3
    ((1.6 - 1) / 2). If the width is actually lower than the height,
    the margin is 0.
]]
local World = register_class("World", Widget, {
    __init = function(self)
        self.windows = {}
        self.size, self.margin = 0, 0
        self.ss_x, self.ss_y = 1, 1
        self.so_x, self.so_y = 0, 0
        return Widget.__init(self)
    end,

    --[[! Function: grabs_input
        This custom overload loops children (in reverse order) and calls
        grabs_input on each. If any of them returns true, this also returns
        true, otherwise it returns false.
    ]]
    grabs_input = function(self)
        return loop_children_r(self, function(o)
            if o:grabs_input() then return true end
        end) or false
    end,

    --[[! Function: hover
        Without this overload, hover events would propagate into windows
        even if they're covered by other windows, which is not really a
        desirable behavior.
    ]]
    hover = function(self, cx, cy)
        local ch = self.children
        for i = #ch, 1, -1 do
            local o = ch[i]
            local ox = cx - o.x
            local oy = cy - o.y
            if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
                local c  = o:hover(ox, oy)
                if    c == o then
                    hover_x = ox
                    hover_y = oy
                end
                return c
            end
        end
    end,

    --[[! Function: click
        See above, but for click events.
    ]]
    click = function(self, cx, cy)
        local ch = self.children
        for i = #ch, 1, -1 do
            local o = ch[i]
            local ox = cx - o.x
            local oy = cy - o.y
            if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
                local c  = o:click(ox, oy)
                if    c == o then
                    click_x = ox
                    click_y = oy
                end
                return c
            end
        end
    end,

    --[[! Function: layout
        First calls layout on <Widget>, then calculates x, y, w, h of the
        world. Takes forced aspect (via the forceaspect engine variable)
        into consideration. Then adjusts children.
    ]]
    layout = function(self)
        Widget.layout(self)

        local sw, sh = hud_get_w(), hud_get_h()
        self.size = sh
        local faspect = var_get("aspect")
        if faspect != 0 then sw = ceil(sh * faspect) end

        local margin = max((sw/sh - 1) / 2, 0)
        self.x = -margin
        self.y = 0
        self.w = 2 * margin + 1
        self.h = 1
        self.margin = margin

        self:adjust_children()
    end,

    projection = function(self)
        local x, y, w, h in self
        hudmatrix_ortho(x, x + w, y + h, y, -1, 1)
        hudmatrix_reset()
        self.ss_x, self.ss_y = hud_get_ss_x(), hud_get_ss_y()
        self.so_x, self.so_y = hud_get_so_x(), hud_get_so_y()
    end,

    calc_scissor = function(self, x1, y1, x2, y2)
        local hudw, hudh = hud_get_w(), hud_get_h()
        local x, y, w, h, ss_x, ss_y, so_x, so_y in self
        local s1_x, s1_y = (x1 * ss_x + so_x), (y2 * ss_y + so_y)
        local s2_x, s2_y = (x2 * ss_x + so_x), (y1 * ss_y + so_y)
        return clamp(floor(s1_x * hudw), 0, hudw),
               clamp(floor(s1_y * hudh), 0, hudh),
               clamp(ceil (s2_x * hudw), 0, hudw),
               clamp(ceil (s2_y * hudh), 0, hudh)
    end,

    --[[! Function: build_window
        Builds a window. Takes the window name, its widget class and optionally
        a function that's called with the newly created window as an argument.
    ]]
    build_window = function(self, name, win, fun)
        local old = self:find_child(Window.type, name, false)
        if old then self:remove(old) end
        win = win { name = name }
        win.parent = self
        local children = self.children
        children[#children + 1] = win
        if fun then fun(win) end
        return win
    end,

    --[[! Function: new_window
        Creates a window, but doesn't show it. At the time of creation
        the actual window structure is not built, it merely creates a
        callback that builds the window (using <build_window>). Takes
        the same arguments as <build_window>.

        If there already was a window of that name, it returns the old build
        hook. You can call it with no arguments to show the window. If you
        pass true as the sole argument, it returns whether the window is
        currently visible. If you pass false to it, it marks the window
        as invisible/destroyed (without actually hiding anything, unlike
        <hide_window> which destroys it AND marks it). Don't actually rely
        on this, it's only intended for the internals.
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

    --[[! Function: show_window
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

    --[[! Function: get_window
        Returns the window build hook (the same one <show_window> calls).
    ]]
    get_window = function(self, name)
        return self.windows[name]
    end,

    --[[! Function: hide_window
        Hides a window - that is, destroys it. It can be re-built anytime
        later. Returns true if it actually destroyed anything, false otherwise.
        It works by finding the window first and then calling self:remove(old).
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

    --[[! Function: replace_in_window
        Given a window name, a tag name, a widget and a function, this
        finds a window of that name (if it doesn't exist it returns false)
        in the children and then returns win:replace(tname, obj, fun). It's
        merely a little wrapper for convenience.
    ]]
    replace_in_window = function(self, wname, tname, obj, fun)
        local win = self:find_child(Window.type, wname, false)
        if not win then return false end
        return win:replace(tname, obj, fun)
    end,

    --[[! Function: window_visible
        Given a window name, returns true if that window is currently shown
        and false otherwise.
    ]]
    window_visible = function(self, name)
        return self.windows[name](true)
    end
})

world = World()

local hud = Overlay { name = "hud" }
hud.layout = function(self)
    Widget.layout(self)
    self.x, self.y, self.w, self.h = world.x, world.y, world.w, world.h
    self:adjust_children()
end

--[[! Function: get_hud
    Returns the HUD overlay.
]]
M.get_hud = function()
    return hud
end

--[[! Variable: uisensitivity
    An engine variable specifying the mouse cursor sensitivity. Ranges from
    0.001 to 1000 and defaults to 1.
]]
cs.var_new_checked("uisensitivity", cs.var_type.float, 0.0001, 1, 10000,
    cs.var_flags.PERSIST)

local cursor_mode = function()
    return var_get("editing") == 0 and var_get("freecursor")
        or var_get("freeeditcursor")
end

set_external("cursor_move", function(dx, dy)
    local cmode = cursor_mode()
    if cmode == 2 or (world:grabs_input() and cmode >= 1) then
        local uisens = var_get("uisensitivity")
        local hudw, hudh = hud_get_w(), hud_get_h()
        cursor_x = clamp(cursor_x + dx * uisens / hudw, 0, 1)
        cursor_y = clamp(cursor_y + dy * uisens / hudh, 0, 1)
        if cmode == 2 then
            if cursor_x != 1 and cursor_x != 0 then dx = 0 end
            if cursor_y != 1 and cursor_y != 0 then dy = 0 end
            return false, dx, dy
        end
        return true, dx, dy
    end
    return false, dx, dy
end)

local cursor_exists = function(draw)
    if draw and cursor_mode() == 2 then return true end
    local w = world
    if w:grabs_input() or w:target(cursor_x * w.w, cursor_y * w.h) then
        return true
    end
    return false
end
set_external("cursor_exists", cursor_exists)

set_external("cursor_get_position", function()
    local cmode = cursor_mode()
    if cmode == 2 or (world:grabs_input() and cmode >= 1) then
        return cursor_x, cursor_y
    else
        return 0.5, 0.5
    end
end)

local menustack = {}

local menu_click = function(o, cx, cy)
    cx = cx - world.margin
    local ox, oy = cx - o.x, cy - o.y
    if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
        local cl = o:click(ox, oy)
        if cl == o then click_x, click_y = ox, oy end
        return true, cl
    else
        return false
    end
end

local menu_hover = function(o, cx, cy)
    cx = cx - world.margin
    local ox, oy = cx - o.x, cy - o.y
    if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
        local cl = o:hover(ox, oy)
        if cl == o then hover_x, hover_y = ox, oy end
        return true, cl
    else
        return false
    end
end

local tremove = table.remove
local menus_drop = function(n)
    local msl = #menustack
    n = n or msl
    for i = msl, msl - n + 1, -1 do
        local o = tremove(menustack)
        o.parent.has_menu = false
    end
end

set_external("input_keypress", function(code, isdown)
    if not cursor_exists() or not world.visible then return false end
    if world:key_raw(code, isdown) then return true end
    if code == key.MOUSE5 or code == key.MOUSE4 or
       code == key.LEFT   or code == key.RIGHT  or
       code == key.DOWN   or code == key.UP
    then
        if (focused  and  focused:key_hover(code, isdown)) or
           (hovering and hovering:key_hover(code, isdown))
        then return true end
        return false
    elseif code == key.MOUSE1 then
        if isdown then
            local cx, cy = cursor_x * world.w, cursor_y * world.h
            local clicked_try
            local ck, cl
            if #menustack > 0 then
                for i = #menustack, 1, -1 do
                    ck, cl = menu_click(menustack[i], cx, cy)
                    if ck then
                        clicked_try = cl
                        break
                    end
                end
                if not ck then menus_drop() end
            end
            if ck then
                clicked = clicked_try
            else
                clicked = world:click(cx, cy)
            end
            if clicked then
                if not ck then
                    local cm = clicked.menu
                    if cm then
                        menustack[1] = cm
                        cm.is_menu = true
                        cm.parent = clicked
                        clicked.has_menu = true
                    end
                end
                clicked:clicked(click_x, click_y)
            end
        else
            clicked = nil
        end
        return true
    end

    return world:key(code, isdown)
end)

set_external("input_text", function(str)
    return world:text_input(str)
end)

local draw_hud = false

set_external("gui_clear", function()
    if  var_get("mainmenu") != 0 and isconnected() then
        var_set("mainmenu", 0, true, false) -- no clamping, readonly var
        world:destroy_children()
        if draw_hud then
            hud:destroy_children()
            draw_hud = false
        end
    end
end)

set_external("gui_visible", function(wname)
    return world:window_visible(wname)
end)

set_external("gui_update", function()
    local i = 1
    while true do
        if i > #update_later then break end
        local ul = update_later[i]
        local first = ul[1]
        local t = type(first)
        if t == "string" then
            var_set(first, ul[2])
        elseif t == "function" then
            first(unpack(ul, 2))
        else
            emit(first, ul[2], unpack(ul, 3))
        end
        i = i + 1
    end
    update_later = {}

    local mm = var_get("mainmenu")

    if mm != 0 and not world:window_visible("main") and
    not isconnected(true) then
        world:show_window("main")
    end

    if not draw_hud and mm == 0 then draw_hud = true end
    if draw_hud then draw_hud = hud.visible end

    local wvisible = world.visible

    local nhov = 0
    if cursor_exists() and wvisible then
        local w, h = world.w, world.h
        local cx, cy = cursor_x * w, cursor_y * h
        local hovering_try
        local hk, hl
        if #menustack > 0 then
            for i = #menustack, 1, -1 do
                hk, hl = menu_hover(menustack[i], cx, cy)
                if hk then
                    hovering_try = hl
                    if hl then nhov = i end
                    break
                end
            end
        end
        if hk then
            hovering = hovering_try
        else
            hovering = world:hover(cx, cy)
        end
        if  hovering then
            hovering:hovering(hover_x, hover_y)
        end

        -- hacky
        if  clicked then
            clicked:pressing((cursor_x - prev_cx) * w, (cursor_y - prev_cy))
        end
    else
        hovering, clicked = nil, nil
    end

    if wvisible then world:layout() end

    local msl = #menustack
    if hovering then
        local tooltip = hovering.tooltip
        if    tooltip then
              tooltip.parent = hovering
              tooltip:layout()
              tooltip:adjust_children()
        end
        if msl > 0 then
            if nhov > 0 then
                local nd = msl - nhov
                if nd > 0 then menus_drop(nd) end
                msl = nhov
            end
            local hmenu = hovering.menu
            if  hmenu then
                hmenu.is_menu = true
                hmenu.parent = hovering
                if nhov > 0 then
                    msl += 1
                else
                    menus_drop()
                    msl = 1
                end
                menustack[msl] = hmenu
                hovering.has_menu = true
            end
        end
    end

    if msl > 0 then
        for i = 1, msl do
            menustack[i]:layout()
            menustack[i]:adjust_children()
        end
    end

    if draw_hud then hud:layout() end

    prev_cx, prev_cy = cursor_x, cursor_y
end)

set_external("gui_render", function()
    local w = world
    if draw_hud or (w.visible and #w.children != 0) then
        w:projection()
        shader_hud_set()

        gl_blend_enable()
        gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

        gle_color3f(1, 1, 1)
        w:draw()

        local msl = #menustack
        if msl > 0 then
            local prevo
            local md = 1 + w.margin
            for i = 1, msl do
                local o = menustack[i]
                local op = o.parent
                op.has_menu = true
                local ow, opw = o.w, op.w
                local omx, omy = op.x, op.y
                local opp = op.parent
                while opp and (i == 1 or opp != prevo) do
                    omx, omy, opp = omx + opp.x, omy + opp.y, opp.parent
                end
                if i != 1 then
                    omx, omy = omx + opp.x, omy + opp.y
                    local oh = o.h
                    if omy + oh > 1 then
                        omy -= oh - op.h
                    end
                    if (omx + opw + ow) > md then
                        omx -= opw
                    else
                        omx += opw
                    end
                else
                    local oh, oph = o.h, op.h
                    if omy + oph + oh > 1 then
                        omy -= oh
                    else
                        omy += oph
                    end
                    if (omx + ow) > md then
                        if (omx + opw) > md then
                            omx = md - ow
                        else
                            omx -= ow - opw
                        end
                    end
                end
                if (omx + ow) > md then
                    omx -= ow
                end
                o.x, o.y = omx, omy
                o:draw(omx, omy)
                prevo = o
            end
        end

        local tooltip = hovering and hovering.tooltip
        if    tooltip then
            local margin = w.margin
            local left, right = -margin, 1 + 2 * margin
            local x, y = left + cursor_x * right + 0.01, cursor_y + 0.01

            local tw, th = tooltip.w, tooltip.h
            if (x + tw * 0.95) > (right - margin) then
                x = x - tw + 0.02
                if x <= -margin then x = -margin + 0.02 end
            end
            if (y + th * 0.95) > 1 then
                y = y - th + 0.02
                if y < 0 then y = 0 end
            end

            tooltip:draw(x, y)
        end

        if draw_hud then
            hud:draw()
        end

        gl_blend_disable()
        gl_scissor_disable()
        gle_disable()
    end
end)

local needsapply = {}

--[[! Variable: applydialog
    An engine variable that controls whether the "apply" dialog will show
    on changes that need restart of some engine subsystem. Defaults to 1.
]]
cs.var_new_checked("applydialog", cs.var_type.int, 0, 1, 1,
    cs.var_flags.PERSIST)

set_external("change_add", function(desc, ctype)
    if var_get("applydialog") == 0 then return nil end

    for i, v in pairs(needsapply) do
        if v.desc == desc then return nil end
    end

    needsapply[#needsapply + 1] = { ctype = ctype, desc = desc }
    local win = world:get_window("changes")
    if win then win() end
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
        update_later[#update_later + 1] = { cs.execute, "resetgl" }
    end

    if (changetypes & CHANGE_SOUND) != 0 then
        update_later[#update_later + 1] = { cs.execute, "resetsound" }
    end

    if (changetypes & CHANGE_SHADERS) != 0 then
        update_later[#update_later + 1] = { cs.execute, "resetshaders" }
    end
end

M.changes_get = function()
    return table2.map(needsapply, function(v) return v.desc end)
end

--[[! Function: get_world
    Gets the default GUI world widget.
]]
M.get_world = function()
    return world
end

return M
