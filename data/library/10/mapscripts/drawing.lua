-- OctaForge drawing application, allows drawing in 3D world.
-- left mouse button draws
-- middle changes color
-- right ends current line/curve
-- built on OF API v1
-- author: q66 <quaker66@gmail.com>

-- Create a custom player class
myplayer = class.new(character.player)
-- Set a class for storage lookup
myplayer._class = "myplayer"

myplayer.properties = {
    newmark = state_variables.state_array_float({ clientset = true, hashistory = false })
}

-- Switches color in entity
function myplayer:nextcolor()
    local len = #self.colors
    if self.colidx < len then
        self.colidx = self.colidx + 1
    else
        self.colidx = 1
    end
    self.color  = self.colors[self.colidx]
end

-- Creates a "dummy" mark to stop current line
function myplayer:resetmark()
    self.newmark   = {-1, -1, -1}
    self.stopbatch = true
end

-- This is called when new mark is created. It adds a point into a storage
-- Vec4's are used, first three elements for position, fourth for color.
function myplayer:on_newmark(mark)
    if #mark == 3 then
        mark = math.vec4(mark[1], mark[2], mark[3], self.color)
    else
        mark = nil
    end
    table.insert(self.marks, mark)
end

-- Called right after initialization on client
function myplayer:client_activate(kwargs)
    -- Call parent
    self.__base.client_activate(self, kwargs)
    -- Mark storage
    self.marks = {}

    -- Available colors
    self.colors = { 0xFF00FF, 0x00FF00, 0xFF0000, 0x0000FF, 0xFFFF00, 0x00FFFF }
    -- Current color index
    self.colidx = 1
    -- Current color
    self.color = self.colors[self.colidx]

    -- When newmark state variable is modified, let's call on_newmark.
    self:connect(state_variables.get_onmodify_prefix() .. "newmark", self.on_newmark)
end

-- Called every frame on client after initialization
function myplayer:client_act(sec)
    -- Call parent
    self.__base.client_act(self, sec)

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
    if conbatch and not self.stopbatch then
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
            self.newmark = newpos:as_array()
        end
    end
end

-- Register our custom player entity class into storage
entity_classes.reg(myplayer, "fpsent")

-- Override clientside click method.
-- When left mouse button is clicked, set pressing to down, and disable stopbatch.
-- When middle mouse button is clicked, change to next color.
-- When right mouse button is clicked, stop drawing current batch and go to new one.
function client_click(btn, down, pos, ent, x, y)
    if btn == 1 then
        entity_store.get_plyent().pressing  = down
        entity_store.get_plyent().stopbatch = false
    elseif btn == 2 and down then
        entity_store.get_plyent():resetmark()
    elseif btn == 3 and down then
        entity_store.get_plyent():nextcolor()
    end
end

-- Notify the engine that we're overriding player by setting engine variable
player_class = "myplayer"

-- This way you can disable gravity, not needed, default value is 200
-- world.gravity = 0
