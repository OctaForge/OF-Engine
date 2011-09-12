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
    bool loading = false;

    types::string curr_map_id;
    types::string scenario_code;

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
            if (loading)
                renderprogress(val, types::string().format(
                    "received entity %i ...", num_received_entities
                ).buf);
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
        scenario_code = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";

        int r = 0;
        types::string tmp;

        char  *it = scenario_code.first();
        for (; it < scenario_code.last (); it++)
        {
            if  (*it == '4' || *it == '-') continue;

            r = (int)floor(rndscale(1) * 16);
            tmp.format("%x", (*it == 'x') ? r : ((r&0x3)|0x8));
            *it = tmp[0];
        }
    }

#ifdef SERVER
    void send_curr_map(int cn)
    {
        if (scenario_code.is_empty()) return;
        send_NotifyAboutCurrentScenario(
            cn,
            curr_map_id.buf,
            scenario_code.buf
        );
    }
#endif

    bool set_map(const types::string& id)
    {
        generate_scenario_code();

#ifdef SERVER
        send_PrepareForNewScenario(-1, scenario_code.buf);
        force_network_flush();
#endif

        curr_map_id = id;

        types::string s = id.substr(0, id.length - 7);
        s += "/";

        if (!load_world(types::string().format("%smap", s.buf).buf))
        {
            logger::log(logger::ERROR, "Failed to load world!\n");
            return false;
        }

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
        types::string buf = types::string().format(
            "%sdata%c%s%c%s",
            homedir, PATHDIV,
            curr_map_id.substr(0, curr_map_id.length - 7).buf,
            PATHDIV, fname
        );

        const char *data = lua::engine.exec<const char*>("return entity_store.save_entities()");
        if (fileexists(buf.buf, "r"))
        {
            types::string buff = types::string().format(
                "%s-%i.bak", buf.buf, (int)time(0)
            );
            tools::fcopy(buf.buf, buff.buf);
        }

        FILE *f = fopen(buf.buf, "w");
        if  (!f)
        {
            logger::log(logger::ERROR, "Cannot open file %s for writing.\n", buf.buf);
            return;
        }
        fputs(data, f);
        fclose(f);
    }

    types::string get_mapfile_path(const char *rpath)
    {
        types::string aloc = curr_map_id.substr(0, curr_map_id.length - 7);

        types::string buf = types::string().format(
            "data%c%s%c%s", PATHDIV, aloc.buf, PATHDIV, rpath
        );
        if (fileexists(buf.buf, "r")) return buf;

        return types::string().format("%s%s", homedir, buf.buf);
    }

    types::string get_mapscript_filename() { return get_mapfile_path("map.lua"); }

    void run_mapscript()
    {
        lua::engine.execf(get_mapscript_filename().buf);
    }
} /* end namespace world */
