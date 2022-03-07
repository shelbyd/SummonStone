local EventsTriggeringRecalc = {
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED", -- Enter combat
    "PLAYER_REGEN_ENABLED", -- Leave combat
    "GROUP_ROSTER_UPDATE",
};

local EventFrame = CreateFrame("Frame", "SummonStone_EventFrame")

for _index, event in pairs(EventsTriggeringRecalc) do
    EventFrame:RegisterEvent(event)
end

EventFrame:SetScript("OnEvent", function(self, event, ...)
    print("Got event", event)

    Luact.Render(Main, UIParent)
end)

function Main()
    if UnitAffectingCombat("player") then
        return nil
    end

    local needingSummon = RaidersNeedingSummon()
    print('needingSummon', needingSummon)
    if table.getn(needingSummon) == 0 then
        return nil
    end

    return MainFrame({
        title = "SummonStone"
    }, {ToSummonNames({ raiderIndices = needingSummon })})
end

function MainFrame(props, children)
    return Luact.Frame({
        id = "SummonStone_MainFrame",
        inherit = "BasicFrameTemplateWithInset",
        size = {300, 300},
        clearPoints = false,
        point = "CENTER",
        resizable = true,
        movable = true,
        MinResize = {100, 100},
        MaxResize = {500, 500}
    }, {Luact.Button({
        id = "SummonStone_Resize",
        point = "BOTTOMRIGHT",
        size = {16, 16},

        textures = {
            normal = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down",
            highlight = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight",
            pushed = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"
        },
        events = {
            OnMouseDown = function(self)
                self:GetParent():StartSizing("BOTTOMRIGHT")
            end,
            OnMouseUp = function(self)
                self:GetParent():StopMovingOrSizing()
            end
        }
    }), Luact.Text(props.title, {
        fontObject = "GameFontHighlight",
        point = function(parent)
            return "LEFT", parent.TitleBg, "LEFT", 5, 0
        end
    })})
end

function RaidersNeedingSummon()
    local needsSummoned = {}
    for i=1,GetNumGroupMembers() do
        if DoesRaiderNNeedSummon(i) then
            table.insert(needsSummoned, i)
        end
    end
    return needsSummoned
end

function DoesRaiderNNeedSummon(n)
    local playerZone = GetZoneText()
    local raiderZone = select(7, GetRaidRosterInfo(n))
    if playerZone == raiderZone then
        return false
    else
        return true
    end
end

function ToSummonNames(props)
    local children = {}
    for i, raiderIndex in ipairs(props.raiderIndices) do
        local name = select(1, GetRaidRosterInfo(raiderIndex))
        table.insert(children, Luact.Text(name))
    end
    return Luact.Frame({
        size = {140, 32},
    }, children)
end

Luact.Render(Main, UIParent)
