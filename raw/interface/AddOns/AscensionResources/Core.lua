if C_Player:IsDefaultClass() then return end
local AddonName = ...
local Addon = LibStub("AceAddon-3.0"):NewAddon("AscensionCustomResources")
Addon.Name = AddonName
Addon.Config = LibStub("AceConfig-3.0")
Addon.Config.Dialog = LibStub("AceConfigDialog-3.0")
Addon.Media = LibStub("LibSharedMedia-3.0")

AscensionCustomResources = Addon

Addon.TexPath = "Interface\\AddOns\\AscensionResources\\textures\\"

local RUNE_COLORS = {
	[1] = { 1, 0, 0 }, -- Blood
	[2] = { 0, 0.5, 0 }, -- Unholy
	[3] = { 0.1, 0.7, 1 }, -- Frost
	[4] = { 0.9, 0.1, 1 }, -- Death
}

--
-- Options
--
local function SetOption(info, ...)
	if select("#", ...) > 1 then
		Addon.db.profile[info[#info]] = { ... }
	else
		Addon.db.profile[info[#info]] = ...
	end
	Addon.Frame:Update()
end

local function GetOption(info)
	local value = Addon.db.profile[info[#info]]
	if type(value) == "table" then
		return unpack(value)
	else
		return value
	end
end

-- Options Table
local options = {
	name = "Energy / Rage Bar",
	desc = "Configuration for Ascension's movable energy / rage bar.",
	descStyle = "inline",
	childGroups = "tab",
	type = "group",
	args = {
		settings = {
			order = 0,
			name = "Settings",
			type = "group",
			childGroups = "tab",
			args = {
				show = {
					name = "Show",
					desc = "Show the movable resource bar",
					type = "toggle",
					default = true,
				},
				locked = {
					name = "Locked",
					desc = "Locks the frame in place",
					type = "toggle",
					default = false,
				},
				width = {
					name = "Width",
					desc = "Width of the frame",
					type = "range",
					min = 50,
					softMax = 400,
					step = 1,
					default = 150,
				},
				showEnergy = {
					name = "Show Energy Bar",
					desc = "Show the Energy bar",
					type = "toggle",
					default = true,
				},
				showRage = {
					name = "Show Rage Bar",
					desc = "Show the Rage bar",
					type = "toggle",
					default = true,
				},
				showMana = {
					name = "Show Mana Bar",
					desc = "Show the mana bar",
					type = "toggle",
					default = false,
				},
				updateInterval = {
					name = "Update Interval",
					desc = "How quickly bars will update\nLower values could cause UI stuttering",
					type = "range",
					min = 0.05,
					max = 1,
					step = 0.01,
					default = 0.2,
				},
				orientation = {
					name = "Orientation",
					desc = "Orientation of the bars",
					type = "select",
					values = {
						["HORIZONTAL"] = "Horizontal",
						["VERTICAL"] = "Vertical",
					},
					default = "VERTICAL",
				},
				textSettings = {
					order = 0,
					name = "Text Settings",
					type = "group",
					args = {
						showText = {
							name = "Show Text",
							desc = "Show current energy and rage text",
							type = "toggle",
							default = true,
						},
						font = {
							name = "Text Font",
							desc = "The font to use",
							type = "select",
							values = Addon.Media:HashTable("font"),
							dialogControl = "LSM30_Font",
							default = "Friz Quadrata TT",
						},
						outline = {
							name = "Text Outline",
							desc = "Outlines the text",
							type = "toggle",
							default = true,
						},
						fontSize = {
							name = "Text Size",
							desc = "Size of the text",
							type = "range",
							softMin = 8,
							softMax = 22,
							step = 1,
							default = 12,
						},
					}
				},
				energy = {
					order = 1,
					name = "Energy",
					type = "group",
					hidden = function() return not Addon.Frame.EnergyBar:IsVisible() end,
					args = {
						energyOrder = {
							order = 0,
							name = "Order",
							desc = "Order the energy bar appears in the frame",
							type = "range",
							min = 1,
							max = 4,
							step = 1,
							default = 1,
						},
						energyColor = {
							name = "Bar Color",
							desc = "Color of the energy bar",
							type = "color",
							default = { 1, 1, 0 }
						},
						energyHeight = {
							name = "Bar Height",
							desc = "Height of the energy bar",
							type = "range",
							softMin = 1,
							softMax = 100,
							step = 1,
							default = 20,
						},
						energyTexture = {
							name = "Bar Texture",
							desc = "Texture for the energy bar",
							type = "select",
							values = Addon.Media:HashTable("statusbar"),
							dialogControl = "LSM30_Statusbar",
							default = "Solid"
						},
						energyShowOutline = {
							name = "Show Outline",
							desc = "Show an outline on the bar",
							type = "toggle",
							default = false,
						},
						energyOutlineThickness = {
							name = "Outline Thickness",
							desc = "Thickness of the outline",
							type = "range",
							min = 1,
							max = 8,
							step = 1,
							default = 1,
						},
						energyTextSettings = {
							order = -1,
							type = "group",
							name = "Text Settings",
							inline = true,
							args = {
								energyShowCurrent = {
									name = "Show Current",
									desc = "Show current energy",
									type = "toggle",
									default = true,
								},
								energyShowTotal = {
									name = "Show Total",
									desc = "Show total energy",
									type = "toggle",
									default = true,
								},
								energyShowPercent = {
									name = "Show Percent",
									desc = "Show energy percent",
									type = "toggle",
									default = false,
								},
								energyTextColor = {
									name = "Text Color",
									desc = "Color of the energy text",
									type = "color",
									default = { 1, 1, 1 }
								},
							},
						},
					}
				},
				rage = {
					order = 2,
					name = "Rage",
					type = "group",
					hidden = function() return not Addon.Frame.RageBar:IsVisible() end,
					args = {
						rageOrder = {
							order = 0,
							name = "Order",
							desc = "Order the rage bar appears in the frame",
							type = "range",
							min = 1,
							max = 4,
							step = 1,
							default = 2,
						},
						rageColor = {
							name = "Bar Color",
							desc = "Color of the rage bar",
							type = "color",
							default = { 1, 0, 0 }
						},
						rageHeight = {
							name = "Bar Height",
							desc = "Height of the rage bar",
							type = "range",
							softMin = 1,
							softMax = 100,
							step = 1,
							default = 20,
						},
						rageTexture = {
							name = "Bar Texture",
							desc = "Texture for the rage bar",
							type = "select",
							values = Addon.Media:HashTable("statusbar"),
							dialogControl = "LSM30_Statusbar",
							default = "Solid"
						},
						rageShowOutline = {
							name = "Show Outline",
							desc = "Show an outline on the bar",
							type = "toggle",
							default = false,
						},
						rageOutlineThickness = {
							name = "Outline Thickness",
							desc = "Thickness of the outline",
							type = "range",
							min = 1,
							max = 8,
							step = 1,
							default = 1,
						},
						rageTextSettings = {
							order = -1,
							type = "group",
							name = "Text Settings",
							inline = true,
							args = {
								rageShowCurrent = {
									order = 4,
									name = "Show Current",
									desc = "Show current rage",
									type = "toggle",
									default = true,
								},
								rageShowTotal = {
									order = 5,
									name = "Show Total",
									desc = "Show total rage",
									type = "toggle",
									default = true,
								},
								rageShowPercent = {
									order = 6,
									name = "Show Percent",
									desc = "Show rage percent",
									type = "toggle",
									default = false,
								},
								rageTextColor = {
									order = 7,
									name = "Text Color",
									desc = "Color of the rage text",
									type = "color",
									default = { 1, 1, 1 }
								},
							}
						},
					}
				},
				mana = {
					order = 3,
					name = "Mana",
					type = "group",
					hidden = function() return not Addon.Frame.ManaBar:IsVisible() end,
					args = {
						manaOrder = {
							order = 0,
							name = "Order",
							desc = "Order the mana bar appears in the frame",
							type = "range",
							min = 1,
							max = 4,
							step = 1,
							default = 3,
						},
						manaColor = {
							name = "Bar Color",
							desc = "Color of the mana bar",
							type = "color",
							default = { 0, 0, 1 }
						},
						manaHeight = {
							name = "Bar Height",
							desc = "Height of the mana bar",
							type = "range",
							softMin = 1,
							softMax = 100,
							step = 1,
							default = 20,
						},
						manaTexture = {
							name = "Bar Texture",
							desc = "Texture for the mana bar",
							type = "select",
							values = Addon.Media:HashTable("statusbar"),
							dialogControl = "LSM30_Statusbar",
							default = "Solid"
						},
						manaShowOutline = {
							name = "Show Outline",
							desc = "Show an outline on the bar",
							type = "toggle",
							default = false,
						},
						manaOutlineThickness = {
							name = "Outline Thickness",
							desc = "Thickness of the outline",
							type = "range",
							min = 1,
							max = 8,
							step = 1,
							default = 1,
						},
						manaTextSettings = {
							order = -1,
							type = "group",
							name = "Text Settings",
							inline = true,
							args = {
								manaShowCurrent = {
									order = 4,
									name = "Show Current",
									desc = "Show current mana",
									type = "toggle",
									default = true,
								},
								manaShowTotal = {
									order = 5,
									name = "Show Total",
									desc = "Show total mana",
									type = "toggle",
									default = true,
								},
								manaShowPercent = {
									order = 6,
									name = "Show Percent",
									desc = "Show mana percent",
									type = "toggle",
									default = false,
								},
								manaTextColor = {
									order = 7,
									name = "Text Color",
									desc = "Color of the mana text",
									type = "color",
									default = { 1, 1, 1 }
								},
							}
						},
					}
				},
				runes = {
					order = 4,
					name = "Runes",
					type = "group",
					hidden = function() return not Addon.Frame.RuneBar:IsVisible() end,
					args = {
						runeOrder = {
							order = 0,
							name = "Order",
							desc = "Order the rune bar appears in the frame",
							type = "range",
							min = 1,
							max = 4,
							step = 1,
							default = 4,
						},
						bloodRuneColor = {
							name = "Blood Rune Color",
							desc = "Color of Blood Runes",
							type = "color",
							default = RUNE_COLORS[1],
						},
						frostRuneColor = {
							name = "Frost Rune Color",
							desc = "Color of Frost Runes",
							type = "color",
							default = RUNE_COLORS[3],
						},
						unholyRuneColor = {
							name = "Unholy Rune Color",
							desc = "Color of Unholy Runes",
							type = "color",
							default = RUNE_COLORS[2],
						},
						deathRuneColor = {
							name = "Death Rune Color",
							desc = "Color of Death Runes",
							type = "color",
							default = RUNE_COLORS[4],
						},
						runeHeight = {
							name = "Bar Height",
							desc = "Height of the rune bar",
							type = "range",
							softMin = 1,
							softMax = 100,
							step = 1,
							default = 20,
						},
						runeBorder = {
							name = "Border",
							desc = "Show a border around rune bars",
							type = "toggle",
							default = true,
						},
						runeTexture = {
							name = "Bar Texture",
							desc = "Texture for each rune bar",
							type = "select",
							values = Addon.Media:HashTable("statusbar"),
							dialogControl = "LSM30_Statusbar",
							default = "Solid"
						},
						runeTextSettings = {
							order = -1,
							name = "Text Settings",
							type = "group",
							inline = true,
							args = {
								runeShowCooldown = {
									name = "Show Cooldown Text",
									desc = "Show a text overlay for rune cooldowns",
									type = "toggle",
									default = true,
								},
								runeShowDecimal = {
									name = "Show Percise Cooldown Text",
									desc = "Add a decimal point to the cooldown.\nDisplays as 0.0 instead of 0",
									type = "toggle",
									default = true,
								},
								runeTextColor = {
									name = "Cooldown Text Color",
									desc = "Color of the cooldown text",
									type = "color",
									default = { 1, 1, 0 }
								},
								runeTextSize = {
									name = "Cooldown Text Size",
									desc = "Size of cooldown text",
									type = "range",
									softMin = 4,
									softMax = 22,
									step = 1,
									default = 10,
								},
								runeTextOutline = {
									name = "Cooldown Text Outline",
									desc = "Show outline on cooldown text",
									type = "toggle",
									default = true,
								}
							}
						},
					},
				}
			},
			set = SetOption,
			get = GetOption,
		},
	},
}

-- Defaults
local defaults = {
	profile = {}
}

function Addon:BuildDefaults(args)
	for k, v in pairs(args) do
		if v.args then
			Addon:BuildDefaults(v.args)
		else
			defaults.profile[k] = v.default
			v.default = nil
		end
	end
end

Addon:BuildDefaults(options.args.settings.args)
Addon.Config:RegisterOptionsTable(Addon.Name, options)
--
-- Ace Functions
--
function Addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("AscensionResourcesDB", defaults, true)
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	options.args.profiles.order = -1

	-- register db callbacks
	self.db.RegisterCallback(self, "OnProfileChanged", function()
		self.Frame:Update()
	end)
	-- OnProfileChanged isn't called when resetting.
	self.db.RegisterCallback(self, "OnProfileReset", function()
		SendSystemMessage("Reset Ascension Resources Profile")
		self.Frame:Update()
	end)

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(Addon.Name, "Ascension Resources")
	self.Frame:Update()
end

--
-- Setup Frames
--
local F = CreateFrame("Button", "AscensionResourcesCustom", UIParent)
Addon.Frame = F

F:SetPoint("TOPLEFT", 205, -45)
F:SetFrameStrata("MEDIUM")
F:SetSize(100, 60)

F:SetClampedToScreen(true)
F:SetMovable(true)
F:EnableMouse(true)
F:RegisterForClicks("AnyUp")
F:RegisterForDrag("LeftButton")
F:SetScript("OnDragStart", F.StartMoving)
F:SetScript("OnHide", F.StopMovingOrSizing)
F:SetScript("OnDragStop", F.StopMovingOrSizing)
F:Show()

F.BG = F:CreateTexture()
F.BG:SetAllPoints()
F.BG:SetTexture(0.1, 0.1, 0.1, 1)

F.MissingText = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
F.MissingText:SetPoint("CENTER")
F.MissingText:SetText("No Bars Active!\nRight Click to Configure")
F.MissingText:Hide()

local function UpdateBar(self)
	local cur = UnitPower("player", self:GetID())
	local max = UnitPowerMax("player", self:GetID())
	local percent = cur / max * 100

	if cur == max then
		percent = 100
	end

	self:SetValue(percent)

	local display = nil
	if self.ShowCurrent then
		display = cur
		if self.ShowTotal then
			display = display .. "/" .. max
		end
	elseif self.ShowTotal then
		display = max
	end

	if self.ShowPercent then
		percent = format("%.0f%%", percent)
		if display then
			display = display .. " - " .. percent
		else
			display = percent
		end
	end

	if display then
		self.Text:SetText(display)
	end
end

-- Energy Bar
do
	local bar = CreateFrame("StatusBar", F:GetName().."EnergyBar", F)
	F.EnergyBar = bar
	bar:SetID(3)
	bar:SetSize(F:GetWidth(), 20)
	bar:SetPoint("TOPLEFT")
	bar:SetMinMaxValues(0, 100)
	bar:SetStatusBarTexture(Addon.TexPath.."normTex")
	bar:SetStatusBarColor(1, 1, 0)
	bar.ShowCurrent = true
	bar.ShowTotal = true
	bar.ShowPercent = false
	bar.time = 0

	local text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.Text = text
	text:SetPoint("CENTER", bar, "CENTER", 0, -1)
	text:SetText("0/100")

	local outline = CreateFrame("Frame", bar:GetName().."Outline", bar)
	outline:SetAllPoints()
	outline.Left = outline:CreateTexture("$parentLeft", "OVERLAY")
	outline.Left:SetPoint("TOPLEFT")
	outline.Left:SetPoint("BOTTOMLEFT")
	outline.Left:SetSize(1, 1)
	outline.Left:SetTexture(0, 0, 0, 1)

	outline.Right = outline:CreateTexture("$parentRight", "OVERLAY")
	outline.Right:SetPoint("TOPRIGHT")
	outline.Right:SetPoint("BOTTOMRIGHT")
	outline.Right:SetSize(1, 1)
	outline.Right:SetTexture(0, 0, 0, 1)

	outline.Top = outline:CreateTexture("$parentTop", "OVERLAY")
	outline.Top:SetPoint("TOPLEFT")
	outline.Top:SetPoint("TOPRIGHT")
	outline.Top:SetSize(1, 1)
	outline.Top:SetTexture(0, 0, 0, 1)

	outline.Bottom = outline:CreateTexture("$parentBottom", "OVERLAY")
	outline.Bottom:SetPoint("BOTTOMLEFT")
	outline.Bottom:SetPoint("BOTTOMRIGHT")
	outline.Bottom:SetSize(1, 1)
	outline.Bottom:SetTexture(0, 0, 0, 1)

	outline.SetThickness = function(self, thickness)
		self.Left:SetSize(thickness, 1)
		self.Right:SetSize(thickness, 1)
		self.Top:SetSize(1, thickness)
		self.Bottom:SetSize(1, thickness)
	end

	bar.Outline = outline

	outline:Hide()

	bar.Update = UpdateBar

	bar:RegisterEvent("UNIT_ENERGY")
	bar:RegisterEvent("PLAYER_ENTERING_WORLD")

	function bar:UNIT_ENERGY(unit)
		if unit ~= "player" then return end
		self:Update()
	end

	function bar:PLAYER_ENTERING_WORLD()
		self:Update()
	end

	bar:SetScript("OnEvent", function(self, event, ...)
		if self[event] then
			self[event](self, ...)
		end
	end)

	bar:SetScript("OnUpdate", function(self, dt)
		if not Addon.db then return end
		self.time = self.time + dt
		if self.time > Addon.db.profile.updateInterval then
			self.time = 0
			self:Update()
		end
	end)
end

-- Rage Bar
do
	local bar = CreateFrame("StatusBar", F:GetName().."RageBar", F)
	F.RageBar = bar
	bar:SetID(1)
	bar:SetSize(F:GetWidth(), 20)
	bar:SetPoint("TOPLEFT", F.EnergyBar, "BOTTOMLEFT")
	bar:SetStatusBarTexture(Addon.TexPath.."normTex")
	bar:SetStatusBarColor(1, 0, 0)
	bar:SetMinMaxValues(0, 100)
	bar.ShowCurrent = true
	bar.ShowTotal = true
	bar.ShowPercent = false
	bar.time = 0

	local text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.Text = text
	text:SetPoint("CENTER", bar, "CENTER", 0, -1)

	local outline = CreateFrame("Frame", bar:GetName().."Outline", bar)
	outline:SetAllPoints()
	outline.Left = outline:CreateTexture("$parentLeft", "OVERLAY")
	outline.Left:SetPoint("TOPLEFT")
	outline.Left:SetPoint("BOTTOMLEFT")
	outline.Left:SetSize(1, 1)
	outline.Left:SetTexture(0, 0, 0, 1)

	outline.Right = outline:CreateTexture("$parentRight", "OVERLAY")
	outline.Right:SetPoint("TOPRIGHT")
	outline.Right:SetPoint("BOTTOMRIGHT")
	outline.Right:SetSize(1, 1)
	outline.Right:SetTexture(0, 0, 0, 1)

	outline.Top = outline:CreateTexture("$parentTop", "OVERLAY")
	outline.Top:SetPoint("TOPLEFT")
	outline.Top:SetPoint("TOPRIGHT")
	outline.Top:SetSize(1, 1)
	outline.Top:SetTexture(0, 0, 0, 1)

	outline.Bottom = outline:CreateTexture("$parentBottom", "OVERLAY")
	outline.Bottom:SetPoint("BOTTOMLEFT")
	outline.Bottom:SetPoint("BOTTOMRIGHT")
	outline.Bottom:SetSize(1, 1)
	outline.Bottom:SetTexture(0, 0, 0, 1)

	outline.SetThickness = function(self, thickness)
		self.Left:SetSize(thickness, 1)
		self.Right:SetSize(thickness, 1)
		self.Top:SetSize(1, thickness)
		self.Bottom:SetSize(1, thickness)
	end

	bar.Outline = outline

	outline:Hide()

	bar.Update = UpdateBar

	bar:RegisterEvent("UNIT_RAGE")
	bar:RegisterEvent("PLAYER_ENTERING_WORLD")

	function bar:UNIT_RAGE(unit)
		if unit ~= "player" then return end
		self:Update()
	end

	function bar:PLAYER_ENTERING_WORLD()
		self:Update()
	end

	bar:SetScript("OnEvent", function(self, event, ...)
		if self[event] then
			self[event](self, ...)
		end
	end)

	bar:SetScript("OnUpdate", function(self, dt)
		if not Addon.db then return end
		self.time = self.time + dt
		if self.time > Addon.db.profile.updateInterval then
			self.time = 0
			self:Update()
		end
	end)
end

-- Mana Bar (Optional)
do
	local bar = CreateFrame("StatusBar", F:GetName().."ManaBar", F)
	F.ManaBar = bar
	bar:SetID(0)
	bar:SetSize(F:GetWidth(), 20)
	bar:SetPoint("TOPLEFT", F.RageBar, "BOTTOMLEFT")
	bar:SetStatusBarTexture(Addon.TexPath.."normTex")
	bar:SetStatusBarColor(0, 0, 1)
	bar:SetMinMaxValues(0, 100)
	bar.ShowCurrent = true
	bar.ShowTotal = true
	bar.ShowPercent = false
	bar.time = 0

	bar:Hide()

	local text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.Text = text
	text:SetPoint("CENTER", bar, "CENTER", 0, -1)

	local outline = CreateFrame("Frame", bar:GetName().."Outline", bar)
	outline:SetAllPoints()
	outline.Left = outline:CreateTexture("$parentLeft", "OVERLAY")
	outline.Left:SetPoint("TOPLEFT")
	outline.Left:SetPoint("BOTTOMLEFT")
	outline.Left:SetSize(1, 1)
	outline.Left:SetTexture(0, 0, 0, 1)

	outline.Right = outline:CreateTexture("$parentRight", "OVERLAY")
	outline.Right:SetPoint("TOPRIGHT")
	outline.Right:SetPoint("BOTTOMRIGHT")
	outline.Right:SetSize(1, 1)
	outline.Right:SetTexture(0, 0, 0, 1)

	outline.Top = outline:CreateTexture("$parentTop", "OVERLAY")
	outline.Top:SetPoint("TOPLEFT")
	outline.Top:SetPoint("TOPRIGHT")
	outline.Top:SetSize(1, 1)
	outline.Top:SetTexture(0, 0, 0, 1)

	outline.Bottom = outline:CreateTexture("$parentBottom", "OVERLAY")
	outline.Bottom:SetPoint("BOTTOMLEFT")
	outline.Bottom:SetPoint("BOTTOMRIGHT")
	outline.Bottom:SetSize(1, 1)
	outline.Bottom:SetTexture(0, 0, 0, 1)

	outline.SetThickness = function(self, thickness)
		self.Left:SetSize(thickness, 1)
		self.Right:SetSize(thickness, 1)
		self.Top:SetSize(1, thickness)
		self.Bottom:SetSize(1, thickness)
	end

	bar.Outline = outline

	outline:Hide()

	bar.Update = UpdateBar

	bar:RegisterEvent("UNIT_MANA")
	bar:RegisterEvent("PLAYER_ENTERING_WORLD")

	function bar:UNIT_MANA(unit)
		if unit ~= "player" then return end
		self:Update()
	end

	function bar:PLAYER_ENTERING_WORLD()
		self:Update()
	end

	bar:SetScript("OnEvent", function(self, event, ...)
		if self[event] then
			self[event](self, ...)
		end
	end)

	bar:SetScript("OnUpdate", function(self, dt)
		if not Addon.db then return end
		self.time = self.time + dt
		if self.time > Addon.db.profile.updateInterval then
			self.time = 0
			self:Update()
		end
	end)
end

-- Rune Bar
do
	local bar = CreateFrame("Frame", F:GetName().."RuneBar", F)
	F.RuneBar = bar
	bar:SetSize(F:GetWidth(), 20)
	bar:SetPoint("TOPLEFT", F.RageBar, "BOTTOMLEFT")
	bar:Hide()

	bar.Runes = {}

	for i = 1, 6 do
		local rune = CreateFrame("StatusBar", bar:GetName().."Rune"..i, bar)
		tinsert(bar.Runes, rune)

		rune:SetSize(bar:GetWidth() / 6, 20)
		if i == 1 then
			rune:SetPoint("TOPLEFT")
		else
			rune:SetPoint("TOPLEFT", bar.Runes[#bar.Runes - 1], "TOPRIGHT")
		end
		rune:SetStatusBarTexture(Addon.TexPath.."normTex")
		rune.type = GetRuneType(i)
		if rune.type then
			rune:SetStatusBarColor(unpack(RUNE_COLORS[rune.type]))
		end
		rune:SetOrientation("vertical")
		rune:SetMinMaxValues(0, 100)
		rune:SetValue(100)
		rune:SetID(i)

		rune:SetScript("OnShow", function(self) self:UpdateCooldown() end)

		local text = rune:CreateFontString(nil, "ARTWORK", "TextStatusBarText")
		rune.Text = text
		text:SetPoint("CENTER", 0, -1)
		text:SetVertexColor(1, 1, 0, 1)
		text:SetText("")

		function rune:UpdateSettings()
			local db = Addon.db.profile
			if rune.type == 1 then
				self:SetStatusBarColor(unpack(db.bloodRuneColor))
			elseif rune.type == 2 then
				self:SetStatusBarColor(unpack(db.unholyRuneColor))
			elseif rune.type == 3 then
				self:SetStatusBarColor(unpack(db.frostRuneColor))
			elseif rune.type == 4 then
				self:SetStatusBarColor(unpack(db.deathRuneColor))
			else
				self:SetStatusBarColor(unpack(db.bloodRuneColor))
			end

			self:SetStatusBarTexture(Addon.Media:Fetch("statusbar", db.runeTexture))

			self:SetSize(self:GetParent():GetWidth() / 6, db.runeHeight)

			self:SetValue(self:GetValue() + 1)
			self:SetValue(self:GetValue() - 1)

			if db.runeBorder then
				self.Border:Show()
			else
				self.Border:Hide()
			end

			if db.runeShowCooldown then
				self.Text:Show()
			else
				self.Text:Hide()
			end

			self.Text:SetVertexColor(unpack(db.runeTextColor))
			local outline = db.runeTextOutline and "OUTLINE" or nil
			self.Text:SetFont(Addon.Media:Fetch("font", db.font), db.runeTextSize, outline)
		end

		function rune:Update(dt)
			self.time = self.time + dt
			local percent = self.time / self.duration * 100
			if Addon.db.profile.runeShowDecimal then
				text:SetText(format("%.1f", self.duration - self.time))
			else
				text:SetText(format("%d", self.duration - self.time))
			end

			if percent > 100 then
				percent = 100
				text:SetText("")
				self:SetScript("OnUpdate", nil)
			end

			rune:SetValue(percent)
		end

		function rune:UpdateCooldown()
			local start, duration, ready = GetRuneCooldown(self:GetID())
			if not start or not duration then
				self.Text:SetText("")
				self:SetValue(100)
				self:SetScript("OnUpdate", nil)
				return
			end

			ready = GetTime() - start >= duration
			if not ready then
				if not self:GetScript("OnUpdate") then
					self.time = GetTime() - start
					self.duration = duration
					self:SetScript("OnUpdate", rune.Update)
				end
			else
				self.Text:SetText("")
				self:SetValue(100)
				self:SetScript("OnUpdate", nil)
			end
		end

		local border = CreateFrame("Frame", nil, rune)
		rune.Border = border
		border:SetAllPoints()

		border.backdrop = {
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tileEdge = false,
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		}
		border:SetBackdrop(border.backdrop)
		border:SetBackdropBorderColor(0, 0, 0, 1)
	end

	function bar:ShowIfNeeded()
		self:SetShown(C_Spell.HasRuneUI())
	end

	function bar:UpdateRunes()
		for _, rune in ipairs(self.Runes) do
			local runeType = GetRuneType(rune:GetID())
			rune.type = runeType
			rune:UpdateSettings()
		end
	end

	bar:RegisterEvent("RUNE_POWER_UPDATE")
	bar:RegisterEvent("RUNE_TYPE_UPDATE")
	bar:RegisterEvent("PLAYER_ENTERING_WORLD")
	bar:RegisterEvent("ASCENSION_SPELLS_UPDATED")

	function bar:RUNE_POWER_UPDATE(rune, usable)
		if rune then
			self.Runes[rune]:UpdateCooldown()
		end
	end

	function bar:RUNE_TYPE_UPDATE(rune)
		self:UpdateRunes()
	end

	function bar:ASCENSION_SPELLS_UPDATED()
		F:Update()
	end

	bar:SetScript("OnEvent", function(self, event, ...)
		if self[event] then
			self[event](self, ...)
		end
	end)
end

--
-- Functions
--
function F:Update()
	local db = Addon.db.profile
	
	self:SetShown(db.show)

	if db.locked then
		F:RegisterForDrag()
	else
		F:RegisterForDrag("LeftButton")
	end

	-- Energy
	F.EnergyBar:SetStatusBarColor(unpack(db.energyColor))
	F.EnergyBar:SetStatusBarTexture(Addon.Media:Fetch("statusbar", db.energyTexture))
	F.EnergyBar.ShowCurrent = db.energyShowCurrent
	F.EnergyBar.ShowTotal = db.energyShowTotal
	F.EnergyBar.ShowPercent = db.energyShowPercent
	F.EnergyBar.Order = db.energyOrder

	-- have to +1 -1 this value so it updates the bar cant find how to 'force update' otherwise
	F.EnergyBar:SetValue(F.EnergyBar:GetValue() + 1)
	F.EnergyBar:SetValue(F.EnergyBar:GetValue() - 1)

	F.EnergyBar.Outline:SetShown(db.energyShowOutline)
	F.EnergyBar.Outline:SetThickness(db.energyOutlineThickness)

	-- Rage
	F.RageBar:SetStatusBarColor(unpack(db.rageColor))
	F.RageBar:SetStatusBarTexture(Addon.Media:Fetch("statusbar", db.rageTexture))
	F.RageBar.ShowCurrent = db.rageShowCurrent
	F.RageBar.ShowTotal = db.rageShowTotal
	F.RageBar.ShowPercent = db.rageShowPercent
	F.RageBar.Order = db.rageOrder

	F.RageBar:SetValue(F.RageBar:GetValue() + 1)
	F.RageBar:SetValue(F.RageBar:GetValue() - 1)

	F.RageBar.Outline:SetShown(db.rageShowOutline)
	F.RageBar.Outline:SetThickness(db.rageOutlineThickness)

	-- Mana
	F.ManaBar:SetStatusBarColor(unpack(db.manaColor))
	F.ManaBar:SetStatusBarTexture(Addon.Media:Fetch("statusbar", db.manaTexture))
	F.ManaBar.ShowCurrent = db.manaShowCurrent
	F.ManaBar.ShowTotal = db.manaShowTotal
	F.ManaBar.ShowPercent = db.manaShowPercent
	F.ManaBar.Order = db.manaOrder

	F.ManaBar:SetValue(F.ManaBar:GetValue() + 1)
	F.ManaBar:SetValue(F.ManaBar:GetValue() - 1)

	F.ManaBar.Outline:SetShown(db.manaShowOutline)
	F.ManaBar.Outline:SetThickness(db.manaOutlineThickness)

	-- Runes
	F.RuneBar:ShowIfNeeded()
	F.RuneBar:SetSize(F:GetWidth(), db.runeHeight)
	F.RuneBar:UpdateRunes()
	F.RuneBar.Order = db.runeOrder

	-- Text
	local outline = db.outline and "OUTLINE" or nil
	F.EnergyBar.Text:SetFont(Addon.Media:Fetch("font", db.font), db.fontSize, outline)
	F.ManaBar.Text:SetFont(Addon.Media:Fetch("font", db.font), db.fontSize, outline)
	F.RageBar.Text:SetFont(Addon.Media:Fetch("font", db.font), db.fontSize, outline)

	F.EnergyBar.Text:SetVertexColor(unpack(db.energyTextColor))
	F.ManaBar.Text:SetVertexColor(unpack(db.manaTextColor))
	F.RageBar.Text:SetVertexColor(unpack(db.rageTextColor))

	if db.showText then
		F.EnergyBar.Text:Show()
		F.ManaBar.Text:Show()
		F.RageBar.Text:Show()
	else
		F.EnergyBar.Text:Hide()
		F.ManaBar.Text:Hide()
		F.RageBar.Text:Hide()
	end

	local toShow = {}
	local size = 0
	if db.showEnergy then
		tinsert(toShow, F.EnergyBar)
	else
		F.EnergyBar:Hide()
	end

	if db.showRage then
		tinsert(toShow, F.RageBar)
	else
		F.RageBar:Hide()
	end

	if db.showMana then
		tinsert(toShow, F.ManaBar)
	else
		F.ManaBar:Hide()
	end

	if F.RuneBar:IsVisible() then
		tinsert(toShow, F.RuneBar)
	end

	table.sort(toShow, function(lbar, rbar)
		return lbar.Order < rbar.Order
	end)

	for i, bar in ipairs(toShow) do
		bar:Show()
		bar:ClearAllPoints()
		if i == 1 then
			bar:SetPoint("TOPLEFT", self, "TOPLEFT")
		else
			if db.orientation == "VERTICAL" then
				bar:SetPoint("TOPLEFT", toShow[i - 1], "BOTTOMLEFT")
			else
				bar:SetPoint("LEFT", toShow[i - 1], "RIGHT")
			end
		end
		if db.orientation == "VERTICAL" then
			size = size + bar:GetHeight()
		else
			size = size + bar:GetWidth()
		end
	end

	if size <= 0 then
		F.MissingText:Show()
		size = 30
	else
		F.MissingText:Hide()
	end

	if db.orientation == "VERTICAL" then
		F:SetHeight(size)
		F:SetWidth(db.width)
	else
		F:SetWidth(math.max(db.width * #toShow, 50))
		F:SetHeight(toShow[1] and toShow[1]:GetHeight() or 30) 
	end
	
	F.EnergyBar:SetSize(db.width, db.energyHeight)
	F.RageBar:SetSize(db.width, db.rageHeight)
	F.ManaBar:SetSize(db.width, db.manaHeight)
	F.EnergyBar:Update()
	F.RageBar:Update()
	F.ManaBar:Update()
end

--
-- Right click drop down
--
local dropdown = CreateFrame("Frame", F:GetName().."Dropdown")
dropdown.displayMode = "MENU"

local info = {}
dropdown.initialize = function(self, level)
	if not level then return end
	wipe(info)
	if level == 1 then
		info.text = "Config"
		info.func = function()
			Addon.Config.Dialog:Open(Addon.Name)
		end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Hide"
		info.func = function()
			Addon.db.profile.show = false
			F:Update()
		end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Lock"
		info.func = function(self, _, _, checked)
			Addon.db.profile.locked = not checked
			F:Update()
		end
		info.checked = Addon.db.profile.locked
		UIDropDownMenu_AddButton(info, level)
	end
end

F:SetScript("OnClick", function(self, button)
	if button == "RightButton" then
		ToggleDropDownMenu(1, nil, dropdown, self:GetName(), 0, 0)
	end
end)