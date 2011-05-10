--[[!
    File: base/base_shaders.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features shader control functions.

    Section: Shaders
]]

--[[!
    Package: shader
    This module controls shaders, such as their definition, parameters etc., as
    well as postprocessing effects.
]]
module("shader", package.seeall)

--- Standard shader.
-- @param s Shader type.
-- @param n Shader name.
-- @param v Vertex shader.
-- @param f Fragment shader.
-- @class function
-- @name std
std = CAPI.shader

--- Variant shader.
-- @param s Shader type.
-- @param n Shader name.
-- @param r Shader row.
-- @param v Vertex shader.
-- @param f Fragment shader.
-- @class function
-- @name variant
variant = CAPI.variantshader

--- Set global shader.
-- @param n Shader name.
-- @class function
-- @name set
set = CAPI.setshader

--- Set shader param.
-- @param n Name of the shader param.
-- @param x X (defaults to 0)
-- @param y Y (defaults to 0)
-- @param z Z (defaults to 0)
-- @param w W (defaults to 0)
function setp(n, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.setshaderparam(n, x, y, z, w)
end

--- Set vertex param.
-- @param i Param index.
-- @param x X (defaults to 0)
-- @param y Y (defaults to 0)
-- @param z Z (defaults to 0)
-- @param w W (defaults to 0)
function setvp(i, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.setvertexparam(i, x, y, z, w)
end

--- Set pixel param.
-- @param i Param index.
-- @param x X (defaults to 0)
-- @param y Y (defaults to 0)
-- @param z Z (defaults to 0)
-- @param w W (defaults to 0)
function setpp(i, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.setpixelparam(i, x, y, z, w)
end

--- Set uniform param.
-- @param n Name of the uniform param.
-- @param x X (defaults to 0)
-- @param y Y (defaults to 0)
-- @param z Z (defaults to 0)
-- @param w W (defaults to 0)
function setup(n, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.setuniformparam(n, x, y, z, w)
end

--- Define vertex param.
-- @param n Name of the param.
-- @param i Index of the param.
-- @param x X (defaults to 0)
-- @param y Y (defaults to 0)
-- @param z Z (defaults to 0)
-- @param w W (defaults to 0)
function defvp(n, i, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.defvertexparam(n, i, x, y, z, w)
end

--- Define pixel param.
-- @param n Name of the param.
-- @param i Index of the param.
-- @param x X (defaults to 0)
-- @param y Y (defaults to 0)
-- @param z Z (defaults to 0)
-- @param w W (defaults to 0)
function defpp(n, i, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.defpixelparam(n, i, x, y, z, w)
end

--- Define uniform param.
-- @param n Name of the param.
-- @param x X (defaults to 0)
-- @param y Y (defaults to 0)
-- @param z Z (defaults to 0)
-- @param w W (defaults to 0)
function defup(n, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.defuniformparam(n, x, y, z, w)
end

--- Alternate shader.
-- @param o Original name.
-- @param n Alternate name.
-- @class function
-- @name alt
alt = CAPI.altshader

--- Fast shader.
-- @param n Name of the "nice" shader.
-- @param f Name of the "fast" shader.
-- @param d Detail.
-- @class function
-- @name fast
fast = CAPI.fastshader

--- Defer shader.
-- @param s Type of the shader.
-- @param n Name of the shader.
-- @param c Contents.
-- @class function
-- @name defer
defer = CAPI.defershader

--- Force shader.
-- @param n Name of the shader.
-- @class function
-- @name force
force = CAPI.forceshader

--- Is shader defined?
-- @param n Name of the shader.
-- @return True if it is, false otherwise.
-- @class function
-- @name isdefined
isdefined = CAPI.isshaderdefined

--- Is shader native?
-- @param n Name of the shader.
-- @return True if it is, false otherwise.
-- @class function
-- @name isnative
isnative = CAPI.isshadernative

--- PostFX control table.
-- @class table
-- @name postfx
postfx = {}

--- Add a post effect.
-- @param n Name of the effect.
-- @param b Bind.
-- @param s Scale.
-- @param i Inputs.
-- @param x X
-- @param y Y
-- @param z Z
-- @param w W
function postfx.add(n, b, s, i, x, y, z, w)
    b = b or 0
    s = s or 0
    i = i or ""
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 0
    CAPI.addpostfx(n, b, s, i, x, y, z, w)
end

--- Set a post effect.
-- @param n Name of the effect.
-- @param x X
-- @param y Y
-- @param z Z
-- @param w W
-- @class function
-- @name postfx.set
postfx.set = CAPI.setpostfx

--- Clear all post effects.
-- @class function
-- @name postfx.clear
postfx.clear = CAPI.clearpostfx
