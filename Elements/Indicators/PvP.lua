local _, UUF = ...

function UUF:CreateUnitPvPIndicator(unitFrame, unit)
    local PvPIndicatorDB = UUF.db.profile.Units.player.Indicators.PvP

    local PvPIndicator = unitFrame.HighLevelContainer:CreateTexture(UUF:FetchFrameName(unit) .. "_PvPIndicator", "OVERLAY", nil, 1)
    PvPIndicator:SetSize(PvPIndicatorDB.Size, PvPIndicatorDB.Size)
    PvPIndicator:SetPoint(PvPIndicatorDB.Layout[1], unitFrame.HighLevelContainer, PvPIndicatorDB.Layout[2], PvPIndicatorDB.Layout[3], PvPIndicatorDB.Layout[4])

    PvPIndicator.Badge = unitFrame.HighLevelContainer:CreateTexture(UUF:FetchFrameName(unit) .. "_PvPIndicatorBadge", "OVERLAY")
    PvPIndicator.Badge:SetSize(PvPIndicatorDB.Size * 5 / 3, PvPIndicatorDB.Size * 26 / 15)
    PvPIndicator.Badge:SetPoint("CENTER", PvPIndicator, "CENTER", 0, 0)

    -- Override the stock element update path: it shows the faction / honor
    -- badge whenever the unit is NOT PvP-flagged, which reads as an enabled
    -- PvP icon for players with war mode off. Only show the classic banner
    -- while the unit is actually PvP flagged (war mode, FFA, PvP realm in
    -- the wild).
    PvPIndicator.Override = function(self, event, unit)
        if unit and unit ~= self.__unit then return end
        unit = unit or self.__unit
        local element = self.PvPIndicator
        local isFFA = UnitIsPVPFreeForAll(unit)
        if not isFFA and not UnitIsPVP(unit) then
            element:Hide()
            element.Badge:Hide()
            return
        end
        element:SetTexture([[Interface\TargetingFrame\UI-PVP-]] .. (isFFA and "FFA" or UnitFactionGroup(unit)))
        element:SetTexCoord(0, 0.65625, 0, 0.65625)
        element:Show()
        element.Badge:Hide()
    end

    if PvPIndicatorDB.Enabled then
        unitFrame.PvPIndicator = PvPIndicator
    else
        PvPIndicator:Hide()
        PvPIndicator.Badge:Hide()
    end

    return PvPIndicator
end

function UUF:UpdateUnitPvPIndicator(unitFrame, unit)
    local PvPIndicatorDB = UUF.db.profile.Units.player.Indicators.PvP

    if PvPIndicatorDB.Enabled then
        unitFrame.PvPIndicator = unitFrame.PvPIndicator or UUF:CreateUnitPvPIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("PvPIndicator") then unitFrame:EnableElement("PvPIndicator") end

        if unitFrame.PvPIndicator then
            unitFrame.PvPIndicator:ClearAllPoints()
            unitFrame.PvPIndicator:SetSize(PvPIndicatorDB.Size, PvPIndicatorDB.Size)
            unitFrame.PvPIndicator:SetPoint(PvPIndicatorDB.Layout[1], unitFrame.HighLevelContainer, PvPIndicatorDB.Layout[2], PvPIndicatorDB.Layout[3], PvPIndicatorDB.Layout[4])
            unitFrame.PvPIndicator.Badge:ClearAllPoints()
            unitFrame.PvPIndicator.Badge:SetSize(PvPIndicatorDB.Size * 5 / 3, PvPIndicatorDB.Size * 26 / 15)
            unitFrame.PvPIndicator.Badge:SetPoint("CENTER", unitFrame.PvPIndicator, "CENTER", 0, 0)
            unitFrame.PvPIndicator:ForceUpdate()
        end
    else
        if not unitFrame.PvPIndicator then return end
        if unitFrame:IsElementEnabled("PvPIndicator") then unitFrame:DisableElement("PvPIndicator") end
        if unitFrame.PvPIndicator then
            unitFrame.PvPIndicator:Hide()
            unitFrame.PvPIndicator.Badge:Hide()
            unitFrame.PvPIndicator = nil
        end
    end
end

-- War mode toggling fires PLAYER_FLAGS_CHANGED, which the element's registered
-- events don't cover; refresh the indicator so it updates promptly.
local PvPEventFrame = CreateFrame("Frame")
PvPEventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
PvPEventFrame:SetScript("OnEvent", function()
    if UUF.PLAYER then UUF:UpdateUnitPvPIndicator(UUF.PLAYER, "player") end
end)
