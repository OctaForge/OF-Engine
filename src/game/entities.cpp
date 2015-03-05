#include "engine.h"
#include "game.h"

void removeentity(int id);
void addentity(int id);
void attachentity(extentity &e);
bool enttoggle(int id);
void makeundoent();
bool dropentity(entity &e, int drop = -1);

extern int efocus;

struct modelinfo {
    model *m, *collide;
    int anim, start_time;
    vector<modelattach> attachments;
    hashtable<const char*, entlinkpos> attachment_positions;

    modelinfo(): m(NULL), collide(NULL), anim(0), start_time(0) {
        attachments.add(modelattach());
    }

    ~modelinfo() {
        clear_attachments(attachments, attachment_positions);
    }
};

struct ofentity: extentity {
    modelinfo *m;
    ofentity(): extentity(), m(NULL) {}
    ~ofentity() { delete m; }
};

namespace entities
{
    using namespace game;

    vector<extentity *> ents;

    vector<extentity *> &getents() { return ents; }

    extentity *newentity() { return new ofentity(); }

    void deleteentity(extentity *e) { delete (ofentity *)e; }

    void clearents()
    {
        while(ents.length()) deleteentity(ents.pop());
    }

    void editent(int i, bool local)
    {
    }

    model *getmodel(const extentity &e) {
        const ofentity &oe = (const ofentity &)e;
        if (!oe.m) return NULL;
        return oe.m->m;
    }

    void setmodel(extentity &e, model *m) {
        ofentity &oe = (ofentity &)e;
        if (!oe.m) return;
        oe.m->m = m;
    }

    model *getcollidemodel(const extentity &e) {
        const ofentity &oe = (const ofentity &)e;
        if (!oe.m) return NULL;
        return oe.m->collide;
    }

    void setcollidemodel(extentity &e, model *m) {
        ofentity &oe = (ofentity &)e;
        if (!oe.m) return;
        oe.m->collide = m;
    }

    int getanim(const extentity &e) {
        const ofentity &oe = (const ofentity &)e;
        if (!oe.m) return 0;
        return oe.m->anim;
    }

    int getstarttime(const extentity &e) {
        const ofentity &oe = (const ofentity &)e;
        if (!oe.m) return 0;
        return oe.m->start_time;
    }

    modelattach *getattachments(extentity &e) {
        ofentity &oe = (ofentity &)e;
        if (!oe.m) return NULL;
        vector<modelattach> &at = oe.m->attachments;
        if (at.length() <= 1) return NULL;
        return at.getbuf();
    }

    /* Entity attributes */

    CLUAICOMMAND(set_animation_dyn, void, (int cn, int anim), {
        gameent *d = getclient(cn);
        if (!d) return;
        d->anim = anim;
        d->start_time = lastmillis;
    });

    CLUAICOMMAND(get_start_time_dyn, bool, (int cn, int *val), {
        gameent *d = getclient(cn);
        if (!d) return false;
        *val = d->start_time;
        return true;
    });

    CLUAICOMMAND(set_animation_ext, void, (int uid, int anim), {
        ofentity *oe = (ofentity *)ents[uid];
        if (!oe || !oe->m) return;
        oe->m->anim = anim;
        oe->m->start_time = lastmillis;
    });

    CLUAICOMMAND(get_start_time_ext, bool, (int uid, int *val), {
        ofentity *oe = (ofentity *)ents[uid];
        if (!oe || !oe->m) return false;
        *val = oe->m->start_time;
        return true;
    });

    CLUAICOMMAND(set_model_name, void, (int uid, const char *name), {
        ofentity *oe = (ofentity *)ents[uid];
        if (!oe || !oe->m) return;
        if (name[0]) oe->m->m = loadmodel(name ? name : "");
    });

    CLUAICOMMAND(set_attachments_dyn, void, (int cn, const char **attach), {
        gameent *d = getclient(cn);
        if (!d) return;
        set_attachments(d->attachments, d->attachment_positions, attach);
    });

    CLUAICOMMAND(set_attachments_ext, void, (int uid, const char **attach), {
        ofentity *oe = (ofentity *)ents[uid];
        if (!oe || !oe->m) return;
        set_attachments(oe->m->attachments, oe->m->attachment_positions, attach);
    });

    static bool get_attachment_pos(const char *tag,
    hashtable<const char *, entlinkpos> &attachment_positions,
    float *x, float *y, float *z) {
        vec *pos = (vec*)attachment_positions.access(tag);
        if (pos) {
            if ((lastmillis - *((int*)(pos + 1))) < 500) {
                *x = pos->x;
                *y = pos->y;
                *z = pos->z;
                return true;
            }
        }
        return false;
    }

    CLUAICOMMAND(get_attachment_pos_ext, bool, (int uid, const char *tag,
    float *x, float *y, float *z), {
        ofentity *oe = (ofentity *)ents[uid];
        if (!oe || !oe->m) return false;
        return get_attachment_pos(tag, oe->m->attachment_positions, x, y, z);
    });

    CLUAICOMMAND(get_attachment_pos_dyn, bool, (int cn, const char *tag,
    float *x, float *y, float *z), {
        gameent *d = getclient(cn);
        if (!d) return false;
        return get_attachment_pos(tag, d->attachment_positions, x, y, z);
    });

    CLUAICOMMAND(set_can_move, void, (int cn, bool b), {
        gameent *d = getclient(cn);
        if (!d) return;
        d->can_move = b;
    });

    /* Extents */

    CLUAICOMMAND(get_attr, bool, (int uid, int a, int *val), {
        extentity *ext = ents[uid];
        assert(ext);
        *val = ext->attr[a];
        return true;
    });
    CLUAICOMMAND(set_attr, void, (int uid, int a, int v), {
        extentity *ext = ents[uid];
        assert(ext);
        ext->attr[a] = v;
    });

    CLUAICOMMAND(get_extent_position, bool, (int uid, double *pos), {
        extentity *ext = ents[uid];
        assert(ext);
        pos[0] = ext->o.x;
        pos[1] = ext->o.y;
        pos[2] = ext->o.z;
        return true;
    });

    CLUAICOMMAND(set_extent_position, void, (int uid, double x, double y,
    double z), {
        extentity *ext = ents[uid];
        assert(ext);
        ext->o.x = x;
        ext->o.y = y;
        ext->o.z = z;
    });

    /* Dynents */

    #define DYNENT_ACCESSORS(n, t, an) \
    CLUAICOMMAND(get_##n, bool, (int cn, t *val), { \
        gameent *d = getclient(cn); \
        assert(d); \
        *val = d->an; \
        return true; \
    }); \
    CLUAICOMMAND(set_##n, void, (int cn, t v), { \
        gameent *d = getclient(cn); \
        assert(d); \
        d->an = v; \
    });

    DYNENT_ACCESSORS(maxspeed, float, maxspeed)
    DYNENT_ACCESSORS(crouchtime, int, crouchtime)
    DYNENT_ACCESSORS(radius, float, radius)
    DYNENT_ACCESSORS(eyeheight, float, eyeheight)
    DYNENT_ACCESSORS(maxheight, float, maxheight)
    DYNENT_ACCESSORS(crouchheight, float, crouchheight)
    DYNENT_ACCESSORS(crouchspeed, float, crouchspeed)
    DYNENT_ACCESSORS(jumpvel, float, jumpvel)
    DYNENT_ACCESSORS(gravity, float, gravity)
    DYNENT_ACCESSORS(aboveeye, float, aboveeye)
    DYNENT_ACCESSORS(yaw, float, yaw)
    DYNENT_ACCESSORS(pitch, float, pitch)
    DYNENT_ACCESSORS(roll, float, roll)
    DYNENT_ACCESSORS(move, int, move)
    DYNENT_ACCESSORS(strafe, int, strafe)
    DYNENT_ACCESSORS(yawing, int, turn_move)
    DYNENT_ACCESSORS(crouching, int, crouching)
    DYNENT_ACCESSORS(pitching, int, look_updown_move)
    DYNENT_ACCESSORS(jumping, bool, jumping)
    DYNENT_ACCESSORS(blocked, bool, blocked)
    DYNENT_ACCESSORS(clientstate, int, state)
    DYNENT_ACCESSORS(physstate, int, physstate)
    DYNENT_ACCESSORS(inwater, int, inwater)
    DYNENT_ACCESSORS(timeinair, int, timeinair)
    #undef DYNENT_ACCESSORS

    CLUAICOMMAND(get_dynent_position, bool, (int cn, double *pos), {
        gameent *d = getclient(cn);
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    CLUAICOMMAND(set_dynent_position, void, (int cn, double x, double y,
    double z), {
        gameent *d = getclient(cn);
        assert(d);

        d->o.x = x;
        d->o.y = y;
        d->o.z = z + d->eyeheight;/* + d->aboveeye; */

        /* also set newpos, otherwise this change may get overwritten */
        d->newpos = d->o;

        /* no need to interpolate to the last position - just jump */
        d->resetinterp();
    });

    CLUAICOMMAND(get_dynent_position, bool, (int cn, double *pos), {
        gameent *d = getclient(cn);
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    #define DYNENTVEC(name, prop) \
        CLUAICOMMAND(get_dynent_##name, bool, (int cn, double *val), { \
            gameent *d = getclient(cn); \
            assert(d); \
            val[0] = d->o.x; \
            val[1] = d->o.y; \
            val[2] = d->o.z; \
            return true; \
        }); \
        CLUAICOMMAND(set_dynent_##name, void, (int cn, double x, \
        double y, double z), { \
            gameent *d = getclient(cn); \
            assert(d); \
            d->prop.x = x; \
            d->prop.y = y; \
            d->prop.z = z; \
        });

    DYNENTVEC(velocity, vel)
    DYNENTVEC(falling, falling)
    #undef DYNENTVEC

    CLUAICOMMAND(get_plag, bool, (int cn, int *val), {
        gameent *p = getclient(cn);
        assert(p);
        *val = p->plag;
        return true;
    });

    CLUAICOMMAND(get_ping, bool, (int cn, int *val), {
        gameent *p = getclient(cn);
        assert(p);
        *val = p->ping;
        return true;
    });

    CLUAICOMMAND(get_selected_entity, int, (), {
        const vector<extentity *> &ents = entities::getents();
        if (!ents.inrange(efocus)) return -1;
        return efocus;
    });

    CLUAICOMMAND(get_attached_entity, int, (int uid), {
        extentity *e = ents.inrange(uid) ? ents[uid] : NULL;
        if (!e || !e->attached) return -1;
        return e->attached->uid;
    });

    CLUAICOMMAND(setup_extent, bool, (int uid, int type, bool isnew), {
        while (ents.length() < uid) ents.add(newentity())->type = ET_EMPTY;
        ofentity *e = NULL;
        if (!ents.inrange(uid)) {
            e = (ofentity*)newentity();
            ents.add(e);
        } else {
            e = (ofentity*)ents[uid];
        }
        if (e->m) delete e->m;
        e->m = (type == ET_MAPMODEL) ? new modelinfo : NULL;
        e->type = type;
        e->uid = uid;
        e->o = vec(0, 0, 0);
        memset(e->attr, 0, sizeof(e->attr));
        return e->type != ET_EMPTY;
    });

    CLUAICOMMAND(destroy_extent, void, (int uid), {
        ofentity *e = (ofentity *)ents[uid];
        if (e->type == ET_SOUND) stopmapsound(e);
        removeentity(uid);
        if (e->m) {
            delete e->m;
            e->m = NULL;
        }
        e->type = ET_EMPTY;
    });

    CLUAICOMMAND(setup_extent_done, void, (int uid, bool prevce, bool isnew, bool synced), {
        ofentity *e = (ofentity *)ents[uid];
        assert(e);
        if (!prevce) {
            int otype = e->type;
            if (isnew && !synced && e->o.x < 0) {
                dropentity(*e);
            }
            e->type = ET_EMPTY;
            if (isnew && !synced) {
                enttoggle(uid);
                makeundoent();
            }
            e->type = otype;
            addentity(uid);
        }
        if (isnew) {
            attachentity(*e);
            commitchanges();
        }
    });

    CLUAICOMMAND(setup_character, bool, (int cn), {
        return !!game::getclient(cn);
    });

    LUAICOMMAND(editent, {
        int i = luaL_checkinteger(L, 1);
        const extentity &e = *ents[i];
        if (e.type == ET_EMPTY) {
            addmsg(N_EDITENT, "ris", i, "");
            return 0;
        }
        const char *name = NULL;
        const char *sdata = NULL;
        size_t sdlen = 0;
        int n = lua::L->call_external_ret_nopop("entity_serialize", "ib", "sm", i,
            true, &name, &sdata, &sdlen);
        if (name) {
            addmsg(N_EDITENT, "risi3ib", i, name, (int)(e.o.x*DMF),
                (int)(e.o.y*DMF), (int)(e.o.z*DMF), (int)sdlen, (int)sdlen, sdata);
        }
        lua::L->pop_external_ret(n);
        return 0;
    });

    void entpos(int i) {
        const extentity &e = *entities::getents()[i];
        if (e.type == ET_EMPTY) return;
        lua::L->call_external("entity_set_pos", "ifff", i,
            e.o.x, e.o.y, e.o.z);
        game::addmsg(N_ENTPOS, "ri4", i, (int)(e.o.x*DMF),
            (int)(e.o.y*DMF), (int)(e.o.z*DMF));
    }

    CLUAICOMMAND(isplayer, bool, (int cn), return cn == player1->clientnum;);
}

