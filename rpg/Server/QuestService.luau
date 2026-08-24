--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Quests = require(Shared:WaitForChild("QuestDefinitions"))

local QuestService = {}
local profiles
local progression
local inventory
local notify
local sync

function QuestService.Init(profileService, progressionService, inventoryService, notifier, synchronize)
	profiles, progression, inventory, notify, sync = profileService, progressionService, inventoryService, notifier, synchronize
end

function QuestService.Accept(player, questId)
	local profile = profiles.Get(player)
	local quest = Quests[questId]
	if not profile or not quest or profile.Level < quest.MinLevel then return false, "Missão indisponível." end
	if profile.ActiveQuests[questId] then return false, "Missão já está ativa." end
	if profile.CompletedQuests[questId] and not quest.Daily then return false, "Missão já foi concluída." end
	if quest.Daily and profile.DailyCompletions[questId] and os.time() - profile.DailyCompletions[questId] < Config.DailyQuestResetHours * 3600 then
		return false, "A missão diária ainda não reiniciou."
	end
	local activeCount = 0
	for _ in pairs(profile.ActiveQuests) do activeCount += 1 end
	if activeCount >= Config.MaxActiveQuests then return false, "Limite de missões ativas atingido." end
	profile.ActiveQuests[questId] = { Progress = 0, AcceptedAt = os.time() }
	notify(player, "Quest", "Nova missão: " .. quest.Name)
	sync(player)
	return true
end

function QuestService.Complete(player, questId)
	local profile = profiles.Get(player)
	local quest = Quests[questId]
	local active = profile and profile.ActiveQuests[questId]
	if not profile or not quest or not active or active.Progress < quest.Amount then return false end
	profile.ActiveQuests[questId] = nil
	profile.CompletedQuests[questId] = true
	if quest.Daily then profile.DailyCompletions[questId] = os.time() end
	profile.Gold += quest.Gold
	profile.Reputation += if quest.Story then 15 else 5
	for itemId, amount in pairs(quest.Items or {}) do inventory.Add(player, itemId, amount, true) end
	progression.AddXP(player, quest.XP, "Missão concluída")
	notify(player, "QuestComplete", "Missão concluída: " .. quest.Name .. " · +" .. tostring(quest.Gold) .. " ouro")
	sync(player)
	return true
end

function QuestService.Progress(player, objectiveType, target, amount)
	local profile = profiles.Get(player)
	if not profile then return end
	local completed = {}
	for questId, active in pairs(profile.ActiveQuests) do
		local quest = Quests[questId]
		if quest and quest.Type == objectiveType and (quest.Target == "Any" or quest.Target == target) then
			active.Progress = math.min(quest.Amount, active.Progress + (amount or 1))
			if active.Progress >= quest.Amount then table.insert(completed, questId) end
		end
	end
	for _, questId in ipairs(completed) do QuestService.Complete(player, questId) end
	sync(player)
end

function QuestService.Abandon(player, questId)
	local profile = profiles.Get(player)
	if not profile or not profile.ActiveQuests[questId] then return false end
	profile.ActiveQuests[questId] = nil
	notify(player, "Quest", "Missão abandonada.")
	sync(player)
	return true
end

return QuestService
