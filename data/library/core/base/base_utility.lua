--[[!
    File: base/base_utility.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features utility library.

    Section: Utilities
]]

--[[!
    Package: utility
    This module contains various utilties. To name some, it's i.e. timer, VFS handling,
    safe file read, variout operations for computing distances, yaws, pitches collisions
    and others.
]]
module("utility", package.seeall)

--[[!
    Function: cache_by_time_delay
    Caches a function (or rather, callable table - see <convert.tocalltable>!)
    by time delay. That allows to execute a function per-frame, But it'll take
    any real action just once upon a time. That is useful for performance reasons,
    mainly.

    Parameters:
        fun - A callable table. See <convert.tocalltable>.
        delay - delay between runs in seconds.

    Returns:
        A function that can be ran per-frame, but it'll execute the callable table
        passed from arguments just once upon time (specified by delay between runs).
]]
function cache_by_time_delay(fun, delay)
    fun.last_time = ((-delay) * 2)
    return function(...)
        if (GLOBAL_TIME - fun.last_time) >= delay then
            fun.last_cached_val = fun(...)
            fun.last_time = GLOBAL_TIME
        end
        return fun.last_cached_val
    end
end

--[[!
    Function: cache_by_time_global_timestamp
    Caches a function (or rather, callable table - see <convert.tocalltable>!)
    by timestamp change. That means the function (callable table) will get executed
    just when <GLOBAL_CURRENT_TIMESTAMP> changes.

    Parameters:
        fun - A callable table. See <convert.tocalltable>.

    Returns:
        A function that takes action only when <GLOBAL_CURRENT_TIMESTAMP> gets changed.
]]
function cache_by_global_timestamp(fun)
    return function(...)
        if fun.last_timestamp ~= GLOBAL_CURRENT_TIMESTAMP then
            fun.last_cached_val = fun(...)
            fun.last_timestamp = GLOBAL_CURRENT_TIMESTAMP
        end
        return fun.last_cached_val
    end
end

--- A simple timer.
-- @class table
-- @name repeating_timer
repeating_timer = class.new()

--- Return string representation of a timer.
-- @return String representation of a timer.
function repeating_timer:__tostring()
    return string.format("repeating_timer: %s %s %s",
                         tostring(self.interval),
                         tostring(self.carryover),
                         tostring(self.sum))
end

--- Constructor for simple timer.
-- @param i Interval for timer.
-- @param c Carry over the timer.
function repeating_timer:__init(i, c)
    self.interval = i
    self.carryover = c or false
    self.sum = 0
end

--- Tick a specified amount of time. If timer has reached the interval ("fire"),
-- it returns true and resets the timer. If carryover is on, the time
-- over interval is left for next time.
-- @param s Specifies how long to tick.
-- @return true if interval reached, false otherwise.
function repeating_timer:tick(s)
    self.sum = self.sum + s
    if self.sum >= self.interval then
        if not self.carryover then
            self.sum = 0
        else
            self.sum = self.sum - self.interval
        end
        return true
    else
        return false
    end
end

--- Sets the timer to fire next tick, no matter how many seconds are given
function repeating_timer:prime()
    self.sum = self.interval
end

--- Calculate the distance between two vectors.
-- @param a first vector.
-- @param b second vector.
-- @return The distance between them.
function distance(a, b)
    return math.sqrt(math.pow(a.x - b.x, 2)
                   + math.pow(a.y - b.y, 2)
                   + math.pow(a.z - b.z, 2))
end

--- Normalize the angle to be within +-180 degrees of some value.
-- @param ag Angle to normalize. (i.e. 80)
-- @param rt Angle to which we'll relatively normalize. (i.e. 360)
-- @return Angle normalized relatively to rt. (in the example, 260)
function angle_normalize(ag, rt)
    while ag < (rt - 180.0) do
        ag = ag + 360.0
    end
    while ag > (rt + 180.0) do
        ag = ag - 360.0
    end
    return ag
end

--- Get the direction of angle change.
-- @param ag The angle.
-- @param rt The angle to which it's changing.
-- @return Sign of the change (1 / 0 / -1)
function angle_dirchange(ag, rt)
    ag = angle_normalize(ag, rt)
    return math.sign(ag - rt)
end

--- Calculate the yaw from origin to target on 2D data (x, y).
-- @param o Origin (position from which we start).
-- @param t Target (position towards which we calculate).
-- @param r Whether to calculate the yaw away from target (defaults to false)
-- @return The calculated yaw.
function yawto(o, t, r)
    return (r and yawto(t, o) or math.deg(-(math.atan2(t.x - o.x, t.y - o.y))))
end

--- Calculate the pitch from origin to target on 2D data (y, z).
-- @param o Origin (position from which we start).
-- @param t Target (position towards which we calculate).
-- @param r Whether to calculate the pitch away from target (defaults to false)
-- @return The calculated pitch.
function pitchto(o, t, r)
    return (r and pitchto(t, o) or (360.0 * (math.asin((t.z - o.z) / distance(o, t))) / (2.0 * math.pi)))
end

--- Check if the yaw between two points is within acceptable error range.
-- @param o Origin.
-- @param t Target.
-- @param cy Current yaw (which we ask is close to actual yaw)
-- @param ae How close the yaws must be to return true.
-- @return True or false, depends on if they're close or not.
function yawcompare(o, t, cy, ae)
    local ty = yawto(o, t)
    ty = angle_normalize(ty, cy)
    return (math.abs(ty - cy) <= ae)
end

--- Check if the pitch between two points is within acceptable error range.
-- @param o Origin.
-- @param t Target.
-- @param cy Current pitch (which we ask is close to actual pitch)
-- @param ae How close the pitches must be to return true.
-- @return True or false, depends on if they're close or not.
function pitchcompare(o, t, cp, ae)
    local tp = pitchto(o, t)
    tp = angle_normalize(tp, cp)
    return (math.abs(tp - cp) <= ae)
end

--- Check for a line of sight between two positions (i.e. if
-- the path is clear and there is no obstacle between them). (Ignores entities?)
-- @param a First position.
-- @param b Another position.
-- @return True if line of sight is clear, false otherwise.
function haslineofsight(a, b)
    return CAPI.raylos(a.x, a.y, a.z,
                       b.x, b.y, b.z)
end

--- Check for collision of ray against world geometry, ignoring entities.
-- The length of the ray implies how far ahead to look. XXX - seems we look farther
-- @param o Where the ray starts.
-- @param r We look for collisions along this ray.
-- @return The distance along the ray to the first collision.
function ray_collisiondist(o, r)
    local rm = r:magnitude()
    if    rm == 0 then return -1 end
    return CAPI.raypos(o.x, o.y, o.z,
                       r.x / rm,
                       r.y / rm,
                       r.z / rm,
                       rm)
end

--- Finds the floor below some position.
-- @param o The position from which to start searching.
-- @param d Max distance to look before giving up.
-- @return The distance to the floor.
-- @see floor_highestdist
-- @see floor_lowestdist
function floor_dist(o, d)
    return CAPI.rayfloor(o.x, o.y, o.z, d)
end

--- Finds the distance to the highest floor, not just a point, but seach within a radius.
-- By highest floor, we mean the smallest distance from the origin to that floor.
-- @param o Where we start searching.
-- @param d Max distance to look before giving up.
-- @param r Radius around the origin where we're looking.
-- @return The distance to the floor.
function floor_highestdist(o, d, r)
    local rt = floor_dist(o, d)
    local tb = { -r / 2, 0, r / 2 }
    for x = 1, #tbl do
        for y = 1, #tbl do
            rt = math.min(rt, floor_dist(o:addnew(vec3(tb[x], tb[y], 0)), d))
        end
    end

    return rt
end

--- Finds the distance to the lowest floor, not just a point, but seach within a radius.
-- By lost floor, we mean the biggest distance from the origin to that floor.
-- @param o Where we start searching.
-- @param d Max distance to look before giving up.
-- @param r Radius around the origin where we're looking.
-- @return The distance to the floor.
function floor_lowestdist(o, d, r)
    local rt = floor_dist(o, d)
    local tb = { -r / 2, 0, r / 2 }
    for x = 1, #tbl do
        for y = 1, #tbl do
            rt = math.max(rt, floor_dist(o:addnew(vec3(tb[x], tb[y], 0)), d))
        end
    end

    return rt
end

--- Finds whether position is colliding.
-- @param p The position.
-- @param r Radius it applies for.
-- @param i Entity to ignore. (optional)
function iscolliding(p, r, i)
    local  ret = CAPI.iscolliding(p.x, p.y, p.z, r, i and i.uid or -1)
    if not ret then
        return is_colliding_entities(p, r, i)
    end
    return ret
end

function is_colliding_entities(position, radius, ignore)
    local entities = get_collidable_entities()
    for i, entity in pairs(entities) do
        if entity ~= ignore and not entity.deactivated then
            local entity_radius = entity.radius
                and entity.radius
                or math.max(
                    entity.collision_radius_width,
                    entity.collision_radius_height
                )
            if position:iscloseto(entity.position, radius + entity_radius) then
                return true
            end
        end
    end
    return false
end

--- Get current time.
-- @class function
-- @name currtime
currtime = CAPI.currtime

--- Get current millis.
-- @class function
-- @name getmillis
getmillis = CAPI.getmillis

--- Tabify a string.
-- @param s String to tabify.
-- @param n Number of tabs.
-- @class function
-- @name tabify
tabify = CAPI.tabify

--- Write a config file.
-- @param cfg The config file to write.
-- @class function
-- @name writecfg
writecfg = CAPI.writecfg

--- Read a file from disk. Path is validated (== can't go outside OF directory)
-- @param file File to read.
-- @return Contents of file as string.
-- @class function
-- @name readfile
readfile = CAPI.readfile

--- Add a zip as VFS.
-- @param name Name of the zip in data directory.
-- @param mount Mount directory. (optional)
-- @param strip String specifying what to strip from the beginning. (optional)
-- @class function
-- @name addzip
addzip = CAPI.addzip

--- Remove a zip from VFS.
-- @param name Name of the zip to remove from VFS.
-- @class function
-- @name removezip
removezip = CAPI.removezip

--- Get target position.
-- @class function
-- @name gettargetpos
-- @return Target position as a vec3.
gettargetpos = cache_by_global_timestamp(convert.tocalltable(CAPI.gettargetpos))

--- Get target entity.
-- @class function
-- @name gettargetent
-- @return Target entity.
gettargetent = cache_by_global_timestamp(convert.tocalltable(CAPI.gettargetent))

function get_ray_collision_world(origin, direction, max_dist)
    max_dist = max_dist or 2048
    local dist = ray_collisiondist(origin, direction:mulnew(max_dist))
    return origin:addnew(direction:mulnew(math.min(dist, max_dist)))
end

function get_collidable_entities()
    return entity_store.get_all_by_class("character")
end

function get_ray_collision_entities(origin, target, ignore)
    local entities  = get_collidable_entities()
    local direction = target:subnew(origin)
    local dist2     = direcion:magnitude()
    if    dist2 == 0 then return nil end
    dist2 = dist2 * dist2

    local best = nil
    function consider(entity, alpha, collision_position)
        if not best or distance < best.distance then
            best = {
                entity = entity,
                alpha  = alpha,
                collision_position = collision_position
            }
        end
    end

    for k, entity in pairs(entities) do
        if entity ~= ignore then
            local entity_dir = entity.center:subnew(origin)
            local entity_rad = entity.radius
                           and entity.radius
                            or math.max(
                                entity.collision_radius_width,
                                entity.collision_radius_height
                            )
            local alpha = direction:dotproduct(entity_dir) / dist2
            local collision_position = origin:addnew(direction:mulnew(alpha))
            local distance = entity.center:subnew(collision_position):magnitude()
            -- XXX alpha check ignores radius
            if alpha < 0 or alpha > 1 or distance > entity_rad then return nil end
            consider(entity, alpha, collision_position)
        end
    end

    return best
end

function get_material(position)
    return CAPI.getmat(position.x, position.y, position.z)
end

MATF_CLIP_SHIFT = 3

MATERIAL = {
    AIR = 0,
    WATER = 1,
    LAVA = 2,
    GLASS = 3,
    NOCLIP = math.lsh(1, MATF_CLIP_SHIFT),  -- collisions always treat cube as empty
    CLIP = math.lsh(2, MATF_CLIP_SHIFT)  -- collisions always treat cube as solid
}

function get_surface_normal(reference, surface, resolution)
    local direction = surface:subnew(reference)
    local distance  = direction:magnitude()
    if    distance == 0 then return nil end

    resolution = resolution or (distance / 20)
    local function random_resolutional()
        return ((math.random() - 0.5) * 2 * resolution)
    end

    local point_direction
    local points
    local ret
    local temp

    for i = 1, 3 do
        points = {}
        for n = 1, 3 do
            point_direction = surface:addnew(math.vec3(
                random_resolutional(),
                random_resolutional(),
                random_resolutional()
            )):sub(reference)
            if  point_direction:magnitude() == 0 then
                point_direction.z = point_direction.z + resolution
            end

            temp = ray_collisiondist(
                reference,
                point_direction:normalize():mul(
                    distance * 3 + resolution * 3 + 3
                )
            )
            table.insert(points, point_direction:normalize():mul(temp))
        end

        ret = points[2]:sub(points[1]):cross_product(points[3]:sub(points[1]))
        if ret:magnitude() > 0 then
            if  ret:dotproduct(reference:subnew(surface)) < 0 then
                ret:mul(-1)
            end
            return ret:normalize()
        end
    end
end

function get_reflected_ray(ray, normal, elasticity, friction)
    elasticity = elasticity or 1
    friction   = friction   or 1

    local bounce_direction = normal:mulnew(-(normal:dotproduct(ray)))
    if friction == 1 then
        return ray:add(bounce_direction:mul(1 + elasticity))
    else
        local  surface_direction = ray:addnew(bounce_direction)
        return surface_direction:mul(friction):add(bounce_direction:mul(elasticity))
    end
end

function bounce(thing, elasticity, friction, seconds)
    local function fallback()
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

    if seconds == 0 or thing.velocity:magnitude() == 0 then
        return true
    end

    if iscolliding(thing.position, thing.radius, thing.ignore) then return fallback() end

    things.last_safe = {{
        position = thing.position:copy(),
        velocity = thing.position:copy()
    }, thing.last_safe and thing.last_safe[1] or nil }

    local old_position = self.position:copy()
    local movement     = thing.velocity:mulnew(seconds)
    thing.position:add(movement)

    if not iscolliding(thing.position, thing.radius, thing.ignore) then return true end

    local direction = movement:copy():normalize()
    local surface_dist = ray_collisiondist(
        old_position, direction:mulnew(3 * movement:magnitude() + 3 * thing.radius + 1.5)
    )
    if surface_dist < 0 then return fallback() end

    local surface = old_position:addnew(direction, surface_dist)
    local normal = get_surface_normal(old_position, surface)
    if not normal then return fallback() end

    movement = world.get_reflected_ray(movement, normal, elasticity, friction)

    thing.position = old_position:add(movement)
    if iscolliding(self.position, self.radius, self.ignore) then return fallback() end
    thing.velocity = movement:mul(1 / seconds)

    return true
end
