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

    Section: Entity class system
]]

--[[!
    Package: entity_classes
    This module handles entity class system such as registration, getting, listing ...
]]
module("entity_classes", package.seeall)

_entity_classes = {}

--- Register entity class. Registers a given entity class into storage
-- and generates protocol data.
-- @param _cl The entity class to register.
-- @param st Sauer type of the entity. It's "fpsent" for dynamic entities and specific for static entities.
-- @return Entity class you're registering.
function reg(_cl, st)
    local _cln = _cl._class

    logging.log(logging.DEBUG, "registering LE class: " .. tostring(_cln))

    st = st or ""

    -- store in registry
    assert(not _entity_classes[tostring(_cln)], "must not exist already, ensure each class has a different _class.")
    _entity_classes[tostring(_cln)] = { _cl, st }

    -- generate protocol data
    local proptable = {}
    local base = _cl
    while base do
        if base.properties then
            for name, var in pairs(base.properties) do
                if not proptable[name] and state_variables.is(var) then
                    proptable[name] = var
                end
            end
        end
        if base == entity.base_root then break end
        base = base.__base
    end
    local sv_names = table.keys(proptable)
    table.sort(sv_names, function(n1, n2)
        if state_variables.is_alias(proptable[n1]) and not
           state_variables.is_alias(proptable[n2]) then return false
        end
        if not state_variables.is_alias(proptable[n1])
           and state_variables.is_alias(proptable[n2]) then return true
        end
        return (n1 < n2)
    end)

    logging.log(logging.DEBUG, "generating protocol data for { " .. table.concat(sv_names, ", ") .. " }")
    message.genprod(tostring(_cln), sv_names)

    return _cl
end

--- Get entity class, knowing its name.
-- @param _cn Entity class name.
-- @return The entity class if found, false otherwise.
function get_class(_cn)
    if _entity_classes[tostring(_cn)] then
        return _entity_classes[tostring(_cn)][1]
    else
        logging.log(logging.ERROR, "invalid class: " .. tostring(_cn))
        return nil
    end
end

--- Get sauer type of entity class, knowing its name.
-- @param _cn Entity class name.
-- @return Entity class' sauer type if found, false otherwise.
function get_sauer_type(_cn)
    if _entity_classes[tostring(_cn)] then
        return _entity_classes[tostring(_cn)][2]
    else
        logging.log(logging.ERROR, "invalid class: " .. tostring(_cn))
        return nil
    end
end

--- List entity classes.
-- @return Table (array) of entity class names.
function list()
    local r = table.values(table.filter(table.keys(_entity_classes), function(k, v) local c = get_class(v); return c and c.sauer_type and c.sauer_type ~= "fpsent" end))
    table.sort(r)
    return r
end
