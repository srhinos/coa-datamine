BuildCategoryMixin = {}

BuildCategoryMixin.ContainerType = {
    General = "GENERAL",
    PvE = "PVE",
    PvP = "PVP",
    Create = "CREATE",
}

local CATEGORY_BACKGROUNDS = {
    [BuildCategoryMixin.ContainerType.General] = "build-category-bg-general",
    [BuildCategoryMixin.ContainerType.PvE] = "build-category-bg-pve",
    [BuildCategoryMixin.ContainerType.PvP] = "build-category-bg-pvp",
    [BuildCategoryMixin.ContainerType.Create] = "build-category-bg-create",
}

local function CheckBuildDraftAllowed()
    if not C_Config.GetBoolConfig("CONFIG_BUILD_DRAFT_ENABLED") then
        return false, RED_FONT_COLOR:WrapText(TOGGLE_BUILDDRAFT_DISABLED)
    end
    
    return true
end

local DISABLED_CATEGORIES = {
    [Enum.BuildCategory.BuildDraft] = CheckBuildDraftAllowed,
    [Enum.BuildCategory.BuildDraftEndGamePvE] = CheckBuildDraftAllowed,
    [Enum.BuildCategory.BuildDraftEndGamePvP] = CheckBuildDraftAllowed,
}

local CATEGORY_BUTTONS = {
    [BuildCategoryMixin.ContainerType.General] = {
        Enum.BuildCategory.BuildDraft,
        "",
        Enum.BuildCategory.Leveling,
    },
    [BuildCategoryMixin.ContainerType.General.."FULL"] = {
        Enum.BuildCategory.BuildDraft,
        Enum.BuildCategory.Leveling,
        "",
        Enum.BuildCategory.Level60PvPvE,
        Enum.BuildCategory.Level70PvPvE,
        Enum.BuildCategory.None,
        "",
        Enum.BuildCategory.History,
        Enum.BuildCategory.MyBuilds,
        Enum.BuildCategory.Archived,
    },
    [BuildCategoryMixin.ContainerType.PvE] = {
        Enum.BuildCategory.BuildDraftEndGamePvE,
        "",
        Enum.BuildCategory.Level60PvE,
        Enum.BuildCategory.Level70PvE,
    },
    [BuildCategoryMixin.ContainerType.PvP] = {
        Enum.BuildCategory.BuildDraftEndGamePvP,
        "",
        Enum.BuildCategory.Level60PvP,
        Enum.BuildCategory.Level70PvP,
    },
    [BuildCategoryMixin.ContainerType.Create] = {
        Enum.BuildCreateCategory.Import,
        Enum.BuildCreateCategory.CurrentBuild,
        Enum.BuildCreateCategory.SavedBuild,
        "",
        Enum.BuildCreateCategory.Leveling,
        Enum.BuildCreateCategory.Level60PvE,
        Enum.BuildCreateCategory.Level70PvE,
        "",
        Enum.BuildCreateCategory.Level60PvP,
        Enum.BuildCreateCategory.Level70PvP,
    }
}

function BuildCategoryMixin:OnLoad()
    self.BorderLeft:SetAtlas("!buildcreator-border-left", Const.TextureKit.UseAtlasSize)
    self.BorderRight:SetAtlas("!buildcreator-border-right", Const.TextureKit.UseAtlasSize)
    Mixin(self.Background, "TextureDollyMixin")
    self.Background:SetDollyStartColor(0.6, 0.6, 0.6, 1)
    self.Background:SetDollyEndColor(0.8, 0.8, 0.8, 1)
    self.Background:SetDollyFinishCallback(function(isAtStart)
        self:SetScript("OnUpdate", nil)
    end)

    local category = self:GetAttribute("category")
    if BuildCategoryMixin.ContainerType[category] then
        self:SetParentCategory(BuildCategoryMixin.ContainerType[category])
    end
end

function BuildCategoryMixin:SetParentCategory(parentCategory)
    self.parentCategory = parentCategory
    local background = CATEGORY_BACKGROUNDS[parentCategory]
    if background then
        self.Background:SetAtlas(background)
        self.Background:SetVertexColor(0.6, 0.6, 0.6, 1)

        local left, right, top, bottom = AtlasUtil:GetCoords(background)
        local endLeft, endRight, endTop, endBottom = TextureUtil.ZoomTexCoords(0.007, left, right, top, bottom)
        self.Background:SetDollyStartCoords(left, right, top, bottom)
        self.Background:SetDollyEndCoords(endLeft, endRight, endTop, endBottom)

        self.Text:SetText(_G["BUILDCREATOR_CATEGORY_HEADER_" .. parentCategory:upper()])
        local smallText = _G["BUILDCREATOR_CATEGORY_HEADER_" .. parentCategory:upper() .. "_SHORT"]
        self.SmallText:SetText(smallText or "")
    else
        C_Logger.Error("Category has no background: %s", parentCategory)
    end

    local categories = CATEGORY_BUTTONS[parentCategory]
    if not categories then
        C_Logger.Error("Category has no subcategory buttons: %s", parentCategory)
        return
    end
    
    if parentCategory == BuildCategoryMixin.ContainerType.General then
        if C_CVar.GetBool("ShowFullBuildCreator") then
            categories = CATEGORY_BUTTONS[parentCategory.."FULL"]
        end
    end

    local buttonHeight = 48
    local totalHeight = (#categories * buttonHeight) + (#categories - 1)

    for i, category in ipairs(categories) do
        if category ~= "" then
            local button = CreateFrame("Button", "$parentButton" .. i, self, "BuildCategoryButtonTemplate")
            self.Buttons = self.Buttons or {}
            self.Buttons[category] = button
            if parentCategory == BuildCategoryMixin.ContainerType.Create then
                button:SetCreateCategory(category)
            else
                button:SetCategory(category)
            end
            local yOffset = (totalHeight / 2) - (buttonHeight / 2) - ((i - 1) * buttonHeight)
            button:SetPoint("CENTER", 0, yOffset)
            button:Show()
            if button:IsEnabled() == 1 then
                button:SetAlpha(1)
            else
                button:SetAlpha(0.4)
            end
        end
    end
end

function BuildCategoryMixin:OnEnter()
    self.Background:SetDollyTimeScale(0.4)
    self:SetScript("OnUpdate", function(self, elapsed)
        self.Background:MoveDollyForward(elapsed)
    end)
end

function BuildCategoryMixin:OnLeave()
    self.Background:SetDollyTimeScale(1.2)
    self:SetScript("OnUpdate", function(self, elapsed)
        self.Background:MoveDollyBackward(elapsed)
    end)
end

function BuildCategoryMixin:OnShow()
    if self.parentCategory ~= BuildCategoryMixin.ContainerType.General then
        self.UnlockCover:SetShown(not C_CVar.GetBool("ShowFullBuildCreator"))
    else
        self.UnlockCover:Hide()
    end
end

BuildCategoryButtonMixin = {}

function BuildCategoryButtonMixin:OnLoad()
    self:SetNormalAtlas("store-category")
    self:SetPushedAtlas("store-category")
    self:GetPushedTexture():SetVertexColor(0.6, 0.6, 0.6, 1)
    self:SetHighlightAtlas("store-category-hover")
end

function BuildCategoryButtonMixin:SetCategory(category)
    self.category = category
    if category == Enum.BuildCategory.BuildDraft then
        HelpTip:Show("BUILD_CREATOR_FEATURED_HINT", self)
    end
    self:SetText(_G["BUILDCREATOR_CATEGORYBUTTON_" .. category:upper()])
    local checkFunc = DISABLED_CATEGORIES[category]
    if checkFunc then
        local enabled, tooltipTitle, tooltipText = checkFunc()
        self:SetEnabled(enabled)
        self.tooltipTitle = tooltipTitle
        self.tooltipText = tooltipText
    else
        self:Enable()
    end
end

function BuildCategoryButtonMixin:SetCreateCategory(category)
    self.category = category
    self.createCategory = true
    self:SetText(_G["BUILDCREATOR_CREATEBUTTON_" .. category:upper()])
    local checkFunc = DISABLED_CATEGORIES[category]
    if checkFunc then
        local enabled, tooltipTitle, tooltipText = checkFunc()
        self:SetEnabled(enabled)
        self.tooltipTitle = tooltipTitle
        self.tooltipText = tooltipText
    else
        self:Enable()
    end
end

function BuildCategoryButtonMixin:OnDisable()
    self.Background:SetDesaturated(true)
    self.Background:SetAlpha(0.8)
    self:GetFontString():SetTextColor(0.4, 0.4, 0.4)
end

function BuildCategoryButtonMixin:OnEnable()
    self.Background:SetDesaturated(false)
    self.Background:SetAlpha(1)
    self:GetFontString():SetTextColor(1, 1, 1)
end

function BuildCategoryButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
    if self.createCategory then
        BuildCreatorFrame:CreateBuild(self.category)
    else
        BuildCreatorFrame:SelectCategory(self.category)
    end
end

function BuildCategoryButtonMixin:OnEnter()
    self:GetParent():OnEnter()
    GameTooltip_GenericTooltip(self, "ANCHOR_BOTTOM")
end

function BuildCategoryButtonMixin:OnLeave()
    self:GetParent():OnLeave()
    GameTooltip:Hide()
end 