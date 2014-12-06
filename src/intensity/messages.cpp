// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.


#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "message_system.h"
#include "of_world.h"

void force_network_flush();
namespace server
{
    int& getUniqueId(int clientNumber);
}

extern ENetPacket *buildfva(const char *format, va_list args, int &exclude);

namespace MessageSystem
{

    void send_AnyMessage(int clientNumber, int chan, ENetPacket *packet, int exclude=-1) {
        INDENT_LOG(logger::DEBUG);

        int start, finish;
        if (clientNumber == -1) 
            start = 0, finish = getnumclients();            // send to all
        else
            start = clientNumber, finish = clientNumber+1;  // send to one

        for (int clientNumber = start; clientNumber < finish; clientNumber++) {
            if (clientNumber == exclude) continue;
            sendpacket(clientNumber, chan, packet, -1);
        }

        if(!packet->referenceCount) enet_packet_destroy(packet);
    }

    CLUAICOMMAND(msg_send, void, (int cn, int exclude, const char *fmt, ...), {
        bool reliable = false;
        va_list args;
        va_start(args, fmt);
        if (*fmt == 'r') { reliable = true; ++fmt; }
        packetbuf p(MAXTRANS, reliable ? ENET_PACKET_FLAG_RELIABLE : 0);
        while (*fmt) switch (*fmt++) {
            case 'i': {
                int n = isdigit(*fmt) ? *fmt++-'0' : 1;
                loopi(n) putint(p, (int)va_arg(args, double));
                break;
            }
            case 'f': {
                int n = isdigit(*fmt) ? *fmt++-'0' : 1;
                loopi(n) putfloat(p, (float)va_arg(args, double));
                break;
            }
            case 's': sendstring(va_arg(args, const char *), p); break;
        }
        va_end(args);
        ENetPacket *packet = p.finalize();
        p.packet = NULL;
        send_AnyMessage(cn, MAIN_CHANNEL, packet, exclude);
    })

// YourUniqueId

    void send_YourUniqueId(int clientNumber, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type YourUniqueId (1004)");
        server::getUniqueId(clientNumber) = uid;
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("rii", 1004, uid));
    }

#ifndef STANDALONE
    void YourUniqueId::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);

        logger::log(logger::DEBUG, "Told my unique ID: %d", uid);
        ClientSystem::uniqueId = uid;
        lua::call_external("player_set_uid", "i", uid);
    }
#endif


// LoginResponse

    void send_LoginResponse(int clientNumber, bool success, bool local)
    {
        logger::log(logger::DEBUG, "Sending a message of type LoginResponse (1005)");
        if (success) server::createluaEntity(clientNumber);

        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("ri", 1005));
    }

#ifndef STANDALONE
    void LoginResponse::receive(int receiver, int sender, ucharbuf &p)
    {
        conoutf("Login was successful.");
        send_RequestCurrentScenario();
    }
#endif


// PrepareForNewScenario

    void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode)
    {
        logger::log(logger::DEBUG, "Sending a message of type PrepareForNewScenario (1006)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("ris", 1006, scenarioCode));
    }

#ifndef STANDALONE
    void PrepareForNewScenario::receive(int receiver, int sender, ucharbuf &p)
    {
        char scenarioCode[MAXTRANS];
        getstring(scenarioCode, p);
        assert(lua::call_external("gui_show_message", "ss", "Server",
            "Map is being prepared on the server, please wait..."));
        ClientSystem::prepareForNewScenario(scenarioCode);
    }
#endif


// RequestCurrentScenario

#ifndef STANDALONE
    void send_RequestCurrentScenario()
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestCurrentScenario (1007)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1007, "r");
    }
#endif

#ifdef STANDALONE
    void RequestCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {

        if (!world::scenario_code[0]) return;
        send_NotifyAboutCurrentScenario(sender, world::curr_map_id, world::scenario_code);
    }
#endif

// NotifyAboutCurrentScenario

    void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc)
    {
        logger::log(logger::DEBUG, "Sending a message of type NotifyAboutCurrentScenario (1008)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riss", 1008, mid, sc));
    }

#ifndef STANDALONE
    void NotifyAboutCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {
        char mid[MAXTRANS];
        getstring(mid, p);
        char sc[MAXTRANS];
        getstring(sc, p);

        copystring(ClientSystem::currScenarioCode, sc);
        world::set_map(mid);
    }
#endif

// AllActiveEntitiesSent

    void send_AllActiveEntitiesSent(int clientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type AllActiveEntitiesSent (1016)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("ri", 1016));
    }

#ifndef STANDALONE
    void AllActiveEntitiesSent::receive(int receiver, int sender, ucharbuf &p)
    {
        ClientSystem::finishLoadWorld();
    }
#endif


// ActiveEntitiesRequest

#ifndef STANDALONE
    void send_ActiveEntitiesRequest(const char* scenarioCode)
    {
        logger::log(logger::DEBUG, "Sending a message of type ActiveEntitiesRequest (1017)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1017, "rs", scenarioCode);
    }
#endif

#ifdef STANDALONE
    void ActiveEntitiesRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        char scenarioCode[MAXTRANS];
        getstring(scenarioCode, p);

        if (!world::scenario_code[0]) return;
        // Mark the client as running the current scenario, if indeed doing so
        server::setClientScenario(sender, scenarioCode);
        if ( !server::isRunningCurrentScenario(sender) )
        {
            logger::log(logger::WARNING, "Client %d requested active entities for an invalid scenario: %s",
                sender, scenarioCode
            );
            lua::call_external("show_client_message", "iss", sender, "Invalid scenario", "An error occured in synchronizing scenarios");
            return;
        }
        assert(lua::call_external("entities_send_all", "i", sender));
        MessageSystem::send_AllActiveEntitiesSent(sender);
        assert(lua::call_external("event_player_login", "i", server::getUniqueId(sender)));
    }
#endif

// InitS2C

    void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion)
    {
        logger::log(logger::DEBUG, "Sending a message of type InitS2C (1022)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riii", 1022, explicitClientNumber, protocolVersion));
    }

#ifndef STANDALONE
    void InitS2C::receive(int receiver, int sender, ucharbuf &p)
    {
        int explicitClientNumber = getint(p);
        int protocolVersion = getint(p);

        logger::log(logger::DEBUG, "client.h: N_INITS2C gave us cn/protocol: %d/%d", explicitClientNumber, protocolVersion);
        if(protocolVersion != PROTOCOL_VERSION)
        {
            conoutf(CON_ERROR, "You are using a different network protocol (you: %d, server: %d)", PROTOCOL_VERSION, protocolVersion);
            disconnect();
            return;
        }
            gameent *player1 = game::player1;
        player1->clientnum = explicitClientNumber; // we are now fully connected
                                                   // Kripken: Well, sauer would be, we still need more...
        ClientSystem::login(explicitClientNumber); // Finish the login process, send server our user/pass.
    }
#endif

// EditModeC2S

#ifndef STANDALONE
    void send_EditModeC2S(int mode)
    {
        logger::log(logger::DEBUG, "Sending a message of type EditModeC2S (1028)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1028, "ri", mode);
    }
#endif

#ifdef STANDALONE
    void EditModeC2S::receive(int receiver, int sender, ucharbuf &p)
    {
        int mode = getint(p);

        if (!world::scenario_code[0] || !server::isRunningCurrentScenario(sender)) return;
        send_EditModeS2C(-1, sender, mode); // Relay
    }
#endif

// EditModeS2C

#ifdef STANDALONE
    void send_EditModeS2C(int clientNumber, int otherClientNumber, int mode)
    {
        logger::log(logger::DEBUG, "Sending a message of type EditModeS2C (1029)");

        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riii", 1029, otherClientNumber, mode), otherClientNumber);
    }
#endif

#ifndef STANDALONE
    void EditModeS2C::receive(int receiver, int sender, ucharbuf &p)
    {
        int otherClientNumber = getint(p);
        int mode = getint(p);

        dynent* d = game::getclient(otherClientNumber);
        // Code from sauer's client.h
        if (d)
        {
            if (mode) 
            {
                d->editstate = d->state;
                d->state     = CS_EDITING;
            }
            else 
            {
                d->state = d->editstate;
            }
        }
    }
#endif

// Register all messages

void MessageManager::registerAll()
{
    registerMessageType( new YourUniqueId() );
    registerMessageType( new LoginResponse() );
    registerMessageType( new PrepareForNewScenario() );
    registerMessageType( new RequestCurrentScenario() );
    registerMessageType( new NotifyAboutCurrentScenario() );
    registerMessageType( new AllActiveEntitiesSent() );
    registerMessageType( new ActiveEntitiesRequest() );
    registerMessageType( new InitS2C() );
    registerMessageType( new EditModeC2S() );
    registerMessageType( new EditModeS2C() );
}

}

