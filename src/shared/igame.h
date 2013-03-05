// the interface the engine uses to run the gameplay module

namespace game
{
    extern void parseoptions(vector<const char *> &args);

    extern void gamedisconnect(bool cleanup);
    extern void parsepacketclient(int chan, packetbuf &p);
    extern void gameconnect(bool _remote);
    extern bool allowedittoggle();
    extern void edittoggled(bool on);
    extern void toserver(char *text);
    extern void changemap(const char *name);
    extern bool ispaused();

    extern const char *gameident();
    extern const char *savedconfig();
    extern const char *restoreconfig();
    extern const char *defaultconfig();
    extern const char *autoexec();
    extern const char *savedservers();
    extern void loadconfigs();

    extern void updateworld();
    extern void initclient();
    extern void physicstrigger(physent *d, bool local, int floorlevel, int waterlevel, int material = 0);
    extern void edittrigger(const selinfo &sel, int op, int arg1 = 0, int arg2 = 0, int arg3 = 0);
    extern types::String getclientmap();
    extern const char *getmapinfo();
    extern void newmap(int size);
    extern void startmap(const char *name);
    extern void preload();
    extern float abovegameplayhud();
    extern void gameplayhud(int w, int h);
    extern bool canjump();
    extern bool allowmove(physent *d);
    extern void doattack(bool on);
    extern dynent *iterdynents(int i);
    extern int numdynents();
    extern void rendergame();
    extern void renderavatar();
    extern void writegamedata(vector<char> &extras);
    extern void readgamedata(vector<char> &extras);
    extern int clipconsole(int w, int h);
    extern void setupcamera();
    extern bool detachcamera();
    extern bool collidecamera();
    extern void adddynlights();
    extern void particletrack(physent *owner, vec &o, vec &d);
    extern void dynlighttrack(physent *owner, vec &o, vec &hud);
    extern bool needminimap();
} 
 
namespace server
{
    extern void *newclientinfo();
    extern void deleteclientinfo(void *ci);
    extern void serverinit();
    extern int reserveclients();
    extern int numchannels();
    extern void clientdisconnect(int n);
    extern int clientconnect(int n, uint ip);
    extern void localdisconnect(int n);
    extern void localconnect(int n);
    extern bool allowbroadcast(int n);
    extern void recordpacket(int chan, void *data, int len);
    extern void parsepacket(int sender, int chan, packetbuf &p);
    extern void sendservmsg(const char *s);
    extern bool sendpackets(bool force = false);
    extern void serverinforeply(ucharbuf &req, ucharbuf &p);
    extern void serverupdate();
    extern bool servercompatible(char *name, char *sdec, char *map, int ping, const vector<int> &attr, int np);
    extern int laninfoport();
    extern int serverinfoport(int servport = -1);
    extern int serverport(int infoport = -1);
    extern const char *defaultmaster();
    extern int masterport();
    extern void processmasterinput(const char *cmd, int cmdlen, const char *args);
}

