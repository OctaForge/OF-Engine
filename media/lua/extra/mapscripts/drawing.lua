--[[! File: lua/extra/mapscripts/drawing.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        A test "game" for OctaForge that lets you draw on the world geometry.
        Left click to draw, right click to stop drawing, middle click to change
        colors.
]]

local log = require("core.logger")

local input = require("core.engine.input")
local var = require("core.engine.var")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local conv = require("core.lua.conv")
local particles = require("core.engine.particles")

local splash, flare = particles.splash, particles.flare
local quadrenderer, taperenderer = particles.register_renderer_quad,
    particles.register_renderer_tape

local hextorgb = conv.hex_to_rgb

local game_manager = require("extra.game_manager")

local connect = signal.connect
local Vec4 = require("core.lua.math").Vec4
local ipairs = ipairs

local colors = {
    0xFFFFFF, 0xFF0000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF, 0xFF00FF
}

local Player = ents.Player

local SPARK, STREAK
if not SERVER then
    SPARK = quadrenderer("spark", "media/particle/spark",
        bit.bor(particles.flags.FLIP, particles.flags.BRIGHT))
    STREAK = taperenderer("streak", "media/particle/flare",
        particles.flags.BRIGHT)
end

--[[! Class: Game_Player
    This serves as a base for our player. It defines all the basic entry
    points for the drawing game.

    The property new_mark contains mark data. It's required because it has
    to sync over the server (e.g. in coop).
]]
local Game_Player = Player:clone {
    name = "Game_Player",

    properties = {
        new_mark = svars.State_Array_Float {
            client_set = true, has_history = false
        }
    },

    -- a property setting example
    init = function(self, ...)
        Player.init(self, ...)
        self:set_attr("jump_velocity", 250)
    end,

    next_color = function(self)
        if  self.color_id < #colors then
            self.color_id = self.color_id + 1
        else
            self.color_id = 1
        end
        self.color = colors[self.color_id]
        log.echo(("color switch: 0x%.6X"):format(self.color))
    end,

    reset_mark = function(self)
        self:set_attr("new_mark", { -1, -1, -1 })
        self.stop_batch = true
    end,

    --[[! Function: activate
        Called on entity activation. Connects a callback to state data
        change of new_mark.
    ]]
    activate = (not SERVER) and function(self, kwargs)
        Player.activate(self, kwargs)
        self.marks = {}
        self.color_id = 1
        self.color    = colors[1]
        connect(self, "new_mark_changed", function(self, nm)
            if #nm == 3 then
                nm = Vec4(nm[1], nm[2], nm[3], self.color)
            else
                nm = nil
            end
            local marks = self.marks
            marks[#marks + 1] = nm
        end)
    end or nil,

    --[[! Function: run
        Called every frame. It goes over the marks and draws everything.
    ]]
    run = (not SERVER) and function(self, millis)
        Player.run(self, millis)
        local last = nil
        local marks = self.marks

        for i, mark in ipairs(marks) do
            if last and mark and mark.x >= 0 and last.x >= 0 then
                local r, g, b = hextorgb(mark.w)
                flare(STREAK, mark, last, r / 255, g / 255, b / 255, 0, 1)
                flare(STREAK, last, mark, r / 255, g / 255, b / 255, 0, 1)
            end
            last = mark
        end

        local newb = #marks == 0 or not marks[#marks - 1]
        local conb = #marks  > 0 and    marks[#marks - 1]

        if conb and not self.stop_batch then
            local mark = marks[#marks - 1]
            local r, g, b = hextorgb(mark.w)
            splash(SPARK, mark, 25, 10, r / 255, g / 255, b / 255, 150, 1, 1)
        end

        if self.pressing then
            local newp = input.get_target_position()
            local topl = self:get_attr("position"):sub_new(newp)
            newp:add(topl:normalize())
            if newb or not marks[#marks - 1]:is_close_to(newp, 5) then
                self:set_attr("new_mark", newp:to_array())
            end
        end
    end or nil
}

ents.register_class(Game_Player, { game_manager.player_plugin })

if not SERVER then
    _C.external_set("input_click_client",
        function(btn, down, x, y, z, ent, cx, cy)
            if ent and ent.click then
                return ent:click(btn, down, x, y, z, cx, cy)
            end
            if btn == 1 then
                ents.get_player().pressing   = down
                ents.get_player().stop_batch = false
            elseif btn == 2 and down then
                ents.get_player():reset_mark()
            elseif btn == 3 and down then
                ents.get_player():next_color()
            end
        end)
end

var.set("player_class", "Game_Player")
