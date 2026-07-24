
function DressUpItemLink(link, undress)
	if not link then
		return;
	end

	local itemID = GetItemInfoFromHyperlink(link)
	local vanityData = VanityCollectionUtil.GetItem(itemID)
	if vanityData then
		local preview = vanityData.creaturePreview
		if preview and preview > 0 then
			if not DressUpFrame:IsShown() then
				ShowUIPanel(DressUpFrame);
			end
			DressUpModel:SetDisplayInfo(preview)
			DressUpModel:ResetValues()
			DressUpModel.isCreature = true
			return
		end
		
		preview = vanityData.spellPreview
		if preview and preview > 0 then
			if not DressUpFrame:IsShown() then
				ShowUIPanel(DressUpFrame);
				DressUpModel:SetUnit("player")
			end

			if DressUpModel.isCreature then
				DressUpModel:SetUnit("player")
				DressUpModel:ResetValues()
				DressUpModel.isCreature = false
			end
			DressUpModel:SetSpell(preview)
			DressUpModel:RefreshValues()
			return
		end
		
		if vanityData.contentsPreview and #vanityData.contentsPreview > 0 then
			if not DressUpFrame:IsShown() then
				ShowUIPanel(DressUpFrame)
				DressUpModel:SetUnit("player")
			end

			if DressUpModel.isCreature then
				DressUpModel:SetUnit("player")
				DressUpModel:ResetValues()
				DressUpModel.isCreature = false
			end

			if undress then
				DressUpModel:Undress()
			end

			for _, contentItemID in ipairs(vanityData.contentsPreview) do
				DressUpModel:TryOn(contentItemID)
			end

			DressUpModel:RefreshValues()
			return
		end
	end

    if not IsDressableItem(link) then
        return
    end

	if ( not DressUpFrame:IsShown() ) then
		ShowUIPanel(DressUpFrame);
        DressUpModel:SetUnit("player");
	end

    if DressUpModel.isCreature then
        DressUpModel:SetUnit("player")
        DressUpModel:ResetValues()
        DressUpModel.isCreature = false
    end

	if undress then
		DressUpModel:Undress()
	end
	DressUpModel:TryOn(link);
    DressUpModel:RefreshValues()
end

function DressUpCreature(creatureID)
	if not creatureID or creatureID == 0 then return end
	if not DressUpFrame:IsShown() then
		ShowUIPanel(DressUpFrame)
	end
	DressUpModel:SetDisplayInfo(creatureID)
	DressUpModel:ResetValues()
	DressUpModel.isCreature = true
end

function DressUpTexturePath(fileName, atlas)
	if not fileName then
		fileName = select(2, UnitRace("player"))
	end

	if ( not fileName ) then
		fileName = "Orc";
	end
	
	if atlas then
		return "DressUpBackground-"..fileName
	end

	return "Interface\\DressUpFrame\\DressUpBackground-"..fileName;
end

function SetDressUpBackground()
	local texture = DressUpTexturePath();
	DressUpBackgroundTopLeft:SetTexture(texture..1);
	DressUpBackgroundTopRight:SetTexture(texture..2);
	DressUpBackgroundBotLeft:SetTexture(texture..3);
	DressUpBackgroundBotRight:SetTexture(texture..4);
end
