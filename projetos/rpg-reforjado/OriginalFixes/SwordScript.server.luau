--!strict
-- Há dois SwordScript idênticos na ferramenta original; somente um controlador deve rodar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local tool = script.Parent
if tool:GetAttribute("RPGSwordController") then return end
tool:SetAttribute("RPGSwordController", true)
local handle = tool:WaitForChild("Handle", 10)
if not handle or not handle:IsA("BasePart") then return end
local animations = ReplicatedStorage:WaitForChild("RPGEnhancements"):WaitForChild("Animations")
local combat = require(ReplicatedStorage.RPGEnhancements.EnhancementConfig).Combat
local wielder, character, humanoid = nil, nil, nil
local attackUntil, attackAt, combo = 0, 0, 0
local hitAt = {}

local function playSound(name: string)
	local sound = handle:FindFirstChild(name)
	if sound and sound:IsA("Sound") then sound:Play() end
end

local function tag(target: Humanoid, player: Player)
	local previous = target:FindFirstChild("creator")
	if previous then previous:Destroy() end
	local value = Instance.new("ObjectValue")
	value.Name, value.Value, value.Parent = "creator", player, target
	Debris:AddItem(value, 4)
end

tool.Equipped:Connect(function()
	character = tool.Parent
	wielder = character and Players:GetPlayerFromCharacter(character)
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	playSound("Unsheath")
end)

tool.Unequipped:Connect(function() wielder, character, humanoid = nil, nil, nil; attackUntil = 0; combo = 0 end)

tool.Activated:Connect(function()
	local now = os.clock()
	if not wielder or not humanoid or humanoid.Health <= 0 or now - attackAt < .42 then return end
	combo = if now - attackAt > 1.4 then 1 else combo % 5 + 1
	attackAt, attackUntil = now, now + .36
	playSound(if combo == 5 then "SwordLunge" else "SwordSlash")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	local animation = animations:FindFirstChild("QuirkSword" .. combo)
	if animator and animation then
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		if ok and track then track.Priority = Enum.AnimationPriority.Action; pcall(function() track:Play(.06) end) end
	end
end)

handle.Touched:Connect(function(part: BasePart)
	local now = os.clock()
	if not wielder or not character or now > attackUntil then return end
	local targetModel = part:FindFirstAncestorOfClass("Model")
	local target = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetModel and (targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart)
	if not target or not root or not targetRoot or target.Health <= 0 or targetModel == character then return end
	if now - (hitAt[target] or 0) < .36 or (targetRoot.Position - root.Position).Magnitude > 11 then return end
	if Players:GetPlayerFromCharacter(targetModel) and not combat.PvPEnabled then return end
	hitAt[target] = now
	local base = math.max(1, tonumber(wielder:GetAttribute("DanoBaseFisico")) or tonumber(wielder:GetAttribute("DanoBase")) or 10)
	local damage = base * (if combo == 5 then 1.6 else 1 + combo * .08)
	damage *= 100 / (100 + math.max(0, tonumber(targetModel:GetAttribute("Defesa")) or 0))
	if math.random() < math.clamp(tonumber(wielder:GetAttribute("CriticoChance")) or .05, 0, .75) then damage *= math.clamp(tonumber(wielder:GetAttribute("CriticoMultiplicador")) or 1.5, 1, 3) end
	if targetModel:GetAttribute("Blocking") then damage *= 1 - combat.BlockReduction end
	tag(target, wielder)
	target:TakeDamage(math.max(1, math.floor(damage)))
	local counter = wielder:FindFirstChild("Combo")
	if counter and counter:IsA("IntValue") then counter.Value += 1 end
end)
