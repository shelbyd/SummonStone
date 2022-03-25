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

    if GetMouseFocus() ~= WorldFrame then
        return false
    end
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
    if name == nil then
        return false
    end
    return UnitIsUnit("target", name)
end

local SummonSet = {}
-- TODO(shelbyd): Custom event for SummonSet updated.

local UpdateSummonOrder = SSUtils:Throttle(1, function()
    local targetInstance = GetTargetInstance()

    local summonContext = SSUtils:Map(Raiders(), function(i)
        return GetRaiderSummonContext(i, targetInstance)
    end)
    local action = SummonAction(PlayerContext(targetInstance), summonContext)
    if type(action) == 'table' then
        local justIds = SSUtils:Map(action, function(context)
            return context.index
        end)
        SummonSet = justIds
    else
        if action ~= 'done' then
            SummonStone:Print(action)
        end
        SummonSet = {}
    end
end)

function GetSummonTarget()
    UpdateSummonOrder()

    for _, raiderIndex in ipairs(SummonSet) do
        if IsCurrentlyTargettingRaider(raiderIndex) then
            return raiderIndex
        end
    end

    return SummonSet[1]
end

function GetTargetInstance()
    if IsInInstance() then
        local name = select(1, GetInstanceInfo())
        return name
    end

    local playerMap = C_Map.GetBestMapForUnit("player")
    if playerMap == nil then
        return nil
    end

    local entrances = C_EncounterJournal.GetDungeonEntrancesForMap(playerMap)
    local sortedEntrances = SSUtils:SortByKey(entrances, function(entrance)
        local playerPosition = C_Map.GetPlayerMapPosition(playerMap, "player")
        local deltaVec = entrance.position
        -- Why is :Subtract mutable and not functional?
        deltaVec:Subtract(playerPosition)
        return deltaVec:GetLength()
    end)
    local nearestEntrance = sortedEntrances[1]
    return nearestEntrance.name
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

function InSameZone(raiderIndex)
    local playerZone = GetZoneText()
    local raiderZone = select(7, GetRaidRosterInfo(raiderIndex))

    return playerZone == raiderZone
end

function GetRaiderSummonContext(raiderIndex, targetInstance)
    local raiderName = select(1, GetRaidRosterInfo(raiderIndex))

    local sameZoneAsPlayer = InSameZone(raiderIndex)
    local inTargetDungeon = MapIsInInstance(C_Map.GetBestMapForUnit(raiderName), targetInstance)
    local _, englishClassName = UnitClass(raiderName)

    return {
        index = raiderIndex,
        sameZoneAsPlayer = sameZoneAsPlayer,
        inTargetDungeon = inTargetDungeon,
        here = sameZoneAsPlayer or inTargetDungeon,
        hasIncoming = C_IncomingSummon.HasIncomingSummon(raiderName),
        isWarlock = englishClassName == "WARLOCK"
    }
end

function PlayerContext(targetInstance)
    return {
        inTargetDungeon = IsInInstance()
    }
end

function MapIsInInstance(mapId, instance)
    if mapId == 0 or mapId == nil then
        return false
    end

    local info = C_Map.GetMapInfo(mapId)
    return info.name == instance or MapIsInInstance(info.parentMapID, instance)
end

local function l(key)
    return function(v)
        if v[key] == nil then
            error("Attempted to access missing value: " .. key)
        end
        return v[key]
    end
end

local function lNot(fn)
    return function(v)
        return not fn(v)
    end
end

local function lAnd(fn1, fn2)
    return function(v)
        return fn1(v) and fn2(v)
    end
end

local function All(list, pred)
    for _, v in ipairs(list) do
        if not pred(v) then
            return false
        end
    end
    return true
end

local function Any(list, pred)
    for _, v in ipairs(list) do
        if pred(v) then
            return true
        end
    end
    return false
end

function SummonAction(player, raiders)
    if All(raiders, l('sameZoneAsPlayer')) then
        return 'done'
    end

    if All(raiders, l('here')) and not player.inTargetDungeon then
        return 'go_in_dungeon'
    end

    local warlockInParty = Any(raiders, l('isWarlock')) or player.isWarlock
    if not warlockInParty then
        return DoSummon(raiders, lNot(l('here'))) or 'wait'
    end

    local warlockHere = Any(raiders, lAnd(l('isWarlock'), l('here'))) or (player.isWarlock)
    if not warlockHere then
        local summon = DoSummon(raiders, l('isWarlock'))
        if summon ~= nil then
            return summon
        end
    end

    local others_here = table.getn(SSUtils:Filter(raiders, l('here')))
    if others_here < 2 then
        return DoSummon(raiders, l('!here')) or 'wait'
    end

    if not player.inTargetDungeon then
        return 'go_in_dungeon'
    end

    return DoSummon(raiders, lNot(l('inTargetDungeon'))) or DoSummon(raiders, lNot(l('sameZoneAsPlayer'))) or 'wait'
end

function DoSummon(raiders, fn)
    local summonable = SSUtils:Filter(raiders, function(r)
        return not r.hasIncoming and fn(r)
    end)
    if table.getn(summonable) == 0 then
        return nil
    else
        return summonable
    end
end
