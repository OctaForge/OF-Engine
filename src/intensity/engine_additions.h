
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

//! An entity in the scenario, something that can act or be acted upon. Note that most of the
//! logic occurs on the server; LogicEntity is just for minimal client-side logic.
//!
//! LogicEntity wraps around the Sauer types, so in practice a LogicEntity is either a dynamic entity
//! (PC/NPC - TODO: Make this gameent? Or do we need movables also?) or a mapmodel. This is completely
//! transparent to users of the LogicEntity class, but they can query the type if they need to.
//!
//! LogicEntities have unique IDs. These are unique in a module (but not a map - entities can
//! move between maps).

struct entlinkpos {
    vec pos;
    int millis;
    entlinkpos(const vec &pos = vec(0), int millis = 0):
        pos(pos), millis(millis) {}
};

struct CLogicEntity
{
    enum {LE_DYNAMIC, LE_STATIC, LE_NONSAUER}; //!< Possible types for a logic entity, correspond to Sauer types

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

    //! Returns the unique ID for this entity
    int   getUniqueId();

    //! Returns the type, i.e., dynamic (player, NPC - physent/gameent), or static (mapmodel). In the future, also lights, etc.
    int   getType();

    bool  isDynamic() { return getType() == LE_DYNAMIC; };
    bool  isStatic()  { return getType() == LE_STATIC;  };

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

    static CLogicEntity *registerLogicEntity(physent* entity);
    static CLogicEntity *registerLogicEntity(extentity* entity);

    //! Register a Logic Entity that is not based on a Sauer type, i.e., is not a physent or an extent
    static void           registerLogicEntityNonSauer(int uniqueId);

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

    static int           getUniqueId(extentity* staticEntity);
    static int           getUniqueId(physent*    dynamicEntity);

    //! Done only in initial preparation of an entity - never afterwards. Note: This is a member of LogicSystem because it would be
    //! invalid as a member of LogicEntity - a LogicEntity, if it exists, must have a valid Id! (i.e., >= 0)
    static void          setUniqueId(extentity* staticEntity, int uniqueId);

    //! Done only in initial preparation of an entity - never afterwards
    static void          setUniqueId(physent* dynamicEntity, int uniqueId);

    static void setupExtent(int ref, int type);

    static void setupCharacter(int ref);

    static void setupNonSauer(int ref);

    static void dismantleExtent(int ref);
    static void dismantleCharacter(int ref);
};

