--[[
	StateManager.luau
	Gestor centralizado del estado del jugador en Blox Fruits
	Almacena toda la información del jugador en una sola fuente de verdad
]]

local StateManager = {}
StateManager.__index = StateManager

export type PlayerState = {
	-- Stats básicos
	Level: number,
	Money: number,
	Fragments: number,
	Health: number,
	MaxHealth: number,
	
	-- Razas
	Race: string,
	RaceVersion: number,
	
	-- Frutas
	Fruits: { [string]: boolean },
	CurrentFruit: string?,
	
	-- Armas
	Weapons: { [string]: boolean },
	
	-- Estilos de lucha
	FightingStyles: { [string]: { Level: number, Progress: number } },
	
	-- Mastery (dominio)
	Mastery: { [string]: { Level: number, Progress: number } },
	
	-- Haki
	Haki: { [string]: boolean },
	
	-- Objetivos
	CurrentObjective: string?,
	CurrentTask: string?,
	CompletedObjectives: { [string]: boolean },
	
	-- Meta
	LastUpdate: number,
	SessionStartTime: number,
}

--[[
	Crea una nueva instancia de StateManager
]]
function StateManager.new(): StateManager
	local self = setmetatable({}, StateManager)
	
	self.state = {
		Level = 1,
		Money = 0,
		Fragments = 0,
		Health = 100,
		MaxHealth = 100,
		Race = "Human",
		RaceVersion = 1,
		Fruits = {},
		CurrentFruit = nil,
		Weapons = {},
		FightingStyles = {},
		Mastery = {},
		Haki = {},
		CurrentObjective = nil,
		CurrentTask = nil,
		CompletedObjectives = {},
		LastUpdate = tick(),
		SessionStartTime = tick(),
	} :: PlayerState
	
	self.changedSignal = Instance.new("BindableEvent")
	
	return self
end

--[[
	Obtiene una copia del estado actual
]]
function StateManager:GetState(): PlayerState
	return table.clone(self.state) :: PlayerState
end

--[[
	Actualiza un stat del jugador
	@param statName: nombre del stat (ej: "Money", "Fragments", "Level")
	@param value: nuevo valor
	@param isDelta: si es true, suma al valor actual en lugar de reemplazar
]]
function StateManager:UpdateStat(statName: string, value: number, isDelta: boolean?): boolean
	if not self.state[statName] or typeof(self.state[statName]) ~= "number" then
		return false
	end
	
	local oldValue = self.state[statName]
	local newValue = if isDelta then oldValue + value else value
	
	self.state[statName] = newValue
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "StatUpdated",
		Stat = statName,
		OldValue = oldValue,
		NewValue = newValue,
	})
	
	return true
end

--[[
	Establece la raza del jugador
]]
function StateManager:SetRace(raceName: string, version: number?): boolean
	self.state.Race = raceName
	self.state.RaceVersion = version or 1
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "RaceChanged",
		Race = raceName,
		Version = version,
	})
	
	return true
end

--[[
	Añade una fruta al inventario
]]
function StateManager:AddFruit(fruitName: string): boolean
	self.state.Fruits[fruitName] = true
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "FruitAdded",
		Fruit = fruitName,
	})
	
	return true
end

--[[
	Establece la fruta activa actual
]]
function StateManager:SetCurrentFruit(fruitName: string?): boolean
	self.state.CurrentFruit = fruitName
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "FruitChanged",
		Fruit = fruitName,
	})
	
	return true
end

--[[
	Añade un arma al inventario
]]
function StateManager:AddWeapon(weaponName: string): boolean
	self.state.Weapons[weaponName] = true
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "WeaponAdded",
		Weapon = weaponName,
	})
	
	return true
end

--[[
	Actualiza el nivel de mastery
]]
function StateManager:UpdateMastery(masteryName: string, level: number, progress: number?): boolean
	self.state.Mastery[masteryName] = {
		Level = level,
		Progress = progress or 0,
	}
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "MasteryUpdated",
		Mastery = masteryName,
		Level = level,
	})
	
	return true
end

--[[
	Desbloquea un Haki
]]
function StateManager:UnlockHaki(hakiName: string): boolean
	self.state.Haki[hakiName] = true
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "HakiUnlocked",
		Haki = hakiName,
	})
	
	return true
end

--[[
	Establece el objetivo actual
]]
function StateManager:SetCurrentObjective(objectiveName: string?): boolean
	self.state.CurrentObjective = objectiveName
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "ObjectiveChanged",
		Objective = objectiveName,
	})
	
	return true
end

--[[
	Establece la tarea actual
]]
function StateManager:SetCurrentTask(taskName: string?): boolean
	self.state.CurrentTask = taskName
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "TaskChanged",
		Task = taskName,
	})
	
	return true
end

--[[
	Marca un objetivo como completado
]]
function StateManager:CompleteObjective(objectiveName: string): boolean
	self.state.CompletedObjectives[objectiveName] = true
	self.state.LastUpdate = tick()
	
	self.changedSignal:Fire({
		Type = "ObjectiveCompleted",
		Objective = objectiveName,
	})
	
	return true
end

--[[
	Verifica si el jugador posee una fruta
]]
function StateManager:OwnsFruit(fruitName: string): boolean
	return self.state.Fruits[fruitName] == true
end

--[[
	Verifica si el jugador posee un arma
]]
function StateManager:OwnsWeapon(weaponName: string): boolean
	return self.state.Weapons[weaponName] == true
end

--[[
	Verifica si un objetivo ya fue completado
]]
function StateManager:IsObjectiveCompleted(objectiveName: string): boolean
	return self.state.CompletedObjectives[objectiveName] == true
end

--[[
	Sincroniza el estado con datos del jugador en el juego
	Se llama periódicamente para mantener la información actualizada
]]
function StateManager:SyncWithGame(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	
	if humanoid then
		self:UpdateStat("Health", humanoid.Health)
		self:UpdateStat("MaxHealth", humanoid.MaxHealth)
	end
	
	return true
end

--[[
	Conecta una función a los cambios de estado
]]
function StateManager:OnChanged(callback: (change: any) -> ()): RBXScriptConnection
	return self.changedSignal.Event:Connect(callback)
end

return StateManager
