#ifndef __TARGETING_H__
#define __TARGETING_H__

// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

//! Manages relating mouse positions, world positions, and logic entities

struct TargetingControl
{
#ifndef STANDALONE
    //! Contains the position where the mouse cursor is aiming. Equal to worldposition in general, unless hovering
    //! on an entity
    static vec targetPosition;

    //! Contains the latest and current information about what logic entity the mouse cursor is hovering over
    static CLogicEntity *targetLogicEntity;
#endif

    //! Utility that wraps around sauer's complex system for intersecting a ray (from->to) with a dynamic entity
    static void intersectClosestDynamicEntity(vec &from, vec &to, physent *targeter, float &dist, dynent*& target);

    //! Utility that wraps around sauer's complex system for intersecting a ray (from->to) with a mapmodel
    static void intersectClosestMapmodel(vec &from, vec &to, float& dist, extentity*& target);

    //! Find the logic entity that the ray from->to intersects, and is not 'targeter' (the entity casting the ray, typically)
    static void intersectClosest(vec &from, vec &to, physent *targeter, float& dist, CLogicEntity *&entity);

#ifndef STANDALONE
    //! Sets or unsets the state of letting the mouse 'target' entities, i.e., mark them
    //! in a visual manner and let clicking affect that entity
    static void setMouseTargeting(bool on);

    //! Called per-frame, sets worldPosition and targetLogicEntity to their appropriate values
    //! @param forceEntityCheck Set to true to find target entities even if default mouse targeting (hover targeting) is off
    static void determineMouseTarget(bool forceEntityCheck=false);
#endif
};

#endif
