
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

// Camera stuff

//! GUI control utilities. Possibly worth merging into CameraControl

struct GuiControl
{
    //! When mouselooking, the mouse controls orientation as in an FPS
    static void toggleMouselook();
    static bool isMouselooking();

    //! Key clicks
    static void menuKeyClickTrigger();
};
