#ifndef __MESSAGES_H__
#define __MESSAGES_H__


// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

// LoginRequest

struct LoginRequest : MessageType
{
    LoginRequest() : MessageType(1003, "LoginRequest") { };

#ifdef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_LoginRequest();


// YourUniqueId

struct YourUniqueId : MessageType
{
    YourUniqueId() : MessageType(1004, "YourUniqueId") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_YourUniqueId(int clientNumber, int uid);


// LoginResponse

struct LoginResponse : MessageType
{
    LoginResponse() : MessageType(1005, "LoginResponse") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_LoginResponse(int clientNumber, bool success, bool local);


// PrepareForNewScenario

struct PrepareForNewScenario : MessageType
{
    PrepareForNewScenario() : MessageType(1006, "PrepareForNewScenario") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode);


// RequestCurrentScenario

struct RequestCurrentScenario : MessageType
{
    RequestCurrentScenario() : MessageType(1007, "RequestCurrentScenario") { };

#ifdef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RequestCurrentScenario();


// NotifyAboutCurrentScenario

struct NotifyAboutCurrentScenario : MessageType
{
    NotifyAboutCurrentScenario() : MessageType(1008, "NotifyAboutCurrentScenario") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc);


// NewEntityRequest

struct NewEntityRequest : MessageType
{
    NewEntityRequest() : MessageType(1010, "NewEntityRequest") { };

#ifdef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_NewEntityRequest(const char* _class, float x, float y, float z, const char* stateData, const char *newent_data);

// AllActiveEntitiesSent

struct AllActiveEntitiesSent : MessageType
{
    AllActiveEntitiesSent() : MessageType(1016, "AllActiveEntitiesSent") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_AllActiveEntitiesSent(int clientNumber);


// ActiveEntitiesRequest

struct ActiveEntitiesRequest : MessageType
{
    ActiveEntitiesRequest() : MessageType(1017, "ActiveEntitiesRequest") { };

#ifdef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_ActiveEntitiesRequest(const char* scenarioCode);

// InitS2C

struct InitS2C : MessageType
{
    InitS2C() : MessageType(1022, "InitS2C") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion);

// EditModeC2S

struct EditModeC2S : MessageType
{
    EditModeC2S() : MessageType(1028, "EditModeC2S") { };

#ifdef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_EditModeC2S(int mode);


// EditModeS2C

struct EditModeS2C : MessageType
{
    EditModeS2C() : MessageType(1029, "EditModeS2C") { };

#ifndef STANDALONE
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_EditModeS2C(int clientNumber, int otherClientNumber, int mode);

#endif
