---
-- base_logent_classes.lua, version 1<br/>
-- Logic entity classes management for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 OctaForge project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

--- This module takes care of logic entity classes.
-- @class module
-- @name of.logent.classes
module("of.logent.classes", package.seeall)

_logent_classes = {}

--- Register entity class. Registers a given entity class into storage
-- and generates protocol data.
-- @param _cl The entity class to register.
-- @param st Sauer type of the entity. It's "fpsent" for dynamic entities and specific for static entities.
-- @return Entity class you're registering.
function reg(_cl, st)
    local _cln = _cl._class

    of.logging.log(of.logging.DEBUG, "registering LE class: " .. tostring(_cln))

    if not st then
        local _base = _cl.__base
        while _base do
            local _pn = __class
            of.logging.log(of.logging.DEBUG, "finding sauertype in parent: " .. tostring(_pn))
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
        of.logging.log(of.logging.INFO, "considering " .. tostring(inst.properties[i][1]) .. " -- " .. tostring(var))
        if of.state_variables.is(var) then
            of.logging.log(of.logging.INFO, "setting up " .. tostring(inst.properties[i][1]))
            table.insert(sv_names, tostring(inst.properties[i][1]))
        end
    end

    of.logging.log(of.logging.DEBUG, "generating protocol data for { " .. table.concat(sv_names, ", ") .. " }")
    of.msgsys.genprod(tostring(_cln), sv_names)

    return _cl
end

--- Get entity class, knowing its name.
-- @param _cn Entity class name.
-- @return The entity class if found, false otherwise.
function get_class(_cn)
    if _logent_classes[tostring(_cn)] then
        return _logent_classes[tostring(_cn)][1]
    else
        of.logging.log(of.logging.ERROR, "invalid class: " .. tostring(_cn))
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
        of.logging.log(of.logging.ERROR, "invalid class: " .. tostring(_cn))
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
