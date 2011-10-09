-- Example script which draws a sine curve in the world procedurally.
-- built on OF API v1
-- author: q66 <quaker66@gmail.com>

-- Create a custom player class
myplayer = class.new(character.player, "myplayer")

-- Called right after initialization on client
function myplayer:client_activate(kwargs)
    -- Call the parent
    self.__base.client_activate(self, kwargs)
    -- Initialize a counter
    self.n = 1
    -- Move the player a bit more to the open space
    self.position.y = self.position.y + 100
end

-- Called every frame on client after initialization
function myplayer:client_act(sec)
    -- Call the parent
    self.__base.client_act(self, sec)
    -- Loop 1000 times
    if self.n <= 1000 then
        -- Calculate X position. Move everything a bit.
        self.position.x = self.n + 50
        -- Calculate Z position (vertical) - create a nice sine graph
        self.position.z = math.sin(math.rad(self.n) * 3) * 100 + 700

        -- Create cubes for X axis
        edit.procedural.create_cube(self.position.x, self.position.y, self.position.z, 1)
        -- Create cubes of the graph
        edit.procedural.create_cube(self.position.x, self.position.y, 700, 1)
        -- Increment the counter
        self.n = self.n + 1
    end
end

-- Register our custom player entity class into storage
entity_classes.register(myplayer, "fpsent")

-- Notify the engine that we're overriding player by setting engine variable
player_class = "myplayer"

-- This way you can disable gravity, not needed, default value is 200
-- world.gravity = 0
