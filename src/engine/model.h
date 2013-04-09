enum { MDL_MD3 = 0, MDL_MD5, MDL_OBJ, MDL_SMD, MDL_IQM, NUMMODELTYPES };

struct model
{
    float spinyaw, spinpitch, offsetyaw, offsetpitch;
    bool collide, ellipsecollide, shadow, depthoffset;
    float scale;
    vec translate;
    BIH *bih;
    vec bbcenter, bbradius, bbextend;
    float eyeheight, collideradius, collideheight;
    int batch;

    bool perentitycollisionboxes; // INTENSITY: Get the collision box from the entiy, not the model type

    model() : spinyaw(0), spinpitch(0), offsetyaw(0), offsetpitch(0), collide(true), ellipsecollide(false), shadow(true), depthoffset(false), scale(1.0f), translate(0, 0, 0), bih(0), bbcenter(0, 0, 0), bbradius(-1, -1, -1), bbextend(0, 0, 0), eyeheight(0.9f), collideradius(0), collideheight(0), batch(-1)
          , perentitycollisionboxes(false)
        {}
    virtual ~model() { DELETEP(bih); }
    virtual void calcbb(vec &center, vec &radius) = 0;
    virtual int intersect(int anim, int basetime, int basetime2, const vec &pos, float yaw, float pitch, dynent *d, modelattach *a, float size, const vec &o, const vec &ray, float &dist, int mode) = 0;
    virtual void render(int anim, int basetime, int basetime2, const vec &o, float yaw, float pitch, dynent *d, modelattach *a = NULL, float size = 1, float trans = 1) = 0;
    virtual bool load() = 0;
    virtual const char *name() const = 0;
    virtual int type() const = 0;
    virtual BIH *setBIH() { return 0; }
    virtual void gentris(vector<BIH::tri> *tris) { } // INTENSITY: Made this 'public' by putting it here
    virtual bool envmapped() { return false; }
    virtual bool skeletal() const { return false; }
    virtual bool animated() const { return false; }

    virtual void setshader(Shader *shader) {}
    virtual void setenvmap(float envmapmin, float envmapmax, Texture *envmap) {}
    virtual void setspec(float spec) {}
    virtual void setambient(float ambient) {}
    virtual void setglow(float glow, float glowdelta, float glowpulse) {}
    virtual void setglare(float specglare, float glowglare) {}
    virtual void setalphatest(float alpha) {}
    virtual void setfullbright(float fullbright) {}
    virtual void setcullface(bool cullface) {}

    virtual void preloadBIH() { if(!bih) setBIH(); }
    virtual void preloadshaders() {}
    virtual void preloadmeshes() {}
    virtual void cleanup() {}

    virtual void startrender() {}
    virtual void endrender() {}

    void boundbox(vec &center, vec &radius, CLogicEntity* entity=0) // INTENSITY: Added entity
    {
        if (perentitycollisionboxes && entity) { perentitybox(center, radius, entity); return; } // INTENSITY

        if(bbradius.x < 0) calcbb(bbcenter, bbradius);
        center = bbcenter;
        radius = vec(bbradius).add(bbextend);
    }

    void collisionbox(vec &center, vec &radius, CLogicEntity* entity=0) // INTENSITY: Added entity
    {
        if (perentitycollisionboxes && entity) { perentitybox(center, radius, entity); return; } // INTENSITY

        boundbox(center, radius);
        if(collideradius)
        {
            center[0] = center[1] = 0;
            radius[0] = radius[1] = collideradius;
        }
        if(collideheight)
        {
            center[2] = radius[2] = collideheight/2;
        }
    }

    float boundsphere(vec &center)
    {
        vec radius;
        boundbox(center, radius);
        return radius.magnitude();
    }

    float above()
    {
        vec center, radius;
        boundbox(center, radius);
        return center.z+radius.z;
    }

    // INTENSITY: New function. A collision/bounding box that uses per-entity info
    void perentitybox(vec &center, vec &radius, CLogicEntity* entity=0)
    {
        assert(entity); // We should never be called without the parameter. It has a defaultvalue
                        // just in order to not need to change sauer code in irrelevant places

        float width = entity->collisionRadiusWidth;
        float height = entity->collisionRadiusHeight;

        if (width < 0) // If never loaded, load once from Lua now. This occurs once per instance.
                        // This is necessary because these are values cached from lua, unlike normal
                        // Sauer C++ variables that are managed in C++. Here, the *true* values are in lua
        {
            lua_State *L = lapi::state.state();
            lua_rawgeti (L, LUA_REGISTRYINDEX, entity->lua_ref);
            lua_getfield(L, -1, "collision_radius_width");
            width = lua_tonumber(L, -1); lua_pop(L, 1);
            lua_getfield(L, -1, "collision_radius_height");
            height = lua_tonumber(L, -1); lua_pop(L, 1);
            lua_pop(L, 1);
        }

        center[0] = center[1] = 0;
        radius[0] = radius[1] = width;
        center[2] = radius[2] = height;
    }
};

