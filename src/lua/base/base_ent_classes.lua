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

_logent_classes = {}

--- Register entity class. Registers a given entity class into storage
-- and generates protocol data.
-- @param _cl The entity class to register.
-- @param st Sauer type of the entity. It's "fpsent" for dynamic entities and specific for static entities.
-- @return Entity class you're registering.
function reg(_cl, st)
    local _cln = _cl._class

    logging.log(logging.DEBUG, "registering LE class: " .. tostring(_cln))

    if not st then
        local _base = _cl.__base
        while _base do
            local _pn = __class
            logging.log(logging.DEBUG, "finding sauertype in parent: " .. tostring(_pn))
            local stype = get_sauertype(_pn)
            if stype then
                st = stype
                break
            else
                _base = ____class and ___base or nil
            end
        end
    end
    st = st or ""

    -- store in registry
    assert(not _logent_classes[tostring(_cln)], "must not exist already, ensure each class has a different _class.")
    _logent_classes[tostring(_cln)] = { _cl, st }

    -- generate protocol data
    local sv_names = {}

    local inst = _cl()
    for i = 1, #inst.properties do
        local var = inst.properties[i][2]
        logging.log(logging.INFO, "considering " .. tostring(inst.properties[i][1]) .. " -- " .. tostring(var))
        if state_variables.is(var) then
            logging.log(logging.INFO, "setting up " .. tostring(inst.properties[i][1]))
            table.insert(sv_names, tostring(inst.properties[i][1]))
        end
    end

    logging.log(logging.DEBUG, "generating protocol data for { " .. table.concat(sv_names, ", ") .. " }")
    message.genprod(tostring(_cln), sv_names)

    return _cl
end

--- Get entity class, knowing its name.
-- @param _cn Entity class name.
-- @return The entity class if found, false otherwise.
function get_class(_cn)
    if _logent_classes[tostring(_cn)] then
        return _logent_classes[tostring(_cn)][1]
    else
        logging.log(logging.ERROR, "invalid class: " .. tostring(_cn))
        return nil
    end
end

--- Get sauer type of entity class, knowing its name.
-- @param _cn Entity class name.
-- @return Entity class' sauer type if found, false otherwise.
function get_sauertype(_cn)
    if _logent_classes[tostring(_cn)] then
        return _logent_classes[tostring(_cn)][2]
    else
        logging.log(logging.ERROR, "invalid class: " .. tostring(_cn))
        return nil
    end
end

--- List entity classes.
-- @return Table (array) of entity class names.
function list()
    local r = table.values(table.filter(table.keys(_logent_classes), function(k, v) local c = get_class(v); return c and c._sauertype and c._sauertype ~= "fpsent" end))
    table.sort(r)
    return r
end
