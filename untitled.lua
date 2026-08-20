local rng = Random.new()
local function GenerateRandomString(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local str = ""
	for i = 1, len do
		local r = rng:NextInteger(1, #chars)
		str = str .. string.sub(chars, r, r)
	end
	return str
end

local _G_Identifier = "VeloxHub_Core_Cleanup_V3_5"
local MainGuiName = "Velox_" .. GenerateRandomString(12)
local FloatBtnName = "VeloxFloat_" .. GenerateRandomString(12)

if getgenv()[_G_Identifier] then
	pcall(function() getgenv()[_G_Identifier]() end)
end

local Services = setmetatable({}, {
	__index = function(self, key)
		local success, service = pcall(function() return game:GetService(key) end)
		if success and service then
			local final = (type(cloneref) == "function") and cloneref(service) or service
			self[key] = final
			return final
		end
		return nil
	end
})

local Players = Services.Players
local UserInputService = Services.UserInputService
local HttpService = Services.HttpService
local VirtualInputManager = Services.VirtualInputManager
local VirtualUser = Services.VirtualUser
local StarterGui = Services.StarterGui
local RunService = Services.RunService
local Stats = Services.Stats
local CoreGui = Services.CoreGui
local TweenService = Services.TweenService
local GuiService = Services.GuiService

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	task.wait()
	LocalPlayer = Players.LocalPlayer
end

local PlaceId = game.PlaceId

local gethui = gethui or function() return nil end
local protectgui = protectgui or (syn and syn.protect_gui) or function(...) return ... end
local exec_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request) or (krnl and krnl.request)
local getexecutor = identifyexecutor or getexecutorname or function() return "Unknown Executor" end
local write_file = writefile or function() end
local read_file = readfile or function() end
local is_file = isfile or function() return false end
local del_file = delfile or function() end

local Theme = {
	Accent = Color3.fromRGB(99, 102, 241),
	BackgroundMain = Color3.fromRGB(15, 23, 42),
	BackgroundSecondary = Color3.fromRGB(20, 29, 55),
	Card = Color3.fromRGB(24, 33, 50),
	CardHover = Color3.fromRGB(30, 41, 59),
	TextPrimary = Color3.fromRGB(248, 250, 252),
	TextSecondary = Color3.fromRGB(148, 163, 184),
	Success = Color3.fromRGB(16, 185, 129),
	Error = Color3.fromRGB(180, 50, 50),
	Warning = Color3.fromRGB(220, 140, 15),
	Info = Color3.fromRGB(56, 189, 248),
	System = Color3.fromRGB(168, 85, 247),
	Execution = Color3.fromRGB(190, 55, 110),
	Stroke = Color3.fromRGB(51, 65, 85),
	ToggleOff = Color3.fromRGB(71, 85, 105)
}

local VeloxConnections = {}
local CardConnections = {}
local RegisteredScripts = {}
local AfkConnections = {}
local PendingTasks = {}
local ActiveTweens = setmetatable({}, { __mode = "k" })
local CatalogGeneration = 0
local CatalogRefreshCooldown = 5
local LastCatalogRefreshAt = 0
local AutoExecuteRanThisSession = false
local InteractiveElements = setmetatable({}, { __mode = "k" })

local isDestroying = false
local isMinimized = false
local isTransitioning = false
local IsBindingKey = false
local IsMobile = UserInputService.TouchEnabled and (not UserInputService.MouseEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y <= 800) or GuiService:IsTenFootInterface())

local mainDragConnection, floatDragConnection
local activeMainDragInput, activeFloatDragInput
local ToggleKeybindConnection = nil
local KeybindCaptureConnection = nil
local DropdownContainer = nil
local ToastContainer = nil
local ConfirmOverlay = nil

local GlobalCooldownBanner = nil
local GlobalCooldownLoopVersion = 0
local GlobalActionCooldownEndTime = 0

local OriginalCache = setmetatable({}, { __mode = "k" })

local function CacheInstanceAndDescendants(root)
	local function CacheObj(obj)
		if not obj or OriginalCache[obj] then return end
		local c = {}
		if obj:IsA("GuiObject") then
			c.BackgroundTransparency = obj.BackgroundTransparency
			c.Size = obj.Size
			c.Position = obj.Position
			c.AnchorPoint = obj.AnchorPoint
			c.Visible = obj.Visible
		end
		if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
			c.TextTransparency = obj.TextTransparency
		end
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			c.ImageTransparency = obj.ImageTransparency
		end
		if obj:IsA("ScrollingFrame") then
			c.ScrollBarImageTransparency = obj.ScrollBarImageTransparency
		end
		if obj:IsA("UIStroke") or obj:IsA("UIGradient") then
			c.Transparency = obj.Transparency
		end
		OriginalCache[obj] = c
	end
	CacheObj(root)
	for _, desc in ipairs(root:GetDescendants()) do
		CacheObj(desc)
	end
end

local function RegConn(connection)
	if connection and typeof(connection) == "RBXScriptConnection" then
		table.insert(VeloxConnections, connection)
	end
	return connection
end

local function UnregConn(connection)
	if not connection then return end
	for i = #VeloxConnections, 1, -1 do
		if VeloxConnections[i] == connection then
			table.remove(VeloxConnections, i)
			break
		end
	end
	if typeof(connection) == "RBXScriptConnection" and connection.Connected then
		pcall(function() connection:Disconnect() end)
	end
end

local function RegCardConn(connection)
	if connection and typeof(connection) == "RBXScriptConnection" then
		table.insert(CardConnections, connection)
	end
	return connection
end

local function TrackTask(fn)
	local thread
	thread = task.spawn(function()
		local ok, err = pcall(fn)
		PendingTasks[thread] = nil
		if not ok and not isDestroying then
			warn("[Velox Task Error]:", tostring(err))
		end
	end)
	PendingTasks[thread] = true
	return thread
end

local function IsTaskCurrent(generation)
	return not isDestroying and generation == CatalogGeneration
end

local function CancelTrackedTasks()
	for thread in pairs(PendingTasks) do
		if type(thread) == "thread" then pcall(task.cancel, thread) end
	end
	table.clear(PendingTasks)
end

local typingTask = nil

local function CleanUpMemory()
	isDestroying = true
	getgenv()[_G_Identifier] = nil
	if typingTask then task.cancel(typingTask); typingTask = nil end

	CancelTrackedTasks()

	if mainDragConnection then pcall(function() mainDragConnection:Disconnect() end) end
	if floatDragConnection then pcall(function() floatDragConnection:Disconnect() end) end
	if ToggleKeybindConnection then UnregConn(ToggleKeybindConnection); ToggleKeybindConnection = nil end
	if KeybindCaptureConnection then UnregConn(KeybindCaptureConnection); KeybindCaptureConnection = nil end

	for _, conn in ipairs(VeloxConnections) do
		if typeof(conn) == "RBXScriptConnection" and conn.Connected then
			conn:Disconnect()
		end
	end
	for _, conn in ipairs(CardConnections) do
		if typeof(conn) == "RBXScriptConnection" and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(VeloxConnections)
	table.clear(CardConnections)
	for _, conn in pairs(AfkConnections) do
		if type(conn) == "table" and conn.Enable then pcall(function() conn:Enable() end)
		elseif typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
	end
	for _, tweenData in pairs(ActiveTweens) do
		if type(tweenData) == "table" then
			if tweenData.Connection then pcall(function() tweenData.Connection:Disconnect() end) end
			if tweenData.Tween then
				pcall(function()
					tweenData.Tween:Cancel()
					tweenData.Tween:Destroy()
				end)
			end
		end
	end
	if DropdownContainer and DropdownContainer.Parent then pcall(function() DropdownContainer:Destroy() end) end
	if ToastContainer and ToastContainer.Parent then pcall(function() ToastContainer:Destroy() end) end
	if ConfirmOverlay and ConfirmOverlay.Parent then pcall(function() ConfirmOverlay:Destroy() end) end
	if GlobalCooldownBanner and GlobalCooldownBanner.Parent then pcall(function() GlobalCooldownBanner:Destroy() end) end

	table.clear(VeloxConnections)
	table.clear(CardConnections)
	table.clear(RegisteredScripts)
	table.clear(AfkConnections)
	table.clear(ActiveTweens)
	table.clear(InteractiveElements)
	table.clear(OriginalCache)
end

local function SafeTween(instance, tweenInfo, properties)
	if not instance or not instance.Parent then return nil end
	if ActiveTweens[instance] then
		local oldData = ActiveTweens[instance]
		if oldData and type(oldData) == "table" then
			if oldData.Connection then pcall(function() oldData.Connection:Disconnect() end) end
			if oldData.Tween then
				pcall(function()
					oldData.Tween:Cancel()
					oldData.Tween:Destroy()
				end)
			end
		end
	end
	local tween = TweenService:Create(instance, tweenInfo, properties)
	local conn
	conn = tween.Completed:Connect(function()
		if conn then conn:Disconnect() end
		if ActiveTweens[instance] and ActiveTweens[instance].Tween == tween then
			ActiveTweens[instance] = nil
		end
		pcall(function() tween:Destroy() end)
	end)
	ActiveTweens[instance] = { Tween = tween, Connection = conn }
	tween:Play()
	return tween
end

local function CreateDebounce(cooldown, func)
	local isRunning = false
	return function(...)
		if isRunning then return end
		isRunning = true
		local args = {...}
		task.spawn(function()
			pcall(func, unpack(args))
			task.wait(cooldown)
			isRunning = false
		end)
	end
end

local DATA_FILE = ".VeloxHub_Data_V3.1.json"
local TEMP_FILE = ".VeloxHub_Data_Temp.json"
local SavedData = {
	Favorites = {},
	AutoExecutes = {},
	ToggleKeybind = "RightControl",
	Settings = { AntiAFK = false }
}

local isSaving = false
local saveQueued = false

local function SanitizeForJSON(data)
	if type(data) == "table" then
		local clean = {}
		for k, v in pairs(data) do
			if type(k) == "string" or type(k) == "number" then
				local cleanVal = SanitizeForJSON(v)
				if cleanVal ~= nil then
					clean[tostring(k)] = cleanVal
				end
			end
		end
		return clean
	elseif type(data) == "string" or type(data) == "number" or type(data) == "boolean" then
		return data
	end
	return nil
end

local function SaveConfiguration()
	if type(write_file) ~= "function" then return end
	if isSaving then
		saveQueued = true
		return
	end
	isSaving = true
	task.spawn(function()
		local cleanData = {
			Favorites = {}, AutoExecutes = {},
			ToggleKeybind = tostring(SavedData.ToggleKeybind or "RightControl"),
			Settings = { AntiAFK = SavedData.Settings.AntiAFK == true }
		}
		for k, v in pairs(SavedData.Favorites) do if v then cleanData.Favorites[tostring(k)] = true end end
		for k, v in pairs(SavedData.AutoExecutes) do
			if type(v) == "table" then
				cleanData.AutoExecutes[tostring(k)] = {
					PlaceId = tonumber(v.PlaceId) or game.PlaceId,
					GameId = tonumber(v.GameId) or game.GameId
				}
			end
		end

		local safeData = SanitizeForJSON(cleanData)
		local success, result = pcall(function() return HttpService:JSONEncode(safeData) end)
		if success then
			local writeSuccess = pcall(function() write_file(TEMP_FILE, result) end)
			if writeSuccess then
				local verifySuccess = pcall(function()
					local check = read_file(TEMP_FILE)
					return HttpService:JSONDecode(check)
				end)
				if verifySuccess then
					pcall(function() write_file(DATA_FILE, result) end)
				end
			end
			pcall(function() del_file(TEMP_FILE) end)
		end
		isSaving = false
		if saveQueued then
			saveQueued = false
			SaveConfiguration()
		end
	end)
end

local function LoadConfiguration()
	if type(is_file) == "function" and type(read_file) == "function" and is_file(DATA_FILE) then
		local success, result = pcall(function() return HttpService:JSONDecode(read_file(DATA_FILE)) end)
		if success and type(result) == "table" then
			if type(result.Favorites) == "table" then
				for k, _ in pairs(result.Favorites) do SavedData.Favorites[tostring(k)] = true end
			end
			if type(result.AutoExecutes) == "table" then
				for k, v in pairs(result.AutoExecutes) do
					if type(k) == "string" and type(v) == "table" then
						SavedData.AutoExecutes[tostring(k)] = {
							PlaceId = type(v.PlaceId) == "number" and v.PlaceId or game.PlaceId,
							GameId = type(v.GameId) == "number" and v.GameId or nil
						}
					end
				end
			end
			if type(result.ToggleKeybind) == "string" then SavedData.ToggleKeybind = result.ToggleKeybind end
			if type(result.Settings) == "table" then
				for k, _ in pairs(result.Settings) do
					if result.Settings[k] ~= nil then SavedData.Settings[k] = result.Settings[k] end
				end
			end
		else
			SaveConfiguration()
		end
	end
end
LoadConfiguration()

local function UniversalHttpGet(url)
	if type(exec_request) == "function" then
		local reqSuccess, reqResult = pcall(function() return exec_request({Url = url, Method = "GET"}) end)
		if reqSuccess and reqResult then
			local body = reqResult.Body or reqResult.body or reqResult.Response
			local status = reqResult.StatusCode or reqResult.Status or reqResult.status_code
			if (status == 200 or status == nil) and body then
				return body
			end
		end
	end
	local success, result = pcall(function() return game:HttpGet(url) end)
	if success and result then return result end
	return nil
end

local function AddCacheBuster(url)
	if type(url) ~= "string" or url == "" then return url end
	local separator = string.find(url, "?", 1, true) and "&" or "?"
	local nonce = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
	return url .. separator .. "velox_cache=" .. nonce
end

local function FetchWithRetry(url, retries, cacheBust)
	retries = retries or 3
	for i = 1, retries do
		local requestUrl = url
		if cacheBust then
			requestUrl = AddCacheBuster(url)
		end

		local response = UniversalHttpGet(requestUrl)
		if response and type(response) == "string" and #response > 0 then
			return response
		end

		if i < retries then
			task.wait(math.pow(2, i))
		end
	end
	return nil
end

local TagTypeConfig = {
	UPDATED = {
		Priority = 5,
		BadgeColor = Theme.Success,
		CardColor = Color3.fromRGB(25, 44, 42),
		HoverColor = Color3.fromRGB(31, 55, 51),
		StrokeColor = Color3.fromRGB(58, 122, 106)
	},
	HOT = {
		Priority = 4,
		BadgeColor = Theme.Error,
		CardColor = Color3.fromRGB(43, 31, 37),
		HoverColor = Color3.fromRGB(57, 38, 46),
		StrokeColor = Color3.fromRGB(116, 67, 80)
	},
	NEW = {
		Priority = 3,
		BadgeColor = Theme.Info,
		CardColor = Color3.fromRGB(27, 38, 47),
		HoverColor = Color3.fromRGB(35, 49, 60),
		StrokeColor = Color3.fromRGB(62, 102, 126)
	},
	FEATURED = {
		Priority = 2,
		BadgeColor = Theme.System,
		CardColor = Color3.fromRGB(39, 32, 48),
		HoverColor = Color3.fromRGB(51, 40, 63),
		StrokeColor = Color3.fromRGB(92, 72, 117)
	},
	NONE = {
		Priority = 1,
		BadgeColor = Color3.fromRGB(100, 116, 139),
		CardColor = Theme.Card,
		HoverColor = Theme.CardHover,
		StrokeColor = Color3.fromRGB(44, 58, 77)
	}
}

local function NormalizeTagType(value)
	if type(value) ~= "string" then return "NONE" end
	local normalized = string.upper(string.gsub(value, "^%s*(.-)%s*$", "%1"))
	if TagTypeConfig[normalized] then return normalized end
	return "NONE"
end

local function GetSafeTimestamp(value)
	local timestamp = tonumber(value)
	if type(timestamp) ~= "number" or timestamp ~= timestamp then return 0 end
	return timestamp
end

local function GetRelativeTime(timestamp)
	local value = tonumber(timestamp)
	if type(value) ~= "number" or value ~= value then return "Updated just now" end
	local diff = os.time() - value
	if diff <= 0 then return "Updated just now" end
	if diff < 60 then return "Updated just now" end

	local minutes = math.floor(diff / 60)
	if minutes < 60 then
		return "Updated " .. minutes .. (minutes == 1 and " minute ago" or " minutes ago")
	end

	local hours = math.floor(diff / 3600)
	if hours < 24 then
		return "Updated " .. hours .. (hours == 1 and " hour ago" or " hours ago")
	end

	local days = math.floor(diff / 86400)
	if days == 1 then return "Updated yesterday" end
	if days < 7 then
		return "Updated " .. days .. (days == 1 and " day ago" or " days ago")
	end

	local weeks = math.floor(days / 7)
	if weeks < 4 then
		return "Updated " .. weeks .. (weeks == 1 and " week ago" or " weeks ago")
	end

	local months = math.floor(days / 30.44)
	if months < 12 then
		return "Updated " .. months .. (months == 1 and " month ago" or " months ago")
	end

	local years = math.floor(days / 365.25)
	return "Updated " .. years .. (years == 1 and " year ago" or " years ago")
end

local function GetSecureParent()
	local huiSuccess, huiTarget = pcall(function() return gethui() end)
	if huiSuccess and huiTarget and typeof(huiTarget) == "Instance" then
		return huiTarget
	end

	local coreSuccess, coreTarget = pcall(function() return CoreGui end)
	if coreSuccess and coreTarget then
		local testAccess = pcall(function()
			local t = Instance.new("Folder")
			t.Parent = coreTarget
			t:Destroy()
		end)
		if testAccess then return coreTarget end
	end

	if LocalPlayer then
		local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then return playerGui end
	end

	return nil
end

local TargetParent = GetSecureParent()
if not TargetParent then return end

local existingGui = TargetParent:FindFirstChild(MainGuiName)
if existingGui then pcall(function() existingGui:Destroy() end) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = MainGuiName
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = TargetParent
pcall(function() protectgui(ScreenGui) end)

getgenv()[_G_Identifier] = function()
	CleanUpMemory()
	if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end

local PANEL_SIZE = IsMobile and UDim2.new(0, 480, 0, 360) or UDim2.new(0, 560, 0, 515)

local function ApplyInteractiveAnimations(gui, originalColor, hoverColor, clickColor, strokeObj, originalStroke, hoverStroke, connectionRegistry)
	if not gui:IsA("GuiObject") then return end
	connectionRegistry = connectionRegistry or VeloxConnections
	InteractiveElements[gui] = {BaseColor = originalColor, BaseStroke = originalStroke, StrokeObj = strokeObj}

	local function RegInteractive(connection)
		if connectionRegistry == CardConnections then
			return RegCardConn(connection)
		end
		return RegConn(connection)
	end

	RegInteractive(gui.MouseEnter:Connect(function()
		if isDestroying or isTransitioning or IsMobile then return end
		if originalColor and hoverColor then gui.BackgroundColor3 = hoverColor end
		if strokeObj and hoverStroke then strokeObj.Color = hoverStroke end
	end))
	RegInteractive(gui.MouseLeave:Connect(function()
		if isDestroying or isTransitioning or IsMobile then return end
		if originalColor then gui.BackgroundColor3 = originalColor end
		if strokeObj and originalStroke then strokeObj.Color = originalStroke end
	end))
	RegInteractive(gui.InputBegan:Connect(function(input)
		if isDestroying or isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if clickColor then gui.BackgroundColor3 = clickColor end
		end
	end))
	RegInteractive(gui.InputEnded:Connect(function(input)
		if isDestroying or isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not IsMobile and hoverColor then
				gui.BackgroundColor3 = hoverColor
			elseif originalColor then
				gui.BackgroundColor3 = originalColor
			end
		end
	end))
end

RegConn(UserInputService.WindowFocusReleased:Connect(function()
	if isDestroying then return end
	for element, data in pairs(InteractiveElements) do
		if element and element.Parent then
			if data.BaseColor then pcall(function() element.BackgroundColor3 = data.BaseColor end) end
			if data.StrokeObj and data.BaseStroke then pcall(function() data.StrokeObj.Color = data.BaseStroke end) end
		end
	end
end))

local FloatingBtn = Instance.new("ImageButton", ScreenGui)
FloatingBtn.Name = FloatBtnName
FloatingBtn.AnchorPoint = Vector2.new(0.5, 0.5)
FloatingBtn.Position = UDim2.new(0.5, 0, 0, 42.5)
FloatingBtn.Size = UDim2.new(0, 45, 0, 45)
FloatingBtn.BackgroundColor3 = Theme.BackgroundMain
FloatingBtn.Image = "rbxassetid://124635602201411"
FloatingBtn.ScaleType = Enum.ScaleType.Fit
FloatingBtn.Visible = false
FloatingBtn.ZIndex = 100
FloatingBtn.Active = true
FloatingBtn.AutoButtonColor = false

local FloatPadding = Instance.new("UIPadding", FloatingBtn)
FloatPadding.PaddingLeft = UDim.new(0, 6); FloatPadding.PaddingRight = UDim.new(0, 6)
FloatPadding.PaddingTop = UDim.new(0, 6); FloatPadding.PaddingBottom = UDim.new(0, 6)
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = Theme.Accent; FloatStroke.Thickness = 2

local floatStart, floatPos
RegConn(FloatingBtn.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeFloatDragInput then
		activeFloatDragInput = input
		floatStart = input.Position
		floatPos = FloatingBtn.Position

		if floatDragConnection then floatDragConnection:Disconnect() end
		floatDragConnection = RegConn(UserInputService.InputChanged:Connect(function(moveInput)
			if isDestroying then return end
			if moveInput == activeFloatDragInput or moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = moveInput.Position - floatStart
				local camera = workspace.CurrentCamera
				local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
				local targetX = floatPos.X.Scale * viewport.X + floatPos.X.Offset + delta.X
				local targetY = floatPos.Y.Scale * viewport.Y + floatPos.Y.Offset + delta.Y
				local halfX = FloatingBtn.AbsoluteSize.X * FloatingBtn.AnchorPoint.X
				local halfY = FloatingBtn.AbsoluteSize.Y * FloatingBtn.AnchorPoint.Y
				targetX = math.clamp(targetX, halfX, viewport.X - (FloatingBtn.AbsoluteSize.X - halfX))
				targetY = math.clamp(targetY, halfY, viewport.Y - (FloatingBtn.AbsoluteSize.Y - halfY))
				FloatingBtn.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end))

local MainPanel = Instance.new("Frame", ScreenGui)
MainPanel.Size = PANEL_SIZE
MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
MainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
MainPanel.BackgroundColor3 = Theme.BackgroundMain
MainPanel.BorderSizePixel = 0
MainPanel.ClipsDescendants = true
MainPanel.Visible = true
MainPanel.Active = true
MainPanel.ZIndex = 1

local MainModalBtn = Instance.new("TextButton", MainPanel)
MainModalBtn.Size = UDim2.new(0, 0, 0, 0)
MainModalBtn.Visible = true
MainModalBtn.Modal = true
MainModalBtn.Text = ""

local MainGradient = Instance.new("UIGradient", MainPanel)
MainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.BackgroundMain),
	ColorSequenceKeypoint.new(1, Theme.BackgroundSecondary)
})
MainGradient.Rotation = 45

local PanelGroup = Instance.new("Frame", MainPanel)
PanelGroup.Size = UDim2.new(1, 0, 1, 0)
PanelGroup.BackgroundTransparency = 1
PanelGroup.Active = false

Instance.new("UICorner", MainPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MainPanel).Color = Theme.Stroke

local SearchInput

local function RestoreCachedProperties()
	for obj, c in pairs(OriginalCache) do
		if obj and obj.Parent then
			if c.BackgroundTransparency ~= nil then pcall(function() obj.BackgroundTransparency = c.BackgroundTransparency end) end
			if c.TextTransparency ~= nil then pcall(function() obj.TextTransparency = c.TextTransparency end) end
			if c.ImageTransparency ~= nil then pcall(function() obj.ImageTransparency = c.ImageTransparency end) end
			if c.ScrollBarImageTransparency ~= nil then pcall(function() obj.ScrollBarImageTransparency = c.ScrollBarImageTransparency end) end
			if c.Transparency ~= nil then pcall(function() obj.Transparency = c.Transparency end) end
			if obj == MainPanel or obj == FloatingBtn or obj == FloatStroke then
				if c.Size ~= nil then pcall(function() obj.Size = c.Size end) end
				if c.Position ~= nil then pcall(function() obj.Position = c.Position end) end
				if c.AnchorPoint ~= nil then pcall(function() obj.AnchorPoint = c.AnchorPoint end) end
			end
		end
	end
end

local function ToggleUI()
	if isDestroying or isTransitioning then return end
	isTransitioning = true

	if DropdownContainer and DropdownContainer.Visible then
		DropdownContainer.Visible = false
	end

	if not isMinimized then
		isMinimized = true
		if SearchInput and SearchInput.Parent then pcall(function() SearchInput:ReleaseFocus() end) end

		MainPanel.Visible = false
		RestoreCachedProperties()
		FloatingBtn.Visible = true
		FloatingBtn.Size = UDim2.new(0, 45, 0, 45)
		FloatingBtn.ImageTransparency = 0
		FloatStroke.Transparency = 0
	else
		isMinimized = false
		FloatingBtn.Visible = false
		MainPanel.Visible = true
		RestoreCachedProperties()
	end

	isTransitioning = false
end

ToastContainer = Instance.new("Frame", ScreenGui)
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, IsMobile and 240 or 320, 1, -40)
ToastContainer.Position = UDim2.new(1, IsMobile and -250 or -330, 0, 20)
ToastContainer.BackgroundTransparency = 1
ToastContainer.ZIndex = 2000

local ToastLayout = Instance.new("UIListLayout", ToastContainer)
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.Padding = UDim.new(0, 8)

local NOTIF_DURATION = 3.5

local function EmergencyFallbackNotification(msg, title)
	pcall(function()
		if StarterGui and type(StarterGui.SetCore) == "function" then
			StarterGui:SetCore("SendNotification", {
				Title = title or "Velox Hub Notice",
				Text = tostring(msg),
				Duration = NOTIF_DURATION
			})
		end
	end)
end

local function StandaloneBannerNotification(msg, notifType)
	local parent = GetSecureParent()
	if not parent then
		EmergencyFallbackNotification(msg, notifType)
		return
	end

	local success = pcall(function()
		local bannerGui = Instance.new("ScreenGui")
		bannerGui.Name = "VeloxBanner_" .. GenerateRandomString(8)
		bannerGui.DisplayOrder = 9999
		bannerGui.ResetOnSpawn = false
		bannerGui.Parent = parent

		local frame = Instance.new("Frame", bannerGui)
		frame.Size = UDim2.new(0, IsMobile and 260 or 340, 0, 45)
		frame.Position = UDim2.new(0.5, 0, 0, -60)
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.BackgroundColor3 = Theme.BackgroundSecondary
		frame.BorderSizePixel = 0
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = Theme[notifType] or Theme.Info
		stroke.Thickness = 1.5

		local txt = Instance.new("TextLabel", frame)
		txt.Size = UDim2.new(1, -20, 1, 0)
		txt.Position = UDim2.new(0, 10, 0, 0)
		txt.BackgroundTransparency = 1
		txt.Text = tostring(msg)
		txt.TextColor3 = Theme.TextPrimary
		txt.Font = Enum.Font.GothamMedium
		txt.TextSize = IsMobile and 11 or 13
		txt.TextWrapped = true

		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 20)
		}):Play()

		task.delay(NOTIF_DURATION, function()
			local outro = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -60)
			})
			outro:Play()
			outro.Completed:Connect(function()
				bannerGui:Destroy()
			end)
		end)
	end)

	if not success then
		EmergencyFallbackNotification(msg, notifType)
	end
end

local function ShowNotification(msg, notifType)
	if isDestroying then return end

	local nType = type(notifType) == "boolean" and (notifType and "Success" or "Error") or (notifType or "Info")
	local indicatorColor = Theme[nType] or Theme.Info

	if not ToastContainer or not ToastContainer.Parent then
		StandaloneBannerNotification(msg, nType)
		return
	end

	local success = pcall(function()
		local wrapper = Instance.new("Frame", ToastContainer)
		wrapper.Size = UDim2.new(1, 0, 0, 0)
		wrapper.AutomaticSize = Enum.AutomaticSize.Y
		wrapper.BackgroundTransparency = 1
		wrapper.ZIndex = 2001

		local box = Instance.new("Frame", wrapper)
		box.Size = UDim2.new(1, 0, 0, 0)
		box.AutomaticSize = Enum.AutomaticSize.Y
		box.BackgroundColor3 = Theme.CardHover
		box.Position = UDim2.new(1.2, 0, 0, 0)
		box.ClipsDescendants = true
		box.ZIndex = 2002
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", box).Color = Color3.fromRGB(40, 53, 75)

		local pad = Instance.new("UIPadding", box)
		pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
		pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 12)

		local indicator = Instance.new("Frame", box)
		indicator.Size = UDim2.new(0, 4, 1, 0)
		indicator.Position = UDim2.new(0, -12, 0, -10)
		indicator.BackgroundColor3 = indicatorColor
		indicator.BorderSizePixel = 0
		indicator.ZIndex = 2003
		Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 6)

		local txt = Instance.new("TextLabel", box)
		txt.Size = UDim2.new(1, 0, 0, 0); txt.AutomaticSize = Enum.AutomaticSize.Y
		txt.BackgroundTransparency = 1; txt.Text = tostring(msg)
		txt.TextColor3 = Theme.TextPrimary; txt.Font = Enum.Font.GothamMedium
		txt.TextSize = IsMobile and 11 or 13; txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.TextWrapped = true; txt.ZIndex = 2003

		local introTween = TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
		introTween:Play()

		task.delay(NOTIF_DURATION, function()
			if not wrapper or not wrapper.Parent then return end
			local outroTween = TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0, 0)})
			outroTween:Play()
			local conn
			conn = outroTween.Completed:Connect(function()
				if conn then conn:Disconnect() end
				if wrapper and wrapper.Parent then wrapper:Destroy() end
			end)
		end)
	end)

	if not success then
		StandaloneBannerNotification(msg, nType)
	end
end

local function AttemptActionWithCooldown(actionFunc)
	local now = tick()
	if now < GlobalActionCooldownEndTime then
		if not GlobalCooldownBanner or not GlobalCooldownBanner.Parent then
			GlobalCooldownLoopVersion = GlobalCooldownLoopVersion + 1
			local currentLoop = GlobalCooldownLoopVersion

			local parent = GetSecureParent()
			if not parent then return end

			local bannerGui = Instance.new("ScreenGui")
			bannerGui.Name = "VeloxCooldown_" .. GenerateRandomString(8)
			bannerGui.DisplayOrder = 10000
			bannerGui.ResetOnSpawn = false
			bannerGui.Parent = parent
			GlobalCooldownBanner = bannerGui

			local frame = Instance.new("Frame", bannerGui)
			frame.Size = UDim2.new(0, IsMobile and 280 or 340, 0, 45)
			frame.Position = UDim2.new(0.5, 0, 0, -60)
			frame.AnchorPoint = Vector2.new(0.5, 0)
			frame.BackgroundColor3 = Theme.BackgroundSecondary
			frame.BorderSizePixel = 0
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

			local stroke = Instance.new("UIStroke", frame)
			stroke.Color = Theme.Warning
			stroke.Thickness = 1.5

			local txt = Instance.new("TextLabel", frame)
			txt.Size = UDim2.new(1, -20, 1, 0)
			txt.Position = UDim2.new(0, 10, 0, 0)
			txt.BackgroundTransparency = 1
			txt.TextColor3 = Theme.TextPrimary
			txt.Font = Enum.Font.GothamMedium
			txt.TextSize = IsMobile and 11 or 13
			txt.TextWrapped = true

			TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 20)
			}):Play()

			task.spawn(function()
				while currentLoop == GlobalCooldownLoopVersion do
					local rem = math.ceil(GlobalActionCooldownEndTime - tick())
					if rem > 1 then
						if txt and txt.Parent then txt.Text = "Please try again in " .. rem .. " seconds" end
					elseif rem == 1 then
						if txt and txt.Parent then txt.Text = "Please try again in 1 second" end
					else
						if txt and txt.Parent then
							txt.Text = "Ready"
							stroke.Color = Theme.Success
						end
						task.wait(1)
						if currentLoop == GlobalCooldownLoopVersion then
							if frame and frame.Parent then
								local outro = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
									Position = UDim2.new(0.5, 0, 0, -60)
								})
								outro:Play()
								outro.Completed:Wait()
							end
							if bannerGui and bannerGui.Parent then bannerGui:Destroy() end
							if GlobalCooldownBanner == bannerGui then
								GlobalCooldownBanner = nil
							end
						end
						break
					end
					task.wait(0.1)
				end
			end)
		end
		return
	end

	GlobalActionCooldownEndTime = tick() + 3

	if GlobalCooldownBanner and GlobalCooldownBanner.Parent then
		GlobalCooldownLoopVersion = GlobalCooldownLoopVersion + 1
		pcall(function() GlobalCooldownBanner:Destroy() end)
		GlobalCooldownBanner = nil
	end

	task.spawn(actionFunc)
end

ConfirmOverlay = Instance.new("Frame", ScreenGui)
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.Position = UDim2.new(0, 0, 0, 0)
ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 1
ConfirmOverlay.Visible = false
ConfirmOverlay.ZIndex = 400
ConfirmOverlay.Active = false

local ConfirmBox = Instance.new("Frame", ConfirmOverlay)
ConfirmBox.Size = IsMobile and UDim2.new(0, 300, 0, 180) or UDim2.new(0, 360, 0, 190)
ConfirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmBox.BackgroundColor3 = Theme.BackgroundSecondary
ConfirmBox.BorderSizePixel = 0
ConfirmBox.ClipsDescendants = true
ConfirmBox.ZIndex = 401
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 12)
local ConfirmBoxStroke = Instance.new("UIStroke", ConfirmBox)
ConfirmBoxStroke.Color = Theme.Stroke; ConfirmBoxStroke.Thickness = 1

local ConfirmPadding = Instance.new("UIPadding", ConfirmBox)
ConfirmPadding.PaddingTop = UDim.new(0, 16); ConfirmPadding.PaddingBottom = UDim.new(0, 16)
ConfirmPadding.PaddingLeft = UDim.new(0, 20); ConfirmPadding.PaddingRight = UDim.new(0, 20)

local ConfirmLayout = Instance.new("UIListLayout", ConfirmBox)
ConfirmLayout.SortOrder = Enum.SortOrder.LayoutOrder
ConfirmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ConfirmLayout.VerticalAlignment = Enum.VerticalAlignment.Center; ConfirmLayout.Padding = UDim.new(0, 8)

local ConfirmTitle = Instance.new("TextLabel", ConfirmBox)
ConfirmTitle.Size = UDim2.new(1, 0, 0, 22); ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "Execute Script"; ConfirmTitle.TextColor3 = Theme.TextPrimary
ConfirmTitle.Font = Enum.Font.GothamBold; ConfirmTitle.TextSize = IsMobile and 14 or 16
ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Center; ConfirmTitle.LayoutOrder = 1; ConfirmTitle.ZIndex = 402

local ConfirmMessage = Instance.new("TextLabel", ConfirmBox)
ConfirmMessage.Size = UDim2.new(1, 0, 0, 18); ConfirmMessage.BackgroundTransparency = 1
ConfirmMessage.Text = "Are you sure you want to run this script?"
ConfirmMessage.TextColor3 = Theme.TextSecondary; ConfirmMessage.Font = Enum.Font.Gotham
ConfirmMessage.TextSize = IsMobile and 11 or 12; ConfirmMessage.TextXAlignment = Enum.TextXAlignment.Center
ConfirmMessage.TextWrapped = true; ConfirmMessage.LayoutOrder = 2; ConfirmMessage.ZIndex = 402

local ConfirmScriptName = Instance.new("TextLabel", ConfirmBox)
ConfirmScriptName.Size = UDim2.new(1, 0, 0, 0); ConfirmScriptName.AutomaticSize = Enum.AutomaticSize.Y
ConfirmScriptName.BackgroundTransparency = 1; ConfirmScriptName.Text = ""
ConfirmScriptName.TextColor3 = Theme.Accent; ConfirmScriptName.Font = Enum.Font.GothamBold
ConfirmScriptName.TextSize = IsMobile and 12 or 13; ConfirmScriptName.TextXAlignment = Enum.TextXAlignment.Center
ConfirmScriptName.TextWrapped = true; ConfirmScriptName.LayoutOrder = 3; ConfirmScriptName.ZIndex = 402

local ConfirmButtonRow = Instance.new("Frame", ConfirmBox)
ConfirmButtonRow.Size = UDim2.new(1, 0, 0, 34); ConfirmButtonRow.BackgroundTransparency = 1
ConfirmButtonRow.LayoutOrder = 4; ConfirmButtonRow.ZIndex = 402
local ConfirmRowLayout = Instance.new("UIListLayout", ConfirmButtonRow)
ConfirmRowLayout.FillDirection = Enum.FillDirection.Horizontal
ConfirmRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ConfirmRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ConfirmRowLayout.SortOrder = Enum.SortOrder.LayoutOrder; ConfirmRowLayout.Padding = UDim.new(0, 12)

local ConfirmCancelBtn = Instance.new("TextButton", ConfirmButtonRow)
ConfirmCancelBtn.Size = UDim2.new(0.5, -6, 1, 0); ConfirmCancelBtn.BackgroundColor3 = Theme.CardHover
ConfirmCancelBtn.Text = "Cancel"; ConfirmCancelBtn.TextColor3 = Theme.TextPrimary
ConfirmCancelBtn.Font = Enum.Font.GothamBold; ConfirmCancelBtn.TextSize = IsMobile and 11 or 12
ConfirmCancelBtn.AutoButtonColor = false; ConfirmCancelBtn.LayoutOrder = 1; ConfirmCancelBtn.ZIndex = 403
Instance.new("UICorner", ConfirmCancelBtn).CornerRadius = UDim.new(0, 6)
local CancelStroke = Instance.new("UIStroke", ConfirmCancelBtn); CancelStroke.Color = Theme.Stroke

local ConfirmExecuteBtn = Instance.new("TextButton", ConfirmButtonRow)
ConfirmExecuteBtn.Size = UDim2.new(0.5, -6, 1, 0); ConfirmExecuteBtn.BackgroundColor3 = Theme.Accent
ConfirmExecuteBtn.Text = "Execute"; ConfirmExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmExecuteBtn.Font = Enum.Font.GothamBold; ConfirmExecuteBtn.TextSize = IsMobile and 11 or 12
ConfirmExecuteBtn.AutoButtonColor = false; ConfirmExecuteBtn.LayoutOrder = 2; ConfirmExecuteBtn.ZIndex = 403
Instance.new("UICorner", ConfirmExecuteBtn).CornerRadius = UDim.new(0, 6)

ApplyInteractiveAnimations(ConfirmCancelBtn, Theme.CardHover, Color3.fromRGB(40, 53, 75), Color3.fromRGB(20, 29, 45), CancelStroke, Theme.Stroke, Theme.Accent)
ApplyInteractiveAnimations(ConfirmExecuteBtn, Theme.Accent, Color3.fromRGB(120, 123, 245), Color3.fromRGB(79, 82, 221))

local isConfirming = false
local pendingExecuteCallback = nil

local function OpenConfirmDialog(scriptName, onExecute)
	if isConfirming or isTransitioning then return end
	isConfirming = true
	pendingExecuteCallback = onExecute
	ConfirmScriptName.Text = scriptName
	ConfirmExecuteBtn.Active = true
	ConfirmExecuteBtn.AutoButtonColor = true
	ConfirmExecuteBtn.Text = "Execute"
	ConfirmOverlay.BackgroundTransparency = 0.5
	ConfirmOverlay.Visible = true
	ConfirmOverlay.Active = true
end

local function CloseConfirmDialog(shouldExecute)
	if not isConfirming then return end
	ConfirmExecuteBtn.Active = false
	ConfirmOverlay.BackgroundTransparency = 1
	ConfirmOverlay.Visible = false
	ConfirmOverlay.Active = false
	isConfirming = false
	local cb = pendingExecuteCallback
	pendingExecuteCallback = nil
	if shouldExecute and type(cb) == "function" then task.spawn(cb) end
end

RegConn(ConfirmCancelBtn.Activated:Connect(CreateDebounce(0.1, function() CloseConfirmDialog(false) end)))
RegConn(ConfirmExecuteBtn.Activated:Connect(function()
	AttemptActionWithCooldown(function()
		CloseConfirmDialog(true)
	end)
end))

RegConn(ConfirmOverlay.InputBegan:Connect(function(input)
	if not isConfirming then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		local bPos, bSize = ConfirmBox.AbsolutePosition, ConfirmBox.AbsoluteSize
		local inside = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y
		if not inside then CloseConfirmDialog(false) end
	end
end))

local ToggleKeybind = Enum.KeyCode.RightControl
pcall(function() if SavedData.ToggleKeybind then ToggleKeybind = Enum.KeyCode[SavedData.ToggleKeybind] end end)
local KeybindButtonRef = nil

local function BindToggleKey(keyCode)
	if ToggleKeybindConnection then
		UnregConn(ToggleKeybindConnection)
		ToggleKeybindConnection = nil
	end

	ToggleKeybindConnection = RegConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or isConfirming or IsBindingKey or isTransitioning or isDestroying then return end

		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyCode then
			if SearchInput and SearchInput:IsFocused() then
				SearchInput:ReleaseFocus()
			end
			ToggleUI()
		end
	end))
end

BindToggleKey(ToggleKeybind)

RegConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isConfirming then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
			CloseConfirmDialog(false)
			return
		end
	end
end))

local function CloseUI()
	if isDestroying then return end
	if SearchInput and SearchInput.Parent then pcall(function() SearchInput:ReleaseFocus() end) end
	isDestroying = true
	getgenv()[_G_Identifier]()
end

local HeaderContainer = Instance.new("Frame", PanelGroup)
HeaderContainer.Size = UDim2.new(1, -32, 0, IsMobile and 48 or 56)
HeaderContainer.Position = UDim2.new(0, 16, 0, IsMobile and 6 or 10)
HeaderContainer.BackgroundTransparency = 1
HeaderContainer.Active = true

local mainDragStart, mainStartPos

RegConn(HeaderContainer.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeMainDragInput then
		activeMainDragInput = input
		mainDragStart = input.Position
		mainStartPos = MainPanel.Position

		if mainDragConnection then mainDragConnection:Disconnect() end
		mainDragConnection = RegConn(UserInputService.InputChanged:Connect(function(moveInput)
			if isDestroying then return end
			if moveInput == activeMainDragInput or moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = moveInput.Position - mainDragStart
				local camera = workspace.CurrentCamera
				local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
				local targetX = mainStartPos.X.Scale * viewport.X + mainStartPos.X.Offset + delta.X
				local targetY = mainStartPos.Y.Scale * viewport.Y + mainStartPos.Y.Offset + delta.Y
				local halfX = MainPanel.AbsoluteSize.X * MainPanel.AnchorPoint.X
				local halfY = MainPanel.AbsoluteSize.Y * MainPanel.AnchorPoint.Y
				targetX = math.clamp(targetX, halfX, viewport.X - (MainPanel.AbsoluteSize.X - halfX))
				targetY = math.clamp(targetY, halfY, viewport.Y - (MainPanel.AbsoluteSize.Y - halfY))
				MainPanel.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end))

RegConn(UserInputService.InputEnded:Connect(function(input)
	if isDestroying then return end
	if activeMainDragInput and (input == activeMainDragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
		activeMainDragInput = nil
		if mainDragConnection then
			mainDragConnection:Disconnect()
			mainDragConnection = nil
		end
		if OriginalCache[MainPanel] then OriginalCache[MainPanel].Position = MainPanel.Position end
	end
	if activeFloatDragInput and (input == activeFloatDragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
		activeFloatDragInput = nil
		if floatDragConnection then
			floatDragConnection:Disconnect()
			floatDragConnection = nil
		end
		if floatStart then
			local dist = (input.Position - floatStart).Magnitude
			if dist < 12 then
				ToggleUI()
			else
				if OriginalCache[FloatingBtn] then OriginalCache[FloatingBtn].Position = FloatingBtn.Position end
			end
		end
	end
end))

local LeftHeaderFrame = Instance.new("Frame", HeaderContainer)
LeftHeaderFrame.Size = UDim2.new(0.6, 0, 1, 0); LeftHeaderFrame.BackgroundTransparency = 1; LeftHeaderFrame.Active = false
local LHLay = Instance.new("UIListLayout", LeftHeaderFrame)
LHLay.SortOrder = Enum.SortOrder.LayoutOrder; LHLay.Padding = UDim.new(0, 4); LHLay.VerticalAlignment = Enum.VerticalAlignment.Center

local TopLeftRow = Instance.new("Frame", LeftHeaderFrame)
TopLeftRow.Size = UDim2.new(1, 0, 0, 24); TopLeftRow.BackgroundTransparency = 1; TopLeftRow.LayoutOrder = 1
local TLRowLay = Instance.new("UIListLayout", TopLeftRow)
TLRowLay.FillDirection = Enum.FillDirection.Horizontal; TLRowLay.SortOrder = Enum.SortOrder.LayoutOrder; TLRowLay.Padding = UDim.new(0, 8); TLRowLay.VerticalAlignment = Enum.VerticalAlignment.Center

local Title = Instance.new("TextLabel", TopLeftRow)
Title.AutomaticSize = Enum.AutomaticSize.X; Title.Size = UDim2.new(0, 0, 1, 0); Title.BackgroundTransparency = 1
Title.Text = "Velox Hub"; Title.TextColor3 = Theme.TextPrimary
Title.Font = Enum.Font.GothamBold; Title.TextSize = IsMobile and 16 or 19; Title.LayoutOrder = 1

local StatusDot = Instance.new("Frame", TopLeftRow)
StatusDot.Size = UDim2.new(0, 8, 0, 8); StatusDot.LayoutOrder = 2
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel", TopLeftRow)
StatusText.AutomaticSize = Enum.AutomaticSize.X; StatusText.Size = UDim2.new(0, 0, 1, 0); StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.GothamBold; StatusText.TextSize = 11; StatusText.LayoutOrder = 3

local BtmLeftRow = Instance.new("Frame", LeftHeaderFrame)
BtmLeftRow.Size = UDim2.new(1, 0, 0, 14); BtmLeftRow.BackgroundTransparency = 1; BtmLeftRow.LayoutOrder = 2
local BLRowLay = Instance.new("UIListLayout", BtmLeftRow)
BLRowLay.FillDirection = Enum.FillDirection.Horizontal; BLRowLay.SortOrder = Enum.SortOrder.LayoutOrder; BLRowLay.Padding = UDim.new(0, 6)

local VersionLabel = Instance.new("TextLabel", BtmLeftRow)
VersionLabel.AutomaticSize = Enum.AutomaticSize.X; VersionLabel.Size = UDim2.new(0, 0, 1, 0)
VersionLabel.BackgroundTransparency = 1; VersionLabel.Text = "v2.0.0 BETA | " .. getexecutor()
VersionLabel.TextColor3 = Theme.Accent; VersionLabel.Font = Enum.Font.GothamMedium; VersionLabel.TextSize = IsMobile and 10 or 12; VersionLabel.LayoutOrder = 1

local DiagnosticsLabel = Instance.new("TextLabel", BtmLeftRow)
DiagnosticsLabel.AutomaticSize = Enum.AutomaticSize.X; DiagnosticsLabel.Size = UDim2.new(0, 0, 1, 0); DiagnosticsLabel.BackgroundTransparency = 1
DiagnosticsLabel.TextColor3 = Theme.TextSecondary; DiagnosticsLabel.Font = Enum.Font.GothamMedium; DiagnosticsLabel.TextSize = IsMobile and 9 or 11
DiagnosticsLabel.Text = "FPS: -- | Ping: --ms"; DiagnosticsLabel.LayoutOrder = 2

local RightHeaderFrame = Instance.new("Frame", HeaderContainer)
RightHeaderFrame.Size = UDim2.new(0.4, 0, 1, 0); RightHeaderFrame.Position = UDim2.new(1, 0, 0, 0); RightHeaderFrame.AnchorPoint = Vector2.new(1, 0)
RightHeaderFrame.BackgroundTransparency = 1; RightHeaderFrame.Active = false
local RHLay = Instance.new("UIListLayout", RightHeaderFrame)
RHLay.FillDirection = Enum.FillDirection.Horizontal; RHLay.SortOrder = Enum.SortOrder.LayoutOrder; RHLay.HorizontalAlignment = Enum.HorizontalAlignment.Right; RHLay.VerticalAlignment = Enum.VerticalAlignment.Center; RHLay.Padding = UDim.new(0, 8)

local UserInfoFrame = Instance.new("Frame", RightHeaderFrame)
UserInfoFrame.Size = UDim2.new(0, IsMobile and 70 or 90, 1, 0); UserInfoFrame.BackgroundTransparency = 1; UserInfoFrame.LayoutOrder = 1
local UILay = Instance.new("UIListLayout", UserInfoFrame)
UILay.SortOrder = Enum.SortOrder.LayoutOrder; UILay.VerticalAlignment = Enum.VerticalAlignment.Center

local UI_DisplayName = Instance.new("TextLabel", UserInfoFrame)
UI_DisplayName.Size = UDim2.new(1, 0, 0, 0); UI_DisplayName.AutomaticSize = Enum.AutomaticSize.Y; UI_DisplayName.BackgroundTransparency = 1
UI_DisplayName.Text = LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name; UI_DisplayName.TextColor3 = Theme.TextPrimary
UI_DisplayName.Font = Enum.Font.GothamBold; UI_DisplayName.TextSize = IsMobile and 10 or 12
UI_DisplayName.TextXAlignment = Enum.TextXAlignment.Right; UI_DisplayName.LayoutOrder = 1

local UI_Username = Instance.new("TextLabel", UserInfoFrame)
UI_Username.Size = UDim2.new(1, 0, 0, 0); UI_Username.AutomaticSize = Enum.AutomaticSize.Y; UI_Username.BackgroundTransparency = 1
UI_Username.Text = "@" .. LocalPlayer.Name; UI_Username.TextColor3 = Theme.TextSecondary
UI_Username.Font = Enum.Font.Gotham; UI_Username.TextSize = IsMobile and 9 or 10
UI_Username.TextXAlignment = Enum.TextXAlignment.Right; UI_Username.LayoutOrder = 2

local AvatarFrame = Instance.new("ImageLabel", RightHeaderFrame)
AvatarFrame.Size = UDim2.new(0, IsMobile and 26 or 32, 0, IsMobile and 26 or 32); AvatarFrame.BackgroundColor3 = Theme.CardHover
AvatarFrame.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"; AvatarFrame.LayoutOrder = 2
Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(0, 8)
local AvatarStroke = Instance.new("UIStroke", AvatarFrame); AvatarStroke.Color = Theme.Accent; AvatarStroke.Thickness = 1.5

task.spawn(function()
	local attempts = 0
	while attempts < 3 and not isDestroying do
		attempts = attempts + 1
		local success, content = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
		if success and content then
			if isDestroying then return end
			if AvatarFrame and AvatarFrame.Parent then AvatarFrame.Image = content end
			break
		else
			task.wait(2)
		end
	end
end)

local MinBtn = Instance.new("TextButton", RightHeaderFrame)
MinBtn.Size = UDim2.new(0, 28, 0, 28); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TextSecondary; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = IsMobile and 14 or 18; MinBtn.LayoutOrder = 3
MinBtn.ClipsDescendants = true
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
RegConn(MinBtn.Activated:Connect(function() ToggleUI() end))
ApplyInteractiveAnimations(MinBtn, nil, Theme.CardHover, Theme.CardHover, nil, nil, nil)

local fpsCount = 0
local diagnosticsElapsed = 0
RegConn(RunService.Heartbeat:Connect(function(deltaTime)
	if isDestroying then return end
	if isMinimized or isTransitioning then
		fpsCount = 0
		diagnosticsElapsed = 0
		return
	end
	fpsCount = fpsCount + 1
	diagnosticsElapsed = diagnosticsElapsed + deltaTime
	if diagnosticsElapsed < 1 then return end
	diagnosticsElapsed = diagnosticsElapsed - 1
	local success, ping = pcall(function()
		return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
	end)
	if DiagnosticsLabel and DiagnosticsLabel.Parent then
		DiagnosticsLabel.Text = string.format("FPS: %d | Ping: %dms", fpsCount, success and ping or 0)
	end
	fpsCount = 0
end))

local TabContainer = Instance.new("Frame", PanelGroup)
TabContainer.Size = UDim2.new(1, -32, 0, 24); TabContainer.Position = UDim2.new(0, 16, 0, IsMobile and 58 or 72); TabContainer.BackgroundTransparency = 1; TabContainer.Active = false

local SectionHeaderLabel = Instance.new("TextLabel", PanelGroup)
SectionHeaderLabel.Size = UDim2.new(1, -32, 0, IsMobile and 16 or 20); SectionHeaderLabel.Position = UDim2.new(0, 16, 0, IsMobile and 88 or 104); SectionHeaderLabel.BackgroundTransparency = 1
SectionHeaderLabel.Text = "Updates"; SectionHeaderLabel.TextColor3 = Theme.TextPrimary
SectionHeaderLabel.Font = Enum.Font.GothamBold; SectionHeaderLabel.TextSize = IsMobile and 13 or 16; SectionHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

local TabViews = {}
local currentTab = "Changelogs"

local function CreateCanvas(name)
	local scroll = Instance.new("ScrollingFrame", PanelGroup)
	scroll.Size = UDim2.new(1, -32, 1, IsMobile and -116 or -138)
	scroll.Position = UDim2.new(0, 16, 0, IsMobile and 108 or 128)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = Theme.Stroke
	scroll.Visible = (name == currentTab)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.Active = true
	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, IsMobile and 8 or 12); layout.SortOrder = Enum.SortOrder.LayoutOrder
	local pad = Instance.new("UIPadding", scroll)
	pad.PaddingRight = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 16)
	TabViews[name] = scroll
	return scroll
end

local ChangelogsView = CreateCanvas("Changelogs")
local ScriptsView = CreateCanvas("Scripts")
local SettingsView = CreateCanvas("Settings")

ScriptsView.Position = IsMobile and UDim2.new(0, 16, 0, 144) or UDim2.new(0, 16, 0, 168)
ScriptsView.Size = IsMobile and UDim2.new(1, -32, 1, -152) or UDim2.new(1, -32, 1, -178)

local EmptyStateMessage = Instance.new("TextLabel", ScriptsView)
EmptyStateMessage.Size = UDim2.new(1, 0, 0, 40); EmptyStateMessage.BackgroundTransparency = 1
EmptyStateMessage.TextColor3 = Theme.TextSecondary; EmptyStateMessage.Font = Enum.Font.GothamMedium
EmptyStateMessage.TextSize = 12; EmptyStateMessage.TextWrapped = true; EmptyStateMessage.LayoutOrder = -1

local SearchRow = Instance.new("Frame", PanelGroup)
SearchRow.Size = UDim2.new(1, -32, 0, IsMobile and 28 or 32); SearchRow.Position = UDim2.new(0, 16, 0, IsMobile and 108 or 128)
SearchRow.BackgroundTransparency = 1; SearchRow.Visible = false; SearchRow.Active = false; SearchRow.ZIndex = 50

local filterBtnWidth = IsMobile and 28 or 32
local gap = 8

local SearchContainer = Instance.new("Frame", SearchRow)
SearchContainer.Size = UDim2.new(1, -(filterBtnWidth * 2 + gap * 2), 1, 0); SearchContainer.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
SearchContainer.ClipsDescendants = true; SearchContainer.ZIndex = 51
Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 6)
local SearchStroke = Instance.new("UIStroke", SearchContainer); SearchStroke.Color = Color3.fromRGB(51, 65, 85); SearchStroke.Thickness = 1

SearchInput = Instance.new("TextBox", SearchContainer)
SearchInput.Size = UDim2.new(1, -40, 1, 0); SearchInput.Position = UDim2.new(0, 12, 0, 0); SearchInput.BackgroundTransparency = 1
SearchInput.Text = ""; SearchInput.PlaceholderText = "Search scripts by name..."
SearchInput.PlaceholderColor3 = Color3.fromRGB(148, 163, 184); SearchInput.TextColor3 = Color3.fromRGB(248, 250, 252)
SearchInput.Font = Enum.Font.Gotham; SearchInput.TextSize = 12; SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false; SearchInput.TextEditable = true; SearchInput.Interactable = true; SearchInput.ZIndex = 52
Instance.new("UIPadding", SearchInput).PaddingRight = UDim.new(0, 10)

local ClearSearchBtn = Instance.new("TextButton", SearchContainer)
ClearSearchBtn.Size = UDim2.new(0, 24, 0, 24)
ClearSearchBtn.Position = UDim2.new(1, -28, 0.5, -12)
ClearSearchBtn.BackgroundTransparency = 1
ClearSearchBtn.Text = "×"
ClearSearchBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
ClearSearchBtn.TextSize = 18
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.ZIndex = 53
ClearSearchBtn.Visible = (SearchInput.Text ~= "")

RegConn(SearchInput.Focused:Connect(function() SearchStroke.Color = Theme.Accent end))
RegConn(SearchInput.FocusLost:Connect(function() SearchStroke.Color = Theme.Stroke end))

local FavFilterBtn = Instance.new("TextButton", SearchRow)
FavFilterBtn.Size = UDim2.new(0, filterBtnWidth, 1, 0); FavFilterBtn.Position = UDim2.new(1, -(filterBtnWidth * 2 + gap), 0, 0)
FavFilterBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59); FavFilterBtn.Text = "☆"
FavFilterBtn.TextColor3 = Color3.fromRGB(148, 163, 184); FavFilterBtn.TextSize = 15
FavFilterBtn.Font = Enum.Font.GothamBold; FavFilterBtn.ZIndex = 51
Instance.new("UICorner", FavFilterBtn).CornerRadius = UDim.new(0, 6)
local FavFilterStroke = Instance.new("UIStroke", FavFilterBtn); FavFilterStroke.Color = Color3.fromRGB(51, 65, 85)

local SortDropdownBtn = Instance.new("TextButton", SearchRow)
SortDropdownBtn.Size = UDim2.new(0, filterBtnWidth, 1, 0); SortDropdownBtn.Position = UDim2.new(1, -filterBtnWidth, 0, 0)
SortDropdownBtn.BackgroundColor3 = Color3.fromRGB(38, 51, 74); SortDropdownBtn.Text = "↕"
SortDropdownBtn.TextColor3 = Theme.TextSecondary; SortDropdownBtn.TextSize = 15
SortDropdownBtn.Font = Enum.Font.GothamBold; SortDropdownBtn.ZIndex = 51; SortDropdownBtn.ClipsDescendants = true
Instance.new("UICorner", SortDropdownBtn).CornerRadius = UDim.new(0, 6)
local SortBtnStroke = Instance.new("UIStroke", SortDropdownBtn); SortBtnStroke.Color = Theme.Stroke
ApplyInteractiveAnimations(SortDropdownBtn, Color3.fromRGB(38, 51, 74), Color3.fromRGB(50, 68, 96), Theme.BackgroundSecondary, SortBtnStroke, Theme.Stroke, Theme.Accent)

DropdownContainer = Instance.new("ScrollingFrame", ScreenGui)
DropdownContainer.Size = UDim2.new(0, 190, 0, 210); DropdownContainer.BackgroundColor3 = Theme.BackgroundMain
DropdownContainer.Visible = false; DropdownContainer.ZIndex = 1000; DropdownContainer.BorderSizePixel = 0
DropdownContainer.ScrollBarThickness = 2; DropdownContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", DropdownContainer).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", DropdownContainer).Color = Theme.Accent
local DDLayout = Instance.new("UIListLayout", DropdownContainer); DDLayout.SortOrder = Enum.SortOrder.LayoutOrder

local viewportConn
local function BindCamera()
	if viewportConn then viewportConn:Disconnect() end
	local cam = workspace.CurrentCamera
	if cam then
		viewportConn = RegConn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if DropdownContainer and DropdownContainer.Visible then
				DropdownContainer.Visible = false
			end
			if MainPanel and MainPanel.Parent then
				local viewport = cam.ViewportSize
				local halfX = MainPanel.AbsoluteSize.X * MainPanel.AnchorPoint.X
				local halfY = MainPanel.AbsoluteSize.Y * MainPanel.AnchorPoint.Y
				local currentOffsetX = MainPanel.Position.X.Offset
				local currentOffsetY = MainPanel.Position.Y.Offset
				if MainPanel.Position.X.Scale ~= 0 or MainPanel.Position.Y.Scale ~= 0 then
					currentOffsetX = MainPanel.Position.X.Scale * viewport.X + currentOffsetX
					currentOffsetY = MainPanel.Position.Y.Scale * viewport.Y + currentOffsetY
				end
				local targetX = math.clamp(currentOffsetX, halfX, viewport.X - (MainPanel.AbsoluteSize.X - halfX))
				local targetY = math.clamp(currentOffsetY, halfY, viewport.Y - (MainPanel.AbsoluteSize.Y - halfY))
				MainPanel.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end
RegConn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCamera))
BindCamera()

local FilterFavoritesActive = false
local filterVersion = 0
local SortMode = "Most Relevant"
local SortOptions = {
	"Most Relevant", "A-Z", "Z-A", "Newest", "Oldest",
	"Updated Today", "Updated This Week", "Updated This Month",
	"Favorites", "Auto Execute: ON", "Auto Execute: OFF"
}

local function UpdateFilter()
	if isDestroying then return end
	filterVersion = filterVersion + 1
	local currentVersion = filterVersion
	task.defer(function()
		if isDestroying or currentVersion ~= filterVersion then return end
		local queryText = SearchInput.Text or ""
		local query = string.lower(string.gsub(queryText, "^%s*(.-)%s*$", "%1"))
		local words = {}
		for word in string.gmatch(query, "%S+") do
			words[#words + 1] = word
		end
		local matches = {}
		local now = os.time()
		local activeFavorites = FilterFavoritesActive
		local currentSort = SortMode

		for _, scr in ipairs(RegisteredScripts) do
			if currentVersion ~= filterVersion then return end
			local isMatch = true
			if query ~= "" then
				for _, word in ipairs(words) do
					if not string.find(scr.SearchTitle, word, 1, true)
						and not string.find(scr.SearchDesc, word, 1, true)
						and not string.find(scr.SearchMeta, word, 1, true) then
						isMatch = false
						break
					end
				end
			end

			local filterPass = true
			local age = scr.LastUpdatedNumber and (now - scr.LastUpdatedNumber) or math.huge
			if activeFavorites then
				filterPass = SavedData.Favorites[scr.ExactName] == true
			end
			if filterPass then
				if currentSort == "Updated Today" then
					filterPass = age <= 86400
				elseif currentSort == "Updated This Week" then
					filterPass = age <= 604800
				elseif currentSort == "Updated This Month" then
					filterPass = age <= 2592000
				elseif currentSort == "Favorites" then
					filterPass = SavedData.Favorites[scr.ExactName] == true
				elseif currentSort == "Auto Execute: ON" then
					filterPass = SavedData.AutoExecutes[scr.ExactName] ~= nil
				elseif currentSort == "Auto Execute: OFF" then
					filterPass = SavedData.AutoExecutes[scr.ExactName] == nil
				end
			end

			local visible = isMatch and filterPass
			if scr.Instance.Visible ~= visible then
				scr.Instance.Visible = visible
			end
			if visible then
				matches[#matches + 1] = scr
			end
		end

		if currentVersion ~= filterVersion then return end
		table.sort(matches, function(a, b)
			if a.TagPriority ~= b.TagPriority then
				return a.TagPriority > b.TagPriority
			end

			local aUpdated = a.LastUpdatedNumber
			local bUpdated = b.LastUpdatedNumber
			if currentSort == "A-Z" then
				if a.SearchTitle ~= b.SearchTitle then return a.SearchTitle < b.SearchTitle end
			elseif currentSort == "Z-A" then
				if a.SearchTitle ~= b.SearchTitle then return a.SearchTitle > b.SearchTitle end
			elseif currentSort == "Oldest" then
				if aUpdated ~= bUpdated then return aUpdated < bUpdated end
			elseif currentSort == "Favorites" then
				local aFav = SavedData.Favorites[a.ExactName] and 1 or 0
				local bFav = SavedData.Favorites[b.ExactName] and 1 or 0
				if aFav ~= bFav then return aFav > bFav end
			elseif currentSort == "Auto Execute: ON" or currentSort == "Auto Execute: OFF" then
				local aAuto = SavedData.AutoExecutes[a.ExactName] and 1 or 0
				local bAuto = SavedData.AutoExecutes[b.ExactName] and 1 or 0
				if aAuto ~= bAuto then return aAuto > bAuto end
			else
				if aUpdated ~= bUpdated then return aUpdated > bUpdated end
			end
			return a.OriginalIndex < b.OriginalIndex
		end)

		for idx, scr in ipairs(matches) do
			if scr.Instance.LayoutOrder ~= idx then
				scr.Instance.LayoutOrder = idx
			end
		end

		local shouldShowEmpty = #RegisteredScripts > 0 and #matches == 0
		if EmptyStateMessage.Visible ~= shouldShowEmpty then
			EmptyStateMessage.Visible = shouldShowEmpty
		end
		if shouldShowEmpty then
			EmptyStateMessage.Text = "No scripts matched your search or filters."
		end
		if ScriptsView and ScriptsView.Parent and query ~= "" then
			local canvasPosition = ScriptsView.CanvasPosition
			if canvasPosition.X ~= 0 or canvasPosition.Y ~= 0 then
				ScriptsView.CanvasPosition = Vector2.new(0, 0)
			end
		end
	end)
end

RegConn(SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	ClearSearchBtn.Visible = (SearchInput.Text ~= "")
	if typingTask then task.cancel(typingTask) end
	typingTask = task.delay(0.2, function() UpdateFilter() end)
end))

RegConn(ClearSearchBtn.Activated:Connect(function()
	SearchInput.Text = ""
	if SearchInput:IsFocused() then SearchInput:ReleaseFocus() end
end))

RegConn(FavFilterBtn.MouseButton1Click:Connect(CreateDebounce(0.1, function()
	if isDestroying then return end
	FilterFavoritesActive = not FilterFavoritesActive
	if FilterFavoritesActive then
		FavFilterBtn.Text = "★"; FavFilterBtn.TextColor3 = Color3.fromRGB(250, 204, 21); FavFilterStroke.Color = Color3.fromRGB(250, 204, 21)
		ShowNotification("Showing your favorite scripts only.", "Info")
	else
		FavFilterBtn.Text = "☆"; FavFilterBtn.TextColor3 = Color3.fromRGB(148, 163, 184); FavFilterStroke.Color = Color3.fromRGB(51, 65, 85)
		ShowNotification("Showing all scripts.", "Info")
	end
	UpdateFilter()
end)))

for _, opt in ipairs(SortOptions) do
	local btn = Instance.new("TextButton", DropdownContainer)
	btn.Size = UDim2.new(1, 0, 0, 28); btn.BackgroundTransparency = 1
	btn.Text = "  " .. opt; btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = (opt == SortMode) and Theme.Accent or Theme.TextPrimary
	btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11; btn.ZIndex = 1001

	RegConn(btn.Activated:Connect(function()
		SortMode = opt
		DropdownContainer.Visible = false
		for _, child in ipairs(DropdownContainer:GetChildren()) do
			if child:IsA("TextButton") then child.TextColor3 = Theme.TextPrimary end
		end
		btn.TextColor3 = Theme.Accent
		ShowNotification("Sorted by: " .. opt, "Info")
		UpdateFilter()
	end))
end

RegConn(SortDropdownBtn.Activated:Connect(function()
	if DropdownContainer.Visible then
		DropdownContainer.Visible = false
	else
		local absPos = SortDropdownBtn.AbsolutePosition
		local absSize = SortDropdownBtn.AbsoluteSize
		local camera = workspace.CurrentCamera
		local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local dropWidth, dropHeight = 190, 210
		local posX = math.clamp(absPos.X + absSize.X - dropWidth, 10, viewportSize.X - dropWidth - 10)
		local posY = absPos.Y + absSize.Y + 4
		if posY + dropHeight > viewportSize.Y - 10 then
			posY = absPos.Y - dropHeight - 4
		end
		if posY < 10 then posY = 10 end
		DropdownContainer.Position = UDim2.new(0, posX, 0, posY)
		DropdownContainer.Visible = true
	end
end))

RegConn(UserInputService.InputBegan:Connect(function(input)
	if DropdownContainer.Visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local pos = input.Position
		local dPos, dSize = DropdownContainer.AbsolutePosition, DropdownContainer.AbsoluteSize
		local sPos, sSize = SortDropdownBtn.AbsolutePosition, SortDropdownBtn.AbsoluteSize
		local insideDrop = pos.X >= dPos.X and pos.X <= dPos.X + dSize.X and pos.Y >= dPos.Y and pos.Y <= dPos.Y + dSize.Y
		local insideBtn = pos.X >= sPos.X and pos.X <= sPos.X + sSize.X and pos.Y >= sPos.Y and pos.Y <= sPos.Y + sSize.Y
		if not insideDrop and not insideBtn then DropdownContainer.Visible = false end
	end
end))

local TabIndicator = Instance.new("Frame", TabContainer)
TabIndicator.Size = UDim2.new(0, IsMobile and 80 or 100, 0, 2)
TabIndicator.Position = UDim2.new(0, 4, 1, -2)
TabIndicator.BackgroundColor3 = Theme.Accent
TabIndicator.BorderSizePixel = 0

local TabButtonCache = {}
local function CreateTab(name, index)
	local xOffset = (index - 1) * (IsMobile and 90 or 115)
	local btn = Instance.new("TextButton", TabContainer)
	btn.Size = UDim2.new(0, IsMobile and 85 or 105, 1, 0)
	btn.Position = UDim2.new(0, xOffset, 0, 0); btn.BackgroundTransparency = 1
	btn.Text = name; btn.Font = Enum.Font.GothamMedium; btn.TextSize = IsMobile and 11 or 13
	btn.TextColor3 = (name == currentTab) and Theme.TextPrimary or Theme.TextSecondary
	btn.ClipsDescendants = true; TabButtonCache[name] = btn
	if index > 1 then
		local div = Instance.new("Frame", TabContainer)
		div.Size = UDim2.new(0, 1, 0, 10); div.Position = UDim2.new(0, xOffset - 3, 0.5, -5)
		div.BackgroundColor3 = Theme.Stroke; div.BackgroundTransparency = 0.3
	end
	ApplyInteractiveAnimations(btn, nil, nil, nil, nil, nil, nil)
	RegConn(btn.Activated:Connect(function()
		if isDestroying or currentTab == name then return end
		currentTab = name; DropdownContainer.Visible = false
		TabIndicator.Size = UDim2.new(0, IsMobile and 80 or 100, 0, 2)
		TabIndicator.BackgroundTransparency = 0
		SafeTween(TabIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, xOffset + 4, 1, -2)})
		SectionHeaderLabel.Text = (name == "Changelogs") and "Updates" or (name == "Scripts") and "Scripts Catalog" or "Settings Hub"
		SearchRow.Visible = (name == "Scripts")
		if name == "Scripts" then
			UpdateFilter()
		elseif SearchInput and SearchInput.Parent then
			pcall(function() SearchInput:ReleaseFocus() end)
		end
		for tName, view in pairs(TabViews) do
			view.Visible = (tName == name)
			if view.Visible then view.CanvasPosition = Vector2.new(0, 0) end
		end
		for tName, tBtn in pairs(TabButtonCache) do
			tBtn.TextColor3 = (tName == currentTab) and Theme.TextPrimary or Theme.TextSecondary
		end
	end))
end
CreateTab("Changelogs", 1); CreateTab("Scripts", 2); CreateTab("Settings", 3)

local function CreateParagraph(title, desc, parentView)
	local block = Instance.new("Frame", parentView)
	block.Size = UDim2.new(1, 0, 0, 0); block.AutomaticSize = Enum.AutomaticSize.Y
	block.BackgroundColor3 = Theme.CardHover
	Instance.new("UICorner", block).CornerRadius = UDim.new(0, 8)
	local blockStroke = Instance.new("UIStroke", block); blockStroke.Color = Color3.fromRGB(33, 43, 61)
	local pad = Instance.new("UIPadding", block)
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	local lay = Instance.new("UIListLayout", block)
	lay.Padding = UDim.new(0, 4); lay.SortOrder = Enum.SortOrder.LayoutOrder
	local tLbl = Instance.new("TextLabel", block)
	tLbl.Size = UDim2.new(1, 0, 0, 18); tLbl.BackgroundTransparency = 1; tLbl.Text = title
	tLbl.TextColor3 = Theme.TextPrimary; tLbl.Font = Enum.Font.GothamBold; tLbl.TextSize = 13
	tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.LayoutOrder = 1
	local dLbl = Instance.new("TextLabel", block)
	dLbl.Size = UDim2.new(1, 0, 0, 0); dLbl.AutomaticSize = Enum.AutomaticSize.Y
	dLbl.BackgroundTransparency = 1; dLbl.Text = desc; dLbl.TextColor3 = Theme.TextSecondary
	dLbl.Font = Enum.Font.Gotham; dLbl.TextSize = 12; dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.TextWrapped = true; dLbl.LayoutOrder = 2
end

CreateParagraph("Found a Bug?", "If you run into any bugs, issues, or anything that doesn't seem right, please report it on our Discord. It really helps me figure out what's going wrong and fix it faster. Even small details can be useful, so don't hesitate to report anything you notice!", ChangelogsView)
CreateParagraph("v2.0.0 - Stability, Compatibility & UX Update BETA", "• Fixed Auto-Execute queue processing to execute scripts seamlessly on startup.\n• Added rich execution notifications and reliable fallback GUIs for improved UX clarity.\n• Implemented context-aware execution handling so error logs clearly identify failed scripts.\n• Hardened the namecall metatable hook with additional checks to improve client stability.\n• Improved executor compatibility with additional API detection and graceful fallbacks.\n• Enhanced HTTP request handling with supported request-method fallbacks.\n• Improved dynamic catalog loading, refreshing, searching, filtering, and metadata handling.\n• Added protection against outdated catalog data replacing newer results.\n• Improved script-card creation, favorites, and Auto-Execute state synchronization.\n• Improved script execution reliability with validation, protected execution, cooldowns, and duplicate-execution protection.\n• Refined UI animations, interactions, navigation, notifications, and viewport handling.\n• Improved mobile and environment-specific UI behavior.\n• Improved configuration saving, loading, validation, serialization, and state restoration.\n• Enhanced Anti-AFK handling with additional API checks and lifecycle safeguards.\n• Improved asynchronous task tracking, connection management, and resource cleanup.\n• Improved unload and shutdown behavior to reduce leftover background operations.\n• Fixed various UI state, catalog refresh, network request, configuration, and lifecycle edge cases.\n• Improved overall performance, stability, compatibility, reliability, and user experience across VeloxHub.", ChangelogsView)

local function RefreshAllCardStates()
	for _, scrData in ipairs(RegisteredScripts) do
		if type(scrData.UpdateUI) == "function" then scrData.UpdateUI() end
		if scrData.TimeLabel and scrData.TimeLabel.Parent then
			scrData.TimeLabel.Text = GetRelativeTime(scrData.LastUpdatedNumber)
		end
	end
end

local function ExecuteSandboxed(code, scriptName)
	local chunk, compileErr = loadstring(code, "=" .. tostring(scriptName))
	if not chunk then
		ShowNotification("Compile Error in [" .. tostring(scriptName) .. "]: Check F9 Console.", "Error")
		warn("[Velox Compile Error]: " .. tostring(compileErr))
		return false, tostring(compileErr)
	end

	TrackTask(function()
		local success, runtimeErr = pcall(chunk)
		if not success and not isDestroying then
			ShowNotification("Execution Error in [" .. tostring(scriptName) .. "]: Check F9 Console.", "Error")
			warn("[Velox Runtime Error]: " .. tostring(runtimeErr))
		end
	end)

	return true, "Script dispatched successfully"
end

local function CreateScriptCard(data, renderParent, registerImmediately, originalIndex)
	local tagType = NormalizeTagType(data and data.TagType)
	local tagConfig = TagTypeConfig[tagType]
	local exactName = type(data.Name) == "string" and data.Name or "Unnamed Script"
	local safeImageAssetId = type(data.ImageAssetId) == "string" and data.ImageAssetId or "rbxassetid://99657752206675"
	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0, 0); card.AutomaticSize = Enum.AutomaticSize.Y
	-- Keep the catalog card background fixed. Tag colors are used by the badge/stroke, not the card fill.
	card.BackgroundColor3 = Theme.Card; card.Text = ""
	card.AutoButtonColor = false; card.Selectable = false; card.ClipsDescendants = true
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local cardStroke = Instance.new("UIStroke", card); cardStroke.Color = tagConfig.StrokeColor; cardStroke.Thickness = 1.5; cardStroke.Transparency = 0
	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	local img = Instance.new("ImageLabel", card)
	img.Size = UDim2.new(0, 68, 0, 68); img.BackgroundColor3 = Theme.BackgroundMain
	img.BorderSizePixel = 0; img.Image = safeImageAssetId
	img.ScaleType = Enum.ScaleType.Crop
	Instance.new("UICorner", img).CornerRadius = UDim.new(0, 8)
	local content = Instance.new("Frame", card)
	content.Size = UDim2.new(1, -76, 0, 0); content.Position = UDim2.new(0, 76, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y; content.BackgroundTransparency = 1
	local cLay = Instance.new("UIListLayout", content)
	cLay.SortOrder = Enum.SortOrder.LayoutOrder; cLay.Padding = UDim.new(0, 4)
	local topRow = Instance.new("Frame", content)
	topRow.Size = UDim2.new(1, 0, 0, 0); topRow.AutomaticSize = Enum.AutomaticSize.Y
	topRow.BackgroundTransparency = 1; topRow.LayoutOrder = 1
	local trLay = Instance.new("UIListLayout", topRow)
	trLay.FillDirection = Enum.FillDirection.Horizontal; trLay.SortOrder = Enum.SortOrder.LayoutOrder; trLay.VerticalAlignment = Enum.VerticalAlignment.Top
	local metaWidth = IsMobile and 196 or 226
	local titleContainer = Instance.new("Frame", topRow)
	titleContainer.Size = UDim2.new(1, -metaWidth, 0, 0); titleContainer.AutomaticSize = Enum.AutomaticSize.Y
	titleContainer.BackgroundTransparency = 1; titleContainer.LayoutOrder = 1
	local titleLbl = Instance.new("TextLabel", titleContainer)
	titleLbl.Size = UDim2.new(1, 0, 0, 0); titleLbl.AutomaticSize = Enum.AutomaticSize.Y
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = data.Name or "Unnamed Script"
	titleLbl.TextColor3 = Theme.TextPrimary; titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = IsMobile and 12 or 13; titleLbl.TextWrapped = true; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	local metaRightContainer = Instance.new("Frame", topRow)
	metaRightContainer.Size = UDim2.new(0, metaWidth, 0, 18); metaRightContainer.BackgroundTransparency = 1; metaRightContainer.LayoutOrder = 2
	local mrLay = Instance.new("UIListLayout", metaRightContainer)
	mrLay.FillDirection = Enum.FillDirection.Horizontal; mrLay.HorizontalAlignment = Enum.HorizontalAlignment.Right; mrLay.VerticalAlignment = Enum.VerticalAlignment.Center; mrLay.SortOrder = Enum.SortOrder.LayoutOrder; mrLay.Padding = UDim.new(0, 2)

	if tagType ~= "NONE" then
		local tag = Instance.new("Frame", metaRightContainer)
		tag.AutomaticSize = Enum.AutomaticSize.X; tag.Size = UDim2.new(0, 0, 0, 14)
		Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 4)
		local tPad = Instance.new("UIPadding", tag)
		tPad.PaddingLeft = UDim.new(0, 5); tPad.PaddingRight = UDim.new(0, 5)
		local tText = Instance.new("TextLabel", tag)
		tText.AutomaticSize = Enum.AutomaticSize.X; tText.Size = UDim2.new(0, 0, 1, 0)
		tText.BackgroundTransparency = 1; tText.Text = tagType
		tText.TextColor3 = Color3.fromRGB(255, 255, 255); tText.Font = Enum.Font.GothamBold; tText.TextSize = 9
		tag.BackgroundColor3 = tagConfig.BadgeColor
		tag.LayoutOrder = 1
	end

	local dateLbl = Instance.new("TextLabel", metaRightContainer)
	dateLbl.Size = UDim2.new(0, IsMobile and 130 or 150, 1, 0)
	dateLbl.BackgroundTransparency = 1; dateLbl.Text = GetRelativeTime(data.LastUpdated)
	dateLbl.TextColor3 = Theme.TextSecondary; dateLbl.Font = Enum.Font.GothamMedium
	dateLbl.TextSize = 9; dateLbl.LayoutOrder = 2; dateLbl.TextXAlignment = Enum.TextXAlignment.Right
	dateLbl.TextWrapped = false; dateLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local function UpdateCardMetaLayout()
		local available = topRow.AbsoluteSize.X
		if available <= 0 then return end
		local target = metaWidth
		if available < 440 then target = math.min(target, math.max(165, math.floor(available * 0.52))) end
		if tagType == "NONE" then target = math.max(145, target - 34) end
		titleContainer.Size = UDim2.new(1, -target, 0, 0)
		metaRightContainer.Size = UDim2.new(0, target, 0, 18)
	end
	RegCardConn(topRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCardMetaLayout))
	UpdateCardMetaLayout()
	local descLbl = Instance.new("TextLabel", content)
	descLbl.Size = UDim2.new(1, 0, 0, 0); descLbl.AutomaticSize = Enum.AutomaticSize.Y
	descLbl.BackgroundTransparency = 1; descLbl.Text = type(data.Description) == "string" and data.Description or "No description provided."
	descLbl.TextColor3 = Theme.TextSecondary; descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 11
	descLbl.TextWrapped = true; descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.LayoutOrder = 2
	local btmRow = Instance.new("Frame", content)
	btmRow.Size = UDim2.new(1, 0, 0, 22); btmRow.BackgroundTransparency = 1; btmRow.LayoutOrder = 3
	local brLay = Instance.new("UIListLayout", btmRow)
	brLay.FillDirection = Enum.FillDirection.Horizontal; brLay.SortOrder = Enum.SortOrder.LayoutOrder; brLay.Padding = UDim.new(0, 8); brLay.VerticalAlignment = Enum.VerticalAlignment.Center
	local autoExecBtn = Instance.new("TextButton", btmRow)
	autoExecBtn.Size = UDim2.new(0, 120, 0, 22); autoExecBtn.BackgroundColor3 = Theme.BackgroundMain
	autoExecBtn.Text = ""; autoExecBtn.AutoButtonColor = false; autoExecBtn.Selectable = false; autoExecBtn.ClipsDescendants = true; autoExecBtn.LayoutOrder = 1; autoExecBtn.ZIndex = 2
	Instance.new("UICorner", autoExecBtn).CornerRadius = UDim.new(0, 6)
	local aeLbl = Instance.new("TextLabel", autoExecBtn)
	aeLbl.Size = UDim2.new(1, -34, 1, 0); aeLbl.Position = UDim2.new(0, 6, 0, 0); aeLbl.BackgroundTransparency = 1
	aeLbl.Text = "Auto Execute"; aeLbl.TextColor3 = Theme.TextPrimary
	aeLbl.Font = Enum.Font.GothamBold; aeLbl.TextSize = 10; aeLbl.TextXAlignment = Enum.TextXAlignment.Left; aeLbl.ZIndex = 2
	local aeState = Instance.new("Frame", autoExecBtn)
	aeState.Size = UDim2.new(0, 24, 0, 14); aeState.Position = UDim2.new(1, -28, 0.5, -7); aeState.ZIndex = 2
	Instance.new("UICorner", aeState).CornerRadius = UDim.new(0, 4)
	local aeStateTxt = Instance.new("TextLabel", aeState)
	aeStateTxt.Size = UDim2.new(1, 0, 1, 0); aeStateTxt.BackgroundTransparency = 1
	aeStateTxt.TextColor3 = Color3.fromRGB(255, 255, 255); aeStateTxt.Font = Enum.Font.GothamBold; aeStateTxt.TextSize = 8; aeStateTxt.ZIndex = 2
	local starBtn = Instance.new("TextButton", btmRow)
	starBtn.Size = UDim2.new(0, 22, 0, 22); starBtn.BackgroundTransparency = 1
	starBtn.Font = Enum.Font.GothamBold; starBtn.TextSize = 15; starBtn.LayoutOrder = 2; starBtn.ZIndex = 2
	starBtn.Selectable = false

	-- Cards must never recolor themselves on touch/click. Keep the fill locked to Theme.Card
	-- and use the existing UIStroke for any interaction feedback.
	ApplyInteractiveAnimations(card, Theme.Card, nil, nil, cardStroke, tagConfig.StrokeColor, tagConfig.StrokeColor, CardConnections)
	ApplyInteractiveAnimations(autoExecBtn, Theme.BackgroundMain, Theme.BackgroundSecondary, Color3.fromRGB(10, 15, 30), nil, nil, nil, CardConnections)
	ApplyInteractiveAnimations(starBtn, nil, nil, nil, nil, nil, nil, CardConnections)

	local description = type(data.Description) == "string" and data.Description or ""
	local tagSearch = tagType
	local scriptEntry = {
		Instance = card, SearchTitle = string.lower(exactName), SearchDesc = string.lower(description),
		SearchMeta = string.lower(table.concat({type(data.Category) == "string" and data.Category or "", type(data.Author) == "string" and data.Author or "", tagSearch}, " ")),
		ExactName = exactName, LastUpdated = data.LastUpdated, LastUpdatedNumber = GetSafeTimestamp(data.LastUpdated), TagType = tagType, TagPriority = tagConfig.Priority, OriginalIndex = originalIndex or (#RegisteredScripts + 1), EntryFingerprint = table.concat({ tostring(data.Name or ""), tostring(data.Description or ""), tostring(data.RawUrl or ""), tostring(data.ImageAssetId or ""), tostring(NormalizeTagType(data.TagType)), tostring(GetSafeTimestamp(data.LastUpdated)), tostring(tonumber(data.PlaceId) or 0), tostring(data.Category or ""), tostring(data.Author or "") }, "\31"), TimeLabel = dateLbl
	}

	local innerActionTime = 0

	scriptEntry.UpdateUI = function()
		local isFav = SavedData.Favorites[exactName]
		starBtn.Text = isFav and "★" or "☆"; starBtn.TextColor3 = isFav and Color3.fromRGB(250, 204, 21) or Theme.TextSecondary
		local isON = (SavedData.AutoExecutes[exactName] ~= nil)
		aeStateTxt.Text = isON and "ON" or "OFF"; aeState.BackgroundColor3 = isON and Theme.Success or Theme.Error
	end
	scriptEntry.UpdateUI()

	RegCardConn(starBtn.Activated:Connect(CreateDebounce(0.1, function()
		if isDestroying then return end
		innerActionTime = tick()
		if SavedData.Favorites[exactName] then
			SavedData.Favorites[exactName] = nil; ShowNotification("Removed '" .. exactName .. "' from favorites.", "Warning")
		else
			SavedData.Favorites[exactName] = true; ShowNotification("Added '" .. exactName .. "' to favorites!", "Success")
		end
		SaveConfiguration(); RefreshAllCardStates(); UpdateFilter()
	end)))

	RegCardConn(autoExecBtn.Activated:Connect(CreateDebounce(0.1, function()
		if isDestroying then return end
		innerActionTime = tick()
		if SavedData.AutoExecutes[exactName] then
			SavedData.AutoExecutes[exactName] = nil; ShowNotification("Disabled auto-execute for '" .. exactName .. "'.", "Warning")
		else
			SavedData.AutoExecutes[exactName] = {PlaceId = game.PlaceId, GameId = game.GameId}; ShowNotification("Enabled auto-execute for '" .. exactName .. "'.", "Success")
		end
		SaveConfiguration(); RefreshAllCardStates(); UpdateFilter()
	end)))

	RegCardConn(card.Activated:Connect(function()
		if isDestroying then return end
		if tick() - innerActionTime < 0.2 then return end

		local function executeScript()
			if type(loadstring) ~= "function" then
				ShowNotification("Execution disabled: 'loadstring' is missing or blocked by your executor.", "Error")
				return
			end
			titleLbl.Text = "Running script..."; titleLbl.TextColor3 = Theme.Accent
			task.spawn(function()
				local raw = FetchWithRetry(type(data.RawUrl) == "string" and data.RawUrl or "", 2)
				if isDestroying then return end
				if not raw then
					ShowNotification("Failed to download script. Please check your connection.", "Error")
				elseif string.find(raw, "404: Not Found") then
					ShowNotification("The script link is broken or no longer available (404 Error).", "Error")
				else
					local success = ExecuteSandboxed(raw, exactName)
					if success then
						ShowNotification("Successfully executed [" .. exactName .. "]!", "Execution")
					end
				end

				if titleLbl and titleLbl.Parent then
					titleLbl.Text = exactName; titleLbl.TextColor3 = Theme.TextPrimary
				end
			end)
		end

		if SavedData.AutoExecutes[exactName] ~= nil then
			AttemptActionWithCooldown(executeScript)
		else
			OpenConfirmDialog(exactName, executeScript)
		end
	end))

	card.Parent = renderParent
	CacheInstanceAndDescendants(card)
	if registerImmediately ~= false then table.insert(RegisteredScripts, scriptEntry) end
	return scriptEntry
end

local CATALOG_URL = "https://raw.githubusercontent.com/KingBacconnnn/VeloxScripts/refs/heads/main/catalog.json"
local CATALOG_REFRESH_INTERVAL = 300
local dbRefreshing = false
local CatalogRefreshQueued = false
local LastCatalogFingerprint = nil

local function BuildCatalogFingerprint(entries)
	local parts = {}
	for index, entry in ipairs(entries) do
		if type(entry) == "table" then
			parts[#parts + 1] = table.concat({
				tostring(entry.Name or ""), tostring(entry.Description or ""), tostring(entry.RawUrl or ""),
				tostring(entry.ImageAssetId or ""), tostring(NormalizeTagType(entry.TagType)),
				tostring(GetSafeTimestamp(entry.LastUpdated)), tostring(tonumber(entry.PlaceId) or 0),
				tostring(entry.Category or ""), tostring(entry.Author or ""), tostring(index)
			}, "\31")
		end
	end
	return table.concat(parts, "\30")
end

PendingTasks.__LoadCatalog = function(force)
	if isDestroying then return false end
	if dbRefreshing then
		CatalogRefreshQueued = true
		PendingTasks.__CatalogRefreshForce = PendingTasks.__CatalogRefreshForce or force == true
		return false
	end
	local now = os.clock()
	if not force and now - LastCatalogRefreshAt < CatalogRefreshCooldown then
		CatalogRefreshQueued = true
		return false
	end

	LastCatalogRefreshAt = now
	dbRefreshing = true
	CatalogGeneration += 1
	local generation = CatalogGeneration
	local savedScroll = ScriptsView.CanvasPosition
	ShowNotification("Fetching latest script catalog...", "System")
	StatusDot.BackgroundColor3 = Theme.Warning
	StatusText.Text = "Connecting..."
	StatusText.TextColor3 = Theme.Warning

	local function FinishRefresh()
		if generation ~= CatalogGeneration then return end
		dbRefreshing = false
		if CatalogRefreshQueued and not isDestroying then
			local queuedForce = PendingTasks.__CatalogRefreshForce == true
			CatalogRefreshQueued = false
			PendingTasks.__CatalogRefreshForce = false
			task.defer(function()
				if not isDestroying then PendingTasks.__LoadCatalog(queuedForce) end
			end)
		end
	end

	local function DisconnectEntryConnections()
		for i = #CardConnections, 1, -1 do
			local conn = CardConnections[i]
			if typeof(conn) == "RBXScriptConnection" and not conn.Connected then table.remove(CardConnections, i) end
		end
	end
	local activeBuildFolder = nil
	local activeNewEntries = {}

	TrackTask(function()
		local taskOk, taskErr = xpcall(function()
			local raw = FetchWithRetry(CATALOG_URL, 3, true)
			if not IsTaskCurrent(generation) then return end
			if not raw then
				if #RegisteredScripts == 0 then EmptyStateMessage.Visible = true; EmptyStateMessage.Text = "Unable to reach script catalog server." end
				StatusDot.BackgroundColor3 = Theme.Error
				StatusText.Text = "Offline"
				StatusText.TextColor3 = Theme.Error
				ShowNotification("Could not connect to the script catalog server.", "Error")
				FinishRefresh()
				return
			end

			local success, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
			if not success or type(parsed) ~= "table" then
				if #RegisteredScripts == 0 then EmptyStateMessage.Visible = true; EmptyStateMessage.Text = "Failed to parse catalog data format." end
				StatusDot.BackgroundColor3 = Theme.Error
				StatusText.Text = "Data Error"
				StatusText.TextColor3 = Theme.Error
				ShowNotification("Catalog data format error.", "Error")
				FinishRefresh()
				return
			end

			local validEntries = {}
			local seenNames = {}
			for _, entry in ipairs(parsed) do
				if type(entry) == "table" and type(entry.Name) == "string" and string.gsub(entry.Name, "^%s*(.-)%s*$", "%1") ~= "" then
					local normalized = {
						Name = entry.Name,
						Description = type(entry.Description) == "string" and entry.Description or "No description provided.",
						RawUrl = type(entry.RawUrl) == "string" and entry.RawUrl or "",
						ImageAssetId = type(entry.ImageAssetId) == "string" and entry.ImageAssetId or "rbxassetid://99657752206675",
						TagType = NormalizeTagType(entry.TagType),
						LastUpdated = GetSafeTimestamp(entry.LastUpdated),
						PlaceId = tonumber(entry.PlaceId) or 0,
						Category = type(entry.Category) == "string" and entry.Category or "",
						Author = type(entry.Author) == "string" and entry.Author or ""
					}
					if not seenNames[normalized.Name] then
						seenNames[normalized.Name] = true
						validEntries[#validEntries + 1] = normalized
					end
				end
			end

			local fingerprint = BuildCatalogFingerprint(validEntries)
			if fingerprint == LastCatalogFingerprint then
				RefreshAllCardStates()
				StatusDot.BackgroundColor3 = Theme.Success
				StatusText.Text = "Online"
				StatusText.TextColor3 = Theme.Success
				ShowNotification("Catalog is already up to date.", "Info")
				FinishRefresh()
				return
			end

			local previousByKey = RegisteredScripts.__ByKey or {}
			local nextByKey = {}
			local nextEntries = {}
			local nextKeys = {}
			local replacedEntries = {}
			table.clear(activeNewEntries)
			activeBuildFolder = Instance.new("Folder")
			activeBuildFolder.Name = "__VeloxCatalogBuild"
			activeBuildFolder.Parent = ScriptsView

			local function BuildEntryFingerprint(data)
				return table.concat({ tostring(data.Name or ""), tostring(data.Description or ""), tostring(data.RawUrl or ""), tostring(data.ImageAssetId or ""), tostring(NormalizeTagType(data.TagType)), tostring(GetSafeTimestamp(data.LastUpdated)), tostring(tonumber(data.PlaceId) or 0), tostring(data.Category or ""), tostring(data.Author or "") }, "\31")
			end

			local function DestroyEntry(entry)
				if not entry or not entry.Instance then return end
				if entry.Instance.Parent then pcall(function() entry.Instance:Destroy() end) end
			end

			local function CleanupNewEntries()
				for _, entry in ipairs(activeNewEntries) do DestroyEntry(entry) end
				if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
				activeBuildFolder = nil
				table.clear(activeNewEntries)
				DisconnectEntryConnections()
			end

			for index, scriptData in ipairs(validEntries) do
				if not IsTaskCurrent(generation) then CleanupNewEntries(); FinishRefresh(); return end
				local key = tostring(scriptData.Name or "")
				local entryFingerprint = BuildEntryFingerprint(scriptData)
				local existing = previousByKey[key]
				local entry
				if existing and existing.EntryFingerprint == entryFingerprint and existing.Instance and existing.Instance.Parent then
					entry = existing
					entry.OriginalIndex = index
				else
					if existing then replacedEntries[#replacedEntries + 1] = existing end
					entry = CreateScriptCard(scriptData, activeBuildFolder, false, index)
					entry.EntryFingerprint = entryFingerprint
					entry.OriginalIndex = index
					activeNewEntries[#activeNewEntries + 1] = entry
				end
				nextEntries[#nextEntries + 1] = entry
				nextByKey[key] = entry
				nextKeys[key] = true
			end

			if not IsTaskCurrent(generation) then CleanupNewEntries(); FinishRefresh(); return end
			for key, oldEntry in pairs(previousByKey) do
				if not nextKeys[key] then DestroyEntry(oldEntry) end
			end
			for _, entry in ipairs(replacedEntries) do DestroyEntry(entry) end
			for _, entry in ipairs(nextEntries) do
				if entry.Instance and entry.Instance.Parent ~= ScriptsView then entry.Instance.Parent = ScriptsView end
				entry.Instance.LayoutOrder = entry.OriginalIndex
			end
			if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
			activeBuildFolder = nil
			table.clear(activeNewEntries)
			DisconnectEntryConnections()

			table.clear(RegisteredScripts)
			for _, entry in ipairs(nextEntries) do RegisteredScripts[#RegisteredScripts + 1] = entry end
			RegisteredScripts.__ByKey = nextByKey
			LastCatalogFingerprint = fingerprint
			RefreshAllCardStates()
			UpdateFilter()
			task.defer(function()
				if IsTaskCurrent(generation) and ScriptsView and ScriptsView.Parent then ScriptsView.CanvasPosition = savedScroll end
			end)

			local validMap = {}
			for _, scriptData in ipairs(validEntries) do validMap[scriptData.Name] = true end
			local cleaned = false
			for key in pairs(SavedData.AutoExecutes) do
				if not validMap[key] then SavedData.AutoExecutes[key] = nil; cleaned = true end
			end
			if cleaned then SaveConfiguration() end

			if not AutoExecuteRanThisSession then
				AutoExecuteRanThisSession = true
				local autoQueue = {}
				for _, scriptData in ipairs(validEntries) do
					local auto = SavedData.AutoExecutes[scriptData.Name]
					if type(auto) == "table" then
						local validPlace = auto.GameId and auto.GameId ~= 0 and auto.GameId == game.GameId
						if not validPlace then validPlace = auto.PlaceId == PlaceId or auto.PlaceId == 0 or not auto.PlaceId end
						if validPlace then autoQueue[#autoQueue + 1] = scriptData end
					end
				end
				if #autoQueue > 0 then
					TrackTask(function()
						if type(loadstring) ~= "function" then ShowNotification("Auto-execute skipped: Executor lacks loadstring support.", "Error"); return end
						local successList, failList = {}, {}
						ShowNotification("Processing " .. #autoQueue .. " auto-execute script(s)...", "Info")
						for _, scriptData in ipairs(autoQueue) do
							if not IsTaskCurrent(generation) then return end
							local scrRaw = FetchWithRetry(scriptData.RawUrl, 2)
							if not IsTaskCurrent(generation) then return end
							if scrRaw and not string.find(scrRaw, "404: Not Found") then
								if ExecuteSandboxed(scrRaw, scriptData.Name) then successList[#successList + 1] = scriptData.Name else failList[#failList + 1] = scriptData.Name end
							else
								failList[#failList + 1] = scriptData.Name
							end
							task.wait(0.3)
						end
						if #successList > 0 then ShowNotification("Auto-executed: " .. table.concat(successList, ", "), "Success") end
						if #failList > 0 then ShowNotification("Auto-execution failed for: " .. table.concat(failList, ", "), "Warning") end
					end)
				end
			end

			StatusDot.BackgroundColor3 = Theme.Success
			StatusText.Text = "Online"
			StatusText.TextColor3 = Theme.Success
			ShowNotification("Script catalog loaded successfully!", "Success")
		end, function(err) return tostring(err) end)

		if not taskOk then
			if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
			activeBuildFolder = nil
			table.clear(activeNewEntries)
			DisconnectEntryConnections()
		end
		if not taskOk and not isDestroying and generation == CatalogGeneration then
			StatusDot.BackgroundColor3 = Theme.Error
			StatusText.Text = "Catalog Error"
			StatusText.TextColor3 = Theme.Error
			ShowNotification("Catalog refresh failed safely.", "Error")
			warn("[Velox Catalog Error]: " .. tostring(taskErr))
		end
		FinishRefresh()
	end)
	return true
end

PendingTasks.__LoadCatalog()

TrackTask(function()
	while not isDestroying do
		task.wait(CATALOG_REFRESH_INTERVAL)
		if isDestroying then break end
		PendingTasks.__LoadCatalog(false)
	end
end)

TrackTask(function()
	while not isDestroying do
		task.wait(60)
		if isDestroying then break end
		for _, scrData in ipairs(RegisteredScripts) do
			if scrData.TimeLabel and scrData.TimeLabel.Parent then
				scrData.TimeLabel.Text = GetRelativeTime(scrData.LastUpdatedNumber)
			end
		end
	end
end)

local function CreateSettingsGroup(titleText, parentView, order)
	local container = Instance.new("Frame", parentView)
	container.Size = UDim2.new(1, 0, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	local groupLayout = Instance.new("UIListLayout", container)
	groupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	groupLayout.Padding = UDim.new(0, 6)
	local header = Instance.new("TextLabel", container)
	header.Size = UDim2.new(1, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.Text = string.upper(titleText)
	header.TextColor3 = Theme.TextSecondary
	header.Font = Enum.Font.GothamBold
	header.TextSize = 10
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = 1
	local card = Instance.new("Frame", container)
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.CardHover
	card.LayoutOrder = 2
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local cardGradient = Instance.new("UIGradient", card)
	cardGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.CardHover),
		ColorSequenceKeypoint.new(1, Theme.Card)
	})
	cardGradient.Rotation = 45
	local cardLayout = Instance.new("UIListLayout", card)
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 0)
	return card
end

local function CreateSettingRowInGroup(groupCard, title, desc, iconAsset, order)
	if order > 1 then
		local divider = Instance.new("Frame", groupCard)
		divider.Size = UDim2.new(1, -24, 0, 1)
		divider.Position = UDim2.new(0, 12, 0, 0)
		divider.BackgroundColor3 = Theme.Stroke
		divider.BackgroundTransparency = 0.6
		divider.BorderSizePixel = 0
		divider.LayoutOrder = (order - 1) * 2
	end
	local row = Instance.new("Frame", groupCard)
	row.Size = UDim2.new(1, 0, 0, IsMobile and 56 or 60)
	row.BackgroundTransparency = 1
	row.LayoutOrder = (order * 2) - 1
	local rowPad = Instance.new("UIPadding", row)
	rowPad.PaddingLeft = UDim.new(0, 12)
	rowPad.PaddingRight = UDim.new(0, 12)
	rowPad.PaddingTop = UDim.new(0, 8)
	rowPad.PaddingBottom = UDim.new(0, 8)
	local iconContainer = Instance.new("Frame", row)
	iconContainer.Size = UDim2.new(0, 32, 0, 32)
	iconContainer.Position = UDim2.new(0, 0, 0.5, -16)
	iconContainer.BackgroundColor3 = Theme.Accent
	iconContainer.BackgroundTransparency = 0.85
	Instance.new("UICorner", iconContainer).CornerRadius = UDim.new(0, 8)
	local iconImg = Instance.new("ImageLabel", iconContainer)
	iconImg.Size = UDim2.new(0, 18, 0, 18)
	iconImg.Position = UDim2.new(0.5, -9, 0.5, -9)
	iconImg.BackgroundTransparency = 1
	iconImg.Image = iconAsset or "rbxassetid://10709782497"
	iconImg.ImageColor3 = Theme.Accent
	local textContainer = Instance.new("Frame", row)
	textContainer.Size = UDim2.new(1, -165, 1, 0)
	textContainer.Position = UDim2.new(0, 42, 0, 0)
	textContainer.BackgroundTransparency = 1
	local tLay = Instance.new("UIListLayout", textContainer)
	tLay.SortOrder = Enum.SortOrder.LayoutOrder
	tLay.Padding = UDim.new(0, 2)
	tLay.VerticalAlignment = Enum.VerticalAlignment.Center
	local t = Instance.new("TextLabel", textContainer)
	t.Size = UDim2.new(1, 0, 0, 16)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = Theme.TextPrimary
	t.Font = Enum.Font.GothamBold
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.LayoutOrder = 1
	local d = Instance.new("TextLabel", textContainer)
	d.Size = UDim2.new(1, 0, 0, 14)
	d.BackgroundTransparency = 1
	d.Text = desc
	d.TextColor3 = Theme.TextSecondary
	d.Font = Enum.Font.Gotham
	d.TextSize = 10
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.LayoutOrder = 2
	d.TextWrapped = true
	local rightContainer = Instance.new("Frame", row)
	rightContainer.Size = UDim2.new(0, 110, 1, 0)
	rightContainer.Position = UDim2.new(1, -110, 0, 0)
	rightContainer.BackgroundTransparency = 1
	return row, rightContainer
end

local function CreateToggleSettingInGroup(groupCard, title, desc, iconAsset, order, defaultValue, callback)
	local row, rightContainer = CreateSettingRowInGroup(groupCard, title, desc, iconAsset, order)
	local toggleBtn = Instance.new("TextButton", rightContainer)
	toggleBtn.Size = UDim2.new(0, 44, 0, 22)
	toggleBtn.Position = UDim2.new(1, -44, 0.5, -11)
	toggleBtn.BackgroundColor3 = defaultValue and Theme.Accent or Theme.BackgroundMain
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = false
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
	local toggleStroke = Instance.new("UIStroke", toggleBtn)
	toggleStroke.Color = defaultValue and Theme.Accent or Theme.Stroke
	toggleStroke.Thickness = 1
	local circle = Instance.new("Frame", toggleBtn)
	circle.Size = UDim2.new(0, 16, 0, 16)
	circle.Position = defaultValue and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
	local state = defaultValue
	RegConn(toggleBtn.Activated:Connect(CreateDebounce(0.1, function()
		if isDestroying then return end
		state = not state
		SafeTween(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = state and Theme.Accent or Theme.BackgroundMain
		})
		SafeTween(toggleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = state and Theme.Accent or Theme.Stroke
		})
		SafeTween(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		})
		if type(callback) == "function" then task.spawn(callback, state) end
	end)))
end

local function CreateButtonSettingInGroup(groupCard, title, desc, iconAsset, btnText, order, isDestructive, callback)
	local row, rightContainer = CreateSettingRowInGroup(groupCard, title, desc, iconAsset, order)
	local btn = Instance.new("TextButton", rightContainer)
	btn.Size = UDim2.new(0, 95, 0, 26)
	btn.Position = UDim2.new(1, -95, 0.5, -13)
	btn.BackgroundColor3 = Theme.BackgroundMain
	btn.BackgroundTransparency = 0.4
	btn.Text = btnText
	btn.TextColor3 = isDestructive and Theme.Error or Theme.TextPrimary
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 11
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = isDestructive and Theme.Error or Theme.Stroke
	btnStroke.Thickness = 1
	local hoverColor = isDestructive and Color3.fromRGB(55, 25, 25) or Theme.CardHover
	local hoverStroke = isDestructive and Theme.Error or Theme.Accent
	ApplyInteractiveAnimations(btn, Theme.BackgroundMain, hoverColor, Color3.fromRGB(10, 15, 30), btnStroke, btnStroke.Color, hoverStroke)
	RegConn(btn.Activated:Connect(CreateDebounce(0.1, function()
		if isDestroying then return end
		if type(callback) == "function" then task.spawn(callback, btn) end
	end)))
	return btn
end

local prefGroup = CreateSettingsGroup("User Preferences", SettingsView, 1)

local kbRow, kbRightContainer = CreateSettingRowInGroup(prefGroup, "Toggle UI", "Keybind to show or hide hub.", "rbxassetid://10709790537", 1)
local KeybindButton = Instance.new("TextButton", kbRightContainer)
KeybindButton.Size = UDim2.new(0, 95, 0, 26)
KeybindButton.Position = UDim2.new(1, -95, 0.5, -13)
KeybindButton.BackgroundColor3 = Theme.BackgroundMain
KeybindButton.BackgroundTransparency = 0.4
KeybindButton.Text = ToggleKeybind.Name
KeybindButton.TextColor3 = Theme.TextPrimary
KeybindButton.Font = Enum.Font.GothamMedium
KeybindButton.TextSize = 11
KeybindButton.AutoButtonColor = false
Instance.new("UICorner", KeybindButton).CornerRadius = UDim.new(0, 6)
local kbBtnStroke = Instance.new("UIStroke", KeybindButton)
kbBtnStroke.Color = Theme.Stroke
KeybindButtonRef = KeybindButton
ApplyInteractiveAnimations(KeybindButton, Theme.BackgroundMain, Theme.CardHover, Color3.fromRGB(10, 15, 30), kbBtnStroke, Theme.Stroke, Theme.Accent)

RegConn(KeybindButton.Activated:Connect(CreateDebounce(0.1, function()
	if isDestroying or IsBindingKey then return end
	IsBindingKey = true
	KeybindButton.Text = "Press Any..."
	ShowNotification("Press any key to bind (Press Escape to cancel).", "System")

	if KeybindCaptureConnection then
		UnregConn(KeybindCaptureConnection)
		KeybindCaptureConnection = nil
	end

	KeybindCaptureConnection = RegConn(UserInputService.InputBegan:Connect(function(input)
		if isDestroying then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				IsBindingKey = false
				if KeybindButtonRef then KeybindButtonRef.Text = ToggleKeybind.Name end
				ShowNotification("Keybind mapping canceled.", "Warning")
				if KeybindCaptureConnection then
					UnregConn(KeybindCaptureConnection)
					KeybindCaptureConnection = nil
				end
				return
			end
			if input.KeyCode.Name ~= "Unknown" then
				ToggleKeybind = input.KeyCode
				IsBindingKey = false
				SavedData.ToggleKeybind = ToggleKeybind.Name
				SaveConfiguration()
				if KeybindButtonRef then KeybindButtonRef.Text = ToggleKeybind.Name end
				ShowNotification("Keybind successfully updated to: " .. input.KeyCode.Name, "Success")

				BindToggleKey(ToggleKeybind)

				if KeybindCaptureConnection then
					UnregConn(KeybindCaptureConnection)
					KeybindCaptureConnection = nil
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			IsBindingKey = false
			if KeybindButtonRef then KeybindButtonRef.Text = ToggleKeybind.Name end
			ShowNotification("Keybind mapping canceled.", "Warning")
			if KeybindCaptureConnection then
				UnregConn(KeybindCaptureConnection)
				KeybindCaptureConnection = nil
			end
		end
	end))
end)))

local function TriggerAntiAFKAction()
	if VirtualUser then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	elseif VirtualInputManager then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
			task.wait(0.1)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
		end)
	end
end

CreateToggleSettingInGroup(prefGroup, "Anti-AFK", "Prevents idle kicks.", "rbxassetid://10734898592", 2, SavedData.Settings.AntiAFK, function(val)
	SavedData.Settings.AntiAFK = val
	SaveConfiguration()
	if val then
		ShowNotification("Anti-AFK system engaged.", "Success")
		if not AfkConnections.Idled then
			AfkConnections.Idled = RegConn(LocalPlayer.Idled:Connect(TriggerAntiAFKAction))
		end
		if getconnections then
			pcall(function()
				for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
					pcall(function()
						if type(conn) == "table" and conn.Disable then
							conn:Disable()
							table.insert(AfkConnections, conn)
						elseif typeof(conn) == "RBXScriptConnection" and conn.Disable then
							conn:Disable()
							table.insert(AfkConnections, conn)
						end
					end)
				end
			end)
		end
	else
		ShowNotification("Anti-AFK deactivated.", "Warning")
		if AfkConnections.Idled then AfkConnections.Idled:Disconnect(); AfkConnections.Idled = nil end
		for _, conn in ipairs(AfkConnections) do
			pcall(function()
				if type(conn) == "table" and conn.Enable then
					conn:Enable()
				elseif typeof(conn) == "RBXScriptConnection" and conn.Enable then
					conn:Enable()
				end
			end)
		end
		table.clear(AfkConnections)
	end
end)

local actionGroup = CreateSettingsGroup("System Actions", SettingsView, 2)

CreateButtonSettingInGroup(actionGroup, "Refresh Catalog", "Fetches latest scripts.", "rbxassetid://10734976528", "Refresh", 1, false, function()
	AttemptActionWithCooldown(function()
		if dbRefreshing then
			CatalogRefreshQueued = true
			ShowNotification("Catalog refresh queued.", "Info")
			return
		end
		LoadDynamicCatalog(true)
	end)
end)

CreateButtonSettingInGroup(actionGroup, "Unload Hub", "Removes Velox Hub completely.", "rbxassetid://10709753149", "Unload", 2, true, function()
	ShowNotification("Unloading Velox Hub...", "Info")
	task.wait(0.3)
	CloseUI()
end)

if SavedData.Settings.AntiAFK then
	if not AfkConnections.Idled then
		AfkConnections.Idled = RegConn(LocalPlayer.Idled:Connect(TriggerAntiAFKAction))
	end
	if getconnections then
		pcall(function()
			for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
				pcall(function()
					if type(conn) == "table" and conn.Disable then
						conn:Disable()
						table.insert(AfkConnections, conn)
					elseif typeof(conn) == "RBXScriptConnection" and conn.Disable then
						conn:Disable()
						table.insert(AfkConnections, conn)
					end
				end)
			end
		end)
	end
end

local function ObfuscateHierarchy(instance)
	instance.Name = GenerateRandomString(15)
	for _, child in ipairs(instance:GetDescendants()) do
		if child:IsA("GuiObject") or child:IsA("UIComponent") or child:IsA("Folder") then
			child.Name = GenerateRandomString(15)
		end
	end
end
ObfuscateHierarchy(ScreenGui)

pcall(function()
	if type(hookmetamethod) == "function" and type(checkcaller) == "function" then
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local ok, isCaller = pcall(checkcaller)
			if ok and not isCaller and ScreenGui and typeof(self) == "Instance" then
				local mOk, method = pcall(getnamecallmethod)
				if mOk and method then
					if self == TargetParent then
						if method == "GetDescendants" or method == "GetChildren" then
							local result = oldNamecall(self, ...)
							if type(result) == "table" then
								local filtered = {}
								for i = 1, #result do
									local v = result[i]
									if v ~= ScreenGui and not v:IsDescendantOf(ScreenGui) then
										table.insert(filtered, v)
									end
								end
								return filtered
							end
							return result
						elseif method == "FindFirstChild" then
							local args = {...}
							if type(args[1]) == "string" and (args[1] == MainGuiName or args[1] == ScreenGui.Name or args[1] == FloatBtnName) then
								return nil
							end
						elseif method == "WaitForChild" then
							local args = {...}
							if type(args[1]) == "string" and (args[1] == MainGuiName or args[1] == ScreenGui.Name or args[1] == FloatBtnName) then
								return nil
							end
						end
					end
				end
			end
			return oldNamecall(self, ...)
		end)

		local oldIndex
		oldIndex = hookmetamethod(game, "__index", function(self, key)
			local ok, isCaller = pcall(checkcaller)
			if ok and not isCaller and ScreenGui and typeof(self) == "Instance" then
				if self == TargetParent and type(key) == "string" then
					if key == MainGuiName or key == ScreenGui.Name or key == FloatBtnName then
						return nil
					end
				end
			end
			return oldIndex(self, key)
		end)
	end
end)

TabViews["Changelogs"].Visible = true
TabViews["Scripts"].Visible = false
TabViews["Settings"].Visible = false
TabIndicator.Position = UDim2.new(0, 4, 1, -2)
SectionHeaderLabel.Text = "Updates"
MainPanel.Visible = true
SearchRow.Visible = false
FloatingBtn.Visible = false

ShowNotification("Velox Hub is ready for use!", "Success")

if IsMobile then
	local UserDataGroup = CreateSettingsGroup("User Data", SettingsView, 3)
	CreateButtonSettingInGroup(UserDataGroup, "Clear UI Cache", "Resets layout position.", "rbxassetid://10734940376", "Reset", 1, true, function()
		if isDestroying then return end
		table.clear(OriginalCache)
		MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
		FloatingBtn.Position = UDim2.new(0.5, 0, 0, 42.5)
		CacheInstanceAndDescendants(MainPanel)
		CacheInstanceAndDescendants(FloatingBtn)
		ShowNotification("UI Cache cleared successfully.", "Success")
	end)
end
