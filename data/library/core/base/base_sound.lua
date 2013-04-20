--[[!
    File: library/core/base/base_sound.lua

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

--[[!
    Function: play
    Plays a sound. If performed on the server, a message gets sent to
    client(s) to play the sound.

    Parameters:
        name - path to the sound (starting with data/sounds as current
        working directory). Can be a protocol ID (see <message>).
        position - sound position, optional, <vec3>.
        Defaults to <0, 0, 0>.
        volume - sound volume, optional, defaults to 100 (max volume).
        Ignored on server (TODO!).
        cn - server only argument, specifies client number to which
        to send a message to play the sound, defaults to
        <msg.ALL_CLIENTS>.
]]
function play(name, pos, volume, cn)
    if not name then return nil end
    -- defaults, we don't default volume since 0 is represented as
    -- 100 by the C API in this case
    pos = pos or math.Vec3(0, 0, 0)

    if CLIENT then
        -- clientside behavior
        _C.sound_play(name, pos.x, pos.y, pos.z, volume)
    else
        -- TODO: don't send if client is too far to hear
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
        msg.send(
            cn, _C.sound_toclients_byname,
            pos.x, pos.y, pos.z,
            name, -1
        )
    end
end

--[[!
    Function: play
    Stops a sound. If performed on the server, a message gets sent to
    client(s) to stop the sound.

    Parameters:
        name - path to the sound (starting with data/sounds as current
        working directory). Can be a protocol ID (see <message>).
        volume - sound volume, optional, defaults to 100 (max volume).
        cn - server only argument, specifies client number to which
        to send a message to play the sound, defaults to
        <msg.ALL_CLIENTS>.
]]
function stop(name, volume, cn)
    if CLIENT then
        _C.sound_stop(name, volume)
    else
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
        msg.send(cn, _C.soundstop_toclients_byname, volume, name, -1)
    end
end

--[[!
    Function: preload
    Preloads a sound about which we know it'll be used, so it
    doesn't have to be loaded later during gameplay.

    This leads to better performance, as we can preload certain
    sounds on initialization.

    For arguments, see <register>.
]]
preload = _C.sound_preload
