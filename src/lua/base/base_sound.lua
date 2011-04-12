---
-- base_sound.lua, version 1<br/>
-- Sound interface for Lua<br/>
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

local CAPI = require("CAPI")
local vec = require("cc.vector")
local glob = require("cc.global")
local msg = require("cc.msgsys")
local log = require("cc.logging")
local string = require("string")

--- Sound system for cC's Lua interface.
-- @class module
-- @name cc.sound
module("cc.sound")

--- Play sound knowing the filename.
-- If done on the server, a message is sent to clients to play the sound.
-- @param n Path to the sound.
-- @param p Position as vec3, optional (defaults to 0,0,0)
-- @param v Sound volume (0 to 100, optional)
-- @param cn Client number (optional, server only, defaults to all clients)
function play(n, p, v, cn)
    p = p or vec.vec3(0, 0, 0)

    if glob.CLIENT then
        CAPI.playsoundname(n, p.x, p.y, p.z, v)
    else
        -- TODO: don't send if client is too far to hear
        -- warn when using non-compressed names
        if #n > 2 then
            log.log(log.WARNING, string.format("Sending a sound '%s' to clients using full string name. This should be done rarely, for bandwidth reasons.", n))
        end
        cn = cn or msg.ALL_CLIENTS
        msg.send(cn, CAPI.sound_toclients_byname, p.x, p.y, p.z, n, -1)
    end
end

function stop(n, v, cn)
    if glob.CLIENT then
        CAPI.stopsoundname(n, v)
    else
        -- warn when using non-compressed names
        if #n > 2 then
            log.log(log.WARNING, string.format("Sending a sound '%s' to clients using full string name. This should be done rarely, for bandwidth reasons.", n))
        end
        cn = cn or msg.ALL_CLIENTS
        msg.send(cn, CAPI.soundstop_toclients_byname, v, n, -1)
    end
end

playmusic = CAPI.music

function setmusichandler(f)
    musichandler = f
    musiccallback() -- start playing now
end

function musiccallback()
    if musichandler then
        musichandler()
    end
end

register = CAPI.registersound
reset = CAPI.resetsound
preload = CAPI.preloadsound
