PollQuestionChoiceMixin = {}

local MaxTextWidth = 258

function PollQuestionChoiceMixin:OnLoad()
    self:SetMultiSelectStyle(false)
    self.CheckButton:EnableMouse(false)
end

function PollQuestionChoiceMixin:SetMultiSelectStyle(multi)
    if multi then
        self.CheckButton:SetNormalAtlas("common-dropdown-ticksquare-2x", Const.TextureKit.IgnoreAtlasSize)
        self.CheckButton:SetCheckedAtlas("common-dropdown-icon-checkmark-yellow-2x", Const.TextureKit.IgnoreAtlasSize)
        self.CheckButton:SetHighlightAtlas("common-dropdown-icon-checkmark-yellow-2x", Const.TextureKit.IgnoreAtlasSize)
    else
        self.CheckButton:SetNormalAtlas("common-dropdown-tickradial-2x", Const.TextureKit.IgnoreAtlasSize)
        self.CheckButton:SetCheckedAtlas("common-dropdown-icon-radialtick-yellow-2x", Const.TextureKit.IgnoreAtlasSize)
        self.CheckButton:SetHighlightAtlas("common-dropdown-icon-radialtick-yellow-2x", Const.TextureKit.IgnoreAtlasSize)
    end
end

function PollQuestionChoiceMixin:SetQuestionIndex(index)
    self.questionIndex = index
end

function PollQuestionChoiceMixin:SetIndex(index)
    self.index = index
end

function PollQuestionChoiceMixin:GetIndex()
    return self.index
end

function PollQuestionChoiceMixin:SetChecked(checked)
    self.CheckButton:SetChecked(checked)
    if checked then
        self.Text:SetFontObject("GameFontHighlight")
    else
        self.Text:SetFontObject("GameFontNormal")
    end
end 

function PollQuestionChoiceMixin:GetChecked()
    return self.CheckButton:GetChecked()
end

function PollQuestionChoiceMixin:SetText(text)
    self.Text:SetWidth(MaxTextWidth)

    self.Text:SetText(text)

    local stringWidth = self.Text:GetStringWidth() or 0
    local desiredTextWidth = math.min(MaxTextWidth, stringWidth + 10)
    self.Text:SetWidth(desiredTextWidth)
    self:SetWidth(desiredTextWidth + 22)

    self:SetHeight(math.max(18, self.Text:GetHeight() + 4))

    return desiredTextWidth
end

function PollQuestionChoiceMixin:ApplyTextWidth(textWidth)
    local finalTextWidth = math.min(MaxTextWidth, textWidth or MaxTextWidth)

    self.Text:SetWidth(finalTextWidth)
    self:SetWidth(finalTextWidth + 22)

    self:SetHeight(math.max(18, self.Text:GetHeight() + 4))
end

function PollQuestionChoiceMixin:OnClick()
    if C_PlayerPoll.CanChangeQuestionChoice(self.questionIndex) then
        PlaySound(SOUNDKIT.UI_WORLDQUEST_MAP_SELECT)
        self:GetParent():GetParent():OnChoiceClicked(self:GetIndex())
    end
end

function PollQuestionChoiceMixin:OnEnter()
    if C_PlayerPoll.CanChangeQuestionChoice(self.questionIndex) then
        self.CheckButton:LockHighlight()
        self.Text:SetFontObject("GameFontHighlight")
    end
end

function PollQuestionChoiceMixin:OnLeave()
    self.CheckButton:UnlockHighlight()
    if not self:GetChecked() then
        self.Text:SetFontObject("GameFontNormal")
    end
end

function PollQuestionChoiceMixin:OnDisable()
    self.CheckButton:UnlockHighlight()
    if self:GetChecked() then
        self.Text:SetFontObject("GameFontHighlight")
    else
        self.Text:SetFontObject("GameFontDisable")
    end
end

function PollQuestionChoiceMixin:OnEnable()
    self.CheckButton:UnlockHighlight()

    if self:GetChecked() then
        self.Text:SetFontObject("GameFontHighlight")
    else
        self.Text:SetFontObject("GameFontNormal")
    end
end 