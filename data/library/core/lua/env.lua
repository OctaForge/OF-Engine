--[[! File: library/core/lua/env.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Provides additional utilities for environment management.
]]

local M = {}

--[[! Function: gen_mapscript_env
    Generates an environment for the mapscript. It's isolated from the outside
    world to some degree, providing some safety against potentially malicious
    code. Externally available as "mapscript_gen_env"
]]
M.gen_mapscript_env = function()
    -- safety? bah, we don't need no stinkin' safety
    return setmetatable({}, { __index = _G })
end
set_external("mapscript_gen_env", M.gen_mapscript_env)

return M
