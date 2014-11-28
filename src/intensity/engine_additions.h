
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

struct entlinkpos {
    vec pos;
    int millis;
    entlinkpos(const vec &pos = vec(0), int millis = 0):
        pos(pos), millis(millis) {}
};

struct CLogicEntity
{
    physent*   dynamicEntity;      //!< Only one of dynamicEntity and staticEntity should be not null, corresponding to the type
    extentity* staticEntity;       //!< Only one of dynamicEntity and staticEntity should be not null, corresponding to the type

    int uniqueId; //!< Only used for nonSauer

    //! The attachments for this entity
    vector<modelattach> attachments;

    //! For attachments that are position markers, the positions go here XXX: Note that current these are readable only clientside
    //! as they require a call to rendering
    hashtable<const char*, entlinkpos> attachment_positions;

    //! The current animation for this entity
    int anim;

    //! The start time of the current animation for this entity
    int startTime;

    //! Whether this entity can move on its own volition
    bool canMove;

    CLogicEntity(): dynamicEntity(NULL), staticEntity(NULL), uniqueId(-8), anim(0), startTime(0)
        { attachments.add(modelattach()); };
    CLogicEntity(physent*    _dynamicEntity) : dynamicEntity(_dynamicEntity),
        staticEntity(NULL), uniqueId(-8), anim(0), startTime(0)
        { attachments.add(modelattach()); };
    CLogicEntity(extentity* _staticEntity): dynamicEntity(NULL),
        staticEntity(_staticEntity), uniqueId(-8), anim(0), startTime(0)
        { attachments.add(modelattach()); };
    CLogicEntity(int _uniqueId): dynamicEntity(NULL), staticEntity(NULL),
        uniqueId(_uniqueId), anim(0), startTime(0)
        { attachments.add(modelattach()); }; // This is a non-Sauer LE
    ~CLogicEntity() { clear_attachments(); }

    void clear_attachments();

    //! The sauer code for the current running animation
    int  getAnimation();

    //! When the current animation started
    int getStartTime();

    //! Updates the attachments based on lua information. Refreshes what is needed in Sauer
    void setAttachments(const char **attach);

    //! Updates the animation based on lua information. Refreshes what is needed in Sauer. In particular sets the start time.
    void setAnimation(int anim);

    vec& getAttachmentPosition(const char *tag);
};

//! The main storage for LogicEntities and management of them. All entities appear in the central list
//! of logic entities here, as well as other scenario-wide data.

struct LogicSystem
{
    typedef hashtable<int, CLogicEntity*> LogicEntityMap;

    static bool initialized;
    static LogicEntityMap logicEntities; //!< All the entities in the scenario

    //! Called before a map loads. Empties list of entities, and unloads the PC logic entity. Removes the lua engine
    static void clear(bool restart_lua = false);

    //! Calls clear(), and creates a new lua engine
    static void init();

    //! Register a logic entity in the LogicSystem system. Must be done so that entities are accessible and are managed.
    static void          registerLogicEntity(CLogicEntity *newEntity);

    //! Unregisters a C++ GE, removes it from the set of currently running entities. Needs to not overload the other,
    //! but have a different name, because we expose this in the lua embedding
    static void          unregisterLogicEntityByUniqueId(int uniqueId);

    //! Tells the ActionSystems of all of our logic entities to manage themselves, i.e., to run their actions accordingly
    //! This is done both on the client and the server, even on entities not controlled by each. The reason is that we
    //! may e.g. have visual effects on an NPC running on the client, and so forth
    static void          manageActions(long millis);

    static CLogicEntity *getLogicEntity(int uniqueId);
    static CLogicEntity *getLogicEntity(const extentity &extent);
    static CLogicEntity *getLogicEntity(physent* entity);

    static void setupExtent(int uid, int type);

    static void setupCharacter(int uid, int cn);

    static void setupNonSauer(int uid);

    static void dismantleExtent(int uid);
    static void dismantleCharacter(int cn);
};

