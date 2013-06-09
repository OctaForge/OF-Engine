--[[! File: lua/core/engine/camera.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Sound related functions.
]]

local msg = require("core.network.msg")

local type = type
local send = msg.send

local play = _C.sound_play
local sound_toclients = _C.sound_toclients
local sound_toclients_byname = _C.sound_toclients_byname
local sound_stop = _C.soundstop_toclients_byname

local vec3 = math.Vec3

return {
    --[[! Function: play
        Plays a sound. If called on the client, accepts the sound name, a
        position (which is a vec3 and defaults to 0, 0, 0) and volume (which
        is a number defaulting to 100).

        On the server it can also take a client number specifying the client
        it'll send the sound message to (which defaults to -1, all clients),
        otherwise the arguments are the same. The volume is ignored on
        the server for now (TODO).
    ]]
    play = CLIENT and function(name, pos, volume)
        if not name then return nil end
        pos = pos or vec3(0, 0, 0)
        play(name, pos.x, pos.y, pos.z, volume)
    end or function(name, pos, volume, cn)
        if not name then return nil end
        pos = pos or vec3(0, 0, 0)
        if #name > 2 then
            #log(WARNING,
            #    string.format(
            #        "Sending a sound '%s' to clients using"
            #        .. " full string name. This should be done rarely,"
            #        .. " for bandwidth reasons.",
            #        name
            #    )
            #)
        end
        send(cn or msg.ALL_CLIENTS, sound_toclients_byname,
            pos.x, pos.y, pos.z, name, -1)
    end,

    --[[! Function: stop
        Stops a sound. If called on the client, accepts the sound name
        and its volume (which defaults to 100). On the server it can also
        take the client number which has the same meaning as above.
    ]]
    stop = CLIENT and _C.sound_stop or function(name, volume, cn)
        if not name then return nil end
        -- warn when using non-compressed names
        if #name > 2 then
            #log(WARNING,
            #    string.format(
            #        "Sending a sound '%s' to clients using"
            #        .. " full string name. This should be done rarely,"
            #        .. " for bandwidth reasons.",
            #        name
            #    )
            #)
        end
        cn = cn or msg.ALL_CLIENTS
        msg.send(cn, sound_stop, volume, name, -1)
    end,

    --[[! Function: preload_map
        Preloads a map sound so that it doesn't have to be loaded on the fly
        later. That leads to better performance.
    ]]
    preload_map = _C.sound_preload_map,

    --[[! Function: preload_game
        Preloads a game sound so that it doesn't have to be loaded on the fly
        later. That leads to better performance.
    ]]
    preload_game = _C.sound_preload_game
}
