--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local action = remotes:WaitForChild("RPGAction")
local Config = require(ReplicatedStorage:WaitForChild("RPGEnhancements"):WaitForChild("EnhancementConfig"))
local Classes = require(ReplicatedStorage.Modules:WaitForChild("Classes"))
local dashAt, requestAt = {}, {}

local function notify(player: Player, title: string, message: string, kind: string)
	local remote = remotes:FindFirstChild("RPGNotification")
	if remote then remote:FireClient(player, title, message, kind) end
end

local function dash(player: Player)
	local now, character = os.clock(), player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local energy = player:GetAttribute("Energia") or 0
	if not humanoid or not root or humanoid.Health <= 0 or now - (dashAt[player] or 0) < Config.Combat.DashCooldown then return end
	if energy < Config.Combat.DashCost then notify(player, "Energia insuficiente", "Você precisa de energia para esquivar.", "warning"); return end
	dashAt[player] = now
	player:SetAttribute("Energia", energy - Config.Combat.DashCost)
	player:SetAttribute("Dashing", true)
	if _G.RegistrarUsoEnergia then _G.RegistrarUsoEnergia(player) end
	local direction = if humanoid.MoveDirection.Magnitude > .1 then humanoid.MoveDirection.Unit else root.CFrame.LookVector
	root.AssemblyLinearVelocity = Vector3.new(direction.X * Config.Combat.DashPower, root.AssemblyLinearVelocity.Y, direction.Z * Config.Combat.DashPower)
	task.delay(.22, function() if player.Parent then player:SetAttribute("Dashing", false) end end)
end

local function selectClass(player: Player, className: any)
	if type(className) ~= "string" or #className > 40 or not Classes.Get(className) then return end
	local previous = player:GetAttribute("Classe")
	if previous == className then return end
	if previous and previous ~= "Noone" and previous ~= "" then
		local money = player:GetAttribute("Dinheiro") or 0
		if money < Config.Progression.ClassChangeCost then notify(player, "Ouro insuficiente", "Trocar de classe custa 150 moedas.", "warning"); return end
		player:SetAttribute("Dinheiro", money - Config.Progression.ClassChangeCost)
	end
	player:SetAttribute("Classe", className)
	notify(player, "Classe escolhida", className .. " agora define seu estilo de combate.", "success")
end

action.OnServerEvent:Connect(function(player: Player, kind: any, value: any)
	if type(kind) ~= "string" or #kind > 30 then return end
	local now = os.clock()
	if now - (requestAt[player] or 0) < .08 then return end
	requestAt[player] = now
	if kind == "Dash" then dash(player)
	elseif kind == "Block" and type(value) == "boolean" then
		local character = player.Character
		if character then character:SetAttribute("Blocking", value); player:SetAttribute("Blocking", value) end
	elseif kind == "SelectClass" then selectClass(player, value)
	end
end)

Players.PlayerRemoving:Connect(function(player) dashAt[player], requestAt[player] = nil, nil end)
