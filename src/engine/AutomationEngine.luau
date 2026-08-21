--[[
	AutomationEngine.luau
	Motor principal de automatización que orquesta todos los sistemas
	Coordina: StateManager, TaskManager, FarmingManager, RequirementManager
]]

local AutomationEngine = {}
AutomationEngine.__index = AutomationEngine

export type EngineConfig = {
	AutoStart: boolean,
	MaxConcurrentTasks: number,
	UpdateInterval: number,
	LogLevel: string,
	EnableNotifications: boolean,
	PauseOnDeath: boolean,
	MaxSessionDuration: number,
}

export type EngineState = {
	IsRunning: boolean,
	CurrentObjective: string?,
	ActiveTasks: number,
	SessionStartTime: number?,
	TotalTasksCompleted: number,
	TotalProgressMade: number,
}

--[[
	Crea una nueva instancia de AutomationEngine
]]
function AutomationEngine.new(
	stateManager: any,
	taskManager: any,
	farmingManager: any,
	requirementManager: any,
	logger: any
): AutomationEngine
	local self = setmetatable({}, AutomationEngine)
	
	self.stateManager = stateManager
	self.taskManager = taskManager
	self.farmingManager = farmingManager
	self.requirementManager = requirementManager
	self.logger = logger
	
	-- Configuración
	self.config = {
		AutoStart = true,
		MaxConcurrentTasks = 3,
		UpdateInterval = 1,
		LogLevel = "Info",
		EnableNotifications = true,
		PauseOnDeath = true,
		MaxSessionDuration = 3600, -- 1 hora
	}
	
	-- Estado del motor
	self.engineState = {
		IsRunning = false,
		CurrentObjective = nil,
		ActiveTasks = 0,
		SessionStartTime = nil,
		TotalTasksCompleted = 0,
		TotalProgressMade = 0,
	}
	
	-- Control
	self.mainLoop = nil
	self.eventConnections = {}
	self.engineSignal = Instance.new("BindableEvent")
	
	return self
end

--[[
	Inicia el motor de automatización
]]
function AutomationEngine:Start(objectiveName: string?): boolean
	if self.engineState.IsRunning then
		self.logger:Warn("El motor ya está ejecutándose", nil, "AutomationEngine")
		return false
	end
	
	self.engineState.IsRunning = true
	self.engineState.SessionStartTime = tick()
	self.engineState.CurrentObjective = objectiveName or "DefaultObjective"
	
	self.logger:Info(
		string.format("Motor de automatización iniciado. Objetivo: %s", self.engineState.CurrentObjective),
		nil,
		"AutomationEngine"
	)
	
	self:_ConnectEvents()
	self:_StartMainLoop()
	
	self.engineSignal:Fire({
		Type = "EngineStarted",
		Objective = self.engineState.CurrentObjective,
	})
	
	return true
end

--[[
	Detiene el motor de automatización
]]
function AutomationEngine:Stop(): boolean
	if not self.engineState.IsRunning then
		return false
	end
	
	self.engineState.IsRunning = false
	self:_DisconnectEvents()
	self:_StopMainLoop()
	
	local sessionDuration = tick() - (self.engineState.SessionStartTime or 0)
	
	self.logger:Info(
		string.format(
			"Motor detenido. Sesión: %.1f min | Tareas completadas: %d | Progreso: %.1f%%",
			sessionDuration / 60,
			self.engineState.TotalTasksCompleted,
			self.engineState.TotalProgressMade / math.max(1, self.engineState.TotalTasksCompleted) * 100
		),
		nil,
		"AutomationEngine"
	)
	
	self.engineSignal:Fire({
		Type = "EngineStopped",
		Duration = sessionDuration,
	})
	
	return true
end

--[[
	Pausa el motor temporalmente
]]
function AutomationEngine:Pause(): boolean
	if not self.engineState.IsRunning then
		return false
	end
	
	self.engineState.IsRunning = false
	
	self.logger:Info("Motor pausado", nil, "AutomationEngine")
	self.engineSignal:Fire({ Type = "EnginePaused" })
	
	return true
end

--[[
	Reanuda el motor desde pausa
]]
function AutomationEngine:Resume(): boolean
	if self.engineState.IsRunning then
		return false
	end
	
	self.engineState.IsRunning = true
	
	self.logger:Info("Motor reanudado", nil, "AutomationEngine")
	self.engineSignal:Fire({ Type = "EngineResumed" })
	
	return true
end

--[[
	Bucle principal del motor
]]
function AutomationEngine:_StartMainLoop(): boolean
	if self.mainLoop then
		return false
	end
	
	self.mainLoop = task.spawn(function()
		while self.engineState.IsRunning do
			self:_UpdateCycle()
			task.wait(self.config.UpdateInterval)
		end
	end)
	
	return true
end

--[[
	Detiene el bucle principal
]]
function AutomationEngine:_StopMainLoop(): boolean
	if self.mainLoop then
		task.cancel(self.mainLoop)
		self.mainLoop = nil
	end
	
	return true
end

--[[
	Ciclo de actualización principal
]]
function AutomationEngine:_UpdateCycle(): boolean
	-- Verificar estado de sesión
	if self.engineState.SessionStartTime then
		local sessionDuration = tick() - self.engineState.SessionStartTime
		if sessionDuration > self.config.MaxSessionDuration then
			self.logger:Info("Duración máxima de sesión alcanzada", nil, "AutomationEngine")
			self:Stop()
			return false
		end
	end
	
	-- Obtener estado actual del jugador
	local state = self.stateManager:GetState()
	
	-- Verificar si hay una tarea activa
	local currentTask = self.taskManager:GetCurrentTask()
	
	if currentTask then
		-- Actualizar progreso de tarea actual
		self:_UpdateActiveTask(currentTask)
	else
		-- Generar nueva tarea
		local nextTask = self.taskManager:GenerateNextTask(self.engineState.CurrentObjective)
		
		if nextTask then
			self.taskManager:SetCurrentTask(nextTask)
			
			-- Iniciar sesión de farming
			local strategy = self.farmingManager:GetBestStrategy(
				nextTask.TargetRequirement,
				state.Level
			)
			
			if strategy then
				self.farmingManager:StartFarmingSession(nextTask.Type, strategy.Location)
			end
		else
			-- Objetivo completado
			if self.engineState.CurrentObjective then
				local objective = self.requirementManager:AnalyzeObjective(self.engineState.CurrentObjective)
				
				if objective and objective.AllRequirementsMet then
					self.logger:Info(
						string.format("¡Objetivo completado: %s!", self.engineState.CurrentObjective),
						nil,
						"AutomationEngine"
					)
					
					self.engineSignal:Fire({
						Type = "ObjectiveCompleted",
						Objective = self.engineState.CurrentObjective,
					})
					
					self:Stop()
					return false
				end
			end
		end
	end
	
	return true
end

--[[
	Actualiza una tarea activa
]]
function AutomationEngine:_UpdateActiveTask(task: any): boolean
	-- Simular progreso de la tarea
	local progressIncrement = math.random(5, 15)
	task.Progress = math.min(task.Progress + progressIncrement, 100)
	
	self.taskManager:UpdateTaskProgress(task.Progress)
	
	-- Simular ganancia de recursos basado en el tipo de tarea
	local state = self.stateManager:GetState()
	self:_SimulateResourceGain(task, state)
	
	-- Completar tarea si llegó al 100%
	if task.Progress >= 100 then
		self.taskManager:CompleteCurrentTask()
		self.engineState.TotalTasksCompleted = self.engineState.TotalTasksCompleted + 1
		self.engineState.TotalProgressMade = self.engineState.TotalProgressMade + 1
		
		self.engineSignal:Fire({
			Type = "TaskCompleted",
			Task = task,
		})
	end
	
	return true
end

--[[
	Simula la ganancia de recursos
]]
function AutomationEngine:_SimulateResourceGain(task: any, state: any): boolean
	if task.Type == "FarmExp" then
		self.stateManager:AddExperience(math.random(100, 300))
	elseif task.Type == "FarmMoney" then
		self.stateManager:AddMoney(math.random(5000, 15000))
	elseif task.Type == "FarmFragments" then
		self.stateManager:AddFragments(math.random(1, 5))
	elseif string.find(task.Type, "Mastery") then
		local masteryType = string.match(task.Type, "Farm(%w+)Mastery")
		if masteryType then
			self.stateManager:AddMastery(masteryType, math.random(10, 50))
		end
	end
	
	return true
end

--[[
	Conecta los eventos del sistema
]]
function AutomationEngine:_ConnectEvents(): boolean
	-- Eventos de estado
	table.insert(self.eventConnections, self.stateManager:OnStateChange(function(event)
		if event.Type == "LevelUp" then
			self.engineSignal:Fire({
				Type = "PlayerLeveledUp",
				Level = event.Level,
			})
		end
	end))
	
	-- Eventos de tarea
	table.insert(self.eventConnections, self.taskManager:OnTaskEvent(function(event)
		if event.Type == "TaskCompleted" then
			self.engineSignal:Fire({
				Type = "TaskProgressUpdated",
				Task = event.Task,
			})
		end
	end))
	
	-- Eventos de farming
	table.insert(self.eventConnections, self.farmingManager:OnFarmingEvent(function(event)
		if event.Type == "SessionEnded" then
			self.logger:Info(
				string.format("Sesión de farming completada: %s", event.Session.Type),
				nil,
				"AutomationEngine"
			)
		end
	end))
	
	return true
end

--[[
	Desconecta todos los eventos
]]
function AutomationEngine:_DisconnectEvents(): boolean
	for _, connection in ipairs(self.eventConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	
	self.eventConnections = {}
	
	return true
end

--[[
	Obtiene el estado del motor
]]
function AutomationEngine:GetEngineState(): EngineState
	return table.clone(self.engineState)
end

--[[
	Actualiza la configuración del motor
]]
function AutomationEngine:SetConfig(newConfig: Partial<EngineConfig>): boolean
	for key, value in pairs(newConfig) do
		if self.config[key] ~= nil then
			self.config[key] = value
		end
	end
	
	self.logger:Info("Configuración actualizada", newConfig, "AutomationEngine")
	
	return true
end

--[[
	Obtiene la configuración actual
]]
function AutomationEngine:GetConfig(): EngineConfig
	return table.clone(self.config)
end

--[[
	Cambia el objetivo actual
]]
function AutomationEngine:SetObjective(objectiveName: string): boolean
	self.engineState.CurrentObjective = objectiveName
	
	self.logger:Info(
		string.format("Objetivo cambiado a: %s", objectiveName),
		nil,
		"AutomationEngine"
	)
	
	self.engineSignal:Fire({
		Type = "ObjectiveChanged",
		Objective = objectiveName,
	})
	
	return true
end

--[[
	Conecta una función a eventos del motor
]]
function AutomationEngine:OnEngineEvent(callback: (event: any) -> ()): RBXScriptConnection
	return self.engineSignal.Event:Connect(callback)
end

--[[
	Genera un reporte de estado del motor
]]
function AutomationEngine:GenerateEngineReport(): string
	local state = self.engineState
	local sessionDuration = state.SessionStartTime and (tick() - state.SessionStartTime) or 0
	
	return string.format(
		"=== REPORTE DEL MOTOR ===\n" ..
		"Estado: %s\n" ..
		"Objetivo: %s\n" ..
		"Duración: %.1f min\n" ..
		"Tareas Completadas: %d\n" ..
		"Progreso Total: %.1f%%\n" ..
		"Tareas Activas: %d",
		state.IsRunning and "Ejecutando" or "Detenido",
		state.CurrentObjective or "Ninguno",
		sessionDuration / 60,
		state.TotalTasksCompleted,
		state.TotalProgressMade / math.max(1, state.TotalTasksCompleted) * 100,
		state.ActiveTasks
	)
end

--[[
	Obtiene estadísticas completas del sistema
]]
function AutomationEngine:GetSystemStatistics(): { [string]: any }
	local taskStats = self.taskManager:GetTaskStatistics()
	local farmingStats = self.farmingManager:GetFarmingStatistics()
	local engineStats = self:GetEngineState()
	
	return {
		Engine = engineStats,
		Tasks = taskStats,
		Farming = farmingStats,
		TotalTimeRunning = engineStats.SessionStartTime and (tick() - engineStats.SessionStartTime) or 0,
	}
end

return AutomationEngine
