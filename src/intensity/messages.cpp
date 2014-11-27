// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.


#include "cube.h"
#include "engine.h"
#include "game.h"

#ifndef SERVER
    #include "targeting.h"
#endif

#include "client_system.h"
#include "message_system.h"
#include "of_world.h"
#include "of_tools.h"

void force_network_flush();
namespace server
{
    int& getUniqueId(int clientNumber);
}

namespace MessageSystem
{

    void send_AnyMessage(int clientNumber, int chan, bool toDummyServer, ENetPacket *packet, int exclude=-1) {
        INDENT_LOG(logger::DEBUG);

        int start, finish;
        if (clientNumber == -1) 
            start = 0, finish = getnumclients();            // send to all
        else
            start = clientNumber, finish = clientNumber+1;  // send to one

        for (int clientNumber = start; clientNumber < finish; clientNumber++) {
            if (clientNumber == exclude) continue;
            #ifdef SERVER
                int testUniqueId = server::getUniqueId(clientNumber);
                if (testUniqueId == -9000) {
                    if (!toDummyServer) continue;
                }
                logger::log(logger::DEBUG, "Sending to %d (%d)", clientNumber, testUniqueId);
            #endif
            sendpacket(clientNumber, chan, packet, -1);
        }

        if(!packet->referenceCount) enet_packet_destroy(packet);
    }

    // PersonalServerMessage

    void send_PersonalServerMessage(int clientNumber, const char* title, const char* content)
    {
        logger::log(logger::DEBUG, "Sending a message of type PersonalServerMessage (1001)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("riss", 1001, title, content));
    }

#ifndef SERVER
    void PersonalServerMessage::receive(int receiver, int sender, ucharbuf &p)
    {
        char title[MAXTRANS];
        getstring(title, p);
        char content[MAXTRANS];
        getstring(content, p);
        assert(lua::call_external("gui_show_message", "ss", title, content));
    }
#endif


// RequestServerMessageToAll

    void send_RequestServerMessageToAll(const char* message)
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestServerMessageToAll (1002)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1002, "rs", message);
    }

#ifdef SERVER
    void RequestServerMessageToAll::receive(int receiver, int sender, ucharbuf &p)
    {
        char message[MAXTRANS];
        getstring(message, p);

        send_PersonalServerMessage(-1, "Message from Client", message);
    }
#endif

// LoginRequest

    void send_LoginRequest()
    {
        logger::log(logger::DEBUG, "Sending a message of type LoginRequest (1003)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1003, "r");
    }

#ifdef SERVER
    void LoginRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        #ifdef SERVER
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
        #else // CLIENT, during a localconnect
            ClientSystem::uniqueId = 9999; // Dummy safe uid value for localconnects. Just set it here, brute force
            // Notify client of results of login
            send_LoginResponse(sender, true, true);
        #endif
    }
#endif

// YourUniqueId

    void send_YourUniqueId(int clientNumber, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type YourUniqueId (1004)");
        server::getUniqueId(clientNumber) = uid;
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("rii", 1004, uid));
    }

#ifndef SERVER
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

        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("riii", 1005, success, local));
    }

#ifndef SERVER
    void LoginResponse::receive(int receiver, int sender, ucharbuf &p)
    {
        bool success = getint(p);
        bool local = getint(p);

        if (success)
        {
            ClientSystem::finishLogin(local); // This player will be known as 'uniqueID' in the current module
            conoutf("Login was successful.");
            send_RequestCurrentScenario();
        } else {
            conoutf("Login failure. Please check your username and password.");
            disconnect();
        }
    }
#endif


// PrepareForNewScenario

    void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode)
    {
        logger::log(logger::DEBUG, "Sending a message of type PrepareForNewScenario (1006)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("ris", 1006, scenarioCode));
    }

#ifndef SERVER
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

    void send_RequestCurrentScenario()
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestCurrentScenario (1007)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1007, "r");
    }

#ifdef SERVER
    void RequestCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {

        if (!world::scenario_code[0]) return;
        world::send_curr_map(sender);
    }
#endif

// NotifyAboutCurrentScenario

    void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc)
    {
        logger::log(logger::DEBUG, "Sending a message of type NotifyAboutCurrentScenario (1008)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("riss", 1008, mid, sc));
    }

#ifndef SERVER
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


// RestartMap

    void send_RestartMap()
    {
        logger::log(logger::DEBUG, "Sending a message of type RestartMap (1009)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1009, "r");
    }

#ifdef SERVER
    void RestartMap::receive(int receiver, int sender, ucharbuf &p)
    {
        if (!world::scenario_code[0]) return;
        if (!server::isAdmin(sender))
        {
            logger::log(logger::WARNING, "Non-admin tried to restart the map");
            send_PersonalServerMessage(sender, "Server", "You are not an administrator, and cannot restart the map");
            return;
        }
        world::restart_map();
    }
#endif

// NewEntityRequest

    void send_NewEntityRequest(const char* _class, float x, float y, float z, const char* stateData, const char *newent_data)
    {
        logger::log(logger::DEBUG, "Sending a message of type NewEntityRequest (1010)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1010, "rsiiiss", _class, int(x*DMF), int(y*DMF), int(z*DMF), stateData, newent_data);
    }

#ifdef SERVER
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

    void send_StateDataUpdate(int clientNumber, int uid, int keyProtocolId, const char* value, int originalClientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type StateDataUpdate (1011)");
        INDENT_LOG(logger::DEBUG);

        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("riiisi", 1011, uid, keyProtocolId, value, originalClientNumber), originalClientNumber);
    }

    void StateDataUpdate::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);
        int keyProtocolId = getint(p);
        char value[MAXTRANS];
        getstring(value, p);
        int originalClientNumber = getint(p);

        #ifdef SERVER
            #define STATE_DATA_UPDATE \
                uid = uid;  /* Prevent warnings */ \
                keyProtocolId = keyProtocolId; \
                originalClientNumber = originalClientNumber; \
                return; /* We do send this to the NPCs sometimes, as it is sent during their creation (before they are fully */ \
                        /* registered even). But we have no need to process it on the server. */
        #else
            #define STATE_DATA_UPDATE \
                assert(originalClientNumber == -1 || ClientSystem::playerNumber != originalClientNumber); /* Can be -1, or else cannot be us */ \
                \
                logger::log(logger::DEBUG, "StateDataUpdate: %d, %d, %s", uid, keyProtocolId, value); \
                \
                if (!LogicSystem::initialized) \
                    return; \
                lua::call_external("entity_set_sdata", "iis", uid, keyProtocolId, value);
        #endif
        STATE_DATA_UPDATE
    }


// StateDataChangeRequest

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

#ifdef SERVER
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

    void send_UnreliableStateDataUpdate(int clientNumber, int uid, int keyProtocolId, const char* value, int originalClientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type UnreliableStateDataUpdate (1013)");

        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("iiisi", 1013, uid, keyProtocolId, value, originalClientNumber), originalClientNumber);
    }

    void UnreliableStateDataUpdate::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);
        int keyProtocolId = getint(p);
        char value[MAXTRANS];
        getstring(value, p);
        int originalClientNumber = getint(p);

        STATE_DATA_UPDATE
    }


// UnreliableStateDataChangeRequest

    void send_UnreliableStateDataChangeRequest(int uid, int keyProtocolId, const char* value)
    {
        logger::log(logger::DEBUG, "Sending a message of type UnreliableStateDataChangeRequest (1014)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1014, "iis", uid, keyProtocolId, value);
    }

#ifdef SERVER
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

// NotifyNumEntities

    void send_NotifyNumEntities(int clientNumber, int num)
    {
        logger::log(logger::DEBUG, "Sending a message of type NotifyNumEntities (1015)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("rii", 1015, num));
    }

#ifndef SERVER
    void NotifyNumEntities::receive(int receiver, int sender, ucharbuf &p)
    {
        int num = getint(p);

        world::set_num_expected_entities(num);
    }
#endif


// AllActiveEntitiesSent

    void send_AllActiveEntitiesSent(int clientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type AllActiveEntitiesSent (1016)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("ri", 1016));
    }

#ifndef SERVER
    void AllActiveEntitiesSent::receive(int receiver, int sender, ucharbuf &p)
    {
        ClientSystem::finishLoadWorld();
    }
#endif


// ActiveEntitiesRequest

    void send_ActiveEntitiesRequest(const char* scenarioCode)
    {
        logger::log(logger::DEBUG, "Sending a message of type ActiveEntitiesRequest (1017)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1017, "rs", scenarioCode);
    }

#ifdef SERVER
    void ActiveEntitiesRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        char scenarioCode[MAXTRANS];
        getstring(scenarioCode, p);

        #ifdef SERVER
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
        #else // CLIENT
            // Send just enough info for the player's LE
            send_LogicEntityCompleteNotification( sender,
                                                  sender,
                                                  9999, // TODO: this same constant appears in multiple places
                                                  "player",
                                                  "{}" );
            MessageSystem::send_AllActiveEntitiesSent(sender);
        #endif
    }
#endif

// LogicEntityCompleteNotification

    void send_LogicEntityCompleteNotification(int clientNumber, int otherClientNumber, int otherUniqueId, const char* otherClass, const char* stateData)
    {
        logger::log(logger::DEBUG, "Sending a message of type LogicEntityCompleteNotification (1018)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("riiiss", 1018, otherClientNumber, otherUniqueId, otherClass, stateData));
    }

    void LogicEntityCompleteNotification::receive(int receiver, int sender, ucharbuf &p)
    {
        int otherClientNumber = getint(p);
        int otherUniqueId = getint(p);
        char otherClass[MAXTRANS];
        getstring(otherClass, p);
        char stateData[MAXTRANS];
        getstring(stateData, p);

        #ifdef SERVER
            return;
        #endif
        if (!LogicSystem::initialized)
            return;
        logger::log(logger::DEBUG, "RECEIVING LE: %d,%d,%s", otherClientNumber, otherUniqueId, otherClass);
        INDENT_LOG(logger::DEBUG);
        // If a logic entity does not yet exist, create one
        CLogicEntity *entity = LogicSystem::getLogicEntity(otherUniqueId);
        if (entity == NULL)
        {
#ifndef SERVER
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
#endif
            lua::call_external("entity_add_with_cn", "sii", otherClass, otherUniqueId, otherClientNumber);
            entity = LogicSystem::getLogicEntity(otherUniqueId);
            if (!entity)
            {
                logger::log(logger::ERROR, "Received a LogicEntityCompleteNotification for a LogicEntity that cannot be created: %d - %s. Ignoring", otherUniqueId, otherClass);
                return;
            }
        } else
            logger::log(logger::DEBUG, "Existing LogicEntity %d,%d,%d, no need to create", entity != NULL, entity->getUniqueId(),
                                            otherUniqueId);
        // A logic entity now exists (either one did before, or we created one), we now update the stateData, if we
        // are remotely connected (TODO: make this not segfault for localconnect)
        logger::log(logger::DEBUG, "Updating stateData with: %s", stateData);
        lua::call_external("entity_set_sdata_full", "is", entity->getUniqueId(), stateData);
        #ifndef SERVER
            // If this new entity is in fact the Player's entity, then we finally have the player's LE, and can link to it.
            if (otherUniqueId == ClientSystem::uniqueId)
            {
                logger::log(logger::DEBUG, "Linking player information, uid: %d", otherUniqueId);
                // Note in C++
                ClientSystem::playerLogicEntity = LogicSystem::getLogicEntity(ClientSystem::uniqueId);
                // Note in lua
                lua::call_external("player_init", "i", ClientSystem::uniqueId);
            }
        #endif
        // Events post-reception
        world::trigger_received_entity();
    }


// RequestLogicEntityRemoval

    void send_RequestLogicEntityRemoval(int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestLogicEntityRemoval (1019)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1019, "ri", uid);
    }

#ifdef SERVER
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

    void send_LogicEntityRemoval(int clientNumber, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type LogicEntityRemoval (1020)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("rii", 1020, uid));
    }

#ifndef SERVER
    void LogicEntityRemoval::receive(int receiver, int sender, ucharbuf &p)
    {
        int uid = getint(p);

        if (!LogicSystem::initialized)
            return;
        lua::call_external("entity_remove", "i", uid);
    }
#endif


// ExtentCompleteNotification

    void send_ExtentCompleteNotification(int clientNumber, int otherUniqueId, const char* otherClass, const char* stateData)
    {
        logger::log(logger::DEBUG, "Sending a message of type ExtentCompleteNotification (1021)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("riiss", 1021, otherUniqueId, otherClass, stateData));
    }

#ifndef SERVER
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
        CLogicEntity *entity = LogicSystem::getLogicEntity(otherUniqueId);
        if (entity == NULL)
        {
            logger::log(logger::DEBUG, "Creating new active LogicEntity");
            lua::call_external("entity_add", "si", otherClass, otherUniqueId);
            entity = LogicSystem::getLogicEntity(otherUniqueId);
            assert(entity != NULL);
        } else
            logger::log(logger::DEBUG, "Existing LogicEntity %d,%d,%d, no need to create", entity != NULL, entity->getUniqueId(),
                                            otherUniqueId);
        // A logic entity now exists (either one did before, or we created one), we now update the stateData, if we
        // are remotely connected (TODO: make this not segfault for localconnect)
        logger::log(logger::DEBUG, "Updating stateData");
        lua::call_external("entity_set_sdata_full", "is", entity->getUniqueId(), stateData);
        // Events post-reception
        world::trigger_received_entity();
    }
#endif


// InitS2C

    void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion)
    {
        logger::log(logger::DEBUG, "Sending a message of type InitS2C (1022)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("riii", 1022, explicitClientNumber, protocolVersion));
    }

#ifndef SERVER
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
        #ifndef SERVER
            gameent *player1 = game::player1;
        #else
            assert(0);
            gameent *player1 = NULL;
        #endif
        player1->clientnum = explicitClientNumber; // we are now fully connected
                                                   // Kripken: Well, sauer would be, we still need more...
        #ifndef SERVER
        ClientSystem::login(explicitClientNumber); // Finish the login process, send server our user/pass.
        #endif
    }
#endif

// EditModeC2S

    void send_EditModeC2S(int mode)
    {
        logger::log(logger::DEBUG, "Sending a message of type EditModeC2S (1028)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1028, "ri", mode);
    }

#ifdef SERVER
    void EditModeC2S::receive(int receiver, int sender, ucharbuf &p)
    {
        int mode = getint(p);

        if (!world::scenario_code[0] || !server::isRunningCurrentScenario(sender)) return;
        send_EditModeS2C(-1, sender, mode); // Relay
    }
#endif

// EditModeS2C

    void send_EditModeS2C(int clientNumber, int otherClientNumber, int mode)
    {
        logger::log(logger::DEBUG, "Sending a message of type EditModeS2C (1029)");

        send_AnyMessage(clientNumber, MAIN_CHANNEL, true, buildf("riii", 1029, otherClientNumber, mode), otherClientNumber);
    }

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


// RequestMap

    void send_RequestMap()
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestMap (1030)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1030, "r");
    }

#ifdef SERVER
    void RequestMap::receive(int receiver, int sender, ucharbuf &p)
    {
        if (!world::scenario_code[0]) return;
        world::send_curr_map(sender);
    }
#endif

// DoClick

    void send_DoClick(int button, int down, float x, float y, float z, int uid)
    {
        logger::log(logger::DEBUG, "Sending a message of type DoClick (1031)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1031, "riiiiii", button, down, int(x*DMF), int(y*DMF), int(z*DMF), uid);
    }

#ifdef SERVER
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

        CLogicEntity *entity = NULL;
        if (uid != -1) entity = LogicSystem::getLogicEntity(uid);
        assert(lua::call_external("input_click_server", "ibfffi", button, down,
            x, y, z, entity ? entity->getUniqueId() : -1));
    }
#endif

// RequestPrivateEditMode

    void send_RequestPrivateEditMode()
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestPrivateEditMode (1034)");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1034, "r");
    }

#ifdef SERVER
    void RequestPrivateEditMode::receive(int receiver, int sender, ucharbuf &p)
    {
        if (!world::scenario_code[0]) return;
        send_NotifyPrivateEditMode(sender);
    }
#endif

// NotifyPrivateEditMode

    void send_NotifyPrivateEditMode(int clientNumber)
    {
        logger::log(logger::DEBUG, "Sending a message of type NotifyPrivateEditMode (1035)");
        send_AnyMessage(clientNumber, MAIN_CHANNEL, false, buildf("ri", 1035));
    }

#ifndef SERVER
    void NotifyPrivateEditMode::receive(int receiver, int sender, ucharbuf &p)
    {
        conoutf("Server: You are now in private edit mode");
        ClientSystem::editingAlone = true;
    }
#endif


// Register all messages

void MessageManager::registerAll()
{
    registerMessageType( new PersonalServerMessage() );
    registerMessageType( new RequestServerMessageToAll() );
    registerMessageType( new LoginRequest() );
    registerMessageType( new YourUniqueId() );
    registerMessageType( new LoginResponse() );
    registerMessageType( new PrepareForNewScenario() );
    registerMessageType( new RequestCurrentScenario() );
    registerMessageType( new NotifyAboutCurrentScenario() );
    registerMessageType( new RestartMap() );
    registerMessageType( new NewEntityRequest() );
    registerMessageType( new StateDataUpdate() );
    registerMessageType( new StateDataChangeRequest() );
    registerMessageType( new UnreliableStateDataUpdate() );
    registerMessageType( new UnreliableStateDataChangeRequest() );
    registerMessageType( new NotifyNumEntities() );
    registerMessageType( new AllActiveEntitiesSent() );
    registerMessageType( new ActiveEntitiesRequest() );
    registerMessageType( new LogicEntityCompleteNotification() );
    registerMessageType( new RequestLogicEntityRemoval() );
    registerMessageType( new LogicEntityRemoval() );
    registerMessageType( new ExtentCompleteNotification() );
    registerMessageType( new InitS2C() );
    registerMessageType( new EditModeC2S() );
    registerMessageType( new EditModeS2C() );
    registerMessageType( new RequestMap() );
    registerMessageType( new DoClick() );
    registerMessageType( new RequestPrivateEditMode() );
    registerMessageType( new NotifyPrivateEditMode() );
}

}

