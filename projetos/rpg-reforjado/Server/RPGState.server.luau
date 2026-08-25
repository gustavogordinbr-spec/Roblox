--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("RPGRequestState")
local Classes = require(ReplicatedStorage.Modules:WaitForChild("Classes"))
local Quests = require(ReplicatedStorage.Modules:WaitForChild("QuestService"))
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
	return {Classes = classes, Quests = available, Level = player:GetAttribute("Level") or 1, Rank = player:GetAttribute("PlayerRank") or "D", Version = "2.0.0"}
end

Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
