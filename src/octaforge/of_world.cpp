/*
 * of_world.cpp, version 1
 * World control functions for OctaForge.
 *
 * author: q66 <quaker66@gmail.com>
 * license: see COPYING.txt
 */

#include "cube.h"
#include "of_world.h"
#include "game.h"
#include "engine.h"
#include "client_system.h"

void force_network_flush();
namespace MessageSystem
{
    void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode);
    void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc);
}
using namespace MessageSystem;

namespace world
{
    string curr_map_id = "";
    string scenario_code = "";

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

    bool set_map(const char *id) {
        generate_scenario_code();
#ifdef STANDALONE
        send_PrepareForNewScenario(-1, scenario_code);
        force_network_flush();
#endif
        copystring(curr_map_id, id);

        string buf;
        copystring(buf, id);
        int len = strlen(id);
        assert(len > 7);
        memcpy(buf + len - 7, "/map", 5);
#ifndef STANDALONE
        if (!load_world(buf)) {
            logger::log(logger::ERROR, "Failed to load world!");
            return false;
        }
#else
        identflags |= IDF_OVERRIDDEN;
        if (lua::L) run_mapscript();
        identflags &= ~IDF_OVERRIDDEN;
        server::resetScenario();
        defformatstring(path, "%sSTANDALONE_READY", homedir);
        FILE *f = fopen(path, "w"); if (f) fclose(f);
        server::createluaEntity(-1);
        send_NotifyAboutCurrentScenario(-1, curr_map_id, scenario_code);
#endif

        return true;
    }

    void export_ents(const char *fname) {
        string tmp;
        copystring(tmp, curr_map_id);
        tmp[strlen(curr_map_id) - 7] = '\0';

        defformatstring(buf, "media%c%s%c%s", PATHDIV, tmp, PATHDIV, fname);

        if (fileexists(buf, "r")) {
            defformatstring(buff, "%s-%d.bak", buf, (int)time(0));
            rename(buf, buff);
        }

        stream *f = openutf8file(buf, "w");
        if  (!f) {
            logger::log(logger::ERROR, "Cannot open file %s for writing.",
                buf);
            return;
        }

        const char *data;
        int popn = lua::call_external_ret("entities_save_all", "", "s", &data);
        f->putstring(data);
        lua::pop_external_ret(popn);
        delete f;
    }

    static string mapfile_path = "";
    const char *get_mapfile_path(const char *rpath) {
        string aloc;
        copystring(aloc, curr_map_id);
        aloc[strlen(curr_map_id) - 7] = '\0';

        formatstring(mapfile_path, "media/%s/%s", aloc, rpath);
        path(mapfile_path);
        return mapfile_path;
    }

    void run_mapscript() {
        int oldflags = identflags;
        identflags |= IDF_SAFE;
#ifndef STANDALONE
        execfile(get_mapfile_path("media.cfg"), false);
#endif
        lua::call_external("mapscript_run", "s", get_mapfile_path("map.oct"));
        identflags = oldflags;
    }
} /* end namespace world */
