--[[!
    File: library/core/base/base_shaders.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features shader control functions.
]]

--[[!
    Package: shader
    This module controls shaders, such as their definition, parameters etc., as
    well as postprocessing effects.
]]
module("shader", package.seeall)

--[[!
    Variable: SHADER_GLSL
    Has value of <math.lsh> (1, 2). See <std>.
]]
SHADER_GLSL = math.lsh(1, 2)

--[[!
    Variable: SHADER_NORMAL
    Has value of <math.lsh> (1, 0). See <std>.
]]
SHADER_NORMAL = math.lsh(1, 0)

--[[!
    Variable: SHADER_ENVMAP
    Has value of <math.lsh> (1, 1). See <std>.
]]
SHADER_ENVMAP = math.lsh(1, 1)

--[[!
    Function: std
    Sets up a standard shader with given name, type, vertex and fragment
    shaders. Type indicates what resources the shader provides, or what backup
    method should be used if graphics card does not support shaders. It's
    either 0 for default ARB shader, <SHADER_GLSL> for default GLSL shader,
    T for non-default ARB shader of math.bor(<SHADER_GLSL>, T) for non-default
    GLSL shader.

    Values of T can be:
        SHADER_NORMAL - this indicates normalmapped shader (<SHADER_NORMAL>).
        SHADER_ENVMAP - indicates a shader reflecting environment
        (<SHADER_ENVMAP>).

    Parameters:
        type - shader type.
        name - shader name.
        vs - vertex shader (string).
        fs - fragment shader (string).
]]
std = CAPI.shader

--[[!
    Function: variant
    Sets up a variant shader. Arguments are like for <std>, but there is
    an additional one, a "row" which is an integral value. Type and name
    are the same, then comes the row, then vertex shader and then fragment
    shader.
]]
variant = CAPI.variantshader

--[[!
    Function: set
    Sets a shader to be used for further defined texture slot. You usually
    use this for i.e. bumpmapped textures. Argument is just one and it
    represents the shader name.

    The shader table is taken from Sauerbraten editing reference.

    (start table)
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | Shader                       | Shader params                      | Texture slots | Description                                                                      |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | stdworld                     |                                    | c             | The default lightmapped world shader.                                            |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | decalworld                   |                                    | c, d          | Like stdworld, except alpha blends decal texture on diffuse texture.             |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    |                              | - glowcolor: Rk, Gk, Bk -          |               |                                                                                  |
    | glowworld                    |   multiplies the glow map color by | c, g          | Like stdworld, except adds light from glow map.                                  |
    |                              |   the factors Rk, Gk, Bk           |               |                                                                                  |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpworld                    |                                    | c, n          | Normal-mapped shader without specularity (diffuse lighting only).                |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpglowworld                | - see glowworld                    | c, n, g       | Normal-mapped shader with glow map and without specularity.                      |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    |                              | - specscale: Rk, Gk, Bk -          |               |                                                                                  |
    | bumpspecworld                |   multiplies the glow map color by | c, n          | Normal-mapped shader with constant specularity factor.                           |
    |                              |   the factors Rk, Gk, Bk           |               |                                                                                  |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpspecmapworld             | - see above                        | c, n, s       | Normal-mapped shader with specularity map.                                       |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpspecglowworld            | - see glowworld and bumpspecworld  | c, n, g       | Normal-mapped shader with constant specularity factor and glow map.              |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpspecmapglowworld         | - see above                        | c, n, s, g    | Normal-mapped shader with specularity map and glow map.                          |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpparallaxworld            | - parallaxscale: Scale, Bias -     | c, n, z       | Normal-mapped shader with height map and without specularity.                    |
    |                              |   scales the heightmap offset      |               |                                                                                  |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpspecparallaxworld        | - see above plus bumpspecworld     | c, n, z       | Normal-mapped shader with constant specularity factor and height map.            |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpspecmapparallaxworld     | - see above                        | c, n, s, z    | Normal-mapped shader with specularity map and height map.                        |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpparallaxglowworld        | - see glowworld, bumpparallaxworld | c, n, z, g    | Normal-mapped shader with height and glow maps, and without specularity.         |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpspecparallaxglowworld    | - see above plus bumpspecworld     | c, n, z, g    | Normal-mapped shader with constant specularity factor and height and glow maps.  |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    | bumpspecmapparallaxglowworld | - see above                        | c, n, s, z, g | Normal-mapped shader with specularity, height and glow maps.                     |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    |                              | - envscale: Rk, Gk, Bk -           |               | Any of the above bump* shader permutations may replace "bump" with "bumpenv"     |
    |                              |   multiplies the environment map   |               | (i.e. bumpenvspecmapworld) and will then reflect the closest envmap entity       |
    |                              |   color by the factors Rk, Gk, Bk  |               | (see static entity documentation, or skybox if necessary). They support all      |
    |                              |                                    |               | their usual texture slots and pixel params, in addition to the envmap multiplier |
    | bumpenv*                     |                                    |               | pixel param. If a specmap is present in the given shader, the raw specmap value  |
    |                              |                                    |               | will be scaled by the envmap multipliers (instead of specmap ones) to determine  |
    |                              |                                    |               | how much of the envmap to reflect. A lightmap recalculation (if it hasn't been   |
    |                              |                                    |               | done before, see world module docs) or recalc (again, see those docs) is also    |
    |                              |                                    |               | needed by this shader to properly setup its engine state.                        |
    +------------------------------+------------------------------------+---------------+----------------------------------------------------------------------------------+
    (end)
]]
set = CAPI.setshader

--[[!
    Function: set_param
    Overrides an uniform parameter for the current shader. Any following
    texture slots will use this parameter until its value is set or reset
    by subsequent commands. Every uniform param is a 4-component vector.
    Components that are not specified default to 0. For param names, see
    the table in <set>.

    Parameters:
        name - name of a defined parameter of the current shader.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.

    See Also:
        <set_vertex_param>
        <set_pixel_param>
        <set_uniform_param>
]]
set_param = CAPI.setshaderparam

--[[!
    Function: set_vertex_param
    Overrides a vertex parameter for the current shader. Any following
    texture slots will use this vertex parameter until its value is
    set or reset by subsequent commands. Every vertex param is a 4-component
    vector. Components that are not specified default to 0.

    Parameters:
        index - index of a program environment parameter
        (program.env[10+INDEX) to the vertex program of the
        current shader.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.

    See Also:
        <set_param>
        <set_pixel_param>
        <set_uniform_param>
]]
set_vertex_param  = CAPI.setvertexparam

--[[!
    Function: set_pixel_param
    Overrides a pixel parameter for the current shader. Any following
    texture slots will use this pixel parameter until its value is
    set or reset by subsequent commands. Every pixel param is a 4-component
    vector. Components that are not specified default to 0.

    Parameters:
        index - index of a program environment parameter
        (program.env[10+INDEX) to the pixel program of the
        current shader.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.

    See Also:
        <set_param>
        <set_vertex_param>
        <set_uniform_param>
]]
set_pixel_param   = CAPI.setpixelparam

--[[!
    Function: set_uniform_param
    Overrides a GLSL uniform parameter for the current shader. Any following
    texture slots will use this parameter until its value is set or reset
    by subsequent commands. Every uniform param is a 4-component vector.
    Components that are not specified default to 0. For param names, see
    the table in <set>.

    Parameters:
        name - name of the uniform variable in the current GLSL shader.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.

    See Also:
        <set_param>
        <set_pixel_param>
        <set_vertex_param>
]]
set_uniform_param = CAPI.setuniformparam

--[[!
    Function: define_vertex_param
    Defines a vertex parameter. See <set_vertex_param>.

    Parameters:
        name - vertex param name.
        index - vertex param index.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.
]]
define_vertex_param  = CAPI.defvertexparam

--[[!
    Function: define_pixel_param
    Defines a pixel parameter. See <set_pixel_param>.

    Parameters:
        name - pixel param name.
        index - pixel param index.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.
]]
define_pixel_param   = CAPI.defpixelparam

--[[!
    Function: define_uniform_param
    Defines an uniform shader parameter. See <set_param>.

    Parameters:
        name - uniform param name.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.
]]
define_uniform_param = CAPI.defuniformparam

--[[!
    Function: alt
    Defines an alternate name for a shader.

    Parameters:
        orig - original shader name.
        alt - alternate shader name.
]]
alt = CAPI.altshader

--[[!
    Function: fast
    Cube 2 allows system of "nice" and "fast" shaders where nice shader
    is the one that is expensive to use and fast is a cheap, but mostly
    worse-looking one. You can specify a detail level (<shaderdetail>
    variable) on which fast shader is last used (i.e. with detail set to
    2, fastshader will be used on details 1 and 2, but not 3).

    Parameters:
        nice - name of the nice shader.
        fast - name of the fast shader.
        detail - shader detail level to toggle between fast and nice.
]]
fast = CAPI.fastshader

--[[!
    Function: defer
    Defers a shader into later stage. Can be disabled by setting
    <defershaders> engine variable to 0, then such shaders will
    be run immediately when setting up.

    Parameters:
        type - shader type, see <std>.
        name - defer shader name.
        contents - a function taking 0 arguments and returning 0
        results that sets up the shader code itself.
]]
defer = CAPI.defershader

--[[!
    Function: force
    Foces usage of shader of name given by argument right now.
]]
force = CAPI.forceshader

--[[!
    Function: is_defined
    Returns true if shader of name given by argument
    is defined, or false otherwise.
]]
is_defined = CAPI.isshaderdefined

--[[!
    Function: is_native
    Returns true if shader of name given by argument
    is native, or false otherwise.
]]
is_native = CAPI.isshadernative

--[[!
    Function: postfx_add
    Loads a postprocessing shader of given name.
    PostFX shaders can have 4 params stored in vec4
    (uniform vec4 params). You pass components through
    arguments.

    Parameters:
        name   - name of the postfx.
        bind   - postfx shader bind.
        scale  - postfx shader scale.
        inputs - postfx shader inputs.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.
]]
postfx_add   = CAPI.addpostfx

--[[!
    Function: postfx_set
    Clears out all current postfx effects
    and sets one with given name. Allows
    passing params.

    Parameters:
        name - name of the postfx.
        x - X component.
        y - Y component.
        z - Z component.
        w - W component.
]]
postfx_set   = CAPI.setpostfx

--[[!
    Function: postfx_clear
    Clears out any presently loaded postfx effects.
]]
postfx_clear = CAPI.clearpostfx
