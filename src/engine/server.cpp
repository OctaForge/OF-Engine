// server.cpp: little more than enhanced multicaster
// runs dedicated or as client coroutine

#include "engine.h"

#include "game.h" // INTENSITY: needed for fpsent
 // INTENSITY
#include "network_system.h"
#include "message_system.h"
#include "of_world.h"

#define SERVER_UPDATE_INTERVAL 300

namespace server
{
    extern bool shutdown_if_empty;
    extern bool shutdown_if_idle;
    extern int  shutdown_idle_interval;
    int& getUniqueId(int clientNumber);
}
bool should_quit = false;

static FILE *logfile = NULL;

void closelogfile()
{
    if(logfile)
    {
        fclose(logfile);
        logfile = NULL;
    }
}

void setlogfile(const char *fname)
{
    closelogfile();
    if(fname && fname[0])
    {
        fname = findfile(fname, "w");
        if(fname) logfile = fopen(fname, "w");
    }
    setvbuf(logfile ? logfile : stdout, NULL, _IOLBF, BUFSIZ);
}

void logoutfv(const char *fmt, va_list args)
{
    vfprintf(logfile ? logfile : stdout, fmt, args);
    fputc('\n', logfile ? logfile : stdout);
}

void logoutf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    logoutfv(fmt, args);
    va_end(args);
}

#ifdef STANDALONE
void fatal(const char *fmt, ...) 
{ 
    void cleanupserver();
    cleanupserver(); 
    va_list args;
    va_start(args, fmt);
    if(logfile) logoutfv(fmt, args);
    fprintf(stderr, "server error: ");
    vfprintf(stderr, fmt, args);
    fputc('\n', stderr);
    va_end(args);
    closelogfile();
    exit(EXIT_FAILURE); 
}

void conoutfv(int type, const char *fmt, va_list args)
{
    string sf, sp;
    vformatstring(sf, fmt, args);
    filtertext(sp, sf);
    logoutf("%s", sp);
}

void conoutf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(CON_INFO, fmt, args);
    va_end(args);
}

void conoutf(int type, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(type, fmt, args);
    va_end(args);
}
#endif

// all network traffic is in 32bit ints, which are then compressed using the following simple scheme (assumes that most values are small).

template<class T>
static inline void putint_(T &p, int n)
{
    if(n<128 && n>-127) p.put(n);
    else if(n<0x8000 && n>=-0x8000) { p.put(0x80); p.put(n); p.put(n>>8); }
    else { p.put(0x81); p.put(n); p.put(n>>8); p.put(n>>16); p.put(n>>24); }
}
void putint(ucharbuf &p, int n) { putint_(p, n); }
void putint(packetbuf &p, int n) { putint_(p, n); }
void putint(vector<uchar> &p, int n) { putint_(p, n); }

int getint(ucharbuf &p)
{
    int c = (char)p.get();
    if(c==-128) { int n = p.get(); n |= char(p.get())<<8; return n; }
    else if(c==-127) { int n = p.get(); n |= p.get()<<8; n |= p.get()<<16; return n|(p.get()<<24); } 
    else return c;
}

// much smaller encoding for unsigned integers up to 28 bits, but can handle signed
template<class T>
static inline void putuint_(T &p, int n)
{
    if(n < 0 || n >= (1<<21))
    {
        p.put(0x80 | (n & 0x7F));
        p.put(0x80 | ((n >> 7) & 0x7F));
        p.put(0x80 | ((n >> 14) & 0x7F));
        p.put(n >> 21);
    }
    else if(n < (1<<7)) p.put(n);
    else if(n < (1<<14))
    {
        p.put(0x80 | (n & 0x7F));
        p.put(n >> 7);
    }
    else 
    { 
        p.put(0x80 | (n & 0x7F)); 
        p.put(0x80 | ((n >> 7) & 0x7F));
        p.put(n >> 14); 
    }
}
void putuint(ucharbuf &p, int n) { putuint_(p, n); }
void putuint(packetbuf &p, int n) { putuint_(p, n); }
void putuint(vector<uchar> &p, int n) { putuint_(p, n); }

int getuint(ucharbuf &p)
{
    int n = p.get();
    if(n & 0x80)
    {
        n += (p.get() << 7) - 0x80;
        if(n & (1<<14)) n += (p.get() << 14) - (1<<14);
        if(n & (1<<21)) n += (p.get() << 21) - (1<<21);
        if(n & (1<<28)) n |= -1<<28;
    }
    return n;
}

template<class T>
static inline void putfloat_(T &p, float f)
{
    lilswap(&f, 1);
    p.put((uchar *)&f, sizeof(float));
}
void putfloat(ucharbuf &p, float f) { putfloat_(p, f); }
void putfloat(packetbuf &p, float f) { putfloat_(p, f); }
void putfloat(vector<uchar> &p, float f) { putfloat_(p, f); }

float getfloat(ucharbuf &p)
{
    float f;
    p.get((uchar *)&f, sizeof(float));
    return lilswap(f);
}

template<class T>
static inline void sendstring_(const char *t, T &p)
{
    while(*t) putint(p, *t++);
    putint(p, 0);
}
void sendstring(const char *t, ucharbuf &p) { sendstring_(t, p); }
void sendstring(const char *t, packetbuf &p) { sendstring_(t, p); }
void sendstring(const char *t, vector<uchar> &p) { sendstring_(t, p); }

void getstring(char *text, ucharbuf &p, int len)
{
    char *t = text;
    do
    {
        if(t>=&text[len]) { text[len-1] = 0; return; }
        if(!p.remaining()) { *t = 0; return; } 
        *t = getint(p);
    }
    while(*t++);
}

void filtertext(char *dst, const char *src, bool whitespace, int len)
{
    for(int c = *src; c; c = *++src)
    {
        switch(c)
        {
        case '\f': ++src; continue;
        }
        if(isspace(c) ? whitespace : isprint(c))
        {
            *dst++ = c;
            if(!--len) break;
        }
    }
    *dst = '\0';
}

enum { ST_EMPTY, ST_LOCAL, ST_TCPIP };

struct client                   // server side version of "dynent" type
{
    int type;
    int num;
    ENetPeer *peer;
    string hostname;
    void *info;
};

vector<client *> clients;

ENetHost *serverhost = NULL;
int laststatus = 0; 
ENetSocket pongsock = ENET_SOCKET_NULL, lansock = ENET_SOCKET_NULL;

void cleanupserver()
{
    if(serverhost) enet_host_destroy(serverhost);
    serverhost = NULL;

    if(pongsock != ENET_SOCKET_NULL) enet_socket_destroy(pongsock);
    if(lansock != ENET_SOCKET_NULL) enet_socket_destroy(lansock);
    pongsock = lansock = ENET_SOCKET_NULL;
}

void process(ENetPacket *packet, int sender, int chan);
//void disconnect_client(int n, int reason);

void *getclientinfo(int i) { return !clients.inrange(i) || clients[i]->type==ST_EMPTY ? NULL : clients[i]->info; }
int getnumclients()        { return clients.length(); }
uint getclientip(int n)    { return clients.inrange(n) && clients[n]->type==ST_TCPIP ? clients[n]->peer->address.host : 0; }

void sendpacket(int n, int chan, ENetPacket *packet, int exclude)
{
    if(n<0)
    {
        if (getnumclients() <= 0) return; // INTENSITY: Added this, because otherwise sending to '-1' when there are no clients segfaults
        server::recordpacket(chan, packet->data, packet->dataLength);
        loopv(clients) if(i!=exclude && server::allowbroadcast(i)) sendpacket(i, chan, packet);
        return;
    }
    switch(clients[n]->type)
    {
        case ST_TCPIP:
        {
            enet_peer_send(clients[n]->peer, chan, packet);

            NetworkSystem::Cataloger::packetSent(chan, packet->dataLength); // INTENSITY

            break;
        }

#ifndef STANDALONE
        case ST_LOCAL:
            localservertoclient(chan, packet);
            break;
#endif
    }
}

ENetPacket *sendf(int cn, int chan, const char *format, ...)
{
    int exclude = -1;
    bool reliable = false;
    if(*format=='r') { reliable = true; ++format; }
    packetbuf p(MAXTRANS, reliable ? ENET_PACKET_FLAG_RELIABLE : 0);
    va_list args;
    va_start(args, format);
    while(*format) switch(*format++)
    {
        case 'x':
            exclude = va_arg(args, int);
            break;

        case 'v':
        {
            int n = va_arg(args, int);
            int *v = va_arg(args, int *);
            loopi(n) putint(p, v[i]);
            break;
        }

        case 'i': 
        {
            int n = isdigit(*format) ? *format++-'0' : 1;
            loopi(n) putint(p, va_arg(args, int));
            break;
        }
        case 'f':
        {
            int n = isdigit(*format) ? *format++-'0' : 1;
            loopi(n) putfloat(p, (float)va_arg(args, double));
            break;
        }
        case 's': sendstring(va_arg(args, const char *), p); break;
        case 'm':
        {
            int n = va_arg(args, int);
            p.put(va_arg(args, uchar *), n);
            break;
        }
    }
    va_end(args);
    ENetPacket *packet = p.finalize();
    sendpacket(cn, chan, packet, exclude);
    return packet->referenceCount > 0 ? packet : NULL;
}

ENetPacket *sendfile(int cn, int chan, stream *file, const char *format, ...)
{
    assert(0); // INTENSITY: We use our own asset system to transfer files
#if 0
    if(cn < 0)
    {
#ifdef STANDALONE
        return NULL;
#endif
    }
    else if(!clients.inrange(cn)) return NULL;

    int len = file->size();
    if(len <= 0) return NULL;

    packetbuf p(MAXTRANS+len, ENET_PACKET_FLAG_RELIABLE);
    va_list args;
    va_start(args, format);
    while(*format) switch(*format++)
    {
        case 'i':
        {
            int n = isdigit(*format) ? *format++-'0' : 1;
            loopi(n) putint(p, va_arg(args, int));
            break;
        }
        case 's': sendstring(va_arg(args, const char *), p); break;
        case 'l': putint(p, len); break;
    }
    va_end(args);

    file->seek(0, SEEK_SET);
    file->read(p.subbuf(len).buf, len);

    ENetPacket *packet = p.finalize();
    if(cn >= 0) sendpacket(cn, chan, packet, -1);
#ifndef STANDALONE
    else sendclientpacket(packet, chan);
#endif
    return packet->referenceCount > 0 ? packet : NULL;
#endif
    return NULL; // quaker66: deprecated function, for now make msvc compile this (must return)
}

const char *disc_reasons[] = { "normal", "end of packet", "client num", "kicked/banned", "tag type", "ip is banned", "server is in private mode", "server FULL", "connection timed out", "overflow" };

void disconnect_client(int n, int reason)
{
    if(!clients.inrange(n) || clients[n]->type!=ST_TCPIP) return;
    enet_peer_disconnect(clients[n]->peer, reason);
    server::clientdisconnect(n);
    clients[n]->type = ST_EMPTY;
    clients[n]->peer->data = NULL;
    server::deleteclientinfo(clients[n]->info);
    clients[n]->info = NULL;
    defformatstring(s)("client (%s) disconnected because: %s", clients[n]->hostname, disc_reasons[reason]);
    puts(s);
    server::sendservmsg(s);
}

void kicknonlocalclients(int reason)
{
    loopv(clients) if(clients[i]->type==ST_TCPIP) disconnect_client(i, reason);
}

void process(ENetPacket *packet, int sender, int chan)   // sender may be -1
{
    packetbuf p(packet);
    server::parsepacket(sender, chan, p);
    if(p.overread()) { disconnect_client(sender, DISC_EOP); return; }
}

void localclienttoserver(int chan, ENetPacket *packet, int cn) // INTENSITY: Added cn
{
    client *c = NULL;
    if (cn == -1) // INTENSITY
    {
        loopv(clients) if(clients[i]->type==ST_LOCAL) { c = clients[i]; break; }
    } else {
        c = clients[cn]; // INTENSITY
    }

    if(c) process(packet, c->num, chan);
}

client &addclient()
{
    loopv(clients) if(clients[i]->type==ST_EMPTY)
    {
        clients[i]->info = server::newclientinfo();
        return *clients[i];
    }
    client *c = new client;
    c->num = clients.length();
    c->info = server::newclientinfo();
    clients.add(c);
    return *c;
}

int localclients = 0, nonlocalclients = 0;

bool hasnonlocalclients() { return nonlocalclients!=0; }
bool haslocalclients() { return localclients!=0; }

static ENetAddress pongaddr;

void sendserverinforeply(ucharbuf &p)
{
    ENetBuffer buf;
    buf.data = p.buf;
    buf.dataLength = p.length();
    enet_socket_send(pongsock, &pongaddr, &buf, 1);
}

#define DEFAULTCLIENTS 6

int uprate = 0, maxclients = DEFAULTCLIENTS;
const char *ip = "";

#if defined(STANDALONE) || defined(SERVER) // INTENSITY: Added server
int curtime = 0, lastmillis = 0, totalmillis = 0;
#endif

// INTENSITY: Moved this code to here, + additions
void show_server_stats()
{
    float seconds = float(totalmillis-laststatus)/1024.0f;

    if(seconds > 0 && (nonlocalclients || serverhost->totalSentData || serverhost->totalReceivedData))
    {
        printf("%d remote clients, %.1f K/sec sent, %.1f K/sec received   [over last %.1f seconds]\n", nonlocalclients, serverhost->totalSentData/seconds/1024, serverhost->totalReceivedData/seconds/1024, seconds);

        NetworkSystem::Cataloger::show(seconds);
    }
    else
        printf("No activity to report\r\n");

    // Initialise
    laststatus = totalmillis;
    serverhost->totalSentData = serverhost->totalReceivedData = 0;
}

void serverslice(bool dedicated, uint timeout)   // main server update, called from main loop in sp, or from below in dedicated server
{
    localclients = nonlocalclients = 0;
    loopv(clients) switch(clients[i]->type)
    {
        case ST_LOCAL: localclients++; break;
        case ST_TCPIP: nonlocalclients++; break;
    }

    if(!serverhost) 
    {
        server::serverupdate();
        server::sendpackets();
        return;
    }
       
    // below is network only

    if(dedicated) 
    {
        int millis = (int)enet_time_get();
        curtime = millis - totalmillis;
        lastmillis = totalmillis = millis;
    }
    server::serverupdate();
    
    ENetEvent event;
    bool serviced = false;
    while(!serviced)
    {
        if(enet_host_check_events(serverhost, &event) <= 0)
        {
            if(enet_host_service(serverhost, &event, timeout) <= 0) break;
            serviced = true;
        }
        switch(event.type)
        {
            case ENET_EVENT_TYPE_CONNECT:
            {
                client &c = addclient();
                c.type = ST_TCPIP;
                c.peer = event.peer;
                c.peer->data = &c;
                char hn[1024];
                copystring(c.hostname, (enet_address_get_host_ip(&c.peer->address, hn, sizeof(hn))==0) ? hn : "unknown");
                logoutf("client connected (%s)", c.hostname);
                int reason = server::clientconnect(c.num, c.peer->address.host);
                if(!reason) nonlocalclients++;
                else disconnect_client(c.num, reason);
                break;
            }
            case ENET_EVENT_TYPE_RECEIVE:
            {
                client *c = (client *)event.peer->data;
                if(c) process(event.packet, c->num, event.channelID);
                if(event.packet->referenceCount==0) enet_packet_destroy(event.packet);
                break;
            }
            case ENET_EVENT_TYPE_DISCONNECT: 
            {
                client *c = (client *)event.peer->data;
                if(!c) break;
                logoutf("disconnected client (%s)", c->hostname);
                server::clientdisconnect(c->num);
                nonlocalclients--;
                c->type = ST_EMPTY;
                event.peer->data = NULL;
                server::deleteclientinfo(c->info);
                c->info = NULL;
                break;
            }
            default:
                break;
        }
    }
    if(server::sendpackets()) enet_host_flush(serverhost);
}

// INTENSITY: Added this, so we can flush out messages at will, e.g., login failure messages,
// which must be done before the next cycle as it might disconnect the other client before
// sending anything.
void force_network_flush()
{
    if (!serverhost)
    {
        Logging::log(Logging::ERROR, "Trying to force_flush, but no serverhost yet\r\n");
        return;
    }

//    if(sv->sendpackets())
        enet_host_flush(serverhost);
}

void flushserver(bool force)
{
    if(server::sendpackets(force) && serverhost) enet_host_flush(serverhost);
}

#ifndef STANDALONE
void localdisconnect(bool cleanup, int cn) // INTENSITY: Added cn
{
    bool disconnected = false;
    loopv(clients) if(clients[i]->type==ST_LOCAL) 
    {
        if (cn != -1 && cn != clients[i]->num) continue; // INTENSITY: if cn given, only process that one
        server::localdisconnect(i);
        localclients--;
        clients[i]->type = ST_EMPTY;
        server::deleteclientinfo(clients[i]->info);
        clients[i]->info = NULL;
        disconnected = true;
    }

#ifdef CLIENT // INTENSITY: Added this
    if(!disconnected) return;
    game::gamedisconnect(cleanup);
    SETV(mainmenu, 1);
#endif
}

int localconnect() // INTENSITY: Added returning client num
{
    client &c = addclient();
    c.type = ST_LOCAL;
    copystring(c.hostname, "local");
    localclients++;
    game::gameconnect(false);
    server::localconnect(c.num);
    return c.num; // INTENSITY: Added returning client num
}
#endif

void rundedicatedserver()
{
    #ifdef WIN32
    SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);
    #endif
#if 0
    logoutf("dedicated server started, waiting for clients...");
    for(;;) serverslice(true, 5);
#endif
}

bool servererror(bool dedicated, const char *desc)
{
#ifndef STANDALONE
    if(!dedicated)
    {
        conoutf(CON_ERROR, desc);
        cleanupserver();
    }
    else
#endif
        fatal(desc);
    return false;
}
  
bool setuplistenserver(bool dedicated)
{
    ENetAddress address = { ENET_HOST_ANY, GETIV(serverport) <= 0 ? enet_uint16(server::serverport()) : enet_uint16(GETIV(serverport)) };
    if(GETSV(serverip)[0])
    {
        if(enet_address_set_host(&address, GETSV(serverip))<0) conoutf(CON_WARN, "WARNING: server ip not resolved");
    }
    serverhost = enet_host_create(&address, min(maxclients + server::reserveclients(), MAXCLIENTS), server::numchannels(), 0, GETIV(serveruprate));
    if(!serverhost)
    {
        // INTENSITY: Do *NOT* fatally quit on this error. It can lead to repeated restarts etc.
        // of the sort that standby mode is meant to prevent, but standby does not protect from this.
        // So, just wait to be manually restarted.
        //return servererror(dedicated, "could not create server host");
        Logging::log(Logging::ERROR, "***!!! could not create server host (awaiting manual restart) !!!***");
        return false;
    }
    loopi(maxclients) serverhost->peers[i].data = NULL;
    address.port = server::serverinfoport(GETIV(serverport) > 0 ? GETIV(serverport) : -1);
    return true;
}

void initserver(bool listen, bool dedicated)
{
    if(dedicated) lua::engine.execf("server-init.lua", false);

    if(listen) setuplistenserver(dedicated);

    server::serverinit();

    if(listen)
    {
        if(dedicated) rundedicatedserver(); // never returns
#ifndef STANDALONE
        else conoutf("listen server started");
#endif
    }
}

bool serveroption(char *opt)
{
    switch(opt[1])
    {
        case 'u': SETV(serveruprate, atoi(opt+2)); return true;
        case 'c': maxclients = atoi(opt+2); return true;
        case 'i': SETVF(serverip, opt+2); return true;
        case 'j': SETVFN(serverport, atoi(opt+2)); return true; 
        default: return false;
    }
}

vector<const char *> gameargs;

#ifdef SERVER
void server_init()//int argc, char* argv[])
{
    setvbuf(stdout, NULL, _IOLBF, BUFSIZ);
    setlogfile(NULL);
    if(enet_initialize()<0) fatal("Unable to initialise network module");
    atexit(enet_deinitialize);
    enet_time_set(0);

    conoutf("Registering messages");
    MessageSystem::MessageManager::registerAll();

    // Init server
    initserver(true, true);

    // Generate 'dummy' singleton client. This is to whom we send position updates on the server so our internal
    // fpsclient is updates.

    localconnect();
    assert(clients.length() == 1); // Ensure noone else connected before

    fpsent* fpsEntity = dynamic_cast<fpsent*>( game::newclient(0) ); // Create a new fpsclient for this client

    fpsEntity->serverControlled = true; // Mark this as not controlled by server, so we don't try to actually do anything with it
                                        // After all it doesn't really exist

    fpsEntity->uniqueId = DUMMY_SINGLETON_CLIENT_UNIQUE_ID;
    server::getUniqueId(0) = DUMMY_SINGLETON_CLIENT_UNIQUE_ID;
}

void serverkeepalive();

void server_runslice()
{
    /* Keep connection alive?
     * 
    clientkeepalive();
    serverkeepalive();*/

    serverslice(true, 5);

    time_t now = time(0);

    static time_t    total_time = 0;
    if (!total_time) total_time = now;

    curtime    = (long)(1000 * (now - total_time));
    total_time = now;

    if(lastmillis) game::updateworld();

    static time_t shutdown_idle_last_update = 0;
    if (!shutdown_idle_last_update)
         shutdown_idle_last_update = time(0);

    if (server::shutdown_if_idle && (time(0) - shutdown_idle_last_update) >= (server::shutdown_idle_interval))
    {
        if (clients.length() <= 1)
        {
            extern bool should_quit;
            should_quit = true;
        }
        shutdown_idle_last_update = time(0);
    }
}

int main(int argc, char **argv)
{
    // Pre-initializations
    static Texture dummyTexture;

    dummyTexture.name = (char*)"";
    dummyTexture.type = Texture::IMAGE;
    dummyTexture.w = 1;
    dummyTexture.h = 1;
    dummyTexture.xs = 1;
    dummyTexture.ys = 1;
    dummyTexture.bpp = 8;
    dummyTexture.clamp = 1;
    dummyTexture.mipmap = 0;
    dummyTexture.canreduce = 0;
    dummyTexture.id = -1;
    dummyTexture.alphamask = new uchar[100]; // Whatever

    notexture = &dummyTexture;

    setlogfile(NULL);

    char *loglevel  = (char*)"WARNING";
    char *map_asset = NULL;
    for(int i = 1; i < argc; i++)
    {
        if(argv[i][0]=='-') switch(argv[i][1])
        {
            case 'q': 
            {
                const char *dir = sethomedir(&argv[i][2]);
                if(dir) logoutf("Using home directory: %s", dir);
                break;
            }
            case 'g': logoutf("Setting logging level", &argv[i][2]); loglevel = &argv[i][2]; break;
            case 'm': logoutf("Setting map", &argv[i][2]); map_asset = &argv[i][2]; break;
            default:
            {
                if (!strcmp(argv[i], "-shutdown-if-empty"))
                    server::shutdown_if_empty = true;
                else if (!strcmp(argv[i], "-shutdown-if-idle"))
                    server::shutdown_if_idle = true;
                else if (!strcmp(argv[i], "-shutdown-idle-interval"))
                {
                    char *endptr = NULL;
                    int interval = strtol(argv[i + 1], &endptr, 10);
                    if (!endptr && interval) server::shutdown_idle_interval = interval;
                }
            }
        }
        else gameargs.add(argv[i]);
    }
    Logging::init(loglevel);

    if (!map_asset)
    {
        Logging::log(Logging::ERROR, "No map asset to run. Shutting down.");
        return 1;
    }

    lua::engine.create();
    server_init();

    Logging::log(Logging::DEBUG, "Running first slice.\n");
    server_runslice();

    int last_server_update = 0;
    int servermillis = time(0) * 1000;
    while (!should_quit)
    {
        while ((time(0) * 1000) - servermillis < 33)
            continue;

        servermillis = time(0) * 1000;

        if (!should_quit)
            server_runslice();

        if (time(0) - last_server_update >= SERVER_UPDATE_INTERVAL)
        {
            Logging::log(Logging::DEBUG, "Setting map ..\n");
            last_server_update = time(0);
            of_world_set_map(map_asset);
        }
    }

    Logging::log(Logging::WARNING, "Stopping main server.");
    var::flush();

    return 0;
}
#endif

