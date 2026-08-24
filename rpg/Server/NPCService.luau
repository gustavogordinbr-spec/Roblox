--!strict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

local NPCService = {}
local combat
local quests
local notify
local sync

function NPCService.Init(combatService, questService, notifier, synchronize)
	combat, quests, notify, sync = combatService, questService, notifier, synchronize
end

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart
end

local function addNameplate(model)
	local root = model:FindFirstChild("Head") or getRoot(model)
	if not root or root:FindFirstChild("AuroraRPGNameplate") then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AuroraRPGNameplate"
	billboard.Size = UDim2.fromOffset(190, 44)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.Parent = root
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextStrokeTransparency = 0.35
	local rank = model:GetAttribute("RPGRank") or "Normal"
	local level = model:GetAttribute("RPGLevel") or 1
	label.TextColor3 = if rank == "Boss" then Color3.fromRGB(255, 97, 108) elseif rank == "Elite" then Color3.fromRGB(193, 123, 255) else Color3.fromRGB(229, 235, 245)
	label.Text = (if rank == "Boss" then "♛ " elseif rank == "Elite" then "◆ " else "") .. model.Name .. "  ·  Nv. " .. tostring(level)
	label.Parent = billboard
end

local function addInteraction(model, role)
	local root = getRoot(model)
	if not root or root:FindFirstChild("AuroraRPGInteraction") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AuroraRPGInteraction"
	prompt.ObjectText = model.Name
	prompt.ActionText = if role == "Merchant" then "Comerciar" elseif role == "QuestGiver" then "Ver missões" else "Conversar"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.25
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		if role == "QuestGiver" then quests.Progress(player, "Talk", "Guide", 1) end
		notify(player, "Open" .. role, model.Name)
		sync(player)
	end)
end

function NPCService.Register(model)
	if not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then return end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or model:GetAttribute("RPGRegistered") then return end
	model:SetAttribute("RPGRegistered", true)
	local lower = model.Name:lower()
	local existingRole = model:GetAttribute("RPGRole")
	local role = existingRole
	if not role then
		if lower:find("shop") or lower:find("merchant") or lower:find("vendor") or lower:find("seller") then
			role = "Merchant"
		elseif lower:find("quest") or lower:find("guide") or lower:find("trainer") or lower:find("civilian") then
			role = "QuestGiver"
		elseif lower:find("villain") or lower:find("enemy") or lower:find("bandit") or lower:find("nomu") or lower:find("boss") or lower:find("thug") or lower:find("criminal") then
			role = "Enemy"
		else
			role = if humanoid.MaxHealth >= 250 then "Enemy" else "QuestGiver"
		end
	end
	model:SetAttribute("RPGRole", role)
	if role == "Enemy" then
		combat.RegisterEnemy(model, nil, if lower:find("boss") then "Boss" else nil)
		addNameplate(model)
	else
		addInteraction(model, role)
	end
end

function NPCService.ScanExistingWorld()
	if not Config.AutoIntegrateNPCs then return end
	local roots = {}
	local world = workspace:FindFirstChild("World")
	if world then
		for _, folderName in ipairs({ "Entities", "Interactable", "MissionsObjects", "Spawns" }) do
			local folder = world:FindFirstChild(folderName)
			if folder then table.insert(roots, folder) end
		end
	end
	for _, folderName in ipairs({ "Alive", "NPCs", "Enemies", "Villains" }) do
		local folder = workspace:FindFirstChild(folderName)
		if folder then table.insert(roots, folder) end
	end
	local integrated = 0
	for _, root in ipairs(roots) do
		for _, child in ipairs(root:GetChildren()) do
			if integrated >= Config.MaxAutoNPCs then break end
			if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
				NPCService.Register(child)
				integrated += 1
			elseif child:IsA("Folder") then
				for _, nested in ipairs(child:GetChildren()) do
					if integrated >= Config.MaxAutoNPCs then break end
					if nested:IsA("Model") and nested:FindFirstChildOfClass("Humanoid") then NPCService.Register(nested); integrated += 1 end
				end
			end
		end
		root.ChildAdded:Connect(function(child)
			if child:IsA("Model") then task.defer(NPCService.Register, child) end
		end)
	end
	for _, tagged in ipairs(CollectionService:GetTagged("RPGNPC")) do NPCService.Register(tagged) end
	for _, tagged in ipairs(CollectionService:GetTagged("RPGEnemy")) do NPCService.Register(tagged) end
	CollectionService:GetInstanceAddedSignal("RPGNPC"):Connect(NPCService.Register)
	CollectionService:GetInstanceAddedSignal("RPGEnemy"):Connect(NPCService.Register)
	print("[AuroraRPG] NPCs existentes integrados:", integrated)
end

return NPCService
