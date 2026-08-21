--[[
	Database.luau
	Base de datos centralizada de objetivos, requisitos y objetos para Blox Fruits
	Contiene todas las definiciones de lo que se necesita para completar cada objetivo
]]

local Database = {}

--[[
	Definición de requisitos para cada objetivo
	Formato: {
		Name: nombre del objetivo,
		Category: categoría (Item, Weapon, Fruit, etc),
		Requirements: {
			StatName: { Required: number, Current: number }
		},
		Reward: descripción de la recompensa,
		Priority: prioridad (1-10)
	}
]]

Database.Objectives = {
	-- ARMAS
	Saber = {
		Name = "Saber",
		Category = "Weapon",
		Requirements = {
			Level = 1,
			Money = 25000,
		},
		Reward = "Espada básica",
		Priority = 1,
	},
	
	SharkAnchor = {
		Name = "Shark Anchor",
		Category = "Weapon",
		Requirements = {
			Level = 300,
			Money = 500000,
		},
		Reward = "Ancla del tiburón",
		Priority = 3,
	},
	
	SkullGuitar = {
		Name = "Skull Guitar",
		Category = "Weapon",
		Requirements = {
			Level = 1900,
			Money = 3000000,
		},
		Reward = "Guitarra de calavera",
		Priority = 5,
	},
	
	MirrorFractal = {
		Name = "Mirror Fractal",
		Category = "Weapon",
		Requirements = {
			Level = 2300,
			Money = 5000000,
			Fragments = 2000,
		},
		Reward = "Espejo fractal",
		Priority = 6,
	},
	
	CursedDualKatana = {
		Name = "Cursed Dual Katana",
		Category = "Weapon",
		Requirements = {
			Level = 2200,
			Money = 5000000,
			Fragments = 5000,
		},
		Reward = "Katanas malditas duales",
		Priority = 7,
	},
	
	Rengoku = {
		Name = "Rengoku",
		Category = "RareWeapon",
		Requirements = {
			Level = 1500,
			Money = 1500000,
		},
		Reward = "Espada legendaria Rengoku",
		Priority = 8,
	},
	
	DragonTrident = {
		Name = "Dragon Trident",
		Category = "RareWeapon",
		Requirements = {
			Level = 2550,
			Money = 7000000,
			Fragments = 10000,
		},
		Reward = "Tridente del dragón",
		Priority = 9,
	},
	
	GravityBlade = {
		Name = "Gravity Blade",
		Category = "RareWeapon",
		Requirements = {
			Level = 2400,
			Money = 6000000,
			Fragments = 8000,
		},
		Reward = "Espada de gravedad",
		Priority = 8,
	},
	
	PoleFirstForm = {
		Name = "Pole (1st Form)",
		Category = "RareWeapon",
		Requirements = {
			Level = 2250,
			Money = 5500000,
			Fragments = 6000,
		},
		Reward = "Palo primera forma",
		Priority = 7,
	},
	
	-- FRUTAS
	Diamond = {
		Name = "Diamond",
		Category = "Fruit",
		Requirements = {
			Level = 500,
			Money = 1000000,
		},
		Reward = "Fruta Diamante",
		Priority = 4,
	},
	
	Buddha = {
		Name = "Buddha",
		Category = "Fruit",
		Requirements = {
			Level = 1500,
			Money = 2500000,
		},
		Reward = "Fruta Buda",
		Priority = 5,
	},
	
	-- RAZAS
	RaceV2 = {
		Name = "Race V2",
		Category = "Race",
		Requirements = {
			Level = 300,
			Money = 500000,
			FragmentsV2 = 1000,
		},
		Reward = "Raza V2",
		Priority = 4,
	},
	
	RaceV3 = {
		Name = "Race V3",
		Category = "Race",
		Requirements = {
			Level = 750,
			Money = 1500000,
			FragmentsV3 = 2500,
		},
		Reward = "Raza V3",
		Priority = 5,
	},
	
	RaceV4 = {
		Name = "Race V4",
		Category = "Race",
		Requirements = {
			Level = 2000,
			Money = 5000000,
			FragmentsV4 = 5000,
		},
		Reward = "Raza V4",
		Priority = 7,
	},
	
	-- OBJETIVOS COMPLEJOS
	Godhuman = {
		Name = "Godhuman",
		Category = "ComplexObjective",
		Requirements = {
			Level = 2550,
			Money = 5000000,
			Fragments = 5000,
			MeleeMastery = 400,
			CombatMastery = 300,
		},
		Reward = "Técnica Godhuman - Poder supremo",
		Priority = 10,
	},
	
	SharkmanKarate = {
		Name = "Sharkman Karate",
		Category = "FightingStyle",
		Requirements = {
			Level = 800,
			Money = 500000,
			Fragments = 500,
		},
		Reward = "Estilo Karate Hombre Tiburón",
		Priority = 5,
	},
	
	AssassinMainMastery = {
		Name = "Assassin Main Mastery",
		Category = "FightingStyle",
		Requirements = {
			Level = 300,
			Money = 100000,
		},
		Reward = "Maestría en Asesinato",
		Priority = 3,
	},
}

--[[
	Base de datos de armas y objetos
]]
Database.Items = {
	Saber = { Price = 25000, Level = 1, Rarity = "Common" },
	Katana = { Price = 50000, Level = 60, Rarity = "Common" },
	SharkAnchor = { Price = 500000, Level = 300, Rarity = "Rare" },
	SkullGuitar = { Price = 3000000, Level = 1900, Rarity = "Rare" },
	MirrorFractal = { Price = 5000000, Level = 2300, Rarity = "Epic" },
	CursedDualKatana = { Price = 5000000, Level = 2200, Rarity = "Epic" },
	Rengoku = { Price = 1500000, Level = 1500, Rarity = "Legendary" },
	DragonTrident = { Price = 7000000, Level = 2550, Rarity = "Legendary" },
	GravityBlade = { Price = 6000000, Level = 2400, Rarity = "Legendary" },
	PoleFirstForm = { Price = 5500000, Level = 2250, Rarity = "Legendary" },
}

--[[
	Base de datos de frutas
]]
Database.Fruits = {
	Diamond = { Price = 1000000, Level = 500, Type = "Logia" },
	Buddha = { Price = 2500000, Level = 1500, Type = "Mythical" },
	Leopard = { Price = 5000000, Level = 2550, Type = "Mythical" },
	Phoenix = { Price = 5000000, Level = 2600, Type = "Mythical" },
	Mammoth = { Price = 2000000, Level = 1000, Type = "Zoan" },
}

--[[
	Base de datos de requisitos de mastery
]]
Database.MasteryRequirements = {
	MeleeMastery = {
		Level400 = { Level = 400, Money = 1000000, Fragments = 2000 },
		Level500 = { Level = 500, Money = 2000000, Fragments = 5000 },
	},
	SwordMastery = {
		Level400 = { Level = 400, Money = 1000000, Fragments = 2000 },
		Level500 = { Level = 500, Money = 2000000, Fragments = 5000 },
	},
	FruitMastery = {
		Level400 = { Level = 400, Money = 1000000, Fragments = 2000 },
		Level500 = { Level = 500, Money = 2000000, Fragments = 5000 },
	},
	GunMastery = {
		Level400 = { Level = 400, Money = 1000000, Fragments = 2000 },
		Level500 = { Level = 500, Money = 2000000, Fragments = 5000 },
	},
}

--[[
	Obtiene un objetivo por nombre
]]
function Database:GetObjective(objectiveName: string)
	return self.Objectives[objectiveName]
end

--[[
	Obtiene todos los objetivos
]]
function Database:GetAllObjectives()
	return table.clone(self.Objectives)
end

--[[
	Obtiene los objetivos ordenados por prioridad
]]
function Database:GetObjectivesByPriority()
	local objectives = {}
	
	for name, objective in pairs(self.Objectives) do
		table.insert(objectives, {
			Name = name,
			Priority = objective.Priority,
			Objective = objective,
		})
	end
	
	table.sort(objectives, function(a, b)
		return a.Priority < b.Priority
	end)
	
	return objectives
end

--[[
	Obtiene un objeto por nombre
]]
function Database:GetItem(itemName: string)
	return self.Items[itemName]
end

--[[
	Obtiene una fruta por nombre
]]
function Database:GetFruit(fruitName: string)
	return self.Fruits[fruitName]
end

--[[
	Obtiene requisitos de mastery
]]
function Database:GetMasteryRequirement(masteryName: string, level: string)
	if self.MasteryRequirements[masteryName] then
		return self.MasteryRequirements[masteryName][level]
	end
	return nil
end

--[[
	Busca objetivos por categoría
]]
function Database:GetObjectivesByCategory(category: string)
	local result = {}
	
	for name, objective in pairs(self.Objectives) do
		if objective.Category == category then
			result[name] = objective
		end
	end
	
	return result
end

--[[
	Obtiene todos los requisitos de un objetivo
]]
function Database:GetObjectiveRequirements(objectiveName: string): { [string]: number }?
	local objective = self:GetObjective(objectiveName)
	if objective then
		return table.clone(objective.Requirements)
	end
	return nil
end

--[[
	Verifica si un objetivo existe
]]
function Database:ObjectiveExists(objectiveName: string): boolean
	return self.Objectives[objectiveName] ~= nil
end

--[[
	Obtiene el precio de un objeto
]]
function Database:GetItemPrice(itemName: string): number?
	local item = self:GetItem(itemName)
	if item then
		return item.Price
	end
	return nil
end

--[[
	Obtiene el nivel requerido para un objeto
]]
function Database:GetItemLevel(itemName: string): number?
	local item = self:GetItem(itemName)
	if item then
		return item.Level
	end
	return nil
end

return Database
