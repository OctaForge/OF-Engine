
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
    lua::push_external("cursor_reset"); lua_call(lua::L,  0, 0);
})

#define QUOT(arg) #arg

#define MOUSECLICK(num) \
void mouse##num##click() { \
    bool down = (addreleaseaction(newstring(QUOT(mouse##num##click))) != 0); \
    logger::log(logger::INFO, "mouse click: %i (down: %i)\n", num, down); \
\
    if (!(lua::L && ClientSystem::scenarioStarted())) \
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
    lua::push_external("cursor_get_position"); \
    lua_call(lua::L, 0, 2); \
\
    float x = lua_tonumber(lua::L, -2); \
    float y = lua_tonumber(lua::L, -1); \
    lua_pop(lua::L, 2); \
\
    assert(lua::push_external("input_click")); \
    lua_pushinteger(lua::L, num); \
    lua_pushboolean(lua::L, down); \
    lua_pushnumber (lua::L, pos.x); \
    lua_pushnumber (lua::L, pos.y); \
    lua_pushnumber (lua::L, pos.z); \
    if (tle && !tle->isNone()) { \
        lua_rawgeti(lua::L, LUA_REGISTRYINDEX, tle->lua_ref); \
    } else { \
        lua_pushnil(lua::L); \
    } \
    lua_pushnumber (lua::L, x); \
    lua_pushnumber (lua::L, y); \
    lua_call       (lua::L, 8, 0); \
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
        lua_rawgeti (lua::L, LUA_REGISTRYINDEX, e->lua_ref); \
        lua_getfield(lua::L, -1, "clear_actions"); \
        lua_insert  (lua::L, -2); \
        lua_call    (lua::L, 1, 0); \
\
        s = (addreleaseaction(newstring(#name)) != 0); \
\
        lua_getglobal(lua::L, "LAPI"); lua_getfield(lua::L, -1, "Input"); \
        lua_getfield (lua::L, -1, "Events"); lua_getfield(lua::L, -1, "Client"); \
        lua_getfield (lua::L, -1, #v); \
        lua_pushinteger(lua::L, s ? d : (os ? -(d) : 0)); \
        lua_pushboolean(lua::L, s); \
        lua_call(lua::L, 2, 0); lua_pop(lua::L, 4); \
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
        lua_rawgeti (lua::L, LUA_REGISTRYINDEX, e->lua_ref);
        lua_getfield(lua::L, -1, "clear_actions");
        lua_insert  (lua::L, -2);
        lua_call    (lua::L, 1, 0);

        bool down = (addreleaseaction(newstring("jump")) != 0);

        lua_getglobal(lua::L, "LAPI"); lua_getfield(lua::L, -1, "Input");
        lua_getfield (lua::L, -1, "Events"); lua_getfield(lua::L, -1, "Client");
        lua_getfield (lua::L, -1, "jump");
        lua_pushboolean(lua::L, down);
        lua_call(lua::L, 1, 0); lua_pop(lua::L, 4);
    }
});
