local _, UUF = ...

local function PositionGameMenuButton()
	if not GameMenuFrame or not GameMenuFrame.UUF then return end
	local height = GameMenuFrame:GetHeight()
	if GameMenuFrame.UUFAdjustedHeight == height then height = height - (GameMenuFrame.UUFAddedHeight or 0) end

	local anchorButton, macroButton, firstExitButton, previousExitButton
	for button in GameMenuFrame.buttonPool:EnumerateActive() do
		local text = button:GetText()
		if text and (text == LOGOUT or text == LOG_OUT or text == EXIT_GAME or text == RETURN_TO_GAME) then
			if not firstExitButton then firstExitButton = button end
			if previousExitButton then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", previousExitButton, "BOTTOMLEFT", 0, -1)
			end
			previousExitButton = button
		else
			if text == MACROS then macroButton = button end
			anchorButton = button
		end
	end
	anchorButton = macroButton or anchorButton
	if anchorButton then
		GameMenuFrame.UUF:ClearAllPoints()
		GameMenuFrame.UUF:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 0, -1)
		GameMenuFrame.UUF:SetText(UUF.ADDON_NAME)
		GameMenuFrame.UUF:Show()
		if firstExitButton then
			firstExitButton:ClearAllPoints()
			firstExitButton:SetPoint("TOPLEFT", GameMenuFrame.UUF, "BOTTOMLEFT", 0, -20)
		end
		GameMenuFrame.UUFAddedHeight = GameMenuFrame.UUF:GetHeight() + 10
		GameMenuFrame.UUFAdjustedHeight = height + GameMenuFrame.UUFAddedHeight
		GameMenuFrame:SetHeight(GameMenuFrame.UUFAdjustedHeight)
	else
		GameMenuFrame.UUFAddedHeight = 0
		GameMenuFrame.UUFAdjustedHeight = nil
		GameMenuFrame.UUF:Hide()
	end
end

local function OpenUUFConfig()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
	UUF:CreateGUI()
end

local function SetupGameMenu()
	if not GameMenuFrame or GameMenuFrame.UUF then return end
	local button = CreateFrame("Button", "UUF_GameMenuButton", GameMenuFrame, "MainMenuFrameButtonTemplate")
	button:SetSize(200, 35)
	button:SetScript("OnClick", OpenUUFConfig)
	GameMenuFrame.UUF = button
	hooksecurefunc(GameMenuFrame, "Layout", PositionGameMenuButton)
end

SetupGameMenu()

if not GameMenuFrame or not GameMenuFrame.UUF then
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("ADDON_LOADED")
	eventFrame:SetScript("OnEvent", function(self, _, addonName)
		if addonName ~= "Blizzard_GameMenu" then return end
		SetupGameMenu()
		if GameMenuFrame and GameMenuFrame.UUF then self:UnregisterAllEvents() end
	end)
end
