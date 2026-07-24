BuildListCategoryListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

local CategoryIcons = {
    [Enum.BuildCategory.ActiveBuild] = "",
    [Enum.BuildCategory.BuildDraft] = "Interface\\Icons\\ability_priest_angelicfeather",
    [Enum.BuildCategory.BuildDraftEndGamePvE] = "Interface\\Icons\\ability_priest_angelicfeather",
    [Enum.BuildCategory.BuildDraftEndGamePvP] = "Interface\\Icons\\ability_priest_angelicfeather",
    [Enum.BuildCategory.Leveling] = "Interface\\Icons\\Mail_GMIcon",
    [Enum.BuildCategory.Level60PvE] = "Interface\\Icons\\pvecurrency-justice",
    [Enum.BuildCategory.Level60PvP] = "Interface\\Icons\\achievement_pvp_legion03",
    [Enum.BuildCategory.Level70PvE] = "Interface\\Icons\\pvecurrency-justice",
    [Enum.BuildCategory.Level70PvP] = "Interface\\Icons\\achievement_pvp_legion03",
    [Enum.BuildCategory.None] = "Interface\\Icons\\garrison_building_workshop",
    [Enum.BuildCreateCategory.Import] = "Interface\\Icons\\garrison_build",
    [Enum.BuildCreateCategory.CurrentBuild] = "Interface\\Icons\\trade_archaeology_draenei_tome",
    [Enum.BuildCreateCategory.SavedBuild] = "Interface\\Icons\\garrison_building_workshop",
    [Enum.BuildCreateCategory.Leveling] = "Interface\\Icons\\Mail_GMIcon",
    [Enum.BuildCreateCategory.Level60PvE] = "Interface\\Icons\\pvecurrency-justice",
    [Enum.BuildCreateCategory.Level60PvP] = "Interface\\Icons\\achievement_pvp_legion03",
    [Enum.BuildCreateCategory.Level70PvE] = "Interface\\Icons\\pvecurrency-justice",
    [Enum.BuildCreateCategory.Level70PvP] = "Interface\\Icons\\achievement_pvp_legion03",
    [Enum.BuildCategory.History] = "Interface\\Icons\\ability_bossmagistrix_timewarp2",
}

function BuildListCategoryListItemMixin:OnLoad()
    self:SetHighlightAtlas("buildcreator-category-highlight")
    self.Icon:SetBorderAtlas("bluemenu-Ring")
    self.Icon:SetBorderSize(48, 48)
    self.Icon:SetRounded(true)
    self.Separator:SetAtlas("_buildcreator-border-bottom", Const.TextureKit.UseAtlasSize)
end

function BuildListCategoryListItemMixin:Update()
    local category = BuildCreatorFrame:GetCategoryAtIndex(self.index)
    self.category = category

    if category == Enum.BuildCategory.ActiveBuild then
        self:SetNormalAtlas("buildcreator-category-currentbuild")
        self.Separator:Show()
        local buildID = BuildCreatorUtil.GetActiveBuildID()
        if buildID then
            local build = C_BuildCreator.GetBuild(buildID)
            if build then
                self:SetText(HIGHLIGHT_FONT_COLOR:WrapText(ACTIVE_BUILD.."|n")..build.Name)
                self.Icon:SetIcon("Interface\\Icons\\"..build.Icon)
            else
                self:SetText(HIGHLIGHT_FONT_COLOR:WrapText(ACTIVE_BUILD))
                self.Icon:SetIcon("Interface\\Icons\\inv_darkmoon_eye")
            end
            self:SetEnabled(true)
            return
        else
            self:SetText(DISABLED_FONT_COLOR:WrapText(NO_ACTIVE_BUILD))
            self.Icon:SetIcon("Interface\\Icons\\inv_darkmoon_eye")
            self:SetEnabled(false)
            return
        end
    else
        self:SetNormalAtlas("buildcreator-category")
        self.Separator:Hide()
    end


    if BuildCreatorFrame.isCreateMode then
        self:SetText(_G["BUILDCREATOR_CREATEBUTTON_" .. category:upper()])
    else
        self:SetText(_G["BUILDCREATOR_CATEGORY_" .. category:upper()])
    end

    self.Icon:SetIcon(CategoryIcons[category] or "Interface\\Icons\\inv_darkmoon_eye")


    if category == Enum.BuildCategory.History then
        self:SetEnabled(C_BuildCreator.GetNumBookmarkedBuilds() > 0)
    else
        local isMaxLevelCategory = category == Enum.BuildCategory.Level60PvE
                or category == Enum.BuildCategory.Level60PvP
                or category == Enum.BuildCategory.Level70PvE
                or category == Enum.BuildCategory.Level70PvP

        if isMaxLevelCategory then
            self:SetEnabled(C_Player:IsMaxLevel())
        else
            self:SetEnabled(true)
        end
    end
end

function BuildListCategoryListItemMixin:OnSelected()
    if BuildCreatorFrame.isCreateMode then
        BuildCreatorFrame:CreateBuild(self.category)
    else
        BuildCreatorFrame:SelectCategory(self.category)
    end
end

function BuildListCategoryListItemMixin:OnDisable()
    self:GetNormalTexture():SetDesaturated(true)
    self.Icon:SetDesaturated(true)
end 

function BuildListCategoryListItemMixin:OnEnable()
    self:GetNormalTexture():SetDesaturated(false)
    self.Icon:SetDesaturated(false)
end