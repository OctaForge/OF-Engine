--[[! File: lua/luacy/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Loads the Luacy language, a supetset of Lua (github: quaker66/luacy).
        This is not an OF project. This init file serves merely as a loader.
        Returns the parser module. It's loaded before any other OF library
        component so that it can be injected into the module loader for
        further use.
]]

return require("luacy.parser")
