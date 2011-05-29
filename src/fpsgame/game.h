
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

enum { PRIV_NONE = 0, PRIV_MASTER, PRIV_ADMIN };

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
    NUMSV
};

#define SAUERBRATEN_SERVER_PORT 28787
#define SAUERBRATEN_SERVINFO_PORT 28789
#define PROTOCOL_VERSION 1001           // bump when protocol changes

#define SGRAYS 20
#define SGSPREAD 4
#define RL_DAMRAD 40
#define RL_SELFDAMDIV 2
#define RL_DISTSCALE 1.5f

struct fpsent : dynent
{   
    int weight;                         // affects the effectiveness of hitpush
    int clientnum, privilege, lastupdate, plag, ping;
    int lifesequence;                   // sequence id for each respawn, used in damage test
    int lastpain;
    int lastaction, lastattackgun;
    bool attacking;
    int lasttaunt;
    int lastpickup, lastpickupmillis, lastbase;
    int superdamage;
    int frags, deaths, totaldamage, totalshots;
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

    fpsent() : weight(100), clientnum(-1), privilege(PRIV_NONE), lastupdate(0), plag(0), ping(0), lifesequence(0), lastpain(0), frags(0), deaths(0), totaldamage(0), totalshots(0), edit(NULL), smoothmillis(-1), ai(NULL)
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

    virtual void reset()
    {
        dynent::reset();
        turn_move = look_updown_move = 0;

        physsteps = 0;
        physframetime = 5;
        lastphysframe = lastmillis; // So we don't move too much on our first frame
        lastPhysicsPosition = vec(0,0,0);
        mapDefinedPositionData = 0;
    }

    virtual void stopmoving()
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
    struct clientmode
    {
        virtual ~clientmode() {}

        virtual void preload() {}
        virtual void drawhud(fpsent *d, int w, int h) {}
        virtual void rendergame() {}
        virtual void respawned(fpsent *d) {}
        virtual void setup() {}
        virtual void checkitems(fpsent *d) {}
        virtual int respawnwait(fpsent *d) { return 0; }
        virtual void pickspawn(fpsent *d) { findplayerspawn(d); }
        virtual void senditems(ucharbuf &p) {}
        virtual const char *prefixnextmap() { return ""; }
        virtual void removeplayer(fpsent *d) {}
        virtual void gameover() {}
        virtual bool hidefrags() { return false; }
        virtual int getteamscore(const char *team) { return 0; }
//        virtual void getteamscores(vector<teamscore> &scores) {}
    };

    extern clientmode *cmode;
    extern void setclientmode();

    // fps
    extern int gamemode, minremain;
    extern bool intermission;
    extern int maptime, maprealtime;
    extern fpsent *player1;
    extern vector<fpsent *> players;
    extern int lastspawnattempt;
    extern int lasthit;
    extern int respawnent;
    extern int following;

    extern bool clientoption(const char *arg);
    extern fpsent *getclient(int cn);
    extern fpsent *newclient(int cn);
    extern char *colorname(fpsent *d, char *name = NULL, const char *prefix = "");
    extern fpsent *pointatplayer();
    extern fpsent *hudplayer();
    extern fpsent *followingplayer();
    extern void stopfollowing();
    extern void clientdisconnected(int cn, bool notify = true);
    extern void spawnplayer(fpsent *);
    extern void deathstate(fpsent *d, bool restore = false);
    extern void damaged(int damage, fpsent *d, fpsent *actor, bool local = true);
    extern void killed(fpsent *d, fpsent *actor);
    extern void timeupdate(int timeremain);
    extern void msgsound(int n, fpsent *d = NULL);
    extern bool usedminimap();

    enum
    {
        HICON_BLUE_ARMOUR = 0,
        HICON_GREEN_ARMOUR,
        HICON_YELLOW_ARMOUR,

        HICON_HEALTH,

        HICON_FIST,
        HICON_SG,
        HICON_CG,
        HICON_RL,
        HICON_RIFLE,
        HICON_GL,
        HICON_PISTOL,

        HICON_QUAD,

        HICON_RED_FLAG,
        HICON_BLUE_FLAG,
        HICON_NEUTRAL_FLAG
    };

    extern void drawicon(int icon, int x, int y);
 
    // client
    extern bool connected, remote, demoplayback, spectator;

    extern int parseplayer(const char *arg);
    extern void addmsg(int type, const char *fmt = NULL, ...);
    extern void switchname(const char *name);
    extern void switchteam(const char *name);
    extern void switchplayermodel(int playermodel);
    extern void sendmapinfo();
    extern void stopdemo();
    extern void changemap(const char *name, int mode);
    extern void c2sinfo(bool force = false);
    extern void sendposition(fpsent *d, bool reliable = false);
    extern void sendmessages(fpsent *d);

    // monster
    struct monster;
    extern vector<monster *> monsters;

    extern void clearmonsters();
    extern void preloadmonsters();
    extern void updatemonsters(int curtime);
    extern void rendermonsters();
    extern void suicidemonster(monster *m);
    extern void hitmonster(int damage, monster *m, fpsent *at, const vec &vel, int gun);
    extern void monsterkilled();
    extern void endsp(bool allkilled);
    extern void spsummary(int accuracy);

    // movable
    struct movable;
    extern vector<movable *> movables;

    extern void clearmovables();
    extern void updatemovables(int curtime);
    extern void rendermovables();
    extern void suicidemovable(movable *m);
    extern void hitmovable(int damage, movable *m, fpsent *at, const vec &vel, int gun);

    // weapon
    extern void shoot(fpsent *d, const vec &targ);
    extern void shoteffects(int gun, const vec &from, const vec &to, fpsent *d, bool local);
    extern void explode(bool local, fpsent *owner, const vec &v, dynent *safe, int dam, int gun);
    extern void damageeffect(int damage, fpsent *d, bool thirdperson = true);
    extern void superdamageeffect(const vec &vel, fpsent *d);
    extern bool intersect(dynent *d, const vec &from, const vec &to);
    extern dynent *intersectclosest(const vec &from, const vec &to, fpsent *at);
    extern void clearbouncers(); 
    extern void updatebouncers(int curtime);
    extern void removebouncers(fpsent *owner);
    extern void renderbouncers();
    extern void clearprojectiles();
    extern void updateprojectiles(int curtime);
    extern void removeprojectiles(fpsent *owner);
    extern void renderprojectiles();
    extern void preloadbouncers();

    // scoreboard
    extern void showscores(bool on);
    extern void getbestplayers(vector<fpsent *> &best);
    extern void getbestteams(vector<const char *> &best);

    // render
    struct playermodelinfo
    {
        const char *ffa, *blueteam, *redteam, *hudguns,
                   *vwep, *quad, *armour[3],
                   *ffaicon, *blueicon, *redicon;
        bool ragdoll, selectable;
    };

    extern int playermodel, teamskins, testteam;

    extern void saveragdoll(fpsent *d);
    extern void clearragdolls();
    extern void moveragdolls();
    extern const playermodelinfo &getplayermodelinfo(fpsent *d);
    extern void swayhudgun(int curtime);
    extern vec hudgunorigin(int gun, const vec &from, const vec &to, fpsent *d);
}

namespace server
{
    extern const char *modename(int n, const char *unknown = "unknown"); 
    extern const char *mastermodename(int n, const char *unknown = "unknown");
    extern void startintermission();
    extern void stopdemo();
    extern void forcemap(const char *map, int mode);
    extern void hashpassword(int cn, int sessionid, const char *pwd, char *result);
    extern int msgsizelookup(int msg);
    extern bool serveroption(const char *arg);

    extern int getUniqueIdFromInfo(void *ci); // INTENSITY
    extern int createluaEntity(int cn, const char *_class = "", const char *uname = "local_editor");
    extern void setAdmin(int clientNumber, bool isAdmin); // INTENSITY: Called when logging in,
                                                          // and this is later applied whenever
                                                          // creating the lua logic entity (login and map restart)

    extern bool isAdmin(int clientNumber); // INTENSITY

    //! Clears info related to the current scenario, as a new one is being prepared
    extern void resetScenario();

    //! Update the current scenario being run by the client. The server uses this to make sure the
    //! client is running the same scenario when it accepts certain world update messages from the
    //! client.
    extern void setClientScenario(int clientNumber, std::string scenarioCode);

    extern bool isRunningCurrentScenario(int clientNumber);
}

