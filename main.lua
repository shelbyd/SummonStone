local EventsTriggeringRecalc = {
    "PLAYER_FOCUS_CHANGED", -- For debugging
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED", -- Enter combat
    "PLAYER_REGEN_ENABLED", -- Leave combat
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

    return Luact.Frame({
        id = "SummonStone_MainFrame",
        inherit = "BasicFrameTemplateWithInset",
        size = {300, 300},
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
            end,
        }
    })})
end

Luact.Render(Main, UIParent)