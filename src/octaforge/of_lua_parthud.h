/*
 * of_lua_parthud.h, version 1
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

VARP(blood, 0, 1, 1);

namespace lua_binds
{
    LUA_BIND_CLIENT(adddecal, {
        adddecal(
            e.get<int>(1), e.get<vec>(2), e.get<vec>(3),
            e.get<double>(4), e.get<bvec>(5), e.get<int>(6)
        );
    })

    LUA_BIND_CLIENT(particle_splash, {
        if (e.get<int>(1) == PART_BLOOD && !blood) return;
        particle_splash(
            e.get<int>(1),
            e.get<int>(2),
            e.get<int>(3),
            e.get<vec>(4),
            e.get<int>(5),
            e.get<double>(6),
            e.get<int>(7),
            e.get<int>(8),
            e.get<bool>(9),
            e.get<int>(10),
            e.get<bool>(11),
            e.get<int>(12)
        );
    })

    LUA_BIND_CLIENT(regular_particle_splash, {
        if (e.get<int>(1) == PART_BLOOD && !blood) return;
        regular_particle_splash(
            e.get<int>(1),
            e.get<int>(2),
            e.get<int>(3),
            e.get<vec>(4),
            e.get<int>(5),
            e.get<double>(6),
            e.get<int>(7),
            e.get<int>(8),
            e.get<int>(9),
            e.get<bool>(10),
            e.get<int>(11)
        );
    })

    LUA_BIND_CLIENT(particle_fireball, {
        particle_fireball(e.get<vec>(1), e.get<double>(2), e.get<int>(3), e.get<int>(4), e.get<int>(5), e.get<double>(6));
    })

    LUA_BIND_CLIENT(particle_explodesplash, {
        particle_explodesplash(e.get<vec>(1), e.get<int>(2), e.get<int>(3), e.get<int>(4), e.get<int>(5), e.get<int>(6), e.get<int>(7));
    })

    LUA_BIND_CLIENT(particle_flare, {
        if (e.get<int>(8) < 0)
            particle_flare(e.get<vec>(1), e.get<vec>(2), e.get<int>(3), e.get<int>(4), e.get<int>(5), e.get<double>(6), NULL, e.get<int>(7));
        else
        {
            CLogicEntity *owner = LogicSystem::getLogicEntity(e.get<int>(8));
            assert(owner->dynamicEntity);
            particle_flare(e.get<vec>(1), e.get<vec>(2), e.get<int>(3), e.get<int>(4), e.get<int>(5), e.get<double>(6), (fpsent*)(owner->dynamicEntity), e.get<int>(7));
        }
    })

    LUA_BIND_CLIENT(particle_flying_flare, {
        particle_flying_flare(e.get<vec>(1), e.get<vec>(2), e.get<int>(3), e.get<int>(4), e.get<int>(5), e.get<double>(6), e.get<int>(7));
    })

    LUA_BIND_CLIENT(particle_trail, {
        particle_trail(e.get<int>(1), e.get<int>(2), e.get<vec>(3), e.get<vec>(4), e.get<int>(5), e.get<double>(6), e.get<int>(7), e.get<bool>(8));
    })

    LUA_BIND_CLIENT(particle_flame, {
        regular_particle_flame(
            e.get<int>(1),
            e.get<vec>(2),
            e.get<double>(3),
            e.get<double>(4),
            e.get<int>(5),
            e.get<int>(6),
            e.get<double>(7),
            e.get<double>(8),
            e.get<double>(9),
            e.get<int>(12)
        );
    })

    LUA_BIND_CLIENT(adddynlight, {
        queuedynlight(e.get<vec>(1), e.get<double>(2), e.get<vec>(3), e.get<int>(4), e.get<int>(5), e.get<int>(6), e.get<double>(7), e.get<vec>(8), NULL);
    })

    LUA_BIND_CLIENT(particle_meter, {
        particle_meter(e.get<vec>(1), e.get<double>(2), e.get<int>(3), e.get<int>(4));
    })

    LUA_BIND_CLIENT(particle_text, {
        particle_textcopy(e.get<vec>(1), e.get<const char*>(2), e.get<int>(3), e.get<int>(4), e.get<int>(5), e.get<double>(6), e.get<int>(7));
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
