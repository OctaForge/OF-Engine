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
            logger::log(logger::ERROR, "Failed to load world!");
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
            logger::log(logger::ERROR, "Cannot open file %s for writing.",
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
        if (lua::load_file(get_mapscript_filename()))
            fatal("%s", lua_tostring(lua::L, -1));
        lua::push_external("mapscript_gen_env");
        lua_call(lua::L, 0, 1);
        lua_setfenv(lua::L, -2);
        if (lua_pcall(lua::L, 0, 0, 0))
            fatal("%s", lua_tostring(lua::L, -1));
        identflags = oldflags;
    }
} /* end namespace world */

void mpeditvslot(VSlot &ds, int allfaces, selinfo &sel, bool local);

CLUAICOMMAND(edit_cube_create, bool, (int x, int y, int z, int gs), {
    logger::log(logger::DEBUG, "edit_cube_create: %d, %d, %d (%d)",
        x, y, z, gs);

    selinfo sel;

    if ((z - gs) >= 0) {
        sel.o = ivec(x, y, z - gs);
        sel.orient = 5; /* up */
    } else if ((z + gs) < getworldsize()) {
        sel.o = ivec(x, y, z + gs);
        sel.orient = 4; /* down */
    } else {
        return false;
    }

    sel.s = ivec(1, 1, 1);
    sel.grid = gs;

    if (!sel.validate()) return false;
    mpeditface(-1, 1, sel, true);
    return true;
});

typedef selinfo selinfo_t;

CLUAICOMMAND(edit_raw_edit_face, void, (int dir, int mode, selinfo_t &sel,
bool local), {
    mpeditface(dir, mode, sel, local);
});

bool edit_cube_delete(int x, int y, int z, int gs) {
    logger::log(logger::DEBUG, "edit_cube_delete: %d, %d, %d (%d)",
        x, y, z, gs);

    selinfo sel;

    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gs;

    if (!sel.validate()) return false;
    mpdelcube(sel, true);
    return true;
}

CLUAICOMMAND(edit_raw_delete_cube, void, (selinfo_t &sel, bool local), {
    mpdelcube(sel, local);
});

CLUACOMMAND(edit_cube_delete, bool, (int, int, int, int), edit_cube_delete);

CLUAICOMMAND(edit_map_erase, void, (), {
    int hs = getworldsize() / 2;
    loopi(2) loopj(2) loopk(2) edit_cube_delete(i * hs, j * hs, k * hs, hs);
});

CLUAICOMMAND(edit_cube_set_texture, bool, (int x, int y, int z, int gs,
int face, int tex), {
    logger::log(logger::DEBUG, "edit_cube_set_texture: %d, %d, %d (%d, %d, %d)",
        x, y, z, gs, face, tex);    

    if (face < -1 || face > 5) return false;

    selinfo sel;
    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gs;

    sel.orient = face != -1 ? face : 5;

    if (!sel.validate()) return false;
    mpedittex(tex, face == -1, sel, true);
    return true;
});

CLUAICOMMAND(edit_raw_edit_texture, void, (int tex, bool allfaces,
selinfo_t &sel, bool local), {
    mpedittex(tex, allfaces, sel, local);
});

CLUAICOMMAND(edit_cube_set_material, bool, (int x, int y, int z, int gs,
int mat), {
    logger::log(logger::DEBUG, "edit_cube_set_material: %d, %d, %d (%d, %d)",
        x, y, z, gs, mat);

    selinfo sel;
    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gs;

    if (!sel.validate()) return false;
    mpeditmat(mat, 0, sel, true);
    return true;
});

CLUAICOMMAND(edit_raw_edit_material, void, (int mat, selinfo_t &sel,
bool local), {
    mpeditmat(mat, 0, sel, local);
});

CLUAICOMMAND(edit_raw_flip, void, (selinfo_t &sel, bool local), {
    mpflip(sel, local);
});

CLUAICOMMAND(edit_raw_rotate, void, (int cw, selinfo_t &sel, bool local), {
    mprotate(cw, sel, local);
});

CLUAICOMMAND(edit_raw_remip, void, (bool local), mpremip(local););

struct vslot_t {
    int flags;
    int rotation;
    int offset_x, offset_y;
    float scroll_s, scroll_t;
    float scale;
    int layer, decal;
    float alpha_front, alpha_back;
    float r, g, b;
    float refract_scale;
    float refract_r, refract_g, refract_b;
};

enum {
    VFLAG_SCALE = 1 << VSLOT_SCALE,
    VFLAG_ROTATION = 1 << VSLOT_ROTATION,
    VFLAG_OFFSET = 1 << VSLOT_OFFSET,
    VFLAG_SCROLL = 1 << VSLOT_SCROLL,
    VFLAG_LAYER = 1 << VSLOT_LAYER,
    VFLAG_ALPHA = 1 << VSLOT_ALPHA,
    VFLAG_COLOR = 1 << VSLOT_COLOR,
    VFLAG_REFRACT = 1 << VSLOT_REFRACT,
    VFLAG_DECAL = 1 << VSLOT_DECAL
};

CLUAICOMMAND(edit_raw_edit_vslot, void, (const vslot_t &v, bool allfaces,
selinfo_t &sel, bool local), {
    VSlot ds;
    ds.changed = v.flags;
    if (ds.changed & VFLAG_ROTATION)
        ds.rotation = clamp(v.rotation, 0, 5);
    if (ds.changed & VFLAG_OFFSET)
        ds.offset = ivec2(v.offset_x, v.offset_y).max(0);
    if (ds.changed & VFLAG_SCROLL)
        ds.scroll = vec2(v.scroll_s / 1000.0f, v.scroll_t / 1000.0f);
    if (ds.changed & VFLAG_SCALE)
        ds.scale = v.scale <= 0 ? 1 : clamp(v.scale, 1 / 8.0f, 8.0f);
    if (ds.changed & VFLAG_LAYER)
        ds.layer = vslots.inrange(v.layer) ? v.layer : 0;
    if (ds.changed & VFLAG_DECAL)
        ds.decal = vslots.inrange(v.decal) ? v.decal : 0;
    if (ds.changed & VFLAG_ALPHA) {
        ds.alphafront = clamp(v.alpha_front, 0.0f, 1.0f);
        ds.alphaback = clamp(v.alpha_back, 0.0f, 1.0f);
    }
    if (ds.changed & VFLAG_COLOR)
        ds.colorscale = vec(clamp(v.r, 0.0f, 1.0f), clamp(v.g, 0.0f, 1.0f),
        clamp(v.b, 0.0f, 1.0f));
    if (ds.changed & VFLAG_REFRACT) {
        ds.refractscale = clamp(v.refract_scale, 0.0f, 1.0f);
        float r = v.refract_r;
        float g = v.refract_g;
        float b = v.refract_b;
        if (ds.refractscale > 0 && (r > 0 || g > 0 || b > 0)) {
            ds.refractcolor = vec(clamp(r, 0.0f, 1.0f), clamp(g, 0.0f, 1.0f),
                clamp(b, 0.0f, 1.0f));
        } else {
            ds.refractcolor = vec(1, 1, 1);
        }
    }
    mpeditvslot(ds, allfaces, sel, local);
});

#define VSELHDR \
    if (face < -1 || face > 5) return false; \
\
    selinfo sel; \
    sel.o = ivec(x, y, z); \
    sel.s = ivec(1, 1, 1); \
    sel.grid = gs; \
\
    sel.orient = face != -1 ? face : 5;

#define VSELFTR \
    if (!sel.validate()) return false; \
    mpeditvslot(ds, face == -1, sel, true); \
    return true;

CLUAICOMMAND(edit_cube_vrotate, bool, (int x, int y, int z, int gs,
int face, int n), {
    logger::log(logger::DEBUG, "edit_cube_vrotate: %d, %d, %d (%d, %d, %d)",
        x, y, z, gs, face, n);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_ROTATION;
    ds.rotation = clamp(n, 0, 5);
    VSELFTR
});

CLUAICOMMAND(edit_cube_voffset, bool, (int x, int y, int z, int gs,
int face, int ox, int oy), {
    logger::log(logger::DEBUG, "edit_cube_voffset: %d, %d, %d (%d, %d, %d, %d)",
        x, y, z, gs, face, x, y);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_OFFSET;
    ds.offset = ivec2(ox, oy).max(0);
    VSELFTR
});

CLUAICOMMAND(edit_cube_vscroll, bool, (int x, int y, int z, int gs,
int face, float s, float t), {
    logger::log(logger::DEBUG, "edit_cube_vscroll: %d, %d, %d (%d, %d) (%f, %f)",
        x, y, z, gs, face, s, t);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_SCROLL;
    ds.scroll = vec2(s / 1000.0f, t / 1000.0f);
    VSELFTR
});

CLUAICOMMAND(edit_cube_vscale, bool, (int x, int y, int z, int gs,
int face, float scale), {
    logger::log(logger::DEBUG, "edit_cube_vscale: %d, %d, %d (%d, %d) (%f)",
        x, y, z, gs, face, scale);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_SCALE;
    ds.scale = scale <= 0 ? 1 : clamp(scale, 1 / 8.0f, 8.0f);
    VSELFTR
});

CLUAICOMMAND(edit_cube_vlayer, bool, (int x, int y, int z, int gs,
int face, int n), {
    logger::log(logger::DEBUG, "edit_cube_vlayer: %d, %d, %d (%d, %d, %d)",
        x, y, z, gs, face, n);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_LAYER;
    ds.layer = vslots.inrange(n) ? n : 0;
    VSELFTR
});

CLUAICOMMAND(edit_cube_vdecal, bool, (int x, int y, int z, int gs,
int face, int n), {
    logger::log(logger::DEBUG, "edit_cube_vdecal: %d, %d, %d (%d, %d, %d)",
        x, y, z, gs, face, n);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_DECAL;
    ds.decal = vslots.inrange(n) ? n : 0;
    VSELFTR
});

CLUAICOMMAND(edit_cube_valpha, bool, (int x, int y, int z, int gs,
int face, float front, float back), {
    logger::log(logger::DEBUG, "edit_cube_valpha: %d, %d, %d (%d, %d) (%f, %f)",
        x, y, z, gs, face, front, back);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_ALPHA;
    ds.alphafront = clamp(front, 0.0f, 1.0f);
    ds.alphaback = clamp(back, 0.0f, 1.0f);
    VSELFTR
});

CLUAICOMMAND(edit_cube_vcolor, bool, (int x, int y, int z, int gs,
int face, float r, float g, float b), {
    logger::log(logger::DEBUG, "edit_cube_vcolor: %d, %d, %d (%d, %d) "
        "(%f, %f, %f)", x, y, z, gs, face, r, g, b);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_COLOR;
    ds.colorscale = vec(clamp(r, 0.0f, 1.0f), clamp(g, 0.0f, 1.0f),
        clamp(b, 0.0f, 1.0f));
    VSELFTR
});

CLUAICOMMAND(edit_cube_vrefract, bool, (int x, int y, int z, int gs,
int face, float k, float r, float g, float b), {
    logger::log(logger::DEBUG, "edit_cube_vrefract: %d, %d, %d (%d, %d) "
        "(%f, %f, %f)", x, y, z, gs, face, r, g, b);
    VSELHDR
    VSlot ds;
    ds.changed = 1 << VSLOT_REFRACT;
    ds.refractscale = clamp(k, 0.0f, 1.0f);
    if (ds.refractscale > 0 && (r > 0 || g > 0 || b > 0)) {
        ds.refractcolor = vec(clamp(r, 0.0f, 1.0f), clamp(g, 0.0f, 1.0f),
            clamp(b, 0.0f, 1.0f));
    } else {
        ds.refractcolor = vec(1, 1, 1);
    }
    VSELFTR
});

#undef VSELHDR
#undef VSELFTR

int cornert[6][4] = {
    /* 0 */ { 2, 3, 0, 1 },
    /* 1 */ { 3, 2, 1, 0 },
    /* 2 */ { 3, 1, 2, 0 },
    /* 3 */ { 1, 3, 0, 2 },
    /* 4 */ { 0, 1, 2, 3 },
    /* 5 */ { 0, 1, 2, 3 }
};

CLUAICOMMAND(edit_cube_push_corner, bool, (int x, int y, int z, int gs,
int face, int corner, int dir), {
    logger::log(logger::DEBUG, "edit_cube_push_corner: %d, %d, %d (%d, %d, %d, %d)",
        x, y, z, gs, face, corner, dir);
    if (face < 0 || face > 5 || corner < 0 || corner > 3) return false;

    selinfo sel;
    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gs;

    sel.orient = face;
    sel.corner = cornert[face][corner];

    if (!sel.validate()) return false;
    mpeditface(dir, 2, sel, true);
    return true;
});

CLUAICOMMAND(edit_get_world_size, int, (), {
    extern int worldsize;
    return worldsize;
})

typedef cube cube_t;

CLUAICOMMAND(edit_lookup_cube, cube_t*, (int x, int y, int z, int ts,
int *rx, int *ry, int *rz, int *rts), {
    ivec co;
    int rs;
    cube *c = &lookupcube(ivec(x, y, z), ts, co, rs);
    *rx = co.x;
    *ry = co.y;
    *rz = co.z;
    *rts = rs;
    return c;
});

CLUAICOMMAND(edit_lookup_texture, ushort, (int x, int y, int z, int ts,
int face), {
    return lookupcube(ivec(x, y, z), ts).texture[face];
});

CLUAICOMMAND(edit_lookup_material, ushort, (int x, int y, int z, int ts), {
    return lookupcube(ivec(x, y, z), ts).material;
});

CLUAICOMMAND(edit_get_material, int, (float x, float y, float z), {
    return lookupmaterial(vec(x, y, z));
});
