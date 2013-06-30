#ifndef __MESSAGES_H__
#define __MESSAGES_H__


// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.


// PersonalServerMessage

struct PersonalServerMessage : MessageType
{
    PersonalServerMessage() : MessageType(1001, "PersonalServerMessage") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_PersonalServerMessage(int clientNumber, const char* title, const char* content);


// RequestServerMessageToAll

struct RequestServerMessageToAll : MessageType
{
    RequestServerMessageToAll() : MessageType(1002, "RequestServerMessageToAll") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RequestServerMessageToAll(const char* message);


// LoginRequest

struct LoginRequest : MessageType
{
    LoginRequest() : MessageType(1003, "LoginRequest") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_LoginRequest();


// YourUniqueId

struct YourUniqueId : MessageType
{
    YourUniqueId() : MessageType(1004, "YourUniqueId") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_YourUniqueId(int clientNumber, int uid);


// LoginResponse

struct LoginResponse : MessageType
{
    LoginResponse() : MessageType(1005, "LoginResponse") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_LoginResponse(int clientNumber, bool success, bool local);


// PrepareForNewScenario

struct PrepareForNewScenario : MessageType
{
    PrepareForNewScenario() : MessageType(1006, "PrepareForNewScenario") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_PrepareForNewScenario(int clientNumber, const char* scenarioCode);


// RequestCurrentScenario

struct RequestCurrentScenario : MessageType
{
    RequestCurrentScenario() : MessageType(1007, "RequestCurrentScenario") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RequestCurrentScenario();


// NotifyAboutCurrentScenario

struct NotifyAboutCurrentScenario : MessageType
{
    NotifyAboutCurrentScenario() : MessageType(1008, "NotifyAboutCurrentScenario") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_NotifyAboutCurrentScenario(int clientNumber, const char* mid, const char* sc);


// RestartMap

struct RestartMap : MessageType
{
    RestartMap() : MessageType(1009, "RestartMap") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RestartMap();


// NewEntityRequest

struct NewEntityRequest : MessageType
{
    NewEntityRequest() : MessageType(1010, "NewEntityRequest") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_NewEntityRequest(const char* _class, float x, float y, float z, const char* stateData);


// StateDataUpdate

struct StateDataUpdate : MessageType
{
    StateDataUpdate() : MessageType(1011, "StateDataUpdate") { };

    void receive(int receiver, int sender, ucharbuf &p);
};

void send_StateDataUpdate(int clientNumber, int uid, int keyProtocolId, const char* value, int originalClientNumber);


// StateDataChangeRequest

struct StateDataChangeRequest : MessageType
{
    StateDataChangeRequest() : MessageType(1012, "StateDataChangeRequest") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_StateDataChangeRequest(int uid, int keyProtocolId, const char* value);


// UnreliableStateDataUpdate

struct UnreliableStateDataUpdate : MessageType
{
    UnreliableStateDataUpdate() : MessageType(1013, "UnreliableStateDataUpdate") { };

    void receive(int receiver, int sender, ucharbuf &p);
};

void send_UnreliableStateDataUpdate(int clientNumber, int uid, int keyProtocolId, const char* value, int originalClientNumber);


// UnreliableStateDataChangeRequest

struct UnreliableStateDataChangeRequest : MessageType
{
    UnreliableStateDataChangeRequest() : MessageType(1014, "UnreliableStateDataChangeRequest") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_UnreliableStateDataChangeRequest(int uid, int keyProtocolId, const char* value);


// NotifyNumEntities

struct NotifyNumEntities : MessageType
{
    NotifyNumEntities() : MessageType(1015, "NotifyNumEntities") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_NotifyNumEntities(int clientNumber, int num);


// AllActiveEntitiesSent

struct AllActiveEntitiesSent : MessageType
{
    AllActiveEntitiesSent() : MessageType(1016, "AllActiveEntitiesSent") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_AllActiveEntitiesSent(int clientNumber);


// ActiveEntitiesRequest

struct ActiveEntitiesRequest : MessageType
{
    ActiveEntitiesRequest() : MessageType(1017, "ActiveEntitiesRequest") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_ActiveEntitiesRequest(const char* scenarioCode);


// LogicEntityCompleteNotification

struct LogicEntityCompleteNotification : MessageType
{
    LogicEntityCompleteNotification() : MessageType(1018, "LogicEntityCompleteNotification") { };

    void receive(int receiver, int sender, ucharbuf &p);
};

void send_LogicEntityCompleteNotification(int clientNumber, int otherClientNumber, int otherUniqueId, const char* otherClass, const char* stateData);


// RequestLogicEntityRemoval

struct RequestLogicEntityRemoval : MessageType
{
    RequestLogicEntityRemoval() : MessageType(1019, "RequestLogicEntityRemoval") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RequestLogicEntityRemoval(int uid);


// LogicEntityRemoval

struct LogicEntityRemoval : MessageType
{
    LogicEntityRemoval() : MessageType(1020, "LogicEntityRemoval") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_LogicEntityRemoval(int clientNumber, int uid);


// ExtentCompleteNotification

struct ExtentCompleteNotification : MessageType
{
    ExtentCompleteNotification() : MessageType(1021, "ExtentCompleteNotification") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_ExtentCompleteNotification(int clientNumber, int otherUniqueId, const char* otherClass, const char* stateData);


// InitS2C

struct InitS2C : MessageType
{
    InitS2C() : MessageType(1022, "InitS2C") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_InitS2C(int clientNumber, int explicitClientNumber, int protocolVersion);

// EditModeC2S

struct EditModeC2S : MessageType
{
    EditModeC2S() : MessageType(1028, "EditModeC2S") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_EditModeC2S(int mode);


// EditModeS2C

struct EditModeS2C : MessageType
{
    EditModeS2C() : MessageType(1029, "EditModeS2C") { };

    void receive(int receiver, int sender, ucharbuf &p);
};

void send_EditModeS2C(int clientNumber, int otherClientNumber, int mode);


// RequestMap

struct RequestMap : MessageType
{
    RequestMap() : MessageType(1030, "RequestMap") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RequestMap();


// DoClick

struct DoClick : MessageType
{
    DoClick() : MessageType(1031, "DoClick") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_DoClick(int button, int down, float x, float y, float z, int uid);


// RequestPrivateEditMode

struct RequestPrivateEditMode : MessageType
{
    RequestPrivateEditMode() : MessageType(1034, "RequestPrivateEditMode") { };

#ifdef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_RequestPrivateEditMode();


// NotifyPrivateEditMode

struct NotifyPrivateEditMode : MessageType
{
    NotifyPrivateEditMode() : MessageType(1035, "NotifyPrivateEditMode") { };

#ifndef SERVER
    void receive(int receiver, int sender, ucharbuf &p);
#endif
};

void send_NotifyPrivateEditMode(int clientNumber);

#endif
