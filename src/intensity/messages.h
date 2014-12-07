#ifndef __MESSAGES_H__
#define __MESSAGES_H__


// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "game.h"

// YourUniqueId

struct YourUniqueId : MessageType
{
    YourUniqueId() : MessageType(N_YOURUID, "YourUniqueId") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_YourUniqueId(int clientNumber, int uid);


// LoginResponse

struct LoginResponse : MessageType
{
    LoginResponse() : MessageType(N_LOGINRESPONSE, "LoginResponse") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_LoginResponse(int clientNumber, bool success, bool local);


// PrepareForNewScenario

struct PrepareForNewScenario : MessageType
{
    PrepareForNewScenario() : MessageType(N_PREPFORNEWSCENARIO, "PrepareForNewScenario") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode);


// RequestCurrentScenario

struct RequestCurrentScenario : MessageType
{
    RequestCurrentScenario() : MessageType(N_REQUESTCURRENTSCENARIO, "RequestCurrentScenario") { };

#ifdef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RequestCurrentScenario();


// NotifyAboutCurrentScenario

struct NotifyAboutCurrentScenario : MessageType
{
    NotifyAboutCurrentScenario() : MessageType(N_NOTIFYABOUTCURRENTSCENARIO, "NotifyAboutCurrentScenario") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc);

// AllActiveEntitiesSent

struct AllActiveEntitiesSent : MessageType
{
    AllActiveEntitiesSent() : MessageType(N_ALLACTIVEENTSSENT, "AllActiveEntitiesSent") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_AllActiveEntitiesSent(int clientNumber);

// InitS2C

struct InitS2C : MessageType
{
    InitS2C() : MessageType(N_INITS2C, "InitS2C") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion);

// EditModeC2S

struct EditModeC2S : MessageType
{
    EditModeC2S() : MessageType(N_EDITMODEC2S, "EditModeC2S") { };

#ifdef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_EditModeC2S(int mode);


// EditModeS2C

struct EditModeS2C : MessageType
{
    EditModeS2C() : MessageType(N_EDITMODES2C, "EditModeS2C") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_EditModeS2C(int clientNumber, int otherClientNumber, int mode);

#endif
