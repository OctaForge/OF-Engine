
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "editing_system.h"
#include "client_system.h"
#include "message_system.h"
#include "network_system.h"
#include "targeting.h"

#ifdef CLIENT
    #include "client_engine_additions.h"
    extern int enthover;
#endif

// Enable to let *server* do physics for players - useful for debugging. Must also be defined in fps.cpp!
#define SERVER_DRIVEN_PLAYERS 0

namespace game
{
    int lastping = 0; // Kripken: Last time we sent out a ping

    bool connected = false, remote = false;

    bool spectator = false;

    void parsemessages(int cn, fpsent *d, ucharbuf &p);

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
#ifdef CLIENT
        if(editmode) toggleedit();
#endif
    }

    void gamedisconnect(bool cleanup)
    {
        logger::log(logger::DEBUG, "client.h: gamedisconnect()\r\n");
//        if(remote) stopfollowing(); Kripken
        connected = false;
        player1->clientnum = -1;
        player1->lifesequence = 0;
        spectator = false;
//        loopv(players) clientdisconnected(i, false); Kripken: When we disconnect, we should shut down anyhow...
        logger::log(logger::WARNING, "Not doing normal Sauer disconnecting of other clients\r\n");

        #ifdef CLIENT
            ClientSystem::onDisconnect();
        #else
            assert(0); // What to do...?
        #endif

        if (player->ragdoll)
            cleanragdoll(player);
    }


    bool allowedittoggle()
    {
#ifdef CLIENT
        if(editmode) return true;
        if (!ClientSystem::isAdmin())
        {
            conoutf("You are not authorized to enter edit mode\r\n");
            return false;
        }

        return true;
#else // SERVER
        assert(0);
        return false;
#endif
    }

    void edittoggled(bool on)
    {
        MessageSystem::send_EditModeC2S(on);
//        addmsg(N_EDITMODE, "ri", on ? 1 : 0);
#ifdef CLIENT
        SETVFN(zoom, -1);
#endif

        #ifdef CLIENT
            enthover = -1; // Would be nice if sauer did this, but it doesn't... so without it you still hover on a nonseen edit ent
        #endif
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
            fpsent *o = (fpsent *)iterdynents(i);
            if(o && !strcmp(arg, o->name)) return o->clientnum;
        }
        // nothing found, try case insensitive
        loopi(numdynents())
        {
            fpsent *o = (fpsent *)iterdynents(i);
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

    void addmsg(int type, const char *fmt, ...)
    {
        logger::log(logger::INFO, "Client: ADDMSG: adding a message of type %d\r\n", type);

        if(!connected) return;
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
                    fpsent *d = va_arg(args, fpsent *);
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
        if (type < INTENSITY_MSG_TYPE_MIN)
        {
            if(msgsize && num!=msgsize) { defformatstring(s)("inconsistent msg size for %d (%d != %d)", type, num, msgsize); fatal(s); }
        }
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
    }

    void toserver(char *text)
    {
#ifdef CLIENT
        if (ClientSystem::scenarioStarted())
#endif // XXX - Need a similar check for NPCs on the server, if/when we have them
        {
            conoutf(CON_CHAT, "%s:\f0 %s", colorname(player1), text);
            addmsg(N_TEXT, "rcs", player1, text);
        }
    }

    void sendposition(fpsent *d, bool reliable)
    {
        logger::log(logger::INFO, "sendposition?, %d)\r\n", curtime);

//        if(d->state==CS_ALIVE || d->state==CS_EDITING) // Kripken: We handle death differently.
//        {
#ifdef CLIENT // If not logged in, or scenario not started, no need to send positions to self server (even can be buggy that way)
        if (ClientSystem::loggedIn && ClientSystem::scenarioStarted())
#else // SERVER
        if (d->uniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID)
#endif
        {
            logger::log(logger::INFO, "sendpacketclient: Sending for client %d: %f,%f,%f\r\n",
                                         d->clientnum, d->o.x, d->o.y, d->o.z);

            // send position updates separately so as to not stall out aiming
            packetbuf q(100, reliable ? ENET_PACKET_FLAG_RELIABLE : 0);

            NetworkSystem::PositionUpdater::QuantizedInfo info;
            info.generateFrom(d);
            info.applyToBuffer(q);

#ifdef CLIENT
    #if (SERVER_DRIVEN_PLAYERS == 0)
            sendclientpacket(q.finalize(), 0, d->clientnum); // Disable this to stop client from updating server with position
    #endif
#else
            localclienttoserver(0, q.finalize(), d->clientnum); // Kripken: Send directly to server, we are its internal headless client
                                            // We feed the correct clientnum here, this is a new functionality of this func
#endif
        }
    }

    void sendmessages(fpsent *d)
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
        sendclientpacket(p.finalize(), 1, d->clientnum);
    }

    void c2sinfo(bool force) // send update to the server
    {
        static int lastupdate = -1000;

        logger::log(logger::INFO, "c2sinfo: %d,%d\r\n", totalmillis, lastupdate);

        if(totalmillis - lastupdate < 33 && !force) return;    // don't update faster than the rate
        lastupdate = totalmillis;

#ifdef CLIENT
        if (ClientSystem::scenarioStarted())
            sendposition(player1);

        sendmessages(player1); // XXX - need to send messages from NPCs?
#else // SERVER
        loopv(players)
        {
            fpsent *d = players[i];
            if (d->serverControlled && d->uniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID)
            {
                sendposition(d);
            }
        }
#endif
        flushclient();
    }

    void updatepos(fpsent *d)
    {
#ifdef CLIENT
        // Only the client cares if other clients overlap him. NPCs on the server don't mind.
        // update the position of other clients in the game in our world
        // don't care if he's in the scenery or other players,
        // just don't overlap with our client

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
#endif
        int lagtime = totalmillis-d->lastupdate;
        if(lagtime)
        {
            if(d->state!=CS_SPAWNING && d->lastupdate) d->plag = (d->plag*5+lagtime)/6;
            d->lastupdate = totalmillis;
        }

        // The client's position has been changed, not by running physics, but by info from the remote
        // client. This counts as if we ran physics, though, since next time we *DO* need to run
        // physics, we don't want to go back any more than this!
        d->lastphysframe = lastmillis;
    }

    void parsepositions(ucharbuf &p)
    {
        int type;
        while(p.remaining()) switch(type = getint(p))
        {
            case N_POS:                        // position of another client
            {
                NetworkSystem::PositionUpdater::QuantizedInfo info;
                info.generateFrom(p);
                info.applyToEntity();

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

        logger::log(logger::INFO, "Client: Receiving packet, channel: %d\r\n", chan);

        switch(chan)
        {   // Kripken: channel 0 is just positions, for as-fast-as-possible position updates. We do not want to change this.
            //          channel 1 is used by essentially all the fps game logic events
            //          channel 2: a binary file is received, a map or a demo
            case 0: 
                parsepositions(p);
                break;

            case 1:
                parsemessages(-1, NULL, p);
                break;

            case 2:
                // kripken: TODO: For now, this should only be for players, not NPCs on the server
                assert(0);
//                receivefile(p.get_buf(), p.maxlen);
                break;
        }
    }

    SVARP(chat_sound, "olpc/FlavioGaete/Vla_G_Major");

    void parsemessages(int cn, fpsent *d, ucharbuf &p) // cn: Sauer's sending client
    {
//        int gamemode = gamemode; Kripken
        types::String text;
        int type;
//        bool mapchanged = false; Kripken

        while(p.remaining())
        {
          type = getint(p);
          logger::log(logger::INFO, "Client: Parsing a message of type %d\r\n", type);
          switch(type)
          { // Kripken: Mangling sauer indentation as little as possible

            case N_CLIENT:
            {
                int cn = getint(p), len = getuint(p);
                ucharbuf q = p.subbuf(len);
                parsemessages(cn, getclient(cn), q); // Only the client needs relayed Sauer messages, not the NPCs.
                break;
            }

            case N_TEXT:
            {
                if(!d) return;
                getstring(text, p);
                /* FIXME: hack attack - add filtering method into the string class */
                filtertext(&text[0], text.get_buf());
#ifdef CLIENT
                if(d->state!=CS_SPECTATOR)
                    particle_textcopy(d->abovehead(), text.get_buf(), PART_TEXT, 2000, 0x32FF64, 4.0f, -8);
                if (chat_sound[0])
                    playsoundname(chat_sound);
#endif
                conoutf(CON_CHAT, "%s:\f0 %s", colorname(d), text.get_buf());
                break;
            }

            case N_CLIPBOARD:
            {
                int cn = getint(p), unpacklen = getint(p), packlen = getint(p);
                fpsent *d = getclient(cn);
                ucharbuf q = p.subbuf(max(packlen, 0));
                if(d) unpackeditinfo(d->edit, q.buf, q.maxlen, unpacklen);
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
            {
//                if(!d) return; Kripken: We can get edit commands from the server, which has no 'd' to speak of XXX FIXME - might be buggy

                logger::log(logger::DEBUG, "Edit command intercepted in client.h\r\n");

                selinfo sel;
                sel.o.x = getint(p); sel.o.y = getint(p); sel.o.z = getint(p);
                sel.s.x = getint(p); sel.s.y = getint(p); sel.s.z = getint(p);
                sel.grid = getint(p); sel.orient = getint(p);
                sel.cx = getint(p); sel.cxs = getint(p); sel.cy = getint(p), sel.cys = getint(p); // Why "," here and not all ;?
                sel.corner = getint(p);
                int dir, mode, mat, filter;
                #ifdef CLIENT
                    int tex, newtex, allfaces, insel;
                #endif
                ivec moveo;
                switch(type)
                {
                    case N_EDITF: dir = getint(p); mode = getint(p); if(sel.validate()) mpeditface(dir, mode, sel, false); break;
                    case N_EDITT:
                        #ifdef CLIENT
                            tex = getint(p); allfaces = getint(p); if(sel.validate()) mpedittex(tex, allfaces, sel, false); break;
                        #else // SERVER
                            getint(p); getint(p); logger::log(logger::DEBUG, "Server ignoring texture change (a)\r\n"); break;
                        #endif
                    case N_EDITM: mat = getint(p); filter = getint(p); if(sel.validate()) mpeditmat(mat, filter, sel, false); break;
                    case N_FLIP: if(sel.validate()) mpflip(sel, false); break;
                    case N_COPY: if(d && sel.validate()) mpcopy(d->edit, sel, false); break;
                    case N_PASTE: if(d && sel.validate()) mppaste(d->edit, sel, false); break;
                    case N_ROTATE: dir = getint(p); if(sel.validate()) mprotate(dir, sel, false); break;
                    case N_REPLACE:
                        #ifdef CLIENT
                            tex = getint(p); newtex = getint(p); insel = getint(p); if(sel.validate()) mpreplacetex(tex, newtex, insel>0, sel, false); break;
                        #else // SERVER
                            getint(p); getint(p); logger::log(logger::DEBUG, "Server ignoring texture change (b)\r\n"); break;
                        #endif
                    case N_DELCUBE: if(sel.validate())mpdelcube(sel, false); break;
                }
                break;
            }
            case N_REMIP:
            {
              #ifdef CLIENT
                if(!d) return;
                conoutf("%s remipped", colorname(d));
                mpremip(false);
              #endif

                break;
            }

            case N_PONG:
#ifdef SERVER
assert(0);
#endif
                // Kripken: Do not let clients know other clients' pings
                player1->ping = (player1->ping*5+lastmillis-getint(p))/6;
//                addmsg(N_CLIENTPING, "i", player1->ping = (player1->ping*5+totalmillis-getint(p))/6);
                break;

            case N_INITCLIENT:
            {
                int cn = getint(p);
                fpsent *d = newclient(cn);
                if(!d->name[0])
                  if(needclipboard >= 0)
                    needclipboard++;
                break;
            }

            case N_SERVCMD:
                getstring(text, p);
                break;

            default:
            {
                logger::log(logger::INFO, "Client: Handling a non-typical message: %d\r\n", type);
#ifdef CLIENT
                if (!MessageSystem::MessageManager::receive(type, ClientSystem::playerNumber, cn, p))
#else
                if (!MessageSystem::MessageManager::receive(type, 0, cn, p)) // Server's internal client is num '0'
#endif
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

    void changemap(const char *name, int mode)        // forced map change from the server // Kripken : TODO: Deprecated, Remove
    {
        logger::log(logger::INFO, "Client: Changing map: %s\r\n", name);

        mode = 0;
        gamemode = mode;
#ifdef CLIENT
        if(editmode) toggleedit();
#endif
        if((gamemode==1 && !name[0]) || (!load_world(name) && remote)) 
        {
            emptymap(0, true, name);
        }
    }

    void changemap(const char *name)
    {
        logger::log(logger::INFO, "Client: Requesting map: %s\r\n", name);
    }
        
    void gotoplayer(const char *arg)
    {
        if(player1->state!=CS_SPECTATOR && player1->state!=CS_EDITING) return;
        int i = parseplayer(arg);
        if(i>=0 && i!=player1->clientnum) 
        {
            fpsent *d = getclient(i);
            if(!d) return;
            player1->o = d->o;
            vec dir;
            vecfromyawpitch(player1->yaw, player1->pitch, 1, 0, dir);
            player1->o.add(dir.mul(-32));
            player1->resetinterp();
        }
    }

    void adddynlights()
    {
        #ifdef CLIENT
            if (GuiControl::isMouselooking()) return;

            if (!TargetingControl::targetLogicEntity
              || TargetingControl::targetLogicEntity->isNone()) return;

            vec color;
            switch (TargetingControl::targetLogicEntity->getType())
            {
                case CLogicEntity::LE_DYNAMIC:
                    color = vec(0.25f, 1.0f, 0.25f);
                    break;
                case CLogicEntity::LE_STATIC:
                    color = vec(0.25f, 0.25f, 1.0f);
                    break;
                default:
                    return;
            }

            vec position = TargetingControl::targetLogicEntity->getOrigin();
            float radius = TargetingControl::targetLogicEntity->getRadius();

            adddynlight(position, radius * 2, color);

            //vec floornorm;
            //float floordist = rayfloor(position, floornorm);
        #endif
    }

    void edittrigger(const selinfo &sel, int op, int arg1, int arg2, int arg3)
    {
#ifdef CLIENT
        if(!ClientSystem::isAdmin())
        {
            logger::log(logger::WARNING, "vartrigger invalid\r\n");
            return;
        }
#endif

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
            case EDIT_TEX:
            {
                addmsg(N_EDITF + op, "ri9i6",
                   sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                   sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner,
                   arg1, arg2);
                break;
            }
            case EDIT_REPLACE:
            {
                addmsg(N_EDITF + op, "ri9i7",
                   sel.o.x, sel.o.y, sel.o.z, sel.s.x, sel.s.y, sel.s.z, sel.grid, sel.orient,
                   sel.cx, sel.cxs, sel.cy, sel.cys, sel.corner,
                   arg1, arg2, arg3);
                break;
            }
            case EDIT_REMIP:
            {
                addmsg(N_EDITF + op, "r");
                break;
            }
        }

        // Note that we made changes
        EditingSystem::madeChanges = true;
    }
};

