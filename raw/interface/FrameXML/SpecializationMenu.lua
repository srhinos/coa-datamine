--
-- Spec List
--
SpecializationListMixin = CreateFromMixins("ScrollListMixin")

function SpecializationListMixin:OnLoad()
    ScrollListMixin.OnLoad(self)
    self:SetGetNumResultsFunction(SpecializationUtil.GetNumSpecializations)
    self:SetSelectedHighlightTexture()
    self:SetTemplate("SpecListItemTemplate")
    
    self.IconSelector:SetFrameLevel(self:GetFrameLevel()+10)
    self.SelectFrame:SetFrameLevel(self:GetFrameLevel()+20)
end

function SpecializationListMixin:OnShow()
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:Refresh()
end

function SpecializationListMixin:OnHide()
    self:UnregisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
end

function SpecializationListMixin:Refresh()
    self.IconSelector:Hide()
    self.SelectFrame:Hide()
    self:RefreshScrollFrame()
end

function SpecializationListMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED()
    self:Refresh()
end

--
-- Spec Menu
--
SpecializationMenuMixin = {}

function SpecializationMenuMixin:OnLoad()
    self.title:SetText(COA_CA_AVAILABLE_SPECIALIZATIONS)
end