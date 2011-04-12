// creation of scoreboard
#include "cube.h"
#include "engine.h"
#include "game.h"

#include "network_system.h"


namespace game
{
    void renderscoreboard(g3d_gui &g, bool firstpass)
    {
        const char *mname = getclientmap();
        defformatstring(modemapstr)("%s: %s", "Syntensity", mname[0] ? mname : "[new map]");

        g.text(modemapstr, 0xFFFF80, "server");

        g.pushlist(); // vertical
        g.pushlist(); // horizontal
            g.background(0x808080, 5);

            using namespace lua;
            engine.getg("cc").t_getraw("appman").t_getraw("inst");
            engine.t_getraw("get_sbtext").push_index(-2).call(1, 1);
            // we get a table here
            LUA_TABLE_FOREACH(engine, {
                int lineUniqueId = engine.t_get<int>(1);
                std::string lineText(engine.t_get<const char*>(2));
                if (lineUniqueId != -1)
                {
                    LogicEntityPtr entity = LogicSystem::getLogicEntity(lineUniqueId);
                    if (entity.get())
                    {
                        fpsent *p = dynamic_cast<fpsent*>(entity->dynamicEntity);
                        assert(p);

                        if (GETIV(showpj))
                        {
                            if (p->state == CS_LAGGED)
                                lineText += "LAG";
                            else
                                lineText += " pj: " + Utility::toString(p->plag);
                        }
                        if (!GETIV(showpj) && p->state == CS_LAGGED)
                            lineText += "LAG";
                        else
                            lineText += " p: " + Utility::toString(p->ping);
                    }
                }
                g.text(lineText.c_str(), 0xFFFFDD, NULL);
            });
            engine.pop(4);

        g.poplist();
        g.poplist();

        // Show network stats
        static int laststatus = 0; 
        float seconds = float(totalmillis-laststatus)/1024.0f;
        static std::string netStats = "";
        if (seconds >= 0.5)
        {
            laststatus = totalmillis;
            netStats = NetworkSystem::Cataloger::briefSummary(seconds);
        }
        g.text(netStats.c_str(), 0xFFFF80, "server");
    }

    struct scoreboardgui : g3d_callback
    {
        bool showing;
        vec menupos;
        int menustart;

        scoreboardgui() : showing(false) {}

        void show(bool on)
        {
            if(!showing && on)
            {
                menupos = menuinfrontofplayer();
                menustart = starttime();
            }
            showing = on;
        }

        void gui(g3d_gui &g, bool firstpass)
        {
            g.start(menustart, 0.03f, NULL, false);
            renderscoreboard(g, firstpass);
            g.end();
        }

        void render()
        {
            if(showing) g3d_addgui(this, menupos, (GETIV(scoreboard2d) ? GUI_FORCE_2D : GUI_2D | GUI_FOLLOW) | GUI_BOTTOM);
        }

    } scoreboard;

    void g3d_gamemenus()
    {
        scoreboard.render();
    }
}

// CubeCreate: temporary for variable exports >.>
void scorebshow(bool on)
{
    game::scoreboard.show(on);
}
