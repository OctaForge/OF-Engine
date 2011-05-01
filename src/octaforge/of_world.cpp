/*
 * of_world.c, version 1
 * World control functions for OctaForge.
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

#include "cube.h"
#include "of_tools.h"
#include "game.h"

#include "of_world.h"
#ifdef SERVER
#include "server_system.h"
#endif

void force_network_flush();
namespace MessageSystem
{
    void send_PrepareForNewScenario(int clientNumber, std::string scenarioCode);
    void send_RequestPrivateEditMode();
    void send_NotifyAboutCurrentScenario(int clientNumber, std::string mapAssetId, std::string scenarioCode);
}
using namespace MessageSystem;

extern string homedir;

bool of_world_set_map(const char *id)
{
    REFLECT_PYTHON(World);
    World.attr("start_scenario")();

#ifdef SERVER
    send_PrepareForNewScenario(-1, boost::python::extract<std::string>(World.attr("scenario_code")));
    force_network_flush();
#endif

    REFLECT_PYTHON(set_curr_map_asset_id);
    set_curr_map_asset_id(id);
    World.attr("asset_location") = id;

    REFLECT_PYTHON(set_curr_map_prefix);
    char *s = strdup(id);
    s[strlen(s) - 6] = '\0';
    s[strlen(s) - 1] = '/';
    set_curr_map_prefix(std::string(s));

    defformatstring(w)("%smap", s);
    if (!load_world(w))
    {
        Logging::log(Logging::ERROR, "Failed to load world!\n");
        return false;
    }
    OF_FREE(s);

#ifdef SERVER
    server::createluaEntity(-1);
    of_world_send_curr_map(-1);
#else
    send_RequestPrivateEditMode();
#endif

    return true;
}

bool of_world_restart_map()
{
    REFLECT_PYTHON(get_curr_map_asset_id);
    return of_world_set_map(boost::python::extract<const char*>(get_curr_map_asset_id()));
}

#ifdef SERVER
void of_world_send_curr_map(int cn)
{
    if (!ServerSystem::isRunningMap()) return;

    REFLECT_PYTHON(World);
    REFLECT_PYTHON(get_curr_map_asset_id);

    send_NotifyAboutCurrentScenario(
        cn,
        boost::python::extract<std::string>(get_curr_map_asset_id()),
        boost::python::extract<std::string>(World.attr("scenario_code"))
    );
}
#endif

void of_world_export_entities(const char *fname)
{
    REFLECT_PYTHON(get_curr_map_prefix);
    const char *prefix = boost::python::extract<const char*>(get_curr_map_prefix());
    char buf[512];
    snprintf(
        buf, sizeof(buf),
        "%s%cdata%c%s%c%s",
        homedir, PATHDIV, PATHDIV,
        prefix, PATHDIV, fname
    );
    const char *data = lua::engine.exec<const char*>("return of.logent.store.save_entities()");
    if (fileexists(buf, "r"))
    {
        char buff[strlen(buf) + 16];
        snprintf(buff, sizeof(buff), "%s-%i.bak", buf, (int)time(0));
        of_tools_file_copy(buf, buff);
    }

    FILE *f = fopen(buf, "w");
    if  (!f)
    {
        Logging::log(Logging::ERROR, "Cannot open file %s for writing.\n", buf);
        return;
    }
    fputs(data, f);
    fclose(f);
}
