--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("Quest", 10)
if not gui then return end
local frame = gui:WaitForChild("QuestFrame", 8)
if not frame then return end
local title, description, progress = frame:WaitForChild("QuestTitle", 5), frame:WaitForChild("QuestDesc", 5), frame:WaitForChild("QuestProgress", 5)
if not title or not description or not progress then return end
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local definitions = require(ReplicatedStorage.Modules:WaitForChild("QuestService")).Quests

gui.ResetOnSpawn = false
frame.BackgroundColor3, frame.BackgroundTransparency = Color3.fromRGB(48, 35, 26), .08
local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
corner.CornerRadius, corner.Parent = UDim.new(0, 4), frame
local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
stroke.Color, stroke.Transparency, stroke.Thickness, stroke.Parent = Color3.fromRGB(177, 140, 74), .17, 1.5, frame
if title:IsA("TextLabel") then title.Font, title.TextColor3 = Enum.Font.Antique, Color3.fromRGB(231, 199, 130) end
if description:IsA("TextLabel") then description.Font, description.TextColor3 = Enum.Font.Antique, Color3.fromRGB(207, 185, 154) end
if progress:IsA("TextLabel") then progress.Font, progress.TextColor3 = Enum.Font.Antique, Color3.fromRGB(219, 171, 85) end

local function update(id: string, current: number, total: number)
	local quest = definitions[id]
	if not quest then return end
	gui.Enabled = true
	title.Text = "✠ CONTRATO " .. (quest.Rank or "D") .. "  ·  " .. quest.Name
	description.Text = quest.Description
	progress.Text = math.max(0, current or 0) .. " / " .. math.max(1, total or quest.Amount)
	TweenService:Create(frame, TweenInfo.new(.2), {BackgroundTransparency = .08}):Play()
end
remotes:WaitForChild("UpdateQuestHUD").OnClientEvent:Connect(update)

remotes:WaitForChild("QuestCompleted").OnClientEvent:Connect(function()
	task.delay(.75, function() if player:GetAttribute("HasActiveQuest") ~= true then gui.Enabled = false end end)
end)

local function restore()
	local id = player:GetAttribute("ActiveQuestId")
	local quest = id and definitions[id]
	if player:GetAttribute("HasActiveQuest") and quest then update(id, player:GetAttribute("ActiveQuestProgress") or 0, quest.Amount) else gui.Enabled = false end
end
player:GetAttributeChangedSignal("ActiveQuestId"):Connect(restore)
player:GetAttributeChangedSignal("ActiveQuestProgress"):Connect(restore)
restore()
