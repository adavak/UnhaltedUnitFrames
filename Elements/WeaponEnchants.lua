local _, UUF = ...

-- Weapon oils / imbues are temporary weapon ENCHANTS, not auras: nothing with
-- a spell ID ever exists in the player's aura stream, so the engine aura
-- containers can never render them. They are rendered as a small strip of
-- buttons leading the player's main buffs container instead: while N enchants
-- are active the container shifts inward by N cells (see Auras.lua) so the
-- strip owns the lead cells, main hand adjacent to the container. No enchants
-- = no shift = byte-identical layout.
--
-- There is deliberately no right-click cancel here: temporary enchants can
-- only be cancelled from the default buff icons in the top-right corner.

local SLOTS = { INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED }

local buttons = {}       -- index -> button
local activeInfos = {}   -- packed active list, main hand first
local activeBySlot = {}  -- slot -> info
local activeCount = 0
local textTicker
local durationFormatter

local function ReadEnchants()
	local n = 0
	for k in pairs(activeBySlot) do activeBySlot[k] = nil end
	for i = 1, #SLOTS do
		local info = C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo
			and C_PaperDollInfo.GetTemporaryEnchantmentInfo(SLOTS[i])
		if info and info.hasExpirationTime then
			n = n + 1
			activeInfos[n] = { slot = SLOTS[i], info = info }
			activeBySlot[SLOTS[i]] = info
		end
	end
	for i = n + 1, #activeInfos do activeInfos[i] = nil end
	activeCount = n
end

-- Raw active-enchant count; Auras.lua shifts the player's main buffs
-- container inward by this many cells. The General toggle gates it; nil
-- (pre-existing profiles) defaults to on.
function UUF:GetWeaponEnchantCount()
	if UUF.db.profile.General.WeaponEnchants == false then return 0 end
	return activeCount
end

local function OnButtonEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetInventoryItem("player", self.slot)
end

local function OnButtonLeave()
	GameTooltip:Hide()
end

local function CreateEnchantButton()
	local b = CreateFrame("Button", nil, UIParent)
	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	b.icon = icon
	local cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawEdge(false)
	cd:SetDrawBling(false)
	cd:SetReverse(true)
	cd:SetHideCountdownNumbers(true)
	b.cd = cd
	-- Duration text rides its own frame ABOVE the cooldown swipe: FontStrings
	-- on the button itself would render under the Cooldown child frame.
	local tf = CreateFrame("Frame", nil, b)
	tf:SetAllPoints()
	tf:SetFrameLevel(cd:GetFrameLevel() + 5)
	b.duration = tf:CreateFontString(nil, "OVERLAY")
	b.charges = tf:CreateFontString(nil, "OVERLAY")
	b:SetScript("OnEnter", OnButtonEnter)
	b:SetScript("OnLeave", OnButtonLeave)
	return b
end

-- Mirrors the aura button look: styled like the container's own buttons so
-- the strip reads as part of the buffs.
local function ApplyButtonStyle(b, size, unitFrame, AuraDB)
	b:SetSize(size, size)
	local FontsDB = UUF.db.profile.General.Fonts
	local flag = FontsDB.FontFlag
	local CooldownTextDB = UUF.db.profile.General.CooldownText
	if CooldownTextDB.Advanced then CooldownTextDB = UUF:GetUnitDB(unitFrame, "player").Auras.AuraDuration end
	local fontSize = CooldownTextDB.FontSize
	if CooldownTextDB.ScaleByIconSize then fontSize = math.max(CooldownTextDB.FontSize * size / 36, 1) end
	local function styleText(fontString, layout)
		fontString:SetFont(UUF.Media.Font, fontSize, flag)
		fontString:ClearAllPoints()
		fontString:SetPoint(layout[1], b, layout[2], layout[3], layout[4])
		if FontsDB.Shadow.Enabled then
			fontString:SetShadowColor(unpack(FontsDB.Shadow.Colour))
			fontString:SetShadowOffset(FontsDB.Shadow.XPos, FontsDB.Shadow.YPos)
		else
			fontString:SetShadowColor(0, 0, 0, 0)
			fontString:SetShadowOffset(0, 0)
		end
	end
	styleText(b.duration, CooldownTextDB.Layout)
	b.charges:SetFont(UUF.Media.Font, AuraDB.Count.FontSize, flag)
	b.charges:ClearAllPoints()
	b.charges:SetPoint(AuraDB.Count.Layout[1], b, AuraDB.Count.Layout[2], AuraDB.Count.Layout[3], AuraDB.Count.Layout[4])
	b.charges:SetTextColor(unpack(AuraDB.Count.Colour))
end

local function PaintContent(b, entry)
	local info = entry.info
	b.icon:SetTexture(GetInventoryItemTexture("player", entry.slot))
	local remaining = (info.remainingTimeMs or 0) / 1000
	b.expire = GetTime() + remaining
	b.cd:SetCooldown(GetTime(), remaining)
	local ch = info.chargesRemaining or 0
	if ch > 1 then
		b.charges:SetText(ch)
		b.charges:Show()
	else
		b.charges:Hide()
	end
	b.slot = entry.slot
end

local function UpdateTexts()
	local now = GetTime()
	local anyShown = false
	for _, b in pairs(buttons) do
		if b:IsShown() then
			anyShown = true
			local remaining = b.expire and (b.expire - now) or 0
			b.duration:SetText(remaining > 0 and durationFormatter:Format(remaining) or "")
		end
	end
	if not anyShown and textTicker then
		textTicker:Cancel()
		textTicker = nil
	end
end

local function EnsureTicker(want)
	if want and not textTicker then
		textTicker = C_Timer.NewTicker(0.5, UpdateTexts)
	elseif not want and textTicker then
		textTicker:Cancel()
		textTicker = nil
	end
end

local function Paint()
	local player = UUF.PLAYER
	local container = player and player.AuraContainers and player.AuraContainers["Container"] or nil
	local AuraDB = container and UUF:GetUnitDB(player, "player").Auras.Containers.Container or nil
	local count = UUF:GetWeaponEnchantCount()
	-- Centered containers never shift, so the strip stays off for them too.
	local shown = container and AuraDB and AuraDB.GrowthDirection ~= "CENTER" and count > 0 or nil
	local anyShown = false
	if shown then
		local anchorParent = AuraDB.AnchorParent == "Health" and player.Health or player
		local size = AuraDB.Size
		local cell = size + AuraDB.Layout[5]
		local sign = AuraDB.GrowthDirection == "LEFT" and -1 or 1
		local strata = UUF:GetUnitDB(player, "player").Auras.FrameStrata
		for i = 1, count do
			local b = buttons[i]
			if not b then
				b = CreateEnchantButton()
				buttons[i] = b
			end
			ApplyButtonStyle(b, size, player, AuraDB)
			b:SetFrameStrata(strata)
			local idx = count - i -- main hand (i=1) adjacent to the container
			b:ClearAllPoints()
			b:SetPoint(AuraDB.Layout[1], anchorParent, AuraDB.Layout[2], AuraDB.Layout[3] + sign * idx * cell, AuraDB.Layout[4])
			PaintContent(b, activeInfos[i])
			b:Show()
			anyShown = true
		end
	end
	for i = 1, #buttons do
		local b = buttons[i]
		if b and (not shown or i > count) then b:Hide() end
	end
	EnsureTicker(anyShown)
	if anyShown then UpdateTexts() end
end

local WeaponEnchantEventFrame = CreateFrame("Frame")
WeaponEnchantEventFrame:RegisterEvent("WEAPON_ENCHANT_CHANGED")
WeaponEnchantEventFrame:RegisterEvent("WEAPON_SLOT_CHANGED")
WeaponEnchantEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WeaponEnchantEventFrame:SetScript("OnEvent", function()
	UUF:UpdateWeaponEnchants()
end)

-- Re-reads enchants, re-seats the player's buffs container so its shift
-- matches the current enchant count, then repacks the strip. Also the GUI
-- toggle's refresh entry point.
function UUF:UpdateWeaponEnchants()
	durationFormatter = UUF:GetCooldownDurationFormatter()
	ReadEnchants()
	if UUF.PLAYER then UUF:UpdateUnitAuras(UUF.PLAYER, "player") end
	Paint()
end