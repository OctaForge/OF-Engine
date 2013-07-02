/*
 * of_world.cpp, version 1
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
#include "engine.h"

void force_network_flush();
namespace MessageSystem
{
    void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode);
    void send_RequestPrivateEditMode();
    void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc);
}
using namespace MessageSystem;

namespace world
{
    bool loading = false;

    string curr_map_id = "";
    string scenario_code = "";

    static int num_expected_entities = 0;
    static int num_received_entities = 0;

    void set_num_expected_entities(int num) {
        num_expected_entities = num;
        num_received_entities = 0;
    }

    void trigger_received_entity() {
        num_received_entities++;

        if (num_expected_entities > 0) {
            float val = clamp(float(num_received_entities) / float(num_expected_entities), 0.0f, 1.0f);
            if (loading) {
                defformatstring(buf, "received entity %d ...", num_received_entities);
                renderprogress(val, buf);
            }
        }
    }

    /*
     * Scenario code UUID (version 4) generator for OctaForge
     * Based on a JS snippet from here
     * 
     * http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
     * 
     */
    void generate_scenario_code() {
        copystring(scenario_code, "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx");

        int r = 0;
        string tmp;

        for (char *it = scenario_code; *it; ++it) {
            if  (*it == '4' || *it == '-') continue;

            r = (int)floor(rndscale(1) * 16);
            formatstring(tmp, "%x", (*it == 'x') ? r : ((r&0x3)|0x8));
            *it = tmp[0];
        }
    }

#ifdef SERVER
    void send_curr_map(int cn) {
        if (!scenario_code[0]) return;
        send_NotifyAboutCurrentScenario(cn, curr_map_id, scenario_code);
    }
#endif

    bool set_map(const char *id) {
        generate_scenario_code();

#ifdef SERVER
        send_PrepareForNewScenario(-1, scenario_code);
        force_network_flush();
#endif

        copystring(curr_map_id, id);

        string buf;
        copystring(buf, id);
        int len = strlen(id);
        assert(len > 7);
        memcpy(buf + len - 7, "/map", 5);

        if (!load_world(buf)) {
            logger::log(logger::ERROR, "Failed to load world!\n");
            return false;
        }

#ifdef SERVER
        /* always returns false with -1 - no pop needed */
        server::createluaEntity(-1);
        send_curr_map(-1);
#else
        send_RequestPrivateEditMode();
#endif

        return true;
    }

    bool restart_map() {
        return set_map(curr_map_id);
    }

    void export_ents(const char *fname) {
        string tmp;
        copystring(tmp, curr_map_id);
        tmp[strlen(curr_map_id) - 7] = '\0';

        defformatstring(buf, "%smedia%c%s%c%s", homedir, PATHDIV, tmp,
            PATHDIV, fname);

        lua::push_external("entities_save_all");
        lua_call(lua::L, 0, 1);
        const char *data = lua_tostring(lua::L, -1);
        lua_pop(lua::L, 1);
        if (fileexists(buf, "r")) {
            defformatstring(buff, "%s-%d.bak", buf, (int)time(0));
            tools::fcopy(buf, buff);
        }

        FILE *f = fopen(buf, "w");
        if  (!f) {
            logger::log(logger::ERROR, "Cannot open file %s for writing.\n",
                buf);
            return;
        }
        fputs(data, f);
        fclose(f);
    }

    static string mapfile_path = "";
    const char *get_mapfile_path(const char *rpath) {
        string aloc;
        copystring(aloc, curr_map_id);
        aloc[strlen(curr_map_id) - 7] = '\0';

        defformatstring(buf, "media%c%s%c%s", PATHDIV, aloc, PATHDIV, rpath);
        formatstring(mapfile_path, "%s%s", homedir, buf);

        if (fileexists(mapfile_path, "r")) {
            return mapfile_path;
        }
        copystring(mapfile_path, buf);
        return mapfile_path;
    }

    const char *get_mapscript_filename() {
        return get_mapfile_path("map.lua");
    }

    void run_mapscript() {
        int oldflags = identflags;
        identflags |= IDF_SAFE;
        if (luaL_loadfile(lua::L, get_mapscript_filename()))
            fatal("%s", lua_tostring(lua::L, -1));
        lua::push_external("mapscript_gen_env");
        lua_call(lua::L, 0, 1);
        lua_setfenv(lua::L, -2);
        if (lua_pcall(lua::L, 0, 0, 0))
            fatal("%s", lua_tostring(lua::L, -1));
        identflags = oldflags;
    }
} /* end namespace world */
