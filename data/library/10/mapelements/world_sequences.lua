module("world_sequences", package.seeall)

plugins = {
    area_trigger = {
        properties = {
            sequence_id  = svars.State_String(),
            sequence_num = svars.State_Integer(),
            sequence_is_mandatory = svars.State_Boolean()
        },

        init = function(self)
            self:set_sequence_id("")
            self:set_sequence_num(1)
            self:set_sequence_is_mandatory(false)
        end,

        client_on_collision = function(self, collider)
            if collider ~= ents.get_player() then return nil end

            if collider.world_sequences[self:get_attr("sequence_id")] == (self:get_attr("sequence_num") - 1) then
                self.sequence_is_mandatory_passed = true

                local area_triggers = ents.get_by_class("area_trigger")

                if #table.filter(area_triggers, function(i, entity)
                    return (entity:get_attr("sequence_id")  == self:get_attr("sequence_id")  and
                            entity:get_attr("sequence_num") == self:get_attr("sequence_num") and
                            entity:get_attr("sequence_is_mandatory") and
                            not entity.sequence_is_mandatory_passed
                    )
                end) > 0 then return nil end

                for k, entity in pairs(table.filter(area_triggers, function(i, entity)
                    return (entity_get_sequence_id()  == self:get_attr("sequence_id") and
                            entity:get_attr("sequence_num") == self:get_attr("sequence_num")
                    )
                end)) do
                    entity.sequence_is_mandatory_passed = false
                end

                collider.world_sequences[self:get_attr("sequence_id")] = collider.world_sequences[self:get_attr("sequence_id")] + 1
                self:on_sequence_arrival(collider)
            end
        end,

        on_sequence_arrival = function(self, collider)
        end
    },
    player = {
        activate = function(self)
            if CLIENT then self.world_sequences = {} end
        end,

        reset_world_sequence = function(self, sequence_id)
            self.world_sequences[sequence_id] = 0
        end
    }
}
