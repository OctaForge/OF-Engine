--[[!
    File: language/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file takes care of properly loading all modules of OctaForge
        Lua extension library.

        It loads:
        - Class system with simple inheritance
        - Math extensions (vec3, vec4, bit ops etc.)
        - Table extensions (merging, copying, filtering ..)
        - String extensions (splitting, template parsing)
        - Conversion system (colors - HSV/HSL/RGB/hex, types)

    Section: Language extensions initialization
]]

logging.log(logging.DEBUG, ":: Class system.")
require("language.mod_class")
logging.log(logging.DEBUG, ":: Math extensions.")
require("language.ext_math")
logging.log(logging.DEBUG, ":: Table extensions.")
require("language.ext_table")
logging.log(logging.DEBUG, ":: String extensions.")
require("language.ext_string")
logging.log(logging.DEBUG, ":: Conversion.")
require("language.mod_conv")
