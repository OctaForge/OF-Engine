
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "game.h"

#ifdef WIN32
#include <io.h>
#else
#include <unistd.h>
#define _dup    dup
#define _fileno fileno
#endif

#include "network_system.h"
#include "message_system.h"

#ifdef CLIENT
    #include "client_system.h"
#endif
#include "of_world.h"
#include "of_tools.h"

extern bool should_quit;

extern char *player_class;

namespace server
{
    struct server_entity            // server side version of "entity" type
    {
    };

    struct gamestate
    {
        int state, editstate;
        int lifesequence;

        gamestate() : state(CS_DEAD), editstate(CS_DEAD), lifesequence(-1) {}

        void reset()
        {
            if(state!=CS_SPECTATOR) state = editstate = CS_DEAD;
            lifesequence = 0;
        }
    };

    struct clientinfo
    {
        int clientnum, overflow;

        int         uniqueId; // Kripken: Unique ID in the current module of this client
        bool        isAdmin; // Kripken: Whether we are admins of this map, and can edit it

        string name, team;
        bool spectator, connected, local, timesync, wantsmaster;
        int gameoffset, lastevent;
        gamestate state;
        vector<uchar> position, messages; // Kripken: These are buffers for channels 0 (positions) and 1 (normal messages)
        ENetPacket *clipboard;
        int lastclipboard, needclipboard;

        //! The current scenario being run by the client
        bool runningCurrentScenario;

        clientinfo() : clipboard(NULL) { reset(); }
        ~clientinfo() { cleanclipboard(); }

        void mapchange()
        {
            state.reset();
            timesync = false;
            lastevent = 0;
            overflow = 0;

            runningCurrentScenario = false;
        }

        void cleanclipboard(bool fullclean = true)
        {
            if(clipboard) { if(--clipboard->referenceCount <= 0) enet_packet_destroy(clipboard); clipboard = NULL; }
            if(fullclean) lastclipboard = 0;
        }

        void reset()
        {
            uniqueId = DUMMY_SINGLETON_CLIENT_UNIQUE_ID - 5; // Kripken: Negative, and also different from dummy singleton
            isAdmin = false; // Kripken

            name[0] = team[0] = 0;
            connected = spectator = local = wantsmaster = false;
            position.setsize(0);
            messages.setsize(0);
            needclipboard = 0;
            cleanclipboard();
            mapchange();
        }
    };

    void *newclientinfo()
    {
        return new clientinfo;
    }

    void deleteclientinfo(void *ci)
    {
        // Delete the logic entity
        clientinfo *_ci = (clientinfo*)ci;
        int uniqueId = _ci->uniqueId;

        // If there are entities to remove, remove. For NPCs/bots, however, do not do this - we are in fact being called from there
        // Also do not do this if the uniqueId is negative - it means we are disconnecting this client *before* a lua
        // entity is actually created for them (this can happen in the rare case of a network error causing a disconnect
        // between ENet connection and completing the login process).
        if (lapi::state.state() && !_ci->local && uniqueId >= 0)
            lapi::state.get<lua::Function>("external", "entity_remove")(uniqueId);
        
        delete (clientinfo *)ci;
    } 

    clientinfo *getinfo(int n)
    {
        if(n < MAXCLIENTS) return (clientinfo *)getclientinfo(n);

        return NULL; // TODO: If we want bots
//        n -= MAXCLIENTS;
//        return bots.inrange(n) ? bots[n] : NULL;
    }

    int& getUniqueId(int clientNumber)
    {
        clientinfo *ci = (clientinfo *)getinfo(clientNumber);
        static int DUMMY = -1;
        return (ci ? ci->uniqueId : DUMMY); // Kind of a hack, but we do use this to both set and get... maybe need two methods separate
    }


    struct worldstate
    {
        int uses;
        vector<uchar> positions, messages;
    };

    int gamemode = 0;
    int gamemillis = 0;

    string serverdesc = "";
    string smapname = "";
    enet_uint32 lastsend = 0;

    vector<clientinfo *> connects, clients;
    vector<worldstate *> worldstates;
    bool reliablemessages  = false;
    bool shutdown_if_empty = false;
    bool shutdown_if_idle  = false;
    int  shutdown_idle_interval = 10;

    struct servmode
    {
        virtual ~servmode() {}

        virtual void entergame(clientinfo *ci) {}
        virtual void leavegame(clientinfo *ci, bool disconnecting = false) {}

        virtual void moved(clientinfo *ci, const vec &oldpos, const vec &newpos) {}
        virtual bool canspawn(clientinfo *ci, bool connecting = false) { return true; }
        virtual void spawned(clientinfo *ci) {}
        virtual void died(clientinfo *victim, clientinfo *actor) {}
        virtual bool canchangeteam(clientinfo *ci, const char *oldteam, const char *newteam) { return true; }
        virtual void changeteam(clientinfo *ci, const char *oldteam, const char *newteam) {}
        virtual void initclient(clientinfo *ci, ucharbuf &p, bool connecting) {}
        virtual void update() {}
        virtual void reset(bool empty) {}
        virtual void intermission() {}
    };

    int nonspectators(int exclude = -1)
    {
        int n = 0;
        loopv(clients) if(i!=exclude && clients[i]->state.state!=CS_SPECTATOR) n++;
        return n;
    }

    void spawnstate(clientinfo *ci)
    {
        gamestate &gs = ci->state;
        gs.lifesequence++;
    }

    void sendspawn(clientinfo *ci)
    {
        spawnstate(ci);
    }

    struct arenaservmode : servmode
    {
        int arenaround;

        arenaservmode() : arenaround(0) {}

        bool canspawn(clientinfo *ci, bool connecting = false) 
        { 
            if(connecting && nonspectators(ci->clientnum)<=1) return true;
            return false; 
        }

        void reset(bool empty)
        {
            arenaround = 0;
        }
    
        void update()
        {
        }
    };

    servmode *smode = NULL;

    void *newinfo() { return new clientinfo; }
    void deleteinfo(void *ci) { delete (clientinfo *)ci; } 
    int getUniqueIdFromInfo(void *ci) { return ((clientinfo *)ci)->uniqueId; }

    void sendservmsg(const char *s) { sendf(-1, 1, "ris", N_SERVMSG, s); }

    void resetitems() 
    { 
    }

    void changemap(const char *s, int mode)
    {
    }

    bool duplicatename(clientinfo *ci, char *name)
    {
        if(!name) name = ci->name;
        loopv(clients) if(clients[i]!=ci && !strcmp(name, clients[i]->name)) return true;
        return false;
    }

    char *colorname(clientinfo *ci, char *name = NULL)
    {
        if(!name) name = ci->name;
        if(name[0] && !duplicatename(ci, name)) return name;
        static string cname;
        formatstring(cname)("%s \fs\f5(%d)\fr", name, ci->clientnum);
        return cname;
    }   

    int checktype(int type, clientinfo *ci)
    {
        if(ci && ci->local) return type;
#if 0
        // other message types can get sent by accident if a master forces spectator on someone, so disabling this case for now and checking for spectator state in message handlers
        // spectators can only connect and talk
        static int spectypes[] = { N_INITC2S, N_POS, N_TEXT, N_PING, N_CLIENTPING, N_GETMAP, N_SETMASTER };
        if(ci && ci->state.state==CS_SPECTATOR && !ci->privilege)
        {
            loopi(sizeof(spectypes)/sizeof(int)) if(type == spectypes[i]) return type;
            return -1;
        }
#endif
        // only allow edit messages in coop-edit mode
//        if(type>=N_EDITENT && type<=N_GETMAP && gamemode!=1) return -1; // Kripken: FIXME: For now, allowing editing all the time
        // server only messages
        static const int servtypes[] = { N_SERVINFO, N_INITCLIENT, N_WELCOME, N_MAPRELOAD, N_SERVMSG, N_DAMAGE, N_HITPUSH, N_SHOTFX, N_DIED, N_SPAWNSTATE, N_FORCEDEATH, N_ITEMACC, N_ITEMSPAWN, N_TIMEUP, N_CDIS, N_CURRENTMASTER, N_PONG, N_RESUME, N_BASESCORE, N_BASEINFO, N_BASEREGEN, N_ANNOUNCE, N_SENDDEMOLIST, N_SENDDEMO, N_DEMOPLAYBACK, N_SENDMAP, N_DROPFLAG, N_SCOREFLAG, N_RETURNFLAG, N_RESETFLAG, N_INVISFLAG, N_CLIENT, N_AUTHCHAL, N_INITAI };
        if(ci)
        {
            loopi(sizeof(servtypes)/sizeof(int))
            {
                if(type == servtypes[i])
                {
                    logger::log(logger::ERROR, "checktype has decided to return -1 for %d\r\n", type);
                    return -1;
                }
            }
            if(type < N_EDITENT || type > N_EDITVAR || !editmode) 
            {
                if(++ci->overflow >= 200) return -2;
            }
        }
        return type;
    }

    void cleanworldstate(ENetPacket *packet)
    {
        loopv(worldstates)
        {
            worldstate *ws = worldstates[i];
            if(ws->positions.inbuf(packet->data) || ws->messages.inbuf(packet->data)) ws->uses--;
            else continue;
            if(!ws->uses)
            {
                delete ws;
                worldstates.remove(i);
            }
            break;
        }
    }

    bool buildworldstate()
    {
        static struct { int posoff, msgoff, msglen; } pkt[MAXCLIENTS];
        worldstate &ws = *new worldstate;

        loopv(clients)
        {
            clientinfo &ci = *clients[i];
            ci.overflow = 0;

            if(ci.position.empty()) pkt[i].posoff = -1;
            else
            {
                logger::log(logger::INFO, "SERVER: prepping relayed N_POS data for sending %d, size: %d\r\n", ci.clientnum,
                             ci.position.length());

                pkt[i].posoff = ws.positions.length();
                ws.positions.put(ci.position.getbuf(), ci.position.length());
            }

            if(ci.messages.empty())
                pkt[i].msgoff = -1;
            else
            {
                pkt[i].msgoff = ws.messages.length();
                putint(ws.messages, N_CLIENT);
                putint(ws.messages, ci.clientnum);
                putuint(ws.messages, ci.messages.length());
                ws.messages.put(ci.messages.getbuf(), ci.messages.length());
                pkt[i].msglen = ws.messages.length() - pkt[i].msgoff;
            }
        }

        logger::log(logger::INFO, "SERVER: prepping sum of relayed data for sending, size: %d,%d\r\n", ws.positions.length(), ws.messages.length());

        int psize = ws.positions.length(), msize = ws.messages.length();
        if(psize)
        {
            //recordpacket(0, ws.positions.getbuf(), psize);
            ucharbuf p = ws.positions.reserve(psize);
            p.put(ws.positions.getbuf(), psize);
            ws.positions.addbuf(p);
        }
        if(msize)
        {
            //recordpacket(1, ws.messages.getbuf(), msize);
            ucharbuf p = ws.messages.reserve(msize);
            p.put(ws.messages.getbuf(), msize);
            ws.messages.addbuf(p);
        }
        ws.uses = 0;

        loopv(clients)
        {
            clientinfo &ci = *clients[i];

            logger::log(logger::INFO, "Processing update relaying for %d:%d\r\n", ci.clientnum, ci.uniqueId);

#ifdef SERVER
            // Kripken: FIXME: Send position updates only to real clients, not local ones. For multiple local
            // ones, a single manual sending suffices, which is done to the singleton dummy client
            fpsent* currClient = game::getclient(ci.clientnum);
            if (!currClient) continue; // We have a server client, but no FPSClient client yet, because we have not yet
                                       // finished the player's login, only after which do we create the lua entity,
                                       // which then gets a client added to the FPSClient (and the remote client's FPSClient)
            if (!currClient->serverControlled || ci.uniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) // Send also to singleton dummy client
#endif
            {

                ENetPacket *packet;
                if(psize && (pkt[i].posoff<0 || psize-ci.position.length()>0))
                {
                    // Kripken: Trickery with offsets here prevents relaying back to the same client. Ditto below
                    packet = enet_packet_create(&ws.positions[pkt[i].posoff<0 ? 0 : pkt[i].posoff+ci.position.length()], 
                                                pkt[i].posoff<0 ? psize : psize-ci.position.length(), 
                                                ENET_PACKET_FLAG_NO_ALLOCATE);

                    logger::log(logger::INFO, "Sending positions packet to %d\r\n", ci.clientnum);

                    sendpacket(ci.clientnum, 0, packet); // Kripken: Sending queue of position changes, in channel 0?

                    if(!packet->referenceCount) enet_packet_destroy(packet);
                    else { ++ws.uses; packet->freeCallback = cleanworldstate; }
                }

                if(msize && (pkt[i].msgoff<0 || msize-pkt[i].msglen>0))
                {
                    packet = enet_packet_create(&ws.messages[pkt[i].msgoff<0 ? 0 : pkt[i].msgoff+pkt[i].msglen], 
                                                pkt[i].msgoff<0 ? msize : msize-pkt[i].msglen, 
                                                (reliablemessages ? ENET_PACKET_FLAG_RELIABLE : 0) | ENET_PACKET_FLAG_NO_ALLOCATE);

                    logger::log(logger::INFO, "Sending messages packet to %d\r\n", ci.clientnum);

                    sendpacket(ci.clientnum, 1, packet);
                    if(!packet->referenceCount) enet_packet_destroy(packet);
                    else { ++ws.uses; packet->freeCallback = cleanworldstate; }
                }

            }

            // Kripken: Do this, if we sent to this client or if not - either way. Note that the only reason 
            // Sauer does this in this loop and not elsewhere is so that we can do the index trickery above to prevent
            // relaying back to the same client
            ci.position.setsize(0);
            ci.messages.setsize(0); // Kripken: Client's relayed messages have been processed; clear them
        }

        reliablemessages = false;
        if(!ws.uses) 
        {
            delete &ws;
            return false;
        }
        else 
        {
            worldstates.add(&ws); 
            return true;
        }
    }

    bool sendpackets(bool force)
    {
        if(clients.empty()) return false;
        enet_uint32 curtime = enet_time_get()-lastsend;
        if(curtime<33 && !force) return false; // kripken: Server sends packets at most every 33ms? FIXME: fast rate, we might slow or dynamic this
        bool flush = buildworldstate();
        lastsend += curtime - (curtime%33);
        return flush;
    }

    void sendclipboard(clientinfo *ci)
    {
        if(!ci->lastclipboard || !ci->clipboard) return;
        bool flushed = false;
        loopv(clients)
        {
            clientinfo &e = *clients[i];
            if(e.clientnum != ci->clientnum && e.needclipboard - ci->lastclipboard >= 0)
            {
                if(!flushed) { flushserver(true); flushed = true; }
                sendpacket(e.clientnum, 1, ci->clipboard);
            }
        }
    }

    void parsepacket(int sender, int chan, packetbuf &p)     // has to parse exactly each byte of the packet
    {
        logger::log(logger::INFO, "Server: Parsing packet, %d-%d\r\n", sender, chan);

        if(sender<0 || p.packet->flags&ENET_PACKET_FLAG_UNSEQUENCED) return;
        if(chan==2) // Kripken: Channel 2 is, just like with the client, for file transfers
        {
            assert(0); // We do file transfers completely differently
        }
        if(p.packet->flags&ENET_PACKET_FLAG_RELIABLE) reliablemessages = true;
        types::String text;
        int cn = -1, type;
        clientinfo *ci = sender>=0 ? (clientinfo *)getinfo(sender) : NULL;

        if (ci == NULL) logger::log(logger::ERROR, "ci is null. Sender: %ld\r\n", (long) sender); // Kripken

        // Kripken: QUEUE_MSG puts the incoming message into the out queue. So after the server parses it,
        // it sends it to all *other* clients. This is in tune with the server-as-a-relay-server approach in Sauer.
        // Note that it puts the message in the messages for the current client. This is apparently what prevents
        // the client from getting it back.
        #define QUEUE_MSG { if(ci->uniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID || !ci->local) while(curmsg<p.length()) ci->messages.add(p.buf[curmsg++]); } // Kripken: We need to send messages through the dummy singleton
        #define QUEUE_BUF(body) { \
            if(!ci->local) \
            { \
                curmsg = p.length(); \
                { body; } \
            } \
        }
        #define QUEUE_INT(n) QUEUE_BUF(putint(ci->messages, n))
        #define QUEUE_UINT(n) QUEUE_BUF(putuint(ci->messages, n))
        #define QUEUE_STR(text) QUEUE_BUF(sendstring(text.get_buf(), ci->messages))
        int curmsg;
        while((curmsg = p.length()) < p.maxlen)
        {
          type = checktype(getint(p), ci);  // kripken: checks type is valid for situation
          logger::log(logger::INFO, "Server: Parsing a message of type %d\r\n", type);
          switch(type)
          { // Kripken: Mangling sauer indentation as little as possible
            case N_POS: // Kripken: position update for a client
            {
                NetworkSystem::PositionUpdater::QuantizedInfo info;
                info.generateFrom(p);

                // Kripken: This is a dummy read, we don't do anything with it (but relay)
                // But we do disconnect on errors
                cn = info.clientNumber;
                if(cn<0 || cn>=getnumclients()) // || cn!=sender) - we have multiple NPCs on single server TODO: But apply to clients?
                {
                    disconnect_client(sender, DISC_CN);
                    return;
                }

#ifdef CLIENT
                if ( !isRunningCurrentScenario(sender) ) break; // Silently ignore info from previous scenario
#endif

                //if(!ci->local) // Kripken: We relay even our local clients, PCs need to hear about NPC positions
                // && (ci->state.state==CS_ALIVE || ci->state.state==CS_EDITING)) // Kripken: We handle death differently
                {
                    logger::log(logger::INFO, "SERVER: relaying N_POS data for client %d\r\n", cn);

                    // Modify the info depending on various server parameters
                    //NetworkSystem::PositionUpdater::processServerPositionReception(info);

                    // Queue the info to be sent to the clients
                    int maxLength = p.length()*2 + 100; // Kripken: The server almost always DECREASES the size, but be careful
                    unsigned char* data = new unsigned char[maxLength];
                    ucharbuf temp(data, maxLength);
                    info.applyToBuffer(temp);
                    ci->position.setsize(0);
                    loopk(temp.length()) ci->position.add(temp.buf[k]);
                    delete[] data;
                }
//                if(smode && ci->state.state==CS_ALIVE) smode->moved(ci, oldpos, ci->state.o); // Kripken:Gametype(ctf etc.)-specific stuff
                break;
            }

            case N_TEXT:
            {
                getstring(text, p);
                /* FIXME: hack attack - add filtering method into the string class */
                filtertext(&text[0], text.get_buf());

                if (!lapi::state.state())
                {
                    QUEUE_INT(type);
                    QUEUE_STR(text);
                    break;
                }

                if (!lapi::state.get<lua::Function>(
                    "LAPI", "World", "Events", "text_message"
                ).call<bool>(ci->uniqueId, text))
                {
                    QUEUE_INT(type);
                    QUEUE_STR(text);
                }
                break;
            }

            case N_PING:
                sendf(sender, 1, "i2", N_PONG, getint(p));
                break;

            case N_CLIENTPING:
                getint(p);
//                QUEUE_MSG; // Kripken: Do not let clients know other clients' pings
                break;

            case N_COPY:
                ci->cleanclipboard();
                ci->lastclipboard = totalmillis ? totalmillis : 1;
                goto genericmsg;

            case N_PASTE:
                if(ci->state.state!=CS_SPECTATOR) sendclipboard(ci);
                goto genericmsg;
    
            case N_CLIPBOARD:
            {
                int unpacklen = getint(p), packlen = getint(p); 
                ci->cleanclipboard(false);
                if(ci->state.state==CS_SPECTATOR)
                {
                    if(packlen > 0) p.subbuf(packlen);
                    break;
                }
                if(packlen <= 0 || packlen > (1<<16) || unpacklen <= 0) 
                {
                    if(packlen > 0) p.subbuf(packlen);
                    packlen = unpacklen = 0;
                }
                packetbuf q(32 + packlen, ENET_PACKET_FLAG_RELIABLE);
                putint(q, N_CLIPBOARD);
                putint(q, ci->clientnum);
                putint(q, unpacklen);
                putint(q, packlen); 
                if(packlen > 0) p.get(q.subbuf(packlen).buf, packlen);
                ci->clipboard = q.finalize();
                ci->clipboard->referenceCount++;
                break;
            } 

            /* TODO: expose this */
            case N_SERVCMD:
                getstring(text, p);
                break;

            case -1:
                disconnect_client(sender, DISC_TAGT);
                return;

            case -2:
                disconnect_client(sender, DISC_OVERFLOW);
                return;

            default: genericmsg:
            {
                logger::log(logger::DEBUG, "Server: Handling a non-typical message: %d\r\n", type);
                if (!MessageSystem::MessageManager::receive(type, -1, sender, p))
                {
                    logger::log(logger::DEBUG, "Relaying Sauer protocol message: %d\r\n", type);

                    int size = msgsizelookup(type);
                    if(size<=0) { disconnect_client(sender, DISC_TAGT); return; }
                    loopi(size-1) getint(p);

                    if ( !isRunningCurrentScenario(sender) ) break; // Silently ignore info from previous scenario

                    if(ci && ci->state.state!=CS_SPECTATOR) QUEUE_MSG;

                    logger::log(logger::DEBUG, "Relaying complete\r\n");
                }
                break;
            }
          } // Kripken: Left indentation as per Sauer
        }
    }

    void serverupdate(int _lastmillis, int _totalmillis)
    {
        curtime = _lastmillis - lastmillis;
        gamemillis += curtime;
        lastmillis = _lastmillis;
        totalmillis = _totalmillis;

        if(smode) smode->update();
    }

    bool serveroption(char *arg)
    {
        if(arg[0]=='-') switch(arg[1])
        {
            case 'n': copystring(serverdesc, &arg[2]); return true;
        }
        return false;
    }

    void serverinit()
    {
        smapname[0] = '\0';
        resetitems();
    }
   
    void localconnect(int n)
    {
        clientinfo *ci = (clientinfo *)getinfo(n);
        ci->clientnum = n;
        ci->needclipboard = totalmillis ? totalmillis : 1;
        ci->local = true;

        clients.add(ci);
    }

    void localdisconnect(int n)
    {
        clientinfo *ci = (clientinfo *)getinfo(n);
        if(smode) smode->leavegame(ci, true);
        clients.removeobj(ci);
    }

    void setAdmin(int clientNumber, bool isAdmin)
    {
        logger::log(logger::DEBUG, "setAdmin for client %d\r\n", clientNumber);

        clientinfo *ci = (clientinfo *)getinfo(clientNumber);
        if (!ci) return; // May have been kicked just before now
        ci->isAdmin = isAdmin;

        if (ci->isAdmin && ci->uniqueId >= 0) // If an entity was already created, update it
            lapi::state.get<lua::Function>("external", "entity_get"
            ).call<lua::Table>(ci->uniqueId)["can_edit"] = true;
    }

    bool isAdmin(int clientNumber)
    {
        clientinfo *ci = (clientinfo *)getinfo(clientNumber);
        if (!ci) return false;
        return ci->isAdmin;
    }

    // INTENSITY: Called when logging in, and also when the map restarts (need a new entity).
    // Creates a new lua entity, in the process of which a uniqueId is generated.
    // returns its ref, no need to store it anywhere.
    lua::Table createluaEntity(int cn, const char *_class, const char *uname)
    {
#ifdef CLIENT
        assert(0);
        return lapi::state.wrap<lua::Table>(lua::nil);
#else // SERVER
        // cn of -1 means "all of them"
        if (cn == -1)
        {
            for (int i = 0; i < getnumclients(); i++)
            {
                clientinfo *ci = (clientinfo *)getinfo(i);
                if (!ci) continue;
                if (ci->uniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) continue;
                if (ci->local) continue; // No need for NPCs created during the map script - they already exist

                logger::log(logger::DEBUG, "luaEntities creation: Adding %d\r\n", i);

                createluaEntity(i);
            }
            return lapi::state.wrap<lua::Table>(lua::nil);
        }

        assert(cn >= 0);
        clientinfo *ci = (clientinfo *)getinfo(cn);
        if (!ci)
        {
            logger::log(logger::WARNING, "Asked to create a player entity for %d, but no clientinfo (perhaps disconnected meanwhile)\r\n", cn);
            return lapi::state.wrap<lua::Table>(lua::nil);
        }

        fpsent* fpsEntity = game::getclient(cn);
        if (fpsEntity)
        {
            // Already created an entity
            logger::log(logger::WARNING, "createluaEntity(%d): already have fpsEntity, and hence lua entity. Kicking.\r\n", cn);
            disconnect_client(cn, DISC_KICK);
            return lapi::state.wrap<lua::Table>(lua::nil);
        }

        // Use the PC class, unless told otherwise
        if (!strcmp(_class, "")) _class = player_class;

        logger::log(logger::DEBUG, "Creating player entity: %s, %d", _class, cn);

        int uniqueId = lapi::state.get<lua::Function>(
            "external", "entity_gen_uid"
        ).call<int>();

        // Notify of uniqueId *before* creating the entity, so when the entity is created, player realizes it is them
        // and does initial connection correctly
        if (!ci->local)
            MessageSystem::send_YourUniqueId(cn, uniqueId);

        ci->uniqueId = uniqueId;

        lua::Table t = lapi::state.new_table(0, 1);
        t["cn"] = cn;
        lapi::state.get<lua::Function>("external", "entity_new")(_class, t, uniqueId, true);

        assert(
            lapi::state.get<lua::Function>(
                "external", "entity_get"
            ).call<lua::Table>(uniqueId).get<int>("cn") == cn
        );

        // Add admin status, if relevant
        if (ci->isAdmin)
            lapi::state.get<lua::Function>("external", "entity_get").call<lua::Table>(uniqueId)["can_edit"] = true;

        // Add nickname
        t = lapi::state.get<lua::Function>("external", "entity_get").call<lua::Table>(uniqueId);
        // got class here
        t["character_name"] = uname;

        // For NPCs/Bots, mark them as such and prepare them, exactly as the players do on the client for themselves
        if (ci->local)
        {
            fpsEntity = game::getclient(cn); // It was created since fpsEntity was def'd
            assert(fpsEntity);

            fpsEntity->serverControlled = true; // Mark this as an NPC the server should control

            game::spawnplayer(fpsEntity);
        }
        return t;
#endif
    }

    int clientconnect(int n, uint ip)
    {
        logger::log(logger::DEBUG, "server::clientconnect: %d\r\n", n);

        clientinfo *ci = (clientinfo *)getinfo(n);
        ci->clientnum = n;
        ci->needclipboard = totalmillis ? totalmillis : 1;
        clients.add(ci);

        // Start the connection handshake process
        MessageSystem::send_InitS2C(n, n, PROTOCOL_VERSION);

        return DISC_NONE;
    }

    void clientdisconnect(int n) 
    { 
        logger::log(logger::DEBUG, "server::clientdisconnect: %d\r\n", n);
        INDENT_LOG(logger::DEBUG);

        clientinfo *ci = (clientinfo *)getinfo(n);
        if(smode) smode->leavegame(ci, true);
        clients.removeobj(ci);

#ifdef SERVER
        /*
         * Check for 1 because there is always at least
         * the dummy singleton client on the server!
         */
        if (shutdown_if_empty && clients.length() <= 1)
            should_quit = true;
#endif
    }

    const char *servername() { return "sauerbratenserver"; }
    int serverinfoport(int servport) { return SAUERBRATEN_SERVINFO_PORT; }
    int laninfoport() { return -1; }
    int serverport(int infoport)
    {
        return SAUERBRATEN_SERVER_PORT;
    }

    bool servercompatible(char *name, char *sdec, char *map, int ping, const vector<int> &attr, int np)
    {
        return attr.length() && attr[0]==PROTOCOL_VERSION;
    }

    int msgsizelookup(int msg)
    {
        // Kripken: Moved here from game.h, to prevent warnings
        static int msgsizes[] =               // size inclusive message token, 0 for variable or not-checked sizes
        {
            N_CONNECT, 0, N_SERVINFO, 5, N_WELCOME, 2, N_INITCLIENT, 0, N_POS, 0, N_TEXT, 0, N_SOUND, 2, N_CDIS, 2,
            N_SHOOT, 0, N_EXPLODE, 0, N_SUICIDE, 1,
            N_DIED, 4, N_DAMAGE, 6, N_HITPUSH, 7, N_SHOTFX, 9,
            N_TRYSPAWN, 1, N_SPAWNSTATE, 14, N_SPAWN, 3, N_FORCEDEATH, 2,
            N_GUNSELECT, 2, N_TAUNT, 1,
            N_MAPCHANGE, 0, N_MAPVOTE, 0, N_ITEMSPAWN, 2, N_ITEMPICKUP, 2, N_ITEMACC, 3,
            N_PING, 2, N_PONG, 2, N_CLIENTPING, 2,
            N_TIMEUP, 2, N_MAPRELOAD, 1, N_FORCEINTERMISSION, 1,
            N_SERVMSG, 0, N_ITEMLIST, 0, N_RESUME, 0,
            N_EDITMODE, 2, N_EDITENT, 11, N_EDITF, 16, N_EDITT, 16, N_EDITM, 16, N_FLIP, 14, N_COPY, 14, N_PASTE, 14, N_ROTATE, 15, N_REPLACE, 16, N_DELCUBE, 14, N_REMIP, 1, N_NEWMAP, 2, N_GETMAP, 1, N_SENDMAP, 0, N_EDITVAR, 0,
            N_MASTERMODE, 2, N_KICK, 2, N_CLEARBANS, 1, N_CURRENTMASTER, 3, N_SPECTATOR, 3, N_SETMASTER, 0, N_SETTEAM, 0,
            N_BASES, 0, N_BASEINFO, 0, N_BASESCORE, 0, N_REPAMMO, 1, N_BASEREGEN, 6, N_ANNOUNCE, 2,
            N_LISTDEMOS, 1, N_SENDDEMOLIST, 0, N_GETDEMO, 2, N_SENDDEMO, 0,
            N_DEMOPLAYBACK, 3, N_RECORDDEMO, 2, N_STOPDEMO, 1, N_CLEARDEMOS, 2,
            N_TAKEFLAG, 2, N_RETURNFLAG, 3, N_RESETFLAG, 4, N_INVISFLAG, 3, N_TRYDROPFLAG, 1, N_DROPFLAG, 6, N_SCOREFLAG, 6, N_INITFLAGS, 6,
            N_SAYTEAM, 0,
            N_CLIENT, 0,
            N_AUTHTRY, 0, N_AUTHCHAL, 0, N_AUTHANS, 0, N_REQAUTH, 0,
            N_PAUSEGAME, 2,
            N_ADDBOT, 2, N_DELBOT, 1, N_INITAI, 0, N_FROMAI, 2, N_BOTLIMIT, 2, N_BOTBALANCE, 2,
            N_MAPCRC, 0, N_CHECKMAPS, 1,
            N_SWITCHNAME, 0, N_SWITCHMODEL, 2, N_SWITCHTEAM, 0,
            -1
        };
        for(int *p = msgsizes; *p>=0; p += 2) if(*p==msg) return p[1];
        return -1;
    }

    void serverupdate()
    {
        gamemillis += curtime;
    }

    void recordpacket(int chan, void *data, int len)
    {
    }

    bool allowbroadcast(int n)
    {
        clientinfo *ci = (clientinfo *)getinfo(n);
        return ci && ci->connected; // XXX FIXME - code is wrong, but rare crashes if fix it by removing 'connected' bit
    }

    int reserveclients() { return 3+1; }

    int numchannels() { return 3; };

    const char *defaultmaster() { return "nada/nullo/"; } ;

    //// Scenario stuff

    void resetScenario()
    {
        loopv(clients)
        {
            clientinfo *ci = clients[i];
            ci->mapchange(); // Old sauer method to reset scenario/game/map transient info
        }
    }

    void setClientScenario(int cn, const char *sc)
    {
        clientinfo *ci = getinfo(cn);
        if (!ci) return;
        ci->runningCurrentScenario = (world::scenario_code == sc);
    }

    bool isRunningCurrentScenario(int clientNumber)
    {
        clientinfo *ci = getinfo(clientNumber);
        if (!ci) return false;

        return ci->runningCurrentScenario;
    }
};

