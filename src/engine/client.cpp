// client.cpp, mostly network related client game code

#include "engine.h"
#include "game.h" // INTENSITY: Need this for gameent, below

#ifndef SERVER
    #include "client_system.h" // INTENSITY
#endif

#include "network_system.h" // INTENSITY



ENetHost *clienthost = NULL;
ENetPeer *curpeer = NULL, *connpeer = NULL;
int connmillis = 0, connattempts = 0, discmillis = 0;

bool multiplayer(bool msg)
{
#ifndef SERVER // INTENSITY
    bool val = !ClientSystem::editingAlone; // INTENSITY
#else // SERVER - the old sauer code
    bool val = curpeer || hasnonlocalclients();
#endif // INTENSITY end
    if(val && msg) conoutf(CON_ERROR, "You must be in private edit mode for that"); // INTENSITY: Message contents
    return val;
}

void setrate(int rate)
{
   if(!curpeer) return;
   enet_host_bandwidth_limit(clienthost, rate*1024, rate*1024);
}

VARF(rate, 0, 0, 1024, setrate(rate));

void throttle();

VARF(throttle_interval, 0, 5, 30, throttle());
VARF(throttle_accel,    0, 2, 32, throttle());
VARF(throttle_decel,    0, 2, 32, throttle());

void throttle()
{
    if(!curpeer) return;
    ASSERT(ENET_PEER_PACKET_THROTTLE_SCALE==32);
    enet_peer_throttle_configure(curpeer, throttle_interval*1000, throttle_accel, throttle_decel);
}

bool isconnected(bool attempt, bool local)
{
    return curpeer || (attempt && connpeer) || (local && haslocalclients());
}

const ENetAddress *connectedpeer()
{
    return curpeer ? &curpeer->address : NULL;
}

void abortconnect()
{
    if(!connpeer) return;
    if(connpeer->state!=ENET_PEER_STATE_DISCONNECTED) enet_peer_reset(connpeer);
    connpeer = NULL;
    if(curpeer) return;
    enet_host_destroy(clienthost);
    clienthost = NULL;
}

SVARP(connectname, "");
VARP(connectport, 0, 0, 0xFFFF);

void connectserv(const char *servername, int serverport, const char *serverpassword)
{
#ifndef SERVER
    if(connpeer)
    {
        conoutf("aborting connection attempt");
        abortconnect();
    }

    if(serverport <= 0) serverport = server::serverport();

    ENetAddress address;
    address.port = serverport;

    if(servername)
    {
        if(strcmp(servername, connectname)) setsvar("connectname", servername);
        if(serverport != connectport) setvar("connectport", serverport);
        conoutf("attempting to connect to %s:%d", servername, serverport);
        if(!resolverwait(servername, &address))
        {
            conoutf("\f3could not resolve server %s", servername);
            return;
        }
    }
    else
    {
        setsvar("connectname", "");
        setvar("connectport", 0);
        conoutf("attempting to connect over LAN");
        address.host = ENET_HOST_BROADCAST;
    }

    if(!clienthost)
        clienthost = enet_host_create(NULL, 2, server::numchannels(), rate*1024, rate*1024);

    if(clienthost)
    {
        connpeer = enet_host_connect(clienthost, &address, server::numchannels(), 0);
        enet_host_flush(clienthost);
        connmillis = totalmillis;
        connattempts = 0;
    }
    else conoutf("\f3could not connect to server");
#endif
}

void disconnect(bool async, bool cleanup)
{
    if(curpeer)
    {
        if(!discmillis)
        {
            enet_peer_disconnect(curpeer, DISC_NONE);
            enet_host_flush(clienthost);
            discmillis = totalmillis;
        }
        if(curpeer->state!=ENET_PEER_STATE_DISCONNECTED)
        {
            if(async) return;
            enet_peer_reset(curpeer);
        }
        curpeer = NULL;
        discmillis = 0;
        conoutf("disconnected");
        game::gamedisconnect(cleanup);
#ifndef SERVER
        mainmenu = 1;
#endif
    }
    if(!connpeer && clienthost)
    {
        enet_host_destroy(clienthost);
        clienthost = NULL;
    }
}

void trydisconnect(bool local)
{
    if(connpeer)
    {
        conoutf("aborting connection attempt");
        abortconnect();
    }
    else if(curpeer)
    {
        conoutf("attempting to disconnect...");
        disconnect(!discmillis);
    }
    else if(local && haslocalclients()) localdisconnect();
    else conoutf("not connected");
}

void sendclientpacket(ENetPacket *packet, int chan, int cn) // INTENSITY: added cn
{
    if(curpeer) enet_peer_send(curpeer, chan, packet);
    else localclienttoserver(chan, packet, cn); // INTENSITY: added cn

    //NetworkSystem::Cataloger::packetSent(chan, packet->dataLength); // INTENSITY
}

void flushclient()
{
    if(clienthost) enet_host_flush(clienthost);
}

void neterr(const char *s, bool disc)
{
    conoutf(CON_ERROR, "\f3illegal network message (%s)", s);
    if(disc) disconnect();
}

void localservertoclient(int chan, ENetPacket *packet)   // processes any updates from the server
{
    packetbuf p(packet);
    game::parsepacketclient(chan, p);
}

void clientkeepalive() { if(clienthost) enet_host_service(clienthost, NULL, 0); }

void gets2c()           // get updates from the server
{
    ENetEvent event;
    if(!clienthost) return;
    if(connpeer && totalmillis/3000 > connmillis/3000)
    {
        conoutf("attempting to connect...");
        connmillis = totalmillis;
        ++connattempts;
        if(connattempts > 3)
        {
            conoutf("\f3could not connect to server");
            abortconnect();
            return;
        }
    }
    while(clienthost && enet_host_service(clienthost, &event, 0)>0)
    switch(event.type)
    {
        case ENET_EVENT_TYPE_CONNECT:
            disconnect(false, false);
            localdisconnect(false);
            curpeer = connpeer;
            connpeer = NULL;
            conoutf("connected to server");
            throttle();
            if(rate) setrate(rate);
            game::gameconnect(true);
            break;

        case ENET_EVENT_TYPE_RECEIVE:
#ifndef SERVER // INTENSITY
            if(discmillis) conoutf("attempting to disconnect...");
            else localservertoclient(event.channelID, event.packet);
            enet_packet_destroy(event.packet);
#else // SERVER
            assert(0);
#endif
            break;

        case ENET_EVENT_TYPE_DISCONNECT:
//            LogicSystem::init(); // INTENSITY: Not sure about this...?

            extern const char *disc_reasons[10]; /* because gcc 4.2 is retarded */
            if(event.data>=DISC_NUM) event.data = DISC_NONE;
            if(event.peer==connpeer)
            {
                conoutf("\f3could not connect to server");
                abortconnect();
            }
            else
            {
                if(!discmillis || event.data) conoutf("\f3server network error, disconnecting (%s) ...", disc_reasons[event.data]);
                disconnect();
            }
            return;

        default:
            break;
    }
}

