/*
 * luabind_blend.hpp, version 1
 * Texture blending methods for Lua
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
extern int paintingblendmap;
void clearblendbrushes();
void delblendbrush(const char *name);
void addblendbrush(const char *name, const char *imgname);
void nextblendbrush(int *dir);
void setblendbrush(const char *name);
void getblendbrushname(int *n);
void curblendbrush();
void rotateblendbrush(int *val);
void paintblendmap(bool msg);
void clearblendmapsel();
void invertblendmapsel();
void invertblendmap();
void showblendmap();
void optimizeblendmap();
void resetblendmap();

namespace lua_binds
{
    LUA_BIND_STD(clearblendbrushes, clearblendbrushes)
    LUA_BIND_STD(delblendbrush, delblendbrush, e.get<const char*>(1))
    LUA_BIND_STD(addblendbrush, addblendbrush, e.get<const char*>(1), e.get<const char*>(2))
    LUA_BIND_STD(nextblendbrush, nextblendbrush, e.get<int*>(1))
    LUA_BIND_STD(setblendbrush, setblendbrush, e.get<const char*>(1))
    LUA_BIND_STD(getblendbrushname, getblendbrushname, e.get<int*>(1))
    LUA_BIND_STD(curblendbrush, curblendbrush)
    LUA_BIND_STD(rotateblendbrush, rotateblendbrush, e.get<int*>(1))
    LUA_BIND_DEF(paintblendmap, {
        if (addreleaseaction("CAPI.paintblendmap()"))
        {
            if (!paintingblendmap)
            {
                paintblendmap(true);
                paintingblendmap = totalmillis;
            }
        }
        else stoppaintblendmap();
    })
    LUA_BIND_STD(clearblendmapsel, clearblendmapsel)
    LUA_BIND_STD(invertblendmapsel, invertblendmapsel)
    LUA_BIND_STD(invertblendmap, invertblendmap)
    LUA_BIND_STD(showblendmap, showblendmap)
    LUA_BIND_STD(optimizeblendmap, optimizeblendmap)
    LUA_BIND_DEF(clearblendmap, {
        if(noedit(true) || (GETIV(nompedit) && multiplayer())) return;
        resetblendmap();
        showblendmap();
    })
}
