
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

VAR(cammovedist, 5, 10, 200); // Distance camera moves per iteration
VAR(cam_dist, 0, 50, 200); // How much higher than the player to set the camera

void CameraControl::incrementCameraDist(int inc_dir)
{
    logger::log(logger::DEBUG, "changing camera increment: %d\r\n", inc_dir);
    cam_dist += inc_dir * cammovedist;
}

int saved_cam_dist; // Saved from before characterviewing, restored right after

void CameraControl::prepareCharacterViewing()
{
    player->pitch  = 0;
    camera1->pitch = 0;
    camera1->yaw   = camera1->yaw;

    saved_cam_dist = cam_dist;
    cam_dist = MIN_CAMERA_MOVE_ITERS*3;
}

void CameraControl::stopCharacterViewing()
{
    cam_dist = saved_cam_dist;
}

FVARP(cameraheight, 0, 10, 50); // How much higher than the player to set the camera
FVAR(smoothcamera, 0, 0.2, 100.0); // Smoothing factor for the smooth camera. 0 means no smoothing
FVARP(cameraavoid, 0, 0.33, 1); // 1 means the camera is 100% away from the closest obstacle (and therefore on the player). 0 means it is on that obstacle. 0.5 means it is midway between them.

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
    if (!thirdperson && savedThirdperson == -1)
    {
        savedThirdperson = thirdperson;
        SETV(thirdperson, 1);
    }
}

void CameraControl::forceYaw(float yaw)
{
    useForcedYaw = true;
    forcedCamera.yaw = yaw;
    if (!thirdperson && savedThirdperson == -1)
    {
        savedThirdperson = thirdperson;
        SETV(thirdperson, 1);
    }
}

void CameraControl::forcePitch(float pitch)
{
    useForcedPitch = true;
    forcedCamera.pitch = pitch;
    if (!thirdperson && savedThirdperson == -1)
    {
        savedThirdperson = thirdperson;
        SETV(thirdperson, 1);
    }
}

void CameraControl::forceRoll(float roll)
{
    useForcedRoll = true;
    forcedCamera.roll = roll;
    if (!thirdperson && savedThirdperson == -1)
    {
        savedThirdperson = thirdperson;
        SETV(thirdperson, 1);
    }
}

void CameraControl::forceFov(float fov)
{
    forcedCameraFov = fov;
    if (!thirdperson && savedThirdperson == -1)
    {
        savedThirdperson = thirdperson;
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
    logger::log(logger::INFO, "CameraControl::positionCamera\r\n");
    INDENT_LOG(logger::INFO);

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
    if (engine.hashandle() && lastCameraHeight != cameraheight) lastCameraHeight = cameraheight;

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
        if (thirdperson)
        {
            vec up(0, 0, 1);
            movecamera(camera1, up, cameraheight, 1);
            movecamera(camera1, up, clamp(cameraheight - camera1->o.dist(cameraOrigin), 0.0f, 1.0f), 0.1f); // Find distance to obstacle
        }

        vec cameraOrigin2 = camera1->o;
        movecamera(camera1, dir, cam_dist, 1);
        movecamera(camera1, dir, clamp(cam_dist - camera1->o.dist(cameraOrigin2), 0.0f, 1.0f), 0.1f); // Find distance to obstacle

        if (smoothcamera) {
            float intendedDist = camera1->o.dist(cameraOrigin2)*(1.0f-cameraavoid);
            static float lastDist = 5;
            float ACTUAL_DISTANCE_FACTOR = clamp(1.0f - (curtime/1000.0f)/smoothcamera, 0.0f, 1.0f);
            float actualDist = ACTUAL_DISTANCE_FACTOR*lastDist + (1-ACTUAL_DISTANCE_FACTOR)*intendedDist;

            // Start again, move to current distance
            camera1->o = cameraOrigin2;
            movecamera(camera1, dir, actualDist, 1);
            movecamera(camera1, dir, clamp(actualDist - camera1->o.dist(cameraOrigin2), 0.0f, 1.0f), 0.1f);
            lastDist = actualDist;
        }
    } else {
        camera1->o.z += cameraheight;
        camera1->o.add(vec(dir).mul(cam_dist));
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
    if (smoothcamera && !GuiControl::isMouselooking() && temp.magnitude() < 50*player->radius && fabs(yawDelta) < 30.0f && fabs(pitchDelta) < 30.0f)
    {
        float ACTUAL_CAMERA_FACTOR = clamp(1.0f - (curtime/1000.0f)/smoothcamera, 0.0f, 1.0f);

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
        _isMouselooking = false;
    else
        _isMouselooking = true;

    gui::resetcursor();
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
