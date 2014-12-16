/*
 * of_world.h, version 1
 * World control functions for OctaForge (header)
 *
 * author: q66 <quaker66@gmail.com>
 * license: see COPYING.txt
 */

#ifndef OF_WORLD_H
#define OF_WORLD_H

namespace world
{
    extern string curr_map_id;

    bool set_map(const char *id);

    void export_ents(const char *fname);
    const char *get_mapfile_path(const char *rpath);
    void run_mapscript();
} /* end namespace world */

#endif
