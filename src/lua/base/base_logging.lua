---
-- base_logging.lua, version 1<br/>
-- Logging system for Lua<br/>
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

local logging = require("logging")

--- Logging for CubeCreate. Logs messages using C++ logger on various loglevels.
-- Available levels are INFO (rarely printed by default, should be used for things
-- that are logged often), DEBUG (less rarely logged), WARNING, and ERROR (always logged)
-- Only ERROR is logged by default, you can change logging level in config file in your
-- CubeCreate configuration directory. Log function and the levels are wrapped as globals.
-- @class module
-- @name cc.logging
module("cc.logging")

--- Logs a message into C++ logging system.<br/>
-- There are several logging levels:<br/><br/>
-- <strong>ERROR</strong> - Logs message as error, prints into console.<br/>
-- <strong>WARNING</strong> - Logs message as warning, prints into terminal.<br/>
-- <strong>DEBUG</strong> - Logs message as debug, doesn't print into terminal unless you've got your loglevel set to DEBUG.<br/>
-- <strong>INFO</strong> - Use this when you want to log a message repeating i.e. every frame.<br/>
-- @param l The logging level to use for the message
-- @param m The message itself. Use string.format if you want to format it.
-- @class function
-- @name log
log = logging.log

INFO = logging.INFO
DEBUG = logging.DEBUG
WARNING = logging.WARNING
ERROR = logging.ERROR

--- Prints something on console.<br/>
-- Useful for printing various console messages, like reports: Unlike logging, this has no level.<br/><br/>
-- @param m The message. Use string.format if you want to format it.
-- @class function
-- @name echo
echo = logging.echo
