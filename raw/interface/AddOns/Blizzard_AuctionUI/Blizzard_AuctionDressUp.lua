
local DressUpItemLink_orig = DressUpItemLink;

function DressUpItemLink(link, undress)
	if ( not link ) then
		return;
	end

	if ( AuctionFrame:IsShown() ) then
		local itemID = GetItemInfoFromHyperlink(link)
		local vanityData = VanityCollectionUtil.GetItem(itemID)
		if vanityData then
			local preview = vanityData.creaturePreview
			if preview and preview > 0 then
				if not AuctionDressUpFrame:IsShown() then
					ShowUIPanel(AuctionDressUpFrame);
				end
				AuctionDressUpModel:SetDisplayInfo(preview)
				AuctionDressUpModel:ResetValues()
				AuctionDressUpModel.isCreature = true
				return
			end

			preview = vanityData.spellPreview
			if preview and preview > 0 then
				if not AuctionDressUpFrame:IsShown() then
					ShowUIPanel(AuctionDressUpFrame);
					AuctionDressUpModel:SetUnit("player")
				end
				if AuctionDressUpModel.isCreature then
					AuctionDressUpModel:SetUnit("player")
					AuctionDressUpModel:ResetValues()
					AuctionDressUpModel.isCreature = false
				end
				AuctionDressUpModel:SetSpell(preview)
				AuctionDressUpModel:RefreshValues()
				return
			end

			if vanityData.contentsPreview and #vanityData.contentsPreview > 0 then
				if not AuctionDressUpFrame:IsShown() then
					ShowUIPanel(AuctionDressUpFrame)
					AuctionDressUpModel:SetUnit("player")
				end

				if AuctionDressUpModel.isCreature then
					AuctionDressUpModel:SetUnit("player")
					AuctionDressUpModel:ResetValues()
					AuctionDressUpModel.isCreature = false
				end

				if undress then
					AuctionDressUpModel:Undress()
				end

				for _, contentItemID in ipairs(vanityData.contentsPreview) do
					AuctionDressUpModel:TryOn(contentItemID)
				end

				AuctionDressUpModel:RefreshValues()
				return
			end
		end

		if ( not AuctionDressUpFrame:IsShown() ) then
			ShowUIPanel(AuctionDressUpFrame);
			AuctionDressUpModel:SetUnit("player");
		end

		if AuctionDressUpModel.isCreature then
			AuctionDressUpModel:SetUnit("player")
			AuctionDressUpModel:ResetValues()
			AuctionDressUpModel.isCreture = false
		end

		if undress then
			AuctionDressUpModel:Undress()
		end
		AuctionDressUpModel:TryOn(link);
		AuctionDressUpModel:RefreshValues()
	else
		DressUpItemLink_orig(link);
	end
end

function SetAuctionDressUpBackground()
	local texture = DressUpTexturePath();
	AuctionDressUpBackgroundTop:SetTexture(texture..1);
	AuctionDressUpBackgroundBot:SetTexture(texture..3);
end

function AuctionDressUpFrame_OnShow()
	UIPanelWindows["AuctionFrame"].width = 1020;
	UpdateUIPanelPositions(AuctionFrame);
	PlaySound("igCharacterInfoOpen");
end

function AuctionDressUpFrame_OnHide()
	UIPanelWindows["AuctionFrame"].width = 840;
	UpdateUIPanelPositions();
	PlaySound("igCharacterInfoClose");
end
