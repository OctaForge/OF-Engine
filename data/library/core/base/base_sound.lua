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

--[[!
    Function: play
    Plays a sound. If performed on the server, a message gets sent to
    client(s) to play the sound.

    Parameters:
        name - path to the sound (starting with data/sounds as current
        working directory). Can be a protocol ID (see <message>).
        position - sound position, optional, <math.vec3>.
        Defaults to <0, 0, 0>.
        volume - sound volume, optional, defaults to 100 (max volume).
        Ignored on server (TODO!).
        cn - server only argument, specifies client number to which
        to send a message to play the sound, defaults to
        <message.ALL_CLIENTS>.
]]
function play(name, position, volume, cn)
    -- defaults, we don't default volume since 0 is represented as
    -- 100 by the C API in this case
    position = position or math.vec3(0, 0, 0)

    if CLIENT then
        -- clientside behavior
        CAPI.playsoundname(
            name,
            position.x, position.y, position.z,
            volume
        )
    else
        -- TODO: don't send if client is too far to hear
        -- warn when using non-compressed names
        if #name > 2 then
            logging.log(
                logging.WARNING,
                string.format(
                    "Sending a sound '%s' to clients using"
                    .. " full string name. This should be done rarely,"
                    .. " for bandwidth reasons.",
                    name
                )
            )
        end

        cn = cn or message.ALL_CLIENTS
        message.send(
            cn, CAPI.sound_toclients_byname,
            position.x, position.y, position.z,
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
        <message.ALL_CLIENTS>.
]]
function stop(name, volume, cn)
    if CLIENT then
        CAPI.stopsoundname(name, volume)
    else
        -- warn when using non-compressed names
        if #name > 2 then
            logging.log(
                logging.WARNING,
                string.format(
                    "Sending a sound '%s' to clients using"
                    .. " full string name. This should be done rarely,"
                    .. " for bandwidth reasons.",
                    name
                )
            )
        end
        cn = cn or message.ALL_CLIENTS
        message.send(cn, CAPI.soundstop_toclients_byname, volume, name, -1)
    end
end

--[[!
    Function: play_music
    Plays music. Filename rules apply in the same way as for <play>.
    When the music ends, <music_callback> is called. See
    <set_music_handler>.

    Parameters:
        name - path to the music, see <play>.
]]
play_music = CAPI.music

--[[!
    Function: set_music_post_handler
    Sets music post handler function. It's a function that takes
    no arguments and is called after music played by <play_music>
    ends. It can for example trigger playing of next music file.
    It's executed from C++ via <music_callback>.

    Parameters:
        fun - the handler function.
]]
function set_music_post_handler(fun)
    music_post_handler = fun
end

--[[!
    Function: music_callback
    This function gets called from C++ and it executes the handler
    set by <set_music_post_handler> if there is any. It gets called
    after music played by <play_music> ends.
]]
function music_callback()
    if  music_post_handler then
        music_post_handler()
    end
end

--[[!
    Function: register
    Registers a sound slot. Used for core hardcoded sounds (TODO:
    get rid of any hardcoded sounds).

    Parameters:
        name - see <play>.
        volume - see <play>.
]]
register = CAPI.registersound

--[[!
    Function: reset
    Resets the sound system, including music, slots and others.
]]
reset = CAPI.resetsound

--[[!
    Function: preload
    Preloads a sound about which we know it'll be used, so it
    doesn't have to be loaded later during gameplay.

    This leads to better performance, as we can preload certain
    sounds on initialization.

    For arguments, see <register>.
]]
preload = CAPI.preloadsound
