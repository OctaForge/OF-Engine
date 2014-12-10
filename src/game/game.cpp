
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"
#include "of_world.h"

extern float rayent(const vec &o, const vec &ray, float radius, int mode, int size, int &orient, int &ent);
extern int enthover;

namespace game
{
    bool haslogicsys = false;

    VAR(useminimap, 0, 0, 1); // do we want the minimap? Set from JS.

    int gamemode = 0;

    int following = -1, followdir = 0;

    gameent *player1 = NULL;         // our client
    vector<gameent *> players;       // other clients
    gameent lastplayerstate;

    void follow(char *arg)
    {
        if(arg[0] ? player1->state==CS_SPECTATOR : following>=0)
        {
            following = arg[0] ? parseplayer(arg) : -1;
            if(following==player1->clientnum) following = -1;
            followdir = 0;
            conoutf("follow %s", following>=0 ? "on" : "off");
        }
    }

    void nextfollow(int dir)
    {
        if(player1->state!=CS_SPECTATOR || players.empty())
        {
            stopfollowing();
            return;
        }
        int cur = following >= 0 ? following : (dir < 0 ? players.length() - 1 : 0);
        loopv(players)
        {
            cur = (cur + dir + players.length()) % players.length();
            if(players[cur])
            {
                if(following<0) conoutf("follow on");
                following = cur;
                followdir = dir;
                return;
            }
        }
        stopfollowing();
    }

    static string clientmap = "";
    const char *getclientmap()
    {
        if (!world::curr_map_id[0]) return clientmap;
        formatstring(clientmap, "map/%s/map", world::curr_map_id);
        return clientmap;
    }

    gameent *spawnstate(gameent *d)              // reset player state not persistent accross spawns
    {
        d->respawn();
        return d;
    }

    void stopfollowing()
    {
        if(following<0) return;
        following = -1;
        followdir = 0;
        conoutf("follow off");
    }

    gameent *followingplayer()
    {
        if(player1->state!=CS_SPECTATOR || following<0) return NULL;
        gameent *target = getclient(following);
        if(target && target->state!=CS_SPECTATOR) return target;
        return NULL;
    }

    gameent *hudplayer()
    {
        if(thirdperson) return player1;
        gameent *target = followingplayer();
        return target ? target : player1;
    }

    void setupcamera()
    {
        gameent *target = followingplayer();
        if(target)
        {
            player1->yaw = target->yaw;    // Kripken: needed?
            player1->pitch = target->state==CS_DEAD ? 0 : target->pitch; // Kripken: needed?
            player1->o = target->o;
            player1->resetinterp();
        }
    }

    bool detachcamera()
    {
        gameent *d = hudplayer();
        return d->state==CS_DEAD;
    }

    bool collidecamera()
    {
        switch(player1->state)
        {
            case CS_EDITING: return false;
            case CS_SPECTATOR: return followingplayer()!=NULL;
        }
        return true;
    }

    VARP(smoothmove, 0, 75, 100);
    VARP(smoothdist, 0, 32, 64);

    void predictplayer(gameent *d, bool move)
    {
        d->o = d->newpos;
        d->yaw = d->newyaw;
        d->pitch = d->newpitch;
        d->roll = d->newroll;
        if(move)
        {
            moveplayer(d, 1, false);
            d->newpos = d->o;
        }
        float k = 1.0f - float(lastmillis - d->smoothmillis)/smoothmove;
        if(k>0)
        {
            d->o.add(vec(d->deltapos).mul(k));
            d->yaw += d->deltayaw*k;
            if(d->yaw<0) d->yaw += 360;
            else if(d->yaw>=360) d->yaw -= 360;
            d->pitch += d->deltapitch*k;
            d->roll += d->deltaroll*k;
        }
    }

    void otherplayers(int curtime)
    {
        loopv(players) if(players[i] && players[i]->uid >= 0) // Need a complete entity for this
        {
            gameent *d = players[i];
            if(d == player1 || d->ai) continue;

            const int lagtime = totalmillis-d->lastupdate;
            if(!lagtime) continue;
            if(lagtime>1000 && d->state==CS_ALIVE)
            {
                d->state = CS_LAGGED;
                continue;
            }

            // Ignore intentions to move, if immobile
            if (!d->can_move)
                d->turn_move = d->move = d->look_updown_move = d->strafe = d->jumping = 0;

            if(d->state==CS_ALIVE || d->state==CS_EDITING)
            {
                crouchplayer(d, 10, false);
                if(smoothmove && d->smoothmillis>0) predictplayer(d, true); // Disable to force server to always move clients
                else moveplayer(d, 1, false);
            }
            else if(d->state==CS_DEAD && lastmillis-d->lastpain<2000) moveplayer(d, 1, true);

            logger::log(logger::INFO, "                                      to %f,%f,%f", d->o.x, d->o.y, d->o.z);
        }
    }

    void moveControlledEntities()
    {
        if (player1)
        {
            bool b;
            lua::pop_external_ret(lua::call_external_ret("entity_is_initialized",
                "p", "b", player1, &b));
            if (b)
            {
                // Ignore intentions to move, if immobile
                if (!player1->can_move)
                    player1->turn_move = player1->move = player1->look_updown_move = player1->strafe = player1->jumping = 0;

//                if(player1->ragdoll && !(player1->anim&ANIM_RAGDOLL)) cleanragdoll(player1); XXX Needed? See below
                crouchplayer(player1, 10, true);
                moveplayer(player1, 10, true); // Disable this to stop play from moving by client command

                logger::log(logger::INFO, "                              moveplayer(): %f,%f,%f.",
                    player1->o.x,
                    player1->o.y,
                    player1->o.z
                );

                swayhudgun(curtime);
            } else
                logger::log(logger::INFO, "Player is not yet initialized, do not run moveplayer() etc.");
        }
        else
            logger::log(logger::INFO, "Player does not yet exist, or scenario not started, do not run moveplayer() etc.");
    }

    void updateworld()        // main game update loop
    {
        logger::log(logger::INFO, "updateworld(?, %d)", curtime);
        INDENT_LOG(logger::INFO);
        if(!curtime)
        {
            gets2c();
            if(player1->clientnum>=0) c2sinfo();
            return;
        }

        bool runWorld = game::scenario_started();
        //===================
        // Run physics
        //===================


        if (runWorld)
        {
            physicsframe();
            game::otherplayers(curtime); // Server doesn't need smooth interpolation of other players
            game::moveControlledEntities();
            loopv(game::players)
            {
                gameent* gameEntity = game::players[i];
                moveragdoll(gameEntity);
            }
            lua::call_external("frame_handle", "ii", curtime, lastmillis);
        }

        //================================================================
        // Get messages - *AFTER* otherplayers, which applies smoothness,
        // and after actions, since gets2c may destroy the engine
        //================================================================

        gets2c();

        //============================================
        // Send network updates, last for least lag
        //============================================

        // clientnum might be -1, if we have yet to get S2C telling us our clientnum, i.e., we are only partially connected
        if(player1->clientnum>=0) c2sinfo(); //player1, // do this last, to reduce the effective frame lag
    }

    void spawnplayer(gameent *d)   // place at random spawn. also used by monsters!
    {
        spawnstate(d);
        d->state = spectator ? CS_SPECTATOR : (d==player1 && editmode ? CS_EDITING : CS_ALIVE);
    }

    // inputs

    void doattack(bool on)
    {
    }

    bool canjump()
    {
        return true; // Handled ourselves elsewhere
    }

    bool cancrouch()
    {
        return true; // Handled ourselves elsewhere
    }

    bool allowmove(physent *d)
    {
        return true; // Handled ourselves elsewhere
    }

    vector<gameent *> clients;

    gameent *newclient(int cn)   // ensure valid entity
    {
        logger::log(logger::DEBUG, "game::newclient: %d", cn);

        if(cn < 0 || cn > max(0xFF, MAXCLIENTS)) // + MAXBOTS))
        {
            neterr("clientnum", false);
            return NULL;
        }

        if(cn == player1->clientnum)
        {
            player1->uid = -5412; // Wipe uid of new client
            return player1;
        }

        while(cn >= clients.length()) clients.add(NULL);

        gameent *d = new gameent;
        d->clientnum = cn;
        assert(clients[cn] == NULL); // XXX FIXME This fails if a player logged in exactly while the server was downloading assets
        clients[cn] = d;
        players.add(d);

        return clients[cn];
    }

    gameent *getclient(int cn)   // ensure valid entity
    {
        if(cn == player1->clientnum) return player1;
        return clients.inrange(cn) ? clients[cn] : NULL;
    }

    void clientdisconnected(int cn, bool notify)
    {
        logger::log(logger::DEBUG, "game::clientdisconnected: %d", cn);

        if(!clients.inrange(cn)) return;
        if(following==cn)
        {
            if(followdir) nextfollow(followdir);
            else stopfollowing();
        }
        gameent *d = clients[cn];
        if(!d) return;
        if(notify && d->name[0]) conoutf("player %s disconnected", colorname(d));
//        removeweapons(d);
        removetrackedparticles(d);
        removetrackeddynlights(d);
        players.removeobj(d);
        DELETEP(clients[cn]);
        cleardynentcache();
    }

    void initclient()
    {
        player1 = spawnstate(new gameent);
        filtertext(player1->name, "unnamed", false, 32);
        players.add(player1);
    }

    void preload() { }; // We use our own preloading system, but need to add the above projectiles etc.

    void startmap(const char *name)   // called just after a map load
    {
//        if(multiplayer(false) && m_sp) { gamemode = 0; conoutf(CON_ERROR, "coop sp not supported yet"); } Kripken
//        clearmovables();
//        clearprojectiles();
//        clearbouncers();
        spawnplayer(player1);
        disablezoom();
//        if(*name) conoutf(CON_GAMEINFO, "\f2game mode is %s", gameserver::modestr(gamemode));

        //execident("mapstart");
    }

    void physicstrigger(physent *d, bool local, int floorlevel, int waterlevel, int material)
    {
        lua::call_external("physics_state_change", "pbiii", d,
            local, floorlevel, waterlevel, material);
    }

    int numdynents()
    {
        return players.length();
    } //+movables.length(); }

    dynent *iterdynents(int i)
    {
        if(i<players.length()) return players[i];
//        i -= players.length();
//        if(i<movables.length()) return (dynent *)movables[i];
        return NULL;
    }

    const char *scriptname(gameent *d)
    {
        static string cns;
        const char *cn;
        int n = lua::call_external_ret("entity_get_attr", "ps", "s",
            d, "character_name", &cn);
        copystring(cns, cn);
        lua::pop_external_ret(n);
        return cns;
    }

    char *colorname(gameent *d, char *name, const char *prefix)
    {
        if(!name) name = (char*)scriptname(d);
        const char* color = (d != player1) ? "" : "\f1";
        static string cname;
        formatstring(cname, "%s%s", color, name);
        return cname;
    }

    void drawhudmodel(gameent *d, int anim, float speed = 0, int base = 0)
    {
        logger::log(logger::WARNING, "Rendering hudmodel is deprecated for now");
    }

    void drawhudgun()
    {
        logger::log(logger::WARNING, "Rendering hudgun is deprecated for now");
    }

    bool needminimap() // you have to enable the minimap inside your map script.
    {
        return (!mainmenu && useminimap);
    }

    float abovegameplayhud()
    {
        return 1650.0f/1800.0f;
    }

    void gameplayhud(int w, int h)
    {
    }

    void particletrack(physent *owner, vec &o, vec &d)
    {
        if(owner->type!=ENT_PLAYER) return;
//        gameent *pl = (gameent *)owner;
        float dist = o.dist(d);
        o = vec(0,0,0); //pl->muzzle;
        if(dist <= 0) d = o;
        else
        {
            vecfromyawpitch(owner->yaw, owner->pitch, 1, 0, d);
            float newdist = raycube(owner->o, d, dist, RAY_CLIPMAT|RAY_ALPHAPOLY);
            d.mul(min(newdist, dist)).add(owner->o);
        }
    }

    void newmap(int size)
    {
        // Generally not used, as we fork emptymap, but useful to clear and resize
    }

    // any data written into this vector will get saved with the map data. Must take care to do own versioning, and endianess if applicable. Will not get called when loading maps from other games, so provide defaults.
    void writegamedata(vector<char> &extras) {}
    void readgamedata(vector<char> &extras) {}

    const char *gameident() { return "game"; }
    const char *defaultmap() { return "login"; }
    const char *savedservers() { return NULL; } //"servers.cfg"; }

    // Dummies

    void parseoptions(vector<const char *> &args)
    {
    }

    const char *getmapinfo()
    {
        return "";
    }

    float clipconsole(float w, float h)
    {
        return 0;
    }

    void loadconfigs()
    {
    }

    bool ispaused() { return false; };

    void dynlighttrack(physent *owner, vec &o, vec &hud)
    {
        return;
    }

    static vec targetpos;
    static extentity *targetextent = NULL;
    static dynent *targetdynent = NULL;

    static void target_intersect_dynamic(vec &from, vec &to, physent *targeter,
    float &dist, dynent *&target) {
        dynent *best = NULL;
        float bdist = 1e16f;
        loopi(numdynents()) {
            dynent *o = iterdynents(i);
            if (!o || o == targeter) continue;
            if (!intersect(o, from, to)) continue;
            float dist = from.dist(o->o);
            if (dist < bdist) {
                best = o;
                bdist = dist;
            }
        }
        dist = bdist;
        target = best;
    }

    static void target_intersect_static(vec &from, vec &to, physent *targeter,
    float &dist, extentity *&target) {
        vec unitv;
        float maxdist = to.dist(from, unitv);
        unitv.div(maxdist);

        vec hitpos;
        int orient, ent;
        dist = rayent(from, unitv, 1e16f, RAY_CLIPMAT|RAY_ALPHAPOLY, 0, orient, ent);

        if (ent != -1)
            target = entities::getents()[ent];
        else {
            target = NULL;
            dist = -1;
        };
    }

    static void target_intersect_closest(vec &from, vec &to, physent *targeter,
    float &dist) {
        const vector<extentity *> &ents = entities::getents();
        if (ents.inrange(enthover)) {
            dist = from.dist(ents[enthover]->o);
            targetextent = ents[enthover];
            targetdynent = NULL;
            return;
        }
        float ddist, sdist;
        target_intersect_dynamic(from, to, targeter, ddist, targetdynent);
        target_intersect_static(from, to, targeter, sdist, targetextent);
        if (!targetextent && !targetdynent) {
            dist = -1;
        } else if (targetdynent && !targetextent) {
            dist = ddist;
        } else if (targetextent && !targetdynent) {
            dist = sdist;
        } else if (sdist < ddist) {
            dist = sdist;
        } else {
            dist = ddist;
        }
    }

    VAR(has_mouse_target, 1, 0, 0);

    void determinetarget(bool force, vec *pos, extentity **extent, dynent **dynent) {
        if (!editmode && !force) {
            targetdynent = NULL;
            targetextent = NULL;
            targetpos = worldpos;
            has_mouse_target = 0;
        } else {
            static long lastcheck = -1;
            if (lastcheck != lastmillis) {
                float dist;
                target_intersect_closest(camera1->o, worldpos, camera1, dist);
                if (!editmode && targetdynent && targetdynent == player1) {
                    vec save = player1->o;
                    player1->o.add(1e16f);
                    target_intersect_closest(camera1->o, worldpos, camera1, dist);
                    player1->o = save;
                }
                has_mouse_target = (targetdynent || targetextent);
                if (has_mouse_target) {
                    vec temp(worldpos);
                    temp.sub(camera1->o);
                    temp.normalize();
                    temp.mul(dist);
                    temp.add(camera1->o);
                    targetpos = temp;
                } else {
                    targetpos = worldpos;
                }
                lastcheck = lastmillis;
            }
        }
        gettarget(pos, extent, dynent);
    }

    void gettarget(vec *pos, extentity **extent, dynent **dynent) {
        if (pos) *pos = targetpos;
        if (extent) *extent = targetextent;
        if (dynent) *dynent = targetdynent;
    }

    CLUAICOMMAND(gettargetent, void *, (), {
        extentity *ext;
        gameent *ent;
        game::determinetarget(true, NULL, &ext, (dynent**)&ent);
        if (ext)
            return (void*)ext;
        else if (ent)
            return (void*)ent;
        return NULL;
    });

    CLUAICOMMAND(gettargetpos, void, (float *v), {
        vec o;
        game::determinetarget(true, &o);
        v[0] = o.x;
        v[1] = o.y;
        v[2] = o.z;
    });
}

