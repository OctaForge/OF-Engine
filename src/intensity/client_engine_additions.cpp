
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "client_engine_additions.h"
#include "targeting.h"
#include "message_system.h"

using namespace MessageSystem;

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

// Input

#define QUOT(arg) #arg

#define MOUSECLICK(num) \
void mouse##num##click() { \
    bool down = (addreleaseaction(newstring(QUOT(mouse##num##click))) != 0); \
    logger::log(logger::INFO, "mouse click: %i (down: %i)\n", num, down); \
\
    if (!(lapi::state.state() && ClientSystem::scenarioStarted())) \
        return; \
\
    TargetingControl::determineMouseTarget(true); \
    vec pos = TargetingControl::targetPosition; \
\
    CLogicEntity *tle = TargetingControl::targetLogicEntity; \
\
    int uid = -1; \
    if (tle && !tle->isNone()) uid = tle->getUniqueId(); \
\
    auto t = lapi::state.get<lua::Function>("external", "cursor_get_position") \
        .call<float, float>(); \
\
    float x = types::get<0>(t); \
    float y = types::get<1>(t); \
\
    if (!lapi::state.get<lua::Function>( \
        "LAPI", "Input", "Events", "Client", "click" \
    ).call<bool>( \
        num, down, pos.x, pos.y, pos.z, \
        ((tle && !tle->isNone()) ? tle->lua_ref : \
            lapi::state.wrap<lua::Table>(lua::nil) \
        ), \
        x, y \
    )) send_DoClick(num, (int)down, pos.x, pos.y, pos.z, uid); \
} \
COMMAND(mouse##num##click, "");

MOUSECLICK(1)
MOUSECLICK(2)
MOUSECLICK(3)
#undef QUOT

bool k_turn_left, k_turn_right, k_look_up, k_look_down;

#define SCRIPT_DIR(name, v, p, d, s, os) \
ICOMMAND(name, "", (), { \
    if (ClientSystem::scenarioStarted()) \
    { \
        CLogicEntity *e = ClientSystem::playerLogicEntity; \
        e->lua_ref.get<lua::Function>("clear_actions")(e->lua_ref); \
\
        s = (addreleaseaction(newstring(#name)) != 0); \
\
        lapi::state.get<lua::Function>( \
            "LAPI", "Input", "Events", "Client", #v \
        )((s ? d : (os ? -(d) : 0)), s); \
    } \
});

SCRIPT_DIR(turn_left,  yaw, yawing, -1, k_turn_left,  k_turn_right);
SCRIPT_DIR(turn_right, yaw, yawing, +1, k_turn_right, k_turn_left);
SCRIPT_DIR(look_down, pitch, pitching, -1, k_look_down, k_look_up);
SCRIPT_DIR(look_up,   pitch, pitching, +1, k_look_up,   k_look_down);

// Old player movements
SCRIPT_DIR(backward, move, move, -1, player->k_down,  player->k_up);
SCRIPT_DIR(forward, move, move,  1, player->k_up,   player->k_down);
SCRIPT_DIR(left,   strafe, strafe,  1, player->k_left, player->k_right);
SCRIPT_DIR(right, strafe, strafe, -1, player->k_right, player->k_left);

ICOMMAND(jump, "", (), {
    if (ClientSystem::scenarioStarted())
    {
        CLogicEntity *e = ClientSystem::playerLogicEntity;
        e->lua_ref.get<lua::Function>("clear_actions")(e->lua_ref);

        bool down = (addreleaseaction(newstring("jump")) != 0);

        lapi::state.get<lua::Function>(
            "LAPI", "Input", "Events", "Client", "jump"
        )(down);
    }
});
