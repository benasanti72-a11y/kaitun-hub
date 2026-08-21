--[[
	FarmingManager.luau
	Sistema completo de farming automático para Blox Fruits
	Gestiona todos los tipos de farming: dinero, exp, fragmentos, mastery
]]

local FarmingManager = {}
FarmingManager.__index = FarmingManager

export type FarmingSession = {
	Type: string,
	Target: string,
	StartTime: number,
	Duration: number,
	AmountGained: number,
	RatePerMinute: number,
	Status: string,
}

export type FarmingStrategy = {
	Name: string,
	TargetLevel: number,
	Location: string,
	Enemy: string,
	EstimatedRatePerMinute: number,
	Requirements: { [string]: number },
}

--[[
	Crea una nueva instancia de FarmingManager
]]
function FarmingManager.new(
	stateManager: any,
	taskManager: any,
	logger: any
): FarmingManager
	local self = setmetatable({}, FarmingManager)
	
	self.stateManager = stateManager
	self.taskManager = taskManager
	self.logger = logger
	
	self.activeSessions = {}
	self.sessionHistory = {}
	self.farmingSignal = Instance.new("BindableEvent")
	
	-- Estrategias de farming predefinidas
	self.strategies = self:_InitializeStrategies()
	
	return self
end

--[[
	Inicializa todas las estrategias de farming disponibles
]]
function FarmingManager:_InitializeStrategies(): { [string]: FarmingStrategy }
	return {
		-- Farming de EXP
		ExpLv1To100 = {
			Name = "Exp Level 1-100",
			TargetLevel = 100,
			Location = "Village",
			Enemy = "Bandit",
			EstimatedRatePerMinute = 150,
			Requirements = { Level = 1 },
		},
		
		ExpLv100To300 = {
			Name = "Exp Level 100-300",
			TargetLevel = 300,
			Location = "Marine Base",
			Enemy = "Marine Soldier",
			EstimatedRatePerMinute = 300,
			Requirements = { Level = 100 },
		},
		
		ExpLv300To750 = {
			Name = "Exp Level 300-750",
			TargetLevel = 750,
			Location = "Jungle",
			Enemy = "Jungle Warrior",
			EstimatedRatePerMinute = 500,
			Requirements = { Level = 300 },
		},
		
		ExpLv750To1500 = {
			Name = "Exp Level 750-1500",
			TargetLevel = 1500,
			Location = "Colosseum",
			Enemy = "Colosseum Beast",
			EstimatedRatePerMinute = 800,
			Requirements = { Level = 750 },
		},
		
		ExpLv1500To2550 = {
			Name = "Exp Level 1500-2550",
			TargetLevel = 2550,
			Location = "Underwater City",
			Enemy = "Elite Warrior",
			EstimatedRatePerMinute = 1200,
			Requirements = { Level = 1500 },
		},
		
		-- Farming de Dinero
		MoneyLv1To100 = {
			Name = "Money Level 1-100",
			TargetLevel = 100,
			Location = "Village",
			Enemy = "Bandit",
			EstimatedRatePerMinute = 5000,
			Requirements = { Level = 1 },
		},
		
		MoneyLv100To300 = {
			Name = "Money Level 100-300",
			TargetLevel = 300,
			Location = "Marine Base",
			Enemy = "Marine Soldier",
			EstimatedRatePerMinute = 15000,
			Requirements = { Level = 100 },
		},
		
		MoneyLv300To750 = {
			Name = "Money Level 300-750",
			TargetLevel = 750,
			Location = "Jungle",
			Enemy = "Jungle Warrior",
			EstimatedRatePerMinute = 35000,
			Requirements = { Level = 300 },
		},
		
		MoneyLv750To1500 = {
			Name = "Money Level 750-1500",
			TargetLevel = 1500,
			Location = "Colosseum",
			Enemy = "Colosseum Beast",
			EstimatedRatePerMinute = 70000,
			Requirements = { Level = 750 },
		},
		
		MoneyLv1500To2550 = {
			Name = "Money Level 1500-2550",
			TargetLevel = 2550,
			Location = "Underwater City",
			Enemy = "Elite Warrior",
			EstimatedRatePerMinute = 150000,
			Requirements = { Level = 1500 },
		},
		
		-- Farming de Fragmentos
		FragmentsFarmEasy = {
			Name = "Fragments Farm Easy",
			TargetLevel = 300,
			Location = "Jungle",
			Enemy = "Jungle Beast",
			EstimatedRatePerMinute = 20,
			Requirements = { Level = 200 },
		},
		
		FragmentsFarmMedium = {
			Name = "Fragments Farm Medium",
			TargetLevel = 1000,
			Location = "Snow Island",
			Enemy = "Snow Beast",
			EstimatedRatePerMinute = 50,
			Requirements = { Level = 750 },
		},
		
		FragmentsFarmHard = {
			Name = "Fragments Farm Hard",
			TargetLevel = 2550,
			Location = "Underwater City",
			Enemy = "Corrupted Creature",
			EstimatedRatePerMinute = 100,
			Requirements = { Level = 1500 },
		},
		
		-- Farming de Mastery
		MeleeMasteryFarm = {
			Name = "Melee Mastery Farm",
			TargetLevel = 2550,
			Location = "Colosseum",
			Enemy = "Melee Master",
			EstimatedRatePerMinute = 30,
			Requirements = { Level = 300 },
		},
		
		SwordMasteryFarm = {
			Name = "Sword Mastery Farm",
			TargetLevel = 2550,
			Location = "Underwater City",
			Enemy = "Swordsman",
			EstimatedRatePerMinute = 25,
			Requirements = { Level = 300 },
		},
		
		FruitMasteryFarm = {
			Name = "Fruit Mastery Farm",
			TargetLevel = 2550,
			Location = "Mountain",
			Enemy = "Fruit User",
			EstimatedRatePerMinute = 20,
			Requirements = { Level = 300 },
		},
		
		GunMasteryFarm = {
			Name = "Gun Mastery Farm",
			TargetLevel = 2550,
			Location = "Desert",
			Enemy = "Gunner",
			EstimatedRatePerMinute = 15,
			Requirements = { Level = 300 },
		},
	}
end

--[[
	Obtiene la mejor estrategia para un objetivo específico
]]
function FarmingManager:GetBestStrategy(targetRequirement: string, currentLevel: number): FarmingStrategy?
	local bestStrategy: FarmingStrategy? = nil
	
	for _, strategy in pairs(self.strategies) do
		-- Filtrar por tipo de requisito
		if string.find(strategy.Name, targetRequirement) == nil then
			continue
		end
		
		-- Verificar que el jugador cumpla los requisitos
		if currentLevel < strategy.Requirements.Level then
			continue
		end
		
		-- Seleccionar la estrategia más óptima
		if bestStrategy == nil or strategy.EstimatedRatePerMinute > bestStrategy.EstimatedRatePerMinute then
			bestStrategy = strategy
		end
	end
	
	return bestStrategy
end

--[[
	Inicia una sesión de farming
]]
function FarmingManager:StartFarmingSession(farmingType: string, target: string): FarmingSession?
	if #self.activeSessions >= 5 then
		self.logger:Warn("Demasiadas sesiones activas", nil, "FarmingManager")
		return nil
	end
	
	local session: FarmingSession = {
		Type = farmingType,
		Target = target,
		StartTime = tick(),
		Duration = 0,
		AmountGained = 0,
		RatePerMinute = 0,
		Status = "Active",
	}
	
	table.insert(self.activeSessions, session)
	
	self.logger:Info(
		string.format("Sesión de farming iniciada: %s", farmingType),
		{ Target = target },
		"FarmingManager"
	)
	
	self.farmingSignal:Fire({
		Type = "SessionStarted",
		Session = session,
	})
	
	return session
end

--[[
	Termina una sesión de farming
]]
function FarmingManager:EndFarmingSession(session: FarmingSession): boolean
	session.Status = "Completed"
	session.Duration = tick() - session.StartTime
	
	if session.Duration > 0 then
		session.RatePerMinute = (session.AmountGained / session.Duration) * 60
	end
	
	table.insert(self.sessionHistory, session)
	
	-- Remover de sesiones activas
	for i, activeSes in ipairs(self.activeSessions) do
		if activeSes == session then
			table.remove(self.activeSessions, i)
			break
		end
	end
	
	self.logger:Info(
		string.format("Sesión de farming completada: %s | Ganado: %d | Tasa: %.0f/min", 
			session.Type, session.AmountGained, session.RatePerMinute),
		nil,
		"FarmingManager"
	)
	
	self.farmingSignal:Fire({
		Type = "SessionEnded",
		Session = session,
	})
	
	return true
end

--[[
	Actualiza el progreso de una sesión
]]
function FarmingManager:UpdateSessionProgress(session: FarmingSession, amountGained: number): boolean
	session.AmountGained = session.AmountGained + amountGained
	session.Duration = tick() - session.StartTime
	
	if session.Duration > 0 then
		session.RatePerMinute = (session.AmountGained / session.Duration) * 60
	end
	
	self.farmingSignal:Fire({
		Type = "SessionProgressUpdated",
		Session = session,
	})
	
	return true
end

--[[
	Obtiene todas las sesiones activas
]]
function FarmingManager:GetActiveSessions(): { FarmingSession }
	return table.clone(self.activeSessions)
end

--[[
	Obtiene el historial de sesiones
]]
function FarmingManager:GetSessionHistory(count: number?): { FarmingSession }
	local limit = count or 10
	local result = {}
	
	for i = math.max(1, #self.sessionHistory - limit + 1), #self.sessionHistory do
		table.insert(result, self.sessionHistory[i])
	end
	
	return result
end

--[[
	Calcula cuánto tiempo se necesita para alcanzar una cantidad
]]
function FarmingManager:CalculateTimeNeeded(farmingType: string, amountNeeded: number, ratePerMinute: number): number
	if ratePerMinute <= 0 then
		return math.huge
	end
	
	return (amountNeeded / ratePerMinute)
end

--[[
	Obtiene estadísticas de farming
]]
function FarmingManager:GetFarmingStatistics(): { [string]: any }
	local totalSessions = #self.sessionHistory
	local totalAmountGained = 0
	local totalTimeSpent = 0
	local averageRate = 0
	
	for _, session in ipairs(self.sessionHistory) do
		totalAmountGained = totalAmountGained + session.AmountGained
		totalTimeSpent = totalTimeSpent + session.Duration
	end
	
	if totalTimeSpent > 0 then
		averageRate = (totalAmountGained / totalTimeSpent) * 60
	end
	
	return {
		TotalSessions = totalSessions,
		TotalAmountGained = totalAmountGained,
		TotalTimeSpent = totalTimeSpent,
		AverageRatePerMinute = averageRate,
		ActiveSessions = #self.activeSessions,
	}
end

--[[
	Conecta una función a eventos de farming
]]
function FarmingManager:OnFarmingEvent(callback: (event: any) -> ()): RBXScriptConnection
	return self.farmingSignal.Event:Connect(callback)
end

--[[
	Genera un reporte de sesión
]]
function FarmingManager:GenerateSessionReport(session: FarmingSession): string
	local durationMinutes = session.Duration / 60
	
	return string.format(
		"Tipo: %s\nTarget: %s\nDuración: %.1f min\nGanado: %d\nTasa: %.0f/min",
		session.Type,
		session.Target,
		durationMinutes,
		session.AmountGained,
		session.RatePerMinute
	)
end

--[[
	Obtiene todas las estrategias disponibles
]]
function FarmingManager:GetAllStrategies(): { [string]: FarmingStrategy }
	return table.clone(self.strategies)
end

--[[
	Recomenda una estrategia basada en el nivel actual
]]
function FarmingManager:RecommendStrategy(targetRequirement: string, currentLevel: number): FarmingStrategy?
	return self:GetBestStrategy(targetRequirement, currentLevel)
end

return FarmingManager
