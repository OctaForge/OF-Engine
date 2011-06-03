-- OctaForge drawing application, allows drawing in 3D world.
-- left mouse button draws
-- middle changes color
-- right ends current line/curve
-- built on OF API v1
-- author: q66 <quaker66@gmail.com>

-- Register our custom player entity class into storage
entity_classes.reg(plugins.bake(
    character.player, {
        health.plugin,
        {
            _class = "game_player",

            properties = {
                new_mark = state_variables.state_array_float({ clientset = true, hashistory = false })
            },

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
                self.new_mark   = { -1, -1, -1 }
                self.stop_batch = true
            end,

            -- This is called when new mark is created. It adds a point into a storage.
            -- vec4's are used, first three elements for position, fourth for color.
            on_new_mark = function(self, mark)
                if #mark == 3 then
                    mark = math.vec4(mark[1], mark[2], mark[3], self.color)
                else
                    mark = nil
                end
                table.insert(self.marks, mark)
            end,

            -- Called right after initialization on client
            client_activate = function(self, kwargs)
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
                self:connect(state_variables.get_onmodify_prefix() .. "new_mark", self.on_new_mark)
            end,

            -- Called every frame on client after initialization
            client_act = function(self, sec)
                -- Draw all marks.
                local last = nil

                for i, mark in pairs(self.marks) do
                    if last and mark and mark.x >= 0 and last.x >= 0 then
                        effect.flare(effect.PARTICLE.STREAK, last, mark, 0, mark.w, 1.0)
                        effect.flare(effect.PARTICLE.STREAK, mark, last, 0, mark.w, 1.0)
                    end
                    last = mark
                end

                -- Check if to draw new batch, or continue
                local newbatch = #self.marks == 0 or not self.marks[#self.marks - 1]
                local conbatch = #self.marks >  0 and    self.marks[#self.marks - 1]

                -- If continuing and haven't just stopped, draw a spark at the end of last mark.
                if conbatch and not self.stop_batch then
                    effect.splash(
                        effect.PARTICLE.SPARK, 10, 0.15,
                        self.marks[#self.marks - 1],
                        self.marks[#self.marks - 1].w,
                        1.0, 25, 1
                    );
                end

                -- If we're pressing left mouse button, let's draw new stuff
                if self.pressing then
                    local newpos = utility.gettargetpos()
                    local toplyr = self.position:subnew(newpos)
                    newpos:add(toplyr:normalize():mul(1.0)) -- bring a little out of the scenery
                    if newbatch or not self.marks[#self.marks - 1]:iscloseto(newpos, 5.0) then
                        self.new_mark = newpos:as_array()
                    end
                end
            end
        }
    }
), "fpsent")

-- Override clientside click method.
-- When left mouse button is clicked, set pressing to down, and disable stop_batch.
-- When middle mouse button is clicked, change to next color.
-- When right mouse button is clicked, stop drawing current batch and go to new one.
function client_click(btn, down, pos, ent, x, y)
    if btn == 1 then
        entity_store.get_plyent().pressing   = down
        entity_store.get_plyent().stop_batch = false
    elseif btn == 2 and down then
        entity_store.get_plyent():reset_mark()
    elseif btn == 3 and down then
        entity_store.get_plyent():next_color()
    end
end

-- Notify the engine that we're overriding player by setting engine variable
player_class = "game_player"

-- This way you can disable gravity, not needed, default value is 200
-- world.gravity = 0
