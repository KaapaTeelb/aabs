DOTA_GAMEMODE_5V5 = 0
DOTA_GAMEMODE_4V4V4V4 = 1

DOTA_GAMEMODE_TYPE_ALLPICK = 100
DOTA_GAMEMODE_TYPE_RANKED_ALLPICK = 101
DOTA_GAMEMODE_TYPE_RANDOM_OMG = 102
DOTA_GAMEMODE_TYPE_ABILITY_SHOP = 103

ARENA_GAMEMODE_MAP_NONE = 200
ARENA_GAMEMODE_MAP_CUSTOM_ABILITIES = 201

DOTA_ACTIVE_GAMEMODE = DOTA_GAMEMODE_5V5
DOTA_ACTIVE_GAMEMODE_TYPE = DOTA_GAMEMODE_TYPE_ALLPICK
ARENA_ACTIVE_GAMEMODE_MAP = ARENA_GAMEMODE_MAP_NONE

if GameModes == nil then
	_G.GameModes = class({})

	GameModes.MapNamesToGamemode = {
		["5v5"] = {gamemode = DOTA_GAMEMODE_5V5, type = DOTA_GAMEMODE_TYPE_ALLPICK, map = ARENA_GAMEMODE_MAP_NONE},
		["4v4v4v4"] = {gamemode = DOTA_GAMEMODE_4V4V4V4, type = DOTA_GAMEMODE_TYPE_ALLPICK, map = ARENA_GAMEMODE_MAP_NONE},
		["5v5_custom_abilities"] = {gamemode = DOTA_GAMEMODE_5V5, type = nil, map = ARENA_GAMEMODE_MAP_CUSTOM_ABILITIES},
		["4v4v4v4_custom_abilities"] = {gamemode = DOTA_GAMEMODE_4V4V4V4, type = nil, map = ARENA_GAMEMODE_MAP_CUSTOM_ABILITIES},
		["ranked"] = {gamemode = DOTA_GAMEMODE_5V5, type = DOTA_GAMEMODE_TYPE_RANKED_ALLPICK, map = ARENA_GAMEMODE_MAP_NONE},
	}

	GameModes.Settings = {
		[ARENA_GAMEMODE_MAP_CUSTOM_ABILITIES] = {
			onPreload = function()
				for k,t in pairs(DROP_TABLE) do
					for i,info in ipairs(t) do
						if string.starts(info.Item, "item_god_transform_") then
							table.remove(DROP_TABLE[k], i)
						end
					end
				end
			end,
		},
		[DOTA_GAMEMODE_4V4V4V4] = {
			onPreload = function()
				MAP_LENGTH = 9216
				USE_AUTOMATIC_PLAYERS_PER_TEAM = false
				MAX_NUMBER_OF_TEAMS = 4
				CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 4
				CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS] = 4
				CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_1] = 4
				CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_2] = 4
				USE_CUSTOM_TEAM_COLORS = true
			end,
		},
	}
end

local mapName = GetMapName()
if GameModes.MapNamesToGamemode[mapName] then
	DOTA_ACTIVE_GAMEMODE = GameModes.MapNamesToGamemode[mapName].gamemode
	DOTA_ACTIVE_GAMEMODE_TYPE = GameModes.MapNamesToGamemode[mapName].type
	ARENA_ACTIVE_GAMEMODE_MAP = GameModes.MapNamesToGamemode[mapName].map
end

function GameModes:Preload()
	GameModes:PreloadGamemodeSettingsFromTable(GameModes.Settings[DOTA_ACTIVE_GAMEMODE])
	GameModes:PreloadGamemodeSettingsFromTable(GameModes.Settings[DOTA_ACTIVE_GAMEMODE_TYPE])
	GameModes:PreloadGamemodeSettingsFromTable(GameModes.Settings[ARENA_ACTIVE_GAMEMODE_MAP])
end

function GameModes:PreloadGamemodeSettingsFromTable(t)
	if not t then return end
	if t.requirements and type(t.requirements) == "table" then
		for _,v in ipairs(t.requirements) do
			require(v)
		end
	end
	if t.onPreload then
		t.onPreload()
	end
end

function GameModes:OnAllVotesSubmitted()
	local kl_sum = 0
	local kl_count = 0
	local GMTypeVotes = {
		[DOTA_GAMEMODE_TYPE_ABILITY_SHOP] = 0
	}
	for _,v in pairs(PLAYER_DATA) do
		if v.GameModeVote then
			kl_sum = kl_sum + v.GameModeVote
			kl_count = kl_count + 1
		end
		if v.GameModeTypeVote then
			GMTypeVotes[v.GameModeTypeVote] = (GMTypeVotes[v.GameModeTypeVote] or 0) + 1
		end
	end
	local kl_result
	if kl_count >= 1 then
		GameRules:SetKillGoal(math.round(kl_sum / kl_count))
	else
		GameRules:SetKillGoal(DOTA_KILL_GOAL_VOTE_STANDART)
	end
	if ARENA_ACTIVE_GAMEMODE_MAP == ARENA_GAMEMODE_MAP_CUSTOM_ABILITIES then
		local key = next(GMTypeVotes)
		local max = GMTypeVotes[key]
		for k, v in pairs(GMTypeVotes) do
		    if GMTypeVotes[k] > max then
		        key, max = k, v
		    end
		end
		DOTA_ACTIVE_GAMEMODE_TYPE = key
		local tt = PlayerTables:GetTableValue("arena", "gamemode_settings")
		tt.gamemode_type = DOTA_ACTIVE_GAMEMODE_TYPE
		PlayerTables:SetTableValue("arena", "gamemode_settings", tt)
		if DOTA_ACTIVE_GAMEMODE_TYPE == DOTA_GAMEMODE_TYPE_ABILITY_SHOP then
			AbilityShop:PostAbilityData()
		end
		print("Gamemode " .. key .. " was selected because of " .. max .. " votes")
	end
end