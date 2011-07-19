--[[!
    File: base/base_sound.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features sound system.
]]

--[[!
    Package: sound
    This module controls sounds - registration, playing, stopping, music etc.
]]
module("sound", package.seeall)

--- Play sound, knowing the filename.
-- If done on the server, a message is sent to clients to play the sound.
-- @param n Path to the sound.
-- @param p Position as vec3, optional (defaults to 0,0,0)
-- @param v Sound volume (0 to 100, optional)
-- @param cn Client number (optional, server only, defaults to all clients)
function play(n, p, v, cn)
    p = p or math.vec3(0, 0, 0)

    if CLIENT then
        CAPI.playsoundname(n, p.x, p.y, p.z, v)
    else
        -- TODO: don't send if client is too far to hear
        -- warn when using non-compressed names
        if #n > 2 then
            logging.log(logging.WARNING, string.format("Sending a sound '%s' to clients using full string name. This should be done rarely, for bandwidth reasons.", n))
        end
        cn = cn or message.ALL_CLIENTS
        message.send(cn, CAPI.sound_toclients_byname, p.x, p.y, p.z, n, -1)
    end
end

--- Stop playing sound, knowing the filename.
-- If done on the server, a message is sent to clients to stop the sound.
-- @param n Path to the sound.
-- @param v Sound volume (0 to 100, optional)
-- @param cn Client number (optional, server only, defaults to all clients)
function stop(n, v, cn)
    if CLIENT then
        CAPI.stopsoundname(n, v)
    else
        -- warn when using non-compressed names
        if #n > 2 then
            logging.log(logging.WARNING, string.format("Sending a sound '%s' to clients using full string name. This should be done rarely, for bandwidth reasons.", n))
        end
        cn = cn or message.ALL_CLIENTS
        message.send(cn, CAPI.soundstop_toclients_byname, v, n, -1)
    end
end

--- Play music.
-- @param n Path to music.
-- @class function
-- @name playmusic
playmusic = CAPI.music

--- Set music handler. Starts playing immediately.
-- @param f Function representing music handler.
function setmusichandler(f)
    musichandler = f
    musiccallback() -- start playing now
end

--- Music callback. Called on playmusic from C++.
-- If there is music handler set, it calls it.
function musiccallback()
    if musichandler then
        musichandler()
    end
end

--- Register a sound. Used for hardcoded sounds. (TODO: do not hardcode sounds)
-- @param n Path to the sound in data/sounds.
-- @param v Volume of the sound (0 to 100, optional, defaults to 100)
-- @class function
-- @name register
register = CAPI.registersound

--- Reset sound slots. DEPRECATED. Entities are now using
-- real paths instead of preregistering.
-- @class function
-- @name reset
reset = CAPI.resetsound

--- Preload sound into slot. DEPRECATED. Entities are now using
-- real paths instead of preregistering.
-- @class function
-- @name preload
preload = CAPI.preloadsound
