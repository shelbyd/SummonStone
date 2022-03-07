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

local EventsTriggeringRecalc = {"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", -- Enter combat
"PLAYER_REGEN_ENABLED", -- Leave combat
"GROUP_ROSTER_UPDATE"};

local EventFrame = CreateFrame("Frame", "SummonStone_EventFrame")

for _index, event in pairs(EventsTriggeringRecalc) do
    EventFrame:RegisterEvent(event)
end

EventFrame:SetScript("OnEvent", function(self, event, ...)
    Render()
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
    if UnitAffectingCombat("player") then
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
        local name = select(1, GetRaidRosterInfo(raiderIndex))
        local label = AceGUI:Create("Label")
        label:SetText(name)
        CurrentSummonFrame:AddChild(label)
    end
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
