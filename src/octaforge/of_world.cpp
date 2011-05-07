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

#ifdef WIN32
#include "wuuid.h"
#else
#include <uuid/uuid.h>
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

/* Defined here */
const char *of_world_curr_map_asset_id = NULL;
const char *of_world_scenario_code     = NULL;

const char *generate_scenario_code()
{
    uuid_t c;
    static char buf[2 * sizeof(c) + 4 + 1];
    uuid_generate(c);
    uuid_unparse (c, buf);
    return buf;
}

bool of_world_set_map(const char *id)
{
    const char *old_scenario_code = of_world_scenario_code;
    if (old_scenario_code)
    {
        while (!strcmp(old_scenario_code, of_world_scenario_code))
            of_world_scenario_code = generate_scenario_code();
    }
    else of_world_scenario_code = generate_scenario_code();

#ifdef SERVER
    send_PrepareForNewScenario(-1, of_world_scenario_code);
    force_network_flush();
#endif

    of_world_curr_map_asset_id = id;

    char *s = strdup(id);
    s[strlen(s) - 6] = '\0';
    s[strlen(s) - 1] = '/';

    char buf[512];
    snprintf(buf, sizeof(buf), "%smap", s);
    if (!load_world(buf))
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
    return of_world_set_map(of_world_curr_map_asset_id);
}

#ifdef SERVER
void of_world_send_curr_map(int cn)
{
    if (!of_world_scenario_code) return;

    send_NotifyAboutCurrentScenario(
        cn,
        of_world_curr_map_asset_id,
        of_world_scenario_code
    );
}
#endif

void of_world_export_entities(const char *fname)
{
    char *prefix = strdup(of_world_curr_map_asset_id);
    prefix[strlen(prefix) - 6] = '\0';
    prefix[strlen(prefix) - 1] = PATHDIV;

    char buf[512];
    snprintf(
        buf, sizeof(buf),
        "%s%cdata%c%s%c%s",
        homedir, PATHDIV, PATHDIV,
        prefix, PATHDIV, fname
    );
    OF_FREE(prefix);

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

char *of_world_get_mapfile_path(const char *rpath)
{
    char *aloc = strdup(of_world_curr_map_asset_id);
    aloc[strlen(aloc) - 7] = '\0';
    
    char buf[512];
    snprintf(buf, sizeof(buf), "data%c%s%c%s", PATHDIV, aloc, PATHDIV, rpath);
    if (fileexists(buf, "r"))
    {
        OF_FREE(aloc);
        return strdup(buf);
    }
    snprintf(
        buf, sizeof(buf), "%s%c%s",
        homedir, PATHDIV, buf
    );
    OF_FREE(aloc);
    return strdup(buf);
}

char *of_world_get_map_script_filename() { return of_world_get_mapfile_path("map.lua"); }

void of_world_run_map_script()
{
    char *name = of_world_get_map_script_filename();
    lua::engine.execf(name);
    OF_FREE(name);
}
