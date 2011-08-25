-- An invisible model that can be used to fill space and cause collisions there.
-- This is useful if rendering is done in a dynamic manner, but we still want collisions.
--
-- See comments in areatrigger
model.all.shadow(false)
model.all.collide(true)
model.all.entity_collision_box(true)
