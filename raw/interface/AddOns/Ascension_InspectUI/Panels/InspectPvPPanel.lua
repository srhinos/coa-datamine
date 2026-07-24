InspectPvPPanelMixin = {}

function InspectPvPPanelMixin:OnLoad()
    self.Background:SetAtlas("inspect-pvp-background", Const.TextureKit.IgnoreAtlasSize)
    self.arenaFrames = { self.Arena2v2, self.Arena3v3, self.Arena1v1 }
end

function InspectPvPPanelMixin:OnShow()
    self:RegisterEvent("INSPECT_HONOR_UPDATE")
    if not HasInspectHonorData() then
        RequestInspectHonorData()
    else
        self:Update()
    end
end 

function InspectPvPPanelMixin:OnHide()
    self:UnregisterEvent("INSPECT_HONOR_UPDATE")
end

function InspectPvPPanelMixin:Update()
    local todayHK, todayHonor, yesterdayHK, yesterdayHonor, lifetimeHK, lifetimeRank = GetInspectHonorData()
    self.HonorableKills.Text:SetFormattedText("%s: |cffffffff%s|r", HONORABLE_KILLS, lifetimeHK)

    local teams = {}
    teams[1] = {size = 2, rating = 0, wins = 0, losses = 0 }
    teams[2] = {size = 3, rating = 0, wins = 0, losses = 0 }
    teams[3] = {size = 5, rating = 0, wins = 0, losses = 0 } -- 1v1

    local _, teamSize, teamRating, teamPlayed, teamWins
    for _, team in pairs(teams) do
        for i = 1, MAX_ARENA_TEAMS do
            _, teamSize, teamRating, teamPlayed, teamWins = GetInspectArenaTeamData(i)
            if team.size == teamSize then
                team.rating = teamRating
                team.wins = teamWins
                team.losses = teamPlayed - teamWins
            end
        end
    end

    local ratingName, ratingIcon, team
    for i, arenaFrame in ipairs(self.arenaFrames) do
        team = teams[i]
        ratingName, _, _, _, _, ratingIcon = C_PVP:GetPVPTierInfo(team.rating)
        arenaFrame.Rating:SetText(team.rating)
        arenaFrame.Record:SetFormattedText("%s - %s", team.wins, team.losses)
        arenaFrame.RankIcon:SetTexture(ratingIcon)
        arenaFrame.Rank:SetText(ratingName)
    end
end

function InspectPvPPanelMixin:OnEvent()
    self:Update()
end 