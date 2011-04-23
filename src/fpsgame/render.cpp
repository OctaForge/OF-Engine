
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "game.h"
#include "crypto.h"

#include "intensity.h"
#include "client_system.h"

namespace game
{      
    void rendergame(bool mainpass)
    {
        if (!ClientSystem::loggedIn) // If not logged in remotely, do not render, because entities lack all the fields like model_name
                                     // in the future, perhaps add these, if we want local rendering
        {
            Logging::log(Logging::INFO, "Not logged in remotely, so not rendering\r\n");
            return;
        }

        startmodelbatches();

        lua::engine.getg("cc")
                   .t_getraw("logent")
                   .t_getraw("store")
                   .t_getraw("render_dynamic")
                   .push(isthirdperson()).call(1, 0)
                   .pop(3);

//        ExtraRendering::renderShadowingMapmodels(); // Kripken: Mapmodels with dynamic shadows, we draw them now
        entities::renderentities();

        endmodelbatches();
    }

    int swaymillis = 0;
    vec swaydir(0, 0, 0);

    void swayhudgun(int curtime)
    {
        fpsent *d = hudplayer();
        if(d->state!=CS_SPECTATOR)
        {
            if(d->physstate>=PHYS_SLOPE) swaymillis += curtime;
            float k = pow(0.7f, curtime/10.0f);
            swaydir.mul(k);
            vec vel(d->vel);
            vel.add(d->falling);
            swaydir.add(vec(vel).mul((1-k)/(15*max(vel.magnitude(), d->maxspeed))));
        }
    }

    void renderavatar()
    {
        lua::engine.getg("cc").t_getraw("logent").t_getraw("store").t_getraw("render_hud_models").call(0, 0).pop(3);
    }
}

