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

namespace world
{
    string curr_map_id = "";

    bool set_map(const char *id) {
#ifdef STANDALONE
        sendf(-1, 1, "ri", N_PREPFORNEWSCENARIO);
        flushserver(true);
#endif
        copystring(curr_map_id, id);

#ifndef STANDALONE
        defformatstring(buf, "map/%s/map", id);
        if (!load_world(buf)) {
            logger::log(logger::ERROR, "Failed to load world!");
            return false;
        }
#else
        identflags |= IDF_OVERRIDDEN | IDF_SAFE;
        lua::call_external("mapscript_run", "s", get_mapfile_path("map.oct"));
        identflags &= ~(IDF_OVERRIDDEN | IDF_SAFE);
        server::resetScenario();
        defformatstring(path, "%sSTANDALONE_READY", homedir);
        FILE *f = fopen(path, "w"); if (f) fclose(f);
        sendf(-1, 1, "ris", N_NOTIFYABOUTCURRENTSCENARIO, curr_map_id);
#endif

        return true;
    }

    static string mapfile_path = "";
    const char *get_mapfile_path(const char *rpath) {
        formatstring(mapfile_path, "media/map/%s/%s", curr_map_id, rpath);
        path(mapfile_path);
        return mapfile_path;
    }
} /* end namespace world */
