--!strict
-- Maid importado de Quirkbound > ReplicatedStorage/GravityController/Utility/Maid.
-- A API original foi preservada para gerenciar eventos e objetos temporários.
local cleanup = {
	["function"] = function(item) item() end,
	RBXScriptConnection = function(item) item:Disconnect() end,
	Instance = function(item) item:Destroy() end,
	table = function(item) if type(item.Destroy) == "function" then item:Destroy() end end,
}

local Maid = {}
Maid.__index = Maid
Maid.ClassName = "Maid"

function Maid.new(...)
	local self = setmetatable({}, Maid)
	self.Trash = {}
	for _, item in pairs({...}) do self:Mark(item) end
	return self
end

function Maid:Mark(item)
	local itemType = typeof(item)
	if not cleanup[itemType] then error(("Maid does not support type \"%s\""):format(itemType), 2) end
	self.Trash[item] = itemType
	return item
end

function Maid:Unmark(item)
	if item then self.Trash[item] = nil else self.Trash = {} end
end

function Maid:Sweep()
	for item, itemType in pairs(self.Trash) do
		local ok, err = pcall(cleanup[itemType], item)
		if not ok then warn("[RPG/Maid]", err) end
	end
	self.Trash = {}
end

Maid.Destroy = Maid.Sweep
return Maid
