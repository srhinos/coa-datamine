RealmTabMixin = {}

function RealmTabMixin:OnLoad()
    self:SetNormalAtlas("realm-tab", true)
    self:SetHighlightAtlas("realm-tab-highlight", true)
    self:SetPushedAtlas("realm-tab-pushed", true)
    self:SetCheckedAtlas("realm-tab-selected", true)

    self:GetPushedTexture():SetVertexColor(0.4, 0.4, 0.4)
    self:GetNormalTexture():SetDrawLayer("BACKGROUND")
    self:GetPushedTexture():SetDrawLayer("BACKGROUND")
    self:GetCheckedTexture():SetDrawLayer("BORDER")
    
    SetParentArray(self, "Buttons", self:GetID())
    self:SetSelected(self:GetID() == 1)
end

function RealmTabMixin:OnEnter()
    local dir = (RealmList.page - self:GetID()) / 100
    RealmList.stop = ((RealmList.page - 1) * GlueParent:GetWidth()) - (dir * GlueParent:GetWidth())

    if not RealmList.isScrolling then
        RealmList.start = RealmList.Scroll:GetHorizontalScroll()
        RealmList.time = 0
    end

    RealmList:SetScript("OnUpdate", RealmList.OnUpdate)
end

function RealmTabMixin:OnLeave()
    if RealmList.page ~= self:GetID() then
        RealmList.stop = (RealmList.page - 1) * GlueParent:GetWidth()

        if not RealmList.isScrolling then
            RealmList.start = RealmList.Scroll:GetHorizontalScroll()
            RealmList.time = 0
        end

        RealmList:SetScript("OnUpdate", RealmList.OnUpdate)
    end
end

function RealmTabMixin:SetSelected(selected)
    self:SetChecked(selected)
    self:SetEnabled(not selected)
end 

function RealmTabMixin:OnClick()
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    RealmList:ScrollPage(self:GetID())
end 