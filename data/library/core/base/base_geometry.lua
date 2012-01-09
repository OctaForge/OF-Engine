--[[!
    File: library/core/base/base_geometry.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides basic geometry utilities.
]]

--[[!
    Package: geometry
    A module containing various utility functions for rays, collisions
    and others.
]]
module("geometry", package.seeall)

--[[!
    Function: get_ray_collision_distance
    Checks for collision of a ray against world geometry, ignoring entities.
    The length of the ray implies how far ahead to look, XXX - seems we look
    farther.

    Parameters:
        o - position (<vec3>) where the ray starts.
        r - we look for collisions along this ray (<vec3>).

    Returns:
        The distance along the ray to the first collision.
]]
function get_ray_collision_distance(o, r)
    local rm = r:length()
    if    rm == 0 then
        return -1
    end
    return CAPI.raypos(o, std.math.Vec3(r.x / rm, r.y / rm, r.z / rm), rm)
end

--[[!
    Function: get_collidable_entities
    Returns an array of entities that are collidable (== can
    be collided in <get_ray_collision_entities>). Here, it's
    all entities of <character> class and inherited classes.
]]
function get_collidable_entities()
    return entity_store.get_all_by_class("character")
end

--[[!
    Function: get_ray_collision_world
    Given an origin point (<vec3>), a direction vector and maximal distance
    to check in (the maximal distance is optional and defaults to 2048), it
    finds a collision point with the world (<vec3>) and returns it.

    See also <get_ray_collision_entities>.
]]
function get_ray_collision_world(origin, direction, max_dist)
    max_dist   = max_dist or 2048
    local dist = get_ray_collision_distance(
        origin, direction:mul_new(max_dist)
    )
    return origin:add_new(
        direction:mul_new(std.math.min(dist, max_dist))
    )
end

--[[!
    Function: get_ray_collision_entities
    Given an origin point (<vec3>) and a target point (NOT direction
    as in <get_ray_collision_world>), it checks if any entities that
    are collidable (<get_collidable_entities>) are in the ray and
    if yes, it returns an associative array { entity, alpha,
    collision_position } where the entity is the best colliding entity.
    You can specify an optional third argument that is an entity that
    should be ignored.

    Best colliding entity is always the closest colliding one.
]]
function get_ray_collision_entities(origin, target, ignore)
    local entities  = get_collidable_entities()
    local direction = target:sub_new(origin)
    local dist2     = direction:length()
    if    dist2 == 0 then
        return nil
    end
    dist2           = dist2 * dist2

    local best = nil
    local function consider(entity, alpha, collision_position, distance)
        if not best or distance < best.distance then
            best = {
                entity   = entity,
                alpha    = alpha,
                distance = distance,
                collision_position = collision_position
            }
        end
    end

    for k, entity in pairs(entities) do
        if entity ~= ignore then
            local entity_dir = entity.center:sub_new(origin)
            local entity_rad = entity.radius
                           and entity.radius
                            or std.math.max(
                                entity.collision_radius_width,
                                entity.collision_radius_height
                            )
            local alpha = direction:dot_product(entity_dir) / dist2
            local collision_position
                = origin:add_new(direction:mul_new(alpha))
            local distance
                = entity.center:sub_new(collision_position):length()
            -- XXX alpha check ignores radius
            if alpha < 0 or alpha > 1 or distance > entity_rad then
                return nil
            end
            consider(entity, alpha, collision_position, distance)
        end
    end

    return best
end

--[[!
    Function: is_colliding
    Finds whether a position is colliding with either world or entity.
    First argument specifies the position, second the radius it applies
    for, third is optional argument specifying entity to ignore while
    doing collision checks. Calls <is_colliding_entities> if the
    position doesn't collide with geometry.
]]
function is_colliding(p, r, i)
    local  ret = CAPI.iscolliding(p, r, i and i.uid or -1)
    if not ret then
        return is_colliding_entities(p, r, i)
    end
    return ret
end

--[[!
    Function: is_colliding_entities
    See <is_colliding>. It is the same, but checks only for entity
    collisions. It's also called from <is_colliding>. To get a list
    of collidable entities, result of <get_collidable_entities>
    is used.
]]
function is_colliding_entities(position, radius, ignore)
    local entities = get_collidable_entities()
    for i, entity in pairs(entities) do
        if entity ~= ignore and not entity.deactivated then
            local   entity_radius = entity.radius
                and entity.radius
                or std.math.max(
                    entity.collision_radius_width,
                    entity.collision_radius_height
                )
            if position:is_close_to(
                entity.position, radius + entity_radius
            ) then
                return true
            end
        end
    end
    return false
end

--[[!
    Function: get_surface_normal
    Finds the normal of a surface with respect to an outside (reference)
    point. This is useful for example to calculate how objects bounce
    off walls.

    Parameters:
        reference  - a point outside of the surface, our reference point.
        surface    - a point on the surface (not the surface itself).
        resolution - if given, what resolution or relevant scale to use.
        Finer detail levels will be ignored. If not given, guessed.

    Returns:
        The surface normal, a <vec3> or nil if we cannot calculate it.
]]
function get_surface_normal(reference, surface, resolution)
    local direction = surface:sub_new(reference)
    local distance  = direction:length()
    if    distance == 0 then
        return nil
    end

    resolution = resolution or (distance / 20)
    local function random_resolutional()
        return ((std.math.random() - 0.5) * 2 * resolution)
    end

    local point_direction
    local points
    local ret
    local temp

    for i = 1, 3 do
        points = {}
        for n = 1, 3 do
            point_direction = surface:add_new(std.math.Vec3(
                random_resolutional(),
                random_resolutional(),
                random_resolutional()
            )):sub(reference)
            if  point_direction:length() == 0 then
                point_direction.z = point_direction.z + resolution
            end

            temp = get_ray_collision_distance(
                reference,
                point_direction:normalize():mul(
                    distance * 3 + resolution * 3 + 3
                )
            )
            table.insert(points, point_direction:normalize():mul(temp))
        end

        ret = points[2]:sub(points[1]):cross_product(points[3]:sub(points[1]))
        if ret:length() > 0 then
            if  ret:dot_product(reference:sub_new(surface)) < 0 then
                ret:mul(-1)
            end
            return ret:normalize()
        end
    end
end

--[[!
    Function: get_reflected_ray
    Calculates the reflected ray off a surface normal and returns it.

    Parameters:
        ray - the casted ray.
        normal - the surface normal (<get_surface_normal>).
        elasticity - optional, defaults to 1.
        friction - optional, defaults to 1.
]]
function get_reflected_ray(ray, normal, elasticity, friction)
    elasticity = elasticity or 1
    friction   = friction   or 1

    local bounce_direction = normal:mul_new(-(normal:dot_product(ray)))
    if friction == 1 then
        return ray:add(bounce_direction:mul(1 + elasticity))
    else
        local  surface_direction = ray:add_new(bounce_direction)
        return surface_direction:mul(friction):add(
            bounce_direction:mul(elasticity)
        )
    end
end

--[[!
    Function: bounce
    Given a physical thing - an entity with position, velocity and radius
    properties, we simulate its movement for a given time, and make it bounce
    from the world geometry. Thing can optionally have ignore boolean member
    which is an entity we will ignore.

    Parameters:
        thing - the thing.
        elasticity - how elastic the bounces are, at 1, all the energy is
        conserved, at 0, all of it is lost.
        seconds - how long to simulate in seconds.

    Returns:
        true if all is fine, false if unavoidable collision occured
        that cannot be bounced from.
]]
function bounce(thing, elasticity, friction, seconds)
    local function fallback()
        -- we failed to bounce, just go in the reverse direction
        -- from the last ok spot - better than something more embarassing
        if  thing.last_safe and thing.last_safe[2] then
            thing.position = thing.last_safe[2].position
            thing.velocity = thing.last_safe[2].velocity
        elseif thing.last_safe then
            thing.position = thing.last_safe[1].position
            thing.velocity = thing.last_safe[1].velocity
        end
        thing.velocity:mul(-1)
        return true
    end

    elasticity = elasticity or 0.9

    if seconds == 0 or thing.velocity:length() == 0 then
        return true
    end

    if is_colliding(thing.position, thing.radius, thing.ignore) then
        return fallback()
    end

    -- save 2 backwards - [1] is the latest, and will have constraints
    -- applied. [2] is two back, so it was safe even WITH constraints
    -- applied to it
    things.last_safe = {{
        position = thing.position:copy(),
        velocity = thing.position:copy()
    }, thing.last_safe and thing.last_safe[1] or nil }

    local old_position = self.position:copy()
    local movement     = thing.velocity:mul_new(seconds)
    thing.position:add(movement)

    if not is_colliding(thing.position, thing.radius, thing.ignore) then
        return true
    end

    -- try actual bounce
    local direction = movement:copy():normalize()
    local surface_dist = get_ray_collision_distance(
        old_position, direction:mul_new(
            3 * movement:length() + 3 * thing.radius + 1.5
        )
    )
    if surface_dist < 0 then return fallback() end

    local surface = old_position:add_new(direction, surface_dist)
    local normal = get_surface_normal(old_position, surface)
    if not normal then return fallback() end

    movement = get_reflected_ray(movement, normal, elasticity, friction)

    thing.position = old_position:add(movement)
    if is_colliding(self.position, self.radius, self.ignore) then
        return fallback()
    end
    thing.velocity = movement:mul(1 / seconds)

    return true
end

--[[!
    Function: is_player_colliding_entity
    Given a player entity and an other entity, the function returns
    true if they collide and false if they don't.
]]
function is_player_colliding_entity(player, entity)
    if  entity.collision_radius_width
    and entity.collision_radius_width ~= 0 then
        -- z
        if player.position.z
        >= entity.position.z + 2 * entity.collision_radius_height or
           player.position.z + player.eye_height + player.above_eye
        <= entity.position.z then
            return false
        end

        -- x
        if player.position.x - player.radius
        >= entity.position.x + entity.collision_radius_width or
           player.position.x + player.radius
        <= entity.position.x - entity.collision_radius_width then
            return false
        end

        -- y
        if player.position.y - player.radius
        >= entity.position.y + entity.collision_radius_width or
           player.position.y + player.radius
        <= entity.position.y - entity.collision_radius_width then
            return false
        end

        return true
    else
        -- z
        if player.position.z
        >= entity.position.z + entity.eye_height + entity.above_eye or
           player.position.z + player.eye_height + player.above_eye
        <= entity.position.z then
            return false
        end

        -- x
        if player.position.x - player.radius
        >= entity.position.x + entity.radius or
           player.position.x + player.radius
        <= entity.position.x - entity.radius then
            return false
        end

        -- y
        if player.position.y - player.radius
        >= entity.position.y + entity.radius or
           player.position.y + player.radius
        <= entity.position.y - entity.radius then
            return false
        end

        return true
    end
end
