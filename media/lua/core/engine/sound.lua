--[[! File: lua/core/engine/camera.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Sound related functions. Relevant only clientside.
]]

if SERVER then return {} end

local capi = require("capi")

local play = capi.sound_play
local vec3 = require("core.lua.math").Vec3

return {
    --[[! Function: play
        Plays a sound. Accepts the sound name, a position (which is a vec3 and
        defaults to 0, 0, 0) and volume (which is a number defaulting to 100).
    ]]
    play = function(name, pos, volume)
        if not name then return nil end
        pos = pos or vec3(0, 0, 0)
        play(name, pos.x, pos.y, pos.z, volume)
    end,

    --[[! Function: stop
        Stops a sound. Accepts the sound name and its volume (which defaults
        to 100).
    ]]
    stop = capi.sound_stop,

    --[[! Function: preload_map
        Preloads a map sound so that it doesn't have to be loaded on the fly
        later. That leads to better performance.
    ]]
    preload_map = capi.sound_preload_map,

    --[[! Function: preload_game
        Preloads a game sound so that it doesn't have to be loaded on the fly
        later. That leads to better performance.
    ]]
    preload_game = capi.sound_preload_game
}
