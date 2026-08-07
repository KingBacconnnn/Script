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

local VeloxConnections = {}
local RegisteredScripts = {}
local AfkConnections = {}
local ActiveNotifications = {}
local NotificationQueue = {}
local ActiveTweens = {}
local ActiveCooldowns = {}

local isDestroying = false
local isMinimized = false
local isTransitioning = false
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
	if isDestroying then return end
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
			if notif.CountdownTimer then task.cancel(notif.CountdownTimer) end
			if notif.Wrapper then notif.Wrapper:Destroy() end
		end)
	end

	for _, cd in pairs(ActiveCooldowns) do
		pcall(function()
			if cd.Timer then task.cancel(cd.Timer) end
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

local EntryTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ExitTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local ToastContainer = Instance.new("Frame", ScreenGui)
ToastContainer.Size = UDim2.new(0, IsMobile and 240 or 320, 1, -40)
ToastContainer.Position = UDim2.new(1, IsMobile and -250 or -330, 0, 20)
ToastContainer.BackgroundTransparency = 1
ToastContainer.ZIndex = 300

local ToastLayout = Instance.new("UIListLayout", ToastContainer)
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.Padding = UDim.new(0, 8)

local MAX_VISIBLE_NOTIFS = 3

local function ProcessNotificationQueue()
	if isDestroying then return end
	while #ActiveNotifications < MAX_VISIBLE_NOTIFS and #NotificationQueue > 0 do
		local nextNotif = table.remove(NotificationQueue, 1)
		DisplayNotification(nextNotif.Msg, nextNotif.Type, nextNotif.Duration, nextNotif.ActionKey)
	end
end

function DisplayNotification(msg, nType, customDuration, actionKey)
	if isDestroying then return end
	
	if actionKey then
		for _, existing in ipairs(ActiveNotifications) do
			if existing.ActionKey == actionKey then
				if existing.Timer then task.cancel(existing.Timer); existing.Timer = nil end
				if existing.CountdownTimer then task.cancel(existing.CountdownTimer); existing.CountdownTimer = nil end
				existing.TextLabel.Text = tostring(msg)
				
				local duration = customDuration or 3.5
				if duration > 0 then
					SafeTween(existing.ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
					existing.Timer = task.delay(duration, function()
						if existing and type(existing.Remove) == "function" then
							existing.Remove()
						end
					end)
				end
				return existing
			end
		end
	end

	local indicatorColor = Theme[nType] or Theme.Info
	local notifState = { IsRemoving = false, ActionKey = actionKey }
	
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
	notifState.TextLabel = txt

	local progressBar = Instance.new("Frame", box)
	progressBar.AnchorPoint = Vector2.new(0, 1)
	progressBar.Position = UDim2.new(0, -12, 1, 12)
	progressBar.Size = UDim2.new(1, 24, 0, 2)
	progressBar.BackgroundColor3 = indicatorColor
	progressBar.BorderSizePixel = 0; progressBar.ZIndex = 304
	notifState.ProgressBar = progressBar

	CacheInstanceAndDescendants(wrapper)

	local function RemoveNotification()
		if notifState.IsRemoving then return end
		notifState.IsRemoving = true

		if notifState.Timer then task.cancel(notifState.Timer); notifState.Timer = nil end
		if notifState.CountdownTimer then task.cancel(notifState.CountdownTimer); notifState.CountdownTimer = nil end

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
			end
		else
			if wrapper and wrapper.Parent then wrapper:Destroy() end
		end
	end

	notifState.Remove = RemoveNotification
	table.insert(ActiveNotifications, notifState)

	SafeTween(box, EntryTweenInfo, {Position = UDim2.new(0, 0, 0, 0)})
	
	local duration = customDuration or 3.5
	if duration > 0 then
		SafeTween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
		notifState.Timer = task.delay(duration, function()
			if notifState and type(notifState.Remove) == "function" then
				notifState.Remove()
			end
		end)
	end
	
	return notifState
end

getfenv().ShowNotification = function(msg, notifType, customDuration, actionKey)
	if isDestroying then return end
	local nType = type(notifType) == "boolean" and (notifType and "Success" or "Error") or (notifType or "Info")
	table.insert(NotificationQueue, {Msg = tostring(msg), Type = nType, Duration = customDuration, ActionKey = actionKey})
	ProcessNotificationQueue()
end
local ShowNotification = getfenv().ShowNotification

local function RunWithCooldown(actionName, func, cooldownDuration)
	cooldownDuration = cooldownDuration or 3
	if ActiveCooldowns[actionName] then
		local remaining = math.ceil(ActiveCooldowns[actionName].Expires - os.clock())
		if remaining > 0 then
			ShowNotification("Please try again in " .. remaining .. " second" .. (remaining == 1 and "" or "s") .. ".", "Warning", 1.1, "Cooldown_" .. actionName)
			return
		end
	end

	ActiveCooldowns[actionName] = {
		Expires = os.clock() + cooldownDuration
	}

	local notifActionKey = "Cooldown_" .. actionName
	ShowNotification("Please try again in " .. cooldownDuration .. " seconds.", "Warning", 1.1, notifActionKey)

	ActiveCooldowns[actionName].Timer = task.spawn(function()
		for i = cooldownDuration - 1, 1, -1 do
			task.wait(1)
			if ActiveCooldowns[actionName] then
				ShowNotification("Please try again in " .. i .. " second" .. (i == 1 and "" or "s") .. ".", "Warning", 1.1, notifActionKey)
			else
				return
			end
		end
		task.wait(1)
		if ActiveCooldowns[actionName] then
			ShowNotification("Ready.", "Success", 1.5, notifActionKey)
			ActiveCooldowns[actionName] = nil
		end
	end)

	task.spawn(func)
end

local ApplyInteractiveAnimations
ApplyInteractiveAnimations = function(gui, originalColor, hoverColor, clickColor, strokeObj, originalStroke, hoverStroke)
	if not gui:IsA("GuiObject") then return end

	RegConn(gui.MouseEnter:Connect(function()
		if isDestroying or isTransitioning then return end
		if originalColor and hoverColor then SafeTween(gui, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}) end
		if strokeObj and hoverStroke then strokeObj.Color = hoverStroke end
	end))

	RegConn(gui.MouseLeave:Connect(function()
		if isDestroying or isTransitioning then return end
		if originalColor then SafeTween(gui, TweenInfo.new(0.15), {BackgroundColor3 = originalColor}) end
		if strokeObj and originalStroke then strokeObj.Color = originalStroke end
	end))

	RegConn(gui.InputBegan:Connect(function(input)
		if isDestroying or isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if clickColor then SafeTween(gui, TweenInfo.new(0.1), {BackgroundColor3 = clickColor}) end
		end
	end))

	RegConn(gui.InputEnded:Connect(function(input)
		if isDestroying or isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if hoverColor then 
				SafeTween(gui, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor})
			elseif originalColor then 
				SafeTween(gui, TweenInfo.new(0.1), {BackgroundColor3 = originalColor})
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
		
		SafeTween(MainPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
		task.wait(0.15)
		MainPanel.Visible = false
		RestoreCachedProperties()
		
		FloatingBtn.Visible = true
		FloatingBtn.Size = UDim2.new(0, 0, 0, 0)
		FloatingBtn.ImageTransparency = 1
		FloatStroke.Transparency = 1
		SafeTween(FloatingBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 45, 0, 45), ImageTransparency = 0})
		SafeTween(FloatStroke, TweenInfo.new(0.2), {Transparency = 0})
	else
		isMinimized = false
		FloatingBtn.Visible = false
		
		MainPanel.Size = UDim2.new(0, 0, 0, 0)
		MainPanel.Visible = true
		SafeTween(MainPanel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = PANEL_SIZE})
		RestoreCachedProperties()
		pcall(function() MainPanel.Interactable = true end)
	end

	task.wait(0.25) 
	isTransitioning = false
end

RegConn(FloatingBtn.MouseButton1Click:Connect(function() 
	if not floatDrag then 
		RunWithCooldown("FloatingButton", ToggleUI, 1)
	end 
end))

local ConfirmOverlay = Instance.new("Frame", ScreenGui)
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.Position = UDim2.new(0, 0, 0, 0)
ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 1
ConfirmOverlay.Visible = false
ConfirmOverlay.ZIndex = 400
ConfirmOverlay.Active = true

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
ConfirmMessage.Text = "Are you sure you want to execute this script?"
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
	RunWithCooldown("ConfirmationDialogs", function()
		isConfirming = true
		pendingExecuteCallback = onExecute

		ConfirmScriptName.Text = scriptName
		ConfirmExecuteBtn.Active = true
		ConfirmExecuteBtn.AutoButtonColor = true
		ConfirmExecuteBtn.Text = "Execute"

		ConfirmOverlay.BackgroundTransparency = 0.5
		ConfirmOverlay.Visible = true
	end, 1)
end

local function CloseConfirmDialog(shouldExecute)
	if not isConfirming then return end
	ConfirmExecuteBtn.Active = false
	ConfirmOverlay.BackgroundTransparency = 1
	ConfirmOverlay.Visible = false
	isConfirming = false

	local cb = pendingExecuteCallback
	pendingExecuteCallback = nil

	if shouldExecute and type(cb) == "function" then task.spawn(cb) end
end

RegConn(ConfirmCancelBtn.Activated:Connect(function() 
	RunWithCooldown("ConfirmationDialogs", function() CloseConfirmDialog(false) end, 1) 
end))
RegConn(ConfirmExecuteBtn.Activated:Connect(function() 
	RunWithCooldown("ConfirmationDialogs", function() CloseConfirmDialog(true) end, 1) 
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

RegConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isConfirming then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
			CloseConfirmDialog(false)
			return
		end
	end
	if IsBindingKey then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				IsBindingKey = false
				if KeybindButtonRef then KeybindButtonRef.Text = ToggleKeybind.Name end
				ShowNotification("Keybind mapping canceled.", "Warning")
				return
			end
			if input.KeyCode.Name ~= "Unknown" then
				ToggleKeybind = input.KeyCode
				IsBindingKey = false
				SavedData.ToggleKeybind = ToggleKeybind.Name
				SaveConfiguration()
				if KeybindButtonRef then KeybindButtonRef.Text = ToggleKeybind.Name end
				ShowNotification("Keybind set to: " + input.KeyCode.Name, "Success")
			end
		end
		return
	end
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == ToggleKeybind then 
		RunWithCooldown("ToggleUI", ToggleUI, 1) 
	end
end))

local function CloseUI()
	if isDestroying then return end
	if SearchInput and SearchInput.Parent then pcall(function() SearchInput:ReleaseFocus() end) end
	CleanUpMemory()
	getgenv()[_G_Identifier]()
end

local HeaderContainer = Instance.new("Frame", PanelGroup)
HeaderContainer.Size = UDim2.new(1, -32, 0, IsMobile and 48 or 56)
HeaderContainer.Position = UDim2.new(0, 16, 0, IsMobile and 6 or 10)
HeaderContainer.BackgroundTransparency = 1
HeaderContainer.Active = true 

local mainDragging, mainDragInput, mainDragStart, mainStartPos, mainInputEndedConn

RegConn(HeaderContainer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if mainInputEndedConn then mainInputEndedConn:Disconnect() end
		mainDragging = true
		mainDragStart = input.Position
		mainStartPos = MainPanel.Position
		
		mainInputEndedConn = RegConn(input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				mainDragging = false
				if OriginalCache[MainPanel] then OriginalCache[MainPanel].Position = MainPanel.Position end
				if mainInputEndedConn then mainInputEndedConn:Disconnect() end
			end
		end))
	end
end))

RegConn(HeaderContainer.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		mainDragInput = input
	end
end))

RegConn(UserInputService.InputChanged:Connect(function(input)
	if input == mainDragInput and mainDragging then
		local delta = input.Position - mainDragStart
		MainPanel.Position = UDim2.new(
			mainStartPos.X.Scale, mainStartPos.X.Offset + delta.X, 
			mainStartPos.Y.Scale, mainStartPos.Y.Offset + delta.Y
		)
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
VersionLabel.BackgroundTransparency = 1; VersionLabel.Text = "v3.1.1 (Stable) | " .. getexecutor()
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
		local thumb, ready = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
		if thumb and ready then AvatarFrame.Image = ready break else task.wait(2) end
	end
end)

local MinBtn = Instance.new("TextButton", RightHeaderFrame)
MinBtn.Size = UDim2.new(0, 28, 0, 28); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TextSecondary; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = IsMobile and 14 or 18; MinBtn.LayoutOrder = 3
MinBtn.ClipsDescendants = true
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
RegConn(MinBtn.Activated:Connect(function() 
	RunWithCooldown("Minimize", ToggleUI, 1) 
end))
ApplyInteractiveAnimations(MinBtn, nil, Theme.CardHover, Theme.CardHover, nil, nil, nil)

local fpsCount = 0
local lastPingUpdate = tick()
RegConn(RunService.Heartbeat:Connect(function() 
	if isMinimized or isDestroying or isTransitioning then return end 
	fpsCount = fpsCount + 1 
	if tick() - lastPingUpdate >= 1 then
		lastPingUpdate = tick()
		local success, ping = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
		if DiagnosticsLabel and DiagnosticsLabel.Parent then
			DiagnosticsLabel.Text = string.format("FPS: %d | Ping: %dms", fpsCount, success and ping or 0)
		end
		fpsCount = 0
	end
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
	scroll.ScrollingEnabled = true
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
SearchInput.Size = UDim2.new(1, -12, 1, 0); SearchInput.Position = UDim2.new(0, 12, 0, 0); SearchInput.BackgroundTransparency = 1
SearchInput.Text = SavedData.LastSearch or ""; SearchInput.PlaceholderText = "Search scripts by name..."
SearchInput.PlaceholderColor3 = Color3.fromRGB(148, 163, 184); SearchInput.TextColor3 = Color3.fromRGB(248, 250, 252)
SearchInput.Font = Enum.Font.Gotham; SearchInput.TextSize = 12; SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false; SearchInput.TextEditable = true; SearchInput.Interactable = true; SearchInput.ZIndex = 52
Instance.new("UIPadding", SearchInput).PaddingRight = UDim.new(0, 10)

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

local DropdownContainer = Instance.new("ScrollingFrame", ScreenGui)
DropdownContainer.Size = UDim2.new(0, 190, 0, 210); DropdownContainer.BackgroundColor3 = Theme.BackgroundMain
DropdownContainer.Visible = false; DropdownContainer.ZIndex = 200; DropdownContainer.BorderSizePixel = 0
DropdownContainer.ScrollBarThickness = 2; DropdownContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
DropdownContainer.ScrollingEnabled = true
Instance.new("UICorner", DropdownContainer).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", DropdownContainer).Color = Theme.Accent
local DDLayout = Instance.new("UIListLayout", DropdownContainer); DDLayout.SortOrder = Enum.SortOrder.LayoutOrder

local FilterFavoritesActive = false
local isFiltering = false
local SortMode = "Most Relevant"
local SortOptions = {
	"Most Relevant", "A-Z", "Z-A", "Newest", "Oldest",
	"Updated Today", "Updated This Week", "Updated This Month",
	"Favorites", "Auto Execute: ON", "Auto Execute: OFF"
}

local function UpdateFilter()
	if isDestroying or isFiltering then return end
	isFiltering = true
	
	task.defer(function()
		local savedScroll = ScriptsView.CanvasPosition
		local queryText = SearchInput.Text
		local query = string.lower(string.gsub(queryText, "^%s*(.-)%s*$", "%1")) 
		SavedData.LastSearch = queryText
		SaveConfiguration()

		local words = {}
		for word in string.gmatch(query, "%S+") do table.insert(words, word) end
		local matches = {}
		local cycleCount = 0
		local osTimeCache = os.time()

		for _, scr in ipairs(RegisteredScripts) do
			local isMatch = true
			if query ~= "" then
				for _, w in ipairs(words) do
					if not (string.find(scr.SearchTitle, w, 1, true) or
							string.find(scr.SearchDesc, w, 1, true) or
							string.find(scr.SearchMeta, w, 1, true)) then
						isMatch = false
						break
					end
				end
			end

			local filterPass = true
			local age = scr.LastUpdated and (osTimeCache - scr.LastUpdated) or math.huge

			if FilterFavoritesActive then
				if not SavedData.Favorites[scr.ExactName] then filterPass = false end
			end

			if filterPass then
				if SortMode == "Updated Today" then filterPass = (age <= 86400)
				elseif SortMode == "Updated This Week" then filterPass = (age <= 604800)
				elseif SortMode == "Updated This Month" then filterPass = (age <= 2592000)
				elseif SortMode == "Favorites" then filterPass = SavedData.Favorites[scr.ExactName]
				elseif SortMode == "Auto Execute: ON" then filterPass = (SavedData.AutoExecutes[scr.ExactName] ~= nil)
				elseif SortMode == "Auto Execute: OFF" then filterPass = (SavedData.AutoExecutes[scr.ExactName] == nil)
				end
			end

			local visible = isMatch and filterPass
			if scr.Instance.Visible ~= visible then scr.Instance.Visible = visible end
			if visible then table.insert(matches, scr) end
			
			cycleCount = cycleCount + 1
			if cycleCount % 20 == 0 then task.wait() end 
		end

		table.sort(matches, function(a, b)
			if SortMode == "Most Relevant" and query ~= "" then
				local aExact = string.sub(a.SearchTitle, 1, #query) == query
				local bExact = string.sub(b.SearchTitle, 1, #query) == query
				if aExact and not bExact then return true end
				if not aExact and bExact then return false end
			elseif SortMode == "A-Z" then return a.SearchTitle < b.SearchTitle
			elseif SortMode == "Z-A" then return a.SearchTitle > b.SearchTitle
			elseif SortMode == "Newest" then return (a.LastUpdated or 0) > (b.LastUpdated or 0)
			elseif SortMode == "Oldest" then return (a.LastUpdated or 0) < (b.LastUpdated or 0)
			elseif SortMode == "Favorites" then
				local aFav = SavedData.Favorites[a.ExactName] and 1 or 0
				local bFav = SavedData.Favorites[b.ExactName] and 1 or 0
				if aFav ~= bFav then return aFav > bFav end
			elseif SortMode == "Auto Execute: ON" or SortMode == "Auto Execute: OFF" then
				local aAuto = SavedData.AutoExecutes[a.ExactName] and 1 or 0
				local bAuto = SavedData.AutoExecutes[b.ExactName] and 1 or 0
				if aAuto ~= bAuto then return aAuto > bAuto end
			end
			return a.OriginalIndex < b.OriginalIndex
		end)

		for idx, scr in ipairs(matches) do 
			if scr.Instance.LayoutOrder ~= idx then scr.Instance.LayoutOrder = idx end
		end

		if #RegisteredScripts > 0 then
			local shouldShowEmpty = (#matches == 0)
			if EmptyStateMessage.Visible ~= shouldShowEmpty then
				EmptyStateMessage.Visible = shouldShowEmpty
			end
			if shouldShowEmpty then EmptyStateMessage.Text = "No scripts matched your search or filters." end
		end

		if ScriptsView and ScriptsView.Parent then ScriptsView.CanvasPosition = savedScroll end
		isFiltering = false
	end)
end

RegConn(SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if typingTask then task.cancel(typingTask) end
	typingTask = task.delay(0.2, function() UpdateFilter() end)
end))

RegConn(FavFilterBtn.MouseButton1Click:Connect(function()
	RunWithCooldown("Favorite", function()
		if isDestroying then return end
		FilterFavoritesActive = not FilterFavoritesActive
		
		if FilterFavoritesActive then
			FavFilterBtn.Text = "★"; FavFilterBtn.TextColor3 = Color3.fromRGB(250, 204, 21); FavFilterStroke.Color = Color3.fromRGB(250, 204, 21)
		else
			FavFilterBtn.Text = "☆"; FavFilterBtn.TextColor3 = Color3.fromRGB(148, 163, 184); FavFilterStroke.Color = Color3.fromRGB(51, 65, 85)
		end
		UpdateFilter()
	end, 0.5)
end))

for _, opt in ipairs(SortOptions) do
	local btn = Instance.new("TextButton", DropdownContainer)
	btn.Size = UDim2.new(1, 0, 0, 28); btn.BackgroundTransparency = 1
	btn.Text = "  " + opt; btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = (opt == SortMode) and Theme.Accent or Theme.TextPrimary
	btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11; btn.ZIndex = 201

	RegConn(btn.Activated:Connect(function()
		RunWithCooldown("Search", function()
			SortMode = opt
			DropdownContainer.Visible = false
			for _, child in ipairs(DropdownContainer:GetChildren()) do
				if child:IsA("TextButton") then child.TextColor3 = Theme.TextPrimary end
			end
			btn.TextColor3 = Theme.Accent
			UpdateFilter()
		end, 0.5)
	end))
end

RegConn(SortDropdownBtn.Activated:Connect(function()
	RunWithCooldown("Search", function()
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
			if posY + dropHeight > viewportSize.Y - 10 then posY = absPos.Y - dropHeight - 4 end

			DropdownContainer.Position = UDim2.new(0, posX, 0, posY)
			DropdownContainer.Visible = true
		end
	end, 0.5)
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
		RunWithCooldown("Tab switching", function()
			if isDestroying or currentTab == name then return end
			currentTab = name; DropdownContainer.Visible = false
			SafeTween(TabIndicator, EntryTweenInfo, {Position = UDim2.new(0, xOffset + 4, 1, -2)})

			SectionHeaderLabel.Text = (name == "Changelogs") and "Updates" or (name == "Scripts") and "Scripts Catalog" or "Settings Hub"
			SearchRow.Visible = (name == "Scripts")

			if name == "Scripts" then UpdateFilter() else if SearchInput.Parent then pcall(function() SearchInput:ReleaseFocus() end) end end

			for tName, view in pairs(TabViews) do
				view.Visible = (tName == name)
				if view.Visible then view.CanvasPosition = Vector2.new(0, 0) end
			end
			for tName, tBtn in pairs(TabButtonCache) do
				tBtn.TextColor3 = (tName == currentTab) and Theme.TextPrimary or Theme.TextSecondary
			end
		end, 0.5)
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

CreateParagraph("v3.1.1 - Core Stability Overhaul", "• Fully integrated custom TweenManager resolving overlapping states & memory leaks.\n• Purged dead signal callbacks globally, closing performance bleed during repeated interactions.\n• Restructured layout rendering engine ensuring frame-perfect alignment out of minimization states.", ChangelogsView)

local function RefreshAllCardStates()
	for _, scrData in ipairs(RegisteredScripts) do
		if type(scrData.UpdateUI) == "function" then scrData.UpdateUI() end
	end
end

local function CreateScriptCard(data, renderParent)
	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0, 0); card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.Card; card.Text = ""
	card.AutoButtonColor = false; card.ClipsDescendants = true
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local cardStroke = Instance.new("UIStroke", card); cardStroke.Color = Color3.fromRGB(44, 58, 77)

	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)

	local img = Instance.new("ImageLabel", card)
	img.Size = UDim2.new(0, 68, 0, 68); img.BackgroundColor3 = Theme.BackgroundMain
	img.BorderSizePixel = 0; img.Image = data.ImageAssetId or "rbxassetid://99657752206675"
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

	local titleContainer = Instance.new("Frame", topRow)
	titleContainer.Size = UDim2.new(1, IsMobile and -115 or -140, 0, 0); titleContainer.AutomaticSize = Enum.AutomaticSize.Y
	titleContainer.BackgroundTransparency = 1; titleContainer.LayoutOrder = 1
	local titleLbl = Instance.new("TextLabel", titleContainer)
	titleLbl.Size = UDim2.new(1, 0, 0, 0); titleLbl.AutomaticSize = Enum.AutomaticSize.Y
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = data.Name or "Unnamed Script"
	titleLbl.TextColor3 = Theme.TextPrimary; titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = IsMobile and 12 or 13; titleLbl.TextWrapped = true; titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local metaRightContainer = Instance.new("Frame", topRow)
	metaRightContainer.Size = UDim2.new(0, IsMobile and 115 or 140, 0, 18); metaRightContainer.BackgroundTransparency = 1; metaRightContainer.LayoutOrder = 2
	local mrLay = Instance.new("UIListLayout", metaRightContainer)
	mrLay.FillDirection = Enum.FillDirection.Horizontal; mrLay.HorizontalAlignment = Enum.HorizontalAlignment.Right; mrLay.VerticalAlignment = Enum.VerticalAlignment.Center; mrLay.SortOrder = Enum.SortOrder.LayoutOrder; mrLay.Padding = UDim.new(0, 6)

	if data.TagType and data.TagType ~= "NONE" then
		local tag = Instance.new("Frame", metaRightContainer)
		tag.AutomaticSize = Enum.AutomaticSize.X; tag.Size = UDim2.new(0, 0, 0, 14)
		Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 4)
		local tPad = Instance.new("UIPadding", tag)
		tPad.PaddingLeft = UDim.new(0, 5); tPad.PaddingRight = UDim.new(0, 5)
		local tText = Instance.new("TextLabel", tag)
		tText.AutomaticSize = Enum.AutomaticSize.X; tText.Size = UDim2.new(0, 0, 1, 0)
		tText.BackgroundTransparency = 1; tText.Text = data.TagType
		tText.TextColor3 = Color3.fromRGB(255, 255, 255); tText.Font = Enum.Font.GothamBold; tText.TextSize = 9
		tag.BackgroundColor3 = (data.TagType == "HOT") and Theme.Error or (data.TagType == "UPDATED") and Theme.Success or Color3.fromRGB(100, 116, 139)
		tag.LayoutOrder = 1
	end

	local dateLbl = Instance.new("TextLabel", metaRightContainer)
	dateLbl.AutomaticSize = Enum.AutomaticSize.X; dateLbl.Size = UDim2.new(0, 0, 1, 0)
	dateLbl.BackgroundTransparency = 1; dateLbl.Text = GetRelativeTime(data.LastUpdated)
	dateLbl.TextColor3 = Theme.TextSecondary; dateLbl.Font = Enum.Font.GothamMedium
	dateLbl.TextSize = 10; dateLbl.LayoutOrder = 2; dateLbl.TextXAlignment = Enum.TextXAlignment.Right

	local descLbl = Instance.new("TextLabel", content)
	descLbl.Size = UDim2.new(1, 0, 0, 0); descLbl.AutomaticSize = Enum.AutomaticSize.Y
	descLbl.BackgroundTransparency = 1; descLbl.Text = data.Description or "No description provided."
	descLbl.TextColor3 = Theme.TextSecondary; descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 11
	descLbl.TextWrapped = true; descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.LayoutOrder = 2

	local btmRow = Instance.new("Frame", content)
	btmRow.Size = UDim2.new(1, 0, 0, 22); btmRow.BackgroundTransparency = 1; btmRow.LayoutOrder = 3
	local brLay = Instance.new("UIListLayout", btmRow)
	brLay.FillDirection = Enum.FillDirection.Horizontal; brLay.SortOrder = Enum.SortOrder.LayoutOrder; brLay.Padding = UDim.new(0, 8); brLay.VerticalAlignment = Enum.VerticalAlignment.Center

	local autoExecBtn = Instance.new("TextButton", btmRow)
	autoExecBtn.Size = UDim2.new(0, 120, 0, 22); autoExecBtn.BackgroundColor3 = Theme.BackgroundMain
	autoExecBtn.Text = ""; autoExecBtn.AutoButtonColor = false; autoExecBtn.ClipsDescendants = true; autoExecBtn.LayoutOrder = 1; autoExecBtn.ZIndex = 2
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

	ApplyInteractiveAnimations(card, Theme.Card, Theme.CardHover, Color3.fromRGB(20, 29, 45), cardStroke, Color3.fromRGB(44, 58, 77), Theme.Accent)
	ApplyInteractiveAnimations(autoExecBtn, Theme.BackgroundMain, Theme.BackgroundSecondary, Color3.fromRGB(10, 15, 30))
	ApplyInteractiveAnimations(starBtn, nil, nil, nil, nil, nil, nil)

	local exactName = data.Name or "Unnamed Script"
	local scriptEntry = {
		Instance = card, SearchTitle = exactName:lower(), SearchDesc = (data.Description or ""):lower(),
		SearchMeta = table.concat({data.Category or "", data.Author or "", data.TagType or "", table.concat(data.Tags or {}, " ")}, " "):lower(),
		ExactName = exactName, LastUpdated = data.LastUpdated, OriginalIndex = #RegisteredScripts + 1
	}

	scriptEntry.UpdateUI = function()
		local isFav = SavedData.Favorites[exactName]
		starBtn.Text = isFav and "★" or "☆"; starBtn.TextColor3 = isFav and Color3.fromRGB(250, 204, 21) or Theme.TextSecondary
		local isON = (SavedData.AutoExecutes[exactName] ~= nil)
		aeStateTxt.Text = isON and "ON" or "OFF"; aeState.BackgroundColor3 = isON and Theme.Success or Theme.Error
	end
	scriptEntry.UpdateUI()

	RegConn(starBtn.Activated:Connect(function()
		RunWithCooldown("Favorite", function()
			if isDestroying then return end
			if SavedData.Favorites[exactName] then
				SavedData.Favorites[exactName] = nil; ShowNotification("Favorite removed: " + exactName, "Info")
			else
				SavedData.Favorites[exactName] = true; ShowNotification("Favorite added: " + exactName, "Success")
			end
			SaveConfiguration(); RefreshAllCardStates(); UpdateFilter()
		end, 0.5)
	end)))

	RegConn(autoExecBtn.Activated:Connect(function()
		RunWithCooldown("Auto Execute", function()
			if isDestroying then return end
			if SavedData.AutoExecutes[exactName] then
				SavedData.AutoExecutes[exactName] = nil; ShowNotification("Auto-Execute disabled: " + exactName, "Warning")
			else
				SavedData.AutoExecutes[exactName] = {PlaceId = PlaceId}; ShowNotification("Auto-Execute enabled: " + exactName, "Success")
			end
			SaveConfiguration(); RefreshAllCardStates(); UpdateFilter()
		end, 0.5)
	end)))

	RegConn(card.Activated:Connect(function()
		RunWithCooldown("Execute", function()
			if isDestroying then return end
			local function executeScript()
				if type(loadstring) ~= "function" then
					ShowNotification("Executor lacks loadstring support!", "Error")
					return
				end

				titleLbl.Text = "Executing..."; titleLbl.TextColor3 = Theme.Accent

				task.spawn(function()
					local success, err = pcall(function()
						local raw = FetchWithRetry(data.RawUrl, 2, 1)
						if not raw then error("HTTP fetch failed.") end
						local chunk, compileErr = loadstring(raw)
						if chunk then task.spawn(chunk) else error("Compile error: " + tostring(compileErr)) end
					end)

					if success then
						ShowNotification("Script executed: " + exactName, "Success")
					else
						ShowNotification("Execution failed. See console.", "Error")
						warn("Velox Hub Execution Error: ", tostring(err))
					end
					titleLbl.Text = exactName; titleLbl.TextColor3 = Theme.TextPrimary
				end)
			end

			if SavedData.AutoExecutes[exactName] ~= nil then executeScript() else OpenConfirmDialog(exactName, executeScript) end
		end, 1)
	end))

	card.Parent = renderParent
	CacheInstanceAndDescendants(card)
	table.insert(RegisteredScripts, scriptEntry)
end

local CATALOG_URL = "https://raw.githubusercontent.com/KingBacconnnn/VeloxScripts/refs/heads/main/catalogtest.json"
local dbRefreshing = false

local function LoadDynamicCatalog()
	if dbRefreshing then return end
	RunWithCooldown("Refresh", function()
		dbRefreshing = true
		local savedScroll = ScriptsView.CanvasPosition
		StatusDot.BackgroundColor3 = Theme.Warning
		StatusText.Text = "Connecting..."
		StatusText.TextColor3 = Theme.Warning
		EmptyStateMessage.Visible = true; EmptyStateMessage.Text = "Loading script repository..."

		task.spawn(function()
			local raw = FetchWithRetry(CATALOG_URL, 3, 2)
			if raw then
				local success, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
				if success and type(parsed) == "table" then
					for _, child in ipairs(ScriptsView:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					table.clear(RegisteredScripts)

					local detachedFolder = Instance.new("Folder")
					local vMap = {}
					for _, scriptData in ipairs(parsed) do
						if type(scriptData) == "table" and scriptData.Name then
							vMap[scriptData.Name] = true
							if isDestroying then return end
							CreateScriptCard(scriptData, detachedFolder)
						end
					end

					local cleaned = false
					for k, _ in pairs(SavedData.AutoExecutes) do
						if not vMap[k] then SavedData.AutoExecutes[k] = nil; cleaned = true end
					end
					if cleaned then SaveConfiguration() end

					for _, card in ipairs(detachedFolder:GetChildren()) do card.Parent = ScriptsView end
					pcall(function() detachedFolder:Destroy() end)

					for _, scriptData in ipairs(parsed) do
						if type(scriptData) == "table" and scriptData.Name then
							local auto = SavedData.AutoExecutes[scriptData.Name]
							if auto and type(auto) == "table" and auto.PlaceId == PlaceId then
								task.spawn(function()
									local scrRaw = FetchWithRetry(scriptData.RawUrl, 2, 1)
									if scrRaw and type(loadstring) == "function" then
										local fn = loadstring(scrRaw)
										if fn then task.spawn(fn); ShowNotification("Auto-executed: " + scriptData.Name, "Success") end
									end
								end)
							end
						end
					end
					UpdateFilter()
					task.defer(function() if ScriptsView and ScriptsView.Parent then ScriptsView.CanvasPosition = savedScroll end end)
					StatusDot.BackgroundColor3 = Theme.Success; StatusText.Text = "Online"; StatusText.TextColor3 = Theme.Success
					ShowNotification("Catalog refreshed successfully.", "Success")
				else
					EmptyStateMessage.Text = "Catalog parsing error. Check console."; StatusText.Text = "Data Error"
				end
			else
				EmptyStateMessage.Text = "Unable to connect to server."; StatusText.Text = "Offline"
			end
			dbRefreshing = false
		end)
	end, 1)
end
LoadDynamicCatalog()

local function CreateSettingRow(title, desc, parent, order)
	local wrap = Instance.new("Frame", parent)
	wrap.Size = UDim2.new(1, 0, 0, IsMobile and 54 or 58); wrap.BackgroundColor3 = Theme.CardHover; wrap.LayoutOrder = order
	Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 8)
	
	local textContainer = Instance.new("Frame", wrap)
	textContainer.Size = UDim2.new(1, -135, 1, 0); textContainer.BackgroundTransparency = 1
	local tPad = Instance.new("UIPadding", textContainer)
	tPad.PaddingLeft = UDim.new(0, 12); tPad.PaddingTop = UDim.new(0, 10); tPad.PaddingBottom = UDim.new(0, 10)
	local tLay = Instance.new("UIListLayout", textContainer)
	tLay.SortOrder = Enum.SortOrder.LayoutOrder; tLay.Padding = UDim.new(0, 4)

	local t = Instance.new("TextLabel", textContainer)
	t.Size = UDim2.new(1, 0, 0, 16); t.BackgroundTransparency = 1; t.Text = title
	t.TextColor3 = Theme.TextPrimary; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextXAlignment = Enum.TextXAlignment.Left; t.LayoutOrder = 1
	
	local d = Instance.new("TextLabel", textContainer)
	d.Size = UDim2.new(1, 0, 0, 16); d.BackgroundTransparency = 1; d.Text = desc
	d.TextColor3 = Theme.TextSecondary; d.Font = Enum.Font.Gotham; d.TextSize = 11; d.TextXAlignment = Enum.TextXAlignment.Left; d.LayoutOrder = 2
	d.TextWrapped = true

	local rightContainer = Instance.new("Frame", wrap)
	rightContainer.Size = UDim2.new(0, 120, 1, 0); rightContainer.Position = UDim2.new(1, -120, 0, 0); rightContainer.BackgroundTransparency = 1
	return wrap, rightContainer
end

local function CreateToggleSetting(title, desc, parent, order, defaultValue, callback)
	local wrap, rightContainer = CreateSettingRow(title, desc, parent, order)
	
	local toggleBtn = Instance.new("TextButton", rightContainer)
	toggleBtn.Size = UDim2.new(0, 44, 0, 24); toggleBtn.Position = UDim2.new(1, -54, 0.5, -12)
	toggleBtn.BackgroundColor3 = defaultValue and Theme.Success or Theme.ToggleOff
	toggleBtn.Text = ""; toggleBtn.AutoButtonColor = false
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

	local circle = Instance.new("Frame", toggleBtn)
	circle.Size = UDim2.new(0, 18, 0, 18); circle.Position = defaultValue and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
	local state = defaultValue

	RegConn(toggleBtn.Activated:Connect(function()
		RunWithCooldown("Settings toggles", function()
			if isDestroying then return end
			state = not state
			toggleBtn.BackgroundColor3 = state and Theme.Success or Theme.ToggleOff
			SafeTween(circle, EntryTweenInfo, {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)})
			if type(callback) == "function" then task.spawn(callback, state) end
		end, 0.5)
	end)))
end

local function CreateButtonSetting(title, desc, btnText, parent, order, callback)
	local wrap, rightContainer = CreateSettingRow(title, desc, parent, order)

	local btn = Instance.new("TextButton", rightContainer)
	btn.Size = UDim2.new(0, 100, 0, 28); btn.Position = UDim2.new(1, -110, 0.5, -14)
	btn.BackgroundColor3 = Theme.BackgroundMain; btn.Text = btnText
	btn.TextColor3 = Theme.TextPrimary; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local btnStroke = Instance.new("UIStroke", btn); btnStroke.Color = Theme.Stroke
	ApplyInteractiveAnimations(btn, Theme.BackgroundMain, Theme.BackgroundSecondary, Color3.fromRGB(10, 15, 30), btnStroke, Theme.Stroke, Theme.Accent)

	RegConn(btn.Activated:Connect(function()
		RunWithCooldown("Settings toggles", function()
			if isDestroying then return end
			if type(callback) == "function" then task.spawn(callback, btn) end
		end, 0.5)
	end)))
	return btn
end

local kbWrap, kbRightContainer = CreateSettingRow("Toggle UI", "Keybind to show/hide the hub.", SettingsView, 1)
local KeybindButton = Instance.new("TextButton", kbRightContainer)
KeybindButton.Size = UDim2.new(0, 100, 0, 28); KeybindButton.Position = UDim2.new(1, -110, 0.5, -14)
KeybindButton.BackgroundColor3 = Theme.BackgroundMain; KeybindButton.Text = ToggleKeybind.Name
KeybindButton.TextColor3 = Theme.TextPrimary; KeybindButton.Font = Enum.Font.GothamMedium
KeybindButton.TextSize = 12; KeybindButton.AutoButtonColor = false
Instance.new("UICorner", KeybindButton).CornerRadius = UDim.new(0, 6)
local kbBtnStroke = Instance.new("UIStroke", KeybindButton); kbBtnStroke.Color = Theme.Stroke
KeybindButtonRef = KeybindButton
ApplyInteractiveAnimations(KeybindButton, Theme.BackgroundMain, Theme.BackgroundSecondary, Color3.fromRGB(10, 15, 30), kbBtnStroke, Theme.Stroke, Theme.Accent)

RegConn(KeybindButton.Activated:Connect(function()
	RunWithCooldown("Settings toggles", function()
		if isDestroying then return end
		IsBindingKey = true
		KeybindButton.Text = "Press Any Key..."
	end, 0.5)
end)))

CreateToggleSetting("Anti-AFK", "Prevents getting disconnected for being idle.", SettingsView, 2, SavedData.Settings.AntiAFK, function(val)
	SavedData.Settings.AntiAFK = val
	SaveConfiguration()
	if val then
		if not AfkConnections.Idled then
			AfkConnections.Idled = RegConn(LocalPlayer.Idled:Connect(function()
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
				task.wait(0.1)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
			end))
		end
		if getconnections then
			for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
				if type(conn) == "table" and conn.Disable then
					conn:Disable(); AfkConnections[conn] = conn
				end
			end
		end
	else
		if AfkConnections.Idled then AfkConnections.Idled:Disconnect(); AfkConnections.Idled = nil end
		for conn, _ in pairs(AfkConnections) do
			if type(conn) == "table" and conn.Enable then pcall(function() conn:Enable() end) end
		end
	end
end)

CreateButtonSetting("Refresh Catalog", "Forces an update to the script list.", "Refresh", SettingsView, 3, function() LoadDynamicCatalog() end)
CreateButtonSetting("Unload Hub", "Removes Velox Hub entirely from the game.", "Unload", SettingsView, 4, function() CloseUI() end)

if SavedData.Settings.AntiAFK then
	if not AfkConnections.Idled then
		AfkConnections.Idled = RegConn(LocalPlayer.Idled:Connect(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
			task.wait(0.1)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
		end))
	end
	if getconnections then
		for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
			if type(conn) == "table" and conn.Disable then
				conn:Disable(); AfkConnections[conn] = conn
			end
		end
	end
end

local function ObfuscateHierarchy(instance)
	for _, child in ipairs(instance:GetDescendants()) do
		if child:IsA("GuiObject") or child:IsA("UIComponent") or child:IsA("Folder") then
			child.Name = GenerateRandomString(15)
		end
	end
end
ObfuscateHierarchy(ScreenGui)

TabViews["Changelogs"].Visible = true
TabViews["Scripts"].Visible = false
TabViews["Settings"].Visible = false
TabIndicator.Position = UDim2.new(0, 4, 1, -2)

CacheInstanceAndDescendants(MainPanel)
CacheInstanceAndDescendants(FloatingBtn)
CacheInstanceAndDescendants(ConfirmOverlay)

ShowNotification("Velox Hub loaded successfully.", "Success")
