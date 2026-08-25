--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SprintEvent")
local config = require(ReplicatedStorage:WaitForChild("RPGEnhancements"):WaitForChild("EnhancementConfig")).Sprint
local active, lastToggle = {}, {}

local function stop(player: Player)
	active[player] = nil
	player:SetAttribute("Sprinting", false)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then humanoid.WalkSpeed = math.clamp(tonumber(player:GetAttribute("VelocidadeWalk")) or 16, 8, 40) end
end

remote.OnServerEvent:Connect(function(player: Player, requested: any)
	if type(requested) ~= "boolean" then return end
	local now = os.clock()
	if now - (lastToggle[player] or 0) < .12 then return end
	lastToggle[player] = now
	if not requested then stop(player); return end
	local character, energy = player.Character, player:GetAttribute("Energia")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or type(energy) ~= "number" or energy < config.MinimumEnergy then return end
	active[player] = true
	player:SetAttribute("Sprinting", true)
	humanoid.WalkSpeed = math.clamp(tonumber(player:GetAttribute("VelocidadeSprint")) or 24, 12, 60)
end)

Players.PlayerAdded:Connect(function(player) player.CharacterAdded:Connect(function() stop(player) end) end)
Players.PlayerRemoving:Connect(function(player) active[player], lastToggle[player] = nil, nil end)

while task.wait(config.Tick) do
	for player in pairs(active) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local energy = player:GetAttribute("Energia")
		if not humanoid or humanoid.Health <= 0 or type(energy) ~= "number" or energy <= 0 then stop(player); continue end
		if humanoid.MoveDirection.Magnitude > .05 then
			player:SetAttribute("Energia", math.max(0, energy - config.DrainPerSecond * config.Tick))
			if _G.RegistrarUsoEnergia then _G.RegistrarUsoEnergia(player) end
		end
	end
end
