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
frame.BackgroundColor3, frame.BackgroundTransparency = Color3.fromRGB(15, 19, 32), .1
local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
corner.CornerRadius, corner.Parent = UDim.new(0, 12), frame
local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
stroke.Color, stroke.Transparency, stroke.Parent = Color3.fromRGB(137, 112, 255), .52, frame
if title:IsA("TextLabel") then title.Font, title.TextColor3 = Enum.Font.GothamBold, Color3.fromRGB(236, 224, 255) end
if description:IsA("TextLabel") then description.Font, description.TextColor3 = Enum.Font.Gotham, Color3.fromRGB(184, 190, 209) end
if progress:IsA("TextLabel") then progress.Font, progress.TextColor3 = Enum.Font.GothamBold, Color3.fromRGB(255, 197, 97) end

remotes:WaitForChild("UpdateQuestHUD").OnClientEvent:Connect(function(id: string, current: number, total: number)
	local quest = definitions[id]
	if not quest then return end
	gui.Enabled = true
	title.Text = "◆ RANK " .. (quest.Rank or "D") .. "  ·  " .. quest.Name
	description.Text = quest.Description
	progress.Text = math.max(0, current or 0) .. " / " .. math.max(1, total or quest.Amount)
	TweenService:Create(frame, TweenInfo.new(.2), {BackgroundTransparency = .1}):Play()
end)

remotes:WaitForChild("QuestCompleted").OnClientEvent:Connect(function()
	task.delay(.75, function() if player:GetAttribute("HasActiveQuest") ~= true then gui.Enabled = false end end)
end)

if not player:GetAttribute("HasActiveQuest") then gui.Enabled = false end
