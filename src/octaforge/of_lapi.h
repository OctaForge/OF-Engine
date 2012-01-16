#ifndef OF_LAPI_H
#define OF_LAPI_H

#include "OFTL/lua.h"

namespace lapi
{
    extern lua::State state;

    void init        (const char *dir = "data/library/core");
    void reset       ();
    bool load_library(const char *name);
}

#endif
