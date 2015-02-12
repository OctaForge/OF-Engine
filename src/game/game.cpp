#include "game.h"

extern float rayent(const vec &o, const vec &ray, float radius, int mode, int size, int &orient, int &ent);
extern int enthover;

namespace game
{
    int maptime = 0, maprealtime = 0;
    int lastspawnattempt = 0;

    gameent *player1 = NULL;         // our client
    vector<gameent *> players;       // other clients

    int following = -1;

    VARFP(specmode, 0, 0, 2,
    {
        if(!specmode) stopfollowing();
        else if(following < 0) nextfollow();
    });

    gameent *followingplayer()
    {
        if(player1->state!=CS_SPECTATOR || following<0) return NULL;
        gameent *target = getclient(following);
        if(target && target->state!=CS_SPECTATOR) return target;
        return NULL;
    }

    ICOMMAND(getfollow, "", (),
    {
        gameent *f = followingplayer();
        intret(f ? f->clientnum : -1);
    });

    void stopfollowing()
    {
        if(following<0) return;
        following = -1;
    }

    void follow(char *arg)
    {
        int cn = -1;
        if(arg[0])
        {
            if(player1->state != CS_SPECTATOR) return;
            cn = parseplayer(arg);
            if(cn == player1->clientnum) cn = -1;
        }
        if(cn < 0 && (following < 0 || specmode)) return;
        following = cn;
    }
    COMMAND(follow, "s");

    void nextfollow(int dir)
    {
        if(player1->state!=CS_SPECTATOR) return;
        int cur = following >= 0 ? following : (dir < 0 ? clients.length() - 1 : 0);
        loopv(clients)
        {
            cur = (cur + dir + clients.length()) % clients.length();
            if(clients[cur] && clients[cur]->state!=CS_SPECTATOR)
            {
                following = cur;
                return;
            }
        }
        stopfollowing();
    }
    ICOMMAND(nextfollow, "i", (int *dir), nextfollow(*dir < 0 ? -1 : 1));

    void checkfollow()
    {
        if(player1->state != CS_SPECTATOR)
        {
            if(following >= 0) stopfollowing();
        }
        else
        {
            if(following >= 0)
            {
                gameent *d = clients.inrange(following) ? clients[following] : NULL;
                if(!d || d->state == CS_SPECTATOR) stopfollowing();
            }
            if(following < 0 && specmode) nextfollow();
        }
    }

    const char *getclientmap() { return clientmap; }

    void resetgamestate()
    {
    }

    gameent *spawnstate(gameent *d)              // reset player state not persistent accross spawns
    {
        d->respawn();
        return d;
    }

    gameent *pointatplayer()
    {
        loopv(players) if(players[i] != player1 && intersect(players[i], player1->o, worldpos)) return players[i];
        return NULL;
    }

    gameent *hudplayer()
    {
        if(thirdperson || specmode > 1) return player1;
        gameent *target = followingplayer();
        return target ? target : player1;
    }

    void setupcamera()
    {
        gameent *target = followingplayer();
        if(target)
        {
            player1->yaw = target->yaw;
            player1->pitch = target->state==CS_DEAD ? 0 : target->pitch;
            player1->o = target->o;
            player1->resetinterp();
        }
    }

    bool detachcamera()
    {
        gameent *d = followingplayer();
        if(d) return specmode > 1 || d->state == CS_DEAD;
        return player1->state == CS_DEAD;
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
        loopv(players)
        {
            gameent *d = players[i];
            if(d == player1 || d->ai) continue;

            if(d->state==CS_DEAD && d->ragdoll) moveragdoll(d);

            const int lagtime = totalmillis-d->lastupdate;
            if(!lagtime) continue;
            else if(lagtime>1000 && d->state==CS_ALIVE)
            {
                d->state = CS_LAGGED;
                continue;
            }
            if(d->state==CS_ALIVE || d->state==CS_EDITING)
            {
                crouchplayer(d, 10, false);
                if(smoothmove && d->smoothmillis>0) predictplayer(d, true);
                else moveplayer(d, 1, false);
            }
            else if(d->state==CS_DEAD && !d->ragdoll && lastmillis-d->lastpain<2000) moveplayer(d, 1, true);
        }
    }

    void updateworld()        // main game update loop
    {
        if(!maptime) { maptime = lastmillis; maprealtime = totalmillis; return; }
        if(!curtime) { gets2c(); if(player1->clientnum>=0) c2sinfo(); return; }

        physicsframe();
        otherplayers(curtime);
        moveragdolls();
        if (connected) lua::call_external("frame_handle", "ii", curtime, lastmillis);
        gets2c();
        bool b = false;
        if (connected) lua::call_external_ret("entity_is_initialized", "i", "b",
            player1->clientnum, &b);
        if (b) {
            if(player1->state == CS_DEAD)
            {
                if(player1->ragdoll) moveragdoll(player1);
                else if(lastmillis-player1->lastpain<2000)
                {
                    player1->move = player1->strafe = 0;
                    moveplayer(player1, 10, true);
                }
            }
            else
            {
                if(player1->ragdoll) cleanragdoll(player1);
                crouchplayer(player1, 10, true);
                moveplayer(player1, 10, true);
            }
        }
        if(player1->clientnum>=0) c2sinfo();   // do this last, to reduce the effective frame lag
    }

    void spawnplayer(gameent *d)   // place at random spawn
    {
        spawnstate(d);
        if(d==player1)
        {
            if(editmode) d->state = CS_EDITING;
            else if(d->state != CS_SPECTATOR) d->state = CS_ALIVE;
        }
        else d->state = CS_ALIVE;
        checkfollow();
    }

    VARP(spawnwait, 0, 0, 1000);

    // inputs

    bool allowmove(physent *d)
    {
        return true;
    }

    VARP(hitsound, 0, 0, 1);

    void timeupdate(int secs)
    {
    }

    vector<gameent *> clients;

    gameent *newclient(int cn)   // ensure valid entity
    {
        if(cn < 0 || cn > max(0xFF, MAXCLIENTS))
        {
            neterr("clientnum", false);
            return NULL;
        }

        if(cn == player1->clientnum) return player1;

        while(cn >= clients.length()) clients.add(NULL);
        if(!clients[cn])
        {
            gameent *d = new gameent;
            d->clientnum = cn;
            clients[cn] = d;
            players.add(d);
        }
        return clients[cn];
    }

    gameent *getclient(int cn)   // ensure valid entity
    {
        if(cn == player1->clientnum) return player1;
        return clients.inrange(cn) ? clients[cn] : NULL;
    }

    void clientdisconnected(int cn, bool notify)
    {
        if(!clients.inrange(cn)) return;
        unignore(cn);
        gameent *d = clients[cn];
        if(d)
        {
            if(notify && d->name[0]) conoutf("\f4leave:\f7 %s", colorname(d));
            removetrackedparticles(d);
            removetrackeddynlights(d);
            players.removeobj(d);
            DELETEP(clients[cn]);
            cleardynentcache();
        }
        if(following == cn)
        {
            if(specmode) nextfollow();
            else stopfollowing();
        }
    }

    void clearclients(bool notify)
    {
        loopv(clients) if(clients[i]) clientdisconnected(i, notify);
    }

    void initclient()
    {
        player1 = spawnstate(new gameent);
        filtertext(player1->name, "unnamed", false, false, MAXNAMELEN);
        players.add(player1);
    }

    VARP(showmodeinfo, 0, 1, 1);

    void startgame()
    {
        clearragdolls();

        // reset perma-state
        loopv(players) players[i]->startgame();

        maptime = maprealtime = 0;

        conoutf(CON_GAMEINFO, "\f2game mode is %s", server::modeprettyname(gamemode));

        const char *info = m_valid(gamemode) ? gamemodes[gamemode - STARTGAMEMODE].info : NULL;
        if(showmodeinfo && info) conoutf(CON_GAMEINFO, "\f0%s", info);

        disablezoom();

        execident("mapstart");
    }

    void startmap(const char *name)   // called just after a map load
    {
        if(!m_mp(gamemode)) spawnplayer(player1);
        copystring(clientmap, name ? name : "");

        sendmapinfo();
    }

    const char *getmapinfo()
    {
        return showmodeinfo && m_valid(gamemode) ? gamemodes[gamemode - STARTGAMEMODE].info : NULL;
    }

    const char *getscreenshotinfo()
    {
        return server::modename(gamemode, NULL);
    }

    void physicstrigger(physent *d, bool local, int floorlevel, int waterlevel, int material)
    {
        lua::call_external("physics_state_change", "ibiii", ((gameent *)d)->clientnum,
            local, floorlevel, waterlevel, material);
    }

    void dynentcollide(physent *d, physent *o, const vec &dir)
    {
    }

    int numdynents() { return players.length(); }

    dynent *iterdynents(int i)
    {
        if(i<players.length()) return players[i];
        return NULL;
    }

    bool duplicatename(gameent *d, const char *name = NULL, const char *alt = NULL)
    {
        if(!name) name = d->name;
        if(alt && d != player1 && !strcmp(name, alt)) return true;
        loopv(players) if(d!=players[i] && !strcmp(name, players[i]->name)) return true;
        return false;
    }

    const char *colorname(gameent *d, const char *name, const char * alt, const char *color)
    {
        if(!name) name = alt && d == player1 ? alt : d->name;
        bool dup = !name[0] || duplicatename(d, name, alt);
        if(dup || color[0])
        {
            if(dup) return tempformatstring("\fs%s%s \f5(%d)\fr", color, name, d->clientnum);
            return tempformatstring("\fs%s%s\fr", color, name);
        }
        return name;
    }

    bool needminimap() { return false; }

    void drawicon(int icon, float x, float y, float sz)
    {
        settexture("media/interface/hud/items.png");
        float tsz = 0.25f, tx = tsz*(icon%4), ty = tsz*(icon/4);
        gle::defvertex(2);
        gle::deftexcoord0();
        gle::begin(GL_TRIANGLE_STRIP);
        gle::attribf(x,    y);    gle::attribf(tx,     ty);
        gle::attribf(x+sz, y);    gle::attribf(tx+tsz, ty);
        gle::attribf(x,    y+sz); gle::attribf(tx,     ty+tsz);
        gle::attribf(x+sz, y+sz); gle::attribf(tx+tsz, ty+tsz);
        gle::end();
    }

    float abovegameplayhud(int w, int h)
    {
        switch(hudplayer()->state)
        {
            case CS_EDITING:
            case CS_SPECTATOR:
                return 1;
            default:
                return 1650.0f/1800.0f;
        }
    }

    void drawhudicons(gameent *d)
    {
    }

    void gameplayhud(int w, int h)
    {
        pushhudmatrix();
        hudmatrix.scale(h/1800.0f, h/1800.0f, 1);
        flushhudmatrix();

        if(player1->state==CS_SPECTATOR)
        {
            float pw, ph, tw, th, fw, fh;
            text_boundsf("  ", pw, ph);
            text_boundsf("SPECTATOR", tw, th);
            th = max(th, ph);
            gameent *f = followingplayer();
            text_boundsf(f ? colorname(f) : " ", fw, fh);
            fh = max(fh, ph);
            draw_text("SPECTATOR", w*1800/h - tw - pw, 1650 - th - fh);
            if(f)
            {
                int color = f->state!=CS_DEAD ? 0xFFFFFF : 0x606060;
                if(f->privilege)
                {
                    color = f->privilege>=PRIV_ADMIN ? 0xFF8000 : 0x40FF80;
                    if(f->state==CS_DEAD) color = (color>>1)&0x7F7F7F;
                }
                draw_text(colorname(f), w*1800/h - fw - pw, 1650 - fh, (color>>16)&0xFF, (color>>8)&0xFF, color&0xFF);
            }
            resethudshader();
        }

        gameent *d = hudplayer();
        if(d->state!=CS_EDITING)
        {
            if(d->state!=CS_SPECTATOR) drawhudicons(d);
        }

        pophudmatrix();
    }

    float clipconsole(float w, float h)
    {
        return 0;
    }

    VARP(hitcrosshair, 0, 425, 1000);

    const char *defaultcrosshair(int index)
    {
        return "media/interface/crosshair/default.png";
    }

    int selectcrosshair(vec &col)
    {
        return 0;
    }

    const char *mastermodecolor(int n, const char *unknown)
    {
        return (n>=MM_START && size_t(n-MM_START)<sizeof(mastermodecolors)/sizeof(mastermodecolors[0])) ? mastermodecolors[n-MM_START] : unknown;
    }

    const char *mastermodeicon(int n, const char *unknown)
    {
        return (n>=MM_START && size_t(n-MM_START)<sizeof(mastermodeicons)/sizeof(mastermodeicons[0])) ? mastermodeicons[n-MM_START] : unknown;
    }

    ICOMMAND(servinfomode, "i", (int *i), GETSERVINFOATTR(*i, 0, mode, intret(mode)));
    ICOMMAND(servinfomodename, "i", (int *i),
        GETSERVINFOATTR(*i, 0, mode,
        {
            const char *name = server::modeprettyname(mode, NULL);
            if(name) result(name);
        }));
    ICOMMAND(servinfomastermode, "i", (int *i), GETSERVINFOATTR(*i, 2, mm, intret(mm)));
    ICOMMAND(servinfomastermodename, "i", (int *i),
        GETSERVINFOATTR(*i, 2, mm,
        {
            const char *name = server::mastermodename(mm, NULL);
            if(name) stringret(newconcatstring(mastermodecolor(mm, ""), name));
        }));
    ICOMMAND(servinfotime, "ii", (int *i, int *raw),
        GETSERVINFOATTR(*i, 1, secs,
        {
            secs = clamp(secs, 0, 59*60+59);
            if(*raw) intret(secs);
            else
            {
                int mins = secs/60;
                secs %= 60;
                result(tempformatstring("%d:%02d", mins, secs));
            }
        }));
    ICOMMAND(servinfoicon, "i", (int *i),
        GETSERVINFO(*i, si,
        {
            int mm = si->attr.inrange(2) ? si->attr[2] : MM_INVALID;
            result(si->maxplayers > 0 && si->numplayers >= si->maxplayers ? "serverfull" : mastermodeicon(mm, "serverunk"));
        }));

    const char *gameconfig() { return "config/game.cfg"; }
    const char *savedconfig() { return "config/saved.cfg"; }
    const char *restoreconfig() { return "config/restore.cfg"; }
    const char *defaultconfig() { return "config/default.cfg"; }
    const char *autoexec() { return "config/autoexec.cfg"; }
    const char *savedservers() { return "config/servers.cfg"; }

    void loadconfigs()
    {
        execfile("config/auth.cfg", false);
    }

    bool clientoption(const char *arg) { return false; }

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

    CLUAICOMMAND(gettargetent, bool, (int *extid, int *dynid), {
        extentity *ext;
        gameent *ent;
        game::determinetarget(true, NULL, &ext, (dynent**)&ent);
        if (ext) {
            *extid = ext->uid;
            *dynid = -1;
            return true;
        } else if (ent) {
            *extid = -1;
            *dynid = ent->clientnum;
            return true;
        }
        return false;
    });

    CLUAICOMMAND(gettargetpos, void, (float *v), {
        vec o;
        game::determinetarget(true, &o);
        v[0] = o.x;
        v[1] = o.y;
        v[2] = o.z;
    });

    void particletrack(physent *owner, vec &o, vec &d)
    {
    }

    void dynlighttrack(physent *owner, vec &o, vec &hud)
    {
    }

    float intersectdist = 1e16f;

    bool intersect(dynent *d, const vec &from, const vec &to, float margin, float &dist)   // if lineseg hits entity bounding box
    {
        vec bottom(d->o), top(d->o);
        bottom.z -= d->eyeheight + margin;
        top.z += d->aboveeye + margin;
        return linecylinderintersect(from, to, bottom, top, d->radius + margin, dist);
    }
}

