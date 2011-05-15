
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include <vector>
#include <map>

// 'Sauer-C'-style looping
#define loopstdv(vec) for (unsigned int i = 0; i < vec.size(); i++)

// XXX This should always be higher than the values in iengine for other DECALS_ - check when sauer is updated!
#define DECAL_CIRCLE 3

// Camera stuff

extern void inc_camera();
extern void dec_camera();

//! Utilities for control of the camera

struct CameraControl
{
    //! How much the camera moves per iteration, as per sauer's system. Each frame, the camera is moved so-and-so iterations
    //! to be behind the PC, but only until it hits a wall
    static int cameraMoveIters; //! How many iterations are used by the camera, each of cammovedist size

    // Increments or decrements the distance of the camera from the PC (to zoom in or out on the PC)
    static void incrementCameraDist(int inc_dir);

    //! During character viewing, the camera spins around the PC, who starts by looking directly at us,
    //! and movement is not allowed. Useful for appearance changing,
    //! character creation, etc.
    static void prepareCharacterViewing();
    static void stopCharacterViewing();

    //! Forces the camera position / yaw / pitch / roll / fov for the next frame
    static void forceCamera(vec& position, float yaw, float pitch, float roll, float fov);
    static void forcePosition(vec& position);
    static void forceYaw(float yaw);
    static void forcePitch(float pitch);
    static void forceRoll(float roll);
    static void forceFov(float fov);

    //! Return the current camera
    static physent* getCamera();

    //! Allow for smooth camera movement, etc.
    static void positionCamera(physent* camera1);
};


//! GUI control utilities. Possibly worth merging into CameraControl

struct GuiControl
{
    //! When mouselooking, the mouse controls orientation as in an FPS
    static void toggleMouselook();
    static bool isMouselooking();

    //! See CameraControl
    static bool isCharacterViewing();
    static void toggleCharacterViewing();

    //! Key clicks
    static void menuKeyClickTrigger();

    // LogicEntity editing GUI
    struct EditedEntity
    {
        static CLogicEntity *currEntity;
        typedef std::map< std::string, std::pair<std::string, std::string> > StateDataMap; // key -> gui_name, value
        static StateDataMap stateData;
        static std::vector<std::string> sortedKeys;
//        static unsigned int currStateDataIndex;
    };
};
