lazyshader = function(stype, name, vert, frag)
    CAPI.defershader (stype, name, function()
        CAPI.shader  (stype, name, vert:eval_embedded(), frag:eval_embedded()) end) end

gdepthinterp = function()
    if EV.gdepthformat ~= 0 then
        return (EV.gdepthformat > 1) and [[
            uniform vec3 gdepthpackparams;
            varying float lineardepth;
        ]] or [[
            uniform vec3 gdepthpackparams;
            varying vec3 lineardepth;
        ]] end end

gdepthpackvert = function(arg1)
    if EV.gdepthformat ~= 0 then
        return ((EV.gdepthformat > 1) and [[
            lineardepth = dot(gl_ModelViewMatrixTranspose[2], @(arg1 and arg1 or "gl_Vertex"));
        ]] or [[
            lineardepth = dot(gl_ModelViewMatrixTranspose[2], @(arg1 and arg1 or "gl_Vertex")) * gdepthpackparams;
        ]]):eval_embedded(nil, { arg1 = arg1 }) end end

gdepthpackfrag = function()
    if EV.gdepthformat ~= 0 then
        return (EV.gdepthformat > 1) and [[
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
    if EV.gdepthformat ~= 0 or arg6 then
        return ((EV.gdepthformat > 1 or arg6) and [[
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
    if EV.gdepthformat ~= 0 or arg6 then
        return ((EV.gdepthformat > 1 or arg6) and [[
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

CAPI.shader(0, "tex3d", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_FrontColor = gl_Color;
    }
]], [[
    uniform sampler3D tex0;
    void main(void)
    {
        gl_FragColor = gl_Color * texture3D(tex0, gl_TexCoord[0].xyz);
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
    if arg[1]:find("pulse") then
        stype = stype + 0x10
    end
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
        @(i == 1 and [[
            uniform float blendlayer;
            uniform sampler2D blendmap;
        ]] or nil)
        void main(void)
        {
            vec4 diffuse = texture2D(diffusemap, gl_TexCoord[0].xy);   

            @(arg[3])

            @(i == 2 and [[
                #define alpha 1.0
            ]] or [[
                #define alpha colorparams.a
            ]])
            
            gl_FragData[0].rgb = diffuse.rgb*colorparams.rgb;
            gl_FragData[1].rgb = normal*0.5+0.5;
            gl_FragData[1].a = 0.0;
            @((#arg < 4 or not arg[4] or arg[4] == "") and "gl_FragData[2].rgb = vec3(0.0);" or arg[4])

            @(i == 2 and [[
                vec3 rlight = texture2DRect(refractlight, gl_FragCoord.xy).rgb;
                gl_FragData[2].rgb += rlight * refractparams.xyz;
            ]] or nil)

            @(i == 1 and [[
                float blend = abs(texture2D(blendmap, gl_TexCoord[1].xy).r - blendlayer);
                gl_FragData[0].rgb *= blend;
                gl_FragData[0].a = blendlayer;
                gl_FragData[1] *= blend;
                gl_FragData[2].rgb *= blend;
            ]] or [[
                gl_FragData[0].a = alpha;
            ]])

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

CAPI.defershader(0x11, "pulseworld", function()
    CAPI.defuniformparam("pulsespeed", 1, 0, 0, 0) -- pulse frequency (Hz)
    worldshader("pulseworld", [[
        pulse = abs(fract(millis.x * pulsespeed.x)*2.0 - 1.0); 
    ]], [[
        vec3 diffuse2 = texture2D(decal, gl_TexCoord[0].xy).rgb; 
        diffuse.rgb = mix(diffuse.rgb, diffuse2, pulse);
    ]], "", "uniform vec4 millis; varying float pulse;", "uniform sampler2D decal;") end)

CAPI.defershader(0x11, "pulseglowworld", function()
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
        stype = stype + 0x10
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
        @(btopt.b and [[
            uniform float blendlayer;
            uniform sampler2D blendmap;
        ]] or nil)
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

            @(btopt.a and [[
                #define alpha 1.0
            ]] or [[
                #define alpha colorparams.a
            ]])

            gl_FragData[0].rgb = diffuse.rgb*colorparams.rgb;

            @(not btopt.P and "vec3 bump = texture2D(normalmap, dtc).rgb;" or nil)

            bump = bump*2.0 - 1.0;
            vec3 bumpw = world * bump;
            gl_FragData[1].rgb = bumpw*0.5 + 0.5;

            @(if btopt.s then
                if btopt.S then return [[
                    gl_FragData[1].a = diffuse.a*specscale.x * 0.5;
                ]] else return [[
                    gl_FragData[1].a = specscale.x * 0.5;
                ]] end
            else return [[
                gl_FragData[1].a = 0.0;
            ]] end)

            @(btopt.g and [=[
                vec3 glow = texture2D(glowmap, dtc).rgb;
                @(btopt.G and [[
                    vec3 pulsecol = mix(glowcolor.xyz, pulseglowcolor.xyz, pulse);
                ]] or nil)

                glow *= @(btopt.G and "pulsecol" or "glowcolor.xyz"); 
                gl_FragData[2].rgb = glow;
            ]=] or [[
                gl_FragData[2].rgb = vec3(0.0);
            ]])

            @(btopt.r and [=[
                vec3 camvecwn = normalize(camvecw);
                float invfresnel = dot(camvecwn, bumpw);
                vec3 rvec = 2.0*bumpw*invfresnel - camvecwn;
                vec3 reflect = textureCube(envmap, rvec).rgb;
                @(btopt.R and [[
                    float rmod = envscale.x*diffuse.a;
                ]] or [[
                    #define rmod envscale.x
                ]])
                gl_FragData[0].rgb = mix(gl_FragData[0].rgb, reflect, rmod*clamp(1.0 - invfresnel, 0.0, 1.0));
            ]=] or nil)

            @(btopt.a and [[
                vec2 rtc = bump.xy*refractparams.w;
                float rmask = texture2DRect(refractmask, gl_FragCoord.xy + rtc).a;
                vec3 rlight = texture2DRect(refractlight, gl_FragCoord.xy + rtc*rmask).rgb;
                gl_FragData[2].rgb += rlight * refractparams.xyz;
            ]] or nil)

            @(btopt.b and [[
                float blend = abs(texture2D(blendmap, gl_TexCoord[1].xy).r - blendlayer);
                gl_FragData[0].rgb *= blend;
                gl_FragData[0].a = blendlayer;
                gl_FragData[1] *= blend;
                gl_FragData[2].rgb *= blend;
            ]] or [[
                gl_FragData[0].a = alpha;
            ]])

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

for i = 0, 1 do
    CAPI.variantshader(1, "rsmworld", i - 1, ([=[
        uniform vec4 texgenscroll;
        uniform vec4 colorparams;
        uniform vec3 rsmdir;
        varying vec4 normal;
        @(i == 1 and "uniform vec4 blendmapparams;" or nil)
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texgenscroll.xy;
            @(i == 1 and [[
                gl_TexCoord[1].xy = (gl_Vertex.xy - blendmapparams.xy)*blendmapparams.zw;
            ]] or nil)
            normal = vec4(gl_Normal, dot(gl_Normal, rsmdir));
        }
    ]=]):eval_embedded(nil, { i = i }, _G), ([=[
        uniform vec4 colorparams;
        uniform sampler2D diffusemap;
        varying vec4 normal;
        @(i == 1 and [[
            uniform float blendlayer;
            uniform sampler2D blendmap;
        ]] or nil)
        void main(void)
        {
            vec4 diffuse = texture2D(diffusemap, gl_TexCoord[0].xy);   

            @(i == 2 and [[
                #define alpha 1.0
            ]] or [[
                #define alpha colorparams.a
            ]])

            gl_FragData[0].rgb = normal.w*diffuse.rgb*colorparams.rgb;
            gl_FragData[1] = vec4(normal.xyz*0.5+0.5, 0.0);

            @(i == 1 and [[
                float blend = abs(texture2D(blendmap, gl_TexCoord[1].xy).r - blendlayer);
                gl_FragData[0].rgb *= blend;
                gl_FragData[0].a = blendlayer;
                gl_FragData[1] *= blend;
            ]] or [[
                gl_FragData[0].a = alpha;
            ]])
        }
    ]=]):eval_embedded(nil, { i = i }, _G))
end

CAPI.shader(0, "rsmsky", [[
    void main(void)
    {
        gl_Position = ftransform();
    }
]], [[
    void main(void)
    {
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(0.5, 0.5, 0.5, 0.0);
    }
]])

--
-- phong lighting model shader
--

-- skeletal animation for matrices and dual quaternions

skelanimdefs = function()
    return ([=[
        @(EV.useubo ~= 0 and [[
            #ifdef GL_ARB_uniform_buffer_object
                #extension GL_ARB_uniform_buffer_object : enable
            #endif
        ]] or nil)
        @(EV.usebue ~= 0 and [[
            #extension GL_EXT_bindable_uniform : enable
        ]] or nil)
        #pragma CUBE2_attrib vweights 6
        #pragma CUBE2_attrib vbones 7
        attribute vec4 vweights; 
        attribute vec4 vbones;
        #pragma CUBE2_uniform animdata AnimData 0 16
        @(EV.useubo ~= 0 and [[
            #ifdef GL_ARB_uniform_buffer_object
                layout(std140) uniform AnimData
                {
                    vec4 animdata[@(math.min(EV.maxvsuniforms, EV.maxanimdata))];
                };
            #else
        ]] or nil)
        @(EV.usebue ~= 0 and [[
            #ifdef GL_EXT_bindable_uniform
                bindable
            #endif
        ]] or nil)
        uniform vec4 animdata[@(math.min(EV.maxvsuniforms, EV.maxanimdata))];
        @(EV.useubo ~= 0 and [[
            #endif
        ]] or nil)
    ]=]):eval_embedded() end

skelanimfragdefs = function()
    if EV.ati_ubo_bug ~= 0 then
        return (EV.useubo ~= 0 and [[
            #ifdef GL_ARB_uniform_buffer_object
                #extension GL_ARB_uniform_buffer_object : enable
                layout(std140) uniform AnimData
                {
                    vec4 animdata[@(math.min(EV.maxvsuniforms, EV.maxanimdata))];
                };
            #endif
        ]] or [[
            #ifdef GL_EXT_bindable_uniform
                #extension GL_EXT_bindable_uniform : enable
                bindable uniform vec4 animdata[@(math.min(EV.maxvsuniforms, EV.maxanimdata))];
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
        @((arg3 and arg3 ~= 0) and [[
            #version 130
            uniform vec4 tetramodelclip;
        ]] or nil)
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

if EV.glslversion >= 130 then
    CAPI.shader(0, "tetramodel", shadowmodelvertexshader("", "", 1), [[
        #version 130
        void main(void)
        {
        }
    ]])

    for i = 1, 4 do
        CAPI.variantshader(0, "tetramodel", 0, shadowmodelvertexshader(skelanimdefs(i, 0, 0), skelmatanim (i, 0, 0), 1), "")
        CAPI.variantshader(0, "tetramodel", 1, shadowmodelvertexshader(skelanimdefs(i, 0, 0), skelquatanim(i, 0, 0), 1), "") end end

alphashadowmodelvertexshader = function(arg1, arg2, arg3)
    return ([=[
        @((arg3 and arg3 ~= 0) and [[
            #version 130
            uniform vec4 tetramodelclip;
        ]] or nil)
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

if EV.glslversion >= 130 then
    CAPI.shader(0, "alphashadowtetramodel", alphashadowmodelvertexshader("", "", 1), [[
        #version 130
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
--    m -> masks
--    d -> decal
--    B -> matrix skeletal animation
--    b -> dual-quat skeletal animation

modelvertexshader = function(...)
    local arg = { ... }
    local modeltype = arg[1]

    local mdlopt = {
        a = modeltype:find("a") ~= nil,
        e = modeltype:find("e") ~= nil,
        n = modeltype:find("n") ~= nil,
        m = modeltype:find("m") ~= nil,
        s = modeltype:find("d") ~= nil,
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
 
            @(mdlopt.e and [[
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
        uniform vec2 fullbright;
        uniform vec4 maskscale;
        @(mdlopt.a and "uniform float alphatest;" or nil)
        uniform sampler2D tex0;
        @(mdlopt.m and "uniform sampler2D tex1;" or nil)
        @(mdlopt.e and "uniform samplerCube tex2;" or nil)
        @(mdlopt.n and "uniform sampler2D tex3;" or nil)
        @(mdlopt.d and "uniform sampler2D tex4;" or nil)
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

            @(mdlopt.d and [[
                vec4 decal = texture2D(tex4, gl_TexCoord[0].xy);
                gl_FragData[0].rgb = mix(gl_FragData[0].rgb, decal.rgb, decal.a);
            ]] or nil)

            @(mdlopt.m and [[
                vec3 masks = texture2D(tex1, gl_TexCoord[0].xy).rgb;
            ]] or nil)

            @(mdlopt.n and [[
                vec3 normal = texture2D(tex3, gl_TexCoord[0].xy).rgb - 0.5;
                normal = normalize(world * normal);
            ]] or [[
                vec3 normal = normalize(nvec);
            ]])

            gl_FragData[1].rgb = 0.5*normal+0.5;

            float spec = maskscale.x;
            @(mdlopt.m and "spec *= masks.r;" or nil) // specmap in red channel
            gl_FragData[1].a = 0.5*spec;

            @(mdlopt.m and [==[
                float gmask = max(maskscale.y*masks.g, fullbright.y); // glow mask in green channel
                gl_FragData[2].rgb = diffuse.rgb*gmask;
                gl_FragData[0].rgb *= fullbright.x-gmask;
                @(mdlopt.e and [=[
                    @(mdlopt.n and [[
                        vec3 camn = normalize(camvec);
                        float invfresnel = dot(camn, normal);
                        vec3 rvec = 2.0*invfresnel*normal - camn;
                        float rmod = envmapscale.x*clamp(invfresnel, 0.0, 1.0) + envmapscale.y;
                    ]] or nil)
                    float rmask = rmod*masks.b; // envmap mask in blue channel
                    vec3 reflect = textureCube(tex2, rvec).rgb;
                    gl_FragData[0].rgb = mix(gl_FragData[0].rgb, reflect, rmask);
                ]=] or nil)
            ]==] or [[
                gl_FragData[2].rgb = diffuse.rgb*fullbright.y;
                gl_FragData[0].rgb *= fullbright.x-fullbright.y;
            ]])

            @(gdepthpackfrag())
        }
    ]===]):eval_embedded(nil, { mdlopt = mdlopt, arg = arg }, _G) end

modelanimshader = function(arg1, arg2, arg3, arg4)
    local fraganimshader = arg2 > 0 and tostring(arg2) or ""
    local reuseanimshader = fraganimshader
    if EV.ati_ubo_bug ~= 0 then
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
-- phong lighting model shader
--

modelshader("stdmodel", "")
modelshader("masksmodel", "m")
modelshader("envmapmodel", "me")
CAPI.altshader("envmapmodel", "masksmodel")

modelshader("bumpmodel", "n")
modelshader("bumpmasksmodel", "nm")
modelshader("bumpenvmapmodel", "nme")
CAPI.altshader("bumpenvmapmodel", "bumpmasksmodel")

modelshader("alphamodel", "a")
modelshader("masksalphamodel", "am")
modelshader("envmapalphamodel", "ame")
CAPI.altshader("envmapalphamodel", "masksalphamodel")

modelshader("bumpalphamodel", "an")
modelshader("bumpmasksalphamodel", "anm")
modelshader("bumpenvmapalphamodel", "anme")
CAPI.altshader("bumpenvmapalphamodel", "bumpmasksalphamodel")

modelshader("decalmodel", "d")
modelshader("decalmasksmodel", "dm")
modelshader("decalenvmapmodel", "dme")
CAPI.altshader("decalenvmapmodel", "decalmasksmodel")

modelshader("decalbumpmodel", "dn")
modelshader("decalbumpmasksmodel", "dnm")
modelshader("decalbumpenvmapmodel", "dnme")
CAPI.altshader("decalbumpenvmapmodel", "decalbumpmasksmodel")

modelshader("decalalphamodel", "da")
modelshader("decalmasksalphamodel", "dam")
modelshader("decalenvmapalphamodel", "dame")
CAPI.altshader("decalenvmapalphamodel", "decalmasksalphamodel")

modelshader("decalbumpalphamodel", "dan")
modelshader("decalbumpmasksalphamodel", "danm")
modelshader("decalbumpenvmapalphamodel", "danme")
CAPI.altshader("decalbumpenvmapalphamodel", "decalbumpmasksalphamodel")

rsmmodelvertexshader = function(...)
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

    return ([=[
        @((mdlopt.b or mdlopt.B) and skelanimdefs(arg[2], 1, 0) or nil)
        uniform vec4 texscroll;
        uniform vec3 rsmdir;
        varying vec4 normal;
        varying float facing;
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
            ]])
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texscroll.yz;
            normal.xyz = (gl_TextureMatrix[0] * vec4(onormal, 0.0)).xyz;
            normal.w = dot(normal.xyz, rsmdir);
        }
    ]=]):eval_embedded(nil, { mdlopt = mdlopt, arg = arg }, _G)
end

rsmmodelfragmentshader = function(...)
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

    return ([=[
        @((mdlopt.b or mdlopt.B) and skelanimfragdefs() or nil)
        varying vec4 normal;
        uniform vec2 fullbright;
        @(mdlopt.a and "uniform float alphatest;" or nil)
        uniform sampler2D tex0;
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
            @(mdlopt.a and [[
                if(diffuse.a <= alphatest)
                    discard;
            ]] or nil)
            gl_FragData[0] = vec4(normal.w*diffuse.rgb, 1.0);
            gl_FragData[1] = vec4(normal.xyz*0.5+0.5, 0.0);
        }
    ]=]):eval_embedded(nil, { mdlopt = mdlopt }, _G)
end

rsmmodelanimshader = function(arg1, arg2, arg3, arg4)
    local fraganimshader = arg2 > 0 and tostring(arg2) or ""
    local reuseanimshader = fraganimshader
    if EV.ati_ubo_bug ~= 0 then
        reuseanimshader = ("%i , %i"):format(arg2, arg2 > 0 and 1 or 0)
        fraganimshader = (arg4 == 1) and modelfragmentshader("bB" .. arg3) or reuseanimshader
    end
    CAPI.variantshader(0, arg1, arg2, rsmmodelvertexshader("B" .. arg3, arg4), fraganimshader)
    CAPI.variantshader(0, arg1, arg2 + 1, rsmmodelvertexshader("b" .. arg3, arg4), reuseanimshader)
end

rsmmodelshader = function(arg1, arg2)
    CAPI.shader(0, arg1, rsmmodelvertexshader(arg2), rsmmodelfragmentshader(arg2))
    for i = 1, 4 do
        rsmmodelanimshader(arg1, 0, arg2, i)
    end
end

rsmmodelshader("rsmmodel", "")
rsmmodelshader("rsmalphamodel", "a")

rhtapoffsets12 = {
    "0.0565813, 0.61211, 0.763359",
    "0.375225, 0.285592, 0.987915",
    "0.615192, 0.668996, 0.604938",
    "0.963195, 0.355937, 0.175787",
    "0.0295724, 0.484268, 0.265694",
    "0.917783, 0.88702, 0.201972",
    "0.408948, 0.0675985, 0.427564",
    "0.19071, 0.923612, 0.0553606",
    "0.968078, 0.403943, 0.847224",
    "0.384503, 0.922269, 0.990844",
    "0.480605, 0.342418, 0.00195318",
    "0.956664, 0.923643, 0.915799"
}

rhtapoffsets20 = {
    "0.0540788, 0.411725, 0.134068",
    "0.0163579, 0.416211, 0.992035",
    "0.692068, 0.549272, 0.886502",
    "0.305795, 0.781854, 0.571337",
    "0.791681, 0.139042, 0.247047",
    "0.83929, 0.973663, 0.460982",
    "0.0336314, 0.0867641, 0.582324",
    "0.148198, 0.961974, 0.0378124",
    "0.948729, 0.0713828, 0.916379",
    "0.586413, 0.591845, 0.031251",
    "0.00189215, 0.973968, 0.932981",
    "0.435865, 0.0853603, 0.995148",
    "0.36848, 0.820612, 0.942717",
    "0.500107, 0.0658284, 0.623005",
    "0.580187, 0.4485, 0.379223",
    "0.258614, 0.0201422, 0.241005",
    "0.987152, 0.441664, 0.43318",
    "0.925108, 0.917203, 0.921506",
    "0.988372, 0.822047, 0.12479",
    "0.330393, 0.43611, 0.762566"
}

rhtapoffsets32 = {
    "0.0553911, 0.675924, 0.22129",
    "0.562975, 0.508286, 0.549883",
    "0.574816, 0.703452, 0.0513016",
    "0.981017, 0.930479, 0.243873",
    "0.889309, 0.133091, 0.319071",
    "0.329112, 0.00759911, 0.472213",
    "0.314463, 0.985839, 0.54442",
    "0.407697, 0.202643, 0.985748",
    "0.998169, 0.760369, 0.792932",
    "0.0917692, 0.0666829, 0.0169683",
    "0.0157781, 0.632954, 0.740806",
    "0.938139, 0.235878, 0.87936",
    "0.442305, 0.184942, 0.0901212",
    "0.578051, 0.863948, 0.799554",
    "0.0698569, 0.259194, 0.667592",
    "0.872494, 0.576312, 0.344157",
    "0.10123, 0.930082, 0.959929",
    "0.178594, 0.991302, 0.046205",
    "0.690176, 0.527543, 0.930509",
    "0.982025, 0.389447, 0.0344554",
    "0.033845, 0.0156865, 0.963866",
    "0.655293, 0.154271, 0.640553",
    "0.317881, 0.598621, 0.97998",
    "0.247261, 0.398206, 0.121586",
    "0.822626, 0.985076, 0.655232",
    "0.00201422, 0.434278, 0.388348",
    "0.511399, 0.977416, 0.278695",
    "0.32371, 0.540147, 0.361187",
    "0.365856, 0.41493, 0.758232",
    "0.792871, 0.979217, 0.0309763",
    "0.0509049, 0.459151, 0.996277",
    "0.0305185, 0.13422, 0.306009"
}

rsmtapoffsets12 = {
    "0.031084, 0.572114",
    "0.040671, 0.95653",
    "0.160921, 0.367819",
    "0.230518, 0.134321",
    "0.247078, 0.819415",
    "0.428665, 0.440522",
    "0.49846, 0.80717",
    "0.604285, 0.0307766",
    "0.684075, 0.283001",
    "0.688304, 0.624171",
    "0.833995, 0.832414",
    "0.975397, 0.189911",
}

rsmtapoffsets20 = {
    "0.00240055, 0.643992",
    "0.0356464, 0.851616",
    "0.101733, 0.21876",
    "0.166119, 0.0278085",
    "0.166438, 0.474999",
    "0.24991, 0.766405",
    "0.333714, 0.130407",
    "0.400681, 0.374781",
    "0.424067, 0.888211",
    "0.448511, 0.678962",
    "0.529383, 0.213568",
    "0.608569, 0.47715",
    "0.617996, 0.862528",
    "0.631784, 0.0515881",
    "0.740969, 0.20753",
    "0.788203, 0.41923",
    "0.794066, 0.615141",
    "0.834504, 0.836612",
    "0.89446, 0.0677863",
    "0.975609, 0.446056"
}

rsmtapoffsets32 = {
    "0.0262032, 0.215221",
    "0.0359769, 0.0467256",
    "0.0760799, 0.713481",
    "0.115087, 0.461431",
    "0.119488, 0.927444",
    "0.22346, 0.319747",
    "0.225964, 0.679227",
    "0.238626, 0.0618425",
    "0.243326, 0.535066",
    "0.29832, 0.90826",
    "0.335208, 0.212103",
    "0.356438, 0.751969",
    "0.401021, 0.478664",
    "0.412027, 0.0245297",
    "0.48477, 0.320659",
    "0.494311, 0.834621",
    "0.515007, 0.165552",
    "0.534574, 0.675536",
    "0.585357, 0.432483",
    "0.600102, 0.94139",
    "0.650182, 0.563571",
    "0.672336, 0.771816",
    "0.701811, 0.187078",
    "0.734207, 0.359024",
    "0.744775, 0.924466",
    "0.763628, 0.659075",
    "0.80735, 0.521281",
    "0.880585, 0.107684",
    "0.898505, 0.904047",
    "0.902536, 0.718989",
    "0.928022, 0.347802",
    "0.971243, 0.504885"
}

radiancehintsshader = function(arg1)
    local numtaps = arg1 > 20 and 32 or (arg1 > 12 and 20) or 12
    CAPI.shader(0, "radiancehints" .. arg1, [[
        varying vec3 rhcenter;
        varying vec2 rsmcenter;
        void main(void)
        {
            gl_Position = gl_Vertex;
            rhcenter = gl_MultiTexCoord0.xyz;
            rsmcenter = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        }
    ]], ([=[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0, tex1, tex2; 
        uniform vec2 rsmspread;
        uniform float rhatten, rhspread;
        varying vec3 rhcenter;
        varying vec2 rsmcenter;

        void calcrhsample(vec3 rhtap, vec2 rsmtap, inout vec4 shr, inout vec4 shg, inout vec4 shb)
        {
            vec3 rhpos = rhcenter + rhtap*rhspread;
            vec2 rsmtc = rsmcenter + rsmtap*rsmspread;
            float rsmdepth = texture2DRect(tex0, rsmtc).x;
            vec3 rsmcolor = texture2DRect(tex1, rsmtc).rgb;
            vec3 rsmnormal = texture2DRect(tex2, rsmtc).xyz*2.0 - 1.0;
            vec3 rsmpos = (gl_TextureMatrixInverse[0] * vec4(rsmtc, rsmdepth, 1.0)).xyz;

            vec3 dir = rhpos - rsmpos;
            float dist = dot(dir, dir);
            if(dist > 0.000049) dir = normalize(dir);
            float atten = clamp(dot(dir, rsmnormal), 0.0, 1.0) / (0.1 + dist*rhatten);
            rsmcolor *= atten;

            shr += vec4(rsmcolor.r*dir, rsmcolor.r);
            shg += vec4(rsmcolor.g*dir, rsmcolor.g);
            shb += vec4(rsmcolor.b*dir, rsmcolor.b);
        }

        void main(void)
        {
            vec4 shr = vec4(0.0), shg = vec4(0.0), shb = vec4(0.0);

            @(([[
                calcrhsample(vec3(@(_G["rhtapoffsets" .. numtaps][$i]))*2.0 - 1.0, vec2(@(_G["rsmtapoffsets" .. numtaps][$i]))*2.0 - 1.0, shr, shg, shb);
            ]]):reppn("$i", 1, numtaps))

            gl_FragData[0] = shr * (vec4(0.5, 0.5, 0.5, 1.0)/@(("%.1f"):format(numtaps))) + vec4(0.5, 0.5, 0.5, 0.0);
            gl_FragData[1] = shg * (vec4(0.5, 0.5, 0.5, 1.0)/@(("%.1f"):format(numtaps))) + vec4(0.5, 0.5, 0.5, 0.0);
            gl_FragData[2] = shb * (vec4(0.5, 0.5, 0.5, 1.0)/@(("%.1f"):format(numtaps))) + vec4(0.5, 0.5, 0.5, 0.0);
        }
    ]=]):eval_embedded(nil, { numtaps = numtaps }, _G))
end

lazyshader(0, "radiancehintsborder", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xyz = gl_MultiTexCoord0.xyz;
    }
]], [[
    uniform sampler3D tex3, tex4, tex5;
    uniform vec3 bordercenter, borderrange, borderscale;
    void main(void)
    {
        float outside = clamp(borderscale.z*(abs(gl_TexCoord[0].z - bordercenter.z) - borderrange.z), 0.0, 1.0);
        vec3 tc = vec3(gl_TexCoord[0].xy, clamp(gl_TexCoord[0].z, bordercenter.z - borderrange.z, bordercenter.z + borderrange.z));
        gl_FragData[0] = texture3D(tex3, tc);
        gl_FragData[1] = texture3D(tex4, tc);
        gl_FragData[2] = mix(texture3D(tex5, tc), vec4(0.5, 0.5, 0.5, 0.0), outside);
    }
]])

lazyshader(0, "radiancehintscached", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xyz = gl_MultiTexCoord0.xyz;
    }
]], [[
    uniform sampler3D tex6, tex7, tex8;
    void main(void)
    {
        gl_FragData[0] = texture3D(tex6, gl_TexCoord[0].xyz);
        gl_FragData[1] = texture3D(tex7, gl_TexCoord[0].xyz);
        gl_FragData[2] = texture3D(tex8, gl_TexCoord[0].xyz);
    }
]])

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

if EV.glslversion >= 130 then
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
        #version 130
        uniform vec4 tetraclip;
        void main(void)
        {
            gl_Position = ftransform();
            gl_ClipDistance[0] = dot(gl_Vertex, tetraclip); 
        }
    ]], [[
        #version 130
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
--    F -> 3x3 weighted box filter
--    f -> 4x filter
--    m -> minimap

deferredlightvariantshader = function(...)
    local arg = { ... }
    local deferredlighttype = arg[3]
    local numsplits = arg[4] + 0
    local numrh     = arg[5] + 0
    local numlights = arg[6] + 0
    local baselight = arg[2] < 0 and true or ((arg[2] % 4) < 2)
    local spotlight = arg[2] >= 4

    local dlopt = {
        p = deferredlighttype:find("p") ~= nil,
        t = deferredlighttype:find("t") ~= nil,
        c = deferredlighttype:find("c") ~= nil,
        a = deferredlighttype:find("a") ~= nil,
        A = deferredlighttype:find("A") ~= nil,
        g = deferredlighttype:find("g") ~= nil,
        F = deferredlighttype:find("F") ~= nil,
        f = deferredlighttype:find("f") ~= nil,
        m = deferredlighttype:find("m") ~= nil,
        r = deferredlighttype:find("r") ~= nil,
        i = deferredlighttype:find("i") ~= nil
    }

    CAPI.variantshader(0, arg[1], arg[2], arg[2] < 0 and [[
        void main(void)
        {
            gl_Position = ftransform();
        }
    ]] or "", ([====[
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
                uniform sampler2DRectShadow tex4;
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
        @(dlopt.c and [=[
            uniform vec3 sunlightdir;
            uniform vec3 sunlightcolor;
            @(dlopt.r and [[
                uniform float giscale, rhnudge;
                uniform vec4 rhbb[@(numrh)];
                uniform vec3 rhscale[@(numrh)];
                uniform vec3 rhoffset[@(numrh)];
                uniform sampler3D tex6, tex7, tex8;
            ]])  
        ]=] or nil)

        uniform vec3 camera;
        uniform vec4 fogdir;
        uniform vec3 fogcolor, fogparams;
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
                    float m = max(adir.x, adir.y);
                    vec2 mparams = shadowparams.xy / max(adir.z, m);
                    vec4 proj;
                    if(adir.x > adir.y) proj = vec4(dir.zyx, 0.0); else proj = vec4(dir.xzy, 1.0);
                    if(adir.z > m) proj = vec4(dir, 2.0);
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
            ]] or (dlopt.F and [[
                #define shadowval(center, xyoff) shadow2DRect(tex4, vec3(center.xy + xyoff, center.z)).r
                float filtershadow(vec3 shadowtc)
                {
                    vec2 offset = fract(shadowtc.xy - 0.5);
                    vec3 center = shadowtc;
                    center.xy -= offset;
                    vec4 size = vec4(offset + 1.0, 2.0 - offset), weight = vec4(2.0 - 1.0 / size.xy, 1.0 / size.zw - 1.0);
                    return (1.0/9.0)*dot(size.zxzx*size.wwyy,
                        vec4(shadowval(center, weight.zw),
                             shadowval(center, weight.xw),
                             shadowval(center, weight.zy),
                             shadowval(center, weight.xy)));
                }
            ]] or (dlopt.f and [[
                #define shadowval(center, xoff, yoff) shadow2DRect(tex4, center + vec3(xoff, yoff, 0.0)).r
                float filtershadow(vec3 shadowtc)
                {
                    return dot(vec4(0.25),
                                vec4(shadowval(shadowtc, -0.4, 1.0),
                                    shadowval(shadowtc, -1.0, -0.4),
                                    shadowval(shadowtc, 0.4, -1.0),
                                    shadowval(shadowtc, 1.0, 0.4))); 
                }
            ]] or "#define filtershadow(shadowtc) shadow2DRect(tex4, shadowtc).r")))
        ]=] or nil)
        @(dlopt.c and [==[
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

            @(dlopt.r and [=[
                vec3 getrhlight(vec3 pos, vec3 norm)
                {
                    vec3 tc;
                    pos += norm*rhnudge;
                    @(([[
                        if(all(lessThan(abs(pos - rhbb[$j].xyz), vec3(rhbb[$j].w))))
                            tc = pos*rhscale[$j] + rhoffset[$j];
                        else
                    ]]):reppn("$j", 0, numrh - 1))
                    if(all(lessThan(abs(pos - rhbb[@(numrh - 1)].xyz), vec3(rhbb[@(numrh - 1)].w))))
                        tc = pos*rhscale[@(numrh - 1)] + rhoffset[@(numrh - 1)];
                    else tc = vec3(-1.0);
                    vec4 shr = texture3D(tex6, tc), shg = texture3D(tex7, tc), shb = texture3D(tex8, tc);
                    shr.rgb -= 0.5;
                    shg.rgb -= 0.5;
                    shb.rgb -= 0.5;
                    vec4 basis = vec4(norm*-(1.023326*0.488603/3.14159*2.0), (0.886226*0.282095/3.14159));
                    return clamp(vec3(dot(basis, shr), dot(basis, shg), dot(basis, shb)), 0.0, 1.0);
                }
            ]=] or nil)
        ]==] or nil)

        void main(void)
        {
            @(dlopt.i and [==[
                vec2 tc = (gl_FragCoord.xy - 0.5)*2.0 + 0.5;
                @(baselight and [=[
                    vec3 inferlight = lightscale.rgb, inferspec = vec3(0.0);
                    @(dlopt.a and [[
                        float ao = texture2DRect(tex5, tc*aoscale).r;
                        inferlight *= aoparams.x + ao*aoparams.y;
                    ]] or nil)
                ]=] or [[
                    vec3 inferlight = vec3(0.0), inferspec = vec3(0.0);
                ]])
            ]==] or [==[
                #define tc gl_FragCoord.xy
                @((baselight or (numlights > 1)) and [[
                    vec4 diffuse = texture2DRect(tex0, tc);
                ]] or nil)
                @(baselight and [=[
                    vec3 light = diffuse.rgb * lightscale.rgb;
                    @(dlopt.a and [[
                        float ao = texture2DRect(tex5, tc*aoscale).r;
                        light *= aoparams.x + ao*aoparams.y;
                    ]] or nil)
                    vec3 glow = texture2DRect(tex2, tc).rgb;
                    light += glow * lightscale.a;
                ]=] or [[
                    vec3 light = vec3(0.0);
                ]])
            ]==])
            @((numlights > 0 or dlopt.c) and [==[
                @(gdepthunpack("depth", "tex3", "tc", [=[
                    @(dlopt.m and [[
                        vec3 pos = (gl_TextureMatrix[0] * vec4(tc, depth, 1.0)).xyz;
                    ]] or [[
                        vec3 pos = (gl_TextureMatrix[0] * vec4(depth*tc, depth, 1.0)).xyz;
                    ]])
                    #define fogcoord depth
                ]=], [[
                    vec4 pos = gl_TextureMatrix[0] * vec4(tc, depth, 1.0);
                    pos.xyz /= pos.w;
                    #define fogcoord dot(fogdir, vec4(pos.xyz, 1.0))
                ]]))
                @((dlopt.c or numlights > 1) and [[
                    vec4 normal = texture2DRect(tex1, tc);
                    normal.xyz = normal.xyz*2.0 - 1.0;
                ]] or nil)
                @((((numlights + (dlopt.c and 1 or 0)) > 1) and (not dlopt.m)) and [[
                    vec3 camdir = normalize(camera - pos.xyz);
                    float facing = 2.0*dot(normal.xyz, camdir);
                ]] or nil)
            ]==] or ((not dlopt.m) and [[
                @(gdepthunpack("depth", "tex3", "tc"))
                #define fogcoord depth
            ]] or nil))
            @(dlopt.c and [===[
                @(dlopt.r and [[
                    vec3 rhlight = @(not dlopt.i and "diffuse.rgb *" or nil) getrhlight(pos.xyz, normal.xyz) * giscale;
                ]] or nil)
                float sunfacing = dot(sunlightdir, normal.xyz);
                if(sunfacing > 0.0)
                {
                    vec3 csmpos = (gl_TextureMatrix[1] * vec4(pos.xyz, 0.0)).xyz;
                    vec3 csmtc = getcsmtc(pos.xyz);
                    float sunoccluded = sunfacing * filtershadow(csmtc);
                    @(dlopt.m and [[
                        light += diffuse.rgb * sunlightcolor * sunoccluded;
                    ]] or [==[
                        @(((numlights + (dlopt.c and 1 or 0)) == 1) and [[
                            vec3 camdir = normalize(camera - pos.xyz);
                            float facing = 2.0*dot(normal.xyz, camdir);
                        ]] or nil)
                        float sunspec = pow(clamp(sunfacing*facing - dot(camdir, sunlightdir), 0.0, 1.0), 8.0) * normal.a;
                        @(dlopt.r and (dlopt.i and [[
                            rhlight += sunoccluded;
                            inferspec += sunspec * sunoccluded @(dlopt.A and "* (aoparams.z + ao*aoparams.w)" or nil) * sunlightcolor;
                        ]] or [[
                            rhlight += (diffuse.rgb + sunspec) * sunoccluded;
                        ]]) or [=[
                            @(dlopt.A and "sunoccluded *= aoparams.z + ao*aoparams.w;" or nil)
                            @(dlopt.i and [[
                                inferlight += sunoccluded * sunlightcolor;
                                inferspec += sunspec * sunoccluded * sunlightcolor;
                            ]] or [[
                                light += (diffuse.rgb + sunspec) * sunoccluded * sunlightcolor;
                            ]])
                        ]=])
                    ]==])
                }
                @(dlopt.r and [[
                    @(dlopt.i and "inferlight" or "light") += rhlight @(dlopt.A and "* (aoparams.z + ao*aoparams.w)" or nil) * sunlightcolor;
                ]] or nil)
            ]===] or nil)
            @(([===[
                vec3 light$jdir = (pos.xyz - lightpos[$j].xyz) * lightpos[$j].w;
                float light$jdist2 = dot(light$jdir, light$jdir);
                if(light$jdist2 < 1.0)
                {
                    @((numlights == 1 and (not dlopt.c)) and [[
                        vec4 normal = texture2DRect(tex1, tc);
                        normal.xyz = normal.xyz*2.0 - 1.0;
                    ]] or nil)
                    float light$jfacing = dot(light$jdir, normal.xyz);
                    if(light$jfacing < 0.0) 
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

                        @(dlopt.i and [=[
                            @((numlights + (dlopt.c and 1 or 0)) == 1 and [[
                                vec3 camdir = normalize(camera - pos.xyz);
                                float facing = 2.0*dot(normal.xyz, camdir);
                            ]] or nil)
                            float light$jspec = pow(clamp(light$jinvdist*(dot(camdir, light$jdir) - light$jfacing*facing), 0.0, 1.0), 8.0) * normal.a;
                            inferlight += lightcolor[$j] * light$jatten;
                            inferspec += light$jspec * lightcolor[$j] * light$jatten;
                        ]=] or [==[
                            @((numlights == 1 and not baselight) and [[
                                vec4 diffuse = texture2DRect(tex0, tc);
                            ]] or nil)
                            @(dlopt.m and [[
                                light += diffuse.rgb * lightcolor[$j] * light$jatten;
                            ]] or [=[
                                @((numlights + (dlopt.c and 1 or 0)) == 1 and [[
                                    vec3 camdir = normalize(camera - pos.xyz);
                                    float facing = 2.0*dot(normal.xyz, camdir);
                                ]])
                                float light$jspec = pow(clamp(light$jinvdist*(dot(camdir, light$jdir) - light$jfacing*facing), 0.0, 1.0), 8.0) * normal.a;
                                light += (diffuse.rgb + light$jspec) * lightcolor[$j] * light$jatten;
                                @(((numlights + (baselight and 1 or 0)) == 1) and [[
                                    float foglerp = clamp((fogparams.y + fogcoord)*fogparams.z, 0.0, 1.0);
                                    light *= foglerp;
                                ]] or nil)
                            ]=])
                        ]==])
                        @(spotlight and "}" or nil)
                    }
                }
            ]===]):reppn("$j", 0, numlights))
            @(dlopt.m and (baselight and [[
                gl_FragColor.rgb = light;
                gl_FragColor.a = diffuse.a;
            ]] or [[
                gl_FragColor.rgb = light;
                gl_FragColor.a = 0.0;
            ]]) or (dlopt.i and [[
                gl_FragData[0].rgb = inferlight;
                gl_FragData[1].rgb = inferspec;
            ]] or ((((baselight or numlights > 1) and [=[
                float foglerp = clamp((fogparams.y + fogcoord)*fogparams.z, 0.0, 1.0);
                @(baselight and [[
                    gl_FragColor.rgb = mix(fogcolor*diffuse.a, light, foglerp);
                    gl_FragColor.a = diffuse.a;
                ]] or [[
                    gl_FragColor.rgb = light*foglerp;
                    gl_FragColor.a = 0.0;
                ]])
            ]=] or [[
                gl_FragColor.rgb = light;
                gl_FragColor.a = 0.0;
            ]])))))
        }
    ]====]):eval_embedded(nil, { dlopt = dlopt, numsplits = numsplits, numrh = numrh, numlights = numlights, baselight = baselight, spotlight = spotlight }, _G), 64) end

deferredlightshader = function(arg1, arg2, arg3, arg4, arg5)
    local shadername = "deferredlight" .. arg1 .. arg2 .. arg3
    deferredlightvariantshader(shadername, -1, arg1 .. arg3, arg4, arg5, 0) -- base shader, no point lights, sunlight
    for i = 1, 8 do
        deferredlightvariantshader(shadername, 0, arg1 .. arg3,         arg4, arg5, i) -- row 0, point lights, sunlight
        deferredlightvariantshader(shadername, 1, arg1 .. arg2 .. arg3, arg4, arg5, i) -- row 1, shadowed point lights, sunlight
        deferredlightvariantshader(shadername, 2, arg1,                 arg4, arg5, i) -- row 2, point lights
        deferredlightvariantshader(shadername, 3, arg1 .. arg2,         arg4, arg5, i) -- row 3, shadowed point lights
        deferredlightvariantshader(shadername, 4, arg1 .. arg3,         arg4, arg5, i) -- row 4, spot lights, sunlight
        deferredlightvariantshader(shadername, 5, arg1 .. arg2 .. arg3, arg4, arg5, i) -- row 5, shadowed spot lights, sunlight
        deferredlightvariantshader(shadername, 6, arg1,                 arg4, arg5, i) -- row 6, spot lights
        deferredlightvariantshader(shadername, 7, arg1 .. arg2,         arg4, arg5, i) -- row 7, shadowed spot lights
    end
end

lazyshader(0, "inferredlight", [[
    void main(void)
    {
        gl_Position = ftransform();
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + 0.5;
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0, tex1, tex2, tex3, tex9, tex10;
    uniform vec3 camera;
    uniform vec4 fogdir;
    uniform vec3 fogcolor, fogparams;
    uniform vec4 lightscale;
    uniform vec2 inferthreshold;
    @(gdepthunpackparams)

    void main(void)
    {
        vec3 color0 = texture2DRect(tex9, gl_TexCoord[0].xy).rgb;
        vec3 color1 = texture2DRect(tex9, gl_TexCoord[1].xy).rgb;
        vec3 spec0 = texture2DRect(tex10, gl_TexCoord[0].xy).rgb;
        vec3 spec1 = texture2DRect(tex10, gl_TexCoord[1].xy).rgb;
        vec3 diff = max(abs(color1 - color0), abs(spec0 - spec1)*inferthreshold.y);
        if(max(max(diff.x, diff.y), diff.z) > inferthreshold.x) discard;

        vec4 diffuse = texture2DRect(tex0, gl_FragCoord.xy);
        vec3 light = (color0 + color1)*diffuse.rgb + spec0 + spec1;
        vec3 glow = texture2DRect(tex2, gl_FragCoord.xy).rgb;
        light += glow * lightscale.a;

        @(gdepthunpack("depth", "tex3", "gl_FragCoord.xy"))
        float foglerp = clamp((fogparams.y + depth)*fogparams.z, 0.0, 1.0);
        gl_FragColor.rgb = mix(fogcolor*diffuse.a, light, foglerp);
        gl_FragColor.a = diffuse.a;
    }
]]):eval_embedded())

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

lumweights = "0.2126, 0.7152, 0.0722"
--lumweights = "0.299, 0.587, 0.114"

CAPI.shader(0, "hdrluminance", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    uniform vec2 hdrgamma;
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_TexCoord[0].xy).rgb*2.0;
        color = pow(color, vec3(hdrgamma.x));
        float lum = dot(color, vec3(@(lumweights)));
        float loglum = (log2(clamp(lum, 0.015625, 4.0)) + 6.0) * (1.0/(6.0+2.0));// allow values as low as 2^-6, and as high 2^2
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
    uniform vec2 hdrgamma;
    varying vec2 tap0, tap1, tap2, tap3;
    void main(void)
    {
        @(([[
            vec3 color$i = texture2DRect(tex0, tap$i).rgb*2.0;
            color$i = pow(color$i, vec3(hdrgamma.x));
            float lum$i = dot(color$i, vec3(@(lumweights)));
            float loglum$i = (log2(clamp(lum$i, 0.015625, 4.0)) + 6.0) * (1.0/(6.0+2.0));
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
        float lum = exp2((texture2DRect(tex0, gl_TexCoord[0].xy).r * (6.0+2.0)) - 6.0);
        gl_FragColor = vec4(vec3(lum*0.25), accumscale);
    }
]])

CAPI.shader(0, "hdrbloom", [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex2; 
    uniform vec4 hdrparams;
    varying float lumscale, lumthreshold;
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        float avglum = 4.0*texture2DRect(tex2, vec2(0.5, 0.5)).r;
        lumscale = hdrparams.x * -log2(1.0 - clamp(avglum, 0.025, 0.25))/(avglum + 1e-4);
        lumthreshold = -log2(1.0 - hdrparams.z);
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0; 
    uniform vec2 hdrgamma;
    varying float lumscale, lumthreshold;
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_TexCoord[0].xy).rgb*2.0;
        color = pow(color, vec3(hdrgamma.x));
        float lum = dot(color, vec3(@(lumweights)));
        color *= max(lum*lumscale - lumthreshold, 0.0) / (lum + 1e-4);
        gl_FragColor.rgb = pow(color, vec3(hdrgamma.y));
    }
]]):eval_embedded(nil, { lumweights = lumweights }))

CAPI.shader(0, "hdrtonemap", [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex2; 
    uniform vec4 hdrparams;
    varying float lumscale, lumsaturate;
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        gl_TexCoord[1].xy = gl_MultiTexCoord1.xy;
        float avglum = 4.0*texture2DRect(tex2, vec2(0.5, 0.5)).r;
        lumscale = hdrparams.x * -log2(1.0 - clamp(avglum, 0.025, 0.25))/(avglum + 1e-4);
        lumsaturate = -log2(1.0 - hdrparams.y) / lumscale;
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0, tex1;
    uniform vec4 hdrparams;
    uniform vec2 hdrgamma;
    varying float lumscale, lumsaturate;
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_TexCoord[0].xy).rgb*2.0;
        vec3 bloom = texture2DRect(tex1, gl_TexCoord[1].xy).rgb*hdrparams.w;
        color += bloom;
        color = pow(color, vec3(hdrgamma.x));
//        color = 1.0 - exp2(-color*lumscale);
        float lum = dot(color, vec3(@(lumweights)));
        color = min(color, lumsaturate);
        color *= (1.0 - exp2(-lum*lumscale)) / (dot(color, vec3(@(lumweights))) + 1e-4);
        color = pow(color, vec3(hdrgamma.y));
        gl_FragColor.rgb = color;
    }
]]):eval_embedded(nil, { lumweights = lumweights }))

lazyshader(0, "hdrtonemapluma", [[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex2; 
    uniform vec4 hdrparams;
    varying float lumscale, lumsaturate;
    void main(void)
    {
        gl_Position = gl_Vertex;
        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        gl_TexCoord[1].xy = gl_MultiTexCoord1.xy;
        float avglum = 4.0*texture2DRect(tex2, vec2(0.5, 0.5)).r;
        lumscale = hdrparams.x * -log2(1.0 - clamp(avglum, 0.025, 0.25))/(avglum + 1e-4);
        lumsaturate = -log2(1.0 - hdrparams.y) / lumscale;
    }
]], ([[
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0, tex1;
    uniform vec4 hdrparams;
    uniform vec2 hdrgamma;
    varying float lumscale, lumsaturate;
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_TexCoord[0].xy).rgb*2.0;
        vec3 bloom = texture2DRect(tex1, gl_TexCoord[1].xy).rgb*hdrparams.w;
        color += bloom;
        color = pow(color, vec3(hdrgamma.x));
//        color = 1.0 - exp2(-color*lumscale);
        float lum = dot(color, vec3(@(lumweights)));
        color = min(color, lumsaturate);
        color *= (1.0 - exp2(-lum*lumscale)) / (dot(color, vec3(@(lumweights))) + 1e-4);
        color = pow(color, vec3(hdrgamma.y));
        gl_FragColor = vec4(color, dot(color, vec3(@(lumweights))));
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

lazyshader(0, "hdrnopluma", [[
    void main(void)
    {
        gl_Position = gl_Vertex;
    }
]], ([[ 
    #extension GL_ARB_texture_rectangle : enable
    uniform sampler2DRect tex0;
    void main(void)
    {
        vec3 color = texture2DRect(tex0, gl_FragCoord.xy).rgb;
        gl_FragColor = vec4(color, dot(color, vec3(@(lumweights))));
    }
]]):eval_embedded(nil, { lumweights = lumweights }))

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
        uniform vec3 tapparams;
        uniform vec2 contrastparams;
        uniform vec4 offsetscale;
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
                float dist2$i = dot(v$i, v$i);
                obscure += step(dist2$i, tapparams.z) * max(0.0, dot(v$i, normal) + depth*1.0e-2) / (dist2$i + 1.0e-5);
            ]]):reppn("$i", 0, maxaotaps))
            gl_FragColor.rg = vec2(pow(clamp(1.0 - contrastparams.x*obscure, 0.0, 1.0), contrastparams.y), depth);
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
    if EV.usetexrect ~= 0 then
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
        @(EV.gdepthformat == 1 and [[
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
                float fresnel = 0.25 + 0.75*pow(clamp(1.0 - dot(camvec, bump), 0.0, 1.0), 4.0);
                rcolor = mix(rcolor, reflect, fresnel*edgefade*clamp(-8.0*reflectdir.z, 0.0, 1.0));
            ]==] or (arg1:find("env") ~= nil and [[
                vec3 reflect = textureCube(tex4, -reflect(camvec, bump)).rgb*0.5;
                float fresnel = 0.5*pow(clamp(1.0 - dot(camvec, bump), 0.0, 1.0), 4.0);
                rcolor = mix(rcolor, reflect, fresnel);
            ]] or nil))

            gl_FragData[0] = vec4(0.0, 0.0, 0.0, alpha);
            gl_FragData[1] = vec4(bump*0.5+0.5, waterspec*alpha);
            gl_FragData[2].rgb = rcolor*alpha;
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
        uniform vec4 waterdeepfade;
        @(gdepthunpackparams)
        void main(void)
        {
            @(gdepthunpack("depth", "tex9", "gl_FragCoord.xy", [[
                vec3 ctc = (gl_TextureMatrix[0] * vec4(depth*gl_FragCoord.xy, depth, 1.0)).xyz;
            ]], [[
                vec4 ctc = gl_TextureMatrix[0] * vec4(gl_FragCoord.xy, depth, 1.0);
                ctc.xyz /= ctc.w;
            ]]))
            float caustics = causticsblend.x*texture2D(tex0, ctc.xy).r + causticsblend.y*texture2D(tex1, ctc.xy).r + causticsblend.z;
            caustics *= clamp(ctc.z, 0.0, 1.0) * clamp(1.0 - ctc.z*waterdeepfade.w, 0.0, 1.0);
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
        uniform vec3 fogcolor, fogparams;
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
            float foglerp = clamp((fogparams.x - fogcoord) * fogparams.z, 0.0, 1.0);
            foglerp *= clamp(2.0*fogbelow + 0.5, 0.0, 1.0);
            vec3 fogcolor = mix(fogcolor, waterdeepcolor, clamp(fogbelow*waterdeepfade, 0.0, 1.0));
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
        gl_FragData[1] = vec4(bumpw*0.5+0.5, lavaspec);
        gl_FragData[2].rgb = diffuse*lavaglow;
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
        env *= 0.1 + 0.4*pow(clamp(1.0 - invfresnel, 0.0, 1.0), 2.0);

        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(bumpw*0.5+0.5, waterfallspec*(1.0 - dot(diffuse, vec3(0.33))));
        gl_FragData[2].rgb = mix(rcolor, waterfallcolor, diffuse) + env;
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
        gl_FragData[1] = vec4(bumpw*0.5+0.5, waterfallspec*(1.0 - dot(diffuse, vec3(0.33))));
        gl_FragData[2].rgb = mix(rcolor, waterfallcolor, diffuse);
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
        env *= 0.1 + 0.4*pow(clamp(1.0 - invfresnel, 0.0, 1.0), 2.0);
  
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragData[1] = vec4(bumpw*0.5+0.5, glassspec);
        gl_FragData[2].rgb = rcolor + env;
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
        gl_FragData[1] = vec4(bumpw*0.5+0.5, glassspec);
        gl_FragData[2].rgb = rcolor; 
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
    package.loaded["shaders.smaa"] = nil
end

fxaashaders = function(arg1)
    fxaapreset = arg1
    require("shaders.fxaa")
    package.loaded["shaders.fxaa"] = nil
end
