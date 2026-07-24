--[[

****************************************************************************************
LibAboutPanel

File date: 2009-06-23T02:04:30Z
Project version: v1.43

Author: Tekkub, Ackis

****************************************************************************************

]]--

local lib = LibStub:NewAscensionLibrary("LibAboutPanel")
if not lib then return end

function lib.new(parent, addonname)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame.name, frame.parent, frame.addonname = not parent and gsub(addonname," ","") or "About", parent, gsub(addonname," ","") -- Remove spaces from addonname because GetMetadata doesn't like that
	frame:Hide()
	frame:SetScript("OnShow", lib.OnShow)
	InterfaceOptions_AddCategory(frame)
	return frame
end

local GAME_LOCALE = GetLocale()

local L = {}

-- frFR
if GAME_LOCALE == "frFR" then
	L["About"] = "à propos de"
	L["Click to copy to clipboard"] = "Click to copy to clipboard"
-- deDE
elseif GAME_LOCALE == "deDE" then
	L["About"] = "Über"
	L["Click to copy to clipboard"] = "Klicken und Strg-C drücken zum kopieren"
-- esES
elseif GAME_LOCALE == "esES" then
	L["About"] = "Acerca de"
	L["Click to copy to clipboard"] = "Click to copy to clipboard"
-- esMX
elseif GAME_LOCALE == "esMX" then
	L["About"] = "Sobre"
	L["Click to copy to clipboard"] = "Click to copy to clipboard"
-- koKR
elseif GAME_LOCALE == "koKR" then
	L["About"] = "대하여"
	L["Click to copy to clipboard"] = "Click to copy to clipboard"
-- ruRU
elseif GAME_LOCALE == "ruRU" then
	L["About"] = "Об аддоне"
	L["Click to copy to clipboard"] = "Click to copy to clipboard"
-- zhCN
elseif GAME_LOCALE == "zhCN" then
	L["About"] = "关于"
	L["Click to copy to clipboard"] = "点击并 Ctrl-C 复制"
-- zhTW
elseif GAME_LOCALE == "zhTW" then
	L["About"] = "關於"
	L["Click to copy to clipboard"] = "點擊並 Ctrl-C 復制"
-- enUS and non-localized
else
	L["About"] ="About"
	L["Click to copy to clipboard"] = "Click to copy to clipboard"
end

function lib.CopyToClipboard(self)
	Internal_CopyToClipboard(self.val)
	SendSystemMessage(S_COPIED_TO_CLIPBOARD:format(self.field:gsub("X%-", "")))
end


local fields = {"Version", "Author", "X-Category", "X-License", "X-Email", "Email", "eMail", "X-Discord", "X-Github-Repository", "X-Website", "X-Credits", "X-Localizations", "X-Donate"}
local haseditbox = {["X-Discord"] = true, ["X-Github-Repository"] = true, ["X-Website"] = true, ["X-Email"] = true, ["X-Donate"] = true, ["Email"] = true, ["eMail"] = true}

local function HideTooltip() GameTooltip:Hide() end

local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(L["Click to copy to clipboard"])
	--GameTooltip:SetText("Click to copy to clipboard")
end

function lib.OnShow(frame)

	local notefield = "Notes"

	if (GAME_LOCALE ~= "enUS") then
		notefield = notefield .. "-" .. GAME_LOCALE
	end

	-- Get the localized version of notes if it exists or fall back to the english one.
	local notes = GetAddOnMetadata(frame.addonname, notefield) or GetAddOnMetadata(frame.addonname, "Notes")

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(frame.parent and (frame.parent.." - " .. L["About"]) or frame.name)

	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", frame, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(notes)

	local anchor
	for _,field in pairs(fields) do
		local val = GetAddOnMetadata(frame.addonname, field)
		if val then
			local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			title:SetWidth(75)
			if not anchor then title:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -12)
			else title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10) end
			title:SetJustifyH("RIGHT")
			title:SetText(field:gsub("X%-", ""))

			local detail = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			detail:SetHeight(32)
			detail:SetPoint("LEFT", title, "RIGHT", 4, 0)
			detail:SetPoint("RIGHT", frame, -16, 0)
			detail:SetJustifyH("LEFT")

			if (field == "Author") then
				local authorservername = GetAddOnMetadata(frame.addonname, "X-Author-Server")
				local authorfaction = GetAddOnMetadata(frame.addonname, "X-Author-Faction")

				if authorservername and authorfaction then
					detail:SetText((haseditbox[field] and "|cff9999ff" or "").. val .. " on " .. authorservername .. " (" .. authorfaction .. ")")
				elseif authorservername and not authorfaction then
					detail:SetText((haseditbox[field] and "|cff9999ff" or "").. val .. " on " .. authorservername)
				elseif not authorservername and authorfaction then
					detail:SetText((haseditbox[field] and "|cff9999ff" or "").. val .. " (" .. authorfaction .. ")")
				else
					detail:SetText((haseditbox[field] and "|cff9999ff" or "").. val)
				end
			elseif (field == "Version") then
				local addonversion = GetAddOnMetadata(frame.addonname, field)
				-- Remove @project-revision@ and replace it with Repository
				addonversion = string.gsub(addonversion,"@project.revision@","Repository")
				detail:SetText((haseditbox[field] and "|cff9999ff" or "").. addonversion)
			else
				detail:SetText((haseditbox[field] and "|cff9999ff" or "").. val)
			end

			if haseditbox[field] then
				local button = CreateFrame("Button", nil, frame)
				button:SetAllPoints(detail)
				button.val = val
				button.field = field
				button:SetScript("OnClick", lib.CopyToClipboard)
				button:SetScript("OnEnter", ShowTooltip)
				button:SetScript("OnLeave", HideTooltip)
			end

			anchor = title
		end
	end

end
