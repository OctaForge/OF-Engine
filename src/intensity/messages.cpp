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
// YourUniqueId

    void send_YourUniqueId(int clientNumber, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type YourUniqueId (1004)");
        server::getUniqueId(clientNumber) = uid;
        sendf(clientNumber, MAIN_CHANNEL, "rii", 1004, uid);
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
        sendf(clientNumber, MAIN_CHANNEL, "ri", 1005);
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
        sendf(clientNumber, MAIN_CHANNEL, "ris", 1006, scenarioCode);
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
        sendf(clientNumber, MAIN_CHANNEL, "riss", 1008, mid, sc);
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
        sendf(clientNumber, MAIN_CHANNEL, "ri", 1016);
    }

#ifndef STANDALONE
    void AllActiveEntitiesSent::receive(int receiver, int sender, ucharbuf &p)
    {
        ClientSystem::finishLoadWorld();
    }
#endif

// InitS2C

    void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion)
    {
        logger::log(logger::DEBUG, "Sending a message of type InitS2C (1022)");
        sendf(clientNumber, MAIN_CHANNEL, "riii", 1022, explicitClientNumber, protocolVersion);
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
        sendf(clientNumber, MAIN_CHANNEL, "rxiii", otherClientNumber, 1029, otherClientNumber, mode);
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
    registerMessageType( new InitS2C() );
    registerMessageType( new EditModeC2S() );
    registerMessageType( new EditModeS2C() );
}

}

