SSUtils = {}

function SSUtils:Filter(list, callback)
    local result = {}
    for _, v in ipairs(list) do
        if callback(v) then
            table.insert(result, v)
        end
    end
    return result
end

function SSUtils:Map(list, fn)
    local result = {}
    for _, v in ipairs(list) do
        table.insert(result, fn(v))
    end
    return result
end

function SSUtils:SortBy(list, compare)
    if table.getn(list) <= 1 then
        return list
    end

    local pivot = list[1]
    local less = {}
    local greater = {}

    for i, v in ipairs(list) do
        if i ~= 1 then
            local comparison = compare(v, pivot)
            if comparison == "less" or comparison == "equal" then
                table.insert(less, v)
            elseif comparison == "greater" then
                table.insert(greater, v)
            else
                error("Unexpected comparison result: " .. comparison)
            end
        end
    end
    less = SSUtils:SortBy(less, compare)
    greater = SSUtils:SortBy(greater, compare)

    return SSUtils:Concat(less, {pivot}, greater)
end

function SSUtils:Concat(...)
    local result = {}
    local args = {...}
    for i, list in ipairs(args) do
        for _, v in ipairs(list) do
            table.insert(result, v)
        end
    end
    return result
end

function SSUtils:Throttle(timeBetween, fn)
    local lastCall = nil
    local scheduled = false

    local callFn = function()
        lastCall = GetTime()
        fn()
    end

    return function()
        if lastCall == nil or GetTime() >= (lastCall + timeBetween) then
            callFn()
            return
        end

        if scheduled then
            return
        end

        scheduled = true
        local delay = (lastCall + timeBetween) - GetTime()
        C_Timer.After(delay, function()
            scheduled = false
            callFn()
        end)
    end
end