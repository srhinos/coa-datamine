NUM_PET_STABLE_SLOTS = 4;

function PetStable_OnLoad(self)
	self:RegisterEvent("PET_STABLE_SHOW");
	self:RegisterEvent("PET_STABLE_UPDATE");
	self:RegisterEvent("PET_STABLE_UPDATE_PAPERDOLL");
	self:RegisterEvent("PET_STABLE_CLOSED");
	self:RegisterEvent("UNIT_PET");
	self:RegisterEvent("UNIT_NAME_UPDATE");
end

function PetStable_OnEvent(self, event, ...)
	local arg1 = ...;
	if ( event == "PET_STABLE_SHOW" ) then
		ShowUIPanel(self);
		if ( not self:IsShown() ) then
			ClosePetStables();
			return;
		end

		PetStable_Update();
	elseif ( event == "PET_STABLE_UPDATE" or
	         (event == "UNIT_PET" and arg1 == "player") or
			 (event == "UNIT_NAME_UPDATE" and arg1 == "pet") ) then
		PetStable_Update();
	elseif ( event == "PET_STABLE_UPDATE_PAPERDOLL" ) then
		-- So warlock pets don't show
		if ( UnitExists("pet") and not HasPetUI() ) then
			PetStable_NoPetsAllowed();
			return;
		end
		SetPetStablePaperdoll(PetStableModel);
	elseif ( event == "PET_STABLE_CLOSED" ) then
		HideUIPanel(self);
		StaticPopup_Hide("CONFIRM_BUY_STABLE_SLOT");
	end
end

function PetStable_Update()
	-- Set stablemaster portrait
	SetPortraitTexture(PetStableFramePortrait, "player")
	PetStableCurrentPet.DeleteButton:Hide()

	-- So warlock pets don't show
	local hasPetUI, isHunterPet = HasPetUI()
	if ( UnitExists("pet") and hasPetUI and not PetCanBeAbandoned()) then
		PetStable_NoPetsAllowed()
		PetStableCurrentPet:Disable()
		return
	else
		PetStableCurrentPet:Enable()
	end

	-- If no selected pet try to set one
	local selectedPet = GetSelectedStablePet()
	if ( selectedPet == -1 ) then
		if ( GetPetIcon() ) then
			selectedPet = 0
			ClickStablePet(0)
		else
			for i=0, NUM_PET_STABLE_SLOTS do
				if ( GetStablePetInfo(i) ) then
					selectedPet = i
					ClickStablePet(i)
					break
				end 
			end
		end
	end

	-- Set slot cost
	MoneyFrame_Update("PetStableCostMoneyFrame", GetNextStableSlotCost())

	-- Set slot statuseses
	local numSlots = GetNumStableSlots()
	local numPets = GetNumStablePets()

	local button, buttonName
	local background
	local icon, name, level, family, talent
	for i=1, NUM_PET_STABLE_SLOTS do
		buttonName = "PetStableStabledPet"..i
		button = _G[buttonName]
		background = _G[buttonName.."Background"]
		icon, name, level, family, talent = GetStablePetInfo(i)
        talent = talent or ""
		SetItemButtonTexture(button, icon)
		if ( i <= GetNumStableSlots() ) then
			background:SetVertexColor(1.0,1.0,1.0)
			button:Enable()
			if ( icon ) then
				button.tooltip = name
				button.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent)
				button.DeleteButton:Show()
			else
				button.tooltip = EMPTY_STABLE_SLOT
				button.tooltipSubtext = ""
				button.DeleteButton:Hide()
			end
			if ( i == selectedPet ) then
				if ( icon ) then
					button:SetChecked(1)
					PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent)
					SetPetStablePaperdoll(PetStableModel)
                    if GetStablePetFoodTypes(i) then
					    PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetStablePetFoodTypes(i)))
                    end
					if ( not PetStableModel:IsShown() ) then
						PetStableModel:Show()
					end
				else
					button:SetChecked(nil)
					PetStableLevelText:SetText("")
					PetStableModel:Hide()
				end

			else
				button:SetChecked(nil)
			end
			if ( GameTooltip:IsOwned(button) ) then
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
				GameTooltip:SetText(button.tooltip)
				GameTooltip:AddLine(button.tooltipSubtext, 1.0, 1.0, 1.0)
				GameTooltip:Show()
			end
		else
			background:SetVertexColor(1.0, 0.1, 0.1)
			button:Disable()
			button.DeleteButton:Hide()
		end
	end

	-- Current pet slot
	if ( selectedPet == 0 ) then
		if ( UnitExists("pet") and hasPetUI ) then
			PetStableCurrentPet:SetChecked(1)
			name = UnitName("pet") or ""
			level = UnitLevel("pet")
			family = UnitCreatureFamily("pet") or ""
			talent = GetPetTalentTree() or ""
			PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent)
			SetPetStablePaperdoll(PetStableModel)
			if ( not PetStableModel:IsShown() ) then
				PetStableModel:Show()
			end
			if ( GetPetFoodTypes() ) then
				PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetPetFoodTypes()))
			end
		elseif ( GetStablePetInfo(0) ) then
			-- If pet doesn't exist it might be dismissed, so check stable slot 0 for current pet info
			PetStableCurrentPet:SetChecked(1)
			icon, name, level, family, talent = GetStablePetInfo(0)
            talent = talent or ""
			PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent)
			SetPetStablePaperdoll(PetStableModel)
			if ( not PetStableModel:IsShown() ) then
				PetStableModel:Show()
			end
			if ( GetStablePetFoodTypes(0) ) then
				PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetStablePetFoodTypes(0)))
			end
		else
			PetStableCurrentPet:SetChecked(nil)
			PetStableLevelText:SetText("")
			PetStableModel:Hide()
		end
	else
		PetStableCurrentPet:SetChecked(nil)
	end

	-- Set tooltip and icon info
	if ( GetPetIcon() and UnitCreatureFamily("pet") ) then
		SetItemButtonTexture(PetStableCurrentPet, GetPetIcon())
		name = UnitName("pet") or ""
		level = UnitLevel("pet")
		family = UnitCreatureFamily("pet") or ""
		talent = GetPetTalentTree() or ""
		PetStableCurrentPet.tooltip = name
		PetStableCurrentPet.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent)
	elseif ( GetStablePetInfo(0) ) then
		icon, name, level, family, talent = GetStablePetInfo(0)
        talent = talent or ""
		SetItemButtonTexture(PetStableCurrentPet, icon)
		PetStableCurrentPet.tooltip = name
		PetStableCurrentPet.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent)
	else
		SetItemButtonTexture(PetStableCurrentPet, "")
		PetStableCurrentPet.tooltip = EMPTY_STABLE_SLOT
		PetStableCurrentPet.tooltipSubtext = ""
		PetStableCurrentPet:SetChecked(nil)
	end
	if ( GameTooltip:IsOwned(PetStableCurrentPet) ) then
		GameTooltip:SetOwner(PetStableCurrentPet, "ANCHOR_RIGHT")
		GameTooltip:SetText(PetStableCurrentPet.tooltip)
		GameTooltip:AddLine(PetStableCurrentPet.tooltipSubtext, 1.0, 1.0, 1.0)
		GameTooltip:Show()
	end

	-- If no selected pet clear everything out
	if ( selectedPet == -1 ) then
		-- no pet
		PetStableModel:Hide()
		PetStableLevelText:SetText("")
	end

	-- Enable, disable, or hide purchase button
	PetStablePurchaseButton:Show()
	if ( GetNumStableSlots() == NUM_PET_STABLE_SLOTS or (not IsAtStableMaster())) then
		PetStablePurchaseButton:Hide()
		PetStableCostLabel:Hide()
		PetStableCostMoneyFrame:Hide()
		PetStableSlotText:Hide()
	elseif ( GetMoney() >= GetNextStableSlotCost() ) then
		PetStablePurchaseButton:Show()
		PetStablePurchaseButton:Enable()
		PetStableCostLabel:Show()
		PetStableCostMoneyFrame:Show()
		PetStableSlotText:Show()
		SetMoneyFrameColor("PetStableCostMoneyFrame", "white")
	else
		PetStablePurchaseButton:Show()
		PetStablePurchaseButton:Disable()
		PetStableCostLabel:Show()
		PetStableCostMoneyFrame:Show()
		PetStableSlotText:Show()
		SetMoneyFrameColor("PetStableCostMoneyFrame", "red")
	end
end

function PetStable_NoPetsAllowed()
	local button;
	for i=1, NUM_PET_STABLE_SLOTS do
		button = _G["PetStableStabledPet"..i];
		button.tooltip = EMPTY_STABLE_SLOT;
		button:SetChecked(nil);
	end
	
	PetStableCurrentPet:SetChecked(nil);
	PetStableLevelText:SetText("");
	PetStableModel:Hide();
	SetItemButtonTexture(PetStableCurrentPet, "");
	PetStableCurrentPet.tooltip = EMPTY_STABLE_SLOT;
	PetStableCurrentPet:SetChecked(nil);
	PetStablePurchaseButton:Hide();
	PetStableCostLabel:Hide();
	PetStableCostMoneyFrame:Hide();
	PetStableSlotText:Hide();
end

function PetStableSlot_DeletePet(self)
	local slotButton = self:GetParent()
	local slotID = slotButton:GetID()
	if slotID > 4 or slotID < 1 then
		return
	end
	
	local _, name = GetStablePetInfo(slotID)
	StaticPopup_Show("CONFIRM_DELETE_STABLED_PET", name, strupper(PET_ABANDON), slotID)
end