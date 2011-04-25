skybox = "textures/sky/remus/sky01"

if of.global.SERVER then
    local entities = of.utils.readfile("./entities.json")
    of.logent.store.load_entities(entities)
end
