

// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

// Automatically generated from messages.template - DO NOT MODIFY THIS FILE!


#include "cube.h"
#include "engine.h"
#include "game.h"

#ifdef CLIENT
    #include "targeting.h"
#endif

#include "client_system.h"
#include "message_system.h"
#include "editing_system.h"
#include "network_system.h"
#include "of_world.h"
#include "of_tools.h"

using namespace lua;

/* Abuse generation from template for now */
void force_network_flush();
namespace server
{
    int& getUniqueId(int clientNumber);
}

namespace MessageSystem
{

// PersonalServerMessage

    void send_PersonalServerMessage(int clientNumber, const char* title, const char* content)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type PersonalServerMessage (1001)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riss", 1001, title, content);

            }
        }
    }

#ifdef CLIENT
    void PersonalServerMessage::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type PersonalServerMessage (1001)\r\n");

        static char title[MAXTRANS];
        getstring(title, p);
        static char content[MAXTRANS];
        getstring(content, p);

        engine.getg("gui")
              .t_getraw("message")
              .push(title)
              .push(content)
              .call(2, 0).pop(1);
    }
#endif


// RequestServerMessageToAll

    void send_RequestServerMessageToAll(const char* message)
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestServerMessageToAll (1002)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1002, "rs", message);
    }

#ifdef SERVER
    void RequestServerMessageToAll::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type RequestServerMessageToAll (1002)\r\n");

        static char message[MAXTRANS];
        getstring(message, p);

        send_PersonalServerMessage(-1, "Message from Client", message);
    }
#endif

// LoginRequest

    void send_LoginRequest()
    {
        logger::log(logger::DEBUG, "Sending a message of type LoginRequest (1003)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1003, "r");
    }

#ifdef SERVER
    void LoginRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type LoginRequest (1003)\r\n");


        #ifdef SERVER
            if (world::scenario_code.is_empty())
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
            ClientSystem::uniqueId = 9999; // Dummy safe uniqueId value for localconnects. Just set it here, brute force
            // Notify client of results of login
            send_LoginResponse(sender, true, true);
        #endif
    }
#endif

// YourUniqueId

    void send_YourUniqueId(int clientNumber, int uniqueId)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type YourUniqueId (1004)\r\n");
        INDENT_LOG(logger::DEBUG);

                 // Remember this client's unique ID. Done here so always in sync with the client's belief about its uniqueId.
        server::getUniqueId(clientNumber) = uniqueId;


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "rii", 1004, uniqueId);

            }
        }
    }

#ifdef CLIENT
    void YourUniqueId::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type YourUniqueId (1004)\r\n");

        int uniqueId = getint(p);

        logger::log(logger::DEBUG, "Told my unique ID: %d\r\n", uniqueId);
        ClientSystem::uniqueId = uniqueId;
    }
#endif


// LoginResponse

    void send_LoginResponse(int clientNumber, bool success, bool local)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type LoginResponse (1005)\r\n");
        INDENT_LOG(logger::DEBUG);

                 // If logged in OK, this is the time to create a lua logic entity for the client. Also adds to internal FPSClient
        if (success)
            server::createluaEntity(clientNumber);


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riii", 1005, success, local);

            }
        }
    }

#ifdef CLIENT
    void LoginResponse::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type LoginResponse (1005)\r\n");

        bool success = getint(p);
        bool local = getint(p);

        if (success)
        {
            ClientSystem::finishLogin(local); // This player will be known as 'uniqueID' in the current module
            conoutf("Login was successful.\r\n");
            send_RequestCurrentScenario();
        } else {
            conoutf("Login failure. Please check your username and password.\r\n");
            disconnect();
        }
    }
#endif


// PrepareForNewScenario

    void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type PrepareForNewScenario (1006)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "ris", 1006, scenarioCode);

            }
        }
    }

#ifdef CLIENT
    void PrepareForNewScenario::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type PrepareForNewScenario (1006)\r\n");

        static char scenarioCode[MAXTRANS];
        getstring(scenarioCode, p);

        engine.getg("gui")
              .t_getraw("message")
              .push("Server")
              .push("Map being prepared on the server, please wait ..")
              .call(2, 0).pop(1);
        ClientSystem::prepareForNewScenario(scenarioCode);
    }
#endif


// RequestCurrentScenario

    void send_RequestCurrentScenario()
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestCurrentScenario (1007)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1007, "r");
    }

#ifdef SERVER
    void RequestCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type RequestCurrentScenario (1007)\r\n");


        if (world::scenario_code.is_empty()) return;
        world::send_curr_map(sender);
    }
#endif

// NotifyAboutCurrentScenario

    void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type NotifyAboutCurrentScenario (1008)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riss", 1008, mid, sc);

            }
        }
    }

#ifdef CLIENT
    void NotifyAboutCurrentScenario::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type NotifyAboutCurrentScenario (1008)\r\n");

        static char mid[MAXTRANS];
        getstring(mid, p);
        static char sc[MAXTRANS];
        getstring(sc, p);

        ClientSystem::currScenarioCode = sc;
        world::set_map(mid);
    }
#endif


// RestartMap

    void send_RestartMap()
    {
        logger::log(logger::DEBUG, "Sending a message of type RestartMap (1009)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1009, "r");
    }

#ifdef SERVER
    void RestartMap::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type RestartMap (1009)\r\n");


        if (world::scenario_code.is_empty()) return;
        if (!server::isAdmin(sender))
        {
            logger::log(logger::WARNING, "Non-admin tried to restart the map\r\n");
            send_PersonalServerMessage(sender, "Server", "You are not an administrator, and cannot restart the map");
            return;
        }
        world::restart_map();
    }
#endif

// NewEntityRequest

    void send_NewEntityRequest(const char* _class, float x, float y, float z, const char* stateData)
    {        EditingSystem::madeChanges = true;

        logger::log(logger::DEBUG, "Sending a message of type NewEntityRequest (1010)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1010, "rsiiis", _class, int(x*DMF), int(y*DMF), int(z*DMF), stateData);
    }

#ifdef SERVER
    void NewEntityRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type NewEntityRequest (1010)\r\n");

        static char _class[MAXTRANS];
        getstring(_class, p);
        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;
        static char stateData[MAXTRANS];
        getstring(stateData, p);

        if (world::scenario_code.is_empty()) return;
        if (!server::isAdmin(sender))
        {
            logger::log(logger::WARNING, "Non-admin tried to add an entity\r\n");
            send_PersonalServerMessage(sender, "Server", "You are not an administrator, and cannot create entities");
            return;
        }
        // Validate class
        lua::engine.getg("entity_classes").t_getraw("get_class").push(_class).call(1, 1);
        if (lua::engine.is<void>(-1))
        {
            lua::engine.pop(2);
            return;
        }
        lua::engine.pop(2);
        // Add entity
        logger::log(logger::DEBUG, "Creating new entity, %s   %f,%f,%f   %s\r\n", _class, x, y, z, stateData);
        if ( !server::isRunningCurrentScenario(sender) ) return; // Silently ignore info from previous scenario
        engine.getg("entity_classes").t_getraw("get_sauer_type").push(_class).call(1, 1);
        const char *sauerType = engine.get(-1, "extent");
        engine.pop(2);
        logger::log(logger::DEBUG, "Sauer type: %s\r\n", sauerType);
        // Create
        engine.getg("entity_store").t_getraw("new").push(_class);
        engine.t_new();
        engine.push("position")
            .t_new()
            .t_set("x", x)
            .t_set("y", y)
            .t_set("z", z);
        engine.t_set().t_set("state_data", stateData);
        engine.call(2, 1);
        int newUniqueId = engine.t_get<int>("uid");
        engine.pop(2);
        logger::log(logger::DEBUG, "Created Entity: %d - %s  (%f,%f,%f) \r\n",
                                      newUniqueId, _class, x, y, z);
    }
#endif

// StateDataUpdate

    void send_StateDataUpdate(int clientNumber, int uniqueId, int keyProtocolId, const char* value, int originalClientNumber)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type StateDataUpdate (1011)\r\n");
        INDENT_LOG(logger::DEBUG);

                 exclude = originalClientNumber;


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (true && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riiisi", 1011, uniqueId, keyProtocolId, value, originalClientNumber);

            }
        }
    }

    void StateDataUpdate::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
#ifdef CLIENT
        is_npc = false;
#else // SERVER
        is_npc = true;
#endif
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type StateDataUpdate (1011)\r\n");

        int uniqueId = getint(p);
        int keyProtocolId = getint(p);
        static char value[MAXTRANS];
        getstring(value, p);
        int originalClientNumber = getint(p);

        #ifdef SERVER
            #define STATE_DATA_UPDATE \
                uniqueId = uniqueId;  /* Prevent warnings */ \
                keyProtocolId = keyProtocolId; \
                originalClientNumber = originalClientNumber; \
                return; /* We do send this to the NPCs sometimes, as it is sent during their creation (before they are fully */ \
                        /* registered even). But we have no need to process it on the server. */
        #else
            #define STATE_DATA_UPDATE \
                assert(originalClientNumber == -1 || ClientSystem::playerNumber != originalClientNumber); /* Can be -1, or else cannot be us */ \
                \
                logger::log(logger::DEBUG, "StateDataUpdate: %d, %d, %s \r\n", uniqueId, keyProtocolId, value); \
                \
                if (!engine.hashandle()) \
                    return; \
                \
                engine.getg("entity_store").t_getraw("set_state_data").push(uniqueId).push(keyProtocolId).push(value).call(3, 0).pop(1);
        #endif
        STATE_DATA_UPDATE
    }


// StateDataChangeRequest

    void send_StateDataChangeRequest(int uniqueId, int keyProtocolId, const char* value)
    {        // This isn't a perfect way to differentiate transient state data changes from permanent ones
        // that justify saying 'changes were made', but for now it will do. Note that even checking
        // for changes to persistent entities is not enough - transient changes on them are generally
        // not expected to count as 'changes'. So this check, of editmode, is the best simple solution
        // there is - if you're in edit mode, the change counts as a 'real change', that you probably
        // want saved.
        // Note: We don't do this with unreliable messages, meaningless anyhow.
        if (editmode)
            EditingSystem::madeChanges = true;

        logger::log(logger::DEBUG, "Sending a message of type StateDataChangeRequest (1012)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1012, "riis", uniqueId, keyProtocolId, value);
    }

#ifdef SERVER
    void StateDataChangeRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type StateDataChangeRequest (1012)\r\n");

        int uniqueId = getint(p);
        int keyProtocolId = getint(p);
        static char value[MAXTRANS];
        getstring(value, p);

        if (world::scenario_code.is_empty()) return;
        #define STATE_DATA_REQUEST \
        int actorUniqueId = server::getUniqueId(sender); \
        \
        logger::log(logger::DEBUG, "client %d requests to change %d to value: %s\r\n", actorUniqueId, keyProtocolId, value); \
        \
        if ( !server::isRunningCurrentScenario(sender) ) return; /* Silently ignore info from previous scenario */ \
        \
        engine.getg("entity_store").t_getraw("set_state_data").push(uniqueId).push(keyProtocolId).push(value).push(actorUniqueId).call(4, 0).pop(1);
        STATE_DATA_REQUEST
    }
#endif

// UnreliableStateDataUpdate

    void send_UnreliableStateDataUpdate(int clientNumber, int uniqueId, int keyProtocolId, const char* value, int originalClientNumber)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type UnreliableStateDataUpdate (1013)\r\n");
        INDENT_LOG(logger::DEBUG);

                 exclude = originalClientNumber;


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (true && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "iiisi", 1013, uniqueId, keyProtocolId, value, originalClientNumber);

            }
        }
    }

    void UnreliableStateDataUpdate::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
#ifdef CLIENT
        is_npc = false;
#else // SERVER
        is_npc = true;
#endif
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type UnreliableStateDataUpdate (1013)\r\n");

        int uniqueId = getint(p);
        int keyProtocolId = getint(p);
        static char value[MAXTRANS];
        getstring(value, p);
        int originalClientNumber = getint(p);

        STATE_DATA_UPDATE
    }


// UnreliableStateDataChangeRequest

    void send_UnreliableStateDataChangeRequest(int uniqueId, int keyProtocolId, const char* value)
    {
        logger::log(logger::DEBUG, "Sending a message of type UnreliableStateDataChangeRequest (1014)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1014, "iis", uniqueId, keyProtocolId, value);
    }

#ifdef SERVER
    void UnreliableStateDataChangeRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type UnreliableStateDataChangeRequest (1014)\r\n");

        int uniqueId = getint(p);
        int keyProtocolId = getint(p);
        static char value[MAXTRANS];
        getstring(value, p);

        if (world::scenario_code.is_empty()) return;
        STATE_DATA_REQUEST
    }
#endif

// NotifyNumEntities

    void send_NotifyNumEntities(int clientNumber, int num)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type NotifyNumEntities (1015)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "rii", 1015, num);

            }
        }
    }

#ifdef CLIENT
    void NotifyNumEntities::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type NotifyNumEntities (1015)\r\n");

        int num = getint(p);

        world::set_num_expected_entities(num);
    }
#endif


// AllActiveEntitiesSent

    void send_AllActiveEntitiesSent(int clientNumber)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type AllActiveEntitiesSent (1016)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "ri", 1016);

            }
        }
    }

#ifdef CLIENT
    void AllActiveEntitiesSent::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type AllActiveEntitiesSent (1016)\r\n");


        ClientSystem::finishLoadWorld();
    }
#endif


// ActiveEntitiesRequest

    void send_ActiveEntitiesRequest(const char* scenarioCode)
    {
        logger::log(logger::DEBUG, "Sending a message of type ActiveEntitiesRequest (1017)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1017, "rs", scenarioCode);
    }

#ifdef SERVER
    void ActiveEntitiesRequest::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type ActiveEntitiesRequest (1017)\r\n");

        static char scenarioCode[MAXTRANS];
        getstring(scenarioCode, p);

        #ifdef SERVER
            if (world::scenario_code.is_empty()) return;
            // Mark the client as running the current scenario, if indeed doing so
            server::setClientScenario(sender, scenarioCode);
            if ( !server::isRunningCurrentScenario(sender) )
            {
                logger::log(logger::WARNING, "Client %d requested active entities for an invalid scenario: %s\r\n",
                    sender, scenarioCode
                );
                send_PersonalServerMessage(sender, "Invalid scenario", "An error occured in synchronizing scenarios");
                return;
            }
            engine.getg("entity_store")
                  .t_getraw("send_entities")
                  .push(sender)
                  .call(1, 0)
                  .pop(1);
            MessageSystem::send_AllActiveEntitiesSent(sender);
            engine.getg("on_player_login");
            if (engine.is<void*>(-1)) engine.getg("entity_store")
                      .t_getraw("get")
                      .push(server::getUniqueId(sender))
                      .call(1, 1)
                      .shift().pop(1)
                      .call(1, 0);
            else engine.pop(1);
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
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type LogicEntityCompleteNotification (1018)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (true && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riiiss", 1018, otherClientNumber, otherUniqueId, otherClass, stateData);

            }
        }
    }

    void LogicEntityCompleteNotification::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
#ifdef CLIENT
        is_npc = false;
#else // SERVER
        is_npc = true;
#endif
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type LogicEntityCompleteNotification (1018)\r\n");

        int otherClientNumber = getint(p);
        int otherUniqueId = getint(p);
        static char otherClass[MAXTRANS];
        getstring(otherClass, p);
        static char stateData[MAXTRANS];
        getstring(stateData, p);

        #ifdef SERVER
            return; // We do send this to the NPCs sometimes, as it is sent during their creation (before they are fully
                    // registered even). But we have no need to process it on the server.
        #endif
        if (!engine.hashandle())
            return;
        logger::log(logger::DEBUG, "RECEIVING LE: %d,%d,%s\r\n", otherClientNumber, otherUniqueId, otherClass);
        INDENT_LOG(logger::DEBUG);
        // If a logic entity does not yet exist, create one
        CLogicEntity *entity = LogicSystem::getLogicEntity(otherUniqueId);
        if (entity == NULL)
        {
            logger::log(logger::DEBUG, "Creating new active LogicEntity\r\n");
            engine.getg("entity_store").t_getraw("add")
                .push(otherClass)
                .push(otherUniqueId)
                .t_new();
            if (otherClientNumber >= 0) // If this is another client, NPC, etc., then send the clientnumber, critical for setup
            {
                #ifdef CLIENT
                    // If this is the player, validate it is the clientNumber we already have
                    if (otherUniqueId == ClientSystem::uniqueId)
                    {
                        logger::log(logger::DEBUG, "This is the player's entity (%d), validating client num: %d,%d\r\n",
                            otherUniqueId, otherClientNumber, ClientSystem::playerNumber);
                        assert(otherClientNumber == ClientSystem::playerNumber);
                    }
                #endif
                engine.t_set("cn", otherClientNumber);
            }
            engine.call(3, 0).pop(1);
            entity = LogicSystem::getLogicEntity(otherUniqueId);
            if (!entity)
            {
                logger::log(logger::ERROR, "Received a LogicEntityCompleteNotification for a LogicEntity that cannot be created: %d - %s. Ignoring\r\n", otherUniqueId, otherClass);
                return;
            }
        } else
            logger::log(logger::DEBUG, "Existing LogicEntity %d,%d,%d, no need to create\r\n", entity != NULL, entity->getUniqueId(),
                                            otherUniqueId);
        // A logic entity now exists (either one did before, or we created one), we now update the stateData, if we
        // are remotely connected (TODO: make this not segfault for localconnect)
        logger::log(logger::DEBUG, "Updating stateData with: %s\r\n", stateData);
        engine.getref(entity->luaRef)
            .t_getraw("update_complete_state_data")
            .push_index(-2)
            .push(stateData)
            .call(2, 0)
            .pop(1);
        #ifdef CLIENT
            // If this new entity is in fact the Player's entity, then we finally have the player's LE, and can link to it.
            if (otherUniqueId == ClientSystem::uniqueId)
            {
                logger::log(logger::DEBUG, "Linking player information, uid: %d\r\n", otherUniqueId);
                // Note in C++
                ClientSystem::playerLogicEntity = LogicSystem::getLogicEntity(ClientSystem::uniqueId);
                // Note in lua
                engine.getg("entity_store").t_getraw("set_player_uid").push(ClientSystem::uniqueId).call(1, 0).pop(1);
            }
        #endif
        // Events post-reception
        world::trigger_received_entity();
    }


// RequestLogicEntityRemoval

    void send_RequestLogicEntityRemoval(int uniqueId)
    {        EditingSystem::madeChanges = true;

        logger::log(logger::DEBUG, "Sending a message of type RequestLogicEntityRemoval (1019)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1019, "ri", uniqueId);
    }

#ifdef SERVER
    void RequestLogicEntityRemoval::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type RequestLogicEntityRemoval (1019)\r\n");

        int uniqueId = getint(p);

        if (world::scenario_code.is_empty()) return;
        if (!server::isAdmin(sender))
        {
            logger::log(logger::WARNING, "Non-admin tried to remove an entity\r\n");
            send_PersonalServerMessage(sender, "Server", "You are not an administrator, and cannot remove entities");
            return;
        }
        if ( !server::isRunningCurrentScenario(sender) ) return; // Silently ignore info from previous scenario
        engine.getg("entity_store").t_getraw("del").push(uniqueId).call(1, 0).pop(1);
    }
#endif

// LogicEntityRemoval

    void send_LogicEntityRemoval(int clientNumber, int uniqueId)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type LogicEntityRemoval (1020)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "rii", 1020, uniqueId);

            }
        }
    }

#ifdef CLIENT
    void LogicEntityRemoval::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type LogicEntityRemoval (1020)\r\n");

        int uniqueId = getint(p);

        if (!engine.hashandle())
            return;
        engine.getg("entity_store").t_getraw("del").push(uniqueId).call(1, 0).pop(1);
    }
#endif


// ExtentCompleteNotification

    void send_ExtentCompleteNotification(int clientNumber, int otherUniqueId, const char* otherClass, const char* stateData, float x, float y, float z, int attr1, int attr2, int attr3, int attr4)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type ExtentCompleteNotification (1021)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riissiiiiiii", 1021, otherUniqueId, otherClass, stateData, int(x*DMF), int(y*DMF), int(z*DMF), attr1, attr2, attr3, attr4);

            }
        }
    }

#ifdef CLIENT
    void ExtentCompleteNotification::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type ExtentCompleteNotification (1021)\r\n");

        int otherUniqueId = getint(p);
        static char otherClass[MAXTRANS];
        getstring(otherClass, p);
        static char stateData[MAXTRANS];
        getstring(stateData, p);
        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;
        int attr1 = getint(p);
        int attr2 = getint(p);
        int attr3 = getint(p);
        int attr4 = getint(p);

        if (!engine.hashandle())
            return;
        logger::log(logger::DEBUG, "RECEIVING Extent: %d,%s - %f,%f,%f  %d,%d,%d\r\n", otherUniqueId, otherClass,
            x, y, z, attr1, attr2, attr3, attr4);
        INDENT_LOG(logger::DEBUG);
        // If a logic entity does not yet exist, create one
        CLogicEntity *entity = LogicSystem::getLogicEntity(otherUniqueId);
        if (entity == NULL)
        {
            logger::log(logger::DEBUG, "Creating new active LogicEntity\r\n");
            engine.getg("entity_classes").t_getraw("get_sauer_type").push(otherClass).call(1, 1);
            const char *sauerType = engine.get(-1, "extent");
            engine.pop(2);
            engine.getg("entity_store").t_getraw("add")
                .push(otherClass)
                .push(otherUniqueId)
                .t_new()
                    .t_set("_type", findtype((char*)sauerType))
                    .t_set("x", x)
                    .t_set("y", y)
                    .t_set("z", z)
                    .t_set("attr1", attr1)
                    .t_set("attr2", attr2)
                    .t_set("attr3", attr3)
                    .t_set("attr4", attr4)
                .call(3, 0).pop(1);
            entity = LogicSystem::getLogicEntity(otherUniqueId);
            assert(entity != NULL);
        } else
            logger::log(logger::DEBUG, "Existing LogicEntity %d,%d,%d, no need to create\r\n", entity != NULL, entity->getUniqueId(),
                                            otherUniqueId);
        // A logic entity now exists (either one did before, or we created one), we now update the stateData, if we
        // are remotely connected (TODO: make this not segfault for localconnect)
        logger::log(logger::DEBUG, "Updating stateData\r\n");
        engine.getref(entity->luaRef)
            .t_getraw("update_complete_state_data")
            .push_index(-2)
            .push(stateData)
            .call(2, 0)
            .pop(1);
        // Events post-reception
        world::trigger_received_entity();
    }
#endif


// InitS2C

    void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type InitS2C (1022)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riii", 1022, explicitClientNumber, protocolVersion);

            }
        }
    }

#ifdef CLIENT
    void InitS2C::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type InitS2C (1022)\r\n");

        int explicitClientNumber = getint(p);
        int protocolVersion = getint(p);

        if (!is_npc)
        {
            logger::log(logger::DEBUG, "client.h: N_INITS2C gave us cn/protocol: %d/%d\r\n", explicitClientNumber, protocolVersion);
            if(protocolVersion != PROTOCOL_VERSION)
            {
                conoutf(CON_ERROR, "You are using a different network protocol (you: %d, server: %d)", PROTOCOL_VERSION, protocolVersion);
                disconnect();
                return;
            }
            #ifdef CLIENT
                fpsent *player1 = game::player1;
            #else
                assert(0);
                fpsent *player1 = NULL;
            #endif
            player1->clientnum = explicitClientNumber; // we are now fully connected
                                                       // Kripken: Well, sauer would be, we still need more...
            #ifdef CLIENT
            ClientSystem::login(explicitClientNumber); // Finish the login process, send server our user/pass. NPCs need not do this.
            #endif
        } else {
            // NPC
            logger::log(logger::INFO, "client.h (npc): N_INITS2C gave us cn/protocol: %d/%d\r\n", explicitClientNumber, protocolVersion);
            assert(0); //does this ever occur?
        }
    }
#endif


// SoundToServer

    void send_SoundToServer(int soundId)
    {
        logger::log(logger::DEBUG, "Sending a message of type SoundToServer (1023)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1023, "i", soundId);
    }

#ifdef SERVER
    void SoundToServer::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type SoundToServer (1023)\r\n");

        int soundId = getint(p);

        if (world::scenario_code.is_empty()) return;
        if ( !server::isRunningCurrentScenario(sender) ) return; // Silently ignore info from previous scenario
        dynent* otherEntity = game::getclient(sender);
        if (otherEntity)
            send_SoundToClients(-1, soundId, sender);
    }
#endif

// SoundToClients

    void send_SoundToClients(int clientNumber, int soundId, int originalClientNumber)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type SoundToClients (1024)\r\n");
        INDENT_LOG(logger::DEBUG);

                 exclude = originalClientNumber; // This is how to ensure we do not send back to the client who originally sent it


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "iii", 1024, soundId, originalClientNumber);

            }
        }
    }

#ifdef CLIENT
    void SoundToClients::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type SoundToClients (1024)\r\n");

        int soundId = getint(p);
        int originalClientNumber = getint(p);

        assert(ClientSystem::playerNumber != originalClientNumber);
        dynent* player = game::getclient(originalClientNumber);
        if (!player)
        {
            if (originalClientNumber == -1) // Do not play sounds from nonexisting clients - would be odd
                playsound(soundId);
        }
        else
        {
            CLogicEntity *entity = LogicSystem::getLogicEntity( player );
            if (entity)
            {
                vec where = entity->getOrigin();
                playsound(soundId, &where);
            } // If no entity - but there should be, there is a player - do not play at all.
        }
    }
#endif


// MapSoundToClients

    void send_MapSoundToClients(int clientNumber, const char* soundName, int entityUniqueId)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type MapSoundToClients (1025)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "isi", 1025, soundName, entityUniqueId);

            }
        }
    }

#ifdef CLIENT
    void MapSoundToClients::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type MapSoundToClients (1025)\r\n");

        static char soundName[MAXTRANS];
        getstring(soundName, p);
        int entityUniqueId = getint(p);

        CLogicEntity *entity = LogicSystem::getLogicEntity(entityUniqueId);
        if (entity)
        {
            extentity *e = entity->staticEntity;
            stopmapsound(e);
            if(camera1->o.dist(e->o) < e->attr2)
            {
                if(!e->visible) playmapsound(soundName, e, e->attr4, -1);
                else if(e->visible) stopmapsound(e);
            }
        }
    }
#endif


// SoundToClientsByName

    void send_SoundToClientsByName(int clientNumber, float x, float y, float z, const char* soundName, int originalClientNumber)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type SoundToClientsByName (1026)\r\n");
        INDENT_LOG(logger::DEBUG);

                 exclude = originalClientNumber; // This is how to ensure we do not send back to the client who originally sent it


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "iiiisi", 1026, int(x*DMF), int(y*DMF), int(z*DMF), soundName, originalClientNumber);

            }
        }
    }

#ifdef CLIENT
    void SoundToClientsByName::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type SoundToClientsByName (1026)\r\n");

        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;
        static char soundName[MAXTRANS];
        getstring(soundName, p);
        int originalClientNumber = getint(p);

        assert(ClientSystem::playerNumber != originalClientNumber);
        vec pos(x,y,z);
        if (pos.x || pos.y || pos.z)
            playsoundname(soundName, &pos);
        else
            playsoundname(soundName);
    }
#endif


// SoundStopToClientsByName

    void send_SoundStopToClientsByName(int clientNumber, int volume, const char* soundName, int originalClientNumber)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type SoundStopToClientsByName (1027)\r\n");
        INDENT_LOG(logger::DEBUG);

                 exclude = originalClientNumber; // This is how to ensure we do not send back to the client who originally sent it


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "iisi", 1027, volume, soundName, originalClientNumber);

            }
        }
    }

#ifdef CLIENT
    void SoundStopToClientsByName::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type SoundStopToClientsByName (1027)\r\n");

        int volume = getint(p);
        static char soundName[MAXTRANS];
        getstring(soundName, p);
        int originalClientNumber = getint(p);

        assert(ClientSystem::playerNumber != originalClientNumber);
        stopsoundbyid(getsoundid(soundName, volume));
    }
#endif


// EditModeC2S

    void send_EditModeC2S(int mode)
    {
        logger::log(logger::DEBUG, "Sending a message of type EditModeC2S (1028)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1028, "ri", mode);
    }

#ifdef SERVER
    void EditModeC2S::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type EditModeC2S (1028)\r\n");

        int mode = getint(p);

        if (world::scenario_code.is_empty() || !server::isRunningCurrentScenario(sender) ) return;
        send_EditModeS2C(-1, sender, mode); // Relay
    }
#endif

// EditModeS2C

    void send_EditModeS2C(int clientNumber, int otherClientNumber, int mode)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type EditModeS2C (1029)\r\n");
        INDENT_LOG(logger::DEBUG);

                 exclude = otherClientNumber;


        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (true && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "riii", 1029, otherClientNumber, mode);

            }
        }
    }

    void EditModeS2C::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
#ifdef CLIENT
        is_npc = false;
#else // SERVER
        is_npc = true;
#endif
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type EditModeS2C (1029)\r\n");

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
        logger::log(logger::DEBUG, "Sending a message of type RequestMap (1030)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1030, "r");
    }

#ifdef SERVER
    void RequestMap::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type RequestMap (1030)\r\n");


        if (world::scenario_code.is_empty()) return;
        world::send_curr_map(sender);
    }
#endif

// DoClick

    void send_DoClick(int button, int down, float x, float y, float z, int uniqueId)
    {
        logger::log(logger::DEBUG, "Sending a message of type DoClick (1031)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1031, "riiiiii", button, down, int(x*DMF), int(y*DMF), int(z*DMF), uniqueId);
    }

#ifdef SERVER
    void DoClick::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type DoClick (1031)\r\n");

        int button = getint(p);
        int down = getint(p);
        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;
        int uniqueId = getint(p);

        if (world::scenario_code.is_empty()) return;
        if ( !server::isRunningCurrentScenario(sender) ) return; // Silently ignore info from previous scenario
        engine.getg("click");
        if (!engine.is<void*>(-1))
        {
            engine.pop(1);
            if (uniqueId != -1)
            {
                CLogicEntity *entity = LogicSystem::getLogicEntity(uniqueId);
                if (entity)
                {
                    engine.getref(entity->luaRef).t_getraw("click");
                    if (!engine.is<void*>(-1))
                    {
                        engine.pop(1);
                        return;
                    }
                    else engine.push_index(-2).push(button).push(down).push(vec(x, y, z)).call(4, 0);
                }
                else return; /* No need to call a click on entity that vanished meanwhile or does not yet exist! */
            }
        }
        else
        {
            engine.push(button).push(down).push(vec(x, y, z));
            int numargs = 3;
            if (uniqueId != -1)
            {
                CLogicEntity *entity = LogicSystem::getLogicEntity(uniqueId);
                if (entity)
                {
                    engine.getref(entity->luaRef);
                    numargs++;
                }
                else
                {
                    engine.pop(4);
                    return;
                }
            }
            engine.call(numargs, 0);
        }
    }
#endif

// ParticleSplashToClients

    void send_ParticleSplashToClients(int clientNumber, int _type, int num, int fade, float x, float y, float z)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type ParticleSplashToClients (1032)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "iiiiiii", 1032, _type, num, fade, int(x*DMF), int(y*DMF), int(z*DMF));

            }
        }
    }

#ifdef CLIENT
    void ParticleSplashToClients::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type ParticleSplashToClients (1032)\r\n");

        int _type = getint(p);
        int num = getint(p);
        int fade = getint(p);
        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;

        vec pos(x,y,z);
        particle_splash(_type, num, fade, pos);
    }
#endif


// ParticleSplashRegularToClients

    void send_ParticleSplashRegularToClients(int clientNumber, int _type, int num, int fade, float x, float y, float z)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type ParticleSplashRegularToClients (1033)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "iiiiiii", 1033, _type, num, fade, int(x*DMF), int(y*DMF), int(z*DMF));

            }
        }
    }

#ifdef CLIENT
    void ParticleSplashRegularToClients::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type ParticleSplashRegularToClients (1033)\r\n");

        int _type = getint(p);
        int num = getint(p);
        int fade = getint(p);
        float x = float(getint(p))/DMF;
        float y = float(getint(p))/DMF;
        float z = float(getint(p))/DMF;

        vec pos(x,y,z);
        regular_particle_splash(_type, num, fade, pos);
    }
#endif


// RequestPrivateEditMode

    void send_RequestPrivateEditMode()
    {
        logger::log(logger::DEBUG, "Sending a message of type RequestPrivateEditMode (1034)\r\n");
        INDENT_LOG(logger::DEBUG);

        game::addmsg(1034, "r");
    }

#ifdef SERVER
    void RequestPrivateEditMode::receive(int receiver, int sender, ucharbuf &p)
    {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type RequestPrivateEditMode (1034)\r\n");


        if (world::scenario_code.is_empty()) return;
        send_NotifyPrivateEditMode(sender);
    }
#endif

// NotifyPrivateEditMode

    void send_NotifyPrivateEditMode(int clientNumber)
    {
        int exclude = -1; // Set this to clientNumber to not send to

        logger::log(logger::DEBUG, "Sending a message of type NotifyPrivateEditMode (1035)\r\n");
        INDENT_LOG(logger::DEBUG);

         

        int start, finish;
        if (clientNumber == -1)
        {
            // Send to all clients
            start  = 0;
            finish = getnumclients() - 1;
        } else {
            start  = clientNumber;
            finish = clientNumber;
        }

#ifdef SERVER
        int testUniqueId;
#endif
        for (clientNumber = start; clientNumber <= finish; clientNumber++)
        {
            if (clientNumber == exclude) continue;
#ifdef SERVER
            fpsent* fpsEntity = game::getclient(clientNumber);
            bool serverControlled = fpsEntity ? fpsEntity->serverControlled : false;

            testUniqueId = server::getUniqueId(clientNumber);
            if ( (!serverControlled && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If a remote client, send even if negative (during login process)
                 (false && testUniqueId == DUMMY_SINGLETON_CLIENT_UNIQUE_ID) || // If need to send to dummy server, send there
                 (false && testUniqueId != DUMMY_SINGLETON_CLIENT_UNIQUE_ID && serverControlled) )  // If need to send to npcs, send there
#endif
            {
                #ifdef SERVER
                    logger::log(logger::DEBUG, "Sending to %d (%d) ((%d))\r\n", clientNumber, testUniqueId, serverControlled);
                #endif
                sendf(clientNumber, MAIN_CHANNEL, "ri", 1035);

            }
        }
    }

#ifdef CLIENT
    void NotifyPrivateEditMode::receive(int receiver, int sender, ucharbuf &p)
    {
        bool is_npc;
        is_npc = false;
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type NotifyPrivateEditMode (1035)\r\n");


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
    registerMessageType( new SoundToServer() );
    registerMessageType( new SoundToClients() );
    registerMessageType( new MapSoundToClients() );
    registerMessageType( new SoundToClientsByName() );
    registerMessageType( new SoundStopToClientsByName() );
    registerMessageType( new EditModeC2S() );
    registerMessageType( new EditModeS2C() );
    registerMessageType( new RequestMap() );
    registerMessageType( new DoClick() );
    registerMessageType( new ParticleSplashToClients() );
    registerMessageType( new ParticleSplashRegularToClients() );
    registerMessageType( new RequestPrivateEditMode() );
    registerMessageType( new NotifyPrivateEditMode() );
}

}

