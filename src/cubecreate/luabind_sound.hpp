/*
 * luabind_sound.hpp, version 1
 * Sound control methods for Lua
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
void startmusic(char *name, char *cmd);
int preload_sound(char *name, int vol);

namespace lua_binds
{
    LUA_BIND_CLIENT(playsoundname, {
        vec loc(e.get<double>(2), e.get<double>(3), e.get<double>(4));

        if (loc.x || loc.y || loc.z)
             playsoundname(e.get<const char*>(1), &loc, e.get<int>(5));
        else playsoundname(e.get<const char*>(1));
    })

    LUA_BIND_STD_CLIENT(stopsoundname, stopsoundbyid, getsoundid(e.get<const char*>(1), e.get<int>(2)))

    LUA_BIND_STD_CLIENT(music, startmusic, e.get<char*>(1), (char*)"cc.sound.musiccallback()")

    LUA_BIND_CLIENT(preloadsound, {
        defformatstring(str)("preloading sound '%s'...", e.get<const char*>(1));
        renderprogress(0, str);

        e.push(preload_sound((char*)e.get<const char*>(1), min(e.get(2, 100), 100)));
    })

    #ifdef CLIENT
    // TODO: sound position
    LUA_BIND_STD(playsound, playsound, e.get<int>(1))
    #else
    LUA_BIND_STD(playsound, MessageSystem::send_SoundToClients, -1, e.get<int>(1), -1)
    #endif
}
