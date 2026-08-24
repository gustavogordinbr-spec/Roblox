--!strict
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

local WorldService = {}
local profiles
local progression

function WorldService.Init(profileService, progressionService)
	profiles, progression = profileService, progressionService
end

function WorldService.StartRegeneration()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local profile = profiles.Get(player)
				if character and profile then
					local maxMana = character:GetAttribute("RPGMaxMana") or Config.BaseMana
					local maxStamina = character:GetAttribute("RPGMaxStamina") or Config.BaseStamina
					local mana = character:GetAttribute("RPGMana") or maxMana
					local stamina = character:GetAttribute("RPGStamina") or maxStamina
					character:SetAttribute("RPGMana", math.min(maxMana, mana + Config.ManaRegen + profile.Attributes.Intelligence * 0.12))
					character:SetAttribute("RPGStamina", math.min(maxStamina, stamina + Config.StaminaRegen + profile.Attributes.Agility * 0.1))
					profile.PlayTime += 1
				end
			end
		end
	end)
end

function WorldService.SetupAtmosphere()
	if Lighting:FindFirstChild("AuroraRPGColorCorrection") then return end
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "AuroraRPGColorCorrection"
	correction.Brightness = 0.015
	correction.Contrast = 0.08
	correction.Saturation = -0.025
	correction.TintColor = Color3.fromRGB(245, 247, 255)
	correction.Parent = Lighting
	workspace:SetAttribute("AuroraRPGVersion", Config.Version)
	workspace:SetAttribute("AuroraRPGName", Config.GameName)
	workspace:SetAttribute("ProceduralVoxelWorldEnabled", Config.ProceduralVoxelWorldEnabled)
end

return WorldService
