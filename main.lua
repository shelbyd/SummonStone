SummonStone = LibStub("AceAddon-3.0"):NewAddon("SummonStone", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local TargetButtonName = "SummonStone_TargetButton";

local InTargetButtonHideDelay = false
function MaybeShowTargetButton()
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
end

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

    -- TODO(shelbyd): Deal with localized Meeting Stone text
    return GetMouseFocus() == WorldFrame and GameTooltipTextLeft1:GetText() == "Meeting Stone"
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

function GetSummonTarget()
    for i = 1, GetNumGroupMembers() do
        if DoesRaiderNNeedSummon(i) then
            return i
        end
    end
    return nil
end

function DoesRaiderNNeedSummon(n)
    local playerZone = GetZoneText()
    local raiderZone = select(7, GetRaidRosterInfo(n))
    if playerZone == raiderZone then
        return false
    end

    local raiderName = select(1, GetRaidRosterInfo(n))
    if C_IncomingSummon.HasIncomingSummon(raiderName) then
        return false
    end

    return true
end

function IsCurrentlyTargettingRaider(raiderIndex)
    local name = select(1, GetRaidRosterInfo(raiderIndex))
    return UnitIsUnit("target", name)
end
