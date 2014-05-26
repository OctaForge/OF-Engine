--[[!<
    Various primitive widgets (rectangles, text and others).

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")
local ffi = require("ffi")
local model = require("core.engine.model")
local cs = require("core.engine.cubescript")
local math2 = require("core.lua.math")
local signal = require("core.events.signal")
local geom = require("core.lua.geom")

local gl_blend_func, shader_hudnotexture_set, shader_hud_set, gl_bind_texture,
gl_texture_param, shader_hud_set_variant, gle_begin, gle_end, gle_defvertexf,
gle_deftexcoord0f, gle_color4f, gle_attrib2f, texture_load,
texture_load_alpha_mask, texture_get_notexture, thumbnail_load,
texture_draw_slot, texture_draw_vslot, gl_blend_disable, gl_blend_enable,
gl_scissor_disable, gl_scissor_enable, gle_disable, model_preview_start,
model_preview, model_preview_end, hudmatrix_push, hudmatrix_scale,
hudmatrix_flush, hudmatrix_pop, hudmatrix_translate, text_draw,
text_get_bounds, text_font_push, text_font_pop, text_font_set,
console_render_full, text_font_get_w, text_font_get_h, prefab_preview in capi

local max   = math.max
local min   = math.min
local abs   = math.abs
local clamp = math2.clamp
local floor = math.floor
local ceil  = math.ceil
local huge  = math.huge
local emit  = signal.emit
local tostring = tostring
local type = type

local Vec2 = geom.Vec2
local sincosmod360 = geom.sin_cos_mod_360
local sincos360 = geom.sin_cos_360

local ffi_new = ffi.new

--! Module: core
local M = require("core.gui.core")

-- consts
local gl = M.gl

-- widget types
local register_class = M.register_class

-- primitive drawing
local quad, quadtri = M.draw_quad, M.draw_quadtri

-- color
local Color = M.Color

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

local Filler = M.Filler

local init_color = function(col)
    return col and (type(col) == "number" and Color(col) or col) or Color()
end

local gen_color_setter = function(name)
    local sname = name .. "_changed"
    return function(self, val)
        self[name] = init_color(val)
        emit(self, sname, val)
    end
end

--[[!
    Derived from $Filler. Represents a regular rectangle.

    Properties:
        - color - color of the rectangle, defaults to $Color() - via kwargs
          you can initialize it either via $Color constructor or a hex number
          in format 0xRRGGBB or 0xAARRGGBB.
        - solid - if true, it's a solid color rectangle (default), otherwise
          it modulates the color its background.
]]
M.Color_Filler = register_class("Color_Filler", Filler, {
    __ctor = function(self, kwargs)
        kwargs       = kwargs or {}
        self.solid = kwargs.solid != false and true or false
        self.color = init_color(kwargs.color)

        return Filler.__ctor(self, kwargs)
    end,

    draw = function(self, sx, sy)
        local w, h, color, solid in self

        if not solid then gl_blend_func(gl.ZERO, gl.SRC_COLOR) end
        shader_hudnotexture_set()
        color:init()

        gle_defvertexf(2)
        gle_begin(gl.TRIANGLE_STRIP)

        gle_attrib2f(sx,     sy)
        gle_attrib2f(sx + w, sy)
        gle_attrib2f(sx,     sy + h)
        gle_attrib2f(sx + w, sy + h)

        gle_end()
        gle_color4f(1, 1, 1, 1)
        shader_hud_set()
        if not solid then
            gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        end

        return Filler.draw(self, sx, sy)
    end,

    --! Function: set_solid
    set_solid = gen_setter "solid",

    --! Function: set_color
    set_color = gen_color_setter "color"
})
local Color_Filler = M.Color_Filler

--[[!
    Derived from $Color_Filler.

    Properties:
        - horizontal - by default the gradient is vertical, if this is true
          it's horizontal.
        - color2 - the other color of the gradient.
]]
M.Gradient = register_class("Gradient", Color_Filler, {
    __ctor = function(self, kwargs)
        Color_Filler.__ctor(self, kwargs)
        self.horizontal = kwargs.horizontal
        self.color2 = init_color(kwargs.color2)
    end,

    draw = function(self, sx, sy)
        local w, h, color, color2, solid, horizontal in self

        if not solid then gl_blend_func(gl.ZERO, gl.SRC_COLOR) end
        shader_hudnotexture_set()

        gle_defvertexf(2)
        color.def()
        gle_begin(gl.TRIANGLE_STRIP)

        gle_attrib2f(sx, sy)
        if horizontal then
            color2:attrib()
        else
            color:attrib()
        end
        gle_attrib2f(sx + w, sy)     color:attrib()
        gle_attrib2f(sx,     sy + h) color2:attrib()
        gle_attrib2f(sx + w, sy + h)
        if horizontal then
            color:attrib()
        else
            color2:attrib()
        end

        gle_end()
        shader_hud_set()
        if not solid then
            gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        end

        return Filler.draw(self, sx, sy)
    end,

    --! Function: set_horizontal
    set_horizontal = gen_setter "horizontal",

    --! Function: set_color2
    set_color2 = gen_color_setter "color2"
})

--[[!
    Derived from $Filler. Represents a line.

    Properties:
        - color - see $Color_Filler.
]]
M.Line = register_class("Line", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.color = init_color(kwargs.color)
        return Filler.__ctor(self, kwargs)
    end,

    draw = function(self, sx, sy)
        local color, w, h in self

        shader_hudnotexture_set()
        color:init()
        gle_defvertexf(2)
        gle_begin(gl.LINE_LOOP)
        gle_attrib2f(sx,     sy)
        gle_attrib2f(sx + w, sy + h)
        gle_end()
        gle_color4f(1, 1, 1, 1)
        shader_hud_set()

        return Filler.draw(self, sx, sy)
    end,

    --! Function: set_color
    set_color = gen_color_setter "color"
})

--[[!
    Derived from $Filler. Represents an outline.

    Properties:
        - color - see $Color_Filler.
]]
M.Outline = register_class("Outline", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.color = init_color(kwargs.color)
        return Filler.__ctor(self, kwargs)
    end,

    draw = function(self, sx, sy)
        local color, w, h in self

        shader_hudnotexture_set()
        color:init()
        gle_defvertexf(2)
        gle_begin(gl.LINE_LOOP)
        gle_attrib2f(sx,     sy)
        gle_attrib2f(sx + w, sy)
        gle_attrib2f(sx + w, sy + h)
        gle_attrib2f(sx,     sy + h)
        gle_end()
        gle_color4f(1, 1, 1, 1)
        shader_hud_set()

        return Filler.draw(self, sx, sy)
    end,

    --! Function: set_color
    set_color = gen_color_setter "color"
})

local check_alpha_mask = function(tex, x, y)
    if tex.alphamask == nil then
        if texture_load_alpha_mask(tex) == nil then
            return true
        end
    end

    local xs, ys = tex.xs, tex.ys
    local tx, ty = clamp(floor(x * tex.xs), 0, tex.xs - 1),
                   clamp(floor(y * tex.ys), 0, tex.ys - 1)

    if (tex.alphamask[ty * ((tex.xs + 7) / 8)] & (1 << (tx % 8))) != 0 then
        return true
    end

    return false
end

--[[! Struct: Image
    Derived from $Filler. Represents a basic image with basic stretching.

    Images are basically containers for texture objects. Texture objects
    are low-level and documented elsewhere.

    The file and alt_file properties are not saved in the image.

    Properties:
        - file - filename of the texture.
        - alt_file - alternative filename assuming file fails.
        - min_filter, mag_filter - see GL_TEXTURE_MIN_FILTER and
          GL_TEXTURE_MAG_FILTER as well as filters later in this module.
        - color - see $Color_Filler.
]]
M.Image = register_class("Image", Filler, {
    __ctor = function(self, kwargs)
        kwargs    = kwargs or {}
        local tex = kwargs.file and texture_load(kwargs.file)

        local notexture = texture_get_notexture()
        local af = kwargs.alt_file
        if (not tex or tex == notexture) and af then
            tex = texture_load(af)
        end

        self.texture = tex or notexture
        self.min_filter = kwargs.min_filter
        self.mag_filter = kwargs.mag_filter
        self.color = init_color(kwargs.color)

        return Filler.__ctor(self, kwargs)
    end,

    --!  Returns the loaded texture filename.
    get_tex = function(self)
        return self.texture.name
    end,

    --[[!
        Given the filename and an alternative filename, this reloads the
        texture this holds. If the file argument is nil/false/none, this
        disables the texture (sets the texture to notexture).
    ]]
    set_tex = function(self, file, alt)
        if not file then
            self.texture = texture_get_notexture()
            return
        end
        local tex = texture_load(file)
        if  tex == texture_get_notexture() and alt then
            tex = texture_load(alt)
        end
        self.texture = tex
    end,

    --[[!
        Images are normally targetable (they're not only where they're
        completely transparent). See also {{$Widget.target}}.
    ]]
    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture
        return (tex.bpp < 32 or check_alpha_mask(tex, cx / self.w,
                                                       cy / self.h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture
        local color = self.color

        if tex == texture_get_notexture() then
            return Filler.draw(self, sx, sy)
        end

        shader_hud_set_variant(tex)
        gl_bind_texture(tex.id)

        if minf and minf != 0 then
            gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf != 0 then
            gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        color:init()
        gle_defvertexf(2)
        gle_deftexcoord0f(2)
        gle_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.w, self.h)
        gle_end()

        return Filler.draw(self, sx, sy)
    end,

    layout = function(self)
        Widget.layout(self)

        local min_w = self.min_w
        local min_h = self.min_h
        if type(min_w) == "function" then min_w = min_w(self) end
        if type(min_h) == "function" then min_h = min_h(self) end

        local r = self:get_root()

        if min_w < 0 then min_w = r:get_ui_size(abs(min_w)) end
        if min_h < 0 then min_h = r:get_ui_size(abs(min_h)) end

        local proj = r:get_projection()
        if min_w == huge then min_w = proj.pw end
        if min_h == huge then min_h = proj.ph end

        if  min_w == 0 or min_h == 0 then
            local tex = self.texture
            if min_w == 0 then min_w = r:get_ui_size(tex.w) end
            if min_h == 0 then min_h = r:get_ui_size(tex.h) end
        end

        self._min_w, self._min_h = min_w, min_h
        self.w = max(self.w, min_w)
        self.h = max(self.h, min_h)
    end,

    --! Function: set_min_filter
    set_min_filter = gen_setter "min_filter",

    --! Function: set_mag_filter
    set_min_filter = gen_setter "mag_filter",

    --! Function: set_color
    set_color = gen_color_setter "color"
})
local Image = M.Image

--[[!
    Represents a raw texture. Not meant for regular use. It's here to aid
    some of the internal OF UIs. Has only a subset of $Image's features.
]]
M.Texture = register_class("Texture", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.texture_id = kwargs.texture_id
        return Filler.__ctor(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if    o then return o end
        return self
    end,

    draw = function(self, sx, sy)
        gl_bind_texture(self.texture_id)
        gle_defvertexf(2)
        gle_deftexcoord0f(2)
        gle_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.w, self.h)
        gle_end()
        return Filler.draw(self, sx, sy)
    end,

    layout = function(self)
        Widget.layout(self)

        local min_w = self.min_w
        local min_h = self.min_h
        if type(min_w) == "function" then min_w = min_w(self) end
        if type(min_h) == "function" then min_h = min_h(self) end

        local r = self:get_root()

        if min_w < 0 then min_w = r:get_ui_size(abs(min_w)) end
        if min_h < 0 then min_h = r:get_ui_size(abs(min_h)) end

        local proj = r:get_projection()
        if min_w == huge then min_w = proj.pw end
        if min_h == huge then min_h = proj.ph end

        self.w = max(self.w, min_w)
        self.h = max(self.h, min_h)
    end
})

local get_border_size = function(tex, size, vert)
    if size >= 0 then
        return size
    end
    return abs(n) / (vert and tex.ys or tex.xs)
end

--[[!
    Deriving from $Image, this represents a cropped image. Negative crop
    values are in pixels.

    Properties:
        - crop_x, crop_y - the crop x and y position, they default to 0.
        - crop_w, crop_h - the crop dimensions, they default to 1.
]]
M.Cropped_Image = register_class("Cropped_Image", Image, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}

        Image.__ctor(self, kwargs)
        local tex = self.texture

        self.crop_x = get_border_size(tex, kwargs.crop_x or 0, false)
        self.crop_y = get_border_size(tex, kwargs.crop_y or 0, true)
        self.crop_w = get_border_size(tex, kwargs.crop_w or 1, false)
        self.crop_h = get_border_size(tex, kwargs.crop_h or 1, true)
    end,

    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture
        return (tex.bpp < 32 or check_alpha_mask(tex,
            self.crop_x + cx / self.w * self.crop_w,
            self.crop_y + cy / self.h * self.crop_h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture

        if tex == texture_get_notexture() then
            return Filler.draw(self, sx, sy)
        end

        shader_hud_set_variant(tex)
        gl_bind_texture(tex.id)

        if minf and minf != 0 then
            gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf != 0 then
            gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        self.color:init()

        gle_defvertexf(2)
        gle_deftexcoord0f(2)
        gle_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.w, self.h,
            self.crop_x, self.crop_y, self.crop_w, self.crop_h)
        gle_end()

        return Filler.draw(self, sx, sy)
    end,

    --!
    set_crop_x = function(self, cx)
        cx = get_border_size(self.texture, cx, false)
        self.crop_x = cx
        emit(self, "crop_x_changed", cx)
    end,

    --!
    set_crop_y = function(self, cy)
        cy = get_border_size(self.texture, cy, true)
        self.crop_y = cy
        emit(self, "crop_y_changed", cy)
    end,

    --!
    set_crop_w = function(self, cw)
        cw = get_border_size(self.texture, cw, false)
        self.crop_w = cw
        emit(self, "crop_w_changed", cx)
    end,

    --!
    set_crop_h = function(self, ch)
        ch = get_border_size(self.texture, ch, true)
        self.crop_h = ch
        emit(self, "crop_h_changed", ch)
    end
})

--[[!
    Derives from $Image and represents a stretched image type. Regular
    images stretch as well, but this uses better quality (and more expensive)
    computations instead of basic stretching.
]]
M.Stretched_Image = register_class("Stretched_Image", Image, {
    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if    o then return o end
        if self.texture.bpp < 32 then return self end

        local mx, my, mw, mh, pw, ph = 0, 0, self._min_w, self._min_h,
                                             self.w,      self.h

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

        if tex == texture_get_notexture() then
            return Filler.draw(self, sx, sy)
        end

        shader_hud_set_variant(tex)
        gl_bind_texture(tex.id)

        if minf and minf != 0 then
            gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf != 0 then
            gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        self.color:init()

        gle_defvertexf(2)
        gle_deftexcoord0f(2)
        gle_begin(gl.QUADS)

        local mw, mh, pw, ph = self._min_w, self._min_h, self.w, self.h

        local splitw = (mw != 0 and min(mw, pw) or pw) / 2
        local splith = (mh != 0 and min(mh, ph) or ph) / 2
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

        gle_end()

        return Filler.draw(self, sx, sy)
    end
})

--[[!
    Derives from $Image. Turns the provided image into a border or a frame.
    Use a <Spacer> with screen_border as padding to offset the children away
    from the border. Without any children, this renders only the corners.
    Negative tex_border represents the value in pixels.

    Properties:
        - screen_border - determines the border size.
        - tex_border - determines a texture offset from which to create the
          borders.
]]
M.Bordered_Image = register_class("Bordered_Image", Image, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        Image.__ctor(self, kwargs)
        self.tex_border = get_border_size(self.texture, kwargs.tex_border or 0)
        self.screen_border = kwargs.screen_border or 0
    end,

    layout = function(self)
        Widget.layout(self)

        local sb = self.screen_border
        self.w = max(self.w, 2 * sb)
        self.h = max(self.h, 2 * sb)
    end,

    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture

        if tex.bpp < 32 then
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

        if tex == texture_get_notexture() then
            return Filler.draw(self, sx, sy)
        end

        shader_hud_set_variant(tex)
        gl_bind_texture(tex.id)

        if minf and minf != 0 then
            gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf != 0 then
            gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        self.color:init()

        gle_defvertexf(2)
        gle_deftexcoord0f(2)
        gle_begin(gl.QUADS)

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

        gle_end()

        return Filler.draw(self, sx, sy)
    end,

    --!
    set_tex_border = function(self, tb)
        tb = get_border_size(self.texture, tb)
        self.tex_border = tb
        emit(self, "tex_border_changed", tb)
    end,

    --! Function: set_screen_border
    set_screen_border = gen_setter "screen_border"
})

--[[!
    Derived from $Image. Represents a tiled image.

    Properties:
        - tile_w, tile_h - tile width and height, they default to 1.
]]
M.Tiled_Image = register_class("Tiled_Image", Image, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}

        self.tile_w = kwargs.tile_w or 1
        self.tile_h = kwargs.tile_h or 1

        return Image.__ctor(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if    o then return o end

        local tex = self.texture

        if tex.bpp < 32 then return self end

        local tw, th = self.tile_w, self.tile_h
        local dx, dy = cx % tw, cy % th

        return check_alpha_mask(tex, dx / tw, dy / th) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.min_filter,
                                self.mag_filter, self.texture

        if tex == texture_get_notexture() then
            return Filler.draw(self, sx, sy)
        end

        shader_hud_set_variant(tex)
        gl_bind_texture(tex.id)

        if minf and minf != 0 then
            gl_texture_param(gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf != 0 then
            gl_texture_param(gl.TEXTURE_MAG_FILTER, magf)
        end

        self.color:init()

        local pw, ph, tw, th = self.w, self.h, self.tile_w, self.tile_h

        -- we cannot use the built in OpenGL texture
        -- repeat with clamped textures
        if tex.clamp != 0 then
            local dx, dy = 0, 0
            gle_defvertexf(2)
            gle_deftexcoord0f(2)
            gle_begin(gl.QUADS)
            while dx < pw do
                while dy < ph do
                    local dw, dh = min(tw, pw - dx), min(th, ph - dy)
                    quad(sx + dx, sy + dy, dw, dh, 0, 0, dw / tw, dh / th)
                    dy = dy + th
                end
                dx, dy = dy + tw, 0
            end
            gle_end()
        else
            gle_defvertexf(2)
            gle_deftexcoord0f(2)
            gle_begin(gl.TRIANGLE_STRIP)
            quadtri(sx, sy, pw, ph, 0, 0, pw / tw, ph / th)
            gle_end()
        end

        return Filler.draw(self, sx, sy)
    end,

    --! Function: set_tile_w
    set_tile_w = gen_setter "tile_w",

    --! Function: set_tile_h
    set_tile_h = gen_setter "tile_h"
})

--[[!
    Derived from $Image. Represents a thumbnail. You can't supply an alt
    image via kwargs, you can supply the other stuff. A thumbnail's default
    texture is notexture and the delay between loads of different
    thumbnails is defined using the "thumbtime" engine variable which
    defaults to 25 milliseconds. If the thumbnail is requested (by
    targeting it), it loads immediately.
]]
M.Thumbnail = register_class("Thumbnail", Image, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.file = kwargs.file
        self.texture = kwargs.fallback and texture_load(kwargs.fallback)
            or texture_get_notexture()

        self.min_filter = kwargs.min_filter
        self.mag_filter = kwargs.mag_filter
        self.color = init_color(kwargs.color)

        return Filler.__ctor(self, kwargs)
    end,

    load = function(self, force)
        if self.loaded then return end
        local tex = thumbnail_load(self.file, force)
        if tex != texture_get_notexture() then
            self.loaded = true
            self.texture = tex
        end
    end,

    --[[!
        Unlike the regular target in $Image, this force-loads the thumbnail
        texture and then targets. See also {{$Image.target}}.
    ]]
    target = function(self, cx, cy)
        self:load(true)
        return Image.target(self, cx, cy)
    end,

    --[[!
        Before drawing, this tries to load the thumbnail, but without forcing
        it like $target.
    ]]
    draw = function(self, sx, sy)
        self:load()
        return Image.draw(self, sx, sy)
    end,

    --[[!
        Loads the fallback texture. If the thumbnail is already loaded,
        doesn't do anything.
    ]]
    set_fallback = function(self, fallback)
        if self.loaded then return end
        if fallback then self.texture = texture_load(fallback) end
    end
})

--[[!
    Derived from $Filler. Represents a texture slot thumbnail, for example
    in a texture selector. Regular thumbnail rules and delays are followed
    like in $Thumbnail. See also $VSlot_Viewer.

    Properties:
        - index - the texture slot index (starting with 0, defaults to 0).
]]
M.Slot_Viewer = register_class("Slot_Viewer", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.index = kwargs.index or 0

        return Filler.__ctor(self, kwargs)
    end,

    target = function(self, cx, cy)
        return Widget.target(self, cx, cy) or self
    end,

    draw = function(self, sx, sy)
        texture_draw_slot(self.index, self.w, self.h, sx, sy)
        return Widget.draw(self, sx, sy)
    end,

    --[[! Function: set_index ]]
    set_index = gen_setter "index"
})

--[[!
    Similar to (and derives from) $Slot_Viewer, but previews vslots.
]]
M.VSlot_Viewer = register_class("VSlot_Viewer", M.Slot_Viewer, {
    draw = function(self, sx, sy)
        texture_draw_vslot(self.index, self.w, self.h, sx, sy)
        return Widget.draw(self, sx, sy)
    end
})

--[[!
    Derived from $Filler. Represents a 3D model preview.

    Properties:
        - model - the model name (like mapmodel paths).
        - anim - an integer.
        - attachments - an array of tag-attachment pairs.
]]
M.Model_Viewer = register_class("Model_Viewer", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.model = kwargs.model
        self.anim = kwargs.anim or 0
        self.attachments = kwargs.attachments or {}

        return Filler.__ctor(self, kwargs)
    end,

    -- turn the table into a ffi-friendly array
    build_attachments = function(self)
        local att = self.attachments
        if att == self._last_attachments then
            return self._c_attachments, #att * 2
        end
        local n = #att * 2
        local stor = ffi_new("const char*[?]", n)
        for i = 0, #att - 1 do
            local at = att[i + 1]
            stor[i * 2], stor[i * 2 + 1] = at[1], at[2]
        end
        self._c_attachments = stor
        self._last_attachments = att
        return stor, n
    end,

    draw = function(self, sx, sy)
        local w, h in self
        local csl = #clip_stack > 0
        if csl then gl_scissor_disable() end
        local sx1, sy1, sx2, sy2 = self:get_root():get_projection()
            :calc_scissor(sx, sy, sx + w, sy + h)
        gl_blend_disable()
        gle_disable()
        model_preview_start(sx1, sy1, sx2 - sx1, sy2 - sy1, csl)
        local anim = self.anim
        model_preview(self.model, anim, self:build_attachments())
        if csl then self:get_root():clip_scissor() end
        model_preview_end()
        shader_hud_set()
        gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        gl_blend_enable()
        if csl then gl_scissor_enable() end
        return Widget.draw(self, sx, sy)
    end,

    --! Function: set_model
    set_model = gen_setter "model",

    --! Function: set_anim
    set_anim = gen_setter "anim",

    --! Function: set_attachments
    set_attachments = gen_setter "attachments"
})

--[[!
    Derived from $Filler. Represents a 3D prefab preview.

    Properties:
        - prefab - the prefab name.
        - color - the color (alpha is ignored).
]]
M.Prefab_Viewer = register_class("Prefab_Viewer", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.prefab = kwargs.prefab
        self.color  = init_color(kwargs.color)

        return Filler.__ctor(self, kwargs)
    end,

    draw = function(self, sx, sy)
        local prefab = self.prefab
        if not prefab then return Widget.draw(self, sx, sy) end
        local w, h in self
        local csl = #clip_stack > 0
        if csl then gl_scissor_disable() end
        local sx1, sy1, sx2, sy2 = self:get_root():get_projection()
            :calc_scissor(sx, sy, sx + w, sy + h)
        gl_blend_disable()
        gle_disable()
        model_preview_start(sx1, sy1, sx2 - sx1, sy2 - sy1, csl)
        local col = self.color
        prefab_preview(prefab, col.r / 255, col.g / 255, col.b / 255)
        if csl then self:get_root():clip_scissor() end
        model_preview_end()
        shader_hud_set()
        gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        gl_blend_enable()
        if csl then gl_scissor_enable() end
        return Widget.draw(self, sx, sy)
    end,

    --! Function: set_prefab
    set_prefab = gen_setter "prefab",

    --! Function: set_color
    set_color = gen_color_setter "color"
})

--! A full console widget that derives from $Filler.
M.Console = register_class("Console", Filler, {
    draw_scale = function(self)
        return self:get_root():get_text_scale(true) / text_font_get_h()
    end,

    draw = function(self, sx, sy)
        local k = self:draw_scale()
        hudmatrix_push()
        hudmatrix_translate(sx, sy, 0)
        hudmatrix_scale(k, k, 1)
        hudmatrix_flush()
        console_render_full(self.w / k, self.h / k)
        hudmatrix_pop()
        return Filler.draw(self, sx, sy)
    end
})

local SOLID    = 0
local OUTLINE  = 1
local MODULATE = 2

--[[!
    Represents a generic shape that derives from $Filler.

    Properties:
        - style - can be Shape.SOLID, Shape.OUTLINE, Shape.MODULATE (defaults
          to solid).
        - color - see $Color_Filler.
]]
M.Shape = register_class("Shape", Filler, {
    SOLID    = SOLID,
    OUTLINE  = OUTLINE,
    MODULATE = MODULATE,

    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.style = kwargs.style or 0
        self.color = init_color(kwargs.color)
        return Filler.__ctor(self, kwargs)
    end,

    --! Function: set_style
    set_style = gen_setter "style",

    --! Function: set_color
    set_color = gen_color_setter "color"
})
local Shape = M.Shape

--[[!
    A regular triangle that derives from $Shape.  Its width and height is
    determined by min_w and min_h (same conventions as on $Filler apply).

    Properties:
        - angle - the triangle rotation (in degrees).
]]
M.Triangle = register_class("Triangle", Shape, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.angle = kwargs.angle or 0
        return Shape.__ctor(self, kwargs)
    end,

    layout = function(self)
        Widget.layout(self)

        local w, h = self.min_w, self.min_h
        if type(w) == "function" then w = w(self) end
        if type(h) == "function" then h = h(self) end
        local angle = self.angle
        local r = self:get_root()

        if w < 0 then w = r:get_ui_size(abs(w)) end
        if h < 0 then h = r:get_ui_size(abs(h)) end

        local proj = r:get_projection()
        if w == huge then w = proj.pw end
        if h == huge then h = proj.ph end

        local a = Vec2(0, -h * 2 / 3)
        local b = Vec2(-w / 2, h / 3)
        local c = Vec2( w / 2, h / 3)

        if angle != 0 then
            local rot = sincosmod360(-angle)
            a:rotate_around_z(rot)
            b:rotate_around_z(rot)
            c:rotate_around_z(rot)
        end

        local bbmin = Vec2(a):min(b):min(c)
        a:sub(bbmin)
        b:sub(bbmin)
        c:sub(bbmin)
        local bbmax = Vec2(a):max(b):max(c)

        self.ta, self.tb, self.tc = a, b, c

        self.w = max(self.w, bbmax.x)
        self.h = max(self.h, bbmax.y)
    end,

    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if o then return o end
        if self.style == OUTLINE then return nil end
        local a, b, c = self.ta, self.tb, self.tc
        local side = Vec2(cx, cy):sub(b):cross(Vec2(a):sub(b)) < 0
        return ((Vec2(cx, cy):sub(c):cross(Vec2(b):sub(c)) < 0) == side
            and (Vec2(cx, cy):sub(a):cross(Vec2(c):sub(a)) < 0) == side)
            and self or nil
    end,

    draw = function(self, sx, sy)
        local color, style in self
        if style == MODULATE then gl_blend_func(gl.ZERO, gl.SRC_COLOR) end
        shader_hudnotexture_set()
        color:init()
        gle_defvertexf(2)
        gle_begin(style == OUTLINE and gl.LINE_LOOP or gl.TRIANGLES)
        gle_attrib2f(Vec2(sx, sy):add(self.ta):unpack())
        gle_attrib2f(Vec2(sx, sy):add(self.tb):unpack())
        gle_attrib2f(Vec2(sx, sy):add(self.tc):unpack())
        gle_end()
        gle_color4f(1, 1, 1, 1)
        shader_hud_set()
        if style == MODULATE then
            gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        end
        return Shape.draw(self, sx, sy)
    end,

    --! Function: set_angle
    set_angle = gen_setter "angle"
})

--[[!
    A regular circle that derives from $Shape. Its radius is determined
    by min_w and min_h (same conventions as on $Filler apply when it comes
    to widget bounds and the smaller one is used to determine radius).

    Properties:
        - sides - defaults to 15, specifying the number of sides this circle
          will have (it's not a perfect circle, but rather a polygon).
]]
M.Circle = register_class("Circle", Shape, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.sides = kwargs.sides or 15
        return Shape.__ctor(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Widget.target(self, cx, cy)
        if o then return o end
        if self.style == OUTLINE then return nil end
        local r = min(self.w, self.h)
        return (Vec2(cx, cy):sub(r):squared_len() <= (r * r)) and self or nil
    end,

    draw = function(self, sx, sy)
        local color, style in self
        shader_hudnotexture_set()
        color:init()
        gle_defvertexf(2)
        local radius = min(self.w, self.h) / 2
        local center = Vec2(sx + radius, sy + radius)
        if style == OUTLINE then
            gle_begin(gl.LINE_LOOP)
            for angle = 0, 359, 360 / self.sides do
                gle_attrib2f(sincos360(angle):mul_new(radius)
                    :add(center):unpack())
            end
            gle_end()
        else
            if style == MODULATE then gl_blend_func(gl.ZERO, gl.SRC_COLOR) end
            gle_begin(gl.TRIANGLE_FAN)
            gle_attrib2f(center.x,          center.y)
            gle_attrib2f(center.x + radius, center.y)
            local sides = self.sides
            for angle = (360 / sides), 359, 360 / sides do
                local p = sincos360(angle):mul_new(radius):add(center)
                gle_attrib2f(p:unpack())
                gle_attrib2f(p:unpack())
            end
            gle_attrib2f(center.x + radius, center.y)
            gle_end()
            if style == MODULATE then
                gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
            end
        end
        gle_color4f(1, 1, 1, 1)
        shader_hud_set()
        return Shape.draw(self, sx, sy)
    end,

    --! Function: set_sides
    set_sides = gen_setter "sides"
})

--[[!
    A regular label. If the scale is negative, it uses console text scaling
    multiplier instead of regular one.

    Properties:
         - text - the label.
         - font - the font (optional).
         - scale - the font scale, defaults to 1.
         - wrap - whether to wrap the text, defaults to -1 - not wrapping,
           otherwise it's a number of characters.
         - color - see $Color_Filler.
]]
M.Label = register_class("Label", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}

        self.text  = kwargs.text  or ""
        self.font  = kwargs.font  or nil
        self.scale = kwargs.scale or  1
        self.wrap  = kwargs.wrap  or -1
        self.color = init_color(kwargs.color)

        return Widget.__ctor(self, kwargs)
    end,

    --[[!
        Labels are always targetable. See also {{$Widget.target}}.
    ]]
    target = function(self, cx, cy)
        return Widget.target(self, cx, cy) or self
    end,

    draw_scale = function(self)
        local scale = self.scale
        return (abs(scale) * self:get_root():get_text_scale(scale < 0))
            / text_font_get_h()
    end,

    draw = function(self, sx, sy)
        text_font_push()
        text_font_set(self.font)
        hudmatrix_push()

        local k = self:draw_scale()
        hudmatrix_scale(k, k, 1)
        hudmatrix_flush()

        local w = self.wrap
        local text = tostring(self.text)
        local color = self.color
        text_draw(text, sx / k, sy / k,
            color.r, color.g, color.b, color.a, -1, w <= 0 and -1 or w / k)

        gle_color4f(1, 1, 1, 1)
        hudmatrix_pop()
        text_font_pop()

        return Widget.draw(self, sx, sy)
    end,

    layout = function(self)
        Widget.layout(self)

        text_font_push()
        text_font_set(self.font)
        local k = self:draw_scale()

        local w, h = text_get_bounds(self.text,
            self.wrap <= 0 and -1 or self.wrap / k)

        if self.wrap <= 0 then
            self.w = max(self.w, w * k)
        else
            self.w = max(self.w, min(self.wrap, w * k))
        end

        self.h = max(self.h, h * k)
        text_font_pop()
    end,

    --! Function: set_text
    set_text = gen_setter "text",

    --! Function: set_font
    set_font = gen_setter "font",

    --! Function: set_scale
    set_scale = gen_setter "scale",

    --! Function: set_wrap
    set_wrap = gen_setter "wrap",

    --! Function: set_color
    set_color = gen_color_setter "color"
})

--[[!
    See $Label. Instead of the property "text", there is "func", which is
    a callable value that returns the text to display.
]]
M.Eval_Label = register_class("Eval_Label", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}

        self.func  = kwargs.func  or nil
        self.scale = kwargs.scale or  1
        self.wrap  = kwargs.wrap  or -1
        self.color = init_color(kwargs.color)

        return Widget.__ctor(self, kwargs)
    end,

    target = function(self, cx, cy)
        return Widget.target(self, cx, cy) or self
    end,

    draw_scale = function(self)
        local scale = self.scale
        return (abs(scale) * self:get_root():get_text_scale(scale < 0))
            / text_font_get_h()
    end,

    draw = function(self, sx, sy)
        local  val = self.val_saved
        if not val then return Widget.draw(self, sx, sy) end

        local k = self.scale_saved
        hudmatrix_push()
        hudmatrix_scale(k, k, 1)
        hudmatrix_flush()

        local w = self.wrap
        local text = tostring(val) or ""
        local color = self.color
        text_draw(text, sx / k, sy / k,
            color.r, color.g, color.b, color.a, -1, w <= 0 and -1 or w / k)

        gle_color4f(1, 1, 1, 1)
        hudmatrix_pop()

        return Widget.draw(self, sx, sy)
    end,

    layout = function(self)
        Widget.layout(self)

        local  cmd = self.func
        if not cmd then return end
        local val = cmd(self)
        self.val_saved = val

        local k = self:draw_scale()
        self.scale_saved = k

        local w, h = text_get_bounds(val or "",
            self.wrap <= 0 and -1 or self.wrap / k)

        if self.wrap <= 0 then
            self.w = max(self.w, w * k)
        else
            self.w = max(self.w, min(self.wrap, w * k))
        end

        self.h = max(self.h, h * k)
    end,

    --! Function: set_func
    set_func = gen_setter "func",

    --! Function: set_scale
    set_scale = gen_setter "scale",

    --! Function: set_wrap
    set_wrap = gen_setter "wrap",

    --! Function: set_color
    set_color = gen_color_setter "color"
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
