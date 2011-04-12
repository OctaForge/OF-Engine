/*
 * luabind_messages.hpp, version 1
 * Message system binds for Lua
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
    using namespace MessageSystem;

    LUA_BIND_DEF(personal_servmsg, send_PersonalServerMessage(
        e.get<int>(1),
        e.get<int>(2),
        e.get<const char*>(3),
        e.get<const char*>(4));
    )
    LUA_BIND_DEF(particle_splash_toclients, send_ParticleSplashToClients(
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<int>(4),
        e.get<double>(5),
        e.get<double>(6),
        e.get<double>(7));
    )
    LUA_BIND_DEF(particle_regularsplash_toclients, send_ParticleSplashToClients(
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<int>(4),
        e.get<double>(5),
        e.get<double>(6),
        e.get<double>(7));
    )
    LUA_BIND_DEF(sound_toclients_byname, send_SoundToClientsByName(
        e.get<int>(1),
        e.get<double>(2),
        e.get<double>(3),
        e.get<double>(4),
        e.get<const char*>(5),
        e.get<int>(6));
    )
    LUA_BIND_DEF(statedata_changerequest, send_StateDataChangeRequest(
        e.get<int>(1),
        e.get<int>(2),
        e.get<const char*>(3));
    )
    LUA_BIND_DEF(statedata_changerequest_unreliable, send_UnreliableStateDataChangeRequest(
        e.get<int>(1),
        e.get<int>(2),
        e.get<const char*>(3));
    )
    LUA_BIND_DEF(notify_numents, send_NotifyNumEntities(e.get<int>(1), e.get<int>(2));)
    LUA_BIND_DEF(le_notification_complete, send_LogicEntityCompleteNotification(
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<const char*>(4),
        e.get<const char*>(5));
    )
    LUA_BIND_DEF(le_removal, send_LogicEntityRemoval(e.get<int>(1), e.get<int>(2));)
    LUA_BIND_DEF(statedata_update, send_StateDataUpdate(
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<const char*>(4),
        e.get<int>(5));
    )
    LUA_BIND_DEF(statedata_update_unreliable, send_UnreliableStateDataUpdate(
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<const char*>(4),
        e.get<int>(5));
    )
    LUA_BIND_DEF(do_click, send_DoClick(
        e.get<int>(1),
        e.get<int>(2),
        e.get<double>(3),
        e.get<double>(4),
        e.get<double>(5),
        e.get<int>(6));
    )
    LUA_BIND_DEF(extent_notification_complete, send_ExtentCompleteNotification(
        e.get<int>(1),
        e.get<int>(2),
        e.get<const char*>(3),
        e.get<const char*>(4),
        e.get<double>(5),
        e.get<double>(6),
        e.get<double>(7),
        e.get<int>(8),
        e.get<int>(9),
        e.get<int>(10),
        e.get<int>(11));
    )

    LUA_BIND_DEF(signalcomp, {
        try
        {
            REFLECT_PYTHON( signal_signal_component );
            boost::python::object data = signal_signal_component(e.get<const char*>(1), e.get<const char*>(2));
            e.push(boost::python::extract<const char*>(data));
        }
        catch(boost::python::error_already_set const &)
        {
            printf("Error in signalling python component initialization\r\n");
            PyErr_Print();
            assert(0 && "Halting on Python error");
        }
    })
}
