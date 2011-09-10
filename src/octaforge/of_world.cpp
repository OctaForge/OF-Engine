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

extern string homedir;

namespace world
{
    bool loading           = false;
    bool has_scenario_code = false;

    static const char *curr_map_id = NULL;
    static       char  scenario_code[37];

    static int num_expected_entities = 0;
    static int num_received_entities = 0;

    void set_num_expected_entities(int num)
    {
        num_expected_entities = num;
        num_received_entities = 0;
    }

    void trigger_received_entity()
    {
        num_received_entities++;

        if (num_expected_entities > 0)
        {
            float val = clamp(float(num_received_entities) / float(num_expected_entities), 0.0f, 1.0f);
            char  buf[32];

            snprintf(buf, sizeof(buf), "received entity %i ...", num_received_entities);
            if (loading)
            {
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
    void generate_scenario_code()
    {
        snprintf(
            scenario_code, sizeof(scenario_code),
            "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        );

        int r = 0;
        char tmp[2];

        for (size_t i = 0; i < (sizeof(scenario_code) - 1); i++)
        {
            char ch = scenario_code[i];
            if  (ch == '4' || ch == '-') continue;

            r = (int)floor(rndscale(1) * 16);
            snprintf(
                tmp, sizeof(tmp), "%x",
                (ch == 'x') ? r : ((r&0x3)|0x8)
            );
            scenario_code[i] = tmp[0];
        }

        has_scenario_code = true;
    }

#ifdef SERVER
    void send_curr_map(int cn)
    {
        if (!has_scenario_code) return;
        send_NotifyAboutCurrentScenario(
            cn,
            curr_map_id,
            scenario_code
        );
    }
#endif

    bool set_map(const char *id)
    {
        generate_scenario_code();

#ifdef SERVER
        send_PrepareForNewScenario(-1, scenario_code);
        force_network_flush();
#endif

        curr_map_id = id;

        char *s = newstring(id);
        s[strlen(s) - 6] = '\0';
        s[strlen(s) - 1] = '/';

        char buf[512];
        snprintf(buf, sizeof(buf), "%smap", s);
        if (!load_world(buf))
        {
            logger::log(logger::ERROR, "Failed to load world!\n");
            return false;
        }
        delete[] s;

#ifdef SERVER
        server::createluaEntity(-1);
        send_curr_map(-1);
#else
        send_RequestPrivateEditMode();
#endif

        return true;
    }

    bool restart_map()
    {
        return set_map(curr_map_id);
    }

    void export_ents(const char *fname)
    {
        char *prefix = newstring(curr_map_id);
        prefix[strlen(prefix) - 6] = '\0';
        prefix[strlen(prefix) - 1] = PATHDIV;

        char buf[512];
        snprintf(
            buf, sizeof(buf),
            "%sdata%c%s%c%s",
            homedir, PATHDIV,
            prefix, PATHDIV, fname
        );
        delete[] prefix;

        const char *data = lua::engine.exec<const char*>("return entity_store.save_entities()");
        if (fileexists(buf, "r"))
        {
            char buff[strlen(buf) + 16];
            snprintf(buff, sizeof(buff), "%s-%i.bak", buf, (int)time(0));
            tools::fcopy(buf, buff);
        }

        FILE *f = fopen(buf, "w");
        if  (!f)
        {
            logger::log(logger::ERROR, "Cannot open file %s for writing.\n", buf);
            return;
        }
        fputs(data, f);
        fclose(f);
    }

    char *get_mapfile_path(const char *rpath)
    {
        char *aloc = newstring(curr_map_id);
        aloc[strlen(aloc) - 7] = '\0';
    
        char buf[512], buff[512];
        snprintf(buf, sizeof(buf), "data%c%s%c%s", PATHDIV, aloc, PATHDIV, rpath);
        if (fileexists(buf, "r"))
        {
            delete[] aloc;
            return newstring(buf);
        }
        snprintf(
            buff, sizeof(buff), "%s%s",
            homedir, buf
        );
        snprintf(buf, sizeof(buf), "%s", buff);
        delete[] aloc;
        return newstring(buf);
    }

    char *get_mapscript_filename() { return get_mapfile_path("map.lua"); }

    void run_mapscript()
    {
        char *name = get_mapscript_filename();
        lua::engine.execf(name);
        delete[] name;
    }

    const char *get_curr_mapid()    { return curr_map_id;   }
    const char *get_scenario_code() { return scenario_code; }

} /* end namespace world */
