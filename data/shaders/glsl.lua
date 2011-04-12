-- GLSL Lua shaders for CubeCreate

-- safe nesting level involved
function lazyshader(st, nm, vs, fs)
    cc.shader.defer(st, nm,
        string.format([===================[
            cc.shader.std(%i, "%s",
                [====================[
                    %s
                ]====================],
                [====================[
                    %s
                ]====================]
            )
        ]===================], st, nm, vs, fs)
    )
end

lmcoordscale = 1.0 / 32767.0

-- used for any textured polys that don't have a shader set

cc.shader.std(4, "default",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = gl_MultiTexCoord0;
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            gl_FragColor = gl_Color * texture2D(tex0, gl_TexCoord[0].xy);
        }
    ]]
)

cc.shader.std(4, "rect",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = gl_MultiTexCoord0;
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0;
        void main(void)
        {
            gl_FragColor = gl_Color * texture2DRect(tex0, gl_TexCoord[0].xy);
        }
    ]]
)

cc.shader.std(4, "cubemap",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = gl_MultiTexCoord0;
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        uniform samplerCube tex0;
        void main(void)
        {
            gl_FragColor = gl_Color * textureCube(tex0, gl_TexCoord[0].xyz);
        }
    ]]
)

cc.shader.std(4, "rgbonly",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = gl_MultiTexCoord0;
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            gl_FragColor.rgb = gl_Color.rgb * texture2D(tex0, gl_TexCoord[0].xy).rgb;
            gl_FragColor.a   = gl_Color.a;
        }
    ]]
)

-- same, but without texture sampling (needed by some HUD)

cc.shader.std(4, "notexture",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        void main(void)
        {
            gl_FragColor = gl_Color;
        }
    ]]
)

-- fogged variants of default shaders

cc.shader.std(4, "fogged",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = gl_MultiTexCoord0;
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            gl_FragColor = gl_Color * texture2D(tex0, gl_TexCoord[0].xy);
        }
    ]]
)

cc.shader.std(4, "foggednotexture",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        void main(void)
        {
            gl_FragColor = gl_Color;
        }
    ]]
)

-- for filling the z-buffer only (i.e. multi-pass rendering, OQ)

cc.shader.std(4, "nocolor",
    [[ void main() { gl_Position = ftransform(); } ]],
    [[ void main() {} ]]
)

cc.shader.std(4, "nocolorglsl",
    [[ void main() { gl_Position = ftransform(); } ]],
    [[ void main() {} ]]
)

-- default lightmapped world shader, does texcoord gen

function worldshader(...)
    local arg = { ... }
    cc.shader.std(
        string.find(arg[1], "env") and 6 or 4,
        arg[1],
        [[
            #pragma CUBE2_fog
            %(arg5)s
            uniform vec4 texgenscroll;
            void main(void)
            {
                gl_Position = ftransform();
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texgenscroll.xy;
                gl_TexCoord[1].xy = gl_MultiTexCoord1.xy * %(lmcs)s;

                %(arg2)s

                #pragma CUBE2_shadowmap
                #pragma CUBE2_dynlight
                #pragma CUBE2_water
            }
        ]] % { arg2 = arg[2] or '', arg5 = arg[5] or '', lmcs = lmcoordscale },
        [[
            %(arg5)s
            %(arg6)s
            uniform vec4 colorparams;
            uniform sampler2D diffusemap, lightmap;
            void main(void)
            {
                vec4 diffuse = texture2D(diffusemap, gl_TexCoord[0].xy);   
                vec4 lm = texture2D(lightmap, gl_TexCoord[1].xy);

                #pragma CUBE2_shadowmap lm
                #pragma CUBE2_dynlight lm

                %(arg3)s

                diffuse *= colorparams;
                %(arg4)s

                #pragma CUBE2_water
            }
        ]] % {
            argln = #arg,
            arg3 = arg[3] or '',
            arg4 = (#arg < 4 or arg[4] == "") and "gl_FragColor = diffuse * lm;" or arg[4],
            arg5 = arg[5] or '',
            arg6 = arg[6] or ''
        }
    )
end

function glareworldshader(...)
    local arg = { ... }
    cc.shader.variant(
        string.find(arg[1], "env") and 6 or 4,
        arg[1], 4,
        [[
            #pragma CUBE2_fog
            %(arg4)s
            uniform vec4 texgenscroll;
            void main(void)
            {
                gl_Position = ftransform();
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texgenscroll.xy;
                gl_TexCoord[1].xy = gl_MultiTexCoord1.xy * %(lmcs)s;

                %(arg2)s
            }
        ]] % { arg2 = arg[2] or '', arg4 = arg[4] or '', lmcs = lmcoordscale },
        [[
            %(arg4)s
            %(arg5)s
            uniform vec4 colorparams;
            uniform sampler2D diffusemap, lightmap;
            void main(void)
            {
                %(arg3)s
            }
        ]] % { arg3 = arg[3] or '', arg4 = arg[4] or '', arg5 = arg[5] or '' }
    )
end

worldshader("stdworld", "", "")

cc.shader.defer(4, "decalworld", [[
    worldshader(
        "decalworld", "",
        [=[
            vec4 diffuse2 = texture2D(decal, gl_TexCoord[0].xy);
            diffuse.rgb = mix(diffuse.rgb, diffuse2.rgb, diffuse2.a);
        ]=],
        "", "", "uniform sampler2D decal;"
    )
]])

cc.shader.defer(4, "glowworld", [[
    cc.shader.defup("glowcolor", 1, 1, 1) -- glow color
    worldshader(
        "glowworld", "", "",
        [=[
            vec3 glow = texture2D(glowmap, gl_TexCoord[0].xy).rgb;
            glow *= glowcolor.rgb;
            gl_FragColor = diffuse*lm + vec4(glow, 0.0);
        ]=],
        "", "uniform sampler2D glowmap;"
    )
    glareworldshader(
        "glowworld", "",
        [=[
            vec3 glow = texture2D(glowmap, gl_TexCoord[0].xy).rgb;
            glow *= glowcolor.rgb;
            float k = max(glow.r, max(glow.g, glow.b)); 
            gl_FragColor.rgb = min(k*k*32.0, 1.0) * glow;
            #pragma CUBE2_variantoverride gl_FragColor.a = texture2D(lightmap, gl_TexCoord[1].xy).a; //
            gl_FragColor.a = colorparams.a;
        ]=],
        "",
        [=[
            uniform sampler2D glowmap; 
            #pragma CUBE2_variant uniform sampler2D lightmap;
        ]=]
    )
]])

cc.shader.defer(4, "pulseworld", [[
    cc.shader.defup("pulsespeed", 1) -- pulse frequency (Hz)
    worldshader(
        "pulseworld",
        "pulse = abs(fract(millis.x * pulsespeed.x)*2.0 - 1.0);",
        [=[
            vec3 diffuse2 = texture2D(decal, gl_TexCoord[0].xy).rgb; 
            diffuse.rgb = mix(diffuse.rgb, diffuse2, pulse);
        ]=],
        "", "uniform vec4 millis; varying float pulse;", "uniform sampler2D decal;"
    )
]])

cc.shader.defer(4, "pulseglowworld", [[
    cc.shader.defup("glowcolor", 1, 1, 1) -- glow color
    cc.shader.defup("pulseglowspeed", 1) -- pulse frequency (Hz)
    cc.shader.defup("pulseglowcolor", 0, 0, 0) -- pulse glow color
    worldshader(
        "pulseglowworld",
        "pulse = mix(glowcolor.rgb, pulseglowcolor.rgb, abs(fract(millis.x * pulseglowspeed.x)*2.0 - 1.0));",
        "",
        [=[
            vec3 glow = texture2D(glowmap, gl_TexCoord[0].xy).rgb;
            gl_FragColor = diffuse*lm + vec4(glow*pulse, 0.0);
        ]=],
        "uniform vec4 millis; varying vec3 pulse;", "uniform sampler2D glowmap;"
    )
    glareworldshader(
        "pulseglowworld",
        "pulse = mix(glowcolor.rgb, pulseglowcolor.rgb, abs(fract(millis.x * pulseglowspeed.x)*2.0 - 1.0));",
        [=[
            vec3 glow = texture2D(glowmap, gl_TexCoord[0].xy).rgb;
            glow *= pulse;
            float k = max(glow.r, max(glow.g, glow.b)); 
            gl_FragColor.rgb = min(k*k*32.0, 1.0) * glow;
            #pragma CUBE2_variantoverride gl_FragColor.a = texture2D(lightmap, gl_TexCoord[1].xy).a; //
            gl_FragColor.a = colorparams.a;
        ]=],
        "uniform vec4 millis; varying vec3 pulse;",
        [=[
            uniform sampler2D glowmap; 
            #pragma CUBE2_variant uniform sampler2D lightmap;
        ]=]
    )
]])

cc.shader.std(4, "fogworld",
    [[ void main() { gl_Position = ftransform(); } ]],
    [[ void main() { gl_FragColor = gl_Fog.color; } ]]
)

cc.shader.std(4, "noglareworld",
    [[ void main() { gl_Position = ftransform(); } ]],
    [[ void main() { gl_FragColor = vec4(0.0); } ]]
)

cc.shader.std(4, "noglareblendworld",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord1.xy * %(lmcs)s;
        }
    ]] % { lmcs = lmcoordscale },
    [[
        uniform sampler2D lightmap;
        void main(void)
        {
            gl_FragColor.rgb = vec3(0.0);
            gl_FragColor.a = texture2D(lightmap, gl_TexCoord[0].xy).a;
        }
    ]]
)

cc.shader.std(4, "noglarealphaworld",
    [[
        void main(void)
        {
            gl_Position = ftransform();
        }
    ]],
    [[
        uniform vec4 colorparams;
        uniform sampler2D lightmap;
        void main(void)
        {
            gl_FragColor.rgb = vec3(0.0);
            gl_FragColor.a = colorparams.a;
        }
    ]]
)

cc.shader.defer(6, "envworld", [[
    cc.shader.defup("envscale", 0.2, 0.2, 0.2) -- reflectivity
    worldshader(
        "envworld",
        [=[
            normal = gl_Normal;
            camvec = camera.xyz - gl_Vertex.xyz; 
        ]=],
        "vec3 reflect = textureCube(envmap, 2.0*normal*dot(camvec, normal) - camvec).rgb;",
        [=[
            diffuse *= lm;
            gl_FragColor.rgb = mix(diffuse.rgb, reflect, envscale.rgb);
            gl_FragColor.a = diffuse.a;
        ]=],
        "uniform vec4 camera; varying vec3 normal, camvec;", "uniform samplerCube envmap;"
    )

    cc.shader.defup("envscale", 0.2, 0.2, 0.2) -- reflectivity
    worldshader(
        "envworldfast",
        [=[
            vec3 camvec = camera.xyz - gl_Vertex.xyz;
            rvec = 2.0*gl_Normal*dot(camvec, gl_Normal) - camvec;
        ]=],
        "vec3 reflect = textureCube(envmap, rvec).rgb;",
        [=[
            diffuse *= lm;
            gl_FragColor.rgb = mix(diffuse.rgb, reflect, envscale.rgb);
            gl_FragColor.a = diffuse.a; 
        ]=],
        "uniform vec4 camera; varying vec3 rvec;", "uniform samplerCube envmap;"
    )

    cc.shader.defup("envscale", 0.2, 0.2, 0.2) -- reflectivity
    worldshader("envworldalt", "", "")

    cc.shader.alt("envworld", "envworldfast")
    cc.shader.fast("envworld", "envworldfast", 2)
    cc.shader.fast("envworld", "envworldalt", 1)
]])

cc.shader.std(4, "depthfxworld",
    [[
        uniform vec4 depthscale, depthoffsets;
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = depthoffsets - (gl_ModelViewMatrix * gl_Vertex).z*depthscale;
        }
    ]],
    [[
        void main(void)
        {
            gl_FragColor = gl_TexCoord[0];
        }
    ]]
)

cc.shader.std(4, "depthfxsplitworld",
    [[
        uniform vec4 depthscale, depthoffsets;
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = depthoffsets - (gl_ModelViewMatrix * gl_Vertex).z*depthscale;
        }
    ]],
    [[
        void main(void)
        {
            vec4 ranges = vec4(gl_TexCoord[0].x, fract(gl_TexCoord[0].yzw));
            ranges.xy -= ranges.yz*vec2(0.00390625, 0.00390625);
            gl_FragColor = ranges;
        }
    ]]
)

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
--    i -> glare intensity

function btopt(bt, a)
    return string.find(bt, a) ~= nil
end

function bumpvariantshader(...)
    local arg = { ... }
    local bts = {
        bt_e = tostring(btopt(arg[2], "e")),
        bt_o = tostring(btopt(arg[2], "o")),
        bt_t = tostring(btopt(arg[2], "t")),
        bt_r = tostring(btopt(arg[2], "r")),
        bt_R = tostring(btopt(arg[2], "R")),
        bt_s = tostring(btopt(arg[2], "s")),
        bt_S = tostring(btopt(arg[2], "S")),
        bt_p = tostring(btopt(arg[2], "p")),
        bt_P = tostring(btopt(arg[2], "P")),
        bt_g = tostring(btopt(arg[2], "g")),
        bt_G = tostring(btopt(arg[2], "G")),
        bt_i = tostring(btopt(arg[2], "i"))
    }
    local stype = btopt(arg[2], "e") and 7 or 5

    if not btopt(arg[2], "i") then
        if btopt(arg[2], "G") then
            cc.shader.defup("glowcolor", 1, 1, 1) -- glow color
            cc.shader.defup("pulseglowspeed", 1) -- pulse frequency (Hz)
            cc.shader.defup("pulseglowcolor", 0, 0, 0) -- pulse glow color
        elseif btopt(arg[2], "g") then
            cc.shader.defup("glowcolor", 1, 1, 1) -- glow color
        end

        if btopt(arg[2], "S") then
            cc.shader.defup("specscale", 6, 6, 6) -- spec map multiplier
        elseif btopt(arg[2], "s") then
            cc.shader.defup("specscale", 1, 1, 1) -- spec multiplier
        end

        if btopt(arg[2], "p") or btopt(arg[2], "P") then
            cc.shader.defup("parallaxscale", 0.06, -0.03) -- parallax scaling
        end

        if btopt(arg[2], "R") then
            cc.shader.defup("envscale", 1, 1, 1) -- reflectivity map multiplier
        elseif btopt(arg[2], "r") then
            cc.shader.defup("envscale", 0.2, 0.2, 0.2) -- reflectivity
        end
    else
        stype = btopt(arg[2], "s") and stype + 8 or stype
    end

    cc.shader.variant(
        stype, arg[1],
        btopt(arg[2], "i") and 4 or -1,
        string.template([[
            #pragma CUBE2_fog
            uniform vec4 texgenscroll;
            <$0 if %(bt_o)s then return "uniform vec4 orienttangent, orientbinormal;" end $0>
            <$0 if %(bt_t)s or %(bt_r)s then return "uniform vec4 camera; varying vec3 camvec;" end $0>
            <$0 if %(bt_G)s then return "uniform vec4 millis; varying float pulse;" end $0>
            <$0 if %(bt_r)s then return "varying mat3 world;" end $0>
            void main(void)
            {
                gl_Position = ftransform();
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texgenscroll.xy;
                // need to store these in Z/W to keep texcoords < 6, otherwise kills performance on Radeons
                // but slows lightmap access in fragment shader a bit, so avoid when possible
                <$0
                    if minimizetcusage == 1 or %(bt_r)s then
                        return "gl_TexCoord[0].zw = gl_MultiTexCoord1.yx * <$1=lmcoordscale$1>;"
                    else
                        return "gl_TexCoord[1].xy = gl_MultiTexCoord1.xy * <$1=lmcoordscale$1>;"
                    end
                $0>
                <$0
                    if %(bt_o)s then
                        return [=[
                            vec4 tangent = gl_Color*2.0 - 1.0;
                            vec3 binormal = cross(gl_Normal, tangent.xyz) * tangent.w;
                            <$1
                                if %(bt_t)s then
                                    return [==[
                                        // trans eye vector into TS
                                        vec3 camobj = camera.xyz - gl_Vertex.xyz;
                                        camvec = vec3(dot(camobj, tangent.xyz), dot(camobj, binormal), dot(camobj, gl_Normal));
                                    ]==]
                                end
                            $1>
                            <$1
                                if %(bt_r)s then
                                    return [==[
                                        <$2
                                            if not %(bt_t)s then
                                                return "camvec = camera.xyz - gl_Vertex.xyz;"
                                            end
                                        $2>
                                        // calculate tangent -> world transform
                                        world = mat3(tangent.xyz, binormal, gl_Normal);
                                    ]==]
                                end
                            $1>
                        ]=]
                    end
                $0>
                <$0
                    if %(bt_G)s then
                        return "pulse = abs(fract(millis.x*pulseglowspeed.x)*2.0 - 1.0);"
                    end
                $0>
                <$0
                    if not %(bt_i)s or %(bt_s)s then
                        return "#pragma CUBE2_dynlight"
                    end
                $0>
                <$0
                    if not %(bt_i)s then
                        return [=[
                            #pragma CUBE2_shadowmap
                            #pragma CUBE2_water
                        ]=]
                    end
                $0>
            }
        ]] % bts),
        string.template([[
            uniform vec4 colorparams;
            uniform sampler2D diffusemap, lmcolor, lmdir;
            <$0
                if not %(bt_i)s or %(bt_s)s or %(bt_p)s or %(bt_P)s then
                    return "uniform sampler2D normalmap;"
                end
            $0>
            <$0 if %(bt_t)s or %(bt_r)s then return "varying vec3 camvec;" end $0>
            <$0 if %(bt_g)s then return "uniform sampler2D glowmap;" end $0>
            <$0 if %(bt_G)s then return "varying float pulse;" end $0>
            <$0 if %(bt_r)s then return "uniform samplerCube envmap; varying mat3 world;" end $0>
            <$0 if not %(bt_i)s or %(bt_s)s then return "uniform vec4 ambient;" end $0>
            void main(void)
            {
                #define lmtc <$0 return (minimizetcusage == 1 or %(bt_r)s) and "gl_TexCoord[0].wz" or "gl_TexCoord[1].xy" $0>
                <$0
                    if not %(bt_i)s or %(bt_s)s then
                        return [=[
                            vec4 lmc = texture2D(lmcolor, lmtc);
                            gl_FragColor.a = colorparams.a * lmc.a;
                            vec3 lmlv = texture2D(lmdir, lmtc).rgb*2.0 - 1.0;
                        ]=]
                    end
                $0>
                <$0 if %(bt_t)s then return "vec3 camdir = normalize(camvec);" end $0>
                <$0
                    if %(bt_p)s then
                        return [=[
                            float height = texture2D(normalmap, gl_TexCoord[0].xy).a;
                            vec2 dtc = gl_TexCoord[0].xy + camdir.xy*(height*parallaxscale.x + parallaxscale.y);
                        ]=]
                    end
                $0>
                <$0
                    if %(bt_P)s then
                        return [=[
                            const float step = -1.0/7.0;
                            vec3 duv = vec3((step*parallaxscale.x/camdir.z)*camdir.xy, step);
                            vec3 htc = vec3(gl_TexCoord[0].xy + duv.xy*parallaxscale.y, 1.0);
                            vec4 height = texture2D(normalmap, htc.xy);
                            <$1
                                sum = ""
                                for i = 1, 7 do
                                    sum = sum .. [==[
                                        htc += height.w < htc.z ? duv : vec(0.0);
                                        height = texture2D(normalmap, htc.xy);
                                    ]==]
                                end
                                return sum
                            $1>
                            #define dtc htc.xy
                            #define bump height.xyz    
                        ]=]
                    end
                $0>
                <$0
                    if not %(bt_p)s and not %(bt_P)s then
                        return "#define dtc gl_TexCoord[0].xy"
                    end
                $0>
                <$0
                    if not %(bt_i)s or %(bt_S)s then
                        return "vec4 diffuse = texture2D(diffusemap, dtc);"
                    end
                $0>
                <$0
                    if not %(bt_i)s then
                        return "diffuse.rgb *= colorparams.rgb;"
                    end
                $0>
                <$0
                    if not %(bt_i)s or %(bt_s)s then
                        return [=[
                            <$1
                                if not %(bt_P)s then
                                    return "vec3 bump = texture2D(normalmap, dtc).rgb;"
                                end
                            $1>
                            bump = bump*2.0 - 1.0;
                        ]=]
                    end
                $0>
                <$0
                    if %(bt_s)s then
                        return [=[
                            vec3 halfangle = normalize(camdir + lmlv);
                            float spec = pow(clamp(dot(halfangle, bump), 0.0, 1.0), <$1 return %(bt_i)s and "128.0" or "32.0" $1>);
                            <$1 if %(bt_i)s then return "spec = min(spec*64.0, 1.0);" end $1>
                            <$1 if %(bt_S)s then return "spec *= diffuse.a;" end $1>
                            <$1
                                if %(bt_i)s then
                                    return [==[<$2 return %(bt_S)s and "diffuse.rgb" or "vec3 diffuse" $2> = specscale.xyz*spec;]==]
                                else
                                    return "diffuse.rgb += specscale.xyz*spec;"
                                end
                            $1>
                        ]=]
                    end
                $0>
                <$0
                    if not %(bt_i)s or %(bt_s)s then
                        return [=[
                            lmc.rgb = max(lmc.rgb*clamp(dot(lmlv, bump), 0.0, 1.0), ambient.xyz);
                            <$1
                                if %(bt_i)s then
                                    return [==[
                                        #pragma CUBE2_dynlight lmc
                                        <$2 return %(bt_g)s and "diffuse.rgb" or "gl_FragColor.rgb" $2> = diffuse.rgb * lmc.rgb;
                                    ]==]
                                else
                                    return [==[
                                        #pragma CUBE2_shadowmap lmc
                                        #pragma CUBE2_dynlight lmc
                                        <$2 return (%(bt_g)s or %(bt_r)s) and "diffuse.rgb" or "gl_FragColor.rgb" $2> = diffuse.rgb * lmc.rgb;
                                    ]==]
                                end
                            $1>
                        ]=]
                    end
                $0>
                <$0
                    if %(bt_r)s then
                        return [=[
                            vec3 rvec;
                            <$1
                                if %(bt_t)s then
                                    return [==[
                                        vec3 rvects = 2.0*bump*dot(camvec, bump) - camvec;
                                        rvec = world * rvects;
                                    ]==]
                                else
                                    return [==[
                                        vec3 bumpw = world * bump;
                                        rvec = 2.0*bumpw*dot(camvec, bumpw) - camvec;
                                    ]==]
                                end
                            $1>
                            vec3 reflect = textureCube(envmap, rvec).rgb;
                            <$1
                                if %(bt_R)s then
                                    return "vec3 rmod = envscale.xyz*diffuse.a;"
                                else
                                    return "#define rmod envscale.xyz"
                                end
                            $1>
                            <$1 return %(bt_g)s and "diffuse.rgb" or "gl_FragColor.rgb" $1> = mix(diffuse.rgb, reflect, rmod);
                        ]=]
                    end
                $0>
                <$0
                    if %(bt_g)s then
                        return [=[
                            vec3 glow = texture2D(glowmap, dtc).rgb;
                            <$1
                                if %(bt_G)s then
                                    return "vec3 pulsecol = mix(glowcolor.xyz, pulseglowcolor.xyz, pulse);"
                                end
                            $1>
                            <$1
                                if %(bt_i)s then
                                    return [==[
                                        glow *= <$2 return %(bt_G)s and "pulsecol" or "glowcolor.xyz" $2>;
                                        float k = max(glow.r, max(glow.g, glow.b));
                                        k = min(k*k*32.0, 1.0);
                                        <$2
                                            if %(bt_s)s then
                                                return "gl_FragColor.rgb = glow*k + diffuse.rgb;"
                                            else
                                                return [===[
                                                    gl_FragColor.rgb = glow*k;
                                                    #pragma CUBE2_variantoverride gl_FragColor.a = texture2D(lmcolor, lmtc).a; //
                                                    gl_FragColor.a = colorparams.a;
                                                ]===]
                                            end
                                        $2>
                                    ]==]
                                else
                                    return [==[
                                        gl_FragColor.rgb = glow * <$2 return %(bt_G)s and "pulsecol" or "glowcolor.xyz" $2> + diffuse.rgb;
                                    ]==]
                                end
                            $1>
                        ]=]
                    end
                $0>
                <$0
                    if not %(bt_i)s then
                        return "#pragma CUBE2_water"
                    end
                $0>
            }
        ]] % bts)
    )
end

function bumpshader(...)
    local arg = { ... }
    cc.shader.defer(
        btopt(arg[2], "e") and 7 or 5,
        arg[1],
        [[
            bumpvariantshader(%(arg1)q, %(arg2)q)
            if %(bt_g)s or %(bt_s)s then
                bumpvariantshader(%(arg1)q, string.gsub(%(arg2)q .. "i", "r", ""))
            end
        ]] % {
            arg1 = arg[1],
            arg2 = arg[2],
            bt_g = tostring(btopt(arg[2], "g")),
            bt_s = tostring(btopt(arg[2], "s"))
        }
    )
end

bumpshader("bumpworld", "")
bumpshader("bumpspecworld", "ots")
cc.shader.fast("bumpspecworld", "bumpworld", 2)
cc.shader.alt("bumpspecworld", "bumpworld")
bumpshader("bumpspecmapworld", "otsS")
cc.shader.fast("bumpspecmapworld", "bumpworld", 2)
cc.shader.alt("bumpspecmapworld", "bumpworld")

bumpshader("bumpglowworld", "g")
bumpshader("bumpspecglowworld", "otsg")
cc.shader.alt("bumpspecglowworld", "bumpglowworld")
bumpshader("bumpspecmapglowworld", "otsSg")
cc.shader.fast("bumpspecmapglowworld", "bumpglowworld", 2)
cc.shader.alt("bumpspecmapglowworld", "bumpglowworld")

bumpshader("bumppulseglowworld", "gG")
bumpshader("bumpspecpulseglowworld", "otsgG")
cc.shader.alt("bumpspecpulseglowworld", "bumppulseglowworld")
bumpshader("bumpspecmappulseglowworld", "otsSgG")
cc.shader.fast("bumpspecmappulseglowworld", "bumppulseglowworld", 2)
cc.shader.alt("bumpspecmappulseglowworld", "bumppulseglowworld")

bumpshader("bumpparallaxworld", "pot")
cc.shader.fast("bumpparallaxworld", "bumpworld", 1)
cc.shader.alt("bumpparallaxworld", "bumpworld")
bumpshader("bumpspecparallaxworld", "pots")
cc.shader.fast("bumpspecparallaxworld", "bumpparallaxworld", 2)
cc.shader.fast("bumpspecparallaxworld", "bumpworld", 1)
cc.shader.alt("bumpspecparallaxworld", "bumpworld")
bumpshader("bumpspecmapparallaxworld", "potsS")
cc.shader.fast("bumpspecmapparallaxworld", "bumpparallaxworld", 2)
cc.shader.fast("bumpspecmapparallaxworld", "bumpworld", 1)
cc.shader.alt("bumpspecmapparallaxworld", "bumpworld")

bumpshader("bumpparallaxglowworld", "potg")
cc.shader.fast("bumpparallaxglowworld", "bumpglowworld", 1)
cc.shader.alt("bumpparallaxglowworld", "bumpglowworld")
bumpshader("bumpspecparallaxglowworld", "potsg")
cc.shader.fast("bumpspecparallaxglowworld", "bumpparallaxglowworld", 2)
cc.shader.fast("bumpspecparallaxglowworld", "bumpglowworld", 1)
cc.shader.alt("bumpspecparallaxglowworld", "bumpglowworld")
bumpshader("bumpspecmapparallaxglowworld", "potsSg")
cc.shader.fast("bumpspecmapparallaxglowworld", "bumpparallaxglowworld", 2)
cc.shader.fast("bumpspecmapparallaxglowworld", "bumpglowworld", 1)
cc.shader.alt("bumpspecmapparallaxglowworld", "bumpglowworld")

bumpshader("bumpparallaxpulseglowworld", "potgG")
cc.shader.fast("bumpparallaxpulseglowworld", "bumppulseglowworld", 1)
cc.shader.alt("bumpparallaxpulseglowworld", "bumppulseglowworld")
bumpshader("bumpspecparallaxpulseglowworld", "potsgG")
cc.shader.fast("bumpspecparallaxpulseglowworld", "bumpparallaxpulseglowworld", 2)
cc.shader.fast("bumpspecparallaxpulseglowworld", "bumppulseglowworld", 1)
cc.shader.alt("bumpspecparallaxpulseglowworld", "bumppulseglowworld")
bumpshader("bumpspecmapparallaxpulseglowworld", "potsSgG")
cc.shader.fast("bumpspecmapparallaxpulseglowworld", "bumpparallaxpulseglowworld", 2)
cc.shader.fast("bumpspecmapparallaxpulseglowworld", "bumppulseglowworld", 1)
cc.shader.alt("bumpspecmapparallaxpulseglowworld", "bumppulseglowworld")

bumpshader("bumpenvworldalt", "e")
bumpshader("bumpenvworld", "eor")
cc.shader.alt("bumpenvworld", "bumpenvworldalt")
cc.shader.fast("bumpenvworld", "bumpenvworldalt", 2)
bumpshader("bumpenvspecworld", "eotsr")
cc.shader.alt("bumpenvspecworld", "bumpenvworldalt")
cc.shader.fast("bumpenvspecworld", "bumpenvworldalt", 2)
bumpshader("bumpenvspecmapworld", "eotsSrR")
cc.shader.alt("bumpenvspecmapworld", "bumpenvworldalt")
cc.shader.fast("bumpenvspecmapworld", "bumpenvworldalt", 2)

bumpshader("bumpenvglowworldalt", "eg")
bumpshader("bumpenvglowworld", "eorg")
cc.shader.alt("bumpenvglowworld", "bumpenvglowworldalt")
cc.shader.fast("bumpenvglowworld", "bumpenvglowworldalt", 2)
bumpshader("bumpenvspecglowworld", "eotsrg")
cc.shader.alt("bumpenvspecglowworld", "bumpenvglowworldalt")
cc.shader.fast("bumpenvspecglowworld", "bumpenvglowworldalt", 2)
bumpshader("bumpenvspecmapglowworld", "eotsSrRg")
cc.shader.alt("bumpenvspecmapglowworld", "bumpenvglowworldalt")
cc.shader.fast("bumpenvspecmapglowworld", "bumpenvglowworldalt", 2)

bumpshader("bumpenvpulseglowworldalt", "egG")
bumpshader("bumpenvpulseglowworld", "eorgG")
cc.shader.alt("bumpenvpulseglowworld", "bumpenvpulseglowworldalt")
cc.shader.fast("bumpenvpulseglowworld", "bumpenvpulseglowworldalt", 2)
bumpshader("bumpenvspecpulseglowworld", "eotsrgG")
cc.shader.alt("bumpenvspecpulseglowworld", "bumpenvpulseglowworldalt")
cc.shader.fast("bumpenvspecpulseglowworld", "bumpenvpulseglowworldalt", 2)
bumpshader("bumpenvspecmappulseglowworld", "eotsSrRgG")
cc.shader.alt("bumpenvspecmappulseglowworld", "bumpenvpulseglowworldalt")
cc.shader.fast("bumpenvspecmappulseglowworld", "bumpenvpulseglowworldalt", 2)

bumpshader("bumpenvparallaxworldalt", "epot")
cc.shader.alt("bumpenvparallaxworldalt", "bumpenvworldalt")
bumpshader("bumpenvparallaxworld", "epotr")
cc.shader.alt("bumpenvparallaxworld", "bumpenvparallaxworldalt")
cc.shader.fast("bumpenvparallaxworld", "bumpenvparallaxworldalt", 2)
cc.shader.fast("bumpenvparallaxworld", "bumpenvworldalt", 1)
bumpshader("bumpenvspecparallaxworld", "epotsr")
cc.shader.alt("bumpenvspecparallaxworld", "bumpenvparallaxworldalt")
cc.shader.fast("bumpenvspecparallaxworld", "bumpenvparallaxworldalt", 2)
cc.shader.fast("bumpenvspecparallaxworld", "bumpenvworldalt", 1)
bumpshader("bumpenvspecmapparallaxworld", "epotsSrR")
cc.shader.alt("bumpenvspecmapparallaxworld", "bumpenvparallaxworldalt")
cc.shader.fast("bumpenvspecmapparallaxworld", "bumpenvparallaxworldalt", 2)
cc.shader.fast("bumpenvspecmapparallaxworld", "bumpenvworldalt", 1)

bumpshader("bumpenvparallaxglowworldalt", "epotg")
cc.shader.alt("bumpenvparallaxglowworldalt", "bumpenvglowworldalt")
bumpshader("bumpenvparallaxglowworld", "epotrg")
cc.shader.alt("bumpenvparallaxglowworld", "bumpenvparallaxglowworldalt")
cc.shader.fast("bumpenvparallaxglowworld", "bumpenvparallaxglowworldalt", 2)
cc.shader.fast("bumpenvparallaxglowworld", "bumpenvglowworldalt", 1)
bumpshader("bumpenvspecparallaxglowworld", "epotsrg")
cc.shader.alt("bumpenvspecparallaxglowworld", "bumpenvparallaxglowworldalt")
cc.shader.fast("bumpenvspecparallaxglowworld", "bumpenvparallaxglowworldalt", 2)
cc.shader.fast("bumpenvspecparallaxglowworld", "bumpenvglowworldalt", 1)
bumpshader("bumpenvspecmapparallaxglowworld", "epotsSrRg")
cc.shader.alt("bumpenvspecmapparallaxglowworld", "bumpenvparallaxglowworldalt")
cc.shader.fast("bumpenvspecmapparallaxglowworld", "bumpenvparallaxglowworldalt", 2)
cc.shader.fast("bumpenvspecmapparallaxglowworld", "bumpenvglowworldalt", 1)

bumpshader("bumpenvparallaxpulseglowworldalt", "epotgG")
cc.shader.alt("bumpenvparallaxpulseglowworldalt", "bumpenvpulseglowworldalt")
bumpshader("bumpenvparallaxpulseglowworld", "epotrgG")
cc.shader.alt("bumpenvparallaxpulseglowworld", "bumpenvparallaxpulseglowpulseglowworldalt")
cc.shader.fast("bumpenvparallaxpulseglowworld", "bumpenvparallaxpulseglowpulseglowworldalt", 2)
cc.shader.fast("bumpenvparallaxpulseglowworld", "bumpenvpulseglowworldalt", 1)
bumpshader("bumpenvspecparallaxpulseglowworld", "epotsrgG")
cc.shader.alt("bumpenvspecparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt")
cc.shader.fast("bumpenvspecparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt", 2)
cc.shader.fast("bumpenvspecparallaxpulseglowworld", "bumpenvpulseglowworldalt", 1)
bumpshader("bumpenvspecmapparallaxpulseglowworld", "epotsSrRgG")
cc.shader.alt("bumpenvspecmapparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt")
cc.shader.fast("bumpenvspecmapparallaxpulseglowworld", "bumpenvparallaxpulseglowworldalt", 2)
cc.shader.fast("bumpenvspecmapparallaxpulseglowworld", "bumpenvpulseglowworldalt", 1)

--bumpshader("steepworld", "Pot")

-- Reflective / refractive water shaders

function watershader(...)
    local arg = { ... }
    lazyshader(
        4, arg[1],
        [[
            uniform vec4 camera, millis, waterheight;
            %(spec_a)s
            varying vec3 camdir;
            void main(void)
            {
                gl_Position = ftransform();
                gl_FrontColor = gl_Color;
                gl_TexCoord[0] = gl_TextureMatrix[0] * gl_Vertex;
                %(uwater)s
                vec2 tc = gl_MultiTexCoord0.xy * 0.1;
                gl_TexCoord[1].xy = tc + millis.x*0.04;
                gl_TexCoord[2].xy = tc - millis.x*0.02;
                camdir = camera.xyz - gl_Vertex.xyz;
                %(spec_b)s
        }
        ]] % {
            spec_a = (arg[2] and arg[2] ~= 0) and "uniform vec4 lightpos; varying vec3 lightdir;" or "",
            spec_b = (arg[2] and arg[2] ~= 0) and "lightdir = lightpos.xyz - gl_Vertex.xyz;" or "",
            uwater = (
                string.find(arg[1], "underwater")
                and
                    "gl_TexCoord[0].z = waterheight.x - gl_Vertex.z;"
                or
                    "gl_TexCoord[0].z = gl_Vertex.z - waterheight.x;"
            ),
            spec = arg[2] or 0,
        },
        [[
            %(rgbfog)s
            uniform vec4 depth;
            %(spec_a)s
            varying vec3 camdir;
            %(env)s
            uniform sampler2D tex1, tex2, tex3;
            void main(void)
            {
                vec3 camvec = normalize(camdir);
                %(spec_b)s
                vec2 dudv = texture2D(tex2, gl_TexCoord[1].xy).xy*2.0 - 1.0;
                %(distort)s
                %(spec_c)s
                %(combine)s
            }
        ]] % {
            spec = arg[2] or 0,
            spec_a = (
                arg[2] and arg[2] ~= 0
                and
                    "uniform vec4 lightcolor, lightradius; varying vec3 lightdir;"
                or ""
            ),
            spec_b = (
                arg[2] and arg[2] ~= 0
                and
                    [=[
                        vec3 lightvec = normalize(lightdir);
                        vec3 halfangle = normalize(camvec + lightvec);
                    ]=]
                or ""
            ),
            spec_c = (
                arg[2] and arg[2] ~= 0
                and
                    [=[
                        float spec = pow(clamp(dot(halfangle, bump), 0.0, 1.0), 96.0);
                        vec3 light = lightcolor.xyz * (1.0 - clamp(length(lightdir)/lightradius.x, 0.0, 1.0));
                    ]=]
                or ""
            ),
            rgbfog = (
                arg[3] and arg[3] ~= 0
                and
                    "#pragma CUBE2_fog"
                or
                    "#pragma CUBE2_fogrgba vec4(0.0, 0.0, 0.0, 1.0)"
            ),
            env = (
                string.find(arg[1], "env")
                and
                    "uniform samplerCube tex0;"
                or
                    "uniform sampler2D tex0;"
            ),
            distort = arg[4] or '',
            combine = arg[5] or ''
        }
    )
end

watershader(
    "waterglare", 1, 1,
    "vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;",
    "gl_FragColor = vec4(light*spec*spec*32.0, 0.0);"
)
lazyshader(
    4, "waterglarefast",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
        }
    ]],
    [[
        void main(void)
        {
            gl_FragColor = vec4(0.0);
        }
    ]]
)
cc.shader.fast("waterglare", "waterglarefast", 2)
cc.shader.alt("waterglare", "waterglarefast")

lazyshader(
    4, "underwater",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
        }
    ]],
    [[
        #pragma CUBE2_fogrgba vec4(0.0, 0.0, 0.0, 1.0)
        uniform vec4 depth;
        void main(void)
        {    
            gl_FragColor.rgb = 0.8*depth.x*gl_Color.rgb;
            gl_FragColor.a = 0.5*depth.y; 
        }
    ]]
)

watershader(
    "underwaterrefract", 0, 1,
    [[
        dudv = texture2D(tex2, gl_TexCoord[2].xy + 0.025*dudv).xy*2.0 - 1.0;
        gl_FragColor = texture2D(tex3, gl_TexCoord[0].xy/gl_TexCoord[0].w + 0.01*dudv);
    ]], ""
)
watershader(
    "underwaterrefractfast", 0, 1,
    "gl_FragColor = texture2DProj(tex3, gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0));", ""
)
cc.shader.fast("underwaterrefract", "underwaterrefractfast", 2)
cc.shader.alt("underwaterrefract", "underwaterrefractfast")

watershader(
    "underwaterfade", 0, 1,
    [[
        dudv = texture2D(tex2, gl_TexCoord[2].xy + 0.025*dudv).xy*2.0 - 1.0;
        vec2 projtc = gl_TexCoord[0].xy/gl_TexCoord[0].w;
        float fade = gl_TexCoord[0].z + 4.0*texture2D(tex3, projtc).a;
        gl_FragColor.a = fade * clamp(gl_FragCoord.z, 0.0, 1.0);
        gl_FragColor.rgb = texture2D(tex3, projtc + 0.01*dudv).rgb; 
    ]], ""
)
watershader(
    "underwaterfadefast", 0, 1,
    [[
        gl_FragColor.rgb = texture2DProj(tex3, gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0)).rgb;
        gl_FragColor.a = gl_TexCoord[0].z + 4.0*texture2DProj(tex3, gl_TexCoord[0]).a;
    ]], ""
)
cc.shader.fast("underwaterfade", "underwaterfadefast", 2)
cc.shader.alt("underwaterfade", "underwaterfadefast")

watershader(
    "water", 1, 0,
    "vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;",
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = gl_Color.rgb*depth.x*mix(0.6, 1.0, invfresnel) + spec*light;
        gl_FragColor.a = invfresnel*depth.y;
    ]]
)
watershader(
    "waterfast", 0, 0,
    "vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;",
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = gl_Color.rgb*depth.x*mix(0.6, 1.0, invfresnel);
        gl_FragColor.a = invfresnel*depth.y;
    ]]
)
cc.shader.fast("water", "waterfast", 1)
cc.shader.alt("water", "waterfast")

watershader(
    "waterreflect", 1, 0,
    [[
        vec3 reflect = texture2DProj(tex0, gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0)).rgb;
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
    ]],
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, gl_Color.rgb*depth.x, invfresnel) + spec*light;
        gl_FragColor.a = invfresnel*depth.y;
    ]]
)
watershader(
    "waterreflectfast", 1, 0,
    [[
        vec3 reflect = texture2DProj(tex0, gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0)).rgb;
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
    ]],
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, gl_Color.rgb*depth.x, invfresnel) + spec*light;
        gl_FragColor.a = invfresnel*depth.y;
    ]]
)
cc.shader.fast("waterreflect", "waterreflectfast", 2)
cc.shader.alt("waterreflect", "waterreflectfast")

watershader(
    "waterrefract", 1, 1,
    [[
        vec2 dtc = gl_TexCoord[2].xy + 0.025*dudv;
        vec3 bump = texture2D(tex1, dtc).rgb*2.0 - 1.0;
        dudv = texture2D(tex2, dtc).xy*2.0 - 1.0;

        vec2 rtc = gl_TexCoord[0].xy/gl_TexCoord[0].w + 0.01*dudv;
        vec3 reflect = texture2D(tex0, rtc).rgb;
        vec3 refract = texture2D(tex3, rtc).rgb;
    ]],
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor = vec4(mix(reflect, refract, invfresnel) + spec*light, 0.0);
    ]]
)
watershader(
    "waterrefractfast", 0, 1,
    [[
        vec4 rtc = gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0);
        vec3 reflect = texture2DProj(tex0, rtc).rgb;
        vec3 refract = texture2DProj(tex3, rtc).rgb;
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
    ]],
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor = vec4(mix(reflect, refract, invfresnel), 0.0);
    ]]
)
cc.shader.fast("waterrefract", "waterrefractfast", 2)
cc.shader.alt("waterrefract", "waterrefractfast")

watershader(
    "waterfade", 1, 1,
    [[
        vec2 dtc = gl_TexCoord[2].xy + 0.025*dudv;
        vec3 bump = texture2D(tex1, dtc).rgb*2.0 - 1.0;
        dudv = texture2D(tex2, dtc).xy*2.0 - 1.0;

        vec2 projtc = gl_TexCoord[0].xy/gl_TexCoord[0].w;
        vec2 rtc = projtc + 0.01*dudv;
        vec3 reflect = texture2D(tex0, rtc).rgb;
        vec3 refract = texture2D(tex3, rtc).rgb;
        float fade = gl_TexCoord[0].z + 4.0*texture2D(tex3, projtc).a;
        gl_FragColor.a = fade * clamp(gl_FragCoord.z, 0.0, 1.0);
    ]],
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, refract, invfresnel) + spec*light;
    ]]
)
watershader(
    "waterfadefast", 0, 1,
    [[
        vec4 rtc = gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0);
        vec3 reflect = texture2DProj(tex0, rtc).rgb;
        vec3 refract = texture2DProj(tex3, rtc).rgb;
        gl_FragColor.a = gl_TexCoord[0].z + 4.0*texture2DProj(tex3, gl_TexCoord[0]).a;
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
    ]],
    [[
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0);
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, refract, invfresnel);
    ]]
)
cc.shader.fast("waterfade", "watefadefast", 2)
cc.shader.alt("waterfade", "waterrefract")

watershader(
    "waterenv", 1, 0,
    [[
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0); 
        vec3 reflect = textureCube(tex0, camvec - 2.0*invfresnel*bump).rgb;
    ]],
    [[
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, gl_Color.rgb*depth.x, invfresnel) + spec*light;
        gl_FragColor.a = invfresnel*depth.y; 
    ]]
)
watershader(
    "waterenvfast", 0, 0,
    [[
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0); 
        vec3 reflect = textureCube(tex0, camvec - 2.0*invfresnel*bump).rgb;
    ]],
    [[
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, gl_Color.rgb*depth.x, invfresnel);
        gl_FragColor.a = invfresnel*depth.y; 
    ]]
)
cc.shader.fast("waterenv", "wateenvfast", 2)
cc.shader.alt("waterenv", "wateenvfast")

watershader(
    "waterenvrefract", 1, 1,
    [[
        vec2 dtc = gl_TexCoord[2].xy + 0.025*dudv;
        vec3 bump = texture2D(tex1, dtc).rgb*2.0 - 1.0;
        dudv = texture2D(tex2, dtc).xy*2.0 - 1.0;

        vec3 refract = texture2D(tex3, gl_TexCoord[0].xy/gl_TexCoord[0].w + 0.01*dudv).rgb;
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0); 
        vec3 reflect = textureCube(tex0, camvec - 2.0*invfresnel*bump).rgb;
    ]],
    [[
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor = vec4(mix(reflect, refract, invfresnel) + spec*light, 0.0);
    ]]
)
watershader(
    "waterenvrefractfast", 0, 1,
    [[
        vec3 refract = texture2DProj(tex3, gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0)).rgb;
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0); 
        vec3 reflect = textureCube(tex0, camvec - 2.0*invfresnel*bump).rgb;
    ]],
    [[
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor = vec4(mix(reflect, refract, invfresnel), 0.0);
    ]]
)
cc.shader.fast("waterenvrefract", "waterenvrefractfast", 2)
cc.shader.alt("waterenvrefract", "waterenvrefractfast")

watershader(
    "waterenvfade", 1, 1,
    [[
        vec2 dtc = gl_TexCoord[2].xy + 0.025*dudv;
        vec3 bump = texture2D(tex1, dtc).rgb*2.0 - 1.0;
        dudv = texture2D(tex2, dtc).xy*2.0 - 1.0;

        vec2 projtc = gl_TexCoord[0].xy/gl_TexCoord[0].w;
        vec3 refract = texture2D(tex3, projtc + 0.01*dudv).rgb;
        float fade = gl_TexCoord[0].z + 4.0*texture2D(tex3, projtc).a;
        gl_FragColor.a = fade * clamp(gl_FragCoord.z, 0.0, 1.0);

        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0); 
        vec3 reflect = textureCube(tex0, camvec - 2.0*invfresnel*bump).rgb;
    ]],
    [[
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, refract, invfresnel) + spec*light;
    ]]
)
watershader(
    "waterenvfadefast", 0, 1,
    [[
        vec3 refract = texture2DProj(tex3, gl_TexCoord[0] + vec4(0.4*dudv, 0.0, 0.0)).rgb;
        gl_FragColor.a = gl_TexCoord[0].z + 4.0*texture2DProj(tex3, gl_TexCoord[0]).a;
        vec3 bump = texture2D(tex1, gl_TexCoord[2].xy + 0.025*dudv).rgb*2.0 - 1.0;
        float invfresnel = clamp(dot(camvec, bump), 0.0, 1.0); 
        vec3 reflect = textureCube(tex0, camvec - 2.0*invfresnel*bump).rgb;
    ]],
    [[
        invfresnel = invfresnel*0.5 + 0.5;
        gl_FragColor.rgb = mix(reflect, refract, invfresnel);
    ]]
)
cc.shader.fast("waterenvfade", "waterenvfadefast", 2)
cc.shader.alt("waterenvfade", "waterenvrefract")

function causticshader(...)
    local arg = { ... }
    lazyshader(
        4, arg[1],
        [[
            #pragma CUBE2_fog
            uniform vec4 texgenS, texgenT;
            void main(void)
            {
                gl_Position = ftransform();
                gl_TexCoord[0].xy = vec2(dot(texgenS.xyz, gl_Vertex.xyz), dot(texgenT.xyz, gl_Vertex.xyz)); 
            }
        ]],
        [[
            uniform vec4 frameoffset;
            uniform sampler2D tex0, tex1;
            void main(void)
            {
                %(arg2)s
            }
        ]] % { arg2 = arg[2] }
    )
end

causticshader(
    "caustic",
    "gl_FragColor = frameoffset.x*texture2D(tex0, gl_TexCoord[0].xy) + frameoffset.y*texture2D(tex1, gl_TexCoord[0].xy);"
)
causticshader(
    "causticfast",
    "gl_FragColor = frameoffset.z*texture2D(tex0, gl_TexCoord[0].xy);"
)
cc.shader.fast("caustic", "causticfast", 2)

lazyshader(
    4, "lava",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            gl_FragColor = gl_Color * texture2D(tex0, gl_TexCoord[0].xy) * 2.0; 
        }
    ]]
)

lazyshader(
    4, "lavaglare",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color*2.0 - 1.0;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            vec4 glow = texture2D(tex0, gl_TexCoord[0].xy) * gl_Color;
            float k = max(glow.r, max(glow.g, glow.b));
            gl_FragColor = glow*k*k*32.0;
        }
    ]]
)

lazyshader(
    4, "waterfallrefract",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            gl_TexCoord[1] = gl_TextureMatrix[0] * gl_Vertex; 
        }
    ]],
    [[
        uniform vec4 dudvoffset;
        uniform sampler2D tex0, tex2, tex4;
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
            vec2 dudv = texture2D(tex2, gl_TexCoord[0].xy + 0.2*diffuse.xy + dudvoffset.xy).xy; 
            vec4 refract = texture2DProj(tex4, gl_TexCoord[1] + vec4(4.0*dudv, 0.0, 0.0));
            gl_FragColor = mix(refract, gl_Color, diffuse);
        }
    ]]
)

lazyshader(
    4, "waterfallenvrefract",
    [[
        #pragma CUBE2_fog
        uniform vec4 camera;
        varying vec3 camdir;
        varying mat3 world; 
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            gl_TexCoord[1] = gl_TextureMatrix[0] * gl_Vertex;
            camdir = camera.xyz - gl_Vertex.xyz;
            vec3 absnorm = abs(gl_Normal);
            world = mat3(absnorm.yzx, -absnorm.zxy, gl_Normal);
        }
    ]],
    [[
        uniform vec4 dudvoffset;
        uniform sampler2D tex0, tex1, tex2, tex4;
        uniform samplerCube tex3;
        varying vec3 camdir;
        varying mat3 world; 
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
            vec2 dudv = texture2D(tex2, gl_TexCoord[0].xy + 0.2*diffuse.xy + dudvoffset.xy).xy; 
            vec3 normal = world * (texture2D(tex1, gl_TexCoord[0].xy + 0.1*dudv).rgb*2.0 - 1.0);
            vec4 refract = texture2DProj(tex4, gl_TexCoord[1] + vec4(4.0*dudv, 0.0, 0.0));
            vec3 camvec = normalize(camdir);
            float invfresnel = dot(normal, camvec);
            vec4 reflect = textureCube(tex3, 2.0*invfresnel*normal - camvec);
            gl_FragColor = mix(mix(reflect, refract, 1.0 - 0.4*step(0.0, invfresnel)), gl_Color, diffuse); 
        }
    ]]
)
cc.shader.alt("waterfallenvrefract", "waterfallrefract")

lazyshader(
    4, "waterfallenv",
    [[
        #pragma CUBE2_fog
        uniform vec4 camera;
        varying vec3 camdir;
        varying mat3 world; 
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            camdir = camera.xyz - gl_Vertex.xyz;
            vec3 absnorm = abs(gl_Normal);
            world = mat3(absnorm.yzx, -absnorm.zxy, gl_Normal);
        }
    ]],
    [[
        uniform vec4 dudvoffset;
        uniform sampler2D tex0, tex1, tex2;
        uniform samplerCube tex3;
        varying vec3 camdir;
        varying mat3 world; 
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
            vec2 dudv = texture2D(tex2, gl_TexCoord[0].xy + 0.2*diffuse.xy + dudvoffset.xy).xy; 
            vec3 normal = world * (texture2D(tex1, gl_TexCoord[0].xy + 0.1*dudv).rgb*2.0 - 1.0);
            vec3 camvec = normalize(camdir);
            vec4 reflect = textureCube(tex3, 2.0*dot(normal, camvec)*normal - camvec);
            gl_FragColor.rgb = mix(reflect.rgb, gl_Color.rgb, diffuse.rgb);
            gl_FragColor.a = 0.25 + 0.75*diffuse.r;    
        }
    ]]
)

lazyshader(
    4, "glass",
    [[
        uniform vec4 camera;
        varying vec3 rvec, camdir, normal;
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            rvec = gl_MultiTexCoord0.xyz;
            camdir = camera.xyz - gl_Vertex.xyz;
            normal = gl_Normal;
        }
    ]],
    [[
        #pragma CUBE2_fogrgba vec4(0.0, 0.0, 0.0, 1.0)
        uniform samplerCube tex0;
        varying vec3 rvec, camdir, normal;
        void main(void)
        {
            vec3 camvec = normalize(camdir);
            vec3 reflect = textureCube(tex0, rvec).rgb;
   
            float invfresnel = max(dot(camvec, normal), 0.70); 
            gl_FragColor.rgb = mix(reflect, gl_Color.rgb*0.05, invfresnel);
            gl_FragColor.a = invfresnel * 0.95;
        }
    ]]
)
lazyshader(
    4, "glassfast",
    [[
        varying vec3 rvec;
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            rvec = gl_MultiTexCoord0.xyz;
        }
    ]],
    [[
        #pragma CUBE2_fogrgba vec4(0.0, 0.0, 0.0, 1.0)
        uniform samplerCube tex0;
        varying vec3 rvec;
        void main(void)
        {
            vec3 reflect = textureCube(tex0, rvec).rgb;
            const float invfresnel = 0.75;
            gl_FragColor.rgb = mix(reflect, gl_Color.rgb*0.05, invfresnel);
            gl_FragColor.a = invfresnel * 0.95; 
        }
    ]]
)
cc.shader.fast("glass", "glassfast", 2)
cc.shader.alt("glass", "glassfast")

lazyshader(
    4, "grass",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            gl_TexCoord[1].xy = gl_MultiTexCoord1.xy;
        }
    ]],
    [[
        #pragma CUBE2_fogrgba vec4(0.0, 0.0, 0.0, 0.0)
        uniform sampler2D tex0, tex1;
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
            diffuse.rgb *= 2.0;
            vec4 lm = texture2D(tex1, gl_TexCoord[1].xy) * gl_Color;
            lm.rgb *= lm.a;
            gl_FragColor = diffuse * lm;
        }
    ]]
)

cc.shader.std(
    4, "overbrightdecal",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
            gl_FragColor = mix(gl_Color, diffuse, gl_Color.a);
        }
    ]]
)

cc.shader.std(
    4, "saturatedecal",
    [[
        #pragma CUBE2_fog
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
            diffuse.rgb *= 2.0;
            gl_FragColor = diffuse * gl_Color;
        }
    ]]
)

cc.shader.std(
    4, "skyboxglare",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            vec4 glare = texture2D(tex0, gl_TexCoord[0].xy) * gl_Color;
            gl_FragColor.rgb = vec3(dot(glare.rgb, vec3(10.56, 10.88, 10.56)) - 30.4);
            gl_FragColor.a = glare.a;
        }
    ]]
)

-- separable blur with up to 7 taps

function blurshader(...)
    local arg = { ... }
    cc.shader.std(
        4, arg[1],
        string.template([[
            uniform vec4 offsets;
            void main(void)
            {
                gl_Position = gl_Vertex;
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
                vec2 tc1 = gl_MultiTexCoord0.xy + offsets.xy;
                vec2 tc2 = gl_MultiTexCoord0.xy - offsets.xy;
                gl_TexCoord[1].xy = tc1;
                gl_TexCoord[2].xy = tc2;
                <$0
                    local sum = ""
                    for i = 1, math.min(%(arg2)i - 1, 2) do
                        sum = sum .. [=[
                            tc1.%(arg3)s += offsets.%(zw)s;
                            tc2.%(arg3)s -= offsets.%(zw)s;
                            gl_TexCoord[%(1)i].xy = tc1;
                            gl_TexCoord[%(2)i].xy = tc2;
                        ]=] % {
                            zw = (i == 1 and "z" or "w"),
                            ((i - 1) * 2) + 3,
                            ((i - 1) * 2) + 4,
                        }
                    end
                    return sum
                $0>
            }
        ]] % { arg2 = arg[2], arg3 = arg[3] }),
        string.template([[
            %(header)s
            uniform vec4 weights, weights2, offset4, offset5, offset6, offset7;
            uniform %(smplr)s tex0;
            void main(void)
            {
                #define texval(coords) %(txtr)s(tex0, (coords))
                vec4 val = texval(gl_TexCoord[0].xy) * weights.x;
                <$0
                    local sum = ""
                    for i = 1, %(arg2)i do
                        sum = sum .. (i <= 3
                            and
                                [==[
                                    val += weights.%(yzw)s * (texval(gl_TexCoord[%(1)i].xy) + texval(gl_TexCoord[%(2)i].xy));
                                ]==] % {
                                    yzw = ({ "y", "z", "w" })[i],
                                    ((i - 1) * 2) + 1,
                                    ((i - 1) * 2) + 2
                                }
                            or
                                [==[
                                    val += weights2.%(xyzw)s * (texval(gl_TexCoord[0].xy + %(offset)s.xy) + texval(gl_TexCoord[0].xy - %(offset)s.xy));
                                ]==] % {
                                    xyzw = ({ "x", "y", "z", "w" })[i - 3],
                                    offset = ({ "offset4", "offset5", "offset6", "offset7" })[i - 3]
                                }
                        )
                    end
                    return sum
                $0>
                gl_FragColor = val;
            }
        ]] % {
            arg2 = arg[2],
            header = (arg[4] == "2DRect") and "#extension GL_ARB_texture_rectangle : enable" or "",
            smplr = "sampler" .. arg[4],
            txtr = "texture" .. arg[4]
        })
    )
end

for i = 1, 7 do
    blurshader("blurx" .. i, i, "x", "2D")
    blurshader("blury" .. i, i, "y", "2D")
    if i > 1 then
        cc.shader.alt("blurx" .. i, "blurx" .. i - 1)
        cc.shader.alt("blury" .. i, "blury" .. i - 1)
    end
    if usetexrect ~= 0 then
        blurshader("blurx" .. i .. "rect", i, "x", "2DRect")
        blurshader("blury" .. i .. "rect", i, "y", "2DRect")
        if i > 1 then
            cc.shader.alt("blurx" .. i .. "rect", "blurx" .. i - 1 .. "rect")
            cc.shader.alt("blury" .. i .. "rect", "blury" .. i - 1 .. "rect")
        end
    end
end

-- full screen shaders

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

lazyshader(4, "invert", " %(1)s } " % { fsvs }, " %(1)s gl_FragColor = 1.0 - sample; } " % { fsps })
lazyshader(4, "gbr", " %(1)s } " % { fsvs }, " %(1)s gl_FragColor = sample.yzxw; } " % { fsps })
lazyshader(4, "bw", " %(1)s } " % { fsvs }, " %(1)s gl_FragColor = vec4(dot(sample.xyz, vec3(0.333))); } " % { fsps })

-- sobel

lazyshader(
    4, "sobel",
    " %(1)s %(2)s } " % { fsvs, setup4corners },
    [[
        %(1)s
        %(2)s
            vec4 t = s00 + s20 - s02 - s22;
            vec4 u = s00 + s02 - s20 - s22;
            gl_FragColor = sample + t*t + u*u;
        }
    ]] % { fsps, sample4corners }
)

-- rotoscope

lazyshader(
    4, "rotoscope",
    [[
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
    ]],
    [[
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
    ]]
)

function blur3shader(...)
    local arg = { ... }
    lazyshader(
        4, arg[1],
        [[
            void main(void)
            {
                gl_Position = gl_Vertex;
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(%(1)s, %(2)s);
                gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(%(3)s, %(4)s);
            }
        ]] % {
            arg[2] == 1 and -0.5 or 0.0,
            arg[3] == 1 and -0.5 or 0.0,
            arg[2] == 1 and 0.5 or 0.0,
            arg[3] == 1 and 0.5 or 0.0
        },
        [[
            #extension GL_ARB_texture_rectangle : enable
            uniform sampler2DRect tex0; 
            void main(void)
            {
                gl_FragColor = 0.5*(texture2DRect(tex0, gl_TexCoord[0].xy) + texture2DRect(tex0, gl_TexCoord[1].xy));
            }
        ]]
    )
end
blur3shader("hblur3", 1, 0)
blur3shader("vblur3", 0, 1)

function blur5shader(...)
    local arg = { ... }
    lazyshader(
        4, arg[1],
        [[
            %(5)s
                gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(%(1)s, %(2)s);
                gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2(%(3)s, %(4)s);
            }
        ]] % {
            arg[2] == 1 and -1.333 or 0.0,
            arg[3] == 1 and -1.333 or 0.0,
            arg[2] == 1 and 1.333 or 0.0,
            arg[3] == 1 and 1.333 or 0.0,
            fsvs
        },
        [[
            #extension GL_ARB_texture_rectangle : enable
            uniform sampler2DRect tex0; 
            void main(void)
            {
                gl_FragColor = 0.4*texture2DRect(tex0, gl_TexCoord[0].xy) + 0.3*(texture2DRect(tex0, gl_TexCoord[1].xy) + texture2DRect(tex0, gl_TexCoord[2].xy));
            }
        ]]
    )
end
blur5shader("hblur5", 1, 0)
blur5shader("vblur5", 0, 1)

function rotoscope(...)
    local arg = { ... }
    cc.shader.postfx.clear()
    if #arg >= 1 then
        cc.shader.postfx.add("rotoscope", 0, 0, 0, arg[1])
    end
    if #arg >= 2 then
        if arg[2] == 1 then
            cc.shader.postfx.add("hblur3")
            cc.shader.postfx.add("vblur3")
        elseif arg[2] == 2 then
            cc.shader.postfx.add("hblur5")
            cc.shader.postfx.add("vblur5")
        end
    end
end

-- bloom-ish

cc.shader.std(
    4, "glare",
    [[
        void main(void)
        {
            gl_Position = gl_Vertex;
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        uniform vec4 glarescale;
        uniform sampler2D tex0; 
        void main(void)
        {
            gl_FragColor = texture2D(tex0, gl_TexCoord[0].xy) * glarescale;
        }
    ]]
)

lazyshader(
    4, "bloom_scale",
    " %(1)s %(2)s } " % { fsvs, setup4corners },
    [[
        %(1)s
        %(2)s
            gl_FragColor = 0.2 * (s02 + s00 + s22 + s20 + sample);
        }
    ]] % { fsps, sample4corners }
)

lazyshader(
    4, "bloom_init",
    " %(1)s } " % { fsvs },
    [[
        %(1)s
            float t = max(sample.r, max(sample.g, sample.b));
            gl_FragColor = t*t*sample;
        }
    ]] % { fsps }
)

function bloomshader(sn, n)
    cc.shader.defer(
        4, sn,
        [[
            cc.shader.force("bloom_scale")
            cc.shader.force("bloom_init")
            cc.shader.std(
                4, %(arg1)q,
                string.template([=[
                    void main(void)
                    {
                        gl_Position = gl_Vertex;
                        gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
                        vec2 tc = gl_MultiTexCoord0.xy;
                        <$0
                            local sum = ""
                            for i = 1, %(arg2)i do
                                sum = sum .. [==[
                                    tc *= 0.5;
                                    gl_TexCoord[%(1)i].xy = tc;
                                ]==] % { i }
                            end
                            return sum
                        $0>
                    }
                ]=]),
                string.template([=[
                    #extension GL_ARB_texture_rectangle : enable
                    uniform vec4 params;
                    uniform sampler2DRect tex0<$0 local sum = ""; for i = 1, %(arg2)i do sum = sum .. " , tex" .. i end; return sum $0>;
                    void main(void)
                    {
                        vec4 sample = texture2DRect(tex0, gl_TexCoord[0].xy);
                        <$0
                            local sum = ""
                            for i = 1, %(arg2)i do
                                sum = sum .. [==[
                                    %(1)s texture2DRect(tex%(2)i, gl_TexCoord[%(2)i].xy);
                                ]==] % {
                                    i > 1 and "bloom +=" or "vec4 bloom =", i
                                }
                            end
                            return sum
                        $0>
                        gl_FragColor = bloom*params.x + sample;
                    }
                ]=])
            )
        ]] % {
            arg1 = sn,
            arg2 = n
        }
    )
end

bloomshader("bloom1", 1)
bloomshader("bloom2", 2)
bloomshader("bloom3", 3)
bloomshader("bloom4", 4)
bloomshader("bloom5", 5)
bloomshader("bloom6", 6)

function setupbloom(...)
    local arg = { ... }
    cc.shader.postfx.add("bloom_init", 1, 1, "+0")
    for i = 1, arg[1] - 1 do
        cc.shader.postfx.add("bloom_scale", i + 1, i + 1, "+" .. i)
    end
    local tbl = { 0 }
    for i = 1, arg[1] do table.insert(tbl, i) end
    cc.shader.postfx.add("bloom" .. arg[1], 0, 0, table.concat(tbl, " "), arg[2])
end

function bloom(a)
    cc.shader.postfx.clear()
    if a and a ~= 0 then setupbloom(6, a) end
end

-- misc effect shaders

cc.shader.std(
    4, "blendbrush",
    [[
        uniform vec4 texgenS, texgenT;
        void main(void)
        {
            gl_Position = ftransform();
            gl_FrontColor = gl_Color;
            gl_TexCoord[0].xy = vec2(dot(texgenS, gl_Vertex), dot(texgenT, gl_Vertex));
        }
    ]],
    [[
        uniform sampler2D tex0;
        void main(void)
        {
            gl_FragColor = texture2D(tex0, gl_TexCoord[0].xy) * gl_Color;
        }
    ]]
)

lazyshader(
    4, "moviergb",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0;
        void main(void)
        {
            gl_FragColor = texture2DRect(tex0, gl_TexCoord[0].xy);
        }
    ]]
)

lazyshader(
    4, "movieyuv",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
        }
    ]],
    [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0;
        void main(void)
        {
            vec4 sample = texture2DRect(tex0, gl_TexCoord[0].xy);
            gl_FragColor = vec4(dot(sample, vec4(0.500, -0.419, -0.081, 0.500)),
                                dot(sample, vec4(-0.169, -0.331, 0.500, 0.500)),
                                dot(sample.rgb, vec3(0.299, 0.587, 0.114)),
                                sample.a);
        }
    ]]
)

lazyshader(
    4, "moviey",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(-1.5, 0.0);
            gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(-0.5, 0.0);
            gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2( 0.5, 0.0);
            gl_TexCoord[3].xy = gl_MultiTexCoord0.xy + vec2( 1.5, 0.0);
        }
    ]],
    [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0;
        void main(void)
        {
            vec3 sample1 = texture2DRect(tex0, gl_TexCoord[0].xy).rgb;
            vec3 sample2 = texture2DRect(tex0, gl_TexCoord[1].xy).rgb;
            vec3 sample3 = texture2DRect(tex0, gl_TexCoord[2].xy).rgb;
            vec3 sample4 = texture2DRect(tex0, gl_TexCoord[3].xy).rgb;
            gl_FragColor = vec4(dot(sample3, vec3(0.299, 0.587, 0.114)),
                                dot(sample2, vec3(0.299, 0.587, 0.114)),
                                dot(sample1, vec3(0.299, 0.587, 0.114)),
                                dot(sample4, vec3(0.299, 0.587, 0.114)));
        }
    ]]
)

lazyshader(
    4, "movieu",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(-3.0, 0.0);
            gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(-1.0, 0.0);
            gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2( 1.0, 0.0);
            gl_TexCoord[3].xy = gl_MultiTexCoord0.xy + vec2( 3.0, 0.0);
        }
    ]],
    [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0;
        void main(void)
        {
            vec4 sample1 = texture2DRect(tex0, gl_TexCoord[0].xy);
            vec4 sample2 = texture2DRect(tex0, gl_TexCoord[1].xy);
            vec4 sample3 = texture2DRect(tex0, gl_TexCoord[2].xy);
            vec4 sample4 = texture2DRect(tex0, gl_TexCoord[3].xy);
            gl_FragColor = vec4(dot(sample3, vec4(-0.169, -0.331, 0.500, 0.500)),
                                dot(sample2, vec4(-0.169, -0.331, 0.500, 0.500)),
                                dot(sample1, vec4(-0.169, -0.331, 0.500, 0.500)),
                                dot(sample4, vec4(-0.169, -0.331, 0.500, 0.500)));
        }
    ]]
)

lazyshader(
    4, "moviev",
    [[
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + vec2(-3.0, 0.0);
            gl_TexCoord[1].xy = gl_MultiTexCoord0.xy + vec2(-1.0, 0.0);
            gl_TexCoord[2].xy = gl_MultiTexCoord0.xy + vec2( 1.0, 0.0);
            gl_TexCoord[3].xy = gl_MultiTexCoord0.xy + vec2( 3.0, 0.0);
        }
    ]],
    [[
        #extension GL_ARB_texture_rectangle : enable
        uniform sampler2DRect tex0;
        void main(void)
        {
            vec4 sample1 = texture2DRect(tex0, gl_TexCoord[0].xy);
            vec4 sample2 = texture2DRect(tex0, gl_TexCoord[1].xy);
            vec4 sample3 = texture2DRect(tex0, gl_TexCoord[2].xy);
            vec4 sample4 = texture2DRect(tex0, gl_TexCoord[3].xy);
            gl_FragColor = vec4(dot(sample3, vec4(0.500, -0.419, -0.081, 0.500)),
                                dot(sample2, vec4(0.500, -0.419, -0.081, 0.500)),
                                dot(sample1, vec4(0.500, -0.419, -0.081, 0.500)),
                                dot(sample4, vec4(0.500, -0.419, -0.081, 0.500)));
        }
    ]]
)

-- wobbles the vertices of an explosion sphere
-- and generates all texcoords 
-- and blends the edge color
-- and modulates the texture

function explosionshader(...)
    local arg = { ... }
    cc.shader.std(
        4, arg[1],
        [[
            #pragma CUBE2_fog
            uniform vec4 center, animstate;
            %(texgen_st)s
            %(depthfx_pv)s
            void main(void)
            {
                vec4 wobble = vec4(gl_Vertex.xyz*(1.0 + 0.5*abs(fract(dot(gl_Vertex.xyz, center.xyz) + animstate.w*0.002) - 0.5)), gl_Vertex.w);
                %(body)s
                gl_FrontColor = gl_Color;
                %(arg2)s
            } 
        ]] % {
            arg2 = arg[2] or "",
            texgen_st = string.find(arg[1], "3d") and "uniform vec4 texgenS, texgenT;" or "",
            depthfx_pv = string.find(arg[1], "soft") and "uniform vec4 depthfxparams, depthfxview;" or "",
            body = string.find(arg[1], "soft") and [[
                vec4 projtc = gl_ModelViewProjectionMatrix * wobble;
                gl_Position = projtc;
                projtc.z = depthfxparams.y - (gl_ModelViewMatrix * wobble).z*depthfxparams.x;
                projtc.xy = (projtc.xy + projtc.w)*depthfxview.xy;
                gl_TexCoord[3] = projtc;
            ]] or "gl_Position = gl_ModelViewProjectionMatrix * wobble;"
        },
        [[
            %(rect_ext)s
            uniform sampler2D tex0, tex1;
            %(dfxp)s
            %(dfxs)s
            void main(void)
            {
                vec2 dtc = gl_TexCoord[0].xy + texture2D(tex0, %(arg3)s.xy).xy*0.1; // use color texture as noise to distort texcoords
                vec4 diffuse = texture2D(tex0, dtc);
                vec4 blend = texture2D(tex1, gl_TexCoord[1].xy); // get blend factors from modulation texture
                %(glareb)s
                %(softb)s
            }
        ]] % {
            arg3 = arg[3] or "",
            rect_ext = string.find(arg[1], "rect") and [[
                #extension GL_ARB_texture_rectangle : enable
                uniform sampler2DRect tex2;
            ]] or "uniform sampler2D tex2;",
            dfxp = string.find(arg[1], "soft") and "uniform vec4 depthfxparams;" or "",
            dfxs = string.find(arg[1], "soft8") and "uniform vec4 depthfxselect;" or "",
            glareb = string.find(arg[1], "glare") and [[
                float k = blend.a*blend.a;
                diffuse.rgb *= k*8.0;
                diffuse.a *= k;
                diffuse.b += k*k;
            ]] or [[
                diffuse *= blend.a*4.0; // dup alpha into RGB channels + intensify and over saturate
                diffuse.b += 0.5 - blend.a*0.5; // blue tint 
            ]],
            softb = string.find(arg[1], "soft") and [[
                gl_FragColor.rgb = diffuse.rgb * gl_Color.rgb;

                #define depthvals %(rectp)s(tex2, gl_TexCoord[3])
                %(softp)s
                gl_FragColor.a = diffuse.a * max(clamp(depth - gl_TexCoord[3].z, 0.0, 1.0) * gl_Color.a, depthfxparams.w);
            ]] % {
                rectp = string.find(arg[1], "rect") and "texture2DRectProj" or "texture2DProj",
                softp = string.find(arg[1], "soft8")
                and
                    "float depth = dot(depthvals, depthfxselect);"
                or
                    "float depth = depthvals.x*depthfxparams.z;"
            } or "gl_FragColor = diffuse * gl_Color;"
        }
    )
end

for i = 1, usetexrect == 0 and 4 or 6 do
    explosionshader(
        "explosion2d" .. ({ "", "glare", "soft", "soft8", "softrect", "soft8rect" })[i],
        [[
            //blow up the tex coords
            float dtc = 1.768 - animstate.x*1.414; // -2, 2.5; -> -2*sqrt(0.5), 2.5*sqrt(0.5);
            dtc *= dtc;
            gl_TexCoord[0].xy = animstate.w*0.0004 + dtc*gl_Vertex.xy;
            gl_TexCoord[1].xy = gl_Vertex.xy*0.5 + 0.5; //using wobble makes it look too spherical at a distance
        ]], "gl_TexCoord[1]"
    )
    explosionshader(
        "explosion3d" .. ({ "", "glare", "soft", "soft8", "softrect", "soft8rect" })[i],
        [[
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
            vec2 texgen = vec2(dot(texgenS, gl_Vertex), dot(texgenT, gl_Vertex)); 
            gl_TexCoord[1].xy = texgen;
            gl_TexCoord[2].xy = texgen - animstate.w*0.0005;
        ]], "gl_TexCoord[2]"
    )
end

cc.shader.std(
    4, "particlenotexture",
    [[
        #pragma CUBE2_fog
        uniform vec4 colorscale;
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = gl_Color * colorscale;
        } 
    ]],
    [[
        void main(void)
        {
            gl_FragColor = gl_TexCoord[0];
        }
    ]]
)

function particleshader(...)
    local arg = { ... }
    cc.shader.std(
        4, arg[1],
        [[
            #pragma CUBE2_fog
            uniform vec4 colorscale;
            %(dfxsoftp)s
            void main(void)
            {
                gl_Position = ftransform();
                gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
                gl_TexCoord[1] = gl_Color * colorscale; 
                %(body)s
            }
        ]] % {
            dfxsoftp = string.find(arg[1], "soft") and "uniform vec4 depthfxparams, depthfxview;" or "",
            body = string.find(arg[1], "soft") and [[
                vec4 projtc = gl_ModelViewProjectionMatrix * gl_Vertex;
                projtc.xy = (projtc.xy + projtc.w) * depthfxview.xy;
                gl_TexCoord[2] = projtc;
                vec2 offset = gl_MultiTexCoord0.xy*2.82842712474619 - 1.4142135623731;
                gl_TexCoord[3].xyz = vec3(offset, 1.0);
                gl_TexCoord[4].xyz = vec3(offset, depthfxparams.y - (gl_ModelViewMatrix * gl_Vertex).z*depthfxparams.x);
            ]] or ""
        },
        [[
            %(header)s
            uniform sampler2D tex0;
            %(dfxp)s
            %(dfxs)s
            void main(void)
            {
                vec4 diffuse = texture2D(tex0, gl_TexCoord[0].xy);
                %(body)s
                gl_FragColor = diffuse * gl_TexCoord[1];
            }
        ]] % {
            header = string.find(arg[1], "soft") and "%(1)s" % {
                string.find(arg[1], "rect") and [[
                    #extension GL_ARB_texture_rectangle : enable
                    uniform sampler2DRect tex2;
                ]] or "uniform sampler2D tex2;"
            } or "",
            dfxp = string.find(arg[1], "soft") and "uniform vec4 depthfxparams;" or "",
            dfxs = string.find(arg[1], "soft8") and "uniform vec4 depthfxselect;" or "",
            body = string.find(arg[1], "soft") and [[
                #define depthvals %(rectp)s(tex2, gl_TexCoord[2])
                %(softp)s
                diffuse.a *= clamp(depth - dot(gl_TexCoord[3].xyz, gl_TexCoord[4].xyz), 0.0, 1.0);
            ]] % {
                rectp = string.find(arg[1], "rect") and "texture2DRectProj" or "texture2DProj",
                softp = string.find(arg[1], "soft8")
                and
                    "float depth = dot(depthvals, depthfxselect);"
                or
                    "float depth = depthvals.x*depthfxparams.z;"
            } or ""
        }
    )
end

for i = 1, usetexrect == 0 and 3 or 5 do
    particleshader("particle" .. ({ "", "soft", "soft8", "softrect", "soft8rect" })[i])
end

-- phong lighting model shader

-- skeletal animation for matrices and dual quaternions

function skelanimdefs() return string.template([[
    <$0
        if useubo ~= 0 then return [=[
            #ifdef GL_ARB_uniform_buffer_object
                #extension GL_ARB_uniform_buffer_object : enable
            #elif defined(GL_ARB_compatibility)
                #version 140
                #extension GL_ARB_compatibility : enable
            #endif
        ]=] end
    $0>
    <$0
        if usebue ~= 0 then return [=[
            #extension GL_EXT_bindable_uniform : enable
        ]=] end
    $0>
    #pragma CUBE2_attrib vweights 6
    #pragma CUBE2_attrib vbones 7
    attribute vec4 vweights; 
    attribute vec4 vbones;
    #pragma CUBE2_uniform animdata AnimData 0 16
    <$0
        if useubo ~= 0 then return [=[
            #if defined(GL_ARB_uniform_buffer_object) || __VERSION__ >= 140
                layout(std140) uniform AnimData
                {
                    vec4 animdata[<$1=(math.min(maxvsuniforms - reservevpparams, 256) - 10)$1>];
                };
            #else
        ]=] end
    $0>
    <$0
        if usebue ~= 0 then return [=[
            #ifdef GL_EXT_bindable_uniform
                bindable
            #endif
        ]=] end
    $0>
    uniform vec4 animdata[<$0=(math.min(maxvsuniforms - reservevpparams, 256) - 10)$0>];
    <$0
        if useubo ~= 0 then return [=[
            #endif
        ]=] end
    $0>
]]) end

function skelanimfragdefs() return ati_ubo_bug ~= 0 and
    (useubo ~= 0 and [[
        #ifdef GL_ARB_uniform_buffer_object
            #extension GL_ARB_uniform_buffer_object : enable
        #elif defined(GL_ARB_compatibility)
            #version 140
            #extension GL_ARB_compatibility : enable
        #endif
        #if defined(GL_ARB_uniform_buffer_object) || __VERSION__ >= 140
            layout(std140) uniform AnimData
            {
                vec4 animdata[%(1)i];
            };
        #endif
    ]] % { math.min(maxvsuniforms - reservevpparams, 256) - 10 } or [[
        #ifdef GL_EXT_bindable_uniform
            #extension GL_EXT_bindable_uniform : enable
            bindable uniform vec4 animdata[%(1)i];
        #endif
    ]] % { math.min(maxvsuniforms - reservevpparams, 256) - 10 })
or
    (useubo ~= 0 and [[
        #if !defined(GL_ARB_uniform_buffer_object) && defined(GL_ARB_compatibility)
            #version 140
        #endif
    ]] or "")
end

function skelmatanim(...)
    local arg = { ... }
    return [[
        int index = int(vbones.x);
        %(1)s
        %(2)s
        %(3)s
        vec4 opos = vec4(dot(mx, gl_Vertex), dot(my, gl_Vertex), dot(mz, gl_Vertex), gl_Vertex.w);
        %(4)s
        %(5)s
    ]] % {
        arg[1] == 1 and [[
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
        ]],
        arg[1] >= 3 and [[
            index = int(vbones.z);
            mx += animdata[index] * vweights.z;
            my += animdata[index+1] * vweights.z;
            mz += animdata[index+2] * vweights.z;
        ]] or "",
        arg[1] >= 4 and [[
            index = int(vbones.w);
            mx += animdata[index] * vweights.w;
            my += animdata[index+1] * vweights.w;
            mz += animdata[index+2] * vweights.w;
        ]],
        arg[2] and arg[2] ~= 0 and [[
            vec3 onormal = vec3(dot(mx.xyz, gl_Normal), dot(my.xyz, gl_Normal), dot(mz.xyz, gl_Normal));
        ]] or "",
        arg[3] and arg[3] ~= 0 and [[
            vec3 otangent = vec3(dot(mx.xyz, vtangent.xyz), dot(my.xyz, vtangent.xyz), dot(mz.xyz, vtangent.xyz));
        ]] or ""
    }
end

function skelquatanim(...)
    local arg = { ... }
    return [[
        int index = int(vbones.x);
        %(1)s
        vec4 opos = vec4((cross(dqreal.xyz, cross(dqreal.xyz, gl_Vertex.xyz) + gl_Vertex.xyz*dqreal.w + dqdual.xyz) + dqdual.xyz*dqreal.w - dqreal.xyz*dqdual.w)*2.0 + gl_Vertex.xyz, gl_Vertex.w);
        %(2)s
        %(3)s
    ]] % {
        arg[1] == 1 and [[
            vec4 dqreal = animdata[index];
            vec4 dqdual = animdata[index+1];
        ]] or [[
            vec4 dqreal = animdata[index] * vweights.x;
            vec4 dqdual = animdata[index+1] * vweights.x;
            index = int(vbones.y);
            dqreal += animdata[index] * vweights.y;
            dqdual += animdata[index+1] * vweights.y;
            %(1)s
            %(2)s
            float len = length(dqreal);
            dqreal /= len;
            dqdual /= len;
        ]] % {
            arg[1] >= 3 and [[
                index = int(vbones.z);
                dqreal += animdata[index] * vweights.z;
                dqdual += animdata[index+1] * vweights.z;
            ]] or "",
            arg[1] >= 4 and [[
                index = int(vbones.w);
                dqreal += animdata[index] * vweights.w;
                dqdual += animdata[index+1] * vweights.w;
            ]] or ""
        },
        arg[2] and arg[2] ~= 0 and [[
            vec3 onormal = cross(dqreal.xyz, cross(dqreal.xyz, gl_Normal) + gl_Normal*dqreal.w)*2.0 + gl_Normal;
        ]] or "",
        arg[3] and arg[3] ~= 0 and [[
            vec3 otangent = cross(dqreal.xyz, cross(dqreal.xyz, vtangent.xyz) + vtangent.xyz*dqreal.w)*2.0 + vtangent.xyz;
        ]] or ""
    }
end

-- model shadowmapping

function shadowmapcastervertexshader(...)
    local arg = { ... }
    return [[
        %(1)s
            uniform vec4 shadowintensity;
        %(2)s
                gl_TexCoord[0] = vec4(1.0 - gl_Position.z, 1.0, 0.0, shadowintensity.x);
            }
    ]] % {
        (#arg >= 2) and arg[1] or "",
        (#arg >= 2) and [[
            void main(void)
            {
                %(1)s
                gl_Position = gl_ModelViewProjectionMatrix * opos;
        ]] % { arg[2] or "" } or [[
            void main(void)
            {
                gl_Position = ftransform();
        ]]
    }
end

cc.shader.std(
    4, "shadowmapcaster",
    shadowmapcastervertexshader(),
    [[
        void main(void)
        {
            gl_FragColor = gl_TexCoord[0];
        }
    ]]
)

for i = 1, 4 do
    cc.shader.variant(4, "shadowmapcaster", 0, shadowmapcastervertexshader(skelanimdefs(), skelmatanim (i, 0, 0)), "")
    cc.shader.variant(4, "shadowmapcaster", 1, shadowmapcastervertexshader(skelanimdefs(), skelquatanim(i, 0, 0)), "")
end

cc.shader.std(
    4, "shadowmapreceiver",
    [[
        uniform vec4 shadowmapbias;
        void main(void)
        {
            gl_Position = ftransform();
            gl_TexCoord[0] = vec4(0.0, 0.0, shadowmapbias.y - gl_Position.z, 0.0); 
        }
    ]],
    [[
        void main(void)
        {
            gl_FragColor = gl_TexCoord[0];
        }
    ]]
)

-- model stencil shadows

function notexturemodelvertexshader(...)
    local arg = { ... }
    return [[
        %(1)s
                gl_FrontColor = gl_Color;
            }
    ]] % {
        (#arg >= 2) and [[
            %(1)s
            #pragma CUBE2_fog opos
            void main(void)
            {
                %(2)s
                gl_Position = gl_ModelViewProjectionMatrix * opos;
        ]] % { arg[1], arg[2] } or [[
            #pragma CUBE2_fog
            void main(void)
            {
                gl_Position = ftransform();
        ]]
    }
end

cc.shader.std(
    4, "notexturemodel",
    notexturemodelvertexshader(),
    [[
        void main(void)
        {
            gl_FragColor = gl_Color;
        }
    ]]
)

for i = 1, 4 do
    cc.shader.variant(4, "notexturemodel", 0, notexturemodelvertexshader(skelanimdefs(), skelmatanim (i, 0, 0)), "")
    cc.shader.variant(4, "notexturemodel", 1, notexturemodelvertexshader(skelanimdefs(), skelquatanim(i, 0, 0)), "")
end

-- mdltype:
--    e -> envmap
--    n -> normalmap
--    s -> spec
--    m -> masks
--    B -> matrix skeletal animation
--    b -> dual-quat skeletal animation
--    i -> glare intensity

function mdlopt(bt, a)
    return string.find(bt, a) ~= nil
end

function modelvertexshader(...)
    local arg = { ... }
    local mdls = {
        mdl_b = tostring(mdlopt(arg[1], "b")),
        mdl_B = tostring(mdlopt(arg[1], "B")),
        mdl_n = tostring(mdlopt(arg[1], "n")),
        mdl_e = tostring(mdlopt(arg[1], "e")),
        mdl_s = tostring(mdlopt(arg[1], "s")),
        mdl_i = tostring(mdlopt(arg[1], "i")),
        mdl_m = tostring(mdlopt(arg[1], "m")),
        arg2  = tostring(arg[2])
    }
    return string.template([[
        <$0 if %(mdl_b)s or %(mdl_B)s then return skelanimdefs() end $0>
        #pragma CUBE2_fog opos
        <$0
            if %(mdl_n)s then return [=[
                #pragma CUBE2_attrib vtangent 1
                attribute vec4 vtangent;
            ]=] end
        $0>
        uniform vec4 camera, lightdir, lightscale, texscroll;
        <$0
            if %(mdl_n)s then return [=[
                <$1
                    if %(mdl_e)s then return [==[
                        varying vec3 camvec;
                        varying mat3 world;
                    ]==] else return [==[
                        varying vec3 lightvec, halfangle;
                    ]==] end
                $1>
            ]=] else return [=[
                <$1
                    if %(mdl_s)s then return "varying vec3 nvec, halfangle;" end
                $1>
                <$1
                    if %(mdl_e)s then return [==[
                        uniform vec4 envmapscale;
                        varying vec3 rvec;
                        varying float rmod;
                    ]==] end
                $1>
            ]=] end
        $0>
        void main(void)
        {
            <$0 if %(mdl_B)s then return skelmatanim(%(arg2)s, 1, %(mdl_n)s and 1 or 0) end $0>
            <$0 if %(mdl_b)s then return skelquatanim(%(arg2)s, 1, %(mdl_n)s and 1 or 0) end $0>
            <$0
                if %(mdl_b)s or %(mdl_B)s then return "gl_Position = gl_ModelViewProjectionMatrix * opos;"
                else return [=[
                    gl_Position = ftransform();
                    #define opos gl_Vertex
                    #define onormal gl_Normal
                    #define otangent vtangent.xyz
                ]=] end
            $0>
            <$0 if %(mdl_n)s or %(mdl_s)s or %(mdl_i)s then return "gl_FrontColor = gl_Color;" end $0>
            gl_TexCoord[0].xy = gl_MultiTexCoord0.xy + texscroll.yz;
            <$0 if %(mdl_e)s or %(mdl_s)s then return "vec3 camdir = normalize(camera.xyz - opos.xyz);" end $0>

            <$0
                if %(mdl_n)s then return [=[
                    <$1
                        if %(mdl_e)s then return [==[
                            camvec = mat3(gl_TextureMatrix[0][0].xyz, gl_TextureMatrix[0][1].xyz, gl_TextureMatrix[0][2].xyz) * camdir;
                            // composition of tangent -> object and object -> world transforms
                            //   becomes tangent -> world
                            vec3 wnormal = mat3(gl_TextureMatrix[0][0].xyz, gl_TextureMatrix[0][1].xyz, gl_TextureMatrix[0][2].xyz) * onormal;
                            vec3 wtangent = mat3(gl_TextureMatrix[0][0].xyz, gl_TextureMatrix[0][1].xyz, gl_TextureMatrix[0][2].xyz) * otangent;
                            world = mat3(wtangent, cross(wnormal, wtangent) * vtangent.w, wnormal);
                        ]==] else return [==[
                            vec3 obitangent = cross(onormal, otangent) * vtangent.w;
                            lightvec = vec3(dot(lightdir.xyz, otangent), dot(lightdir.xyz, obitangent), dot(lightdir.xyz, onormal));
                            <$2
                                if %(mdl_s)s then return [===[
                                    vec3 halfdir = lightdir.xyz + camdir; 
                                    halfangle = vec3(dot(halfdir, otangent), dot(halfdir, obitangent), dot(halfdir, onormal));
                                ]===] end
                            $2>
                        ]==] end
                    $1>
                ]=] else return [=[
                    <$1
                        if %(mdl_s)s then return [==[
                            nvec = onormal; 
                            halfangle = lightdir.xyz + camdir;
                        ]==] else return [==[
                            gl_FrontColor = vec4(gl_Color.rgb*max(dot(onormal, lightdir.xyz) + 0.5, lightscale.y), gl_Color.a);
                        ]==] end
                    $1>
                    <$1
                        if %(mdl_e)s then return [==[
                            float invfresnel = dot(camdir, onormal);
                            rvec = mat3(gl_TextureMatrix[0][0].xyz, gl_TextureMatrix[0][1].xyz, gl_TextureMatrix[0][2].xyz) * (2.0*invfresnel*onormal - camdir);
                            rmod = envmapscale.x*max(invfresnel, 0.0) + envmapscale.y;  
                        ]==] end
                    $1>
                ]=] end
            $0>
        }
    ]] % mdls)
end

function modelfragmentshader(...)
    local arg = { ... }
    local mdls = {
        mdl_b = tostring(mdlopt(arg[1], "b")),
        mdl_B = tostring(mdlopt(arg[1], "B")),
        mdl_n = tostring(mdlopt(arg[1], "n")),
        mdl_e = tostring(mdlopt(arg[1], "e")),
        mdl_s = tostring(mdlopt(arg[1], "s")),
        mdl_i = tostring(mdlopt(arg[1], "i")),
        mdl_m = tostring(mdlopt(arg[1], "m")),
        arg2  = tostring(arg[2])
    }
    return string.template([[
        <$0 if %(mdl_b)s or %(mdl_B)s then return skelanimfragdefs() end $0>
        <$0
            if %(mdl_n)s then return [=[
                <$1
                    if %(mdl_e)s then return [==[
                        #define lightvec lightdirworld.xyz
                        uniform vec4 lightdirworld, envmapscale;
                        varying vec3 camvec;
                        varying mat3 world;
                    ]==] else return [==[
                        varying vec3 lightvec, halfangle;
                    ]==] end
                $1>
            ]=] else return [=[
                <$1
                    if %(mdl_s)s then return [==[
                        #define lightvec lightdir.xyz
                        uniform vec4 lightdir;
                        varying vec3 nvec, halfangle;
                    ]==] end
                $1>
                <$1
                    if %(mdl_e)s then return [==[
                        varying vec3 rvec;
                        varying float rmod;
                    ]==] end
                $1>
            ]=] end
        $0>
        <$0 if %(mdl_s)s or %(mdl_m)s or (%(mdl_n)s and not %(mdl_i)s) then return "uniform vec4 lightscale;" end $0>
        <$0 if %(mdl_i)s and (%(mdl_s)s or %(mdl_m)s) then return "uniform vec4 glarescale;" end $0>
        uniform sampler2D tex0;
        <$0 if %(mdl_m)s then return "uniform sampler2D tex1;" end $0>
        <$0 if %(mdl_e)s then return "uniform samplerCube tex2;" end $0>
        <$0 if %(mdl_n)s then return "uniform sampler2D tex3;" end $0>
        void main(void)
        {
            vec4 light = texture2D(tex0, gl_TexCoord[0].xy);
            <$0
                if %(mdl_m)s then return [=[
                    vec3 masks = texture2D(tex1, gl_TexCoord[0].xy).rgb;
                    vec3 glow = light.rgb * lightscale.z;
                ]=] end
            $0>
            <$0
                if %(mdl_n)s then return [=[
                    vec3 normal = normalize(texture2D(tex3, gl_TexCoord[0].xy).rgb - 0.5);
                    <$1 if %(mdl_e)s then return "normal = world * normal;" end $1>
                ]=] end
            $0>
            <$0
                if %(mdl_s)s then return [=[
                    <$1
                        if %(mdl_n)s then return [==[
                            <$2 if %(mdl_e)s then return "vec3 halfangle = lightvec + camvec;" end $2>
                        ]==] else return "vec3 normal = normalize(nvec);" end
                    $1>
                    float spec = lightscale.x * pow(clamp(dot(normalize(halfangle), normal), 0.0, 1.0), <$1=%(mdl_i)s and "256.0" or "128.0"$1>);
                    <$1 if %(mdl_m)s then return "spec *= masks.r;" end $1> // specmap in red channel
                ]=] end
            $0>
            <$0
                if %(mdl_i)s then return [=[
                    <$1
                        if %(mdl_s)s then return [==[
                            spec *= glarescale.x;
                            <$2=%(mdl_m)s and "light.rgb" or "gl_FragColor.rgb"$2> = spec * gl_Color.rgb;
                        ]==] elseif not %(mdl_m)s then return "gl_FragColor.rgb = vec3(0.0);" end
                    $1>
                ]=] else return [=[
                    <$1 if %(mdl_s)s or %(mdl_n)s then return "light.rgb *= max(dot(normal, lightvec) + 0.5, lightscale.y);" end $1>
                    <$1 if %(mdl_s)s then return "light.rgb += spec;" end $1>
                    <$1 if %(mdl_m)s then return "light.rgb *= gl_Color.rgb;" else return "gl_FragColor = light * gl_Color;" end $1>
                ]=] end
            $0>
            <$0
                if %(mdl_m)s then
                    if %(mdl_e)s then return [=[
                        light.rgb = mix(light.rgb, glow, masks.g); // glow mask in green channel
                        <$1
                            if %(mdl_n)s then return [==[
                                vec3 camn = normalize(camvec);
                                float invfresnel = dot(camn, normal);
                                vec3 rvec = 2.0*invfresnel*normal - camn;
                                float rmod = envmapscale.x*max(invfresnel, 0.0) + envmapscale.y;
                            ]==] end
                        $1>
                        vec3 reflect = textureCube(tex2, rvec).rgb; 
                        gl_FragColor.rgb = mix(light.rgb, reflect, rmod*masks.b); // envmap mask in blue channel
                    ]=] else
                        if %(mdl_i)s then return [=[
                            float k = min(masks.g*masks.g*glarescale.y, 1.0); // glow mask in green channel
                            gl_FragColor.rgb = <$1=%(mdl_s)s and "glow*k + light.rgb" or "glow*k"$1>;
                        ]=] else return [=[
                            gl_FragColor.rgb = mix(light.rgb, glow, masks.g); // glow mask in green channel
                        ]=] end
                    end
                end
            $0>
            <$0 if %(mdl_i)s or %(mdl_m)s then return "gl_FragColor.a = light.a * gl_Color.a;" end $0>
        }
    ]] % mdls)
end

function modelanimshader(...)
    local arg = { ... }
    local fraganimshader = arg[2] > 0 and arg[2] or 0
    local reuseanimshader = fraganimshader
    if ati_ubo_bug ~= 0 then
        reuseanimshader = "%(1)s , %(2)s" % { arg[2], arg[2] > 0 and 1 or 0 }
        fraganimshader = arg[4] == 1 and modelfragmentshader("bB" .. arg[3]) or reuseanimshader
    end
    cc.shader.variant(4, arg[1], arg[2], modelvertexshader("B" .. arg[3], arg[4]), fraganimshader)
    cc.shader.variant(4, arg[1], arg[2] + 1, modelvertexshader("b" .. arg[3], arg[4]), reuseanimshader)
end

function modelshader(...)
    local arg = { ... }
    cc.shader.defer(
        4, arg[1],
        [[
            local basemodeltype = %(arg2)q
            cc.shader.std(4, %(arg1)q, modelvertexshader(basemodeltype), modelfragmentshader(basemodeltype))
            for i = 1, 4 do
                modelanimshader(%(arg1)q, 0, basemodeltype, i)
            end
            local glaremodeltype = string.gsub(basemodeltype .. "i", "e", "")
            if not string.find(glaremodeltype, "s") then glaremodeltype = string.gsub(glaremodeltype, "n", "") end
            cc.shader.variant(4, %(arg1)q, 2, modelvertexshader(glaremodeltype), modelfragmentshader(glaremodeltype))
            for i = 1, 4 do
                modelanimshader(%(arg1)q, 2, glaremodeltype, i)
            end
        ]] % {
            arg1 = arg[1] or "",
            arg2 = arg[2] or ""
        }
    )
end

-- gouraud lighting model shader: cheaper, non-specular version for vegetation etc. gets used when spec==0

modelshader("nospecmodel", "")
modelshader("masksnospecmodel", "m")
modelshader("envmapnospecmodel", "me")
cc.shader.alt("envmapnospecmodel", "masksnospecmodel")

modelshader("bumpnospecmodel", "n")
modelshader("bumpmasksnospecmodel", "nm")
modelshader("bumpenvmapnospecmodel", "nme")
cc.shader.alt("bumpenvmapnospecmodel", "bumpmasksnospecmodel")

-- phong lighting model shader

modelshader("stdmodel", "s")
cc.shader.fast("stdmodel", "nospecmodel", 1)
modelshader("masksmodel", "sm")
cc.shader.fast("masksmodel", "masksnospecmodel", 1)
modelshader("envmapmodel", "sme")
cc.shader.alt("envmapmodel", "masksmodel")
cc.shader.fast("envmapmodel", "envmapnospecmodel", 1)

modelshader("bumpmodel", "ns")
cc.shader.fast("bumpmodel", "bumpnospecmodel", 1)
modelshader("bumpmasksmodel", "nsm")
cc.shader.fast("bumpmasksmodel", "bumpmasksnospecmodel", 1)
modelshader("bumpenvmapmodel", "nsme")
cc.shader.alt("bumpenvmapmodel", "bumpmasksmodel")
cc.shader.fast("bumpenvmapmodel", "bumpenvmapnospecmodel", 1)

