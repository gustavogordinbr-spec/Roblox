--!strict
return {
	Version = "3.0.0",
	Combat = {AttackCooldown = 0.32, ComboReset = 1.35, Reach = 8, HitboxSize = Vector3.new(7, 6, 8), DashCooldown = 2.4, DashCost = 24, DashPower = 58, BlockReduction = 0.68, PvPEnabled = false},
	Sprint = {MinimumEnergy = 10, DrainPerSecond = 12, Tick = 0.2},
	Progression = {ClassChangeCost = 150, AttributesScaleWithLevel = true},
	Customization = {StartingRaceSpins = 3, DailyRaceSpins = 1, MaximumFreeSpins = 10, RaceSpinCost = 120, RaceSpinCooldown = 2.2, GuaranteedEpicAt = 18, GuaranteedLegendaryAt = 45, UpdateCooldown = .12},
	Presentation = {NormalFOV = 72, SprintFOV = 82, DashFOV = 89, AccentColor = Color3.fromRGB(157, 112, 65), GoldColor = Color3.fromRGB(207, 169, 94)},
	Ranks = {{Minimum = 120, Name = "S"}, {Minimum = 70, Name = "A"}, {Minimum = 35, Name = "B"}, {Minimum = 15, Name = "C"}, {Minimum = 1, Name = "D"}},
}
