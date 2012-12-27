--[[! File: library/core/std/gui/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (GUI system).
]]

#log(DEBUG, ":::: Core UI implementation.")

local sets = {}

gui = {
    core = require "std.gui.core",

    get_sets = function() return sets end,
    get_set  = function(name)
        return themes[name]
    end,

    register_set   = function(name, set)
        sets[name] = set
    end
}

sets["default"] = require "std.gui.default"

var.new("uiset", var.STRING, "default")

setmetatable(gui, {
    __index = function(self, n)
        print("index")
        -- try regular members first
        local v = rawget(self, n)
        if    v ~= nil then return v end

        -- try a set otherwise
        v = sets[EV.uiset]
        if v then return v[n] end
    end
})
print(gui.Window)
