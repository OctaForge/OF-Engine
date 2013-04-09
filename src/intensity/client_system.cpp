
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"

#include "editing_system.h"
#include "targeting.h"

#include "client_system.h"
#include "of_world.h"

int            ClientSystem::playerNumber       = -1;
CLogicEntity  *ClientSystem::playerLogicEntity  = NULL;
bool           ClientSystem::loggedIn           = false;
bool           ClientSystem::editingAlone       = false;
int            ClientSystem::uniqueId           = -1;
types::String  ClientSystem::currScenarioCode   = "";

bool _scenarioStarted = false;
bool _mapCompletelyReceived = false;

namespace game
{
    extern int minimapradius;
    extern int minimaprightalign;
    extern int forceminminimapzoom, forcemaxminimapzoom;
    extern int minimapsides;
    extern int minminimapzoom, maxminimapzoom;
    extern float minimapxpos, minimapypos, minimaprotation;
}


void ClientSystem::connect(const char *host, int port)
{
    editingAlone = false;

    connectserv((char *)host, port, "");
}

void ClientSystem::login(int clientNumber)
{
    logger::log(logger::DEBUG, "ClientSystem::login()\r\n");

    playerNumber = clientNumber;

    MessageSystem::send_LoginRequest();
}

void ClientSystem::finishLogin(bool local)
{
    editingAlone = local;
    loggedIn = true;

    logger::log(logger::DEBUG, "Now logged in, with unique_ID: %d\r\n", uniqueId);
}

void ClientSystem::doDisconnect()
{
    disconnect();
}

void ClientSystem::onDisconnect()
{
    editingAlone = false;
    playerNumber = -1;
    loggedIn     = false;
    _scenarioStarted  = false;
    _mapCompletelyReceived = false;

    // it's also useful to stop all mapsounds and gamesounds (but only for client that disconnects!)
    stopsounds();

    // we also must get the lua system into clear state
    LogicSystem::clear(true);
}

bool ClientSystem::scenarioStarted()
{
    if (!_mapCompletelyReceived)
        logger::log(logger::INFO, "Map not completely received, so scenario not started\r\n");

    // If not already started, test if indeed started
    if (_mapCompletelyReceived && !_scenarioStarted)
    {
        if (lapi::L)
            _scenarioStarted = lapi::state.get<lua::Function>("external", "scene_is_ready").call<bool>();
    }

    return _mapCompletelyReceived && _scenarioStarted;
}

void ClientSystem::frameTrigger(int curtime)
{
    if (scenarioStarted())
    {
        float delta = float(curtime)/1000.0f;

        /* turn if mouse is at borders */
        auto t = lapi::state.get<lua::Function>("external",
            "cursor_get_position").call<float, float>();

        float x = types::get<0>(t);
        float y = types::get<1>(t);

        bool b = lapi::state.get<lua::Function>("external",
            "cursor_exists").call<bool>();

        /* do not scroll with mouse */
        if (b) x = y = 0.5;

        /* turning */
        fpsent *fp = (fpsent*)player;
        lua_rawgeti (lapi::L, LUA_REGISTRYINDEX, ClientSystem::playerLogicEntity->lua_ref);
        lua_getfield(lapi::L, -1, "facing_speed");
        float fs = lua_tonumber(lapi::L, -1); lua_pop(lapi::L, 2);

        if (fp->turn_move || fabs(x - 0.5) > 0.45)
        {
            player->yaw += fs * (
                fp->turn_move ? fp->turn_move : (x > 0.5 ? 1 : -1)
            ) * delta;
        }

        if (fp->look_updown_move || fabs(y - 0.5) > 0.45)
        {
            player->pitch += fs * (
                fp->look_updown_move ? fp->look_updown_move : (y > 0.5 ? -1 : 1)
            ) * delta;
        }

        /* normalize and limit the yaw and pitch values to appropriate ranges */
        extern void fixcamerarange();
        fixcamerarange();

        TargetingControl::determineMouseTarget();
        dobgload();
    }
}

void ClientSystem::finishLoadWorld()
{
    extern bool finish_load_world();
    finish_load_world();

    _mapCompletelyReceived = true; // We have the original map + static entities (still, scenarioStarted might want more stuff)

    EditingSystem::madeChanges = false; // Clean the slate

    ClientSystem::editingAlone = false; // Assume not in this mode

    lapi::state.get<lua::Function>("external", "gui_clear")(); // (see prepareForMap)
}

void ClientSystem::prepareForNewScenario(const types::String& sc)
{
    _mapCompletelyReceived = false; // We no longer have a map. This implies scenarioStarted will return false, thus
                                    // stopping sending of position updates, as well as rendering

    mainmenu = 1; // Keep showing GUI meanwhile (in particular, to show the message about a new map on the way

    // Clear the logic system, as it is no longer valid - were it running, we might try to process messages from
    // the new map being set up on the server, even though they are irrelevant to the existing engine, set up for
    // another map with its Classes etc.
    LogicSystem::clear();

    currScenarioCode = sc;
}

bool ClientSystem::isAdmin()
{
    if (!loggedIn) return false;
    if (!playerLogicEntity) return false;

    lua_rawgeti (lapi::L, LUA_REGISTRYINDEX, playerLogicEntity->lua_ref);
    lua_getfield(lapi::L, -1, "can_edit");
    bool b = lua_toboolean(lapi::L, -1); lua_pop(lapi::L, 2);
    return b;
}

