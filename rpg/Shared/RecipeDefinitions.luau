--!strict
return {
	HealthPotion = { Name = "Preparar Poção de Vida", Profession = "Alchemy", Level = 1, Gold = 12, Ingredients = { IronOre = 1 }, Result = { Id = "HealthPotion", Amount = 2 }, XP = 12 },
	ManaPotion = { Name = "Preparar Poção de Foco", Profession = "Alchemy", Level = 1, Gold = 15, Ingredients = { IronOre = 1 }, Result = { Id = "ManaPotion", Amount = 2 }, XP = 14 },
	GreaterPotion = { Name = "Preparar Poção Superior", Profession = "Alchemy", Level = 5, Gold = 35, Ingredients = { HealthPotion = 2, AuroraShard = 1 }, Result = { Id = "GreaterHealthPotion", Amount = 1 }, XP = 38 },
	SteelSword = { Name = "Forjar Espada de Aço", Profession = "Blacksmith", Level = 3, Gold = 90, Ingredients = { IronOre = 6 }, Result = { Id = "SteelSword", Amount = 1 }, XP = 48 },
	ReinforcedArmor = { Name = "Forjar Armadura Reforçada", Profession = "Blacksmith", Level = 4, Gold = 110, Ingredients = { IronOre = 8 }, Result = { Id = "ReinforcedArmor", Amount = 1 }, XP = 60 },
	HeroGauntlets = { Name = "Forjar Manoplas de Herói", Profession = "Blacksmith", Level = 10, Gold = 280, Ingredients = { IronOre = 12, AuroraShard = 3 }, Result = { Id = "HeroGauntlets", Amount = 1 }, XP = 135 },
	AuroraPendant = { Name = "Montar Pingente da Aurora", Profession = "Artifice", Level = 12, Gold = 450, Ingredients = { AuroraShard = 7, BossCore = 1 }, Result = { Id = "AuroraPendant", Amount = 1 }, XP = 210 },
	EclipseBlade = { Name = "Forjar Lâmina do Eclipse", Profession = "Blacksmith", Level = 25, Gold = 1400, Ingredients = { IronOre = 25, AuroraShard = 12, BossCore = 3 }, Result = { Id = "EclipseBlade", Amount = 1 }, XP = 650 },
	HeroMantle = { Name = "Criar Manto do Herói", Profession = "Artifice", Level = 18, Gold = 800, Ingredients = { AuroraShard = 8, BossCore = 2 }, Result = { Id = "HeroMantle", Amount = 1 }, XP = 340 },
}
