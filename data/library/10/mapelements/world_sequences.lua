module("world_sequences", package.seeall)

plugins = {
    area_trigger = {
        properties = {
            sequence_id  = state_variables.state_string (),
            sequence_num = state_variables.state_integer(),
            sequence_is_mandatory = state_variables.state_bool()
        },

        init = function(self)
            self.sequence_id  = ""
            self.sequence_num = 1
            self.sequence_is_mandatory = false
        end,

        client_on_collision = function(self, collider)
            if collider ~= entity_store.get_player_entity() then return nil end

            if collider.world_sequences[self.sequence_id] == (self.sequence_num - 1) then
                self.sequence_is_mandatory_passed = true

                local area_triggers = entity_store.get_all_by_class("area_trigger")

                if #table.filter_dict(area_triggers, function(i, entity)
                    return (entity.sequence_id  == self.sequence_id  and
                            entity.sequence_num == self.sequence_num and
                            entity.sequence_is_mandatory and
                            not entity.sequence_is_mandatory_passed
                    )
                end) > 0 then return nil end

                for k, entity in pairs(table.filter_dict(area_triggers, function(i, entity)
                    return (entity.sequence_id  == self.sequence_id and
                            entity.sequence_num == self.sequence_num
                    )
                end)) do
                    entity.sequence_is_mandatory_passed = false
                end

                collider.world_sequences[self.sequence_id] = collider.world_sequences[self.sequence_id] + 1
                self:on_sequence_arrival(collider)
            end
        end,

        on_sequence_arrival = function(self, collider)
        end
    },
    player = {
        client_activate = function(self)
            self.world_sequences = {}
        end,

        reset_world_sequence = function(self, sequence_id)
            self.world_sequences[sequence_id] = 0
        end
    }
}
