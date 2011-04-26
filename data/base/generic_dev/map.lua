skybox = "textures/sky/remus/sky01"

myplayer = of.class.new(of.character.player)
myplayer._class = "myplayer"
function myplayer:client_activate(kwargs)
    self.__base.client_activate(self, kwargs)
    self.n = 1
    self.position.y = self.position.y + 100
end
function myplayer:client_act(sec)
    self.__base.client_act(self, sec)
    if self.n <= 1000 then
        self.position.x = self.n + 50
        self.position.z = math.sin(math.rad(self.n) * 3) * 100 + 700
        self.n = self.n + 1

        of.world.editing_createcube(self.position.x, self.position.y, self.position.z, 1)
        of.world.editing_createcube(self.position.x, self.position.y, 700, 1)
    end
end

of.logent.classes.reg(myplayer, "fpsent")
of.engine_variables.new("player_class", of.engine_variables.VAR_S, "myplayer")

--of.world.gravity = 0

if of.global.SERVER then
    local entities = of.utils.readfile("./entities.json")
    of.logent.store.load_entities(entities)
end
