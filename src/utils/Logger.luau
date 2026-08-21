--[[
	Logger.luau
	Sistema de logging completo para Blox Fruits Automation
	Registra eventos, errores, warnings y información
]]

local Logger = {}
Logger.__index = Logger

export type LogEntry = {
	Level: string,
	Message: string,
	Timestamp: number,
	Source: string,
	Context: { [string]: any }?,
	StackTrace: string?,
}

export type LoggerConfig = {
	MaxEntries: number,
	EnableConsole: boolean,
	EnableFile: boolean,
	EnableNotifications: boolean,
	LogLevel: string,
	DateFormat: string,
}

--[[
	Crea una nueva instancia de Logger
]]
function Logger.new(config: Partial<LoggerConfig>?): Logger
	local self = setmetatable({}, Logger)
	
	-- Configuración por defecto
	self.config = {
		MaxEntries = 500,
		EnableConsole = true,
		EnableFile = true,
		EnableNotifications = true,
		LogLevel = "Info",
		DateFormat = "%Y-%m-%d %H:%M:%S",
	}
	
	-- Aplicar configuración personalizada
	if config then
		for key, value in pairs(config) do
			self.config[key] = value
		end
	end
	
	-- Almacenamiento
	self.entries = {}
	self.logSignal = Instance.new("BindableEvent")
	
	-- Niveles de log
	self.logLevels = {
		Debug = 1,
		Info = 2,
		Warn = 3,
		Error = 4,
		Fatal = 5,
	}
	
	-- Colores para consola
	self.colors = {
		Debug = "\27[36m",   -- Cyan
		Info = "\27[32m",    -- Verde
		Warn = "\27[33m",    -- Amarillo
		Error = "\27[31m",   -- Rojo
		Fatal = "\27[35m",   -- Magenta
		Reset = "\27[0m",
	}
	
	return self
end

--[[
	Log de nivel Debug
]]
function Logger:Debug(message: string, context: any?, source: string?): boolean
	return self:_Log("Debug", message, context, source)
end

--[[
	Log de nivel Info
]]
function Logger:Info(message: string, context: any?, source: string?): boolean
	return self:_Log("Info", message, context, source)
end

--[[
	Log de nivel Warning
]]
function Logger:Warn(message: string, context: any?, source: string?): boolean
	return self:_Log("Warn", message, context, source)
end

--[[
	Log de nivel Error
]]
function Logger:Error(message: string, context: any?, source: string?): boolean
	return self:_Log("Error", message, context, source)
end

--[[
	Log de nivel Fatal
]]
function Logger:Fatal(message: string, context: any?, source: string?): boolean
	return self:_Log("Fatal", message, context, source)
end

--[[
	Implementación interna de logging
]]
function Logger:_Log(level: string, message: string, context: any?, source: string?): boolean
	-- Verificar si el nivel de log es lo suficientemente alto
	local currentLevelValue = self.logLevels[self.config.LogLevel] or 2
	local entryLevelValue = self.logLevels[level] or 2
	
	if entryLevelValue < currentLevelValue then
		return false
	end
	
	-- Crear entrada de log
	local entry: LogEntry = {
		Level = level,
		Message = message,
		Timestamp = tick(),
		Source = source or "Unknown",
		Context = context,
		StackTrace = nil,
	}
	
	-- Guardar en almacenamiento
	table.insert(self.entries, entry)
	
	-- Limitar el tamaño del almacenamiento
	if #self.entries > self.config.MaxEntries then
		table.remove(self.entries, 1)
	end
	
	-- Procesar salida
	if self.config.EnableConsole then
		self:_PrintToConsole(entry)
	end
	
	if self.config.EnableNotifications then
		self:_SendNotification(entry)
	end
	
	-- Dispara evento
	self.logSignal:Fire(entry)
	
	return true
end

--[[
	Imprime log en consola
]]
function Logger:_PrintToConsole(entry: LogEntry): boolean
	local color = self.colors[entry.Level] or self.colors.Info
	local reset = self.colors.Reset
	
	local timestamp = os.date(self.config.DateFormat, entry.Timestamp)
	local formattedMessage = string.format(
		"%s[%s] %s [%s]:%s %s",
		color,
		timestamp,
		entry.Level,
		entry.Source,
		reset,
		entry.Message
	)
	
	print(formattedMessage)
	
	-- Si hay contexto, imprimirlo
	if entry.Context then
		print(color .. "  Context: " .. self:_TableToString(entry.Context) .. reset)
	end
	
	return true
end

--[[
	Envía una notificación
]]
function Logger:_SendNotification(entry: LogEntry): boolean
	-- Solo enviar notificaciones para Warning, Error y Fatal
	if entry.Level ~= "Warn" and entry.Level ~= "Error" and entry.Level ~= "Fatal" then
		return false
	end
	
	-- Aquí iría la lógica de notificación real
	-- Por ahora, solo registramos que se envió
	
	return true
end

--[[
	Convierte una tabla a string
]]
function Logger:_TableToString(tbl: any): string
	if type(tbl) ~= "table" then
		return tostring(tbl)
	end
	
	local result = "{ "
	local first = true
	
	for key, value in pairs(tbl) do
		if not first then
			result = result .. ", "
		end
		first = false
		
		if type(value) == "table" then
			result = result .. key .. " = " .. self:_TableToString(value)
		else
			result = result .. key .. " = " .. tostring(value)
		end
	end
	
	result = result .. " }"
	return result
end

--[[
	Obtiene el historial de logs
]]
function Logger:GetHistory(count: number?, level: string?): { LogEntry }
	local limit = count or 50
	local result = {}
	
	for i = math.max(1, #self.entries - limit + 1), #self.entries do
		local entry = self.entries[i]
		
		-- Filtrar por nivel si se especifica
		if level == nil or entry.Level == level then
			table.insert(result, entry)
		end
	end
	
	return result
end

--[[
	Obtiene logs filtrados por fuente
]]
function Logger:GetBySource(source: string, count: number?): { LogEntry }
	local limit = count or 50
	local result = {}
	
	for i = #self.entries, math.max(1, #self.entries - limit + 1), -1 do
		local entry = self.entries[i]
		
		if entry.Source == source then
			table.insert(result, 1, entry)
		end
	end
	
	return result
end

--[[
	Obtiene logs filtrados por nivel
]]
function Logger:GetByLevel(level: string, count: number?): { LogEntry }
	local limit = count or 50
	local result = {}
	
	for i = #self.entries, math.max(1, #self.entries - limit + 1), -1 do
		local entry = self.entries[i]
		
		if entry.Level == level then
			table.insert(result, 1, entry)
		end
	end
	
	return result
end

--[[
	Registra un evento de tarea
]]
function Logger:LogTaskEvent(taskName: string, eventType: string, context: any?): boolean
	return self:Info(
		string.format("Task Event: %s - %s", taskName, eventType),
		context,
		"TaskLogger"
	)
end

--[[
	Registra un evento de farming
]]
function Logger:LogFarmingEvent(farmingType: string, eventType: string, context: any?): boolean
	return self:Info(
		string.format("Farming Event: %s - %s", farmingType, eventType),
		context,
		"FarmingLogger"
	)
end

--[[
	Limpia todos los logs
]]
function Logger:Clear(): boolean
	self.entries = {}
	self:Info("Logs cleared", nil, "Logger")
	return true
end

--[[
	Exporta logs a formato de texto
]]
function Logger:ExportAsText(): string
	local lines = {}
	
	table.insert(lines, "=== BLOX FRUITS AUTOMATION LOG REPORT ===")
	table.insert(lines, "Generated: " .. os.date(self.config.DateFormat))
	table.insert(lines, "")
	
	for _, entry in ipairs(self.entries) do
		local timestamp = os.date(self.config.DateFormat, entry.Timestamp)
		local line = string.format(
			"[%s] %s [%s] %s",
			timestamp,
			entry.Level,
			entry.Source,
			entry.Message
		)
		
		table.insert(lines, line)
		
		if entry.Context then
			table.insert(lines, "  Context: " .. self:_TableToString(entry.Context))
		end
	end
	
	return table.concat(lines, "\n")
end

--[[
	Obtiene estadísticas de logs
]]
function Logger:GetStatistics(): { [string]: any }
	local stats = {
		Total = #self.entries,
		Debug = 0,
		Info = 0,
		Warn = 0,
		Error = 0,
		Fatal = 0,
		BySources = {},
	}
	
	for _, entry in ipairs(self.entries) do
		stats[entry.Level] = (stats[entry.Level] or 0) + 1
		
		if not stats.BySources[entry.Source] then
			stats.BySources[entry.Source] = 0
		end
		stats.BySources[entry.Source] = stats.BySources[entry.Source] + 1
	end
	
	return stats
end

--[[
	Conecta una función a eventos de log
]]
function Logger:OnLogEvent(callback: (entry: LogEntry) -> ()): RBXScriptConnection
	return self.logSignal.Event:Connect(callback)
end

--[[
	Genera un reporte sumario
]]
function Logger:GenerateSummary(): string
	local stats = self:GetStatistics()
	
	return string.format(
		"=== LOG SUMMARY ===\n" ..
		"Total Entries: %d\n" ..
		"Debug: %d | Info: %d | Warn: %d | Error: %d | Fatal: %d\n" ..
		"Recent Entry: [%s] %s",
		stats.Total,
		stats.Debug or 0,
		stats.Info or 0,
		stats.Warn or 0,
		stats.Error or 0,
		stats.Fatal or 0,
		self.entries[#self.entries] and self.entries[#self.entries].Source or "None",
		self.entries[#self.entries] and self.entries[#self.entries].Message or "None"
	)
end

--[[
	Actualiza la configuración del logger
]]
function Logger:SetConfig(newConfig: Partial<LoggerConfig>): boolean
	for key, value in pairs(newConfig) do
		if self.config[key] ~= nil then
			self.config[key] = value
		end
	end
	
	return true
end

return Logger
