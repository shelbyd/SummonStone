local EventsTriggeringRecalc = {"PLAYER_ENTERING_WORLD"};

local EventFrame = CreateFrame("Frame", "SummonStone_EventFrame")

for _index, event in pairs(EventsTriggeringRecalc) do
    EventFrame:RegisterEvent(event)
end

EventFrame:SetScript("OnEvent", function(self, event, ...)
    print("Got event", event)
    local inCombat = UnitAffectingCombat("player")
    if (inCombat) then
        print("Hiding MainFrame")
        MainFrame:Hide()
    end
end)

local MainFrame = CreateFrame("Frame", "SummonStone_MainFrame", UIParent, "BasicFrameTemplateWithInset");

MainFrame:SetResizable(true)
MainFrame:SetMinResize(100, 100)
MainFrame:SetMaxResize(500, 500)

MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)

MainFrame:SetSize(300, 360)
MainFrame:SetPoint("CENTER", UIParent, "CENTER")

local MainFrameResize = CreateFrame("Button", "SummonStone_Resize", MainFrame)
MainFrameResize:EnableMouse(true)
MainFrameResize:SetPoint("BOTTOMRIGHT")
MainFrameResize:SetSize(16, 16)
MainFrameResize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
MainFrameResize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
MainFrameResize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
MainFrameResize:SetScript("OnMouseDown", function(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end)
MainFrameResize:SetScript("OnMouseUp", function(self)
    self:GetParent():StopMovingOrSizing()
end)
