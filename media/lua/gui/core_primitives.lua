--[[! File: lua/gui/core_widgets.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Primitive widgets - rectangles, images, labels...
]]

local model = require("core.engine.model")
local var = require("core.lua.var")
local signal = require("core.events.signal")

local var_get = var.get

local band  = math.band
local bor   = math.bor
local bnot  = math.bnot
local blsh  = math.lsh
local brsh  = math.rsh
local max   = math.max
local min   = math.min
local abs   = math.abs
local clamp = math.clamp
local floor = math.floor
local ceil  = math.ceil
local _C    = _G["_C"]
local emit  = signal.emit

local M = require("gui.core")
local world = M.get_world()

-- consts
local gl = M.gl

-- widget types
local register_class = M.register_class

-- scissoring
local clip_area_scissor = M.clip_area_scissor
local clip_push, clip_pop = M.clip_push, M.clip_pop

-- primitive drawing
local quad, quadtri = M.draw_quad, M.draw_quadtri

-- base widgets
local Object = M.get_class("Object")

-- setters
local gen_setter = M.gen_setter

local Filler = M.Filler

--[[! Struct: Rectangle
    Derived from <Filler>. Represents a regular rectangle. Has properties
    r (red, 0-255), g (green, 0-255), b (blue, 0-255), a (alpha, 0-255)
    and solid, which is a boolean value specifying whether the rectangle
    is solid - that is, if it's just a regular color fill or whether it
    modulates the color of the thing underneath. The color/alpha values
    defautl to 255, solid defaults to true.
]]
M.Rectangle = register_class("Rectangle", Filler, {
    __init = function(self, kwargs)
        kwargs       = kwargs or {}
        self.solid = kwargs.solid == false and false or true
        self.r     = kwargs.r or 255
        self.g     = kwargs.g or 255
        self.b     = kwargs.b or 255
        self.a     = kwargs.a or 255

        return Filler.__init(self, kwargs)
    end,

    --[[! Function: target
        Rectangles are targetable.
    ]]
    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw = function(self, sx, sy)
        local w, h, solid = self.w, self.h, self.solid

        if not solid then _C.gl_blend_func(gl.ZERO, gl.SRC_COLOR) end
        _C.shader_hudnotexture_set()
        _C.gle_color4ub(self.r, self.g, self.b, self.a)

        _C.gle_defvertex(2)
        _C.gle_begin(gl.TRIANGLE_STRIP)

        _C.gle_attrib2f(sx,     sy)
        _C.gle_attrib2f(sx + w, sy)
        _C.gle_attrib2f(sx,     sy + h)
        _C.gle_attrib2f(sx + w, sy + h)

        _C.gle_end()
        _C.gle_color4f(1, 1, 1, 1)
        _C.shader_hud_set()
        if not solid then
            _C.gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        end

        return Filler.draw(self, sx, sy)
    end,

    --[[! Function: set_solid ]]
    set_solid = gen_setter "solid",

    --[[! Function: set_r ]]
    set_r = gen_setter "r",

    --[[! Function: set_g ]]
    set_g = gen_setter "g",

    --[[! Function: set_b ]]
    set_b = gen_setter "b",

    --[[! Function: set_a ]]
    set_a = gen_setter "a"
})

local check_alpha_mask = function(tex, x, y)
    if not tex:get_alphamask() then
        _C.texture_load_alpha_mask(tex)
        if not tex:get_alphamask() then
            return true
        end
    end

    local xs, ys = tex:get_xs(), tex:get_ys()
    local tx, ty = clamp(floor(x * xs), 0, xs - 1),
                   clamp(floor(y * ys), 0, ys - 1)

    local m = tex:get_alphamask(ty * ((xs + 7) / 8))
    if band(m, blsh(1, tx % 8)) ~= 0 then
        return true
    end

    return false
end

--[[! Struct: Image
    Derived from Filler. Represents a basic image with basic stretching.
    Has two kwargs properties - file (the filename), alt_file (alternative
    filename assuming file fails) - those are not saved in the object and
    six other properties - min_filter, mag_filter (see GL_TEXTURE_MIN_FILTER
    and GL_TEXTURE_MAG_FILTER as well as the filters later in this module),
    r, g, b, a (see <Rectangle>).

    Negative min_w and min_h values are in pixels.

    Images are basically containers for texture objects. Texture objects
    are low-level and documented elsewhere.
]]
local Image = register_class("Image", Filler, {
    __init = function(self, kwargs)
        kwargs    = kwargs or {}
        local tex = kwargs.file and _C.texture_load(kwargs.file)

        local af = kwargs.alt_file
        if (not tex or _C.texture_is_notexture(tex)) and af then
            tex = _C.texture_load(af)
        end

        self.texture = tex or _C.texture_get_notexture()
        self.min_filter = kwargs.min_filter
        self.mag_filter = kwargs.mag_filter

        self.r = kwargs.r or 255
        self.g = kwargs.g or 255
        self.b = kwargs.b or 255
        self.a = kwargs.a or 255

        return Filler.__init(self, kwargs)
    end,

    --[[! Function: get_tex
        Returns the loaded texture filename.
    ]]
    get_tex = function(self)
        return self.texture:get_name()
    end,

    --[[! Function: set_tex
        Given the filename and an alternative filename, this reloads the
        texture this holds.
    ]]
    set_tex = function(self, file, alt)
        local tex = _C.texture_load(file)
        if _C.texture_is_notexture(tex) and alt then
              tex = _C.texture_load(alt)
        end
        self.texture = tex
    end,

    --[[! Function: target
        Images are normally targetable (they're not only where they're
        completely transparent).
    ]]
    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture
        return (tex:get_bpp() < 32 or check_alpha_mask(tex, cx / self.w,
                                                      cy / self.h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.r, self.g, self.b, self.a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.w, self.h)
        _C.gle_end()

        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local min_w = self.min_w
        local min_h = self.min_h

        if  min_w < 0 then
            min_w = abs(min_w) / var_get("scr_h")
        end
        if  min_h < 0 then
            min_h = abs(min_h) / var_get("scr_h")
        end

        if  min_w == -1 then
            min_w = world.w
        end
        if  min_h == -1 then
            min_h = 1
        end

        if  min_w == 0 or min_h == 0 then
            local tex, scrh = self.texture, var_get("scr_h")
            if  min_w == 0 then
                min_w = tex:get_w() / scrh
            end
            if  min_h == 0 then
                min_h = tex:get_h() / scrh
            end
        end

        self.w = max(self.w, min_w)
        self.h = max(self.h, min_h)
    end,

    --[[! Function: set_min_filter ]]
    set_min_filter = gen_setter "min_filter",

    --[[! Function: set_mag_filter ]]
    set_min_filter = gen_setter "mag_filter",

    --[[! Function: set_r ]]
    set_r = gen_setter "r",

    --[[! Function: set_g ]]
    set_g = gen_setter "g",

    --[[! Function: set_b ]]
    set_b = gen_setter "b",

    --[[! Function: set_a ]]
    set_a = gen_setter "a"
})
M.Image = Image

local get_border_size = function(tex, size, vert)
    if size >= 0 then
        return size
    end

    return abs(n) / (vert and tex:get_ys() or tex:get_xs())
end

--[[! Struct: Cropped_Image
    Deriving from <Image>, this represents a cropped image. It has four
    additional properties, crop_x (the x crop position, defaults to 0),
    crop_y, crop_w (the crop width, defaults to 1), crop_h. With these
    default settings it does not crop. Negative values represent the
    sizes in pixels.
]]
M.Cropped_Image = register_class("Cropped_Image", Image, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        Image.__init(self, kwargs)
        local tex = self.texture

        self.crop_x = get_border_size(tex, kwargs.crop_x or 0, false)
        self.crop_y = get_border_size(tex, kwargs.crop_y or 0, true)
        self.crop_w = get_border_size(tex, kwargs.crop_w or 1, false)
        self.crop_h = get_border_size(tex, kwargs.crop_h or 1, true)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture
        return (tex:get_bpp() < 32 or check_alpha_mask(tex,
            self.crop_x + cx / self.w * self.crop_w,
            self.crop_y + cy / self.h * self.crop_h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.r, self.g, self.b, self.a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.w, self.h,
            self.crop_x, self.crop_y, self.crop_w, self.crop_h)
        _C.gle_end()

        return Object.draw(self, sx, sy)
    end,

    --[[! Function: set_crop_x ]]
    set_crop_x = function(self, cx)
        cx = get_border_size(self.texture, cx, false)
        self.crop_x = cx
        emit(self, "crop_x_changed", cx)
    end,

    --[[! Function: set_crop_y ]]
    set_crop_y = function(self, cy)
        cy = get_border_size(self.texture, cy, true)
        self.crop_y = cy
        emit(self, "crop_y_changed", cy)
    end,

    --[[! Function: set_crop_w ]]
    set_crop_w = function(self, cw)
        cw = get_border_size(self.texture, cw, false)
        self.crop_w = cw
        emit(self, "crop_w_changed", cx)
    end,

    --[[! Function: set_crop_w ]]
    set_crop_h = function(self, ch)
        ch = get_border_size(self.texture, ch, true)
        self.crop_h = ch
        emit(self, "crop_h_changed", ch)
    end
})

--[[! Struct: Stretched_Image
    Derives from <Image> and represents a stretched image type. Regular
    images stretch as well, but this uses better quality (and more expensive)
    computations instead of basic stretching.
]]
M.Stretched_Image = register_class("Stretched_Image", Image, {
    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end
        if self.texture:get_bpp() < 32 then return self end

        local mx, my, mw, mh, pw, ph = 0, 0, self.min_w, self.min_h,
                                             self.w,     self.h

        if     pw <= mw          then mx = cx / pw
        elseif cx <  mw / 2      then mx = cx / mw
        elseif cx >= pw - mw / 2 then mx = 1 - (pw - cx) / mw
        else   mx = 0.5 end

        if     ph <= mh          then my = cy / ph
        elseif cy <  mh / 2      then my = cy / mh
        elseif cy >= ph - mh / 2 then my = 1 - (ph - cy) / mh
        else   my = 0.5 end

        return check_alpha_mask(self.texture, mx, my) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.r, self.g, self.b, self.a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.QUADS)

        local mw, mh, pw, ph = self.min_w, self.min_h, self.w, self.h

        local splitw = (mw ~= 0 and min(mw, pw) or pw) / 2
        local splith = (mh ~= 0 and min(mh, ph) or ph) / 2
        local vy, ty = sy, 0

        for i = 1, 3 do
            local vh, th = 0, 0
            if i == 1 then
                if splith < ph - splith then
                    vh, th = splith, 0.5
                else
                    vh, th = ph, 1
                end
            elseif i == 2 then
                vh, th = ph - 2 * splith, 0
            elseif i == 3 then
                vh, th = splith, 0.5
            end

            local vx, tx = sx, 0

            for j = 1, 3 do
                local vw, tw = 0, 0
                if j == 1 then
                    if splitw < pw - splitw then
                        vw, tw = splitw, 0.5
                    else
                        vw, tw = pw, 1
                    end
                elseif j == 2 then
                    vw, tw = pw - 2 * splitw, 0
                elseif j == 3 then
                    vw, tw = splitw, 0.5
                end
                quad(vx, vy, vw, vh, tx, ty, tw, th)
                vx, tx = vx + vw, tx + tw
                if  tx >= 1 then break end
            end
            vy, ty = vy + vh, ty + th
            if  ty >= 1 then break end
        end

        _C.gle_end()

        return Object.draw(self, sx, sy)
    end
})

--[[! Struct: Bordered_Image
    Derives from <Image>. Turns the provided image into a border or a frame.
    There are two properties, screen_border - this one determines the border
    size and tex_border - this one determines a texture offset from which
    to create the borders. Use a <Spacer> with screen_border as padding to
    offset the children away from the border. Without any children, this
    renders only the corners. Negative tex_border represents the value in
    pixels.
]]
M.Bordered_Image = register_class("Bordered_Image", Image, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        Image.__init(self, kwargs)
        self.tex_border = get_border_size(self.texture, kwargs.tex_border or 0)
        self.screen_border = kwargs.screen_border or 0
    end,

    layout = function(self)
        Object.layout(self)

        local sb = self.screen_border
        self.w = max(self.w, 2 * sb)
        self.h = max(self.h, 2 * sb)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture

        if tex:get_bpp() < 32 then
            return self
        end

        local mx, my, tb, sb = 0, 0, self.tex_border, self.screen_border
        local pw, ph = self.w, self.h

        if     cx <  sb      then mx = cx / sb * tb
        elseif cx >= pw - sb then mx = 1 - tb + (cx - (pw - sb)) / sb * tb
        else   mx = tb + (cx - sb) / (pw - 2 * sb) * (1 - 2 * tb) end

        if     cy <  sb      then my = cy / sb * tb
        elseif cy >= ph - sb then my = 1 - tb + (cy - (ph - sb)) / sb * tb
        else   my = tb + (cy - sb) / (ph - 2 * sb) * (1 - 2 * tb) end

        return check_alpha_mask(tex, mx, my) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.r, self.g, self.b, self.a)

        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gle_begin(gl.QUADS)

        local vy, ty = sy, 0
        for i = 1, 3 do
            local vh, th = 0, 0
            if i == 2 then
                vh, th = self.h - 2 * sb, 1 - 2 * tb
            else
                vh, th = sb, tb
            end
            local vx, tx = sx, 0
            for j = 1, 3 do
                local vw, tw = 0, 0
                if j == 2 then
                    vw, tw = self.w - 2 * sb, 1 - 2 * tb
                else
                    vw, tw = sb, tb
                end
                quad(vx, vy, vw, vh, tx, ty, tw, th)
                vx, tx = vx + vw, tx + tw
            end
            vy, ty = vy + vh, ty + th
        end

        _C.gle_end()

        return Object.draw(self, sx, sy)
    end,

    --[[! Function: set_tex_border ]]
    set_tex_border = function(self, tb)
        tb = get_border_size(self.texture, tb)
        self.tex_border = tb
        emit(self, "tex_border_changed", tb)
    end,

    --[[! Function: set_screen_border ]]
    set_screen_border = gen_setter "screen_border"
})

--[[! Struct: Tiled_Image
    Derived from Image. Represents a tiled image with the tile_w and tile_h
    properties specifying the tile width and height (they both default to 1).
]]
local Tiled_Image = register_class("Tiled_Image", Image, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.tile_w = kwargs.tile_w or 1
        self.tile_h = kwargs.tile_h or 1

        return Image.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture

        if tex:get_bpp() < 32 then return self end

        local tw, th = self.tile_w, self.tile_h
        local dx, dy = cx % tw, cy % th

        return check_alpha_mask(tex, dx / tw, dy / th) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture

        _C.shader_hud_set_variant(tex)
        _C.gl_bind_texture(tex)

        if minf and minf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            _C.gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        _C.gle_color4ub(self.r, self.g, self.b, self.a)

        local pw, ph, tw, th = self.w, self.h, self.tile_w, self.tile_h

        -- we cannot use the built in OpenGL texture
        -- repeat with clamped textures
        if tex:get_clamp() ~= 0 then
            local dx, dy = 0, 0
            _C.gle_defvertex(2)
            _C.gle_deftexcoord0(2)
            _C.gle_begin(gl.QUADS)
            while dx < pw do
                while dy < ph do
                    local dw, dh = min(tw, pw - dx), min(th, ph - dy)
                    quad(sx + dx, sy + dy, dw, dh, 0, 0, dw / tw, dh / th)
                    dy = dy + th
                end
                dx, dy = dy + tw, 0
            end
            _C.gle_end()
        else
            _C.gle_defvertex(2)
            _C.gle_deftexcoord0(2)
            _C.gle_begin(gl.TRIANGLE_STRIP)
            quadtri(sx, sy, pw, ph, 0, 0, pw / tw, ph / th)
            _C.gle_end()
        end

        return Object.draw(self, sx, sy)
    end,

    --[[! Function: set_tile_w ]]
    set_tile_w = gen_setter "tile_w",

    --[[! Function: set_tile_h ]]
    set_tile_h = gen_setter "tile_h"
})

--[[! Struct: Thumbnail
    Derived from Image. Represents a thumbnail. You can't supply an alt
    image via kwargs, you can supply the other stuff. A thumbnail's default
    texture is notexture and the delay between loads of different
    thumbnails is defined using the "thumbtime" engine variable which
    defaults to 25 milliseconds. If the thumbnail is requested (by
    targeting it), it loads immediately.
]]
M.Thumbnail = register_class("Thumbnail", Image, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.file = kwargs.file
        self.texture = kwargs.fallback and _C.texture_load(kwargs.fallback)
            or _C.texture_get_notexture()

        self.min_filter = kwargs.min_filter
        self.mag_filter = kwargs.mag_filter

        self.r = kwargs.r or 255
        self.g = kwargs.g or 255
        self.b = kwargs.b or 255
        self.a = kwargs.a or 255

        return Filler.__init(self, kwargs)
    end,

    load = function(self, force)
        if self.loaded then return nil end
        local tex = _C.thumbnail_load(self.file, force)
        if tex then
            self.loaded = true
            self.texture = tex
        end
    end,

    --[[! Function: target
        Unlike the regular target in <Image>, this force-loads the thumbnail
        texture and then targets.
    ]]
    target = function(self, cx, cy)
        self:load(true)
        return Image.target(self, cx, cy)
    end,

    --[[! Function: draw
        Before drawing, this tries to load the thumbnail, but without forcing
        it like <target>.
    ]]
    draw = function(self, sx, sy)
        self:load()
        return Image.target(self, sx, sy)
    end,

    --[[! Function: set_r ]]
    set_r = gen_setter "r",

    --[[! Function: set_g ]]
    set_g = gen_setter "g",

    --[[! Function: set_b ]]
    set_b = gen_setter "b",

    --[[! Function: set_a ]]
    set_a = gen_setter "a",

    --[[! Function: set_fallback
        Loads the fallback texture. If the thumbnail is already loaded,
        doesn't do anything.
    ]]
    set_fallback = function(self, fallback)
        if self.loaded then return nil end
        if fallback then self.texture = _C.texture_load(fallback) end
    end
})

--[[! Struct: Slot_Viewer
    Derived from <Filler>. Represents a texture slot thumbnail, for example
    in a texture selector. Has one property, slot, which is the texture slot
    id. Regular thumbnail rules and delays are followed like in <Thumbnail>.
]]
M.Slot_Viewer = register_class("Slot_Viewer", Filler, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.slot = kwargs.slot or 0

        return Filler.__init(self, kwargs)
    end,

    --[[! Function: target
        Slot viewers are targetable assuming the slot exists.
    ]]
    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o or not _C.slot_exists(self.slot) then return o end
        return _C.slot_check_vslot(self.slot) and self or nil
    end,

    draw = function(self, sx, sy)
        _C.texture_draw_slot(self.slot, self.w, self.h, sx, sy)
        return Object.draw(self, sx, sy)
    end,

    --[[! Function: set_slot ]]
    set_slot = gen_setter "slot"
})

--[[! Struct: Model_Viewer
    Derived from <Filler>. Represents a 3D model preview. Has several
    properties, the most important being model, which is the model path
    (identical to mapmodel paths). Another property is anim, which is
    a model animation represented as an integer (see the model and
    animation API) - you only provide a primary and a optionally a
    secondary animation, the widget takes care of looping. The third
    property is attachments. It's an array of tag-attachment pairs.
]]
M.Model_Viewer = register_class("Model_Viewer", Filler, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.model = kwargs.model

        local a = kwargs.anim
        local aprim = bor(band(a, model.anims.INDEX), model.anims.LOOP)
        local asec  = band(brsh(a, 8), model.anims.INDEX)
        if asec ~= 0 then asec = bor(asec, model.anims.LOOP) end

        self.anim = bor(aprim, blsh(asec, model.anims.SECONDARY))
        self.attachments = kwargs.attachments or {}

        return Filler.__init(self, kwargs)
    end,

    draw = function(self, sx, sy)
        _C.gl_blend_disable()
        local csl = #clip_stack > 0
        if csl then _C.gl_scissor_disable() end

        local screenw, ww, ws = var_get("scr_w"), world.w, world.size
        local w, h = self.w, self.h

        local x = floor((sx + world.margin) * screenw / ww)
        local dx = ceil(w * screenw / ww)
        local y  = ceil((1 - (h + sy)) * ws)
        local dy = ceil(h * ws)

        _C.gle_disable()
        _C.model_preview_start(x, y, dx, dy, csl)
        _C.model_preview(self.model, self.anim, self.attachments)
        if csl then clip_area_scissor() end
        _C.model_preview_end()

        _C.shader_hud_set()
        _C.gle_defvertex(2)
        _C.gle_deftexcoord0(2)
        _C.gl_blend_enable()
        if csl then _C.gl_scissor_enable() end
        return Object.draw(self, sx, sy)
    end,

    --[[! Function: set_model ]]
    set_model = gen_setter "model",

    --[[! Function: set_anim ]]
    set_anim = gen_setter "anim",

    --[[! Function: set_attachments ]]
    set_attachments = gen_setter "attachments"
})

--[[! Variable: uitextrows
    Specifies how many rows of text of scale 1 can fit on the screen. Defaults
    to 40. You can change this to tweak the font scale and thus the whole UI
    scale.
]]
var.new("uitextrows", var.INT, 1, 40, 200, var.PERSIST)

--[[! Struct: Label
    A regular label. Has several properties - text (the label, a string),
    scale (the scale, defaults to 1, which is the base scale), wrap (text
    wrapping, defaults to -1 - not wrapped, otherwis a size), r, g, b, a
    (see <Rectangle> for these).
]]
M.Label = register_class("Label", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.text  = kwargs.text  or ""
        self.scale = kwargs.scale or  1
        self.wrap  = kwargs.wrap  or -1
        self.r     = kwargs.r or 255
        self.g     = kwargs.g or 255
        self.b     = kwargs.b or 255
        self.a     = kwargs.a or 255

        return Object.__init(self, kwargs)
    end,

    --[[! Function: target
        Labels are always targetable.
    ]]
    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw_scale = function(self)
        return self.scale / (var_get("fonth") * var_get("uitextrows"))
    end,

    draw = function(self, sx, sy)
        _C.hudmatrix_push()

        local k = self:draw_scale()
        _C.hudmatrix_scale(k, k, 1)
        _C.hudmatrix_flush()

        local w = self.wrap
        _C.text_draw(self.text, sx / k, sy / k,
            self.r, self.g, self.b, self.a, -1, w <= 0 and -1 or w / k)

        _C.gle_color4f(1, 1, 1, 1)
        _C.hudmatrix_pop()

        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local k = self:draw_scale()

        local w, h = _C.text_get_bounds(self.text,
            self.wrap <= 0 and -1 or self.wrap / k)

        if self.wrap <= 0 then
            self.w = max(self.w, w * k)
        else
            self.w = max(self.w, min(self.wrap, w * k))
        end

        self.h = max(self.h, h * k)
    end,

    --[[! Function: set_text ]]
    set_text = gen_setter "text",

    --[[! Function: set_scale ]]
    set_scale = gen_setter "scale",

    --[[! Function: set_wrap ]]
    set_wrap = gen_setter "wrap",

    --[[! Function: set_r ]]
    set_r = gen_setter "r",

    --[[! Function: set_g ]]
    set_g = gen_setter "g",

    --[[! Function: set_b ]]
    set_b = gen_setter "b",

    --[[! Function: set_a ]]
    set_a = gen_setter "a"
})

--[[! Struct: Eval_Label
    See <Label>. Instead of the property "text", there is "func", which is
    a callable value that returns the text to display.
]]
M.Eval_Label = register_class("Eval_Label", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.func  = kwargs.func  or nil
        self.scale = kwargs.scale or  1
        self.wrap  = kwargs.wrap  or -1
        self.r     = kwargs.r or 255
        self.g     = kwargs.g or 255
        self.b     = kwargs.b or 255
        self.a     = kwargs.a or 255

        return Object.__init(self, kwargs)
    end,

    --[[! Function: target
        Labels are always targetable.
    ]]
    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw_scale = function(self)
        return self.scale / (var_get("fonth") * var_get("uitextrows"))
    end,

    draw = function(self, sx, sy)
        local  val = self.val_saved
        if not val then return Object.draw(self, sx, sy) end

        local k = self.scale_saved
        _C.hudmatrix_push()
        _C.hudmatrix_scale(k, k, 1)
        _C.hudmatrix_flush()

        local w = self.wrap
        _C.text_draw(val or "", sx / k, sy / k,
            self.r, self.g, self.b, self.a, -1, w <= 0 and -1 or w / k)

        _C.gle_color4f(1, 1, 1, 1)
        _C.hudmatrix_pop()

        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local  cmd = self.func
        if not cmd then return nil end
        local val = cmd()
        self.val_saved = val

        local k = self:draw_scale()
        self.scale_saved = k

        local w, h = _C.text_get_bounds(val or "",
            self.wrap <= 0 and -1 or self.wrap / k)

        if self.wrap <= 0 then
            self.w = max(self.w, w * k)
        else
            self.w = max(self.w, min(self.wrap, w * k))
        end

        self.h = max(self.h, h * k)
    end,

    --[[! Function: set_func ]]
    set_func = gen_setter "func",

    --[[! Function: set_scale ]]
    set_scale = gen_setter "scale",

    --[[! Function: set_wrap ]]
    set_wrap = gen_setter "wrap",

    --[[! Function: set_r ]]
    set_r = gen_setter "r",

    --[[! Function: set_g ]]
    set_g = gen_setter "g",

    --[[! Function: set_b ]]
    set_b = gen_setter "b",

    --[[! Function: set_a ]]
    set_a = gen_setter "a"
})

--[[! Variable: FILTER_LINEAR
    A texture fitler equivalent to GL_LINEAR.
]]
M.FILTER_LINEAR = gl.LINEAR

--[[! Variable: FILTER_LINEAR_MIPMAP_LINAER
    A texture fitler equivalent to GL_LINEAR_MIPMAP_LINEAR.
]]
M.FILTER_LINEAR_MIPMAP_LINEAR = gl.LINEAR_MIPMAP_LINEAR

--[[! Variable: FILTER_LINEAR_MIPMAP_NEAREST
    A texture fitler equivalent to GL_LINEAR_MIPMAP_NEAREST.
]]
M.FILTER_LINEAR_MIPMAP_NEAREST = gl.LINEAR_MIPMAP_NEAREST

--[[! Variable: FILTER_NEAREST
    A texture fitler equivalent to GL_NEAREST.
]]
M.FILTER_NEAREST = gl.NEAREST

--[[! Variable: FILTER_NEAREST_MIPMAP_LINEAR
    A texture fitler equivalent to GL_NEAREST_MIPMAP_LINEAR.
]]
M.FILTER_NEAREST_MIPMAP_LINEAR = gl.NEAREST_MIPMAP_LINEAR

--[[! Variable: FILTER_NEAREST_MIPMAP_NEAREST
    A texture fitler equivalent to GL_NEAREST_MIPMAP_NEAREST.
]]
M.FILTER_NEAREST_MIPMAP_NEAREST = gl.NEAREST_MIPMAP_NEAREST
