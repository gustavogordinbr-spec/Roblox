--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local root = ReplicatedStorage:WaitForChild("AuroraRPG")
local Shared = root:WaitForChild("Shared")
local Remotes = root:WaitForChild("Remotes")
local Config = require(Shared:WaitForChild("GameConfig"))
local Classes = require(Shared:WaitForChild("ClassDefinitions"))
local Items = require(Shared:WaitForChild("ItemDefinitions"))
local Abilities = require(Shared:WaitForChild("AbilityDefinitions"))
local Quests = require(Shared:WaitForChild("QuestDefinitions"))
local Recipes = require(Shared:WaitForChild("RecipeDefinitions"))
local Achievements = require(Shared:WaitForChild("AchievementDefinitions"))

local actionRemote = Remotes:WaitForChild("Action")
local stateRemote = Remotes:WaitForChild("StateChanged")
local notificationRemote = Remotes:WaitForChild("Notification")
local requestState = Remotes:WaitForChild("RequestState")

local state = nil
local menuOpen = false
local selectedTab = "Personagem"
local activeNotifications = 0
local currentTarget = nil

local colors = {
	Background = Color3.fromRGB(13, 16, 24),
	Panel = Color3.fromRGB(22, 26, 38),
	PanelLight = Color3.fromRGB(31, 37, 53),
	Accent = Color3.fromRGB(121, 101, 255),
	Accent2 = Color3.fromRGB(78, 210, 218),
	Text = Color3.fromRGB(236, 240, 250),
	Muted = Color3.fromRGB(153, 163, 185),
	Danger = Color3.fromRGB(255, 91, 111),
	Success = Color3.fromRGB(91, 220, 151),
	Gold = Color3.fromRGB(255, 194, 91),
}

local gui = Instance.new("ScreenGui")
gui.Name = "AuroraRPGInterface"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 90
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 8)
	value.Parent = parent
end

local function stroke(parent, color, transparency, thickness)
	local value = Instance.new("UIStroke")
	value.Color = color or colors.Accent
	value.Transparency = transparency or 0.65
	value.Thickness = thickness or 1
	value.Parent = parent
end

local function padding(parent, size)
	local value = Instance.new("UIPadding")
	value.PaddingTop = UDim.new(0, size)
	value.PaddingBottom = UDim.new(0, size)
	value.PaddingLeft = UDim.new(0, size)
	value.PaddingRight = UDim.new(0, size)
	value.Parent = parent
end

local function label(parent, text, size, position, fontSize, color, bold)
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Size = size
	value.Position = position or UDim2.new()
	value.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	value.Text = text
	value.TextSize = fontSize or 14
	value.TextColor3 = color or colors.Text
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextWrapped = true
	value.Parent = parent
	return value
end

local function button(parent, text, size, position, callback, accent)
	local value = Instance.new("TextButton")
	value.AutoButtonColor = false
	value.BackgroundColor3 = accent or colors.PanelLight
	value.Size = size
	value.Position = position or UDim2.new()
	value.Font = Enum.Font.GothamBold
	value.Text = text
	value.TextSize = 13
	value.TextColor3 = colors.Text
	value.Parent = parent
	corner(value, 7)
	value.MouseEnter:Connect(function() TweenService:Create(value, TweenInfo.new(0.14), { BackgroundColor3 = (accent or colors.Accent):Lerp(Color3.new(1, 1, 1), 0.12) }):Play() end)
	value.MouseLeave:Connect(function() TweenService:Create(value, TweenInfo.new(0.14), { BackgroundColor3 = accent or colors.PanelLight }):Play() end)
	value.Activated:Connect(callback)
	return value
end

local function clear(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
	end
end

local hud = Instance.new("Frame")
hud.Name = "RPGHUD"
hud.BackgroundTransparency = 1
hud.Size = UDim2.fromScale(1, 1)
hud.Parent = gui

local status = Instance.new("Frame")
status.BackgroundColor3 = colors.Background
status.BackgroundTransparency = 0.08
status.Size = UDim2.fromOffset(320, 112)
status.Position = UDim2.new(0, 18, 1, -132)
status.Parent = hud
corner(status, 12)
stroke(status, colors.Accent, 0.45, 1.5)

local playerName = label(status, player.DisplayName, UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 8), 16, colors.Text, true)
local levelLabel = label(status, "Nv. 1", UDim2.fromOffset(90, 24), UDim2.new(1, -102, 0, 8), 13, colors.Gold, true)
levelLabel.TextXAlignment = Enum.TextXAlignment.Right

local function createBar(y, color, name)
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundColor3 = Color3.fromRGB(42, 47, 62)
	holder.Size = UDim2.new(1, -24, 0, 14)
	holder.Position = UDim2.fromOffset(12, y)
	holder.Parent = status
	corner(holder, 7)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = color
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = holder
	corner(fill, 7)
	local text = label(holder, "", UDim2.fromScale(1, 1), UDim2.new(), 10, colors.Text, true)
	text.TextXAlignment = Enum.TextXAlignment.Center
	return fill, text
end

local healthFill, healthText = createBar(38, Color3.fromRGB(238, 78, 98), "Health")
local manaFill, manaText = createBar(59, Color3.fromRGB(101, 123, 255), "Mana")
local staminaFill, staminaText = createBar(80, Color3.fromRGB(84, 218, 157), "Stamina")

local xpHolder = Instance.new("Frame")
xpHolder.BackgroundColor3 = colors.Background
xpHolder.Size = UDim2.new(0.34, 0, 0, 8)
xpHolder.Position = UDim2.new(0.33, 0, 1, -20)
xpHolder.Parent = hud
corner(xpHolder, 4)
local xpFill = Instance.new("Frame")
xpFill.BackgroundColor3 = colors.Accent
xpFill.Size = UDim2.new(0, 0, 1, 0)
xpFill.Parent = xpHolder
corner(xpFill, 4)
local xpLabel = label(hud, "0 / 100 XP", UDim2.new(0.34, 0, 0, 18), UDim2.new(0.33, 0, 1, -40), 11, colors.Muted, true)
xpLabel.TextXAlignment = Enum.TextXAlignment.Center

local currency = Instance.new("Frame")
currency.BackgroundColor3 = colors.Background
currency.BackgroundTransparency = 0.08
currency.Size = UDim2.fromOffset(190, 40)
currency.Position = UDim2.new(1, -208, 0, 16)
currency.Parent = hud
corner(currency, 10)
stroke(currency, colors.Gold, 0.62, 1)
local currencyText = label(currency, "◈ 0    ◆ 0", UDim2.new(1, -18, 1, 0), UDim2.fromOffset(9, 0), 14, colors.Gold, true)
currencyText.TextXAlignment = Enum.TextXAlignment.Center

local questTracker = Instance.new("Frame")
questTracker.BackgroundColor3 = colors.Background
questTracker.BackgroundTransparency = 0.12
questTracker.Size = UDim2.fromOffset(276, 132)
questTracker.Position = UDim2.new(1, -294, 0, 68)
questTracker.Parent = hud
corner(questTracker, 10)
stroke(questTracker, colors.Accent2, 0.7, 1)
label(questTracker, "MISSÕES ATIVAS", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 8), 12, colors.Accent2, true)
local questTrackerBody = label(questTracker, "Nenhuma missão ativa.", UDim2.new(1, -20, 1, -38), UDim2.fromOffset(10, 32), 12, colors.Text, false)
questTrackerBody.TextYAlignment = Enum.TextYAlignment.Top

local hotbar = Instance.new("Frame")
hotbar.BackgroundTransparency = 1
hotbar.Size = UDim2.fromOffset(340, 62)
hotbar.Position = UDim2.new(0.5, -170, 1, -88)
hotbar.Parent = hud
local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 8)
hotbarLayout.Parent = hotbar
local hotbarButtons = {}
for index = 1, 4 do
	local slot = button(hotbar, tostring(index), UDim2.fromOffset(62, 62), nil, function()
		if state and state.Hotbar[index] then actionRemote:FireServer("UseAbility", { Id = state.Hotbar[index], Target = currentTarget }) end
	end)
	slot.TextWrapped = true
	slot.TextSize = 10
	hotbarButtons[index] = slot
end

local menu = Instance.new("Frame")
menu.BackgroundColor3 = colors.Background
menu.Size = UDim2.new(0.82, 0, 0.82, 0)
menu.Position = UDim2.new(0.5, 0, 0.52, 0)
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Visible = false
menu.Parent = gui
corner(menu, 14)
stroke(menu, colors.Accent, 0.3, 1.5)

local menuSize = Instance.new("UISizeConstraint")
menuSize.MinSize = if UserInputService.TouchEnabled then Vector2.new(320, 350) else Vector2.new(620, 420)
menuSize.MaxSize = Vector2.new(1040, 720)
menuSize.Parent = menu

local header = Instance.new("Frame")
header.BackgroundColor3 = colors.Panel
header.Size = UDim2.new(1, 0, 0, 58)
header.Parent = menu
corner(header, 14)
label(header, "QUIRKBOUND  /  ASCENSÃO DOS HERÓIS", UDim2.new(1, -120, 1, 0), UDim2.fromOffset(18, 0), 17, colors.Text, true)
button(header, "FECHAR  [M]", UDim2.fromOffset(102, 34), UDim2.new(1, -114, 0.5, -17), function()
	menuOpen = false; menu.Visible = false
end, colors.Danger)

local sidebar = Instance.new("ScrollingFrame")
sidebar.BackgroundColor3 = Color3.fromRGB(17, 20, 30)
sidebar.Size = UDim2.new(0, 170, 1, -58)
sidebar.Position = UDim2.fromOffset(0, 58)
sidebar.BorderSizePixel = 0
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.CanvasSize = UDim2.new()
sidebar.ScrollBarThickness = 3
sidebar.Parent = menu
local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 7)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.Parent = sidebar
padding(sidebar, 10)

local content = Instance.new("ScrollingFrame")
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Size = UDim2.new(1, -186, 1, -74)
content.Position = UDim2.fromOffset(178, 66)
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = colors.Accent
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = menu
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 9)
contentLayout.Parent = content
padding(content, 8)

local tabButtons = {}
local renderTab

local function card(parent, height)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = colors.Panel
	frame.Size = UDim2.new(1, -10, 0, height)
	frame.Parent = parent
	corner(frame, 9)
	stroke(frame, colors.Accent, 0.78, 1)
	return frame
end

local function fire(action, data)
	actionRemote:FireServer(action, data or {})
end

local tabNames = { "Personagem", "Inventário", "Habilidades", "Missões", "Grupo", "Loja", "Criação", "Conquistas", "Configurações" }
for _, tabName in ipairs(tabNames) do
	tabButtons[tabName] = button(sidebar, tabName, UDim2.new(1, -10, 0, 38), nil, function()
		selectedTab = tabName
		if renderTab then renderTab() end
	end)
end

local function sortedKeys(data)
	local keys = {}
	for key in pairs(data) do table.insert(keys, key) end
	table.sort(keys)
	return keys
end

renderTab = function()
	clear(content)
	for name, tabButton in pairs(tabButtons) do
		tabButton.BackgroundColor3 = if name == selectedTab then colors.Accent else colors.PanelLight
	end
	if not state then label(content, "Carregando dados...", UDim2.new(1, 0, 0, 40), nil, 16, colors.Muted, true); return end

	if selectedTab == "Personagem" then
		local classData = Classes[state.Class]
		local summary = card(content, 110)
		label(summary, (classData and (classData.Icon .. " " .. classData.Name) or "Classe não escolhida") .. "  ·  Nível " .. tostring(state.Level), UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 10), 20, classData and classData.Color or colors.Text, true)
		label(summary, "XP: " .. tostring(state.Experience) .. "/" .. tostring(state.RequiredXP) .. "    Ouro: " .. tostring(state.Gold) .. "    Renome: " .. tostring(state.Reputation) .. "    Abates: " .. tostring(state.Kills), UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 48), 13, colors.Muted, false)
		label(summary, "Pontos disponíveis: " .. tostring(state.AttributePoints), UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 76), 13, colors.Gold, true)
		if state.EquippedTitle and state.EquippedTitle ~= "" then playerName.Text = "[" .. state.EquippedTitle .. "] " .. player.DisplayName end
		for _, attribute in ipairs(Config.Attributes) do
			local row = card(content, 52)
			local names = { Strength = "Força", Vitality = "Vitalidade", Agility = "Agilidade", Intelligence = "Inteligência", Luck = "Sorte" }
			label(row, names[attribute] .. "  " .. tostring(state.Attributes[attribute]), UDim2.new(1, -130, 1, 0), UDim2.fromOffset(12, 0), 14, colors.Text, true)
			button(row, "+ ATRIBUIR", UDim2.fromOffset(108, 32), UDim2.new(1, -120, 0.5, -16), function() fire("AllocateAttribute", { Attribute = attribute }) end, colors.Accent)
		end
	elseif selectedTab == "Inventário" then
		for _, itemId in ipairs(sortedKeys(state.Inventory)) do
			local item = Items[itemId]
			if item then
				local row = card(content, 74)
				local equipped = false
				for _, equippedId in pairs(state.Equipped) do if equippedId == itemId then equipped = true end end
				label(row, item.Name .. "  x" .. tostring(state.Inventory[itemId]) .. (if equipped then "  [EQUIPADO]" else ""), UDim2.new(1, -150, 0, 25), UDim2.fromOffset(12, 8), 14, Config.RarityColors[item.Rarity] or colors.Text, true)
				label(row, item.Description, UDim2.new(1, -150, 0, 30), UDim2.fromOffset(12, 36), 11, colors.Muted, false)
				if item.Type == "Consumable" then
					button(row, "USAR", UDim2.fromOffset(92, 32), UDim2.new(1, -104, 0.5, -16), function() fire("UseItem", { Id = itemId }) end, colors.Success)
				elseif item.Type == "Weapon" or item.Type == "Armor" or item.Type == "Accessory" then
					button(row, "EQUIPAR", UDim2.fromOffset(92, 32), UDim2.new(1, -104, 0.5, -16), function() fire("EquipItem", { Id = itemId }) end, colors.Accent)
				end
			end
		end
	elseif selectedTab == "Habilidades" then
		for abilityId in pairs(state.UnlockedAbilities) do
			local ability = Abilities[abilityId]
			if ability then
				local row = card(content, 70)
				label(row, ability.Name, UDim2.new(1, -160, 0, 25), UDim2.fromOffset(12, 8), 14, colors.Accent2, true)
				label(row, "Recarga: " .. tostring(ability.Cooldown) .. "s · Foco: " .. tostring(ability.Mana), UDim2.new(1, -160, 0, 24), UDim2.fromOffset(12, 36), 12, colors.Muted, false)
				button(row, "ATIVAR", UDim2.fromOffset(96, 34), UDim2.new(1, -108, 0.5, -17), function() fire("UseAbility", { Id = abilityId, Target = currentTarget }) end, colors.Accent)
			end
		end
	elseif selectedTab == "Missões" then
		for questId, quest in pairs(Quests) do
			if state.Level >= quest.MinLevel then
				local active = state.ActiveQuests[questId]
				local completed = state.CompletedQuests[questId] and not quest.Daily
				local row = card(content, 92)
				label(row, quest.Name .. (if quest.Daily then "  [DIÁRIA]" elseif quest.Story then "  [HISTÓRIA]" else ""), UDim2.new(1, -145, 0, 24), UDim2.fromOffset(12, 8), 14, if completed then colors.Success else colors.Text, true)
				label(row, quest.Description, UDim2.new(1, -155, 0, 35), UDim2.fromOffset(12, 34), 11, colors.Muted, false)
				label(row, (active and (tostring(active.Progress) .. "/" .. tostring(quest.Amount)) or ("Recompensa: " .. tostring(quest.XP) .. " XP · " .. tostring(quest.Gold) .. " ouro")), UDim2.new(1, -155, 0, 20), UDim2.fromOffset(12, 68), 11, colors.Gold, true)
				if active then button(row, "ABANDONAR", UDim2.fromOffset(110, 32), UDim2.new(1, -122, 0.5, -16), function() fire("AbandonQuest", { Id = questId }) end, colors.Danger)
				elseif not completed then button(row, "ACEITAR", UDim2.fromOffset(100, 32), UDim2.new(1, -112, 0.5, -16), function() fire("AcceptQuest", { Id = questId }) end, colors.Accent) end
			end
		end
	elseif selectedTab == "Grupo" then
		local invite = card(content, 92)
		label(invite, "Grupo cooperativo", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 8), 16, colors.Text, true)
		local box = Instance.new("TextBox")
		box.PlaceholderText = "Nome do jogador"
		box.Text = ""
		box.BackgroundColor3 = colors.PanelLight
		box.TextColor3 = colors.Text
		box.Font = Enum.Font.Gotham
		box.TextSize = 13
		box.Size = UDim2.new(1, -145, 0, 34)
		box.Position = UDim2.fromOffset(12, 47)
		box.Parent = invite
		corner(box, 7)
		button(invite, "CONVIDAR", UDim2.fromOffset(110, 34), UDim2.new(1, -122, 0, 47), function() fire("InviteParty", { Name = box.Text }) end, colors.Accent)
		if state.Party then
			for _, member in ipairs(state.Party.Members) do
				local row = card(content, 48)
				label(row, (if member.Leader then "★ " else "• ") .. member.Name, UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), 14, if member.Leader then colors.Gold else colors.Text, true)
			end
			button(content, "SAIR DO GRUPO", UDim2.new(1, -10, 0, 40), nil, function() fire("LeaveParty") end, colors.Danger)
		else
			button(content, "ACEITAR CONVITE PENDENTE", UDim2.new(1, -10, 0, 42), nil, function() fire("AcceptParty") end, colors.Success)
		end
	elseif selectedTab == "Loja" then
		for _, itemId in ipairs(sortedKeys(Items)) do
			local item = Items[itemId]
			if item.Price and item.Type ~= "Material" and item.Type ~= "Relic" then
				local row = card(content, 68)
				label(row, item.Name, UDim2.new(1, -170, 0, 25), UDim2.fromOffset(12, 8), 14, Config.RarityColors[item.Rarity], true)
				label(row, tostring(item.Price) .. " ouro · " .. item.Type, UDim2.new(1, -170, 0, 22), UDim2.fromOffset(12, 36), 11, colors.Muted, false)
				button(row, "COMPRAR", UDim2.fromOffset(105, 34), UDim2.new(1, -117, 0.5, -17), function() fire("BuyItem", { Id = itemId, Amount = 1 }) end, colors.Gold)
			end
		end
	elseif selectedTab == "Criação" then
		for _, recipeId in ipairs(sortedKeys(Recipes)) do
			local recipe = Recipes[recipeId]
			local ingredients = {}
			for itemId, amount in pairs(recipe.Ingredients) do
				local itemName = Items[itemId] and Items[itemId].Name or itemId
				table.insert(ingredients, itemName .. " " .. tostring(state.Inventory[itemId] or 0) .. "/" .. tostring(amount))
			end
			local row = card(content, 92)
			label(row, recipe.Name .. "  ·  Nv. " .. tostring(recipe.Level), UDim2.new(1, -140, 0, 26), UDim2.fromOffset(12, 8), 14, colors.Accent2, true)
			label(row, table.concat(ingredients, "  ·  "), UDim2.new(1, -140, 0, 34), UDim2.fromOffset(12, 34), 11, colors.Muted, false)
			label(row, tostring(recipe.Gold) .. " ouro · " .. recipe.Profession, UDim2.new(1, -140, 0, 20), UDim2.fromOffset(12, 68), 11, colors.Gold, true)
			button(row, "CRIAR", UDim2.fromOffset(96, 34), UDim2.new(1, -108, 0.5, -17), function() fire("CraftItem", { Id = recipeId }) end, colors.Accent)
		end
	elseif selectedTab == "Conquistas" then
		for _, achievementId in ipairs(sortedKeys(Achievements)) do
			local achievement = Achievements[achievementId]
			local unlocked = state.Achievements[achievementId]
			local progress = math.min(state[achievement.Metric] or 0, achievement.Goal)
			local row = card(content, 82)
			label(row, (if unlocked then "✓ " else "○ ") .. achievement.Name, UDim2.new(1, -145, 0, 24), UDim2.fromOffset(12, 8), 14, if unlocked then colors.Success else colors.Text, true)
			label(row, achievement.Description, UDim2.new(1, -145, 0, 28), UDim2.fromOffset(12, 35), 11, colors.Muted, false)
			label(row, tostring(progress) .. "/" .. tostring(achievement.Goal) .. "  ·  Título: " .. achievement.Title, UDim2.new(1, -145, 0, 20), UDim2.fromOffset(12, 60), 11, colors.Gold, true)
			if unlocked then button(row, "USAR TÍTULO", UDim2.fromOffset(115, 32), UDim2.new(1, -127, 0.5, -16), function() fire("EquipTitle", { Title = achievement.Title }) end, colors.Accent) end
		end
	else
		button(content, "RESGATAR RECOMPENSA DIÁRIA", UDim2.new(1, -10, 0, 42), nil, function() fire("ClaimDailyReward") end, colors.Gold)
		for _, setting in ipairs({ { "Music", "Música" }, { "Effects", "Efeitos" }, { "ShowDamage", "Mostrar dano" } }) do
			local row = card(content, 54)
			local enabled = state.Settings[setting[1]]
			label(row, setting[2], UDim2.new(1, -130, 1, 0), UDim2.fromOffset(12, 0), 14, colors.Text, true)
			button(row, if enabled then "LIGADO" else "DESLIGADO", UDim2.fromOffset(110, 32), UDim2.new(1, -122, 0.5, -16), function() fire("UpdateSetting", { Key = setting[1], Value = not enabled }) end, if enabled then colors.Success else colors.Danger)
		end
	end
end

local classSelect = Instance.new("Frame")
classSelect.BackgroundColor3 = colors.Background
classSelect.Size = UDim2.new(0.78, 0, 0.7, 0)
classSelect.Position = UDim2.fromScale(0.5, 0.5)
classSelect.AnchorPoint = Vector2.new(0.5, 0.5)
classSelect.Visible = false
classSelect.Parent = gui
corner(classSelect, 16)
stroke(classSelect, colors.Accent, 0.2, 2)
label(classSelect, "ESCOLHA SEU CAMINHO", UDim2.new(1, -24, 0, 42), UDim2.fromOffset(12, 14), 24, colors.Text, true).TextXAlignment = Enum.TextXAlignment.Center
label(classSelect, "A classe define seu começo, mas seus equipamentos e atributos continuam livres.", UDim2.new(1, -30, 0, 36), UDim2.fromOffset(15, 54), 13, colors.Muted, false).TextXAlignment = Enum.TextXAlignment.Center
local classGrid = Instance.new("ScrollingFrame")
classGrid.BackgroundTransparency = 1
classGrid.BorderSizePixel = 0
classGrid.Size = UDim2.new(1, -30, 1, -112)
classGrid.Position = UDim2.fromOffset(15, 96)
classGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
classGrid.CanvasSize = UDim2.new()
classGrid.ScrollBarThickness = 5
classGrid.Parent = classSelect
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.32, -8, 0, 142)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = classGrid
if UserInputService.TouchEnabled then
	menu.Size = UDim2.new(0.96, 0, 0.88, 0)
	classSelect.Size = UDim2.new(0.96, 0, 0.86, 0)
	grid.CellSize = UDim2.new(0.47, -6, 0, 138)
	status.Size = UDim2.fromOffset(250, 112)
	questTracker.Size = UDim2.fromOffset(210, 108)
	questTracker.Position = UDim2.new(1, -218, 0, 64)
end
for classId, classData in pairs(Classes) do
	local choice = button(classGrid, classData.Icon .. "\n" .. classData.Name .. "\n\n" .. classData.Description, UDim2.new(), nil, function()
		fire("ChooseClass", { Id = classId })
	end, classData.Color:Lerp(colors.Background, 0.65))
	choice.TextWrapped = true
	choice.TextSize = 13
	stroke(choice, classData.Color, 0.3, 1.5)
end

local notificationHolder = Instance.new("Frame")
notificationHolder.BackgroundTransparency = 1
notificationHolder.Size = UDim2.fromOffset(370, 300)
notificationHolder.Position = UDim2.new(0.5, -185, 0, 18)
notificationHolder.Parent = gui
local notificationLayout = Instance.new("UIListLayout")
notificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notificationLayout.Padding = UDim.new(0, 7)
notificationLayout.Parent = notificationHolder

local function showNotification(kind, message)
	activeNotifications += 1
	local note = Instance.new("TextLabel")
	note.BackgroundColor3 = if kind == "Warning" then colors.Danger elseif kind == "QuestComplete" or kind == "LevelUp" then colors.Success else colors.Panel
	note.BackgroundTransparency = 1
	note.Size = UDim2.fromOffset(360, 0)
	note.Font = Enum.Font.GothamBold
	note.Text = tostring(message)
	note.TextColor3 = colors.Text
	note.TextSize = 13
	note.TextTransparency = 1
	note.TextWrapped = true
	note.Parent = notificationHolder
	corner(note, 9)
	stroke(note, colors.Text, 0.8, 1)
	TweenService:Create(note, TweenInfo.new(0.22), { Size = UDim2.fromOffset(360, 48), BackgroundTransparency = 0.08, TextTransparency = 0 }):Play()
	task.delay(3.5, function()
		if note.Parent then
			TweenService:Create(note, TweenInfo.new(0.2), { Size = UDim2.fromOffset(360, 0), BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			task.wait(0.22)
			note:Destroy()
			activeNotifications -= 1
		end
	end)
end

local function updateState(newState)
	state = newState
	if not state then return end
	levelLabel.Text = "Nv. " .. tostring(state.Level)
	currencyText.Text = "◈ " .. tostring(state.Gold) .. "    ◆ " .. tostring(state.Gems)
	local ratio = if state.RequiredXP > 0 then state.Experience / state.RequiredXP else 1
	TweenService:Create(xpFill, TweenInfo.new(0.25), { Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0) }):Play()
	xpLabel.Text = tostring(state.Experience) .. " / " .. tostring(state.RequiredXP) .. " XP"
	local tracked = {}
	for questId, progress in pairs(state.ActiveQuests) do
		local quest = Quests[questId]
		if quest and #tracked < 3 then table.insert(tracked, "• " .. quest.Name .. "  " .. tostring(progress.Progress) .. "/" .. tostring(quest.Amount)) end
	end
	questTrackerBody.Text = if #tracked > 0 then table.concat(tracked, "\n") else "Nenhuma missão ativa. Abra [M] para aceitar uma."
	for index, slot in ipairs(hotbarButtons) do
		local abilityId = state.Hotbar[index]
		local ability = abilityId and Abilities[abilityId]
		slot.Text = tostring(index) .. (ability and ("\n" .. ability.Name) or "\nVAZIO")
	end
	classSelect.Visible = state.Class == ""
	if menuOpen then renderTab() end
end

stateRemote.OnClientEvent:Connect(updateState)
notificationRemote.OnClientEvent:Connect(function(kind, message)
	if kind == "ChooseClass" then classSelect.Visible = true end
	if kind == "OpenMerchant" then menuOpen = true; menu.Visible = true; selectedTab = "Loja"; renderTab() end
	if kind == "OpenQuestGiver" then menuOpen = true; menu.Visible = true; selectedTab = "Missões"; renderTab() end
	showNotification(kind, message)
end)

local function modelFromTarget(target)
	local current = target
	for _ = 1, 4 do
		if not current then break end
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then return current end
		current = current.Parent
	end
	return nil
end

mouse.Button1Down:Connect(function()
	if menuOpen or classSelect.Visible then return end
	currentTarget = modelFromTarget(mouse.Target)
	if currentTarget then fire("Attack", { Target = currentTarget, AttackType = "Light" }) end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed and input.KeyCode ~= Enum.KeyCode.M then return end
	if input.KeyCode == Enum.KeyCode.M then
		menuOpen = not menuOpen
		menu.Visible = menuOpen
		if menuOpen then renderTab() end
	elseif input.KeyCode == Enum.KeyCode.F and not menuOpen then
		currentTarget = modelFromTarget(mouse.Target)
		if currentTarget then fire("Attack", { Target = currentTarget, AttackType = "Heavy" }) end
	elseif input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.Four then
		local index = ({ [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4 })[input.KeyCode]
		if state and state.Hotbar[index] then fire("UseAbility", { Id = state.Hotbar[index], Target = currentTarget }) end
	end
end)

local mobileMenu = button(hud, "☰ RPG", UDim2.fromOffset(82, 38), UDim2.new(0, 18, 0, 18), function()
	menuOpen = not menuOpen; menu.Visible = menuOpen; if menuOpen then renderTab() end
end, colors.Accent)
mobileMenu.Visible = UserInputService.TouchEnabled

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and character then
		local healthRatio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 0
		healthFill.Size = UDim2.new(math.clamp(healthRatio, 0, 1), 0, 1, 0)
		healthText.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
		local mana, maxMana = character:GetAttribute("RPGMana") or 0, character:GetAttribute("RPGMaxMana") or 1
		manaFill.Size = UDim2.new(math.clamp(mana / maxMana, 0, 1), 0, 1, 0)
		manaText.Text = "Foco  " .. math.floor(mana) .. " / " .. math.floor(maxMana)
		local stamina, maxStamina = character:GetAttribute("RPGStamina") or 0, character:GetAttribute("RPGMaxStamina") or 1
		staminaFill.Size = UDim2.new(math.clamp(stamina / maxStamina, 0, 1), 0, 1, 0)
		staminaText.Text = "Vigor  " .. math.floor(stamina) .. " / " .. math.floor(maxStamina)
	end
end)

task.spawn(function()
	local ok, result = pcall(function() return requestState:InvokeServer() end)
	if ok and result then updateState(result) else showNotification("Warning", "Não foi possível carregar o sistema RPG agora.") end
end)

showNotification("Welcome", "Sistema RPG carregado · [M] abre o menu · [F] ataque pesado")
