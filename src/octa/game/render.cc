#include "game.hh"

namespace game
{
    VARP(ragdoll, 0, 1, 1);
    VARP(ragdollmillis, 0, 10000, 300000);
    VARP(ragdollfade, 0, 100, 5000);

    vector<gameent *> ragdolls;

    CLUAICOMMAND(ragdoll_save, bool, (int cn), {
        gameent *d = getclient(cn);
        assert(d);
        if(!d->ragdoll || !ragdollmillis || (!ragdollfade && lastmillis > d->lastdeath + ragdollmillis)) return false;
        gameent *r = new gameent(*d);
        r->lastupdate = ragdollfade && lastmillis > d->lastdeath + max(ragdollmillis - ragdollfade, 0) ? lastmillis - max(ragdollmillis - ragdollfade, 0) : d->lastdeath;
        r->edit = NULL;
        r->ai = NULL;
        ragdolls.add(r);
        d->ragdoll = NULL;
        return true;
    });

    CLUAICOMMAND(ragdoll_clean, void, (int cn), {
        gameent *d = getclient(cn);
        assert(d);
        if (d->ragdoll) cleanragdoll(d);
    })

    void clearragdolls() {
        ragdolls.deletecontents();
    }

    CLUAICOMMAND(ragdolls_clear, void, (), clearragdolls(););

    void moveragdolls() {
        loopv(ragdolls)
        {
            gameent *d = ragdolls[i];
            if(lastmillis > d->lastupdate + ragdollmillis)
            {
                delete ragdolls.remove(i--);
                continue;
            }
            moveragdoll(d);
        }
    }

    CLUAICOMMAND(ragdolls_move, void, (), moveragdolls(););

    VARP(playerfpsshadow, 0, 1, 1);

    void rendergame()
    {
        bool tp = isthirdperson();
        lua::L->call_external("game_render", "bb", tp, !tp && playerfpsshadow);
    }

    void renderavatar()
    {
        lua::L->call_external("game_render_hud", "");
    }
}

