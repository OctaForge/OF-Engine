--[[!
    File: library/10/plugins.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features plugin baker for OctaForge.

    Section: Plugins
]]

--[[!
    Package: plugins
    Plugin system that allows to plug tables into a class.
    Useful for i.e. merging custom functionality into existing
    entity class while making the entity able to execute both
    old and custom-defined actions.
]]
module("plugins", package.seeall)

--[[!
    Variable: __MODULAR_PREFIX
    With this, table of functions with their names defined by <slots>
    is prefixed in the new class.
]]
local __MODULAR_PREFIX = "__MODULAR_"

--[[!
    Function: bake
    Bakes functions from a table into a class.
    Items from <slots> are pre-checked, so
    if a class already contains the function,
    it's not only overriden - instead, all
    of those functions get called one by one.
    If an item from plugin is not included in
    <slots>, it simply overrides the old one.

    Parameters:
        _class - The class to merge plugins into.
        plugins - Array of plugins to bake in.

    Returns:
        A new class with the items baked inside.
]]
function bake(_class, plugins)
    local cldata     = {}
    local properties = {}

    --[[!
        Variable: slots
        A list of function names to perform checks for. If the plugin
        contains any of these, it won't simply override, instead it
        will call all available functions of this name one by one.
        For meaning of these functions, look into their base classes -
        <base_root>, <base_client>, <base_server>.

        Items:
            init
            activate
            client_activate
            deactivate
            client_deactivate
            act
            client_act
            render_dynamic
    ]]
    local slots = {
        "init",
        "activate",
        "client_activate",
        "deactivate",
        "client_deactivate",
        "act",
        "client_act",
        "render_dynamic"
    }

    for i, slot in pairs(slots) do
        local old = _class[slot]
        assert(not _class[__MODULAR_PREFIX .. _class._class .. slot])

        local callees = {}
        if old then
            table.insert(callees, old)
        end
        for d, plugin in pairs(plugins) do
            local possible = plugin[slot]
            if possible then
                table.insert(callees, possible)
            end
        end

        local skip = false
        skip = #callees == 0 and true or false
        skip = #callees == 1 and callees[1] == old and true or false
        if not skip then
            cldata[__MODULAR_PREFIX .. _class._class .. slot] = callees
            cldata[slot] = function(self, ...)
                local callees = self[__MODULAR_PREFIX .. _class._class .. slot]
                for i = 1, #callees do
                    callees[i](self, ...)
                end
            end
        end
    end

    -- non-slot functions and items - no check for overriding
    for i, plugin in pairs(plugins) do
        for name, item in pairs(plugin) do
            if type(item) ~= "function" or not table.find(slots, name) then
                if type(item) == "table" and name == "properties" then
                    if not properties then
                        properties = item
                    else
                        table.mergedicts(properties, item)
                    end
                else
                    cldata[name] = item
                end
            end
        end
    end

    local newclass = class.new(_class, cldata)
    newclass.properties = properties

    return newclass
end
