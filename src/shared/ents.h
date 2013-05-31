// this file defines static map entities ("entity") and dynamic entities (players/monsters, "dynent")
// the gamecode extends these types to add game specific functionality

// ET_*: the only static entity types dictated by the engine... rest are gamecode dependent

enum { ET_EMPTY = 0, ET_MARKER, ET_ORIENTED_MARKER, ET_LIGHT, ET_SPOTLIGHT, ET_ENVMAP, ET_SOUND, ET_PARTICLES, ET_MAPMODEL, ET_OBSTACLE, ET_EXTRA };

struct entity                                   // persistent map entity
{
    vec o;                                      // position
    short attr1, attr2, attr3, attr4, attr5;
    uchar type;                                 // type is one of the above
    uchar reserved;
};

struct extentity : entity                       // part of the entity that doesn't get saved to disk
{
    enum
    {
        F_NOVIS     = 1<<0,
        F_NOSHADOW  = 1<<1,
        F_NOCOLLIDE = 1<<2,
        F_ANIM      = 1<<3
    };

    uchar spawned, inoctanode, visible, flags;  // the only dynamic state of a map entity
    extentity *attached, *attached_next; /* OF: attached_next */

    int uniqueId; // Kripken: Added this

    extentity() : visible(false), flags(0), attached(NULL), attached_next(NULL), uniqueId(-1) {}
};

#define MAXENTS 10000

//extern vector<extentity *> ents;                // map entities

enum { CS_ALIVE = 0, CS_DEAD, CS_SPAWNING, CS_LAGGED, CS_EDITING, CS_SPECTATOR };

enum { PHYS_FLOAT = 0, PHYS_FALL, PHYS_SLIDE, PHYS_SLOPE, PHYS_FLOOR, PHYS_STEP_UP, PHYS_STEP_DOWN, PHYS_BOUNCE };

enum { ENT_PLAYER = 0, ENT_CAMERA, ENT_BOUNCE };

enum { COLLIDE_AABB = 0, COLLIDE_OBB, COLLIDE_ELLIPSE };

#define CROUCHTIME 150 
#define CROUCHHEIGHT 0.75f

struct physent                                  // base entity type, can be affected by physics
{
    vec o, vel, falling;                        // origin, velocity
    vec deltapos, newpos;                       // movement interpolation
    float yaw, pitch, roll;
    float maxspeed;                             // cubes per second, 100 for player
    int timeinair;
    float radius, eyeheight, maxheight, aboveeye; // bounding box size
    float xradius, yradius, zmargin;
    vec floor;                                  // the normal of floor the dynent is on

    int inwater;
    bool jumping;
    char move, strafe, crouching;

    uchar physstate;                            // one of PHYS_* above
    uchar state, editstate;                     // one of CS_* above
    uchar type;                                 // one of ENT_* above
    uchar collidetype;                          // one of COLLIDE_* above           

    bool blocked, moving;                       // used by physics to signal ai
    physent *onplayer;
    int lastmove, lastmoveattempt;

    physent() : o(0, 0, 0), deltapos(0, 0, 0), newpos(0, 0, 0), yaw(0), pitch(0), roll(0), maxspeed(100), 
               radius(4.1f), eyeheight(14), maxheight(14), aboveeye(1), xradius(4.1f), yradius(4.1f), zmargin(0),
               state(CS_ALIVE), editstate(CS_ALIVE), type(ENT_PLAYER),
               collidetype(COLLIDE_ELLIPSE),
               blocked(false), moving(true),
               onplayer(NULL), lastmove(0), lastmoveattempt(0)
               { reset(); }
              
    void resetinterp()
    {
        newpos = o;
        deltapos = vec(0, 0, 0);
    }

    virtual void reset() // OF: virtual
    {
        inwater = 0;
        timeinair = 0;
        eyeheight = maxheight;
        strafe = move = crouching = 0;
        physstate = PHYS_FALL;
        vel = falling = vec(0, 0, 0);
        floor = vec(0, 0, 1);
    }

    vec feetpos(float offset = 0) const { return vec(o).add(vec(0, 0, offset - eyeheight)); }
    vec headpos(float offset = 0) const { return vec(o).add(vec(0, 0, offset)); }

    /* OF: normalization functions */
    void normalize_yaw(float angle)
    {
        while(yaw<angle-180.0f) yaw += 360.0f;
        while(yaw>angle+180.0f) yaw -= 360.0f;
    }

    void normalize_pitch(float angle)
    {
        while(pitch<angle-180.0f) pitch += 360.0f;
        while(pitch>angle+180.0f) pitch -= 360.0f;
    }

    void normalize_roll(float angle)
    {
        while(roll<angle-180.0f) roll += 360.0f;
        while(roll>angle+180.0f) roll -= 360.0f;
    }
};

#define ANIM_ALL         0x7F
#define ANIM_INDEX       0x7F
#define ANIM_LOOP        (1<<7)
#define ANIM_START       (1<<8)
#define ANIM_END         (1<<9)
#define ANIM_REVERSE     (1<<10)
#define ANIM_CLAMP       (ANIM_START|ANIM_END)
#define ANIM_DIR         0x780
#define ANIM_SECONDARY   11
#define ANIM_NOSKIN      (1<<22)
#define ANIM_SETTIME     (1<<23)
#define ANIM_FULLBRIGHT  (1<<24)
#define ANIM_REUSE       (1<<25)
#define ANIM_NORENDER    (1<<26)
#define ANIM_RAGDOLL     (1<<27)
#define ANIM_SETSPEED    (1<<28)
#define ANIM_NOPITCH     (1<<29)
#define ANIM_FLAGS       (0xFF<<22)

struct animinfo // description of a character's animation
{
    int anim, frame, range, basetime;
    float speed;
    uint varseed;

    animinfo() : anim(0), frame(0), range(0), basetime(0), speed(100.0f), varseed(0) { }

    bool operator==(const animinfo &o) const { return frame==o.frame && range==o.range && (anim&(ANIM_SETTIME|ANIM_DIR))==(o.anim&(ANIM_SETTIME|ANIM_DIR)) && (anim&ANIM_SETTIME || basetime==o.basetime) && speed==o.speed; }
    bool operator!=(const animinfo &o) const { return frame!=o.frame || range!=o.range || (anim&(ANIM_SETTIME|ANIM_DIR))!=(o.anim&(ANIM_SETTIME|ANIM_DIR)) || (!(anim&ANIM_SETTIME) && basetime!=o.basetime) || speed!=o.speed; }
};

struct animinterpinfo // used for animation blending of animated characters
{
    animinfo prev, cur;
    int lastswitch;
    void *lastmodel;

    animinterpinfo() : lastswitch(-1), lastmodel(NULL) {}

    void reset() { lastswitch = -1; }
};

#define MAXANIMPARTS 3

struct occludequery;
struct ragdolldata;

struct dynent : physent                         // animated characters, or characters that can receive input
{
    bool k_left, k_right, k_up, k_down;         // see input code

    animinterpinfo animinterp[MAXANIMPARTS];
    ragdolldata *ragdoll;
    occludequery *query;
    int lastrendered;

    dynent() : ragdoll(NULL), query(NULL), lastrendered(0)
    { 
        reset(); 
    }

    virtual ~dynent() // OF: virtual
    {
#ifdef CLIENT
        extern void cleanragdoll(dynent *d);
        if(ragdoll) cleanragdoll(this);
#endif
    }
               
    virtual void stopmoving() // OF: virtual
    {
        k_left = k_right = k_up = k_down = jumping = false;
        move = strafe = crouching = 0;
    }
        
    virtual void reset() // OF: virtual
    {
        physent::reset();
        stopmoving();
        loopi(MAXANIMPARTS) animinterp[i].reset();
    }

    vec abovehead() { return vec(o).add(vec(0, 0, aboveeye+4)); }
};


