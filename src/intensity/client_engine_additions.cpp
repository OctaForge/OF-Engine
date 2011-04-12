
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "client_engine_additions.h"
#include "targeting.h"
#include "message_system.h"

using namespace lua;

//=========================
// Camera stuff
//=========================

#define MIN_CAMERA_MOVE_ITERS 8

void CameraControl::incrementCameraDist(int inc_dir)
{
    Logging::log(Logging::DEBUG, "changing camera increment: %d\r\n", inc_dir);

    SETV(cam_dist, GETIV(cam_dist) + (inc_dir * GETIV(cameraMoveDist)));

    if (engine.hashandle()) engine.getg("cc").t_getraw("global").t_set("cam_dist", GETIV(cam_dist)).pop(2);
}

int saved_cam_dist; // Saved from before characterviewing, restored right after

void CameraControl::prepareCharacterViewing()
{
    player->pitch  = 0;
    camera1->pitch = 0;
    camera1->yaw   = camera1->yaw;

    saved_cam_dist = GETIV(cam_dist);
    SETV(cam_dist, MIN_CAMERA_MOVE_ITERS*3);
}

void CameraControl::stopCharacterViewing()
{
    SETV(cam_dist, saved_cam_dist);
}

physent forcedCamera;
bool useForcedCamera = false;
float forcedCameraFov = -1;
int savedThirdperson = -1;

bool useForcedPosition = false;
bool useForcedYaw = false;
bool useForcedPitch = false;
bool useForcedRoll = false;

void CameraControl::forcePosition(vec& position)
{
    useForcedPosition = true;
    forcedCamera.o = position;

    // If we just switched to forced camera mode, save thirdperson state and go to third person
    // (We need third person so that we show the player's avatar as the camera moves. There is
    // currently no support for forcing the camera in first person mode, which would be tricky to do.)
    if (!GETIV(thirdperson) && savedThirdperson == -1)
    {
        savedThirdperson = GETIV(thirdperson);
        SETV(thirdperson, 1);
    }
}

void CameraControl::forceYaw(float yaw)
{
    useForcedYaw = true;
    forcedCamera.yaw = yaw;
    if (!GETIV(thirdperson) && savedThirdperson == -1)
    {
        savedThirdperson = GETIV(thirdperson);
        SETV(thirdperson, 1);
    }
}

void CameraControl::forcePitch(float pitch)
{
    useForcedPitch = true;
    forcedCamera.pitch = pitch;
    if (!GETIV(thirdperson) && savedThirdperson == -1)
    {
        savedThirdperson = GETIV(thirdperson);
        SETV(thirdperson, 1);
    }
}

void CameraControl::forceRoll(float roll)
{
    useForcedRoll = true;
    forcedCamera.roll = roll;
    if (!GETIV(thirdperson) && savedThirdperson == -1)
    {
        savedThirdperson = GETIV(thirdperson);
        SETV(thirdperson, 1);
    }
}

void CameraControl::forceFov(float fov)
{
    forcedCameraFov = fov;
    if (!GETIV(thirdperson) && savedThirdperson == -1)
    {
        savedThirdperson = GETIV(thirdperson);
        SETV(thirdperson, 1);
    }
}

void CameraControl::forceCamera(vec& position, float yaw, float pitch, float roll, float fov)
{
    useForcedCamera = true;
    CameraControl::forcePosition(position);
    CameraControl::forceYaw(yaw);
    CameraControl::forcePitch(pitch);
    CameraControl::forceRoll(roll);
    CameraControl::forceFov(fov);
}

physent* CameraControl::getCamera()
{
    return camera1;
}

void CameraControl::positionCamera(physent* camera1)
{
    Logging::log(Logging::INFO, "CameraControl::positionCamera\r\n");
    INDENT_LOG(Logging::INFO);

    if (useForcedCamera || useForcedPosition || useForcedYaw || useForcedPitch || useForcedRoll)
    {
        if (useForcedPosition) { camera1->o = forcedCamera.o; useForcedPosition = false; };
        if (useForcedYaw) { camera1->yaw = forcedCamera.yaw; useForcedYaw = false; };
        if (useForcedPitch) { camera1->pitch = forcedCamera.pitch; useForcedPitch = false; };
        if (useForcedRoll) { camera1->roll = forcedCamera.roll; useForcedRoll = false; };

        if (useForcedCamera)
        {
            useForcedCamera = false; // Prepare for next frame
            return;
        }
    }

    // Sync camera height to scripts, if necessary
    static double lastCameraHeight = -1;
    if (engine.hashandle() && lastCameraHeight != GETFV(cameraheight))
    {
        lastCameraHeight = GETFV(cameraheight);
        engine.getg("cc").t_getraw("global").t_set("cameraheight", GETFV(cameraheight)).pop(2);
    }

    // If we just left forced camera mode, restore thirdperson state
    if (savedThirdperson != -1)
    {
        SETV(thirdperson, savedThirdperson);
        savedThirdperson = -1;
    }

    float saved_camera_speed = camera1->maxspeed; // Kripken: need to save this, because camera1 =?= player1
    camera1->maxspeed = 50; // This speed determines the distance of the camera, so the Sauer way of tying it to the 
                            // player's speed is not completely general

    vec dir;
    vecfromyawpitch(camera1->yaw, camera1->pitch, -1, 0, dir);

    if (GuiControl::isCharacterViewing())
        camera1->o = player->o; // Start from player

    if(game::collidecamera()) 
    {
        vec cameraOrigin = camera1->o;
        if (GETIV(thirdperson))
        {
            vec up(0, 0, 1);
            movecamera(camera1, up, GETFV(cameraheight), 1);
            movecamera(camera1, up, clamp(GETFV(cameraheight) - camera1->o.dist(cameraOrigin), 0.0f, 1.0f), 0.1f); // Find distance to obstacle
        }

        vec cameraOrigin2 = camera1->o;
        movecamera(camera1, dir, GETIV(cam_dist), 1);
        movecamera(camera1, dir, clamp(GETIV(cam_dist) - camera1->o.dist(cameraOrigin2), 0.0f, 1.0f), 0.1f); // Find distance to obstacle

        if (GETFV(smoothcamera)) {
            float intendedDist = camera1->o.dist(cameraOrigin2)*(1.0f-GETFV(cameraavoid));
            static float lastDist = 5;
            float ACTUAL_DISTANCE_FACTOR = clamp(1.0f - (curtime/1000.0f)/GETFV(smoothcamera), 0.0f, 1.0f);
            float actualDist = ACTUAL_DISTANCE_FACTOR*lastDist + (1-ACTUAL_DISTANCE_FACTOR)*intendedDist;

            // Start again, move to current distance
            camera1->o = cameraOrigin2;
            movecamera(camera1, dir, actualDist, 1);
            movecamera(camera1, dir, clamp(actualDist - camera1->o.dist(cameraOrigin2), 0.0f, 1.0f), 0.1f);
            lastDist = actualDist;
        }
    } else {
        camera1->o.z += GETFV(cameraheight);
        camera1->o.add(vec(dir).mul(GETIV(cam_dist)));
    }

    camera1->maxspeed = saved_camera_speed;

    // Kripken: Smooth camera movement: We interpolate our the new calculated position with the old one, smoothly

    static fpsent actualCamera; // Need fpsent for new normalization functions
    static vec lastPlayerPosition;

    vec temp(actualCamera.o);
    temp.sub(camera1->o);

    actualCamera.normalize_yaw(camera1->yaw);
    actualCamera.normalize_pitch(camera1->pitch);

    float yawDelta = camera1->yaw - actualCamera.yaw;
    float pitchDelta = camera1->pitch - actualCamera.pitch;

    // Only interpolate if we are fairly close, otherwise this might be a new map, or we teleported, etc.
    if (GETFV(smoothcamera) && !GuiControl::isMouselooking() && temp.magnitude() < 50*player->radius && fabs(yawDelta) < 30.0f && fabs(pitchDelta) < 30.0f)
    {
        float ACTUAL_CAMERA_FACTOR = clamp(1.0f - (curtime/1000.0f)/GETFV(smoothcamera), 0.0f, 1.0f);

        vec temp = player->o;
        temp.sub(lastPlayerPosition);
        actualCamera.o.add(temp); // Prevent camera stutter

        actualCamera.o.mul(ACTUAL_CAMERA_FACTOR);
        temp = camera1->o;
        temp.mul(1-ACTUAL_CAMERA_FACTOR);
        actualCamera.o.add(temp);

        actualCamera.yaw = ACTUAL_CAMERA_FACTOR*actualCamera.yaw + (1-ACTUAL_CAMERA_FACTOR)*camera1->yaw;
        actualCamera.pitch = ACTUAL_CAMERA_FACTOR*actualCamera.pitch + (1-ACTUAL_CAMERA_FACTOR)*camera1->pitch;

        camera1->o = actualCamera.o;
        camera1->yaw = actualCamera.yaw;
        camera1->pitch = actualCamera.pitch;

//        camera1->o.z += player->aboveeye + player->eyeheight;

    } else {
        actualCamera.o = camera1->o;
        actualCamera.yaw = camera1->yaw;
        actualCamera.pitch = camera1->pitch;
    }

    lastPlayerPosition = player->o;
}


//=========================
// GUI stuff
//=========================

bool _isMouselooking = true; // Default like sauer

bool GuiControl::isMouselooking()
    { return _isMouselooking; };


void GuiControl::toggleMouselook()
{
    if (_isMouselooking)
    {
        _isMouselooking = false;

        // Restore cursor to center
        g3d_resetcursor();
    } else {
        _isMouselooking = true;
    };
};

bool _isCharacterViewing = false;

bool GuiControl::isCharacterViewing()
    { return _isCharacterViewing; };

void GuiControl::toggleCharacterViewing()
{
    if (!_isCharacterViewing)
        CameraControl::prepareCharacterViewing();
    else
        CameraControl::stopCharacterViewing();

    _isCharacterViewing = !_isCharacterViewing;
}

void GuiControl::menuKeyClickTrigger()
{
    playsound(S_MENUCLICK);
}

// Editing GUI statics
LogicEntityPtr GuiControl::EditedEntity::currEntity;
GuiControl::EditedEntity::StateDataMap GuiControl::EditedEntity::stateData;
std::vector<std::string> GuiControl::EditedEntity::sortedKeys;

// Player movements control - keyboard stuff

void PlayerControl::handleExtraPlayerMovements(int millis)
{
    float delta = float(millis)/1000.0f;

    physent *mover;
//    if (GuiControl::isCharacterViewing()) // Buggy. Commenting this out gives a good enough result, actually:
//                                          // keys move *player*, and do mouseMove mode if you want to use the mouse to look around
//        mover = camera1;
//    else
        mover = player;

    // Turn if mouse is at borders

    float x, y;
    g3d_cursorpos(x, y);
    if (g3d_windowhit(true, false)) x = y = 0.5; // Do not scroll with mouse

    // Turning

    fpsent* fpsPlayer = dynamic_cast<fpsent*>(player);

    engine.getref(ClientSystem::playerLogicEntity.get()->luaRef);
    float _facingSpeed = engine.t_get<double>("facing_speed");

    if (fpsPlayer->turn_move || fabs(x - 0.5) > 0.45)
        mover->yaw += _facingSpeed * (
                fpsPlayer->turn_move ? fpsPlayer->turn_move : (x > 0.5 ? 1 : -1)
            ) * delta;

    if (fpsPlayer->look_updown_move || fabs(y - 0.5) > 0.45)
        mover->pitch += _facingSpeed * (
                fpsPlayer->look_updown_move ? fpsPlayer->look_updown_move : (y > 0.5 ? -1 : 1)
            ) * delta;

    engine.pop(1);

    extern void fixcamerarange();
    fixcamerarange(); // Normalize and limit the yaw and pitch values to appropriate ranges
}

bool PlayerControl::handleKeypress(SDLKey sym, int unicode, bool isdown)
{
    assert(0);
    return false;
}

bool PlayerControl::handleClick(int button, bool up)
{
    assert(0);
    return false;
}

void PlayerControl::flushActions()
{
    engine.getref(ClientSystem::playerLogicEntity.get()->luaRef);
    engine.t_getraw("action_system");
    engine.t_getraw("clear").push_index(-2).call(1, 0).pop(2);
}

void PlayerControl::toggleMainMenu()
{
    assert(0);
}


//==============================
// Light Control
//==============================

namespace LightControl
{

void addHoverLight()
{
    if (GuiControl::isMouselooking())
        return; // We don't need to mark anything if we are mouselooking. There is no cursor anyhow.

    vec color;

    if (!TargetingControl::targetLogicEntity.get())
    {
        Logging::log(Logging::WARNING, "targetLogicEntity is NULL\r\n");
        return;
    }

    switch (TargetingControl::targetLogicEntity.get()->getType())
    {
        case CLogicEntity::LE_DYNAMIC: color = vec(0.25f, 1.0f, 0.25f);  break;
        case CLogicEntity::LE_STATIC:  color = vec(0.25f, 0.25f, 1.0f);  break;
        case CLogicEntity::LE_NONE:    color = vec(1.0f, 1.0f, 0.5f);
    }

    vec   location;
    float radius;
    bool  needDecal;

    if (!TargetingControl::targetLogicEntity.get()->isNone())
    {    
        location = TargetingControl::targetLogicEntity.get()->getOrigin();
        radius   = TargetingControl::targetLogicEntity.get()->getRadius();
        needDecal = true;
    } else {
        location  = TargetingControl::worldPosition;
        radius    = 0; // 3
        needDecal = false;
    }

    // Add some light to mark the mouse - probably a bad idea for production though though TODO: Consider
    adddynlight(location, radius*2, color);

    if (needDecal)
    {
        // Calculate floor position, and draw a decal there
        vec floorNorm;
        float floorDist = rayfloor(location, floorNorm);
        adddecal(DECAL_CIRCLE, location.sub(vec(0,0,floorDist)), floorNorm, radius);
    }
}

// Queued dynamic lights - to be added for the next frame.
// We should really just create dynamic lights only during the
// weapon::addynlights() code, but this makes writing scripts
// somewhat messier. This approach might lead to lag of 1 frame,
// so livable for now.
struct queuedDynamicLight
{
    vec o;
    float radius;
    vec color;
    int fade, peak, flags;
    float initradius;
    vec initcolor;
    physent *owner;
};

std::vector<queuedDynamicLight> queuedDynamicLights;

void queueDynamicLight(const vec &o, float radius, const vec &color, int fade, int peak, int flags, float initradius, const vec &initcolor, physent *owner)
{
    queuedDynamicLight q;
    q.o = o;
    q.radius = radius;
    q.color = color;
    q.fade = fade;
    q.peak = peak;
    q.flags = flags;
    q.initradius = initradius;
    q.initcolor = initcolor;
    q.owner = owner;
    queuedDynamicLights.push_back(q);
}

void showQueuedDynamicLights()
{
    for (unsigned int i = 0; i < queuedDynamicLights.size(); i++)
    {
        queuedDynamicLight& q = queuedDynamicLights[i];
        adddynlight(q.o, q.radius, q.color, q.fade, q.peak, q.flags, q.initradius, q.initcolor, q.owner);
    }

    queuedDynamicLights.clear();
}

}

// Additional Rendering

std::vector<extentity*> ExtraRendering::currShadowingMapmodels;

void ExtraRendering::renderShadowingMapmodels()
{
    assert(0);
#if 0
    loopstdv(currShadowingMapmodels)
    {
        extentity *mapmodel = currShadowingMapmodels[i];
        model *theModel = LogicSystem::getLogicEntity(*mapmodel).get()->getModel();
        if(!theModel) continue;
        const char *mdlname = theModel->name(); //mapmodelname(mapmodel->attr2);

        int flags = MDL_LIGHT | MDL_CULL_VFC | MDL_CULL_DIST | MDL_CULL_OCCLUDED;

        if (theModel->translucent)
            flags |= MDL_TRANSLUCENT;
        else
            flags |= MDL_SHADOW; // flags |= MDL_DYNSHADOW; ?

        rendermodel(NULL,
                    mdlname,
                    ANIM_MAPMODEL | ANIM_LOOP, // FIXME: Shadowing mapmodels aren't generally per-frame calculated, but who knows,fix this
                    mapmodel->o,
                    LogicSystem::getLogicEntity(*mapmodel),
                    mapmodel->attr1,
                    0,
                    flags);
    }
#endif
}
