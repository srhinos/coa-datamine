FeedbackFrameMixin = {}
FeedbackFrameMixin.OnEvent = OnEventToMethod

function FeedbackFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    self.Background:SetAtlas("auctionhouse-background-sell-right", Const.TextureKit.IgnoreAtlasSize)
    PortraitFrame_SetIcon(self, "Interface\\Icons\\mail_gmicon")
    PortraitFrame_SetTitle(self, SUBMIT_FEEDBACK)
    
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
end 

function FeedbackFrameMixin:OnShow()
    self.Rating:SetRating(3)
    self.AdditionalInformation:SetText("")
    self:RegisterEvent("SUBMIT_GAME_FEEDBACK_RESULT")
    self.ErrorFrame:Hide()
end

function FeedbackFrameMixin:OnHide()
    self:UnregisterEvent("SUBMIT_GAME_FEEDBACK_RESULT")
    self.ErrorFrame:Hide()
end

function FeedbackFrameMixin:OnDragStart()
    self:StartMoving()
end 

function FeedbackFrameMixin:OnDragStop()
    self:StopMovingOrSizing()
end 

function FeedbackFrameMixin:SubmitFeedback()
    local rating = self.Rating:GetRating() or 3
    local feedback = self.AdditionalInformation:GetText() or ""
    SubmitGameFeedback(rating, feedback:trim())
end 

function FeedbackFrameMixin:SUBMIT_GAME_FEEDBACK_RESULT(result)
    if result:endswith("_OK") then
        SendSystemMessage(FEEDBACK_SUBMITTED_THANK_YOU)
        self:Hide()
    else
        self.ErrorFrame:SetText(FEEDBACK_NOT_SUBMITTED, _G[result] or result)
        self.ErrorFrame:Show()
    end
end 