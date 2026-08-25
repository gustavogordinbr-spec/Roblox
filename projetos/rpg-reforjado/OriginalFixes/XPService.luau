--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfig"))
local XPConfig = require(Modules:WaitForChild("XPConfig"))
local Stats = require(Modules:WaitForChild("Stats"))
local XPService = {MaxLevel = XPConfig.HardCap}

local function getRank(level: number): string
	if level >= 120 then return "S" end
	if level >= 70 then return "A" end
	if level >= 35 then return "B" end
	if level >= 15 then return "C" end
	return "D"
end

function XPService.LevelUp(player: Player, levelsGained: number?)
	if not RunService:IsServer() or not player or not player:IsA("Player") then return end
	local previous = math.max(1, math.floor(player:GetAttribute("Level") or 1))
	local gained = math.max(0, math.floor(levelsGained or 1))
	local current = math.min(previous + gained, XPService.MaxLevel)
	if current <= previous then return end
	local actual = current - previous
	player:SetAttribute("Level", current)
	player:SetAttribute("PlayerRank", getRank(current))
	player:SetAttribute("AttributePoints", (player:GetAttribute("AttributePoints") or 0) + actual * 3)
	local notifier = game:GetService("ServerStorage"):FindFirstChild("LevelUpNotifier")
	if notifier and notifier:IsA("BindableEvent") then notifier:Fire(player, previous, current) end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("LevelUp")
	if remote and remote:IsA("RemoteEvent") then remote:FireClient(player, current, actual) end
end

function XPService.AddXP(player: Player, amount: number)
	if not RunService:IsServer() or not player or not player:IsA("Player") then return false end
	if type(amount) ~= "number" or amount ~= amount or amount == math.huge or amount <= 0 then return false end
	local level = math.clamp(math.floor(player:GetAttribute("Level") or 1), 1, XPService.MaxLevel)
	if level >= XPService.MaxLevel then player:SetAttribute("XP", 0); return false end
	local current = math.max(0, player:GetAttribute("XP") or 0)
	local newLevel, remaining = XPConfig.CalcularSubidas(level, current + math.min(amount, 100000000))
	player:SetAttribute("XP", remaining)
	if newLevel > level then XPService.LevelUp(player, newLevel - level) end
	return true
end

function XPService.RewardPlayer(player: Player, rewards: {[string]: any})
	if type(rewards) ~= "table" then return end
	for key, value in pairs(rewards) do
		if key == "XP" and type(value) == "number" and value > 0 then
			XPService.AddXP(player, value)
		elseif key == "Level" and type(value) == "number" and value > 0 then
			XPService.LevelUp(player, value)
		elseif (key == "Money" or key == "Gold" or key == "Dinheiro") and type(value) == "number" and value > 0 then
			Stats.AddAttributeSafe(player, "Dinheiro", value)
		elseif key == "Stats" and type(value) == "table" then
			for stat, amount in pairs(value) do if type(amount) == "number" then Stats.AddAttributeSafe(player, stat, amount) end end
		elseif type(value) == "number" and value ~= 0 then
			Stats.AddAttributeSafe(player, key, value)
		end
	end
end

function XPService.RewardForQuest(player: Player, xpAmount: number)
	return XPService.AddXP(player, xpAmount)
end

if RunService:IsServer() then
	local function initialize(player: Player)
		if player:GetAttribute("Level") == nil then player:SetAttribute("Level", 1) end
		if player:GetAttribute("XP") == nil then player:SetAttribute("XP", 0) end
		if player:GetAttribute("Dinheiro") == nil then player:SetAttribute("Dinheiro", 0) end
		if player:GetAttribute("Limitador") == nil then player:SetAttribute("Limitador", 100) end
		if player:GetAttribute("AttributePoints") == nil then player:SetAttribute("AttributePoints", 0) end
		if player:GetAttribute("PlayerRank") == nil then player:SetAttribute("PlayerRank", getRank(player:GetAttribute("Level") or 1)) end
		for name, base in pairs(GameConfig.BaseStats) do
			if name ~= "Energia" and player:GetAttribute(name) == nil then player:SetAttribute(name, base) end
		end
	end
	Players.PlayerAdded:Connect(initialize)
	for _, player in ipairs(Players:GetPlayers()) do task.defer(initialize, player) end
end

return XPService
