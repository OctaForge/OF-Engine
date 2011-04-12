skybox = "textures/sky/remus/sky01"

if cc.global.SERVER then
    local entities = cc.utils.readfile("./entities.json")
    cc.logent.store.load_entities(entities)
end
