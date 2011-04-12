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

namespace MasterServer
{
    void do_login(char *username, char *password);
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

    LUA_BIND_CLIENT(connect_to_instance, {
        REFLECT_PYTHON(login_to_instance);
        login_to_instance(e.get<const char*>(1));
    })

    LUA_BIND_CLIENT(connect_to_lobby, {
        REFLECT_PYTHON(connect_to_lobby);
        connect_to_lobby();
    })

    LUA_BIND_CLIENT(connect_to_selected_instance, {
        REFLECT_PYTHON(connect_to_selected_instance);
        connect_to_selected_instance();
    })

    LUA_BIND_CLIENT(show_instances, {
        REFLECT_PYTHON(get_possible_instances);
        boost::python::object instances = get_possible_instances();
        REFLECT_PYTHON(None);

        if (instances == None)
        {
            SETVF(error_message, "Could not get the list of instances");
            showgui("error");
            return;
        }

        char buf[1024];
        snprintf(buf, sizeof(buf),
            "cc.gui.new(\"instances\", [[\n"
            "    cc.gui.text(\"Pick an instance to enter:\")\n"
            "    cc.gui.bar()\n");
        char *command = (char*)malloc(strlen(buf) + 1);
        strcpy(command, buf);

        int ninst = boost::python::extract<int>(instances.attr("__len__")());
        for (int i = 0; i < ninst; i++)
        {
            boost::python::object instance = instances[i];
            const char *instance_id = boost::python::extract<const char*>(instance.attr("__getitem__")("instance_id"));
            const char *event_name = boost::python::extract<const char*>(instance.attr("__getitem__")("event_name"));

            assert( Utility::validateAlphaNumeric(instance_id) );
            assert( Utility::validateAlphaNumeric(event_name, " (),.;") ); // XXX: Allow more than alphanumeric+spaces: ()s, .s, etc.

            snprintf(buf, sizeof(buf), "    cc.gui.button(\"%s\", \"cc.network.connect_to_instance(%s)\")\n", event_name, instance_id);
            command = (char*)realloc(command, strlen(command) + strlen(buf) + 1);
            assert(command);
            strcat(command, buf);
        }

        snprintf(buf, sizeof(buf), "]])\ncc.gui.show(\"instances\")\n");
        command = (char*)realloc(command, strlen(command) + strlen(buf) + 1);
        assert(command);
        strcat(command, buf);

        Logging::log(Logging::DEBUG, "Instances GUI: %s\r\n", command);
        engine.exec(command);

        command = NULL;
        free(command);
    })

    LUA_BIND_CLIENT(do_upload, {
        renderprogress(0.1, "compiling scripts ..");

        REFLECT_PYTHON(get_map_script_filename);
        const char *fname = boost::python::extract<const char*>(get_map_script_filename());
        if (!engine.load(Utility::readFile(fname).c_str()))
        {
            IntensityGUI::showMessage("Compilation failed", engine.geterror_last());
            return;
        }

        renderprogress(0.3, "generating map ..");
        save_world(game::getclientmap());

        renderprogress(0.4, "exporting entities ..");
        REFLECT_PYTHON(export_entities);
        export_entities("entities.json");

        renderprogress(0.5, "uploading map ..");
        REFLECT_PYTHON(upload_map);
        upload_map();

        REFLECT_PYTHON(get_curr_map_asset_id);
        const char *aid = boost::python::extract<const char*>(get_curr_map_asset_id());
        SETVF(last_uploaded_map_asset, aid);
    })

    /* Reuploads asset - doesn't save world and doesn't require one running - useful
     * for reuploading stuff crashing etc
     */
    LUA_BIND_CLIENT(repeat_upload, {
        const char *lumasset = GETSV(last_uploaded_map_asset);

        renderprogress(0.2, "getting map asset info ..");
        REFLECT_PYTHON(AssetManager);
        boost::python::object ainfo = AssetManager.attr("get_info")(lumasset);

        REFLECT_PYTHON(set_curr_map_asset_id);
        set_curr_map_asset_id(lumasset);

        REFLECT_PYTHON(World);
        World.attr("asset_info") = ainfo;

        renderprogress(0.5, "compiling scripts ..");
        REFLECT_PYTHON(get_map_script_filename);
        const char *fname = boost::python::extract<const char*>(get_map_script_filename());
        if (!engine.load(Utility::readFile(fname).c_str()))
        {
            IntensityGUI::showMessage("Compilation failed", engine.geterror_last());
            return;
        }

        renderprogress(0.7, "uploading map ..");
        REFLECT_PYTHON(upload_map);
        upload_map();

        conoutf("Upload complete.");
    })

    LUA_BIND_STD_CLIENT(restart_map, MessageSystem::send_RestartMap)

    LUA_BIND_STD_CLIENT(do_login, MasterServer::do_login, e.get<char*>(1), e.get<char*>(2))
}
