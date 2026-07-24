CoASpecViewMixin = {}

function CoASpecViewMixin:OnLoad()
    self.class = select(2, UnitClass("player"))
    self.Background:SetAtlas("spec-background", Const.TextureKit.IgnoreAtlasSize)
    self.SpecChoicePool = CreateFramePool("Frame", self, "CoASpecChoiceTemplate")

    local specs = C_ClassInfo.GetAllSpecs(self.class)
    local numSpecs = #specs
    local choiceWidth = self:GetWidth() / math.max(numSpecs, 1)
    local choiceHeight = self:GetHeight()
    
    local specInfo, choiceFrame
    for i, spec in ipairs(specs) do
        specInfo = C_ClassInfo.GetSpecInfo(self.class, spec)
        choiceFrame = self.SpecChoicePool:Acquire()
        choiceFrame:SetSpecInfo(specInfo, choiceWidth, choiceHeight, i == 1, i == numSpecs)
        choiceFrame:SetPoint("LEFT", choiceWidth*(i-1), 0)
        choiceFrame:SetDividerShown(i ~= numSpecs)
        choiceFrame:Show()
    end

end

function CoASpecViewMixin:OnShow()
    local activeSpecID = C_CharacterAdvancement.GetActiveChrSpec()
    for choiceFrame in self.SpecChoicePool:EnumerateActive() do
        choiceFrame:UpdateVisualState(choiceFrame:GetSpecID() == activeSpecID)
    end
end