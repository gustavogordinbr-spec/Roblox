--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modules = ReplicatedStorage:WaitForChild("Modules")
local Stats = require(modules:WaitForChild("Stats"))
local Racas = require(modules:WaitForChild("Racas"))
local Classes = require(modules:WaitForChild("Classes"))
local oldMax, connections, queued = {}, {}, {}

local function preserve(current: any, previous: any, maximum: number): number
	maximum = math.max(1, maximum)
	if type(current) ~= "number" or type(previous) ~= "number" or previous <= 0 then return maximum end
	return math.clamp(math.floor(maximum * math.clamp(current / previous, 0, 1)), 0, maximum)
end

local function apply(player: Player)
	queued[player] = nil
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local level = math.max(1, tonumber(player:GetAttribute("Level")) or 1)
	local limiter = tonumber(player:GetAttribute("Limitador")) or 100
	if not Stats.ValidarLimitador(limiter) then limiter = 100 end
	local race = Racas.Get(player:GetAttribute("Raca")) or Racas.Get("Humano")
	local class = Classes.Get(player:GetAttribute("Classe"))
	local multipliers = {}
	for key, value in pairs(race.Multiplicadores or {}) do multipliers[key] = value end
	if class then
		for key, value in pairs(class.Multiplicadores or {}) do multipliers[key] = (multipliers[key] or 1) * value end
	end
	local base = Stats.CalcularBase(Stats.LevelComLimitador(level, limiter), multipliers, limiter)
	-- Todos os atributos crescem exclusivamente com o nível, a raça e a classe.
	local derived = Stats.CalcularDerivados(base, player)
	derived.VidaMax = math.max(1, math.floor(derived.VidaMax * (multipliers.Vida or 1)))
	derived.DanoBaseFisico = math.max(1, math.floor(derived.DanoBaseFisico * (multipliers.Dano or 1)))
	derived.DanoBaseMagico = math.max(1, math.floor(derived.DanoBaseMagico * (multipliers.DanoMagico or 1)))
	derived.Defesa = math.max(0, math.floor(derived.Defesa * (multipliers.Defesa or 1)))
	derived.CriticoChance = math.clamp(derived.CriticoChance * (multipliers.CriticoChance or 1), 0, .8)
	derived.VidaRegen *= multipliers.VidaRegen or 1
	derived.EnergiaRegen *= multipliers.EnergiaRegen or 1

	local oldHealth, previousHealthMax = humanoid.Health, humanoid.MaxHealth
	humanoid.MaxHealth = math.max(1, derived.VidaMax)
	humanoid.Health = if oldHealth <= 0 then 0 else math.max(1, preserve(oldHealth, previousHealthMax, humanoid.MaxHealth))
	local previousEnergy = player:GetAttribute("Energia")
	local previousMaximum = oldMax[player]
	player:SetAttribute("EnergiaMax", math.max(1, derived.EnergiaMax))
	player:SetAttribute("Energia", if previousMaximum then preserve(previousEnergy, previousMaximum, derived.EnergiaMax) else derived.EnergiaMax)
	oldMax[player] = derived.EnergiaMax
	if not player:GetAttribute("Sprinting") then humanoid.WalkSpeed = derived.VelocidadeWalk end
	humanoid.JumpPower = derived.JumpPower
	for name, value in pairs(base) do
		-- Energia é a barra atual; o atributo-base recebe um nome independente.
		player:SetAttribute(if name == "Energia" then "EnergiaBase" else name, math.floor(value))
	end
	for name, value in pairs(derived) do player:SetAttribute(name, value) end
	-- A espada original consulta DanoBase; preservamos essa API de compatibilidade.
	player:SetAttribute("DanoBase", derived.DanoBaseFisico)
	player:SetAttribute("DanoMagico", derived.DanoBaseMagico)
	player:SetAttribute("RacePassive", race.Passiva or "")
	player:SetAttribute("RaceRarity", race.Raridade or "Comum")
	player:SetAttribute("RaceAffinity", race.Afinidade or "Equilíbrio")
	if class then player:SetAttribute("ClassAbility", class.Habilidade); player:SetAttribute("ClassType", class.Tipo) end
end

local function schedule(player: Player)
	if queued[player] then return end
	queued[player] = true
	task.defer(apply, player)
end

local function connect(player: Player)
	if connections[player] then return end
	if player:GetAttribute("Level") == nil then player:SetAttribute("Level", 1) end
	if player:GetAttribute("Raca") == nil then player:SetAttribute("Raca", "Humano") end
	if player:GetAttribute("Limitador") == nil then player:SetAttribute("Limitador", 100) end
	connections[player] = {}
	for _, name in ipairs({"Level", "Raca", "Classe", "Limitador"}) do
		table.insert(connections[player], player:GetAttributeChangedSignal(name):Connect(function() schedule(player) end))
	end
	table.insert(connections[player], player.CharacterAdded:Connect(function(character) character:WaitForChild("Humanoid", 10); schedule(player) end))
	if player.Character then schedule(player) end
end

Players.PlayerAdded:Connect(connect)
for _, player in ipairs(Players:GetPlayers()) do task.defer(connect, player) end
Players.PlayerRemoving:Connect(function(player)
	for _, connection in ipairs(connections[player] or {}) do connection:Disconnect() end
	connections[player], oldMax[player], queued[player] = nil, nil, nil
	Stats.CleanupPlayer(player)
end)
