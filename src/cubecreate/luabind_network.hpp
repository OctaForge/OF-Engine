/*
 * luabind_network.hpp, version 1
 * Various server / network methods for Lua
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
void trydisconnect();
void startlistenserver(int usemaster);
void stoplistenserver();

namespace game
{
    void toserver(char *text);
    fpsent *followingplayer();
}

namespace lua_binds
{
    LUA_BIND_STD_CLIENT(connect, ClientSystem::connect, e.get<const char*>(1), e.get<int>(2))
    LUA_BIND_STD(isconnected, e.push, isconnected(e.get<int>(1) > 0) ? 1 : 0)

    LUA_BIND_DEF(connectedip, {
        const ENetAddress *address = connectedpeer();
        string hostname;
        e.push(address && enet_address_get_host_ip(address, hostname, sizeof(hostname)) >= 0 ? hostname : "");
    })

    LUA_BIND_DEF(connectedport, {
        const ENetAddress *address = connectedpeer();
        e.push(address ? address->port : -1);
    })

    LUA_BIND_STD(connectserv, connectserv, e.get<const char*>(1), e.get<int>(2), e.get<const char*>(3))
    LUA_BIND_STD(lanconnect, connectserv, NULL, e.get<int>(1), e.get<const char*>(2))
    LUA_BIND_STD(disconnect, trydisconnect)
    LUA_BIND_STD(localconnect, if(!isconnected() && !haslocalclients()) localconnect)
    LUA_BIND_STD(localdisconnect, if(haslocalclients()) localdisconnect)

    LUA_BIND_STD(startlistenserver, startlistenserver, e.get<int>(1))
    LUA_BIND_STD(stoplistenserver, stoplistenserver)

    LUA_BIND_DEF(getfollow, {
        fpsent *f = game::followingplayer();
        e.push(f ? f->clientnum : -1);
    })

    LUA_BIND_CLIENT(do_upload, {
        renderprogress(0.1, "compiling scripts ..");

        REFLECT_PYTHON(get_map_script_filename);
        const char *fname = boost::python::extract<const char*>(get_map_script_filename());
        if (!engine.loadf(fname))
        {
            IntensityGUI::showMessage("Compilation failed", engine.geterror_last());
            return;
        }

        renderprogress(0.3, "generating map ..");
        save_world(game::getclientmap());

        renderprogress(0.4, "exporting entities ..");
        of_world_export_entities("entities.json");

        renderprogress(0.5, "uploading map ..");
        REFLECT_PYTHON(upload_map);
        upload_map();
    })

    LUA_BIND_STD_CLIENT(restart_map, MessageSystem::send_RestartMap)
}
