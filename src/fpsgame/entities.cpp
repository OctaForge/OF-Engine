#include "cube.h"
#include "engine.h"
#include "game.h"


namespace entities
{
    using namespace game;
    
    vector<extentity *> ents;

    vector<extentity *> &getents() { return ents; }

    bool mayattach(extentity &e) { return false; }
    bool attachent(extentity &e, extentity &a) { return false; }
    
    const char *entmodel(const entity &e)
    {
        return NULL;
    }

    void preloadentities()
    {
    }

    void renderent(extentity &e, const char *mdlname, float z, float yaw)
    {
        assert(0);
    }

    void renderent(extentity &e, int type, float z, float yaw)
    {
        assert(0);
    }

    void renderentities()
    {
        loopv(ents)
        {
            extentity &e = *ents[i];
            if(e.type==CARROT || e.type==RESPAWNPOINT)
            {
                renderent(e, e.type, (float)(1+sin(lastmillis/100.0+e.o.x+e.o.y)/20), lastmillis/(e.attr2 ? 1.0f : 10.0f));
                continue;
            }
            if(e.type==TELEPORT)
            {
                if(e.attr2 < 0) continue;
                if(e.attr2 > 0)
                {
                    renderent(e, mapmodelname(e.attr2), (float)(1+sin(lastmillis/100.0+e.o.x+e.o.y)/20), lastmillis/10.0f);        
                    continue;
                }
            }
            else
            {
                if(!e.spawned) continue;
                if(e.type<I_SHELLS || e.type>I_QUAD) continue;
            }
            renderent(e, e.type, (float)(1+sin(lastmillis/100.0+e.o.x+e.o.y)/20), lastmillis/10.0f);
        }
    }

    void rumble(const extentity &e)
    {
    }

    void trigger(extentity &e)
    {
    }

    void addammo(int type, int &v, bool local)
    {
    }

    void repammo(fpsent *d, int type, bool local)
    {
        addammo(type, d->ammo[type-I_SHELLS+GUN_SG], local);
    }

    // these two functions are called when the server acknowledges that you really
    // picked up the item (in multiplayer someone may grab it before you).

    void pickupeffects(int n, fpsent *d)
    {
    }

    // these functions are called when the client touches the item

    void teleport(int n, fpsent *d)     // also used by monsters
    {
    }

    void trypickup(int n, fpsent *d)
    {
    }

    void checkitems(fpsent *d)
    {
    }

    void checkquad(int time, fpsent *d)
    {
    }

    void putitems(ucharbuf &p)            // puts items in network stream and also spawns them locally
    {
    }

    void resetspawns() { loopv(ents) ents[i]->spawned = false; }

    void spawnitems()
    {
    }

    void setspawn(int i, bool on) { if(ents.inrange(i)) ents[i]->spawned = on; }

    extentity *newentity() { return new fpsentity(); }
    void deleteentity(extentity *e) { delete (fpsentity *)e; }

    void clearents()
    {
        while(ents.length()) deleteentity(ents.pop());
    }

    void animatemapmodel(const extentity &e, int &anim, int &basetime)
    {
    }

    void fixentity(extentity &e)
    {
    }

    void entradius(extentity &e, bool color)
    {
    }

    const char *entnameinfo(entity &e) { return ""; }
    const char *entname(int i)
    {
        static const char *entnames[] =
        {
            "none?", "light", "mapmodel", "playerstart", "envmap", "particles", "sound", "spotlight",
            "shells", "bullets", "rockets", "riflerounds", "grenades", "cartridges",
            "health", "healthboost", "greenarmour", "yellowarmour", "quaddamage",
            "teleport", "teledest",
            "monster", "carrot", "jumppad",
            "base", "respawnpoint",
            "box", "barrel",
            "platform", "elevator",
            "flag",
            "", "", "", "",
        };
        return i>=0 && size_t(i)<sizeof(entnames)/sizeof(entnames[0]) ? entnames[i] : "";
    }
    
    int extraentinfosize() { return 0; }       // size in bytes of what the 2 methods below read/write... so it can be skipped by other games

    void writeent(entity &e, char *buf)   // write any additional data to disk (except for ET_ ents)
    {
    }

    void readent(entity &e, char *buf)     // read from disk, and init
    {
        int ver = getmapversion();
        if(ver <= 30) switch(e.type)
        {
            case FLAG:
            case MONSTER:
            case TELEDEST:
            case RESPAWNPOINT:
            case BOX:
            case BARREL:
            case PLATFORM:
            case ELEVATOR:
                e.attr1 = (int(e.attr1)+180)%360;
                break;
        }
    }

    void editent(int i, bool local)
    {
        // We use our own protocol for this sort of thing - StateVariable updates, normally
    }

    float dropheight(entity &e)
    {
        if(e.type==MAPMODEL || e.type==BASE || e.type==FLAG) return 0.0f;
        return 4.0f;
    }

    bool printent(extentity &e, char *buf)
    {
        return false;
    }
}

