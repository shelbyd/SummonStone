SummonStone = LibStub("AceAddon-3.0"):NewAddon("SummonStone", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local TargetButtonName = "SummonStone_TargetButton";

local InTargetButtonHideDelay = false
local MaybeShowTargetButton = SSUtils:Throttle(0.1, function()
    if InTargetButtonHideDelay then
        return
    end
    if IsInCombat() then
        return HideTargetButton()
    end

    local summonTarget = GetSummonTarget()
    if summonTarget == nil then
        return HideTargetButton()
    end
    if IsCurrentlyTargettingRaider(summonTarget) then
        return HideTargetButton()
    end

    if IsMousingOverMeetingStone() then
        return ShowTargetButtonAtMouse(summonTarget)
    end
    if GetMouseFocus() ~= nil and GetMouseFocus():GetName() == TargetButtonName then
        return ShowTargetButtonAtMouse(summonTarget)
    end

    return HideTargetButton()
end)

function IsInCombat()
    return UnitAffectingCombat("player")
end

local TargetButton = CreateFrame("Button", TargetButtonName, UIParent,
    "GameMenuButtonTemplate,SecureActionButtonTemplate")
TargetButton:Hide()
TargetButton:SetAttribute("type", "macro")
TargetButton:SetScript("OnLeave", function()
    -- Give game a few frames to update tooltip text
    InTargetButtonHideDelay = true
    C_Timer.After(0.1, function()
        InTargetButtonHideDelay = false
        MaybeShowTargetButton()
    end)
end)

TargetButton:RegisterEvent("CURSOR_UPDATE")
TargetButton:RegisterEvent("PLAYER_TARGET_CHANGED")
TargetButton:SetScript("OnEvent", MaybeShowTargetButton)

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
    if not TooltipShown then
        return false
    end

    if GetMouseFocus() ~= WorldFrame then return false end
    local tooltip = GameTooltipTextLeft1:GetText()
    -- TODO(shelbyd): Deal with localized Meeting Stone text
    return tooltip == "Meeting Stone" or tooltip == "Summoning Portal"
end

function ShowTargetButtonAtMouse(raiderIndex)
    if not TargetButton:IsShown() then
        TargetButton:Show()
        local scale = TargetButton:GetEffectiveScale()
        local x, y = GetCursorPosition()
        TargetButton:SetPoint("CENTER", nil, "BOTTOMLEFT", x / scale, y / scale);
    end

    local name = select(1, GetRaidRosterInfo(raiderIndex))
    TargetButton:SetAttribute("macrotext", "/target " .. name)
    TargetButton:SetText("Target " .. name)
    TargetButton:SetWidth(TargetButton:GetTextWidth() + 16)
end

function HideTargetButton()
    TargetButton:Hide()
end

function IsCurrentlyTargettingRaider(raiderIndex)
    local name = select(1, GetRaidRosterInfo(raiderIndex))
    return UnitIsUnit("target", name)
end

local SummonOrder = {}
 -- TODO(shelbyd): Custom event for SummonOrder updated.

local UpdateSummonOrder = SSUtils:Throttle(1, function()
    local differentZones = SSUtils:Filter(Raiders(), InDifferentZone)

    SummonOrder = SSUtils:Filter(differentZones, NeedsSummon)
end)

function GetSummonTarget()
    UpdateSummonOrder()
    return SummonOrder[1]
end

function Raiders()
    local indices = {}
    for i = 1, GetNumGroupMembers() do
        if GetRaidRosterInfo(i) ~= nil then
            table.insert(indices, i)
        end
    end
    return indices
end

function InDifferentZone(raiderIndex)
    local playerZone = GetZoneText()
    local raiderZone = select(7, GetRaidRosterInfo(raiderIndex))

    return playerZone ~= raiderZone
end

function NeedsSummon(raiderIndex)
    local raiderName = select(1, GetRaidRosterInfo(raiderIndex))
    if C_IncomingSummon.HasIncomingSummon(raiderName) then
        return false
    end

    local raiderZone = select(7, GetRaidRosterInfo(raiderIndex))
    if raiderZone == "Offline" then
        return false
    end

    if RaiderZoneAheadOfPlayer(raiderIndex) then
        return false
    end

    return true
end

local ZoneMap = {
    {"Zereth Mortis", "Sepulcher of the First Ones"},
    {"Zereth Mortis", "The Sepulcher of the First Ones"},
    {"Zereth Mortis", "Eternal Watch"},
    {"Zereth Mortis", "Immortal Hearth"},
    {"Zereth Mortis", "Ephemeral Plains"},
    {"Zereth Mortis", "Broker's Sting"},
    {"Zereth Mortis", "Domination's Grasp"},
}

local PrintedZones = {}

function RaiderZoneAheadOfPlayer(n)
    local playerZone = GetZoneText()
    local raiderZone = select(7, GetRaidRosterInfo(n))

    for _, pairs in ipairs(ZoneMap) do
        if playerZone == pairs[1] and raiderZone == pairs[2] then
            return true
        end
    end

    local printKey = playerZone .. " / " .. raiderZone
    if PrintedZones[printKey] == nil then
        SummonStone:Print("Assuming should summon to", playerZone, "from", raiderZone)
        PrintedZones[printKey] = true
    end

    return false
end

-- https://wowpedia.fandom.com/wiki/API_C_EncounterJournal.GetDungeonEntrancesForMap
-- https://wowpedia.fandom.com/wiki/API_C_Map.GetBestMapForUnit
