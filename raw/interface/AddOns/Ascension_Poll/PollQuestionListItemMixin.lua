PollQuestionListItemMixin = CreateFromMixins("ScrollListItemBaseMixin")

function PollQuestionListItemMixin:OnLoad()
    self.Highlight:SetAtlas("activities-incomplete-active", Const.TextureKit.IgnoreAtlasSize)
    self:SetNormalAtlas("activities-complete", Const.TextureKit.IgnoreAtlasSize)
end

function PollQuestionListItemMixin:Update()
    local _, questionText, _, feedbackText = C_PlayerPoll.GetQuestionInfo(self.index)
    local questionType = C_PlayerPoll.GetQuestionType and C_PlayerPoll.GetQuestionType(self.index)

    self.Question:SetText(questionText)

    local selectedParts = {}
    for i = 1, C_PlayerPoll.GetNumQuestionChoices(self.index) do
        local choiceText, isSelected = C_PlayerPoll.GetQuestionChoiceInfo(self.index, i)
        if isSelected then
            selectedParts[#selectedParts + 1] = choiceText
        end
    end

    if #selectedParts == 0 then
        if questionType == PollQuestionMixin.QuestionType.OptionalChoice and not string.isNilOrEmpty(feedbackText) then
            self.Answer:SetText(feedbackText)
        else
            self.Answer:SetText(DISABLED_FONT_COLOR:WrapText(POLL_UNANSWERED))
        end
    else
        self.Answer:SetText(table.concat(selectedParts, ", "))
    end
end

function PollQuestionListItemMixin:OnSelected()
    self:GetScrollList():Hide()
    self:GetScrollList():GetParent():SetSelectedQuestion(self.index)
end

function PollQuestionListItemMixin:OnEnter()
    self.Highlight:Show()
end 

function PollQuestionListItemMixin:OnLeave()
    self.Highlight:Hide()
end 
