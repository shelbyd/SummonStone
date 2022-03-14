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