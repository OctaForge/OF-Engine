// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

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

struct Message_Storage {
    MessageManager::MessageMap data;
    Message_Storage(): data() {}
    ~Message_Storage() {
        enumerate(data, MessageType*, msg, delete msg);
    }
};
static Message_Storage storage;

MessageManager::MessageMap &MessageManager::messageTypes = storage.data;

void MessageManager::registerMessageType(MessageType *newMessageType)
{
    logger::log(logger::DEBUG, "MessageSystem: Registering message %s (%d)\r\n",
                                 newMessageType->type_name,
                                 newMessageType->type_code);

    assert(messageTypes.access(newMessageType->type_code) == NULL); // We cannot have duplicate message types

    messageTypes.access(newMessageType->type_code, newMessageType);
}

bool MessageManager::receive(int type, int receiver, int sender, ucharbuf &p)
{
    if (messageTypes.access(type) == NULL) {
        logger::log(logger::DEBUG, "MessageSystem: Receiving a message of type %d from %d: Type not found in our extensions to Sauer\r\n", type, sender);
        return false; // This isn't one of our messages, hopefully it's a sauer one
    }

    MessageType *message_type = messageTypes[type];
    logger::log(logger::DEBUG,     "MessageSystem: Receiving a message of type %d from %d: %s\r\n", type, sender, message_type->type_name);
    INDENT_LOG(logger::DEBUG);

    message_type->receive(receiver, sender, p);

    logger::log(logger::DEBUG, "MessageSystem: message successfully handled\r\n");

    return true;
}

}
