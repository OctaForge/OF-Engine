
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "message_system.h"

#include "of_localserver.h"
#include "of_world.h"

extern int enthover;
extern int freecursor, freeeditcursor;

namespace game
{
    extern int smoothmove, smoothdist;

    int lastping = 0; // Kripken: Last time we sent out a ping

    bool connected = false, remote = false;

    bool spectator = false;

    void parsemessages(int cn, gameent *d, ucharbuf &p);

    void initclientnet()
    {
    }

    int needclipboard = -1;

    void sendclipboard()
    {
        uchar *outbuf = NULL;
        int inlen = 0, outlen = 0;
        if(!packeditinfo(localedit, inlen, outbuf, outlen))
        {
            outbuf = NULL;
            inlen = outlen = 0;
        }
        packetbuf p(16 + outlen, ENET_PACKET_FLAG_RELIABLE);
        putint(p, N_CLIPBOARD);
        putint(p, inlen);
        putint(p, outlen);
        if(outlen > 0) p.put(outbuf, outlen);
        sendclientpacket(p.finalize(), 1);
        needclipboard = -1;
    }

    void gameconnect(bool _remote)
    {
        connected = true;
        remote = _remote;
    }

    void gamedisconnect(bool cleanup)
    {
        logger::log(logger::DEBUG, "client.h: gamedisconnect()");
        connected = false;
        player1->clientnum = -1;
        if(editmode) toggleedit();
        player1->lifesequence = 0;
        spectator = false;
//        loopv(players) clientdisconnected(i, false); Kripken: When we disconnect, we should shut down anyhow...
        logger::log(logger::WARNING, "Not doing normal Sauer disconnecting of other clients");

        ClientSystem::onDisconnect();

        if (player->ragdoll)
            cleanragdoll(player);
    }


    bool allowedittoggle()
    {
        if(editmode) return true;
        if (!ClientSystem::isAdmin())
        {
            conoutf("You are not authorized to enter edit mode\r\n");
            return false;
        }

        return true;
    }

    void edittoggled(bool on)
    {
        addmsg(N_EDITMODEC2S, "ri", on ? 1 : 0);
        disablezoom();
        enthover = -1; // Would be nice if sauer did this, but it doesn't... so without it you still hover on a nonseen edit ent
    }

    int parseplayer(const char *arg)
    {
        char *end;
        int n = strtol(arg, &end, 10);
        if(*arg && !*end)
        {
            if(n!=player1->clientnum && !players.inrange(n)) return -1;
            return n;
        }
        // try case sensitive first
        loopi(numdynents())
        {
            gameent *o = (gameent *)iterdynents(i);
            if(o && !strcmp(arg, o->name)) return o->clientnum;
        }
        // nothing found, try case insensitive
        loopi(numdynents())
        {
            gameent *o = (gameent *)iterdynents(i);
            if(o && !strcasecmp(arg, o->name)) return o->clientnum;
        }
        return -1;
    }

    void togglespectator(int val, const char *who)
    {
        if(!remote) return;
        int i = who[0] ? parseplayer(who) : player1->clientnum;
        if(i>=0) addmsg(N_SPECTATOR, "rii", i, val);
    }

    // collect c2s messages conveniently
    vector<uchar> messages;
    int messagecn = -1, messagereliable = false;

    bool addmsg(int type, const char *fmt, ...)
    {
        logger::log(logger::INFO, "Client: ADDMSG: adding a message of type %d", type);

        if(!connected) return false;
        static uchar buf[MAXTRANS];
        ucharbuf p(buf, sizeof(buf));
        putint(p, type);
        int numi = 1, numf = 0, nums = 0, mcn = -1;
        bool reliable = false;
        if(fmt)
        {
            va_list args;
            va_start(args, fmt);
            while(*fmt) switch(*fmt++)
            {
                case 'r': reliable = true; break;
                case 'c':
                {
                    gameent *d = va_arg(args, gameent *);
                    mcn = !d || d == player1 ? -1 : d->clientnum;
                    break;
                }
                case 'v':
                {
                    int n = va_arg(args, int);
                    int *v = va_arg(args, int *);
                    loopi(n) putint(p, v[i]);
                    numi += n;
                    break;
                }

                case 'i':
                {
                    int n = isdigit(*fmt) ? *fmt++-'0' : 1;
                    loopi(n) putint(p, va_arg(args, int));
                    numi += n;
                    break;
                }
                case 'f':
                {
                    int n = isdigit(*fmt) ? *fmt++-'0' : 1;
                    loopi(n) putfloat(p, (float)va_arg(args, double));
                    numf += n;
                    break;
                }
                case 's': sendstring(va_arg(args, const char *), p); nums++; break;
            }
            va_end(args);
        }
        int num = nums || numf ? 0 : numi, msgsize = server::msgsizelookup(type);
        // Kripken: ignore message sizes for non-sauer messages, i.e., ones we added
        if((type & 0xFF) == type && msgsize && num!=msgsize) { fatal("inconsistent msg size for %d (%d != %d)", type, num, msgsize); }
        if(reliable) messagereliable = true;
        if(mcn != messagecn)
        {
            static uchar mbuf[16];
            ucharbuf m(mbuf, sizeof(mbuf));
            putint(m, N_FROMAI);
            putint(m, mcn);
            messages.put(mbuf, m.length());
            messagecn = mcn;
        }
        messages.put(buf, p.length());
        return true;
    }

    CLUAICOMMAND(msg_add, bool, (int type, const char *fmt, ...), {
        logger::log(logger::INFO, "client: addmsg: adding a scripting message of type %d", type);
        if (!connected) return false;
        static uchar buf[MAXTRANS];
        ucharbuf p(buf, sizeof(buf));
        putint(p, type);
        int numi = 1;
        int numf = 0;
        int nums = 0;
        bool reliable = false;
        if (fmt) {
            va_list args;
            va_start(args, fmt);
            while (*fmt) switch (*fmt++) {
                case 'r': reliable = true; break;
                case 'i': {
                    int n = isdigit(*fmt) ? *fmt++-'0' : 1;
                    loopi(n) putint(p, (int)va_arg(args, double));
                    numi += n;
                    break;
                }
                case 'f': {
                    int n = isdigit(*fmt) ? *fmt++-'0' : 1;
                    loopi(n) putfloat(p, (float)va_arg(args, double));
                    numf += n;
                    break;
                }
                case 's': sendstring(va_arg(args, const char *), p); nums++; break;
            }
            va_end(args);
        }
        int num = nums || numf ? 0 : numi;
        int msgsize = server::msgsizelookup(type);
        if ((type & 0xFF) == type && msgsize && num!=msgsize) { fatal("inconsistent msg size for %d (%d != %d)", type, num, msgsize); }
        if (reliable) messagereliable = true;
        messages.put(buf, p.length());
        return true;
    });

    void toserver(char *text)
    {
        if (ClientSystem::scenarioStarted())
        {
            conoutf(CON_CHAT, "%s:\f0 %s", colorname(player1), text);
            addmsg(N_TEXT, "rcs", player1, text);
        }
    }
    COMMANDN(say, toserver, "C");

    static void sendposition(gameent *d, packetbuf &q)
    {
        putint(q, N_POS);
        putuint(q, d->clientnum);
        // 3 bits phys state, 1 bit life sequence, 2 bits move, 2 bits strafe
        uchar physstate = d->physstate | ((d->lifesequence&1)<<3) | ((d->move&3)<<4) | ((d->strafe&3)<<6);
        q.put(physstate);
        ivec o = ivec(vec(d->o.x, d->o.y, d->o.z-d->eyeheight).mul(DMF));
        uint vel = min(int(d->vel.magnitude()*DVELF), 0xFFFF), fall = min(int(d->falling.magnitude()*DVELF), 0xFFFF);
        // 3 bits position, 1 bit velocity, 3 bits falling, 1 bit material, 1 bit crouching
        uint flags = 0;
        if(o.x < 0 || o.x > 0xFFFF) flags |= 1<<0;
        if(o.y < 0 || o.y > 0xFFFF) flags |= 1<<1;
        if(o.z < 0 || o.z > 0xFFFF) flags |= 1<<2;
        if(vel > 0xFF) flags |= 1<<3;
        if(fall > 0)
        {
            flags |= 1<<4;
            if(fall > 0xFF) flags |= 1<<5;
            if(d->falling.x || d->falling.y || d->falling.z > 0) flags |= 1<<6;
        }
        if((lookupmaterial(d->feetpos())&MATF_CLIP) == MAT_GAMECLIP) flags |= 1<<7;
        if(d->crouching < 0) flags |= 1<<8;
        putuint(q, flags);
        loopk(3)
        {
            q.put(o[k]&0xFF);
            q.put((o[k]>>8)&0xFF);
            if(o[k] < 0 || o[k] > 0xFFFF) q.put((o[k]>>16)&0xFF);
        }
        uint dir = (d->yaw < 0 ? 360 + int(d->yaw)%360 : int(d->yaw)%360) + clamp(int(d->pitch+90), 0, 180)*360;
        q.put(dir&0xFF);
        q.put((dir>>8)&0xFF);
        q.put(clamp(int(d->roll+90), 0, 180));
        q.put(vel&0xFF);
        if(vel > 0xFF) q.put((vel>>8)&0xFF);
        float velyaw, velpitch;
        vectoyawpitch(d->vel, velyaw, velpitch);
        uint veldir = (velyaw < 0 ? 360 + int(velyaw)%360 : int(velyaw)%360) + clamp(int(velpitch+90), 0, 180)*360;
        q.put(veldir&0xFF);
        q.put((veldir>>8)&0xFF);
        if(fall > 0)
        {
            q.put(fall&0xFF);
            if(fall > 0xFF) q.put((fall>>8)&0xFF);
            if(d->falling.x || d->falling.y || d->falling.z > 0)
            {
                float fallyaw, fallpitch;
                vectoyawpitch(d->falling, fallyaw, fallpitch);
                uint falldir = (fallyaw < 0 ? 360 + int(fallyaw)%360 : int(fallyaw)%360) + clamp(int(fallpitch+90), 0, 180)*360;
                q.put(falldir&0xFF);
                q.put((falldir>>8)&0xFF);
            }
        }
    }

    void sendposition(gameent *d, bool reliable)
    {
        if(d->state != CS_ALIVE && d->state != CS_EDITING) return;
        packetbuf q(100, reliable ? ENET_PACKET_FLAG_RELIABLE : 0);
        sendposition(d, q);
        sendclientpacket(q.finalize(), 0);
    }

    void sendmessages(gameent *d)
    {
        packetbuf p(MAXTRANS);
        if(messages.length())
        {
            p.put(messages.getbuf(), messages.length());
            messages.setsize(0);
            if(messagereliable) p.reliable();
            messagereliable = false;
            messagecn = -1;
        }
        if(totalmillis-lastping>250)
        {
            putint(p, N_PING);
            putint(p, totalmillis);
            lastping = totalmillis;
        }
        sendclientpacket(p.finalize(), 1);
    }

    void c2sinfo(bool force) // send update to the server
    {
        static int lastupdate = -1000;

        logger::log(logger::INFO, "c2sinfo: %d,%d", totalmillis, lastupdate);

        if(totalmillis - lastupdate < 40 && !force) return;    // don't update faster than the rate
        lastupdate = totalmillis;

        if (ClientSystem::scenarioStarted())
            sendposition(player1);

        sendmessages(player1);
        flushclient();
    }

    void updatepos(gameent *d)
    {
        const float r = player1->radius+d->radius;
        const float dx = player1->o.x-d->o.x;
        const float dy = player1->o.y-d->o.y;
        const float dz = player1->o.z-d->o.z;
        const float rz = player1->aboveeye+d->eyeheight;
        const float fx = (float)fabs(dx), fy = (float)fabs(dy), fz = (float)fabs(dz);
        if(fx<r && fy<r && fz<rz && player1->state!=CS_SPECTATOR && d->state!=CS_DEAD)
        {
            if(fx<fy) d->o.y += dy<0 ? r-fy : -(r-fy);  // push aside
            else      d->o.x += dx<0 ? r-fx : -(r-fx);
        }
        int lagtime = totalmillis-d->lastupdate;
        if(lagtime)
        {
            if(d->state!=CS_SPAWNING && d->lastupdate) d->plag = (d->plag*5+lagtime)/6;
            d->lastupdate = totalmillis;
        }
    }

    void parsepositions(ucharbuf &p)
    {
        int type;
        while(p.remaining()) switch(type = getint(p))
        {
            case N_POS:                        // position of another client
            {
                int cn = getuint(p), physstate = p.get(), flags = getuint(p);
                vec o, vel, falling;
                float yaw, pitch, roll;
                loopk(3)
                {
                    int n = p.get(); n |= p.get()<<8; if(flags&(1<<k)) { n |= p.get()<<16; if(n&0x800000) n |= -1<<24; }
                    o[k] = n/DMF;
                }
                int dir = p.get(); dir |= p.get()<<8;
                yaw = dir%360;
                pitch = clamp(dir/360, 0, 180)-90;
                roll = clamp(int(p.get()), 0, 180)-90;
                int mag = p.get(); if(flags&(1<<3)) mag |= p.get()<<8;
                dir = p.get(); dir |= p.get()<<8;
                vecfromyawpitch(dir%360, clamp(dir/360, 0, 180)-90, 1, 0, vel);
                vel.mul(mag/DVELF);
                if(flags&(1<<4))
                {
                    mag = p.get(); if(flags&(1<<5)) mag |= p.get()<<8;
                    if(flags&(1<<6))
                    {
                        dir = p.get(); dir |= p.get()<<8;
                        vecfromyawpitch(dir%360, clamp(dir/360, 0, 180)-90, 1, 0, falling);
                    }
                    else falling = vec(0, 0, -1);
                    falling.mul(mag/DVELF);
                }
                else falling = vec(0, 0, 0);
                int seqcolor = (physstate>>3)&1;
                gameent *d = getclient(cn);
                if(!d || d->lifesequence < 0 || seqcolor!=(d->lifesequence&1) || d->state==CS_DEAD) continue;
                float oldyaw = d->yaw, oldpitch = d->pitch, oldroll = d->roll;
                d->yaw = yaw;
                d->pitch = pitch;
                d->roll = roll;
                d->move = (physstate>>4)&2 ? -1 : (physstate>>4)&1;
                d->strafe = (physstate>>6)&2 ? -1 : (physstate>>6)&1;
                d->crouching = (flags&(1<<8))!=0 ? -1 : abs(d->crouching);
                vec oldpos(d->o);
                if(allowmove(d))
                {
                    d->o = o;
                    d->o.z += d->eyeheight;
                    d->vel = vel;
                    d->falling = falling;
                    d->physstate = physstate&7;
                }
                updatephysstate(d);
                updatepos(d);
                if(smoothmove && d->smoothmillis>=0 && oldpos.dist(d->o) < smoothdist)
                {
                    d->newpos = d->o;
                    d->newyaw = d->yaw;
                    d->newpitch = d->pitch;
                    d->newroll = d->roll;
                    d->o = oldpos;
                    d->yaw = oldyaw;
                    d->pitch = oldpitch;
                    d->roll = oldroll;
                    (d->deltapos = oldpos).sub(d->newpos);
                    d->deltayaw = oldyaw - d->newyaw;
                    if(d->deltayaw > 180) d->deltayaw -= 360;
                    else if(d->deltayaw < -180) d->deltayaw += 360;
                    d->deltapitch = oldpitch - d->newpitch;
                    d->deltaroll = oldroll - d->newroll;
                    d->smoothmillis = lastmillis;
                }
                else d->smoothmillis = 0;
                if(d->state==CS_LAGGED || d->state==CS_SPAWNING) d->state = CS_ALIVE;
                break;
            }

            default:
                neterr("positions-type");
                return;
        }
    }

    void parsepacketclient(int chan, packetbuf &p)   // processes any updates from the server
    {
        if(p.packet->flags&ENET_PACKET_FLAG_UNSEQUENCED) return;

        logger::log(logger::INFO, "Client: Receiving packet, channel: %d", chan);

        switch(chan)
        {   // Kripken: channel 0 is just positions, for as-fast-as-possible position updates. We do not want to change this.
            //          channel 1 is used by essentially all the game logic events
            //          channel 2: a binary file is received, a map or a demo
            case 0:
                parsepositions(p);
                break;

            case 1:
                parsemessages(-1, NULL, p);
                break;

            case 2:
                assert(0);
//                receivefile(p.get_buf(), p.maxlen);
                break;
        }
    }

    SVARP(chat_sound, "olpc/FlavioGaete/Vla_G_Major");

    void parsemessages(int cn, gameent *d, ucharbuf &p) // cn: Sauer's sending client
    {
//        int gamemode = gamemode; Kripken
        static char text[MAXTRANS];
        int type;
//        bool mapchanged = false; Kripken

        while(p.remaining())
        {
          type = getint(p);
          logger::log(logger::INFO, "Client: Parsing a message of type %d", type);
          switch(type)
          { // Kripken: Mangling sauer indentation as little as possible

            case N_CLIENT:
            {
                int cn = getint(p), len = getuint(p);
                ucharbuf q = p.subbuf(len);
                parsemessages(cn, getclient(cn), q);
                break;
            }

            case N_TEXT:
            {
                if(!d) return;
                getstring(text, p);
                filtertext(text, text);
                if (d->state != CS_SPECTATOR) {
                    const vec &o = d->abovehead();
                    lua::call_external("particle_draw_text", "sfffiifi", text,
                        o.x, o.y, o.z, 0x32FF64, 2000, 4.0f, -8);
                }
                if (chat_sound[0])
                    playsound(chat_sound);
                conoutf(CON_CHAT, "%s:\f0 %s", colorname(d), text);
                break;
            }

            case N_CLIPBOARD:
            {
                int cn = getint(p), unpacklen = getint(p), packlen = getint(p);
                gameent *d = getclient(cn);
                ucharbuf q = p.subbuf(max(packlen, 0));
                if(d) unpackeditinfo(d->edit, q.buf, q.maxlen, unpacklen);
                break;
            }
            case N_UNDO:
            case N_REDO:
            {
                int cn = getint(p), unpacklen = getint(p), packlen = getint(p);
                gameent *d = getclient(cn);
                ucharbuf q = p.subbuf(max(packlen, 0));
                if(d) unpackundo(q.buf, q.maxlen, unpacklen);
                break;
            }

            case N_EDITF:              // coop editing messages
            case N_EDITT:
            case N_EDITM:
            case N_FLIP:
            case N_COPY:
            case N_PASTE:
            case N_ROTATE:
            case N_REPLACE:
            case N_DELCUBE:
            case N_EDITVSLOT:
            {
//                if(!d) return; Kripken: We can get edit commands from the server, which has no 'd' to speak of XXX FIXME - might be buggy

                logger::log(logger::DEBUG, "Edit command intercepted in client.h");

                selinfo sel;
                sel.o.x = getint(p); sel.o.y = getint(p); sel.o.z = getint(p);
                sel.s.x = getint(p); sel.s.y = getint(p); sel.s.z = getint(p);
                sel.grid = getint(p); sel.orient = getint(p);
                sel.cx = getint(p); sel.cxs = getint(p); sel.cy = getint(p), sel.cys = getint(p); // Why "," here and not all ;?
                sel.corner = getint(p);
                ivec moveo;
                switch(type)
                {
                    case N_EDITF: { int dir = getint(p), mode = getint(p); if(sel.validate()) mpeditface(dir, mode, sel, false); break; }
                    case N_EDITT:
                    {
                        int tex = getint(p),
                            allfaces = getint(p);
                        if(p.remaining() < 2) return;
                        int extra = lilswap(*(const ushort *)p.pad(2));
                        if(p.remaining() < extra) return;
                        ucharbuf ebuf = p.subbuf(extra);
                        if(sel.validate()) mpedittex(tex, allfaces, sel, ebuf);
                        break;
                    }
                    case N_EDITM: { int mat = getint(p), filter = getint(p); if(sel.validate()) mpeditmat(mat, filter, sel, false); break; }
                    case N_FLIP: if(sel.validate()) mpflip(sel, false); break;
                    case N_COPY: if(d && sel.validate()) mpcopy(d->edit, sel, false); break;
                    case N_PASTE: if(d && sel.validate()) mppaste(d->edit, sel, false); break;
                    case N_ROTATE: { int dir = getint(p); if(sel.validate()) mprotate(dir, sel, false); break; }
                    case N_REPLACE:
                    {
                        int oldtex = getint(p),
                            newtex = getint(p),
                            insel = getint(p);
                        if(p.remaining() < 2) return;
                        int extra = lilswap(*(const ushort *)p.pad(2));
                        if(p.remaining() < extra) return;
                        ucharbuf ebuf = p.subbuf(extra);
                        if(sel.validate()) mpreplacetex(oldtex, newtex, insel>0, sel, ebuf);
                        break;
                    }
                    case N_DELCUBE: if(sel.validate())mpdelcube(sel, false); break;
                    case N_EDITVSLOT:
                    {
                        int delta = getint(p),
                            allfaces = getint(p);
                        if(p.remaining() < 2) return;
                        int extra = lilswap(*(const ushort *)p.pad(2));
                        if(p.remaining() < extra) return;
                        ucharbuf ebuf = p.subbuf(extra);
                        if(sel.validate()) mpeditvslot(delta, allfaces, sel, ebuf);
                        break;
                    }
                }
                break;
            }
            case N_REMIP:
                if(!d) return;
                conoutf("%s remipped", colorname(d));
                mpremip(false);
                break;
            case N_CALCLIGHT:
                if(!d) return;
                conoutf("%s calced lights", colorname(d));
                mpcalclight(false);
                break;

            case N_PONG:
                // Kripken: Do not let clients know other clients' pings
                player1->ping = (player1->ping*5+lastmillis-getint(p))/6;
//                addmsg(N_CLIENTPING, "i", player1->ping = (player1->ping*5+totalmillis-getint(p))/6);
                break;

            case N_INITCLIENT:
            {
                int cn = getint(p);
                gameent *d = newclient(cn);
                if(!d->name[0])
                  if(needclipboard >= 0)
                    needclipboard++;
                break;
            }

            case N_SERVCMD:
                getstring(text, p);
                break;

            case N_YOURUID: {
                int uid = getint(p);
                logger::log(logger::DEBUG, "Told my unique ID: %d", uid);
                ClientSystem::uniqueId = uid;
                lua::call_external("player_set_uid", "i", uid);
                break;
            }

            case N_LOGINRESPONSE: {
                conoutf("Login was successful.");
                game::addmsg(N_REQUESTCURRENTSCENARIO, "r");
                break;
            }

            case N_PREPFORNEWSCENARIO:
                getstring(text, p);
                assert(lua::call_external("gui_show_message", "ss", "Server",
                    "Map is being prepared on the server, please wait..."));
                ClientSystem::prepareForNewScenario(text);
                break;

            case N_NOTIFYABOUTCURRENTSCENARIO: {
                char sc[MAXTRANS];
                getstring(text, p);
                getstring(sc, p);
                copystring(ClientSystem::currScenarioCode, sc);
                world::set_map(text);
                break;
            }

            case N_ALLACTIVEENTSSENT:
                ClientSystem::finishLoadWorld();
                break;

            default:
            {
                logger::log(logger::INFO, "Client: Handling a non-typical message: %d", type);
                if (!MessageSystem::MessageManager::receive(type, ClientSystem::playerNumber, cn, p))
                {
                    assert(0);
                    neterr("messages-type-client");
                    printf("Quitting\r\n");
                    return;
                }
                break;
            }
          }
        }
    }

    ICOMMAND(map, "s", (char *name), {
        if (!name || !name[0])
            local_server::stop();
        else
            local_server::run(name);
    })

    ICOMMAND(hasmap, "", (), intret(local_server::is_running()));

    void changemap(const char *name, int mode)        // forced map change from the server // Kripken : TODO: Deprecated, Remove
    {
        logger::log(logger::INFO, "Client: Changing map: %s", name);

        mode = 0;
        gamemode = mode;
        if(editmode) toggleedit();
        if((gamemode==1 && !name[0]) || (!load_world(name) && remote))
        {
            emptymap(0, true, name);
        }
    }

    void changemap(const char *name)
    {
        logger::log(logger::INFO, "Client: Requesting map: %s", name);
    }

    void adddynlights()
    {
    }

    void edittrigger(const selinfo &sel, int op, int arg1, int arg2, int arg3, const VSlot *vs)
    {
        if(!ClientSystem::isAdmin())
        {
            logger::log(logger::WARNING, "vartrigger invalid");
            return;
        }

        switch(op)
        {
            case EDIT_FLIP:
            case EDIT_COPY:
            case EDIT_PASTE:
            case EDIT_DELCUBE:
            {
                switch(op)
                {
                    case EDIT_COPY: needclipboard = 0; break;
                    case EDIT_PASTE:
                        if(needclipboard > 0)
                        {
                            c2sinfo(true);
                            sendclipboard();
                        }
                        break;
                }
                addmsg(N_EDITF + op, "ri9i4",
                   sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                   sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner);
                break;
            }
            case EDIT_ROTATE:
            {
                addmsg(N_EDITF + op, "ri9i5",
                   sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                   sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner,
                   arg1);
                break;
            }
            case EDIT_MAT:
            case EDIT_FACE:
            {
                addmsg(N_EDITF + op, "ri9i6",
                   sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                   sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner,
                   arg1, arg2);
                break;
            }
            case EDIT_TEX:
            {
                int tex1 = shouldpacktex(arg1);
                if(addmsg(N_EDITF + op, "ri9i6",
                    sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                    sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner,
                    tex1 ? tex1 : arg1, arg2))
                {
                    messages.pad(2);
                    int offset = messages.length();
                    if(tex1) packvslot(messages, arg1);
                    *(ushort *)&messages[offset-2] = lilswap(ushort(messages.length() - offset));
                }
                break;
            }
            case EDIT_REPLACE:
            {
                int tex1 = shouldpacktex(arg1), tex2 = shouldpacktex(arg2);
                if(addmsg(N_EDITF + op, "ri9i7",
                    sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                    sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner,
                    tex1 ? tex1 : arg1, tex2 ? tex2 : arg2, arg3))
                {
                    messages.pad(2);
                    int offset = messages.length();
                    if(tex1) packvslot(messages, arg1);
                    if(tex2) packvslot(messages, arg2);
                    *(ushort *)&messages[offset-2] = lilswap(ushort(messages.length() - offset));
                }
                break;
            }
            case EDIT_CALCLIGHT:
            case EDIT_REMIP:
            {
                addmsg(N_EDITF + op, "r");
                break;
            }
            case EDIT_VSLOT:
            {
                if(addmsg(N_EDITF + op, "ri9i6",
                    sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                    sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner,
                    arg1, arg2))
                {
                    messages.pad(2);
                    int offset = messages.length();
                    packvslot(messages, vs);
                    *(ushort *)&messages[offset-2] = lilswap(ushort(messages.length() - offset));
                }
                break;
            }
            case EDIT_UNDO:
            case EDIT_REDO:
            {
                uchar *outbuf = NULL;
                int inlen = 0, outlen = 0;
                if(packundo(op, inlen, outbuf, outlen))
                {
                    if(addmsg(N_EDITF + op, "ri2", inlen, outlen)) messages.put(outbuf, outlen);
                    delete[] outbuf;
                }
                break;
            }
        }
    }
};

