#ifndef __GAME_H__
#define __GAME_H__

#include "cube.h"

// console message types

enum
{
    CON_CHAT       = 1<<8,
    CON_GAMEINFO   = 1<<10,
};

// network quantization scale
#define DMF 16.0f                // for world locations
#define DNF 100.0f              // for normalized vectors
#define DVELF 1.0f              // for playerspeed based velocity vectors

enum
{
    M_EDIT       = 1<<3,
    M_DEMO       = 1<<4,
    M_LOCAL      = 1<<5,
};

static struct gamemodeinfo
{
    const char *name, *prettyname;
    int flags;
    const char *info;
} gamemodes[] =
{
    { "demo", "Demo", M_DEMO | M_LOCAL, NULL},
    { "edit", "Edit", M_EDIT, "Cooperative Editing:\nEdit maps with multiple players simultaneously." }
};

#define STARTGAMEMODE (-1)
#define NUMGAMEMODES ((int)(sizeof(gamemodes)/sizeof(gamemodes[0])))

#define m_valid(mode)          ((mode) >= STARTGAMEMODE && (mode) < STARTGAMEMODE + NUMGAMEMODES)
#define m_check(mode, flag)    (m_valid(mode) && gamemodes[(mode) - STARTGAMEMODE].flags&(flag))
#define m_checknot(mode, flag) (m_valid(mode) && !(gamemodes[(mode) - STARTGAMEMODE].flags&(flag)))
#define m_checkall(mode, flag) (m_valid(mode) && (gamemodes[(mode) - STARTGAMEMODE].flags&(flag)) == (flag))

#define m_demo         (m_check(gamemode, M_DEMO))
#define m_edit         (m_check(gamemode, M_EDIT))
#define m_botmode      (m_checknot(gamemode, M_DEMO|M_LOCAL))
#define m_mp(mode)     (m_checknot(mode, M_LOCAL))

enum { MM_AUTH = -1, MM_OPEN = 0, MM_VETO, MM_LOCKED, MM_PRIVATE, MM_PASSWORD, MM_START = MM_AUTH, MM_INVALID = MM_START - 1 };

static const char * const mastermodenames[] =  { "auth",   "open",   "veto",       "locked",     "private",    "password" };
static const char * const mastermodecolors[] = { "",       "\f0",    "\f2",        "\f2",        "\f3",        "\f3" };
static const char * const mastermodeicons[] =  { "server", "server", "serverlock", "serverlock", "serverpriv", "serverpriv" };

// network messages codes, c2s, c2c, s2c

enum { PRIV_NONE = 0, PRIV_MASTER, PRIV_AUTH, PRIV_ADMIN };

enum
{
    N_CONNECT = 0, N_SERVINFO, N_WELCOME, N_INITCLIENT, N_POS, N_TEXT, N_CDIS,
    N_MAPCHANGE, N_MAPVOTE,
    N_PING, N_PONG, N_CLIENTPING,
    N_TIMEUP, N_FORCEINTERMISSION,
    N_SERVMSG, N_RESUME,
    N_EDITMODE, N_EDITENT, N_ENTPOS, N_EDITF, N_EDITT, N_EDITM, N_FLIP, N_COPY, N_PASTE, N_ROTATE, N_REPLACE, N_DELCUBE, N_CALCLIGHT, N_REMIP, N_EDITVSLOT, N_UNDO, N_REDO, N_NEWMAP, N_GETMAP, N_SENDMAP, N_CLIPBOARD, N_EDITVAR,
    N_MASTERMODE, N_KICK, N_CLEARBANS, N_CURRENTMASTER, N_SPECTATOR, N_SETMASTER,
    N_LISTDEMOS, N_SENDDEMOLIST, N_GETDEMO, N_SENDDEMO,
    N_DEMOPLAYBACK, N_RECORDDEMO, N_STOPDEMO, N_CLEARDEMOS,
    N_CLIENT,
    N_AUTHTRY, N_AUTHKICK, N_AUTHCHAL, N_AUTHANS, N_REQAUTH,
    N_PAUSEGAME, N_GAMESPEED,
    N_MAPCRC, N_CHECKMAPS,
    N_SWITCHNAME,
    N_SERVCMD,
    N_DEMOPACKET,

    N_ENTCN, N_ENTREM, N_ENTSDATAUP, N_ENTSDATAUPREQ,

    N_ACTIVEENTSREQUEST, N_ALLACTIVEENTSSENT,
    N_TEXPACKLOAD, N_TEXPACKUNLOAD, N_TEXPACKRELOAD,
    N_MATPACKLOAD, N_DECALPACKLOAD,

    NUMMSG
};

static const int msgsizes[] =               // size inclusive message token, 0 for variable or not-checked sizes
{
    N_CONNECT, 0, N_SERVINFO, 0, N_WELCOME, 1, N_INITCLIENT, 0, N_POS, 0, N_TEXT, 0, N_CDIS, 2,
    N_MAPCHANGE, 0, N_MAPVOTE, 0,
    N_PING, 2, N_PONG, 2, N_CLIENTPING, 2,
    N_TIMEUP, 2, N_FORCEINTERMISSION, 1,
    N_SERVMSG, 0, N_RESUME, 0,
    N_EDITMODE, 2, N_EDITENT, 0, N_ENTPOS, 5, N_EDITF, 16, N_EDITT, 16, N_EDITM, 16, N_FLIP, 14, N_COPY, 14, N_PASTE, 14, N_ROTATE, 15, N_REPLACE, 17, N_DELCUBE, 14, N_CALCLIGHT, 1, N_REMIP, 1, N_EDITVSLOT, 16, N_UNDO, 0, N_REDO, 0, N_NEWMAP, 2, N_GETMAP, 1, N_SENDMAP, 0, N_EDITVAR, 0, 
    N_MASTERMODE, 2, N_KICK, 0, N_CLEARBANS, 1, N_CURRENTMASTER, 0, N_SPECTATOR, 3, N_SETMASTER, 0,
    N_LISTDEMOS, 1, N_SENDDEMOLIST, 0, N_GETDEMO, 2, N_SENDDEMO, 0,
    N_DEMOPLAYBACK, 3, N_RECORDDEMO, 2, N_STOPDEMO, 1, N_CLEARDEMOS, 2,
    N_CLIENT, 0,
    N_AUTHTRY, 0, N_AUTHKICK, 0, N_AUTHCHAL, 0, N_AUTHANS, 0, N_REQAUTH, 0,
    N_PAUSEGAME, 0, N_GAMESPEED, 0,
    N_MAPCRC, 0, N_CHECKMAPS, 1,
    N_SWITCHNAME, 0,
    N_SERVCMD, 0,
    N_DEMOPACKET, 0,

    N_ENTCN, 0, N_ENTREM, 0, N_ENTSDATAUP, 0, N_ENTSDATAUPREQ, 0,

    N_ACTIVEENTSREQUEST, 0, N_ALLACTIVEENTSSENT, 0,
    N_TEXPACKLOAD, 0, N_TEXPACKUNLOAD, 0, N_TEXPACKRELOAD, 0,
    N_MATPACKLOAD, 0, N_DECALPACKLOAD, 0,

    -1
};

#define OCTAFORGE_SERVER_PORT 46000
#define OCTAFORGE_LANINFO_PORT 45998
#define OCTAFORGE_MASTER_PORT 45999
#define PROTOCOL_VERSION 1              // bump when protocol changes
#define DEMO_VERSION 1                  // bump when demo format changes
#define DEMO_MAGIC "OCTAFORGE_DEMO\0\0"

struct demoheader
{
    char magic[16];
    int version, protocol;
};

#define MAXNAMELEN 15

struct gameent : dynent
{
    int weight;                         // affects the effectiveness of hitpush
    int clientnum, privilege, lastupdate, plag, ping;
    int lifesequence;
    int lastdeath;
    editinfo *edit;
    float deltayaw, deltapitch, deltaroll, newyaw, newpitch, newroll;
    int smoothmillis;
    int anim, start_time;
    bool can_move;

    string name;
    void *ai;

    char turn_move, look_updown_move;

#ifndef STANDALONE
    vector<modelattach> attachments;
    hashtable<const char*, entlinkpos> attachment_positions;
#endif

    gameent() : weight(100), clientnum(-1), privilege(PRIV_NONE), lastupdate(0), plag(0), ping(0), lifesequence(0), lastdeath(0), edit(NULL), smoothmillis(-1), anim(0), start_time(0), can_move(false), ai(NULL)
    {
        name[0] = 0;
#ifndef STANDALONE
        attachments.add(modelattach());
#endif
        reset();
    }
    ~gameent()
    {
        freeeditinfo(edit);
#ifndef STANDALONE
        clear_attachments(attachments, attachment_positions);
#endif
    }

    void startgame()
    {
        lifesequence = -1;
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

namespace entities
{
    extern vector<extentity *> ents;
}

namespace game
{
    extern int gamemode;

    // game
    extern int nextmode;
    extern string clientmap;
    extern int maptime, maprealtime;
    extern gameent *player1;
    extern vector<gameent *> players, clients;
    extern int following;
    extern int smoothmove, smoothdist;

    extern bool clientoption(const char *arg);
    extern gameent *getclient(int cn);
    extern gameent *newclient(int cn);
    extern const char *colorname(gameent *d, const char *name = NULL, const char *alt = NULL, const char *color = "");
    extern gameent *pointatplayer();
    extern gameent *hudplayer();
    extern gameent *followingplayer();
    extern void stopfollowing();
    extern void checkfollow();
    extern void nextfollow(int dir = 1);
    extern void clientdisconnected(int cn, bool notify = true);
    extern void clearclients(bool notify = true);
    extern void startgame();
    extern void timeupdate(int timeremain);
    extern void drawicon(int icon, float x, float y, float sz = 120);
    const char *mastermodecolor(int n, const char *unknown);
    const char *mastermodeicon(int n, const char *unknown);
    extern void collidedynent(int pl, int cn, const vec &wall);
    extern void collideextent(int pl, int uid);

    // client
    extern bool connected, remote, demoplayback;
    extern string servdesc;
    extern vector<uchar> messages;

    extern int parseplayer(const char *arg);
    extern void ignore(int cn);
    extern void unignore(int cn);
    extern bool isignored(int cn);
    extern bool addmsg(int type, const char *fmt = NULL, ...);
    extern void sendmapinfo();
    extern void stopdemo();
    extern void changemap(const char *name, int mode);
    extern void c2sinfo(bool force = false);
    extern void sendposition(gameent *d, bool reliable = false);

    extern float intersectdist;
    extern bool intersect(dynent *d, const vec &from, const vec &to, float margin = 0, float &dist = intersectdist);

    // render
    extern void saveragdoll(gameent *d);
    extern void clearragdolls();
    extern void moveragdolls();

    void determinetarget(bool force = false, vec *pos = NULL, extentity **extent = NULL, dynent **dynent = NULL);
    void gettarget(vec *pos, extentity **extent, dynent **dynent);
}

namespace server
{
    extern const char *modename(int n, const char *unknown = "unknown");
    extern const char *modeprettyname(int n, const char *unknown = "unknown");
    extern const char *mastermodename(int n, const char *unknown = "unknown");
    extern void stopdemo();
    extern void forcemap(const char *map, int mode);
    extern void forcepaused(bool paused);
    extern void forcegamespeed(int speed);
    extern void hashpassword(int cn, int sessionid, const char *pwd, char *result, int maxlen = MAXSTRLEN);
    extern int msgsizelookup(int msg);
    extern bool serveroption(const char *arg);
}

#endif

