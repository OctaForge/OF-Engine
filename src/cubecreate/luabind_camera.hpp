/*
 * luabind_camera.hpp, version 1
 * Camera control for Lua
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
    LUA_BIND_CLIENT(forcecam, {
        vec position(e.get<float>(1), e.get<float>(2), e.get<float>(3));
        CameraControl::forceCamera(position, e.get<float>(4), e.get<float>(5), e.get<float>(6), e.get<float>(7));
    })

    LUA_BIND_CLIENT(forcepos, {
        vec position(e.get<float>(1), e.get<float>(2), e.get<float>(3));
        CameraControl::forcePosition(position);
    })

    LUA_BIND_STD_CLIENT(forceyaw, CameraControl::forceYaw, e.get<float>(1))
    LUA_BIND_STD_CLIENT(forcepitch, CameraControl::forcePitch, e.get<float>(1))
    LUA_BIND_STD_CLIENT(forceroll, CameraControl::forceRoll, e.get<float>(1))
    LUA_BIND_STD_CLIENT(forcefov, CameraControl::forceFov, e.get<float>(1))
    LUA_BIND_STD_CLIENT(resetcam, CameraControl::positionCamera, CameraControl::getCamera())

    LUA_BIND_CLIENT(getcam, {
        physent *camera = CameraControl::getCamera();
        e.t_new()
            .t_set("position", camera->o)
            .t_set("yaw", camera->yaw)
            .t_set("pitch", camera->pitch)
            .t_set("roll", camera->roll);
    })

    LUA_BIND_CLIENT(getcampos, {
        physent *camera = CameraControl::getCamera();
        e.push(camera->o);
    })

    LUA_BIND_STD_CLIENT(caminc, CameraControl::incrementCameraDist, +1)
    LUA_BIND_STD_CLIENT(camdec, CameraControl::incrementCameraDist, -1)
    LUA_BIND_STD_CLIENT(mouselook, GuiControl::toggleMouselook)
    LUA_BIND_STD_CLIENT(characterview, GuiControl::toggleCharacterViewing)
}
