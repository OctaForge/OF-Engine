--[[! File: lua/extra/events/timers.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Timer objects for general use.
]]

local M = {}

--[[! Class: Timer
    A general use timer. It's not automatically managed - you have to simulate
    it yourself using the provided methods. That makes it flexible for various
    scenarios (where the timing is not managed by the general event loop).
]]
M.Timer = table.Object:clone {
    name = "Timer",

    --[[! Constructor: __init
        The constructor takes at least one additional argument, interval. It's
        time in seconds the timer should take until next repeated action. An
        additional third argument is a boolean which specifies whether to
        carry potential extra time to next iteration (if you "tick" with
        a too large value, the sum will be larger than the interval).
        This extra argument is saved as carry_over and defaults to false.
    ]]
    __init = function(self, interval, carry_over)
        self.interval   = interval
        self.carry_over = carry_over or false
        self.sum        = 0
    end,

    --[[! Function: tick
        Given a value in seconds, this simulates the timer. It adds the given
        value to an internal sum member. If that member is >= the interval,
        sum is reset to either zero or "sum - interval" (if carry_over is
        true) and this returns true. Otherwise this returns false.
    ]]
    tick = function(self, seconds)
        local sum = self.sum + seconds
        local interval = self.interval
        if sum >= interval then
            self.sum = self.carry_over and (sum - interval) or 0
            return true
        else
            self.sum = sum
            return false
        end
    end,

    --[[! Function: prime
        Manually sets sum to interval.
    ]]
    prime = function(self)
        self.sum = self.interval
    end
}

return M
