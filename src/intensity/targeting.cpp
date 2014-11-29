
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "targeting.h"

vec           TargetingControl::targetPosition;
CLogicEntity *TargetingControl::targetLogicEntity = NULL;

void TargetingControl::intersectClosestDynamicEntity(vec &from, vec &to, physent *targeter, float& dist, dynent*& target)
{
    dynent *best = NULL;
    float bestdist = 1e16f;
    loopi(game::numdynents())
    {
        dynent *o = game::iterdynents(i);
        if(!o || o==targeter) continue;
        if(!game::intersect(o, from, to)) continue;
        float dist = from.dist(o->o);
        if(dist<bestdist)
        {
            best = o;
            bestdist = dist;
        }
    }
    dist = bestdist;
    target = best;
}

void TargetingControl::intersectClosestMapmodel(vec &from, vec &to, float& dist, extentity*& target)
{
    vec unitv;
    float maxdist = to.dist(from, unitv);
    unitv.div(maxdist);

    vec hitpos;
    int orient, ent;
    extern float rayent(const vec &o, const vec &ray, float radius, int mode, int size, int &orient, int &ent);
    dist = rayent(from, unitv, 1000.0f, RAY_CLIPMAT|RAY_ALPHAPOLY/*was: RAY_ENTS*/, 0, orient, ent); // TODO: maxdist, or 1000.0f...?

    if (ent != -1)
        target = entities::getents()[ent];
    else
    {
        target = NULL;
        dist = -1;
    };
}

void TargetingControl::intersectClosest(vec &from, vec &to, physent *targeter, float& dist, CLogicEntity *&entity)
{
    extern int enthover;

    // Check if Sauer already found us hovering on an entity
    // Note that we will be -1 if no entity, or we might be too high, if enthover is outdated
    const vector<extentity *> &ents = entities::getents();
    if (ents.inrange(enthover))
    {
        dist = -7654; // TODO: Calculate
        entity = LogicSystem::getLogicEntity(ents[enthover]->uid);
    } else {
        // Manually check if we are hovering, using ray intersections. TODO: Not needed for extents?
        CLogicEntity *ignore = targeter ? LogicSystem::getLogicEntity(((gameent*)targeter)->uid) : NULL;
        float dynamicDist, staticDist;
        dynent* dynamicEntity;
        extentity* staticEntity;
        TargetingControl::intersectClosestDynamicEntity(from, to, ignore ? ignore->dynamicEntity : NULL, dynamicDist,  dynamicEntity);
        TargetingControl::intersectClosestMapmodel     (from, to,                                        staticDist, staticEntity);

        dist = -1;

        gameent *d = (gameent*)dynamicEntity;
        if (dynamicEntity == NULL && staticEntity == NULL)
        {
            dist = -1;
            entity = NULL;
        } else if (dynamicEntity != NULL && staticEntity == NULL)
        {
            dist = dynamicDist;
            entity = LogicSystem::getLogicEntity(d->uid);
        } else if (dynamicEntity == NULL && staticEntity != NULL)
        {
            dist = staticDist;
            entity = LogicSystem::getLogicEntity(staticEntity->uid);
        } else if (staticDist < dynamicDist)
        {
            dist = staticDist;
            entity = LogicSystem::getLogicEntity(staticEntity->uid);
        } else {
            dist = dynamicDist;
            entity = LogicSystem::getLogicEntity(d->uid);
        }
    }
}

VAR(has_mouse_target, 0, 0, 1);

void TargetingControl::determineMouseTarget(bool forceEntityCheck)
{
    targetLogicEntity = NULL;
    if (!editmode && !forceEntityCheck)
    {
        TargetingControl::targetLogicEntity = NULL;
        TargetingControl::targetPosition = worldpos;
        has_mouse_target = 0;
    } else {
        static long lastEntityCheck = -1; // Use this to not run an actual entity check more than 1/frame

        if (lastEntityCheck != lastmillis)
        {
            float dist;

            TargetingControl::intersectClosest(camera1->o,
                                               worldpos,
                                               camera1,
                                               dist,
                                               TargetingControl::targetLogicEntity);

            // If not edit mode, ignore the player itself
            if (!editmode && TargetingControl::targetLogicEntity &&
                TargetingControl::targetLogicEntity->uniqueId == game::player1->uid)
            {
                // Try to see if the player was the sole cause of collision - move it away, test, then move it back
                vec save = game::player1->o;
                game::player1->o.add(10000.0);

                TargetingControl::intersectClosest(camera1->o,
                                                   worldpos,
                                                   camera1,
                                                   dist,
                                                   TargetingControl::targetLogicEntity);

                game::player1->o = save;
            }

            has_mouse_target = TargetingControl::targetLogicEntity != NULL;

            if (has_mouse_target)
            {
                vec temp(worldpos);
                temp.sub(camera1->o);
                temp.normalize();
                temp.mul(dist);
                temp.add(camera1->o);

                TargetingControl::targetPosition = temp;
            } else
                TargetingControl::targetPosition = worldpos;

            lastEntityCheck = lastmillis;
        }
    }
}
