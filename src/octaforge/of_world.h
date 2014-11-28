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
    extern bool loading;

    extern string curr_map_id;
    extern string scenario_code;

    void set_num_expected_entities(int num);
    void trigger_received_entity();

    bool set_map(const char *id);
    bool restart_map();

#ifdef STANDALONE
    void send_curr_map(int cn);
#endif

    void export_ents(const char *fname);
    const char *get_mapfile_path(const char *rpath);
    void run_mapscript();
} /* end namespace world */

#endif
