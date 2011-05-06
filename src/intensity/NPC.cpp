
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "fpsserver_interface.h"

#include "NPC.h"
#include "of_tools.h"

namespace NPC
{

int add(std::string _class)
{
    int cn = localconnect(); // Local connect to the server
    char *uname = FPSServerInterface::getUsername(cn);
    if (uname) OF_FREE(uname);

    uname = of_tools_vstrcat(NULL, "si", "Bot.", cn); // Also sets as valid ('logged in')
    Logging::log(Logging::DEBUG, "New NPC with client number: %d\r\n", cn);

    // Create lua entity (players do this when they log in, NPCs do it here
    return server::createluaEntity(cn, _class);
}

void remove(int clientNumber)
{
    localdisconnect(true, clientNumber);
}

};

