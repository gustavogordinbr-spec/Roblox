--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local XPService = require(ReplicatedStorage.Modules:WaitForChild("XPService"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateQuestHUD = Remotes:WaitForChild("UpdateQuestHUD")
local QuestCompleted = Remotes:WaitForChild("QuestCompleted")
local QuestService = {}

QuestService.Quests = {
	quest_001 = {Name = "Problema Goblin", Description = "Derrote 5 goblins na floresta próxima", Amount = 5, Rank = "D", MinLevel = 1, Target = "Goblin", Reward = {XP = 200, Dinheiro = 50}},
	quest_002 = {Name = "Ervas para o Alquimista", Description = "Colete 3 ervas mágicas", Amount = 3, Rank = "D", MinLevel = 1, Target = "Erva", Reward = {XP = 180, Dinheiro = 40}},
	quest_003 = {Name = "Slimes no Pântano", Description = "Derrote 6 slimes corrosivos", Amount = 6, Rank = "D", MinLevel = 2, Target = "Slime", Reward = {XP = 260, Dinheiro = 65}},
	quest_004 = {Name = "Lobos Famintos", Description = "Derrote 4 lobos que rondam a estrada", Amount = 4, Rank = "D", MinLevel = 3, Target = "Lobo", Reward = {XP = 300, Dinheiro = 70}},
	quest_005 = {Name = "Goblins Armados", Description = "Derrote 6 goblins armados", Amount = 6, Rank = "C", MinLevel = 5, Target = "Goblin", Reward = {XP = 450, Dinheiro = 120}},
	quest_006 = {Name = "Slime Explosivo", Description = "Derrote 3 slimes instáveis", Amount = 3, Rank = "C", MinLevel = 7, Target = "Slime", Reward = {XP = 500, Dinheiro = 140}},
	quest_007 = {Name = "Caçada Noturna", Description = "Derrote 5 lobos sombrios", Amount = 5, Rank = "B", MinLevel = 10, Target = "Lobo", Reward = {XP = 550, Dinheiro = 150}},
	quest_008 = {Name = "Infestação na Mina", Description = "Derrote 8 insetos da mina", Amount = 8, Rank = "B", MinLevel = 12, Target = "Inseto", Reward = {XP = 600, Dinheiro = 170}},
	quest_009 = {Name = "Xamã Goblin", Description = "Derrote o xamã goblin e seus lacaios", Amount = 1, Rank = "A", MinLevel = 18, Target = "Xama", Reward = {XP = 850, Dinheiro = 260}},
	quest_010 = {Name = "Guardião da Caverna", Description = "Derrote o monstro que guarda a caverna", Amount = 1, Rank = "A", MinLevel = 22, Target = "Guardiao", Reward = {XP = 950, Dinheiro = 300}},
	quest_011 = {Name = "Aberração do Pântano", Description = "Derrote a criatura que emergiu do pântano", Amount = 1, Rank = "A", MinLevel = 26, Target = "Aberracao", Reward = {XP = 1100, Dinheiro = 350}},
	quest_012 = {Name = "Invasão Goblin", Description = "Derrote 3 capitães goblins", Amount = 3, Rank = "S", MinLevel = 35, Target = "CapitaoGoblin", Reward = {XP = 1500, Dinheiro = 600}},
	quest_013 = {Name = "O Lobo Ancião", Description = "Derrote o lobo ancestral da floresta", Amount = 1, Rank = "S", MinLevel = 40, Target = "LoboAnciao", Reward = {XP = 1800, Dinheiro = 750}},
	quest_014 = {Name = "Entidade Desperta", Description = "Derrote a entidade que despertou nas ruínas", Amount = 1, Rank = "S", MinLevel = 45, Target = "Entidade", Reward = {XP = 2200, Dinheiro = 900}},
	quest_015 = {Name = "Provação do Caçador", Description = "Derrote 5 elites diferentes", Amount = 5, Rank = "S", MinLevel = 50, Target = "Elite", Reward = {XP = 2600, Dinheiro = 1100}},
	quest_016 = {Name = "Lenda Viva", Description = "Derrote um inimigo lendário", Amount = 1, Rank = "S", MinLevel = 60, Target = "Lendario", Reward = {XP = 3200, Dinheiro = 1500}},
}

local progressByUser = {}
local function getData(player: Player)
	progressByUser[player.UserId] = progressByUser[player.UserId] or {}
	return progressByUser[player.UserId]
end

function QuestService.StartQuest(player: Player, questId: string): (boolean, string?)
	if not RunService:IsServer() or not player or type(questId) ~= "string" then return false, "Missão inválida." end
	local quest = QuestService.Quests[questId]
	if not quest then return false, "Missão não encontrada." end
	if player:GetAttribute("HasActiveQuest") then return false, "Conclua sua missão atual primeiro." end
	if player:GetAttribute(questId .. "_AlreadyCompleted") then return false, "Você já concluiu essa missão." end
	if (player:GetAttribute("Level") or 1) < quest.MinLevel then return false, "Nível " .. quest.MinLevel .. " necessário." end
	getData(player)[questId] = {Progress = 0, Completed = false}
	player:SetAttribute("HasActiveQuest", true)
	player:SetAttribute("ActiveQuestId", questId)
	player:SetAttribute("ActiveQuestRank", quest.Rank)
	player:SetAttribute("ActiveQuestProgress", 0)
	UpdateQuestHUD:FireClient(player, questId, 0, quest.Amount)
	return true, nil
end

function QuestService.UpdateProgress(player: Player, questId: string, amount: number?)
	if not RunService:IsServer() or not player or player:GetAttribute("ActiveQuestId") ~= questId then return false end
	local quest = QuestService.Quests[questId]
	local data = getData(player)[questId]
	if not quest or not data or data.Completed then return false end
	local increment = math.clamp(math.floor(tonumber(amount) or 1), 1, quest.Amount)
	data.Progress = math.clamp(data.Progress + increment, 0, quest.Amount)
	player:SetAttribute("ActiveQuestProgress", data.Progress)
	UpdateQuestHUD:FireClient(player, questId, data.Progress, quest.Amount)
	if data.Progress < quest.Amount then return true end
	data.Completed = true
	player:SetAttribute(questId .. "_AlreadyCompleted", true)
	player:SetAttribute("HasActiveQuest", false)
	player:SetAttribute("ActiveQuestId", nil)
	player:SetAttribute("ActiveQuestRank", nil)
	player:SetAttribute("ActiveQuestProgress", nil)
	XPService.RewardPlayer(player, quest.Reward)
	QuestCompleted:FireClient(player, questId, quest.Reward)
	local notification = Remotes:FindFirstChild("RPGNotification")
	if notification and notification:IsA("RemoteEvent") then notification:FireClient(player, "Missão concluída", quest.Name, "success") end
	return true
end

function QuestService.ProgressActive(player: Player, target: string, amount: number?)
	local questId = player:GetAttribute("ActiveQuestId")
	local quest = questId and QuestService.Quests[questId]
	if not quest then return false end
	local wanted, found = string.lower(quest.Target), string.lower(target or "")
	if wanted ~= found and not string.find(found, wanted, 1, true) and not string.find(wanted, found, 1, true) then return false end
	return QuestService.UpdateProgress(player, questId, amount)
end

function QuestService.GetProgress(player: Player, questId: string): (number, boolean)
	local data = getData(player)[questId]
	local current = if data then data.Progress else 0
	local completed = if data then data.Completed else player:GetAttribute(questId .. "_AlreadyCompleted") == true
	return current, completed
end

if RunService:IsServer() then Players.PlayerRemoving:Connect(function(player) progressByUser[player.UserId] = nil end) end
return QuestService
