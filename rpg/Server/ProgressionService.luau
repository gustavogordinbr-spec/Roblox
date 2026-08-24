--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Classes = require(Shared:WaitForChild("ClassDefinitions"))
local Abilities = require(Shared:WaitForChild("AbilityDefinitions"))

local ProgressionService = {}
local profiles
local notify
local sync

function ProgressionService.Init(profileService, notifier, synchronize)
	profiles, notify, sync = profileService, notifier, synchronize
end

function ProgressionService.RequiredXP(level)
	return math.floor(Config.ExperienceBase * (level ^ Config.ExperienceGrowth))
end

function ProgressionService.ApplyCharacter(player)
	local profile = profiles.Get(player)
	local character = player.Character
	if not profile or not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local previousMax = humanoid.MaxHealth
	local healthRatio = if previousMax > 0 then humanoid.Health / previousMax else 1
	humanoid.MaxHealth = Config.BaseHealth + profile.Attributes.Vitality * Config.HealthPerVitality + profile.Level * 4
	humanoid.Health = math.clamp(humanoid.MaxHealth * healthRatio, 1, humanoid.MaxHealth)
	character:SetAttribute("RPGLevel", profile.Level)
	character:SetAttribute("RPGClass", profile.Class)
	character:SetAttribute("RPGStrength", profile.Attributes.Strength)
	character:SetAttribute("RPGMaxMana", Config.BaseMana + profile.Attributes.Intelligence * Config.ManaPerIntelligence)
	character:SetAttribute("RPGMaxStamina", Config.BaseStamina + profile.Attributes.Agility * Config.StaminaPerAgility)
	if character:GetAttribute("RPGMana") == nil then character:SetAttribute("RPGMana", character:GetAttribute("RPGMaxMana")) end
	if character:GetAttribute("RPGStamina") == nil then character:SetAttribute("RPGStamina", character:GetAttribute("RPGMaxStamina")) end
	local existingStats = player:FindFirstChild("leaderstats")
	if not existingStats then
		existingStats = Instance.new("Folder")
		existingStats.Name = "leaderstats"
		existingStats.Parent = player
	end
	for _, pair in ipairs({ { "Nível", profile.Level }, { "Ouro", profile.Gold }, { "Renome", profile.Reputation } }) do
		local stat = existingStats:FindFirstChild(pair[1])
		if not stat then stat = Instance.new("IntValue"); stat.Name = pair[1]; stat.Parent = existingStats end
		stat.Value = pair[2]
	end
end

function ProgressionService.AddXP(player, amount, reason)
	local profile = profiles.Get(player)
	if not profile or typeof(amount) ~= "number" or amount <= 0 then return false end
	profile.Experience += math.floor(amount)
	local leveled = false
	while profile.Level < Config.MaxLevel and profile.Experience >= ProgressionService.RequiredXP(profile.Level) do
		profile.Experience -= ProgressionService.RequiredXP(profile.Level)
		profile.Level += 1
		profile.AttributePoints += Config.PointsPerLevel
		leveled = true
		if profile.Class ~= "" and Classes[profile.Class] then
			for _, abilityId in ipairs(Classes[profile.Class].Abilities) do
				if Abilities[abilityId] and Abilities[abilityId].UnlockLevel <= profile.Level then
					profile.UnlockedAbilities[abilityId] = true
					local present = false
					for _, equippedAbility in pairs(profile.Hotbar) do if equippedAbility == abilityId then present = true end end
					if not present and #profile.Hotbar < 4 then table.insert(profile.Hotbar, abilityId) end
				end
			end
		end
		notify(player, "LevelUp", "Nível " .. tostring(profile.Level) .. " alcançado! +" .. tostring(Config.PointsPerLevel) .. " pontos de atributo.")
	end
	if leveled then ProgressionService.ApplyCharacter(player) end
	notify(player, "Experience", "+" .. tostring(math.floor(amount)) .. " XP" .. (reason and (" · " .. reason) or ""))
	sync(player)
	return true
end

function ProgressionService.ChooseClass(player, classId)
	local profile = profiles.Get(player)
	local classData = Classes[classId]
	if not profile or not classData or profile.Class ~= "" then return false, "Classe inválida ou já escolhida." end
	profile.Class = classId
	for attribute, bonus in pairs(classData.Bonuses) do
		profile.Attributes[attribute] = (profile.Attributes[attribute] or 0) + bonus
	end
	for _, abilityId in ipairs(classData.Abilities) do
		if Abilities[abilityId].UnlockLevel <= profile.Level then profile.UnlockedAbilities[abilityId] = true end
	end
	profile.Hotbar[1] = classData.Abilities[1]
	ProgressionService.ApplyCharacter(player)
	notify(player, "Class", "Você se tornou " .. classData.Name .. "!")
	sync(player)
	return true
end

function ProgressionService.Allocate(player, attribute)
	local profile = profiles.Get(player)
	if not profile or profile.AttributePoints <= 0 or profile.Attributes[attribute] == nil then return false end
	profile.Attributes[attribute] += 1
	profile.AttributePoints -= 1
	ProgressionService.ApplyCharacter(player)
	sync(player)
	return true
end

return ProgressionService
