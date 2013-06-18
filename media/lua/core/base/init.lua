--[[!
    File: lua/core/base/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file takes care of properly loading all modules of OctaForge
        base library.
]]

if not SERVER then
#log(DEBUG, ":: Effects.")
require("core.base.base_effects")
end
