
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"

#ifdef CLIENT
    #include "client_system.h"
#endif

#include "system_manager.h"


//==================================
// System
//==================================

void SystemManager::init()
{
    printf("SystemManager::init()\r\n");

    lua::engine.create(); // init lua engine if required. It'll simply return if already initialized

    printf("SystemManager::MessageSystem setup\r\n");
    MessageSystem::MessageManager::registerAll();
}

void SystemManager::quit()
{
    lua::engine.destroy();
}

void SystemManager::frameTrigger(int curtime)
{
    #ifdef CLIENT
        ClientSystem::frameTrigger(curtime);
    #endif
}

