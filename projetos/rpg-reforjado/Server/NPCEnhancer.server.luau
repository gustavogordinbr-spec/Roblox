--!strict
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XPService = require(ReplicatedStorage.Modules:WaitForChild("XPService"))
local QuestService = require(ReplicatedStorage.Modules:WaitForChild("QuestService"))
local EnemyBrain = require(ReplicatedStorage:WaitForChild("RPGEnhancements"):WaitForChild("EnemyBrain"))
local tracked = {}

local function classify(model: Model): string
	local name = string.lower(model.Name)
	if string.find(name, "boss", 1, true) or string.find(name, "guard", 1, true) then return "Boss" end
	if string.find(name, "elite", 1, true) or string.find(name, "capit", 1, true) then return "Elite" end
	return "Normal"
end

local function enhance(model: Instance)
	if not model:IsA("Model") or tracked[model] or Players:GetPlayerFromCharacter(model) then return end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	tracked[model] = true
	local parent, spawn = model.Parent, model:GetPivot()
	local automatic = parent and parent.Name == "NPCs" and not model:FindFirstChild("Respawn")
	local template = if automatic and model.Archivable then model:Clone() else nil
	local tier = classify(model)
	model:SetAttribute("EnemyTier", tier)
	if model:GetAttribute("EnemyLevel") == nil then model:SetAttribute("EnemyLevel", if tier == "Boss" then 12 elseif tier == "Elite" then 6 else 2) end
	if model:GetAttribute("Defesa") == nil then model:SetAttribute("Defesa", if tier == "Boss" then 24 elseif tier == "Elite" then 12 else 4) end
	if not CollectionService:HasTag(model, "RPGEnemy") then CollectionService:AddTag(model, "RPGEnemy") end
	humanoid.Died:Connect(function()
		local creator = humanoid:FindFirstChild("creator")
		local killer = creator and creator.Value
		if killer and killer:IsA("Player") and not model:FindFirstChild("Reward") then
			local enemyLevel = math.max(1, tonumber(model:GetAttribute("EnemyLevel")) or 1)
			XPService.RewardPlayer(killer, {XP = 18 * enemyLevel, Dinheiro = 6 * enemyLevel})
		end
		if killer and killer:IsA("Player") and not humanoid:GetAttribute("QuestProgressCredited") then
			humanoid:SetAttribute("QuestProgressCredited", true)
			QuestService.ProgressActive(killer, model:GetAttribute("QuestTarget") or model.Name, 1)
		end
		if tier == "Boss" then
			local event = ServerStorage:FindFirstChild("BossMorto")
			if creator and creator.Value and event and event:IsA("BindableEvent") then event:Fire(creator.Value, model) end
		end
		if template and parent then
			task.delay(10, function()
				if not parent.Parent then return end
				local replacement = template:Clone()
				replacement:PivotTo(spawn)
				replacement.Parent = parent
			end)
		end
		task.delay(2, function() tracked[model] = nil end)
	end)
	if automatic and not model:FindFirstChild("Follow") and not model:FindFirstChild("AI") then
		local enemyLevel = math.max(1, tonumber(model:GetAttribute("EnemyLevel")) or 1)
		EnemyBrain.Bind(model, {
			Tier = tier, BaseDamage = 12 + enemyLevel * 5,
			AggroRange = if tier == "Boss" then 55 elseif tier == "Elite" then 45 else 36,
			ChaseSpeed = if tier == "Boss" then 18 elseif tier == "Elite" then 17 else 15,
			LeashRange = if tier == "Boss" then 115 else 85,
			AttackCooldown = if tier == "Boss" then .88 else 1.12,
		})
	end
end

local folder = workspace:FindFirstChild("NPCs")
if folder then
	for _, model in ipairs(folder:GetChildren()) do task.defer(enhance, model) end
	folder.ChildAdded:Connect(function(model) task.delay(.25, enhance, model) end)
end
local bandit = workspace:FindFirstChild("Bandit")
if bandit then task.defer(enhance, bandit) end
