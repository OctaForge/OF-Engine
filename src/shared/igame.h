// the interface the engine uses to run the gameplay module

namespace entities
{
    extern void editent(int i, bool local);
    extern const char *entnameinfo(entity &e);
    extern const char *entname(int i);
    extern float dropheight(entity &e);
    extern void fixentity(extentity &e);
    extern void entradius(extentity &e, bool color);
    extern bool printent(extentity &e, char *buf, int len);
    extern extentity *newentity();
    extern void deleteentity(extentity *e);
    extern void clearents();
    extern vector<extentity *> &getents();
    extern void animatemapmodel(const extentity &e, int &anim, int &basetime);
    model *getmodel(const extentity &e);
    void setmodel(extentity &e, model *m);
    model *getcollidemodel(const extentity &e);
    void setcollidemodel(extentity &e, model *m);
    int getanim(const extentity &e);
    int getstarttime(const extentity &e);
    modelattach *getattachments(extentity &e);
}

namespace game
{
    extern void parseoptions(vector<const char *> &args);

    extern void gamedisconnect(bool cleanup);
    extern void parsepacketclient(int chan, packetbuf &p);
    extern void connectattempt(const char *name, const char *password, const ENetAddress &address);
    extern void connectfail();
    extern void gameconnect(bool _remote);
    extern bool allowedittoggle();
    extern void edittoggled(bool on);
    extern void writeclientinfo(stream *f);
    extern void toserver(char *text);
    extern void changemap(const char *name);
    extern void forceedit(const char *name);
    extern bool ispaused();
    extern int scaletime(int t);
    extern bool allowmouselook();

    extern const char *gameident();
    extern const char *gameconfig();
    extern const char *savedconfig();
    extern const char *restoreconfig();
    extern const char *defaultconfig();
    extern const char *autoexec();
    extern const char *savedservers();
    extern void loadconfigs();

    extern void updateworld();
    extern void initclient();
    extern void physicstrigger(physent *d, bool local, int floorlevel, int waterlevel, int material = 0);
    extern void edittrigger(const selinfo &sel, int op, int arg1 = 0, int arg2 = 0, int arg3 = 0, const VSlot *vs = NULL);
    extern void vartrigger(ident *id);
    extern void dynentcollide(physent *d, physent *o, const vec &dir);
    extern const char *getclientmap();
    extern const char *getmapinfo();
    extern const char *getscreenshotinfo();
    extern void resetgamestate();
    extern void newmap(int size);
    extern void startmap(const char *name);
    extern float abovegameplayhud(int w, int h);
    extern void gameplayhud(int w, int h);
    extern bool allowmove(physent *d);
    extern dynent *iterdynents(int i);
    extern int numdynents();
    extern void rendergame();
    extern void renderavatar();
    extern int numanims();
    extern float clipconsole(float w, float h);
    extern const char *defaultcrosshair(int index);
    extern int selectcrosshair(vec &col);
    extern void setupcamera();
    extern bool detachcamera();
    extern bool collidecamera();
    extern void particletrack(physent *owner, vec &o, vec &d);
    extern void dynlighttrack(physent *owner, vec &o, vec &hud);
    extern bool needminimap();
}

namespace server
{
    extern void *newclientinfo();
    extern void deleteclientinfo(void *ci);
    extern void serverinit(bool dedicated);
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
    extern int protocolversion();
    extern int laninfoport();
    extern int serverport();
    extern const char *defaultmaster();
    extern int masterport();
    extern void processmasterinput(const char *cmd, int cmdlen, const char *args);
    extern void masterconnected();
    extern void masterdisconnected();
    extern bool ispaused();
    extern int scaletime(int t);
}

