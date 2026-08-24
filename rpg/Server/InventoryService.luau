--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Items = require(Shared:WaitForChild("ItemDefinitions"))

local InventoryService = {}
local profiles
local notify
local sync
local onCollect

function InventoryService.Init(profileService, notifier, synchronize)
	profiles, notify, sync = profileService, notifier, synchronize
end

function InventoryService.SetCollectCallback(callback)
	onCollect = callback
end

function InventoryService.Add(player, itemId, amount, silent)
	local profile = profiles.Get(player)
	local item = Items[itemId]
	amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 999)
	if not profile or not item then return false end
	profile.Inventory[itemId] = (profile.Inventory[itemId] or 0) + amount
	if onCollect then onCollect(player, itemId, amount) end
	if not silent then notify(player, "Item", "+" .. tostring(amount) .. " " .. item.Name) end
	sync(player)
	return true
end

function InventoryService.Remove(player, itemId, amount)
	local profile = profiles.Get(player)
	amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 999)
	if not profile or (profile.Inventory[itemId] or 0) < amount then return false end
	profile.Inventory[itemId] -= amount
	if profile.Inventory[itemId] <= 0 then profile.Inventory[itemId] = nil end
	sync(player)
	return true
end

function InventoryService.Equip(player, itemId)
	local profile = profiles.Get(player)
	local item = Items[itemId]
	if not profile or not item or not profile.Inventory[itemId] then return false, "Item não encontrado." end
	if item.Type ~= "Weapon" and item.Type ~= "Armor" and item.Type ~= "Accessory" then return false, "Este item não pode ser equipado." end
	if profile.Level < (item.Level or 1) then return false, "Nível insuficiente." end
	profile.Equipped[item.Type] = itemId
	if player.Character then player.Character:SetAttribute("RPG" .. item.Type, itemId) end
	notify(player, "Equip", item.Name .. " equipado.")
	sync(player)
	return true
end

function InventoryService.Use(player, itemId)
	local profile = profiles.Get(player)
	local item = Items[itemId]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not profile or not item or item.Type ~= "Consumable" or not humanoid then return false end
	if not profile.Inventory[itemId] then return false end
	if item.Heal then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + item.Heal) end
	if item.RestoreMana then
		character:SetAttribute("RPGMana", math.min(character:GetAttribute("RPGMaxMana") or 80, (character:GetAttribute("RPGMana") or 0) + item.RestoreMana))
	end
	if item.RestoreStamina then
		character:SetAttribute("RPGStamina", math.min(character:GetAttribute("RPGMaxStamina") or 100, (character:GetAttribute("RPGStamina") or 0) + item.RestoreStamina))
	end
	InventoryService.Remove(player, itemId, 1)
	notify(player, "Consumable", item.Name .. " utilizado.")
	return true
end

function InventoryService.Buy(player, itemId, amount)
	local profile = profiles.Get(player)
	local item = Items[itemId]
	amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 25)
	if not profile or not item or not item.Price then return false, "Item indisponível." end
	local cost = item.Price * amount
	if profile.Gold < cost then return false, "Ouro insuficiente." end
	profile.Gold -= cost
	InventoryService.Add(player, itemId, amount, true)
	notify(player, "Shop", "Comprou " .. item.Name .. " por " .. tostring(cost) .. " ouro.")
	sync(player)
	return true
end

function InventoryService.Sell(player, itemId, amount)
	local profile = profiles.Get(player)
	local item = Items[itemId]
	amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 25)
	if not profile or not item or not item.Price then return false end
	for _, equippedId in pairs(profile.Equipped) do
		if equippedId == itemId and (profile.Inventory[itemId] or 0) <= amount then return false, "Desequipe o item antes de vender." end
	end
	if not InventoryService.Remove(player, itemId, amount) then return false, "Quantidade insuficiente." end
	local payment = math.max(1, math.floor(item.Price * amount * 0.45))
	profile.Gold += payment
	notify(player, "Shop", "Vendeu " .. item.Name .. " por " .. tostring(payment) .. " ouro.")
	sync(player)
	return true
end

return InventoryService
