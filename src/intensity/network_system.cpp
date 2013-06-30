
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "network_system.h"
#include "of_tools.h"

namespace game
{
    void updatepos(fpsent *d);
    extern int smoothmove, smoothdist;
}

namespace NetworkSystem
{

//==================
// PositionUpdater
//==================

namespace PositionUpdater
{

int QuantizedInfo::getLifeSequence()
{
    return (misc >> 3) & 1;
}

void QuantizedInfo::generateFrom(fpsent *d)
{
    clientNumber = d->clientnum; // Kripken: Changed player1 to d, so this will work for NPCs as well

    position.x = (int)(d->o.x*DMF);              // quantize coordinates to 1/4th of a cube, between 1 and 3 bytes
    position.y = (int)(d->o.y*DMF);
    position.z = (int)(d->o.z*DMF);

    d->normalize_yaw(180.0f); // Kripken: Normalize to 0-360
    yaw = (unsigned char)(256.0f * (d->yaw + 180.0f) / 360.0f); // Kripken: Send quantized to 256 values, 1 byte

    d->normalize_pitch(0.0f); // Kripken: Normalize to -180-180
    pitch = (unsigned char)(256.0f * (d->pitch + 180.0f) / 360.0f); // Kripken: Send quantized to 256 values, 1 byte

    d->normalize_roll(0.0f); // Kripken: Normalize to -180-180
    roll = (unsigned char)(256.0f * (d->roll + 180.0f) / 360.0f); // Kripken: Send quantized to 256 values, 1 byte

    velocity.x = (int)(d->vel.x*DVELF);          // quantize to itself, almost always 1 byte
    velocity.y = (int)(d->vel.y*DVELF);
    velocity.z = (int)(d->vel.z*DVELF);

    falling.x = (int)(d->falling.x*DVELF);      // quantize to itself, almost always 1 byte
    falling.y = (int)(d->falling.y*DVELF);
    falling.z = (int)(d->falling.z*DVELF); // XXX: hasFalling is done the old Sauer way, not the new way
    hasFalling = (falling.x || falling.y || falling.z); // XXX: hasFalling is done the old Sauer way, not the new way

    assert(d->physstate < 8);

    misc = 0;
    misc |= d->physstate;
    misc |= (d->lifesequence << 3);
    misc |= ((d->move + 1) << 4);
    misc |= ((d->strafe + 1) << 6);

    mapDefinedPositionData = d->mapDefinedPositionData;

    crouching = d->crouching < 0;
}

void QuantizedInfo::generateFrom(ucharbuf& p)
{
    clientNumber = getint(p);// printf("START GET: %d\r\n", clientNumber);

    // Indicates which fields are in fact present (the has[X] stuff)
    unsigned int indicator = getuint(p);// printf("GET: %u\r\n", indicator); 
////////////////////////////////////printf("generateFrom: %d (%d,%d,%d,%d,%d,%d,%d,%d)\r\n", indicator, hasPosition, hasYaw, hasPitch, hasRoll, hasVelocity, hasFallingXY, hasFallingZ, hasMisc);
    hasPosition = (indicator & 1) != 0;
    hasYaw = (indicator & 2) != 0;
    hasPitch = (indicator & 4) != 0;
    hasRoll = (indicator & 8) != 0;
    hasVelocity = (indicator & 16) != 0; 
    hasFalling = (indicator & 32) != 0;
    hasMisc = (indicator & 64) != 0;
    crouching = (indicator & 128) != 0;
    hasMapDefinedPositionData = (indicator & 256) != 0;

    if (hasPosition)
    {
        position.x = getuint(p);// printf("GET: %d\r\n", position.x);
        position.y = getuint(p);// printf("GET: %d\r\n", position.y);
        position.z = getuint(p);// printf("GET: %d\r\n", position.z);
    }

    if (hasYaw)
    {
        yaw = p.get();// printf("GET: %u\r\n", yaw);
    }

    if (hasPitch)
    {
        pitch = p.get();// printf("GET: %u\r\n", pitch);
    }

    if (hasRoll)
    {
        roll = p.get();// printf("GET: %u\r\n", roll);
    }

    if (hasVelocity)
    {
        velocity.x = getint(p);// printf("GET: %d\r\n", velocity.x);
        velocity.y = getint(p);// printf("GET: %d\r\n", velocity.y);
        velocity.z = getint(p);// printf("GET: %d\r\n", velocity.z);
    }

    if (hasFalling)
    {
        falling.x = getint(p);// printf("GET: %d\r\n", falling.x);
        falling.y = getint(p);// printf("GET: %d\r\n", falling.y);
        falling.z = getint(p);// printf("GET: %d\r\n", falling.z);
    } else {
        // XXX: hasFalling is done the old Sauer way, not the new way
        falling.x = 0;
        falling.y = 0;
        falling.z = 0;
    }

    if (hasMisc)
    {
        misc = p.get();// printf("GET: %u\r\n", misc);
    }

    if (hasMapDefinedPositionData)
    {
        mapDefinedPositionData = getuint(p);
    }
}

void QuantizedInfo::applyToEntity(fpsent *d)
{
    if (!d) d = game::getclient(clientNumber);
//        fpsent *d = cl.getclient(cn);

    // Only possibly discard if we get a value for the lifesequence
    if(!d || (hasMisc && (getLifeSequence()!=(d->lifesequence&1))))
    {
        logger::log(logger::WARNING, "Not applying position update for client %d, reasons: %p,%d,%d (real:%d)\r\n",
                     clientNumber, (void*)d, getLifeSequence(), d ? d->lifesequence&1 : -1, d ? d->lifesequence : -1);
        return;
    } else
        logger::log(logger::INFO, "Applying position update for client %d\r\n", clientNumber);

    #ifdef SERVER
    if(d->serverControlled) // Server does not need to update positions of its own NPCs. TODO: Don't even send to here.
    {
        logger::log(logger::INFO, "Not applying position update for server NPC: (uid: %d , addr %d):\r\n", d->uid, d != NULL);
        return;
    }
    #endif

    #ifndef SERVER
    float oldyaw = d->yaw, oldpitch = d->pitch;
    #endif

    if (hasYaw)
    {
        d->yaw = (360.0f * float(yaw) / 256.0f) - 180.0f; // Kripken: Unquantize from 256 values
        d->normalize_yaw(180.0f); // Kripken: Normalize to 0-360
    }

    if (hasPitch)
    {
        d->pitch = (360.0f * float(pitch) / 256.0f) - 180.0f; // Kripken: Unquantize from 256 values
        d->normalize_pitch(0.0f); // Kripken: Normalize to -180-180
    }

    if (hasRoll)
    {
        d->roll = (360.0f * float(roll) / 256.0f) - 180.0f; // Kripken: Unquantize from 256 values
        d->normalize_roll(0.0f); // Kripken: Normalize to -180-180
    }

    if (hasMisc)
    {
        d->lifesequence = getLifeSequence();
        d->move = ((misc >> 4) & 3) - 1;
        d->strafe = ((misc >> 6) & 3) - 1;
    }

    d->crouching = crouching ? -1 : abs(d->crouching);

    if (hasMapDefinedPositionData)
    {
        d->mapDefinedPositionData = mapDefinedPositionData;
    }

#ifndef SERVER
    vec oldpos(d->o);
#endif

    if(game::allowmove(d))
    {
        if (hasPosition)
            d->o = vec(position.x/DMF, position.y/DMF, position.z/DMF);
        if (hasVelocity)
            d->vel = vec(velocity.x/DVELF, velocity.y/DVELF, velocity.z/DVELF);
        if (hasFalling)
        {
            d->falling.x = falling.x/DVELF;
            d->falling.y = falling.y/DVELF;
            d->falling.z = falling.z/DVELF;
        } else {
            d->falling.x = 0;
            d->falling.y = 0;
            d->falling.z = 0;
        }
        if (hasMisc)
            d->physstate = misc & 7;

        updatephysstate(d);
        game::updatepos(d);
    }
    #ifndef SERVER // No need to smooth for server, and certainly no need to double smooth before getting to other clients
    if(game::smoothmove && d->smoothmillis>=0 && oldpos.dist(d->o) < game::smoothdist)
    {
        d->newpos = d->o;
        d->newyaw = d->yaw;
        d->newpitch = d->pitch;
        d->o = oldpos;
        d->yaw = oldyaw;
        d->pitch = oldpitch;
        (d->deltapos = oldpos).sub(d->newpos);
        d->deltayaw = oldyaw - d->newyaw;
        if(d->deltayaw > 180) d->deltayaw -= 360;
        else if(d->deltayaw < -180) d->deltayaw += 360;
        d->deltapitch = oldpitch - d->newpitch;
        d->smoothmillis = lastmillis;
    }
    else
    #endif
        d->smoothmillis = 0;

    if(d->state==CS_LAGGED || d->state==CS_SPAWNING) d->state = CS_ALIVE;
}

void QuantizedInfo::applyToBuffer(ucharbuf& q)
{
    putint(q, N_POS);// printf("(PUT N_POS): %d\r\n", N_POS);

    putint(q, clientNumber);// printf("START PUT: %d\r\n", clientNumber);

    unsigned int indicator = 0; // Indicates which fields are in fact present (the has[X] stuff)
    indicator |= hasPosition;
    indicator |= (hasYaw << 1);
    indicator |= (hasPitch << 2);
    indicator |= (hasRoll << 3);
    indicator |= (hasVelocity << 4);
    indicator |= (hasFalling << 5);
    indicator |= (hasMisc << 6);
    indicator |= (crouching << 7);
    indicator |= (hasMapDefinedPositionData << 8);
///////////////////////////////printf("applyToBuffer: %d (%d,%d,%d,%d,%d,%d,%d,%d)\r\n", indicator, hasPosition, hasYaw, hasPitch, hasRoll, hasVelocity, hasFallingXY, hasFallingZ, hasMisc);
    putuint(q, indicator);// printf("PUT: %u\r\n", indicator);

    if (hasPosition)
    {
        putuint(q, position.x);// printf("PUT: %d\r\n", position.x);
        putuint(q, position.y);// printf("PUT: %d\r\n", position.y);
        putuint(q, position.z);// printf("PUT: %d\r\n", position.z);
    }

    if (hasYaw)
    {
        q.put(yaw);// printf("PUT: %u\r\n", yaw);
    }

    if (hasPitch)
    {
        q.put(pitch);// printf("PUT: %u\r\n", pitch);
    }

    if (hasRoll)
    {
        q.put(roll);// printf("PUT: %u\r\n", roll);
    }

    if (hasVelocity)
    {
        putint(q, velocity.x);// printf("PUT: %d\r\n", velocity.x);
        putint(q, velocity.y);// printf("PUT: %d\r\n", velocity.y);
        putint(q, velocity.z);// printf("PUT: %d\r\n", velocity.z);
    }

    if (hasFalling)
    {
        putint(q, falling.x);// printf("PUT: %d\r\n", falling.x);
        putint(q, falling.y);// printf("PUT: %d\r\n", falling.y);
        putint(q, falling.z);// printf("PUT: %d\r\n", falling.z);
    }

    if (hasMisc)
    {
        q.put(misc);// printf("PUT: %u\r\n", misc);
    }

    if (hasMapDefinedPositionData)
    {
        putuint(q, mapDefinedPositionData);
    }
///////////////////////printf("***Generated size: %d\r\n", q.length());
}


//======================================
// Bandwidth optimization system for
// position updates
//======================================


//! How fast we would like to send, assuming that we are talking about
//! sending a value that has not changed. Right after a change, we still send
//! at the normal rate (clients might miss some updates), but later on we
//! gradually lower that rate (since with high probability they have already
//! received it).
//! @param sinceChanged The time since there was a change to this value
//! @param receiveLatency The average latency of receiving from this
//!                       client, which is an estimate of the 'full speed'
//!                       that would be used for a constantly-changing
//!                       value.
int calcDesiredLatency(int sinceChanged, int receiveLatency)
{
    // At this time we will decay to our slowest rate (secs)
    float maxTime = 2.0f;
    // How much weight to give the slowest possible rate
    float slowestFactor = min((float(sinceChanged)/1000.0f)/maxTime, 1.0f);
    // At least 3fps, but generally about 1/10 normal speed
    // (if normal = 30fps, then that is 3fps).
    int slowestLatency = min(receiveLatency*10, 333); 

    return int( (slowestLatency*slowestFactor) + (receiveLatency*(1-slowestFactor)) );
}

//! Decide whether to send an update about a datum, or not
//! @param sameValue Whether this value has changed or not
//! @param sinceSend The amount of time since we sent an update about this value
//! @param receiveLatencyRaw The latency in receiving updates for this client.
//!                          If latency is high we are more conservative about
//!                          our decisions, so as not to make things worse. This
//!                          is the 'raw' estimate - our best guess.
//! @param receiveLatencySafe This is a 'safe' version, taking into account some
//!                           variance.
//! @param sinceChanged The amount of time since this value has changed
//! @return Whether the decision is to send this value
bool positionDatumDecider(bool sameValue, int sinceSend, int receiveLatencyRaw, int receiveLatencySafe, int sinceChanged)
{
//////////////////////////printf("DECIDER: same: %d  last: %d   raw: %d    safe: %d      sinceChange: %d\r\n",        sameValue, sinceSend, receiveLatencyRaw, receiveLatencySafe, sinceChanged);

    if (sinceSend == -1)
        return true; // No previously sent value, so decide to send

    if (!sameValue)
        return true; // For now, always send different values

    // This is the same value as we last sent, possibly decide to not sent it.

    // How much time passed since we last sent
    int currLatency = sinceSend;
    // How much time we estimate will pass until the next sending opportunity.
    // Use a conservative 'safe' estimate of latency.
    int estimatedFutureLatency = receiveLatencySafe;
    // The latency we are shooting for. Use 'raw' best-guess estimate of latency.
    int desiredLatency = calcDesiredLatency(sinceChanged, receiveLatencyRaw);

//////////////////////////printf("Decider: curr, future: %d, %d     desired: %d       hence: %d\r\n", currLatency, estimatedFutureLatency, desiredLatency,       (currLatency + estimatedFutureLatency >= desiredLatency)    );

    // If the overall latency between messages will be as we want, or more, send now
    return (currLatency + estimatedFutureLatency >= desiredLatency);
}

}

}

