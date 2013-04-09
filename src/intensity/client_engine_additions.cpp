
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "targeting.h"
#include "message_system.h"

using namespace MessageSystem;

// Input

VARF(mouselook, 0, 1, 1, {
    lapi::state.get<lua::Function>("external", "cursor_reset")();
})

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
    lua_State *L = lapi::state.state(); \
    lua_getglobal(L, "LAPI"); lua_getfield(L, -1, "Input"); \
    lua_getfield (L, -1, "Events"); lua_getfield(L, -1, "Client"); \
    lua_getfield (L, -1, "click"); \
    lua_pushinteger(L, num); lua_pushboolean (L, down); \
    lua_pushnumber (L, pos.x); lua_pushnumber(L, pos.y); \
    lua_pushnumber (L, pos.z); \
    if (tle && !tle->isNone()) { \
        lua_rawgeti(L, LUA_REGISTRYINDEX, tle->lua_ref); \
    } else { \
        lua_pushnil(L); \
    } \
    lua_pushnumber(L, x); lua_pushnumber(L, y); \
    lua_call(L, 8, 1); \
    bool b = lua_toboolean(L, -1); \
    lua_pop(L, 5); \
    if (b) send_DoClick(num, (int)down, pos.x, pos.y, pos.z, uid); \
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
        lua_State *L = lapi::state.state(); \
        lua_rawgeti (L, LUA_REGISTRYINDEX, e->lua_ref); \
        lua_getfield(L, -1, "clear_actions"); \
        lua_insert  (L, -2); \
        lua_call    (L, 1, 0); \
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
        lua_State *L = lapi::state.state();
        lua_rawgeti (L, LUA_REGISTRYINDEX, e->lua_ref);
        lua_getfield(L, -1, "clear_actions");
        lua_insert  (L, -2);
        lua_call    (L, 1, 0);

        bool down = (addreleaseaction(newstring("jump")) != 0);

        lapi::state.get<lua::Function>(
            "LAPI", "Input", "Events", "Client", "jump"
        )(down);
    }
});
