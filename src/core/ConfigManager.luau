--[[
	ConfigManager.luau
	Gestor de configuración para Kaitun Hub en Blox Fruits
	Almacena y maneja todas las configuraciones del usuario
]]

local ConfigManager = {}
ConfigManager.__index = ConfigManager

export type Config = {
	-- Ejecución
	AutoExecute: boolean,
	
	-- Reset y Teleport
	ResetTeleport: {
		Enabled: boolean,
		DelayReset: number,
		ItemsDontReset: {
			Fruit: {
				Enabled: boolean,
				AllFruit: boolean,
				SelectedFruit: { [string]: boolean },
			},
		},
	},
	
	-- Rendimiento
	Performance: {
		WhiteScreen: boolean,
		LockFPS: {
			Enabled: boolean,
			FPS: number,
		},
	},
	
	-- Obtener objetos
	GetItems: {
		[string]: boolean,
	},
	
	-- Objetos raros
	GetRareItems: {
		[string]: boolean,
	},
	
	-- Farm de fragmentos
	FarmFragments: {
		Enabled: boolean,
		TargetFragments: number,
	},
	
	-- Chat automático
	AutoChat: {
		Enabled: boolean,
		Text: string,
	},
	
	-- Evocar Rip Indra
	AutoSummonRipIndra: boolean,
	
	-- Hopping de servidores
	SelectHop: {
		[string]: boolean,
	},
	
	-- Farm de mastery
	FarmMastery: {
		[string]: boolean,
	},
	
	-- Comprar Haki
	BuyHaki: {
		[string]: boolean,
	},
}

--[[
	Crea una nueva instancia de ConfigManager
]]
function ConfigManager.new(): ConfigManager
	local self = setmetatable({}, ConfigManager)
	
	self.config = {
		AutoExecute = true,
		ResetTeleport = {
			Enabled = false,
			DelayReset = 3,
			ItemsDontReset = {
				Fruit = {
					Enabled = true,
					AllFruit = true,
					SelectedFruit = {},
				},
			},
		},
		Performance = {
			WhiteScreen = false,
			LockFPS = {
				Enabled = true,
				FPS = 60,
			},
		},
		GetItems = {
			Saber = true,
			Godhuman = true,
			SkullGuitar = true,
			MirrorFractal = true,
			CursedDualKatana = true,
			UpgradeRaceV2V3 = true,
			AutoPullLever = true,
			SharkAnchor = true,
		},
		GetRareItems = {
			Rengoku = true,
			DragonTrident = true,
			PoleFirstForm = true,
			GravityBlade = true,
		},
		FarmFragments = {
			Enabled = false,
			TargetFragments = 50000,
		},
		AutoChat = {
			Enabled = false,
			Text = "",
		},
		AutoSummonRipIndra = true,
		SelectHop = {
			HopServerIfHavePlayerNear = false,
			HopFindRipIndra = true,
			HopFindDoughKing = true,
			HopFindRaidsCastle = true,
			HopFindCakeQueen = true,
			HopFindSoulReaper = true,
			HopFindDarkbeard = true,
			HopFindMirage = true,
		},
		FarmMastery = {
			Melee = false,
			Sword = false,
		},
		BuyHaki = {
			Enhancement = true,
			Skyjump = true,
			FlashStep = true,
			Observation = true,
		},
	} :: Config
	
	self.changedSignal = Instance.new("BindableEvent")
	self.configFile = "KaitunHubConfig.json"
	
	return self
end

--[[
	Obtiene la configuración completa
]]
function ConfigManager:GetConfig(): Config
	return table.clone(self.config) :: Config
end

--[[
	Obtiene un valor específico de configuración
	@param path: ruta al valor (ej: "Performance.LockFPS.Enabled")
]]
function ConfigManager:Get(path: string): any
	local parts = string.split(path, ".")
	local current = self.config
	
	for _, part in ipairs(parts) do
		if typeof(current) == "table" then
			current = current[part]
		else
			return nil
		end
	end
	
	return current
end

--[[
	Establece un valor de configuración
	@param path: ruta al valor (ej: "Performance.LockFPS.Enabled")
	@param value: nuevo valor
]]
function ConfigManager:Set(path: string, value: any): boolean
	local parts = string.split(path, ".")
	local current = self.config
	
	for i = 1, #parts - 1 do
		local part = parts[i]
		if not current[part] then
			current[part] = {}
		end
		current = current[part]
	end
	
	local lastPart = parts[#parts]
	local oldValue = current[lastPart]
	current[lastPart] = value
	
	self.changedSignal:Fire({
		Type = "ConfigChanged",
		Path = path,
		OldValue = oldValue,
		NewValue = value,
	})
	
	return true
end

--[[
	Establece toda la configuración
]]
function ConfigManager:SetAll(newConfig: Config): boolean
	self.config = table.clone(newConfig) :: Config
	
	self.changedSignal:Fire({
		Type = "ConfigReset",
	})
	
	return true
end

--[[
	Verifica si AutoExecute está habilitado
]]
function ConfigManager:IsAutoExecuteEnabled(): boolean
	return self.config.AutoExecute == true
end

--[[
	Verifica si se debe farmear fragmentos
]]
function ConfigManager:ShouldFarmFragments(): boolean
	return self.config.FarmFragments.Enabled == true
end

--[[
	Obtiene el objetivo de fragmentos
]]
function ConfigManager:GetTargetFragments(): number
	return self.config.FarmFragments.TargetFragments or 50000
end

--[[
	Verifica si un objeto debe ser obtenido
]]
function ConfigManager:ShouldGetItem(itemName: string): boolean
	return self.config.GetItems[itemName] == true
end

--[[
	Verifica si un objeto raro debe ser obtenido
]]
function ConfigManager:ShouldGetRareItem(itemName: string): boolean
	return self.config.GetRareItems[itemName] == true
end

--[[
	Obtiene la lista de objetos a obtener
]]
function ConfigManager:GetItemsToBuy(): { [string]: boolean }
	return table.clone(self.config.GetItems)
end

--[[
	Obtiene la lista de objetos raros a obtener
]]
function ConfigManager:GetRareItemsToBuy(): { [string]: boolean }
	return table.clone(self.config.GetRareItems)
end

--[[
	Obtiene el FPS límite si está habilitado
]]
function ConfigManager:GetMaxFPS(): number?
	if self.config.Performance.LockFPS.Enabled then
		return self.config.Performance.LockFPS.FPS
	end
	return nil
end

--[[
	Guarda la configuración en un archivo (simulado)
	En un injector real, esto usaría writefile()
]]
function ConfigManager:Save(): boolean
	local success, result = pcall(function()
		local jsonString = game:GetService("HttpService"):JSONEncode(self.config)
		-- En un injector: writefile(self.configFile, jsonString)
		return true
	end)
	
	return success
end

--[[
	Carga la configuración desde un archivo (simulado)
	En un injector real, esto usaría readfile()
]]
function ConfigManager:Load(): boolean
	local success, result = pcall(function()
		-- En un injector: local jsonString = readfile(self.configFile)
		-- local loadedConfig = game:GetService("HttpService"):JSONDecode(jsonString)
		-- self.config = loadedConfig
		return true
	end)
	
	return success
end

--[[
	Conecta una función a los cambios de configuración
]]
function ConfigManager:OnChanged(callback: (change: any) -> ()): RBXScriptConnection
	return self.changedSignal.Event:Connect(callback)
end

--[[
	Restablece la configuración a valores por defecto
]]
function ConfigManager:Reset(): boolean
	self.config = {
		AutoExecute = true,
		ResetTeleport = {
			Enabled = false,
			DelayReset = 3,
			ItemsDontReset = {
				Fruit = {
					Enabled = true,
					AllFruit = true,
					SelectedFruit = {},
				},
			},
		},
		Performance = {
			WhiteScreen = false,
			LockFPS = {
				Enabled = true,
				FPS = 60,
			},
		},
		GetItems = {
			Saber = true,
			Godhuman = true,
			SkullGuitar = true,
			MirrorFractal = true,
			CursedDualKatana = true,
			UpgradeRaceV2V3 = true,
			AutoPullLever = true,
			SharkAnchor = true,
		},
		GetRareItems = {
			Rengoku = true,
			DragonTrident = true,
			PoleFirstForm = true,
			GravityBlade = true,
		},
		FarmFragments = {
			Enabled = false,
			TargetFragments = 50000,
		},
		AutoChat = {
			Enabled = false,
			Text = "",
		},
		AutoSummonRipIndra = true,
		SelectHop = {
			HopServerIfHavePlayerNear = false,
			HopFindRipIndra = true,
			HopFindDoughKing = true,
			HopFindRaidsCastle = true,
			HopFindCakeQueen = true,
			HopFindSoulReaper = true,
			HopFindDarkbeard = true,
			HopFindMirage = true,
		},
		FarmMastery = {
			Melee = false,
			Sword = false,
		},
		BuyHaki = {
			Enhancement = true,
			Skyjump = true,
			FlashStep = true,
			Observation = true,
		},
	} :: Config
	
	self.changedSignal:Fire({
		Type = "ConfigReset",
	})
	
	return true
end

return ConfigManager
