CATalentArtMixin = {}

function CATalentArtMixin:OnLoad()
    self.artSet = {}
end

function CATalentArtMixin:SetArtSet(set)
    self.artSet = set
end

function CATalentArtMixin:GetShape()
    return self.artSet and self.artSet.shape or TalentButtonUtil.VisualShape.Square
end 