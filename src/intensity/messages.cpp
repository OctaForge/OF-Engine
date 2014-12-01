// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.


#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "message_system.h"
#include "of_world.h"

void force_network_flush();
namespace server
{
    int& getUniqueId(int clientNumber);
}

namespace MessageSystem
{

    void send_AnyMessage(int clientNumber, int chan, ENetPacket *packet, int exclude=-1) {
        INDENT_LOG(logger::DEBUG);

        int start, finish;
        if (clientNumber == -1) 
            start = 0, finish = getnumclients();            // send to all
        else
            start = clientNumber, finish = clientNumber+1;  // send to one

        for (int clientNumber = start; clientNumber < finish; clientNumber++) {
            if (clientNumber == exclude) continue;
            sendpacket(clientNumber, chan, packet, -1);
        }

        if(!packet->referenceCount) enet_packet_destroy(packet);
    }

    // PersonalServerMessage

    void send_PersonalServerMessage(int clientNumber, const char* title, const char* content)
    {
        logger::log(logger::DEBUG, "Sending a message of type PersonalServerMessage (1001)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riss", 1001, title, content));
    }

#ifndef STANDALONE
    void PersonalServerMessage::receive(int receiver, int sender, ucharbuf &p)
    {
        char title[MAXTRANS];
        getstring(title, p);
        char content[MAXTRANS];
        getstring(content, p);
        assert(lua::call_external("gui_show_message", "ss", title, content));
    }
#endif

// LoginRequest

#ifndef STANDALONE
    void send_LoginRequest()
    {
        logger::log(logger::DEBUG, "Sending a message of type LoginRequest (1003)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1003, "r");
    }
#endif

#ifdef STANDALONE
    void LoginRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        if (!world::scenario_code[0])
        {
            send_PersonalServerMessage(
                sender,
                "Login failure",
                "Login failure: instance is not running a map"
            );
            force_network_flush();
            disconnect_client(sender, 3); // DISC_KICK .. most relevant for now
        }
        server::setAdmin(sender, true);
        send_LoginResponse(sender, true, true);
    }
#endif

// YourUniqueId

    void send_YourUniqueId(int clientNumber, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type YourUniqueId (1004)");
        server::getUniqueId(clientNumber) = uid;
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("rii", 1004, uid));
    }

#ifndef STANDALONE
    void YourUniqueId::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);

        logger::log(logger::DEBUG, "Told my unique ID: %d", uid);
        ClientSystem::uniqueId = uid;
    }
#endif


// LoginResponse

    void send_LoginResponse(int clientNumber, bool success, bool local)
    {
        logger::log(logger::DEBUG, "Sending a message of type LoginResponse (1005)");
        if (success) server::createluaEntity(clientNumber);

        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("ri", 1005));
    }

#ifndef STANDALONE
    void LoginResponse::receive(int receiver, int sender, ucharbuf &p)
    {
        conoutf("Login was successful.");
        send_RequestCurrentScenario();
    }
#endif


// PrepareForNewScenario

    void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode)
    {
        logger::log(logger::DEBUG, "Sending a message of type PrepareForNewScenario (1006)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("ris", 1006, scenarioCode));
    }

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

#ifndef STANDALONE
    void send_RequestCurrentScenario()
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestCurrentScenario (1007)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1007, "r");
    }
#endif

#ifdef STANDALONE
    void RequestCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {

        if (!world::scenario_code[0]) return;
        send_NotifyAboutCurrentScenario(sender, world::curr_map_id, world::scenario_code);
    }
#endif

// NotifyAboutCurrentScenario

    void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc)
    {
        logger::log(logger::DEBUG, "Sending a message of type NotifyAboutCurrentScenario (1008)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riss", 1008, mid, sc));
    }

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


// NewEntityRequest

#ifndef STANDALONE
    void send_NewEntityRequest(const char* _class, float x, float y, float z, const char* stateData, const char *newent_data)
    {
        logger::log(logger::DEBUG, "Sending a message of type NewEntityRequest (1010)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1010, "rsiiiss", _class, int(x*DMF), int(y*DMF), int(z*DMF), stateData, newent_data);
    }
#endif

#ifdef STANDALONE
    void NewEntityRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        char _class[MAXTRANS];
        getstring(_class, p);
        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;
        char stateData[MAXTRANS];
        getstring(stateData, p);
        char newent_data[MAXTRANS];
        getstring(newent_data, p);

        if (!world::scenario_code[0]) return;
        if (!server::isAdmin(sender))
        {
            logger::log(logger::WARNING, "Non-admin tried to add an entity");
            send_PersonalServerMessage(sender, "Server", "You are not an administrator, and cannot create entities");
            return;
        }
        // Validate class
        bool b;
        lua::pop_external_ret(lua::call_external_ret("entity_proto_exists", "s", "b", _class, &b));
        if (!b) return;
        // Add entity
        logger::log(logger::DEBUG, "Creating new entity, %s   %f,%f,%f   %s|%s", _class, x, y, z, stateData, newent_data);
        if ( !server::isRunningCurrentScenario(sender) ) return; // Silently ignore info from previous scenario
        // Create
        lua::call_external("entity_new_with_sd", "sfffss", _class, x, y, z, stateData, newent_data);
    }
#endif

// StateDataUpdate

#ifdef STANDALONE
    void send_StateDataUpdate(int clientNumber, int uid, int keyProtocolId, const char* value, int originalClientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type StateDataUpdate (1011)");
        INDENT_LOG(logger::DEBUG);

        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riiisi", 1011, uid, keyProtocolId, value, originalClientNumber), originalClientNumber);
    }
#endif

#ifndef STANDALONE
    void StateDataUpdate::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);
        int keyProtocolId = getint(p);
        char value[MAXTRANS];
        getstring(value, p);
        int originalClientNumber = getint(p);

        #define STATE_DATA_UPDATE \
            assert(originalClientNumber == -1 || ClientSystem::playerNumber != originalClientNumber); /* Can be -1, or else cannot be us */ \
            \
            logger::log(logger::DEBUG, "StateDataUpdate: %d, %d, %s", uid, keyProtocolId, value); \
            \
            if (!LogicSystem::initialized) \
                return; \
            lua::call_external("entity_set_sdata", "iis", uid, keyProtocolId, value);
        STATE_DATA_UPDATE
    }
#endif


// StateDataChangeRequest

#ifndef STANDALONE
    void send_StateDataChangeRequest(int uid, int keyProtocolId, const char* value)
    {        // This isn't a perfect way to differentiate transient state data changes from permanent ones
        // that justify saying 'changes were made', but for now it will do. Note that even checking
        // for changes to persistent entities is not enough - transient changes on them are generally
        // not expected to count as 'changes'. So this check, of editmode, is the best simple solution
        // there is - if you're in edit mode, the change counts as a 'real change', that you probably
        // want saved.
        // Note: We don't do this with unreliable messages, meaningless anyhow.

        logger::log(logger::DEBUG, "Sending a message of type StateDataChangeRequest (1012)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1012, "riis", uid, keyProtocolId, value);
    }
#endif

#ifdef STANDALONE
    void StateDataChangeRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);
        int keyProtocolId = getint(p);
        char value[MAXTRANS];
        getstring(value, p);

        if (!world::scenario_code[0]) return;
        #define STATE_DATA_REQUEST \
        int actorUniqueId = server::getUniqueId(sender); \
        \
        logger::log(logger::DEBUG, "client %d requests to change %d to value: %s", actorUniqueId, keyProtocolId, value); \
        \
        if ( !server::isRunningCurrentScenario(sender) ) return; /* Silently ignore info from previous scenario */ \
        lua::call_external("entity_set_sdata", "iisi", uid, keyProtocolId, value, actorUniqueId);
        STATE_DATA_REQUEST
    }
#endif

// UnreliableStateDataUpdate

#ifdef STANDALONE
    void send_UnreliableStateDataUpdate(int clientNumber, int uid, int keyProtocolId, const char* value, int originalClientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type UnreliableStateDataUpdate (1013)");

        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("iiisi", 1013, uid, keyProtocolId, value, originalClientNumber), originalClientNumber);
    }
#endif

#ifndef STANDALONE
    void UnreliableStateDataUpdate::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);
        int keyProtocolId = getint(p);
        char value[MAXTRANS];
        getstring(value, p);
        int originalClientNumber = getint(p);

        STATE_DATA_UPDATE
    }
#endif


// UnreliableStateDataChangeRequest

#ifndef STANDALONE
    void send_UnreliableStateDataChangeRequest(int uid, int keyProtocolId, const char* value)
    {
        logger::log(logger::DEBUG, "Sending a message of type UnreliableStateDataChangeRequest (1014)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1014, "iis", uid, keyProtocolId, value);
    }
#endif

#ifdef STANDALONE
    void UnreliableStateDataChangeRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);
        int keyProtocolId = getint(p);
        char value[MAXTRANS];
        getstring(value, p);

        if (!world::scenario_code[0]) return;
        STATE_DATA_REQUEST
    }
#endif

// AllActiveEntitiesSent

    void send_AllActiveEntitiesSent(int clientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type AllActiveEntitiesSent (1016)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("ri", 1016));
    }

#ifndef STANDALONE
    void AllActiveEntitiesSent::receive(int receiver, int sender, ucharbuf &p)
    {
        ClientSystem::finishLoadWorld();
    }
#endif


// ActiveEntitiesRequest

#ifndef STANDALONE
    void send_ActiveEntitiesRequest(const char* scenarioCode)
    {
        logger::log(logger::DEBUG, "Sending a message of type ActiveEntitiesRequest (1017)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1017, "rs", scenarioCode);
    }
#endif

#ifdef STANDALONE
    void ActiveEntitiesRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        char scenarioCode[MAXTRANS];
        getstring(scenarioCode, p);

        if (!world::scenario_code[0]) return;
        // Mark the client as running the current scenario, if indeed doing so
        server::setClientScenario(sender, scenarioCode);
        if ( !server::isRunningCurrentScenario(sender) )
        {
            logger::log(logger::WARNING, "Client %d requested active entities for an invalid scenario: %s",
                sender, scenarioCode
            );
            send_PersonalServerMessage(sender, "Invalid scenario", "An error occured in synchronizing scenarios");
            return;
        }
        assert(lua::call_external("entities_send_all", "i", sender));
        MessageSystem::send_AllActiveEntitiesSent(sender);
        assert(lua::call_external("event_player_login", "i", server::getUniqueId(sender)));
    }
#endif

// LogicEntityCompleteNotification

#ifdef STANDALONE
    void send_LogicEntityCompleteNotification(int clientNumber, int otherClientNumber, int otherUniqueId, const char* otherClass, const char* stateData)
    {
        logger::log(logger::DEBUG, "Sending a message of type LogicEntityCompleteNotification (1018)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riiiss", 1018, otherClientNumber, otherUniqueId, otherClass, stateData));
    }
#endif

#ifndef STANDALONE
    void LogicEntityCompleteNotification::receive(int receiver, int sender, ucharbuf &p)
    {
        int otherClientNumber = getint(p);
        int otherUniqueId = getint(p);
        char otherClass[MAXTRANS];
        getstring(otherClass, p);
        char stateData[MAXTRANS];
        getstring(stateData, p);

        if (!LogicSystem::initialized)
            return;
        logger::log(logger::DEBUG, "RECEIVING LE: %d,%d,%s", otherClientNumber, otherUniqueId, otherClass);
        INDENT_LOG(logger::DEBUG);
        // If a logic entity does not yet exist, create one
        bool ent_exists = false;
        lua::pop_external_ret(lua::call_external_ret("entity_exists", "i", "b", otherUniqueId, &ent_exists));
        if (!ent_exists)
        {
            if (otherClientNumber >= 0) // If this is another client, then send the clientnumber, critical for setup
            {
                // If this is the player, validate it is the clientNumber we already have
                if (otherUniqueId == ClientSystem::uniqueId)
                {
                    logger::log(logger::DEBUG, "This is the player's entity (%d), validating client num: %d,%d",
                        otherUniqueId, otherClientNumber, ClientSystem::playerNumber);
                    assert(otherClientNumber == ClientSystem::playerNumber);
                }
            }
            lua::pop_external_ret(lua::call_external_ret("entity_add_with_cn", "sii", "b", otherClass, otherUniqueId, otherClientNumber, &ent_exists));
            if (!ent_exists)
            {
                logger::log(logger::ERROR, "Received a LogicEntityCompleteNotification for a LogicEntity that cannot be created: %d - %s. Ignoring", otherUniqueId, otherClass);
                return;
            }
        } else
            logger::log(logger::DEBUG, "Existing LogicEntity %d, no need to create", otherUniqueId);
        // A logic entity now exists (either one did before, or we created one), we now update the stateData, if we
        // are remotely connected (TODO: make this not segfault for localconnect)
        logger::log(logger::DEBUG, "Updating stateData with: %s", stateData);
        lua::call_external("entity_set_sdata_full", "is", otherUniqueId, stateData);
        // If this new entity is in fact the Player's entity, then we finally have the player's LE, and can link to it.
        if (otherUniqueId == ClientSystem::uniqueId)
        {
            logger::log(logger::DEBUG, "Linking player information, uid: %d", otherUniqueId);
            // Note in lua
            lua::call_external("player_init", "i", ClientSystem::uniqueId);
        }
        renderprogress(0, "receiving entities...");
    }
#endif


// RequestLogicEntityRemoval

#ifndef STANDALONE
    void send_RequestLogicEntityRemoval(int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestLogicEntityRemoval (1019)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1019, "ri", uid);
    }
#endif

#ifdef STANDALONE
    void RequestLogicEntityRemoval::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);

        if (!world::scenario_code[0]) return;
        if (!server::isAdmin(sender))
        {
            logger::log(logger::WARNING, "Non-admin tried to remove an entity");
            send_PersonalServerMessage(sender, "Server", "You are not an administrator, and cannot remove entities");
            return;
        }
        if ( !server::isRunningCurrentScenario(sender) ) return; // Silently ignore info from previous scenario
        lua::call_external("entity_remove", "i", uid);
    }
#endif

// LogicEntityRemoval

#ifdef STANDALONE
    void send_LogicEntityRemoval(int clientNumber, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type LogicEntityRemoval (1020)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("rii", 1020, uid));
    }
#endif

#ifndef STANDALONE
    void LogicEntityRemoval::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);

        if (!LogicSystem::initialized)
            return;
        lua::call_external("entity_remove", "i", uid);
    }
#endif


// ExtentCompleteNotification

#ifdef STANDALONE
    void send_ExtentCompleteNotification(int clientNumber, int otherUniqueId, const char* otherClass, const char* stateData)
    {
        logger::log(logger::DEBUG, "Sending a message of type ExtentCompleteNotification (1021)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riiss", 1021, otherUniqueId, otherClass, stateData));
    }
#endif

#ifndef STANDALONE
    void ExtentCompleteNotification::receive(int receiver, int sender, ucharbuf &p)
    {
        int otherUniqueId = getint(p);
        char otherClass[MAXTRANS];
        getstring(otherClass, p);
        char stateData[MAXTRANS];
        getstring(stateData, p);

        if (!LogicSystem::initialized)
            return;
        logger::log(logger::DEBUG, "RECEIVING Extent: %d,%s", otherUniqueId, otherClass);
        INDENT_LOG(logger::DEBUG);
        // If a logic entity does not yet exist, create one
        bool ent_exists = false;
        lua::pop_external_ret(lua::call_external_ret("entity_exists", "i", "b", otherUniqueId, &ent_exists));
        if (!ent_exists)
        {
            logger::log(logger::DEBUG, "Creating new active LogicEntity");
            lua::pop_external_ret(lua::call_external_ret("entity_add", "si", "b", otherClass, otherUniqueId, &ent_exists));
            assert(ent_exists);
        } else
            logger::log(logger::DEBUG, "Existing LogicEntity %d, no need to create", otherUniqueId);
        // A logic entity now exists (either one did before, or we created one), we now update the stateData, if we
        // are remotely connected (TODO: make this not segfault for localconnect)
        logger::log(logger::DEBUG, "Updating stateData");
        lua::call_external("entity_set_sdata_full", "is", otherUniqueId, stateData);
        renderprogress(0, "receiving entities...");
    }
#endif


// InitS2C

    void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion)
    {
        logger::log(logger::DEBUG, "Sending a message of type InitS2C (1022)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riii", 1022, explicitClientNumber, protocolVersion));
    }

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

#ifndef STANDALONE
    void send_EditModeC2S(int mode)
    {
        logger::log(logger::DEBUG, "Sending a message of type EditModeC2S (1028)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1028, "ri", mode);
    }
#endif

#ifdef STANDALONE
    void EditModeC2S::receive(int receiver, int sender, ucharbuf &p)
    {
        int mode = getint(p);

        if (!world::scenario_code[0] || !server::isRunningCurrentScenario(sender)) return;
        send_EditModeS2C(-1, sender, mode); // Relay
    }
#endif

// EditModeS2C

#ifdef STANDALONE
    void send_EditModeS2C(int clientNumber, int otherClientNumber, int mode)
    {
        logger::log(logger::DEBUG, "Sending a message of type EditModeS2C (1029)");

        send_AnyMessage(clientNumber, MAIN_CHANNEL, buildf("riii", 1029, otherClientNumber, mode), otherClientNumber);
    }
#endif

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

// DoClick

#ifndef STANDALONE
    void send_DoClick(int button, int down, float x, float y, float z, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type DoClick (1031)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1031, "riiiiii", button, down, int(x*DMF), int(y*DMF), int(z*DMF), uid);
    }
#endif

#ifdef STANDALONE
    void DoClick::receive(int receiver, int sender, ucharbuf &p)
    {
        int button = getint(p);
        int down = getint(p);
        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;
        int uid = getint(p);

        if (!world::scenario_code[0]) return;
        if (!server::isRunningCurrentScenario(sender)) return; // Silently ignore info from previous scenario

        assert(lua::call_external("input_click_server", "ibfffi", button, down,
            x, y, z, uid));
    }
#endif


// Register all messages

void MessageManager::registerAll()
{
    registerMessageType( new PersonalServerMessage() );
    registerMessageType( new LoginRequest() );
    registerMessageType( new YourUniqueId() );
    registerMessageType( new LoginResponse() );
    registerMessageType( new PrepareForNewScenario() );
    registerMessageType( new RequestCurrentScenario() );
    registerMessageType( new NotifyAboutCurrentScenario() );
    registerMessageType( new NewEntityRequest() );
    registerMessageType( new StateDataUpdate() );
    registerMessageType( new StateDataChangeRequest() );
    registerMessageType( new UnreliableStateDataUpdate() );
    registerMessageType( new UnreliableStateDataChangeRequest() );
    registerMessageType( new AllActiveEntitiesSent() );
    registerMessageType( new ActiveEntitiesRequest() );
    registerMessageType( new LogicEntityCompleteNotification() );
    registerMessageType( new RequestLogicEntityRemoval() );
    registerMessageType( new LogicEntityRemoval() );
    registerMessageType( new ExtentCompleteNotification() );
    registerMessageType( new InitS2C() );
    registerMessageType( new EditModeC2S() );
    registerMessageType( new EditModeS2C() );
    registerMessageType( new DoClick() );
}

}

