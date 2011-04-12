---
-- init.lua, version 1
-- Loader for core Lua library.
--
-- @author q66 (quaker66@gmail.com)
-- license: MIT/X11
--
-- @copyright 2011 CubeCreate project
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

package.path = package.path .. ";./src/lua/?.lua;./src/lua/?/init.lua;./?/init.lua"

--[[
function trace (event, line)
      local s = debug.getinfo(2, "nSl")
      print("DEBUG:")
      print("    " .. tostring(s.name))
      print("    " .. tostring(s.namewhat))
      print("    " .. tostring(s.source))
      print("    " .. tostring(s.short_src))
      print("    " .. tostring(s.linedefined))
      print("    " .. tostring(s.lastlinedefined))
      print("    " .. tostring(s.what))
      print("    " .. tostring(s.currentline))
    end
    
debug.sethook(trace, "c")
]]

-- Logging comes first.
require("base.base_logging")
-- Globally wrap some logging stuff because it's often used.
log = cc.logging.log
INFO = cc.logging.INFO
DEBUG = cc.logging.DEBUG
WARNING = cc.logging.WARNING
ERROR = cc.logging.ERROR
echo = cc.logging.echo

cc.logging.log(cc.logging.DEBUG, "Initializing language extensions.")
require("language")

cc.logging.log(cc.logging.DEBUG, "Initializing base.")
require("base")

cc.logging.log(cc.logging.DEBUG, "Core scripting initialization complete.")
