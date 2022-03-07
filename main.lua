SummonStone = LibStub("AceAddon-3.0"):NewAddon("SummonStone", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")

function SummonStone:OnInitialize()
end

local ShouldRender = true

SummonStone:RegisterChatCommand("ss", "OnSlashCommand")
function SummonStone:OnSlashCommand(input)
    ShouldRender = true
    Render()
end

local EventsTriggeringRecalc = {
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED", -- Enter combat
    "PLAYER_REGEN_ENABLED", -- Leave combat
    "GROUP_ROSTER_UPDATE",
    "CURSOR_UPDATE",
};

local EventFrame = CreateFrame("Frame", "SummonStone_EventFrame")

for _index, event in pairs(EventsTriggeringRecalc) do
    EventFrame:RegisterEvent(event)
end

EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CURSOR_UPDATE" then
        SummonStone:OnCursorUpdate()
        return
    end

    -- Render()
end)

local CurrentSummonFrame = nil

function Render()
    if CurrentSummonFrame ~= nil then
        -- Need to nil out CurrentSummonFrame so we can detect if the
        -- close button was clicked below
        local frame = CurrentSummonFrame
        CurrentSummonFrame = nil
        AceGUI:Release(frame)
    end

    if not ShouldRender then
        return
    end
    if IsInCombat() then
        return
    end

    local needSummon = RaidersNeedingSummon()
    if table.getn(needSummon) == 0 then
        return
    end

    CurrentSummonFrame = AceGUI:Create("Frame")
    CurrentSummonFrame:SetTitle("SummonStone")
    CurrentSummonFrame:SetStatusText("Get your team summoned!")
    CurrentSummonFrame:SetCallback("OnClose", function(widget, ...)
        local closeButtonClicked = CurrentSummonFrame ~= nil
        if closeButtonClicked then
            ShouldRender = false
        end
        CurrentSummonFrame = nil
        AceGUI:Release(widget)
    end)
    CurrentSummonFrame:SetAutoAdjustHeight(true)
    CurrentSummonFrame:SetLayout("Flow")

    local heading = AceGUI:Create("Heading")
    heading:SetText("Needing Summon")
    heading:SetRelativeWidth(1)
    CurrentSummonFrame:AddChild(heading)

    for i, raiderIndex in ipairs(needSummon) do
        RenderSummonNeeded(raiderIndex, CurrentSummonFrame)
    end
end

function IsInCombat()
    return UnitAffectingCombat("player")
end

function RaidersNeedingSummon()
    local needsSummoned = {}
    for i = 1, GetNumGroupMembers() do
        if DoesRaiderNNeedSummon(i) then
            table.insert(needsSummoned, i)
        end
    end
    return needsSummoned
end

function DoesRaiderNNeedSummon(n)
    local playerZone = GetZoneText()
    local raiderZone = select(7, GetRaidRosterInfo(n))
    local name = select(1, GetRaidRosterInfo(n))
    if playerZone == raiderZone then
        return false
    else
        return true
    end
end

function RenderSummonNeeded(raiderIndex, parent)
    local name = select(1, GetRaidRosterInfo(raiderIndex))
    SummonStone:Print(GetRaidRosterInfo(raiderIndex))

    local label = AceGUI:Create("Label")
    label:SetText(name)
    label:SetRelativeWidth(1)
    parent:AddChild(label)
end

local TargetButtonName = "SummonStone_TargetButton";

local InTargetButtonHideDelay = false
function MaybeShowTargetButton()
    if InTargetButtonHideDelay then
        return
    end

    if IsInCombat() then
        return HideTargetButton()
    end
    if IsMousingOverMeetingStone() then
        return ShowTargetButtonAtMouse()
    end
    if GetMouseFocus():GetName() == TargetButtonName then
        return ShowTargetButtonAtMouse()
    end

    return HideTargetButton()
end

function SummonStone:OnCursorUpdate()
    MaybeShowTargetButton()
end

local TargetButton = CreateFrame("Button", TargetButtonName, UIParent, "GameMenuButtonTemplate,SecureActionButtonTemplate")
TargetButton:Hide()
TargetButton:SetScript("OnLeave", function()
    -- Give game a few frames to update tooltip text
    InTargetButtonHideDelay = true
    C_Timer.After(0.1, function()
        InTargetButtonHideDelay = false
        MaybeShowTargetButton()
    end)
end)

local TooltipShown = false
GameTooltip:HookScript("OnUpdate", function(tooltip, e)
    TooltipShown = true
    MaybeShowTargetButton()
end)
GameTooltip:HookScript("OnHide", function(tooltip, e)
    TooltipShown = false
    MaybeShowTargetButton()
end)

function IsMousingOverMeetingStone()
    if not TooltipShown then return false end

    -- TODO(shelbyd): Deal with localized Meeting Stone text
    return GetMouseFocus() == WorldFrame and GameTooltipTextLeft1:GetText() == "Meeting Stone"
end

function ShowTargetButtonAtMouse()
    if TargetButton:IsShown() then return end

    TargetButton:Show()
    TargetButton:SetAttribute("type", "target")
    TargetButton:SetAttribute("unit", "player") 

    TargetButton:SetText("Target player")

    local scale = TargetButton:GetEffectiveScale()
    local x, y = GetCursorPosition()
    TargetButton:SetPoint("CENTER", nil, "BOTTOMLEFT", x/scale, y/scale);
end

function HideTargetButton()
    TargetButton:Hide()
end