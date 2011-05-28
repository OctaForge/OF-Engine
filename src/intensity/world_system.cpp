
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"

#include "world_system.h"
#include "of_tools.h"

using namespace lua;

bool WorldSystem::loadingWorld = false;

int numExpectedEntities = 0;
int numReceivedEntities = 0;

void WorldSystem::setNumExpectedEntities(int num)
{
    numExpectedEntities = num;
    numReceivedEntities = 0;
}

void WorldSystem::triggerReceivedEntity()
{
    numReceivedEntities += 1;

    if (numExpectedEntities > 0)
    {
        float val = float(numReceivedEntities)/float(numExpectedEntities);
        val = clamp(val, 0.0f, 1.0f);
        char *text = new char[32];
        snprintf(text, 32, "received entity %i...", numReceivedEntities);
        if (WorldSystem::loadingWorld) // Show message only during map loading, not when new clients log in
            renderprogress(val, text);
        delete[] text;
    }
}
