-- OctaForge drawing application, allows drawing in 3D world.
-- left mouse button draws
-- middle changes color
-- right ends current line/curve
-- built on OF API v1
-- author: q66 <quaker66@gmail.com>

local input = require("core.engine.input")
local var = require("core.lua.var")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

-- set up "shoot mode" variable aloas, which will be persistent.
-- you can then toggle shooting and drawing from the console using this.
-- because it's persistent, your last state (drawing / shooting) will
-- be saved and applied the next run.
if not var.get("shoot_mode") then
    var.new("shoot_mode", var.INT, 0, 0, 1, var.PERSIST)
end

-- Register our custom player entity class into storage
ents.register_class(ents.Player, {
    game_manager.player_plugin,
    firing.plugins.protocol,
    firing.plugins.player,
    health.plugin,
    projectiles.plugin,
    chaingun.chaingun.plugin,
    {
        properties = {
            new_mark = svars.State_Array_Float { client_set = true, has_history = false }
        },

        -- player gun indexes and current gun
        init = function(self)
            self:set_attr("gun_indexes", { player_chaingun, player_rocket_launcher })
            self:set_attr("current_gun_index", player_chaingun)
        end,

        -- Switches color in entity
        next_color = function(self)
            local len = #self.colors
            if  self.color_id < len then
                self.color_id = self.color_id + 1
            else
                self.color_id = 1
            end
            self.color = self.colors[self.color_id]
        end,

        -- Creates a "dummy" mark to stop current line
        reset_mark = function(self)
            self:set_attr("new_mark", { -1, -1, -1 })
            self.stop_batch = true
        end,

        -- This is called when new mark is created. It adds a point into a storage.
        -- vec4's are used, first three elements for position, fourth for color.
        on_new_mark = function(self, mark)
            if #mark == 3 then
                mark = math.Vec4(mark[1], mark[2], mark[3], self.color)
            else
                mark = nil
            end
            local mrks = self.marks
            mrks[#mrks + 1] = mark
        end,

        -- Called right after initialization on client
        activate = (not SERVER) and function(self, kwargs)
            -- Mark storage
            self.marks    = {}

            -- Available colors
            self.colors   = {
                0xFFFFFF, 0xFF0000,
                0x00FF00, 0x0000FF,
                0xFFFF00, 0xFF00FF,
                0x00FFFF
            }
            -- Current color index
            self.color_id = 1
            -- Current color
            self.color    = self.colors[1]

            -- When new_mark state variable is modified, let's call on_new_mark.
            signal.connect(self, "new_mark_changed", self.on_new_mark)
        end or nil,

        -- Called every frame on client after initialization
        run = (not SERVER) and function(self, sec)
            -- Draw all marks.
            local last = nil

            for i, mark in pairs(self.marks) do
                if last and mark and mark.x >= 0 and last.x >= 0 then
                    effects.flare(effects.PARTICLE.STREAK, last, mark, 0, mark.w, 1.0)
                    effects.flare(effects.PARTICLE.STREAK, mark, last, 0, mark.w, 1.0)
                end
                last = mark
            end

            -- Check if to draw new batch, or continue
            local newbatch = #self.marks == 0 or not self.marks[#self.marks - 1]
            local conbatch = #self.marks >  0 and    self.marks[#self.marks - 1]

            -- If continuing and haven't just stopped, draw a spark at the end of last mark.
            if conbatch and not self.stop_batch then
                effects.splash(
                    effects.PARTICLE.SPARK, 10, 0.15,
                    self.marks[#self.marks - 1],
                    self.marks[#self.marks - 1].w,
                    1.0, 25, 1
                );
            end

            -- If we're pressing left mouse button, let's draw new stuff
            if self.pressing then
                local newpos = input.get_target_position()
                local toplyr = self:get_attr("position"):sub_new(newpos)
                newpos:add(toplyr:normalize():mul(1.0)) -- bring a little out of the scenery
                if newbatch or not self.marks[#self.marks - 1]:is_close_to(newpos, 5.0) then
                    self:set_attr("new_mark", newpos:to_array())
                end
            end
        end or nil
    }
}, "game_player")

-- set up a chaingun (non-projectile, repeating)
player_chaingun        = firing.register_gun(
    chaingun.chaingun(), "chaingun"
)
-- and a rocket launcher (projectile, non-repeating)
player_rocket_launcher = firing.register_gun(
    rocket_launcher.rocket_launcher(), "rocket_launcher"
)

-- Override clientside click method.
-- When left mouse button is clicked, set pressing to down, and disable stop_batch.
-- When middle mouse button is clicked, change to next color.
-- When right mouse button is clicked, stop drawing current batch and go to new one.
if not SERVER then
    _C.external_set("input_click_client", function(btn, down, x, y, z, ent, cx, cy)
        if ent and ent.click then
            return ent:click(btn, down, x, y, z, cx, cy)
        end

        if var.get("shoot_mode") == 1 then
            return firing.click(btn, down, x, y, z, ent, cx, cy)
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

-- Notify the engine that we're overriding player by setting engine variable
var.set("player_class", "game_player")

-- This way you can disable gravity, not needed, default value is 200
-- world.gravity = 0
