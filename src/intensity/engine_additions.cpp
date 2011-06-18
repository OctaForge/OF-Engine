
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"
#include "client_system.h"
#include "world_system.h"
#include "of_tools.h"
#include "of_entities.h"

using namespace lua;

// WorldSystem
extern void removeentity(extentity* entity);
extern void addentity(extentity* entity);

bool dropentity(entity &e, int drop = -1);

//=========================
// Logic Entities
//=========================

int CLogicEntity::getUniqueId()
{
    switch (getType())
    {
        case LE_DYNAMIC:
            return LogicSystem::getUniqueId(dynamicEntity);
        case LE_STATIC:
            return LogicSystem::getUniqueId(staticEntity);
        case LE_NONSAUER:
            return uniqueId; // This can be made to work for the others, if we ensure that uniqueId is set. Would be faster
        default:
            assert(0 && "getting the unique ID of a NONE logic entity!\r\n");
            return -1;
    };
}

int CLogicEntity::getType()
{
    if (dynamicEntity != NULL)
        return LE_DYNAMIC;
    else if (staticEntity != NULL)
        return LE_STATIC;
    else if (nonSauer)
        return LE_NONSAUER;
    else
        return LE_NONE;
}

extern vector<mapmodelinfo> mapmodels; // KLUDGE

vec CLogicEntity::getOrigin()
{
    switch (getType())
    {
        case LE_DYNAMIC:
            return dynamicEntity->o;
        case LE_STATIC:
        {
            if (staticEntity->type == ET_MAPMODEL)
            {
                vec bbcenter, bbradius;
                model *m = theModel;
                if (m)
                {
                    CLogicEntity *ptr = LogicSystem::getLogicEntity(getUniqueId());
                    assert(ptr);
                    m->collisionbox(0, bbcenter, bbradius, ptr);
                    rotatebb(bbcenter, bbradius, int(staticEntity->attr1));
                    bbcenter.add(staticEntity->o);
                    return bbcenter;
                } else {
                    logger::log(logger::WARNING, "Invalid mapmodel model\r\n");
                    return staticEntity->o;
                }
            } else
                return staticEntity->o;
        }
    };

    assert(0 && "getting the origin of a NONE or non-Sauer LogicEntity!");
    return vec(0,0,0);
}

float CLogicEntity::getRadius()
{
    switch (getType())
    {
        case LE_DYNAMIC:
            return 10;
        case LE_STATIC:
        {
            if (staticEntity->type == ET_MAPMODEL)
            {
                vec bbcenter, bbradius;
                model *m = theModel;
                if (m)
                {
                    CLogicEntity *ptr = LogicSystem::getLogicEntity(getUniqueId());
                    assert(ptr);
                    m->collisionbox(0, bbcenter, bbradius, ptr);
                    rotatebb(bbcenter, bbradius, int(staticEntity->attr1));
                    bbcenter.add(staticEntity->o);
                    return bbradius.x + bbradius.y;
                } else {
                    logger::log(logger::WARNING, "Invalid mapmodel model, cannot find radius\r\n");
                    return 8;
                }

            } else
                return 8;
        }
    };

    assert(0 && "getting the radius of a NONE or non-Sauer LogicEntity!");
    return -1;
}

void CLogicEntity::setOrigin(vec &newOrigin)
{
    defformatstring(c)("entity_store.get(%i).position = {%f,%f,%f}", getUniqueId(), newOrigin.x, newOrigin.y, newOrigin.z);
    engine.exec(c);
}

int CLogicEntity::getAnimation()
{
    return animation;
}

int CLogicEntity::getStartTime()
{
    return startTime;
}

int CLogicEntity::getAnimationFrame()
{
    return 0; /* DEPRECATED for now */
}

std::string CLogicEntity::getClass()
{
    engine.getg("tostring").getref(luaRef).call(1, 1);
    std::string _class = engine.get(-1, "unknown");
    engine.pop(1);
    return _class;
}

model* CLogicEntity::getModel()
{
    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return NULL;

    // Fallback to sauer mapmodel system, if not overidden (-1 or less in attr2 if so)
    if (staticEntity && staticEntity->type == ET_MAPMODEL && staticEntity->attr2 >= 0)
    {
        // If no such model, leave the current model, from modelName
        model* possible = loadmodel(NULL, staticEntity->attr2);
        if (possible && possible != theModel)
            theModel = possible;
    }

    return theModel;
}

void CLogicEntity::setModel(std::string name)
{
    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    if (staticEntity)
        removeentity(staticEntity);

    if (name != "")
        theModel = loadmodel(name.c_str());

    logger::log(logger::DEBUG, "CLE:setModel: %s (%lu)\r\n", name.c_str(), (unsigned long)theModel);

    if (staticEntity)
    {
//        #ifdef SERVER
//            if (name != "" && staticEntity->type == ET_MAPMODEL)
//            {
//                scriptEntity->setProperty("attr2", -1); // Do not use sauer mmodel list
//            }
//        #endif

        // Refresh the entity in sauer
        addentity(staticEntity);
    }
}

void CLogicEntity::setAttachments(std::string _attachments)
{
    logger::log(logger::DEBUG, "CLogicEntity::setAttachments: %s\r\n", _attachments.c_str());

    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    // Clean out old data
    for (int i = 0; attachments[i].tag; i++)
    {
        delete[] attachments[i].tag;
        delete[] attachments[i].name;
    }

    // Generate new data
    int num = 0, i = 0;
    char *curr = NULL, *name = NULL, *tag = NULL;
    char *data = newstring(_attachments.c_str());
    char * pch = strchr(data, '|');

    while (pch)
    {
        num++;
        pch = strchr(pch + 1, '|');
    }
    /* Because it'd be 1 even with no attachments. */
    if (_attachments != "") num++;

    assert(num <= MAX_ATTACHMENTS);

    pch = strtok(data, "|");
    while (pch)
    {
        curr = newstring(pch);
        if (!strchr(curr, ','))
        {
            name = NULL;
            tag  = curr;
        }
        else
        {
            tag  = strtok(curr, ",");
            name = strtok(NULL, ",");
        }

        /* Tags starting with a '*' indicate this is a position marker */
        if (strlen(tag) >= 1 && tag[0] == '*')
        {
            tag++;
            attachments[i].pos = &attachmentPositions[i];
            /* Initialize, as if the attachment doesn't exist in the model,
             * we don't want NaNs and such causing crashes
             */
            attachmentPositions[i] = vec(0, 0, 0);
        }
        else attachments[i].pos = NULL;

        attachments[i].tag  = newstring(tag);
        attachments[i].name = name ? newstring(name) : newstring("");
        /* attachments[i].anim = ANIM_VWEP | ANIM_LOOP;
         * This will become important if/when we have animated attachments
         */
        attachments[i].basetime = 0;

        logger::log(
            logger::DEBUG,
            "Adding attachment: %s - %s\r\n",
            attachments[i].name,
            attachments[i].tag
        );

        delete[] curr;

        pch = strtok(NULL, "|");
        i++;
    }

    /* tag=null as well - probably not needed (order reversed with following line) */
    attachments[num].tag  = NULL;
    /* Null name element at the end, for sauer to know to stop */
    attachments[num].name = NULL;

    delete[] data;
}

void CLogicEntity::setAnimation(int _animation)
{
    logger::log(logger::DEBUG, "setAnimation: %d\r\n", _animation);

    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    logger::log(logger::DEBUG, "(2) setAnimation: %d\r\n", _animation);

    animation = _animation;
    startTime = lastmillis; // tools::currtime(); XXX Do NOT want the actual time! We
                            // need 'lastmillis', sauer's clock, which doesn't advance *inside* frames,
                            // because otherwise the starttime may be
                            // LATER than lastmillis, while sauer's animation system does lastmillis-basetime,
                            // leading to a negative number and segfaults in finding frame data
}

void CLogicEntity::setSound(std::string _sound)
{
    logger::log(logger::DEBUG, "setSound: %s\r\n", _sound.c_str());

    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    logger::log(logger::DEBUG, "(2) setSound: %s\r\n", _sound.c_str());

    soundName = _sound;

#ifdef CLIENT
    stopmapsound(staticEntity);
    if(camera1->o.dist(staticEntity->o) < staticEntity->attr2)
      {
        if(!staticEntity->visible) playmapsound(soundName.c_str(), staticEntity, staticEntity->attr4, -1);
        else if(staticEntity->visible) stopmapsound(staticEntity);
      }
#else
    MessageSystem::send_MapSoundToClients(-1, soundName.c_str(), LogicSystem::getUniqueId(staticEntity));
#endif
}

const char *CLogicEntity::getSound()
{
    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return NULL;

    return soundName.c_str();
}

vec& CLogicEntity::getAttachmentPosition(std::string tag)
{
    // If last actual render - which actually calculated the attachment positions - was recent
    // enough, use that data
    if (abs(lastmillis - lastActualRenderMillis) < 500)
    {
        // TODO: Use a hash table. But, if just 1-4 attachments, then fast enough for now as is
        for (int i = 0; attachments[i].tag; i++)
        {
            if (attachments[i].tag == tag)
                return attachmentPositions[i];
        }
    }
    static vec missing; // Returned if no such tag, or no recent attachment position info. Note: Only one of these, static!
    missing = getOrigin();
    return missing;
}

void CLogicEntity::noteActualRender()
{
    lastActualRenderMillis = lastmillis;
}


//=========================
// LogicSystem
//=========================

LogicSystem::LogicEntityMap LogicSystem::logicEntities;

void LogicSystem::clear()
{
    logger::log(logger::DEBUG, "clear()ing LogicSystem\r\n");
    INDENT_LOG(logger::DEBUG);

    if (engine.hashandle())
    {
        engine.getg("entity_store").t_getraw("del_all").call(0, 0).pop(1);
        assert(logicEntities.size() == 0);

        //engine.destroy();
    }
}

void LogicSystem::init()
{
    clear();
    engine.create();
}

void LogicSystem::registerLogicEntity(CLogicEntity *newEntity)
{
    logger::log(logger::DEBUG, "C registerLogicEntity: %d\r\n", newEntity->getUniqueId());
    INDENT_LOG(logger::DEBUG);

    int uniqueId = newEntity->getUniqueId();
    assert(logicEntities.find(uniqueId) == logicEntities.end());
    logicEntities.insert( LogicEntityMap::value_type( uniqueId, newEntity ) );

    engine.getg("entity_store").t_getraw("get").push(uniqueId).call(1, 1);
    newEntity->luaRef = engine.ref();
    engine.pop(1);

    assert(newEntity->luaRef >= 0);

    logger::log(logger::DEBUG, "C registerLogicEntity completes\r\n");
}

CLogicEntity *LogicSystem::registerLogicEntity(physent* entity)
{
    if (getUniqueId(entity) < 0)
    {
        logger::log(logger::ERROR, "Trying to register an entity with an invalid unique Id: %d (D)\r\n", getUniqueId(entity));
        assert(0);
    }

    CLogicEntity *newEntity = new CLogicEntity(entity);

    logger::log(logger::DEBUG, "adding physent %d\r\n", newEntity->getUniqueId());

    registerLogicEntity(newEntity);

    return newEntity;
}

CLogicEntity *LogicSystem::registerLogicEntity(extentity* entity)
{
    if (getUniqueId(entity) < 0)
    {
        logger::log(logger::ERROR, "Trying to register an entity with an invalid unique Id: %d (S)\r\n", getUniqueId(entity));
        assert(0);
    }

    CLogicEntity *newEntity = new CLogicEntity(entity);

//    logger::log(logger::DEBUG, "adding entity %d : %d,%d,%d,%d\r\n", entity->type, entity->attr1, entity->attr2, entity->attr3, entity->attr4);

    registerLogicEntity(newEntity);

    return newEntity;
}

void LogicSystem::registerLogicEntityNonSauer(int uniqueId)
{
    CLogicEntity *newEntity = new CLogicEntity(uniqueId);

    newEntity->nonSauer = true; // Set as non-Sauer

    logger::log(logger::DEBUG, "adding non-Sauer entity %d\r\n", uniqueId);

    registerLogicEntity(newEntity);

//    return newEntity;
}

void LogicSystem::unregisterLogicEntityByUniqueId(int uniqueId)
{
    logger::log(logger::DEBUG, "UNregisterLogicEntity by UniqueID: %d\r\n", uniqueId);

    CLogicEntity *ptr = logicEntities[uniqueId];

    logicEntities.erase(uniqueId);
    if (!ptr) return;

    for (int i = 0; ptr->attachments[i].tag; i++)
    {
        delete[] ptr->attachments[i].tag;
        delete[] ptr->attachments[i].name;
    }

    if (ptr->luaRef >= 0) engine.unref(ptr->luaRef);
    delete ptr;
}

void LogicSystem::manageActions(long millis)
{
    logger::log(logger::INFO, "manageActions: %d\r\n", millis);
    INDENT_LOG(logger::INFO);

    if (engine.hashandle())
        engine.getg("entity_store")
              .t_getraw("manage_actions")
              .push(double(millis) / 1000.0f)
              .push(lastmillis).call(2, 0).pop(1);

    logger::log(logger::INFO, "manageActions complete\r\n");
}

CLogicEntity *LogicSystem::getLogicEntity(int uniqueId)
{
    LogicEntityMap::iterator iter = logicEntities.find(uniqueId);

    if (iter == logicEntities.end())
    {
        logger::log(logger::INFO, "(C++) Trying to get a non-existant logic entity %d\r\n", uniqueId);
        return NULL;
    }

    return iter->second;
}

CLogicEntity *LogicSystem::getLogicEntity(const extentity &extent)
{
    return getLogicEntity(extent.uniqueId);
}


CLogicEntity *LogicSystem::getLogicEntity(physent* entity)
{
    return getLogicEntity(getUniqueId(entity)); // TODO: do this directly, without the intermediary getUniqueId, for speed?
}

int LogicSystem::getUniqueId(extentity* staticEntity)
{
    return staticEntity->uniqueId;
}

int LogicSystem::getUniqueId(physent* dynamicEntity)
{
    return ((fpsent*)dynamicEntity)->uniqueId;
}

// TODO: Use this whereever it should be used
void LogicSystem::setUniqueId(extentity* staticEntity, int uniqueId)
{
    if (getUniqueId(staticEntity) >= 0)
    {
        logger::log(logger::ERROR, "Trying to set to %d a unique Id that has already been set, to %d (S)\r\n",
                                     uniqueId,
                                     getUniqueId(staticEntity));
        assert(0);
    }

    staticEntity->uniqueId = uniqueId;
}

// TODO: Use this whereever it should be used
void LogicSystem::setUniqueId(physent* dynamicEntity, int uniqueId)
{
    logger::log(logger::DEBUG, "Setting a unique ID: %d (of addr: %d)\r\n", uniqueId, dynamicEntity != NULL);

    if (getUniqueId(dynamicEntity) >= 0)
    {
        logger::log(logger::ERROR, "Trying to set to %d a unique Id that has already been set, to %d (D)\r\n",
                                     uniqueId,
                                     getUniqueId(dynamicEntity));
        assert(0);
    }

    ((fpsent*)dynamicEntity)->uniqueId = uniqueId;
}

void LogicSystem::setupExtent(int ref, int type, float x, float y, float z, int attr1, int attr2, int attr3, int attr4)
{
    engine.getref(ref);
    int uniqueId = engine.t_get("uid", -1);
    engine.pop(1);

    logger::log(logger::DEBUG, "setupExtent: %d,  %d : %f,%f,%f : %d,%d,%d,%d\r\n", uniqueId, type, x, y, z, attr1, attr2, attr3, attr4);
    INDENT_LOG(logger::DEBUG);

    extentity &e = *(new extentity);
    entities::storage.add(&e);

    e.type  = type;
    e.o     = vec(x,y,z);
    e.attr1 = attr1;
    e.attr2 = attr2;
    e.attr3 = attr3;
    e.attr4 = attr4;

    e.inoctanode = false; // This is not set by the constructor in sauer, but by those calling "new extentity", so we also do that here

    extern void addentity(extentity* entity);
    addentity(&e);
    attachentity(e);

    LogicSystem::setUniqueId(&e, uniqueId);
    LogicSystem::registerLogicEntity(&e);
}

void LogicSystem::setupCharacter(int ref)
{
//    #ifdef CLIENT
//        assert(0); // until we figure this out
//    #endif

    engine.getref(ref);
    int uniqueId = engine.t_get("uid", -1);

    logger::log(logger::DEBUG, "setupCharacter: %d\r\n", uniqueId);
    INDENT_LOG(logger::DEBUG);

    fpsent* fpsEntity;

    int clientNumber = engine.t_get("cn", -1);
    logger::log(logger::DEBUG, "(a) cn: %d\r\n", clientNumber);

    #ifdef CLIENT
        logger::log(logger::DEBUG, "client numbers: %d, %d\r\n", ClientSystem::playerNumber, clientNumber);

        if (uniqueId == ClientSystem::uniqueId) engine.t_set("cn", ClientSystem::playerNumber);
    #endif

    // nothing else will happen with lua table got from ref, so let's pop it out
    engine.pop(1);

    logger::log(logger::DEBUG, "(b) cn: %d\r\n", clientNumber);

    assert(clientNumber >= 0);

    #ifdef CLIENT
    // If this is the player. There should already have been created an fpsent for this client,
    // which we can fetch with the valid client #
    logger::log(logger::DEBUG, "UIDS: in ClientSystem %d, and given to us%d\r\n", ClientSystem::uniqueId, uniqueId);

    if (uniqueId == ClientSystem::uniqueId)
    {
        logger::log(logger::DEBUG, "This is the player, use existing clientnumber for fpsent (should use player1?) \r\n");

        fpsEntity = dynamic_cast<fpsent*>( game::getclient(clientNumber) );

        // Wipe clean the uniqueId set for the fpsent, so we can re-use it.
        fpsEntity->uniqueId = -77;
    }
    else
    #endif
    {
        logger::log(logger::DEBUG, "This is a remote client or NPC, do a newClient for the fpsent\r\n");

        // This is another client, perhaps NPC. Connect this new client using newClient
        fpsEntity =  dynamic_cast<fpsent*>( game::newclient(clientNumber) );
    }

    // Register with the C++ system.

    LogicSystem::setUniqueId(fpsEntity, uniqueId);
    LogicSystem::registerLogicEntity(fpsEntity);
}

void LogicSystem::setupNonSauer(int ref)
{
    engine.getref(ref);
    int uniqueId = engine.t_get("uid", -1);
    engine.pop(1);

    logger::log(logger::DEBUG, "setupNonSauer: %d\r\n", uniqueId);
    INDENT_LOG(logger::DEBUG);

    LogicSystem::registerLogicEntityNonSauer(uniqueId);
}

void LogicSystem::dismantleExtent(int ref)
{
    engine.getref(ref);
    int uniqueId = engine.t_get("uid", -1);
    engine.pop(1);

    logger::log(logger::DEBUG, "Dismantle extent: %d\r\n", uniqueId);

    extentity* extent = getLogicEntity(uniqueId)->staticEntity;
#ifdef CLIENT
    if (extent->type == ET_SOUND) stopmapsound(extent);
#endif
    removeentity(extent);
    extent->type = ET_EMPTY;

//    delete extent; extent = NULL; // For symmetry with the "new extentity" this should be here, but sauer does it
                                                     // in clearents() in the next load_world.
}

void LogicSystem::dismantleCharacter(int ref)
{
    engine.getref(ref);
    int clientNumber = engine.t_get("cn", -1);
    engine.pop(1);
    #ifdef CLIENT
    if (clientNumber == ClientSystem::playerNumber)
        logger::log(logger::DEBUG, "Not dismantling own client\r\n", clientNumber);
    else
    #endif
    {
        logger::log(logger::DEBUG, "Dismantling other client %d\r\n", clientNumber);

#ifdef SERVER
        fpsent* fpsEntity = dynamic_cast<fpsent*>( game::getclient(clientNumber) );
        bool isNPC = fpsEntity->serverControlled;
#endif

        game::clientdisconnected(clientNumber);

#ifdef SERVER
        if (isNPC)
        {
            /* The server connections of NPCs are removed when they are dismantled -
             * they must be re-created manually in the new scenario, unlike players */
            localdisconnect(true, clientNumber);
        }
#endif
    }
}
