
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

//! General utilities

#ifndef UTILITY_H
#define UTILITY_H

struct Utility
{
    //! Convert to std::string (this one is a dummy, exists just so we can call toString on anything)
    static std::string toString(std::string val);
    //! Convert to std::string
    static std::string toString(int         val);
    //! Convert to std::string
    static std::string toString(long        val);
    //! Convert to std::string
    static std::string toString(double      val);

    //! System information

    struct SystemInfo
    {
        //! The current time in the local machine
        static int currTime();
    };
};

struct Timer
{
    int startTime;

    Timer() { reset(); };
    virtual ~Timer() { };

    int totalPassed() { return Utility::SystemInfo::currTime() - startTime; };
    virtual void reset() { startTime = Utility::SystemInfo::currTime(); };
};

struct Benchmarker : Timer
{
    //! The last time start() was called
    int currStartTime;

    //! The total amount of time between start() and stop() calls
    int totalTime;

    void start() { currStartTime = Utility::SystemInfo::currTime(); };
    void stop() { totalTime += Utility::SystemInfo::currTime() - currStartTime; currStartTime = -1; };
    float percentage() { return 100.0f * float(totalTime) / totalPassed(); };
    virtual void reset() { Timer::reset(); currStartTime = -1; totalTime = 0; };
};

#endif

