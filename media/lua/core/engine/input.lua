--[[!<
    Input related engine functions. It's a clientside module.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

if SERVER then return {} end

local capi = require("capi")
local frame = require("core.events.frame")

local vec3 = require("core.lua.geom").Vec3

--! Module: input
return {
    --[[! Function: get_target_entity
        Returns the entity you're targeting.
    ]]
    get_target_entity = frame.cache_by_frame(capi.gettargetent),

    --[[! Function: set_target_entity
        Sets the entiyt you're targeting.
    ]]
    set_target_entity = capi.set_targeted_entity,

    --[[! Function: get_target_position
        Returns the position in the world you're targeting.
    ]]
    get_target_position = frame.cache_by_frame(function()
        return vec3(capi.gettargetpos())
    end),

    --[[! Function: save_mouse_position
        Saves the mouse position in an internal storage. That's later
        useful while editing (e.g. when inserting an entity).
    ]]
    save_mouse_position = capi.save_mouse_position
}
