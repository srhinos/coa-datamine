TicketCharacterChoiceMixin = CreateFromMixins("ScrollListItemBaseMixin")

function TicketCharacterChoiceMixin:OnLoad()
    self.Icon:SetBorderAtlas("GarrMission_PortraitRing")
    self.Icon:SetBorderSize(34, 34)
    self:SetHighlightAtlas("auctionhouse-ui-row-highlight")
end

function TicketCharacterChoiceMixin:DisplayCharacter(index)
    self.Icon:Show()
    self.FactionIcon:Show()
    self.Icon:SetPointOffset(0, 0)
    self.Icon:SetBorderOffset(1, -2)

    local characterInfo = C_AccountInfo.GetCharacterAtIndex(index)
    self.characterInfo = characterInfo
    self.Name:SetText(characterInfo.CharacterName)

    -- convert class 
    local class = CLASS_ENUM_TO_CLASS_FILE[characterInfo.Class] or characterInfo.Class:sub(7)
    local classColor = RAID_CLASS_COLORS[class] or HIGHLIGHT_FONT_COLOR
    local className = LOCALIZED_CLASS_NAMES_MALE[class] or UNKNOWN_OBJECT

    -- convert sex 
    local sex = characterInfo.Sex:sub(8)

    -- convert race 
    local race = characterInfo.Race:sub(6)
    if race == "UNDEAD_PLAYER" then
        race = "SCOURGE"
    end

    -- set icon to race + sex icon
    local coords = RACE_ICON_TCOORDS[race.."_"..sex]
    self.Icon:SetIcon("Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES_Round")
    self.Icon.Icon:SetTexCoord(unpack(coords))
    
    self.FactionIcon:SetAtlas(format("communities-create-button-wow-%s", characterInfo.Faction:lower()), Const.TextureKit.UseAtlasSize)

    -- set unit info
    self.UnitInfo:SetFormattedText(TOOLTIP_UNIT_LEVEL_CLASS, characterInfo.Level, classColor:WrapText(className))
end

function TicketCharacterChoiceMixin:DisplaySpecial(index)
    self.FactionIcon:Hide()
    self.Icon:SetIconAtlas("Garr_FollowerPortrait_Bg")
    self.Icon:SetBorderOffset(-0.5, -1)
    self.Icon:SetPointOffset(1.5, -2)
    if index == 1 then
        self.Name:SetText(TICKET_AFFECTED_CHARACTER_NONE_SHORT)
        self.UnitInfo:SetText(TICKET_AFFECTED_CHARACTER_NONE)
    elseif index == 2 then
        self.Name:SetText(TICKET_AFFECTED_CHARACTER_ALL_SHORT)
        self.UnitInfo:SetText(TICKET_AFFECTED_CHARACTER_ALL)
    end
end

function TicketCharacterChoiceMixin:Update()
    self:SetNormalAtlas(self.index % 2 == 0 and "auctionhouse-rowstripe-1" or "auctionhouse-rowstripe-2")
    local index = self.index
    local offset = index - 2
    if offset > 0 then
        self:DisplayCharacter(offset)
    else
        self:DisplaySpecial(index)
    end
end