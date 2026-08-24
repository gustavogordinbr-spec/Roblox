--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Achievements = require(Shared:WaitForChild("AchievementDefinitions"))

local AchievementService = {}
local profiles
local notify

function AchievementService.Init(profileService, notifier)
	profiles, notify = profileService, notifier
end

function AchievementService.Evaluate(player)
	local profile = profiles.Get(player)
	if not profile then return false end
	local changed = false
	for achievementId, achievement in pairs(Achievements) do
		if not profile.Achievements[achievementId] and (profile[achievement.Metric] or 0) >= achievement.Goal then
			profile.Achievements[achievementId] = os.time()
			profile.Gems += achievement.Gems
			profile.Titles[achievement.Title] = true
			if profile.EquippedTitle == "" then profile.EquippedTitle = achievement.Title end
			notify(player, "Achievement", "Conquista: " .. achievement.Name .. " · +" .. tostring(achievement.Gems) .. " cristais")
			changed = true
		end
	end
	return changed
end

function AchievementService.EquipTitle(player, title)
	local profile = profiles.Get(player)
	if not profile or not profile.Titles[title] then return false end
	profile.EquippedTitle = title
	if player.Character then player.Character:SetAttribute("RPGTitle", title) end
	notify(player, "Title", "Título equipado: " .. title)
	return true
end

return AchievementService
