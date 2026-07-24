CARarityBarMixin = {}

function CARarityBarMixin:OnLoad()
    self.Highlight:SetAtlas("search-highlight")
    self.Left:SetAtlas("collapse-button-left")
    self.Right:SetAtlas("collapse-button-right")
    self.Middle:SetAtlas("collapse-button-middle")
    self.RarityGemContainer:SetPoint("LEFT", self.Text, "RIGHT", 4, 0)
    self.RarityGemContainer:SetGemSize(16)
    self.RarityGemContainer:SetOrientation({ "BOTTOMLEFT", "BOTTOMRIGHT", -2, 0 })
    self.RarityGemContainer:SetGemClickHandler(GenerateClosure(self.OnClick, self))
    self.RarityGemContainer:SetGemOnEnterHandler(function() self:LockHighlight() end)
    self.RarityGemContainer:SetGemOnLeaveHandler(function() self:UnlockHighlight() end)
    AttributesToKeyValues(self, "quality")
    if self.quality then
        self:SetQuality(self.quality)
    end
end 

function CARarityBarMixin:OnShow()
    self:Update()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CARarityBarMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CARarityBarMixin:OnEvent()
    self:Update()
end

function CARarityBarMixin:SetQuality(quality)
    self.quality = quality
    self.RarityGemContainer:SetGemQuality(quality)
    self:SetText(ITEM_QUALITY_COLORS[quality]:WrapText(_G["ITEM_QUALITY" .. quality .. "_DESC"]))
end 

function CARarityBarMixin:Update()
    if not self.quality then return end
    if not self:IsVisible() then return end

    local amount
    if BuildCreatorUtil.IsPickingSpells() then
        amount = select(self.quality, C_BuildEditor.GetQualityInfoForLevel()) or 0
    else
        amount = C_CharacterAdvancement.GetQualityCount(self.quality)
    end
    local limit = C_CharacterAdvancement.GetQualityLimit(self.quality)
    self.RarityGemContainer:SetNumGems(limit or amount, amount)
end

function CARarityBarMixin:OnClick()
    if self.quality then
        CharacterAdvancement:SetSearch(_G["ITEM_QUALITY" .. self.quality .. "_DESC"])
    end
end 