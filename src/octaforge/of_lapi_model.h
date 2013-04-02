VARP(ragdoll, 0, 1, 1);

namespace lapi_binds
{
#ifdef CLIENT
    static int oldtp = -1;

    void preparerd(int& anim, CLogicEntity *self)
    {
        if (anim&ANIM_RAGDOLL)
        {
            //if (!ragdoll || loadmodel(mdl);
            fpsent *fp = (fpsent*)self->dynamicEntity;

            if (fp->clientnum == ClientSystem::playerNumber)
            {
                if (oldtp == -1 && thirdperson == 0)
                {
                    oldtp = thirdperson;
                    thirdperson = 1;
                }
            }

            if (fp->ragdoll || !ragdoll)
            {
                anim &= ~ANIM_RAGDOLL;
                self->lua_ref.get<lua::Function>("set_local_animation")
                    (self->lua_ref, anim);
            }
        }
        else
        {
            if (self->dynamicEntity)
            {
                fpsent *fp = (fpsent*)self->dynamicEntity;

                if (fp->clientnum == ClientSystem::playerNumber && oldtp != -1)
                {
                    thirdperson = oldtp;
                    oldtp = -1;
                }
            }
        }
    }

    fpsent *getproxyfpsent(CLogicEntity *self)
    {
        lua::Object h(self->lua_ref["rendering_hash_hint"]);
        if (!h.is_nil())
        {
            static bool initialized = false;
            static fpsent *fpsentsfr[1024];
            if (!initialized)
            {
                for (int i = 0; i < 1024; i++) fpsentsfr[i] = new fpsent;
                initialized = true;
            }

            int rhashhint = h.to<int>();
            rhashhint = rhashhint & 1023;
            assert(rhashhint >= 0 && rhashhint < 1024);
            return fpsentsfr[rhashhint];
        }
        else return NULL;
    }

    void _lua_rendermodel(
        lua::Table self, const char *mdl,
        int anim, float x, float y, float z,
        float yaw, float pitch,
        int flags, int basetime
    )
    {
        LAPI_GET_ENT(entity, self, "CAPI.rendermodel", return)

        preparerd(anim, entity);
        fpsent *fp = NULL;

        if (entity->dynamicEntity)
            fp = (fpsent*)entity->dynamicEntity;
        else
            fp = getproxyfpsent(entity);

        rendermodel(mdl, anim, vec(x, y, z), yaw, pitch, flags, fp,
            entity->attachments, basetime, 0, 1);
    }

    lua::Table _lua_scriptmdlbb(const char *name)
    {
        model *mdl = loadmodel(name);
        if   (!mdl)
            return lapi::state.wrap<lua::Table>(lua::nil);

        vec center, radius;
        mdl->boundbox(center, radius);

        lua::Table ret(lapi::state.new_table(0, 2));
        ret["center"] = lapi::state.get<lua::Function>("external", "new_vec3")
            .call<lua::Table>(center.x, center.y, center.z);
        ret["radius"] = lapi::state.get<lua::Function>("external", "new_vec3")
            .call<lua::Table>(radius.x, radius.y, radius.z);
        return ret;
    }

    lua::Table _lua_scriptmdlcb(const char *name)
    {
        model *mdl = loadmodel(name);
        if   (!mdl)
            return lapi::state.wrap<lua::Table>(lua::nil);

        vec center, radius;
        mdl->collisionbox(center, radius);

        lua::Table ret(lapi::state.new_table(0, 2));
        ret["center"] = lapi::state.get<lua::Function>("external", "new_vec3")
            .call<lua::Table>(center.x, center.y, center.z);
        ret["radius"] = lapi::state.get<lua::Function>("external", "new_vec3")
            .call<lua::Table>(radius.x, radius.y, radius.z);
        return ret;
    }

    lua::Table _lua_mdlmesh(const char *name)
    {
        model *mdl = loadmodel(name);
        if   (!mdl)
            return lapi::state.wrap<lua::Table>(lua::nil);

        vector<BIH::tri> tris2[2];
        mdl->gentris(tris2);
        vector<BIH::tri>& tris = tris2[0];
        types::String buf;

        lua::Table ret(lapi::state.new_table(0, 1));
        ret["length"] = tris.length();

        for (int i = 0; i < tris.length(); ++i)
        {
            BIH::tri& bt = tris[i];

            lua::Table t(lapi::state.new_table(0, 3));
            t["a"] = lapi::state.get<lua::Function>("external", "new_vec3")
                .call<lua::Table>(bt.a.x, bt.a.y, bt.a.z);
            t["b"] = lapi::state.get<lua::Function>("external", "new_vec3")
                .call<lua::Table>(bt.b.x, bt.b.y, bt.b.z);
            t["c"] = lapi::state.get<lua::Function>("external", "new_vec3")
                .call<lua::Table>(bt.c.x, bt.c.y, bt.c.z);

            ret[buf.format("%i", i).get_buf()] = t;
        }

        return ret;
    }

    lua::Table _lua_findanims(const char *pattern)
    {
        vector<int> anims;
        findanims(pattern, anims);

        lua::Table ret(lapi::state.new_table());
        for (int i = 0; i < anims.length(); ++i)
            ret[i + 1] = anims[i];
        return ret;
    }
#else
    LAPI_EMPTY(rendermodel)
    LAPI_EMPTY(scriptmdlbb)
    LAPI_EMPTY(scriptmdlcb)
    LAPI_EMPTY(mdlmesh)
    LAPI_EMPTY(findanims)
#endif

    void reg_model(lua::Table& t)
    {
        LAPI_REG(rendermodel);
        LAPI_REG(scriptmdlbb);
        LAPI_REG(scriptmdlcb);
        LAPI_REG(mdlmesh);
        LAPI_REG(findanims);
    }
}
