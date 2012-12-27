--[[! File: library/core/std/events/frame.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Handles a single main loop frame from the scripting system.
        Further accessible as "frame".
]]

local current_frame      = 0
local current_time       = 0
local current_frame_time = 1
local last_millis        = 0
local queued_actions     = {}

--[[! Function: handle_frame
    Executed per frame from C++. It handles the current frame, meaning
    it first flushes the global action queue (see <queue_global_action>),
    then updates all the required timing vars (<get_frame>, <get_time>,
    <get_frame_time>, <get_last_millis>) and then runs on all available
    activated entities. External as "frame_handle".
]]
local handle_frame = function(seconds, lastmillis)
    local get_ents = ents.get_all

    #log(INFO, "frame.handle_frame: New frame")
    current_frame = current_frame + 1

    local queue = table.copy(queued_actions)
    queued_actions = {}

    for i = 1, #queue do queue[i]() end

    current_time       = current_time + seconds
    current_frame_time = seconds
    last_millis        = lastmillis

    #log(INFO, "frame.handle_frame: Acting on entities")

    for uid, entity in pairs(get_ents()) do
        local skip = false

        if entity.deactivated or not entity.per_frame then
            skip = true
        end

        if not skip then
            entity:run(seconds)
        end
    end
end
external.frame_handle = handle_frame

return {
    --[[! Function: get_frame
        Returns the current Lua frame count.
    ]]
    get_frame = function()
        return current_frame
    end,

    --[[! Function: get_time
        Returns the number of seconds elapsed since the scripting system init.
    ]]
    get_time = function()
        return current_time
    end,

    --[[! Function: get_frame_time
        Returns the current frame time in seconds.
    ]]
    get_frame_time = function()
        return current_frame_time
    end,

    --[[! Function: get_last_millis
        Returns the number of milliseconds since the last counter reset.
        If you want the total time, see <get_time>. Note that you'll have
        to multiply it by 1000 to get milliseconds.
    ]]
    get_last_millis = function()
        return last_millis
    end,

    --[[! Function: queue_global_action
        Queues an action (a simple function taking no arguments) for the
        next frame globally. It's a very simple mechanism, consisting
        of simple execution of everything in the queue when the next
        frame comes and clearing up the queue.
    ]]
    queue_global_action = function(action)
        queued_actions[#queued_actions + 1] = action
    end,

    handle_frame = handle_frame,

    --[[! Function: cache_by_delay
        Caches a function by a delay. That comes in handy if you need to
        execute something frequently, but not necessarily every frame.

        Takes the function (or a callable table) and a delay in seconds.
        Returns a function that you can further call every frame (or nil
        if a wrong argument is passed).
    ]]
    cache_by_delay = function(fun, delay)
        if type(fun) == "function" then
            fun = tocalltable(fun)
        end

        if type(fun) ~= "table" then
            return nil
        end

        fun.last_time = ((-delay) * 2)
        return function(...)
            if (current_time - fun.last_time) >= delay then
                fun.last_cached_val = fun(...)
                fun.last_time       = current_time
            end
            return fun.last_cached_val
        end
    end,

    --[[! Function: cache_by_frame
        Caches a function by frame. That means it won't get executed more than
        exactly once every frame, no matter how many times in a frame you call
        it. Returns a function you can further call as many times as you want
        every frame without making it execute more than once.
    ]]
    cache_by_frame = function(fun)
        if type(fun) == "function" then
            fun = tocalltable(fun)
        end

        if type(fun) ~= "table" then
            return nil
        end

        return function(...)
            if fun.last_frame ~= current_frame then
                fun.last_cached_val = fun(...)
                fun.last_frame = current_frame
            end
            return fun.last_cached_val
        end
    end
}
