local _, UUF = ...
local LSM = UUF.LSM
local AG = UUF.AG
local GUIWidgets = UUF.GUIWidgets
local UUFGUI = {}
local L = LibStub("AceLocale-3.0"):GetLocale("UnhaltedUnitFrames")
local isGUIOpen = false
local reloadRequired = false
local AdditionalSpellIDsTooltip = L["|cFF8080FFBuffs|r can only be filtered on |cFF40FF40Friendly|r Units.\n|cFF8080FFDebuffs|r can only be filtered on |cFFFF4040Unfriendly|r Units.\n|cFF8080FFLeft-Click|r on any existing |cFF8080FFSpellID|r to remove it from the list.\n|cFF8080FFFilters|r & |cFF8080FFSpellIDs|r can be used in combination."]
-- Stores last selected tabs: [unit] = { mainTab = "CastBar", subTabs = { CastBar = "Bar" } }
local lastSelectedUnitTabs = {}

local function GetUnitDB(unit)
	return UUF:GetUnitDB(nil, unit)
end

local function GetDefaultUnitDB(unit)
	return UUF:GetUnitDB(nil, unit, UUF:GetDefaultDB().profile.Units)
end

local function SaveSubTab(unit, tabName, subTabValue)
    if not lastSelectedUnitTabs[unit] then lastSelectedUnitTabs[unit] = {} end
    if not lastSelectedUnitTabs[unit].subTabs then lastSelectedUnitTabs[unit].subTabs = {} end
    lastSelectedUnitTabs[unit].subTabs[tabName] = subTabValue
end

local function GetSavedSubTab(unit, tabName, defaultValue)
    return lastSelectedUnitTabs[unit] and lastSelectedUnitTabs[unit].subTabs and lastSelectedUnitTabs[unit].subTabs[tabName] or defaultValue
end

local function GetSavedMainTab(unit, defaultValue)
    return lastSelectedUnitTabs[unit] and lastSelectedUnitTabs[unit].mainTab or defaultValue
end

local function UpdateUnitSettings(unit, updateCallback, element)
	if unit == "boss" and UUF.BOSS_TEST_MODE or unit == "party" and UUF.PARTY_TEST_MODE or unit == "raid" and UUF.RAID_TEST_MODE then
		UUF:UpdateTestEnvironment(unit, element or "all")
	elseif unit == "boss" then
		UUF:UpdateBossFrames()
	elseif unit == "party" then
		UUF:UpdateGroupFrame("party")
	elseif unit == "raid" then
		UUF:UpdateGroupFrame("raid")
	elseif unit == "augmentation" then
		UUF:UpdateAugmentationRaidFrames()
	elseif updateCallback then
		updateCallback()
	end
end

local UnitDBToUnitPrettyName = {
    player = L["Player"],
    target = L["Target"],
    targettarget = L["Target of Target"],
    focus = L["Focus"],
    focustarget = L["Focus Target"],
    pet = L["Pet"],
    boss = L["Boss"],
    party = L["Party"],
    raid = L["Raid"],
	augmentation = L["Augmentation"],
}


local CooldownBreakpointStyles = {
    {
        decimalSeconds = L["Decimal Seconds (1.1)"],
        seconds = L["Seconds (10s)"],
        secondsOnly = L["Seconds (10)"],
        clock = L["Clock (1:10)"],
        minutes = L["Minutes (2m)"],
        hours = L["Hours (1h)"],
        days = L["Days (1d)"],
    },
    {"decimalSeconds", "seconds", "secondsOnly", "clock", "minutes", "hours", "days"},
}

local CooldownBreakpointSettings = {
    decimalSeconds = {step = 0.1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%.1f"},
    seconds = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%ds"},
    secondsOnly = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, min = 1, format = "%d"},
    clock = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%d:%02d"},
    minutes = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%dm"},
    hours = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%dh"},
    days = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%dd"},
}

local AnchorPoints = { { ["TOPLEFT"] = L["Top Left"], ["TOP"] = L["Top"], ["TOPRIGHT"] = L["Top Right"], ["LEFT"] = L["Left"], ["CENTER"] = L["Center"], ["RIGHT"] = L["Right"], ["BOTTOMLEFT"] = L["Bottom Left"], ["BOTTOM"] = L["Bottom"], ["BOTTOMRIGHT"] = L["Bottom Right"] }, { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT", } }
local AuraAnchorParents = {{Frame = L["Unit Frame"], Health = L["Health Bar"]}, {"Frame", "Health"}}
local FrameStrataList = {{ ["BACKGROUND"] = L["Background"], ["LOW"] = L["Low"], ["MEDIUM"] = L["Medium"], ["HIGH"] = L["High"], ["DIALOG"] = L["Dialog"], ["FULLSCREEN"] = L["Fullscreen"], ["FULLSCREEN_DIALOG"] = L["Fullscreen Dialog"], ["TOOLTIP"] = L["Tooltip"] }, { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }}
local TopBottomList = {{ ["TOP"] = L["Top"], ["BOTTOM"] = L["Bottom"] }, { "TOP", "BOTTOM" }}
local RaidGrowthDirectionList = {
    {
        ["RIGHT_DOWN"] = L["Right to Left, then Down"],
        ["RIGHT_UP"] = L["Right to Left, then Up"],
        ["LEFT_DOWN"] = L["Left to Right, then Down"],
        ["LEFT_UP"] = L["Left to Right, then Up"],
        ["UP_RIGHT"] = L["Top to Bottom, then Right"],
        ["UP_LEFT"] = L["Top to Bottom, then Left"],
        ["DOWN_RIGHT"] = L["Bottom to Top, then Right"],
        ["DOWN_LEFT"] = L["Bottom to Top, then Left"],
    },
    {"RIGHT_DOWN", "RIGHT_UP", "LEFT_DOWN", "LEFT_UP", "UP_RIGHT", "UP_LEFT", "DOWN_RIGHT", "DOWN_LEFT"},
}
local Power = {
    [0] = L["Mana"],
    [1] = L["Rage"],
    [2] = L["Focus"],
    [3] = L["Energy"],
    [4] = L["Combo Points"],
    [5] = L["Runes"],
    [6] = L["Runic Power"],
    [7] = L["Soul Shards"],
    [8] = L["Astral Power"],
    [9] = L["Holy Power"],
    [11] = L["Maelstrom"],
    [12] = L["Chi"],
    [13] = L["Insanity"],
    [17] = L["Fury"],
    [16] = L["Arcange Charges"],
    [18] = L["Pain"],
    [19] = L["Essences"],
}

local Reaction = {
    [1] = L["Hated"],
    [2] = L["Hostile"],
    [3] = L["Unfriendly"],
    [4] = L["Neutral"],
    [5] = L["Friendly"],
    [6] = L["Honored"],
    [7] = L["Revered"],
    [8] = L["Exalted"],
}

local Status = {
    Tapped = L["Tapped"],
    Disconnected = L["Disconnected"],
    DeadBackdrop = L["Dead Backdrop"],
}

local Threat = {
    [0] = L["No Threat"],
    [1] = L["High Threat"],
    [2] = L["Insecure Tanking"],
    [3] = L["Secure Tanking"],
}

local StatusTextures = {
    Combat = {
        ["DEFAULT"] = "|TInterface\\CharacterFrame\\UI-StateIcon:20:20:0:0:64:64:32:64:0:31|t",
        ["COMBAT0"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat0.tga:18:18|t",
        ["COMBAT1"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat1.tga:18:18|t",
        ["COMBAT2"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat2.tga:18:18|t",
        ["COMBAT3"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat3.tga:18:18|t",
        ["COMBAT4"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat4.tga:18:18|t",
        ["COMBAT5"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat5.tga:18:18|t",
        ["COMBAT6"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat6.tga:18:18|t",
        ["COMBAT7"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat7.tga:18:18|t",
        ["COMBAT8"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Combat\\Combat8.png:18:18|t",
    },

    Resting = {
        ["DEFAULT"] = "|TInterface\\CharacterFrame\\UI-StateIcon:18:18:0:0:64:64:0:32:0:27|t",
        ["RESTING0"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting0.tga:18:18|t",
        ["RESTING1"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting1.tga:18:18|t",
        ["RESTING2"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting2.tga:18:18|t",
        ["RESTING3"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting3.tga:18:18|t",
        ["RESTING4"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting4.tga:18:18|t",
        ["RESTING5"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting5.tga:18:18|t",
        ["RESTING6"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting6.tga:18:18|t",
        ["RESTING7"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting7.tga:18:18|t",
        ["RESTING8"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Status\\Resting\\Resting8.png:18:18|t",
    }
}

local RoleTextures = {
	["Default"] = "|A:UI-LFG-RoleIcon-Tank-Micro-Raid:18:18|a |A:UI-LFG-RoleIcon-Healer-Micro-Raid:18:18|a |A:UI-LFG-RoleIcon-DPS-Micro-Raid:18:18|a",
	["Blizzard"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Blizzard\\Tank.tga:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Blizzard\\Healer.tga:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Blizzard\\DPS.tga:18:18|t",
	["Colour"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Colour\\Tank.tga:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Colour\\Healer.tga:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Colour\\DPS.tga:18:18|t",
	["White"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\White\\Tank.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\White\\Healer.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\White\\DPS.png:18:18|t",
	["ElvUI"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\ElvUI\\Tank.tga:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\ElvUI\\Healer.tga:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\ElvUI\\DPS.tga:18:18|t",
	["Square"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Square\\Tank.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Square\\Healer.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Role\\Square\\DPS.png:18:18|t",
}

local function EnableAurasTestMode(unit)
	UUF.AURA_TEST_MODE = true
	if unit == "augmentation" then
		UUF:ForEachAugmentationRaidFrame(function(unitFrame, frameUnit)
			if frameUnit then UUF:CreateTestAuras(unitFrame, frameUnit) end
		end, false)
	elseif unit == "party" or unit == "raid" or unit == "boss" then
		UUF:UpdateTestEnvironment(unit, "Auras")
	else
		UUF:CreateTestAuras(UUF[unit:upper()], unit)
	end
end

local function DisableAurasTestMode(unit)
	UUF.AURA_TEST_MODE = false
	if unit == "augmentation" then
		UUF:ForEachAugmentationRaidFrame(function(unitFrame, frameUnit)
			if frameUnit then UUF:CreateTestAuras(unitFrame, frameUnit) end
		end, false)
	elseif unit == "party" or unit == "raid" or unit == "boss" then
		UUF:UpdateTestEnvironment(unit, "Auras")
	else
		UUF:CreateTestAuras(UUF[unit:upper()], unit)
	end
end

local function EnableCastBarTestMode(unit)
    UUF.CASTBAR_TEST_MODE = true
    UUF:CreateTestCastBar(UUF[unit:upper()], unit)
end

local function DisableCastBarTestMode(unit)
    UUF.CASTBAR_TEST_MODE = false
    UUF:CreateTestCastBar(UUF[unit:upper()], unit)
end

local function EnableBossFramesTestMode()
	if UUF.BOSS_TEST_MODE then return end
    UUF.BOSS_TEST_MODE = true
    UUF:UpdateTestEnvironment("boss", "all")
end

local function DisableBossFramesTestMode()
	if not UUF.BOSS_TEST_MODE then return end
    UUF.BOSS_TEST_MODE = false
    UUF:UpdateTestEnvironment("boss", "all")
end

local function EnablePartyFramesTestMode()
	if UUF.PARTY_TEST_MODE then return end
	UUF.PARTY_TEST_MODE = true
	UUF:EnableTestGroupFrames("party")
end

local function DisablePartyFramesTestMode()
	if not UUF.PARTY_TEST_MODE then return end
	UUF.PARTY_TEST_MODE = false
	UUF:UpdateTestEnvironment("party", "all")
end

local function EnableRaidFramesTestMode()
	if UUF.RAID_TEST_MODE then return end
	UUF.RAID_TEST_MODE = true
	UUF:EnableTestGroupFrames("raid")
end

local function DisableRaidFramesTestMode()
	if not UUF.RAID_TEST_MODE then return end
	UUF.RAID_TEST_MODE = false
	UUF:UpdateTestEnvironment("raid", "all")
end

local function DisableAllTestModes()
	UUF.AURA_TEST_MODE = false
	UUF.CASTBAR_TEST_MODE = false
	UUF.BOSS_TEST_MODE = false
	UUF.PARTY_TEST_MODE = false
	UUF.RAID_TEST_MODE = false
	UUF.MOVERS_UNLOCKED = false
	UUF:ForEachUnitDB(function(_, unit)
		if unit == "party" or unit == "raid" or unit == "augmentation" then
			DisableAurasTestMode(unit)
		elseif UUF[unit:upper()] then
			UUF:CreateTestAuras(UUF[unit:upper()], unit)
			UUF:CreateTestCastBar(UUF[unit:upper()], unit)
		end
	end)
	UUF:UpdateTestEnvironment("boss", "all")
	UUF:UpdateTestEnvironment("party", "all")
	UUF:UpdateTestEnvironment("raid", "all")
	for _, frameMover in pairs(UUF.MOVERS or {}) do frameMover:Hide() end
end

local function GenerateSupportText(parentFrame)
    local SupportOptions = {
        -- "Support Me on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Ko-Fi.png:13:18|t |cFF8080FFKo-Fi|r!",
        -- "Support Me on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Patreon.png:14:14|t |cFF8080FFPatreon|r!",
        -- "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\PayPal.png:20:18|t |cFF8080FFPayPal Donations|r are appreciated!",
        L["Join the |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Discord.png:18:18|t |cFF8080FFDiscord|r Community!"],
        L["Report Issues / Feedback on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\GitHub.png:18:18|t |cFF8080FFGitHub|r!"],
        L["Follow Me on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Twitch.png:18:14|t |cFF8080FFTwitch|r!"],
        L["|cFF8080FFSupport|r is truly appreciated |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Emotes\\peepoLove.png:18:18|t "] .. L["|cFF8080FFDevelopment|r takes time & effort."]
    }
    parentFrame.statustext:SetText(SupportOptions[math.random(1, #SupportOptions)])
end

local function BuildMainNavigationTree()
	local unitNavigation = {
		{ text = L["Player"], value = "Player" },
		{ text = L["Target"], value = "Target" },
		{ text = L["Target of Target"], value = "TargetTarget" },
		{ text = L["Pet"], value = "Pet" },
		{ text = L["Focus"], value = "Focus" },
		{ text = L["Focus Target"], value = "FocusTarget" },
		{ text = L["Party"], value = "Party" },
		{ text = L["Raid"], value = "Raid" },
	}
	if UUF:IsAugmentationEvoker() then unitNavigation[#unitNavigation + 1] = { text = L["Augmentation"], value = "Augmentation" } end
	unitNavigation[#unitNavigation + 1] = { text = L["Boss"], value = "Boss" }
	return {
		{ text = L["General"], value = "General" },
		{text = L["Global"], value = "Global", children = {
			{text = L["Toggles"], value = "GlobalToggles"},
			{text = L["Fonts"], value = "GlobalFonts"},
			{text = L["Textures"], value = "GlobalTextures"},
			{text = L["Range"], value = "GlobalRange"},
			{text = L["Tag Settings"], value = "GlobalTags"},
			{text = L["Cooldown Text"], value = "CooldownText"},
		}},
		{text = L["Units"], value = "Units", children = unitNavigation},
		{ text = L["Tags"], value = "Tags" },
		{ text = L["Profiles"], value = "Profiles" },
	}
end

local function CreateUIScaleSettings(containerParent)
    local Container = GUIWidgets.CreateInlineGroup(containerParent, L["UI Scale"])
    GUIWidgets.CreateInformationTag(Container,L["These options allow you to adjust the UI Scale beyond the means that |cFF00B0F7Blizzard|r provides. If you encounter issues, please |cFFFF4040disable|r this feature."])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable UI Scale"])
    Toggle:SetValue(UUF.db.profile.General.UIScale.Enabled)
    Toggle:SetFullWidth(true)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.UIScale.Enabled = value UUF:SetUIScale() GUIWidgets.DeepDisable(Container, not value, Toggle) end)
    Toggle:SetRelativeWidth(0.5)
    Container:AddChild(Toggle)

    local Slider = AG:Create("Slider")
    Slider:SetLabel(L["UI Scale"])
    Slider:SetValue(UUF.db.profile.General.UIScale.Scale)
    Slider:SetSliderValues(0.3, 1.5, 0.01)
    Slider:SetFullWidth(true)
    Slider:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.UIScale.Scale = value UUF:SetUIScale() end)
    Slider:SetRelativeWidth(0.5)
    Container:AddChild(Slider)

    GUIWidgets.CreateHeader(Container, L["Presets"])

    local PixelPerfectButton = AG:Create("Button")
    PixelPerfectButton:SetText(L["Pixel Perfect Scale"])
    PixelPerfectButton:SetRelativeWidth(0.33)
    PixelPerfectButton:SetCallback("OnClick", function() local pixelScale = UUF:GetPixelPerfectScale() UUF.db.profile.General.UIScale.Scale = pixelScale UUF:SetUIScale() Slider:SetValue(pixelScale) end)
    PixelPerfectButton:SetCallback("OnEnter", function() GameTooltip:SetOwner(PixelPerfectButton.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(string.format(L["Recommended UI Scale: |cFF8080FF%s|r"], UUF:GetPixelPerfectScale()), 1, 1, 1, false) GameTooltip:Show() end)
    PixelPerfectButton:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    Container:AddChild(PixelPerfectButton)

    local TenEighytyPButton = AG:Create("Button")
    TenEighytyPButton:SetText(L["1080p Scale"])
    TenEighytyPButton:SetRelativeWidth(0.33)
    TenEighytyPButton:SetCallback("OnClick", function() UUF.db.profile.General.UIScale.Scale = 0.7111111111111 UUF:SetUIScale() Slider:SetValue(0.7111111111111) end)
    TenEighytyPButton:SetCallback("OnEnter", function() GameTooltip:SetOwner(TenEighytyPButton.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(L["UI Scale: |cFF8080FF0.7111111111111|r"], 1, 1, 1, false) GameTooltip:Show() end)
    TenEighytyPButton:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    Container:AddChild(TenEighytyPButton)

    local FourteenFortyPButton = AG:Create("Button")
    FourteenFortyPButton:SetText(L["1440p Scale"])
    FourteenFortyPButton:SetRelativeWidth(0.33)
    FourteenFortyPButton:SetCallback("OnClick", function() UUF.db.profile.General.UIScale.Scale = 0.5333333333333 UUF:SetUIScale() Slider:SetValue(0.5333333333333) end)
    FourteenFortyPButton:SetCallback("OnEnter", function() GameTooltip:SetOwner(FourteenFortyPButton.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(L["UI Scale: |cFF8080FF0.5333333333333|r"], 1, 1, 1, false) GameTooltip:Show() end)
    FourteenFortyPButton:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    Container:AddChild(FourteenFortyPButton)

    GUIWidgets.DeepDisable(Container, not UUF.db.profile.General.UIScale.Enabled, Toggle)
end

local function CreateFontSettings(containerParent)
    local Container = GUIWidgets.CreateInlineGroup(containerParent, L["Fonts"])

    GUIWidgets.CreateInformationTag(Container,L["Fonts are applied to all Unit Frames & Elements where appropriate. More fonts can be added via |cFF8080FFSharedMedia|r."])

    local FontDropdown = AG:Create("LSM30_Font")
    FontDropdown:SetList(LSM:HashTable("font"))
    FontDropdown:SetLabel(L["Font"])
    FontDropdown:SetValue(UUF.db.profile.General.Fonts.Font)
    FontDropdown:SetRelativeWidth(0.5)
	FontDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) UUF.db.profile.General.Fonts.Font = value reloadRequired = true UUF:ResolveLSM() UUF:UpdateAllUnitFrames() UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    Container:AddChild(FontDropdown)

    local FontFlagDropdown = AG:Create("Dropdown")
    FontFlagDropdown:SetList({[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick Outline"], ["MONOCHROME"] = L["Monochrome"], ["MONOCHROMEOUTLINE"] = L["Monochrome Outline"], ["MONOCHROMETHICKOUTLINE"] = L["Monochrome Thick Outline"], ["OUTLINE, SLUG"] = L["Outline Slug"]})
    FontFlagDropdown:SetLabel(L["Font Flag"])
    FontFlagDropdown:SetValue(UUF.db.profile.General.Fonts.FontFlag)
    FontFlagDropdown:SetRelativeWidth(0.5)
	FontFlagDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) UUF.db.profile.General.Fonts.FontFlag = value reloadRequired = true UUF:ResolveLSM() UUF:UpdateAllUnitFrames() UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    Container:AddChild(FontFlagDropdown)

    local SimpleGroup = AG:Create("SimpleGroup")
    SimpleGroup:SetFullWidth(true)
    SimpleGroup:SetLayout("Flow")
    Container:AddChild(SimpleGroup)

    GUIWidgets.CreateHeader(SimpleGroup, L["Font Shadows"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable Font Shadows"])
    Toggle:SetValue(UUF.db.profile.General.Fonts.Shadow.Enabled)
    Toggle:SetFullWidth(true)
	Toggle:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.Fonts.Shadow.Enabled = value reloadRequired = true UUF:ResolveLSM() GUIWidgets.DeepDisable(SimpleGroup, not UUF.db.profile.General.Fonts.Shadow.Enabled, Toggle) UUF:UpdateAllUnitFrames() UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    Toggle:SetRelativeWidth(0.5)
    SimpleGroup:AddChild(Toggle)

    local ColorPicker = AG:Create("ColorPicker")
    ColorPicker:SetLabel(L["Colour"])
    ColorPicker:SetColor(unpack(UUF.db.profile.General.Fonts.Shadow.Colour))
    ColorPicker:SetFullWidth(true)
	ColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) UUF.db.profile.General.Fonts.Shadow.Colour = {r, g, b, a} reloadRequired = true UUF:ResolveLSM() UUF:UpdateAllUnitFrames() UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    ColorPicker:SetRelativeWidth(0.5)
    SimpleGroup:AddChild(ColorPicker)

    local XSlider = AG:Create("Slider")
    XSlider:SetLabel(L["Offset X"])
    XSlider:SetValue(UUF.db.profile.General.Fonts.Shadow.XPos)
    XSlider:SetSliderValues(-5, 5, 1)
    XSlider:SetFullWidth(true)
	XSlider:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.Fonts.Shadow.XPos = value reloadRequired = true UUF:ResolveLSM() UUF:UpdateAllUnitFrames() UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    XSlider:SetRelativeWidth(0.5)
    SimpleGroup:AddChild(XSlider)

    local YSlider = AG:Create("Slider")
    YSlider:SetLabel(L["Offset Y"])
    YSlider:SetValue(UUF.db.profile.General.Fonts.Shadow.YPos)
    YSlider:SetSliderValues(-5, 5, 1)
    YSlider:SetFullWidth(true)
	YSlider:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.Fonts.Shadow.YPos = value reloadRequired = true UUF:ResolveLSM() UUF:UpdateAllUnitFrames() UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    YSlider:SetRelativeWidth(0.5)
    SimpleGroup:AddChild(YSlider)

    GUIWidgets.DeepDisable(SimpleGroup, not UUF.db.profile.General.Fonts.Shadow.Enabled, Toggle)
end

local function CreateTextureSettings(containerParent)
    local Container = GUIWidgets.CreateInlineGroup(containerParent, L["Textures"])

    GUIWidgets.CreateInformationTag(Container,L["Textures are applied to all Unit Frames & Elements where appropriate. More textures can be added via |cFF8080FFSharedMedia|r."])

    local ForegroundTextureDropdown = AG:Create("LSM30_Statusbar")
    ForegroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    ForegroundTextureDropdown:SetLabel(L["Foreground Texture"])
    ForegroundTextureDropdown:SetValue(UUF.db.profile.General.Textures.Foreground)
    ForegroundTextureDropdown:SetRelativeWidth(0.5)
    ForegroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) UUF.db.profile.General.Textures.Foreground = value UUF:ResolveLSM() UUF:UpdateAllUnitFrames() end)
    Container:AddChild(ForegroundTextureDropdown)

    local BackgroundTextureDropdown = AG:Create("LSM30_Statusbar")
    BackgroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    BackgroundTextureDropdown:SetLabel(L["Background Texture"])
    BackgroundTextureDropdown:SetValue(UUF.db.profile.General.Textures.Background)
    BackgroundTextureDropdown:SetRelativeWidth(0.5)
    BackgroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) UUF.db.profile.General.Textures.Background = value UUF:ResolveLSM() UUF:UpdateAllUnitFrames() end)
    Container:AddChild(BackgroundTextureDropdown)

    local MouseoverStyleDropdown = AG:Create("Dropdown")
    MouseoverStyleDropdown:SetList({["SELECT"] = L["Set a Highlight Texture..."], ["BORDER"] = L["Border"], ["OVERLAY"] = L["Overlay"], ["GRADIENT"] = L["Gradient"] })
    MouseoverStyleDropdown:SetLabel(L["Highlight Style"])
    MouseoverStyleDropdown:SetValue("SELECT")
    MouseoverStyleDropdown:SetRelativeWidth(0.5)
    MouseoverStyleDropdown:SetCallback("OnValueChanged", function(_, _, value) UUF:ForEachUnitDB(function(unitDB) if unitDB.Indicators.Mouseover and unitDB.Indicators.Mouseover.Enabled then unitDB.Indicators.Mouseover.Style = value end end) UUF:UpdateAllUnitFrames() MouseoverStyleDropdown:SetValue("SELECT") end)
    MouseoverStyleDropdown:SetCallback("OnEnter", function() GameTooltip:SetOwner(MouseoverStyleDropdown.frame, "ANCHOR_BOTTOM") GameTooltip:AddLine(L["Set |cFF8080FFMouseover Highlight Style|r for all units. |cFF8080FFColour|r & |cFF8080FFAlpha|r can be adjusted per unit."], 1, 1, 1) GameTooltip:Show() end)
    MouseoverStyleDropdown:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    Container:AddChild(MouseoverStyleDropdown)

    local MouseoverHighlightSlider = AG:Create("Slider")
    MouseoverHighlightSlider:SetLabel(L["Highlight Opacity"])
    MouseoverHighlightSlider:SetValue(0.8)
    MouseoverHighlightSlider:SetSliderValues(0.0, 1.0, 0.01)
    MouseoverHighlightSlider:SetRelativeWidth(0.5)
    MouseoverHighlightSlider:SetIsPercent(true)
    MouseoverHighlightSlider:SetCallback("OnValueChanged", function(_, _, value) UUF:ForEachUnitDB(function(unitDB) if unitDB.Indicators.Mouseover and unitDB.Indicators.Mouseover.Enabled then unitDB.Indicators.Mouseover.HighlightOpacity = value end end) UUF:UpdateAllUnitFrames() end)
    Container:AddChild(MouseoverHighlightSlider)

    local ForegroundColourPicker = AG:Create("ColorPicker")
    ForegroundColourPicker:SetLabel(L["Foreground Colour"])
    local R, G, B = 8/255, 8/255, 8/255
    ForegroundColourPicker:SetColor(R, G, B)
    ForegroundColourPicker:SetRelativeWidth(0.5)
    ForegroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) UUF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.Foreground = {r, g, b} end) UUF:UpdateAllUnitFrames() end)
    Container:AddChild(ForegroundColourPicker)

    local ForegroundOpacitySlider = AG:Create("Slider")
    ForegroundOpacitySlider:SetLabel(L["Foreground Opacity"])
    ForegroundOpacitySlider:SetValue(0.8)
    ForegroundOpacitySlider:SetSliderValues(0.0, 1.0, 0.01)
    ForegroundOpacitySlider:SetRelativeWidth(0.5)
    ForegroundOpacitySlider:SetIsPercent(true)
    ForegroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) UUF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.ForegroundOpacity = value end) UUF:UpdateAllUnitFrames() end)
    Container:AddChild(ForegroundOpacitySlider)

    local BackgroundColourPicker = AG:Create("ColorPicker")
    BackgroundColourPicker:SetLabel(L["Background Colour"])
    local R2, G2, B2 = 8/255, 8/255, 8/255
    BackgroundColourPicker:SetColor(R2, G2, B2)
    BackgroundColourPicker:SetRelativeWidth(0.5)
    BackgroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) UUF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.Background = {r, g, b} end) UUF:UpdateAllUnitFrames() end)
    Container:AddChild(BackgroundColourPicker)

    local BackgroundOpacitySlider = AG:Create("Slider")
    BackgroundOpacitySlider:SetLabel(L["Background Opacity"])
    BackgroundOpacitySlider:SetValue(0.8)
    BackgroundOpacitySlider:SetSliderValues(0.0, 1.0, 0.01)
    BackgroundOpacitySlider:SetRelativeWidth(0.5)
    BackgroundOpacitySlider:SetIsPercent(true)
    BackgroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) UUF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.BackgroundOpacity = value end) UUF:UpdateAllUnitFrames() end)
    Container:AddChild(BackgroundOpacitySlider)

    local CastBarContainer = GUIWidgets.CreateInlineGroup(Container, L["Cast Bar"])

    local CastBarForegroundColourPicker = AG:Create("ColorPicker")
    CastBarForegroundColourPicker:SetLabel(L["Foreground Colour"])
    local CR, CG, CB = 128/255, 128/255, 255/255
    CastBarForegroundColourPicker:SetColor(CR, CG, CB)
    CastBarForegroundColourPicker:SetRelativeWidth(0.25)
    CastBarForegroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) UUF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.Foreground = {r, g, b} end end) UUF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarForegroundColourPicker)

    local CastBarBackgroundColourPicker = AG:Create("ColorPicker")
    CastBarBackgroundColourPicker:SetLabel(L["Background Colour"])
    local CR2, CG2, CB2 = 34/255, 34/255, 34/255
    CastBarBackgroundColourPicker:SetColor(CR2, CG2, CB2)
    CastBarBackgroundColourPicker:SetRelativeWidth(0.25)
    CastBarBackgroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) UUF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.Background = {r, g, b} end end) UUF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarBackgroundColourPicker)

    local CastBarNotInterruptibleColourPicker = AG:Create("ColorPicker")
    CastBarNotInterruptibleColourPicker:SetLabel(L["Not Interruptible Colour"])
    local CR3, CG3, CB3 = 255/255, 64/255, 64/255
    CastBarNotInterruptibleColourPicker:SetColor(CR3, CG3, CB3)
    CastBarNotInterruptibleColourPicker:SetRelativeWidth(0.25)
    CastBarNotInterruptibleColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) UUF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.NotInterruptibleColour = {r, g, b} end end) UUF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarNotInterruptibleColourPicker)

    local CastBarInterruptCooldownColourPicker = AG:Create("ColorPicker")
    CastBarInterruptCooldownColourPicker:SetLabel(L["Interrupt on Cooldown Colour"])
    local CR4, CG4, CB4 = 235/255, 90/255, 50/255
    CastBarInterruptCooldownColourPicker:SetColor(CR4, CG4, CB4)
    CastBarInterruptCooldownColourPicker:SetRelativeWidth(0.25)
    CastBarInterruptCooldownColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) UUF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.InterruptCooldownColour = {r, g, b} end end) UUF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarInterruptCooldownColourPicker)
end

local function CreateRangeSettings(containerParent)
    local RangeDB = UUF.db.profile.General.Range
    local Container = GUIWidgets.CreateInlineGroup(containerParent, L["Range"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable Range Fading"])
    Toggle:SetValue(RangeDB.Enabled)
    Toggle:SetFullWidth(true)
	Toggle:SetCallback("OnValueChanged", function(_, _, value) RangeDB.Enabled = value UUF:UpdateAllRangeFrames() GUIWidgets.DeepDisable(Container, not value, Toggle) end)
    Toggle:SetRelativeWidth(0.33)
    Container:AddChild(Toggle)

    local InAlphaSlider = AG:Create("Slider")
    InAlphaSlider:SetLabel(L["In Range Alpha"])
    InAlphaSlider:SetValue(RangeDB.InRange)
    InAlphaSlider:SetSliderValues(0.0, 1.0, 0.01)
    InAlphaSlider:SetFullWidth(true)
	InAlphaSlider:SetCallback("OnValueChanged", function(_, _, value) RangeDB.InRange = value UUF:UpdateAllRangeFrames() end)
    InAlphaSlider:SetRelativeWidth(0.33)
    InAlphaSlider:SetIsPercent(true)
    Container:AddChild(InAlphaSlider)

    local OutAlphaSlider = AG:Create("Slider")
    OutAlphaSlider:SetLabel(L["Out of Range Alpha"])
    OutAlphaSlider:SetValue(RangeDB.OutOfRange)
    OutAlphaSlider:SetSliderValues(0.0, 1.0, 0.01)
    OutAlphaSlider:SetFullWidth(true)
	OutAlphaSlider:SetCallback("OnValueChanged", function(_, _, value) RangeDB.OutOfRange = value UUF:UpdateAllRangeFrames() end)
    OutAlphaSlider:SetRelativeWidth(0.33)
    OutAlphaSlider:SetIsPercent(true)
    Container:AddChild(OutAlphaSlider)

    GUIWidgets.DeepDisable(Container, not RangeDB.Enabled, Toggle)
end

local function CreateColourSettings(containerParent)
    local Container = GUIWidgets.CreateInlineGroup(containerParent, L["Colours"])
    UUF.db.profile.General.Colours.Status = UUF.db.profile.General.Colours.Status or {}
    for statusType, color in pairs(UUF:GetDefaultDB().profile.General.Colours.Status) do
        UUF.db.profile.General.Colours.Status[statusType] = UUF.db.profile.General.Colours.Status[statusType] or {color[1], color[2], color[3]}
    end
    UUF.db.profile.General.Colours.Threat = UUF.db.profile.General.Colours.Threat or {}
    for threatStatus, color in pairs(UUF:GetDefaultDB().profile.General.Colours.Threat) do
        UUF.db.profile.General.Colours.Threat[threatStatus] = UUF.db.profile.General.Colours.Threat[threatStatus] or {color[1], color[2], color[3]}
    end

    GUIWidgets.CreateInformationTag(Container,L["Buttons below will reset the colours to their default values as defined by "] .. UUF.PRETTY_ADDON_NAME .. ".")

    local ResetAllColoursButton = AG:Create("Button")
    ResetAllColoursButton:SetText(L["All Colours"])
    ResetAllColoursButton:SetCallback("OnClick", function() UUF:CopyTable(UUF:GetDefaultDB().profile.General.Colours, UUF.db.profile.General.Colours) reloadRequired = true UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() Container:ReleaseChildren() CreateColourSettings(containerParent) Container:DoLayout() containerParent:DoLayout() end)
    ResetAllColoursButton:SetRelativeWidth(1)
    Container:AddChild(ResetAllColoursButton)

    local ResetPowerColoursButton = AG:Create("Button")
    ResetPowerColoursButton:SetText(L["Power Colours"])
    ResetPowerColoursButton:SetCallback("OnClick", function() UUF:CopyTable(UUF:GetDefaultDB().profile.General.Colours.Power, UUF.db.profile.General.Colours.Power) Container:ReleaseChildren() CreateColourSettings(containerParent) Container:DoLayout() containerParent:DoLayout() end)
    ResetPowerColoursButton:SetRelativeWidth(0.33)
    Container:AddChild(ResetPowerColoursButton)

    local ResetSecondaryPowerColoursButton = AG:Create("Button")
    ResetSecondaryPowerColoursButton:SetText(L["Secondary Power Colours"])
    ResetSecondaryPowerColoursButton:SetCallback("OnClick", function() UUF:CopyTable(UUF:GetDefaultDB().profile.General.Colours.SecondaryPower, UUF.db.profile.General.Colours.SecondaryPower) Container:ReleaseChildren() CreateColourSettings(containerParent) Container:DoLayout() containerParent:DoLayout() end)
    ResetSecondaryPowerColoursButton:SetRelativeWidth(0.33)
    Container:AddChild(ResetSecondaryPowerColoursButton)

    local ResetReactionColoursButton = AG:Create("Button")
    ResetReactionColoursButton:SetText(L["Reaction Colours"])
    ResetReactionColoursButton:SetCallback("OnClick", function() UUF:CopyTable(UUF:GetDefaultDB().profile.General.Colours.Reaction, UUF.db.profile.General.Colours.Reaction) Container:ReleaseChildren() CreateColourSettings(containerParent) Container:DoLayout() containerParent:DoLayout() end)
    ResetReactionColoursButton:SetRelativeWidth(0.33)
    Container:AddChild(ResetReactionColoursButton)

    local ResetDispelColoursButton = AG:Create("Button")
    ResetDispelColoursButton:SetText(L["Dispel Colours"])
    ResetDispelColoursButton:SetCallback("OnClick", function() UUF:CopyTable(UUF:GetDefaultDB().profile.General.Colours.Dispel, UUF.db.profile.General.Colours.Dispel) reloadRequired = true Container:ReleaseChildren() CreateColourSettings(containerParent) Container:DoLayout() containerParent:DoLayout() end)
    ResetDispelColoursButton:SetRelativeWidth(0.33)
    Container:AddChild(ResetDispelColoursButton)

    local ResetStatusColoursButton = AG:Create("Button")
    ResetStatusColoursButton:SetText(L["Status Colours"])
    ResetStatusColoursButton:SetCallback("OnClick", function() UUF:CopyTable(UUF:GetDefaultDB().profile.General.Colours.Status, UUF.db.profile.General.Colours.Status) UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() Container:ReleaseChildren() CreateColourSettings(containerParent) Container:DoLayout() containerParent:DoLayout() end)
    ResetStatusColoursButton:SetRelativeWidth(0.33)
    Container:AddChild(ResetStatusColoursButton)

    local ResetThreatColoursButton = AG:Create("Button")
    ResetThreatColoursButton:SetText(L["Threat Colours"])
    ResetThreatColoursButton:SetCallback("OnClick", function() UUF:CopyTable(UUF:GetDefaultDB().profile.General.Colours.Threat, UUF.db.profile.General.Colours.Threat) UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() Container:ReleaseChildren() CreateColourSettings(containerParent) Container:DoLayout() containerParent:DoLayout() end)
    ResetThreatColoursButton:SetRelativeWidth(0.33)
    Container:AddChild(ResetThreatColoursButton)

    GUIWidgets.CreateHeader(Container, L["Power"])

    local PowerOrder = {0, 1, 2, 3, 6, 8, 11, 13, 17, 18}

    for _, powerType in ipairs(PowerOrder) do
        local powerColour = UUF.db.profile.General.Colours.Power[powerType]
        local PowerColourPicker = AG:Create("ColorPicker")
        PowerColourPicker:SetLabel(Power[powerType])
        local R, G, B = unpack(powerColour)
        PowerColourPicker:SetColor(R, G, B)
        PowerColourPicker:SetCallback("OnValueChanged", function(widget, _, r, g, b) UUF.db.profile.General.Colours.Power[powerType] = {r, g, b} UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() end)
        PowerColourPicker:SetHasAlpha(false)
        PowerColourPicker:SetRelativeWidth(0.19)
        Container:AddChild(PowerColourPicker)
    end

    GUIWidgets.CreateHeader(Container, L["Secondary Power"])

    local SecondaryPowerOrder = {4, 7, 9, 12, 16, 19}

    for _, secondaryPowerType in ipairs(SecondaryPowerOrder) do
        local secondaryPowerColour = UUF.db.profile.General.Colours.SecondaryPower[secondaryPowerType]
        if secondaryPowerColour then
            local SecondaryPowerColourPicker = AG:Create("ColorPicker")
            SecondaryPowerColourPicker:SetLabel(Power[secondaryPowerType])
            local R, G, B = unpack(secondaryPowerColour)
            SecondaryPowerColourPicker:SetColor(R, G, B)
            SecondaryPowerColourPicker:SetCallback("OnValueChanged", function(widget, _, r, g, b) UUF.db.profile.General.Colours.SecondaryPower[secondaryPowerType] = {r, g, b} UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() end)
            SecondaryPowerColourPicker:SetHasAlpha(false)
            SecondaryPowerColourPicker:SetRelativeWidth(0.2)
            Container:AddChild(SecondaryPowerColourPicker)
        end
    end

    GUIWidgets.CreateHeader(Container, L["Reaction"])

    local ReactionOrder = {1, 2, 3, 4, 5, 6, 7, 8}

    for _, reactionType in ipairs(ReactionOrder) do
        local ReactionColourPicker = AG:Create("ColorPicker")
        ReactionColourPicker:SetLabel(Reaction[reactionType])
        local R, G, B = unpack(UUF.db.profile.General.Colours.Reaction[reactionType])
        ReactionColourPicker:SetColor(R, G, B)
        ReactionColourPicker:SetCallback("OnValueChanged", function(widget, _, r, g, b) UUF.db.profile.General.Colours.Reaction[reactionType] = {r, g, b} UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() end)
        ReactionColourPicker:SetHasAlpha(false)
        ReactionColourPicker:SetRelativeWidth(0.25)
        Container:AddChild(ReactionColourPicker)
    end

    GUIWidgets.CreateHeader(Container, L["Status"])

    local StatusOrder = {"Tapped", "Disconnected", "DeadBackdrop"}

    for _, statusType in ipairs(StatusOrder) do
        local StatusColourPicker = AG:Create("ColorPicker")
        StatusColourPicker:SetLabel(Status[statusType])
        local R, G, B = unpack(UUF.db.profile.General.Colours.Status[statusType])
        StatusColourPicker:SetColor(R, G, B)
        StatusColourPicker:SetCallback("OnValueChanged", function(widget, _, r, g, b) UUF.db.profile.General.Colours.Status[statusType] = {r, g, b} UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() end)
        StatusColourPicker:SetHasAlpha(false)
        StatusColourPicker:SetRelativeWidth(0.25)
        Container:AddChild(StatusColourPicker)
    end

    GUIWidgets.CreateHeader(Container, L["Threat"])

    local ThreatOrder = {0, 1, 2, 3}

    for _, threatStatus in ipairs(ThreatOrder) do
        local ThreatColourPicker = AG:Create("ColorPicker")
        ThreatColourPicker:SetLabel(Threat[threatStatus])
        local R, G, B = unpack(UUF.db.profile.General.Colours.Threat[threatStatus])
        ThreatColourPicker:SetColor(R, G, B)
        ThreatColourPicker:SetCallback("OnValueChanged", function(widget, _, r, g, b) UUF.db.profile.General.Colours.Threat[threatStatus] = {r, g, b} UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() end)
        ThreatColourPicker:SetHasAlpha(false)
        ThreatColourPicker:SetRelativeWidth(0.25)
        Container:AddChild(ThreatColourPicker)
    end

    GUIWidgets.CreateHeader(Container, L["Dispel Types"])

    local DispelTypes = {"Magic", "Curse", "Disease", "Poison", "Bleed"}

    for _, dispelType in ipairs(DispelTypes) do
        local DispelColourPicker = AG:Create("ColorPicker")
        DispelColourPicker:SetLabel(L[dispelType])
        local R, G, B = unpack(UUF.db.profile.General.Colours.Dispel[dispelType])
        DispelColourPicker:SetColor(R, G, B)
        DispelColourPicker:SetCallback("OnValueChanged", function(widget, _, r, g, b) UUF.db.profile.General.Colours.Dispel[dispelType] = {r, g, b} reloadRequired = true UUF:LoadCustomColours() UUF:UpdateAllUnitFrames() end)
        DispelColourPicker:SetHasAlpha(false)
        DispelColourPicker:SetRelativeWidth(0.2)
        Container:AddChild(DispelColourPicker)
    end
end

local function CreateFrameSettings(containerParent, unit, unitHasParent, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local HealthBarDB = GetUnitDB(unit).HealthBar

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local WidthSlider = AG:Create("Slider")
    WidthSlider:SetLabel(L["Width"])
    WidthSlider:SetValue(FrameDB.Width)
    WidthSlider:SetSliderValues(1, 3000, 0.1)
    WidthSlider:SetRelativeWidth(0.5)
    WidthSlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Width = value updateCallback("Frame") end)
    LayoutContainer:AddChild(WidthSlider)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel(L["Height"])
    HeightSlider:SetValue(FrameDB.Height)
    HeightSlider:SetSliderValues(1, 3000, 0.1)
    HeightSlider:SetRelativeWidth(0.5)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Height = value updateCallback("Frame") end)
    LayoutContainer:AddChild(HeightSlider)

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(FrameDB.Layout[1])
	AnchorFromDropdown:SetRelativeWidth((unit == "raid" or unit == "augmentation") and 0.5 or ((unitHasParent or unit == "boss") and 0.33 or (unit == "party" and 0.25 or 0.5)))
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Layout[1] = value updateCallback("Frame") end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    if unitHasParent then
        local AnchorParentEditBox = AG:Create("EditBox")
        AnchorParentEditBox:SetLabel(L["Anchor Parent"])
        AnchorParentEditBox:SetText(FrameDB.AnchorParent or "")
        AnchorParentEditBox:SetRelativeWidth(0.33)
        AnchorParentEditBox:DisableButton(true)
        AnchorParentEditBox:SetCallback("OnEnterPressed", function(_, _, value) FrameDB.AnchorParent = value AnchorParentEditBox:SetText(FrameDB.AnchorParent or "") updateCallback("Frame") end)
        LayoutContainer:AddChild(AnchorParentEditBox)
    end

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(FrameDB.Layout[2])
	AnchorToDropdown:SetRelativeWidth((unit == "raid" or unit == "augmentation") and 0.5 or ((unitHasParent or unit == "boss") and 0.33 or (unit == "party" and 0.25 or 0.5)))
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Layout[2] = value updateCallback("Frame") end)
    LayoutContainer:AddChild(AnchorToDropdown)

	if unit == "boss" or unit == "party" or unit == "raid" or unit == "augmentation" then
        local GrowthDirectionDropdown = AG:Create("Dropdown")
		if unit == "raid" or unit == "augmentation" then
            GrowthDirectionDropdown:SetList(RaidGrowthDirectionList[1], RaidGrowthDirectionList[2])
        elseif unit == "party" then
            GrowthDirectionDropdown:SetList({["UP"] = L["Up"], ["DOWN"] = L["Down"], ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]}, {"UP", "DOWN", "LEFT", "RIGHT"})
        else
            GrowthDirectionDropdown:SetList({["UP"] = L["Up"], ["DOWN"] = L["Down"]})
        end
        GrowthDirectionDropdown:SetLabel(L["Growth Direction"])
        GrowthDirectionDropdown:SetValue(FrameDB.GrowthDirection)
		GrowthDirectionDropdown:SetRelativeWidth((unit == "raid" and 0.33) or (unit == "party" and 0.25) or (unit == "augmentation" and 0.5) or 0.33)
        GrowthDirectionDropdown:SetCallback("OnValueChanged", function(_, _, value) FrameDB.GrowthDirection = value updateCallback("Frame") end)
        LayoutContainer:AddChild(GrowthDirectionDropdown)
    end

    if unit == "party" or unit == "raid" or unit == "augmentation" then
        local SortByDropdown = AG:Create("Dropdown")
        if unit == "raid" then
            SortByDropdown:SetList({["GROUP"] = L["Group"], ["INDEX"] = L["Index"]}, {"GROUP", "INDEX"})
		elseif unit == "augmentation" then
			SortByDropdown:SetList({["NAMELIST"] = L["Player List"], ["NAME"] = L["Name"]}, {"NAMELIST", "NAME"})
        else
            SortByDropdown:SetList({["ROLE"] = L["Role"], ["INDEX"] = L["Index"], ["NAME"] = L["Name"]}, {"ROLE", "INDEX", "NAME"})
        end
        SortByDropdown:SetLabel(L["Sort By"])
		SortByDropdown:SetValue(unit == "augmentation" and FrameDB.SortBy ~= "NAME" and "NAMELIST" or FrameDB.SortBy)
		SortByDropdown:SetRelativeWidth((unit == "raid" and 0.33) or (unit == "augmentation" and 0.5) or 0.25)
        SortByDropdown:SetCallback("OnValueChanged", function(_, _, value) FrameDB.SortBy = value updateCallback("Frame") RefreshSortOrders() end)
        LayoutContainer:AddChild(SortByDropdown)
    end

    if unit == "raid" then
        FrameDB.Groups = FrameDB.Groups or {}
        local AutoAdjustGroupsToggle = AG:Create("CheckBox")
        AutoAdjustGroupsToggle:SetLabel(L["Groups Per Difficulty"])
        AutoAdjustGroupsToggle:SetValue(FrameDB.AutoAdjustGroups)
        AutoAdjustGroupsToggle:SetRelativeWidth(0.33)
        AutoAdjustGroupsToggle:SetCallback("OnEnter", function() GameTooltip:SetOwner(AutoAdjustGroupsToggle.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(L["Automatically adjusts visible raid groups for the current difficulty.\n\n|cFF8080FFNormal / Heroic:|r Groups 1 - 6\n|cFF8080FFMythic:|r Groups 1 - 4\n|cFF8080FFMythic Flex:|r Groups 1 - 5"], 1, 1, 1, true) GameTooltip:Show() end)
        AutoAdjustGroupsToggle:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        LayoutContainer:AddChild(AutoAdjustGroupsToggle)

        local GroupsContainer = GUIWidgets.CreateInlineGroup(LayoutContainer, L["Groups To Show"])
        for groupIndex = 1, UUF.MAX_RAID_GROUPS do
            local GroupToggle = AG:Create("CheckBox")
            GroupToggle:SetLabel(L["G%s"]:format(groupIndex))
            GroupToggle:SetValue(FrameDB.Groups[groupIndex])
            GroupToggle:SetRelativeWidth(0.12)
            GroupToggle:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Groups[groupIndex] = value updateCallback("Frame") end)
            GroupsContainer:AddChild(GroupToggle)
        end
        GUIWidgets.DeepDisable(GroupsContainer, FrameDB.AutoAdjustGroups)
        AutoAdjustGroupsToggle:SetCallback("OnValueChanged", function(_, _, value) FrameDB.AutoAdjustGroups = value GUIWidgets.DeepDisable(GroupsContainer, value) updateCallback("Frame") end)
    end

    if unit == "party" then
        for i = 1, 3 do
            local roleOrder = FrameDB.RoleOrder[i]
            local RoleOrderDropdown = AG:Create("Dropdown")
            RoleOrderDropdown:SetList({["TANK"] = L["Tank"], ["HEALER"] = L["Healer"], ["DAMAGER"] = L["DPS"]}, {"TANK", "HEALER", "DAMAGER"})
            RoleOrderDropdown:SetLabel(L["Order %s"]:format(i))
            RoleOrderDropdown:SetValue(roleOrder)
            RoleOrderDropdown:SetRelativeWidth(0.33)
            RoleOrderDropdown:SetCallback("OnValueChanged", function(_, _, value) FrameDB.RoleOrder[i] = value updateCallback("Frame") end)
            RoleOrderDropdown:SetDisabled(FrameDB.SortBy ~= "ROLE")
            LayoutContainer:AddChild(RoleOrderDropdown)
        end
    end

    function RefreshSortOrders()
        if unit ~= "party" then return end
        for i = 1, 3 do
            local RoleOrderDropdown = LayoutContainer.children[7 + i]
            RoleOrderDropdown:SetDisabled(FrameDB.SortBy ~= "ROLE")
        end
    end

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(FrameDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
	XPosSlider:SetRelativeWidth((unit == "boss" or unit == "party" or unit == "raid" or unit == "augmentation") and 0.25 or 0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Layout[3] = value updateCallback("Frame") end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(FrameDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
	YPosSlider:SetRelativeWidth((unit == "boss" or unit == "party" or unit == "raid" or unit == "augmentation") and 0.25 or 0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Layout[4] = value updateCallback("Frame") end)
    LayoutContainer:AddChild(YPosSlider)

	if unit == "boss" or unit == "party" or unit == "raid" or unit == "augmentation" then
        local SpacingSlider = AG:Create("Slider")
        SpacingSlider:SetLabel(L["Frame Spacing"])
        SpacingSlider:SetValue(FrameDB.Layout[5])
        SpacingSlider:SetSliderValues(-1, 100, 0.1)
        SpacingSlider:SetRelativeWidth(0.25)
        SpacingSlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.Layout[5] = value updateCallback("Frame") end)
        LayoutContainer:AddChild(SpacingSlider)
    end

    if unit == "augmentation" then
		local UnitsPerColumnSlider = AG:Create("Slider")
		UnitsPerColumnSlider:SetLabel(L["Units Per Row / Column"])
		UnitsPerColumnSlider:SetValue(FrameDB.UnitsPerColumn or UUF.MAX_RAID_FRAMES_PER_GROUP)
		UnitsPerColumnSlider:SetSliderValues(1, UUF.MAX_RAID_FRAMES, 1)
		UnitsPerColumnSlider:SetRelativeWidth(0.25)
		UnitsPerColumnSlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.UnitsPerColumn = value updateCallback("Frame") end)
		LayoutContainer:AddChild(UnitsPerColumnSlider)
	end

    local FrameStrataDropdown = AG:Create("Dropdown")
    FrameStrataDropdown:SetList(FrameStrataList[1], FrameStrataList[2])
    FrameStrataDropdown:SetLabel(L["Frame Strata"])
    FrameStrataDropdown:SetValue(FrameDB.FrameStrata)
	FrameStrataDropdown:SetRelativeWidth((unit == "boss" or unit == "party" or unit == "raid") and 0.25 or (unit == "augmentation" and 1) or 0.33)
    FrameStrataDropdown:SetCallback("OnValueChanged", function(_, _, value) FrameDB.FrameStrata = value updateCallback("Frame") end)
    LayoutContainer:AddChild(FrameStrataDropdown)

    local ColourContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Colours & Toggles"])
    local healthToggleWidth = (unit == "player" or unit == "target") and 0.25 or 0.33
	local primaryToggleWidth = (unit == "party" or unit == "raid" or unit == "augmentation") and 0.33 or healthToggleWidth
	local secondaryToggleWidth = (unit == "raid" or unit == "augmentation") and 0.33 or primaryToggleWidth

    if unit == "party" then
        local ShowPlayerToggle = AG:Create("CheckBox")
        ShowPlayerToggle:SetLabel(L["Show Player"])
        ShowPlayerToggle:SetValue(FrameDB.ShowPlayer)
        ShowPlayerToggle:SetRelativeWidth(primaryToggleWidth)
        ShowPlayerToggle:SetCallback("OnValueChanged", function(_, _, value)
            StaticPopupDialogs["UUF_RELOAD_UI"] = {
                text = L["You must reload to apply this change, do you want to reload now?"],
                button1 = L["Reload Now"],
                button2 = L["Later"],
                showAlert = true,
                OnAccept = function() FrameDB.ShowPlayer = value C_UI.Reload() end,
                OnCancel = function() ShowPlayerToggle:SetValue(FrameDB.ShowPlayer) containerParent:DoLayout() end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("UUF_RELOAD_UI")
        end)
        ColourContainer:AddChild(ShowPlayerToggle)
    end

    local SmoothUpdatesToggle = AG:Create("CheckBox")
    SmoothUpdatesToggle:SetLabel(L["Smooth Updates"])
    SmoothUpdatesToggle:SetValue(HealthBarDB.Smooth ~= false)
    SmoothUpdatesToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.Smooth = value updateCallback("HealthBar") end)
    SmoothUpdatesToggle:SetRelativeWidth(primaryToggleWidth)
    ColourContainer:AddChild(SmoothUpdatesToggle)

    local ColourWhenTappedToggle = AG:Create("CheckBox")
    ColourWhenTappedToggle:SetLabel(L["Colour When Tapped"])
    ColourWhenTappedToggle:SetValue(HealthBarDB.ColourWhenTapped)
    ColourWhenTappedToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColourWhenTapped = value updateCallback("HealthBar") end)
    ColourWhenTappedToggle:SetRelativeWidth(primaryToggleWidth)
    ColourContainer:AddChild(ColourWhenTappedToggle)

    local ColourWhenDisconnectedToggle = AG:Create("CheckBox")
    ColourWhenDisconnectedToggle:SetLabel(L["Colour When Disconnected"])
    ColourWhenDisconnectedToggle:SetValue(HealthBarDB.ColourWhenDisconnected)
    ColourWhenDisconnectedToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColourWhenDisconnected = value updateCallback("HealthBar") end)
    ColourWhenDisconnectedToggle:SetRelativeWidth(secondaryToggleWidth)
    ColourContainer:AddChild(ColourWhenDisconnectedToggle)

	if unit == "party" or unit == "raid" or unit == "augmentation" then
        local ColourBackdropWhenDeadToggle = AG:Create("CheckBox")
        ColourBackdropWhenDeadToggle:SetLabel(L["Colour Backdrop When Dead"])
        ColourBackdropWhenDeadToggle:SetValue(HealthBarDB.ColourBackdropWhenDead)
        ColourBackdropWhenDeadToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColourBackdropWhenDead = value updateCallback("HealthBar") end)
        ColourBackdropWhenDeadToggle:SetRelativeWidth(secondaryToggleWidth)
        ColourContainer:AddChild(ColourBackdropWhenDeadToggle)
    end

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel(L["Inverse Growth Direction"])
    InverseGrowthDirectionToggle:SetValue(HealthBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.Inverse = value updateCallback("HealthBar") end)
    InverseGrowthDirectionToggle:SetRelativeWidth(secondaryToggleWidth)
    ColourContainer:AddChild(InverseGrowthDirectionToggle)

    if unit == "player" or unit == "target" then
        local AnchorToCooldownViewerToggle = AG:Create("CheckBox")
        AnchorToCooldownViewerToggle:SetLabel(L["Anchor To Cooldown Viewer"])
        AnchorToCooldownViewerToggle:SetValue(HealthBarDB.AnchorToCooldownViewer)
        AnchorToCooldownViewerToggle:SetCallback("OnValueChanged",
        function(_, _, value)
            HealthBarDB.AnchorToCooldownViewer = value
            if not value then
                FrameDB.Layout[1] = GetDefaultUnitDB(unit).Frame.Layout[1]
                FrameDB.Layout[2] = GetDefaultUnitDB(unit).Frame.Layout[2]
                FrameDB.Layout[3] = GetDefaultUnitDB(unit).Frame.Layout[3]
                FrameDB.Layout[4] = GetDefaultUnitDB(unit).Frame.Layout[4]
                AnchorFromDropdown:SetValue(FrameDB.Layout[1])
                AnchorToDropdown:SetValue(FrameDB.Layout[2])
                XPosSlider:SetValue(FrameDB.Layout[3])
                YPosSlider:SetValue(FrameDB.Layout[4])
            else
                if unit == "player" then
                    FrameDB.Layout[1] = L["Right"]
                    FrameDB.Layout[2] = L["Left"]
                    FrameDB.Layout[3] = 0
                    FrameDB.Layout[4] = 0
                    AnchorFromDropdown:SetValue(FrameDB.Layout[1])
                    AnchorToDropdown:SetValue(FrameDB.Layout[2])
                    XPosSlider:SetValue(FrameDB.Layout[3])
                    YPosSlider:SetValue(FrameDB.Layout[4])
                elseif unit == "target" then
                    FrameDB.Layout[1] = L["Left"]
                    FrameDB.Layout[2] = L["Right"]
                    FrameDB.Layout[3] = 0
                    FrameDB.Layout[4] = 0
                    AnchorFromDropdown:SetValue(FrameDB.Layout[1])
                    AnchorToDropdown:SetValue(FrameDB.Layout[2])
                    XPosSlider:SetValue(FrameDB.Layout[3])
                    YPosSlider:SetValue(FrameDB.Layout[4])
                end
            end
            updateCallback("Frame")
        end)
        AnchorToCooldownViewerToggle:SetCallback("OnEnter", function() GameTooltip:SetOwner(AnchorToCooldownViewerToggle.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(L["Anchor To |cFF8080FFEssential|r Cooldown Viewer. Toggling this will overwrite existing |cFF8080FFLayout|r Settings."], 1, 1, 1, false) GameTooltip:Show() end)
        AnchorToCooldownViewerToggle:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        AnchorToCooldownViewerToggle:SetRelativeWidth(0.25)
        ColourContainer:AddChild(AnchorToCooldownViewerToggle)
    end

    GUIWidgets.CreateInformationTag(ColourContainer, L["Foreground & Background Opacity can be set using the sliders."])

    local ForegroundColourPicker = AG:Create("ColorPicker")
    ForegroundColourPicker:SetLabel(L["Foreground Colour"])
    local R, G, B = unpack(HealthBarDB.Foreground)
    ForegroundColourPicker:SetColor(R, G, B)
    ForegroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) HealthBarDB.Foreground = {r, g, b} updateCallback("HealthBar") end)
    ForegroundColourPicker:SetHasAlpha(false)
    ForegroundColourPicker:SetRelativeWidth(0.25)
    ForegroundColourPicker:SetDisabled(HealthBarDB.ColourByClass)
    ColourContainer:AddChild(ForegroundColourPicker)
    UUFGUI.FrameFGColourPicker = ForegroundColourPicker

    local ForegroundColourByClassToggle = AG:Create("CheckBox")
    ForegroundColourByClassToggle:SetLabel(L["Colour by Class / Reaction"])
    ForegroundColourByClassToggle:SetValue(HealthBarDB.ColourByClass)
    ForegroundColourByClassToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColourByClass = value UUFGUI.FrameFGColourPicker:SetDisabled(HealthBarDB.ColourByClass) updateCallback("HealthBar") end)
    ForegroundColourByClassToggle:SetRelativeWidth(0.25)
    ColourContainer:AddChild(ForegroundColourByClassToggle)

    local ForegroundOpacitySlider = AG:Create("Slider")
    ForegroundOpacitySlider:SetLabel(L["Foreground Opacity"])
    ForegroundOpacitySlider:SetValue(HealthBarDB.ForegroundOpacity)
    ForegroundOpacitySlider:SetSliderValues(0, 1, 0.01)
    ForegroundOpacitySlider:SetRelativeWidth(0.5)
    ForegroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ForegroundOpacity = value updateCallback("HealthBar") end)
    ForegroundOpacitySlider:SetIsPercent(true)
    ColourContainer:AddChild(ForegroundOpacitySlider)

    local BackgroundColourPicker = AG:Create("ColorPicker")
    BackgroundColourPicker:SetLabel(L["Background Colour"])
    local R2, G2, B2 = unpack(HealthBarDB.Background)
    BackgroundColourPicker:SetColor(R2, G2, B2)
    BackgroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) HealthBarDB.Background = {r, g, b} updateCallback("HealthBar") end)
    BackgroundColourPicker:SetHasAlpha(false)
    BackgroundColourPicker:SetRelativeWidth(0.25)
    BackgroundColourPicker:SetDisabled(HealthBarDB.ColourBackgroundByClass)
    ColourContainer:AddChild(BackgroundColourPicker)
    UUFGUI.FrameBGColourPicker = BackgroundColourPicker

    local BackgroundColourByClassToggle = AG:Create("CheckBox")
    BackgroundColourByClassToggle:SetLabel(L["Colour by Class / Reaction"])
    BackgroundColourByClassToggle:SetValue(HealthBarDB.ColourBackgroundByClass)
    BackgroundColourByClassToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColourBackgroundByClass = value UUFGUI.FrameBGColourPicker:SetDisabled(HealthBarDB.ColourBackgroundByClass) updateCallback("HealthBar") end)
    BackgroundColourByClassToggle:SetRelativeWidth(0.25)
    ColourContainer:AddChild(BackgroundColourByClassToggle)

    local BackgroundOpacitySlider = AG:Create("Slider")
    BackgroundOpacitySlider:SetLabel(L["Background Opacity"])
    BackgroundOpacitySlider:SetValue(HealthBarDB.BackgroundOpacity)
    BackgroundOpacitySlider:SetSliderValues(0, 1, 0.01)
    BackgroundOpacitySlider:SetRelativeWidth(0.5)
    BackgroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.BackgroundOpacity = value updateCallback("HealthBar") end)
    BackgroundOpacitySlider:SetIsPercent(true)
    ColourContainer:AddChild(BackgroundOpacitySlider)

	if unit == "player" or unit == "target" or unit == "focus" or unit == "party" or unit == "raid" or unit == "augmentation" then
        local DispelHighlightContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Dispel Highlighting"])

        local EnableDispelHighlightingToggle = AG:Create("CheckBox")
        EnableDispelHighlightingToggle:SetLabel(L["Enable Dispel Highlighting"])
        EnableDispelHighlightingToggle:SetValue(HealthBarDB.DispelHighlight.Enabled)
        EnableDispelHighlightingToggle:SetRelativeWidth(0.5)
        EnableDispelHighlightingToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.DispelHighlight.Enabled = value updateCallback("HealthBar") end)
        DispelHighlightContainer:AddChild(EnableDispelHighlightingToggle)

        local DispelHighlightStyleDropdown = AG:Create("Dropdown")
        DispelHighlightStyleDropdown:SetList({["HEALTHBAR"] = L["Health Bar"], ["GRADIENT"] = L["Gradient"] })
        DispelHighlightStyleDropdown:SetLabel(L["Highlight Style"])
        DispelHighlightStyleDropdown:SetValue(HealthBarDB.DispelHighlight.Style)
        DispelHighlightStyleDropdown:SetRelativeWidth(0.5)
        DispelHighlightStyleDropdown:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.DispelHighlight.Style = value reloadRequired = true updateCallback("HealthBar") end)
        DispelHighlightContainer:AddChild(DispelHighlightStyleDropdown)
    end
end

local function CreateAugmentationFrameSettings(containerParent)
	local AugmentationDB = UUF.db.profile.Units.raid.augmentation
	local GeneralContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Player Filter"])
	GUIWidgets.CreateInformationTag(GeneralContainer, L["|cFF8080FFListed|r Raid Members are the only players that will be shown."])

	local NamesEditBox = AG:Create("MultiLineEditBox")
	NamesEditBox:SetLabel(L["Player Names (Comma Delimited)"])
	NamesEditBox:SetText(AugmentationDB.Names or "")
	NamesEditBox:SetNumLines(8)
	NamesEditBox:SetFullWidth(true)
	NamesEditBox:SetCallback("OnEnterPressed", function(_, _, value) AugmentationDB.Names = value UUF:UpdateAugmentationRaidFrames() end)
	GeneralContainer:AddChild(NamesEditBox)
end

local function CreateHealPredictionSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local HealPredictionDB = GetUnitDB(unit).HealPrediction

    local IncomingHealSettings = GUIWidgets.CreateInlineGroup(containerParent, L["Incoming Heal Settings"])
    local ShowIncomingHealToggle = AG:Create("CheckBox")
    ShowIncomingHealToggle:SetLabel(L["Show Incoming Heals"])
    ShowIncomingHealToggle:SetValue(HealPredictionDB.IncomingHeal.Enabled)
    ShowIncomingHealToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.IncomingHeal.Enabled = value updateCallback() RefreshHealPredictionSettings() end)
    ShowIncomingHealToggle:SetRelativeWidth(0.33)
    IncomingHealSettings:AddChild(ShowIncomingHealToggle)

    local UseStripedTextureIncomingHealToggle = AG:Create("CheckBox")
    UseStripedTextureIncomingHealToggle:SetLabel(L["Use Striped Texture"])
    UseStripedTextureIncomingHealToggle:SetValue(HealPredictionDB.IncomingHeal.UseStripedTexture)
    UseStripedTextureIncomingHealToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.IncomingHeal.UseStripedTexture = value updateCallback() end)
    UseStripedTextureIncomingHealToggle:SetRelativeWidth(0.33)
    IncomingHealSettings:AddChild(UseStripedTextureIncomingHealToggle)

    local MatchParentHeightToggle = AG:Create("CheckBox")
    MatchParentHeightToggle:SetLabel(L["Match Parent Height"])
    MatchParentHeightToggle:SetValue(HealPredictionDB.IncomingHeal.MatchParentHeight)
    MatchParentHeightToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.IncomingHeal.MatchParentHeight = value updateCallback() RefreshHealPredictionSettings() end)
    MatchParentHeightToggle:SetRelativeWidth(0.33)
    IncomingHealSettings:AddChild(MatchParentHeightToggle)

    local IncomingHealColourPicker = AG:Create("ColorPicker")
    IncomingHealColourPicker:SetLabel(L["Incoming Heal Colour"])
    local R, G, B, A = unpack(HealPredictionDB.IncomingHeal.Colour)
    IncomingHealColourPicker:SetColor(R, G, B, A)
    IncomingHealColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) HealPredictionDB.IncomingHeal.Colour = {r, g, b, a} updateCallback() end)
    IncomingHealColourPicker:SetHasAlpha(true)
    IncomingHealColourPicker:SetRelativeWidth(0.33)
    IncomingHealSettings:AddChild(IncomingHealColourPicker)

    local IncomingHealHeightSlider = AG:Create("Slider")
    IncomingHealHeightSlider:SetLabel(L["Height"])
    IncomingHealHeightSlider:SetValue(HealPredictionDB.IncomingHeal.Height)
    IncomingHealHeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    IncomingHealHeightSlider:SetRelativeWidth(0.33)
    IncomingHealHeightSlider:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.IncomingHeal.Height = value updateCallback() end)
    IncomingHealHeightSlider:SetDisabled(HealPredictionDB.IncomingHeal.MatchParentHeight or HealPredictionDB.IncomingHeal.Position == "ATTACH")
    IncomingHealSettings:AddChild(IncomingHealHeightSlider)

    local IncomingHealPositionDropdown = AG:Create("Dropdown")
    IncomingHealPositionDropdown:SetList({["TOPLEFT"] = L["Top Left"], ["TOPRIGHT"] = L["Top Right"], ["BOTTOMLEFT"] = L["Bottom Left"], ["BOTTOMRIGHT"] = L["Bottom Right"], ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["ATTACH"] = L["Attach To Missing Health"]}, {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT", "ATTACH"})
    IncomingHealPositionDropdown:SetLabel(L["Position"])
    IncomingHealPositionDropdown:SetValue(HealPredictionDB.IncomingHeal.Position)
    IncomingHealPositionDropdown:SetRelativeWidth(0.33)
    IncomingHealPositionDropdown:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.IncomingHeal.Position = value updateCallback() RefreshHealPredictionSettings() end)
    IncomingHealSettings:AddChild(IncomingHealPositionDropdown)

    local AbsorbSettings = GUIWidgets.CreateInlineGroup(containerParent, L["Absorb Settings"])

    local ShowAbsorbToggle = AG:Create("CheckBox")
    ShowAbsorbToggle:SetLabel(L["Show Absorbs"])
    ShowAbsorbToggle:SetValue(HealPredictionDB.Absorbs.Enabled)
    ShowAbsorbToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.Absorbs.Enabled = value updateCallback() RefreshHealPredictionSettings() end)
    ShowAbsorbToggle:SetRelativeWidth(0.25)
    AbsorbSettings:AddChild(ShowAbsorbToggle)

    local ShowOverAbsorbToggle = AG:Create("CheckBox")
    ShowOverAbsorbToggle:SetLabel(L["Show Over Absorb"])
    ShowOverAbsorbToggle:SetValue(HealPredictionDB.Absorbs.ShowOverAbsorb or false)
    ShowOverAbsorbToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.Absorbs.ShowOverAbsorb = HealPredictionDB.Absorbs.Position == "ATTACH" and value or false updateCallback() RefreshHealPredictionSettings() end)
    ShowOverAbsorbToggle:SetCallback("OnEnter", function() GameTooltip:SetOwner(ShowOverAbsorbToggle.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(L["This will add an overlay of your current absorbs when at maximum health.\nThis will only work when the |cFF8080FFPosition|r is set to |cFF8080FFAttach To Missing Health|r."], 1, 1, 1, false) GameTooltip:Show() end)
    ShowOverAbsorbToggle:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    ShowOverAbsorbToggle:SetRelativeWidth(0.25)
    AbsorbSettings:AddChild(ShowOverAbsorbToggle)

    local UseStripedTextureAbsorbToggle = AG:Create("CheckBox")
    UseStripedTextureAbsorbToggle:SetLabel(L["Use Striped Texture"])
    UseStripedTextureAbsorbToggle:SetValue(HealPredictionDB.Absorbs.UseStripedTexture)
    UseStripedTextureAbsorbToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.Absorbs.UseStripedTexture = value updateCallback() end)
    UseStripedTextureAbsorbToggle:SetRelativeWidth(0.25)
    AbsorbSettings:AddChild(UseStripedTextureAbsorbToggle)

    local MatchParentHeightToggle = AG:Create("CheckBox")
    MatchParentHeightToggle:SetLabel(L["Match Parent Height"])
    MatchParentHeightToggle:SetValue(HealPredictionDB.Absorbs.MatchParentHeight)
    MatchParentHeightToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.Absorbs.MatchParentHeight = value updateCallback() RefreshHealPredictionSettings() end)
    MatchParentHeightToggle:SetRelativeWidth(0.25)
    AbsorbSettings:AddChild(MatchParentHeightToggle)

    local AbsorbColourPicker = AG:Create("ColorPicker")
    AbsorbColourPicker:SetLabel(L["Absorb Colour"])
    local R, G, B, A = unpack(HealPredictionDB.Absorbs.Colour)
    AbsorbColourPicker:SetColor(R, G, B, A)
    AbsorbColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) HealPredictionDB.Absorbs.Colour = {r, g, b, a} updateCallback() end)
    AbsorbColourPicker:SetHasAlpha(true)
    AbsorbColourPicker:SetRelativeWidth(0.33)
    AbsorbSettings:AddChild(AbsorbColourPicker)

    local AbsorbHeightSlider = AG:Create("Slider")
    AbsorbHeightSlider:SetLabel(L["Height"])
    AbsorbHeightSlider:SetValue(HealPredictionDB.Absorbs.Height)
    AbsorbHeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    AbsorbHeightSlider:SetRelativeWidth(0.33)
    AbsorbHeightSlider:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.Absorbs.Height = value updateCallback() end)
    AbsorbHeightSlider:SetDisabled(HealPredictionDB.Absorbs.MatchParentHeight or HealPredictionDB.Absorbs.Position == "ATTACH")
    AbsorbSettings:AddChild(AbsorbHeightSlider)

    local AbsorbPositionDropdown = AG:Create("Dropdown")
    AbsorbPositionDropdown:SetList({["TOPLEFT"] = L["Top Left"], ["TOPRIGHT"] = L["Top Right"], ["BOTTOMLEFT"] = L["Bottom Left"], ["BOTTOMRIGHT"] = L["Bottom Right"], ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["ATTACH"] = L["Attach To Missing Health"]}, {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT", "ATTACH"})
    AbsorbPositionDropdown:SetLabel(L["Position"])
    AbsorbPositionDropdown:SetValue(HealPredictionDB.Absorbs.Position)
    AbsorbPositionDropdown:SetRelativeWidth(0.33)
    AbsorbPositionDropdown:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.Absorbs.Position = value if value ~= "ATTACH" then HealPredictionDB.Absorbs.ShowOverAbsorb = false ShowOverAbsorbToggle:SetValue(false) end updateCallback() RefreshHealPredictionSettings() end)
    AbsorbSettings:AddChild(AbsorbPositionDropdown)

    local HealAbsorbSettings = GUIWidgets.CreateInlineGroup(containerParent, L["Heal Absorb Settings"])
    local ShowHealAbsorbToggle = AG:Create("CheckBox")
    ShowHealAbsorbToggle:SetLabel(L["Show Heal Absorbs"])
    ShowHealAbsorbToggle:SetValue(HealPredictionDB.HealAbsorbs.Enabled)
    ShowHealAbsorbToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.HealAbsorbs.Enabled = value updateCallback() RefreshHealPredictionSettings() end)
    ShowHealAbsorbToggle:SetRelativeWidth(0.33)
    HealAbsorbSettings:AddChild(ShowHealAbsorbToggle)

    local UseStripedTextureHealAbsorbToggle = AG:Create("CheckBox")
    UseStripedTextureHealAbsorbToggle:SetLabel(L["Use Striped Texture"])
    UseStripedTextureHealAbsorbToggle:SetValue(HealPredictionDB.HealAbsorbs.UseStripedTexture)
    UseStripedTextureHealAbsorbToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.HealAbsorbs.UseStripedTexture = value updateCallback() end)
    UseStripedTextureHealAbsorbToggle:SetRelativeWidth(0.33)
    HealAbsorbSettings:AddChild(UseStripedTextureHealAbsorbToggle)

    local MatchParentHeightHealAbsorbToggle = AG:Create("CheckBox")
    MatchParentHeightHealAbsorbToggle:SetLabel(L["Match Parent Height"])
    MatchParentHeightHealAbsorbToggle:SetValue(HealPredictionDB.HealAbsorbs.MatchParentHeight)
    MatchParentHeightHealAbsorbToggle:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.HealAbsorbs.MatchParentHeight = value updateCallback() RefreshHealPredictionSettings() end)
    MatchParentHeightHealAbsorbToggle:SetRelativeWidth(0.33)
    HealAbsorbSettings:AddChild(MatchParentHeightHealAbsorbToggle)

    local HealAbsorbColourPicker = AG:Create("ColorPicker")
    HealAbsorbColourPicker:SetLabel(L["Heal Absorb Colour"])
    local R2, G2, B2, A2 = unpack(HealPredictionDB.HealAbsorbs.Colour)
    HealAbsorbColourPicker:SetColor(R2, G2, B2, A2)
    HealAbsorbColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) HealPredictionDB.HealAbsorbs.Colour = {r, g, b, a} updateCallback() end)
    HealAbsorbColourPicker:SetHasAlpha(true)
    HealAbsorbColourPicker:SetRelativeWidth(0.33)
    HealAbsorbSettings:AddChild(HealAbsorbColourPicker)

    local HealAbsorbHeightSlider = AG:Create("Slider")
    HealAbsorbHeightSlider:SetLabel(L["Height"])
    HealAbsorbHeightSlider:SetValue(HealPredictionDB.HealAbsorbs.Height)
    HealAbsorbHeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    HealAbsorbHeightSlider:SetRelativeWidth(0.33)
    HealAbsorbHeightSlider:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.HealAbsorbs.Height = value updateCallback() end)
    HealAbsorbHeightSlider:SetDisabled(HealPredictionDB.HealAbsorbs.MatchParentHeight or HealPredictionDB.HealAbsorbs.Position == "ATTACH")
    HealAbsorbSettings:AddChild(HealAbsorbHeightSlider)

    local HealAbsorbPositionDropdown = AG:Create("Dropdown")
    HealAbsorbPositionDropdown:SetList({["TOPLEFT"] = L["Top Left"], ["TOPRIGHT"] = L["Top Right"], ["BOTTOMLEFT"] = L["Bottom Left"], ["BOTTOMRIGHT"] = L["Bottom Right"], ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["ATTACH"] = L["Attach To Missing Health"]}, {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT", "ATTACH"})
    HealAbsorbPositionDropdown:SetLabel(L["Position"])
    HealAbsorbPositionDropdown:SetValue(HealPredictionDB.HealAbsorbs.Position)
    HealAbsorbPositionDropdown:SetRelativeWidth(0.33)
    HealAbsorbPositionDropdown:SetCallback("OnValueChanged", function(_, _, value) HealPredictionDB.HealAbsorbs.Position = value updateCallback() RefreshHealPredictionSettings() end)
    HealAbsorbSettings:AddChild(HealAbsorbPositionDropdown)

    function RefreshHealPredictionSettings()
        GUIWidgets.DeepDisable(IncomingHealSettings, not HealPredictionDB.IncomingHeal.Enabled, ShowIncomingHealToggle)
        IncomingHealHeightSlider:SetDisabled(HealPredictionDB.IncomingHeal.MatchParentHeight or HealPredictionDB.IncomingHeal.Position == "ATTACH")
        GUIWidgets.DeepDisable(AbsorbSettings, not HealPredictionDB.Absorbs.Enabled, ShowAbsorbToggle)
        GUIWidgets.DeepDisable(HealAbsorbSettings, not HealPredictionDB.HealAbsorbs.Enabled, ShowHealAbsorbToggle)
        AbsorbHeightSlider:SetDisabled(HealPredictionDB.Absorbs.MatchParentHeight or HealPredictionDB.Absorbs.Position == "ATTACH")
        ShowOverAbsorbToggle:SetDisabled(not HealPredictionDB.Absorbs.Enabled or HealPredictionDB.Absorbs.Position ~= "ATTACH")
        HealAbsorbHeightSlider:SetDisabled(HealPredictionDB.HealAbsorbs.MatchParentHeight or HealPredictionDB.HealAbsorbs.Position == "ATTACH")
    end

    RefreshHealPredictionSettings()
end

local function CreateCastBarBarSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local CastBarDB = GetUnitDB(unit).CastBar
    local DefaultCastBarDB = GetDefaultUnitDB(unit).CastBar
    if not CastBarDB.InterruptCooldownColour then CastBarDB.InterruptCooldownColour = {unpack(DefaultCastBarDB.InterruptCooldownColour)} end
    local isPlayerorPet = unit == "player" or unit == "pet"

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Cast Bar Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFCast Bar|r"])
    Toggle:SetValue(CastBarDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Enabled = value updateCallback() RefreshCastBarBarSettings() end)
    Toggle:SetRelativeWidth(0.33)
    LayoutContainer:AddChild(Toggle)

    local MatchParentWidthToggle = AG:Create("CheckBox")
    MatchParentWidthToggle:SetLabel(L["Match Frame Width"])
    MatchParentWidthToggle:SetValue(CastBarDB.MatchParentWidth)
    MatchParentWidthToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.MatchParentWidth = value updateCallback() RefreshCastBarBarSettings() end)
    MatchParentWidthToggle:SetRelativeWidth(0.33)
    LayoutContainer:AddChild(MatchParentWidthToggle)

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel(L["Inverse Growth Direction"])
    InverseGrowthDirectionToggle:SetValue(CastBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Inverse = value updateCallback() end)
    InverseGrowthDirectionToggle:SetRelativeWidth(0.33)
    LayoutContainer:AddChild(InverseGrowthDirectionToggle)

    local WidthSlider = AG:Create("Slider")
    WidthSlider:SetLabel(L["Width"])
    WidthSlider:SetValue(CastBarDB.Width)
    WidthSlider:SetSliderValues(1, 3000, 0.1)
    WidthSlider:SetRelativeWidth(0.5)
    WidthSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Width = value updateCallback() end)
    LayoutContainer:AddChild(WidthSlider)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel(L["Height"])
    HeightSlider:SetValue(CastBarDB.Height)
    HeightSlider:SetSliderValues(1, 3000, 0.1)
    HeightSlider:SetRelativeWidth(0.5)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)

    local HoldTimeSlider = AG:Create("Slider")
    HoldTimeSlider:SetLabel(L["Interrupted/Failed Hold Time"])
    HoldTimeSlider:SetValue(CastBarDB.HoldTime)
    HoldTimeSlider:SetSliderValues(0, 5, 0.1)
    HoldTimeSlider:SetRelativeWidth(1)
    HoldTimeSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.HoldTime = value updateCallback() end)
    LayoutContainer:AddChild(HoldTimeSlider)

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(CastBarDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(CastBarDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(CastBarDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(CastBarDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local FrameStrataDropdown = AG:Create("Dropdown")
    FrameStrataDropdown:SetList(FrameStrataList[1], FrameStrataList[2])
    FrameStrataDropdown:SetLabel(L["Frame Strata"])
    FrameStrataDropdown:SetValue(CastBarDB.FrameStrata)
    FrameStrataDropdown:SetRelativeWidth(0.33)
    FrameStrataDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.FrameStrata = value updateCallback() end)
    LayoutContainer:AddChild(FrameStrataDropdown)

    local ColourContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Colours & Toggles"])

    if isPlayerorPet then
        local ClassColourToggle = AG:Create("CheckBox")
        ClassColourToggle:SetLabel(L["Foreground: Colour by Class"])
        ClassColourToggle:SetValue(CastBarDB.ColourByClass)
        ClassColourToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.ColourByClass = value UUFGUI.ForegroundColourPicker:SetDisabled(CastBarDB.ColourByClass) updateCallback() end)
        ClassColourToggle:SetRelativeWidth(0.5)
        ColourContainer:AddChild(ClassColourToggle)
        UUFGUI.ClassColourToggle = ClassColourToggle
    end

    local ForegroundColourPicker = AG:Create("ColorPicker")
    ForegroundColourPicker:SetLabel(L["Foreground"])
    local R, G, B, A = unpack(CastBarDB.Foreground)
    ForegroundColourPicker:SetColor(R, G, B, A)
    ForegroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) CastBarDB.Foreground = {r, g, b, a} updateCallback() end)
    ForegroundColourPicker:SetHasAlpha(true)
    ForegroundColourPicker:SetRelativeWidth(0.5)
    ColourContainer:AddChild(ForegroundColourPicker)

    UUFGUI.ForegroundColourPicker = ForegroundColourPicker

    local BackgroundColourPicker = AG:Create("ColorPicker")
    BackgroundColourPicker:SetLabel(L["Background"])
    local R2, G2, B2, A2 = unpack(CastBarDB.Background)
    BackgroundColourPicker:SetColor(R2, G2, B2, A2)
    BackgroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) CastBarDB.Background = {r, g, b, a} updateCallback() end)
    BackgroundColourPicker:SetHasAlpha(true)
    BackgroundColourPicker:SetRelativeWidth(0.5)
    ColourContainer:AddChild(BackgroundColourPicker)

    local NotInterruptibleColourPicker = AG:Create("ColorPicker")
    NotInterruptibleColourPicker:SetLabel(L["Not Interruptible"])
    local R3, G3, B3 = unpack(CastBarDB.NotInterruptibleColour)
    NotInterruptibleColourPicker:SetColor(R3, G3, B3)
    NotInterruptibleColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) CastBarDB.NotInterruptibleColour = {r, g, b, a} updateCallback() end)
    NotInterruptibleColourPicker:SetHasAlpha(true)
    NotInterruptibleColourPicker:SetRelativeWidth(0.5)
    ColourContainer:AddChild(NotInterruptibleColourPicker)

    local InterruptCooldownColourPicker = AG:Create("ColorPicker")
    InterruptCooldownColourPicker:SetLabel(L["Interrupt on Cooldown"])
    local R4, G4, B4 = unpack(CastBarDB.InterruptCooldownColour)
    InterruptCooldownColourPicker:SetColor(R4, G4, B4)
    InterruptCooldownColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) CastBarDB.InterruptCooldownColour = {r, g, b, a} updateCallback() end)
    InterruptCooldownColourPicker:SetHasAlpha(true)
    InterruptCooldownColourPicker:SetRelativeWidth(0.5)
    ColourContainer:AddChild(InterruptCooldownColourPicker)

    local InterruptedFailedColourPicker = AG:Create("ColorPicker")
    InterruptedFailedColourPicker:SetLabel(L["Interrupted / Failed"])
    local R5, G5, B5 = unpack(CastBarDB.InterruptedFailedColour)
    InterruptedFailedColourPicker:SetColor(R5, G5, B5)
    InterruptedFailedColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) CastBarDB.InterruptedFailedColour = {r, g, b, a} updateCallback() end)
    InterruptedFailedColourPicker:SetHasAlpha(true)
    InterruptedFailedColourPicker:SetRelativeWidth(isPlayerorPet and 0.2 or 0.2)
    ColourContainer:AddChild(InterruptedFailedColourPicker)

    function RefreshCastBarBarSettings()
        if CastBarDB.Enabled then
            MatchParentWidthToggle:SetDisabled(false)
            WidthSlider:SetDisabled(CastBarDB.MatchParentWidth)
            HeightSlider:SetDisabled(false)
            HoldTimeSlider:SetDisabled(false)
            AnchorFromDropdown:SetDisabled(false)
            AnchorToDropdown:SetDisabled(false)
            XPosSlider:SetDisabled(false)
            YPosSlider:SetDisabled(false)
            ForegroundColourPicker:SetDisabled(CastBarDB.ColourByClass)
            BackgroundColourPicker:SetDisabled(false)
            NotInterruptibleColourPicker:SetDisabled(false)
            InterruptCooldownColourPicker:SetDisabled(false)
            InterruptedFailedColourPicker:SetDisabled(false)
            if isPlayerorPet then UUFGUI.ClassColourToggle:SetDisabled(false) end
        else
            MatchParentWidthToggle:SetDisabled(true)
            WidthSlider:SetDisabled(true)
            HeightSlider:SetDisabled(true)
            HoldTimeSlider:SetDisabled(true)
            AnchorFromDropdown:SetDisabled(true)
            AnchorToDropdown:SetDisabled(true)
            XPosSlider:SetDisabled(true)
            YPosSlider:SetDisabled(true)
            ForegroundColourPicker:SetDisabled(true)
            BackgroundColourPicker:SetDisabled(true)
            NotInterruptibleColourPicker:SetDisabled(true)
            InterruptCooldownColourPicker:SetDisabled(true)
            InterruptedFailedColourPicker:SetDisabled(true)
            if isPlayerorPet then UUFGUI.ClassColourToggle:SetDisabled(true) end
        end
    end

    RefreshCastBarBarSettings()
end

local function CreateCastBarIconSettings(containerParent, unit, updateCallback)
    local CastBarIconDB = GetUnitDB(unit).CastBar.Icon

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Icon Settings"])
    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFCast Bar Icon|r"])
    Toggle:SetValue(CastBarIconDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) CastBarIconDB.Enabled = value updateCallback() RefreshCastBarIconSettings() end)
    Toggle:SetRelativeWidth(0.5)
    LayoutContainer:AddChild(Toggle)

    local PositionDropdown = AG:Create("Dropdown")
    PositionDropdown:SetList({["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]})
    PositionDropdown:SetLabel(L["Position"])
    PositionDropdown:SetValue(CastBarIconDB.Position)
    PositionDropdown:SetRelativeWidth(0.5)
    PositionDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarIconDB.Position = value updateCallback() end)
    LayoutContainer:AddChild(PositionDropdown)

    function RefreshCastBarIconSettings()
        if CastBarIconDB.Enabled then
            PositionDropdown:SetDisabled(false)
        else
            PositionDropdown:SetDisabled(true)
        end
    end

    RefreshCastBarIconSettings()
end

local function CreateCastBarSpellNameTextSettings(containerParent, unit, updateCallback)
    local CastBarDB = GetUnitDB(unit).CastBar
    local CastBarTextDB = CastBarDB.Text
    local SpellNameTextDB = CastBarTextDB.SpellName

    local SpellNameContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Spell Name Settings"])

    local SpellNameToggle = AG:Create("CheckBox")
    SpellNameToggle:SetLabel(L["Enable |cFF8080FFSpell Name Text|r"])
    SpellNameToggle:SetValue(SpellNameTextDB.Enabled)
    SpellNameToggle:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.Enabled = value updateCallback() RefreshCastBarSpellNameSettings() end)
    SpellNameToggle:SetRelativeWidth(0.33)
    SpellNameContainer:AddChild(SpellNameToggle)

    local ShowTargetToggle = AG:Create("CheckBox")
    ShowTargetToggle:SetLabel(L["Show Target"])
    ShowTargetToggle:SetValue(CastBarDB.ShowTarget)
    ShowTargetToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.ShowTarget = value updateCallback() end)
    ShowTargetToggle:SetRelativeWidth(0.33)
    SpellNameContainer:AddChild(ShowTargetToggle)

    local SpellNameColourPicker = AG:Create("ColorPicker")
    SpellNameColourPicker:SetLabel(L["Colour"])
    local R, G, B = unpack(SpellNameTextDB.Colour)
    SpellNameColourPicker:SetColor(R, G, B)
    SpellNameColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) SpellNameTextDB.Colour = {r, g, b} updateCallback() end)
    SpellNameColourPicker:SetHasAlpha(false)
    SpellNameColourPicker:SetRelativeWidth(0.33)
    SpellNameContainer:AddChild(SpellNameColourPicker)

    local SpellNameLayoutContainer = GUIWidgets.CreateInlineGroup(SpellNameContainer, L["Layout"])
    local SpellNameAnchorFromDropdown = AG:Create("Dropdown")
    SpellNameAnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    SpellNameAnchorFromDropdown:SetLabel(L["Anchor From"])
    SpellNameAnchorFromDropdown:SetValue(SpellNameTextDB.Layout[1])
    SpellNameAnchorFromDropdown:SetRelativeWidth(0.5)
    SpellNameAnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.Layout[1] = value updateCallback() end)
    SpellNameLayoutContainer:AddChild(SpellNameAnchorFromDropdown)

    local SpellNameAnchorToDropdown = AG:Create("Dropdown")
    SpellNameAnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    SpellNameAnchorToDropdown:SetLabel(L["Anchor To"])
    SpellNameAnchorToDropdown:SetValue(SpellNameTextDB.Layout[2])
    SpellNameAnchorToDropdown:SetRelativeWidth(0.5)
    SpellNameAnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.Layout[2] = value updateCallback() end)
    SpellNameLayoutContainer:AddChild(SpellNameAnchorToDropdown)

    local SpellNameXPosSlider = AG:Create("Slider")
    SpellNameXPosSlider:SetLabel(L["X Position"])
    SpellNameXPosSlider:SetValue(SpellNameTextDB.Layout[3])
    SpellNameXPosSlider:SetSliderValues(-3000, 3000, 0.1)
    SpellNameXPosSlider:SetRelativeWidth(0.25)
    SpellNameXPosSlider:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.Layout[3] = value updateCallback() end)
    SpellNameLayoutContainer:AddChild(SpellNameXPosSlider)

    local SpellNameYPosSlider = AG:Create("Slider")
    SpellNameYPosSlider:SetLabel(L["Y Position"])
    SpellNameYPosSlider:SetValue(SpellNameTextDB.Layout[4])
    SpellNameYPosSlider:SetSliderValues(-3000, 3000, 0.1)
    SpellNameYPosSlider:SetRelativeWidth(0.25)
    SpellNameYPosSlider:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.Layout[4] = value updateCallback() end)
    SpellNameLayoutContainer:AddChild(SpellNameYPosSlider)

    local SpellNameFontSizeSlider = AG:Create("Slider")
    SpellNameFontSizeSlider:SetLabel(L["Font Size"])
    SpellNameFontSizeSlider:SetValue(SpellNameTextDB.FontSize)
    SpellNameFontSizeSlider:SetSliderValues(8, 64, 1)
    SpellNameFontSizeSlider:SetRelativeWidth(0.25)
    SpellNameFontSizeSlider:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.FontSize = value updateCallback() end)
    SpellNameLayoutContainer:AddChild(SpellNameFontSizeSlider)

    local MaxCharsSlider = AG:Create("Slider")
    MaxCharsSlider:SetLabel(L["Max Characters"])
    MaxCharsSlider:SetValue(SpellNameTextDB.MaxChars)
    MaxCharsSlider:SetSliderValues(1, 64, 1)
    MaxCharsSlider:SetRelativeWidth(0.25)
    MaxCharsSlider:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.MaxChars = value updateCallback() end)
    SpellNameLayoutContainer:AddChild(MaxCharsSlider)

    function RefreshCastBarSpellNameSettings()
        if SpellNameTextDB.Enabled then
            SpellNameAnchorFromDropdown:SetDisabled(false)
            SpellNameAnchorToDropdown:SetDisabled(false)
            SpellNameXPosSlider:SetDisabled(false)
            SpellNameYPosSlider:SetDisabled(false)
            SpellNameFontSizeSlider:SetDisabled(false)
            SpellNameColourPicker:SetDisabled(false)
            ShowTargetToggle:SetDisabled(false)
            MaxCharsSlider:SetDisabled(false)
        else
            SpellNameAnchorFromDropdown:SetDisabled(true)
            SpellNameAnchorToDropdown:SetDisabled(true)
            SpellNameXPosSlider:SetDisabled(true)
            SpellNameYPosSlider:SetDisabled(true)
            SpellNameFontSizeSlider:SetDisabled(true)
            SpellNameColourPicker:SetDisabled(true)
            ShowTargetToggle:SetDisabled(true)
            MaxCharsSlider:SetDisabled(true)
        end
    end

    RefreshCastBarSpellNameSettings()
end

local function CreateCastBarDurationTextSettings(containerParent, unit, updateCallback)
    local CastBarTextDB = GetUnitDB(unit).CastBar.Text
    local DurationTextDB = CastBarTextDB.Duration

     local DurationContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Duration Settings"])

    local DurationToggle = AG:Create("CheckBox")
    DurationToggle:SetLabel(L["Enable |cFF8080FFDuration Text|r"])
    DurationToggle:SetValue(DurationTextDB.Enabled)
    DurationToggle:SetCallback("OnValueChanged", function(_, _, value) DurationTextDB.Enabled = value updateCallback() RefreshCastBarDurationSettings() end)
    DurationToggle:SetRelativeWidth(0.5)
    DurationContainer:AddChild(DurationToggle)

    local DurationColourPicker = AG:Create("ColorPicker")
    DurationColourPicker:SetLabel(L["Colour"])
    local R, G, B = unpack(DurationTextDB.Colour)
    DurationColourPicker:SetColor(R, G, B)
    DurationColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) DurationTextDB.Colour = {r, g, b} updateCallback() end)
    DurationColourPicker:SetHasAlpha(false)
    DurationColourPicker:SetRelativeWidth(0.5)
    DurationContainer:AddChild(DurationColourPicker)

    local DurationLayoutContainer = GUIWidgets.CreateInlineGroup(DurationContainer, L["Layout"])
    local DurationAnchorFromDropdown = AG:Create("Dropdown")
    DurationAnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    DurationAnchorFromDropdown:SetLabel(L["Anchor From"])
    DurationAnchorFromDropdown:SetValue(DurationTextDB.Layout[1])
    DurationAnchorFromDropdown:SetRelativeWidth(0.5)
    DurationAnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) DurationTextDB.Layout[1] = value updateCallback() end)
    DurationLayoutContainer:AddChild(DurationAnchorFromDropdown)

    local DurationAnchorToDropdown = AG:Create("Dropdown")
    DurationAnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    DurationAnchorToDropdown:SetLabel(L["Anchor To"])
    DurationAnchorToDropdown:SetValue(DurationTextDB.Layout[2])
    DurationAnchorToDropdown:SetRelativeWidth(0.5)
    DurationAnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) DurationTextDB.Layout[2] = value updateCallback() end)
    DurationLayoutContainer:AddChild(DurationAnchorToDropdown)

    local DurationXPosSlider = AG:Create("Slider")
    DurationXPosSlider:SetLabel(L["X Position"])
    DurationXPosSlider:SetValue(DurationTextDB.Layout[3])
    DurationXPosSlider:SetSliderValues(-3000, 3000, 0.1)
    DurationXPosSlider:SetRelativeWidth(0.33)
    DurationXPosSlider:SetCallback("OnValueChanged", function(_, _, value) DurationTextDB.Layout[3] = value updateCallback() end)
    DurationLayoutContainer:AddChild(DurationXPosSlider)

    local DurationYPosSlider = AG:Create("Slider")
    DurationYPosSlider:SetLabel(L["Y Position"])
    DurationYPosSlider:SetValue(DurationTextDB.Layout[4])
    DurationYPosSlider:SetSliderValues(-3000, 3000, 0.1)
    DurationYPosSlider:SetRelativeWidth(0.33)
    DurationYPosSlider:SetCallback("OnValueChanged", function(_, _, value) DurationTextDB.Layout[4] = value updateCallback() end)
    DurationLayoutContainer:AddChild(DurationYPosSlider)

    local DurationFontSizeSlider = AG:Create("Slider")
    DurationFontSizeSlider:SetLabel(L["Font Size"])
    DurationFontSizeSlider:SetValue(DurationTextDB.FontSize)
    DurationFontSizeSlider:SetSliderValues(8, 64, 1)
    DurationFontSizeSlider:SetRelativeWidth(0.33)
    DurationFontSizeSlider:SetCallback("OnValueChanged", function(_, _, value) DurationTextDB.FontSize = value updateCallback() end)
    DurationLayoutContainer:AddChild(DurationFontSizeSlider)

    function RefreshCastBarDurationSettings()
        if DurationTextDB.Enabled then
            DurationAnchorFromDropdown:SetDisabled(false)
            DurationAnchorToDropdown:SetDisabled(false)
            DurationXPosSlider:SetDisabled(false)
            DurationYPosSlider:SetDisabled(false)
            DurationFontSizeSlider:SetDisabled(false)
            DurationColourPicker:SetDisabled(false)
        else
            DurationAnchorFromDropdown:SetDisabled(true)
            DurationAnchorToDropdown:SetDisabled(true)
            DurationXPosSlider:SetDisabled(true)
            DurationYPosSlider:SetDisabled(true)
            DurationFontSizeSlider:SetDisabled(true)
            DurationColourPicker:SetDisabled(true)
        end
    end

    RefreshCastBarDurationSettings()
end

local function CreateCastBarSettings(containerParent, unit)
	local function UpdateCastBar() UpdateUnitSettings(unit, function() UUF:UpdateUnitCastBar(UUF[unit:upper()], unit) end, "CastBar") end

    local function SelectCastBarTab(CastBarContainer, _, CastBarTab)
        SaveSubTab(unit, "CastBar", CastBarTab)
        CastBarContainer:ReleaseChildren()
        if CastBarTab == "Bar" then
            CreateCastBarBarSettings(CastBarContainer, unit, UpdateCastBar)
        elseif CastBarTab == "Icon" then
            CreateCastBarIconSettings(CastBarContainer, unit, UpdateCastBar)
        elseif CastBarTab == "SpellName" then
            CreateCastBarSpellNameTextSettings(CastBarContainer, unit, UpdateCastBar)
        elseif CastBarTab == "Duration" then
            CreateCastBarDurationTextSettings(CastBarContainer, unit, UpdateCastBar)
        end
    end

    local CastBarTabGroup = AG:Create("TabGroup")
    CastBarTabGroup:SetLayout("Flow")
    CastBarTabGroup:SetFullWidth(true)
    CastBarTabGroup:SetTabs({
        {text = L["Bar"], value = "Bar"},
        {text = L["Icon"] , value = "Icon"},
        {text = L["Text: |cFFFFFFFFSpell Name|r"], value = "SpellName"},
        {text = L["Text: |cFFFFFFFFDuration|r"], value = "Duration"},
    })
    CastBarTabGroup:SetCallback("OnGroupSelected", SelectCastBarTab)
    CastBarTabGroup:SelectTab(GetSavedSubTab(unit, "CastBar", "Bar"))
    containerParent:AddChild(CastBarTabGroup)
end

local function CreatePowerBarSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local PowerBarDB = GetUnitDB(unit).PowerBar
    local isGroupPowerBar = unit == "party" or unit == "raid"
    local toggleRelativeWidth = isGroupPowerBar and 0.5 or 0.25

    local function UpdatePowerBarSettings()
        updateCallback()
        if unit == "player" and UUF.PLAYER then
            UUF:UpdateUnitSecondaryPowerBar(UUF.PLAYER, unit)
        end
    end

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Power Bar Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFPower Bar|r"])
    Toggle:SetValue(PowerBarDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Enabled = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    Toggle:SetRelativeWidth(0.25)
    LayoutContainer:AddChild(Toggle)

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel(L["Inverse Growth Direction"])
    InverseGrowthDirectionToggle:SetValue(PowerBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Inverse = value UpdatePowerBarSettings() end)
    InverseGrowthDirectionToggle:SetRelativeWidth(0.25)
    LayoutContainer:AddChild(InverseGrowthDirectionToggle)

    local PositionDropdown = AG:Create("Dropdown")
    PositionDropdown:SetList(TopBottomList[1], TopBottomList[2])
    PositionDropdown:SetLabel(L["Position"])
    PositionDropdown:SetValue(UUF:GetConfiguredPowerBarPosition(unit))
    PositionDropdown:SetRelativeWidth(0.25)
    PositionDropdown:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Position = value UpdatePowerBarSettings() end)
    LayoutContainer:AddChild(PositionDropdown)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel(L["Height"])
    HeightSlider:SetValue(PowerBarDB.Height)
    HeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    HeightSlider:SetRelativeWidth(0.25)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Height = value UpdatePowerBarSettings() end)
    LayoutContainer:AddChild(HeightSlider)

    local ColourContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Colours & Toggles"])

    local SmoothUpdatesToggle = AG:Create("CheckBox")
    SmoothUpdatesToggle:SetLabel(L["Smooth Updates"])
    SmoothUpdatesToggle:SetValue(PowerBarDB.Smooth)
    SmoothUpdatesToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Smooth = value UpdatePowerBarSettings() end)
    SmoothUpdatesToggle:SetRelativeWidth(toggleRelativeWidth)
    ColourContainer:AddChild(SmoothUpdatesToggle)

    local ColourByTypeToggle = AG:Create("CheckBox")
    ColourByTypeToggle:SetLabel(L["Colour By Type"])
    ColourByTypeToggle:SetValue(PowerBarDB.ColourByType)
    ColourByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColourByType = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColourByTypeToggle:SetRelativeWidth(toggleRelativeWidth)
    ColourContainer:AddChild(ColourByTypeToggle)

    local ColourByClassToggle = AG:Create("CheckBox")
    ColourByClassToggle:SetLabel(L["Colour By Class"])
    ColourByClassToggle:SetValue(PowerBarDB.ColourByClass)
    ColourByClassToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColourByClass = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColourByClassToggle:SetRelativeWidth(toggleRelativeWidth)
    ColourContainer:AddChild(ColourByClassToggle)

    local ColourBackgroundByTypeToggle = AG:Create("CheckBox")
    ColourBackgroundByTypeToggle:SetLabel(L["Colour Background By Power Type"])
    ColourBackgroundByTypeToggle:SetValue(PowerBarDB.ColourBackgroundByType)
    ColourBackgroundByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColourBackgroundByType = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColourBackgroundByTypeToggle:SetRelativeWidth(toggleRelativeWidth)
    ColourBackgroundByTypeToggle:SetDisabled(true)
    ColourContainer:AddChild(ColourBackgroundByTypeToggle)

    local OnlyShowHealersToggle
    if isGroupPowerBar then
        OnlyShowHealersToggle = AG:Create("CheckBox")
        OnlyShowHealersToggle:SetLabel(L["Only Show Healer Mana"])
        OnlyShowHealersToggle:SetValue(PowerBarDB.OnlyShowHealers or false)
        OnlyShowHealersToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.OnlyShowHealers = value UpdatePowerBarSettings() end)
        OnlyShowHealersToggle:SetRelativeWidth(toggleRelativeWidth)
        ColourContainer:AddChild(OnlyShowHealersToggle)

        local ColourRowBreak = AG:Create("Label")
        ColourRowBreak:SetText("")
        ColourRowBreak:SetFullWidth(true)
        ColourContainer:AddChild(ColourRowBreak)
    end

    local ForegroundColourPicker = AG:Create("ColorPicker")
    ForegroundColourPicker:SetLabel(L["Foreground Colour"])
    local R, G, B, A = unpack(PowerBarDB.Foreground)
    ForegroundColourPicker:SetColor(R, G, B, A)
    ForegroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) PowerBarDB.Foreground = {r, g, b, a} UpdatePowerBarSettings() end)
    ForegroundColourPicker:SetHasAlpha(true)
    ForegroundColourPicker:SetRelativeWidth(0.33)
    ForegroundColourPicker:SetDisabled(PowerBarDB.ColourByClass or PowerBarDB.ColourByType)
    ColourContainer:AddChild(ForegroundColourPicker)

    local BackgroundColourPicker = AG:Create("ColorPicker")
    BackgroundColourPicker:SetLabel(L["Background Colour"])
    local R2, G2, B2, A2 = unpack(PowerBarDB.Background)
    BackgroundColourPicker:SetColor(R2, G2, B2, A2)
    BackgroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) PowerBarDB.Background = {r, g, b, a} UpdatePowerBarSettings() end)
    BackgroundColourPicker:SetHasAlpha(true)
    BackgroundColourPicker:SetRelativeWidth(0.33)
    BackgroundColourPicker:SetDisabled(PowerBarDB.ColourBackgroundByType)
    ColourContainer:AddChild(BackgroundColourPicker)

    local BackgroundMultiplierSlider = AG:Create("Slider")
    BackgroundMultiplierSlider:SetLabel(L["Background Multiplier"])
    BackgroundMultiplierSlider:SetValue(PowerBarDB.BackgroundMultiplier)
    BackgroundMultiplierSlider:SetSliderValues(0, 1, 0.01)
    BackgroundMultiplierSlider:SetRelativeWidth(0.33)
    BackgroundMultiplierSlider:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.BackgroundMultiplier = value UpdatePowerBarSettings() end)
    BackgroundMultiplierSlider:SetIsPercent(true)
    BackgroundMultiplierSlider:SetDisabled(not PowerBarDB.ColourBackgroundByType)
    ColourContainer:AddChild(BackgroundMultiplierSlider)

    function RefreshPowerBarGUI()
        if PowerBarDB.Enabled then
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
            GUIWidgets.DeepDisable(ColourContainer, false, Toggle)
            if PowerBarDB.ColourByClass or PowerBarDB.ColourByType then
                ForegroundColourPicker:SetDisabled(true)
            else
                ForegroundColourPicker:SetDisabled(false)
            end
            BackgroundColourPicker:SetDisabled(PowerBarDB.ColourBackgroundByType)
            BackgroundMultiplierSlider:SetDisabled(not PowerBarDB.ColourBackgroundByType)
            if OnlyShowHealersToggle then OnlyShowHealersToggle:SetDisabled(false) end
        else
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
            GUIWidgets.DeepDisable(ColourContainer, true, Toggle)
        end
    end

    RefreshPowerBarGUI()
end

local function CreateSecondaryPowerBarSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local SecondaryPowerBarDB = GetUnitDB(unit).SecondaryPowerBar

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Power Bar Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFSecondary Power Bar|r"])
    Toggle:SetValue(SecondaryPowerBarDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.Enabled = value updateCallback() RefreshSecondaryPowerBarGUI() end)
    Toggle:SetRelativeWidth(0.33)
    LayoutContainer:AddChild(Toggle)

    local PositionDropdown = AG:Create("Dropdown")
    PositionDropdown:SetList(TopBottomList[1], TopBottomList[2])
    PositionDropdown:SetLabel(L["Position"])
    PositionDropdown:SetValue(UUF:GetConfiguredSecondaryPowerBarPosition(unit))
    PositionDropdown:SetRelativeWidth(0.33)
    PositionDropdown:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.Position = value updateCallback() end)
    LayoutContainer:AddChild(PositionDropdown)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel(L["Height"])
    HeightSlider:SetValue(SecondaryPowerBarDB.Height)
    HeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    HeightSlider:SetRelativeWidth(0.33)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)

    local ColourContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Colours & Toggles"])

    local ColourByTypeToggle = AG:Create("CheckBox")
    ColourByTypeToggle:SetLabel(L["Colour By Type"])
    ColourByTypeToggle:SetValue(SecondaryPowerBarDB.ColourByType)
    ColourByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.ColourByType = value updateCallback() RefreshSecondaryPowerBarGUI() end)
    ColourByTypeToggle:SetRelativeWidth(1)
    ColourContainer:AddChild(ColourByTypeToggle)

    local ForegroundColourPicker = AG:Create("ColorPicker")
    ForegroundColourPicker:SetLabel(L["Foreground Colour"])
    local R, G, B, A = unpack(SecondaryPowerBarDB.Foreground)
    ForegroundColourPicker:SetColor(R, G, B, A)
    ForegroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) SecondaryPowerBarDB.Foreground = {r, g, b, a} updateCallback() end)
    ForegroundColourPicker:SetHasAlpha(true)
    ForegroundColourPicker:SetRelativeWidth(0.5)
    ForegroundColourPicker:SetDisabled(SecondaryPowerBarDB.ColourByClass or SecondaryPowerBarDB.ColourByType)
    ColourContainer:AddChild(ForegroundColourPicker)

    local BackgroundColourPicker = AG:Create("ColorPicker")
    BackgroundColourPicker:SetLabel(L["Background Colour"])
    local R2, G2, B2, A2 = unpack(SecondaryPowerBarDB.Background)
    BackgroundColourPicker:SetColor(R2, G2, B2, A2)
    BackgroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) SecondaryPowerBarDB.Background = {r, g, b, a} updateCallback() end)
    BackgroundColourPicker:SetHasAlpha(true)
    BackgroundColourPicker:SetRelativeWidth(0.5)
    BackgroundColourPicker:SetDisabled(SecondaryPowerBarDB.ColourBackgroundByType)
    ColourContainer:AddChild(BackgroundColourPicker)

    function RefreshSecondaryPowerBarGUI()
        if SecondaryPowerBarDB.Enabled then
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
            GUIWidgets.DeepDisable(ColourContainer, false, Toggle)
            if SecondaryPowerBarDB.ColourByClass or SecondaryPowerBarDB.ColourByType then
                ForegroundColourPicker:SetDisabled(true)
            else
                ForegroundColourPicker:SetDisabled(false)
            end
        else
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
            GUIWidgets.DeepDisable(ColourContainer, true, Toggle)
        end
    end

    RefreshSecondaryPowerBarGUI()
end

local function CreateAlternativePowerBarSettings(containerParent, unit, updateCallback)
    local AlternativePowerBarDB = GetUnitDB(unit).AlternativePowerBar

    GUIWidgets.CreateInformationTag(containerParent, L["The |cFF8080FFAlternative Power Bar|r will display |cFF4080FFMana|r for classes that have an alternative resource."])

    local AlternativePowerBarSettings = GUIWidgets.CreateInlineGroup(containerParent, L["Alternative Power Bar Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFAlternative Power Bar|r"])
    Toggle:SetValue(AlternativePowerBarDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Enabled = value updateCallback() RefreshAlternativePowerBarGUI() end)
    Toggle:SetRelativeWidth(0.5)
    AlternativePowerBarSettings:AddChild(Toggle)

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel(L["Inverse Growth Direction"])
    InverseGrowthDirectionToggle:SetValue(AlternativePowerBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Inverse = value updateCallback() end)
    InverseGrowthDirectionToggle:SetRelativeWidth(0.5)
    AlternativePowerBarSettings:AddChild(InverseGrowthDirectionToggle)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local WidthSlider = AG:Create("Slider")
    WidthSlider:SetLabel(L["Width"])
    WidthSlider:SetValue(AlternativePowerBarDB.Width)
    WidthSlider:SetSliderValues(1, 3000, 0.1)
    WidthSlider:SetRelativeWidth(0.5)
    WidthSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Width = value updateCallback() end)
    LayoutContainer:AddChild(WidthSlider)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel(L["Height"])
    HeightSlider:SetValue(AlternativePowerBarDB.Height)
    HeightSlider:SetSliderValues(1, 64, 0.1)
    HeightSlider:SetRelativeWidth(0.5)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(AlternativePowerBarDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(AlternativePowerBarDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(AlternativePowerBarDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.5)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(AlternativePowerBarDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.5)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local ColourContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Colours & Toggles"])

    local ColourByTypeToggle = AG:Create("CheckBox")
    ColourByTypeToggle:SetLabel(L["Colour By Type"])
    ColourByTypeToggle:SetValue(AlternativePowerBarDB.ColourByType)
    ColourByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.ColourByType = value updateCallback() RefreshAlternativePowerBarGUI() end)
    ColourByTypeToggle:SetRelativeWidth(0.33)
    ColourContainer:AddChild(ColourByTypeToggle)

    local ForegroundColourPicker = AG:Create("ColorPicker")
    ForegroundColourPicker:SetLabel(L["Foreground Colour"])
    local R, G, B, A = unpack(AlternativePowerBarDB.Foreground)
    ForegroundColourPicker:SetColor(R, G, B, A)
    ForegroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) AlternativePowerBarDB.Foreground = {r, g, b, a} updateCallback() end)
    ForegroundColourPicker:SetHasAlpha(true)
    ForegroundColourPicker:SetRelativeWidth(0.33)
    ForegroundColourPicker:SetDisabled(AlternativePowerBarDB.ColourByType)
    ColourContainer:AddChild(ForegroundColourPicker)

    local BackgroundColourPicker = AG:Create("ColorPicker")
    BackgroundColourPicker:SetLabel(L["Background Colour"])
    local R2, G2, B2, A2 = unpack(AlternativePowerBarDB.Background)
    BackgroundColourPicker:SetColor(R2, G2, B2, A2)
    BackgroundColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) AlternativePowerBarDB.Background = {r, g, b, a} updateCallback() end)
    BackgroundColourPicker:SetHasAlpha(true)
    BackgroundColourPicker:SetRelativeWidth(0.33)
    ColourContainer:AddChild(BackgroundColourPicker)

    function RefreshAlternativePowerBarGUI()
        if AlternativePowerBarDB.Enabled then
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
            GUIWidgets.DeepDisable(ColourContainer, false, Toggle)
            if AlternativePowerBarDB.ColourByType then
                ForegroundColourPicker:SetDisabled(true)
            else
                ForegroundColourPicker:SetDisabled(false)
            end
        else
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
            GUIWidgets.DeepDisable(ColourContainer, true, Toggle)
        end
        InverseGrowthDirectionToggle:SetDisabled(not AlternativePowerBarDB.Enabled)
    end

    RefreshAlternativePowerBarGUI()
end

local function CreatePortraitSettings(containerParent, unit, updateCallback)
    local PortraitDB = GetUnitDB(unit).Portrait
    PortraitDB.Style = PortraitDB.Style or "2D"

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Portrait Settings"])

    GUIWidgets.CreateInformationTag(ToggleContainer, L["|cFF8080FF3D Portraits|r will |cFFFF4040NOT|r work in instances, as they are now secret. |cFF8080FF2D Portraits|r will be used as a fallback if this is the case."])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFPortrait|r"])
    Toggle:SetValue(PortraitDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Enabled = value updateCallback() RefreshPortraitGUI() end)
    Toggle:SetRelativeWidth(0.33)
    ToggleContainer:AddChild(Toggle)

    local UseClassPortraitToggle = AG:Create("CheckBox")
    UseClassPortraitToggle:SetLabel(L["Use Class Portrait"])
    UseClassPortraitToggle:SetValue(PortraitDB.UseClassPortrait)
    UseClassPortraitToggle:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.UseClassPortrait = value updateCallback() end)
    UseClassPortraitToggle:SetRelativeWidth(0.33)
    ToggleContainer:AddChild(UseClassPortraitToggle)

    local PortraitStyleDropdown = AG:Create("Dropdown")
    PortraitStyleDropdown:SetList({["2D"] = L["2D"], ["3D"] = L["3D"]})
    PortraitStyleDropdown:SetLabel(L["Portrait Style"])
    PortraitStyleDropdown:SetValue(PortraitDB.Style)
    PortraitStyleDropdown:SetRelativeWidth(0.33)
    PortraitStyleDropdown:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Style = value updateCallback() RefreshPortraitGUI() end)
    ToggleContainer:AddChild(PortraitStyleDropdown)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(PortraitDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(PortraitDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(PortraitDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(PortraitDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local ZoomSlider = AG:Create("Slider")
    ZoomSlider:SetLabel(L["Zoom"])
    ZoomSlider:SetValue(PortraitDB.Zoom)
    ZoomSlider:SetSliderValues(0, 1, 0.01)
    ZoomSlider:SetRelativeWidth(0.33)
    ZoomSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Zoom = value updateCallback() end)
    ZoomSlider:SetIsPercent(true)
    LayoutContainer:AddChild(ZoomSlider)

    local WidthSlider = AG:Create("Slider")
    WidthSlider:SetLabel(L["Width"])
    WidthSlider:SetValue(PortraitDB.Width)
    WidthSlider:SetSliderValues(8, 128, 0.1)
    WidthSlider:SetRelativeWidth(0.5)
    WidthSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Width = value updateCallback() end)
    LayoutContainer:AddChild(WidthSlider)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel(L["Height"])
    HeightSlider:SetValue(PortraitDB.Height)
    HeightSlider:SetSliderValues(8, 128, 0.1)
    HeightSlider:SetRelativeWidth(0.5)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)

    function RefreshPortraitGUI()
        if PortraitDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
        UseClassPortraitToggle:SetDisabled(not PortraitDB.Enabled or PortraitDB.Style ~= "2D")
        ZoomSlider:SetDisabled(not PortraitDB.Enabled or PortraitDB.Style ~= "2D")
    end

    RefreshPortraitGUI()
end

local function CreateRaidTargetMarkerSettings(containerParent, unit, updateCallback)
    local RaidTargetMarkerDB = GetUnitDB(unit).Indicators.RaidTargetMarker

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Raid Target Marker Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFRaid Target Marker|r Indicator"])
    Toggle:SetValue(RaidTargetMarkerDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) RaidTargetMarkerDB.Enabled = value updateCallback() RefreshStatusGUI() end)
    Toggle:SetRelativeWidth(1)
    ToggleContainer:AddChild(Toggle)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(RaidTargetMarkerDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) RaidTargetMarkerDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(RaidTargetMarkerDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) RaidTargetMarkerDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(RaidTargetMarkerDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) RaidTargetMarkerDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(RaidTargetMarkerDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) RaidTargetMarkerDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(RaidTargetMarkerDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) RaidTargetMarkerDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshStatusGUI()
        if RaidTargetMarkerDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
    end

    RefreshStatusGUI()
end

local function CreateReadyCheckIndicatorSettings(containerParent, unit, updateCallback)
	local ReadyCheckDB = GetUnitDB(unit).Indicators.ReadyCheckIndicator
	ReadyCheckDB.Texture = ReadyCheckDB.Texture or "Default"
	local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Ready Check Indicator Settings"])
	local Toggle = AG:Create("CheckBox")
	Toggle:SetLabel(L["Enable |cFF8080FFReady Check|r Indicator"])
	Toggle:SetValue(ReadyCheckDB.Enabled)
	Toggle:SetRelativeWidth(0.5)
	ToggleContainer:AddChild(Toggle)

	local TextureDropdown = AG:Create("Dropdown")
	TextureDropdown:SetList({
		["Default"] = "|A:UI-LFG-ReadyMark-Raid:18:18|a |A:UI-LFG-DeclineMark-Raid:18:18|a |A:UI-LFG-PendingMark-Raid:18:18|a",
		["White"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\ReadyCheck\\White\\Ready.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\ReadyCheck\\White\\NotReady.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\ReadyCheck\\White\\Pending.png:18:18|t",
        ["HiRes"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\ReadyCheck\\HiRes\\Ready.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\ReadyCheck\\HiRes\\NotReady.png:18:18|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\ReadyCheck\\HiRes\\Pending.png:18:18|t",
	}, {"Default", "White", "HiRes"})
	TextureDropdown:SetLabel(L["Ready Check Texture"])
	TextureDropdown:SetValue(ReadyCheckDB.Texture)
	TextureDropdown:SetRelativeWidth(0.5)
	TextureDropdown:SetCallback("OnValueChanged", function(_, _, value) ReadyCheckDB.Texture = value updateCallback() end)
	ToggleContainer:AddChild(TextureDropdown)

	local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])
	local AnchorFromDropdown = AG:Create("Dropdown")
	AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorFromDropdown:SetLabel(L["Anchor From"])
	AnchorFromDropdown:SetValue(ReadyCheckDB.Layout[1])
	AnchorFromDropdown:SetRelativeWidth(0.5)
	AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) ReadyCheckDB.Layout[1] = value updateCallback() end)
	LayoutContainer:AddChild(AnchorFromDropdown)

	local AnchorToDropdown = AG:Create("Dropdown")
	AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorToDropdown:SetLabel(L["Anchor To"])
	AnchorToDropdown:SetValue(ReadyCheckDB.Layout[2])
	AnchorToDropdown:SetRelativeWidth(0.5)
	AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) ReadyCheckDB.Layout[2] = value updateCallback() end)
	LayoutContainer:AddChild(AnchorToDropdown)

	local XPosSlider = AG:Create("Slider")
	XPosSlider:SetLabel(L["X Position"])
	XPosSlider:SetValue(ReadyCheckDB.Layout[3])
	XPosSlider:SetSliderValues(-3000, 3000, 0.1)
	XPosSlider:SetRelativeWidth(0.33)
	XPosSlider:SetCallback("OnValueChanged", function(_, _, value) ReadyCheckDB.Layout[3] = value updateCallback() end)
	LayoutContainer:AddChild(XPosSlider)

	local YPosSlider = AG:Create("Slider")
	YPosSlider:SetLabel(L["Y Position"])
	YPosSlider:SetValue(ReadyCheckDB.Layout[4])
	YPosSlider:SetSliderValues(-3000, 3000, 0.1)
	YPosSlider:SetRelativeWidth(0.33)
	YPosSlider:SetCallback("OnValueChanged", function(_, _, value) ReadyCheckDB.Layout[4] = value updateCallback() end)
	LayoutContainer:AddChild(YPosSlider)

	local SizeSlider = AG:Create("Slider")
	SizeSlider:SetLabel(L["Size"])
	SizeSlider:SetValue(ReadyCheckDB.Size)
	SizeSlider:SetSliderValues(8, 64, 1)
	SizeSlider:SetRelativeWidth(0.33)
	SizeSlider:SetCallback("OnValueChanged", function(_, _, value) ReadyCheckDB.Size = value updateCallback() end)
	LayoutContainer:AddChild(SizeSlider)

	Toggle:SetCallback("OnValueChanged", function(_, _, value) ReadyCheckDB.Enabled = value updateCallback() GUIWidgets.DeepDisable(ToggleContainer, not value, Toggle) GUIWidgets.DeepDisable(LayoutContainer, not value) end)
	GUIWidgets.DeepDisable(ToggleContainer, not ReadyCheckDB.Enabled, Toggle)
	GUIWidgets.DeepDisable(LayoutContainer, not ReadyCheckDB.Enabled)
end

local function CreateResurrectIndicatorSettings(containerParent, unit, updateCallback)
	local ResurrectDB = GetUnitDB(unit).Indicators.ResurrectIndicator
	local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Resurrect Indicator Settings"])
	local Toggle = AG:Create("CheckBox")
	Toggle:SetLabel(L["Enable |cFF8080FFResurrect|r Indicator"])
	Toggle:SetValue(ResurrectDB.Enabled)
	Toggle:SetRelativeWidth(1)
	ToggleContainer:AddChild(Toggle)

	local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])
	local AnchorFromDropdown = AG:Create("Dropdown")
	AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorFromDropdown:SetLabel(L["Anchor From"])
	AnchorFromDropdown:SetValue(ResurrectDB.Layout[1])
	AnchorFromDropdown:SetRelativeWidth(0.5)
	AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) ResurrectDB.Layout[1] = value updateCallback() end)
	LayoutContainer:AddChild(AnchorFromDropdown)

	local AnchorToDropdown = AG:Create("Dropdown")
	AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorToDropdown:SetLabel(L["Anchor To"])
	AnchorToDropdown:SetValue(ResurrectDB.Layout[2])
	AnchorToDropdown:SetRelativeWidth(0.5)
	AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) ResurrectDB.Layout[2] = value updateCallback() end)
	LayoutContainer:AddChild(AnchorToDropdown)

	local XPosSlider = AG:Create("Slider")
	XPosSlider:SetLabel(L["X Position"])
	XPosSlider:SetValue(ResurrectDB.Layout[3])
	XPosSlider:SetSliderValues(-3000, 3000, 0.1)
	XPosSlider:SetRelativeWidth(0.33)
	XPosSlider:SetCallback("OnValueChanged", function(_, _, value) ResurrectDB.Layout[3] = value updateCallback() end)
	LayoutContainer:AddChild(XPosSlider)

	local YPosSlider = AG:Create("Slider")
	YPosSlider:SetLabel(L["Y Position"])
	YPosSlider:SetValue(ResurrectDB.Layout[4])
	YPosSlider:SetSliderValues(-3000, 3000, 0.1)
	YPosSlider:SetRelativeWidth(0.33)
	YPosSlider:SetCallback("OnValueChanged", function(_, _, value) ResurrectDB.Layout[4] = value updateCallback() end)
	LayoutContainer:AddChild(YPosSlider)

	local SizeSlider = AG:Create("Slider")
	SizeSlider:SetLabel(L["Size"])
	SizeSlider:SetValue(ResurrectDB.Size)
	SizeSlider:SetSliderValues(8, 64, 1)
	SizeSlider:SetRelativeWidth(0.33)
	SizeSlider:SetCallback("OnValueChanged", function(_, _, value) ResurrectDB.Size = value updateCallback() end)
	LayoutContainer:AddChild(SizeSlider)

	Toggle:SetCallback("OnValueChanged", function(_, _, value) ResurrectDB.Enabled = value updateCallback() GUIWidgets.DeepDisable(LayoutContainer, not value) end)
	GUIWidgets.DeepDisable(LayoutContainer, not ResurrectDB.Enabled)
end

local function CreateSummonIndicatorSettings(containerParent, unit, updateCallback)
	GetUnitDB(unit).Indicators.Summon = GetUnitDB(unit).Indicators.Summon or {}
	local SummonDB = GetUnitDB(unit).Indicators.Summon
	local DefaultSummonDB = GetDefaultUnitDB(unit).Indicators.Summon
	for key, value in pairs(DefaultSummonDB) do
		if SummonDB[key] == nil then SummonDB[key] = type(value) == "table" and {unpack(value)} or value end
	end

	local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Summon Indicator Settings"])
	local Toggle = AG:Create("CheckBox")
	Toggle:SetLabel(L["Enable |cFF8080FFSummon|r Indicator"])
	Toggle:SetValue(SummonDB.Enabled)
	Toggle:SetRelativeWidth(1)
	ToggleContainer:AddChild(Toggle)

	local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])
	local AnchorFromDropdown = AG:Create("Dropdown")
	AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorFromDropdown:SetLabel(L["Anchor From"])
	AnchorFromDropdown:SetValue(SummonDB.Layout[1])
	AnchorFromDropdown:SetRelativeWidth(0.5)
	AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) SummonDB.Layout[1] = value updateCallback() end)
	LayoutContainer:AddChild(AnchorFromDropdown)

	local AnchorToDropdown = AG:Create("Dropdown")
	AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorToDropdown:SetLabel(L["Anchor To"])
	AnchorToDropdown:SetValue(SummonDB.Layout[2])
	AnchorToDropdown:SetRelativeWidth(0.5)
	AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) SummonDB.Layout[2] = value updateCallback() end)
	LayoutContainer:AddChild(AnchorToDropdown)

	local XPosSlider = AG:Create("Slider")
	XPosSlider:SetLabel(L["X Position"])
	XPosSlider:SetValue(SummonDB.Layout[3])
	XPosSlider:SetSliderValues(-3000, 3000, 0.1)
	XPosSlider:SetRelativeWidth(0.33)
	XPosSlider:SetCallback("OnValueChanged", function(_, _, value) SummonDB.Layout[3] = value updateCallback() end)
	LayoutContainer:AddChild(XPosSlider)

	local YPosSlider = AG:Create("Slider")
	YPosSlider:SetLabel(L["Y Position"])
	YPosSlider:SetValue(SummonDB.Layout[4])
	YPosSlider:SetSliderValues(-3000, 3000, 0.1)
	YPosSlider:SetRelativeWidth(0.33)
	YPosSlider:SetCallback("OnValueChanged", function(_, _, value) SummonDB.Layout[4] = value updateCallback() end)
	LayoutContainer:AddChild(YPosSlider)

	local SizeSlider = AG:Create("Slider")
	SizeSlider:SetLabel(L["Size"])
	SizeSlider:SetValue(SummonDB.Size)
	SizeSlider:SetSliderValues(8, 64, 1)
	SizeSlider:SetRelativeWidth(0.33)
	SizeSlider:SetCallback("OnValueChanged", function(_, _, value) SummonDB.Size = value updateCallback() end)
	LayoutContainer:AddChild(SizeSlider)

	Toggle:SetCallback("OnValueChanged", function(_, _, value) SummonDB.Enabled = value updateCallback() GUIWidgets.DeepDisable(LayoutContainer, not value) end)
	GUIWidgets.DeepDisable(LayoutContainer, not SummonDB.Enabled)
end

local function CreateLeaderAssistaintSettings(containerParent, unit, updateCallback)
    local LeaderAssistantDB = GetUnitDB(unit).Indicators.LeaderAssistantIndicator

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Leader & Assistant Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFLeader|r & |cFF8080FFAssistant|r Indicator"])
    Toggle:SetValue(LeaderAssistantDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) LeaderAssistantDB.Enabled = value updateCallback() RefreshStatusGUI() end)
    Toggle:SetRelativeWidth(1)
    ToggleContainer:AddChild(Toggle)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(LeaderAssistantDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) LeaderAssistantDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(LeaderAssistantDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) LeaderAssistantDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(LeaderAssistantDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) LeaderAssistantDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(LeaderAssistantDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) LeaderAssistantDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(LeaderAssistantDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) LeaderAssistantDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshStatusGUI()
        if LeaderAssistantDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
    end

    RefreshStatusGUI()
end

local function CreateRoleIndicatorSettings(containerParent, unit, updateCallback)
    GetUnitDB(unit).Indicators.Role = GetUnitDB(unit).Indicators.Role or {}
    local DefaultRoleDB = GetDefaultUnitDB(unit).Indicators.Role
    local RoleDB = GetUnitDB(unit).Indicators.Role
    if RoleDB.Enabled == nil then RoleDB.Enabled = DefaultRoleDB.Enabled end
	if RoleDB.ShowTank == nil then RoleDB.ShowTank = DefaultRoleDB.ShowTank end
	if RoleDB.ShowHealer == nil then RoleDB.ShowHealer = DefaultRoleDB.ShowHealer end
	if RoleDB.ShowDamager == nil then RoleDB.ShowDamager = DefaultRoleDB.ShowDamager end
    RoleDB.Texture = RoleDB.Texture or DefaultRoleDB.Texture
    RoleDB.Size = RoleDB.Size or DefaultRoleDB.Size
    RoleDB.Layout = RoleDB.Layout or {unpack(DefaultRoleDB.Layout)}

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Role Indicator Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFRole|r Indicator"])
    Toggle:SetValue(RoleDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) RoleDB.Enabled = value updateCallback() RefreshRoleGUI() end)
    Toggle:SetRelativeWidth(0.5)
    ToggleContainer:AddChild(Toggle)

    local TextureDropdown = AG:Create("Dropdown")
	TextureDropdown:SetList(RoleTextures, {"Default", "Blizzard", "Colour", "White", "ElvUI", "Square"})
    TextureDropdown:SetLabel(L["Role Texture"])
    TextureDropdown:SetValue(RoleDB.Texture)
    TextureDropdown:SetRelativeWidth(0.5)
    TextureDropdown:SetCallback("OnValueChanged", function(_, _, value) RoleDB.Texture = value updateCallback() end)
    ToggleContainer:AddChild(TextureDropdown)

	local TankToggle = AG:Create("CheckBox")
	TankToggle:SetLabel(L["Show Tank"])
	TankToggle:SetValue(RoleDB.ShowTank)
	TankToggle:SetCallback("OnValueChanged", function(_, _, value) RoleDB.ShowTank = value updateCallback() end)
	TankToggle:SetRelativeWidth(0.33)
	ToggleContainer:AddChild(TankToggle)

	local HealerToggle = AG:Create("CheckBox")
	HealerToggle:SetLabel(L["Show Healer"])
	HealerToggle:SetValue(RoleDB.ShowHealer)
	HealerToggle:SetCallback("OnValueChanged", function(_, _, value) RoleDB.ShowHealer = value updateCallback() end)
	HealerToggle:SetRelativeWidth(0.33)
	ToggleContainer:AddChild(HealerToggle)

	local DamagerToggle = AG:Create("CheckBox")
	DamagerToggle:SetLabel(L["Show DPS"])
	DamagerToggle:SetValue(RoleDB.ShowDamager)
	DamagerToggle:SetCallback("OnValueChanged", function(_, _, value) RoleDB.ShowDamager = value updateCallback() end)
	DamagerToggle:SetRelativeWidth(0.33)
	ToggleContainer:AddChild(DamagerToggle)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(RoleDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) RoleDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(RoleDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) RoleDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(RoleDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) RoleDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(RoleDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) RoleDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(RoleDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) RoleDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshRoleGUI()
        if RoleDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
    end

    RefreshRoleGUI()
end

local function CreatePhaseIndicatorSettings(containerParent, unit, updateCallback)
    GetUnitDB(unit).Indicators.Phase = GetUnitDB(unit).Indicators.Phase or {}
    local DefaultPhaseDB = GetDefaultUnitDB(unit).Indicators.Phase
    for key, value in pairs(DefaultPhaseDB) do
        if GetUnitDB(unit).Indicators.Phase[key] == nil then
            GetUnitDB(unit).Indicators.Phase[key] = type(value) == "table" and {unpack(value)} or value
        end
    end
    local PhaseDB = GetUnitDB(unit).Indicators.Phase

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Phase Indicator Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFPhase|r Indicator"])
    Toggle:SetValue(PhaseDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) PhaseDB.Enabled = value updateCallback() RefreshPhaseGUI() end)
    Toggle:SetRelativeWidth(1)
    ToggleContainer:AddChild(Toggle)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(PhaseDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) PhaseDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(PhaseDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) PhaseDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(PhaseDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) PhaseDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(PhaseDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) PhaseDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(PhaseDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) PhaseDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshPhaseGUI()
        if PhaseDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
    end

    RefreshPhaseGUI()
end

local function CreatePvPIndicatorSettings(containerParent, updateCallback)
    local PvPIndicatorDB = UUF.db.profile.Units.player.Indicators.PvP

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["PvP Indicator Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFPvP|r Indicator"])
    Toggle:SetValue(PvPIndicatorDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) PvPIndicatorDB.Enabled = value updateCallback() RefreshPvPIndicatorGUI() end)
    Toggle:SetRelativeWidth(1)
    ToggleContainer:AddChild(Toggle)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(PvPIndicatorDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) PvPIndicatorDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(PvPIndicatorDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) PvPIndicatorDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(PvPIndicatorDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) PvPIndicatorDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(PvPIndicatorDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) PvPIndicatorDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(PvPIndicatorDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) PvPIndicatorDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshPvPIndicatorGUI()
        if PvPIndicatorDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
    end

    RefreshPvPIndicatorGUI()
end

local function CreateQuestIndicatorSettings(containerParent, updateCallback)
    local QuestIndicatorDB = UUF.db.profile.Units.target.Indicators.Quest

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Quest Indicator Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFQuest|r Indicator"])
    Toggle:SetValue(QuestIndicatorDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) QuestIndicatorDB.Enabled = value updateCallback() RefreshQuestIndicatorGUI() end)
    Toggle:SetRelativeWidth(0.5)
    ToggleContainer:AddChild(Toggle)

    local TextureDropdown = AG:Create("Dropdown")
    TextureDropdown:SetList({
        ["DEFAULT"] = "|TInterface\\TargetingFrame\\PortraitQuestBadge:20:20|t",
        ["QUEST0"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Quest\\Quest01.png:20:6|t",
        ["QUEST1"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Quest\\Quest02.png:20:20|t",
    }, {"DEFAULT", "QUEST0", "QUEST1"})
    TextureDropdown:SetLabel(L["Quest Texture"])
    TextureDropdown:SetValue(QuestIndicatorDB.Texture or "DEFAULT")
    TextureDropdown:SetRelativeWidth(0.5)
    TextureDropdown:SetCallback("OnValueChanged", function(_, _, value) QuestIndicatorDB.Texture = value updateCallback() end)
    ToggleContainer:AddChild(TextureDropdown)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(QuestIndicatorDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) QuestIndicatorDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(QuestIndicatorDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) QuestIndicatorDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(QuestIndicatorDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) QuestIndicatorDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(QuestIndicatorDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) QuestIndicatorDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(QuestIndicatorDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) QuestIndicatorDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshQuestIndicatorGUI()
        if QuestIndicatorDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
    end

    RefreshQuestIndicatorGUI()
end

local function CreateClassificationIndicatorSettings(containerParent, updateCallback)
    local ClassificationIndicatorDB = UUF.db.profile.Units.target.Indicators.Classification

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Classification Indicator Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFClassification|r Indicator"])
    Toggle:SetValue(ClassificationIndicatorDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) ClassificationIndicatorDB.Enabled = value updateCallback() RefreshClassificationIndicatorGUI() end)
    Toggle:SetRelativeWidth(0.5)
    ToggleContainer:AddChild(Toggle)

    local TextureDropdown = AG:Create("Dropdown")
    TextureDropdown:SetList({
        ["CLASSIFICATION0"] = "|A:nameplates-icon-elite-gold:20:20|a |A:nameplates-icon-elite-silver:20:20|a |A:nameplates-icon-elite-silver:20:20|a |A:nameplates-icon-elite-gold:20:20|a",
        ["CLASSIFICATION1"] = "|A:VignetteEvent-SuperTracked:20:20|a |A:VignetteEvent:20:20|a |A:VignetteKillElite-SuperTracked:20:20|a |A:vignettekillboss:20:20|a",
        ["CLASSIFICATION2"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Classic\\Elite.png:20:20|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Classic\\Rare.png:20:20|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Classic\\RareElite.png:20:20|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Classic\\WorldBoss.png:20:20|t",
        ["CLASSIFICATION3"] = "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Minimalist\\Elite.png:20:20|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Minimalist\\Rare.png:20:20|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Minimalist\\RareElite.png:20:20|t |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Classification\\Minimalist\\WorldBoss.png:20:20|t",
    }, {"CLASSIFICATION0", "CLASSIFICATION1", "CLASSIFICATION2", "CLASSIFICATION3"})
    TextureDropdown:SetLabel(L["Classification Texture"])
    TextureDropdown:SetValue(ClassificationIndicatorDB.Texture or "DEFAULT")
    TextureDropdown:SetRelativeWidth(0.5)
    TextureDropdown:SetCallback("OnValueChanged", function(_, _, value) ClassificationIndicatorDB.Texture = value updateCallback() end)
    ToggleContainer:AddChild(TextureDropdown)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(ClassificationIndicatorDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) ClassificationIndicatorDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(ClassificationIndicatorDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) ClassificationIndicatorDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(ClassificationIndicatorDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) ClassificationIndicatorDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(ClassificationIndicatorDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) ClassificationIndicatorDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(ClassificationIndicatorDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) ClassificationIndicatorDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshClassificationIndicatorGUI()
        GUIWidgets.DeepDisable(ToggleContainer, not ClassificationIndicatorDB.Enabled, Toggle)
        GUIWidgets.DeepDisable(LayoutContainer, not ClassificationIndicatorDB.Enabled, Toggle)
    end

    RefreshClassificationIndicatorGUI()
end

local function CreateStatusSettings(containerParent, unit, statusDB, updateCallback)
    local StatusDB = GetUnitDB(unit).Indicators[statusDB]
    local StatusName = L[statusDB]

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["%s Settings"]:format(StatusName))

    local StatusTextureList = {}
    for key, texture in pairs(StatusTextures[statusDB]) do
        StatusTextureList[key] = texture
    end

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FF%s|r Indicator"]:format(StatusName))
    Toggle:SetValue(StatusDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Enabled = value updateCallback() RefreshStatusGUI() end)
    Toggle:SetRelativeWidth(0.5)
    ToggleContainer:AddChild(Toggle)

    local StatusTextureDropdown = AG:Create("Dropdown")
    StatusTextureDropdown:SetList(StatusTextureList)
    StatusTextureDropdown:SetLabel(L["%s Texture"]:format(StatusName))
    StatusTextureDropdown:SetValue(StatusDB.Texture)
    StatusTextureDropdown:SetRelativeWidth(0.5)
    StatusTextureDropdown:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Texture = value updateCallback() end)
    ToggleContainer:AddChild(StatusTextureDropdown)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(StatusDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(StatusDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(StatusDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(StatusDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(StatusDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshStatusGUI()
        if StatusDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true, Toggle)
        end
    end

    RefreshStatusGUI()
end

local function CreateMouseoverSettings(containerParent, unit, updateCallback)
    local MouseoverDB = GetUnitDB(unit).Indicators.Mouseover

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Mouseover Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFMouseover|r Highlight"])
    Toggle:SetValue(MouseoverDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) MouseoverDB.Enabled = value updateCallback() RefreshMouseoverGUI() end)
    Toggle:SetRelativeWidth(1)
    ToggleContainer:AddChild(Toggle)

    local ColourPicker = AG:Create("ColorPicker")
    ColourPicker:SetLabel(L["Highlight Colour"])
    ColourPicker:SetColor(MouseoverDB.Colour[1], MouseoverDB.Colour[2], MouseoverDB.Colour[3])
    ColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) MouseoverDB.Colour = {r, g, b} updateCallback() end)
    ColourPicker:SetHasAlpha(false)
    ColourPicker:SetRelativeWidth(0.33)
    ToggleContainer:AddChild(ColourPicker)

    local OpacitySlider = AG:Create("Slider")
    OpacitySlider:SetLabel(L["Highlight Opacity"])
    OpacitySlider:SetValue(MouseoverDB.HighlightOpacity)
    OpacitySlider:SetSliderValues(0, 1, 0.01)
    OpacitySlider:SetRelativeWidth(0.33)
    OpacitySlider:SetCallback("OnValueChanged", function(_, _, value) MouseoverDB.HighlightOpacity = value updateCallback() end)
    OpacitySlider:SetIsPercent(true)
    ToggleContainer:AddChild(OpacitySlider)

    local StyleDropdown = AG:Create("Dropdown")
    StyleDropdown:SetList({["BORDER"] = L["Border"], ["OVERLAY"] = L["Overlay"], ["GRADIENT"] = L["Gradient"] })
    StyleDropdown:SetLabel(L["Highlight Style"])
    StyleDropdown:SetValue(MouseoverDB.Style)
    StyleDropdown:SetRelativeWidth(0.33)
    StyleDropdown:SetCallback("OnValueChanged", function(_, _, value) MouseoverDB.Style = value updateCallback() end)
    ToggleContainer:AddChild(StyleDropdown)

    function RefreshMouseoverGUI()
        if MouseoverDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
        end
    end

    RefreshMouseoverGUI()
end

local function CreateTargetIndicatorSettings(containerParent, unit, updateCallback)
    local TargetIndicatorDB = GetUnitDB(unit).Indicators.Target
    TargetIndicatorDB.Style = TargetIndicatorDB.Style or "Glow"

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Target Indicator Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFTarget Indicator|r"])
    Toggle:SetValue(TargetIndicatorDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) TargetIndicatorDB.Enabled = value updateCallback() RefreshTargetIndicatorGUI() end)
    Toggle:SetRelativeWidth(0.33)
    ToggleContainer:AddChild(Toggle)

    local ColourPicker = AG:Create("ColorPicker")
    ColourPicker:SetLabel(L["Indicator Colour"])
    ColourPicker:SetColor(TargetIndicatorDB.Colour[1], TargetIndicatorDB.Colour[2], TargetIndicatorDB.Colour[3])
    ColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) TargetIndicatorDB.Colour = {r, g, b} updateCallback() end)
    ColourPicker:SetHasAlpha(false)
    ColourPicker:SetRelativeWidth(0.33)
    ToggleContainer:AddChild(ColourPicker)

    local StyleDropdown = AG:Create("Dropdown")
    StyleDropdown:SetList({["Glow"] = L["Glow"], ["Border"] = L["Border"]}, {"Glow", "Border"})
    StyleDropdown:SetLabel(L["Indicator Style"])
    StyleDropdown:SetValue(TargetIndicatorDB.Style)
    StyleDropdown:SetRelativeWidth(0.33)
    StyleDropdown:SetCallback("OnValueChanged", function(_, _, value) TargetIndicatorDB.Style = value updateCallback() end)
    ToggleContainer:AddChild(StyleDropdown)

    function RefreshTargetIndicatorGUI()
        if TargetIndicatorDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
        end
    end

    RefreshTargetIndicatorGUI()
end

local function CreateThreatIndicatorSettings(containerParent, unit, updateCallback)
    GetUnitDB(unit).Indicators.Threat = GetUnitDB(unit).Indicators.Threat or {}
    local DefaultThreatDB = GetDefaultUnitDB(unit).Indicators.Threat
    for key, value in pairs(DefaultThreatDB) do
        if GetUnitDB(unit).Indicators.Threat[key] == nil then GetUnitDB(unit).Indicators.Threat[key] = type(value) == "table" and {unpack(value)} or value end
    end
    local ThreatIndicatorDB = GetUnitDB(unit).Indicators.Threat

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Threat Indicator Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFThreat|r Indicator"])
    Toggle:SetValue(ThreatIndicatorDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) ThreatIndicatorDB.Enabled = value updateCallback() RefreshThreatIndicatorGUI() end)
    Toggle:SetRelativeWidth(1)
    ToggleContainer:AddChild(Toggle)

    function RefreshThreatIndicatorGUI()
        GUIWidgets.DeepDisable(ToggleContainer, not ThreatIndicatorDB.Enabled, Toggle)
    end

    RefreshThreatIndicatorGUI()
end

local function CreateTotemsIndicatorSettings(containerParent, unit, updateCallback)
    local TotemsIndicatorDB = GetUnitDB(unit).Indicators.Totems

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Totems Settings"])

    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(L["Enable |cFF8080FFTotems|r"])
    Toggle:SetValue(TotemsIndicatorDB.Enabled)
    Toggle:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Enabled = value updateCallback() RefreshTotemsIndicatorGUI() end)
    Toggle:SetRelativeWidth(1)
    ToggleContainer:AddChild(Toggle)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])
    local TotemAnchorFromDropdown = AG:Create("Dropdown")
    TotemAnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    TotemAnchorFromDropdown:SetLabel(L["Anchor From"])
    TotemAnchorFromDropdown:SetValue(TotemsIndicatorDB.Layout[1])
    TotemAnchorFromDropdown:SetRelativeWidth(0.33)
    TotemAnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(TotemAnchorFromDropdown)

    local TotemAnchorToDropdown = AG:Create("Dropdown")
    TotemAnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    TotemAnchorToDropdown:SetLabel(L["Anchor To"])
    TotemAnchorToDropdown:SetValue(TotemsIndicatorDB.Layout[2])
    TotemAnchorToDropdown:SetRelativeWidth(0.33)
    TotemAnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(TotemAnchorToDropdown)

    local GrowthDirectionDropdown = AG:Create("Dropdown")
    GrowthDirectionDropdown:SetList({["RIGHT"] = L["Right"], ["LEFT"] = L["Left"]})
    GrowthDirectionDropdown:SetLabel(L["Growth Direction"])
    GrowthDirectionDropdown:SetValue(TotemsIndicatorDB.GrowthDirection)
    GrowthDirectionDropdown:SetRelativeWidth(0.33)
    GrowthDirectionDropdown:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.GrowthDirection = value updateCallback() end)
    LayoutContainer:AddChild(GrowthDirectionDropdown)

    local TotemXPosSlider = AG:Create("Slider")
    TotemXPosSlider:SetLabel(L["X Position"])
    TotemXPosSlider:SetValue(TotemsIndicatorDB.Layout[3])
    TotemXPosSlider:SetSliderValues(-3000, 3000, 0.1)
    TotemXPosSlider:SetRelativeWidth(0.25)
    TotemXPosSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(TotemXPosSlider)

    local TotemYPosSlider = AG:Create("Slider")
    TotemYPosSlider:SetLabel(L["Y Position"])
    TotemYPosSlider:SetValue(TotemsIndicatorDB.Layout[4])
    TotemYPosSlider:SetSliderValues(-3000, 3000, 0.1)
    TotemYPosSlider:SetRelativeWidth(0.25)
    TotemYPosSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(TotemYPosSlider)

    local SpacingSlider = AG:Create("Slider")
    SpacingSlider:SetLabel(L["Totems Indicator Spacing"])
    SpacingSlider:SetValue(TotemsIndicatorDB.Layout[5])
    SpacingSlider:SetSliderValues(0, 100, 1)
    SpacingSlider:SetRelativeWidth(0.25)
    SpacingSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[5] = value updateCallback() end)
    LayoutContainer:AddChild(SpacingSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Icon Size"])
    SizeSlider:SetValue(TotemsIndicatorDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.25)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    function RefreshTotemsIndicatorGUI()
        if TotemsIndicatorDB.Enabled then
            GUIWidgets.DeepDisable(ToggleContainer, false, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, false)
        else
            GUIWidgets.DeepDisable(ToggleContainer, true, Toggle)
            GUIWidgets.DeepDisable(LayoutContainer, true)
        end
    end

    RefreshTotemsIndicatorGUI()
end

local function CreateIndicatorSettings(containerParent, unit)
    local function SelectIndicatorTab(IndicatorContainer, _, IndicatorTab)
        SaveSubTab(unit, "Indicators", IndicatorTab)
        IndicatorContainer:ReleaseChildren()
        if IndicatorTab == "RaidTargetMarker" then
            CreateRaidTargetMarkerSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitRaidTargetMarker(UUF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "LeaderAssistant" then
            CreateLeaderAssistaintSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitLeaderAssistantIndicator(UUF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Role" then
            CreateRoleIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
        elseif IndicatorTab == "Phase" then
            CreatePhaseIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
		elseif IndicatorTab == "ReadyCheckIndicator" then
			CreateReadyCheckIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
		elseif IndicatorTab == "ResurrectIndicator" then
			CreateResurrectIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
		elseif IndicatorTab == "Summon" then
			CreateSummonIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
        elseif IndicatorTab == "Resting" then
            CreateStatusSettings(IndicatorContainer, unit, "Resting", function() UUF:UpdateUnitRestingIndicator(UUF[unit:upper()], unit) end)
        elseif IndicatorTab == "Combat" then
            CreateStatusSettings(IndicatorContainer, unit, "Combat", function() UUF:UpdateUnitCombatIndicator(UUF[unit:upper()], unit) end)
        elseif IndicatorTab == "PvP" and unit == "player" then
            CreatePvPIndicatorSettings(IndicatorContainer, function() UUF:UpdateUnitPvPIndicator(UUF.PLAYER, "player") end)
        elseif IndicatorTab == "Mouseover" then
            CreateMouseoverSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitMouseoverIndicator(UUF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "TargetIndicator" then
            CreateTargetIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitTargetGlowIndicator(UUF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "ThreatIndicator" then
            CreateThreatIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitThreatIndicator(UUF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Totems" then
            CreateTotemsIndicatorSettings(IndicatorContainer, unit, function() UUF:UpdateUnitTotems(UUF[unit:upper()], unit) end)
        elseif IndicatorTab == "Quest" and unit == "target" then
            CreateQuestIndicatorSettings(IndicatorContainer, function() UUF:UpdateUnitQuestIndicator(UUF.TARGET, "target") end)
        elseif IndicatorTab == "Classification" and unit == "target" then
            CreateClassificationIndicatorSettings(IndicatorContainer, function() UUF:UpdateUnitClassificationIndicator(UUF.TARGET, "target") end)
        end
    end

    local IndicatorContainerTabGroup = AG:Create("TabGroup")
    IndicatorContainerTabGroup:SetLayout("Flow")
    IndicatorContainerTabGroup:SetFullWidth(true)
    if unit == "player" then
        IndicatorContainerTabGroup:SetTabs({
            { text = L["Raid Target Marker"], value = "RaidTargetMarker" },
            { text = L["Leader & Assistant"], value = "LeaderAssistant" },
            { text = L["Resting"], value = "Resting" },
            { text = L["Combat"], value = "Combat" },
            { text = L["PvP"], value = "PvP" },
            { text = L["Mouseover"], value = "Mouseover" },
            { text = L["Threat Indicator"], value = "ThreatIndicator" },
            { text = L["Totems"], value = "Totems" },
        })
    elseif unit == "target" then
        IndicatorContainerTabGroup:SetTabs({
            { text = L["Raid Target Marker"], value = "RaidTargetMarker" },
            { text = L["Leader & Assistant"], value = "LeaderAssistant" },
            { text = L["Combat"], value = "Combat" },
            { text = L["Mouseover"], value = "Mouseover" },
            { text = L["Target Indicator"], value = "TargetIndicator" },
            { text = L["Threat Indicator"], value = "ThreatIndicator" },
            { text = L["Classification"], value = "Classification" },
            { text = L["Quest"], value = "Quest" },
        })
	elseif unit == "party" or unit == "raid" or unit == "augmentation" then
        IndicatorContainerTabGroup:SetTabs({
            { text = L["Raid Target Marker"], value = "RaidTargetMarker" },
            { text = L["Leader & Assistant"], value = "LeaderAssistant" },
            { text = L["Mouseover"], value = "Mouseover" },
            { text = L["Target Indicator"], value = "TargetIndicator" },
            { text = L["Threat Indicator"], value = "ThreatIndicator" },
            { text = L["Role"], value = "Role" },
            { text = L["Phase"], value = "Phase" },
			{ text = L["Ready Check"], value = "ReadyCheckIndicator" },
			{ text = L["Resurrect"], value = "ResurrectIndicator" },
			{ text = L["Summon"], value = "Summon" },
        })
    elseif unit == "focus" or unit == "pet" then
        IndicatorContainerTabGroup:SetTabs({
            { text = L["Raid Target Marker"], value = "RaidTargetMarker" },
            { text = L["Mouseover"], value = "Mouseover" },
            { text = L["Target Indicator"], value = "TargetIndicator" },
            { text = L["Threat Indicator"], value = "ThreatIndicator" },
        })
    elseif unit == "targettarget" or unit == "focustarget" or unit == "boss" then
        IndicatorContainerTabGroup:SetTabs({
            { text = L["Raid Target Marker"], value = "RaidTargetMarker" },
            { text = L["Mouseover"], value = "Mouseover" },
            { text = L["Target Indicator"], value = "TargetIndicator" },
        })
    end
    IndicatorContainerTabGroup:SetCallback("OnGroupSelected", SelectIndicatorTab)
    IndicatorContainerTabGroup:SelectTab(GetSavedSubTab(unit, "Indicators", "RaidTargetMarker"))
    containerParent:AddChild(IndicatorContainerTabGroup)
end

local function CreateTagSetting(containerParent, unit, tagDB)
	local TagDB = GetUnitDB(unit).Tags[tagDB]
	local function UpdateTag()
		if unit == "boss" and UUF.BOSS_TEST_MODE or unit == "party" and UUF.PARTY_TEST_MODE or unit == "raid" and UUF.RAID_TEST_MODE then
			UUF:UpdateTestEnvironment(unit, "Tags")
		else
			UUF:UpdateUnitTags(unit, tagDB)
		end
	end

    local TagContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Tag Settings"])

    local EditBox = AG:Create("EditBox")
    EditBox:SetLabel(L["Tag"])
    EditBox:SetText(TagDB.Tag)
    EditBox:SetRelativeWidth(0.5)
    EditBox:DisableButton(true)
    EditBox:SetCallback("OnEnterPressed", function(_, _, value) TagDB.Tag = value EditBox:SetText(TagDB.Tag) UpdateTag() end)
    TagContainer:AddChild(EditBox)

    local ColourPicker = AG:Create("ColorPicker")
    ColourPicker:SetLabel(L["Colour"])
    ColourPicker:SetColor(TagDB.Colour[1], TagDB.Colour[2], TagDB.Colour[3], 1)
    ColourPicker:SetFullWidth(true)
    ColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) TagDB.Colour = {r, g, b} UpdateTag() end)
    ColourPicker:SetHasAlpha(false)
    ColourPicker:SetRelativeWidth(0.5)
    TagContainer:AddChild(ColourPicker)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Layout & Positioning"])

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel(L["Anchor From"])
    AnchorFromDropdown:SetValue(TagDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) TagDB.Layout[1] = value UpdateTag() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel(L["Anchor To"])
    AnchorToDropdown:SetValue(TagDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) TagDB.Layout[2] = value UpdateTag() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(TagDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) TagDB.Layout[3] = value UpdateTag() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(TagDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) TagDB.Layout[4] = value UpdateTag() end)
    LayoutContainer:AddChild(YPosSlider)

    local FontSizeSlider = AG:Create("Slider")
    FontSizeSlider:SetLabel(L["Font Size"])
    FontSizeSlider:SetValue(TagDB.FontSize)
    FontSizeSlider:SetSliderValues(8, 64, 1)
    FontSizeSlider:SetRelativeWidth(0.33)
    FontSizeSlider:SetCallback("OnValueChanged", function(_, _, value) TagDB.FontSize = value UpdateTag() end)
    LayoutContainer:AddChild(FontSizeSlider)

    local TagSelectionContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Tag Selection"])
    GUIWidgets.CreateInformationTag(TagSelectionContainer, L["You can use the dropdowns below to quickly add tags.\n|cFF8080FFPrefix|r indicates that this should be added to the start of the tag string."])

    local HealthTagDropdown = AG:Create("Dropdown")
    HealthTagDropdown:SetList(UUF:FetchTagData("Health")[1], UUF:FetchTagData("Health")[2])
    HealthTagDropdown:SetLabel(L["Health Tags"])
    HealthTagDropdown:SetValue(nil)
    HealthTagDropdown:SetRelativeWidth(0.5)
    HealthTagDropdown:SetCallback("OnValueChanged", function(_, _, value) local currentTag = TagDB.Tag if currentTag and currentTag ~= "" then currentTag = currentTag .. "[" .. value .. "]" else currentTag = "[" .. value .. "]" end EditBox:SetText(currentTag) GetUnitDB(unit).Tags[tagDB].Tag = currentTag UpdateTag() HealthTagDropdown:SetValue(nil) end)
    TagSelectionContainer:AddChild(HealthTagDropdown)

    local PowerTagDropdown = AG:Create("Dropdown")
    PowerTagDropdown:SetList(UUF:FetchTagData("Power")[1], UUF:FetchTagData("Power")[2])
    PowerTagDropdown:SetLabel(L["Power Tags"])
    PowerTagDropdown:SetValue(nil)
    PowerTagDropdown:SetRelativeWidth(0.5)
    PowerTagDropdown:SetCallback("OnValueChanged", function(_, _, value) local currentTag = TagDB.Tag if currentTag and currentTag ~= "" then currentTag = currentTag .. "[" .. value .. "]" else currentTag = "[" .. value .. "]" end EditBox:SetText(currentTag) GetUnitDB(unit).Tags[tagDB].Tag = currentTag UpdateTag() PowerTagDropdown:SetValue(nil) end)
    TagSelectionContainer:AddChild(PowerTagDropdown)

    local NameTagDropdown = AG:Create("Dropdown")
    NameTagDropdown:SetList(UUF:FetchTagData("Name")[1], UUF:FetchTagData("Name")[2])
    NameTagDropdown:SetLabel(L["Name Tags"])
    NameTagDropdown:SetValue(nil)
    NameTagDropdown:SetRelativeWidth(0.5)
    NameTagDropdown:SetCallback("OnValueChanged", function(_, _, value) local currentTag = TagDB.Tag if currentTag and currentTag ~= "" then currentTag = currentTag .. "[" .. value .. "]" else currentTag = "[" .. value .. "]" end EditBox:SetText(currentTag) GetUnitDB(unit).Tags[tagDB].Tag = currentTag UpdateTag() NameTagDropdown:SetValue(nil) end)
    TagSelectionContainer:AddChild(NameTagDropdown)

    local MiscTagDropdown = AG:Create("Dropdown")
    MiscTagDropdown:SetList(UUF:FetchTagData("Misc")[1], UUF:FetchTagData("Misc")[2])
    MiscTagDropdown:SetLabel(L["Misc Tags"])
    MiscTagDropdown:SetValue(nil)
    MiscTagDropdown:SetRelativeWidth(0.5)
    MiscTagDropdown:SetCallback("OnValueChanged", function(_, _, value) local currentTag = TagDB.Tag if currentTag and currentTag ~= "" then currentTag = currentTag .. "[" .. value .. "]" else currentTag = "[" .. value .. "]" end EditBox:SetText(currentTag) GetUnitDB(unit).Tags[tagDB].Tag = currentTag UpdateTag() MiscTagDropdown:SetValue(nil) end)
    MiscTagDropdown:SetDisabled(#UUF:FetchTagData("Misc") == 0)
    TagSelectionContainer:AddChild(MiscTagDropdown)

    containerParent:DoLayout()
end

local function CreateTagsSettings(containerParent, unit)

    local function SelectTagTab(TagContainer, _, TagTab)
        SaveSubTab(unit, "Tags", TagTab)
        TagContainer:ReleaseChildren()
        CreateTagSetting(TagContainer, unit, TagTab)
        containerParent:DoLayout()
    end

    local TagContainerTabGroup = AG:Create("TabGroup")
    TagContainerTabGroup:SetLayout("Flow")
    TagContainerTabGroup:SetFullWidth(true)
    TagContainerTabGroup:SetTabs({
        { text = L["Tag One"], value = "TagOne"},
        { text = L["Tag Two"], value = "TagTwo"},
        { text = L["Tag Three"], value = "TagThree"},
        { text = L["Tag Four"], value = "TagFour"},
        { text = L["Tag Five"], value = "TagFive"},
    })
    TagContainerTabGroup:SetCallback("OnGroupSelected", SelectTagTab)
    TagContainerTabGroup:SelectTab(GetSavedSubTab(unit, "Tags", "TagOne"))
    containerParent:AddChild(TagContainerTabGroup)

    containerParent:DoLayout()
end

local function GetAuraContainerTreeLabel(auraKey, AuraDB)
	local filterNames = {}
	local configuredNames = {}
	for _, filter in ipairs(UUF.AURA_FILTERS) do
		if AuraDB.Filters[filter.Key] then
			local filterName = filter.TreeTitle or filter.Title
			if not configuredNames[filterName] then
				configuredNames[filterName] = true
				filterNames[#filterNames + 1] = filterName
			end
		end
	end
	return #filterNames > 0 and L[AuraDB.Type] .. " - " .. table.concat(filterNames, ", ") or auraKey
end

local function CreateSpecificAuraSettings(containerParent, unit, auraKey, refreshSettings, refreshTree)
    local AuraDB = GetUnitDB(unit).Auras.Containers[auraKey]
    local auraTitle = AuraDB.Type
    local function UpdateAuras()
        UpdateUnitSettings(unit, function() UUF:UpdateUnitAuras(UUF[unit:upper()], unit) end, "Auras")
    end

    local AuraContainer = GUIWidgets.CreateInlineGroup(containerParent, GetAuraContainerTreeLabel(auraKey, AuraDB))
    local TypeDropdown = AG:Create("Dropdown")
    TypeDropdown:SetList({["Buffs"] = L["Buffs"], ["Debuffs"] = L["Debuffs"]}, {"Buffs", "Debuffs"})
    TypeDropdown:SetLabel(L["Container Type"])
    TypeDropdown:SetValue(AuraDB.Type)
    TypeDropdown:SetRelativeWidth(0.5)
    TypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
        AuraDB.Type = value
        UpdateAuras()
		refreshTree()
		refreshSettings()
    end)
    AuraContainer:AddChild(TypeDropdown)

    local ShowTypeCheckbox = AG:Create("CheckBox")
    ShowTypeCheckbox:SetLabel(L["Show %s Type Border"]:format(L[auraTitle]))
    ShowTypeCheckbox:SetValue(AuraDB.ShowType)
    ShowTypeCheckbox:SetCallback("OnValueChanged", function(_, _, value) AuraDB.ShowType = value UpdateAuras() end)
    ShowTypeCheckbox:SetRelativeWidth(0.5)
    AuraContainer:AddChild(ShowTypeCheckbox)

	local selectedSettingsTab = GetSavedSubTab(unit, "AuraContainerSettings", "Layout")
	local SettingsTabs = AG:Create("TabGroup")
	SettingsTabs:SetLayout("Flow")
	SettingsTabs:SetFullWidth(true)
	SettingsTabs:SetTabs({
        {text = L["Layout & Positioning"], value = "Layout"},
		{text = L["Count"], value = "Count"},
		{text = L["Filters"], value = "Filters"},
	})
	SettingsTabs:SelectTab(selectedSettingsTab)
	SettingsTabs:SetCallback("OnGroupSelected", function(_, _, value) SaveSubTab(unit, "AuraContainerSettings", value) refreshSettings() end)
	containerParent:AddChild(SettingsTabs)

	if selectedSettingsTab == "Filters" then
    local FilterContainer = GUIWidgets.CreateInlineGroup(SettingsTabs, L["%s Filters"]:format(L[auraTitle]))
    GUIWidgets.CreateInformationTag(FilterContainer, L["Filters support |cFF8080FFmultiple selections|r."])
    for _, filterGroup in ipairs({"Player (You)", "Others (Not You)"}) do
        local filterList = {}
        local filterOrder = {}
        local filterDescriptions = {}
        local FilterDropdown = AG:Create("Dropdown")
        for _, filter in ipairs(UUF.AURA_FILTERS) do
            if filter.Group == filterGroup then
                filterList[filter.Key] = filter.Title
                filterOrder[#filterOrder + 1] = filter.Key
                filterDescriptions[filter.Key] = filter.Desc
            end
        end
        FilterDropdown:SetLabel(L["%s Filters"]:format(L[filterGroup]))
        FilterDropdown:SetMultiselect(true)
        FilterDropdown:SetList(filterList, filterOrder)
        for _, filterKey in ipairs(filterOrder) do FilterDropdown:SetItemValue(filterKey, AuraDB.Filters[filterKey] or false) end
        FilterDropdown:SetRelativeWidth(0.5)
        FilterDropdown:SetCallback("OnValueChanged", function(_, _, filterKey, value) AuraDB.Filters[filterKey] = value or nil AuraContainer:SetTitle("|cFFFFFFFF" .. GetAuraContainerTreeLabel(auraKey, AuraDB) .. "|r") UpdateAuras() refreshTree() end)
        for _, dropdownItem in FilterDropdown.pullout:IterateItems() do
            local desc = filterDescriptions[dropdownItem.userdata and dropdownItem.userdata.value]
            if desc then
                dropdownItem:SetCallback("OnEnter", function() GameTooltip:SetOwner(dropdownItem.frame, "ANCHOR_CURSOR_RIGHT") GameTooltip:SetFrameStrata("TOOLTIP") GameTooltip:SetFrameLevel((FilterDropdown.pullout.frame:GetFrameLevel() or 0) + 100) GameTooltip:SetToplevel(true) GameTooltip:AddLine(desc, 1, 1, 1, true) GameTooltip:Show() GameTooltip:SetFrameLevel((FilterDropdown.pullout.frame:GetFrameLevel() or 0) + 100) end)
                dropdownItem:SetCallback("OnLeave", function() GameTooltip:Hide() end)
            end
        end
        FilterContainer:AddChild(FilterDropdown)
    end

    local SpellIDContainer = GUIWidgets.CreateInlineGroup(SettingsTabs, L["SpellID Filters"])
	local SpellIDInformation = AG:Create("InteractiveLabel")
	SpellIDInformation:SetText(UUF.INFOBUTTON)
	SpellIDInformation:SetWidth(24)
	SpellIDInformation.frame:SetParent(SpellIDContainer.frame)
	SpellIDInformation.frame:ClearAllPoints()
	SpellIDInformation.frame:SetPoint("TOPLEFT", SpellIDContainer.frame, "TOPLEFT", 18 + SpellIDContainer.titletext:GetStringWidth(), -3)
	SpellIDInformation.frame:Show()
	SpellIDInformation:SetCallback("OnEnter", function() GameTooltip:SetOwner(SpellIDInformation.frame, "ANCHOR_CURSOR_RIGHT") GameTooltip:AddLine(AdditionalSpellIDsTooltip, 1, 1, 1, false) GameTooltip:Show() end)
	SpellIDInformation:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	SpellIDContainer:SetCallback("OnRelease", function() GameTooltip:Hide() AG:Release(SpellIDInformation) end)

	local SpellIDEditBox = AG:Create("EditBox")
	SpellIDEditBox:SetLabel(L["Add SpellID"])
	SpellIDEditBox:DisableButton(true)
	SpellIDEditBox:SetRelativeWidth(0.35)
	SpellIDContainer:AddChild(SpellIDEditBox)

	local SpellIDDropdown = AG:Create("Dropdown")
	SpellIDDropdown:SetLabel(L["Added Spells"])
	SpellIDDropdown:SetRelativeWidth(0.65)
	SpellIDContainer:AddChild(SpellIDDropdown)

	local configuredSpellIDs = AuraDB.SpellIDs
	local function RefreshSpellIDDropdown()
		local spellList = {}
		local spellOrder = {}
		for spellID in pairs(configuredSpellIDs) do
			local spellInfo = C_Spell.GetSpellInfo(spellID)
			local spellName = spellInfo and spellInfo.name or L["Unknown Spell"]
			local iconID = spellInfo and spellInfo.iconID or 134400
			spellList[spellID] = ("|T%d:16:16:0:0|t %s - |cFF808080%d|r"):format(iconID, spellName, spellID)
			spellOrder[#spellOrder + 1] = spellID
		end
		table.sort(spellOrder)
		SpellIDDropdown:SetList(spellList, spellOrder)
		SpellIDDropdown:SetValue(nil)
		SpellIDDropdown:SetText(spellList[spellOrder[1]] or "")
		SpellIDDropdown:SetDisabled(#spellOrder == 0)
	end

	SpellIDEditBox:SetCallback("OnEnterPressed", function(widget, _, value)
		local spellID = tostring(value or ""):match("^%s*(%d+)%s*$")
		spellID = spellID and tonumber(spellID)
		if not spellID or spellID <= 0 or spellID > 2147483647 then return true end
		local spellInfo = C_Spell.GetSpellInfo(spellID)
		if not spellInfo or not spellInfo.name then			return true end

		if configuredSpellIDs[spellID] then return true end

		configuredSpellIDs[spellID] = true
		RefreshSpellIDDropdown()
		UpdateAuras()
		widget:SetText("")
		widget:ClearFocus()
	end)

	SpellIDDropdown:SetCallback("OnValueChanged", function(_, _, spellID)
		local spellInfo = C_Spell.GetSpellInfo(spellID)
		local spellName = spellInfo and spellInfo.name or L["Unknown Spell"]
		local iconID = spellInfo and spellInfo.iconID or 134400
		UUF:CreatePrompt(L["Remove SpellID"], "Remove |T" .. iconID .. ":16:16:0:0|t |cFF8080FF" .. spellName .. "|r (" .. spellID .. L[") from this container?"], function() configuredSpellIDs[spellID] = nil RefreshSpellIDDropdown() UpdateAuras() end, function() RefreshSpellIDDropdown() end, L["Remove"])
	end)

	RefreshSpellIDDropdown()

	elseif selectedSettingsTab == "Layout" then
    local LayoutContainer = GUIWidgets.CreateInlineGroup(SettingsTabs, L["Layout & Positioning"])

	local AnchorParentDropdown = AG:Create("Dropdown")
	AnchorParentDropdown:SetList(AuraAnchorParents[1], AuraAnchorParents[2])
	AnchorParentDropdown:SetLabel(L["Anchor Parent"])
	AnchorParentDropdown:SetValue(AuraDB.AnchorParent)
	AnchorParentDropdown:SetRelativeWidth(0.5)
	AnchorParentDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.AnchorParent = value UpdateAuras() end)
	LayoutContainer:AddChild(AnchorParentDropdown)

	local AnchorFromDropdown = AG:Create("Dropdown")
	AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorFromDropdown:SetLabel(L["Anchor From"])
	AnchorFromDropdown:SetValue(AuraDB.Layout[1])
	AnchorFromDropdown:SetRelativeWidth(0.5)
	AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Layout[1] = value UpdateAuras() end)
	LayoutContainer:AddChild(AnchorFromDropdown)

	local AnchorToDropdown = AG:Create("Dropdown")
	AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorToDropdown:SetLabel(L["Anchor To"])
	AnchorToDropdown:SetValue(AuraDB.Layout[2])
	AnchorToDropdown:SetRelativeWidth(0.5)
	AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Layout[2] = value UpdateAuras() end)
	LayoutContainer:AddChild(AnchorToDropdown)

    local SortingDropdown = AG:Create("Dropdown")
    SortingDropdown:SetList({ BLIZZARD = L["Blizzard"], BLIZZARD_REVERSED = L["Blizzard Reversed"], DURATION = L["Duration"], DURATION_REVERSED = L["Duration Reversed"], }, {"BLIZZARD", "BLIZZARD_REVERSED", "DURATION", "DURATION_REVERSED"})
    SortingDropdown:SetLabel(L["Aura Sorting"])
    SortingDropdown:SetValue(AuraDB.Sorting or "BLIZZARD")
    SortingDropdown:SetRelativeWidth(0.5)
    SortingDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Sorting = value UpdateAuras() end)
    for _, dropdownItem in SortingDropdown.pullout:IterateItems() do
        local value = dropdownItem.userdata and dropdownItem.userdata.value
        local desc = value == "BLIZZARD" and L["|cFF00B4FFBlizzard|r's Default Ordering."]
            or value == "BLIZZARD_REVERSED" and L["|cFF00B4FFBlizzard|r's Default Ordering in Reverse."]
            or value == "DURATION" and L["|cFF8080FFDuration-Based|r Ordering.\nAuras with the shortest remaining duration will be displayed first."]
            or value == "DURATION_REVERSED" and L["|cFF8080FFDuration-Based|r Ordering in Reverse.\nAuras with the longest remaining duration will be displayed first."]
        if desc then
            dropdownItem:SetCallback("OnEnter", function() GameTooltip:SetOwner(dropdownItem.frame, "ANCHOR_CURSOR_RIGHT") GameTooltip:SetFrameStrata("TOOLTIP") GameTooltip:SetFrameLevel((SortingDropdown.pullout.frame:GetFrameLevel() or 0) + 100) GameTooltip:SetToplevel(true) GameTooltip:AddLine(desc, 1, 1, 1, false) GameTooltip:Show() GameTooltip:SetFrameLevel((SortingDropdown.pullout.frame:GetFrameLevel() or 0) + 100) end)
            dropdownItem:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        end
    end
    LayoutContainer:AddChild(SortingDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel(L["X Position"])
    XPosSlider:SetValue(AuraDB.Layout[3])
    XPosSlider:SetSliderValues(-3000, 3000, 0.1)
    XPosSlider:SetRelativeWidth(0.5)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Layout[3] = value UpdateAuras() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel(L["Y Position"])
    YPosSlider:SetValue(AuraDB.Layout[4])
    YPosSlider:SetSliderValues(-3000, 3000, 0.1)
    YPosSlider:SetRelativeWidth(0.5)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Layout[4] = value UpdateAuras() end)
    LayoutContainer:AddChild(YPosSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel(L["Size"])
    SizeSlider:SetValue(AuraDB.Size)
    SizeSlider:SetSliderValues(8, 64, 1)
    SizeSlider:SetRelativeWidth(0.5)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Size = value UpdateAuras() end)
    LayoutContainer:AddChild(SizeSlider)

    local SpacingSlider = AG:Create("Slider")
    SpacingSlider:SetLabel(L["Spacing"])
    SpacingSlider:SetValue(AuraDB.Layout[5])
    SpacingSlider:SetSliderValues(-5, 5, 1)
    SpacingSlider:SetRelativeWidth(0.5)
    SpacingSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Layout[5] = value UpdateAuras() end)
    LayoutContainer:AddChild(SpacingSlider)

    GUIWidgets.CreateHeader(LayoutContainer, L["Layout"])

    local NumAurasSlider = AG:Create("Slider")
    NumAurasSlider:SetLabel(L["%s Limit"]:format(L[auraTitle]))
    NumAurasSlider:SetValue(AuraDB.Num)
    NumAurasSlider:SetSliderValues(1, 24, 1)
    NumAurasSlider:SetRelativeWidth(0.5)
    NumAurasSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Num = value UpdateAuras() end)
    LayoutContainer:AddChild(NumAurasSlider)

    local PerRowSlider = AG:Create("Slider")
    PerRowSlider:SetLabel(L["%s Per Row"]:format(L[auraTitle]))
    PerRowSlider:SetValue(AuraDB.Wrap)
    PerRowSlider:SetSliderValues(1, 24, 1)
    PerRowSlider:SetRelativeWidth(0.5)
    PerRowSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Wrap = value UpdateAuras() end)
    LayoutContainer:AddChild(PerRowSlider)

    local GrowthDirectionDropdown = AG:Create("Dropdown")
    GrowthDirectionDropdown:SetList({["LEFT"] = L["Left"], ["CENTER"] = L["Centered"], ["RIGHT"] = L["Right"]}, {"LEFT", "CENTER", "RIGHT"})
    GrowthDirectionDropdown:SetLabel(L["Growth Direction"])
    GrowthDirectionDropdown:SetValue(AuraDB.GrowthDirection)
    GrowthDirectionDropdown:SetRelativeWidth(0.5)
    GrowthDirectionDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.GrowthDirection = value UpdateAuras() end)
    LayoutContainer:AddChild(GrowthDirectionDropdown)

    local WrapDirectionDropdown = AG:Create("Dropdown")
    WrapDirectionDropdown:SetList({ ["UP"] = L["Up"], ["DOWN"] = L["Down"]})
    WrapDirectionDropdown:SetLabel(L["Wrap Direction"])
    WrapDirectionDropdown:SetValue(AuraDB.WrapDirection)
    WrapDirectionDropdown:SetRelativeWidth(0.5)
    WrapDirectionDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.WrapDirection = value UpdateAuras() end)
    LayoutContainer:AddChild(WrapDirectionDropdown)

	elseif selectedSettingsTab == "Count" then
    local CountContainer = GUIWidgets.CreateInlineGroup(SettingsTabs, L["Count Settings"])

    local ColourPicker = AG:Create("ColorPicker")
    ColourPicker:SetLabel(L["Colour"])
    ColourPicker:SetColor(AuraDB.Count.Colour[1], AuraDB.Count.Colour[2], AuraDB.Count.Colour[3], 1)
    ColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) AuraDB.Count.Colour = {r, g, b} UpdateAuras() end)
    ColourPicker:SetHasAlpha(false)
    ColourPicker:SetRelativeWidth(0.5)
    CountContainer:AddChild(ColourPicker)

    local HideStacksToggle = AG:Create("CheckBox")
    HideStacksToggle:SetLabel(L["Hide Stacks"])
    HideStacksToggle:SetValue(AuraDB.Count.HideStacks or false)
    HideStacksToggle:SetRelativeWidth(0.5)
    HideStacksToggle:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Count.HideStacks = value UpdateAuras() GUIWidgets.DeepDisable(CountContainer, value, HideStacksToggle) end)
    CountContainer:AddChild(HideStacksToggle)

    local CountAnchorFromDropdown = AG:Create("Dropdown")
    CountAnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    CountAnchorFromDropdown:SetLabel(L["Anchor From"])
    CountAnchorFromDropdown:SetValue(AuraDB.Count.Layout[1])
    CountAnchorFromDropdown:SetRelativeWidth(0.5)
    CountAnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Count.Layout[1] = value UpdateAuras() end)
    CountContainer:AddChild(CountAnchorFromDropdown)

    local CountAnchorToDropdown = AG:Create("Dropdown")
    CountAnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    CountAnchorToDropdown:SetLabel(L["Anchor To"])
    CountAnchorToDropdown:SetValue(AuraDB.Count.Layout[2])
    CountAnchorToDropdown:SetRelativeWidth(0.5)
    CountAnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Count.Layout[2] = value UpdateAuras() end)
    CountContainer:AddChild(CountAnchorToDropdown)

    local CountXPosSlider = AG:Create("Slider")
    CountXPosSlider:SetLabel(L["X Position"])
    CountXPosSlider:SetValue(AuraDB.Count.Layout[3])
    CountXPosSlider:SetSliderValues(-3000, 3000, 0.1)
    CountXPosSlider:SetRelativeWidth(0.33)
    CountXPosSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Count.Layout[3] = value UpdateAuras() end)
    CountContainer:AddChild(CountXPosSlider)

    local CountYPosSlider = AG:Create("Slider")
    CountYPosSlider:SetLabel(L["Y Position"])
    CountYPosSlider:SetValue(AuraDB.Count.Layout[4])
    CountYPosSlider:SetSliderValues(-3000, 3000, 0.1)
    CountYPosSlider:SetRelativeWidth(0.33)
    CountYPosSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Count.Layout[4] = value UpdateAuras() end)
    CountContainer:AddChild(CountYPosSlider)

    local FontSizeSlider = AG:Create("Slider")
    FontSizeSlider:SetLabel(L["Font Size"])
    FontSizeSlider:SetValue(AuraDB.Count.FontSize)
    FontSizeSlider:SetSliderValues(8, 64, 1)
    FontSizeSlider:SetRelativeWidth(0.33)
    FontSizeSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Count.FontSize = value UpdateAuras() end)
    CountContainer:AddChild(FontSizeSlider)

	GUIWidgets.DeepDisable(CountContainer, AuraDB.Count.HideStacks, HideStacksToggle)
	end

    containerParent:DoLayout()
end

local function CreateAuraSettings(containerParent, unit, refreshScrollFrame)
    local AurasDB = GetUnitDB(unit).Auras

    local ShowAurasButton = AG:Create("Button")
	ShowAurasButton:SetText(UUF.AURA_TEST_MODE and L["Hide Auras"] or L["Show Auras"])
	ShowAurasButton:SetRelativeWidth(0.5)
	ShowAurasButton:SetCallback("OnClick", function()
		if UUF.AURA_TEST_MODE then DisableAurasTestMode(unit) else EnableAurasTestMode(unit) end
		ShowAurasButton:SetText(UUF.AURA_TEST_MODE and L["Hide Auras"] or L["Show Auras"])
	end)
	containerParent:AddChild(ShowAurasButton)

    local FrameStrataDropdown = AG:Create("Dropdown")
    FrameStrataDropdown:SetList(FrameStrataList[1], FrameStrataList[2])
    FrameStrataDropdown:SetLabel(L["Frame Strata"])
    FrameStrataDropdown:SetValue(AurasDB.FrameStrata)
    FrameStrataDropdown:SetRelativeWidth(0.5)
    FrameStrataDropdown:SetCallback("OnValueChanged", function(_, _, value) AurasDB.FrameStrata = value UpdateUnitSettings(unit, function() UUF:UpdateUnitAurasStrata(unit) end, "Auras") end)
    containerParent:AddChild(FrameStrataDropdown)

    local function CreateAuraContainerManager(managerParent)
		local selectedContainer = GetSavedSubTab(unit, "AuraContainer", nil)
		if not AurasDB.Containers[selectedContainer] then selectedContainer = nil end

		local CreateButton = AG:Create("Button")
		CreateButton:SetText(L["Create Aura Container"])
		CreateButton:SetRelativeWidth(0.5)
		managerParent:AddChild(CreateButton)

		local DeleteButton = AG:Create("Button")
		DeleteButton:SetText(L["Delete Aura Container"])
		DeleteButton:SetRelativeWidth(0.5)
		DeleteButton:SetDisabled(not selectedContainer)
		managerParent:AddChild(DeleteButton)

		local ContainerTree = AG:Create("TreeGroup")
		ContainerTree:SetLayout("Fill")
		ContainerTree:SetFullWidth(true)
		ContainerTree:SetAutoAdjustHeight(false)
		ContainerTree:SetHeight(350)
		ContainerTree:SetTreeWidth(200, false)
		managerParent:AddChild(ContainerTree)

		local function UpdateAuras()
			UpdateUnitSettings(unit, function() UUF:UpdateUnitAuras(UUF[unit:upper()], unit) end, "Auras")
		end

		local function RefreshTree()
			local containerTree = {}
			local containerKeys = UUF:GetAuraContainerKeys(AurasDB)
			for _, containerKey in ipairs(containerKeys) do containerTree[#containerTree + 1] = {text = GetAuraContainerTreeLabel(containerKey, AurasDB.Containers[containerKey]), value = containerKey} end
			ContainerTree:SetTree(containerTree)
			CreateButton:SetDisabled(#containerKeys >= UUF.MAX_AURA_CONTAINERS)
		end

		local function RefreshSelectedContainer()
			ContainerTree:ReleaseChildren()
			DeleteButton:SetDisabled(not selectedContainer)
			if selectedContainer and AurasDB.Containers[selectedContainer] then
				local OptionsScrollFrame = GUIWidgets.CreateScrollFrame(ContainerTree)
				CreateSpecificAuraSettings(OptionsScrollFrame, unit, selectedContainer, RefreshSelectedContainer, RefreshTree)
				OptionsScrollFrame:DoLayout()
			end
			ContainerTree:DoLayout()
			managerParent:DoLayout()
			containerParent:DoLayout()
			refreshScrollFrame()
		end

		ContainerTree:SetCallback("OnGroupSelected", function(_, _, value)
			selectedContainer = value
			SaveSubTab(unit, "AuraContainer", value)
			RefreshSelectedContainer()
		end)

		CreateButton:SetCallback("OnClick", function()
			if #UUF:GetAuraContainerKeys(AurasDB) >= UUF.MAX_AURA_CONTAINERS then return end
			local containerIndex = 1
			local containerKey = "Container #" .. containerIndex
			while AurasDB.Containers[containerKey] do containerIndex = containerIndex + 1 containerKey = "Container #" .. containerIndex end
			local ContainerDB = {}
			UUF:CopyTable(GetDefaultUnitDB(unit).Auras.Container, ContainerDB)
			AurasDB.Containers[containerKey] = ContainerDB
			selectedContainer = containerKey
			UpdateAuras()
			RefreshTree()
			ContainerTree:SelectByValue(containerKey)
		end)

		DeleteButton:SetCallback("OnClick", function()
			if not selectedContainer or not AurasDB.Containers[selectedContainer] then return end
			local containerToDelete = selectedContainer
			local containerLabel = GetAuraContainerTreeLabel(containerToDelete, AurasDB.Containers[containerToDelete])
			UUF:CreatePrompt(L["Delete Aura Container"], string.format(L["Delete |cFF8080FF%s|r and all of its settings?"], containerLabel), function()
				AurasDB.Containers[containerToDelete] = nil
				selectedContainer = nil
				SaveSubTab(unit, "AuraContainer", nil)
				UpdateAuras()
				RefreshTree()
				RefreshSelectedContainer()
			end, nil, L["Delete"])
		end)

		RefreshTree()
		if selectedContainer and AurasDB.Containers[selectedContainer] then ContainerTree:SelectByValue(selectedContainer) else selectedContainer = nil SaveSubTab(unit, "AuraContainer", nil) RefreshSelectedContainer() end
    end

    CreateAuraContainerManager(containerParent)

    containerParent:DoLayout()
end

local function CreateCooldownTextSettings(containerParent)
    local CooldownTextDB = UUF.db.profile.General.CooldownText
    local CooldownTextContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Cooldown Text Settings"])

    local AdvancedToggle = AG:Create("CheckBox")
    AdvancedToggle:SetLabel(L["Advanced"])
    AdvancedToggle:SetValue(CooldownTextDB.Advanced)
    AdvancedToggle:SetRelativeWidth(CooldownTextDB.Advanced and 1 or 0.5)
    AdvancedToggle:SetCallback("OnValueChanged", function(_, _, value) CooldownTextDB.Advanced = value UUF:UpdateAllUnitFrames() containerParent:ReleaseChildren() CreateCooldownTextSettings(containerParent) containerParent:DoLayout() end)
    AdvancedToggle:SetCallback("OnEnter", function() GameTooltip:SetOwner(AdvancedToggle.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(L["Advanced Settings will allow you to customize cooldown text for each unit individually."], 1, 1, 1, true) GameTooltip:Show() end)
    AdvancedToggle:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    CooldownTextContainer:AddChild(AdvancedToggle)

    local function CreateCooldownTextStyleSettings(StyleContainerParent, CooldownTextStyleDB)
        local ScaleByIconSizeCheckbox = AG:Create("CheckBox")
        ScaleByIconSizeCheckbox:SetLabel(L["Scale Cooldown Text By Icon Size"])
        ScaleByIconSizeCheckbox:SetValue(CooldownTextStyleDB.ScaleByIconSize)
        ScaleByIconSizeCheckbox:SetRelativeWidth(CooldownTextDB.Advanced and 1 or 0.5)
        StyleContainerParent:AddChild(ScaleByIconSizeCheckbox)

        local AnchorFromDropdown = AG:Create("Dropdown")
        AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        AnchorFromDropdown:SetLabel(L["Anchor From"])
        AnchorFromDropdown:SetValue(CooldownTextStyleDB.Layout[1])
        AnchorFromDropdown:SetRelativeWidth(0.5)
        AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) CooldownTextStyleDB.Layout[1] = value UUF:UpdateAllUnitFrames() end)
        StyleContainerParent:AddChild(AnchorFromDropdown)

        local AnchorToDropdown = AG:Create("Dropdown")
        AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        AnchorToDropdown:SetLabel(L["Anchor To"])
        AnchorToDropdown:SetValue(CooldownTextStyleDB.Layout[2])
        AnchorToDropdown:SetRelativeWidth(0.5)
        AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) CooldownTextStyleDB.Layout[2] = value UUF:UpdateAllUnitFrames() end)
        StyleContainerParent:AddChild(AnchorToDropdown)

        local XPosSlider = AG:Create("Slider")
        XPosSlider:SetLabel(L["X Position"])
        XPosSlider:SetValue(CooldownTextStyleDB.Layout[3])
        XPosSlider:SetSliderValues(-3000, 3000, 0.1)
        XPosSlider:SetRelativeWidth(0.33)
        XPosSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownTextStyleDB.Layout[3] = value UUF:UpdateAllUnitFrames() end)
        StyleContainerParent:AddChild(XPosSlider)

        local YPosSlider = AG:Create("Slider")
        YPosSlider:SetLabel(L["Y Position"])
        YPosSlider:SetValue(CooldownTextStyleDB.Layout[4])
        YPosSlider:SetSliderValues(-3000, 3000, 0.1)
        YPosSlider:SetRelativeWidth(0.33)
        YPosSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownTextStyleDB.Layout[4] = value UUF:UpdateAllUnitFrames() end)
        StyleContainerParent:AddChild(YPosSlider)

        local FontSizeSlider = AG:Create("Slider")
        FontSizeSlider:SetLabel(L["Font Size"])
        FontSizeSlider:SetValue(CooldownTextStyleDB.FontSize)
        FontSizeSlider:SetSliderValues(8, 64, 1)
        FontSizeSlider:SetRelativeWidth(0.33)
        FontSizeSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownTextStyleDB.FontSize = value UUF:UpdateAllUnitFrames() end)
        FontSizeSlider:SetDisabled(CooldownTextStyleDB.ScaleByIconSize)
        StyleContainerParent:AddChild(FontSizeSlider)
        ScaleByIconSizeCheckbox:SetCallback("OnValueChanged", function(_, _, value) CooldownTextStyleDB.ScaleByIconSize = value FontSizeSlider:SetDisabled(value) UUF:UpdateAllUnitFrames() end)
    end

    if CooldownTextDB.Advanced then
        local function SelectCooldownTextTab(CooldownTextTabContainer, _, CooldownTextTab)
            CooldownTextTabContainer:ReleaseChildren()
            if CooldownTextTab == "Global" then
                CreateCooldownTextStyleSettings(CooldownTextTabContainer, CooldownTextDB)
            elseif CooldownTextTab == "Auras" then
                local function SelectAuraUnit(AuraUnitContainer, _, unit)
                    AuraUnitContainer:ReleaseChildren()
                    CreateCooldownTextStyleSettings(AuraUnitContainer, GetUnitDB(unit).Auras.AuraDuration)
                    containerParent:DoLayout()
                end

                local AuraUnitTabs = AG:Create("TabGroup")
                AuraUnitTabs:SetLayout("Flow")
                AuraUnitTabs:SetFullWidth(true)
				local auraUnitTabs = {
                    { text = L["Player"], value = "player" },
                    { text = L["Target"], value = "target" },
                    { text = L["Target of Target"], value = "targettarget" },
                    { text = L["Focus"], value = "focus" },
                    { text = L["Focus Target"], value = "focustarget" },
                    { text = L["Pet"], value = "pet" },
                    { text = L["Party"], value = "party" },
                    { text = L["Raid"], value = "raid" },
				}
				if UUF:IsAugmentationEvoker() then auraUnitTabs[#auraUnitTabs + 1] = { text = L["Augmentation Raid"], value = "augmentation" } end
				auraUnitTabs[#auraUnitTabs + 1] = { text = L["Boss"], value = "boss" }
				AuraUnitTabs:SetTabs(auraUnitTabs)
                AuraUnitTabs:SetCallback("OnGroupSelected", SelectAuraUnit)
                AuraUnitTabs:SelectTab("player")
                CooldownTextTabContainer:AddChild(AuraUnitTabs)
            end
            containerParent:DoLayout()
        end

        local CooldownTextTabs = AG:Create("TabGroup")
        CooldownTextTabs:SetLayout("Flow")
        CooldownTextTabs:SetFullWidth(true)
        CooldownTextTabs:SetTabs({
            { text = L["Global"], value = "Global" },
            { text = L["Auras"], value = "Auras" },
        })
        CooldownTextTabs:SetCallback("OnGroupSelected", SelectCooldownTextTab)
        CooldownTextTabs:SelectTab("Global")
        CooldownTextContainer:AddChild(CooldownTextTabs)
    else
        CreateCooldownTextStyleSettings(CooldownTextContainer, CooldownTextDB)
    end

    local Breakpoints = CooldownTextDB.CooldownBreakpoints
    local DefaultBreakpoints = UUF:GetDefaultDB().profile.General.CooldownText.CooldownBreakpoints
    for BreakpointIndex = 1, 5 do
        Breakpoints[BreakpointIndex] = Breakpoints[BreakpointIndex] or CopyTable(DefaultBreakpoints[BreakpointIndex])
        Breakpoints[BreakpointIndex].color = Breakpoints[BreakpointIndex].color or CopyTable(DefaultBreakpoints[BreakpointIndex].color)
    end
    while #Breakpoints > 5 do tremove(Breakpoints) end

    local BreakpointContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Cooldown Text Breakpoints"])

    local function SelectBreakpoint(BreakpointTabContainer, _, BreakpointIndex)
        BreakpointTabContainer:ReleaseChildren()
        local BreakpointDB = Breakpoints[BreakpointIndex]

        local MinimumValue = AG:Create("EditBox")
        MinimumValue:SetLabel(L["Minimum Value in Seconds"])
        MinimumValue:SetText(tostring(BreakpointDB.threshold or 0))
        MinimumValue:SetRelativeWidth(0.33)
        MinimumValue:SetCallback("OnEnterPressed", function(widget, _, value) value = tonumber(value) if not value then widget:SetText(tostring(BreakpointDB.threshold or 0)) return end BreakpointDB.threshold = value BreakpointDB.components = UUF:GetCooldownDurationComponents(BreakpointDB.displayStyle, value) UUF:UpdateAllUnitFrames() end)
        BreakpointTabContainer:AddChild(MinimumValue)

        local DisplayStyle = AG:Create("Dropdown")
        DisplayStyle:SetLabel(L["Display Style"])
        DisplayStyle:SetList(CooldownBreakpointStyles[1], CooldownBreakpointStyles[2])
        DisplayStyle:SetValue(BreakpointDB.displayStyle)
        DisplayStyle:SetRelativeWidth(0.33)
        DisplayStyle:SetCallback("OnValueChanged", function(_, _, value)
            local DisplayStyleDB = CooldownBreakpointSettings[value]
            BreakpointDB.displayStyle = value
            BreakpointDB.step = DisplayStyleDB.step
            BreakpointDB.rounding = DisplayStyleDB.rounding
            BreakpointDB.min = DisplayStyleDB.min
            BreakpointDB.format = CreateColor(unpack(BreakpointDB.color)):WrapTextInColorCode(DisplayStyleDB.format)
            BreakpointDB.components = UUF:GetCooldownDurationComponents(value, BreakpointDB.threshold or 0)
            UUF:UpdateAllUnitFrames()
        end)
        BreakpointTabContainer:AddChild(DisplayStyle)

        local ColourPicker = AG:Create("ColorPicker")
        ColourPicker:SetLabel(L["Colour"])
        ColourPicker:SetColor(BreakpointDB.color[1], BreakpointDB.color[2], BreakpointDB.color[3], BreakpointDB.color[4] or 1)
        ColourPicker:SetHasAlpha(false)
        ColourPicker:SetRelativeWidth(0.33)
        ColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) BreakpointDB.color = {r, g, b, 1} BreakpointDB.format = CreateColor(r, g, b, 1):WrapTextInColorCode(CooldownBreakpointSettings[BreakpointDB.displayStyle].format) UUF:UpdateAllUnitFrames() end)
        BreakpointTabContainer:AddChild(ColourPicker)
    end

    local BreakpointTabs = AG:Create("TabGroup")
    BreakpointTabs:SetLayout("Flow")
    BreakpointTabs:SetFullWidth(true)
    BreakpointTabs:SetTabs({
        { text = L["Breakpoint 1"], value = 1 },
        { text = L["Breakpoint 2"], value = 2 },
        { text = L["Breakpoint 3"], value = 3 },
        { text = L["Breakpoint 4"], value = 4 },
        { text = L["Breakpoint 5"], value = 5 },
    })
    BreakpointTabs:SetCallback("OnGroupSelected", SelectBreakpoint)
    BreakpointTabs:SelectTab(1)
    BreakpointContainer:AddChild(BreakpointTabs)
end

local function CreateGlobalToggleSettings(containerParent)
    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Toggles"])

    local ApplyColours = AG:Create("Button")
    ApplyColours:SetText(L["Colour Mode"])
    ApplyColours:SetRelativeWidth(0.33)
    ApplyColours:SetCallback("OnClick", function()
        UUF:ForEachUnitDB(function(unitDB)
            unitDB.HealthBar.ColourByClass = true
            unitDB.HealthBar.ColourWhenTapped = true
            unitDB.HealthBar.ColourBackgroundByClass = false
        end)
        UUF:UpdateAllUnitFrames()
    end)
    ToggleContainer:AddChild(ApplyColours)

    local RemoveColours = AG:Create("Button")
    RemoveColours:SetText(L["Dark Mode"])
    RemoveColours:SetRelativeWidth(0.33)
    RemoveColours:SetCallback("OnClick", function() UUF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.ColourByClass = false unitDB.HealthBar.ColourWhenTapped = false unitDB.HealthBar.ColourBackgroundByClass = false end) UUF:UpdateAllUnitFrames() end)
    ToggleContainer:AddChild(RemoveColours)

    local DisplayLoginMessageToggle = AG:Create("CheckBox")
    DisplayLoginMessageToggle:SetLabel(L["Display Login Message"])
    DisplayLoginMessageToggle:SetValue(UUF.db.global.DisplayLoginMessage)
    DisplayLoginMessageToggle:SetCallback("OnValueChanged", function(_, _, value) UUF.db.global.DisplayLoginMessage = value end)
    DisplayLoginMessageToggle:SetRelativeWidth(0.33)
    ToggleContainer:AddChild(DisplayLoginMessageToggle)
end

local function CreateGlobalTagSettings(containerParent)
    local TagContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Tag Settings"])

    local UseCustomAbbreviationsCheckbox = AG:Create("CheckBox")
    UseCustomAbbreviationsCheckbox:SetLabel(L["Custom Abbreviations"])
    UseCustomAbbreviationsCheckbox:SetValue(UUF.db.profile.General.UseCustomAbbreviations)
    UseCustomAbbreviationsCheckbox:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.UseCustomAbbreviations = value UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    UseCustomAbbreviationsCheckbox:SetRelativeWidth(0.25)
    TagContainer:AddChild(UseCustomAbbreviationsCheckbox)

    local TagIntervalSlider = AG:Create("Slider")
    TagIntervalSlider:SetLabel(L["Tag Updates Per Second"])
    TagIntervalSlider:SetValue(1 / UUF.db.profile.General.TagUpdateInterval)
    TagIntervalSlider:SetSliderValues(1, 10, 0.5)
    TagIntervalSlider:SetRelativeWidth(0.25)
    TagIntervalSlider:SetCallback("OnValueChanged", function(_, _, value) UUF.TAG_UPDATE_INTERVAL = 1 / value UUF.db.profile.General.TagUpdateInterval = 1 / value UUF:SetTagUpdateInterval() UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    TagContainer:AddChild(TagIntervalSlider)

    local SeparatorDropdown = AG:Create("Dropdown")
    SeparatorDropdown:SetList(UUF.SEPARATOR_TAGS[1], UUF.SEPARATOR_TAGS[2])
    SeparatorDropdown:SetLabel(L["Tag Separator"])
    SeparatorDropdown:SetValue(UUF.db.profile.General.Separator)
    SeparatorDropdown:SetRelativeWidth(0.25)
    SeparatorDropdown:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.Separator = value UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    SeparatorDropdown:SetCallback("OnEnter", function() GameTooltip:SetOwner(SeparatorDropdown.frame, "ANCHOR_BOTTOM") GameTooltip:AddLine(L["The separator chosen here is only applied to custom tags which are combined. Such as |cFF8080FF[curhpperhp]|r or |cFF8080FF[curhpperhp:abbr]|r"], 1, 1, 1) GameTooltip:Show() end)
    SeparatorDropdown:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    TagContainer:AddChild(SeparatorDropdown)

    local ToTSeparatorDropdown = AG:Create("Dropdown")
    ToTSeparatorDropdown:SetList(UUF.TOT_SEPARATOR_TAGS[1], UUF.TOT_SEPARATOR_TAGS[2])
    ToTSeparatorDropdown:SetLabel(L["ToT Separator"])
    ToTSeparatorDropdown:SetValue(UUF.db.profile.General.ToTSeparator)
    ToTSeparatorDropdown:SetRelativeWidth(0.25)
    ToTSeparatorDropdown:SetCallback("OnValueChanged", function(_, _, value) UUF.db.profile.General.ToTSeparator = value UUF.TOT_SEPARATOR = value UUF:ForEachUnitDB(function(_, unit) UUF:UpdateUnitTags(unit) end) end)
    ToTSeparatorDropdown:SetCallback("OnEnter", function() GameTooltip:SetOwner(ToTSeparatorDropdown.frame, "ANCHOR_BOTTOM") GameTooltip:AddLine(L["Used as the prefix separator for Target of Target tags like |cFF8080FF[name:target]|r on your target frame."], 1, 1, 1) GameTooltip:Show() end)
    ToTSeparatorDropdown:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    TagContainer:AddChild(ToTSeparatorDropdown)
end

local function CreateUnitSettings(containerParent, unit)
    local EnableUnitFrameToggle = AG:Create("CheckBox")
    EnableUnitFrameToggle:SetLabel(L["Enable |cFF8080FF%s|r"]:format(UnitDBToUnitPrettyName[unit] or unit))
    EnableUnitFrameToggle:SetValue(GetUnitDB(unit).Enabled)
    EnableUnitFrameToggle:SetCallback("OnValueChanged", function(_, _, value)
        StaticPopupDialogs["UUF_RELOAD_UI"] = {
            text = L["You must reload to apply this change, do you want to reload now?"],
            button1 = L["Reload Now"],
            button2 = L["Later"],
            showAlert = true,
            OnAccept = function() GetUnitDB(unit).Enabled= value C_UI.Reload() end,
            OnCancel = function() EnableUnitFrameToggle:SetValue(GetUnitDB(unit).Enabled) containerParent:DoLayout() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("UUF_RELOAD_UI")
    end)
	EnableUnitFrameToggle:SetRelativeWidth(unit == "augmentation" and 0.5 or 0.33)
    containerParent:AddChild(EnableUnitFrameToggle)

	if unit ~= "augmentation" then
		local HideBlizzardToggle = AG:Create("CheckBox")
		HideBlizzardToggle:SetLabel(L["Hide Blizzard |cFF8080FF%s|r"]:format(UnitDBToUnitPrettyName[unit] or unit))
		HideBlizzardToggle:SetValue(GetUnitDB(unit).ForceHideBlizzard)
		HideBlizzardToggle:SetCallback("OnValueChanged", function(_, _, value)
				StaticPopupDialogs["UUF_RELOAD_UI"] = {
				text = L["You must reload to apply this change, do you want to reload now?"],
				button1 = L["Reload Now"],
				button2 = L["Later"],
				showAlert = true,
				OnAccept = function() GetUnitDB(unit).ForceHideBlizzard = value C_UI.Reload() end,
				OnCancel = function() HideBlizzardToggle:SetValue(GetUnitDB(unit).ForceHideBlizzard) containerParent:DoLayout() end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
			}
			StaticPopup_Show("UUF_RELOAD_UI")
		end)
		HideBlizzardToggle:SetRelativeWidth(0.33)
		HideBlizzardToggle:SetDisabled(GetUnitDB(unit).Enabled)
		containerParent:AddChild(HideBlizzardToggle)
	end

	local ToggleMoversButton = AG:Create("Button")
	ToggleMoversButton:SetText(UUF.MOVERS_UNLOCKED and L["Lock Movers"] or L["Unlock Movers"])
	ToggleMoversButton:SetRelativeWidth(unit == "augmentation" and 0.5 or 0.33)
	ToggleMoversButton:SetCallback("OnClick", function() ToggleMoversButton:SetText(UUF:ToggleMovers() and L["Lock Movers"] or L["Unlock Movers"]) end)
	containerParent:AddChild(ToggleMoversButton)

    local SettingsContainer = AG:Create("SimpleGroup")
    SettingsContainer:SetFullWidth(true)
    SettingsContainer:SetLayout("Flow")
    containerParent:AddChild(SettingsContainer)

    local playerClass = UnitClassBase("player")
    local playerHasSecondaryPower = playerClass == "DEATHKNIGHT" or UUF:GetSecondaryPowerType() ~= nil

    local function SelectUnitTab(SubContainer, _, UnitTab)
        if not lastSelectedUnitTabs[unit] then lastSelectedUnitTabs[unit] = {} end
        lastSelectedUnitTabs[unit].mainTab = UnitTab
		containerParent.UUFDisableScroll = UnitTab == "Auras"
		containerParent.scrollframe:EnableMouseWheel(UnitTab ~= "Auras")
		if UnitTab == "Auras" then containerParent:SetScroll(0) end
        SubContainer:ReleaseChildren()
        if UnitTab == "Frame" then
            CreateFrameSettings(SubContainer, unit, GetUnitDB(unit).Frame.AnchorParent and true or false, function(element) UpdateUnitSettings(unit, function() UUF:UpdateUnitFrame(UUF[unit:upper()], unit) end, element) end)
		elseif UnitTab == "Players" and unit == "augmentation" then
			CreateAugmentationFrameSettings(SubContainer)
        elseif UnitTab == "HealPrediction" then
            CreateHealPredictionSettings(SubContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitHealPrediction(UUF[unit:upper()], unit) end, "HealPrediction") end)
        elseif UnitTab == "Auras" then
            CreateAuraSettings(SubContainer, unit, function() SettingsContainer:DoLayout() containerParent:DoLayout() end)
        elseif UnitTab == "PowerBar" then
            CreatePowerBarSettings(SubContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitPowerBar(UUF[unit:upper()], unit) end, "PowerBar") end)
        elseif UnitTab == "SecondaryPowerBar" and unit == "player" and playerHasSecondaryPower then
            CreateSecondaryPowerBarSettings(SubContainer, unit, function() UUF:UpdateUnitSecondaryPowerBar(UUF[unit:upper()], unit) end)
        elseif UnitTab == "AlternativePowerBar" then
            CreateAlternativePowerBarSettings(SubContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitAlternativePowerBar(UUF[unit:upper()], unit) end) end)
        elseif UnitTab == "CastBar" then
            CreateCastBarSettings(SubContainer, unit)
        elseif UnitTab == "Portrait" then
            CreatePortraitSettings(SubContainer, unit, function() UpdateUnitSettings(unit, function() UUF:UpdateUnitPortrait(UUF[unit:upper()], unit) end, "Portrait") end)
        elseif UnitTab == "Indicators" then
            CreateIndicatorSettings(SubContainer, unit)
        elseif UnitTab == "Tags" then
            CreateTagsSettings(SubContainer, unit)
        end
        if UnitTab == "CastBar" then EnableCastBarTestMode(unit) else DisableCastBarTestMode(unit) end
		if unit == "party" and UUF.PARTY_TEST_MODE or unit == "raid" and UUF.RAID_TEST_MODE then UUF:UpdateTestEnvironment(unit, "all") end
        containerParent:DoLayout()
    end

    local SubContainerTabGroup = AG:Create("TabGroup")
    SubContainerTabGroup:SetLayout("Flow")
    SubContainerTabGroup:SetFullWidth(true)

    if unit == "player" then
        local playerTabs = {
            { text = L["Frame"], value = "Frame"},
            { text = L["Heal Prediction"], value = "HealPrediction"},
            { text = L["Auras"], value = "Auras"},
            { text = L["Power Bar"], value = "PowerBar"},
            { text = L["Cast Bar"], value = "CastBar"},
            { text = L["Portrait"], value = "Portrait"},
            { text = L["Indicators"], value = "Indicators"},
            { text = L["Tags"], value = "Tags"},
        }

        local nextPowerTabIndex = 5
        if playerHasSecondaryPower then
            table.insert(playerTabs, nextPowerTabIndex, { text = L["Secondary Power Bar"], value = "SecondaryPowerBar"})
            nextPowerTabIndex = nextPowerTabIndex + 1
        end
        if UUF:RequiresAlternativePowerBar() then
            table.insert(playerTabs, nextPowerTabIndex, { text = L["Alternative Power Bar"], value = "AlternativePowerBar"})
        end

        SubContainerTabGroup:SetTabs(playerTabs)
    elseif unit == "party" then
        SubContainerTabGroup:SetTabs({
            { text = L["Frame"], value = "Frame"},
            { text = L["Heal Prediction"], value = "HealPrediction"},
            { text = L["Auras"], value = "Auras"},
            { text = L["Power Bar"], value = "PowerBar"},
            { text = L["Indicators"], value = "Indicators"},
            { text = L["Tags"], value = "Tags"},
        })
	elseif unit == "raid" or unit == "augmentation" then
		local raidTabs = {
			{ text = L["Frame"], value = "Frame"},
			{ text = L["Heal Prediction"], value = "HealPrediction"},
			{ text = L["Auras"], value = "Auras"},
			{ text = L["Power Bar"], value = "PowerBar"},
			{ text = L["Indicators"], value = "Indicators"},
			{ text = L["Tags"], value = "Tags"},
		}
		if unit == "augmentation" then table.insert(raidTabs, { text = L["Players"], value = "Players"}) end
		SubContainerTabGroup:SetTabs(raidTabs)
    elseif unit ~= "targettarget" and unit ~= "focustarget" then
        SubContainerTabGroup:SetTabs({
            { text = L["Frame"], value = "Frame"},
            { text = L["Heal Prediction"], value = "HealPrediction"},
            { text = L["Auras"], value = "Auras"},
            { text = L["Power Bar"], value = "PowerBar"},
            { text = L["Cast Bar"], value = "CastBar"},
            { text = L["Portrait"], value = "Portrait"},
            { text = L["Indicators"], value = "Indicators"},
            { text = L["Tags"], value = "Tags"},
        })
    else
        SubContainerTabGroup:SetTabs({
            { text = L["Frame"], value = "Frame"},
            { text = L["Heal Prediction"], value = "HealPrediction"},
            { text = L["Auras"], value = "Auras"},
            { text = L["Power Bar"], value = "PowerBar"},
            { text = L["Indicators"], value = "Indicators"},
            { text = L["Tags"], value = "Tags"},
        })
    end
    SubContainerTabGroup:SetCallback("OnGroupSelected", SelectUnitTab)
	local selectedTab = GetSavedMainTab(unit, "Frame")
    if selectedTab == "SecondaryPowerBar" and not playerHasSecondaryPower then selectedTab = "Frame" end
    SubContainerTabGroup:SelectTab(selectedTab)
    SettingsContainer:AddChild(SubContainerTabGroup)

    GUIWidgets.DeepDisable(SettingsContainer, not GetUnitDB(unit).Enabled)

    containerParent:DoLayout()
end

local function CreateTagSettings(containerParent)

    local function DrawTagContainer(TagContainer, TagGroup)
        local TagsList, TagOrder = UUF:FetchTagData(TagGroup)[1], UUF:FetchTagData(TagGroup)[2]

        local SortedTagsList = {}
        for _, tag in ipairs(TagOrder) do
            if TagsList[tag] then
                SortedTagsList[tag] = TagsList[tag]
            end
        end

        for _, Tag in ipairs(TagOrder) do
            local Desc = SortedTagsList[Tag]
            local TagDesc = AG:Create("Label")
            TagDesc:SetText(Desc)
            TagDesc:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            TagDesc:SetRelativeWidth(0.5)
            TagContainer:AddChild(TagDesc)

            local TagValue = AG:Create("EditBox")
            TagValue:SetText("[" .. Tag .. "]")
            TagValue:SetCallback("OnTextChanged", function(widget, event, value) TagValue:ClearFocus() TagValue:SetText("[" .. Tag .. "]") end)
            TagValue:SetRelativeWidth(0.5)
            TagContainer:AddChild(TagValue)
        end
    end

    local function SelectedGroup(TagContainer, _, TagGroup)
        TagContainer:ReleaseChildren()
        if TagGroup == "Health" then
            DrawTagContainer(TagContainer, "Health")
        elseif TagGroup == "Name" then
            DrawTagContainer(TagContainer, "Name")
        elseif TagGroup == "Power" then
            DrawTagContainer(TagContainer, "Power")
        elseif TagGroup == "Misc" then
            DrawTagContainer(TagContainer, "Misc")
        end
        TagContainer:DoLayout()
    end

    local GUIContainerTabGroup = AG:Create("TabGroup")
    GUIContainerTabGroup:SetLayout("Flow")
    GUIContainerTabGroup:SetTabs({
        { text = L["Health"], value = "Health" },
        { text = L["Name"], value = "Name" },
        { text = L["Power"], value = "Power" },
        { text = L["Miscellaneous"], value = "Misc" },
    })
    GUIContainerTabGroup:SetCallback("OnGroupSelected", SelectedGroup)
    GUIContainerTabGroup:SelectTab("Health")
    GUIContainerTabGroup:SetFullWidth(true)
    containerParent:AddChild(GUIContainerTabGroup)
    containerParent:DoLayout()
end

local function CreateProfileSettings(containerParent)
    local profileKeys = {}
    local specProfilesList = {}
    local numSpecs = GetNumSpecializations()

    local ProfileContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Profile Management"])

    local ActiveProfileHeading = AG:Create("Heading")
    ActiveProfileHeading:SetFullWidth(true)
    ProfileContainer:AddChild(ActiveProfileHeading)

    local function RefreshProfiles()
        wipe(profileKeys)
        local tmp = {}
        for _, name in ipairs(UUF.db:GetProfiles(tmp, true)) do profileKeys[name] = name end
        local profilesToDelete = {}
        for k, v in pairs(profileKeys) do profilesToDelete[k] = v end
        profilesToDelete[UUF.db:GetCurrentProfile()] = nil
        SelectProfileDropdown:SetList(profileKeys)
        CopyFromProfileDropdown:SetList(profileKeys)
        GlobalProfileDropdown:SetList(profileKeys)
        DeleteProfileDropdown:SetList(profilesToDelete)
        for i = 1, numSpecs do
            specProfilesList[i]:SetList(profileKeys)
            specProfilesList[i]:SetValue(UUF.db:GetDualSpecProfile(i))
        end
        SelectProfileDropdown:SetValue(UUF.db:GetCurrentProfile())
        GlobalProfileDropdown:SetValue((UUF.db.global.GlobalProfile and UUF.db.global.GlobalProfile ~= "" and UUF.db.global.GlobalProfile) or (UUF.db.global.GlobalProfileName and UUF.db.global.GlobalProfileName ~= "" and UUF.db.global.GlobalProfileName) or "Default")
        CopyFromProfileDropdown:SetValue(nil)
        DeleteProfileDropdown:SetValue(nil)
        if not next(profilesToDelete) then
            DeleteProfileDropdown:SetDisabled(true)
        else
            DeleteProfileDropdown:SetDisabled(false)
        end
        ResetProfileButton:SetText(string.format(L["Reset |cFF8080FF%s|r Profile"], UUF.db:GetCurrentProfile()))
        local isUsingGlobal = UUF.db.global.UseGlobalProfile
        local activeProfileText = string.format(L["Active Profile: |cFFFFFFFF%s|r"], UUF.db:GetCurrentProfile())
	if isUsingGlobal then activeProfileText = activeProfileText .. L[" (|cFF8080FFGlobal|r)"] end
        ActiveProfileHeading:SetText(activeProfileText)
        if UUF.db:IsDualSpecEnabled() then
            SelectProfileDropdown:SetDisabled(true)
            CopyFromProfileDropdown:SetDisabled(true)
            GlobalProfileDropdown:SetDisabled(true)
            DeleteProfileDropdown:SetDisabled(true)
            UseGlobalProfileToggle:SetDisabled(true)
            GlobalProfileDropdown:SetDisabled(true)
        else
            SelectProfileDropdown:SetDisabled(isUsingGlobal)
            CopyFromProfileDropdown:SetDisabled(isUsingGlobal)
            GlobalProfileDropdown:SetDisabled(not isUsingGlobal)
            DeleteProfileDropdown:SetDisabled(isUsingGlobal or not next(profilesToDelete))
            UseGlobalProfileToggle:SetDisabled(false)
            GlobalProfileDropdown:SetDisabled(not isUsingGlobal)
        end
    end

    UUFG.RefreshProfiles = RefreshProfiles -- Exposed for Share.lua

    SelectProfileDropdown = AG:Create("Dropdown")
    SelectProfileDropdown:SetLabel(L["Select..."])
    SelectProfileDropdown:SetRelativeWidth(0.25)
    SelectProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) UUF.db:SetProfile(value) UUF:SetUIScale() UUF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(SelectProfileDropdown)

    CopyFromProfileDropdown = AG:Create("Dropdown")
    CopyFromProfileDropdown:SetLabel(L["Copy From..."])
    CopyFromProfileDropdown:SetRelativeWidth(0.25)
    CopyFromProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) UUF:CreatePrompt(L["Copy Profile"], string.format(L["Are you sure you want to copy from |cFF8080FF%s|r?\nThis will |cFFFF4040overwrite|r your current profile settings."], value), function() UUF.db:CopyProfile(value) UUF:SetUIScale() UUF:UpdateAllUnitFrames() RefreshProfiles() end) end)
    ProfileContainer:AddChild(CopyFromProfileDropdown)

    DeleteProfileDropdown = AG:Create("Dropdown")
    DeleteProfileDropdown:SetLabel(L["Delete..."])
    DeleteProfileDropdown:SetRelativeWidth(0.25)
    DeleteProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) if value ~= UUF.db:GetCurrentProfile() then UUF:CreatePrompt(L["Delete Profile"], string.format(L["Are you sure you want to delete |cFF8080FF%s|r?"], value), function() UUF.db:DeleteProfile(value) UUF:UpdateAllUnitFrames() RefreshProfiles() end) end end)
    ProfileContainer:AddChild(DeleteProfileDropdown)

    ResetProfileButton = AG:Create("Button")
    ResetProfileButton:SetText(string.format(L["Reset |cFF8080FF%s|r Profile"], UUF.db:GetCurrentProfile()))
    ResetProfileButton:SetRelativeWidth(0.25)
    ResetProfileButton:SetCallback("OnClick", function() UUF.db:ResetProfile() UUF:ResolveLSM() UUF:SetUIScale() UUF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(ResetProfileButton)

    local CreateProfileEditBox = AG:Create("EditBox")
    CreateProfileEditBox:SetLabel(L["Profile Name:"])
    CreateProfileEditBox:SetText("")
    CreateProfileEditBox:SetRelativeWidth(0.5)
    CreateProfileEditBox:DisableButton(true)
    CreateProfileEditBox:SetCallback("OnEnterPressed", function() CreateProfileEditBox:ClearFocus() end)
    ProfileContainer:AddChild(CreateProfileEditBox)

    local CreateProfileButton = AG:Create("Button")
    CreateProfileButton:SetText(L["Create Profile"])
    CreateProfileButton:SetRelativeWidth(0.5)
    CreateProfileButton:SetCallback("OnClick", function() local profileName = strtrim(CreateProfileEditBox:GetText() or "") if profileName ~= "" then UUF.db:SetProfile(profileName) UUF:SetUIScale() UUF:UpdateAllUnitFrames() RefreshProfiles() CreateProfileEditBox:SetText("") end end)
    ProfileContainer:AddChild(CreateProfileButton)

    local GlobalProfileHeading = AG:Create("Heading")
    GlobalProfileHeading:SetText(L["Global Profile Settings"])
    GlobalProfileHeading:SetFullWidth(true)
    ProfileContainer:AddChild(GlobalProfileHeading)

    GUIWidgets.CreateInformationTag(ProfileContainer, L["If |cFF8080FFUse Global Profile Settings|r is enabled, the profile selected below will be used as your active profile.\nThis is useful if you want to use the same profile across multiple characters."])

    UseGlobalProfileToggle = AG:Create("CheckBox")
    UseGlobalProfileToggle:SetLabel(L["Use Global Profile Settings"])
    UseGlobalProfileToggle:SetValue(UUF.db.global.UseGlobalProfile)
    UseGlobalProfileToggle:SetRelativeWidth(0.5)
    UseGlobalProfileToggle:SetCallback("OnValueChanged", function(_, _, value) RefreshProfiles() UUF.db.global.UseGlobalProfile = value UUF.db.global.GlobalProfile = (UUF.db.global.GlobalProfile and UUF.db.global.GlobalProfile ~= "" and UUF.db.global.GlobalProfile) or (UUF.db.global.GlobalProfileName and UUF.db.global.GlobalProfileName ~= "" and UUF.db.global.GlobalProfileName) or "Default" if value then UUF.db:SetProfile(UUF.db.global.GlobalProfile) UUF:SetUIScale() end GlobalProfileDropdown:SetDisabled(not value) for _, child in ipairs(ProfileContainer.children) do if child ~= UseGlobalProfileToggle and child ~= GlobalProfileDropdown then GUIWidgets.DeepDisable(child, value) end end UUF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(UseGlobalProfileToggle)

    GlobalProfileDropdown = AG:Create("Dropdown")
    GlobalProfileDropdown:SetLabel(L["Global Profile..."])
    GlobalProfileDropdown:SetRelativeWidth(0.5)
    GlobalProfileDropdown:SetList(profileKeys)
    GlobalProfileDropdown:SetValue((UUF.db.global.GlobalProfile and UUF.db.global.GlobalProfile ~= "" and UUF.db.global.GlobalProfile) or (UUF.db.global.GlobalProfileName and UUF.db.global.GlobalProfileName ~= "" and UUF.db.global.GlobalProfileName) or "Default")
    GlobalProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) UUF.db:SetProfile(value) UUF.db.global.GlobalProfile = value UUF:SetUIScale() UUF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(GlobalProfileDropdown)

    local SpecProfileContainer = GUIWidgets.CreateInlineGroup(ProfileContainer, L["Specialization Profiles"])

    local UseDualSpecializationToggle = AG:Create("CheckBox")
    UseDualSpecializationToggle:SetLabel(L["Enable Specialization Profiles"])
    UseDualSpecializationToggle:SetValue(UUF.db:IsDualSpecEnabled())
    UseDualSpecializationToggle:SetRelativeWidth(1)
    UseDualSpecializationToggle:SetCallback("OnValueChanged", function(_, _, value) UUF.db:SetDualSpecEnabled(value) for i = 1, numSpecs do specProfilesList[i]:SetDisabled(not value) end UUF:UpdateAllUnitFrames() RefreshProfiles() end)
    UseDualSpecializationToggle:SetDisabled(UUF.db.global.UseGlobalProfile)
    SpecProfileContainer:AddChild(UseDualSpecializationToggle)

    for i = 1, numSpecs do
        local _, specName = GetSpecializationInfo(i)
        specProfilesList[i] = AG:Create("Dropdown")
        specProfilesList[i]:SetLabel(string.format("%s", specName or (L["Spec %d"]):format(i)))
        specProfilesList[i]:SetList(profileKeys)
        specProfilesList[i]:SetCallback("OnValueChanged", function(widget, event, value) UUF.db:SetDualSpecProfile(value, i) end)
        specProfilesList[i]:SetRelativeWidth(numSpecs == 2 and 0.5 or numSpecs == 3 and 0.33 or 0.25)
        specProfilesList[i]:SetDisabled(not UUF.db:IsDualSpecEnabled() or UUF.db.global.UseGlobalProfile)
        SpecProfileContainer:AddChild(specProfilesList[i])
    end

    RefreshProfiles()

    local SharingContainer = GUIWidgets.CreateInlineGroup(containerParent, L["Profile Sharing"])

    local ExportingHeading = AG:Create("Heading")
    ExportingHeading:SetText(L["Exporting"])
    ExportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ExportingHeading)

    GUIWidgets.CreateInformationTag(SharingContainer, L["You can export your profile by pressing |cFF8080FFExport Profile|r button below & share the string with other |cFF8080FFUnhalted|r Unit Frame users."])

    local ExportingEditBox = AG:Create("EditBox")
    ExportingEditBox:SetLabel(L["Export String..."])
    ExportingEditBox:SetText("")
    ExportingEditBox:SetRelativeWidth(0.7)
    ExportingEditBox:DisableButton(true)
    ExportingEditBox:SetCallback("OnEnterPressed", function() ExportingEditBox:ClearFocus() end)
    ExportingEditBox:SetCallback("OnTextChanged", function() ExportingEditBox:ClearFocus() end)
    SharingContainer:AddChild(ExportingEditBox)

    local ExportProfileButton = AG:Create("Button")
    ExportProfileButton:SetText(L["Export Profile"])
    ExportProfileButton:SetRelativeWidth(0.3)
    ExportProfileButton:SetCallback("OnClick", function() ExportingEditBox:SetText(UUF:ExportSavedVariables()) ExportingEditBox:HighlightText() ExportingEditBox:SetFocus() end)
    SharingContainer:AddChild(ExportProfileButton)

    local ImportingHeading = AG:Create("Heading")
    ImportingHeading:SetText(L["Importing"])
    ImportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ImportingHeading)

    GUIWidgets.CreateInformationTag(SharingContainer, L["If you have an exported string, paste it in the |cFF8080FFImport String|r box below & press |cFF8080FFImport Profile|r."])

    local ImportingEditBox = AG:Create("EditBox")
    ImportingEditBox:SetLabel(L["Import String..."])
    ImportingEditBox:SetText("")
    ImportingEditBox:SetRelativeWidth(0.7)
    ImportingEditBox:DisableButton(true)
    ImportingEditBox:SetCallback("OnEnterPressed", function() ImportingEditBox:ClearFocus() end)
    ImportingEditBox:SetCallback("OnTextChanged", function() ImportingEditBox:ClearFocus() end)
    SharingContainer:AddChild(ImportingEditBox)

    local ImportProfileButton = AG:Create("Button")
    ImportProfileButton:SetText(L["Import Profile"])
    ImportProfileButton:SetRelativeWidth(0.3)
    ImportProfileButton:SetCallback("OnClick", function() if ImportingEditBox:GetText() ~= "" then UUF:ImportSavedVariables(ImportingEditBox:GetText()) ImportingEditBox:SetText("") end end)
    SharingContainer:AddChild(ImportProfileButton)
    GlobalProfileDropdown:SetDisabled(not UUF.db.global.UseGlobalProfile)
    if UUF.db.global.UseGlobalProfile then for _, child in ipairs(ProfileContainer.children) do if child ~= UseGlobalProfileToggle and child ~= GlobalProfileDropdown then GUIWidgets.DeepDisable(child, true) end end end

    local DefaultsExportHeading = AG:Create("Heading")
    DefaultsExportHeading:SetText(L["Export Profile (Table)"])
    DefaultsExportHeading:SetFullWidth(true)
    SharingContainer:AddChild(DefaultsExportHeading)

    GUIWidgets.CreateInformationTag(SharingContainer, L["Export the active profile as a readable Lua table matching the structure used by |cFF8080FFDefaults.lua|r.\nThis is intended for |cFF8080FFadvanced|r users or |cFF8080FFdevelopers|r."])

    local DefaultsExportEditBox = AG:Create("MultiLineEditBox")
    DefaultsExportEditBox:SetLabel(L["Export Table..."])
    DefaultsExportEditBox:SetText("")
    DefaultsExportEditBox:SetNumLines(14)
    DefaultsExportEditBox:SetFullWidth(true)
    DefaultsExportEditBox:DisableButton(true)
    SharingContainer:AddChild(DefaultsExportEditBox)

    local ExportDefaultsButton = AG:Create("Button")
    ExportDefaultsButton:SetText(L["Export Profile (Table)"])
    ExportDefaultsButton:SetFullWidth(true)
    ExportDefaultsButton:SetCallback("OnClick", function() DefaultsExportEditBox:SetText(UUF:ExportDefaultsTable()) DefaultsExportEditBox:HighlightText() DefaultsExportEditBox:SetFocus() end)
    SharingContainer:AddChild(ExportDefaultsButton)
end

function UUF:CreateGUI()
    if isGUIOpen then return end
    if InCombatLockdown() then return end

    isGUIOpen = true
    reloadRequired = false

    Container = AG:Create("Frame")
    Container:SetTitle(UUF.PRETTY_ADDON_NAME)
    Container:SetLayout("Fill")
    Container:SetWidth(1100)
    Container:SetHeight(600)
    Container:EnableResize(false)
    Container:SetCallback("OnClose", function(widget)
		local shouldReload = reloadRequired
		reloadRequired = false
		AG:Release(widget)
		isGUIOpen = false
		DisableAllTestModes()
		if shouldReload then UUF:CreatePrompt(L["Reload UI"], L["Aura visual settings have changed. Reload the UI now to apply them?"], function() C_UI.Reload() end, nil, L["Reload Now"], L["Later"]) end
	end)

    local function SelectTab(GUIContainer, _, MainTab)
		MainTab = MainTab:match("[^\001]+$")
		if MainTab == "Global" then GUIContainer:SelectByValue("Global\001GlobalToggles") return end
		if MainTab == "Units" then GUIContainer:SelectByValue("Units\001Player") return end
		GUIContainer:ReleaseChildren()
		UUF:ForEachUnitDB(function(_, unit) DisableAurasTestMode(unit) end)

        local Wrapper = AG:Create("SimpleGroup")
        Wrapper:SetFullWidth(true)
        Wrapper:SetFullHeight(true)
        Wrapper:SetLayout("Fill")
        GUIContainer:AddChild(Wrapper)

        if MainTab == "General" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUIScaleSettings(ScrollFrame)
            CreateColourSettings(ScrollFrame)

            local SupportMeContainer = AG:Create("InlineGroup")
            SupportMeContainer:SetTitle(L["|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Emotes\\peepoLove.png:18:18|t  How To Support "] .. UUF.PRETTY_ADDON_NAME .. L[" Development"])
            SupportMeContainer:SetLayout("Flow")
            SupportMeContainer:SetFullWidth(true)
            ScrollFrame:AddChild(SupportMeContainer)

            local TwitchInteractive = AG:Create("InteractiveLabel")
            TwitchInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Twitch.png:25:21|t |cFF8080FFTwitch|r")
            TwitchInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
            TwitchInteractive:SetJustifyV("MIDDLE")
            TwitchInteractive:SetRelativeWidth(0.33)
            TwitchInteractive:SetCallback("OnClick", function() UUF:OpenURL(L["Support Me on Twitch"], "https://www.twitch.tv/unhaltedgb") end)
            TwitchInteractive:SetCallback("OnEnter", function() TwitchInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Twitch.png:25:21|t |cFFFFFFFFTwitch|r") end)
            TwitchInteractive:SetCallback("OnLeave", function() TwitchInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Twitch.png:25:21|t |cFF8080FFTwitch|r") end)
            SupportMeContainer:AddChild(TwitchInteractive)

            local DiscordInteractive = AG:Create("InteractiveLabel")
            DiscordInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Discord.png:21:21|t |cFF8080FFDiscord|r")
            DiscordInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
            DiscordInteractive:SetJustifyV("MIDDLE")
            DiscordInteractive:SetRelativeWidth(0.33)
            DiscordInteractive:SetCallback("OnClick", function() UUF:OpenURL(L["Support Me on Discord"], "https://discord.gg/UZCgWRYvVE") end)
            DiscordInteractive:SetCallback("OnEnter", function() DiscordInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Discord.png:21:21|t |cFFFFFFFFDiscord|r") end)
            DiscordInteractive:SetCallback("OnLeave", function() DiscordInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Discord.png:21:21|t |cFF8080FFDiscord|r") end)
            SupportMeContainer:AddChild(DiscordInteractive)

            local GithubInteractive = AG:Create("InteractiveLabel")
            GithubInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Github.png:21:21|t |cFF8080FFGithub|r")
            GithubInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
            GithubInteractive:SetJustifyV("MIDDLE")
            GithubInteractive:SetRelativeWidth(0.33)
            GithubInteractive:SetCallback("OnClick", function() UUF:OpenURL(L["Support Me on Github"], "https://github.com/dalehuntgb/UnhaltedUnitFrames") end)
            GithubInteractive:SetCallback("OnEnter", function() GithubInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Github.png:21:21|t |cFFFFFFFFGithub|r") end)
            GithubInteractive:SetCallback("OnLeave", function() GithubInteractive:SetText("|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Github.png:21:21|t |cFF8080FFGithub|r") end)
            SupportMeContainer:AddChild(GithubInteractive)

            ScrollFrame:DoLayout()
        elseif MainTab == "GlobalToggles" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateGlobalToggleSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif MainTab == "GlobalFonts" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateFontSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif MainTab == "GlobalTextures" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateTextureSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif MainTab == "GlobalRange" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateRangeSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif MainTab == "GlobalTags" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateGlobalTagSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif MainTab == "CooldownText" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateCooldownTextSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif MainTab == "Player" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "player")

            ScrollFrame:DoLayout()
        elseif MainTab == "Target" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "target")

            ScrollFrame:DoLayout()
        elseif MainTab == "TargetTarget" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "targettarget")

            ScrollFrame:DoLayout()
        elseif MainTab == "Pet" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "pet")

            ScrollFrame:DoLayout()
        elseif MainTab == "Focus" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "focus")

            ScrollFrame:DoLayout()
        elseif MainTab == "FocusTarget" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "focustarget")

            ScrollFrame:DoLayout()
        elseif MainTab == "Party" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "party")

            ScrollFrame:DoLayout()
        elseif MainTab == "Raid" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "raid")

            ScrollFrame:DoLayout()
		elseif MainTab == "Augmentation" and UUF:IsAugmentationEvoker() then
			local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

			CreateUnitSettings(ScrollFrame, "augmentation")

			ScrollFrame:DoLayout()
        elseif MainTab == "Boss" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateUnitSettings(ScrollFrame, "boss")

            ScrollFrame:DoLayout()
        elseif MainTab == "Tags" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)
            CreateTagSettings(ScrollFrame)
            ScrollFrame:DoLayout()
        elseif MainTab == "Profiles" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateProfileSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        end
        if MainTab == "Party" then EnablePartyFramesTestMode() else DisablePartyFramesTestMode() end
        if MainTab == "Raid" then EnableRaidFramesTestMode() else DisableRaidFramesTestMode() end
        if MainTab == "Boss" then EnableBossFramesTestMode() else DisableBossFramesTestMode() end
        GenerateSupportText(Container)
    end

    local mainNavigationTree = BuildMainNavigationTree()
    local mainNavigationValues = {}
    for _, entry in ipairs(mainNavigationTree) do
        mainNavigationValues[entry.value] = true
		for _, child in ipairs(entry.children or {}) do mainNavigationValues[entry.value .. "\001" .. child.value] = true end
    end

    UUFGUI.MainNavigationStatus = UUFGUI.MainNavigationStatus or {}

    local ContainerTreeGroup = AG:Create("TreeGroup")
    ContainerTreeGroup:SetLayout("Fill")
    ContainerTreeGroup:SetFullWidth(true)
    ContainerTreeGroup:SetFullHeight(true)
    ContainerTreeGroup:SetStatusTable(UUFGUI.MainNavigationStatus)
    ContainerTreeGroup:SetTreeWidth(220, false)
    ContainerTreeGroup:SetTree(mainNavigationTree)
    ContainerTreeGroup:SetCallback("OnGroupSelected", SelectTab)
    Container:AddChild(ContainerTreeGroup)
    UUFGUI.MainNavigation = ContainerTreeGroup

    local initialSection = UUFGUI.MainNavigationStatus.selected
    if not initialSection or not mainNavigationValues[initialSection] then
        initialSection = "General"
    end
    ContainerTreeGroup:SelectByValue(initialSection)
end

function UUF:OpenGUIToUnit(unit)
    if InCombatLockdown() then return end
	if unit == "augmentation" and not UUF:IsAugmentationEvoker() then return end
	if not lastSelectedUnitTabs[unit] then lastSelectedUnitTabs[unit] = {} end
	lastSelectedUnitTabs[unit].mainTab = "Frame"
    UUF:CreateGUI()
	if UUFGUI.MainNavigation then UUFGUI.MainNavigation:SelectByValue("Units\001" .. (unit == "augmentation" and "Augmentation" or unit == "targettarget" and "TargetTarget" or unit == "focustarget" and "FocusTarget" or unit:gsub("^%l", string.upper))) end
end

function UUFG:OpenUUFGUI()
    UUF:CreateGUI()
end

function UUFG:CloseUUFGUI()
    if isGUIOpen and Container then
        Container:Hide()
        DisableAllTestModes()
    end
end
