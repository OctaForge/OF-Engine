/*
 * luabind_parthud.hpp, version 1
 * Particles, HUD, dynlights
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

namespace lua_binds
{
    LUA_BIND_CLIENT(adddecal, {
        vec  center(e.get<double>(2), e.get<double>(3), e.get<double>(4));
        vec  surface(e.get<double>(5), e.get<double>(6), e.get<double>(7));
        bvec color(e.get<int>(9), e.get<int>(10), e.get<int>(11));

        adddecal(e.get<int>(1), center, surface, e.get<double>(8), color, e.get<int>(12));
    })

    LUA_BIND_CLIENT(particle_splash, {
        if (e.get<int>(1) == PART_BLOOD && !GETIV(blood)) return;
        vec p(e.get<double>(4), e.get<double>(5), e.get<double>(6));
        particle_splash(
            e.get<int>(1),
            e.get<int>(2),
            e.get<int>(3),
            p,
            e.get<int>(7),
            e.get<double>(8),
            e.get<int>(9),
            e.get<int>(10),
            e.get<bool>(11),
            e.get<int>(12),
            e.get<bool>(13),
            e.get<int>(14)
        );
    })

    LUA_BIND_CLIENT(regular_particle_splash, {
        if (e.get<int>(1) == PART_BLOOD && !GETIV(blood)) return;
        vec p(e.get<double>(4), e.get<double>(5), e.get<double>(6));
        regular_particle_splash(
            e.get<int>(1),
            e.get<int>(2),
            e.get<int>(3),
            p,
            e.get<int>(7),
            e.get<double>(8),
            e.get<int>(9),
            e.get<int>(10),
            e.get<int>(11),
            e.get<bool>(12),
            e.get<int>(13)
        );
    })

    LUA_BIND_CLIENT(particle_fireball, {
        vec dest(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        particle_fireball(dest, e.get<double>(4), e.get<int>(5), e.get<int>(6), e.get<int>(7), e.get<double>(8));
    })

    LUA_BIND_CLIENT(particle_explodesplash, {
        vec o(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        particle_explodesplash(o, e.get<int>(4), e.get<int>(5), e.get<int>(6), e.get<int>(7), e.get<int>(8), e.get<int>(9));
    })

    LUA_BIND_CLIENT(particle_flare, {
        vec p(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        vec dest(e.get<double>(4), e.get<double>(5), e.get<double>(6));
        if (e.get<int>(12) < 0)
            particle_flare(p, dest, e.get<int>(7), e.get<int>(8), e.get<int>(9), e.get<double>(10), NULL, e.get<int>(11));
        else
        {
            LogicEntityPtr owner = LogicSystem::getLogicEntity(e.get<int>(12));
            assert(owner.get()->dynamicEntity);
            particle_flare(p, dest, e.get<int>(7), e.get<int>(8), e.get<int>(9), e.get<double>(10), (fpsent*)(owner.get()->dynamicEntity), e.get<int>(11));
        }
    })

    LUA_BIND_CLIENT(particle_flying_flare, {
        vec p(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        vec dest(e.get<double>(4), e.get<double>(5), e.get<double>(6));
        particle_flying_flare(p, dest, e.get<int>(7), e.get<int>(8), e.get<int>(9), e.get<double>(10), e.get<int>(11));
    })

    LUA_BIND_CLIENT(particle_trail, {
        vec from(e.get<double>(3), e.get<double>(4), e.get<double>(5));
        vec to(e.get<double>(6), e.get<double>(7), e.get<double>(8));
        particle_trail(e.get<int>(1), e.get<int>(2), from, to, e.get<int>(9), e.get<double>(10), e.get<int>(11), e.get<bool>(12));
    })

    LUA_BIND_CLIENT(particle_flame, {
        regular_particle_flame(
            e.get<int>(1),
            vec(e.get<double>(2), e.get<double>(3), e.get<double>(4)),
            e.get<double>(5),
            e.get<double>(6),
            e.get<int>(7),
            e.get<int>(8),
            e.get<double>(9),
            e.get<double>(10),
            e.get<double>(11),
            e.get<int>(12)
        );
    })

    LUA_BIND_CLIENT(adddynlight, {
        vec o(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        vec color(float(e.get<double>(5))/255.0, float(e.get<double>(6))/255.0, float(e.get<double>(7))/255.0);
        vec initcolor(float(e.get<double>(12))/255.0, float(e.get<double>(13))/255.0, float(e.get<double>(14))/255.0);

        LightControl::queueDynamicLight(o, e.get<double>(4), color, e.get<int>(8), e.get<int>(9), e.get<int>(10), e.get<double>(11), initcolor, NULL);
    })

    LUA_BIND_CLIENT(spawndebris, {
        vec v(e.get<double>(2), e.get<double>(3), e.get<double>(4));
        vec debrisvel(e.get<double>(6), e.get<double>(7), e.get<double>(8));

        LogicEntityPtr owner = LogicSystem::getLogicEntity(e.get<int>(9));
        assert(owner->dynamicEntity);
        FPSClientInterface::spawnDebris(e.get<int>(1), v, e.get<int>(5), debrisvel, (dynent*)(owner->dynamicEntity));
    })

    LUA_BIND_CLIENT(particle_meter, {
        vec s(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        particle_meter(s, e.get<double>(4), e.get<int>(5), e.get<int>(6));
    })

    LUA_BIND_CLIENT(particle_text, {
        vec s(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        particle_textcopy(s, e.get<const char*>(4), e.get<int>(5), e.get<int>(6), e.get<int>(7), e.get<double>(8), e.get<int>(9));
    })

    LUA_BIND_CLIENT(client_damage_effect, {
        ((fpsent*)player)->damageroll(e.get<int>(1));
        damageblend(e.get<int>(2));
    })

    LUA_BIND_CLIENT(showhudrect,  ClientSystem::addHUDRect (e.get<double>(1), e.get<double>(2), e.get<double>(3), e.get<double>(4), e.get<int>(5), e.get(6, 1.0));)
    LUA_BIND_CLIENT(showhudimage, ClientSystem::addHUDImage(e.get<const char*>(1), e.get<double>(2), e.get<double>(3), e.get<double>(4), e.get<double>(5), e.get(6, 0xFFFFFF), e.get(7, 1.0));)

    // text, x, y, scale, color
    LUA_BIND_CLIENT(showhudtext, ClientSystem::addHUDText(e.get<const char*>(1), e.get<double>(2), e.get<double>(3), e.get<double>(4), e.get<int>(5));)
}
