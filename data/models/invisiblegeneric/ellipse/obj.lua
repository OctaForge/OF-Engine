-- An invisible model that can be used to fill space and cause collisions there.
-- This is useful if rendering is done in a dynamic manner, but we still want collisions.
--
-- See comments in areatrigger
cc.model.mdl.shadow(0)
cc.model.mdl.collide(1)
cc.model.mdl.perentitycollisionboxes(1)
cc.model.mdl.ellipsecollide(1)
