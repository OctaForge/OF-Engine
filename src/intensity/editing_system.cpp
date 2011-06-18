
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#ifdef WIN32
    #include <math.h>
#endif

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"
#include "editing_system.h"
#include "targeting.h"
#include "client_system.h"
#include "of_tools.h"
#include "of_entities.h"

#include <set>
#include <algorithm>

// Kripken:
// sel.corner: The face corner the mouse pointer is closest to.
//             For a face from above, 0 is to the origin, and 2 is across from 1 (so, fill one row, then fill
//             the next row, starting from the same side)
// cx, cxs, cy, cys: Seems related to the  difference between selections and cursor hoverings.
//                   Some examples values: 0,2,0,2 for one cube, 0,2,0,4 for 1x2 and 0,4,0,4 for 2x2.
// o: Current cube origin (if mapsize is 1024, then stuff like 0,0,512
// s: Selection size, in cubes. So 1,1,1 is exactly one cube, of the current gridsize
// grid: gridsize. So if mapsize is 1024, and we are on the largest cube size (1/8 of the map), we have 512
// orient: orientation of the face. Values: if 0,0,0 is in the lower left, and the cube extends away from us
//         in the other axis, then:
//              0: facing us (negative X)
//              1: away from us (positive X)
//              2: left (negative Y)
//              3: right (positive Y)
//              4: down (negative Z)
//              5: up (positive Z)
//      (note that orientation/2 is a dimension, one of x,y,z)
// dir: -1 seems to be extrude, +1 to push back into. For pushing edges, 1 is into the cube, -1 is back out
// mode: 1 == extrude/push back cube(s), 2 == push a corner
// local: whether initiated here (if so, notify others)
/////////////////////void mpeditface(int dir, int mode, selinfo &sel, bool local)



// 1.0 is to place it exactly on worldpos
#define FAR_PLACING_FACTOR 0.9

extern int efocus;
extern int orient;

extern bool havesel;
extern selinfo sel;

namespace EditingSystem
{
    bool madeChanges = false;


std::vector<std::string> entityClasses;

void prepareentityclasses()
{
    entityClasses.clear();

    lua::engine.getg("entity_classes").t_getraw("list").call(0, 1);
    logger::log(logger::DEBUG, "prepareentityclasses: Got table of entity classes.");
    LUA_TABLE_FOREACH(lua::engine, {
        entityClasses.push_back(lua::engine.get<const char*>(-1));
    });
    lua::engine.pop(2);
    logger::log(logger::DEBUG, "prepareentityclasses: Done.");
}

bool validateEntityClass(std::string _class)
{
    prepareentityclasses();

    return std::find(entityClasses.begin(), entityClasses.end(), _class) != entityClasses.end();
}

void newEntity(std::string _class, std::string stateData)
{
    /* the positioning is ugly. SPANK SPANK SPANK */
    #ifdef CLIENT
        if (!havesel) return;
        vec o = sel.o.tovec();

        if (stateData == "") stateData = "{}";
        MessageSystem::send_NewEntityRequest(_class.c_str(),
                                             o.x,
                                             o.y,
                                             worldpos.z,
                                             stateData.c_str());
    #else // SERVER
        assert(0); // Where?
    #endif
}

//----------------

int getWorldSize()
{
    return getworldsize();
}

void eraseGeometry()
{
    // Clear out map
    int halfSize = getworldsize()/2;
    loopi(2) loopj(2) loopk(2)
        deleteCube(i*halfSize, j*halfSize, k*halfSize, halfSize);
}

// Ensure that cube coordinates are valid. (x,y,z) can be any values in 0..getworldsize, and gridsize must
// be a cube size appropriate for that, i.e.,
//      512,512,512  ;  64
// is fine, as a cube of size 64 can indeed start there. But
//      1, 1, 1      ;  64
// is invalid, as only a cube of size 1 can be in that position.
bool checkCubeCoords(int x, int y, int z, int gridsize)
{
    int curr = 1;
    while (curr < getworldsize())
    {
        if (gridsize == curr)
            break;
        curr *= 2;
    }
    if (gridsize != curr) return false;

    if (gridsize*(x/gridsize) != x ) return false;
    if (gridsize*(y/gridsize) != y ) return false;
    if (gridsize*(z/gridsize) != z ) return false;

    if (x >= getworldsize()) return false;
    if (y >= getworldsize()) return false;
    if (z >= getworldsize()) return false;

    return true;
}

void createCube(int x, int y, int z, int gridsize)
{
    logger::log(logger::DEBUG, "createCube: %d,%d,%d  --  %d\r\n", x, y, z, gridsize);

    if (!checkCubeCoords(x, y, z, gridsize))
    {
        logger::log(logger::ERROR, "Bad cube coordinates to createCube: %d,%d,%d : %d\r\n", x, y, z, gridsize);
        return;
    }

    // We simulate creating a cube by extruding from another, using mpeditface. This works even if there is no cube there to extrude from.
    selinfo sel;
    // We can either extrude from an imaginary cube from below, or from above. If there is room below, then extrude from there
    if (z - gridsize >= 0)
    {
        sel.o = ivec(x, y, z - gridsize);
        sel.orient = 5; // up
    } else {
        assert(z + gridsize < getworldsize());
        sel.o = ivec(x, y, z + gridsize);
        sel.orient = 4; // down
    }

    sel.s = ivec(1, 1, 1);
    sel.grid = gridsize;

    // Does it matter?
    sel.corner = 1;
    sel.cx = 0;
    sel.cxs = 2;
    sel.cy = 0;
    sel.cys = 2;

    mpeditface(-1, 1, sel, true);
}

void deleteCube(int x, int y, int z, int gridsize)
{
    if (!checkCubeCoords(x, y, z, gridsize))
    {
        logger::log(logger::ERROR, "Bad cube coordinates to createCube: %d,%d,%d : %d\r\n", x, y, z, gridsize);
        return;
    }

    selinfo sel;
    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gridsize;

    // Does it matter?
    sel.orient = 5;
    sel.corner = 1;
    sel.cx = 0;
    sel.cxs = 2;
    sel.cy = 0;
    sel.cys = 2;

    mpdelcube(sel, true);
}

void setCubeTexture(int x, int y, int z, int gridsize, int face, int texture)
{
    if (!checkCubeCoords(x, y, z, gridsize))
    {
        logger::log(logger::ERROR, "Bad cube coordinates to setCubeTexture: %d,%d,%d : %d\r\n", x, y, z, gridsize);
        return;
    }

    assert(face >= -1 && face < 6);

    selinfo sel;
    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gridsize;

    // Does it matter?
    sel.orient = face != -1 ? face : 5;
    sel.corner = 1;
    sel.cx = 0;
    sel.cxs = 2;
    sel.cy = 0;
    sel.cys = 2;

    mpedittex(texture, face == -1, sel, true);
}

void setCubeMaterial(int x, int y, int z, int gridsize, int material)
{
    if (!checkCubeCoords(x, y, z, gridsize))
    {
        logger::log(logger::ERROR, "Bad cube coordinates to setCubeMaterial: %d,%d,%d : %d\r\n", x, y, z, gridsize);
        return;
    }

    selinfo sel;
    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gridsize;

    // Does it matter?
    sel.orient = 5;
    sel.corner = 1;
    sel.cx = 0;
    sel.cxs = 2;
    sel.cy = 0;
    sel.cys = 2;

    mpeditmat(material, 0, sel, true);
}


int cornerTranslators[6][4] =
    {
        /* 0 */ { 2, 3, 0, 1 },
        /* 1 */ { 3, 2, 1, 0 },
        /* 2 */ { 3, 1, 2, 0 },
        /* 3 */ { 1, 3, 0, 2 },
        /* 4 */ { 0, 1, 2, 3 },
        /* 5 */ { 0, 1, 2, 3 }
    };

void pushCubeCorner(int x, int y, int z, int gridsize, int face, int corner, int direction)
{
    if (!checkCubeCoords(x, y, z, gridsize))
    {
        logger::log(logger::ERROR, "Bad cube coordinates to pushCubeCorner: %d,%d,%d : %d\r\n", x, y, z, gridsize);
        return;
    }

    assert(face >= 0 && face < 6);
    assert(corner >= 0 && corner < 4);

    selinfo sel;
    sel.o = ivec(x, y, z);
    sel.s = ivec(1, 1, 1);
    sel.grid = gridsize;

    sel.orient = face;
    sel.corner = cornerTranslators[face][corner];
    sel.cx = 0;
    sel.cxs = 2;
    sel.cy = 0;
    sel.cys = 2;

    mpeditface(direction, 2, sel, true);
}

CLogicEntity *getSelectedEntity()
{
    if (!entities::storage.inrange(efocus)) return NULL;
    extentity& e = *(entities::storage[efocus]);
    return LogicSystem::getLogicEntity(e);
}

}
