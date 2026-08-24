--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Recipes = require(Shared:WaitForChild("RecipeDefinitions"))

local CraftingService = {}
local profiles
local inventory
local progression
local notify
local sync

function CraftingService.Init(profileService, inventoryService, progressionService, notifier, synchronize)
	profiles, inventory, progression, notify, sync = profileService, inventoryService, progressionService, notifier, synchronize
end

function CraftingService.Craft(player, recipeId)
	local profile = profiles.Get(player)
	local recipe = Recipes[recipeId]
	if not profile or not recipe then return false, "Receita não encontrada." end
	if profile.Level < recipe.Level then return false, "Seu nível ainda é insuficiente para esta receita." end
	if profile.Gold < recipe.Gold then return false, "Ouro insuficiente para criar este item." end
	for itemId, required in pairs(recipe.Ingredients) do
		if (profile.Inventory[itemId] or 0) < required then return false, "Materiais insuficientes." end
	end
	profile.Gold -= recipe.Gold
	for itemId, required in pairs(recipe.Ingredients) do inventory.Remove(player, itemId, required) end
	inventory.Add(player, recipe.Result.Id, recipe.Result.Amount, true)
	profile.ProfessionXP[recipe.Profession] = (profile.ProfessionXP[recipe.Profession] or 0) + recipe.XP
	progression.AddXP(player, math.max(5, math.floor(recipe.XP * 0.35)), "Criação de item")
	notify(player, "Craft", recipe.Name .. " concluído!")
	sync(player)
	return true
end

return CraftingService
