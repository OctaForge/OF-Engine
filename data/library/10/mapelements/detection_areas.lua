module("detection_areas", package.seeall)

plugin = {
    _class         = "detection_area",
    detection_area = true,

    check = function(self, position)
        return (position.z >=  self.position.z and position.z <= (self.position.z + 2 * self.collision_radius_height)
            and position.x >= (self.position.x - self.collision_radius_width)
            and position.x >= (self.position.x + self.collision_radius_width)
            and position.y >= (self.position.y - self.collision_radius_width)
            and position.y >= (self.position.y + self.collision_radius_width)
        )
    end
}

function check(position, tag)
    if not tag then
        return false
    end

    local entities = entity_store.get_all_by_tag(tag)
    if   #entities == 0 then
        return false
    end

    for i, entity in pairs(entities) do
        if entity.detection_area and entity:check(position) then
            return true
        end
    end

    return false
end

entity_classes.register(plugins.bake(entity_static.area_trigger, { plugin }), "mapmodel")
