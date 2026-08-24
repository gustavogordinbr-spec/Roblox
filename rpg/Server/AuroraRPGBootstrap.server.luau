--!strict
-- Camada RPG aditiva: não remove ou substitui mapas, VFX, poderes e scripts existentes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("AuroraRPG")
local Shared = root:WaitForChild("Shared")
local Remotes = root:WaitForChild("Remotes")
local Config = require(Shared:WaitForChild("GameConfig"))

local services = script.Parent:WaitForChild("Services")
local Profiles = require(services:WaitForChild("ProfileService"))
local Progression = require(services:WaitForChild("ProgressionService"))
local Inventory = require(services:WaitForChild("InventoryService"))
local Quests = require(services:WaitForChild("QuestService"))
local Parties = require(services:WaitForChild("PartyService"))
local Combat = require(services:WaitForChild("CombatService"))
local NPCs = require(services:WaitForChild("NPCService"))
local World = require(services:WaitForChild("WorldService"))
local Crafting = require(services:WaitForChild("CraftingService"))
local Achievements = require(services:WaitForChild("AchievementService"))

local actionRemote = Remotes:WaitForChild("Action")
local stateRemote = Remotes:WaitForChild("StateChanged")
local notificationRemote = Remotes:WaitForChild("Notification")
local requestState = Remotes:WaitForChild("RequestState")
local rateLimit = {}

local function notify(player, kind, message)
	if player and player.Parent then notificationRemote:FireClient(player, kind, message) end
end

local function stateFor(player)
	local profile = Profiles.Get(player)
	if not profile then return nil end
	return {
		Version = Config.Version, Class = profile.Class, Level = profile.Level,
		Experience = profile.Experience, RequiredXP = Progression.RequiredXP(profile.Level),
		Gold = profile.Gold, Gems = profile.Gems, Reputation = profile.Reputation,
		AttributePoints = profile.AttributePoints, Attributes = profile.Attributes,
		Inventory = profile.Inventory, Equipped = profile.Equipped,
		ActiveQuests = profile.ActiveQuests, CompletedQuests = profile.CompletedQuests,
		UnlockedAbilities = profile.UnlockedAbilities, Hotbar = profile.Hotbar,
		Kills = profile.Kills, BossKills = profile.BossKills, PlayTime = profile.PlayTime,
		ProfessionXP = profile.ProfessionXP, Achievements = profile.Achievements,
		Titles = profile.Titles, EquippedTitle = profile.EquippedTitle,
		Party = Parties.GetSnapshot(player), Settings = profile.Settings,
	}
end

local function sync(player)
	if player and player.Parent then stateRemote:FireClient(player, stateFor(player)) end
end

Progression.Init(Profiles, notify, sync)
Inventory.Init(Profiles, notify, sync)
Quests.Init(Profiles, Progression, Inventory, notify, sync)
Parties.Init(notify, sync)
Combat.Init(Profiles, Progression, Inventory, Quests, Parties, notify, sync)
NPCs.Init(Combat, Quests, notify, sync)
World.Init(Profiles, Progression)
Crafting.Init(Profiles, Inventory, Progression, notify, sync)
Achievements.Init(Profiles, notify)
Inventory.SetCollectCallback(function(player, itemId, amount)
	Quests.Progress(player, "Collect", itemId, amount)
end)

local actions = {
	ChooseClass = function(player, data) return Progression.ChooseClass(player, data.Id) end,
	AllocateAttribute = function(player, data) return Progression.Allocate(player, data.Attribute) end,
	EquipItem = function(player, data) return Inventory.Equip(player, data.Id) end,
	UseItem = function(player, data) return Inventory.Use(player, data.Id) end,
	BuyItem = function(player, data) return Inventory.Buy(player, data.Id, data.Amount) end,
	SellItem = function(player, data) return Inventory.Sell(player, data.Id, data.Amount) end,
	AcceptQuest = function(player, data) return Quests.Accept(player, data.Id) end,
	AbandonQuest = function(player, data) return Quests.Abandon(player, data.Id) end,
	Attack = function(player, data) return Combat.Attack(player, data.Target, data.AttackType) end,
	UseAbility = function(player, data) return Combat.UseAbility(player, data.Id, data.Target) end,
	InviteParty = function(player, data) return Parties.Invite(player, data.Name) end,
	AcceptParty = function(player) return Parties.Accept(player) end,
	LeaveParty = function(player) return Parties.Leave(player) end,
	CraftItem = function(player, data) return Crafting.Craft(player, data.Id) end,
	EquipTitle = function(player, data)
		local success = Achievements.EquipTitle(player, data.Title)
		if success then sync(player) end
		return success
	end,
	ClaimDailyReward = function(player)
		local profile = Profiles.Get(player)
		if not profile then return false end
		if os.time() - profile.LastDailyReward < 24 * 3600 then return false, "Sua recompensa diária ainda não está disponível." end
		profile.LastDailyReward = os.time()
		profile.Gold += 120 + profile.Level * 8
		profile.Gems += 2
		Inventory.Add(player, "HealthPotion", 2, true)
		notify(player, "Daily", "Recompensa diária resgatada!")
		sync(player)
		return true
	end,
	UpdateSetting = function(player, data)
		local profile = Profiles.Get(player)
		if profile and profile.Settings[data.Key] ~= nil and typeof(data.Value) == "boolean" then profile.Settings[data.Key] = data.Value; sync(player); return true end
		return false
	end,
}

actionRemote.OnServerEvent:Connect(function(player, action, data)
	if typeof(action) ~= "string" or typeof(data) ~= "table" then return end
	local now = os.clock()
	local key = tostring(player.UserId) .. action
	if rateLimit[key] and now - rateLimit[key] < Config.RemoteCooldown then return end
	rateLimit[key] = now
	local handler = actions[action]
	if not handler or not Profiles.Get(player) then return end
	local ok, success, message = pcall(handler, player, data)
	if not ok then warn("[AuroraRPG] Falha na ação", action, success); return end
	if success == false and message then notify(player, "Warning", message) end
	if success ~= false and Achievements.Evaluate(player) then sync(player) end
end)

requestState.OnServerInvoke = function(player)
	local deadline = os.clock() + 12
	while not Profiles.Get(player) and os.clock() < deadline do task.wait(0.1) end
	return stateFor(player)
end

local function setupCharacter(player, character)
	task.wait(0.2)
	Progression.ApplyCharacter(player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			local profile = Profiles.Get(player)
			if not profile then return end
			local loss = math.floor(profile.Gold * Config.RespawnGoldLossPercent)
			profile.Gold -= loss
			if loss > 0 then notify(player, "Warning", "Você perdeu " .. tostring(loss) .. " ouro ao ser derrotado.") end
			sync(player)
		end)
	end
	sync(player)
end

local function playerAdded(player)
	Profiles.Load(player)
	player.CharacterAdded:Connect(function(character) setupCharacter(player, character) end)
	if player.Character then task.spawn(setupCharacter, player, player.Character) end
	task.delay(2, function()
		if player.Parent then
			notify(player, "Welcome", "Bem-vindo a " .. Config.GameName .. "!")
			if Profiles.Get(player) and Profiles.Get(player).Class == "" then notify(player, "ChooseClass", "Escolha sua classe para começar a jornada.") end
			sync(player)
		end
	end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
	Parties.Leave(player)
	Profiles.Release(player)
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(playerAdded, player) end

Profiles.StartAutoSave()
World.StartRegeneration()
World.SetupAtmosphere()
task.delay(3, NPCs.ScanExistingWorld)

print("[AuroraRPG] Camada de RPG iniciada com sucesso —", Config.GameName, Config.Version)
