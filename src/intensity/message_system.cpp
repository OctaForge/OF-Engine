// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#ifndef STANDALONE
    #include "cube.h"
    #include "engine.h"
    #include "game.h"
#else
    #include "cube.h"
    #include "iengine.h"
    #include "igame.h"
#endif

#include "message_system.h"


namespace MessageSystem
{

// MessageType

void MessageType::receive(int receiver, int sender, ucharbuf &p)
{
    logger::log(logger::ERROR, "Trying to receive a message, but no handler present: %s (%d)\r\n", type_name, type_code);
    assert(0);
}


// MessageManager

MessageManager::MessageMap MessageManager::messageTypes;

void MessageManager::registerMessageType(MessageType *newMessageType)
{
    logger::log(logger::DEBUG, "MessageSystem: Registering message %s (%d)\r\n",
                                 newMessageType->type_name,
                                 newMessageType->type_code);

    assert(!messageTypes.find(newMessageType->type_code)); // We cannot have duplicate message types

    messageTypes.insert(newMessageType->type_code, newMessageType);
}

bool MessageManager::receive(int type, int receiver, int sender, ucharbuf &p)
{
    logger::log(logger::DEBUG, "MessageSystem: Trying to handle a message, type/sender:: %d/%d\r\n", type, sender);
    INDENT_LOG(logger::DEBUG);

    if (!messageTypes.find(type))
    {
        logger::log(logger::DEBUG, "Message type not found in our extensions to Sauer: %d\r\n", type);
        return false; // This isn't one of our messages, hopefully it's a sauer one
    }

    MessageType *message_type = messageTypes[type].get();
    message_type->receive(receiver, sender, p);

    logger::log(logger::DEBUG, "MessageSystem: message successfully handled\r\n");

    return true;
}

}
