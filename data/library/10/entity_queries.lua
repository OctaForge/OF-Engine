module("entity_queries", package.seeall)

function by_distance(origin, max_distance, _class, fun, kwargs)
    kwargs = kwargs or {}
    local with_tag     = kwargs.with_tag
    local unsorted     = kwargs.unsorted
    local ret          = {}

    for name, entity in pairs(entity_store.get_all()) do
        if _class   and not entity:is_a(_class)      then break end
        if with_tag and not entity:has_tag(with_tag) then break end

        local distance = origin:subnew(fun(entity)):magnitude()
        if    distance <= max_distance then
            table.insert(ret, { entity, distance })
        end
    end

    if not unsorted then
        table.sort(ret, function(a, b) return a[2] < b[2] end)
    end

    return ret
end
