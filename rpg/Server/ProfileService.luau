--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

local ProfileService = {}
local profiles = {}
local store = DataStoreService:GetDataStore(Config.DataStoreName)

local function clone(value)
	if typeof(value) ~= "table" then return value end
	local output = {}
	for key, child in pairs(value) do output[key] = clone(child) end
	return output
end

local function defaultProfile(player)
	return {
		Version = 2, UserId = player.UserId, Name = player.DisplayName,
		Class = "", Level = 1, Experience = 0,
		Gold = Config.StartingGold, Gems = Config.StartingGems, Reputation = 0,
		AttributePoints = Config.StartingAttributePoints,
		Attributes = { Strength = 5, Vitality = 5, Agility = 5, Intelligence = 5, Luck = 5 },
		Inventory = { TrainingBlade = 1, StarterVest = 1, HealthPotion = 3 },
		Equipped = { Weapon = "TrainingBlade", Armor = "StarterVest", Accessory = "" },
		ActiveQuests = {}, CompletedQuests = {}, DailyCompletions = {},
		UnlockedAbilities = {}, Hotbar = {}, WeaponMastery = {},
		ProfessionXP = { Alchemy = 0, Blacksmith = 0, Artifice = 0 },
		Achievements = {}, Titles = {}, EquippedTitle = "", LastDailyReward = 0,
		Kills = 0, BossKills = 0, PlayTime = 0, LastSeen = os.time(),
		Settings = { Music = true, Effects = true, ShowDamage = true },
	}
end

local function reconcile(target, template)
	for key, default in pairs(template) do
		if target[key] == nil then
			target[key] = clone(default)
		elseif typeof(default) == "table" and typeof(target[key]) == "table" then
			reconcile(target[key], default)
		end
	end
	return target
end

function ProfileService.Get(player)
	return profiles[player]
end

function ProfileService.Load(player)
	local template = defaultProfile(player)
	local success, result = pcall(function()
		return store:GetAsync("player_" .. tostring(player.UserId))
	end)
	if success and typeof(result) == "table" then
		profiles[player] = reconcile(result, template)
	else
		profiles[player] = template
		if not success then warn("[AuroraRPG] Salvamento indisponível, usando perfil local:", result) end
	end
	profiles[player].LastSeen = os.time()
	return profiles[player]
end

function ProfileService.Save(player)
	local profile = profiles[player]
	if not profile then return false end
	profile.LastSeen = os.time()
	local snapshot = clone(profile)
	local success, result = pcall(function()
		store:UpdateAsync("player_" .. tostring(player.UserId), function()
			return snapshot
		end)
	end)
	if not success then warn("[AuroraRPG] Não foi possível salvar:", player.Name, result) end
	return success
end

function ProfileService.Release(player)
	ProfileService.Save(player)
	profiles[player] = nil
end

function ProfileService.StartAutoSave()
	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(ProfileService.Save, player)
			end
		end
	end)
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do ProfileService.Save(player) end
	end)
end

return ProfileService
