---
-- base_appman.lua, version 1<br/>
-- Application manager for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local base = _G
local string = require("string")
local CAPI = require("CAPI")
local log = require("cc.logging")
local glob = require("cc.global")
local class = require("cc.class")
local lent = require("cc.logent")
local msgsys = require("cc.msgsys")
local sig = require("cc.signals")

--- Application manager for cC Lua interface.
-- @class module
-- @name cc.appman
module("cc.appman")

function set_appclass(_c)
    log.log(log.DEBUG, "appman: setting appclass to " .. base.tostring(_c))

    inst = _c()

    -- do not run init on client
    if glob.SERVER then inst:init() end

    log.log(log.DEBUG, "appman: instance is " .. base.tostring(inst))
end

application = class.new()
function application:__tostring() return "application" end

function application:init()
    log.log(log.WARNING, "application:init: You should override this, and there is no need to call the ancestor. This should never run.")
end

function application:get_pcclass()
    return "player"
end

function application:client_on_disconnect()
    log.log(log.WARNING, "application:client_on_disconnect: You should override this, and there is no need to call the ancestor. This should never run.")
end

function application:on_entoffmap(ent)
    log.log(log.WARNING, base.tostring(ent.uid) .. " has fallen off the map.")
end

function application:client_on_entoffmap(ent)
    log.log(log.WARNING, base.tostring(ent.uid) .. " has fallen off the map.")
end

function application:on_player_login(ply)
end

function application:do_movement(move, down)
    lent.store.get_plyent().move = move
end

function application:do_strafe(strafe, down)
    lent.store.get_plyent().strafe = strafe
end

function application:do_jump(down)
    if down then
        lent.store.get_plyent():jump()
    end
end

function application:do_yaw(yaw, down)
    lent.store.get_plyent().yawing = yaw
end

function application:do_pitch(pitch, down)
    lent.store.get_plyent().pitching = pitch
end

function application:do_mousemove(y, p)
    return { yaw = y, pitch = p }
end

function application:do_click(btn, down, pos, ent, x, y)
    if not self:client_click(btn, down, pos, ent, x, y) then
        local uid = ent and ent.uid or -1
        msgsys.send(CAPI.do_click, btn, down, pos.x, pos.y, pos.z, uid)
    end
end

function application:client_click(btn, down, pos, ent, x, y)
    if ent and ent.client_click then
        return ent:client_click(btn, down, pos, x, y)
    end
    return false
end

function application:click(btn, down, pos, ent)
    if ent and ent.click then
        return ent:click(btn, down, pos)
    end
    return false
end

function application:action_key(index, down)
    self:emit("action_key," .. base.tostring(index) .. "," .. base.tostring(down))
end

function application:get_sbtext()
    return {
        { -1, "No scoreboard text defined" },
        { -1, "This should be done in the application" }
    }
end

function application:get_crosshair()
    return "data/textures/hud/crosshair.png"
end

function application:handle_textmsg(uid, text)
    return false
end

sig.methods_add(application)

__dummy_application = class.new(application)
function __dummy_application:__tostring() return "__dummy_application" end

function __dummy_application:init()
    log.log(log.WARNING, "(init) appman.set_appclass was not called, this is __dummy_application running.")
    application.init(self)
end

function __dummy_application:get_pcclass()
    log.log(log.WARNING, "(get_pcclass) appman.set_appclass was not called, this is __dummy_application running.")
    return "player"
end

function __dummy_application:client_on_disconnect()
    log.log(log.WARNING, "(client_on_disconnect) appman.set_appclass was not called, this is __dummy_application running.")
    application.client_on_disconnect(self)
end

function __dummy_application:on_entoffmap(ent)
    log.log(log.WARNING, "(on_entoffmap) appman.set_appclass was not called, this is __dummy_application running.")
    application.on_entoffmap(self, ent)
end

function __dummy_application:client_on_entoffmap(ent)
    log.log(log.WARNING, "(client_on_entoffmap) appman.set_appclass was not called, this is __dummy_application running.")
    application.client_on_entoffmap(self, ent)
end

function __dummy_application:on_player_login(ply)
    log.log(log.WARNING, "(on_player_login) appman.set_appclass was not called, this is __dummy_application running.")
    application.on_player_login(self, ply)
end

function __dummy_application:do_click(...)
     log.log(log.WARNING, "(do_click) appman.set_appclass was not called, this is __dummy_application running.")
     application.do_click(self, ...)
end

function __dummy_application:client_click(...)
     log.log(log.WARNING, "(client_click) appman.set_appclass was not called, this is __dummy_application running.")
     application.client_click(self, ...)
end

function __dummy_application:click(...)
     log.log(log.WARNING, "(click) appman.set_appclass was not called, this is __dummy_application running.")
     application.click(self, ...)
end

function __dummy_application:action_key(index, down)
    log.log(log.WARNING, "(action_key) appman.set_appclass was not called, this is __dummy_application running.")
end

log.log(log.DEBUG, "Setting dummy application")
set_appclass(__dummy_application)
