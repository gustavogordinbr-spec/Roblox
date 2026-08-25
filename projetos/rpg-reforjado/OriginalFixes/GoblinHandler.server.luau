--!strict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestService = require(ReplicatedStorage.Modules:WaitForChild("QuestService"))
local hooked = {}

local function monitor(model: Instance)
	if not model:IsA("Model") then return end
	local lower = string.lower(model.Name)
	if not string.find(lower, "goblin", 1, true) and not CollectionService:HasTag(model, "Goblin") then return end
	if not CollectionService:HasTag(model, "Goblin") then CollectionService:AddTag(model, "Goblin") end
	local humanoid = model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid", 3)
	if not humanoid or hooked[humanoid] then return end
	hooked[humanoid] = humanoid.Died:Connect(function()
		local creator = humanoid:FindFirstChild("creator")
		local player = creator and creator.Value
		if player and player:IsA("Player") and Players:GetPlayerByUserId(player.UserId) then QuestService.ProgressActive(player, "Goblin", 1) end
		if hooked[humanoid] then hooked[humanoid]:Disconnect(); hooked[humanoid] = nil end
	end)
end

local folder = workspace:FindFirstChild("NPCs")
if folder then
	for _, child in ipairs(folder:GetChildren()) do task.spawn(monitor, child) end
	folder.ChildAdded:Connect(function(child) task.defer(monitor, child) end)
end
for _, goblin in ipairs(CollectionService:GetTagged("Goblin")) do task.spawn(monitor, goblin) end
CollectionService:GetInstanceAddedSignal("Goblin"):Connect(monitor)
