TalkingHeadFrameMixin = {
	Duration = 0,
	Art = {
		Alliance = {
			Portrait = "TalkingHeads-Alliance-PortraitFrame",
			Background = "TalkingHeads-Alliance-TextBackground",
			Name = CreateColor(0.02, 0.42, 1),
			Text = CreateColor(0, 0, 0),
			Shadow = CreateColor(0, 0, 0, 0)
		},
		Horde = {
			Portrait = "TalkingHeads-Horde-PortraitFrame",
			Background = "TalkingHeads-Horde-TextBackground",
			Name = CreateColor(0.82, 0.02, 0.02),
			Text = CreateColor(0, 0, 0),
			Shadow = CreateColor(0, 0, 0, 0)
		},
		Neutral = {
			Portrait = "TalkingHeads-Neutral-PortraitFrame",
			Background = "TalkingHeads-Neutral-TextBackground",
			Name = CreateColor(1, 0.82, 0.02),
			Text = CreateColor(0, 0, 0),
			Shadow = CreateColor(0, 0, 0, 0)
		},
		None = {
			Portrait = "TalkingHeads-Neutral-PortraitFrame",
			Background = "TalkingHeads-TextBackground",
			Name = CreateColor(1, 0.82, 0.02),
			Text = CreateColor(1, 1, 1),
			Shadow = CreateColor(0, 0, 0, 1)
		}
	},
	Queue = {},
}

function TalkingHeadFrameMixin:OnLoad()
	self.Background:SetAtlas("TalkingHeads-TextBackground", Const.TextureKit.UseAtlasSize)
	self.Sheen:SetAtlas("TalkingHeads-Glow-Sheen", Const.TextureKit.UseAtlasSize)
	self.TextSheen:SetAtlas("TalkingHeads-Glow-TextSheen", Const.TextureKit.UseAtlasSize)
	self:RegisterEvent("TALKING_HEAD_FRAME_DISPLAY")
end

function TalkingHeadFrameMixin:UpdateDisplay(name, text, nameSize, textSize, duration, portrait, art, animationID, loopAnim)
	if self:IsShown() and not self.hiding then
		self:Enqueue(name, text, nameSize, textSize, duration, portrait, art)
		return
	end

	art = self.Art[art] or self.Art.None

	if not duration then
		duration = 4
	end

	if not nameSize then
		nameSize = 20
	end

	if not textSize then
		textSize = 14
	end
	
	self.hiding = false
	self.PortraitFrame.Portrait:SetAtlas(art.Portrait, Const.TextureKit.UseAtlasSize)
	self.Background:SetAtlas(art.Background, Const.TextureKit.UseAtlasSize)
	self.PortraitFrame.Model:StopSequence()
	
	self.Name:SetFontSize(nameSize)
	self.Text:SetFontSize(textSize)

	if portrait and portrait ~= "" then
		self.PortraitFrame:Show()
		local isCreature = type(portrait) == "number"

		self.PortraitFrame.Model:SetShown(isCreature)
		self.PortraitFrame.Icon:SetShown(not isCreature)

		if isCreature then
			self.PortraitFrame.Model:SetDisplayInfo(portrait)
			if animationID then
				self.PortraitFrame.Model:PlaySequence(animationID, loopAnim)
			else
				self.PortraitFrame.Model:StopSequence()
			end
		else
			self.PortraitFrame.Icon:SetTexture("Interface\\Icons\\"..portrait)
		end
		self.Name:SetPoint("TOPLEFT", self.PortraitFrame.Background, "TOPRIGHT", 12, 0)
	else
		self.PortraitFrame:Hide()
		self.Name:SetPoint("TOPLEFT", 28, -28)
	end
	
	self.Name:SetText(name)
	self.Text:SetText(text)
	
	self.Name:SetTextColor(art.Name:GetRGBA())
	self.Name:SetShadowColor(art.Shadow:GetRGBA())
	
	self.Text:SetTextColor(art.Text:GetRGBA())
	self.Text:SetShadowColor(art.Shadow:GetRGBA())

	if self.Sheen.Anim:IsPlaying() then
		self.Sheen.Anim:Stop()
	end

	if self.TextSheen.Anim:IsPlaying() then
		self.TextSheen.Anim:Stop()
	end

	if self.FadeOut:IsPlaying() then
		self.FadeOut:Stop()
		self.FadeIn:Play()
	end

	if not self:IsShown() then
		self.FadeIn:Play()
	end

	self.Sheen.Anim:Play()
	self.TextSheen.Anim:Play()

	if self.Timer then
		self.Timer:Cancel()
	end
	
	self.Duration = duration

	if duration > 0 and not self:IsMouseOver() then
		self.Timer = Timer.NewTimer(duration, function()
			self.Timer = nil
			self:Close()
		end)
	end 
end

function TalkingHeadFrameMixin:Enqueue(name, text, nameSize, textSize, duration, portrait, art)
	tinsert(self.Queue, { name, text, nameSize, textSize, duration, portrait, art })
end

function TalkingHeadFrameMixin:GetNext()
	return tremove(self.Queue, 1)
end

function TalkingHeadFrameMixin:EmptyQueue()
	wipe(self.Queue)
end

function TalkingHeadFrameMixin:OnHide()
	if self.FadeIn:IsPlaying() then
		self.FadeIn:Stop()
	end

	if self.Sheen.Anim:IsPlaying() then
		self.Sheen.Anim:Stop()
	end

	if self.TextSheen.Anim:IsPlaying() then
		self.Sheen.Anim:Stop()
	end
end

function TalkingHeadFrameMixin:OnEnter()
	if self.FadeOut:IsPlaying() then
		self.FadeOut:Stop()
	end
	if self.Timer then
		self.Timer:Cancel()
	end
end

function TalkingHeadFrameMixin:OnLeave()
	if self.Timer then
		self.Timer:Cancel()
	end

	if self.Duration > 0 then
		self.Timer = Timer.NewTimer(self.Duration, function()
			self.FadeOut:Play()
		end)
	end
end

function TalkingHeadFrameMixin:OnClick()
	self:Close()
end

function TalkingHeadFrameMixin:TALKING_HEAD_FRAME_DISPLAY(header, body, headerSize, bodySize, duration, portrait, art, animID, loopAnim)
	portrait = tonumber(portrait) or portrait
	if animID and animID <= 0 then
		animID = nil
	end
	if loopAnim == nil then
		loopAnim = true
	end
	self:UpdateDisplay(header, body, headerSize, bodySize, duration, portrait, art, animID, loopAnim)
end

function TalkingHeadFrameMixin:Close()
	if self.Timer then
		self.Timer:Cancel()
	end

	self.hiding = true
	self.Duration = 0
	local next = self:GetNext()
	if next then
		self:UpdateDisplay(unpack(next))
		return
	end

	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
	self.FadeOut:Play()
end 