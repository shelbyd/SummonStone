Luact = {}

Luact.frameCache = {}

Luact.Render = function(component, parent)
    for i, child in ipairs({parent:GetChildren()}) do
        Luact._DetachAndCacheLuactFrame(child)
    end
    local toRender = component()
    if toRender == nil then
        return
    end

    toRender(parent)
end

Luact._DetachAndCacheLuactFrame = function(frame)
    if not frame.__luact_owned then
        return
    end

    frame:SetParent(nil)
    frame:Hide()
    table.insert(Luact.frameCache, frame)

    for i, child in ipairs({frame:GetChildren()}) do
        Luact._DetachAndCacheLuactFrame(child)
    end
end

Luact._GetOrCreateFrame = function(type, id, parent, inherit)
    for i, frame in ipairs(Luact.frameCache) do
        local sameType = frame:GetObjectType() == type
        local sameName = frame:GetName() == id
        local sameInherit = frame.__luact_inherited == inherit

        if sameType and sameName and sameInherit then
            local frame = table.remove(Luact.frameCache, i)
            frame:SetParent(parent)
            frame:Show()
            return frame, false
        end
    end

    local frame = CreateFrame(type, id, parent, inherit)
    frame.__luact_owned = true
    return frame, true
end

Luact.Frame = function(props, children)
    return function(parent)
        local frame, created = Luact._GetOrCreateFrame("Frame", props.id, parent, props.inherit)
        frame.__luact_inherited = props.inherit

        if created then
            if props.size ~= nil then
                frame:SetSize(props.size[1], props.size[2])
            end
            frame:SetPoint(props.point, parent, props.point)
        end

        if props.movable then
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton")
            frame:SetScript("OnDragStart", frame.StartMoving)
            frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        end

        if props.resizable then
            frame:SetResizable(true)
        else
            frame:SetResizable(false)
        end

        for i, child in ipairs(children) do
            child(frame)
        end

        return frame
    end
end

Luact.Button = function(props)
    return function(parent)
        local button = Luact._GetOrCreateFrame("Button", props.id, parent, props.inherit)
        button:EnableMouse(true)
        if props.size ~= nil then
            button:SetSize(props.size[1], props.size[2])
        end
        button:SetPoint(props.point, parent, props.point)

        if props.textures ~= nil then
            local tex = props.textures
            button:SetNormalTexture(tex.normal)
            button:SetHighlightTexture(tex.highlight or tex.normal)
            button:SetPushedTexture(tex.pushed or tex.normal)
        end

        for name, fn in pairs(props.events) do
            button:SetScript(name, fn)
        end

        return button
    end
end
