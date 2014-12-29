#include "game.h"

void removeentity(extentity* entity);
void addentity(extentity* entity);
void attachentity(extentity &e);

extern int efocus;

/* OF */
static const int attrnums[] = {
    0, /* ET_EMPTY */
    0, /* ET_MARKER */
    2, /* ET_ORIENTED_MARKER */
    5, /* ET_LIGHT */
    1, /* ET_SPOTLIGHT */
    1, /* ET_ENVMAP */
    2, /* ET_SOUND */
    0, /* ET_PARTICLES */
    4, /* ET_MAPMODEL */
    7, /* ET_OBSTACLE */
    5  /* ET_DECAL */
};

int getattrnum(int type) {
    return attrnums[(type >= 0 &&
        (size_t)type < (sizeof(attrnums) / sizeof(int))) ? type : 0];
}

struct modelentity: extentity {
    model *m, *collide;
    int anim, start_time;
    vector<modelattach> attachments;
    hashtable<const char*, entlinkpos> attachment_positions;

    modelentity(): extentity(), m(NULL), collide(NULL), anim(0), start_time(0) {
        attachments.add(modelattach());
    }

    ~modelentity() {
        clear_attachments(attachments, attachment_positions);
    }
};

namespace entities
{
    using namespace game;

    vector<extentity *> ents;

    vector<extentity *> &getents() { return ents; }

    extentity *newentity() { return new extentity(); }

    void deleteentity(extentity *e) {
        if (e->type == ET_MAPMODEL)
            delete (modelentity *)e;
        else
            delete e;
    }

    void clearents()
    {
        while(ents.length()) deleteentity(ents.pop());
    }

    void editent(int i, bool local)
    {
    }

    model *getmodel(const extentity &e) {
        if (e.type != ET_MAPMODEL) return NULL;
        return ((const modelentity &)e).m;
    }

    void setmodel(extentity &e, model *m) {
        if (e.type != ET_MAPMODEL) return;
        ((modelentity &)e).m = m;
    }

    model *getcollidemodel(const extentity &e) {
        if (e.type != ET_MAPMODEL) return NULL;
        return ((const modelentity &)e).collide;
    }

    void setcollidemodel(extentity &e, model *m) {
        if (e.type != ET_MAPMODEL) return;
        ((modelentity &)e).collide = m;
    }

    int getanim(const extentity &e) {
        if (e.type != ET_MAPMODEL) return 0;
        return ((const modelentity &)e).anim;
    }

    int getstarttime(const extentity &e) {
        if (e.type != ET_MAPMODEL) return 0;
        return ((const modelentity &)e).start_time;
    }

    modelattach *getattachments(extentity &e) {
        if (e.type != ET_MAPMODEL) return NULL;
        vector<modelattach> &at = ((modelentity &)e).attachments;
        if (at.length() <= 1) return NULL;
        return at.getbuf();
    }

    /* Entity attributes */

    CLUAICOMMAND(set_animation_dyn, void, (physent *ent, int anim), {
        if (!ent) return;
        gameent *d = (gameent*)ent;
        d->anim = anim;
        d->start_time = lastmillis;
    });

    CLUAICOMMAND(get_start_time_dyn, bool, (physent *ent, int *val), {
        if (!ent) return false;
        gameent *d = (gameent*)ent;
        *val = d->start_time;
        return true;
    });

    CLUAICOMMAND(set_animation_ext, void, (extentity *ext, int anim), {
        if (!ext) return;
        ((modelentity*)ext)->anim = anim;
        ((modelentity*)ext)->start_time = lastmillis;
    });

    CLUAICOMMAND(get_start_time_ext, bool, (extentity *ext, int *val), {
        if (!ext) return false;
        *val = ((modelentity*)ext)->start_time;
        return true;
    });

    CLUAICOMMAND(set_model_name, void, (extentity *ext, const char *name), {
        if (!ext) return;
        removeentity(ext);
        if (name[0]) ((modelentity*)ext)->m = loadmodel(name ? name : "");
        addentity(ext);
    });

    CLUAICOMMAND(set_attachments_dyn, void, (physent *ent, const char **attach), {
        if (!ent) return;
        gameent *d = (gameent*)ent;
        set_attachments(d->attachments, d->attachment_positions, attach);
    });

    CLUAICOMMAND(set_attachments_ext, void, (extentity *ext, const char **attach), {
        if (!ext || ext->type != ET_MAPMODEL) return;
        modelentity *e = (modelentity*)ext;
        set_attachments(e->attachments, e->attachment_positions, attach);
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

    CLUAICOMMAND(get_attachment_pos_ext, bool, (extentity *ext, const char *tag,
    float *x, float *y, float *z), {
        if (!ext || ext->type != ET_MAPMODEL) return false;
        return get_attachment_pos(tag, ((modelentity*)ext)->attachment_positions, x, y, z);
    });

    CLUAICOMMAND(get_attachment_pos_dyn, bool, (physent *ent, const char *tag,
    float *x, float *y, float *z), {
        if (!ent) return false;
        return get_attachment_pos(tag, ((gameent*)ent)->attachment_positions, x, y, z);
    });

    CLUAICOMMAND(set_can_move, void, (physent *ent, bool b), {
        if (!ent) return;
        gameent *d = (gameent*)ent;
        d->can_move = b;
    });

    /* Extents */

    CLUAICOMMAND(get_attr, bool, (extentity *ext, int a, int *val), {
        assert(ext);
        *val = ext->attr[a];
        return true;
    });
    CLUAICOMMAND(set_attr, void, (extentity *ext, int a, int v), {
        assert(ext);
        removeentity(ext);
        ext->attr[a] = v;
        addentity(ext);
    });
    CLUAICOMMAND(FAST_set_attr, void, (extentity *ext, int a, int v), {
        assert(ext);
        ext->attr[a] = v;
    });

    CLUAICOMMAND(get_extent_position, bool, (extentity *ext, double *pos), {
        assert(ext);
        pos[0] = ext->o.x;
        pos[1] = ext->o.y;
        pos[2] = ext->o.z;
        return true;
    });

    CLUAICOMMAND(set_extent_position, void, (extentity *ext, double x, double y,
    double z), {
        assert(ext);
        removeentity(ext);
        ext->o.x = x;
        ext->o.y = y;
        ext->o.z = z;
        addentity(ext);
    });

    /* Dynents */

    #define DYNENT_ACCESSORS(n, t, an) \
    CLUAICOMMAND(get_##n, bool, (physent *ent, t *val), { \
        gameent *d = (gameent*)ent; \
        assert(d); \
        *val = d->an; \
        return true; \
    }); \
    CLUAICOMMAND(set_##n, void, (physent *ent, t v), { \
        gameent *d = (gameent*)ent; \
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

    CLUAICOMMAND(get_dynent_position, bool, (physent *ent, double *pos), {
        gameent *d = (gameent*)ent;
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    CLUAICOMMAND(set_dynent_position, void, (physent *ent, double x, double y,
    double z), {
        gameent *d = (gameent*)ent;
        assert(d);

        d->o.x = x;
        d->o.y = y;
        d->o.z = z + d->eyeheight;/* + d->aboveeye; */

        /* also set newpos, otherwise this change may get overwritten */
        d->newpos = d->o;

        /* no need to interpolate to the last position - just jump */
        d->resetinterp();
    });

    CLUAICOMMAND(get_dynent_position, bool, (physent *ent, double *pos), {
        gameent *d = (gameent*)ent;
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    #define DYNENTVEC(name, prop) \
        CLUAICOMMAND(get_dynent_##name, bool, (physent *ent, double *val), { \
            gameent *d = (gameent*)ent; \
            assert(d); \
            val[0] = d->o.x; \
            val[1] = d->o.y; \
            val[2] = d->o.z; \
            return true; \
        }); \
        CLUAICOMMAND(set_dynent_##name, void, (physent *ent, double x, \
        double y, double z), { \
            gameent *d = (gameent*)ent; \
            assert(d); \
            d->prop.x = x; \
            d->prop.y = y; \
            d->prop.z = z; \
        });

    DYNENTVEC(velocity, vel)
    DYNENTVEC(falling, falling)
    #undef DYNENTVEC

    CLUAICOMMAND(get_plag, bool, (physent *d, int *val), {
        gameent *p = (gameent*)d;
        assert(p);
        *val = p->plag;
        return true;
    });

    CLUAICOMMAND(get_ping, bool, (physent *d, int *val), {
        gameent *p = (gameent*)d;
        assert(p);
        *val = p->ping;
        return true;
    });

    CLUAICOMMAND(get_selected_entity, extentity *, (), {
        const vector<extentity *> &ents = entities::getents();
        if (!ents.inrange(efocus)) return NULL;
        return ents[efocus];
    });

    CLUAICOMMAND(get_attached_entity, extentity *, (extentity *e), {
        if (!e || !e->attached) return NULL;
        return e->attached;
    });

    CLUAICOMMAND(setup_extent, extentity *, (int uid, int type, extentity *ce), {
        while (ents.length() < uid) ents.add(newentity())->type = ET_EMPTY;
        extentity *e;
        if (type == ET_MAPMODEL && (!ce || ce->type != ET_MAPMODEL)) {
            e = new modelentity;
            if (ce) {
                delete (extentity *)ce;
                ce = e;
            }
        } else if (ce) {
            e = ce;
        } else {
            e = new extentity;
        }
        e->type = type;
        e->o = vec(0, 0, 0);
        int numattrs = getattrnum(type);
        e->attr.setsize(0);
        for (int i = 0; i < numattrs; ++i) e->attr.add(0);
        if (!ce) {
            if (ents.inrange(uid)) {
                deleteentity(ents[uid]);
                ents[uid] = e;
            } else {
                ents.add(e);
            }
            addentity(e);
        }
        attachentity(*e);
        return e;
    });

    CLUAICOMMAND(destroy_extent, void, (int uid), {
        extentity *e = ents[uid];
        if (e->type == ET_SOUND) stopmapsound(e);
        removeentity(e);
        if (e->type == ET_MAPMODEL) {
            delete e;
            ents[uid] = new extentity;
            e = ents[uid];
        }
        e->type = ET_EMPTY;
    });

    CLUAICOMMAND(setup_character, physent *, (int cn), {
        return game::getclient(cn);
    });
}

