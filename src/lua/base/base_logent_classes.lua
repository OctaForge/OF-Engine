---
-- base_logent_classes.lua, version 1<br/>
-- Logic entity classes management for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
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

local base = _G
local table = require("table")
local log = require("cc.logging")
local svar = require("cc.state_variables")
local msgsys = require("cc.msgsys")

--- This module takes care of logic entity classes.
-- @class module
-- @name cc.logent.classes
module("cc.logent.classes")

_logent_classes = {}

function reg(_cl, st)
    local _cln = _cl._class

    log.log(log.DEBUG, "registering LE class: " .. base.tostring(_cln))

    if not st then
        local _base = _cl.__base
        while _base do
            local _pn = _base._class
            log.log(log.DEBUG, "finding sauertype in parent: " .. base.tostring(_pn))
            local found, stype = get_sauertype(_pn)
            if found then
                st = stype
                break
            else
                _base = _base.__base._class and _base.__base or nil
            end
        end
    end
    st = st or ""

    -- store in registry
    base.assert(not _logent_classes[base.tostring(_cln)], "must not exist already, ensure each class has a different _class.")
    _logent_classes[base.tostring(_cln)] = { _cl, st }

    -- generate protocol data
    local sv_names = {}

    local inst = _cl()
    for i = 1, #inst.properties do
        local var = inst.properties[i][2]
        log.log(log.INFO, "considering " .. base.tostring(inst.properties[i][1]) .. " -- " .. base.tostring(var))
        if svar.is(var) then
            log.log(log.INFO, "setting up " .. base.tostring(inst.properties[i][1]))
            table.insert(sv_names, base.tostring(inst.properties[i][1]))
        end
    end

    log.log(log.DEBUG, "generating protocol data for { " .. table.concat(sv_names, ", ") .. " }")
    msgsys.genprod(base.tostring(_cln), sv_names)

    return _cl
end

function get_class(_cn)
    if _logent_classes[base.tostring(_cn)] then
        return true, _logent_classes[base.tostring(_cn)][1]
    else
        log.log(log.ERROR, "invalid class: " .. base.tostring(_cn))
        return false, nil
    end
end

function get_sauertype(_cn)
    if _logent_classes[base.tostring(_cn)] then
        return true, _logent_classes[base.tostring(_cn)][2]
    else
        log.log(log.ERROR, "invalid class: " .. base.tostring(_cn))
        return false, nil
    end
end

function list()
    local r = table.values(table.filter(table.keys(_logent_classes), function(k, v) local f, c = get_class(v); return f and c._sauertype and c._sauertype ~= "fpsent" end))
    table.sort(r)
    return r
end
