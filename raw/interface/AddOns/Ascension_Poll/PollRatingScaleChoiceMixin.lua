PollRatingScaleChoiceMixin = {}

local MinWidth = 44
local MaxTextWidth = 100

function PollRatingScaleChoiceMixin:OnLoad()
    self.CheckButton:SetCheckedAtlas("common-dropdown-icon-radialtick-yellow-2x", Const.TextureKit.IgnoreAtlasSize)
    self.CheckButton:SetNormalAtlas("common-dropdown-tickradial-2x", Const.TextureKit.IgnoreAtlasSize)
    self.CheckButton:SetHighlightAtlas("common-dropdown-icon-radialtick-yellow-2x", Const.TextureKit.IgnoreAtlasSize)
    self.CheckButton:EnableMouse(false)
end

function PollRatingScaleChoiceMixin:SetQuestionIndex(index)
    self.questionIndex = index
end

function PollRatingScaleChoiceMixin:SetIndex(index)
    self.index = index
end

function PollRatingScaleChoiceMixin:GetIndex()
    return self.index
end

function PollRatingScaleChoiceMixin:SetChecked(checked)
    self.CheckButton:SetChecked(checked)
    self.Text:SetFontObject(checked and "GameFontHighlightSmall" or "GameFontNormalSmall")
end

function PollRatingScaleChoiceMixin:GetChecked()
    return self.CheckButton:GetChecked()
end

function PollRatingScaleChoiceMixin:SetText(text)
    self:SetWidth(MaxTextWidth)
    self.Text:SetText(text or "")

    local stringWidth = self.Text:GetStringWidth() or 0
    local desired = math.min(MaxTextWidth, math.max(MinWidth, stringWidth + 10))
    self:SetWidth(desired)

    return desired
end

function PollRatingScaleChoiceMixin:ApplyTextWidth(width)
    local finalWidth = math.min(MaxTextWidth, math.max(MinWidth, width or MinWidth))
    self:SetWidth(finalWidth)
end

function PollRatingScaleChoiceMixin:OnClick()
    if C_PlayerPoll.CanChangeQuestionChoice(self.questionIndex) then
        PlaySound(SOUNDKIT.UI_WORLDQUEST_MAP_SELECT)
        self:GetParent():GetParent():OnChoiceClicked(self:GetIndex())
    end
end

function PollRatingScaleChoiceMixin:OnEnter()
    if C_PlayerPoll.CanChangeQuestionChoice(self.questionIndex) then
        self.CheckButton:LockHighlight()
        self.Text:SetFontObject("GameFontHighlightSmall")
    end
end

function PollRatingScaleChoiceMixin:OnLeave()
    self.CheckButton:UnlockHighlight()
    if not self:GetChecked() then
        self.Text:SetFontObject("GameFontNormalSmall")
    end
end

function PollRatingScaleChoiceMixin:OnDisable()
    self.CheckButton:UnlockHighlight()
    if self:GetChecked() then
        self.Text:SetFontObject("GameFontHighlightSmall")
    else
        self.Text:SetFontObject("GameFontDisableSmall")
    end
end

function PollRatingScaleChoiceMixin:OnEnable()
    self.CheckButton:UnlockHighlight()
    if self:GetChecked() then
        self.Text:SetFontObject("GameFontHighlightSmall")
    else
        self.Text:SetFontObject("GameFontNormalSmall")
    end
end
