--[[
	Logger.luau
	Sistema de logging para Kaitun Hub
	Registra todos los eventos y acciones para debugging y monitoreo
]]

local Logger = {}
Logger.__index = Logger

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR" | "CRITICAL"

export type LogEntry = {
	Timestamp: number,
	Level: LogLevel,
	Message: string,
	Details: { [string]: any }?,
	Source: string?,
}

--[[
	Crea una nueva instancia de Logger
]]
function Logger.new(maxEntries: number?): Logger
	local self = setmetatable({}, Logger)
	
	self.entries = {} :: { LogEntry }
	self.maxEntries = maxEntries or 1000
	self.logSignal = Instance.new("BindableEvent")
	
	-- Niveles de log (0 = mostrar todo)
	self.logLevel = 0 -- DEBUG
	
	return self
end

--[[
	Mapea niveles de log a números
]]
local LOG_LEVELS = {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	CRITICAL = 4,
}

--[[
	Obtiene el color para un nivel de log (para consola)
]]
local function getLogColor(level: LogLevel): string
	local colors = {
		DEBUG = "\27[36m", -- Cyan
		INFO = "\27[32m", -- Green
		WARN = "\27[33m", -- Yellow
		ERROR = "\27[31m", -- Red
		CRITICAL = "\27[35m", -- Magenta
	}
	return colors[level] or "\27[37m" -- White por defecto
end

--[[
	Log genérico con nivel especificado
]]
function Logger:Log(level: LogLevel, message: string, details: { [string]: any }?, source: string?): boolean
	-- Verificar si el nivel de log es suficiente
	if LOG_LEVELS[level] < self.logLevel then
		return false
	end
	
	local entry: LogEntry = {
		Timestamp = tick(),
		Level = level,
		Message = message,
		Details = details,
		Source = source or "KaitunHub",
	}
	
	table.insert(self.entries, entry)
	
	-- Limitar el número de entradas
	if #self.entries > self.maxEntries then
		table.remove(self.entries, 1)
	end
	
	-- Imprimir en consola
	local color = getLogColor(level)
	local time = os.date("%H:%M:%S", math.floor(entry.Timestamp))
	local reset = "\27[0m"
	
	print(string.format("%s[%s] [%s] %s%s", color, time, level, message, reset))
	
	if details then
		print("  Details:", details)
	end
	
	-- Disparar señal
	self.logSignal:Fire(entry)
	
	return true
end

--[[
	Log de nivel DEBUG
]]
function Logger:Debug(message: string, details: { [string]: any }?, source: string?): boolean
	return self:Log("DEBUG", message, details, source)
end

--[[
	Log de nivel INFO
]]
function Logger:Info(message: string, details: { [string]: any }?, source: string?): boolean
	return self:Log("INFO", message, details, source)
end

--[[
	Log de nivel WARN
]]
function Logger:Warn(message: string, details: { [string]: any }?, source: string?): boolean
	return self:Log("WARN", message, details, source)
end

--[[
	Log de nivel ERROR
]]
function Logger:Error(message: string, details: { [string]: any }?, source: string?): boolean
	return self:Log("ERROR", message, details, source)
end

--[[
	Log de nivel CRITICAL
]]
function Logger:Critical(message: string, details: { [string]: any }?, source: string?): boolean
	return self:Log("CRITICAL", message, details, source)
end

--[[
	Obtiene todas las entradas de log
]]
function Logger:GetEntries(): { LogEntry }
	return table.clone(self.entries)
end

--[[
	Obtiene las últimas N entradas
]]
function Logger:GetLastEntries(count: number): { LogEntry }
	local result = {}
	local startIndex = math.max(1, #self.entries - count + 1)
	
	for i = startIndex, #self.entries do
		table.insert(result, self.entries[i])
	end
	
	return result
end

--[[
	Filtra entradas por nivel
]]
function Logger:FilterByLevel(level: LogLevel): { LogEntry }
	local result = {}
	
	for _, entry in ipairs(self.entries) do
		if entry.Level == level then
			table.insert(result, entry)
		end
	end
	
	return result
end

--[[
	Filtra entradas por fuente
]]
function Logger:FilterBySource(source: string): { LogEntry }
	local result = {}
	
	for _, entry in ipairs(self.entries) do
		if entry.Source == source then
			table.insert(result, entry)
		end
	end
	
	return result
end

--[[
	Limpia todos los logs
]]
function Logger:Clear(): boolean
	self.entries = {}
	self:Info("Logs cleared")
	return true
end

--[[
	Conecta una función a eventos de log
]]
function Logger:OnLog(callback: (entry: LogEntry) -> ()): RBXScriptConnection
	return self.logSignal.Event:Connect(callback)
end

--[[
	Exporta logs a una cadena formateada
]]
function Logger:ExportToString(): string
	local lines = {}
	
	table.insert(lines, "=== Kaitun Hub Log Export ===")
	table.insert(lines, "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
	table.insert(lines, "")
	
	for _, entry in ipairs(self.entries) do
		local time = os.date("%H:%M:%S", math.floor(entry.Timestamp))
		local line = string.format("[%s] [%s] [%s] %s", time, entry.Level, entry.Source, entry.Message)
		table.insert(lines, line)
		
		if entry.Details then
			for key, value in pairs(entry.Details) do
				table.insert(lines, string.format("  - %s: %s", key, tostring(value)))
			end
		end
	end
	
	return table.concat(lines, "\n")
end

--[[
	Registra un evento de tarea
]]
function Logger:LogTaskEvent(taskName: string, status: string, details: { [string]: any }?): boolean
	return self:Info(
		string.format("Task: %s - Status: %s", taskName, status),
		details,
		"TaskManager"
	)
end

--[[
	Registra un evento de objetivo
]]
function Logger:LogObjectiveEvent(objectiveName: string, status: string, details: { [string]: any }?): boolean
	return self:Info(
		string.format("Objective: %s - Status: %s", objectiveName, status),
		details,
		"ObjectiveManager"
	)
end

--[[
	Registra un evento de actualización de estado
]]
function Logger:LogStateUpdate(statName: string, oldValue: any, newValue: any): boolean
	return self:Debug(
		string.format("State Update: %s", statName),
		{
			OldValue = oldValue,
			NewValue = newValue,
		},
		"StateManager"
	)
end

--[[
	Registra un error con contexto
]]
function Logger:LogError(errorMessage: string, context: { [string]: any }?): boolean
	return self:Error(
		string.format("Error: %s", errorMessage),
		context,
		"System"
	)
end

--[[
	Cambia el nivel mínimo de log a mostrar
	DEBUG=0, INFO=1, WARN=2, ERROR=3, CRITICAL=4
]]
function Logger:SetLogLevel(level: LogLevel): boolean
	local levelNum = LOG_LEVELS[level]
	if levelNum == nil then
		return false
	end
	
	self.logLevel = levelNum
	return true
end

return Logger
