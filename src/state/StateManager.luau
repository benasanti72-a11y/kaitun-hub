--[[
	StateManager.luau
	Gestor centralizado del estado del jugador
	Mantiene sincronizado el estado con el servidor de Blox Fruits
]]

local StateManager = {}
StateManager.__index = StateManager

export type PlayerState = {
	Level: number,
	Experience: number,
	Money: number,
	Health: number,
	MaxHealth: number,
	Fragments: number,
	Inventory: { [string]: number },
	Mastery: {
		Melee: { Level: number, Experience: number },
		Sword: { Level: number, Experience: number },
		Fruit: { Level: number, Experience: number },
		Gun: { Level: number, Experience: number },
		Combat: { Level: number, Experience: number },
	},
	CurrentFruit: string?,
	CurrentWeapon: string?,
	CurrentRace: string?,
	Location: string,
	Timestamp: number,
}

--[[
	Crea una nueva instancia de StateManager
]]
function StateManager.new(logger: any): StateManager
	local self = setmetatable({}, StateManager)
	
	self.logger = logger
	self.state = self:_CreateEmptyState()
	self.stateHistory = {}
	self.maxHistorySize = 50
	self.updateSignal = Instance.new("BindableEvent")
	
	return self
end

--[[
	Crea un estado vacío
]]
function StateManager:_CreateEmptyState(): PlayerState
	return {
		Level = 0,
		Experience = 0,
		Money = 0,
		Health = 0,
		MaxHealth = 0,
		Fragments = 0,
		Inventory = {},
		Mastery = {
			Melee = { Level = 0, Experience = 0 },
			Sword = { Level = 0, Experience = 0 },
			Fruit = { Level = 0, Experience = 0 },
			Gun = { Level = 0, Experience = 0 },
			Combat = { Level = 0, Experience = 0 },
		},
		CurrentFruit = nil,
		CurrentWeapon = nil,
		CurrentRace = nil,
		Location = "Village",
		Timestamp = tick(),
	}
end

--[[
	Obtiene el estado actual
]]
function StateManager:GetState(): PlayerState
	return table.clone(self.state)
end

--[[
	Actualiza un valor específico del estado
]]
function StateManager:UpdateValue(key: string, value: any): boolean
	local oldValue = self.state[key]
	self.state[key] = value
	self.state.Timestamp = tick()
	
	if oldValue ~= value then
		self:_RecordStateChange(key, oldValue, value)
		
		self.updateSignal:Fire({
			Type = "ValueUpdated",
			Key = key,
			OldValue = oldValue,
			NewValue = value,
		})
		
		return true
	end
	
	return false
end

--[[
	Actualiza la experiencia
]]
function StateManager:AddExperience(amount: number): boolean
	local oldExp = self.state.Experience
	self.state.Experience = oldExp + amount
	
	-- Calcular nuevos niveles basado en experiencia
	local newLevel = self:_CalculateLevel(self.state.Experience)
	if newLevel > self.state.Level then
		self.state.Level = newLevel
		
		self.logger:Info(
			string.format("¡Nivel subido! Nuevo nivel: %d", newLevel),
			nil,
			"StateManager"
		)
		
		self.updateSignal:Fire({
			Type = "LevelUp",
			Level = newLevel,
		})
	end
	
	self.state.Timestamp = tick()
	self:_RecordStateChange("Experience", oldExp, self.state.Experience)
	
	return true
end

--[[
	Actualiza el dinero
]]
function StateManager:AddMoney(amount: number): boolean
	local oldMoney = self.state.Money
	self.state.Money = oldMoney + amount
	self.state.Timestamp = tick()
	
	self:_RecordStateChange("Money", oldMoney, self.state.Money)
	
	self.updateSignal:Fire({
		Type = "ValueUpdated",
		Key = "Money",
		OldValue = oldMoney,
		NewValue = self.state.Money,
	})
	
	return true
end

--[[
	Actualiza los fragmentos
]]
function StateManager:AddFragments(amount: number): boolean
	local oldFragments = self.state.Fragments
	self.state.Fragments = oldFragments + amount
	self.state.Timestamp = tick()
	
	self:_RecordStateChange("Fragments", oldFragments, self.state.Fragments)
	
	self.updateSignal:Fire({
		Type = "ValueUpdated",
		Key = "Fragments",
		OldValue = oldFragments,
		NewValue = self.state.Fragments,
	})
	
	return true
end

--[[
	Actualiza el mastery de un tipo
]]
function StateManager:AddMastery(masteryType: string, experience: number): boolean
	if not self.state.Mastery[masteryType] then
		return false
	end
	
	local oldExp = self.state.Mastery[masteryType].Experience
	self.state.Mastery[masteryType].Experience = oldExp + experience
	
	-- Calcular nuevo nivel de mastery
	local newLevel = self:_CalculateMasteryLevel(self.state.Mastery[masteryType].Experience)
	if newLevel > self.state.Mastery[masteryType].Level then
		self.state.Mastery[masteryType].Level = newLevel
		
		self.logger:Info(
			string.format("%s Mastery subió a nivel %d", masteryType, newLevel),
			nil,
			"StateManager"
		)
		
		self.updateSignal:Fire({
			Type = "MasteryLevelUp",
			MasteryType = masteryType,
			Level = newLevel,
		})
	end
	
	self.state.Timestamp = tick()
	self:_RecordStateChange("Mastery." .. masteryType, oldExp, self.state.Mastery[masteryType].Experience)
	
	return true
end

--[[
	Actualiza el inventario
]]
function StateManager:UpdateInventory(itemName: string, quantity: number): boolean
	local oldQuantity = self.state.Inventory[itemName] or 0
	self.state.Inventory[itemName] = quantity
	self.state.Timestamp = tick()
	
	if oldQuantity ~= quantity then
		self:_RecordStateChange("Inventory." .. itemName, oldQuantity, quantity)
		
		self.updateSignal:Fire({
			Type = "InventoryUpdated",
			Item = itemName,
			OldQuantity = oldQuantity,
			NewQuantity = quantity,
		})
		
		return true
	end
	
	return false
end

--[[
	Actualiza la fruta actual
]]
function StateManager:SetCurrentFruit(fruitName: string?): boolean
	local oldFruit = self.state.CurrentFruit
	self.state.CurrentFruit = fruitName
	self.state.Timestamp = tick()
	
	self:_RecordStateChange("CurrentFruit", oldFruit, fruitName)
	
	self.updateSignal:Fire({
		Type = "FruitChanged",
		OldFruit = oldFruit,
		NewFruit = fruitName,
	})
	
	return true
end

--[[
	Actualiza el arma actual
]]
function StateManager:SetCurrentWeapon(weaponName: string?): boolean
	local oldWeapon = self.state.CurrentWeapon
	self.state.CurrentWeapon = weaponName
	self.state.Timestamp = tick()
	
	self:_RecordStateChange("CurrentWeapon", oldWeapon, weaponName)
	
	self.updateSignal:Fire({
		Type = "WeaponChanged",
		OldWeapon = oldWeapon,
		NewWeapon = weaponName,
	})
	
	return true
end

--[[
	Actualiza la raza actual
]]
function StateManager:SetCurrentRace(raceName: string?): boolean
	local oldRace = self.state.CurrentRace
	self.state.CurrentRace = raceName
	self.state.Timestamp = tick()
	
	self:_RecordStateChange("CurrentRace", oldRace, raceName)
	
	self.updateSignal:Fire({
		Type = "RaceChanged",
		OldRace = oldRace,
		NewRace = raceName,
	})
	
	return true
end

--[[
	Actualiza la ubicación
]]
function StateManager:SetLocation(location: string): boolean
	local oldLocation = self.state.Location
	self.state.Location = location
	self.state.Timestamp = tick()
	
	if oldLocation ~= location then
		self:_RecordStateChange("Location", oldLocation, location)
		
		self.updateSignal:Fire({
			Type = "LocationChanged",
			OldLocation = oldLocation,
			NewLocation = location,
		})
		
		return true
	end
	
	return false
end

--[[
	Reemplaza el estado completo
]]
function StateManager:SetFullState(newState: PlayerState): boolean
	self.state = table.clone(newState)
	self.state.Timestamp = tick()
	
	self:_RecordStateChange("FullState", nil, self.state)
	
	self.updateSignal:Fire({
		Type = "FullStateUpdated",
		State = self.state,
	})
	
	return true
end

--[[
	Calcula el nivel basado en la experiencia (fórmula simplificada)
]]
function StateManager:_CalculateLevel(experience: number): number
	-- Fórmula: cada nivel requiere 100 * nivel de experiencia
	local level = 0
	local expNeeded = 100
	local totalExp = 0
	
	while totalExp + expNeeded <= experience do
		totalExp = totalExp + expNeeded
		level = level + 1
		expNeeded = expNeeded + 100
	end
	
	return level
end

--[[
	Calcula el nivel de mastery basado en experiencia
]]
function StateManager:_CalculateMasteryLevel(experience: number): number
	-- Fórmula: cada nivel de mastery requiere 50 * nivel de experiencia
	local level = 0
	local expNeeded = 50
	local totalExp = 0
	
	while totalExp + expNeeded <= experience do
		totalExp = totalExp + expNeeded
		level = level + 1
		expNeeded = expNeeded + 50
	end
	
	return level
end

--[[
	Registra un cambio en el estado
]]
function StateManager:_RecordStateChange(key: string, oldValue: any, newValue: any): boolean
	local record = {
		Timestamp = tick(),
		Key = key,
		OldValue = oldValue,
		NewValue = newValue,
	}
	
	table.insert(self.stateHistory, record)
	
	if #self.stateHistory > self.maxHistorySize then
		table.remove(self.stateHistory, 1)
	end
	
	return true
end

--[[
	Obtiene el historial de cambios
]]
function StateManager:GetStateHistory(count: number?): any
	local limit = count or 10
	local result = {}
	
	for i = math.max(1, #self.stateHistory - limit + 1), #self.stateHistory do
		table.insert(result, self.stateHistory[i])
	end
	
	return result
end

--[[
	Conecta una función a eventos de estado
]]
function StateManager:OnStateChange(callback: (event: any) -> ()): RBXScriptConnection
	return self.updateSignal.Event:Connect(callback)
end

--[[
	Obtiene el progreso hacia el siguiente nivel
]]
function StateManager:GetLevelProgress(): { Current: number, Target: number, Percentage: number }
	local currentLevel = self.state.Level
	local nextLevelExp = (currentLevel + 1) * 100 + (currentLevel * (currentLevel + 1) / 2) * 100
	local currentLevelExp = currentLevel * 100 + (currentLevel * (currentLevel - 1) / 2) * 100
	
	local expInLevel = self.state.Experience - currentLevelExp
	local expNeededForLevel = nextLevelExp - currentLevelExp
	
	return {
		Current = math.max(0, expInLevel),
		Target = expNeededForLevel,
		Percentage = if expNeededForLevel > 0 then (expInLevel / expNeededForLevel) * 100 else 0,
	}
end

return StateManager
