// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.


#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "message_system.h"
#include "of_world.h"

namespace MessageSystem
{
// YourUniqueId
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

#ifndef STANDALONE
    void LoginResponse::receive(int receiver, int sender, ucharbuf &p)
    {
        conoutf("Login was successful.");
        game::addmsg(N_REQUESTCURRENTSCENARIO, "r");
    }
#endif


// PrepareForNewScenario

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

#ifdef STANDALONE
    void RequestCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {

        if (!world::scenario_code[0]) return;
        sendf(-1, 1, "riss", N_NOTIFYABOUTCURRENTSCENARIO, world::curr_map_id, world::scenario_code);
    }
#endif

// NotifyAboutCurrentScenario

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

#ifndef STANDALONE
    void AllActiveEntitiesSent::receive(int receiver, int sender, ucharbuf &p)
    {
        ClientSystem::finishLoadWorld();
    }
#endif

// InitS2C

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

#ifdef STANDALONE
    void EditModeC2S::receive(int receiver, int sender, ucharbuf &p)
    {
        int mode = getint(p);

        if (!world::scenario_code[0] || !server::isRunningCurrentScenario(sender)) return;
        sendf(-1, 1, "rxiii", sender, N_EDITMODES2C, sender, mode); // Relay
    }
#endif

// EditModeS2C

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

