repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ============================================
-- CONFIGURACIÓN
-- ============================================
getgenv().Config = {
	Farming = false,
	FarmType = "Money",
	Location = "Jungle",
	Combat = true,
	AutoPickup = true,
	SafeMode = true,
	ShowDebug = false,
}

local Stats = {
	Money = 0,
	Exp = 0,
	Kills = 0,
	SessionTime = 0,
	StartTime = tick(),
}

-- ============================================
-- LOCACIONES REALES DE BLOX FRUITS
-- ============================================
local Locations = {
	Village = {Pos = Vector3.new(1573, 15, 1118), Enemies = {"Bandit", "Pirate"}},
	Jungle = {Pos = Vector3.new(-1573, 330, -1118), Enemies = {"Jungle Warrior", "Jungle Beast"}},
	Colosseum = {Pos = Vector3.new(5650, 5.83, 22.76), Enemies = {"Colosseum Beast"}},
	["Snow Island"] = {Pos = Vector3.new(-6143.82, 144.83, -8999.76), Enemies = {"Snow Warrior"}},
	["Underwater City"] = {Pos = Vector3.new(-10353, -8378, -8238), Enemies = {"Military Soldier"}},
}

-- ============================================
-- ENCONTRAR REMOTE EVENTS
-- ============================================
local Combat = {}
Combat.RemoteEvent = nil
Combat.TargetEnemy = nil

function Combat:FindRemote()
	-- Buscar RemoteEvent de combate
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") then
			local name = obj.Name:lower()
			if string.find(name, "combat") or string.find(name, "attack") or string.find(name, "damage") then
				self.RemoteEvent = obj
				return obj
			end
		end
	end
	
	-- Si no encuentra, usar uno genérico
	if not self.RemoteEvent then
		for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
			if obj:IsA("RemoteEvent") then
				self.RemoteEvent = obj
				break
			end
		end
	end
	
	return self.RemoteEvent
end

-- ============================================
-- FUNCIONES CORE DE COMBATE
-- ============================================
function Combat:EquipWeapon()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return false end
	
	local weapon = nil
	
	-- Prioridad: Espada > Arma > Herramienta
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			if string.find(tool.Name:lower(), "sword") or string.find(tool.Name:lower(), "katana") then
				weapon = tool
				break
			elseif not weapon then
				weapon = tool
			end
		end
	end
	
	if weapon then
		weapon.Parent = Character
		wait(0.2)
		return true
	end
	
	return false
end

function Combat:AttackEnemy(enemy)
	if not enemy or not enemy:FindFirstChild("Humanoid") then return false end
	if enemy.Humanoid.Health <= 0 then return false end
	
	-- Acercarse al enemigo
	local targetPos = enemy:FindFirstChild("HumanoidRootPart")
	if targetPos then
		HumanoidRootPart.CFrame = CFrame.new(
			targetPos.Position + Vector3.new(0, 0, -15)
		)
		wait(0.1)
	end
	
	-- Equipar arma si no tiene
	if not Character:FindFirstChildOfClass("Tool") then
		self:EquipWeapon()
	end
	
	-- Activar herramienta
	local tool = Character:FindFirstChildOfClass("Tool")
	if tool then
		tool:Activate()
		wait(0.3)
	end
	
	-- Intentar usar RemoteEvent
	if self.RemoteEvent then
		pcall(function()
			self.RemoteEvent:FireServer(enemy)
		end)
	end
	
	Stats.Kills = Stats.Kills + 1
	return true
end

-- ============================================
-- ENCONTRAR ENEMIGOS
-- ============================================
local function FindNearestEnemy()
	local nearest = nil
	local maxDist = 200
	local location = Locations[Config.Location]
	
	if not location then return nil end
	
	for _, obj in ipairs(Workspace:GetChildren()) do
		-- Buscar por nombre o que tenga Humanoid
		if obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
			if obj ~= Character then
				-- Verificar si es enemigo (no es jugador)
				if not Players:FindFirstChild(obj.Name) then
					local dist = (obj.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
					
					if dist < maxDist and obj.Humanoid.Health > 0 then
						-- Verificar que sea el tipo de enemigo correcto
						for _, enemyName in ipairs(location.Enemies) do
							if string.find(obj.Name:lower(), enemyName:lower()) then
								nearest = obj
								maxDist = dist
								break
							end
						end
					end
				end
			end
		end
	end
	
	return nearest
end

-- ============================================
-- RECOLECCIÓN DE ITEMS
-- ============================================
local function CollectDroppedItems()
	local itemsFolder = Workspace:FindFirstChild("ItemSpawns") or Workspace:FindFirstChild("Dropped")
	
	if not itemsFolder then return end
	
	for _, item in ipairs(itemsFolder:GetChildren()) do
		if item:FindFirstChild("HumanoidRootPart") or item:FindFirstChild("Position") then
			local itemPos = item:FindFirstChild("HumanoidRootPart") and item.HumanoidRootPart.Position or item.Position
			local dist = (itemPos - HumanoidRootPart.Position).Magnitude
			
			if dist < 100 then
				HumanoidRootPart.CFrame = CFrame.new(itemPos)
				wait(0.2)
			end
		end
	end
end

-- ============================================
-- LOOP PRINCIPAL DE FARMING
-- ============================================
local function FarmLoop()
	Combat:FindRemote()
	
	while Config.Farming do
		-- Verificar si está muerto
		if Humanoid.Health <= 0 then
			if Config.SafeMode then
				wait(5)
			end
		end
		
		-- Mantener posición en la locación
		local locationData = Locations[Config.Location]
		if locationData then
			local dist = (HumanoidRootPart.Position - locationData.Pos).Magnitude
			if dist > 500 then
				HumanoidRootPart.CFrame = CFrame.new(locationData.Pos)
				wait(1)
			end
		end
		
		-- Buscar y atacar enemigos
		if Config.Combat then
			local enemy = FindNearestEnemy()
			if enemy then
				Combat:AttackEnemy(enemy)
			end
		end
		
		-- Recolectar items
		if Config.AutoPickup and math.random(1, 3) == 1 then
			CollectDroppedItems()
		end
		
		Stats.SessionTime = tick() - Stats.StartTime
		wait(0.3)
	end
end

-- ============================================
-- CREAR UI HUB
-- ============================================
local function CreateUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BloxFruitsHub"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Marco principal
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 380, 0, 500)
	MainFrame.Position = UDim2.new(0, 20, 0, 20)
	MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	MainFrame.BorderSizePixel = 0
	MainFrame.Active = true
	MainFrame.Draggable = true
	MainFrame.Parent = ScreenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = MainFrame
	
	-- HEADER
	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, 50)
	Header.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
	Header.BorderSizePixel = 0
	Header.Parent = MainFrame
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = Header
	
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -20, 1, 0)
	Title.Position = UDim2.new(0, 10, 0, 0)
	Title.BackgroundTransparency = 1
	Title.TextColor3 = Color3.fromRGB(0, 255, 150)
	Title.TextSize = 22
	Title.Font = Enum.Font.GothamBold
	Title.Text = "BLOX FRUITS FARM"
	Title.Parent = Header
	
	-- BOTÓN START
	local StartBtn = Instance.new("TextButton")
	StartBtn.Name = "StartBtn"
	StartBtn.Size = UDim2.new(0.45, 0, 0, 45)
	StartBtn.Position = UDim2.new(0.05, 0, 0.12, 0)
	StartBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	StartBtn.TextSize = 15
	StartBtn.Font = Enum.Font.GothamBold
	StartBtn.Text = "▶ START"
	StartBtn.BorderSizePixel = 0
	StartBtn.Parent = MainFrame
	
	local startCorner = Instance.new("UICorner")
	startCorner.CornerRadius = UDim.new(0, 8)
	startCorner.Parent = StartBtn
	
	-- BOTÓN STOP
	local StopBtn = Instance.new("TextButton")
	StopBtn.Name = "StopBtn"
	StopBtn.Size = UDim2.new(0.45, 0, 0, 45)
	StopBtn.Position = UDim2.new(0.5, 0, 0.12, 0)
	StopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	StopBtn.TextSize = 15
	StopBtn.Font = Enum.Font.GothamBold
	StopBtn.Text = "⏹ STOP"
	StopBtn.BorderSizePixel = 0
	StopBtn.Parent = MainFrame
	
	local stopCorner = Instance.new("UICorner")
	stopCorner.CornerRadius = UDim.new(0, 8)
	stopCorner.Parent = StopBtn
	
	-- SELECTOR LOCACIÓN
	local LocationLabel = Instance.new("TextLabel")
	LocationLabel.Size = UDim2.new(0.9, 0, 0, 25)
	LocationLabel.Position = UDim2.new(0.05, 0, 0.27, 0)
	LocationLabel.BackgroundTransparency = 1
	LocationLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	LocationLabel.TextSize = 13
	LocationLabel.Font = Enum.Font.Gotham
	LocationLabel.Text = "📍 Location: " .. Config.Location
	LocationLabel.Parent = MainFrame
	
	local LocationBtn = Instance.new("TextButton")
	LocationBtn.Name = "LocationBtn"
	LocationBtn.Size = UDim2.new(0.9, 0, 0, 40)
	LocationBtn.Position = UDim2.new(0.05, 0, 0.33, 0)
	LocationBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
	LocationBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
	LocationBtn.TextSize = 14
	LocationBtn.Font = Enum.Font.Gotham
	LocationBtn.Text = "Change Location"
	LocationBtn.BorderSizePixel = 0
	LocationBtn.Parent = MainFrame
	
	local locCorner = Instance.new("UICorner")
	locCorner.CornerRadius = UDim.new(0, 8)
	locCorner.Parent = LocationBtn
	
	-- PANEL DE ESTADÍSTICAS
	local StatsFrame = Instance.new("Frame")
	StatsFrame.Size = UDim2.new(0.9, 0, 0, 140)
	StatsFrame.Position = UDim2.new(0.05, 0, 0.48, 0)
	StatsFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
	StatsFrame.BorderSizePixel = 0
	StatsFrame.Parent = MainFrame
	
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = StatsFrame
	
	local StatsLabel = Instance.new("TextLabel")
	StatsLabel.Name = "StatsLabel"
	StatsLabel.Size = UDim2.new(1, -10, 1, -10)
	StatsLabel.Position = UDim2.new(0, 5, 0, 5)
	StatsLabel.BackgroundTransparency = 1
	StatsLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	StatsLabel.TextSize = 12
	StatsLabel.Font = Enum.Font.GothamMonospace
	StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
	StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
	StatsLabel.Parent = StatsFrame
	
	-- TOGGLES
	local CombatToggle = Instance.new("TextButton")
	CombatToggle.Size = UDim2.new(0.9, 0, 0, 35)
	CombatToggle.Position = UDim2.new(0.05, 0, 0.76, 0)
	CombatToggle.BackgroundColor3 = Config.Combat and Color3.fromRGB(100, 150, 100) or Color3.fromRGB(80, 80, 80)
	CombatToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	CombatToggle.TextSize = 13
	CombatToggle.Font = Enum.Font.Gotham
	CombatToggle.Text = "⚔ Auto Combat: " .. (Config.Combat and "ON" or "OFF")
	CombatToggle.BorderSizePixel = 0
	CombatToggle.Parent = MainFrame
	
	local combatCorner = Instance.new("UICorner")
	combatCorner.CornerRadius = UDim.new(0, 8)
	combatCorner.Parent = CombatToggle
	
	-- EVENTOS
	StartBtn.MouseButton1Click:Connect(function()
		Config.Farming = true
		StartBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		StartBtn.Text = "▶ FARMING..."
		StopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		
		-- Teletransportarse a la locación
		local loc = Locations[Config.Location]
		if loc then
			HumanoidRootPart.CFrame = CFrame.new(loc.Pos)
			wait(1)
		end
		
		task.spawn(FarmLoop)
	end)
	
	StopBtn.MouseButton1Click:Connect(function()
		Config.Farming = false
		StartBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		StartBtn.Text = "▶ START"
	end)
	
	LocationBtn.MouseButton1Click:Connect(function()
		local locs = {"Village", "Jungle", "Colosseum", "Snow Island", "Underwater City"}
		for i, loc in ipairs(locs) do
			if loc == Config.Location then
				Config.Location = locs[i % #locs + 1]
				break
			end
		end
		LocationLabel.Text = "📍 Location: " .. Config.Location
		
		if Config.Farming then
			local loc = Locations[Config.Location]
			if loc then
				HumanoidRootPart.CFrame = CFrame.new(loc.Pos)
			end
		end
	end)
	
	CombatToggle.MouseButton1Click:Connect(function()
		Config.Combat = not Config.Combat
		CombatToggle.BackgroundColor3 = Config.Combat and Color3.fromRGB(100, 150, 100) or Color3.fromRGB(80, 80, 80)
		CombatToggle.Text = "⚔ Auto Combat: " .. (Config.Combat and "ON" or "OFF")
	end)
	
	-- ACTUALIZAR STATS EN TIEMPO REAL
	RunService.Heartbeat:Connect(function()
		StatsLabel.Text = string.format(
			"⏱ Time: %.1f min\n💥 Kills: %d\n📊 Status: %s\n\n[F9] Hide/Show",
			Stats.SessionTime / 60,
			Stats.Kills,
			Config.Farming and "FARMING" or "IDLE"
		)
	end)
	
	-- Hotkey F9
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.F9 then
			MainFrame.Visible = not MainFrame.Visible
		end
	end)
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================
local function Init()
	print("═══════════════════════════════════")
	print("BLOX FRUITS FARMING BOT v2")
	print("Presiona F9 para mostrar/ocultar UI")
	print("═══════════════════════════════════")
	
	CreateUI()
	
	-- Monitorear respawn
	local function OnRespawn()
		Humanoid.Died:Connect(function()
			print("[!] Personaje muerto, esperando respawn...")
			Character = LocalPlayer.CharacterAdded:Wait()
			HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
			Humanoid = Character:WaitForChild("Humanoid")
			print("[+] Respawneado correctamente")
			OnRespawn()
		end)
	end
	
	OnRespawn()
end

Init()

-- Exportar globals
getgenv().BloxConfig = Config
getgenv().BloxStats = Stats
