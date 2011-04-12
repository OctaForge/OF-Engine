/*
 * luabind_shaders.hpp, version 1
 * Shader system exports for Lua
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

/* PROTOTYPES */
void shader(int *type, char *name, char *vs, char *ps);
void variantshader(int *type, char *name, int *row, char *vs, char *ps);
void setshader(char *name);
void addshaderparam(const char *name, int type, int n, float x, float y, float z, float w);
void altshader(char *origname, char *altname);
void fastshader(char *nice, char *fast, int *detail);
void defershader(int *type, const char *name, const char *contents);
Shader *useshaderbyname(const char *name);
void isshaderdefined(char *name);
void isshadernative(char *name);
void addpostfx(const char *name, int bind, int scale, const char *inputs, float x, float y, float z, float w);
void setpostfx(const char *name, float x, float y, float z, float w);
void clearpostfx();

namespace lua_binds
{
    LUA_BIND_STD_CLIENT(shader, shader,
                        e.get<int*>(1), e.get<char*>(2),
                        e.get<char*>(3), e.get<char*>(4))
    LUA_BIND_STD_CLIENT(variantshader, variantshader,
                        e.get<int*>(1), e.get<char*>(2),
                        e.get<int*>(3), e.get<char*>(4),
                        e.get<char*>(5))
    LUA_BIND_STD_CLIENT(setshader, setshader, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(altshader, altshader, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD_CLIENT(fastshader, fastshader, e.get<char*>(1), e.get<char*>(2), e.get<int*>(3))
    LUA_BIND_STD_CLIENT(defershader, defershader, e.get<int*>(1), e.get<const char*>(2), e.get<const char*>(3))
    LUA_BIND_STD_CLIENT(forceshader, useshaderbyname, e.get<const char*>(1))

    LUA_BIND_STD_CLIENT(isshaderdefined, isshaderdefined, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(isshadernative, isshadernative, e.get<char*>(1))

    LUA_BIND_STD_CLIENT(setvertexparam, addshaderparam,
                        NULL, SHPARAM_VERTEX, e.get<int>(1),
                        e.get<float>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5))
    LUA_BIND_STD_CLIENT(setpixelparam, addshaderparam,
                        NULL, SHPARAM_VERTEX, e.get<int>(1),
                        e.get<float>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5))
    LUA_BIND_STD_CLIENT(setuniformparam, addshaderparam,
                        e.get<const char*>(1), SHPARAM_UNIFORM, -1,
                        e.get<float>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5))
    LUA_BIND_STD_CLIENT(setshaderparam, addshaderparam,
                        e.get<const char*>(1), SHPARAM_LOOKUP, -1,
                        e.get<float>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5))
    LUA_BIND_STD_CLIENT(defvertexparam, addshaderparam,
                        e.get<const char*>(1)[0] ? e.get<char*>(1) : NULL,
                        SHPARAM_VERTEX, e.get<int>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5), e.get<float>(6))
    LUA_BIND_STD_CLIENT(defpixelparam, addshaderparam,
                        e.get<const char*>(1)[0] ? e.get<char*>(1) : NULL,
                        SHPARAM_PIXEL, e.get<int>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5), e.get<float>(6))
    LUA_BIND_STD_CLIENT(defuniformparam, addshaderparam,
                        e.get<const char*>(1), SHPARAM_UNIFORM, -1,
                        e.get<float>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5))

    LUA_BIND_STD_CLIENT(addpostfx, addpostfx,
                        e.get<const char*>(1), e.get<int>(2),e.get<int>(3),
                        e.get<const char*>(4), e.get<float>(5),e.get<float>(6),
                        e.get<float>(7), e.get<float>(8))
    LUA_BIND_STD_CLIENT(setpostfx, setpostfx,
                        e.get<const char*>(1), e.get<float>(2), e.get<float>(3),
                        e.get<float>(4), e.get<float>(5))
    LUA_BIND_STD_CLIENT(clearpostfx, clearpostfx)
}
