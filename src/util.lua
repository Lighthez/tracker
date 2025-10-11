function default(a, b)
    a = a or {}

    for k, v in pairs(b) do
        local v_is_table = type(v) == "table"

        if not a[k] then
            a[k] = v_is_table and default({}, v) or v 
        elseif a[k] and (type(a[k]) == "table" and v_is_table) then
            a[k] = default(a[k], v)
        end
    end

    return a
end

function rnd_not(range, decline)
    while true do
        local x = flr(rnd(range))
        if x != decline then return x end
    end
end

function round(num)
    return num >= 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
end