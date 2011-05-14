
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "targeting.h"

#ifdef CLIENT
    #include "client_system.h"
#endif


#ifdef CLIENT
void TargetingControl::setupOrientation()
{
    extern float curfov, aspect; // rendergl.cpp

    vecfromyawpitch(camera1->yaw, 0,                   0, -1, camright);
    vecfromyawpitch(camera1->yaw, camera1->pitch + 90, 1,  0, camup);

    // Account for mouse position in the world position we are aiming at
    float cx, cy;
    g3d_cursorpos(cx, cy);

    float factor = tanf(RAD*curfov/2.0f); // Size of edge opposite the angle of fov/2, in the triangle for (half of) viewport,
                                          // having unknown radius but known angle of fov/2 and close edge of 1.0

    camdir.x = 0.0f; camdir.y = 1.0f; camdir.z = 0.0f; // Looking straight forward
    camdir.x -= 2.0f * (cx - 0.5f) * factor;            // adjust for mouse position
    camdir.z -= 2.0f * (cy - 0.5f) * factor / aspect;   // adjust for mouse position

    camdir.normalize();

    camdir.rotate_around_z(RAD*camera1->yaw);
    camdir.rotate(-RAD*camera1->pitch, camright);

    if(raycubepos(camera1->o, camdir, worldpos, 0, RAY_CLIPMAT|RAY_SKIPFIRST) == -1)
        worldpos = vec(camdir).mul(2*worldsize).add(camera1->o); //otherwise 3dgui won't work when outside of map
}
#endif

#ifdef CLIENT
vec           TargetingControl::worldPosition;
vec           TargetingControl::targetPosition;
CLogicEntity *TargetingControl::targetLogicEntity = NULL;
#endif

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
    if (entities::getents().inrange(enthover))
    {
        dist = -7654; // TODO: Calculate
        entity = LogicSystem::getLogicEntity(*entities::getents()[enthover]);
    } else {
        // Manually check if we are hovering, using ray intersections. TODO: Not needed for extents?
        CLogicEntity *ignore = (fpsent*)targeter ? LogicSystem::getLogicEntity(targeter) : NULL;
        float dynamicDist, staticDist;
        dynent* dynamicEntity;
        extentity* staticEntity;
        TargetingControl::intersectClosestDynamicEntity(from, to, ignore ? ignore->dynamicEntity : NULL, dynamicDist,  dynamicEntity);
        TargetingControl::intersectClosestMapmodel     (from, to,                                        staticDist, staticEntity);

        dist = -1;

        if (dynamicEntity == NULL && staticEntity == NULL)
        {
            dist = -1;
            entity = NULL;
        } else if (dynamicEntity != NULL && staticEntity == NULL)
        {
            dist = dynamicDist;
            entity = LogicSystem::getLogicEntity(dynamicEntity);
        } else if (dynamicEntity == NULL && staticEntity != NULL)
        {
            dist = staticDist;
            entity = LogicSystem::getLogicEntity(*staticEntity);
        } else if (staticDist < dynamicDist)
        {
            dist = staticDist;
            entity = LogicSystem::getLogicEntity(*staticEntity);
        } else {
            dist = dynamicDist;
            entity = LogicSystem::getLogicEntity(dynamicEntity);
        }
    }
}

#ifdef CLIENT
bool useMouseTargeting = false;

void TargetingControl::setMouseTargeting(bool on)
{
    useMouseTargeting = on;
}

VAR(has_mouse_target, 0, 0, 1);

void TargetingControl::determineMouseTarget(bool forceEntityCheck)
{
    targetLogicEntity = NULL;

    TargetingControl::worldPosition = worldpos;

    if (Logging::shouldShow(Logging::INFO))
        particle_splash(0, 50, 100, TargetingControl::worldPosition); // Kripken: Show some sparkles where the mouse points - for debug

    if (!useMouseTargeting && !editmode && !forceEntityCheck)
    {
        TargetingControl::targetLogicEntity = NULL;
        TargetingControl::targetPosition = TargetingControl::worldPosition;
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
            if (!editmode && TargetingControl::targetLogicEntity && !TargetingControl::targetLogicEntity->isNone() &&
                TargetingControl::targetLogicEntity->getUniqueId() == ClientSystem::uniqueId)
            {
                // Try to see if the player was the sole cause of collision - move it away, test, then move it back
                vec save = ClientSystem::playerLogicEntity->dynamicEntity->o;
                ClientSystem::playerLogicEntity->dynamicEntity->o.add(10000.0);

                TargetingControl::intersectClosest(camera1->o,
                                                   worldpos,
                                                   camera1,
                                                   dist,
                                                   TargetingControl::targetLogicEntity);

                ClientSystem::playerLogicEntity->dynamicEntity->o = save;
            }

            has_mouse_target = int(TargetingControl::targetLogicEntity && !TargetingControl::targetLogicEntity->isNone());

            if (has_mouse_target)
            {
                vec temp(worldpos);
                temp.sub(camera1->o);
                temp.normalize();
                temp.mul(dist);
                temp.add(camera1->o);

                TargetingControl::targetPosition = temp;
            } else
                TargetingControl::targetPosition = TargetingControl::worldPosition;

            lastEntityCheck = lastmillis;
        }
    }
}

#endif

float TargetingControl::calculateMovement(physent* entity)
{
    fpsent* fpsEntity = (fpsent*)entity;
    // Take into account movement both by velocity, and of movement since our last frame
    vec movement(fpsEntity->lastPhysicsPosition);
    movement.sub(fpsEntity->o);
    movement.mul(curtime/1024.0f); // Take into account the timeframe
    movement.add(fpsEntity->vel);
    movement.mul(0.5f);
    return movement.magnitude();
}

// Default Sauerbraten physics frame time - 200fps.
#define PHYSFRAMETIME 5
#define MAXFRAMETIME 200 /* 5fps, suitable for really tiny nonmoving entities */

void TargetingControl::calcPhysicsFrames(physent *entity)
{
    // XXX: Note that at 200fps we now see bad movement stutter. Look at the original
    // sauer code in physics.cpp that was the basis for this function to see if perhaps
    // they now do thins differently. To debug this, revert back to sauer's method
    // of NON-per-entity physics and see what that changes.

    fpsent* fpsEntity = (fpsent*)entity;

    Logging::log(Logging::INFO, "physicsframe() lastmillis: %d  curtime: %d  lastphysframe: %d\r\n", lastmillis, curtime, fpsEntity->lastphysframe);

    // If no previous physframe - this is the first time - then don't bother
    // running physics, wait for that first frame. Or else we might run
    // a lot of frames for nothing at this stage (all the way back to time '0')
    if (fpsEntity->lastphysframe == 0)
        fpsEntity->lastphysframe = lastmillis; // Will induce diff=0 for this frame

    int diff = lastmillis - fpsEntity->lastphysframe; // + curtime
    if(diff <= 0) fpsEntity->physsteps = 0;
    else
    {
        int entityFrameTime;

#ifdef SERVER
        entityFrameTime = (calculateMovement(fpsEntity) >= 0.001) ? 15 : 30;
#else
        entityFrameTime = (fpsEntity == player) ? 5 : 10;
#endif
        fpsEntity->physframetime = entityFrameTime; // WAS: clamp((entityFrameTime*gamespeed)/100, 1, entityFrameTime);

        fpsEntity->physsteps = (diff + fpsEntity->physframetime - 1)/fpsEntity->physframetime;
        fpsEntity->lastphysframe += fpsEntity->physsteps * fpsEntity->physframetime;

        fpsEntity->lastPhysicsPosition = fpsEntity->o;
    }

    if (fpsEntity->physsteps * fpsEntity->physframetime > 2000)
    {
        Logging::log(Logging::WARNING, "Trying to run over 2 seconds of physics prediction at once for %d: %d/%d (%d fps) (diff: %d ; %d, %d). Aborting physics for this round.\r\n", fpsEntity->uniqueId, fpsEntity->physframetime, fpsEntity->physsteps, 1000/fpsEntity->physframetime, diff, lastmillis, fpsEntity->lastphysframe - (fpsEntity->physsteps * fpsEntity->physframetime));
        fpsEntity->physsteps = 1; // If we had a ton of physics to run - like, say, after 19 seconds of lightmap calculations -
                                  // then just give up, don't run all that physics, do just one frame. Back to normal next time, after all.
    }

    Logging::log(Logging::INFO, "physicsframe() Decided on physframetime/physsteps: %d/%d (%d fps) (diff: %d)\r\n", fpsEntity->physframetime, fpsEntity->physsteps, 1000/fpsEntity->physframetime, diff);
}

