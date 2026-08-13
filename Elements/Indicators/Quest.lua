local _, UUF = ...

local function UpdateQuestTexture(QuestIndicator)
    local QuestIndicatorDB = UUF.db.profile.Units.target.Indicators.Quest
    QuestIndicator:SetTexture(UUF.QuestTextures[QuestIndicatorDB.Texture] or UUF.QuestTextures.DEFAULT)
    if QuestIndicatorDB.Texture == "QUEST0" then
        QuestIndicator:SetHeight(QuestIndicatorDB.Size)
        QuestIndicator:SetWidth(QuestIndicatorDB.Size * 0.35)
    else
        QuestIndicator:SetSize(QuestIndicatorDB.Size, QuestIndicatorDB.Size)
    end
end

function UUF:CreateUnitQuestIndicator(unitFrame, unit)
    local QuestIndicatorDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Quest

    local QuestIndicator = unitFrame.HighLevelContainer:CreateTexture(UUF:FetchFrameName(unit) .. "_QuestIndicator", "OVERLAY")
    QuestIndicator:SetPoint(QuestIndicatorDB.Layout[1], unitFrame.HighLevelContainer, QuestIndicatorDB.Layout[2], QuestIndicatorDB.Layout[3], QuestIndicatorDB.Layout[4])
    QuestIndicator.PostUpdate = UpdateQuestTexture
    UpdateQuestTexture(QuestIndicator)

    if QuestIndicatorDB.Enabled then
        unitFrame.QuestUnitIndicator = QuestIndicator
        unitFrame.QuestUnitIndicator:Show()
    else
        if unitFrame:IsElementEnabled("QuestUnitIndicator") then unitFrame:DisableElement("QuestUnitIndicator") end
        QuestIndicator:Hide()
    end

    return QuestIndicator
end

function UUF:UpdateUnitQuestIndicator(unitFrame, unit)
    local QuestIndicatorDB = UUF.db.profile.Units[UUF:GetNormalizedUnit(unit)].Indicators.Quest

    if QuestIndicatorDB.Enabled then
        unitFrame.QuestUnitIndicator = unitFrame.QuestUnitIndicator or UUF:CreateUnitQuestIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("QuestUnitIndicator") then unitFrame:EnableElement("QuestUnitIndicator") end

        if unitFrame.QuestUnitIndicator then
            unitFrame.QuestUnitIndicator:ClearAllPoints()
            unitFrame.QuestUnitIndicator:SetPoint(QuestIndicatorDB.Layout[1], unitFrame.HighLevelContainer, QuestIndicatorDB.Layout[2], QuestIndicatorDB.Layout[3], QuestIndicatorDB.Layout[4])
            unitFrame.QuestUnitIndicator:ForceUpdate()
        end
    else
        if not unitFrame.QuestUnitIndicator then return end
        if unitFrame:IsElementEnabled("QuestUnitIndicator") then unitFrame:DisableElement("QuestUnitIndicator") end
        if unitFrame.QuestUnitIndicator then
            unitFrame.QuestUnitIndicator:Hide()
            unitFrame.QuestUnitIndicator = nil
        end
    end
end

-- oUF element registration (moved from Libraries/oUF_Elements)
local oUF = UUF.oUF

local function QuestIndicatorUpdate(self, event, unit)
	if unit ~= self.unit then return end
	local element = self.QuestUnitIndicator
	if not element then return end
	if element.PreUpdate then element:PreUpdate() end
	local isQuestUnit = UnitIsQuestBoss(unit) or C_QuestLog.UnitIsRelatedToActiveQuest(unit)
	element:SetShown(isQuestUnit)
	if element.PostUpdate then return element:PostUpdate(isQuestUnit) end
end

local function QuestIndicatorPath(self, ...)
	return (self.QuestUnitIndicator.Override or QuestIndicatorUpdate)(self, ...)
end

local function QuestIndicatorForceUpdate(element)
	return QuestIndicatorPath(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function QuestIndicatorEnable(self)
	local element = self.QuestUnitIndicator
	if element then
		element.__owner = self
		element.ForceUpdate = QuestIndicatorForceUpdate
		self:RegisterEvent("QUEST_LOG_UPDATE", QuestIndicatorPath, true)
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", QuestIndicatorPath)
		return true
	end
end

local function QuestIndicatorDisable(self)
	local element = self.QuestUnitIndicator
	if element then
		element:Hide()
		self:UnregisterEvent("QUEST_LOG_UPDATE", QuestIndicatorPath)
		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", QuestIndicatorPath)
	end
end

oUF:AddElement("QuestUnitIndicator", QuestIndicatorPath, QuestIndicatorEnable, QuestIndicatorDisable)
