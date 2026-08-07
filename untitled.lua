local function GenerateRandomString(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local str = ""
	math.randomseed(os.clock() * 10000)
	for i = 1, len do
		local r = math.random(1, #chars)
		str = str .. string.sub(chars, r, r)
	end
	return str
end

local _G_Identifier = GenerateRandomString(16)
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
local RunService = Services.RunService
local Stats = Services.Stats
local CoreGui = Services.CoreGui
local TweenService = Services.TweenService

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end
local PlaceId = game.PlaceId

local gethui = gethui or function() 
	local success, target = pcall(function() return CoreGui end)
	if success and target then return target end
	return LocalPlayer:WaitForChild("PlayerGui") 
end
local protectgui = protectgui or (syn and syn.protect_gui) or function(...) return ... end
local exec_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request) or (krnl and krnl.request)
local getexecutor = identifyexecutor or getexecutorname or function() return "Unknown Executor" end
local write_file = writefile or function() end
local read_file = readfile or function() return "" end
local is_file = isfile or function() return false end

local Theme = {
	Accent = Color3.fromRGB(99, 102, 241),
	BackgroundMain = Color3.fromRGB(15, 23, 42),
	BackgroundSecondary = Color3.fromRGB(20, 29, 55),
	Card = Color3.fromRGB(24, 33, 50),
	CardHover = Color3.fromRGB(30, 41, 59),
	TextPrimary = Color3.fromRGB(248, 250, 252),
	TextSecondary = Color3.fromRGB(148, 163, 184),
	Success = Color3.fromRGB(16, 185, 129),
	Error = Color3.fromRGB(239, 68, 68),
	Warning = Color3.fromRGB(245, 158, 11),
	Info = Color3.fromRGB(56, 189, 248),
	Stroke = Color3.fromRGB(51, 65, 85),
	ToggleOff = Color3.fromRGB(71, 85, 105)
}

-- Memory & Event Management
local VeloxConnections = {}
local RegisteredScripts = {}
local AfkConnections = {}
local ActiveNotifications = {}
local NotificationQueue = {}
local ActiveTweens = {}
local ActiveCooldowns = {}
local CooldownTracker = {}

local isDestroying = false
local isMinimized = false
local isTransitioning = false
local GlobalExecutionCooldown = false
local IsBindingKey = false
local MainGuiName = GenerateRandomString(20)

local OriginalCache = {}

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

local typingTask = nil

local function CleanUpMemory()
	isDestroying = true
	getgenv()[_G_Identifier] = nil

	if typingTask then task.cancel(typingTask); typingTask = nil end

	for _, conn in ipairs(VeloxConnections) do
		if typeof(conn) == "RBXScriptConnection" and conn.Connected then
			conn:Disconnect()
		end
	end
	for _, conn in pairs(AfkConnections) do
		if type(conn) == "table" and conn.Enable then pcall(function() conn:Enable() end)
		elseif typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
	end
	
	for _, notif in ipairs(ActiveNotifications) do
		pcall(function()
			if notif.Timer then task.cancel(notif.Timer) end
			if notif.Wrapper then notif.Wrapper:Destroy() end
		end)
	end

	for _, tween in pairs(ActiveTweens) do
		pcall(function() 
			tween:Cancel() 
			tween:Destroy() 
		end)
	end

	table.clear(VeloxConnections)
	table.clear(RegisteredScripts)
	table.clear(AfkConnections)
	table.clear(ActiveNotifications)
	table.clear(NotificationQueue)
	table.clear(ActiveTweens)
	table.clear(ActiveCooldowns)
	table.clear(CooldownTracker)
	table.clear(OriginalCache)
end

local function SafeTween(instance, tweenInfo, properties)
	if not instance or not instance.Parent then return nil end
	
	if ActiveTweens[instance] then
		pcall(function() 
			ActiveTweens[instance]:Cancel() 
			ActiveTweens[instance]:Destroy() 
		end)
	end
	
	local tween = TweenService:Create(instance, tweenInfo, properties)
	ActiveTweens[instance] = tween
	
	local conn
	conn = tween.Completed:Connect(function()
		if conn then conn:Disconnect() end
		if ActiveTweens[instance] == tween then
			ActiveTweens[instance] = nil
		end
		pcall(function() tween:Destroy() end)
	end)
	
	tween:Play()
	return tween
end

local function CreateDebounce(delay, func)
	local isDebounced = false
	return function(...)
		if isDebounced then return end
		isDebounced = true
		task.spawn(func, ...)
		task.delay(delay, function() isDebounced = false end)
	end
end

local DATA_FILE = ".VeloxHub_Data_V3.1.json"
local SavedData = {
	Favorites = {},
	AutoExecutes = {},
	LastSearch = "",
	ToggleKeybind = "RightControl",
	Settings = { AntiAFK = false }
}

local function SaveConfiguration()
	if type(write_file) == "function" then
		task.spawn(function()
			local cleanData = {
				Favorites = {},
				AutoExecutes = {},
				LastSearch = tostring(SavedData.LastSearch or ""),
				ToggleKeybind = tostring(SavedData.ToggleKeybind or "RightControl"),
				Settings = { AntiAFK = SavedData.Settings.AntiAFK == true }
			}
			for k, v in pairs(SavedData.Favorites) do
				if v then cleanData.Favorites[tostring(k)] = true end
			end
			for k, v in pairs(SavedData.AutoExecutes) do
				if type(v) == "table" and v.PlaceId then
					cleanData.AutoExecutes[tostring(k)] = { PlaceId = tonumber(v.PlaceId) or game.PlaceId }
				end
			end
			local success, result = pcall(function() return HttpService:JSONEncode(cleanData) end)
			if success then pcall(function() write_file(DATA_FILE, result) end) end
		end)
	end
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
					if type(k) == "string" and type(v) == "table" and type(v.PlaceId) == "number" then
						SavedData.AutoExecutes[tostring(k)] = {PlaceId = v.PlaceId}
					end
				end
			end
			if type(result.LastSearch) == "string" then SavedData.LastSearch = result.LastSearch end
			if type(result.ToggleKeybind) == "string" then SavedData.ToggleKeybind = result.ToggleKeybind end
			if type(result.Settings) == "table" then
				for k, _ in pairs(SavedData.Settings) do
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
	local success, result = pcall(function() return game:HttpGet(url) end)
	if success and result then return result end
	if type(exec_request) == "function" then
		local reqSuccess, reqResult = pcall(function() return exec_request({Url = url, Method = "GET"}).Body end)
		if reqSuccess and reqResult then return reqResult end
	end
	return nil
end

local function FetchWithRetry(url, retries, delayTime)
	retries = retries or 3
	delayTime = delayTime or 2
	for i = 1, retries do
		local response = UniversalHttpGet(url)
		if response then return response end
		if i < retries then task.wait(delayTime) end
	end
	return nil
end

local function GetRelativeTime(timestamp)
	if type(timestamp) ~= "number" then return "Unknown" end
	local diff = os.time() - timestamp
	if diff < 0 then return "Unknown" end
	local days = math.floor(diff / 86400)
	if days == 0 then return "Today" end
	if days == 1 then return "Yesterday" end
	if days < 7 then return days .. " days ago" end
	local weeks = math.floor(days / 7)
	if weeks < 4 then return weeks .. (weeks == 1 and " week ago" or " weeks ago") end
	local months = math.floor(days / 30.44)
	if months < 12 then return months .. (months == 1 and " month ago" or " months ago") end
	local years = math.floor(days / 365.25)
	return years .. (years == 1 and " year ago" or " years ago")
end

local TargetParent = gethui()
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

local mt = getrawmetatable(game)
if mt and setreadonly and checkcaller and getnamecallmethod then
	local oldNamecall = mt.__namecall
	setreadonly(mt, false)
	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if not checkcaller() and (method == "FindFirstChild" or method == "WaitForChild") then
			local args = {...}
			if args[1] == MainGuiName then return nil end
		end
		return oldNamecall(self, ...)
	end)
	setreadonly(mt, true)
end

getgenv()[_G_Identifier] = function()
	CleanUpMemory()
	if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end

local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local PANEL_SIZE = IsMobile and UDim2.new(0, 480, 0, 360) or UDim2.new(0, 560, 0, 515)

local function ApplyInteractiveAnimations(gui, originalColor, hoverColor, clickColor, strokeObj, originalStroke, hoverStroke)
	if not gui:IsA("GuiObject") then return end

	RegConn(gui.MouseEnter:Connect(function()
		if isDestroying or isTransitioning then return end
		if originalColor and hoverColor then gui.BackgroundColor3 = hoverColor end
		if strokeObj and hoverStroke then strokeObj.Color = hoverStroke end
	end))

	RegConn(gui.MouseLeave:Connect(function()
		if isDestroying or isTransitioning then return end
		if originalColor then gui.BackgroundColor3 = originalColor end
		if strokeObj and originalStroke then strokeObj.Color = originalStroke end
	end))

	RegConn(gui.InputBegan:Connect(function(input)
		if isDestroying or isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if clickColor then gui.BackgroundColor3 = clickColor end
		end
	end))

	RegConn(gui.InputEnded:Connect(function(input)
		if isDestroying or isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if hoverColor then 
				gui.BackgroundColor3 = hoverColor
			elseif originalColor then 
				gui.BackgroundColor3 = originalColor
			end
		end
	end))
end

local FloatingBtn = Instance.new("ImageButton", ScreenGui)
FloatingBtn.Name = "VeloxFloatingIcon"
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

local floatDrag, floatStart, floatPos, floatInputConn
RegConn(FloatingBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if floatInputConn then floatInputConn:Disconnect() end
		
		floatDrag = true
		floatStart = input.Position
		floatPos = FloatingBtn.Position
		
		floatInputConn = RegConn(input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then 
				floatDrag = false 
				if OriginalCache[FloatingBtn] then
					OriginalCache[FloatingBtn].Position = FloatingBtn.Position
				end
				if floatInputConn then floatInputConn:Disconnect() end
			end
		end))
	end
end))

RegConn(UserInputService.InputChanged:Connect(function(input)
	if floatDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - floatStart
		FloatingBtn.Position = UDim2.new(floatPos.X.Scale, floatPos.X.Offset + delta.X, floatPos.Y.Scale, floatPos.Y.Offset + delta.Y)
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
	if isDestroying or IsBindingKey or isTransitioning then return end
	isTransitioning = true

	if not isMinimized then
		isMinimized = true
		pcall(function() MainPanel.Interactable = false end)
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
		pcall(function() MainPanel.Interactable = true end)
	end

	task.wait(0.1) 
	isTransitioning = false
end

RegConn(FloatingBtn.MouseButton1Click:Connect(function() if not floatDrag then ToggleUI() end end))

local ToastContainer = Instance.new("Frame", ScreenGui)
ToastContainer.Size = UDim2.new(0, IsMobile and 240 or 320, 1, -40)
ToastContainer.Position = UDim2.new(1, IsMobile and -250 or -330, 0, 20)
ToastContainer.BackgroundTransparency = 1
ToastContainer.ZIndex = 300

local ToastLayout = Instance.new("UIListLayout", ToastContainer)
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.Padding = UDim.new(0, 8)

local MAX_VISIBLE_NOTIFS = 10
local NOTIF_DURATION = 3.5
local ANIM_DURATION = 0.2

local EntryTweenInfo = TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ExitTweenInfo = TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local LinearTweenInfo = TweenInfo.new(NOTIF_DURATION, Enum.EasingStyle.Linear)

local function ProcessNotificationQueue()
	if isDestroying then return end
	while #ActiveNotifications < MAX_VISIBLE_NOTIFS and #NotificationQueue > 0 do
		local nextNotif = table.remove(NotificationQueue, 1)
		DisplayNotification(nextNotif.Msg, nextNotif.Type)
	end
end

function DisplayNotification(msg, nType)
	if isDestroying then return end
	local indicatorColor = Theme[nType] or Theme.Info
	
	local notifState = { IsRemoving = false }
	
	local wrapper = Instance.new("Frame", ToastContainer)
	wrapper.Size = UDim2.new(1, 0, 0, 0)
	wrapper.AutomaticSize = Enum.AutomaticSize.Y
	wrapper.BackgroundTransparency = 1
	wrapper.ZIndex = 301
	notifState.Wrapper = wrapper

	local box = Instance.new("Frame", wrapper)
	box.Size = UDim2.new(1, 0, 0, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.BackgroundColor3 = Theme.CardHover
	box.Position = UDim2.new(1.5, 0, 0, 0)
	box.ClipsDescendants = true
	box.ZIndex = 302
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
	indicator.ZIndex = 303
	Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 6)

	local txt = Instance.new("TextLabel", box)
	txt.Size = UDim2.new(1, 0, 0, 0); txt.AutomaticSize = Enum.AutomaticSize.Y
	txt.BackgroundTransparency = 1; txt.Text = tostring(msg)
	txt.TextColor3 = Theme.TextPrimary; txt.Font = Enum.Font.GothamMedium
	txt.TextSize = IsMobile and 11 or 13; txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextWrapped = true; txt.ZIndex = 303

	local progressBar = Instance.new("Frame", box)
	progressBar.AnchorPoint = Vector2.new(0, 1)
	progressBar.Position = UDim2.new(0, -12, 1, 12)
	progressBar.Size = UDim2.new(1, 24, 0, 2)
	progressBar.BackgroundColor3 = indicatorColor
	progressBar.BorderSizePixel = 0; progressBar.ZIndex = 304

	CacheInstanceAndDescendants(wrapper)

	local function RemoveNotification()
		if notifState.IsRemoving then return end
		notifState.IsRemoving = true

		if notifState.Timer then
			if coroutine.running() ~= notifState.Timer then
				task.cancel(notifState.Timer)
			end
			notifState.Timer = nil
		end

		local idx = table.find(ActiveNotifications, notifState)
		if idx then table.remove(ActiveNotifications, idx) end

		ProcessNotificationQueue()

		if box and box.Parent then
			local exitTween = SafeTween(box, ExitTweenInfo, {Position = UDim2.new(1.5, 0, 0, 0)})
			if exitTween then
				local exitConn
				exitConn = exitTween.Completed:Connect(function()
					if exitConn then exitConn:Disconnect() end
					if wrapper and wrapper.Parent then wrapper:Destroy() end
				end)
			else
				if wrapper and wrapper.Parent then wrapper:Destroy() end
			end
		else
			if wrapper and wrapper.Parent then wrapper:Destroy() end
		end
	end

	notifState.Remove = RemoveNotification
	table.insert(ActiveNotifications, notifState)

	SafeTween(box, EntryTweenInfo, {Position = UDim2.new(0, 0, 0, 0)})
	SafeTween(progressBar, LinearTweenInfo, {Size = UDim2.new(0, 0, 0, 2)})

	notifState.Timer = task.delay(NOTIF_DURATION, function()
		if not isDestroying and not notifState.IsRemoving then
			RemoveNotification()
		end
	end)
end

getfenv().ShowNotification = function(msg, notifType)
	if isDestroying then return end
	notifType = notifType or "Info"
	
	if #ActiveNotifications >= MAX_VISIBLE_NOTIFS then
		table.insert(NotificationQueue, {Msg = msg, Type = notifType})
	else
		DisplayNotification(msg, notifType)
	end
end
local ShowNotification = getfenv().ShowNotification

-- [ Action Cooldown Tracker & Synchronized Notification System ]
getfenv().ShowCooldownNotification = function(actionId, duration)
	if isDestroying then return end
	if ActiveCooldowns[actionId] then return end 

	local indicatorColor = Theme.Warning
	local notifState = { IsRemoving = false, ActionId = actionId }
	ActiveCooldowns[actionId] = notifState

	local wrapper = Instance.new("Frame", ToastContainer)
	wrapper.Size = UDim2.new(1, 0, 0, 0)
	wrapper.AutomaticSize = Enum.AutomaticSize.Y
	wrapper.BackgroundTransparency = 1
	wrapper.ZIndex = 301
	notifState.Wrapper = wrapper

	local box = Instance.new("Frame", wrapper)
	box.Size = UDim2.new(1, 0, 0, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.BackgroundColor3 = Theme.CardHover
	box.Position = UDim2.new(1.5, 0, 0, 0)
	box.ClipsDescendants = true
	box.ZIndex = 302
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
	indicator.ZIndex = 303
	Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 6)

	local txt = Instance.new("TextLabel", box)
	txt.Size = UDim2.new(1, 0, 0, 0); txt.AutomaticSize = Enum.AutomaticSize.Y
	txt.BackgroundTransparency = 1
	txt.Text = string.format("Please try again in %d second%s.", math.ceil(duration), math.ceil(duration) == 1 and "" or "s")
	txt.TextColor3 = Theme.TextPrimary; txt.Font = Enum.Font.GothamMedium
	txt.TextSize = IsMobile and 11 or 13; txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextWrapped = true; txt.ZIndex = 303

	local progressBar = Instance.new("Frame", box)
	progressBar.AnchorPoint = Vector2.new(0, 1)
	progressBar.Position = UDim2.new(0, -12, 1, 12)
	progressBar.Size = UDim2.new(1, 24, 0, 2)
	progressBar.BackgroundColor3 = indicatorColor
	progressBar.BorderSizePixel = 0; progressBar.ZIndex = 304

	CacheInstanceAndDescendants(wrapper)

	local function RemoveNotification()
		if notifState.IsRemoving then return end
		notifState.IsRemoving = true

		ActiveCooldowns[actionId] = nil

		if notifState.Timer and coroutine.running() ~= notifState.Timer then
			pcall(function() task.cancel(notifState.Timer) end)
		end
		notifState.Timer = nil

		local idx = table.find(ActiveNotifications, notifState)
		if idx then table.remove(ActiveNotifications, idx) end
		ProcessNotificationQueue()

		if box and box.Parent then
			local exitTween = SafeTween(box, ExitTweenInfo, {Position = UDim2.new(1.5, 0, 0, 0)})
			if exitTween then
				local exitConn
				exitConn = exitTween.Completed:Connect(function()
					if exitConn then exitConn:Disconnect() end
					if wrapper and wrapper.Parent then wrapper:Destroy() end
				end)
			else
				if wrapper and wrapper.Parent then wrapper:Destroy() end
			end
		else
			if wrapper and wrapper.Parent then wrapper:Destroy() end
		end
	end

	notifState.Remove = RemoveNotification
	table.insert(ActiveNotifications, notifState)

	if #ActiveNotifications > MAX_VISIBLE_NOTIFS then
		local oldest = ActiveNotifications[1]
		if oldest and type(oldest.Remove) == "function" then
			oldest.Remove()
		end
	end

	SafeTween(box, EntryTweenInfo, {Position = UDim2.new(0, 0, 0, 0)})
	SafeTween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})

	notifState.Timer = task.spawn(function()
		local endTime = os.clock() + duration
		while os.clock() < endTime and not isDestroying and not notifState.IsRemoving do
			local remaining = math.ceil(endTime - os.clock())
			if txt and txt.Parent then
				txt.Text = string.format("Please try again in %d second%s.", remaining, remaining == 1 and "" or "s")
			end
			task.wait(0.1)
		end
		if not notifState.IsRemoving then
			RemoveNotification()
		end
	end)
end
local ShowCooldownNotification = getfenv().ShowCooldownNotification

getfenv().SetActionCooldown = function(actionId, duration)
	CooldownTracker[actionId] = os.clock() + duration
end
local SetActionCooldown = getfenv().SetActionCooldown

getfenv().CheckActionCooldown = function(actionId)
	if CooldownTracker[actionId] then
		local remaining = CooldownTracker[actionId] - os.clock()
		if remaining > 0 then
			ShowCooldownNotification(actionId, remaining)
			return false
		end
	end
	return true
end
local CheckActionCooldown = getfenv().CheckActionCooldown

local Sidebar = Instance.new("Frame", PanelGroup)
Sidebar.Size = UDim2.new(0, IsMobile and 50 or 60, 1, 0)
Sidebar.BackgroundColor3 = Theme.BackgroundSecondary
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local SidebarDivider = Instance.new("Frame", Sidebar)
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
SidebarDivider.BackgroundColor3 = Theme.Stroke
SidebarDivider.BorderSizePixel = 0; SidebarDivider.ZIndex = 2

local NavLayout = Instance.new("UIListLayout", Sidebar)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
NavLayout.Padding = UDim.new(0, 12)

local PadNav = Instance.new("UIPadding", Sidebar)
PadNav.PaddingTop = UDim.new(0, 16); PadNav.PaddingBottom = UDim.new(0, 16)

local Header = Instance.new("Frame", PanelGroup)
Header.Size = UDim2.new(1, -(IsMobile and 50 or 60), 0, IsMobile and 50 or 60)
Header.Position = UDim2.new(0, IsMobile and 50 or 60, 0, 0)
Header.BackgroundTransparency = 1; Header.ZIndex = 2

local HeaderTitle = Instance.new("TextLabel", Header)
HeaderTitle.Size = UDim2.new(1, -60, 1, 0)
HeaderTitle.Position = UDim2.new(0, 16, 0, 0)
HeaderTitle.BackgroundTransparency = 1; HeaderTitle.Text = "Velox Hub"
HeaderTitle.TextColor3 = Theme.TextPrimary; HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = IsMobile and 18 or 20; HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.ZIndex = 2

local CloseBtn = Instance.new("ImageButton", Header)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -16, 0.5, 0)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Image = "rbxassetid://10747384394"
CloseBtn.ImageColor3 = Theme.TextSecondary; CloseBtn.ZIndex = 2
RegConn(CloseBtn.MouseButton1Click:Connect(function() getgenv()[_G_Identifier]() end))

local MinBtn = Instance.new("ImageButton", Header)
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.AnchorPoint = Vector2.new(1, 0.5)
MinBtn.Position = UDim2.new(1, -48, 0.5, 0)
MinBtn.BackgroundTransparency = 1; MinBtn.Image = "rbxassetid://10747383210"
MinBtn.ImageColor3 = Theme.TextSecondary; MinBtn.ZIndex = 2
RegConn(MinBtn.MouseButton1Click:Connect(function() ToggleUI() end))

local HeaderDivider = Instance.new("Frame", Header)
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
HeaderDivider.BackgroundColor3 = Theme.Stroke
HeaderDivider.BorderSizePixel = 0; HeaderDivider.ZIndex = 2

local ContentArea = Instance.new("Frame", PanelGroup)
ContentArea.Size = UDim2.new(1, -(IsMobile and 50 or 60), 1, -(IsMobile and 50 or 60))
ContentArea.Position = UDim2.new(0, IsMobile and 50 or 60, 0, IsMobile and 50 or 60)
ContentArea.BackgroundTransparency = 1; ContentArea.ZIndex = 2

local Views = {}
local NavButtons = {}
local CurrentView = nil

local function SwitchView(viewName)
	if isDestroying or CurrentView == viewName then return end
	CurrentView = viewName
	
	for name, view in pairs(Views) do
		if name == viewName then
			view.Visible = true
			view.Position = UDim2.new(0, 10, 0, 0)
			view.GroupTransparency = 1
			SafeTween(view, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0})
		else
			view.Visible = false
		end
	end
	
	for name, btnData in pairs(NavButtons) do
		if name == viewName then
			SafeTween(btnData.Highlight, TweenInfo.new(0.2), {BackgroundTransparency = 0})
			SafeTween(btnData.Icon, TweenInfo.new(0.2), {ImageColor3 = Theme.Accent})
		else
			SafeTween(btnData.Highlight, TweenInfo.new(0.2), {BackgroundTransparency = 1})
			SafeTween(btnData.Icon, TweenInfo.new(0.2), {ImageColor3 = Theme.TextSecondary})
		end
	end
end

local function CreateNavButton(name, iconId)
	local btn = Instance.new("TextButton", Sidebar)
	btn.Size = UDim2.new(0, IsMobile and 36 or 42, 0, IsMobile and 36 or 42)
	btn.BackgroundColor3 = Theme.CardHover; btn.BackgroundTransparency = 1
	btn.Text = ""; btn.ZIndex = 3
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

	local icon = Instance.new("ImageLabel", btn)
	icon.Size = UDim2.new(0, IsMobile and 20 or 24, 0, IsMobile and 20 or 24)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.BackgroundTransparency = 1; icon.Image = iconId
	icon.ImageColor3 = Theme.TextSecondary; icon.ZIndex = 3

	local highlight = Instance.new("Frame", btn)
	highlight.Size = UDim2.new(1, 0, 1, 0)
	highlight.BackgroundColor3 = Theme.CardHover
	highlight.BackgroundTransparency = 1; highlight.ZIndex = 2
	Instance.new("UICorner", highlight).CornerRadius = UDim.new(0, 10)

	NavButtons[name] = {Btn = btn, Icon = icon, Highlight = highlight}
	ApplyInteractiveAnimations(btn, nil, Theme.CardHover, Theme.Card, nil, nil, nil)
	RegConn(btn.MouseButton1Click:Connect(function() SwitchView(name) end))
end

local function CreateView(name)
	local cg = Instance.new("CanvasGroup", ContentArea)
	cg.Size = UDim2.new(1, 0, 1, 0)
	cg.BackgroundTransparency = 1
	cg.BorderSizePixel = 0
	cg.Visible = false
	cg.ZIndex = 2
	Views[name] = cg
	return cg
end

CreateNavButton("Home", "rbxassetid://10747382271")
CreateNavButton("Scripts", "rbxassetid://10747383120")
CreateNavButton("Settings", "rbxassetid://10747383618")

local HomeView = CreateView("Home")
local ScriptsView = CreateView("Scripts")
local SettingsView = CreateView("Settings")

-- ================== HOME VIEW ==================

local HomeScroll = Instance.new("ScrollingFrame", HomeView)
HomeScroll.Size = UDim2.new(1, 0, 1, 0)
HomeScroll.BackgroundTransparency = 1
HomeScroll.ScrollBarThickness = IsMobile and 2 or 4
HomeScroll.ScrollBarImageColor3 = Theme.Stroke
HomeScroll.ZIndex = 2

local HomeLayout = Instance.new("UIListLayout", HomeScroll)
HomeLayout.SortOrder = Enum.SortOrder.LayoutOrder
HomeLayout.Padding = UDim.new(0, 16)
local HomePadding = Instance.new("UIPadding", HomeScroll)
HomePadding.PaddingTop = UDim.new(0, 16); HomePadding.PaddingBottom = UDim.new(0, 16)
HomePadding.PaddingLeft = UDim.new(0, 16); HomePadding.PaddingRight = UDim.new(0, 16)
RegConn(HomeLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	if not isDestroying then HomeScroll.CanvasSize = UDim2.new(0, 0, 0, HomeLayout.AbsoluteContentSize.Y + 32) end
end))

local function CreateStatCard(parent, title, val, iconId, order)
	local card = Instance.new("Frame", parent)
	card.Size = UDim2.new(1, 0, 0, IsMobile and 60 or 70)
	card.BackgroundColor3 = Theme.Card
	card.LayoutOrder = order
	card.ZIndex = 3
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", card).Color = Theme.Stroke

	local iconBox = Instance.new("Frame", card)
	iconBox.Size = UDim2.new(0, IsMobile and 36 or 42, 0, IsMobile and 36 or 42)
	iconBox.Position = UDim2.new(0, 12, 0.5, -(IsMobile and 18 or 21))
	iconBox.BackgroundColor3 = Theme.BackgroundSecondary
	iconBox.ZIndex = 4
	Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 8)

	local icon = Instance.new("ImageLabel", iconBox)
	icon.Size = UDim2.new(0, IsMobile and 20 or 24, 0, IsMobile and 20 or 24)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.BackgroundTransparency = 1; icon.Image = iconId
	icon.ImageColor3 = Theme.Accent; icon.ZIndex = 4

	local titleLbl = Instance.new("TextLabel", card)
	titleLbl.Size = UDim2.new(1, -70, 0, 20)
	titleLbl.Position = UDim2.new(0, IsMobile and 56 or 64, 0, IsMobile and 10 or 14)
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = title
	titleLbl.TextColor3 = Theme.TextSecondary; titleLbl.Font = Enum.Font.GothamMedium
	titleLbl.TextSize = IsMobile and 12 or 13; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 4

	local valLbl = Instance.new("TextLabel", card)
	valLbl.Size = UDim2.new(1, -70, 0, 24)
	valLbl.Position = UDim2.new(0, IsMobile and 56 or 64, 0, IsMobile and 30 or 34)
	valLbl.BackgroundTransparency = 1; valLbl.Text = val
	valLbl.TextColor3 = Theme.TextPrimary; valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = IsMobile and 16 or 18; valLbl.TextXAlignment = Enum.TextXAlignment.Left
	valLbl.ZIndex = 4

	return valLbl
end

local StatsGrid = Instance.new("Frame", HomeScroll)
StatsGrid.Size = UDim2.new(1, 0, 0, 0)
StatsGrid.AutomaticSize = Enum.AutomaticSize.Y
StatsGrid.BackgroundTransparency = 1; StatsGrid.LayoutOrder = 1; StatsGrid.ZIndex = 2
local Grid = Instance.new("UIGridLayout", StatsGrid)
Grid.CellSize = UDim2.new(0.5, -6, 0, IsMobile and 60 or 70)
Grid.CellPadding = UDim2.new(0, 12, 0, 12)
Grid.SortOrder = Enum.SortOrder.LayoutOrder

CreateStatCard(StatsGrid, "User", LocalPlayer.Name, "rbxassetid://10747383842", 1)
CreateStatCard(StatsGrid, "Executor", getexecutor(), "rbxassetid://10747384074", 2)
local PingStat = CreateStatCard(StatsGrid, "Ping", "0ms", "rbxassetid://10747384394", 3)
local FPSStat = CreateStatCard(StatsGrid, "FPS", "0", "rbxassetid://10747383618", 4)

local lastTime = os.clock()
local frames = 0
RegConn(RunService.RenderStepped:Connect(function()
	if isDestroying then return end
	frames = frames + 1
	local currentTime = os.clock()
	if currentTime - lastTime >= 1 then
		if FPSStat and FPSStat.Parent then FPSStat.Text = tostring(math.floor(frames / (currentTime - lastTime))) end
		frames = 0
		lastTime = currentTime
	end
	if PingStat and PingStat.Parent then
		pcall(function() PingStat.Text = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) .. "ms" end)
	end
end))

local InfoCard = Instance.new("Frame", HomeScroll)
InfoCard.Size = UDim2.new(1, 0, 0, 120)
InfoCard.BackgroundColor3 = Theme.Card; InfoCard.LayoutOrder = 2; InfoCard.ZIndex = 3
Instance.new("UICorner", InfoCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", InfoCard).Color = Theme.Stroke

local InfoTitle = Instance.new("TextLabel", InfoCard)
InfoTitle.Size = UDim2.new(1, -32, 0, 30)
InfoTitle.Position = UDim2.new(0, 16, 0, 16)
InfoTitle.BackgroundTransparency = 1; InfoTitle.Text = "System Information"
InfoTitle.TextColor3 = Theme.TextPrimary; InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextSize = IsMobile and 14 or 16; InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.ZIndex = 4

local GameLabel = Instance.new("TextLabel", InfoCard)
GameLabel.Size = UDim2.new(1, -32, 0, 20)
GameLabel.Position = UDim2.new(0, 16, 0, 50)
GameLabel.BackgroundTransparency = 1
local success, gameName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(PlaceId).Name end)
GameLabel.Text = "Game: " .. (success and gameName or "Unknown Game") .. " (" .. tostring(PlaceId) .. ")"
GameLabel.TextColor3 = Theme.TextSecondary; GameLabel.Font = Enum.Font.GothamMedium
GameLabel.TextSize = IsMobile and 12 or 13; GameLabel.TextXAlignment = Enum.TextXAlignment.Left
GameLabel.ZIndex = 4

local ExecLabel = Instance.new("TextLabel", InfoCard)
ExecLabel.Size = UDim2.new(1, -32, 0, 20)
ExecLabel.Position = UDim2.new(0, 16, 0, 74)
ExecLabel.BackgroundTransparency = 1
ExecLabel.Text = "Identity: Level " .. tostring(select(2, pcall(getthreadidentity)) or "Unknown")
ExecLabel.TextColor3 = Theme.TextSecondary; ExecLabel.Font = Enum.Font.GothamMedium
ExecLabel.TextSize = IsMobile and 12 or 13; ExecLabel.TextXAlignment = Enum.TextXAlignment.Left
ExecLabel.ZIndex = 4

-- ================== SCRIPTS VIEW ==================

local TopBar = Instance.new("Frame", ScriptsView)
TopBar.Size = UDim2.new(1, 0, 0, IsMobile and 40 or 50)
TopBar.BackgroundTransparency = 1; TopBar.ZIndex = 2

local SearchBox = Instance.new("Frame", TopBar)
SearchBox.Size = UDim2.new(1, -70, 0, IsMobile and 30 or 36)
SearchBox.Position = UDim2.new(0, 16, 0, IsMobile and 5 or 7)
SearchBox.BackgroundColor3 = Theme.Card; SearchBox.ZIndex = 3
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 8)
local SearchStroke = Instance.new("UIStroke", SearchBox)
SearchStroke.Color = Theme.Stroke

local SearchIcon = Instance.new("ImageLabel", SearchBox)
SearchIcon.Size = UDim2.new(0, 16, 0, 16)
SearchIcon.Position = UDim2.new(0, 12, 0.5, -8)
SearchIcon.BackgroundTransparency = 1; SearchIcon.Image = "rbxassetid://10747384210"
SearchIcon.ImageColor3 = Theme.TextSecondary; SearchIcon.ZIndex = 4

SearchInput = Instance.new("TextBox", SearchBox)
SearchInput.Size = UDim2.new(1, -40, 1, 0)
SearchInput.Position = UDim2.new(0, 36, 0, 0)
SearchInput.BackgroundTransparency = 1; SearchInput.PlaceholderText = "Search scripts..."
SearchInput.Text = SavedData.LastSearch or ""
SearchInput.TextColor3 = Theme.TextPrimary; SearchInput.PlaceholderColor3 = Theme.TextSecondary
SearchInput.Font = Enum.Font.GothamMedium; SearchInput.TextSize = IsMobile and 12 or 13
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false; SearchInput.ZIndex = 4

RegConn(SearchInput.Focused:Connect(function() 
	if not isDestroying then SafeTween(SearchStroke, TweenInfo.new(0.2), {Color = Theme.Accent}) end 
end))
RegConn(SearchInput.FocusLost:Connect(function() 
	if not isDestroying then 
		SafeTween(SearchStroke, TweenInfo.new(0.2), {Color = Theme.Stroke})
		SavedData.LastSearch = SearchInput.Text
		SaveConfiguration()
	end 
end))

local FavFilterBtn = Instance.new("TextButton", TopBar)
FavFilterBtn.Size = UDim2.new(0, IsMobile and 30 or 36, 0, IsMobile and 30 or 36)
FavFilterBtn.Position = UDim2.new(1, -46, 0, IsMobile and 5 or 7)
FavFilterBtn.BackgroundColor3 = Theme.Card; FavFilterBtn.Text = ""
FavFilterBtn.ZIndex = 3
Instance.new("UICorner", FavFilterBtn).CornerRadius = UDim.new(0, 8)
local FavStroke = Instance.new("UIStroke", FavFilterBtn)
FavStroke.Color = Theme.Stroke

local FavIcon = Instance.new("ImageLabel", FavFilterBtn)
FavIcon.Size = UDim2.new(0, 18, 0, 18)
FavIcon.AnchorPoint = Vector2.new(0.5, 0.5)
FavIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
FavIcon.BackgroundTransparency = 1; FavIcon.Image = "rbxassetid://10747384351"
FavIcon.ImageColor3 = Theme.TextSecondary; FavIcon.ZIndex = 4

local ScriptScroll = Instance.new("ScrollingFrame", ScriptsView)
ScriptScroll.Size = UDim2.new(1, 0, 1, -(IsMobile and 40 or 50))
ScriptScroll.Position = UDim2.new(0, 0, 0, IsMobile and 40 or 50)
ScriptScroll.BackgroundTransparency = 1
ScriptScroll.ScrollBarThickness = IsMobile and 2 or 4
ScriptScroll.ScrollBarImageColor3 = Theme.Stroke
ScriptScroll.ZIndex = 2

local ScriptLayout = Instance.new("UIListLayout", ScriptScroll)
ScriptLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScriptLayout.Padding = UDim.new(0, 8)
local ScriptPad = Instance.new("UIPadding", ScriptScroll)
ScriptPad.PaddingTop = UDim.new(0, 4); ScriptPad.PaddingBottom = UDim.new(0, 16)
ScriptPad.PaddingLeft = UDim.new(0, 16); ScriptPad.PaddingRight = UDim.new(0, 16)
RegConn(ScriptLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	if not isDestroying then ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, ScriptLayout.AbsoluteContentSize.Y + 20) end
end))

local ScriptElements = {}
local ShowFavoritesOnly = false

local function RefreshScriptList()
	if isDestroying then return end
	local query = string.lower(SearchInput.Text)
	for id, el in pairs(ScriptElements) do
		local matchQuery = query == "" or string.find(string.lower(el.Title), query, 1, true)
		local matchFav = (not ShowFavoritesOnly) or SavedData.Favorites[id]
		el.Frame.Visible = matchQuery and matchFav
	end
end

RegConn(FavFilterBtn.MouseButton1Click:Connect(CreateDebounce(0.2, function()
	ShowFavoritesOnly = not ShowFavoritesOnly
	SafeTween(FavIcon, TweenInfo.new(0.2), {ImageColor3 = ShowFavoritesOnly and Theme.Accent or Theme.TextSecondary})
	SafeTween(FavStroke, TweenInfo.new(0.2), {Color = ShowFavoritesOnly and Theme.Accent or Theme.Stroke})
	RefreshScriptList()
end)))

local function OnSearchChanged()
	if typingTask then task.cancel(typingTask) end
	typingTask = task.delay(0.3, RefreshScriptList)
end
RegConn(SearchInput:GetPropertyChangedSignal("Text"):Connect(OnSearchChanged))

local function OpenScriptDetails(scriptData, frame)
	if isDestroying or isTransitioning then return end
	isTransitioning = true

	local Overlay = Instance.new("Frame", ScriptsView)
	Overlay.Size = UDim2.new(1, 0, 1, 0)
	Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	Overlay.BackgroundTransparency = 1; Overlay.ZIndex = 10
	
	local Modal = Instance.new("Frame", Overlay)
	Modal.Size = UDim2.new(1, -32, 0, IsMobile and 240 or 280)
	Modal.AnchorPoint = Vector2.new(0.5, 0.5)
	Modal.Position = UDim2.new(0.5, 0, 0.5, 20)
	Modal.BackgroundColor3 = Theme.Card; Modal.GroupTransparency = 1
	Modal.ClipsDescendants = true; Modal.ZIndex = 11
	Instance.new("UICorner", Modal).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", Modal).Color = Theme.Stroke
	
	SafeTween(Overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5})
	SafeTween(Modal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 0})

	local mTitle = Instance.new("TextLabel", Modal)
	mTitle.Size = UDim2.new(1, -32, 0, 30)
	mTitle.Position = UDim2.new(0, 16, 0, 16)
	mTitle.BackgroundTransparency = 1; mTitle.Text = scriptData.title
	mTitle.TextColor3 = Theme.TextPrimary; mTitle.Font = Enum.Font.GothamBold
	mTitle.TextSize = IsMobile and 16 or 18; mTitle.TextXAlignment = Enum.TextXAlignment.Left
	mTitle.ZIndex = 12

	local mDesc = Instance.new("TextLabel", Modal)
	mDesc.Size = UDim2.new(1, -32, 1, -120)
	mDesc.Position = UDim2.new(0, 16, 0, 50)
	mDesc.BackgroundTransparency = 1
	mDesc.Text = scriptData.description or "No description provided."
	mDesc.TextColor3 = Theme.TextSecondary; mDesc.Font = Enum.Font.GothamMedium
	mDesc.TextSize = IsMobile and 12 or 13; mDesc.TextXAlignment = Enum.TextXAlignment.Left
	mDesc.TextYAlignment = Enum.TextYAlignment.Top; mDesc.TextWrapped = true
	mDesc.ZIndex = 12

	local mInfo = Instance.new("TextLabel", Modal)
	mInfo.Size = UDim2.new(1, -32, 0, 20)
	mInfo.Position = UDim2.new(0, 16, 1, -66)
	mInfo.BackgroundTransparency = 1
	local isAuto = SavedData.AutoExecutes[scriptData.id] ~= nil
	local sType = scriptData.script.type == "url" and "Cloud API" or "Direct Source"
	mInfo.Text = "Author: " .. (scriptData.author or "Unknown") .. " | Format: " .. sType .. "\nAuto-Execute: " .. (isAuto and "Enabled" or "Disabled")
	mInfo.TextColor3 = Theme.TextSecondary; mInfo.Font = Enum.Font.Gotham
	mInfo.TextSize = 11; mInfo.TextXAlignment = Enum.TextXAlignment.Left
	mInfo.ZIndex = 12

	local ConfirmCancelBtn = Instance.new("TextButton", Modal)
	ConfirmCancelBtn.Size = UDim2.new(0.5, -20, 0, 36)
	ConfirmCancelBtn.Position = UDim2.new(0, 16, 1, -44)
	ConfirmCancelBtn.BackgroundColor3 = Theme.CardHover; ConfirmCancelBtn.Text = "Cancel"
	ConfirmCancelBtn.TextColor3 = Theme.TextPrimary; ConfirmCancelBtn.Font = Enum.Font.GothamMedium
	ConfirmCancelBtn.TextSize = 13; ConfirmCancelBtn.ZIndex = 12
	Instance.new("UICorner", ConfirmCancelBtn).CornerRadius = UDim.new(0, 8)
	ApplyInteractiveAnimations(ConfirmCancelBtn, Theme.CardHover, Theme.Stroke, Theme.BackgroundSecondary, nil, nil, nil)

	local ConfirmExecuteBtn = Instance.new("TextButton", Modal)
	ConfirmExecuteBtn.Size = UDim2.new(0.5, -20, 0, 36)
	ConfirmExecuteBtn.Position = UDim2.new(0.5, 4, 1, -44)
	ConfirmExecuteBtn.BackgroundColor3 = Theme.Accent; ConfirmExecuteBtn.Text = "Execute"
	ConfirmExecuteBtn.TextColor3 = Color3.new(1, 1, 1); ConfirmExecuteBtn.Font = Enum.Font.GothamMedium
	ConfirmExecuteBtn.TextSize = 13; ConfirmExecuteBtn.ZIndex = 12
	Instance.new("UICorner", ConfirmExecuteBtn).CornerRadius = UDim.new(0, 8)
	ApplyInteractiveAnimations(ConfirmExecuteBtn, Theme.Accent, Color3.fromRGB(81, 84, 219), Color3.fromRGB(67, 70, 189), nil, nil, nil)

	local function CloseModal()
		if not Overlay.Parent then return end
		local t1 = SafeTween(Overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		local t2 = SafeTween(Modal, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0.5, 20), GroupTransparency = 1})
		if t1 then 
			local c
			c = t1.Completed:Connect(function()
				if c then c:Disconnect() end
				if Overlay and Overlay.Parent then Overlay:Destroy() end
				isTransitioning = false
			end)
		else
			if Overlay and Overlay.Parent then Overlay:Destroy() end
			isTransitioning = false
		end
	end

	RegConn(ConfirmCancelBtn.Activated:Connect(CreateDebounce(0.1, CloseModal)))

	RegConn(ConfirmExecuteBtn.Activated:Connect(CreateDebounce(0.1, function()
		if not CheckActionCooldown("ScriptExecution") then return end
		SetActionCooldown("ScriptExecution", 2)
		
		CloseModal()
		local sourceCode = ""
		local sType = scriptData.script.type
		local isError = false
		if sType == "url" then
			sourceCode = UniversalHttpGet(scriptData.script.url)
			if not sourceCode then isError = true end
		elseif sType == "source" then
			sourceCode = scriptData.script.source
		end

		if isError or sourceCode == "" then
			ShowNotification("Failed to fetch script data.", "Error")
			return
		end

		local successExec, err = pcall(function() loadstring(sourceCode)() end)
		if successExec then
			ShowNotification("Executed '" .. scriptData.title .. "' successfully.", "Success")
			scriptData.views = (scriptData.views or 0) + 1
			if frame and frame:FindFirstChild("MetaLabel") then
				frame.MetaLabel.Text = tostring(scriptData.views) .. " Views • Updated " .. GetRelativeTime(scriptData.updatedAt)
			end
		else
			ShowNotification("Execution Error: " .. tostring(err), "Error")
		end
	end)))
end

local function CreateScriptCard(scriptData)
	if isDestroying then return end
	local id = tostring(scriptData.id)
	if ScriptElements[id] then return end

	local card = Instance.new("Frame", ScriptScroll)
	card.Size = UDim2.new(1, 0, 0, IsMobile and 64 or 72)
	card.BackgroundColor3 = Theme.Card
	card.ZIndex = 3
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local cStroke = Instance.new("UIStroke", card)
	cStroke.Color = Theme.Stroke
	ApplyInteractiveAnimations(card, Theme.Card, Theme.CardHover, Theme.CardHover, cStroke, Theme.Stroke, Theme.Accent)

	local titleLbl = Instance.new("TextLabel", card)
	titleLbl.Size = UDim2.new(1, -90, 0, 20)
	titleLbl.Position = UDim2.new(0, 12, 0, 12)
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = scriptData.title
	titleLbl.TextColor3 = Theme.TextPrimary; titleLbl.Font = Enum.Font.GothamMedium
	titleLbl.TextSize = IsMobile and 13 or 14; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd; titleLbl.ZIndex = 4

	local metaLbl = Instance.new("TextLabel", card)
	metaLbl.Name = "MetaLabel"
	metaLbl.Size = UDim2.new(1, -90, 0, 16)
	metaLbl.Position = UDim2.new(0, 12, 0, 36)
	metaLbl.BackgroundTransparency = 1
	metaLbl.Text = tostring(scriptData.views or 0) .. " Views • Updated " .. GetRelativeTime(scriptData.updatedAt)
	metaLbl.TextColor3 = Theme.TextSecondary; metaLbl.Font = Enum.Font.Gotham
	metaLbl.TextSize = IsMobile and 11 or 12; metaLbl.TextXAlignment = Enum.TextXAlignment.Left
	metaLbl.ZIndex = 4

	local actionContainer = Instance.new("Frame", card)
	actionContainer.Size = UDim2.new(0, 70, 1, 0)
	actionContainer.Position = UDim2.new(1, -70, 0, 0)
	actionContainer.BackgroundTransparency = 1; actionContainer.ZIndex = 4
	local actLayout = Instance.new("UIListLayout", actionContainer)
	actLayout.FillDirection = Enum.FillDirection.Horizontal
	actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actLayout.Padding = UDim.new(0, 6)
	local actPad = Instance.new("UIPadding", actionContainer)
	actPad.PaddingRight = UDim.new(0, 12)

	local starBtn = Instance.new("ImageButton", actionContainer)
	starBtn.Size = UDim2.new(0, 24, 0, 24)
	starBtn.BackgroundTransparency = 1; starBtn.Image = "rbxassetid://10747384351"
	starBtn.ImageColor3 = SavedData.Favorites[id] and Theme.Warning or Theme.TextSecondary
	starBtn.ZIndex = 5

	local autoExecBtn = Instance.new("ImageButton", actionContainer)
	autoExecBtn.Size = UDim2.new(0, 24, 0, 24)
	autoExecBtn.BackgroundTransparency = 1; autoExecBtn.Image = "rbxassetid://10747383618"
	autoExecBtn.ImageColor3 = SavedData.AutoExecutes[id] and Theme.Accent or Theme.TextSecondary
	autoExecBtn.ZIndex = 5

	RegConn(starBtn.Activated:Connect(CreateDebounce(0.2, function()
		if SavedData.Favorites[id] then
			SavedData.Favorites[id] = nil
			SafeTween(starBtn, TweenInfo.new(0.2), {ImageColor3 = Theme.TextSecondary})
			ShowNotification("Removed '" .. scriptData.title .. "' from favorites.", "Info")
		else
			SavedData.Favorites[id] = true
			SafeTween(starBtn, TweenInfo.new(0.2), {ImageColor3 = Theme.Warning})
			ShowNotification("Added '" .. scriptData.title .. "' to favorites.", "Success")
		end
		SaveConfiguration()
		if ShowFavoritesOnly then RefreshScriptList() end
	end)))

	RegConn(autoExecBtn.Activated:Connect(CreateDebounce(0.2, function()
		if SavedData.AutoExecutes[id] then
			SavedData.AutoExecutes[id] = nil
			SafeTween(autoExecBtn, TweenInfo.new(0.2), {ImageColor3 = Theme.TextSecondary})
			ShowNotification("Disabled Auto-Execute for '" .. scriptData.title .. "'.", "Info")
		else
			SavedData.AutoExecutes[id] = {PlaceId = game.PlaceId}
			SafeTween(autoExecBtn, TweenInfo.new(0.2), {ImageColor3 = Theme.Accent})
			ShowNotification("Enabled Auto-Execute for '" .. scriptData.title .. "'.", "Success")
		end
		SaveConfiguration()
	end)))

	local btn = Instance.new("TextButton", card)
	btn.Size = UDim2.new(1, -70, 1, 0)
	btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 5
	RegConn(btn.Activated:Connect(CreateDebounce(0.1, function() OpenScriptDetails(scriptData, card) end)))

	ScriptElements[id] = {Frame = card, Title = scriptData.title}
	return card
end

local function LoadDynamicCatalog()
	if isDestroying then return end
	local catalogData = nil
	local url = "https://raw.githubusercontent.com/username/velox-hub/main/catalog.json"
	
	task.spawn(function()
		local rawData = FetchWithRetry(url, 2, 1)
		if rawData then
			pcall(function() catalogData = HttpService:JSONDecode(rawData) end)
		end
		
		if not catalogData or type(catalogData) ~= "table" then
			catalogData = {
				{
					id = "s1", title = "Infinite Yield", author = "Edge",
					description = "The ultimate admin script with hundreds of commands.",
					script = {type = "url", url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
					updatedAt = os.time() - 86400, views = 50204
				},
				{
					id = "s2", title = "Dex Explorer", author = "Moon",
					description = "View and modify the game hierarchy in real-time.",
					script = {type = "url", url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"},
					updatedAt = os.time() - (86400 * 14), views = 21093
				},
				{
					id = "s3", title = "Simple ESP", author = "VeloxTeam",
					description = "Draws boxes around players.",
					script = {type = "source", source = "print('ESP Loaded')"},
					updatedAt = os.time() - 3600, views = 150
				}
			}
		end

		if isDestroying then return end
		table.sort(catalogData, function(a, b) return (a.updatedAt or 0) > (b.updatedAt or 0) end)
		for _, scr in ipairs(catalogData) do CreateScriptCard(scr) end
		RefreshScriptList()

		for sId, cfg in pairs(SavedData.AutoExecutes) do
			if cfg.PlaceId == PlaceId then
				for _, scr in ipairs(catalogData) do
					if tostring(scr.id) == tostring(sId) then
						task.spawn(function()
							local sc = ""
							if scr.script.type == "url" then sc = FetchWithRetry(scr.script.url, 2, 1) or ""
							elseif scr.script.type == "source" then sc = scr.script.source end
							if sc ~= "" then pcall(function() loadstring(sc)() end) end
						end)
						break
					end
				end
			end
		end
	end)
end

-- ================== SETTINGS VIEW ==================

local SettingsScroll = Instance.new("ScrollingFrame", SettingsView)
SettingsScroll.Size = UDim2.new(1, 0, 1, 0)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.ScrollBarThickness = IsMobile and 2 or 4
SettingsScroll.ScrollBarImageColor3 = Theme.Stroke
SettingsScroll.ZIndex = 2

local SetLayout = Instance.new("UIListLayout", SettingsScroll)
SetLayout.SortOrder = Enum.SortOrder.LayoutOrder
SetLayout.Padding = UDim.new(0, 12)
local SetPad = Instance.new("UIPadding", SettingsScroll)
SetPad.PaddingTop = UDim.new(0, 16); SetPad.PaddingBottom = UDim.new(0, 16)
SetPad.PaddingLeft = UDim.new(0, 16); SetPad.PaddingRight = UDim.new(0, 16)
RegConn(SetLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	if not isDestroying then SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, SetLayout.AbsoluteContentSize.Y + 32) end
end))

local function CreateSettingToggle(title, desc, parent, order, settingKey, callback)
	local card = Instance.new("Frame", parent)
	card.Size = UDim2.new(1, 0, 0, 60)
	card.BackgroundColor3 = Theme.Card; card.LayoutOrder = order; card.ZIndex = 3
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", card).Color = Theme.Stroke

	local lbl = Instance.new("TextLabel", card)
	lbl.Size = UDim2.new(1, -70, 0, 20)
	lbl.Position = UDim2.new(0, 16, 0, 10)
	lbl.BackgroundTransparency = 1; lbl.Text = title
	lbl.TextColor3 = Theme.TextPrimary; lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4

	local dLbl = Instance.new("TextLabel", card)
	dLbl.Size = UDim2.new(1, -70, 0, 16)
	dLbl.Position = UDim2.new(0, 16, 0, 32)
	dLbl.BackgroundTransparency = 1; dLbl.Text = desc
	dLbl.TextColor3 = Theme.TextSecondary; dLbl.Font = Enum.Font.Gotham
	dLbl.TextSize = 11; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.ZIndex = 4

	local toggleBg = Instance.new("Frame", card)
	toggleBg.Size = UDim2.new(0, 40, 0, 20)
	toggleBg.AnchorPoint = Vector2.new(1, 0.5)
	toggleBg.Position = UDim2.new(1, -16, 0.5, 0)
	toggleBg.BackgroundColor3 = SavedData.Settings[settingKey] and Theme.Accent or Theme.ToggleOff
	toggleBg.ZIndex = 4
	Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

	local toggleDot = Instance.new("Frame", toggleBg)
	toggleDot.Size = UDim2.new(0, 16, 0, 16)
	toggleDot.Position = SavedData.Settings[settingKey] and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
	toggleDot.BackgroundColor3 = Color3.new(1, 1, 1); toggleDot.ZIndex = 5
	Instance.new("UICorner", toggleDot).CornerRadius = UDim.new(1, 0)

	local toggleBtn = Instance.new("TextButton", card)
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1; toggleBtn.Text = ""; toggleBtn.ZIndex = 6

	RegConn(toggleBtn.Activated:Connect(CreateDebounce(0.1, function()
		SavedData.Settings[settingKey] = not SavedData.Settings[settingKey]
		local state = SavedData.Settings[settingKey]
		SafeTween(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff})
		SafeTween(toggleDot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)})
		SaveConfiguration()
		if callback then callback(state) end
	end)))
end

local function CreateSettingKeybind(title, desc, parent, order)
	local card = Instance.new("Frame", parent)
	card.Size = UDim2.new(1, 0, 0, 60)
	card.BackgroundColor3 = Theme.Card; card.LayoutOrder = order; card.ZIndex = 3
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", card).Color = Theme.Stroke

	local lbl = Instance.new("TextLabel", card)
	lbl.Size = UDim2.new(1, -120, 0, 20)
	lbl.Position = UDim2.new(0, 16, 0, 10)
	lbl.BackgroundTransparency = 1; lbl.Text = title
	lbl.TextColor3 = Theme.TextPrimary; lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4

	local dLbl = Instance.new("TextLabel", card)
	dLbl.Size = UDim2.new(1, -120, 0, 16)
	dLbl.Position = UDim2.new(0, 16, 0, 32)
	dLbl.BackgroundTransparency = 1; dLbl.Text = desc
	dLbl.TextColor3 = Theme.TextSecondary; dLbl.Font = Enum.Font.Gotham
	dLbl.TextSize = 11; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.ZIndex = 4

	local btn = Instance.new("TextButton", card)
	btn.Size = UDim2.new(0, 90, 0, 30)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -16, 0.5, 0)
	btn.BackgroundColor3 = Theme.BackgroundSecondary
	btn.Text = SavedData.ToggleKeybind; btn.TextColor3 = Theme.TextPrimary
	btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12; btn.ZIndex = 5
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", btn).Color = Theme.Stroke

	RegConn(btn.MouseButton1Click:Connect(function()
		if IsBindingKey then return end
		IsBindingKey = true
		btn.Text = "..."
		local bindConn
		bindConn = RegConn(UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				SavedData.ToggleKeybind = input.KeyCode.Name
				btn.Text = SavedData.ToggleKeybind
				SaveConfiguration()
				if bindConn then bindConn:Disconnect() end
				task.wait(0.1)
				IsBindingKey = false
			end
		end))
	end))
end

local function CreateButtonSetting(title, desc, btnText, parent, order, callback)
	local card = Instance.new("Frame", parent)
	card.Size = UDim2.new(1, 0, 0, 60)
	card.BackgroundColor3 = Theme.Card; card.LayoutOrder = order; card.ZIndex = 3
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", card).Color = Theme.Stroke

	local lbl = Instance.new("TextLabel", card)
	lbl.Size = UDim2.new(1, -120, 0, 20)
	lbl.Position = UDim2.new(0, 16, 0, 10)
	lbl.BackgroundTransparency = 1; lbl.Text = title
	lbl.TextColor3 = Theme.TextPrimary; lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4

	local dLbl = Instance.new("TextLabel", card)
	dLbl.Size = UDim2.new(1, -120, 0, 16)
	dLbl.Position = UDim2.new(0, 16, 0, 32)
	dLbl.BackgroundTransparency = 1; dLbl.Text = desc
	dLbl.TextColor3 = Theme.TextSecondary; dLbl.Font = Enum.Font.Gotham
	dLbl.TextSize = 11; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.ZIndex = 4

	local btn = Instance.new("TextButton", card)
	btn.Size = UDim2.new(0, 90, 0, 30)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -16, 0.5, 0)
	btn.BackgroundColor3 = Theme.BackgroundSecondary
	btn.Text = btnText; btn.TextColor3 = Theme.TextPrimary
	btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12; btn.ZIndex = 5
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local bStroke = Instance.new("UIStroke", btn); bStroke.Color = Theme.Stroke
	ApplyInteractiveAnimations(btn, Theme.BackgroundSecondary, Theme.CardHover, Theme.Card, bStroke, Theme.Stroke, Theme.Accent)
	RegConn(btn.Activated:Connect(function() if callback then callback() end end))
end

CreateSettingKeybind("Toggle UI", "Keybind to show/hide the hub.", SettingsScroll, 1)

CreateSettingToggle("Anti-AFK", "Prevents Roblox from kicking you for inactivity.", SettingsScroll, 2, "AntiAFK", function(state)
	if state then
		if not AfkConnections["Idled"] then
			AfkConnections["Idled"] = LocalPlayer.Idled:Connect(function()
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
				task.wait(0.1)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
			end)
		end
		ShowNotification("Anti-AFK Enabled", "Success")
	else
		if AfkConnections["Idled"] then
			AfkConnections["Idled"]:Disconnect()
			AfkConnections["Idled"] = nil
		end
		ShowNotification("Anti-AFK Disabled", "Info")
	end
end)
if SavedData.Settings.AntiAFK then
	AfkConnections["Idled"] = LocalPlayer.Idled:Connect(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
	end)
end

CreateButtonSetting("Refresh Catalog", "Forces an update to the script list.", "Refresh", SettingsScroll, 3, function() 
	if not CheckActionCooldown("RefreshCatalog") then return end
	SetActionCooldown("RefreshCatalog", 5)
	LoadDynamicCatalog() 
end)

CreateButtonSetting("Unload Hub", "Removes Velox Hub from memory.", "Unload", SettingsScroll, 4, function() getgenv()[_G_Identifier]() end)

RegConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isDestroying or gameProcessed or IsBindingKey then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local boundKey = Enum.KeyCode[SavedData.ToggleKeybind]
		if boundKey and input.KeyCode == boundKey then
			ToggleUI()
		end
	end
end))

SwitchView("Home")
LoadDynamicCatalog()
ShowNotification("Welcome to Velox Hub", "Info")
