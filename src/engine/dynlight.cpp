#include "engine.h"

enum
{
    DL_SHRINK = 1<<0,
    DL_EXPAND = 1<<1,
    DL_FLASH  = 1<<2
};

VARP(dynlightdist, 0, 1024, 10000);

struct dynlight
{
    vec o, hud;
    float radius, initradius, curradius, dist;
    vec color, initcolor, curcolor;
    int fade, peak, expire, flags;
    physent *owner;
    vec dir;
    int spot;

    void calcradius()
    {
        if(fade + peak > 0)
        {
            int remaining = expire - lastmillis;
            if(flags&DL_EXPAND)
                curradius = initradius + (radius - initradius) * (1.0f - remaining/float(fade + peak));
            else if(!(flags&DL_FLASH) && remaining > fade)
                curradius = initradius + (radius - initradius) * (1.0f - float(remaining - fade)/peak);
            else if(flags&DL_SHRINK)
                curradius = (radius*remaining)/fade;
            else curradius = radius;
        }
        else curradius = radius;
    }

    void calccolor()
    {
        if(flags&DL_FLASH || peak <= 0) curcolor = color;
        else
        {
            int peaking = expire - lastmillis - fade;
            if(peaking <= 0) curcolor = color;
            else curcolor.lerp(initcolor, color, 1.0f - float(peaking)/peak);
        }

        float intensity = 1.0f;
        if(fade > 0)
        {
            int fading = expire - lastmillis;
            if(fading < fade) intensity = float(fading)/fade;
        }
        curcolor.mul(intensity);
    }
};

vector<dynlight> dynlights;
vector<dynlight *> closedynlights;

struct dynlight_queued
{
    vec o;
    float radius;
    vec color;
    int fade, peak, flags;
    float initradius;
    vec initcolor;
    physent *owner;
    vec dir;
    int spot;
};
vector<dynlight_queued> dynlight_queue;

void adddynlight(const vec &o, float radius, const vec &color, int fade = 0, int peak = 0, int flags = 0, float initradius = 0, const vec &initcolor = vec(0, 0, 0), physent *owner = NULL, const vec &dir = vec(0, 0, 0), int spot = 0)
{
    if(o.dist(camera1->o) > dynlightdist || radius <= 0) return;

    int insert = 0, expire = fade + peak + lastmillis;
    loopvrev(dynlights) if(expire>=dynlights[i].expire) { insert = i+1; break; }
    dynlight d;
    d.o = d.hud = o;
    d.radius = radius;
    d.initradius = initradius;
    d.color = color;
    d.initcolor = initcolor;
    d.fade = fade;
    d.peak = peak;
    d.expire = expire;
    d.flags = flags;
    d.owner = owner;
    d.dir = dir;
    d.spot = spot;
    dynlights.insert(insert, d);
}

void cleardynlights()
{
    int faded = -1;
    loopv(dynlights) if(lastmillis<dynlights[i].expire) { faded = i; break; }
    if(faded<0) dynlights.setsize(0);
    else if(faded>0) dynlights.remove(0, faded);
}

void removetrackeddynlights(physent *owner)
{
    loopvrev(dynlights) if(owner ? dynlights[i].owner == owner : dynlights[i].owner != NULL) dynlights.remove(i);
}

void updatedynlights()
{
    cleardynlights();
    game::adddynlights();

    loopv(dynlight_queue)
    {
        dynlight_queued &d = dynlight_queue[i];
        adddynlight(d.o, d.radius, d.color, d.fade, d.peak, d.flags, d.initradius, d.initcolor, d.owner, d.dir, d.spot);
    }
    dynlight_queue.setsize(0);

    loopv(dynlights)
    {
        dynlight &d = dynlights[i];
        if(d.owner) game::dynlighttrack(d.owner, d.o, d.hud);
        d.calcradius();
        d.calccolor();
    }
}

int finddynlights()
{
    closedynlights.setsize(0);
    physent e;
    e.type = ENT_CAMERA;
    loopvj(dynlights)
    {
        dynlight &d = dynlights[j];
        if(d.curradius <= 0) continue;
        d.dist = camera1->o.dist(d.o) - d.curradius;
        if(d.dist > dynlightdist || isfoggedsphere(d.curradius, d.o) || pvsoccludedsphere(d.o, d.curradius))
            continue;
        e.o = d.o;
        e.radius = e.xradius = e.yradius = e.eyeheight = e.aboveeye = d.curradius;
        if(!collide(&e, vec(0, 0, 0), 0, false)) continue;

        int insert = 0;
        loopvrev(closedynlights) if(d.dist >= closedynlights[i]->dist) { insert = i+1; break; }
        closedynlights.insert(insert, &d);
    }
    return closedynlights.length();
}

bool getdynlight(int n, vec &o, float &radius, vec &color, vec &dir, int &spot)
{
    if(!closedynlights.inrange(n)) return false;
    dynlight &d = *closedynlights[n];
    o = d.o;
    radius = d.curradius;
    color = d.curcolor;
    spot = d.spot;
    dir = d.dir;
    return true;
}

void queuedynlight(const vec &o, float radius, const vec &color, int fade, int peak, int flags, float initradius, const vec &initcolor, physent *owner, const vec &dir, int spot)
{
    dynlight_queued d;
    d.o = o;
    d.radius = radius;
    d.initradius = initradius;
    d.color = color;
    d.initcolor = initcolor;
    d.fade = fade;
    d.peak = peak;
    d.flags = flags;
    d.owner = owner;
    d.dir = dir;
    d.spot = spot;
    dynlight_queue.add(d);
}

#define DYNLIGHT_GET_OWNER(owner, num) \
    physent *owner = NULL; \
    if (!lua_isnoneornil(L, num)) { \
        lua::push_external(L, "entity_get_attr"); \
        lua_pushvalue(L, num); \
        lua_pushliteral(L, "uid"); \
        lua_call(L, 2, 1); \
        int uid = lua_tointeger(L, -1); lua_pop(L, 1); \
        CLogicEntity *ent = LogicSystem::getLogicEntity(uid); \
        assert(ent && ent->dynamicEntity); \
        owner = ent->dynamicEntity; \
    }

LUAICOMMAND(dynlight_add, {
    float ox = luaL_checknumber(L, 1);
    float oy = luaL_checknumber(L, 2);
    float oz = luaL_checknumber(L, 3);
    float radius = luaL_checknumber(L, 4);
    float r = luaL_checknumber(L, 5);
    float g = luaL_checknumber(L, 6);
    float b = luaL_checknumber(L, 7);
    int fade = luaL_optinteger(L, 8, 0);
    int peak = luaL_optinteger(L, 9, 0);
    int flags = luaL_optinteger(L, 10, 0);
    float initradius = luaL_optnumber(L, 11, 0.0f);
    float ir = luaL_optnumber(L, 12, 0.0f);
    float ig = luaL_optnumber(L, 13, 0.0f);
    float ib = luaL_optnumber(L, 14, 0.0f);
    DYNLIGHT_GET_OWNER(owner, 15);
    queuedynlight(vec(ox, oy, oz), radius, vec(r, g, b), fade, peak, flags,
        initradius, vec(ir, ig, ib), owner, vec(0, 0, 0), 0);
    lua_pushboolean(L, true);
    return 1;
})

LUAICOMMAND(dynlight_add_spot, {
    float ox = luaL_checknumber(L, 1);
    float oy = luaL_checknumber(L, 2);
    float oz = luaL_checknumber(L, 3);
    float dx = luaL_checknumber(L, 4);
    float dy = luaL_checknumber(L, 5);
    float dz = luaL_checknumber(L, 6);
    float radius = luaL_checknumber(L, 7);
    int spot = luaL_checkinteger(L, 8);
    float r = luaL_checknumber(L, 9);
    float g = luaL_checknumber(L, 10);
    float b = luaL_checknumber(L, 11);
    int fade = luaL_optinteger(L, 12, 0);
    int peak = luaL_optinteger(L, 13, 0);
    int flags = luaL_optinteger(L, 14, 0);
    float initradius = luaL_optnumber(L, 15, 0.0f);
    float ir = luaL_optnumber(L, 16, 0.0f);
    float ig = luaL_optnumber(L, 17, 0.0f);
    float ib = luaL_optnumber(L, 18, 0.0f);
    DYNLIGHT_GET_OWNER(owner, 19);
    queuedynlight(vec(ox, oy, oz), radius, vec(r, g, b), fade, peak, flags,
        initradius, vec(ir, ig, ib), owner, vec(dx, dy, dz), spot);
    lua_pushboolean(L, true);
    return 1;
})

#undef DYNLIGHT_GET_OWNER
