--!strict
local Players = game:GetService("Players")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("RespawnRE")
local last = {}

remote.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if now - (last[player] or 0) < 3 then return end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then return end
	last[player] = now
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
