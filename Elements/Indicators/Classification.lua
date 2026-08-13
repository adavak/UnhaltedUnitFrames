local _, UUF = ...

local function UpdateClassificationTexture(ClassificationIndicator, _, classification)
	local ClassificationIndicatorDB = UUF.db.profile.Units.target.Indicators.Classification
	local ClassificationTextures = UUF.ClassificationTextures[ClassificationIndicatorDB.Texture]
	if ClassificationIndicatorDB.Texture == "CLASSIFICATION0" or ClassificationIndicatorDB.Texture == "CLASSIFICATION1" then
		if ClassificationTextures[classification] then
			ClassificationIndicator:SetAtlas(ClassificationTextures[classification], false)
		end
	else
		if ClassificationTextures[classification] then
			ClassificationIndicator:SetTexture(ClassificationTextures[classification])
		end
	end
end

function UUF:CreateUnitClassificationIndicator(unitFrame, unit)
	local ClassificationIndicatorDB = UUF.db.profile.Units.target.Indicators.Classification
	local ClassificationIndicator = unitFrame.HighLevelContainer:CreateTexture(UUF:FetchFrameName(unit) .. "_ClassificationIndicator", "OVERLAY")
	ClassificationIndicator:SetSize(ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Size)
	ClassificationIndicator:SetPoint(ClassificationIndicatorDB.Layout[1], unitFrame.HighLevelContainer, ClassificationIndicatorDB.Layout[2], ClassificationIndicatorDB.Layout[3], ClassificationIndicatorDB.Layout[4])
	ClassificationIndicator.PostUpdate = UpdateClassificationTexture

	if ClassificationIndicatorDB.Enabled then
		unitFrame.ClassificationIndicator = ClassificationIndicator
	else
		ClassificationIndicator:Hide()
	end

	return ClassificationIndicator
end

function UUF:UpdateUnitClassificationIndicator(unitFrame, unit)
	local ClassificationIndicatorDB = UUF.db.profile.Units.target.Indicators.Classification

	if ClassificationIndicatorDB.Enabled then
		unitFrame.ClassificationIndicator = unitFrame.ClassificationIndicator or UUF:CreateUnitClassificationIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ClassificationIndicator") then unitFrame:EnableElement("ClassificationIndicator") end

		unitFrame.ClassificationIndicator:ClearAllPoints()
		unitFrame.ClassificationIndicator:SetSize(ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Size)
		unitFrame.ClassificationIndicator:SetPoint(ClassificationIndicatorDB.Layout[1], unitFrame.HighLevelContainer, ClassificationIndicatorDB.Layout[2], ClassificationIndicatorDB.Layout[3], ClassificationIndicatorDB.Layout[4])
		unitFrame.ClassificationIndicator:ForceUpdate()
	elseif unitFrame.ClassificationIndicator then
		if unitFrame:IsElementEnabled("ClassificationIndicator") then unitFrame:DisableElement("ClassificationIndicator") end
		unitFrame.ClassificationIndicator:Hide()
		unitFrame.ClassificationIndicator = nil
	end
end

-- oUF element registration (moved from Libraries/oUF_Elements)
local oUF = UUF.oUF

local ICONS = {
	elite = 'nameplates-icon-elite-gold',
	worldboss = 'nameplates-icon-elite-gold',
	rareelite = 'nameplates-icon-elite-silver',
	rare = 'nameplates-icon-elite-silver',
}

local function ClassificationIndicatorUpdate(self, event, unit)
	if unit ~= self.unit then return end
	local element = self.ClassificationIndicator
	if not element then return end
	if element.PreUpdate then element:PreUpdate(unit) end
	local classification = UnitClassification(unit)
	local icon = ICONS[classification]
	if icon then
		element:SetAtlas(icon, element.useAtlasSize)
		element:Show()
	else
		element:Hide()
	end
	if element.PostUpdate then return element:PostUpdate(unit, classification) end
end

local function ClassificationIndicatorPath(self, ...)
	return (self.ClassificationIndicator.Override or ClassificationIndicatorUpdate)(self, ...)
end

local function ClassificationIndicatorForceUpdate(element)
	return ClassificationIndicatorPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function ClassificationIndicatorEnable(self)
	local element = self.ClassificationIndicator
	if element then
		element.__owner = self
		element.ForceUpdate = ClassificationIndicatorForceUpdate
		self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', ClassificationIndicatorPath)
		return true
	end
end

local function ClassificationIndicatorDisable(self)
	local element = self.ClassificationIndicator
	if element then
		element:Hide()
		self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', ClassificationIndicatorPath)
	end
end

oUF:AddElement('ClassificationIndicator', ClassificationIndicatorPath, ClassificationIndicatorEnable, ClassificationIndicatorDisable)
