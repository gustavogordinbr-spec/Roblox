--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("RPGRequestState")
local Classes = require(ReplicatedStorage.Modules:WaitForChild("Classes"))
local Quests = require(ReplicatedStorage.Modules:WaitForChild("QuestService"))
local Races = require(ReplicatedStorage.Modules:WaitForChild("Racas"))
local settings = require(ReplicatedStorage:WaitForChild("RPGEnhancements"):WaitForChild("EnhancementConfig"))
local last = {}

request.OnServerInvoke = function(player: Player)
	local now = os.clock()
	if now - (last[player] or 0) < .4 then return nil end
	last[player] = now
	local available = {}
	for id, quest in pairs(Quests.Quests) do
		table.insert(available, {Id = id, Name = quest.Name, Rank = quest.Rank, MinLevel = quest.MinLevel, Completed = player:GetAttribute(id .. "_AlreadyCompleted") == true, Reward = quest.Reward})
	end
	table.sort(available, function(a, b) return a.Id < b.Id end)
	local classes = {}
	for _, entry in ipairs(Classes.GetSorted()) do table.insert(classes, {Name = entry.Name, Type = entry.Data.Tipo, Rarity = entry.Data.Raridade, Description = entry.Data.Descricao, Ability = entry.Data.Habilidade}) end
	local races = {}
	for _, entry in ipairs(Races.GetSorted()) do table.insert(races, {Name = entry.Name, Rarity = entry.Data.Raridade, Passive = entry.Data.Passiva, Description = entry.Data.Descricao, Buffs = Races.GetBuffs(entry.Name)}) end
	return {Classes = classes, Quests = available, Races = races, Level = player:GetAttribute("Level") or 1, Rank = player:GetAttribute("PlayerRank") or "D", Version = settings.Version, AttributesScaleWithLevel = true}
end

Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
