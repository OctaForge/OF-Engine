// creation of scoreboard
#include "cube.h"
#include "engine.h"
#include "game.h"

#include "network_system.h"
#include "of_tools.h"

namespace game
{
    VARP(scoreboard2d, 0, 1, 1);
    VARP(showpj, 0, 1, 1); // Kripken
    VARP(showping, 0, 1, 1);
    VARP(showspectators, 0, 1, 1);

    struct scoreboardgui
    {
        bool showing;

        scoreboardgui() : showing(false) {}

        void show(bool on)
        {
            if(!showing && on)
                lapi::state.get<lua::Function>(
                    "LAPI", "GUI", "show"
                )("scoreboard");
            else
                lapi::state.get<lua::Function>(
                    "LAPI", "GUI", "hide"
                )("scoreboard");
            showing = on;
        }
    } scoreboard;
}

// CubeCreate: temporary for variable exports >.>
void scorebshow(bool on)
{
    game::scoreboard.show(on);
}
