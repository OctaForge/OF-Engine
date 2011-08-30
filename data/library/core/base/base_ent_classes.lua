--[[!
    File: base/base_ent_classes.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features entity class system.
]]

--[[!
    Package: entity_classes
    This module handles entity class system such
    as registration, getting, listing ...
]]
module("entity_classes", package.seeall)

--[[!
    Variable: class_storage
    Here, all registered entity classes are stored.
    It's accessible from outside.
]]
class_storage = {}

--[[!
    Function: register
    Registers entity class into <class_storage>
    and generates proper protocol data.

    Available sauer types for static entities are "light", "mapmodel",
    "playerstart", "envmap", "particles", "sound" and "spotlight".
    If you're registering static entity, select whichever fits best your entity
    (or look at sauer type of entity you're inheriting).

    Parameters:
        class - the class to register.
        sauer_type - class' sauer type, it's "fpsent" for dynamic entities and
        for static entities, it's specific. If not specified, the registered
        entity class won't be treated as sauer entity.
]]
function register(class, sauer_type)
    -- get the class name
    local class_name = class.name

    logging.log(logging.DEBUG, "registering LE class: " .. class_name)

    -- default sauer type to empty (nonsauer entity)
    sauer_type = sauer_type or ""

    -- store in class_storage, assert non-existance
    assert(
        not class_storage[class_name],
        "must not exist already, ensure each class has a different name."
    )
    class_storage[class_name] = { class, sauer_type }

    -- generate protocol data - first create table of properties
    local proptable = {}

    -- save the class as "base"
    local base = class
    -- loop deeper into parents until there is no other parent
    while base do
        -- if the class has properties, loop them
        if base.properties then
            for name, var in pairs(base.properties) do
                -- if we have a state variable and it wasn't already
                -- inserted by children, insert it into proptable
                if not proptable[name]
                   and state_variables.is_state_variable(var) then
                    proptable[name] = var
                end
            end
        end
        -- save iteration
        if base == entity.base_root then break end
        -- go deeper
        base = base.__base
    end

    -- get a list of names from proptable
    local sv_names = table.keys(proptable)
    -- sort them so they're sorted by name and variable aliases come last
    table.sort(sv_names, function(n1, n2)
        -- if first is alias and second is not, leave alias last
        if state_variables.is_state_variable_alias(proptable[n1]) and not
           state_variables.is_state_variable_alias(proptable[n2]) then
           return false
        end
        -- if first is not alias and second is, leave alias last
        if not state_variables.is_state_variable_alias(proptable[n1])
           and state_variables.is_state_variable_alias(proptable[n2]) then
           return true
        end
        -- if both are aliases or both are state variables, sort by name
        return (n1 < n2)
    end)

    logging.log(
        logging.DEBUG,
        "generating protocol data for { "
            .. table.concat(sv_names, ", ")
            .. " }"
    )
    -- generate protocol data
    message.generate_protocol_data(tostring(class_name), sv_names)

    -- return the class
    return class
end

--[[!
    Function: get_class
    Returns entity class of given name (or logs
    an error message and returns nil if it doesn't exist)

    Parameters:
        class_name - name of the class to get.
]]
function get_class(class_name)
    if class_storage[class_name] then
        return class_storage[class_name][1]
    else
        logging.log(logging.ERROR, "invalid class: " .. class_name)
        return nil
    end
end

--[[!
    Function: get_sauer_type
    Returns sauer type of entity class of given name (or logs
    an error message and returns nil if the class doesn't exist)

    Parameters:
        class_name - name of the class to get sauertype of.
]]
function get_sauer_type(class_name)
    if class_storage[class_name] then
        return class_storage[class_name][2]
    else
        logging.log(logging.ERROR, "invalid class: " .. class_name)
        return nil
    end
end

--[[!
    Function: list
    Returns an array of entity class names
    from <class_storage> sorted by name.
    Dynamic entity classes get skipped.
]]
function list()
    local r = table.values(
        table.filter_dict(
            table.keys(class_storage),
            function(k, v)
                local c = get_class(v)
                return c and c.sauer_type and c.sauer_type ~= "fpsent"
            end
        )
    )
    table.sort(r)
    return r
end
