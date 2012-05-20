lazyshader = function(stype, name, vert, frag)
    CAPI.defershader (stype, name, function()
        CAPI.shader  (stype, name, vert:eval_embedded(), frag:eval_embedded()) end) end

gdepthinterp = function()
    if EVAR.gdepthformat ~= 0 then
        return (EVAR.gdepthformat > 1) and [[
            uniform vec3 gdepthpackparams;
            varying float lineardepth;
        ]] or [[
            uniform vec3 gdepthpackparams;
            varying vec3 lineardepth;
        ]] end end

gdepthpackvert = function(arg1)
    if EVAR.gdepthformat ~= 0 then
        return ((EVAR.gdepthformat > 1) and [[
            lineardepth = dot(gl_ModelViewMatrixTranspose[2], @(arg1 and arg1 or "gl_Vertex"));
        ]] or [[
            lineardepth = dot(gl_ModelViewMatrixTranspose[2], @(arg1 and arg1 or "gl_Vertex")) * gdepthpackparams;
        ]]):eval_embedded(nil, { arg1 = arg1 }) end end

gdepthpackfrag = function()
    if EVAR.gdepthformat ~= 0 then
        return (EVAR.gdepthformat > 1) and [[
            gl_FragData[3].r = lineardepth;
        ]] or [[
            vec3 packdepth = vec3(lineardepth.x, fract(lineardepth.yz));
            packdepth.xy -= packdepth.yz * (1.0/255.0);
            gl_FragData[3].rgb = packdepth;
        ]] end end

gdepthunpackparams = [[
    uniform vec3 gdepthscale;
    uniform vec3 gdepthunpackparams;
]]

gdepthunpack = function(arg1, arg2, arg3, arg4, arg5, arg6)
    if EVAR.gdepthformat ~= 0 or arg6 then
        return ((EVAR.gdepthformat > 1 or arg6) and [[
            float @(arg1) = texture2DRect(@(arg2), @(arg3)).r;
            @(arg4)
        ]] or [[
            float @(arg1) = dot(texture2DRect(@(arg2), @(arg3)).rgb, gdepthunpackparams); 
            @(arg4)
        ]]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3, arg4 = arg4 })
    else
        return ((not arg5 or arg5 == "") and [[
            float @(arg1) = gdepthscale.x / (texture2DRect(@(arg2), @(arg3)).r*gdepthscale.y + gdepthscale.z);
        ]] or [[
            float @(arg1) = texture2DRect(@(arg2), @(arg3)).r;
            @(arg5)
        ]]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3, arg5 = arg5 }) end end


gdepthunpackproj = function(arg1, arg2, arg3, arg4, arg5, arg6)
    if EVAR.gdepthformat ~= 0 or arg6 then
        return ((EVAR.gdepthformat > 1 or arg6) and [[
            float @(arg1) = texture2DRectProj(@(arg2), @(arg3)).r;
            @(arg4)
        ]] or [[
            float @(arg1) = dot(texture2DRectProj(@(arg2), @(arg3)).rgb, gdepthunpackparams); 
            @(arg4)
        ]]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3, arg4 = arg4 })
    else
        return ((not arg5 or arg5 == "") and [[
            float @(arg1) = gdepthscale.x / (texture2DRectProj(@(arg2), @(arg3)).r*gdepthscale.y + gdepthscale.z);
        ]] or [[
            float @(arg1) = texture2DRectProj(@(arg2), @(arg3)).r;
            @(arg5)
        ]]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3, arg5 = arg5 }) end end

CAPI.shader(0, "null", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
    }
]], [[
    void main(void)
    {
        gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
    }
]])

--
-- used for any textured polys that don't have a shader set
--

CAPI.shader(0, "default", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        gl_FragColor = gl_Color * texture2D(tex0, gl_TexCoord[0].xy);
    }
]])

CAPI.shader(0, "rect", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        gl_FragColor = gl_Color * texture2DRect(tex0, gl_TexCoord[0].xy);
    }
]])

CAPI.shader(0, "cubemap", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], [[
    uniform samplerCube tex0;
    void main(void)
    {
        gl_FragColor = gl_Color * textureCube(tex0, gl_TexCoord[0].xyz);
    }
]])

CAPI.shader(0, "rgbonly", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        gl_FragColor.rgb = gl_Color.rgb * texture2D(tex0, gl_TexCoord[0].xy).rgb;
        gl_FragColor.a   = gl_Color.a;
    }
]])

--
-- same, but now without texture sampling (some HUD stuff needs this)
--

CAPI.shader(0, "notexture", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_FrontColor = gl_Color;
    }
]], [[
    void main(void)
    {
        gl_FragColor = gl_Color;
    }
]])

--
-- fogged variants of default shaders
--

CAPI.shader(0, "fogged", [[
    #pragma CUBE2_fog
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        gl_FragColor = gl_Color * texture2D(tex0, gl_TexCoord[0].xy);
    }
]])

CAPI.shader(0, "foggednotexture", [[
    #pragma CUBE2_fog
    void main(void)
    {
        gl_Position = ftransform();
        gl_FrontColor = gl_Color;
    }
]], [[
    void main(void)
    {
        gl_FragColor = gl_Color;
    }
]])

--
-- LDR variants of default shaders
--

CAPI.shader(0, "ldr", [[
    uniform float ldrscale;
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = vec4(ldrscale * gl_Color.rgb, gl_Color.a);
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        gl_FragColor = gl_Color * texture2D(tex0, gl_TexCoord[0].xy);
    }
]])

CAPI.shader(0, "ldrnotexture", [[
    uniform float ldrscale;
    void main(void)
    {
        gl_Position = ftransform();
        gl_FrontColor = vec4(ldrscale * gl_Color.rgb, gl_Color.a);
    }
]], [[
    void main(void)
    {
        gl_FragColor = gl_Color;
    }
]])

--
-- for filling the z-buffer only (i.e. multi-pass rendering, OQ)
--

CAPI.shader(0, "nocolor", [[
    void main() { gl_Position = ftransform(); }
]], [[
    void main() {}
]])

--
-- default lightmapped world shader.. does texcoord gen
--

worldshader = function(...)
    local arg   = { ... }
    local stype = arg[1]:find("env") ~= nil and 3 or 1
    for i = 0, 2 do CAPI.variantshader(i == 2 and stype + 4 or stype, arg[1], i - 1, ([[
        @(#arg >= 5 and arg[5] or nil)
        uniform vec4 texgenscroll;
        varying vec3 normal;
        @(gdepthinterp())
        @(i == 1 and "uniform vec4 blendmapparams;" or nil)
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texgenscroll.xy;
            @(i == 1 and "gl_TexCoord[1].xy = (gl_Vertex.xy - blendmapparams.xy)*blendmapparams.zw;" or nil)
            normal = gl_Normal;
    
            @(gdepthpackvert())

            @(arg[2])
        }
    ]]):eval_embedded(nil, { i = i, arg = arg }, _G), ([=[
        @(i == 2 and [[
            #extension GL_ARB_texture_rectangle : enable
            uniform sampler2DRect refractlight;
            uniform vec4 refractparams;
        ]] or nil)
        @(#arg >= 5 and arg[5] or nil)
        @(#arg >= 6 and arg[6] or nil)
        uniform vec4 colorparams;
        uniform sampler2D diffusemap;
        varying vec3 normal;
        @(gdepthinterp())
        @(i == 1 and "uniform sampler2D blendmap;" or nil)
        void main(void)
        {
            vec4 diffuse = texture2D(diffusemap, gl_TexCoord[0].xy);   

            @(arg[3])

            @(if i == 1 then return [[
                float alpha = colorparams.a * texture2D(blendmap, gl_TexCoord[1].xy).r;
            ]] elseif i == 2 then return [[
                #define alpha 1.0
            ]] else return [[
                #define alpha colorparams.a
            ]] end)
            
            gl_FragData[0] = vec4(diffuse.rgb*colorparams.rgb, alpha);
            gl_FragData[1] = vec4(normal*0.5+0.5, alpha);
            gl_FragData[2].a = 0.0;
            @((#arg < 4 or not arg[4] or arg[4] == "") and "gl_FragData[2].rgb = vec3(0.0);" or arg[4])

            @(i == 2 and [[
                vec3 rlight = texture2DRect(refractlight, gl_FragCoord.xy).rgb;
                gl_FragData[2].rgb += rlight * refractparams.xyz;
            ]] or nil)

            @(gdepthpackfrag())
        }
    ]=]):eval_embedded(nil, { i = i, arg = arg }, _G)) end end

worldshader("stdworld", "", "")

CAPI.defershader(1, "glowworld", function()
    CAPI.defuniformparam("glowcolor", 1, 1, 1, 0) -- glow color
    worldshader("glowworld", "", "", [[
        vec3 glow = texture2D(glowmap, gl_TexCoord[0].xy).rgb;
        glow *= glowcolor.rgb;
        gl_FragData[2].rgb = glow;
    ]], "", "uniform sampler2D glowmap;") end)

CAPI.defershader(1, "pulseworld", function()
    CAPI.defuniformparam("pulsespeed", 1, 0, 0, 0) -- pulse frequency (Hz)
    worldshader("pulseworld", [[
        pulse = abs(fract(millis.x * pulsespeed.x)*2.0 - 1.0); 
    ]], [[
        vec3 diffuse2 = texture2D(decal, gl_TexCoord[0].xy).rgb; 
        diffuse.rgb = mix(diffuse.rgb, diffuse2, pulse);
    ]], "", "uniform vec4 millis; varying float pulse;", "uniform sampler2D decal;") end)

CAPI.defershader(1, "pulseglowworld", function()
    CAPI.defuniformparam("glowcolor", 1, 1, 1, 0) -- glow color
    CAPI.defuniformparam("pulseglowspeed", 1, 0, 0, 0) -- pulse frequency (Hz)
    CAPI.defuniformparam("pulseglowcolor", 0, 0, 0, 0) -- pulse glow color
    worldshader("pulseglowworld", [[
        pulse = mix(glowcolor.rgb, pulseglowcolor.rgb, abs(fract(millis.x * pulseglowspeed.x)*2.0 - 1.0));
    ]], "", [[
        vec3 glow = texture2D(glowmap, gl_TexCoord[0].xy).rgb;
        gl_FragData[2].rgb = glow*pulse;
    ]], "uniform vec4 millis; varying vec3 pulse;", "uniform sampler2D glowmap;") end)

CAPI.defershader(3, "envworld", function()
    CAPI.defuniformparam("envscale", 0.2, 0.2, 0.2, 0) -- reflectivity
    worldshader("envworld", [[
        camvec = camera.xyz - gl_Vertex.xyz; 
    ]], [[
        vec3 reflect = textureCube(envmap, 2.0*normal*dot(camvec, normal) - camvec).rgb;
    ]], [[
        gl_FragData[0].rgb *= 1.0-envscale.x;
        gl_FragData[2].rgb = reflect*(0.5*envscale.x);
    ]], "uniform vec4 camera; varying vec3 camvec;", "uniform samplerCube envmap;")

    CAPI.defuniformparam("envscale", 0.2, 0.2, 0.2, 0) -- reflectivity
    worldshader("envworldfast", [[
        vec3 camvec = camera.xyz - gl_Vertex.xyz;
        rvec = 2.0*gl_Normal*dot(camvec, gl_Normal) - camvec;
    ]], [[
        vec3 reflect = textureCube(envmap, rvec).rgb;
    ]], [[
        gl_FragData[0].rgb *= 1.0-envscale.x;
        gl_FragData[2].rgb = reflect*(0.5*envscale.x);
    ]], "uniform vec4 camera; varying vec3 rvec;", "uniform samplerCube envmap;")

    CAPI.defuniformparam("envscale", 0.2, 0.2, 0.2, 0) -- reflectivity
    worldshader("envworldalt", "", "")

    CAPI.altshader ("envworld", "envworldalt")
    CAPI.fastshader("envworld", "envworldfast", 2)
    CAPI.fastshader("envworld", "envworldalt",  1) end)

-- bumptype:
--    e -> reserve envmap texture slot
--    o -> orthonormalize
--    t -> tangent space cam
--    r -> envmap reflection
--    R -> modulate envmap reflection with spec map
--    s -> spec
--    S -> spec map
--    p -> parallax
--    P -> steep parallax (7 steps)
--    g -> glow
--    G -> pulse glow
--    b -> blendmap
--    a -> refractive

bumpvariantshader = function(...)
    local arg = { ... }
    local bumptype = arg[2]

    local btopt = {
        e = bumptype:find("e") ~= nil,
        o = bumptype:find("o") ~= nil,
        t = bumptype:find("t") ~= nil,
        r = bumptype:find("r") ~= nil,
        R = bumptype:find("R") ~= nil,
        s = bumptype:find("s") ~= nil,
        S = bumptype:find("S") ~= nil,
        p = bumptype:find("p") ~= nil,
        P = bumptype:find("P") ~= nil,
        g = bumptype:find("g") ~= nil,
        G = bumptype:find("G") ~= nil,
        b = bumptype:find("b") ~= nil,
        a = bumptype:find("a") ~= nil,
    }

    local stype = btopt.e and 3 or 1
    local srow  = -1

    if btopt.G then
        CAPI.defuniformparam("glowcolor", 1, 1, 1, 0) -- glow color
        CAPI.defuniformparam("pulseglowspeed", 1, 0, 0, 0) -- pulse frequency (Hz)
        CAPI.defuniformparam("pulseglowcolor", 0, 0, 0, 1) -- pulse glow color
    elseif btopt.g then
        CAPI.defuniformparam("glowcolor", 1, 1, 1, 0) end -- glow color

    if btopt.S then
        CAPI.defuniformparam("specscale", 6, 6, 6, 0) -- spec map multiplier
    elseif btopt.s then
        CAPI.defuniformparam("specscale", 1, 1, 1, 0) end -- spec multiplier

    if btopt.p or btopt.P then
        CAPI.defuniformparam("parallaxscale", 0.06, -0.03, 0, 0) end -- parallax scaling

    if btopt.R then
        CAPI.defuniformparam("envscale", 1, 1, 1, 0) -- reflectivity map multiplier
    elseif btopt.r then
        CAPI.defuniformparam("envscale", 0.2, 0.2, 0.2, 0) end -- reflectivity

    if btopt.b then srow = 0 end
    if btopt.a then
        stype = stype + 4
        srow  = 1 end

    CAPI.variantshader(stype, arg[1], srow, ([[
        uniform vec4 texgenscroll;
        varying mat3 world;
        @(gdepthinterp())
        @((btopt.t or btopt.r) and "uniform vec4 camera;" or nil)
        @(btopt.t and "varying vec3 camvects;" or nil)
        @(btopt.r and "varying vec3 camvecw;" or nil)
        @(btopt.G and "uniform vec4 millis; varying float pulse;" or nil)
        @(btopt.b and "uniform vec4 blendmapparams;" or nil)

        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texgenscroll.xy;

            @(gdepthpackvert())

            @(btopt.b and "gl_TexCoord[1].xy = (gl_Vertex.xy - blendmapparams.xy)*blendmapparams.zw;" or nil)

            vec4 tangent = gl_Color*2.0 - 1.0;
            vec3 binormal = cross(gl_Normal, tangent.xyz) * tangent.w;
            // calculate tangent -> world transform
            world = mat3(tangent.xyz, binormal, gl_Normal);

            @(btopt.t and "camvects = (camera.xyz - gl_Vertex.xyz) * world;" or nil)
            @(btopt.r and "camvecw = camera.xyz - gl_Vertex.xyz;" or nil)

            @(btopt.G and "pulse = abs(fract(millis.x*pulseglowspeed.x)*2.0 - 1.0);" or nil)
        }
    ]]):eval_embedded(nil, { btopt = btopt }, _G), ([==[
        @(btopt.a and [[
            #extension GL_ARB_texture_rectangle : enable
            uniform sampler2DRect refractmask, refractlight;
            uniform vec4 refractparams;
        ]] or nil)
        uniform vec4 colorparams;
        uniform sampler2D diffusemap, normalmap;
        varying mat3 world;
        @(gdepthinterp())
        @(btopt.t and "varying vec3 camvects;" or nil)
        @(btopt.g and "uniform sampler2D glowmap;" or nil)
        @(btopt.G and "varying float pulse;" or nil)
        @(btopt.r and "uniform samplerCube envmap; varying vec3 camvecw;" or nil)
        @(btopt.b and "uniform sampler2D blendmap;" or nil)
        void main(void)
        {
            @(btopt.t and "vec3 camdirts = normalize(camvects);" or nil)
            @(btopt.p and [[
                float height = texture2D(normalmap, gl_TexCoord[0].xy).a;
                vec2 dtc = gl_TexCoord[0].xy + camdirts.xy*(height*parallaxscale.x + parallaxscale.y);
            ]])
            @(btopt.P and [=[
                const float step = -1.0/7.0;
                vec3 duv = vec3((step*parallaxscale.x/camdir.z)*camdirts.xy, step);
                vec3 htc = vec3(gl_TexCoord[0].xy + duv.xy*parallaxscale.y, 1.0);
                vec4 height = texture2D(normalmap, htc.xy);
                @(string.rep([[
                    htc += height.w < htc.z ? duv : vec(0.0);
                    height = texture2D(normalmap, htc.xy);
                ]], 7))
                #define dtc htc.xy
                #define bump height.xyz
            ]=])

            @((btopt.p or btopt.P) and nil or "#define dtc gl_TexCoord[0].xy")

            vec4 diffuse = texture2D(diffusemap, dtc);

            @(if btopt.b then return [[
                float alpha = colorparams.a * texture2D(blendmap, gl_TexCoord[1].xy).r;
                #define specalpha alpha
            ]] elseif btopt.a then return [[
                #define alpha 1.0
                #define specalpha 1.0
            ]] else return [[
                #define alpha colorparams.a
                #define specalpha 1.0
            ]] end)

            gl_FragData[0] = vec4(diffuse.rgb*colorparams.rgb, alpha);

            @(not btopt.P and "vec3 bump = texture2D(normalmap, dtc).rgb;" or nil)

            bump = bump*2.0 - 1.0;
            vec3 bumpw = world * bump;
            gl_FragData[1] = vec4(bumpw*0.5 + 0.5, alpha);

            @(if btopt.s then
                if btopt.S then return [[
                    gl_FragData[2].a = diffuse.a*specscale.x * 0.5 * specalpha;
                ]] else return [[
                    gl_FragData[2].a = specscale.x * 0.5 * specalpha;
                ]] end
            else return [[
                gl_FragData[2].a = 0.0;
            ]] end)

            @(if btopt.r or btopt.g then return [=[
                @(btopt.g and [[
                    vec3 glow = texture2D(glowmap, dtc).rgb;
                    @(btopt.G and
                        "vec3 pulsecol = mix(glowcolor.xyz, pulseglowcolor.xyz, pulse);"
                        or nil)
                    glow *= @(btopt.G and "pulsecol" or "glowcolor.xyz");
                    @(not btopt.r and "gl_FragData[2].rgb = glow;" or nil)
                ]] or nil)

                @(btopt.r and [[
                    vec3 rvec = 2.0*bumpw*dot(camvecw, bumpw) - camvecw;
                    vec3 reflect = textureCube(envmap, rvec).rgb;
                    @(btopt.R
                        and "float rmod = envscale.x*diffuse.a;"
                        or  "#define rmod envscale.x")
                    gl_FragData[0].rgb *= 1.0 - rmod;
                    gl_FragData[2].rgb = reflect*rmod;
                    @(btopt.g and "gl_FragData[2].rgb += glow;" or nil)
                ]] or nil)
            ]=] else return [[
                gl_FragData[2].rgb = vec3(0.0);
            ]] end)

            @(btopt.a and [[
                vec2 rtc = bump.xy*refractparams.w;
                float rmask = texture2DRect(refractmask, gl_FragCoord.xy + rtc).a;
                vec3 rlight = texture2DRect(refractlight, gl_FragCoord.xy + rtc*rmask).rgb;
                gl_FragData[2].rgb += rlight * refractparams.xyz;
            ]] or nil)

            @(gdepthpackfrag())
        }
    ]==]):eval_embedded(nil, { btopt = btopt }, _G)) end

bumpshader = function(name, btopts)
    CAPI.defershader(btopts:find("e") and 3 or 1, name, function()
        bumpvariantshader(name, btopts)
        bumpvariantshader(name, btopts .. "b")
        bumpvariantshader(name, btopts .. "a") end) end

bumpshader("bumpworld", "")
bumpshader("bumpspecworld", "ots")
CAPI.fastshader("bumpspecworld", "bumpworld", 2)
CAPI.altshader("bumpspecworld", "bumpworld")
bumpshader("bumpspecmapworld", "otsS")
CAPI.fastshader("bumpspecmapworld", "bumpworld", 2)
CAPI.altshader("bumpspecmapworld", "bumpworld")

bumpshader("bumpglowworld", "g")
bumpshader("bumpspecglowworld", "otsg")
CAPI.altshader("bumpspecglowworld", "bumpglowworld")
bumpshader("bumpspecmapglowworld", "otsSg")
CAPI.fastshader("bumpspecmapglowworld", "bumpglowworld", 2)
CAPI.altshader("bumpspecmapglowworld", "bumpglowworld")

bumpshader("bumppulseglowworld", "gG")
bumpshader("bumpspecpulseglowworld", "otsgG")
CAPI.altshader("bumpspecpulseglowworld", "bumppulseglowworld")
bumpshader("bumpspecmappulseglowworld", "otsSgG")
CAPI.fastshader("bumpspecmappulseglowworld", "bumppulseglowworld", 2)
CAPI.altshader("bumpspecmappulseglowworld", "bumppulseglowworld")

bumpshader("bumpparallaxworld", "pot")
CAPI.fastshader("bumpparallaxworld", "bumpworld", 1)
CAPI.altshader("bumpparallaxworld", "bumpworld")
bumpshader("bumpspecparallaxworld", "pots")
CAPI.fastshader("bumpspecparallaxworld", "bumpparallaxworld", 2)
CAPI.fastshader("bumpspecparallaxworld", "bumpworld", 1)
CAPI.altshader("bumpspecparallaxworld", "bumpworld")
bumpshader("bumpspecmapparallaxworld", "potsS")
CAPI.fastshader("bumpspecmapparallaxworld", "bumpparallaxworld", 2)
CAPI.fastshader("bumpspecmapparallaxworld", "bumpworld", 1)
CAPI.altshader("bumpspecmapparallaxworld", "bumpworld")

bumpshader("bumpparallaxglowworld", "potg")
CAPI.fastshader("bumpparallaxglowworld", "bumpglowworld", 1)
CAPI.altshader("bumpparallaxglowworld", "bumpglowworld")
bumpshader("bumpspecparallaxglowworld", "potsg")
CAPI.fastshader("bumpspecparallaxglowworld", "bumpparallaxglowworld", 2)
CAPI.fastshader("bumpspecparallaxglowworld", "bumpglowworld", 1)
CAPI.altshader("bumpspecparallaxglowworld", "bumpglowworld")
bumpshader("bumpspecmapparallaxglowworld", "potsSg")
CAPI.fastshader("bumpspecmapparallaxglowworld", "bumpparallaxglowworld", 2)
CAPI.fastshader("bumpspecmapparallaxglowworld", "bumpglowworld", 1)
CAPI.altshader("bumpspecmapparallaxglowworld", "bumpglowworld")

bumpshader("bumpparallaxpulseglowworld", "potgG")
CAPI.fastshader("bumpparallaxpulseglowworld", "bumppulseglowworld", 1)
CAPI.altshader("bumpparallaxpulseglowworld", "bumppulseglowworld")
bumpshader("bumpspecparallaxpulseglowworld", "potsgG")
CAPI.fastshader("bumpspecparallaxpulseglowworld", "bumpparallaxpulseglowworld", 2)
CAPI.fastshader("bumpspecparallaxpulseglowworld", "bumppulseglowworld", 1)
CAPI.altshader("bumpspecparallaxpulseglowworld", "bumppulseglowworld")
bumpshader("bumpspecmapparallaxpulseglowworld", "potsSgG")
CAPI.fastshader("bumpspecmapparallaxpulseglowworld", "bumpparallaxpulseglowworld", 2)
CAPI.fastshader("bumpspecmapparallaxpulseglowworld", "bumppulseglowworld", 1)
CAPI.altshader("bumpspecmapparallaxpulseglowworld", "bumppulseglowworld")

bumpshader("bumpenvworldalt", "e")
bumpshader("bumpenvworld", "eor")
CAPI.altshader("bumpenvworld", "bumpenvworldalt")
CAPI.fastshader("bumpenvworld", "bumpenvworldalt", 2)
bumpshader("bumpenvspecworld", "eotsr")
CAPI.altshader("bumpenvspecworld", "bumpenvworldalt")
CAPI.fastshader("bumpenvspecworld", "bumpenvworldalt", 2)
bumpshader("bumpenvspecmapworld", "eotsSrR")
CAPI.altshader("bumpenvspecmapworld", "bumpenvworldalt")
CAPI.fastshader("bumpenvspecmapworld", "bumpenvworldalt", 2)

bumpshader("bumpenvglowworldalt", "eg")
bumpshader("bumpenvglowworld", "eorg")
CAPI.altshader("bumpenvglowworld", "bumpenvglowworldalt")
CAPI.fastshader("bumpenvglowworld", "bumpenvglowworldalt", 2)
bumpshader("bumpenvspecglowworld", "eotsrg")
CAPI.altshader("bumpenvspecglowworld", "bumpenvglowworldalt")
CAPI.fastshader("bumpenvspecglowworld", "bumpenvglowworldalt", 2)
bumpshader("bumpenvspecmapglowworld", "eotsSrRg")
CAPI.altshader("bumpenvspecmapglowworld", "bumpenvglowworldalt")
CAPI.fastshader("bumpenvspecmapglowworld", "bumpenvglowworldalt", 2)

bumpshader("bumpenvpulseglowworldalt", "egG")
bumpshader("bumpenvpulseglowworld", "eorgG")
CAPI.altshader("bumpenvpulseglowworld", "bumpenvpulseglowworldalt")
CAPI.fastshader("bumpenvpulseglowworld", "bumpenvpulseglowworldalt", 2)
bumpshader("bumpenvspecpulseglowworld", "eotsrgG")
CAPI.altshader("bumpenvspecpulseglowworld", "bumpenvpulseglowworldalt")
CAPI.fastshader("bumpenvspecpulseglowworld", "bumpenvpulseglowworldalt", 2)
bumpshader("bumpenvspecmappulseglowworld", "eotsSrRgG")
CAPI.altshader("bumpenvspecmappulseglowworld", "bumpenvpulseglowworldalt")
CAPI.fastshader("bumpenvspecmappulseglowworld", "bumpenvpulseglowworldalt", 2)

bumpshader("bumpenvparallaxworldalt", "epot")
CAPI.altshader("bumpenvparallaxworldalt", "bumpenvworldalt")
bumpshader("bumpenvparallaxworld", "epotr")
CAPI.altshader("bumpenvparallaxworld", "bumpenvparallaxworldalt")
CAPI.fastshader("bumpenvparallaxworld", "bumpenvparallaxworldalt", 2)
CAPI.fastshader("bumpenvparallaxworld", "bumpenvworldalt", 1)
bumpshader("bumpenvspecparallaxworld", "epotsr")
CAPI.altshader("bumpenvspecparallaxworld", "bumpenvparallaxworldalt")
CAPI.fastshader("bumpenvspecparallaxworld", "bumpenvparallaxworldalt", 2)
CAPI.fastshader("bumpenvspecparallaxworld", "bumpenvworldalt", 1)
bumpshader("bumpenvspecmapparallaxworld", "epotsSrR")
CAPI.altshader("bumpenvspecmapparallaxworld", "bumpenvparallaxworldalt")
CAPI.fastshader("bumpenvspecmapparallaxworld", "bumpenvparallaxworldalt", 2)
CAPI.fastshader("bumpenvspecmapparallaxworld", "bumpenvworldalt", 1)

bumpshader("bumpenvparallaxglowworldalt", "epotg")
CAPI.altshader("bumpenvparallaxglowworldalt", "bumpenvglowworldalt")
bumpshader("bumpenvparallaxglowworld", "epotrg")
CAPI.altshader("bumpenvparallaxglowworld", "bumpenvparallaxglowworldalt")
CAPI.fastshader("bumpenvparallaxglowworld", "bumpenvparallaxglowworldalt", 2)
CAPI.fastshader("bumpenvparallaxglowworld", "bumpenvglowworldalt", 1)
bumpshader("bumpenvspecparallaxglowworld", "epotsrg")
CAPI.altshader("bumpenvspecparallaxglowworld", "bumpenvparallaxglowworldalt")
CAPI.fastshader("bumpenvspecparallaxglowworld", "bumpenvparallaxglowworldalt", 2)
CAPI.fastshader("bumpenvspecparallaxglowworld", "bumpenvglowworldalt", 1)
bumpshader("bumpenvspecmapparallaxglowworld", "epotsSrRg")
CAPI.altshader("bumpenvspecmapparallaxglowworld", "bumpenvparallaxglowworldalt")
CAPI.fastshader("bumpenvspecmapparallaxglowworld", "bumpenvparallaxglowworldalt", 2)
CAPI.fastshader("bumpenvspecmapparallaxglowworld", "bumpenvglowworldalt", 1)

bumpshader("bumpenvparallaxpulseglowworldalt", "epotgG")
CAPI.altshader("bumpenvparallaxpulseglowworldalt", "bumpenvpulseglowworldalt")
bumpshader("bumpenvparallaxpulseglowworld", "epotrgG")
CAPI.altshader("bumpenvparallaxpulseglowworld", "bumpenvparallaxpulseglowpulseglowworldalt")
CAPI.fastshader("bumpenvparallaxpulseglowworld", "bumpenvparallaxpulseglowpulseglowworldalt", 2)
CAPI.fastshader("bumpenvparallaxpulseglowworld", "bumpenvpulseglowworldalt", 1)
bumpshader("bumpenvspecparallaxpulseglowworld", "epotsrgG")
CAPI.altshader("bumpenvspecparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt")
CAPI.fastshader("bumpenvspecparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt", 2)
CAPI.fastshader("bumpenvspecparallaxpulseglowworld", "bumpenvpulseglowworldalt", 1)
bumpshader("bumpenvspecmapparallaxpulseglowworld", "epotsSrRgG")
CAPI.altshader("bumpenvspecmapparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt")
CAPI.fastshader("bumpenvspecmapparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt", 2)
CAPI.fastshader("bumpenvspecmapparallaxpulseglowworld", "bumpenvpulseglowworldalt", 1)

--bumpshader("steepworld", "Pot")

--
-- phong lighting model shader
--

-- skeletal animation for matrices and dual quaternions

skelanimdefs = function()
    return ([=[
        @(EVAR.useubo ~= 0 and [[
            #ifdef GL_ARB_uniform_buffer_object
                #extension GL_ARB_uniform_buffer_object : enable
            #endif
        ]] or nil)
        @(EVAR.usebue ~= 0 and [[
            #extension GL_EXT_bindable_uniform : enable
        ]] or nil)
        #pragma CUBE2_attrib vweights 6
        #pragma CUBE2_attrib vbones 7
        attribute vec4 vweights; 
        attribute vec4 vbones;
        #pragma CUBE2_uniform animdata AnimData 0 16
        @(EVAR.useubo ~= 0 and [[
            #ifdef GL_ARB_uniform_buffer_object
                layout(std140) uniform AnimData
                {
                    vec4 animdata[@(math.min(EVAR.maxvsuniforms, EVAR.maxanimdata))];
                };
            #else
        ]] or nil)
        @(EVAR.usebue ~= 0 and [[
            #ifdef GL_EXT_bindable_uniform
                bindable
            #endif
        ]] or nil)
        uniform vec4 animdata[@(math.min(EVAR.maxvsuniforms, EVAR.maxanimdata))];
        @(EVAR.useubo ~= 0 and [[
            #endif
        ]] or nil)
    ]=]):eval_embedded() end

skelanimfragdefs = function()
    if EVAR.ati_ubo_bug ~= 0 then
        return (EVAR.useubo ~= 0 and [[
            #ifdef GL_ARB_uniform_buffer_object
                #extension GL_ARB_uniform_buffer_object : enable
                layout(std140) uniform AnimData
                {
                    vec4 animdata[@(math.min(EVAR.maxvsuniforms, EVAR.maxanimdata))];
                };
            #endif
        ]] or [[
            #ifdef GL_EXT_bindable_uniform
                #extension GL_EXT_bindable_uniform : enable
                bindable uniform vec4 animdata[@(math.min(EVAR.maxvsuniforms, EVAR.maxanimdata))];
            #endif
        ]]):eval_embedded() end end

skelmatanim = function(arg1, arg2, arg3)
    return ([=[
        int index = int(vbones.x);
        @(arg1 == 1 and [[
            vec4 mx = animdata[index];
            vec4 my = animdata[index+1];
            vec4 mz = animdata[index+2];
        ]] or [[
            vec4 mx = animdata[index] * vweights.x;
            vec4 my = animdata[index+1] * vweights.x;
            vec4 mz = animdata[index+2] * vweights.x;
            index = int(vbones.y);
            mx += animdata[index] * vweights.y;
            my += animdata[index+1] * vweights.y;
            mz += animdata[index+2] * vweights.y;
        ]])
        @(arg1 >= 3 and [[
            index = int(vbones.z);
            mx += animdata[index] * vweights.z;
            my += animdata[index+1] * vweights.z;
            mz += animdata[index+2] * vweights.z;
        ]] or nil)
        @(arg1 >= 4 and [[
            index = int(vbones.w);
            mx += animdata[index] * vweights.w;
            my += animdata[index+1] * vweights.w;
            mz += animdata[index+2] * vweights.w;
        ]] or nil)

        vec4 opos = vec4(dot(mx, gl_Vertex), dot(my, gl_Vertex), dot(mz, gl_Vertex), gl_Vertex.w);

        @((arg2 and arg2 ~= 0) and [[
            vec3 onormal = vec3(dot(mx.xyz, gl_Normal), dot(my.xyz, gl_Normal), dot(mz.xyz, gl_Normal));
        ]] or nil)

        @((arg3 and arg3 ~= 0) and [[
            vec3 otangent = vec3(dot(mx.xyz, vtangent.xyz), dot(my.xyz, vtangent.xyz), dot(mz.xyz, vtangent.xyz));
        ]] or nil)
    ]=]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3 }, _G) end

skelquatanim = function(arg1, arg2, arg3)
    return ([==[
        int index = int(vbones.x);
        @(arg1 == 1 and [[
            vec4 dqreal = animdata[index];
            vec4 dqdual = animdata[index+1];
        ]] or [=[
            vec4 dqreal = animdata[index] * vweights.x;
            vec4 dqdual = animdata[index+1] * vweights.x;
            index = int(vbones.y);
            dqreal += animdata[index] * vweights.y;
            dqdual += animdata[index+1] * vweights.y;
            @(arg1 >= 3 and [[
                index = int(vbones.z);
                dqreal += animdata[index] * vweights.z;
                dqdual += animdata[index+1] * vweights.z;
            ]] or nil)
            @(arg1 >= 4 and [[
                index = int(vbones.w);
                dqreal += animdata[index] * vweights.w;
                dqdual += animdata[index+1] * vweights.w;
            ]] or nil)
            float len = length(dqreal);
            dqreal /= len;
            dqdual /= len;
        ]=])

        vec4 opos = vec4((cross(dqreal.xyz, cross(dqreal.xyz, gl_Vertex.xyz) + gl_Vertex.xyz*dqreal.w + dqdual.xyz) + dqdual.xyz*dqreal.w - dqreal.xyz*dqdual.w)*2.0 + gl_Vertex.xyz, gl_Vertex.w);

        @((arg2 and arg2 ~= 0) and [[
            vec3 onormal = cross(dqreal.xyz, cross(dqreal.xyz, gl_Normal) + gl_Normal*dqreal.w)*2.0 + gl_Normal;
        ]] or nil)

        @((arg3 and arg3 ~= 0) and [[
            vec3 otangent = cross(dqreal.xyz, cross(dqreal.xyz, vtangent.xyz) + vtangent.xyz*dqreal.w)*2.0 + vtangent.xyz;
        ]] or nil)
    ]==]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3 }) end

shadowmodelvertexshader = function(arg1, arg2, arg3)
    return ([=[
        @((arg3 and arg3 ~= 0) and "uniform vec4 tetramodelclip;" or nil)
        @(((arg1 and #arg1 > 0) or (arg2 and #arg2 > 0)) and [[
            @(arg1)
            void main(void)
            {
                @(arg2)
                gl_Position = gl_ModelViewProjectionMatrix * opos;
        ]] or [[
            void main(void)
            {
                gl_Position = ftransform();
                #define opos gl_Vertex
        ]])
                @((arg3 and arg3 ~= 0) and "gl_ClipDistance[0] = dot(opos, tetramodelclip);" or nil)
            }
    ]=]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3 }) end

CAPI.shader(0, "shadowmodel", shadowmodelvertexshader(), [[
    void main(void)
    {
    }
]])

for i = 1, 4 do
    CAPI.variantshader(0, "shadowmodel", 0, shadowmodelvertexshader(skelanimdefs(i, 0, 0), skelmatanim (i, 0, 0)), "")
    CAPI.variantshader(0, "shadowmodel", 1, shadowmodelvertexshader(skelanimdefs(i, 0, 0), skelquatanim(i, 0, 0)), "") end

if EVAR.glslversion >= 130 then
    CAPI.shader(0, "tetramodel", shadowmodelvertexshader("", "", 1), [[
        void main(void)
        {
        }
    ]])

    for i = 1, 4 do
        CAPI.variantshader(0, "tetramodel", 0, shadowmodelvertexshader(skelanimdefs(i, 0, 0), skelmatanim (i, 0, 0), 1), "")
        CAPI.variantshader(0, "tetramodel", 1, shadowmodelvertexshader(skelanimdefs(i, 0, 0), skelquatanim(i, 0, 0), 1), "") end end

alphashadowmodelvertexshader = function(arg1, arg2, arg3)
    return ([=[
        @((arg3 and arg3 ~= 0) and "uniform vec4 tetramodelclip;" or nil)
        uniform vec4 texscroll;
        @(((arg1 and #arg1 > 0) or (arg2 and #arg2 > 0)) and [[
            @(arg1)
            void main(void)
            {
                @(arg2)
                gl_Position = gl_ModelViewProjectionMatrix * opos;
        ]] or [[
            void main(void)
            {
                gl_Position = ftransform();
                #define opos gl_Vertex
        ]])
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texscroll.yz;
                @((arg3 and arg3 ~= 0) and "gl_ClipDistance[0] = dot(opos, tetramodelclip);" or nil)
            }
    ]=]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2, arg3 = arg3 }) end

CAPI.shader(0, "alphashadowmodel", alphashadowmodelvertexshader(), [[
    uniform sampler2D tex0;
    uniform float alphatest;
    void main(void)
    {
        vec4 color = texture2D(tex0, gl_TexCoord[0].xy);
        if(color.a <= alphatest)    
            discard;
        gl_FragColor = vec4(color.rgb, 1.0);
    }
]])

for i = 1, 4 do
    CAPI.variantshader(0, "alphashadowmodel", 0, alphashadowmodelvertexshader(skelanimdefs(i, 0, 0), skelmatanim (i, 0, 0)), "")
    CAPI.variantshader(0, "alphashadowmodel", 1, alphashadowmodelvertexshader(skelanimdefs(i, 0, 0), skelquatanim(i, 0, 0)), "") end

if EVAR.glslversion >= 130 then
    CAPI.shader(0, "alphashadowtetramodel", alphashadowmodelvertexshader("", "", 1), [[
        uniform sampler2D tex0;
        uniform float alphatest;
        void main(void)
        {
            vec4 color = texture2D(tex0, gl_TexCoord[0].xy);
            if(color.a <= alphatest)    
                discard;
            gl_FragColor = vec4(color.rgb, 1.0);
        }
    ]])

    for i = 1, 4 do
        CAPI.variantshader(0, "alphashadowtetramodel", 0, alphashadowmodelvertexshader(skelanimdefs(i, 0, 0), skelmatanim (i, 0, 0), 1), "")
        CAPI.variantshader(0, "alphashadowtetramodel", 1, alphashadowmodelvertexshader(skelanimdefs(i, 0, 0), skelquatanim(i, 0, 0), 1), "") end end

-- mdltype:
--    a -> alpha test
--    e -> envmap
--    n -> normalmap
--    s -> spec
--    m -> masks
--    B -> matrix skeletal animation
--    b -> dual-quat skeletal animation

modelvertexshader = function(...)
    local arg = { ... }
    local modeltype = arg[1]

    local mdlopt = {
        a = modeltype:find("a") ~= nil,
        e = modeltype:find("e") ~= nil,
        n = modeltype:find("n") ~= nil,
        s = modeltype:find("s") ~= nil,
        m = modeltype:find("m") ~= nil,
        B = modeltype:find("B") ~= nil,
        b = modeltype:find("b") ~= nil,
    }

    return ([==[
        @((mdlopt.b or mdlopt.B) and skelanimdefs(arg[2], 1, mdlopt.n) or nil)
        @(mdlopt.n and [[
            #pragma CUBE2_attrib vtangent 1
            attribute vec4 vtangent;
        ]] or nil)
        uniform vec4 ocamera, texscroll;
        @(mdlopt.n and [[
            varying mat3 world;
            @(mdlopt.e and "varying vec3 camvec;" or nil)
        ]] or [=[
            varying vec3 nvec;
            @(mdlopt.e and [[
                uniform vec4 envmapscale;
                varying vec3 rvec;
                varying float rmod;
            ]])
        ]=])
        @(gdepthinterp())
        void main(void)
        {
            @(mdlopt.B and skelmatanim (arg[2], 1, mdlopt.n) or nil)
            @(mdlopt.b and skelquatanim(arg[2], 1, mdlopt.n) or nil)
            @((mdlopt.b or mdlopt.B) and [[
                gl_Position = gl_ModelViewProjectionMatrix * opos;
            ]] or [[
                gl_Position = ftransform();
                #define opos gl_Vertex
                #define onormal gl_Normal
                #define otangent vtangent.xyz
            ]])

            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texscroll.yz;
    
            @(gdepthpackvert())
 
            @((mdlopt.e or mdlopt.s) and [[
                vec3 camdir = normalize(ocamera.xyz - opos.xyz);
            ]] or nil)
 
            mat3 objmat = mat3(gl_TextureMatrix[0][0].xyz, gl_TextureMatrix[0][1].xyz, gl_TextureMatrix[0][2].xyz);
            @(mdlopt.n and [=[
                @(mdlopt.e and [[
                    camvec = objmat * camdir;
                ]] or nil)
                // composition of tangent -> object and object -> world transforms
                //   becomes tangent -> world
                vec3 wnormal = objmat * onormal;
                vec3 wtangent = objmat * otangent;
                vec3 wbitangent = cross(wnormal, wtangent) * vtangent.w;
                world = mat3(wtangent, wbitangent, wnormal);
            ]=] or [=[
                nvec = objmat * onormal; 
                @(mdlopt.e and [[
                    float invfresnel = dot(camdir, onormal);
                    rvec = objmat * (2.0*invfresnel*onormal - camdir);
                    rmod = envmapscale.x*max(invfresnel, 0.0) + envmapscale.y; 
                ]] or nil)
            ]=])
        }
    ]==]):eval_embedded(nil, { mdlopt = mdlopt, arg = arg }, _G) end

modelfragmentshader = function(...)
    local arg = { ... }
    local modeltype = arg[1]

    local mdlopt = {
        a = modeltype:find("a") ~= nil,
        e = modeltype:find("e") ~= nil,
        n = modeltype:find("n") ~= nil,
        s = modeltype:find("s") ~= nil,
        m = modeltype:find("m") ~= nil,
        B = modeltype:find("B") ~= nil,
        b = modeltype:find("b") ~= nil,
    }

    return ([===[
        @((mdlopt.b or mdlopt.B) and skelanimfragdefs() or nil)
        @(mdlopt.n and [=[
            varying mat3 world; 
            @(mdlopt.e and [[
                uniform vec4 envmapscale;
                varying vec3 camvec;
            ]] or nil)
        ]=] or [=[
            varying vec3 nvec;
            @(mdlopt.e and [[
                varying vec3 rvec;
                varying float rmod;
            ]] or nil)
        ]=])
        @((mdlopt.s or mdlopt.m) and "uniform vec4 maskscale;" or nil)
        @(mdlopt.a and "uniform float alphatest;" or nil)
        uniform sampler2D tex0;
        @(mdlopt.m and "uniform sampler2D tex1;" or nil)
        @(mdlopt.e and "uniform samplerCube tex2;" or nil)
        @(mdlopt.n and "uniform sampler2D tex3;" or nil)
        @(gdepthinterp())
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);

            @(mdlopt.a and [[
                if(diffuse.a <= alphatest)
                    discard;
                gl_FragData[0] = vec4(diffuse.rgb, 1.0);
            ]] or [[
                gl_FragData[0] = diffuse;
            ]])

            @(mdlopt.m and [[
                vec3 masks = texture2D(tex1, gl_TexCoord[0].xy).rgb;
            ]])

            @(mdlopt.n and [[
                vec3 normal = texture2D(tex3, gl_TexCoord[0].xy).rgb - 0.5;
                normal = normalize(world * normal);
            ]] or [[
                vec3 normal = normalize(nvec);
            ]])

            gl_FragData[1].rgb = 0.5*normal+0.5;

            @(mdlopt.s and [[
                float spec = maskscale.x;
                @(mdlopt.m and "spec *= masks.r;" or nil) // specmap in red channel
                gl_FragData[2].a = 0.5*spec;
            ]] or [[
                gl_FragData[2].a = 0.0;
            ]])

            @(mdlopt.m and [==[
                float fade = masks.g;
                gl_FragData[2].rgb = diffuse.rgb*maskscale.y*masks.g; // glow mask in green channel
                @(mdlopt.e and [=[
                    @(mdlopt.n and [[
                        vec3 camn = normalize(camvec);
                        float invfresnel = dot(camn, normal);
                        vec3 rvec = 2.0*invfresnel*normal - camn;
                        float rmod = envmapscale.x*max(invfresnel, 0.0) + envmapscale.y;
                    ]] or nil)
                    vec3 reflect = textureCube(tex2, rvec).rgb; 
                    fade += rmod*masks.b; // envmap mask in blue channel
                    gl_FragData[2].rgb += reflect*(0.5*rmod*masks.b);
                ]=] or nil)
                gl_FragData[0].rgb *= 1.0-fade;
            ]==] or [[
                gl_FragData[2].rgb = vec3(0.0);
            ]])

            @(gdepthpackfrag())
        }
    ]===]):eval_embedded(nil, { mdlopt = mdlopt, arg = arg }, _G) end

modelanimshader = function(arg1, arg2, arg3, arg4)
    local fraganimshader = arg2 > 0 and tostring(arg2) or ""
    local reuseanimshader = fraganimshader
    if EVAR.ati_ubo_bug ~= 0 then
        reuseanimshader = ("%i , %i"):format(arg2, arg2 > 0 and 1 or 0)
        fraganimshader = (arg4 == 1) and modelfragmentshader("bB" .. arg3) or reuseanimshader
    end
    CAPI.variantshader(0, arg1, arg2, modelvertexshader("B" .. arg3, arg4), fraganimshader)
    CAPI.variantshader(0, arg1, arg2 + 1, modelvertexshader("b" .. arg3, arg4), reuseanimshader) end

modelshader = function(arg1, arg2)
    CAPI.defershader(0, arg1, function()
        local basemodeltype = arg2
        CAPI.shader(0, arg1, modelvertexshader(basemodeltype), modelfragmentshader(basemodeltype))
        for i = 1, 4 do
            modelanimshader(arg1, 0, basemodeltype, i) end end) end

--
-- gourad lighting model shader: cheaper, non-specular version for vegetation etc. gets used when spec==0
--

modelshader("nospecmodel", "")
modelshader("masksnospecmodel", "m")
modelshader("envmapnospecmodel", "me")
CAPI.altshader("envmapnospecmodel", "masksnospecmodel")

modelshader("bumpnospecmodel", "n")
modelshader("bumpmasksnospecmodel", "nm")
modelshader("bumpenvmapnospecmodel", "nme")
CAPI.altshader("bumpenvmapnospecmodel", "bumpmasksnospecmodel")

modelshader("nospecalphamodel", "a")
modelshader("masksnospecalphamodel", "am")
modelshader("envmapnospecalphamodel", "ame")
CAPI.altshader("envmapnospecalphamodel", "masksnospecalphamodel")

modelshader("bumpnospecalphamodel", "an")
modelshader("bumpmasksnospecalphamodel", "anm")
modelshader("bumpenvmapnospecalphamodel", "anme")
CAPI.altshader("bumpenvmapnospecalphamodel", "bumpmasksnospecalphamodel")

--
-- phong lighting model shader
--

modelshader("stdmodel", "s")
CAPI.fastshader("stdmodel", "nospecmodel", 1)
modelshader("masksmodel", "sm")
CAPI.fastshader("masksmodel", "masksnospecmodel", 1)
modelshader("envmapmodel", "sme")
CAPI.altshader("envmapmodel", "masksmodel")
CAPI.fastshader("envmapmodel", "envmapnospecmodel", 1)

modelshader("bumpmodel", "ns")
CAPI.fastshader("bumpmodel", "bumpnospecmodel", 1)
modelshader("bumpmasksmodel", "nsm")
CAPI.fastshader("bumpmasksmodel", "bumpmasksnospecmodel", 1)
modelshader("bumpenvmapmodel", "nsme")
CAPI.altshader("bumpenvmapmodel", "bumpmasksmodel")
CAPI.fastshader("bumpenvmapmodel", "bumpenvmapnospecmodel", 1)

modelshader("alphamodel", "as")
CAPI.fastshader("alphamodel", "nospecalphamodel", 1)
modelshader("masksalphamodel", "asm")
CAPI.fastshader("masksalphamodel", "masksnospecalphamodel", 1)
modelshader("envmapalphamodel", "asme")
CAPI.altshader("envmapalphamodel", "masksalphamodel")
CAPI.fastshader("envmapalphamodel", "envmapnospecalphamodel", 1)

modelshader("bumpalphamodel", "ans")
CAPI.fastshader("bumpalphamodel", "bumpnospecalphamodel", 1)
modelshader("bumpmasksalphamodel", "ansm")
CAPI.fastshader("bumpmasksalphamodel", "bumpmasksnospecalphamodel", 1)
modelshader("bumpenvmapalphamodel", "ansme")
CAPI.altshader("bumpenvmapalphamodel", "bumpmasksalphamodel")
CAPI.fastshader("bumpenvmapalphamodel", "bumpenvmapnospecalphamodel", 1)

--
-- deferred shading
--

CAPI.shader(0, "shadowmapworld", [[
    void main(void)
    {
        gl_Position = ftransform();
    }
]], [[
    void main(void)
    {
    }
]])

if EVAR.glslversion >= 130 then
    CAPI.shader(0, "tetraclear", [[
        void main(void)
        {
            gl_Position = gl_Vertex;
        }
    ]], [[
        void main(void)
        {
        }
    ]])

    CAPI.shader(0, "tetraworld", [[
        uniform vec4 tetraclip;
        void main(void)
        {
            gl_Position = ftransform();
            gl_ClipDistance[0] = dot(gl_Vertex, tetraclip); 
        }
    ]], [[
        void main(void)
        {
        }
    ]]) end

-- deferredlighttype:
--    p -> point-light shadow (default cubemap)
--    t -> tetrahedrdal point-light shadow
--    c -> CSM
--    a -> AO
--    A -> AO sun
--    g -> gather filter
--    m -> minimap

deferredlightvariantshader = function(...)
    local arg = { ... }
    local deferredlighttype = arg[3]
    local numsplits = arg[4] + 0
    local numlights = arg[5] + 0
    local baselight = arg[2] < 0 and true or ((arg[2] % 4) < 2)
    local spotlight = arg[2] >= 4

    local dlopt = {
        p = deferredlighttype:find("p") ~= nil,
        t = deferredlighttype:find("t") ~= nil,
        c = deferredlighttype:find("c") ~= nil,
        a = deferredlighttype:find("a") ~= nil,
        A = deferredlighttype:find("A") ~= nil,
        g = deferredlighttype:find("g") ~= nil,
        m = deferredlighttype:find("m") ~= nil
    }

    CAPI.variantshader(0, arg[1], arg[2], arg[2] < 0 and [[
        void main(void)
        {
            gl_Position = gl_Vertex;
        }
    ]] or "", ([===[
        #extension GL_ARB_texture_rectangle : enable
        @(dlopt.g and [[
            #ifdef GL_EXT_gpu_shader4
            #  extension GL_EXT_gpu_shader4 : enable
            #endif
            #ifdef GL_ARB_texture_gather
            #  extension GL_ARB_texture_gather : enable
            #else
            #  ifdef GL_AMD_texture_texture4
            #    extension GL_AMD_texture_texture4 : enable
            #  endif
            #endif
        ]] or nil)
        uniform sampler2DRect tex0, tex1, tex2, tex3;
        @((dlopt.p or dlopt.c) and [=[
            @(dlopt.g and [[
                uniform sampler2D tex4;
            ]] or [[
                uniform sampler2DShadow tex4;
            ]])
        ]=] or nil)
        @(numlights ~= 0 and [==[
            uniform vec4 lightpos[@(numlights)];
            uniform vec3 lightcolor[@(numlights)];
            @(spotlight and "uniform vec4 spotparams[@(numlights)];" or nil)
            @(dlopt.p and [=[
                @(spotlight and [[
                    uniform vec3 spotx[@(numlights)];
                    uniform vec3 spoty[@(numlights)];
                ]] or nil)
                uniform vec4 shadowparams[@(numlights)];
                uniform vec2 shadowoffset[@(numlights)];
            ]=] or nil)
        ]==] or nil)
        @(numsplits ~= 0 and [[
            uniform vec3 splitcenter[@(numsplits)];
            uniform vec3 splitbounds[@(numsplits)];
            uniform vec3 splitscale[@(numsplits)];
            uniform vec3 splitoffset[@(numsplits)];
        ]] or nil)
        @(dlopt.c and [[
            uniform vec3 sunlightdir;
            uniform vec3 sunlightcolor;
        ]] or nil)

        uniform vec3 camera;
        uniform vec2 shadowatlasscale;
        uniform vec4 lightscale;
        @(dlopt.a and "uniform sampler2DRect tex5; uniform vec2 aoscale; uniform vec4 aoparams;" or nil)
        @(gdepthunpackparams)

        @(dlopt.p and [=[
            @(spotlight and [[
                vec3 getspottc(vec3 dir, float spotdist, vec3 spotx, vec3 spoty, vec4 shadowparams, vec2 shadowoffset)
                {
                    vec2 mparams = shadowparams.xy / spotdist;
                    return vec3(vec2(dot(dir, spotx), dot(dir, spoty))*mparams.x + shadowoffset, mparams.y + shadowparams.w);
                }
            ]] or (dlopt.t and [[
                vec3 getshadowtc(vec3 dir, vec4 shadowparams, vec2 shadowoffset)
                {
                    float top = abs(dir.x+dir.y)+dir.z, bottom = abs(dir.x-dir.y)-dir.z;
                    vec2 mparams = shadowparams.xy / max(top, bottom);
                    shadowoffset.x += step(top, bottom)*shadowparams.z;
                    return vec3(dir.xy*mparams.x + shadowoffset, mparams.y + shadowparams.w);
                }
            ]] or [[
                vec3 getshadowtc(vec3 dir, vec4 shadowparams, vec2 shadowoffset)
                {
                    vec3 adir = abs(dir);
                    float m; vec4 proj;
                    if (adir.x > adir.y) { m = adir.x; proj = vec4(dir.zyx, 0.0); } else { m = adir.y; proj = vec4(dir.xzy, 1.0); }
                    if (adir.z > m) { m = adir.z; proj = vec4(dir, 2.0); }
                    vec2 mparams = shadowparams.xy / m;
                    return vec3(proj.xy * mparams.x + vec2(proj.w, step(proj.z, 0.0)) * shadowparams.z + shadowoffset, mparams.y + shadowparams.w);
                }
            ]]))
        ]=] or nil)

        @((dlopt.p or dlopt.c) and [=[
            @(dlopt.g and [[
                #ifdef GL_ARB_texture_gather
                #  define shadowgather(center, xoff, yoff) textureGatherOffset(tex4, center, ivec2(xoff, yoff))
                #else
                #  define shadowgather(center, xoff, yoff) texture4(tex4, center + vec2(xoff, yoff)*shadowatlasscale)
                #endif
                float filtershadow(vec3 shadowtc)
                {
                    vec2 offset = fract(shadowtc.xy - 0.5), center = (shadowtc.xy - offset)*shadowatlasscale;
                    vec4 group1 = step(shadowtc.z, shadowgather(center, -1.0, -1.0));
                    vec4 group2 = step(shadowtc.z, shadowgather(center,  1.0, -1.0));
                    vec4 group3 = step(shadowtc.z, shadowgather(center, -1.0,  1.0));
                    vec4 group4 = step(shadowtc.z, shadowgather(center,  1.0,  1.0));
                    vec4 cols = vec4(group1.rg, group2.rg) + vec4(group3.ab, group4.ab) + mix(vec4(group1.ab, group2.ab), vec4(group3.rg, group4.rg), offset.y);
                    return dot(mix(cols.xyz, cols.yzw, offset.x), vec3(1.0/9.0));
                }
            ]] or [[
                #define shadowval(center, xoff, yoff) shadow2D(tex4, vec3((center.xy + vec2(xoff, yoff))*shadowatlasscale, center.z)).r
                float filtershadow(vec3 shadowtc)
                {
                    return dot(vec4(0.25),
                                vec4(shadowval(shadowtc, -0.4, 1.0),
                                    shadowval(shadowtc, -1.0, -0.4),
                                    shadowval(shadowtc, 0.4, -1.0),
                                    shadowval(shadowtc, 1.0, 0.4))); 
                }
            ]])
        ]=] or nil)
        @(dlopt.c and [=[
            vec3 getcsmtc(vec3 pos)
            {
                pos = (gl_TextureMatrix[1] * vec4(pos, 0.0)).xyz;
                @(([[
                    if(all(lessThan(abs(pos - splitcenter[$j]), splitbounds[$j])))
                        pos = pos*splitscale[$j] + splitoffset[$j];
                    else
                ]]):reppn("$j", 0, numsplits - 1))
                if(all(lessThan(abs(pos.xy - splitcenter[@(numsplits - 1)].xy), splitbounds[@(numsplits - 1)].xy)))
                    pos = pos*splitscale[@(numsplits - 1)] + splitoffset[@(numsplits - 1)];
                else pos = vec3(-1.0);
                return pos;
            }
        ]=] or nil)

        void main(void)
        {
            vec4 diffuse = texture2DRect(tex0, gl_FragCoord.xy);
            vec4 glow = texture2DRect(tex2, gl_FragCoord.xy);
            @(baselight and [=[
                vec3 light = diffuse.rgb * lightscale.rgb;
                @(dlopt.a and [[
                    float ao = texture2DRect(tex5, gl_FragCoord.xy*aoscale).r;
                    light *= aoparams.x + ao*aoparams.y;
                ]] or nil)
                light += glow.rgb * lightscale.a;
            ]=] or [[
                vec3 light = vec3(0.0);
            ]])
            @((numlights > 0 or dlopt.c) and [==[
                vec4 normal = texture2DRect(tex1, gl_FragCoord.xy);
                @(gdepthunpack("depth", "tex3", "gl_FragCoord.xy", [=[
                    @(dlopt.m and [[
                        vec3 pos = (gl_TextureMatrix[0] * vec4(gl_FragCoord.xy, depth, 1.0)).xyz;
                    ]] or [[
                        vec3 pos = (gl_TextureMatrix[0] * vec4(depth*gl_FragCoord.xy, depth, 1.0)).xyz;
                    ]])
                    #define fogcoord depth
                ]=], [[
                    vec4 pos = gl_TextureMatrix[0] * vec4(gl_FragCoord.xy, depth, 1.0);
                    pos.xyz /= pos.w;
                    #define fogcoord dot(gl_ModelViewMatrixTranspose[2], vec4(pos.xyz, 1.0))
                ]]))
                normal.xyz = normal.xyz*2.0 - 1.0;
                @((not dlopt.m) and [[
                    vec3 camdir = normalize(camera - pos.xyz);
                    float facing = 2.0*dot(normal.xyz, camdir);
                ]] or nil)
            ]==] or ((not dlopt.m) and [[
                @(gdepthunpack("depth", "tex3", "gl_FragCoord.xy"))
                #define fogcoord depth
            ]] or nil))
            @(dlopt.c and [==[
                float sunfacing = dot(sunlightdir, normal.xyz);
                if(sunfacing > 0.0)
                {
                    vec3 csmtc = getcsmtc(pos.xyz);
                    float sunoccluded = sunfacing * filtershadow(csmtc);
                    @(dlopt.A and "sunoccluded *= aoparams.z + ao*aoparams.w;" or nil)
                    @(dlopt.m and [[
                        light += diffuse.rgb * sunlightcolor * sunoccluded;
                    ]] or [[
                        float sunspec = pow(max(sunfacing*facing - dot(camdir, sunlightdir), 0.0), 8.0) * glow.a;
                        light += (diffuse.rgb + sunspec) * sunlightcolor * sunoccluded;
                    ]])
                }
            ]==] or nil)
            @(([==[
                vec3 light$jdir = (pos.xyz - lightpos[$j].xyz) * lightpos[$j].w;
                float light$jdist2 = dot(light$jdir, light$jdir);
                float light$jfacing = dot(light$jdir, normal.xyz);
                if(light$jdist2 < 1.0 && light$jfacing < 0.0)
                {
                    float light$jinvdist = inversesqrt(light$jdist2);
                    @(spotlight and [[
                        float spot$jdist = dot(light$jdir, spotparams[$j].xyz);
                        float spot$jatten = light$jinvdist * spot$jdist - spotparams[$j].w;
                        if(spot$jatten > 0.0)
                        {
                    ]] or nil)
                    float light$jatten = light$jfacing * (1.0 - light$jinvdist);
                    @(spotlight and [=[
                        @(dlopt.p and [[
                            vec3 spot$jtc = getspottc(light$jdir, spot$jdist, spotx[$j], spoty[$j], shadowparams[$j], shadowoffset[$j]);
                            light$jatten *= spot$jatten * filtershadow(spot$jtc);
                        ]] or [[
                            light$jatten *= spot$jatten;
                        ]])
                    ]=] or [=[
                        @(dlopt.p and [[
                            vec3 shadow$jtc = getshadowtc(light$jdir, shadowparams[$j], shadowoffset[$j]);
                            light$jatten *= filtershadow(shadow$jtc);
                        ]] or nil)
                    ]=])
                    @(dlopt.m and [[
                        light += diffuse.rgb * lightcolor[$j] * light$jatten;
                    ]] or [[
                        float light$jspec = pow(max(light$jinvdist*(dot(camdir, light$jdir) - light$jfacing*facing), 0.0), 8.0) * glow.a;
                        light += (diffuse.rgb + light$jspec) * lightcolor[$j] * light$jatten;
                    ]])
                    @(spotlight and "}" or nil)
                }
            ]==]):reppn("$j", 0, numlights))
            @(dlopt.m and (baselight and [[
                gl_FragColor.rgb = light;
                gl_FragColor.a = diffuse.a;
            ]] or [[
                gl_FragColor.rgb = light;
                gl_FragColor.a = 0.0;
            ]]) or [=[
                float foglerp = clamp((gl_Fog.end + fogcoord) * gl_Fog.scale, 0.0, 1.0);
                @(baselight and [[
                    gl_FragColor.rgb = mix(gl_Fog.color.rgb*diffuse.a, light, foglerp);
                    gl_FragColor.a = diffuse.a;
                ]] or [[
                    gl_FragColor.rgb = light*foglerp;
                    gl_FragColor.a = 0.0;
                ]])
            ]=])
        }
    ]===]):eval_embedded(nil, { dlopt = dlopt, numsplits = numsplits, numlights = numlights, baselight = baselight, spotlight = spotlight }, _G), 64) end

deferredlightshader = function(arg1, arg2, arg3, arg4)
    local shadername = "deferredlight" .. arg1 .. arg2 .. arg3
    deferredlightvariantshader(shadername, -1, arg1 .. arg3, arg4, 0) -- base shader, no point lights, sunlight
    for i = 1, 8 do
        deferredlightvariantshader(shadername, 0, arg1 .. arg3,         arg4, i) -- row 0, point lights, sunlight
        deferredlightvariantshader(shadername, 1, arg1 .. arg2 .. arg3, arg4, i) -- row 1, shadowed point lights, sunlight
        deferredlightvariantshader(shadername, 2, arg1,                 arg4, i) -- row 2, point lights
        deferredlightvariantshader(shadername, 3, arg1 .. arg2,         arg4, i) -- row 3, shadowed point lights
        deferredlightvariantshader(shadername, 4, arg1 .. arg3,         arg4, i) -- row 4, spot lights, sunlight
        deferredlightvariantshader(shadername, 5, arg1 .. arg2 .. arg3, arg4, i) -- row 5, shadowed spot lights, sunlight
        deferredlightvariantshader(shadername, 6, arg1,                 arg4, i) -- row 6, spot lights
        deferredlightvariantshader(shadername, 7, arg1 .. arg2,         arg4, i) end end -- ow 7, shadowed spot lights

CAPI.shader(0, "hdrreduce", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    void main(void)
    {
        gl_FragColor.rgb = texture2DRect(tex0, gl_TexCoord[0].xy).rgb;
    }
]])

CAPI.shader(0, "hdrreduce2", [[
    uniform vec2 reducestep;
    varying vec2 tap0, tap1, tap2, tap3;
    void main(void)
    {
        gl_Position = gl_Vertex;
        tap0 = gl_MultiTexCoord0.xy + vec2(-1.0, -1.0)*reducestep;
        tap1 = gl_MultiTexCoord0.xy + vec2( 1.0, -1.0)*reducestep;
        tap2 = gl_MultiTexCoord0.xy + vec2( 1.0,  1.0)*reducestep;
        tap3 = gl_MultiTexCoord0.xy + vec2(-1.0,  1.0)*reducestep;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    varying vec2 tap0, tap1, tap2, tap3;
    void main(void)
    {
        gl_FragColor.rgb = 0.25*(texture2DRect(tex0, tap0).rgb + texture2DRect(tex0, tap1).rgb +
                                 texture2DRect(tex0, tap2).rgb + texture2DRect(tex0, tap3).rgb);
    }
]])

--lumweights = "0.2126, 0.7152, 0.0722"
lumweights = "0.299, 0.587, 0.114"

CAPI.shader(0, "hdrluminance", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_TexCoord[0].xy).rgb;
        float lum = dot(color, 2.0*vec3(@(lumweights)));
        float loglum = (log2(lum + 1.0/511.0) + 9.0) * (1.0/(9.0+1.0));// allow values as low as 2^-9, and as high 2^1, with 2^-9ish epsilon
        gl_FragColor.rgb = vec3(loglum);
    }
]]):eval_embedded(nil, { lumweights = lumweights }))

CAPI.shader(0, "hdrluminance2", [[
    uniform vec2 reducestep;
    varying vec2 tap0, tap1, tap2, tap3;
    void main(void)
    {
        gl_Position = gl_Vertex;
        tap0 = gl_MultiTexCoord0.xy + vec2(-1.0, -1.0)*reducestep;
        tap1 = gl_MultiTexCoord0.xy + vec2( 1.0, -1.0)*reducestep;
        tap2 = gl_MultiTexCoord0.xy + vec2( 1.0,  1.0)*reducestep;
        tap3 = gl_MultiTexCoord0.xy + vec2(-1.0,  1.0)*reducestep;
    }
]], ([=[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    varying vec2 tap0, tap1, tap2, tap3;
    void main(void)
    {
        @(([[
            vec3 color$i = texture2DRect(tex0, tap$i).rgb;
            float lum$i = dot(color$i, 2.0*vec3(@(lumweights)));
            // allow values as low as 2^-9, and as high 2^1, with 2^-9ish epsilon
            float loglum$i = (log2(lum$i + 1.0/511.0) + 9.0) * (1.0/(9.0+1.0));
        ]]):reppn("$i", 0, 4))
        gl_FragColor.rgb = vec3(0.25*(loglum0 + loglum1 + loglum2 + loglum3));
    }
]=]):eval_embedded(nil, { lumweights = lumweights }, _G))

CAPI.shader(0, "hdraccum", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    uniform float accumscale;
    void main(void)
    {
        float lum = exp2((texture2DRect(tex0, gl_TexCoord[0].xy).r * (9.0+1.0)) - 9.0) - 1.0/511.0;
        gl_FragColor = vec4(vec3(lum*0.5), accumscale);
    }
]])

CAPI.shader(0, "hdrbloom", [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex2; 
    uniform vec4 bloomparams;
    varying float lumscale;
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        float avglum = 2.0*texture2DRect(tex2, vec2(0.5, 0.5)).r;
        lumscale = bloomparams.x/clamp(avglum, bloomparams.z, bloomparams.w);
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    uniform vec4 bloomparams;
    varying float lumscale;
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_TexCoord[0].xy).rgb*2.0;
        float lum = dot(color, vec3(@(lumweights)));
        color *= (1.0 - exp2(min(lum*lumscale + bloomparams.y, 0.0))) / (lum + 1.0e-4);
        gl_FragColor.rgb = color;
    }
]]):eval_embedded(nil, { lumweights = lumweights }))

CAPI.shader(0, "hdrtonemap", [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex2; 
    uniform vec4 hdrparams;
    uniform vec2 bloomsize;
    varying float lumscale;
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        gl_TexCoord[1].xy = (gl_Vertex.xy*0.5 + 0.5)*bloomsize;
        float avglum = 2.0*texture2DRect(tex2, vec2(0.5, 0.5)).r;
        lumscale = hdrparams.x/avglum;
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0, tex1;
    uniform vec4 hdrparams;
    varying float lumscale;
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_TexCoord[0].xy).rgb*2.0;
        vec3 bloom = texture2DRect(tex1, gl_TexCoord[1].xy).rgb*hdrparams.y;
        float lum = dot(color, vec3(@(lumweights)));       
        color *= clamp((1.0 - exp2(lum*lumscale)) / (lum + 1.0e-4), hdrparams.z, hdrparams.w);
        gl_FragColor.rgb = color + bloom;
    }
]]):eval_embedded(nil, { lumweights = lumweights }))

CAPI.shader(0, "hdrnop", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        gl_FragColor = texture2DRect(tex0, gl_FragCoord.xy);
    }
]])

aotapoffsets = {
    "-0.933103, 0.025116",
    "-0.432784, -0.989868",
    "0.432416, -0.413800",
    "-0.117770, 0.970336",
    "0.837276, 0.531114",
    "-0.184912, 0.200232",
    "-0.955748, 0.815118",
    "0.946166, -0.998596",
    "-0.897519, -0.581102",
    "0.979248, -0.046602",
    "-0.155736, -0.488204",
    "0.460310, 0.982178"
}

ambientobscurancevariantshader = function(arg1, arg2, arg3)
    local lineardepth = arg2:find("l") ~= 0
    local maxaotaps   = arg3
    CAPI.shader(0, arg1, [[
        void main(void)
        {
            gl_Position = gl_Vertex;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            gl_TexCoord[1].xy = gl_MultiTexCoord1.xy;
        }
    ]], ([=[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0, tex1;
        uniform sampler2D tex2;
        uniform vec4 tapparams, offsetscale;
        @(lineardepth and [[
            #define depthtc gl_FragCoord.xy
        ]] or [[
            #define depthtc gl_TexCoord[0].xy
        ]])
        @(gdepthunpackparams)
        void main(void)
        {
            @(gdepthunpack("depth", "tex0", "depthtc", [[
                vec2 tapscale = tapparams.xy/depth;
            ]], [[
                float w = depth*gdepthscale.y + gdepthscale.z;
                depth = gdepthscale.x/w;
                vec2 tapscale = tapparams.xy*w;
            ]], lineardepth))
            vec2 pos = depth*(depthtc*offsetscale.xy + offsetscale.zw);
            vec3 normal = texture2DRect(tex1, gl_TexCoord[0].xy).rgb*2.0 - 1.0;
            normal = (gl_ModelViewMatrix * vec4(normal, 0.0)).xyz;
            vec2 noise = texture2D(tex2, gl_TexCoord[1].xy).rg*2.0-1.0;
            float obscure = 0.0;
            @(([[
                vec2 offset$i = reflect(vec2(@(aotapoffsets[$i + 1])), noise);
                offset$i = depthtc + tapscale * offset$i;
                @(gdepthunpack("depth$i", "tex0", "offset$i.xy", "", "", lineardepth))
                vec3 v$i = vec3(depth$i*(offset$i.xy*offsetscale.xy + offsetscale.zw) - pos, depth$i - depth);
                obscure += max(0.0, dot(v$i, normal) + depth*1.0e-2) / (dot(v$i, v$i) + 1.0e-5);
            ]]):reppn("$i", 0, maxaotaps))
            gl_FragColor.rg = vec2(pow(max(1.0 - tapparams.z*obscure, 0.0), tapparams.w), depth);
        }
    ]=]):eval_embedded(nil, { lineardepth = lineardepth, maxaotaps = maxaotaps }, _G)) end

ambientobscuranceshader = function(arg1, arg2)
    ambientobscurancevariantshader(("ambientobscurance%s%i"):format(arg1, arg2), arg1, arg2) end

CAPI.shader(0, "linearizedepth", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    @(gdepthunpackparams)
    void main(void)
    {
        @(gdepthunpack("depth", "tex0", "gl_TexCoord[0].xy"))
        gl_FragColor.r = depth;
    }
]]):eval_embedded())

bilateralvariantshader = function(arg1, arg2, arg3, arg4)
    local reduced   = arg2:find("r") ~= nil
    local linear    = arg2:find("l") ~= nil
    local packed    = arg2:find("l") ~= nil
    local numtaps   = arg3
    local filterdir = arg4
    CAPI.shader(0, arg1, ([[
        void main(void)
        {
            gl_Position = gl_Vertex;
            @((not linear and reduced) and "gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;" or nil)
        }
    ]]):eval_embedded(nil, { linear = linear, reduced = reduced }), ([===[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0;
        @(not packed and "uniform sampler2DRect tex1;" or nil)
        uniform vec4 bilateralparams;
        @(filterdir == "x" and [[
            #define tapoffset(i) vec2(i, 0.0)
            #define viewoffset(i) vec2(i*bilateralparams.z, 0.0)
        ]] or [[
            #define tapoffset(i) vec2(0.0, i)
            #define viewoffset(i) vec2(0.0, i*bilateralparams.w)
        ]])
        @(gdepthunpackparams)
        void main(void)
        {
            @(linear and (packed and [[
                vec2 vals = texture2DRect(tex0, gl_FragCoord.xy).rg;
                #define depth vals.y
                #define color vals.x
            ]] or [[
                vec2 tc = gl_FragCoord.xy;
                float depth = texture2DRect(tex1, tc).r;
                float color = texture2DRect(tex0, tc).r;
            ]]) or (reduced and [[
                @(gdepthunpack("depth", "tex1", "gl_TexCoord[0].xy"))
                float color = texture2DRect(tex0, gl_FragCoord.xy).r;
            ]] or [[
                vec2 tc = gl_FragCoord.xy;
                @(gdepthunpack("depth", "tex1", "tc"))
                float color = texture2DRect(tex0, tc).r;
            ]]))
            float weights = 1.0;
            @(([==[
                @(
                    local curtap = $i - numtaps
                    if curtap >= 0 then curtap = curtap + 1 end
                    local ret = ([=[
                        @(linear and (packed and [[
                            vec2 vals$i = texture2DRect(tex0, gl_FragCoord.xy + tapoffset(@(("%.1f"):format($curtap)))).rg;
                            #define depth$i vals$i.y
                            #define color$i vals$i.x
                        ]] or [[
                            vec2 tc$i = gl_FragCoord.xy + tapoffset(@(("%.1f"):format($curtap)));
                            float depth$i = texture2DRect(tex1, tc$i).r;
                            float color$i = texture2DRect(tex0, tc$i).r;
                        ]]) or (reduced and [[
                            @(gdepthunpack("depth$i", "tex1", "gl_TexCoord[0].xy + viewoffset(@(("%.1f"):format($curtap)))"))
                            float color$i = texture2DRect(tex0, gl_FragCoord.xy + tapoffset(@(("%.1f"):format($curtap)))).r;
                        ]] or [[
                            vec2 tc$i = gl_FragCoord.xy + tapoffset(@(("%.1f"):format($curtap)));
                            @(gdepthunpack("depth$i", "tex1", "tc$i"))
                            float color$i = texture2DRect(tex0, tc$i).r;
                        ]]))
                        depth$i -= depth;
                        float weight$i = exp(@(("%.1f"):format(0 - $curtap * $curtap))*bilateralparams.x - depth$i*depth$i*bilateralparams.y); 
                        weights += weight$i;
                        color += weight$i * color$i;
                    ]=]):gsub("$curtap", tostring(curtap))
                    return ret
                )
            ]==]):reppn("$i", 0, 2 * numtaps))
            @(packed and [[
                gl_FragColor.rg = vec2(color / weights, depth);
            ]] or [[
                gl_FragColor.rgb = vec3(color / weights);
            ]])
        }
    ]===]):eval_embedded(nil, { reduced = reduced, linear = linear, packed = packed, numtaps = numtaps, filterdir = filterdir }, _G)) end

bilateralshader = function(arg1, arg2)
    bilateralvariantshader(("bilateralx%s%i"):format(arg1, arg2), arg1, arg2, "x")
    bilateralvariantshader(("bilateraly%s%i"):format(arg1, arg2), arg1, arg2, "y") end


--
-- buffer splitting / merging
--

CAPI.shader(0, "buffersplit", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex;
    uniform vec2 rcptiledim;
    uniform vec2 tiledim;
    uniform vec2 split;
    void main(void)
    {
        vec2 tile = gl_FragCoord.xy * rcptiledim;
        vec2 block = gl_FragCoord.xy - tiledim * floor(gl_FragCoord.xy * rcptiledim);
        vec2 coord = tile + block * split;
        gl_FragColor.rgb = texture2DRect(tex, coord).rgb;
    }
]])

CAPI.shader(0, "buffermerge", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex;
    uniform vec2 tiledim;
    uniform vec2 split;
    uniform vec2 rcpsplit;
    void main(void)
    {
        vec2 block = gl_FragCoord.xy * rcpsplit;
        vec2 tile = gl_FragCoord.xy - split * floor(gl_FragCoord.xy * rcpsplit);
        vec2 coord = tile * tiledim + block;
        gl_FragColor.rgb = texture2DRect(tex, coord).rgb;
    }
]])

--
-- separable blur with up to 7 taps
--

blurshader = function(...)
    local arg = { ... }
    CAPI.shader(0, arg[1], ([=[
        uniform vec4 offsets;
        void main(void)
        {
            gl_Position = gl_Vertex;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            vec2 tc1 = gl_MultiTexCoord0.xy + offsets.xy;
            vec2 tc2 = gl_MultiTexCoord0.xy - offsets.xy;
            gl_TexCoord[1].xy = tc1;
            gl_TexCoord[2].xy = tc2;
            @(([[
                tc1.@(arg[3]) += offsets.@(({ "z", "w" })[$i + 1]);
                tc2.@(arg[3]) -= offsets.@(({ "z", "w" })[$i + 1]);
                gl_TexCoord[@($i * 2 + 3)].xy = tc1;
                gl_TexCoord[@($i * 2 + 4)].xy = tc2;
            ]]):reppn("$i", 0, math.min(arg[2] - 1, 2)))
        }
    ]=]):eval_embedded(nil, { arg = arg }, _G), ([==[
        @(arg[4] == "2DRect" and [[
            #extension GL_ARB_texture_rectangle : enable
        ]] or nil)
        uniform vec4 weights, weights2, offset4, offset5, offset6, offset7;
        uniform @("sampler" .. arg[4]) tex0;
        void main(void)
        {
            #define texval(coords) @("texture" .. arg[4])(tex0, (coords))
            vec4 val = texval(gl_TexCoord[0].xy) * weights.x;
            @(([=[
                @($i < 3 and [[
                    val += weights.@(({ "y", "z", "w" })[$i + 1]) * (texval(gl_TexCoord[@($i * 2 + 1)].xy) + texval(gl_TexCoord[@($i * 2 + 2)].xy));
                ]] or [[
                    val += weights2.@(({ "x", "y", "z", "w" })[$i - 2]) * 
                                (texval(gl_TexCoord[0].xy + @(({ "offset4", "offset5", "offset6", "offset7" })[$i - 2]).xy) +
                                 texval(gl_TexCoord[0].xy - @(({ "offset4", "offset5", "offset6", "offset7" })[$i - 2]).xy));
                ]])
            ]=]):reppn("$i", 0, arg[2]))
            gl_FragColor = val;
        }
    ]==]):eval_embedded(nil, { arg = arg }, _G)) end

for i = 1, 7 do
    blurshader(("blurx%i"):format(i), i, "x", "2D")
    blurshader(("blury%i"):format(i), i, "y", "2D")
    if i > 1 then
        CAPI.altshader(("blurx%i"):format(i), ("blurx%i"):format(i - 1))
        CAPI.altshader(("blury%i"):format(i), ("blury%i"):format(i - 1)) end
    if EVAR.usetexrect ~= 0 then
        blurshader(("blurx%irect"):format(i), i, "x", "2DRect")
        blurshader(("blury%irect"):format(i), i, "y", "2DRect")
        if i > 1 then
            CAPI.altshader(("blurx%irect"):format(i), ("blurx%irect"):format(i - 1))
            CAPI.altshader(("blury%irect"):format(i), ("blury%irect"):format(i - 1)) end end end

--
-- full screen shaders: 
--

fsvs = [[
    void main(void)
    {
        gl_Position = gl_Vertex;   // woohoo, no mvp :) 
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
]]

fsps = [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    void main(void)
    {
        vec4 sample = texture2DRect(tex0, gl_TexCoord[0].xy);
]]

setup4corners = [[
    gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(-1.5, -1.5);
    gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2( 1.5, -1.5);
    gl_TexCoord[3].xy = gl_MultiTexCoord0.xy + vec2(-1.5,  1.5);
    gl_TexCoord[4].xy = gl_MultiTexCoord0.xy + vec2( 1.5,  1.5);
]]

sample4corners = [[
    vec4 s00 = texture2DRect(tex0, gl_TexCoord[1].xy);
    vec4 s02 = texture2DRect(tex0, gl_TexCoord[2].xy);
    vec4 s20 = texture2DRect(tex0, gl_TexCoord[3].xy);
    vec4 s22 = texture2DRect(tex0, gl_TexCoord[4].xy);
]]

-- some simple ones that just do an effect on the RGB value...

lazyshader(0, "invert", "@(fsvs) }", "@(fsps) gl_FragColor = 1.0 - sample; }")
lazyshader(0, "gbr",    "@(fsvs) }", "@(fsps) gl_FragColor = sample.yzxw; }")
lazyshader(0, "bw",     "@(fsvs) }", "@(fsps) gl_FragColor = vec4(dot(sample.xyz, vec3(0.333))); }")

-- sobel

lazyshader(0, "sobel", "@(fsvs) @(setup4corners) }", [[
    @(fsps)
    @(sample4corners)
        vec4 t = s00 + s20 - s02 - s22;
        vec4 u = s00 + s02 - s20 - s22;
        gl_FragColor = sample + t*t + u*u;
    }
]])

-- rotoscope

lazyshader(0, "rotoscope", [[
    uniform vec4 params;
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;

        // stuff two sets of texture coordinates into each one to get around hardware attribute limits
        gl_TexCoord[1] = vec4(-1.0, -1.0,  1.0, 0.0)*params.x + gl_MultiTexCoord0.xyyx;
        gl_TexCoord[2] = vec4(-1.0,  0.0, -1.0, 1.0)*params.x + gl_MultiTexCoord0.xyyx;
        gl_TexCoord[3] = vec4(-1.0,  1.0,  0.0, 1.0)*params.x + gl_MultiTexCoord0.xyyx;
        gl_TexCoord[4] = vec4( 0.0, -1.0,  1.0, 1.0)*params.x + gl_MultiTexCoord0.xyyx;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    void main(void)
    {
        #define t11 gl_TexCoord[0]
        #define t00_12 gl_TexCoord[1]
        #define t01_20 gl_TexCoord[2]
        #define t02_21 gl_TexCoord[3]
        #define t10_22 gl_TexCoord[4]
        vec4 c00 = texture2DRect(tex0, t00_12.xy);
        vec4 c01 = texture2DRect(tex0, t01_20.xy);
        vec4 c02 = texture2DRect(tex0, t02_21.xy);
        vec4 c10 = texture2DRect(tex0, t10_22.xy);
        vec4 c11 = texture2DRect(tex0, t11.xy);
        vec4 c12 = texture2DRect(tex0, t00_12.wz);
        vec4 c20 = texture2DRect(tex0, t01_20.wz);
        vec4 c21 = texture2DRect(tex0, t02_21.wz);
        vec4 c22 = texture2DRect(tex0, t10_22.wz);

        vec4 diag1 = c00 - c22;
        vec4 diag2 = c02 - c20;
        vec4 xedge = (c01 - c21)*2.0 + diag1 + diag2;
        vec4 yedge = (c10 - c12)*2.0 + diag1 - diag2;
        xedge *= xedge;
        yedge *= yedge;

        vec4 xyedge = xedge + yedge;
        float sobel = step(max(xyedge.x, max(xyedge.y, xyedge.z)), 0.1);

        float hue = dot(c11.xyz, vec3(1.0));
        c11 /= hue;
        vec3 cc = step(vec3(0.2, 0.8, 1.5), vec3(hue));
        c11 *= dot(cc, vec3(0.5, 0.5, 1.5)); 
        
        gl_FragColor = c11 * max(cc.z, sobel);
    }
]])

blur3shader = function(arg1, arg2, arg3)
    lazyshader(0, arg1, ([[
        void main(void)
        {
            gl_Position = gl_Vertex;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(@(arg2 and -0.5 or 0.0), @(arg3 and -0.5 or 0.0));
            gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(@(arg2 and  0.5 or 0.0), @(arg3 and  0.5 or 0.0));
        }
    ]]):eval_embedded(nil, { arg2 = arg2, arg3 = arg3 }), [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0; 
        void main(void)
        {
            gl_FragColor = 0.5*(texture2DRect(tex0, gl_TexCoord[0].xy) + texture2DRect(tex0, gl_TexCoord[1].xy));
        }
    ]]) end
blur3shader("hblur3", 1, 0)
blur3shader("vblur3", 0, 1)

blur5shader = function(arg1, arg2, arg3)
    lazyshader(0, arg1, ([[
        void main(void)
        {
            gl_Position = gl_Vertex;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(@(arg2 and -1.333 or 0.0), @(arg3 and -1.333 or 0.0));
            gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(@(arg2 and  1.333 or 0.0), @(arg3 and  1.333 or 0.0));
        }
    ]]):eval_embedded(nil, { arg2 = arg2, arg3 = arg3 }), [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0; 
        void main(void)
        {
            gl_FragColor = 0.4*texture2DRect(tex0, gl_TexCoord[0].xy) + 0.3*(texture2DRect(tex0, gl_TexCoord[1].xy) + texture2DRect(tex0, gl_TexCoord[2].xy));
        }
    ]]) end
blur5shader("hblur5", 1, 0)
blur5shader("vblur5", 0, 1)

rotoscope = function(...)
    local arg = { ... }
    CAPI.clearpostfx()
    if #arg >= 1 then CAPI.addpostfx("rotoscope", 0, 0, 0, arg[1]) end
    if #arg >= 2 then
        if arg[2] == 1 then
            CAPI.addpostfx("hblur3")
            CAPI.addpostfx("vblur3") end
        if arg[2] == 2 then
            CAPI.addpostfx("hblur5")
            CAPI.addpostfx("vblur5") end end end

-- bloom-ish

lazyshader(0, "bloom_scale", "@(fsvs) @(setup4corners) }", [[
    @(fsps)
    @(sample4corners)
        gl_FragColor = 0.2 * (s02 + s00 + s22 + s20 + sample);
    }
]])

lazyshader(0, "bloom_init", "@(fsvs) }", [[
    @(fsps)
        float t = max(sample.r, max(sample.g, sample.b));
        gl_FragColor = t*t*sample;
    }
]])

bloomshader = function(arg1, arg2)
    CAPI.defershader(0, arg1, function()
        CAPI.forceshader("bloom_scale")
        CAPI.forceshader("bloom_init")
        CAPI.shader(0, arg1, ([=[
            void main(void)
            {
                gl_Position = gl_Vertex;
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
                vec2 tc = gl_MultiTexCoord0.xy;
                @(([[
                    tc *= 0.5;
                    gl_TexCoord[$i].xy = tc;
                ]]):reppn("$i", 1, arg2))
            }
        ]=]):eval_embedded(nil, { arg2 = arg2 }, _G), ([=[
            #extension GL_ARB_texture_rectangle : enable
            uniform vec4 params;
            uniform sampler2DRect tex0 @((", tex$i"):reppn("$i", 1, arg2)); 
            void main(void)
            {
                vec4 sample = texture2DRect(tex0, gl_TexCoord[0].xy);
                @(([[
                    @($i > 1 and "bloom +=" or "vec4 bloom =") texture2DRect(tex$i, gl_TexCoord[$i].xy);
                ]]):reppn("$i", 1, arg2))
                gl_FragColor = bloom*params.x + sample;
            }
        ]=]):eval_embedded(nil, { arg2 = arg2 }, _G)) end) end

bloomshader("bloom1", 1)
bloomshader("bloom2", 2)
bloomshader("bloom3", 3)
bloomshader("bloom4", 4)
bloomshader("bloom5", 5)
bloomshader("bloom6", 6)

setupbloom = function(arg1, arg2)
    CAPI.addpostfx("bloom_init", 1, 1, "+0")
    for i = 1, arg1 - 1 do
        CAPI.addpostfx("bloom_scale", i + 1, i + 1, "+" .. i) end
    CAPI.addpostfx("bloom" .. arg1, 0, 0, ("$i"):reppn("$i", 0, arg1 + 1), arg2) end

bloom = function(arg1)
    CAPI.clearpostfx()
    if arg1 then setupbloom(6, arg1) end end

--
-- miscellaneous effect shaders: 
--

-- wobbles the vertices of an explosion sphere
-- and generates all texcoords 
-- and blends the edge color
-- and modulates the texture
explosionshader = function(arg1, arg2, arg3)
    CAPI.shader(0, arg1, ([=[
        #pragma CUBE2_fog
        uniform vec4 center, animstate;
        @(arg1:find("3d")   ~= nil and "uniform vec4 texgenS, texgenT;" or nil)
        @(arg1:find("soft") ~= nil and [[
            uniform vec4 softparams;
            varying float softdepth;
        ]] or nil)
        void main(void)
        {
            vec4 wobble = vec4(gl_Vertex.xyz*(1.0 + 0.5*abs(fract(dot(gl_Vertex.xyz, center.xyz) + animstate.w*0.002) - 0.5)), gl_Vertex.w);
            gl_Position = gl_ModelViewProjectionMatrix * wobble;
            @(arg1:find("soft") ~= nil and [[
                softdepth = softparams.y + (gl_ModelViewMatrix * wobble).z*softparams.x;
            ]] or nil)

            gl_FrontColor = gl_Color;

            @(arg2)
        }
    ]=]):eval_embedded(nil, { arg1 = arg1, arg2 = arg2 }), ([=[
        @(arg1:find("soft") ~= nil and [[
            #extension GL_ARB_texture_rectangle : enable
            uniform sampler2DRect tex2;
            uniform vec4 softparams;
            varying float softdepth;
            @(gdepthunpackparams)
        ]] or nil)
        uniform sampler2D tex0, tex1;
        void main(void)
        {
            vec2 dtc = gl_TexCoord[0].xy + texture2D(tex0, @(arg3).xy).xy*0.1; // use color texture as noise to distort texcoords
            vec4 diffuse = texture2D(tex0, dtc);
            vec4 blend = texture2D(tex1, gl_TexCoord[1].xy); // get blend factors from modulation texture 
            diffuse *= blend.a*4.0; // dup alpha into RGB channels + intensify and over saturate
            diffuse.b += 0.5 - blend.a*0.5; // blue tint 

            @(arg1:find("soft") ~= nil and [[
                gl_FragColor.rgb = diffuse.rgb * gl_Color.rgb;

                @(gdepthunpack("depth", "tex2", "gl_FragCoord.xy"))
                gl_FragColor.a = diffuse.a * max(clamp(depth*softparams.x - softdepth, 0.0, 1.0) * gl_Color.a, softparams.w);
            ]] or [[
                gl_FragColor = diffuse * gl_Color;
            ]])
        }
    ]=]):eval_embedded(nil, { arg1 = arg1, arg3 = arg3 }, _G)) end

for i = 1, 2 do
    explosionshader("explosion2d" .. ({ "", "soft" })[i], [[
        //blow up the tex coords
        float dtc = 1.768 - animstate.x*1.414; // -2, 2.5; -> -2*sqrt(0.5), 2.5*sqrt(0.5);
        dtc *= dtc;
        gl_TexCoord[0].xy = animstate.w*0.0004 + dtc*gl_Vertex.xy;
        gl_TexCoord[1].xy = gl_Vertex.xy*0.5 + 0.5; //using wobble makes it look too spherical at a distance
    ]], "gl_TexCoord[1]")
    explosionshader("explosion3d" .. ({ "", "soft" })[i], [[
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        vec2 texgen = vec2(dot(texgenS, gl_Vertex), dot(texgenT, gl_Vertex)); 
        gl_TexCoord[1].xy = texgen;
        gl_TexCoord[2].xy = texgen - animstate.w*0.0005;
    ]], "gl_TexCoord[2]") end

CAPI.shader(0, "particlenotexture", [[
    #pragma CUBE2_fog
    uniform vec4 colorscale;
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_Color * colorscale;
    } 
]], [[
    void main(void)
    {
        gl_FragColor = gl_TexCoord[0];
    }
]])

particleshader = function(arg1)
    CAPI.shader(0, arg1, ([=[
        #pragma CUBE2_fog
        uniform vec4 colorscale;
        @(arg1:find("soft") ~= nil and [[
            uniform vec4 softparams;
            varying float softdepth;
        ]] or nil)
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            gl_TexCoord[1] = gl_Color * colorscale; 

            @(arg1:find("soft") ~= nil and [[
                vec2 offset = gl_MultiTexCoord0.xy*2.82842712474619 - 1.4142135623731;
                gl_TexCoord[2].xyz = vec3(offset, 1.0);
                gl_TexCoord[3].xyz = vec3(offset, softparams.y + (gl_ModelViewMatrix * gl_Vertex).z*softparams.x);
            ]] or nil)
        }
    ]=]):eval_embedded(nil, { arg1 = arg1 }), ([=[
        @(arg1:find("soft") ~= nil and [[
            #extension GL_ARB_texture_rectangle : enable
            uniform sampler2DRect tex2;
            uniform vec4 softparams;
            varying float softdepth;
            @(gdepthunpackparams)
        ]] or nil)
        uniform sampler2D tex0;
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);

            @(arg1:find("soft") ~= nil and [[
                @(gdepthunpack("depth", "tex2", "gl_FragCoord.xy"))
                diffuse.a *= clamp(depth*softparams.x - dot(gl_TexCoord[2].xyz, gl_TexCoord[3].xyz), 0.0, 1.0);
            ]] or nil)

            gl_FragColor = diffuse * gl_TexCoord[1];
        }
    ]=]):eval_embedded(nil, { arg1 = arg1 }, _G)) end

for i = 1, 2 do
    particleshader("particle" .. ({ "", "soft" })[i]) end

CAPI.shader(0, "blendbrush", [[
    uniform vec4 texgenS, texgenT;
    void main(void)
    {
        gl_Position = ftransform();
        gl_FrontColor = gl_Color;
        gl_TexCoord[0].xy = vec2(dot(texgenS, gl_Vertex), dot(texgenT, gl_Vertex));
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        gl_FragColor = texture2D(tex0, gl_TexCoord[0].xy) * gl_Color;
    }
]])

lazyshader(0, "moviergb", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        gl_FragColor = texture2DRect(tex0, gl_TexCoord[0].xy);
    }
]])

lazyshader(0, "movieyuv", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        vec3 sample = texture2DRect(tex0, gl_TexCoord[0].xy).rgb;
        gl_FragColor = vec4(dot(sample, vec3(0.439216, -0.367788, -0.071427)) + 0.501961,
                            dot(sample, vec3(-0.148224, -0.290992, 0.439216)) + 0.501961,
                            dot(sample, vec3(0.256788, 0.504125, 0.097905)) + 0.062745,
                            0.0);
    }
]])

lazyshader(0, "moviey", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(-1.5, 0.0);
        gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(-0.5, 0.0);
        gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2( 0.5, 0.0);
        gl_TexCoord[3].xy = gl_MultiTexCoord0.xy + vec2( 1.5, 0.0);
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        vec3 sample1 = texture2DRect(tex0, gl_TexCoord[0].xy).rgb;
        vec3 sample2 = texture2DRect(tex0, gl_TexCoord[1].xy).rgb;
        vec3 sample3 = texture2DRect(tex0, gl_TexCoord[2].xy).rgb;
        vec3 sample4 = texture2DRect(tex0, gl_TexCoord[3].xy).rgb;
        gl_FragColor = vec4(dot(sample3, vec3(0.256788, 0.504125, 0.097905)) + 0.062745,
                            dot(sample2, vec3(0.256788, 0.504125, 0.097905)) + 0.062745,
                            dot(sample1, vec3(0.256788, 0.504125, 0.097905)) + 0.062745,
                            dot(sample4, vec3(0.256788, 0.504125, 0.097905)) + 0.062745);
    }
]])

lazyshader(0, "movieu", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(-3.0, 0.0);
        gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(-1.0, 0.0);
        gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2( 1.0, 0.0);
        gl_TexCoord[3].xy = gl_MultiTexCoord0.xy + vec2( 3.0, 0.0);
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        vec3 sample1 = texture2DRect(tex0, gl_TexCoord[0].xy).rgb;
        vec3 sample2 = texture2DRect(tex0, gl_TexCoord[1].xy).rgb;
        vec3 sample3 = texture2DRect(tex0, gl_TexCoord[2].xy).rgb;
        vec3 sample4 = texture2DRect(tex0, gl_TexCoord[3].xy).rgb;
        gl_FragColor = vec4(dot(sample3, vec3(-0.148224, -0.290992, 0.43921)) + 0.501961,
                            dot(sample2, vec3(-0.148224, -0.290992, 0.43921)) + 0.501961,
                            dot(sample1, vec3(-0.148224, -0.290992, 0.43921)) + 0.501961,
                            dot(sample4, vec3(-0.148224, -0.290992, 0.43921)) + 0.501961);
    }
]])

lazyshader(0, "moviev", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(-3.0, 0.0);
        gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(-1.0, 0.0);
        gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2( 1.0, 0.0);
        gl_TexCoord[3].xy = gl_MultiTexCoord0.xy + vec2( 3.0, 0.0);
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        vec3 sample1 = texture2DRect(tex0, gl_TexCoord[0].xy).rgb;
        vec3 sample2 = texture2DRect(tex0, gl_TexCoord[1].xy).rgb;
        vec3 sample3 = texture2DRect(tex0, gl_TexCoord[2].xy).rgb;
        vec3 sample4 = texture2DRect(tex0, gl_TexCoord[3].xy).rgb;
        gl_FragColor = vec4(dot(sample3, vec3(0.439216, -0.367788, -0.071427)) + 0.501961,
                            dot(sample2, vec3(0.439216, -0.367788, -0.071427)) + 0.501961,
                            dot(sample1, vec3(0.439216, -0.367788, -0.071427)) + 0.501961,
                            dot(sample4, vec3(0.439216, -0.367788, -0.071427)) + 0.501961);
    }
]])

--
-- reflective/refractive water shaders:
--

CAPI.shader(0, "refractmask", [[
    varying float lineardepth;
    void main(void)
    {
        gl_Position = ftransform();
        lineardepth = dot(gl_ModelViewMatrixTranspose[2], gl_Vertex);
    }
]], ([=[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    @(gdepthunpackparams)
    uniform vec4 gdepthpackparams;
    varying float lineardepth;
    uniform float refractdepth;
    void main(void)
    {
        @(EVAR.gdepthformat == 1 and [[
            vec3 packdepth = texture2DRect(tex0, gl_FragCoord.xy).rgb;
            float depth = dot(packdepth, gdepthunpackparams);
        ]] or [[
            @(gdepthunpack("depth", "tex0", "gl_FragCoord.xy")) 
            vec3 packdepth = depth * gdepthpackparams.xyz;
            packdepth.yz = fract(packdepth.yz);
            packdepth.xy -= packdepth.yz * (1.0/255.0);
        ]])
        gl_FragColor = vec4(packdepth, clamp(refractdepth*(lineardepth - depth), 0.0, 1.0));
    }
]=]):eval_embedded())

lazyshader(0, "waterminimap", [[
    void main(void)
    {
        gl_Position = ftransform();
    }
]], [[
    uniform vec3 watercolor;
    void main(void)
    {
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(0.5, 0.5, 1.0, 0.0);
        gl_FragData[2] = vec4(watercolor, 0.0);
    }
]])

watershader = function(arg1)
    lazyshader(0, arg1, ([=[
        uniform vec3 camera;
        varying vec3 surface, esurface;
        @(gdepthinterp())
        void main(void)
        {
            gl_Position = ftransform();
            surface = gl_Vertex.xyz;
            @(arg1:find("reflect") ~= nil and [[
                esurface = (gl_TextureMatrix[1] * gl_Vertex).xyz;
            ]] or nil)
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy * 0.1;
            @(gdepthpackvert())
        }
    ]=]):eval_embedded(nil, { arg1 = arg1 }, _G), ([===[
        #extension GL_ARB_texture_rectangle : enable
        uniform float millis;
        uniform vec3 camera;
        varying vec3 surface, esurface;
        uniform sampler2D tex0, tex1;
        uniform sampler2DRect tex7, tex8, tex9;
        uniform vec4 viewsize;
        uniform vec3 watercolor, waterdeepcolor, waterdeepfade;
        uniform float waterfog, waterspec;
        uniform vec4 waterreflect, waterrefract;
        @(arg1:find("caustics") ~= nil and [[
            uniform vec3 causticsS, causticsT;
            uniform vec3 causticsblend;
            uniform sampler2D tex2, tex3;
        ]] or nil)
        @(arg1:find("env") ~= nil and [[
            uniform samplerCube tex4;
        ]] or nil)
        @(gdepthunpackparams)
        @(gdepthinterp())
        void main(void)
        {
            vec3 camdir = camera - surface, camvec = normalize(camdir);
            vec3 bump = texture2D(tex0, gl_TexCoord[0].xy + millis*0.05 + 0.23).rgb;
            vec3 bump2 = texture2D(tex0, gl_TexCoord[0].xy - millis*0.05 + 0.71).rgb;
            vec3 bump3 = texture2D(tex0, gl_TexCoord[0].xy + millis*vec2(0.05, -0.05) + 0.49).rgb;
            vec3 bump4 = texture2D(tex0, gl_TexCoord[0].xy + millis*vec2(-0.05, 0.05) + 0.67).rgb;
            bump = normalize(bump + bump2 + bump3 + bump4 - 2.0);
            vec2 rtc = bump.xy * waterrefract.w;

            float rmask = texture2DRect(tex7, gl_FragCoord.xy + rtc).a;
            rtc = gl_FragCoord.xy + rtc*rmask;
            vec3 rcolor = texture2DRect(tex8, rtc).rgb * waterrefract.xyz;
            float rdepth = dot(texture2DRect(tex7, rtc).rgb, gdepthunpackparams);
            vec3 rpos = (gl_TextureMatrix[0] * vec4(rdepth*rtc, rdepth, 1.0)).xyz;

            @(arg1:find("under") ~= nil and [[
                float above = rpos.z - surface.z; 
                float alpha = clamp(above, 0.0, 1.0);
            ]] or [=[
                vec3 rdir = rpos.xyz - camera;
                float raydepth = length(rdir)*(1.0 + camdir.z/rdir.z);
                float deep = surface.z - rpos.z;
                float alpha = clamp(deep*0.5, 0.0, 1.0);

                @(arg1:find("caustics") ~= nil and [[
                    vec2 ctc = vec2(dot(causticsS, rpos.xyz), dot(causticsT, rpos.xyz));
                    float caustics = causticsblend.x*texture2D(tex2, ctc).r + causticsblend.y*texture2D(tex3, ctc).r + causticsblend.z;
                    rcolor *= caustics;
                ]] or nil)

                rcolor = mix(rcolor, watercolor, clamp(raydepth * waterfog, 0.0, 1.0));
                rcolor = mix(rcolor, waterdeepcolor, clamp(deep * waterdeepfade, 0.0, 1.0));
            ]=])

            @(arg1:find("reflect") ~= nil and [==[
                vec3 reflectdir = reflect(camvec, bump);
                vec3 edir = (gl_TextureMatrix[1] * vec4(-waterreflect.w*reflectdir, 0.0)).xyz;
                vec3 epos = esurface + edir;
                @(([=[
                    @(gdepthunpackproj("edepth$i", "tex9", "epos", [[
                        if(edepth$i < epos.z || edepth$i > esurface.z) epos += edir;
                    ]], [[
                        edepth$i = edepth$i*gdepthscale.y + gdepthscale.z;
                        if(gdepthscale.x < epos.z*edepth$i || gdepthscale.x > esurface.z*edepth$i) epos += edir;
                    ]]))
                ]=]):reppn("$i", 0, 4))
                vec2 etc = epos.xy/epos.z;
                vec3 reflect = texture2DRect(tex8, etc).rgb * waterreflect.xyz;
                float edgefade = clamp(4.0*(0.5 - max(abs(etc.x*viewsize.z - 0.5), abs(etc.y*viewsize.w - 0.5))), 0.0, 1.0);
                float fresnel = 0.25 + 0.75*pow(1.0 - max(dot(camvec, bump), 0.0), 4.0);
                rcolor = mix(rcolor, reflect, fresnel*edgefade*clamp(-8.0*reflectdir.z, 0.0, 1.0));
            ]==] or (arg1:find("env") ~= nil and [[
                vec3 reflect = textureCube(tex4, -reflect(camvec, bump)).rgb*0.5;
                float fresnel = 0.5*pow(1.0 - max(dot(camvec, bump), 0.0), 4.0);
                rcolor = mix(rcolor, reflect, fresnel);
            ]] or nil))

            gl_FragData[0] = vec4(0.0, 0.0, 0.0, alpha);
            gl_FragData[1] = vec4(bump*0.5+0.5, 0.0);
            gl_FragData[2] = vec4(rcolor*alpha, waterspec*alpha);
            @(gdepthpackfrag())
        }
    ]===]):eval_embedded(nil, { arg1 = arg1 }, _G)) end

watershader("water")
watershader("watercaustics")
watershader("waterenv")
watershader("waterenvcaustics")
watershader("waterreflect")
watershader("waterreflectcaustics")
watershader("underwater")

causticshader = function(arg1)
    lazyshader(0, arg1, [[
        void main(void)
        {
            gl_Position = gl_Vertex;
        }
    ]], [=[
        #extension GL_ARB_texture_rectangle : enable
        uniform vec3 causticsblend;
        uniform sampler2D tex0, tex1;
        uniform sampler2DRect tex9;
        void main(void)
        {
            @(gdepthunpack("depth", "tex9", "gl_FragCoord.xy", [[
                vec3 ctc = (gl_TextureMatrix[0] * vec4(depth*gl_FragCoord.xy, depth, 1.0)).xyz;
            ]], [[
                vec4 ctc = gl_TextureMatrix[0] * vec4(gl_FragCoord.xy, depth, 1.0);
                ctc.xyz /= ctc.w;
            ]]))
            float caustics = causticsblend.x*texture2D(tex0, ctc.xy).r + causticsblend.y*texture2D(tex1, ctc.xy).r + causticsblend.z;
            caustics *= clamp(ctc.z, 0.0, 1.0);
            gl_FragColor.rgb = vec3(0.5 + caustics);
        }
    ]=]) end
causticshader("caustics")

waterfogshader = function(arg1)
    lazyshader(0, arg1, [[
        void main(void)
        {
            gl_Position = gl_Vertex;
        }
    ]], [=[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex9;
        @(gdepthunpackparams)
        uniform float waterdeep;
        uniform vec3 waterdeepcolor, waterdeepfade;
        void main(void)
        {
            @(gdepthunpack("depth", "tex9", "gl_FragCoord.xy", [[
                float fogbelow = (gl_TextureMatrix[0] * vec4(depth*gl_FragCoord.xy, depth, 1.0)).z;
                #define fogcoord depth 
            ]], [[
                vec3 pos = (gl_TextureMatrix[0] * vec4(gl_FragCoord.xy, depth, 1.0)).xzw;
                pos.xy /= pos.z;
                #define fogbelow pos.y
                #define fogcoord pos.x
            ]]))
            float foglerp = clamp((gl_Fog.start - fogcoord) * gl_Fog.scale, 0.0, 1.0);
            foglerp *= clamp(2.0*fogbelow + 0.5, 0.0, 1.0);
            vec3 fogcolor = mix(gl_Fog.color.rgb, waterdeepcolor, clamp(fogbelow*waterdeepfade, 0.0, 1.0));
            gl_FragColor.rgb = fogcolor;
            gl_FragColor.a = foglerp;
        }
    ]=]) end
waterfogshader("waterfog")

lazyshader(0, "lava", [[
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        vec3 tangent = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.x));
        vec3 bitangent = mix(vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.z));
        world = mat3(tangent, bitangent, gl_Normal);
        @(gdepthpackvert())
    }
]], [[
    uniform sampler2D tex0, tex1;
    uniform float lavaglow, lavaspec;
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        vec3 diffuse = texture2D(tex0, gl_TexCoord[0].xy).rgb;
        vec3 bump = texture2D(tex1, gl_TexCoord[0].xy).rgb*2.0-1.0;
        vec3 bumpw = world * bump;
        gl_FragData[0] = vec4(diffuse, 1.0);
        gl_FragData[1] = vec4(bumpw*0.5+0.5, 0.0);
        gl_FragData[2] = vec4(diffuse*lavaglow, lavaspec);
        @(gdepthpackfrag())
    }
]])

lazyshader(0, "waterfallenv", [[
    uniform vec4 camera;
    varying vec3 camdir;
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        camdir = camera.xyz - gl_Vertex.xyz;
        vec3 tangent = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.x));
        vec3 bitangent = mix(vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.z));
        world = mat3(tangent, bitangent, gl_Normal);
        @(gdepthpackvert())
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex7, tex8;
    uniform samplerCube tex3;
    uniform sampler2D tex0, tex1;
    uniform vec3 waterfallcolor;
    uniform float waterfallspec;
    uniform vec4 waterfallrefract;
    varying vec3 camdir;
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        vec3 camvec = normalize(camdir);
        vec3 diffuse = texture2D(tex0, gl_TexCoord[0].xy).rgb;
        vec3 bump = texture2D(tex1, gl_TexCoord[0].xy).rgb*2.0 - 1.0;
        vec3 bumpw = world * bump;

        vec2 rtc = bump.xy * waterfallrefract.w;
        float rmask = texture2DRect(tex7, gl_FragCoord.xy + rtc).a;
        rtc = gl_FragCoord.xy + rtc*rmask;
        vec3 rcolor = texture2DRect(tex8, rtc).rgb * waterfallrefract.xyz;

        float invfresnel = dot(camvec, bumpw);
        vec3 env = textureCube(tex3, 2.0*bumpw*invfresnel - camvec).rgb;
        env *= 0.1 + 0.4*pow(1.0 - max(invfresnel, 0.0), 2.0);

        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(bumpw*0.5+0.5, 0.0);
        gl_FragData[2] = vec4(mix(rcolor, waterfallcolor, diffuse) + env, waterfallspec*(1.0 - dot(diffuse, vec3(0.33)))); 
        @(gdepthpackfrag())
    }
]])

lazyshader(0, "waterfall", [[
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        vec3 tangent = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.x));
        vec3 bitangent = mix(vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.z));
        world = mat3(tangent, bitangent, gl_Normal);
        @(gdepthpackvert())
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex7, tex8;
    uniform sampler2D tex0, tex1;
    uniform vec3 waterfallcolor;
    uniform float waterfallspec;
    uniform vec4 waterfallrefract;
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        vec3 diffuse = texture2D(tex0, gl_TexCoord[0].xy).rgb;
        vec3 bump = texture2D(tex1, gl_TexCoord[0].xy).rgb*2.0 - 1.0;
        vec3 bumpw = world * bump;

        vec2 rtc = bump.xy * waterfallrefract.w;
        float rmask = texture2DRect(tex7, gl_FragCoord.xy + rtc).a;
        rtc = gl_FragCoord.xy + rtc*rmask;
        vec3 rcolor = texture2DRect(tex8, rtc).rgb * waterfallrefract.xyz;

        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(bumpw*0.5+0.5, 0.0);
        gl_FragData[2] = vec4(mix(rcolor, waterfallcolor, diffuse), waterfallspec*(1.0 - dot(diffuse, vec3(0.33)))); 
        @(gdepthpackfrag())
    }
]])
CAPI.altshader("waterfallenv", "waterfall")

lazyshader(0, "glassenv", [[
    uniform vec4 camera;
    varying vec3 camdir;
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        camdir = camera.xyz - gl_Vertex.xyz;
        vec3 tangent = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.x));
        vec3 bitangent = mix(vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.z));
        world = mat3(tangent, bitangent, gl_Normal);
        @(gdepthpackvert())
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex7, tex8;
    uniform samplerCube tex0;
    uniform sampler2D tex1;
    uniform float glassspec;
    uniform vec4 glassrefract;
    varying vec3 camdir;
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        vec3 camvec = normalize(camdir);
        vec3 bump = texture2D(tex1, gl_TexCoord[0].xy).rgb*2.0 - 1.0;
        vec3 bumpw = world * bump;

        vec2 rtc = bump.xy * glassrefract.w;
        float rmask = texture2DRect(tex7, gl_FragCoord.xy + rtc).a;
        rtc = gl_FragCoord.xy + rtc*rmask;
        vec3 rcolor = texture2DRect(tex8, rtc).rgb;
        rcolor *= glassrefract.xyz;
      
        float invfresnel = dot(camvec, bumpw);
        vec3 env = textureCube(tex0, 2.0*bumpw*invfresnel - camvec).rgb;
        env *= 0.1 + 0.4*pow(1.0 - max(invfresnel, 0.0), 2.0);
  
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(bumpw*0.5+0.5, 0.0);
        gl_FragData[2] = vec4(rcolor + env, glassspec);
        @(gdepthpackfrag())
    }
]])

lazyshader(0, "glass", [[
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        vec3 tangent = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.x));
        vec3 bitangent = mix(vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0), abs(gl_Normal.z));
        world = mat3(tangent, bitangent, gl_Normal);
        @(gdepthpackvert())
    }
]], [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex7, tex8;
    uniform sampler2D tex1;
    uniform float glassspec;
    uniform vec4 glassrefract;
    varying mat3 world;
    @(gdepthinterp())
    void main(void)
    {
        vec3 bump = texture2D(tex1, gl_TexCoord[0].xy).rgb*2.0 - 1.0;
        vec3 bumpw = world * bump;

        vec2 rtc = bump.xy * glassrefract.w;
        float rmask = texture2DRect(tex7, gl_FragCoord.xy + rtc).a;
        rtc = gl_FragCoord.xy + rtc*rmask;
        vec3 rcolor = texture2DRect(tex8, rtc).rgb;
        rcolor *= glassrefract.xyz;
        
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(bumpw*0.5+0.5, 0.0);
        gl_FragData[2] = vec4(rcolor, glassspec); 
        @(gdepthpackfrag())
    }
]])
CAPI.altshader("glassenv", "glass")

CAPI.defershader(0, "grass", function()
    for i = 0, 1 do
        CAPI.variantshader(0, "grass", i - 1, ([=[
            @(gdepthinterp())
            @(i ~= 0 and "uniform vec4 blendmapparams;" or nil)
            void main(void)
            {
                gl_Position = ftransform();
                gl_FrontColor = gl_Color;
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
                @(i ~= 0
                    and "gl_TexCoord[1].xy = (gl_Vertex.xy - blendmapparams.xy)*blendmapparams.zw;"
                    or nil)
                @(gdepthpackvert())
            }
        ]=]):eval_embedded(nil, { i = i }, _G), ([=[
            uniform sampler2D tex0;
            uniform float grasstest;
            @(gdepthinterp())
            @(i ~= 0 and "uniform sampler2D tex1;" or nil)
            void main(void)
            {
                vec4 color = texture2D(tex0, gl_TexCoord[0].xy) * gl_Color;
                @(i ~= 0
                    and "color.a *= texture2D(tex1, gl_TexCoord[1].xy).r;"
                    or nil)
                if(color.a <= grasstest)
                    discard;
                gl_FragData[0] = vec4(color.rgb, 1.0);
                gl_FragData[1] = vec4(0.5, 0.5, 1.0, 0.0); 
                gl_FragData[2] = vec4(0.0);
                @(gdepthpackfrag())
            }
        ]=]):eval_embedded(nil, { i = i }, _G)) end end)

CAPI.shader(0, "overbrightdecal", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_FrontColor = gl_Color;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
        gl_FragColor = mix(gl_Color, diffuse, gl_Color.a);
    }
]])

CAPI.shader(0, "saturatedecal", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_FrontColor = gl_Color;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
        diffuse.rgb *= 2.0;
        gl_FragColor = diffuse * gl_Color;
    }
]])

CAPI.shader(0, "decal", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], [[
    uniform sampler2D tex0;
    void main(void)
    {
        gl_FragColor = gl_Color * texture2D(tex0, gl_TexCoord[0].xy);
    }
]])

CAPI.shader(0, "skyboxoverbright", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], ([[
    uniform sampler2D tex0;
    uniform vec2 overbrightparams;
    void main(void)
    {
        vec3 color = texture2D(tex0, gl_TexCoord[0].xy).rgb;
        float lum = dot(vec3(@(lumweights)), color);
        float scale = 1.0 + overbrightparams.x*clamp(lum - overbrightparams.y, 0.0, 1.0);
        gl_FragColor.rgb = gl_Color.rgb * color * scale;
    }
]]):eval_embedded())


smaashaders = function(arg1)
    smaapreset = arg1
    require("shaders.smaa")
    package.loaded["shaders.smaa"] = nil end
