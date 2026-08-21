--[[
	TaskManager.luau
	Gestor de tareas que orquesta el flujo de progresión automática
	Decide qué tarea ejecutar basado en el análisis de requisitos
]]

local TaskManager = {}
TaskManager.__index = TaskManager

export type Task = {
	Name: string,
	Type: string,
	Objective: string,
	TargetRequirement: string,
	TargetAmount: number,
	Status: string,
	Progress: number,
	StartedAt: number,
	CompletedAt: number?,
}

--[[
	Crea una nueva instancia de TaskManager
]]
function TaskManager.new(
	database: any,
	stateManager: any,
	requirementManager: any,
	logger: any
): TaskManager
	local self = setmetatable({}, TaskManager)
	
	self.database = database
	self.stateManager = stateManager
	self.requirementManager = requirementManager
	self.logger = logger
	
	self.currentTask = nil
	self.taskHistory = {}
	self.maxHistorySize = 100
	
	self.taskSignal = Instance.new("BindableEvent")
	
	return self
end

--[[
	Analiza un objetivo y genera la siguiente tarea
	@param objectiveName: nombre del objetivo
	@return Task a ejecutar, o nil si el objetivo está completado
]]
function TaskManager:GenerateNextTask(objectiveName: string): Task?
	if not self.database:ObjectiveExists(objectiveName) then
		self.logger:Error("Objetivo no existe: " .. objectiveName, nil, "TaskManager")
		return nil
	end
	
	-- Verificar si el objetivo está completado
	if self.requirementManager:IsObjectiveComplete(objectiveName) then
		self.logger:Info("Objetivo completado: " .. objectiveName, nil, "TaskManager")
		return nil
	end
	
	-- Obtener el siguiente requisito faltante
	local nextRequirement = self.requirementManager:GetNextMissingRequirement(objectiveName)
	
	if not nextRequirement then
		return nil
	end
	
	-- Generar tarea basada en el requisito faltante
	local task = self:_CreateTaskForRequirement(objectiveName, nextRequirement)
	
	return task
end

--[[
	Crea una tarea específica para un requisito
]]
function TaskManager:_CreateTaskForRequirement(objectiveName: string, requirement: any): Task
	local taskType = self:_DetermineTaskType(requirement.Name)
	
	local task: Task = {
		Name = string.format("Farm%s", requirement.Name),
		Type = taskType,
		Objective = objectiveName,
		TargetRequirement = requirement.Name,
		TargetAmount = requirement.Remaining,
		Status = "Pending",
		Progress = 0,
		StartedAt = tick(),
		CompletedAt = nil,
	}
	
	self.logger:LogTaskEvent(task.Name, "Created", {
		Objective = objectiveName,
		TargetRequirement = requirement.Name,
		TargetAmount = requirement.Remaining,
	})
	
	return task
end

--[[
	Determina el tipo de tarea basado en el requisito
]]
function TaskManager:_DetermineTaskType(requirementName: string): string
	local typeMapping = {
		Level = "FarmExp",
		Money = "FarmMoney",
		Fragments = "FarmFragments",
		MeleeMastery = "FarmMeleeMastery",
		SwordMastery = "FarmSwordMastery",
		FruitMastery = "FarmFruitMastery",
		GunMastery = "FarmGunMastery",
	}
	
	return typeMapping[requirementName] or "FarmGeneric"
end

--[[
	Establece la tarea actual
]]
function TaskManager:SetCurrentTask(task: Task?): boolean
	local oldTask = self.currentTask
	self.currentTask = task
	
	if task then
		task.Status = "Active"
		self.logger:LogTaskEvent(task.Name, "Started", {
			Type = task.Type,
			Objective = task.Objective,
		})
	end
	
	self.taskSignal:Fire({
		Type = "TaskChanged",
		OldTask = oldTask,
		NewTask = task,
	})
	
	return true
end

--[[
	Obtiene la tarea actual
]]
function TaskManager:GetCurrentTask(): Task?
	return self.currentTask
end

--[[
	Actualiza el progreso de la tarea actual
]]
function TaskManager:UpdateTaskProgress(progress: number): boolean
	if not self.currentTask then
		return false
	end
	
	self.currentTask.Progress = math.min(progress, 100)
	
	self.taskSignal:Fire({
		Type = "TaskProgressUpdated",
		Task = self.currentTask,
		Progress = progress,
	})
	
	return true
end

--[[
	Marca la tarea actual como completada
]]
function TaskManager:CompleteCurrentTask(): boolean
	if not self.currentTask then
		return false
	end
	
	local task = self.currentTask
	task.Status = "Completed"
	task.CompletedAt = tick()
	
	-- Guardar en historial
	table.insert(self.taskHistory, task)
	if #self.taskHistory > self.maxHistorySize then
		table.remove(self.taskHistory, 1)
	end
	
	self.logger:LogTaskEvent(task.Name, "Completed", {
		Duration = task.CompletedAt - task.StartedAt,
		Type = task.Type,
	})
	
	self.taskSignal:Fire({
		Type = "TaskCompleted",
		Task = task,
	})
	
	self.currentTask = nil
	
	return true
end

--[[
	Cancela la tarea actual
]]
function TaskManager:CancelCurrentTask(): boolean
	if not self.currentTask then
		return false
	end
	
	local task = self.currentTask
	task.Status = "Cancelled"
	
	self.logger:LogTaskEvent(task.Name, "Cancelled", nil)
	
	self.taskSignal:Fire({
		Type = "TaskCancelled",
		Task = task,
	})
	
	self.currentTask = nil
	
	return true
end

--[[
	Obtiene el historial de tareas
]]
function TaskManager:GetTaskHistory(count: number?): { Task }
	local limit = count or 10
	local result = {}
	
	for i = math.max(1, #self.taskHistory - limit + 1), #self.taskHistory do
		table.insert(result, self.taskHistory[i])
	end
	
	return result
end

--[[
	Obtiene estadísticas de tareas
]]
function TaskManager:GetTaskStatistics(): { [string]: any }
	local completed = 0
	local cancelled = 0
	local totalTime = 0
	
	for _, task in ipairs(self.taskHistory) do
		if task.Status == "Completed" then
			completed = completed + 1
			if task.CompletedAt then
				totalTime = totalTime + (task.CompletedAt - task.StartedAt)
			end
		elseif task.Status == "Cancelled" then
			cancelled = cancelled + 1
		end
	end
	
	return {
		TotalTasks = #self.taskHistory,
		CompletedTasks = completed,
		CancelledTasks = cancelled,
		AverageTaskTime = if completed > 0 then totalTime / completed else 0,
	}
end

--[[
	Conecta una función a eventos de tarea
]]
function TaskManager:OnTaskEvent(callback: (event: any) -> ()): RBXScriptConnection
	return self.taskSignal.Event:Connect(callback)
end

--[[
	Genera un reporte de la tarea actual
]]
function TaskManager:GenerateTaskReport(): string
	if not self.currentTask then
		return "No hay tarea activa"
	end
	
	local task = self.currentTask
	
	return string.format(
		"Tarea: %s\nTipo: %s\nObjetivo: %s\nProgreso: %.1f%%\nRequisito: %s (+%d)",
		task.Name,
		task.Type,
		task.Objective,
		task.Progress,
		task.TargetRequirement,
		task.TargetAmount
	)
end

return TaskManager
