--[[
	RequirementManager.luau
	Gestor de requisitos para Blox Fruits
	Analiza y verifica los requisitos de cada objetivo
]]

local RequirementManager = {}
RequirementManager.__index = RequirementManager

export type RequirementStatus = {
	Name: string,
	Required: number,
	Current: number,
	IsMet: boolean,
	Remaining: number,
}

export type ObjectiveAnalysis = {
	ObjectiveName: string,
	AllRequirementsMet: boolean,
	RequirementStatuses: { [string]: RequirementStatus },
	MissingRequirements: { [string]: RequirementStatus },
	PercentageComplete: number,
}

--[[
	Crea una nueva instancia de RequirementManager
]]
function RequirementManager.new(database: any, stateManager: any): RequirementManager
	local self = setmetatable({}, RequirementManager)
	
	self.database = database
	self.stateManager = stateManager
	
	return self
end

--[[
	Analiza un objetivo específico
	@param objectiveName: nombre del objetivo a analizar
	@return ObjectiveAnalysis con el estado de todos los requisitos
]]
function RequirementManager:AnalyzeObjective(objectiveName: string): ObjectiveAnalysis?
	local objective = self.database:GetObjective(objectiveName)
	
	if not objective then
		return nil
	end
	
	local state = self.stateManager:GetState()
	local requirementStatuses = {}
	local missingRequirements = {}
	local totalRequirements = 0
	local metRequirements = 0
	
	-- Analizar cada requisito
	for requirementName, requiredValue in pairs(objective.Requirements) do
		totalRequirements = totalRequirements + 1
		
		local currentValue = self:GetCurrentValue(requirementName, state)
		local isMet = currentValue >= requiredValue
		
		if isMet then
			metRequirements = metRequirements + 1
		end
		
		local status: RequirementStatus = {
			Name = requirementName,
			Required = requiredValue,
			Current = currentValue,
			IsMet = isMet,
			Remaining = math.max(0, requiredValue - currentValue),
		}
		
		requirementStatuses[requirementName] = status
		
		if not isMet then
			missingRequirements[requirementName] = status
		end
	end
	
	local percentageComplete = if totalRequirements > 0 
		then (metRequirements / totalRequirements) * 100 
		else 0
	
	return {
		ObjectiveName = objectiveName,
		AllRequirementsMet = #missingRequirements == 0,
		RequirementStatuses = requirementStatuses,
		MissingRequirements = missingRequirements,
		PercentageComplete = percentageComplete,
	} :: ObjectiveAnalysis
end

--[[
	Obtiene el valor actual de un requisito del estado del jugador
	@param requirementName: nombre del requisito
	@param state: estado del jugador
	@return valor actual del requisito
]]
function RequirementManager:GetCurrentValue(requirementName: string, state: any): number
	-- Mapeo de nombres de requisitos a valores del estado
	local mapping = {
		-- Stats básicos
		Level = state.Level,
		Money = state.Money,
		Fragments = state.Fragments,
		Health = state.Health,
		
		-- Mastery
		MeleeMastery = (state.Mastery.Melee and state.Mastery.Melee.Level) or 0,
		SwordMastery = (state.Mastery.Sword and state.Mastery.Sword.Level) or 0,
		FruitMastery = (state.Mastery.Fruit and state.Mastery.Fruit.Level) or 0,
		GunMastery = (state.Mastery.Gun and state.Mastery.Gun.Level) or 0,
		CombatMastery = (state.Mastery.Combat and state.Mastery.Combat.Level) or 0,
		
		-- Fragmentos especiales
		FragmentsV2 = state.Fragments,
		FragmentsV3 = state.Fragments,
		FragmentsV4 = state.Fragments,
	}
	
	return mapping[requirementName] or 0
end

--[[
	Encuentra el siguiente requisito faltante para un objetivo
	@param objectiveName: nombre del objetivo
	@return RequirementStatus del requisito faltante más próximo, o nil si todos están cumplidos
]]
function RequirementManager:GetNextMissingRequirement(objectiveName: string): RequirementStatus?
	local analysis = self:AnalyzeObjective(objectiveName)
	
	if not analysis or analysis.AllRequirementsMet then
		return nil
	end
	
	-- Encontrar el requisito más cercano a completarse
	local closestRequirement: RequirementStatus? = nil
	local smallestRemaining = math.huge
	
	for _, status in pairs(analysis.MissingRequirements) do
		if status.Remaining < smallestRemaining then
			smallestRemaining = status.Remaining
			closestRequirement = status
		end
	end
	
	return closestRequirement
end

--[[
	Obtiene todos los requisitos faltantes ordenados por proximidad
	@param objectiveName: nombre del objetivo
	@return tabla con requisitos ordenados por Remaining (menor a mayor)
]]
function RequirementManager:GetMissingRequirementsSorted(objectiveName: string): { RequirementStatus }
	local analysis = self:AnalyzeObjective(objectiveName)
	
	if not analysis then
		return {}
	end
	
	local sorted = {}
	
	for _, status in pairs(analysis.MissingRequirements) do
		table.insert(sorted, status)
	end
	
	table.sort(sorted, function(a, b)
		return a.Remaining < b.Remaining
	end)
	
	return sorted
end

--[[
	Verifica si un objetivo está completamente cumplido
	@param objectiveName: nombre del objetivo
	@return true si todos los requisitos están cumplidos
]]
function RequirementManager:IsObjectiveComplete(objectiveName: string): boolean
	local analysis = self:AnalyzeObjective(objectiveName)
	return analysis and analysis.AllRequirementsMet or false
end

--[[
	Obtiene el progreso de un objetivo en porcentaje
	@param objectiveName: nombre del objetivo
	@return número entre 0 y 100
]]
function RequirementManager:GetObjectiveProgress(objectiveName: string): number
	local analysis = self:AnalyzeObjective(objectiveName)
	return analysis and analysis.PercentageComplete or 0
end

--[[
	Compara dos requisitos para determinar cuál está más próximo a completarse
	@return true si req1 es más próximo, false si req2 es más próximo
]]
function RequirementManager:IsRequirementCloser(req1: RequirementStatus, req2: RequirementStatus): boolean
	return req1.Remaining < req2.Remaining
end

--[[
	Obtiene una descripción legible del estado de un requisito
	@param status: RequirementStatus
	@return cadena descriptiva
]]
function RequirementManager:GetRequirementStatusString(status: RequirementStatus): string
	if status.IsMet then
		return string.format("✓ %s: %d / %d", status.Name, status.Current, status.Required)
	else
		return string.format("✗ %s: %d / %d (Falta: %d)", status.Name, status.Current, status.Required, status.Remaining)
	end
end

--[[
	Genera un reporte detallado de un objetivo
	@param objectiveName: nombre del objetivo
	@return cadena con reporte formateado
]]
function RequirementManager:GenerateObjectiveReport(objectiveName: string): string
	local analysis = self:AnalyzeObjective(objectiveName)
	
	if not analysis then
		return "Objetivo no encontrado: " .. objectiveName
	end
	
	local lines = {}
	
	table.insert(lines, "=== Reporte de Objetivo: " .. analysis.ObjectiveName .. " ===")
	table.insert(lines, "Progreso: " .. string.format("%.1f%%", analysis.PercentageComplete))
	table.insert(lines, "Estado: " .. (analysis.AllRequirementsMet and "✓ COMPLETADO" or "✗ INCOMPLETO"))
	table.insert(lines, "")
	
	table.insert(lines, "Requisitos:")
	for _, status in pairs(analysis.RequirementStatuses) do
		table.insert(lines, "  " .. self:GetRequirementStatusString(status))
	end
	
	if not analysis.AllRequirementsMet then
		table.insert(lines, "")
		table.insert(lines, "Próximo requisito a completar:")
		local nextReq = self:GetNextMissingRequirement(objectiveName)
		if nextReq then
			table.insert(lines, "  " .. self:GetRequirementStatusString(nextReq))
		end
	end
	
	return table.concat(lines, "\n")
end

--[[
	Verifica si un requisito específico está cumplido
	@param requirementName: nombre del requisito
	@param requiredValue: valor requerido
	@return true si el requisito actual >= requerido
]]
function RequirementManager:IsRequirementMet(requirementName: string, requiredValue: number): boolean
	local state = self.stateManager:GetState()
	local currentValue = self:GetCurrentValue(requirementName, state)
	return currentValue >= requiredValue
end

--[[
	Obtiene cuánto falta para cumplir un requisito
	@param requirementName: nombre del requisito
	@param requiredValue: valor requerido
	@return cantidad faltante (0 si ya está cumplido)
]]
function RequirementManager:GetRequirementRemaining(requirementName: string, requiredValue: number): number
	local state = self.stateManager:GetState()
	local currentValue = self:GetCurrentValue(requirementName, state)
	return math.max(0, requiredValue - currentValue)
end

return RequirementManager
