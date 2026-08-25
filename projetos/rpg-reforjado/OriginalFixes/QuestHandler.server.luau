--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestService = require(ReplicatedStorage.Modules:WaitForChild("QuestService"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local lastRequest = {}

Remotes:WaitForChild("StartQuest").OnServerEvent:Connect(function(player: Player, questId: any)
	if typeof(questId) ~= "string" or #questId > 32 or not Players:GetPlayerByUserId(player.UserId) then return end
	local now = os.clock()
	if now - (lastRequest[player] or 0) < .65 then return end
	lastRequest[player] = now
	local ok, reason = QuestService.StartQuest(player, questId)
	if not ok and reason then
		local notify = Remotes:FindFirstChild("RPGNotification")
		if notify and notify:IsA("RemoteEvent") then notify:FireClient(player, "Missão indisponível", reason, "warning") end
	end
end)

Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
