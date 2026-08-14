local _, UUF = ...
local L = LibStub("AceLocale-3.0"):GetLocale("UnhaltedUnitFrames")

function UUF:CreatePositionController()
    local useCDMAnchor = UUF.db.profile.Units.player.HealthBar.AnchorToCooldownViewer or UUF.db.profile.Units.target.HealthBar.AnchorToCooldownViewer
    if not useCDMAnchor then return end

    local ECDM = ""

    if C_AddOns.IsAddOnLoaded("SkironCooldownManager") then
        ECDM = _G["SCM_GroupAnchor_1"]
	elseif C_AddOns.IsAddOnLoaded("Coolinator") then
		ECDM = _G["CoolinatorPrimaryGroupAnchor"]
    else
        ECDM = _G["EssentialCooldownViewer"]
    end

    if ECDM and ECDM:IsShown() then
        local CDMAnchor = CreateFrame("Frame", "UUF_CDMAnchor", UIParent)
        CDMAnchor:SetAllPoints(ECDM)
        CDMAnchor:SetSize(ECDM:GetWidth() or 300, ECDM:GetHeight() or 48)
    else
        UUF:PrettyPrint(string.format(L["%s was not found."], "|cFF8080FF" .. L["Anchor Point"] .. "|r"))
    end
end