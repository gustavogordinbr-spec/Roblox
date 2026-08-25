--!strict
local Appearance = {}

Appearance.HairStyles = {"Original", "Curto", "Ondulado", "Longo", "Moicano", "Preso"}
Appearance.HairColors = {
	Preto = Color3.fromRGB(30, 29, 35), Castanho = Color3.fromRGB(99, 65, 47), Loiro = Color3.fromRGB(219, 184, 112),
	Ruivo = Color3.fromRGB(160, 66, 45), Branco = Color3.fromRGB(232, 232, 239), Prateado = Color3.fromRGB(165, 178, 197),
	Azul = Color3.fromRGB(70, 112, 207), Violeta = Color3.fromRGB(139, 88, 190), Verde = Color3.fromRGB(84, 153, 113),
	Rosa = Color3.fromRGB(205, 122, 160), Cinza = Color3.fromRGB(112, 117, 130), Dourado = Color3.fromRGB(229, 173, 76),
}
Appearance.EyeColors = {
	Castanho = Color3.fromRGB(109, 72, 45), Verde = Color3.fromRGB(89, 180, 113), Azul = Color3.fromRGB(82, 150, 239),
	Mel = Color3.fromRGB(218, 157, 65), Cinza = Color3.fromRGB(167, 178, 193), Violeta = Color3.fromRGB(166, 106, 240),
	Rubi = Color3.fromRGB(218, 72, 95), Celeste = Color3.fromRGB(124, 216, 238), Dourado = Color3.fromRGB(249, 202, 99),
	Branco = Color3.fromRGB(229, 235, 242),
}
Appearance.SkinTones = {
	Original = Color3.fromRGB(232, 195, 163), Porcelana = Color3.fromRGB(247, 222, 203), Clara = Color3.fromRGB(231, 192, 159),
	Areia = Color3.fromRGB(207, 162, 122), Bronze = Color3.fromRGB(170, 120, 87), Morena = Color3.fromRGB(135, 91, 66),
	Escura = Color3.fromRGB(98, 64, 49), Obsidiana = Color3.fromRGB(71, 71, 79), Lunar = Color3.fromRGB(188, 181, 215),
	Oceanica = Color3.fromRGB(120, 169, 183),
}
Appearance.Outfits = {
	Aventureiro = {Primary = Color3.fromRGB(86, 76, 69), Secondary = Color3.fromRGB(196, 159, 99)},
	Cacador = {Primary = Color3.fromRGB(65, 95, 77), Secondary = Color3.fromRGB(153, 122, 81)},
	Cavaleiro = {Primary = Color3.fromRGB(102, 116, 134), Secondary = Color3.fromRGB(207, 187, 123)},
	Arcano = {Primary = Color3.fromRGB(98, 80, 146), Secondary = Color3.fromRGB(171, 133, 233)},
	Sombrio = {Primary = Color3.fromRGB(48, 46, 58), Secondary = Color3.fromRGB(150, 77, 101)},
	Real = {Primary = Color3.fromRGB(125, 49, 70), Secondary = Color3.fromRGB(221, 176, 80)},
	Selvagem = {Primary = Color3.fromRGB(92, 115, 72), Secondary = Color3.fromRGB(150, 123, 79)},
}
Appearance.RarityColors = {
	Comum = Color3.fromRGB(194, 201, 216), Incomum = Color3.fromRGB(108, 212, 144), Rara = Color3.fromRGB(106, 161, 248),
	Epica = Color3.fromRGB(183, 125, 255), Lendaria = Color3.fromRGB(248, 183, 84), Secreta = Color3.fromRGB(239, 102, 194),
}
Appearance.RaceAccents = {
	Humano = Color3.fromRGB(215, 177, 105), Elfyn = Color3.fromRGB(126, 198, 133), Durgan = Color3.fromRGB(200, 142, 81),
	Feralkin = Color3.fromRGB(204, 149, 98), Sylvani = Color3.fromRGB(119, 192, 113), Stoneborn = Color3.fromRGB(136, 156, 182),
	Nightborn = Color3.fromRGB(137, 108, 197), Tidecaller = Color3.fromRGB(100, 185, 204), Draconian = Color3.fromRGB(212, 103, 76),
	Celestial = Color3.fromRGB(242, 216, 135), Abyssal = Color3.fromRGB(188, 77, 102), Voidborn = Color3.fromRGB(171, 91, 222),
}
Appearance.Defaults = {
	HairStyle = "Original", HairColor = "Castanho", EyeColor = "Castanho", SkinTone = "Original", Outfit = "Aventureiro",
	ShowAura = true, ShowRaceCosmetics = true, ShowWings = true, ShowHorns = true,
}

function Appearance.GetSortedKeys(values: {[string]: any})
	local names = {}
	for name in pairs(values) do table.insert(names, name) end
	table.sort(names)
	return names
end

function Appearance.IsValid(option: string, value: any): boolean
	if option == "HairStyle" then return type(value) == "string" and table.find(Appearance.HairStyles, value) ~= nil end
	if option == "HairColor" then return type(value) == "string" and Appearance.HairColors[value] ~= nil end
	if option == "EyeColor" then return type(value) == "string" and Appearance.EyeColors[value] ~= nil end
	if option == "SkinTone" then return type(value) == "string" and Appearance.SkinTones[value] ~= nil end
	if option == "Outfit" then return type(value) == "string" and Appearance.Outfits[value] ~= nil end
	if option == "ShowAura" or option == "ShowRaceCosmetics" or option == "ShowWings" or option == "ShowHorns" then return type(value) == "boolean" end
	return false
end

return Appearance
