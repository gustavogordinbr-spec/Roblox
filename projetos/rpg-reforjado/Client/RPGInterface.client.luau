--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local action = remotes:WaitForChild("RPGAction")
local questsRemote = remotes:WaitForChild("StartQuest")
local Classes = require(ReplicatedStorage.Modules:WaitForChild("Classes"))
local QuestService = require(ReplicatedStorage.Modules:WaitForChild("QuestService"))
local palette = {background = Color3.fromRGB(11, 14, 24), surface = Color3.fromRGB(18, 23, 37), soft = Color3.fromRGB(27, 33, 50), line = Color3.fromRGB(54, 64, 90), text = Color3.fromRGB(241, 243, 252), muted = Color3.fromRGB(159, 171, 195), accent = Color3.fromRGB(139, 116, 255), gold = Color3.fromRGB(255, 197, 95), green = Color3.fromRGB(103, 218, 153), red = Color3.fromRGB(245, 105, 117)}

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "RPGEnhancedInterface", false, false, 16
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function create(className: string, properties: {[string]: any}, parent: Instance?): any
	local object = Instance.new(className)
	for key, value in pairs(properties) do object[key] = value end
	object.Parent = parent
	return object
end

local function rounded(object: Instance, radius: number?, border: boolean?)
	create("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, object)
	if border then create("UIStroke", {Color = palette.line, Transparency = .3, Thickness = 1}, object) end
end

local function label(parent: Instance, text: string, size: UDim2, position: UDim2, fontSize: number, color: Color3?, weight: Enum.Font?)
	return create("TextLabel", {BackgroundTransparency = 1, Size = size, Position = position, Text = text, Font = weight or Enum.Font.Gotham, TextSize = fontSize, TextColor3 = color or palette.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, parent)
end

local profile = create("Frame", {Name = "Profile", Size = UDim2.fromOffset(232, 67), Position = UDim2.fromOffset(18, 16), BackgroundColor3 = palette.surface, BackgroundTransparency = .08}, gui)
rounded(profile, 14, true)
local insignia = create("TextLabel", {Text = "D", Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = palette.gold, BackgroundColor3 = palette.soft, Size = UDim2.fromOffset(43, 43), Position = UDim2.fromOffset(12, 12)}, profile)
rounded(insignia, 12)
local profileName = label(profile, player.DisplayName, UDim2.fromOffset(158, 22), UDim2.fromOffset(66, 11), 15, palette.text, Enum.Font.GothamBold)
local profileClass = label(profile, "Aventureiro · Humano", UDim2.fromOffset(162, 18), UDim2.fromOffset(66, 36), 11, palette.muted)

local quick = create("Frame", {Name = "ActionBar", AnchorPoint = Vector2.new(.5, 1), Size = UDim2.fromOffset(430, 63), Position = UDim2.new(.5, 0, 1, -19), BackgroundColor3 = palette.surface, BackgroundTransparency = .08}, gui)
rounded(quick, 15, true)
create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8)}, quick)
local shortcuts = {{"Q", "ESQUIVA"}, {"F", "DEFESA"}, {"E", "ATRIBUTOS"}, {"J", "MISSÕES"}, {"C", "CLASSES"}}

local modal = create("Frame", {Name = "Menu", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(680, 460), BackgroundColor3 = palette.background, Visible = false}, gui)
rounded(modal, 18, true)
create("UISizeConstraint", {MaxSize = Vector2.new(760, 550), MinSize = Vector2.new(320, 320)}, modal)
local modalScale = create("UIScale", {Scale = 1}, modal)
local header = create("Frame", {Size = UDim2.new(1, 0, 0, 71), BackgroundColor3 = palette.surface, BorderSizePixel = 0}, modal)
rounded(header, 18)
local heading = label(header, "PERSONAGEM", UDim2.fromOffset(440, 27), UDim2.fromOffset(25, 14), 20, palette.text, Enum.Font.GothamBold)
local subtitle = label(header, "Ajuste sua build e acompanhe a jornada.", UDim2.fromOffset(480, 17), UDim2.fromOffset(26, 42), 11, palette.muted)
local close = create("TextButton", {Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -49, 0, 18), Text = "×", Font = Enum.Font.Gotham, TextSize = 27, TextColor3 = palette.text, BackgroundColor3 = palette.soft, AutoButtonColor = true}, header)
rounded(close, 10)
local sidebar = create("Frame", {Position = UDim2.fromOffset(14, 86), Size = UDim2.new(0, 161, 1, -103), BackgroundTransparency = 1}, modal)
create("UIListLayout", {Padding = UDim.new(0, 8)}, sidebar)
local content = create("ScrollingFrame", {Name = "Content", Position = UDim2.fromOffset(190, 88), Size = UDim2.new(1, -207, 1, -106), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = palette.accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, modal)
create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, content)
create("UIPadding", {PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 7)}, content)

local activeTab = "Atributos"
local tabButtons = {}
local function clearContent()
	for _, object in ipairs(content:GetChildren()) do if object:IsA("GuiObject") then object:Destroy() end end
end

local function card(height: number): Frame
	local object = create("Frame", {Size = UDim2.new(1, -4, 0, height), BackgroundColor3 = palette.surface, BorderSizePixel = 0}, content)
	rounded(object, 11, true)
	return object
end

local function button(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3, callback: () -> ())
	local object = create("TextButton", {Text = text, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = palette.text, Size = size, Position = position, BackgroundColor3 = color, AutoButtonColor = true}, parent)
	rounded(object, 8)
	object.Activated:Connect(callback)
	return object
end

local renderTab
local function showStats()
	heading.Text, subtitle.Text = "ATRIBUTOS", "Distribua seus pontos e construa seu estilo de combate."
	local summary = card(69)
	label(summary, "PONTOS DISPONÍVEIS", UDim2.fromOffset(220, 18), UDim2.fromOffset(15, 11), 10, palette.muted, Enum.Font.GothamBold)
	label(summary, tostring(player:GetAttribute("AttributePoints") or 0), UDim2.fromOffset(220, 27), UDim2.fromOffset(15, 32), 22, palette.gold, Enum.Font.GothamBlack)
	for index, item in ipairs({{"Forca", "FORÇA", "Dano físico e poder ofensivo"}, {"Agilidade", "AGILIDADE", "Mobilidade e velocidade de combate"}, {"Vitalidade", "VITALIDADE", "Vida máxima e resistência"}, {"Energia", "ENERGIA", "Reserva arcana e dano mágico"}, {"Sorte", "SORTE", "Chance de acertos críticos"}}) do
		local row = card(62)
		row.LayoutOrder = index
		label(row, item[2], UDim2.fromOffset(180, 18), UDim2.fromOffset(14, 9), 12, palette.text, Enum.Font.GothamBold)
		label(row, item[3], UDim2.fromOffset(300, 17), UDim2.fromOffset(14, 34), 10, palette.muted)
		local attribute = if item[1] == "Energia" then "EnergiaBase" else item[1]
		local value = math.floor(tonumber(player:GetAttribute(attribute)) or 0)
		label(row, tostring(value), UDim2.fromOffset(55, 26), UDim2.new(1, -111, 0, 17), 17, palette.gold, Enum.Font.GothamBold)
		button(row, "+", UDim2.fromOffset(32, 32), UDim2.new(1, -44, 0, 15), palette.accent, function() action:FireServer("AllocateStat", item[1]) end)
	end
end

local function showClasses()
	heading.Text, subtitle.Text = "CLASSES", "A primeira classe é gratuita; mudanças posteriores custam 150 moedas."
	local selected = player:GetAttribute("Classe") or "Noone"
	for index, entry in ipairs(Classes.GetSorted()) do
		local data, row = entry.Data, card(91)
		row.LayoutOrder = index
		label(row, entry.Name, UDim2.fromOffset(235, 21), UDim2.fromOffset(13, 9), 14, palette.text, Enum.Font.GothamBold)
		label(row, data.Tipo .. "  ·  " .. (data.Raridade or "Comum"), UDim2.fromOffset(260, 16), UDim2.fromOffset(14, 33), 10, palette.gold)
		label(row, data.Descricao, UDim2.new(1, -118, 0, 18), UDim2.fromOffset(14, 60), 10, palette.muted)
		local current = selected == entry.Name
		button(row, if current then "ATIVA" else "ESCOLHER", UDim2.fromOffset(88, 31), UDim2.new(1, -99, 0, 30), if current then Color3.fromRGB(48, 109, 78) else palette.accent, function() if not current then action:FireServer("SelectClass", entry.Name) end end)
	end
end

local function showQuests()
	heading.Text, subtitle.Text = "QUADRO DE MISSÕES", "Escolha contratos, acompanhe requisitos e ganhe recompensas."
	local ids = {}
	for id in pairs(QuestService.Quests) do table.insert(ids, id) end
	table.sort(ids)
	for index, id in ipairs(ids) do
		local quest, row = QuestService.Quests[id], card(98)
		row.LayoutOrder = index
		local completed = player:GetAttribute(id .. "_AlreadyCompleted") == true
		local active = player:GetAttribute("ActiveQuestId") == id
		local locked = (player:GetAttribute("Level") or 1) < quest.MinLevel
		label(row, "[" .. quest.Rank .. "] " .. quest.Name, UDim2.new(1, -112, 0, 20), UDim2.fromOffset(13, 8), 13, palette.text, Enum.Font.GothamBold)
		label(row, quest.Description, UDim2.new(1, -20, 0, 17), UDim2.fromOffset(14, 32), 10, palette.muted)
		label(row, "+" .. quest.Reward.XP .. " XP  ·  ✦ " .. quest.Reward.Dinheiro .. "  ·  LV " .. quest.MinLevel, UDim2.fromOffset(280, 18), UDim2.fromOffset(14, 66), 10, palette.gold, Enum.Font.GothamMedium)
		local text = if completed then "CONCLUÍDA" elseif active then "EM CURSO" elseif locked then "LV " .. quest.MinLevel else "ACEITAR"
		local color = if completed then Color3.fromRGB(48, 109, 78) elseif locked then palette.soft else palette.accent
		button(row, text, UDim2.fromOffset(94, 28), UDim2.new(1, -105, 0, 59), color, function() if not completed and not active and not locked then questsRemote:FireServer(id) end end)
	end
end

renderTab = function(name: string)
	activeTab = name
	clearContent()
	for tabName, tab in pairs(tabButtons) do tab.BackgroundColor3 = if tabName == name then palette.accent else palette.surface end
	if name == "Atributos" then showStats() elseif name == "Classes" then showClasses() else showQuests() end
end

for _, tabName in ipairs({"Atributos", "Missões", "Classes"}) do
	local tab = create("TextButton", {Size = UDim2.new(1, 0, 0, 40), Text = tabName, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = palette.text, BackgroundColor3 = palette.surface, AutoButtonColor = false}, sidebar)
	rounded(tab, 9)
	tab.Activated:Connect(function() renderTab(tabName) end)
	tabButtons[tabName] = tab
end

local function open(tab: string)
	if modal.Visible and activeTab == tab then modal.Visible = false; return end
	modal.Visible = true
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local target = math.min(1, (viewport.X - 28) / 680, (viewport.Y - 55) / 460)
	modalScale.Scale = target * .95
	TweenService:Create(modalScale, TweenInfo.new(.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target}):Play()
	renderTab(tab)
end
close.Activated:Connect(function() modal.Visible = false end)

for _, item in ipairs(shortcuts) do
	local tile = create("TextButton", {Text = "", Size = UDim2.fromOffset(77, 46), BackgroundColor3 = palette.soft, AutoButtonColor = true}, quick)
	rounded(tile, 10)
	local key = label(tile, item[1], UDim2.fromOffset(69, 20), UDim2.fromOffset(0, 3), 14, palette.gold, Enum.Font.GothamBold)
	key.TextXAlignment = Enum.TextXAlignment.Center
	local text = label(tile, item[2], UDim2.fromOffset(73, 14), UDim2.fromOffset(2, 26), 8, palette.muted, Enum.Font.GothamMedium)
	text.TextXAlignment = Enum.TextXAlignment.Center
	tile.Activated:Connect(function()
		if item[1] == "Q" then action:FireServer("Dash")
		elseif item[1] == "F" then action:FireServer("Block", not (player:GetAttribute("Blocking") == true))
		elseif item[1] == "E" then open("Atributos") elseif item[1] == "J" then open("Missões") else open("Classes") end
	end)
end

local toastContainer = create("Frame", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.fromScale(.5, .075), Size = UDim2.fromOffset(380, 225), BackgroundTransparency = 1}, gui)
create("UIListLayout", {Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center}, toastContainer)
local function toast(title: any, detail: any, kind: any)
	local color = if kind == "success" then palette.green elseif kind == "warning" then palette.gold elseif kind == "critical" then palette.red else palette.accent
	local frame = create("Frame", {Size = UDim2.fromOffset(350, 59), BackgroundColor3 = palette.surface, BackgroundTransparency = .08}, toastContainer)
	rounded(frame, 11, true)
	create("Frame", {Size = UDim2.new(0, 4, 1, -15), Position = UDim2.fromOffset(0, 7), BackgroundColor3 = color, BorderSizePixel = 0}, frame)
	label(frame, tostring(title), UDim2.fromOffset(310, 18), UDim2.fromOffset(14, 9), 13, color, Enum.Font.GothamBold)
	label(frame, tostring(detail or ""), UDim2.fromOffset(318, 18), UDim2.fromOffset(14, 31), 11, palette.muted)
	task.delay(3.4, function() if frame.Parent then TweenService:Create(frame, TweenInfo.new(.22), {BackgroundTransparency = 1}):Play(); task.wait(.24); frame:Destroy() end end)
end

remotes:WaitForChild("RPGNotification").OnClientEvent:Connect(toast)
remotes:WaitForChild("LevelUp").OnClientEvent:Connect(function(level: number, gained: number)
	toast("NÍVEL " .. tostring(level) .. " ALCANÇADO", "+" .. tostring(gained * 3) .. " pontos de atributo disponíveis", "success")
end)

local function updateProfile()
	insignia.Text = player:GetAttribute("PlayerRank") or "D"
	local className = player:GetAttribute("Classe") or "Noone"
	profileClass.Text = (if className == "Noone" then "Aventureiro" else className) .. "  ·  " .. (player:GetAttribute("Raca") or "Humano")
	if modal.Visible then renderTab(activeTab) end
end
for _, name in ipairs({"PlayerRank", "Classe", "Raca", "AttributePoints", "Level", "ActiveQuestId", "Allocated_Forca", "Allocated_Agilidade", "Allocated_Vitalidade", "Allocated_Energia", "Allocated_Sorte"}) do player:GetAttributeChangedSignal(name):Connect(updateProfile) end

UserInputService.InputBegan:Connect(function(input, consumed)
	if consumed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Q then action:FireServer("Dash")
	elseif input.KeyCode == Enum.KeyCode.F then action:FireServer("Block", true)
	elseif input.KeyCode == Enum.KeyCode.E then open("Atributos")
	elseif input.KeyCode == Enum.KeyCode.J then open("Missões")
	elseif input.KeyCode == Enum.KeyCode.C then open("Classes")
	elseif input.KeyCode == Enum.KeyCode.Escape and modal.Visible then modal.Visible = false end
end)
UserInputService.InputEnded:Connect(function(input) if input.KeyCode == Enum.KeyCode.F then action:FireServer("Block", false) end end)

local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local size = camera.ViewportSize
	modalScale.Scale = math.min(1, (size.X - 28) / 680, (size.Y - 55) / 460)
	quick.Size = UDim2.fromOffset(if size.X < 500 then 365 else 430, 63)
	profile.Size = UDim2.fromOffset(if size.X < 500 then 205 else 232, 67)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
resize()
updateProfile()
