
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "client_engine_additions.h"
#include "targeting.h"
#include "message_system.h"

//=========================
// GUI stuff
//=========================

bool _isMouselooking = true; // Default like sauer

bool GuiControl::isMouselooking()
    { return _isMouselooking; };


void GuiControl::toggleMouselook()
{
    if (_isMouselooking)
        _isMouselooking = false;
    else
        _isMouselooking = true;

    lapi::state.get<lua::Function>("external", "cursor_reset")();
};

void GuiControl::menuKeyClickTrigger()
{
    playsound(S_MENUCLICK);
}
