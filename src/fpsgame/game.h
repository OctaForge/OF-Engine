
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

// Windows
#undef PLATFORM

// console message types

enum
{
    CON_CHAT       = 1<<8,
    CON_TEAMCHAT   = 1<<9,
    CON_GAMEINFO   = 1<<10,
    CON_FRAG_SELF  = 1<<11,
    CON_FRAG_OTHER = 1<<12
};

// network quantization scale
#define DMF 16.0f                // for world locations
#define DNF 100.0f              // for normalized vectors
#define DVELF 1.0f              // for playerspeed based velocity vectors

enum                            // static entity types
{
    NOTUSED = ET_EMPTY,         // entity slot not in use in map
    LIGHT = ET_LIGHT,           // lightsource, attr1 = radius, attr2 = intensity
    MAPMODEL = ET_MAPMODEL,     // attr1 = angle, attr2 = idx
    PLAYERSTART,                // attr1 = angle, attr2 = team
    ENVMAP = ET_ENVMAP,         // attr1 = radius
    PARTICLES = ET_PARTICLES,
    MAPSOUND = ET_SOUND,
    SPOTLIGHT = ET_SPOTLIGHT,
    MAXENTTYPES
};

// hardcoded sounds, defined in sounds.cfg
enum
{
    S_JUMP = 0, S_LAND, 
    S_SPLASH1, S_SPLASH2,
    S_BURN,
    S_MENUCLICK,
    S_UW
};

// network messages codes, c2s, c2c, s2c

enum
{
    N_CONNECT = 0, N_SERVINFO, N_WELCOME, N_INITCLIENT, N_POS, N_TEXT, N_SOUND, N_CDIS,
    N_SHOOT, N_EXPLODE, N_SUICIDE,
    N_DIED, N_DAMAGE, N_HITPUSH, N_SHOTFX,
    N_TRYSPAWN, N_SPAWNSTATE, N_SPAWN, N_FORCEDEATH,
    N_GUNSELECT, N_TAUNT,
    N_MAPCHANGE, N_MAPVOTE, N_ITEMSPAWN, N_ITEMPICKUP, N_ITEMACC,
    N_PING, N_PONG, N_CLIENTPING,
    N_TIMEUP, N_MAPRELOAD, N_FORCEINTERMISSION,
    N_SERVMSG, N_ITEMLIST, N_RESUME,
    N_EDITMODE, N_EDITENT, N_EDITF, N_EDITT, N_EDITM, N_FLIP, N_COPY, N_PASTE, N_ROTATE, N_REPLACE, N_DELCUBE, N_REMIP, N_NEWMAP, N_GETMAP, N_SENDMAP, N_CLIPBOARD, N_EDITVAR,
    N_MASTERMODE, N_KICK, N_CLEARBANS, N_CURRENTMASTER, N_SPECTATOR, N_SETMASTER, N_SETTEAM,
    N_BASES, N_BASEINFO, N_BASESCORE, N_REPAMMO, N_BASEREGEN, N_ANNOUNCE,
    N_LISTDEMOS, N_SENDDEMOLIST, N_GETDEMO, N_SENDDEMO,
    N_DEMOPLAYBACK, N_RECORDDEMO, N_STOPDEMO, N_CLEARDEMOS,
    N_TAKEFLAG, N_RETURNFLAG, N_RESETFLAG, N_INVISFLAG, N_TRYDROPFLAG, N_DROPFLAG, N_SCOREFLAG, N_INITFLAGS,
    N_SAYTEAM,
    N_CLIENT,
    N_AUTHTRY, N_AUTHCHAL, N_AUTHANS, N_REQAUTH,
    N_PAUSEGAME,
    N_ADDBOT, N_DELBOT, N_INITAI, N_FROMAI, N_BOTLIMIT, N_BOTBALANCE,
    N_MAPCRC, N_CHECKMAPS,
    N_SWITCHNAME, N_SWITCHMODEL, N_SWITCHTEAM,
    N_SERVCMD, NUMSV
};

#define SAUERBRATEN_SERVER_PORT 28787
#define SAUERBRATEN_SERVINFO_PORT 28789
#define PROTOCOL_VERSION 1001           // bump when protocol changes

struct fpsent : dynent
{   
    int weight;                         // affects the effectiveness of hitpush
    int clientnum, lastupdate, plag, ping;
    int lifesequence;                   // sequence id for each respawn, used in damage test
    int lastpain;
    editinfo *edit;
    float deltayaw, deltapitch, newyaw, newpitch;
    int smoothmillis;

    string name, team, info;

    void *ai; // TODO: If we want, import rest of AI code

    int lastServerUpdate; // Kripken: This is the last time we sent the server an update. Might be different per NPC.

#ifdef SERVER
    bool serverControlled; // Kripken: Set to true for NPCs that this server controls. For now, that means all NPCs
#endif

    CLogicEntity *logicEntity;

    char turn_move, look_updown_move;    // Kripken: New movements

    int physsteps, physframetime, lastphysframe; // Kripken: Moved this here from physics.cpp: now done on a per-ent basis
    vec lastPhysicsPosition; // Kripken: The position before the last physics calculation of frame rates, etc.

    //! An integer, reserved for use in the position protocol update system. This is meant to be used by
    //! individual maps, which place their own data here, and use it however they want (for rendering, etc.).
    //! The engine itself just sends this inside the protocol updates.
    //! The reason this is needed, and why a normal StateData cannot be used, is that StateData is sent
    //! in channel 1, using reliable transmission, whereas some information must be sent along with the
    //! position info in channel 0, which is unreliable. This information will arrive faster (if there
    //! are dropped packets or network congestion), and will be synched with the position info, as it
    //! is a part of it. So, for example, this could contain animation information, that must be synched
    //! with the position very closely.
    //! This data is an unsigned integer. It is set to '0' initially and when the entity resets (so it
    //! would make sense for maps to consider that value the initialized value).
    unsigned int mapDefinedPositionData;

    int uniqueId;

    fpsent() : weight(100), clientnum(-1), lastupdate(0), plag(0), ping(0), lifesequence(0), lastpain(0), edit(NULL), smoothmillis(-1), ai(NULL)
                                                                      , lastServerUpdate(0)
#ifdef SERVER
                                                                      , serverControlled(false)
#endif
                                                                      , physsteps(0), physframetime(5), lastphysframe(0), lastPhysicsPosition(0,0,0)
                                                                      , mapDefinedPositionData(0), uniqueId(-821)
               { name[0] = team[0] = info[0] = 0; respawn(); }
    ~fpsent()
    {
#ifdef CLIENT
        freeeditinfo(edit);
#endif
     }

    void damageroll(float damage)
    {
        float damroll = 2.0f*damage;
        roll += roll>0 ? damroll : (roll<0 ? -damroll : (rnd(2) ? damroll : -damroll)); // give player a kick
    }

    void respawn()
    {
        dynent::reset();
    }

    virtual void reset() // OF: virtual
    {
        dynent::reset();
        turn_move = look_updown_move = 0;

        physsteps = 0;
        physframetime = 5;
        lastphysframe = lastmillis; // So we don't move too much on our first frame
        lastPhysicsPosition = vec(0,0,0);
        mapDefinedPositionData = 0;
    }

    virtual void stopmoving() // OF: virtual
    {
        dynent::stopmoving();
        turn_move = look_updown_move = 0;
    }

    // Kripken: Normalizations missing from the engine
    void normalize_pitch(float angle)
    {
        while(pitch<angle-180.0f) pitch += 360.0f;
        while(pitch>angle+180.0f) pitch -= 360.0f;
    }

    void normalize_roll(float angle)
    {
        while(roll<angle-180.0f) roll += 360.0f;
        while(roll>angle+180.0f) roll -= 360.0f;
    }

    float getheight() // Kripken: Added this
    {
        return aboveeye + eyeheight;
    }

    vec getcenter() // Kripken: Added this
    {
        vec center(o);
        center.z -= getheight();
        return center;
    }
};

namespace game
{
    // fps
    extern int gamemode;
    extern bool intermission;
    extern fpsent *player1;
    extern vector<fpsent *> players;
    extern int lasthit;
    extern int following;

    extern bool clientoption(const char *arg);
    extern fpsent *getclient(int cn);
    extern fpsent *newclient(int cn);
    extern char *colorname(fpsent *d, char *name = NULL, const char *prefix = "");
    extern fpsent *hudplayer();
    extern fpsent *followingplayer();
    extern void stopfollowing();
    extern void clientdisconnected(int cn, bool notify = true);
    extern void spawnplayer(fpsent *);

    // client
    extern bool connected, remote, demoplayback, spectator;

    extern int parseplayer(const char *arg);
    extern void addmsg(int type, const char *fmt = NULL, ...);
    extern void changemap(const char *name, int mode);
    extern void c2sinfo(bool force = false);
    extern void sendposition(fpsent *d, bool reliable = false);
    extern void sendmessages(fpsent *d);

    // weapon
    extern bool intersect(dynent *d, const vec &from, const vec &to);

    extern int playermodel;

    extern void swayhudgun(int curtime);
}

namespace server
{
    extern int msgsizelookup(int msg);
    extern bool serveroption(const char *arg);

    extern int getUniqueIdFromInfo(void *ci); // INTENSITY
    extern lua::Table createluaEntity(int cn, const char *_class = "", const char *uname = "local_editor");
    extern void setAdmin(int clientNumber, bool isAdmin); // INTENSITY: Called when logging in,
                                                          // and this is later applied whenever
                                                          // creating the lua logic entity (login and map restart)

    extern bool isAdmin(int clientNumber); // INTENSITY

    //! Clears info related to the current scenario, as a new one is being prepared
    extern void resetScenario();

    //! Update the current scenario being run by the client. The server uses this to make sure the
    //! client is running the same scenario when it accepts certain world update messages from the
    //! client.
    extern void setClientScenario(int cn, const char *sc);

    extern bool isRunningCurrentScenario(int clientNumber);
}

