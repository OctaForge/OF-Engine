
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

//! System management for the client: usernames, passwords, logging in, client numbers, etc.

struct ClientSystem
{
    //! The client number of the PC. A copy of player1->clientnum, but nicer name
    static int           playerNumber;

    //! Convenient way to get at the player's logic entity
    static CLogicEntity *playerLogicEntity;

    //! Whether logged in to a _remote_ server. There is no 'login' locally, just 'connecting'.
    static bool          loggedIn;

    //! Whether we are only connecting locally
    static bool          editingAlone;

    //! UniqueID of the player in the current module. Set in a successful response to
    //! logging in. When we then load a map, this is used to create the player's
    //! LogicEntity.
    static int           uniqueId;

    //! An identifier for the current scenario the client is active in. Used to check with the
    //! server, when the server starts a new scenario, to know when we are in sync or not
    static types::string currScenarioCode;

    // Functions

    //! Connects to the server, at the enet level
    static void connect(const char *host, int port);

    //! After connected at the enet level, validate ourselves to the server using the transactionCode we received from the master server
    //!
    //! clientNumber: The client # the server gave to us. Placed in playerNumber.
    static void login(int clientNumber);

    //! Called upon a successful login to an instance. Sets logged in state to true, and the uniqueID as that received
    //! from the LoginResponse.
    static void finishLogin(bool local);

    //! Disconnects from the server and returns to the main menu
    static void doDisconnect();

    //! Marks the status as not logged in. Called on a disconnect from sauer's client.h:gamedisconnect()
    static void onDisconnect();

    //! Whether the scenario has actually started, i.e., we have received everything we need from the server to get going
    static bool scenarioStarted();

    //! Stuff done on each frame
    static void frameTrigger(int curtime);

    static void finishLoadWorld();

    static void prepareForNewScenario(const types::string& buf);

    //! Check if this user has admin privileges, which allows entering edit mode and using the Sauer console (/slash)
    static bool isAdmin();

    static void addHUDImage(const char *tex, float centerX, float centerY, float widthInUniform, float heightInUniform, int color = 0xFFFFFF, float alpha = 1.0f);

    static void addHUDText(const char *text, float x, float y, float scale, int color);

    // x2 < 0 means it is a uniform width; ditto y2 for height
    static void addHUDRect(float x1, float y1, float x2, float y2, int color, float alpha = 1.0f);

    //! Show the current HUD. Called once per frame
    static void drawHUD(int w, int h);

    //! Show the minimap. Called once per frame
    static void drawMinimap(int w, int h);

    //! Called once/frame, after drawing the HUD. Cleans up temporary structures.
    //! It is important to call this even if the HUD is not drawn (e.g. in edit
    //! mode).
    static void cleanupHUD();
};

