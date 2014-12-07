// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#ifndef __GAME_H__
#define __GAME_H__

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
    N_EDITMODE, N_EDITENT, N_EDITF, N_EDITT, N_EDITM, N_FLIP, N_COPY, N_PASTE, N_ROTATE, N_REPLACE, N_DELCUBE, N_CALCLIGHT, N_REMIP, N_EDITVSLOT, N_UNDO, N_REDO, N_NEWMAP, N_GETMAP, N_SENDMAP, N_CLIPBOARD, N_EDITVAR,
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
    N_SERVCMD,

    N_ENTREQUESTNEW, N_ENTREQUESTREMOVE,
    N_ACTIVEENTSREQUEST, N_ALLACTIVEENTSSENT,
    N_LOGINREQUEST, N_LOGINRESPONSE,
    N_YOURUID,
    N_PREPFORNEWSCENARIO, N_REQUESTCURRENTSCENARIO, N_NOTIFYABOUTCURRENTSCENARIO,
    N_INITS2C,
    N_EDITMODEC2S, N_EDITMODES2C,

    NUMSV
};

#define TESSERACT_STANDALONE_PORT 42000
#define PROTOCOL_VERSION 2 // bump when protocol changes

struct gameent : dynent
{
    int weight;                         // affects the effectiveness of hitpush
    int clientnum, lastupdate, plag, ping;
    int lifesequence;                   // sequence id for each respawn, used in damage test
    int lastpain;
    editinfo *edit;
    float deltayaw, deltapitch, deltaroll, newyaw, newpitch, newroll;
    int smoothmillis;
    int anim, start_time;
    bool can_move;

    string name, team, info;

    void *ai; // TODO: If we want, import rest of AI code

    char turn_move, look_updown_move;
    int uid;

#ifndef STANDALONE
    vector<modelattach> attachments;
    hashtable<const char*, entlinkpos> attachment_positions;
#endif

    gameent() : weight(100), clientnum(-1), lastupdate(0), plag(0), ping(0), lifesequence(0), lastpain(0), edit(NULL), smoothmillis(-1), anim(0), start_time(0), can_move(false), ai(NULL)
                                                                      , uid(-821)
    {
        name[0] = team[0] = info[0] = 0; respawn();
#ifndef STANDALONE
        attachments.add(modelattach());
#endif
    }
    ~gameent()
    {
#ifndef STANDALONE
        freeeditinfo(edit);
        clear_attachments(attachments, attachment_positions);
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
    }

    virtual void stopmoving() // OF: virtual
    {
        dynent::stopmoving();
        turn_move = look_updown_move = 0;
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
    // game
    extern int gamemode;
    extern bool intermission;
    extern gameent *player1;
    extern vector<gameent *> players;
    extern int lasthit;
    extern int following;

    extern bool clientoption(const char *arg);
    extern gameent *getclient(int cn);
    extern gameent *newclient(int cn);
    extern char *colorname(gameent *d, char *name = NULL, const char *prefix = "");
    extern gameent *hudplayer();
    extern gameent *followingplayer();
    extern void stopfollowing();
    extern void clientdisconnected(int cn, bool notify = true);
    extern void spawnplayer(gameent *);

    // client
    extern bool connected, remote, demoplayback, spectator;

    extern int parseplayer(const char *arg);
    extern bool addmsg(int type, const char *fmt = NULL, ...);
    extern void changemap(const char *name, int mode);
    extern void c2sinfo(bool force = false);
    extern void sendposition(gameent *d, bool reliable = false);
    extern void sendmessages(gameent *d);

    // weapon
    extern bool intersect(dynent *d, const vec &from, const vec &to);

    extern int playermodel;

    extern void swayhudgun(int curtime);

    void determinetarget(bool force = false, vec *pos = NULL, extentity **extent = NULL, dynent **dynent = NULL);
    void gettarget(vec *pos, extentity **extent, dynent **dynent);

    extern bool haslogicsys;
}

namespace server
{
    extern int msgsizelookup(int msg);
    extern bool serveroption(const char *arg);

    extern int createluaEntity(int cn, const char *_class = "", const char *uname = "local_editor");
    extern void setAdmin(int clientNumber, bool isAdmin);
    extern bool isAdmin(int clientNumber);

    //! Clears info related to the current scenario, as a new one is being prepared
    extern void resetScenario();

    //! Update the current scenario being run by the client. The server uses this to make sure the
    //! client is running the same scenario when it accepts certain world update messages from the
    //! client.
    extern void setClientScenario(int cn, const char *sc);

    extern bool isRunningCurrentScenario(int clientNumber);
}

#endif
