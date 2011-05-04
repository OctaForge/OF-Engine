
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"

#include <map>
#include <sstream>

//==============================
// String utils
//==============================

std::string Utility::toString(std::string val)
{
    return val;
}

#define TO_STRING(type)                  \
std::string Utility::toString(type val)  \
{                                        \
    std::stringstream ss;                \
    std::string ret;                     \
    ss << val;                           \
    return ss.str();                     \
}

TO_STRING(int)
TO_STRING(long)
TO_STRING(double)

//==============================
// System Info
//==============================

extern int clockrealbase;

int Utility::SystemInfo::currTime()
{
#ifdef SERVER
    return enet_time_get();
#else // CLIENT
    return SDL_GetTicks() - clockrealbase;
#endif
// This old method only changes during calls to updateworld etc.!
//    extern int lastmillis;
//    return lastmillis; // We wrap around the sauer clock
}

