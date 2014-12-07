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
// RequestCurrentScenario

#ifdef STANDALONE
    void RequestCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {

        if (!world::scenario_code[0]) return;
        sendf(-1, 1, "riss", N_NOTIFYABOUTCURRENTSCENARIO, world::curr_map_id, world::scenario_code);
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
    registerMessageType( new RequestCurrentScenario() );
    registerMessageType( new InitS2C() );
    registerMessageType( new EditModeC2S() );
    registerMessageType( new EditModeS2C() );
}

}

