--!strict
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local XPService = require(game:GetService("ReplicatedStorage").Modules:WaitForChild("XPService"))
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
		task.spawn(function()
			local root = model:FindFirstChild("HumanoidRootPart")
			local attackAt = 0
			while root and model.Parent and humanoid.Health > 0 do
				local chosen, distance = nil, 34
				for _, candidate in ipairs(Players:GetPlayers()) do
					local character = candidate.Character
					local candidateRoot = character and character:FindFirstChild("HumanoidRootPart")
					local candidateHumanoid = character and character:FindFirstChildOfClass("Humanoid")
					if candidateRoot and candidateHumanoid and candidateHumanoid.Health > 0 then
						local measured = (root.Position - candidateRoot.Position).Magnitude
						if measured < distance then chosen, distance = character, measured end
					end
				end
				if chosen then
					local targetRoot = chosen:FindFirstChild("HumanoidRootPart")
					local target = chosen:FindFirstChildOfClass("Humanoid")
					if targetRoot and target and distance < 4.5 and os.clock() - attackAt > 1.15 then
						attackAt = os.clock()
						local amount = (model:GetAttribute("EnemyLevel") or 1) * 5 + 12
						target:TakeDamage(if chosen:GetAttribute("Blocking") then math.floor(amount * .32) else amount)
					elseif targetRoot then humanoid:MoveTo(targetRoot.Position) end
				end
				task.wait(.3)
			end
		end)
	end
end

local folder = workspace:FindFirstChild("NPCs")
if folder then
	for _, model in ipairs(folder:GetChildren()) do task.defer(enhance, model) end
	folder.ChildAdded:Connect(function(model) task.delay(.25, enhance, model) end)
end
local bandit = workspace:FindFirstChild("Bandit")
if bandit then task.defer(enhance, bandit) end
