-- Example script which draws a sine curve in the world procedurally.
-- built on OF API v1
-- author: q66 <quaker66@gmail.com>

local edit = require("core.engine.edit")

-- Create a custom player class
myplayer = ents.Player:clone { name = "myplayer" }

-- Called right after initialization on client
if CLIENT then
function myplayer:activate(kwargs)
    -- Call the parent
    ents.Player.activate(self, kwargs)
    -- Initialize a counter
    self.n = 1
    -- Move the player a bit more to the open space
    self:get_attr("position").y = self:get_attr("position").y + 100
end

-- Called every frame on client after initialization
function myplayer:run(sec)
    -- Call the parent
    ents.Player.run(self, sec)
    -- Loop 1000 times
    if self.n <= 1000 then
        -- Calculate X position. Move everything a bit.
        self:get_attr("position").x = self.n + 50
        -- Calculate Z position (vertical) - create a nice sine graph
        self:get_attr("position").z = math.sin(math.rad(self.n) * 3) * 100 + 700

        -- Create cubes for X axis
        edit.create_cube(self:get_attr("position").x, self:get_attr("position").y, self:get_attr("position").z, 1)
        -- Create cubes of the graph
        edit.create_cube(self:get_attr("position").x, self:get_attr("position").y, 700, 1)
        -- Increment the counter
        self.n = self.n + 1
    end
end
end

-- Register our custom player entity class into storage
ents.register_class(myplayer)

-- Notify the engine that we're overriding player by setting engine variable
_V.player_class = "myplayer"

-- This way you can disable gravity, not needed, default value is 200
-- world.gravity = 0
