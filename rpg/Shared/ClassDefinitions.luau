--!strict
return {
	Guardian = {
		Name = "Guardião", Icon = "🛡", Color = Color3.fromRGB(106, 156, 255),
		Description = "Defesa, proteção de aliados e controle de combate.",
		Bonuses = { Strength = 2, Vitality = 5, Agility = 0, Intelligence = 1, Luck = 0 },
		Abilities = { "ShieldBash", "IronWill", "GuardianRoar", "Unbreakable" },
	},
	Striker = {
		Name = "Combatente", Icon = "⚔", Color = Color3.fromRGB(255, 115, 108),
		Description = "Ataques agressivos, combos rápidos e alto dano físico.",
		Bonuses = { Strength = 5, Vitality = 2, Agility = 2, Intelligence = 0, Luck = 0 },
		Abilities = { "RisingStrike", "Flurry", "WarCry", "MeteorBreak" },
	},
	Arcanist = {
		Name = "Arcanista", Icon = "✦", Color = Color3.fromRGB(180, 119, 255),
		Description = "Manipulação de energia, efeitos elementais e habilidades especiais.",
		Bonuses = { Strength = 0, Vitality = 1, Agility = 1, Intelligence = 6, Luck = 1 },
		Abilities = { "ArcaneBolt", "ManaBarrier", "NovaBurst", "AstralCollapse" },
	},
	Ranger = {
		Name = "Patrulheiro", Icon = "➶", Color = Color3.fromRGB(106, 225, 151),
		Description = "Mobilidade, golpes precisos e exploração de pontos fracos.",
		Bonuses = { Strength = 2, Vitality = 1, Agility = 5, Intelligence = 0, Luck = 2 },
		Abilities = { "PiercingShot", "ShadowStep", "HuntersMark", "StormVolley" },
	},
	Medic = {
		Name = "Socorrista", Icon = "✚", Color = Color3.fromRGB(107, 223, 222),
		Description = "Cura, suporte em grupo e resistência para longas batalhas.",
		Bonuses = { Strength = 0, Vitality = 3, Agility = 1, Intelligence = 4, Luck = 1 },
		Abilities = { "HealingPulse", "Purify", "Revitalize", "SecondChance" },
	},
	Rogue = {
		Name = "Infiltrador", Icon = "◈", Color = Color3.fromRGB(245, 183, 87),
		Description = "Ataques críticos, furtividade e recompensas extras.",
		Bonuses = { Strength = 2, Vitality = 0, Agility = 4, Intelligence = 0, Luck = 4 },
		Abilities = { "Backstab", "SmokeBomb", "LuckyStrike", "PhantomDance" },
	},
}
