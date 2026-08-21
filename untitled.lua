local State = {}
State.GlobalEnv = _G
if type(getgenv) == "function" then
	local ok, env = pcall(getgenv)
	if ok and type(env) == "table" then
		State.GlobalEnv = env
	end
end

function State.ProtectTable(tbl)
	local secure_func = type(newcclosure) == "function" and newcclosure or function(f) return f end
	local proxy = setmetatable({}, {
		__index = secure_func(function(_, key)
			return tbl[key]
		end),
		__newindex = secure_func(function(_, k, v)

		end),
		__metatable = "Locked_Environment",
		__tostring = secure_func(function() return " " end),
		__mode = "v"
	})

	if type(setreadonly) == "function" then pcall(setreadonly, proxy, true) end
	if type(table.freeze) == "function" then pcall(table.freeze, proxy) end

	return proxy
end

function State.GenerateRandomString(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local zwc = {"\226\128\139", "\226\128\140", "\226\128\141"}
	local str = ""
	for i = 1, len do
		local r = math.random(1, #chars)
		str = str .. string.sub(chars, r, r)

		if math.random(1, 3) == 1 then
			str = str .. zwc[math.random(1, #zwc)]
		end
	end
	return str
end

State._G_Identifier = "VeloxHub_Core_Cleanup_" .. State.GenerateRandomString(8)
State.MainGuiName = "Velox_" .. State.GenerateRandomString(16)
State.FloatBtnName = "VeloxFloat_" .. State.GenerateRandomString(16)

if State.GlobalEnv[State._G_Identifier] then
	pcall(function() State.GlobalEnv[State._G_Identifier]() end)
end

State.Services = State.ProtectTable(setmetatable({}, {
	__index = function(self, key)
		local success, service = pcall(function() return game:GetService(key) end)
		if success and service then
			local final = (type(cloneref) == "function") and cloneref(service) or service
			self[key] = final
			return final
		end
		return nil
	end
}))

State.Players = State.Services.Players
State.UserInputService = State.Services.UserInputService
State.HttpService = State.Services.HttpService
State.VirtualInputManager = State.Services.VirtualInputManager
State.VirtualUser = State.Services.VirtualUser
State.StarterGui = State.Services.StarterGui
State.RunService = State.Services.RunService
State.Stats = State.Services.Stats
State.CoreGui = State.Services.CoreGui
State.TweenService = State.Services.TweenService
State.GuiService = State.Services.GuiService

State.LocalPlayer = State.Players.LocalPlayer
while not State.LocalPlayer do
	task.wait()
	State.LocalPlayer = State.Players.LocalPlayer
end

State.PlaceId = game.PlaceId

function State.GetAdvancedExecutor()
	local name, version = "Unknown Executor", ""

	if type(identifyexecutor) == "function" then
		local extName, extVer = identifyexecutor()
		name = extName or name
		version = extVer or version
	elseif type(getexecutorname) == "function" then
		name = getexecutorname()
	else
		local env = type(getgenv) == "function" and getgenv() or _G
		if env.Delta then name = "Delta"
		elseif env.arceus then name = "Arceus X"
		elseif env.codex then name = "Codex"
		elseif env.wave then name = "Wave"
		elseif env.macsploit then name = "Macsploit"
		elseif env.RoExec then name = "RoExec (Krampus)"
		elseif syn and type(syn) == "table" and not syn.toast_notification then name = "Synapse Z"
		elseif syn then name = "Synapse X"
		elseif krnl then name = "Krnl"
		elseif fluxus then name = "Fluxus"
		elseif is_sirhurt_closure then name = "SirHurt"
		end
	end

	version = string.gsub(tostring(version), "\n", "")
	return name .. (version ~= "" and (" (" .. version .. ")") or "")
end

State.RuntimeEnv = type(getgenv) == "function" and getgenv() or _G

State.gethui = type(gethui) == "function" and gethui or nil

State.protectgui = nil
if type(syn) == "table" and type(syn.protect_gui) == "function" then
	State.protectgui = syn.protect_gui
elseif type(State.protectgui) == "function" then
	State.protectgui = State.protectgui
else
	State.protectgui = function(gui)
		return gui
	end
end

function State.ResolveFunction(names, containers)
	for _, container in ipairs(containers) do
		if type(container) == "table" then
			for _, name in ipairs(names) do
				local candidate = rawget(container, name)
				if type(candidate) == "function" then
					return candidate
				end
			end
		end
	end
	for _, name in ipairs(names) do
		local candidate = rawget(State.RuntimeEnv, name) or rawget(_G, name)
		if type(candidate) == "function" then
			return candidate
		end
	end
	return nil
end

State.exec_request = State.ResolveFunction(
	{"request", "http_request"},
	{
		State.RuntimeEnv,
		_G,
		type(syn) == "table" and syn or nil,
		type(fluxus) == "table" and fluxus or nil,
		type(krnl) == "table" and krnl or nil,
		type(http) == "table" and http or nil
	}
)

State.getexecutor = State.GetAdvancedExecutor
State.write_file = type(writefile) == "function" and writefile or nil
State.read_file = type(readfile) == "function" and readfile or nil
State.is_file = type(isfile) == "function" and isfile or nil
State.del_file = type(delfile) == "function" and delfile or nil

State.CompileFunction = State.ResolveFunction(
	{"loadstring", "load", "luau_load"},
	{State.RuntimeEnv, _G}
)

function State.CompileChunk(source, chunkName)
	if type(State.CompileFunction) ~= "function" then
		return nil, "no compatible Lua compiler"
	end

	local ok, chunk, err = pcall(State.CompileFunction, source, chunkName)
	if ok and type(chunk) == "function" then
		return chunk
	end

	local okOneArg, chunkOneArg, errOneArg = pcall(State.CompileFunction, source)
	if okOneArg and type(chunkOneArg) == "function" then
		return chunkOneArg
	end

	return nil, tostring(errOneArg or err or chunk or chunkOneArg or "compiler error")
end

State.Theme = {
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

State.VeloxConnections = {}
State.CardConnections = {}
State.RegisteredScripts = {}
State.AfkConnections = {}
State.PendingTasks = {}
State.ActiveTweens = setmetatable({}, { __mode = "k" })
State.CatalogGeneration = 0
State.CatalogRefreshCooldown = 5
State.LastCatalogRefreshAt = 0
State.AutoExecuteRanThisSession = false
State.InteractiveElements = setmetatable({}, { __mode = "k" })

State.isDestroying = false
State.isMinimized = false
State.isTransitioning = false
State.IsBindingKey = false
State.IsMobile = State.UserInputService.TouchEnabled and (not State.UserInputService.MouseEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y <= 800) or State.GuiService:IsTenFootInterface())

State.mainDragConnection, State.floatDragConnection = nil, nil
State.activeMainDragInput, State.activeFloatDragInput = nil, nil
State.ToggleKeybindConnection = nil
State.KeybindCaptureConnection = nil
State.DropdownContainer = nil
State.ToastContainer = nil
State.ConfirmOverlay = nil

State.GlobalCooldownBanner = nil
State.GlobalCooldownLoopVersion = 0
State.GlobalActionCooldownEndTime = 0

State.OriginalCache = setmetatable({}, { __mode = "k" })

function State.CacheInstanceAndDescendants(root)
	local function CacheObj(obj)
		if not obj or State.OriginalCache[obj] then return end
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
		State.OriginalCache[obj] = c
	end
	CacheObj(root)
	for _, desc in ipairs(root:GetDescendants()) do
		CacheObj(desc)
	end
end

function State.RegConn(connection)
	if connection and typeof(connection) == "RBXScriptConnection" then
		table.insert(State.VeloxConnections, connection)
	end
	return connection
end

function State.UnregConn(connection)
	if not connection then return end
	for i = #State.VeloxConnections, 1, -1 do
		if State.VeloxConnections[i] == connection then
			table.remove(State.VeloxConnections, i)
			break
		end
	end
	if typeof(connection) == "RBXScriptConnection" and connection.Connected then
		pcall(function() connection:Disconnect() end)
	end
end

function State.RegCardConn(connection)
	if connection and typeof(connection) == "RBXScriptConnection" then
		table.insert(State.CardConnections, connection)
	end
	return connection
end

function State.TrackTask(fn)
	local thread
	thread = task.spawn(function()
		pcall(fn)
		State.PendingTasks[thread] = nil
	end)
	State.PendingTasks[thread] = true
	return thread
end

function State.IsTaskCurrent(generation)
	return not State.isDestroying and generation == State.CatalogGeneration
end

function State.CancelTrackedTasks()
	for thread in pairs(State.PendingTasks) do
		if type(thread) == "thread" then pcall(task.cancel, thread) end
	end
	table.clear(State.PendingTasks)
end

State.typingTask = nil

function State.CleanUpMemory()
	State.isDestroying = true
	State.GlobalEnv[State._G_Identifier] = nil
	if State.typingTask then task.cancel(State.typingTask); State.typingTask = nil end

	State.CancelTrackedTasks()

	if State.mainDragConnection then pcall(function() State.mainDragConnection:Disconnect() end) end
	if State.floatDragConnection then pcall(function() State.floatDragConnection:Disconnect() end) end
	if State.ToggleKeybindConnection then State.UnregConn(State.ToggleKeybindConnection); State.ToggleKeybindConnection = nil end
	if State.KeybindCaptureConnection then State.UnregConn(State.KeybindCaptureConnection); State.KeybindCaptureConnection = nil end

	for _, conn in ipairs(State.VeloxConnections) do
		if typeof(conn) == "RBXScriptConnection" and conn.Connected then
			conn:Disconnect()
		end
	end
	for _, conn in ipairs(State.CardConnections) do
		if typeof(conn) == "RBXScriptConnection" and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(State.VeloxConnections)
	table.clear(State.CardConnections)
	for _, conn in pairs(State.AfkConnections) do
		if type(conn) == "table" and conn.Enable then pcall(function() conn:Enable() end)
		elseif typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
	end
	for _, tweenData in pairs(State.ActiveTweens) do
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
	if State.DropdownContainer and State.DropdownContainer.Parent then pcall(function() State.DropdownContainer:Destroy() end) end
	if State.ToastContainer and State.ToastContainer.Parent then pcall(function() State.ToastContainer:Destroy() end) end
	if State.ConfirmOverlay and State.ConfirmOverlay.Parent then pcall(function() State.ConfirmOverlay:Destroy() end) end
	if State.GlobalCooldownBanner and State.GlobalCooldownBanner.Parent then pcall(function() State.GlobalCooldownBanner:Destroy() end) end

	table.clear(State.RegisteredScripts)
	table.clear(State.AfkConnections)
	table.clear(State.ActiveTweens)
	table.clear(State.InteractiveElements)
	table.clear(State.OriginalCache)
end

function State.SafeTween(instance, tweenInfo, properties)
	if not instance or not instance.Parent then return nil end
	if State.ActiveTweens[instance] then
		local oldData = State.ActiveTweens[instance]
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
	local tween = State.TweenService:Create(instance, tweenInfo, properties)
	local conn
	conn = tween.Completed:Connect(function()
		if conn then conn:Disconnect() end
		if State.ActiveTweens[instance] and State.ActiveTweens[instance].Tween == tween then
			State.ActiveTweens[instance] = nil
		end
		pcall(function() tween:Destroy() end)
	end)
	State.ActiveTweens[instance] = { Tween = tween, Connection = conn }
	tween:Play()
	return tween
end

function State.CreateDebounce(cooldown, func)
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

State.DATA_FILE = ".VeloxHub_Data_V3.1.json"
State.TEMP_FILE = ".VeloxHub_Data_Temp.json"
State.SavedData = {
	Favorites = {},
	AutoExecutes = {},
	ToggleKeybind = "RightControl",
	Settings = { AntiAFK = false }
}

State.isSaving = false
State.saveQueued = false

function State.SanitizeForJSON(data)
	if type(data) == "table" then
		local clean = {}
		for k, v in pairs(data) do
			if type(k) == "string" or type(k) == "number" then
				local cleanVal = State.SanitizeForJSON(v)
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

function State.SaveConfiguration()
	if type(State.write_file) ~= "function" then return end
	if State.isSaving then
		State.saveQueued = true
		return
	end
	State.isSaving = true
	task.spawn(function()
		local cleanData = {
			Favorites = {}, AutoExecutes = {},
			ToggleKeybind = tostring(State.SavedData.ToggleKeybind or "RightControl"),
			Settings = { AntiAFK = State.SavedData.Settings.AntiAFK == true }
		}
		for k, v in pairs(State.SavedData.Favorites) do if v then cleanData.Favorites[tostring(k)] = true end end
		for k, v in pairs(State.SavedData.AutoExecutes) do
			if type(v) == "table" then
				cleanData.AutoExecutes[tostring(k)] = {
					PlaceId = tonumber(v.PlaceId) or game.PlaceId,
					GameId = tonumber(v.GameId) or game.GameId
				}
			end
		end

		local safeData = State.SanitizeForJSON(cleanData)
		local success, result = pcall(function() return State.HttpService:JSONEncode(safeData) end)
		if success then
			local writeSuccess = pcall(function() State.write_file(State.TEMP_FILE, result) end)
			if writeSuccess then
				local verifySuccess = pcall(function()
					local check = State.read_file(State.TEMP_FILE)
					return State.HttpService:JSONDecode(check)
				end)
				if verifySuccess then
					pcall(function() State.write_file(State.DATA_FILE, result) end)
				end
			end
			if State.del_file then
				pcall(function() State.del_file(State.TEMP_FILE) end)
			end
		end
		State.isSaving = false
		if State.saveQueued then
			State.saveQueued = false
			State.SaveConfiguration()
		end
	end)
end

function State.LoadConfiguration()
	if type(State.is_file) == "function" and type(State.read_file) == "function" and State.is_file(State.DATA_FILE) then
		local success, result = pcall(function() return State.HttpService:JSONDecode(State.read_file(State.DATA_FILE)) end)
		if success and type(result) == "table" then
			if type(result.Favorites) == "table" then
				for k, _ in pairs(result.Favorites) do State.SavedData.Favorites[tostring(k)] = true end
			end
			if type(result.AutoExecutes) == "table" then
				for k, v in pairs(result.AutoExecutes) do
					if type(k) == "string" and type(v) == "table" then
						State.SavedData.AutoExecutes[tostring(k)] = {
							PlaceId = type(v.PlaceId) == "number" and v.PlaceId or game.PlaceId,
							GameId = type(v.GameId) == "number" and v.GameId or nil
						}
					end
				end
			end
			if type(result.ToggleKeybind) == "string" then State.SavedData.ToggleKeybind = result.ToggleKeybind end
			if type(result.Settings) == "table" then
				for k, _ in pairs(result.Settings) do
					if result.Settings[k] ~= nil then State.SavedData.Settings[k] = result.Settings[k] end
				end
			end
		else
			State.SaveConfiguration()
		end
	end
end
State.LoadConfiguration()

function State.UniversalHttpGet(url)
	if type(url) ~= "string" or url == "" then
		return nil
	end

	if type(State.exec_request) == "function" then
		local ok, result = pcall(function()
			return State.exec_request({
				Url = url,
				Method = "GET",
				Headers = {
					["Cache-Control"] = "no-cache"
				}
			})
		end)

		if ok and type(result) == "table" then
			local body = result.Body or result.body or result.Response or result.response
			local status = result.StatusCode or result.Status or result.status_code or result.statusCode
			if type(body) == "string" and #body > 0 and (status == nil or tonumber(status) == nil or tonumber(status) >= 200 and tonumber(status) < 400) then
				return body
			end
		end
	end

	if game and type(game.HttpGet) == "function" then
		local ok, result = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(result) == "string" and #result > 0 then
			return result
		end

		local okDot, resultDot = pcall(function()
			return game.HttpGet(game, url)
		end)
		if okDot and type(resultDot) == "string" and #resultDot > 0 then
			return resultDot
		end
	end

	if State.HttpService and type(State.HttpService.GetAsync) == "function" then
		local ok, result = pcall(function()
			return State.HttpService:GetAsync(url, false)
		end)
		if ok and type(result) == "string" and #result > 0 then
			return result
		end
	end

	return nil
end

function State.AddCacheBuster(url)
	if type(url) ~= "string" or url == "" then return url end
	local separator = string.find(url, "?", 1, true) and "&" or "?"
	local nonce = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
	return url .. separator .. "velox_cache=" .. nonce
end

function State.FetchWithRetry(url, retries, cacheBust)
	retries = retries or 3
	for i = 1, retries do
		local requestUrl = url
		if cacheBust then
			requestUrl = State.AddCacheBuster(url)
		end

		local response = State.UniversalHttpGet(requestUrl)
		if response and type(response) == "string" and #response > 0 then
			return response
		end

		if i < retries then
			task.wait(math.pow(2, i))
		end
	end
	return nil
end

State.TagTypeConfig = {
	UPDATED = {
		Priority = 5,
		BadgeColor = State.Theme.Success,
		CardColor = Color3.fromRGB(25, 44, 42),
		HoverColor = Color3.fromRGB(31, 55, 51),
		StrokeColor = Color3.fromRGB(58, 122, 106)
	},
	HOT = {
		Priority = 4,
		BadgeColor = State.Theme.Error,
		CardColor = Color3.fromRGB(43, 31, 37),
		HoverColor = Color3.fromRGB(57, 38, 46),
		StrokeColor = Color3.fromRGB(116, 67, 80)
	},
	NEW = {
		Priority = 3,
		BadgeColor = State.Theme.Info,
		CardColor = Color3.fromRGB(27, 38, 47),
		HoverColor = Color3.fromRGB(35, 49, 60),
		StrokeColor = Color3.fromRGB(62, 102, 126)
	},
	FEATURED = {
		Priority = 2,
		BadgeColor = State.Theme.System,
		CardColor = Color3.fromRGB(39, 32, 48),
		HoverColor = Color3.fromRGB(51, 40, 63),
		StrokeColor = Color3.fromRGB(92, 72, 117)
	},
	NONE = {
		Priority = 1,
		BadgeColor = Color3.fromRGB(100, 116, 139),
		CardColor = State.Theme.Card,
		HoverColor = State.Theme.CardHover,
		StrokeColor = Color3.fromRGB(44, 58, 77)
	}
}

function State.NormalizeTagType(value)
	if type(value) ~= "string" then return "NONE" end
	local normalized = string.upper(string.gsub(value, "^%s*(.-)%s*$", "%1"))
	if State.TagTypeConfig[normalized] then return normalized end
	return "NONE"
end

function State.GetOrCreateCardStroke(card)
	if not card or not card:IsA("GuiObject") then return nil end
	local stroke = card:FindFirstChild("TagTypeStroke")
	if stroke and stroke:IsA("UIStroke") then return stroke end
	if stroke then pcall(function() stroke:Destroy() end) end
	stroke = Instance.new("UIStroke")
	stroke.Name = "TagTypeStroke"
	stroke.Parent = card
	return stroke
end

function State.ApplyTagBorder(card, tagType, stroke)
	if not card or not card.Parent then return end
	stroke = stroke or State.GetOrCreateCardStroke(card)
	if not stroke or not stroke.Parent then return end

	local normalized = State.NormalizeTagType(tagType)
	local config = State.TagTypeConfig[normalized] or State.TagTypeConfig.NONE
	stroke.Color = config.StrokeColor
	stroke.Transparency = 0
	stroke.Enabled = true
end

function State.GetSafeTimestamp(value)
	local timestamp = tonumber(value)
	if type(timestamp) ~= "number" or timestamp ~= timestamp then return 0 end
	return timestamp
end

function State.GetRelativeTime(timestamp)
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

function State.GetSecureParent()
	local huiSuccess, huiTarget = pcall(function() return State.gethui() end)
	if huiSuccess and huiTarget and typeof(huiTarget) == "Instance" then
		return huiTarget
	end

	local coreSuccess, coreTarget = pcall(function() return State.CoreGui end)
	if coreSuccess and coreTarget then

		local container = Instance.new("Folder")
		container.Name = State.GenerateRandomString(16)

		local accessSuccess = pcall(function()
			local robloxGui = coreTarget:FindFirstChild("RobloxGui")
			if robloxGui then
				container.Parent = robloxGui
			else
				container.Parent = coreTarget
			end
		end)

		if accessSuccess then return container end
	end

	if State.LocalPlayer then
		local playerGui = State.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then return playerGui end
	end

	return nil
end

State.TargetParent = State.GetSecureParent()
if not State.TargetParent then return end

State.existingGui = State.TargetParent:FindFirstChild(State.MainGuiName)
if State.existingGui then pcall(function() State.existingGui:Destroy() end) end

State.ScreenGui = Instance.new("ScreenGui")
State.ScreenGui.Name = State.MainGuiName
State.ScreenGui.ResetOnSpawn = false
State.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
State.ScreenGui.IgnoreGuiInset = true
State.ScreenGui.DisplayOrder = 100
State.ScreenGui.Parent = State.TargetParent
pcall(function() State.protectgui(State.ScreenGui) end)

State.GlobalEnv[State._G_Identifier] = function()
	State.CleanUpMemory()
	if State.ScreenGui and State.ScreenGui.Parent then State.ScreenGui:Destroy() end
end

State.PANEL_SIZE = State.IsMobile and UDim2.new(0, 480, 0, 360) or UDim2.new(0, 560, 0, 515)

function State.ApplyInteractiveAnimations(gui, originalColor, hoverColor, clickColor, strokeObj, originalStroke, hoverStroke, connectionRegistry)
	if not gui:IsA("GuiObject") then return end
	connectionRegistry = connectionRegistry or State.VeloxConnections
	State.InteractiveElements[gui] = {BaseColor = originalColor, BaseStroke = originalStroke, StrokeObj = strokeObj}

	local function RegInteractive(connection)
		if connectionRegistry == State.CardConnections then
			return State.RegCardConn(connection)
		end
		return State.RegConn(connection)
	end

	RegInteractive(gui.MouseEnter:Connect(function()
		if State.isDestroying or State.isTransitioning or State.IsMobile then return end
		if originalColor and hoverColor then gui.BackgroundColor3 = hoverColor end
		if strokeObj and hoverStroke then strokeObj.Color = hoverStroke end
	end))
	RegInteractive(gui.MouseLeave:Connect(function()
		if State.isDestroying or State.isTransitioning or State.IsMobile then return end
		if originalColor then gui.BackgroundColor3 = originalColor end
		if strokeObj and originalStroke then strokeObj.Color = originalStroke end
	end))
	RegInteractive(gui.InputBegan:Connect(function(input)
		if State.isDestroying or State.isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if clickColor then gui.BackgroundColor3 = clickColor end
		end
	end))
	RegInteractive(gui.InputEnded:Connect(function(input)
		if State.isDestroying or State.isTransitioning then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not State.IsMobile and hoverColor then
				gui.BackgroundColor3 = hoverColor
			elseif originalColor then
				gui.BackgroundColor3 = originalColor
			end
		end
	end))
end

State.RegConn(State.UserInputService.WindowFocusReleased:Connect(function()
	if State.isDestroying then return end
	for element, data in pairs(State.InteractiveElements) do
		if element and element.Parent then
			if data.BaseColor then pcall(function() element.BackgroundColor3 = data.BaseColor end) end
			if data.StrokeObj and data.BaseStroke then pcall(function() data.StrokeObj.Color = data.BaseStroke end) end
		end
	end
end))

State.FloatingBtn = Instance.new("ImageButton", State.ScreenGui)
State.FloatingBtn.Name = State.FloatBtnName
State.FloatingBtn.AnchorPoint = Vector2.new(0.5, 0.5)
State.FloatingBtn.Position = UDim2.new(0.5, 0, 0, 42.5)
State.FloatingBtn.Size = UDim2.new(0, 45, 0, 45)
State.FloatingBtn.BackgroundColor3 = State.Theme.BackgroundMain
State.FloatingBtn.Image = "rbxassetid://124635602201411"
State.FloatingBtn.ScaleType = Enum.ScaleType.Fit
State.FloatingBtn.Visible = false
State.FloatingBtn.ZIndex = 100
State.FloatingBtn.Active = true
State.FloatingBtn.AutoButtonColor = false

State.FloatPadding = Instance.new("UIPadding", State.FloatingBtn)
State.FloatPadding.PaddingLeft = UDim.new(0, 6); State.FloatPadding.PaddingRight = UDim.new(0, 6)
State.FloatPadding.PaddingTop = UDim.new(0, 6); State.FloatPadding.PaddingBottom = UDim.new(0, 6)
Instance.new("UICorner", State.FloatingBtn).CornerRadius = UDim.new(1, 0)
State.FloatStroke = Instance.new("UIStroke", State.FloatingBtn)
State.FloatStroke.Color = State.Theme.Accent; State.FloatStroke.Thickness = 2

State.floatStart, State.floatPos = nil, nil
State.RegConn(State.FloatingBtn.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not State.activeFloatDragInput then
		State.activeFloatDragInput = input
		State.floatStart = input.Position
		State.floatPos = State.FloatingBtn.Position

		if State.floatDragConnection then State.floatDragConnection:Disconnect() end
		State.floatDragConnection = State.RegConn(State.UserInputService.InputChanged:Connect(function(moveInput)
			if State.isDestroying then return end
			if moveInput == State.activeFloatDragInput or moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = moveInput.Position - State.floatStart
				local camera = workspace.CurrentCamera
				local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
				local targetX = State.floatPos.X.Scale * viewport.X + State.floatPos.X.Offset + delta.X
				local targetY = State.floatPos.Y.Scale * viewport.Y + State.floatPos.Y.Offset + delta.Y
				local halfX = State.FloatingBtn.AbsoluteSize.X * State.FloatingBtn.AnchorPoint.X
				local halfY = State.FloatingBtn.AbsoluteSize.Y * State.FloatingBtn.AnchorPoint.Y
				targetX = math.clamp(targetX, halfX, viewport.X - (State.FloatingBtn.AbsoluteSize.X - halfX))
				targetY = math.clamp(targetY, halfY, viewport.Y - (State.FloatingBtn.AbsoluteSize.Y - halfY))
				State.FloatingBtn.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end))

State.MainPanel = Instance.new("Frame", State.ScreenGui)
State.MainPanel.Size = State.PANEL_SIZE
State.MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
State.MainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
State.MainPanel.BackgroundColor3 = State.Theme.BackgroundMain
State.MainPanel.BorderSizePixel = 0
State.MainPanel.ClipsDescendants = true
State.MainPanel.Visible = true
State.MainPanel.Active = true
State.MainPanel.ZIndex = 1

State.MainModalBtn = Instance.new("TextButton", State.MainPanel)
State.MainModalBtn.Size = UDim2.new(0, 0, 0, 0)
State.MainModalBtn.Visible = true
State.MainModalBtn.Modal = true
State.MainModalBtn.Text = ""

State.MainGradient = Instance.new("UIGradient", State.MainPanel)
State.MainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, State.Theme.BackgroundMain),
	ColorSequenceKeypoint.new(1, State.Theme.BackgroundSecondary)
})
State.MainGradient.Rotation = 45

State.PanelGroup = Instance.new("Frame", State.MainPanel)
State.PanelGroup.Size = UDim2.new(1, 0, 1, 0)
State.PanelGroup.BackgroundTransparency = 1
State.PanelGroup.Active = false

Instance.new("UICorner", State.MainPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", State.MainPanel).Color = State.Theme.Stroke

State.SearchInput = nil

function State.RestoreCachedProperties()
	for obj, c in pairs(State.OriginalCache) do
		if obj and obj.Parent then
			if c.BackgroundTransparency ~= nil then pcall(function() obj.BackgroundTransparency = c.BackgroundTransparency end) end
			if c.TextTransparency ~= nil then pcall(function() obj.TextTransparency = c.TextTransparency end) end
			if c.ImageTransparency ~= nil then pcall(function() obj.ImageTransparency = c.ImageTransparency end) end
			if c.ScrollBarImageTransparency ~= nil then pcall(function() obj.ScrollBarImageTransparency = c.ScrollBarImageTransparency end) end
			if c.Transparency ~= nil then pcall(function() obj.Transparency = c.Transparency end) end
			if obj == State.MainPanel or obj == State.FloatingBtn or obj == State.FloatStroke then
				if c.Size ~= nil then pcall(function() obj.Size = c.Size end) end
				if c.Position ~= nil then pcall(function() obj.Position = c.Position end) end
				if c.AnchorPoint ~= nil then pcall(function() obj.AnchorPoint = c.AnchorPoint end) end
			end
		end
	end
end

function State.ToggleUI()
	if State.isDestroying or State.isTransitioning then return end
	State.isTransitioning = true

	if State.DropdownContainer and State.DropdownContainer.Visible then
		State.DropdownContainer.Visible = false
	end

	if not State.isMinimized then
		State.isMinimized = true
		if State.SearchInput and State.SearchInput.Parent then pcall(function() State.SearchInput:ReleaseFocus() end) end

		State.MainPanel.Visible = false
		State.RestoreCachedProperties()
		State.FloatingBtn.Visible = true
		State.FloatingBtn.Size = UDim2.new(0, 45, 0, 45)
		State.FloatingBtn.ImageTransparency = 0
		State.FloatStroke.Transparency = 0
	else
		State.isMinimized = false
		State.FloatingBtn.Visible = false
		State.MainPanel.Visible = true
		State.RestoreCachedProperties()
	end

	State.isTransitioning = false
end

State.ToastContainer = Instance.new("Frame", State.ScreenGui)
State.ToastContainer.Name = "ToastContainer"
State.ToastContainer.Size = UDim2.new(0, State.IsMobile and 240 or 320, 1, -40)
State.ToastContainer.Position = UDim2.new(1, State.IsMobile and -250 or -330, 0, 20)
State.ToastContainer.BackgroundTransparency = 1
State.ToastContainer.ZIndex = 2000

State.ToastLayout = Instance.new("UIListLayout", State.ToastContainer)
State.ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
State.ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
State.ToastLayout.Padding = UDim.new(0, 8)

State.NOTIF_DURATION = 3.5

function State.EmergencyFallbackNotification(msg, title)
	pcall(function()
		if State.StarterGui and type(State.StarterGui.SetCore) == "function" then
			State.StarterGui:SetCore("SendNotification", {
				Title = title or "Velox Hub Notice",
				Text = tostring(msg),
				Duration = State.NOTIF_DURATION
			})
		end
	end)
end

function State.StandaloneBannerNotification(msg, notifType)
	local parent = State.GetSecureParent()
	if not parent then
		State.EmergencyFallbackNotification(msg, notifType)
		return
	end

	local success = pcall(function()
		local bannerGui = Instance.new("ScreenGui")
		bannerGui.Name = "VeloxBanner_" .. State.GenerateRandomString(8)
		bannerGui.DisplayOrder = 9999
		bannerGui.ResetOnSpawn = false
		bannerGui.Parent = parent

		local frame = Instance.new("Frame", bannerGui)
		frame.Size = UDim2.new(0, State.IsMobile and 260 or 340, 0, 45)
		frame.Position = UDim2.new(0.5, 0, 0, -60)
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.BackgroundColor3 = State.Theme.BackgroundSecondary
		frame.BorderSizePixel = 0
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = State.Theme[notifType] or State.Theme.Info
		stroke.Thickness = 1.5

		local txt = Instance.new("TextLabel", frame)
		txt.Size = UDim2.new(1, -20, 1, 0)
		txt.Position = UDim2.new(0, 10, 0, 0)
		txt.BackgroundTransparency = 1
		txt.Text = tostring(msg)
		txt.TextColor3 = State.Theme.TextPrimary
		txt.Font = Enum.Font.GothamMedium
		txt.TextSize = State.IsMobile and 11 or 13
		txt.TextWrapped = true

		State.TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 20)
		}):Play()

		task.delay(State.NOTIF_DURATION, function()
			local outro = State.TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -60)
			})
			outro:Play()
			outro.Completed:Connect(function()
				bannerGui:Destroy()
			end)
		end)
	end)

	if not success then
		State.EmergencyFallbackNotification(msg, notifType)
	end
end

function State.ShowNotification(msg, notifType)
	if State.isDestroying then return end

	local nType = type(notifType) == "boolean" and (notifType and "Success" or "Error") or (notifType or "Info")
	local indicatorColor = State.Theme[nType] or State.Theme.Info

	if not State.ToastContainer or not State.ToastContainer.Parent then
		State.StandaloneBannerNotification(msg, nType)
		return
	end

	local success = pcall(function()
		local wrapper = Instance.new("Frame", State.ToastContainer)
		wrapper.Size = UDim2.new(1, 0, 0, 0)
		wrapper.AutomaticSize = Enum.AutomaticSize.Y
		wrapper.BackgroundTransparency = 1
		wrapper.ZIndex = 2001

		local box = Instance.new("Frame", wrapper)
		box.Size = UDim2.new(1, 0, 0, 0)
		box.AutomaticSize = Enum.AutomaticSize.Y
		box.BackgroundColor3 = State.Theme.CardHover
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
		txt.TextColor3 = State.Theme.TextPrimary; txt.Font = Enum.Font.GothamMedium
		txt.TextSize = State.IsMobile and 11 or 13; txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.TextWrapped = true; txt.ZIndex = 2003

		local introTween = State.TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
		introTween:Play()

		task.delay(State.NOTIF_DURATION, function()
			if not wrapper or not wrapper.Parent then return end
			local outroTween = State.TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0, 0)})
			outroTween:Play()
			local conn
			conn = outroTween.Completed:Connect(function()
				if conn then conn:Disconnect() end
				if wrapper and wrapper.Parent then wrapper:Destroy() end
			end)
		end)
	end)

	if not success then
		State.StandaloneBannerNotification(msg, nType)
	end
end

function State.AttemptActionWithCooldown(actionFunc)
	local now = tick()
	if now < State.GlobalActionCooldownEndTime then
		if not State.GlobalCooldownBanner or not State.GlobalCooldownBanner.Parent then
			State.GlobalCooldownLoopVersion = State.GlobalCooldownLoopVersion + 1
			local currentLoop = State.GlobalCooldownLoopVersion

			local parent = State.GetSecureParent()
			if not parent then return end

			local bannerGui = Instance.new("ScreenGui")
			bannerGui.Name = "VeloxCooldown_" .. State.GenerateRandomString(8)
			bannerGui.DisplayOrder = 10000
			bannerGui.ResetOnSpawn = false
			bannerGui.Parent = parent
			State.GlobalCooldownBanner = bannerGui

			local frame = Instance.new("Frame", bannerGui)
			frame.Size = UDim2.new(0, State.IsMobile and 280 or 340, 0, 45)
			frame.Position = UDim2.new(0.5, 0, 0, -60)
			frame.AnchorPoint = Vector2.new(0.5, 0)
			frame.BackgroundColor3 = State.Theme.BackgroundSecondary
			frame.BorderSizePixel = 0
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

			local stroke = Instance.new("UIStroke", frame)
			stroke.Color = State.Theme.Warning
			stroke.Thickness = 1.5

			local txt = Instance.new("TextLabel", frame)
			txt.Size = UDim2.new(1, -20, 1, 0)
			txt.Position = UDim2.new(0, 10, 0, 0)
			txt.BackgroundTransparency = 1
			txt.TextColor3 = State.Theme.TextPrimary
			txt.Font = Enum.Font.GothamMedium
			txt.TextSize = State.IsMobile and 11 or 13
			txt.TextWrapped = true

			State.TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 20)
			}):Play()

			task.spawn(function()
				while currentLoop == State.GlobalCooldownLoopVersion do
					local rem = math.ceil(State.GlobalActionCooldownEndTime - tick())
					if rem > 1 then
						if txt and txt.Parent then txt.Text = "Please try again in " .. rem .. " seconds" end
					elseif rem == 1 then
						if txt and txt.Parent then txt.Text = "Please try again in 1 second" end
					else
						if txt and txt.Parent then
							txt.Text = "Ready"
							stroke.Color = State.Theme.Success
						end
						task.wait(1)
						if currentLoop == State.GlobalCooldownLoopVersion then
							if frame and frame.Parent then
								local outro = State.TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
									Position = UDim2.new(0.5, 0, 0, -60)
								})
								outro:Play()
								outro.Completed:Wait()
							end
							if bannerGui and bannerGui.Parent then bannerGui:Destroy() end
							if State.GlobalCooldownBanner == bannerGui then
								State.GlobalCooldownBanner = nil
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

	State.GlobalActionCooldownEndTime = tick() + 3

	if State.GlobalCooldownBanner and State.GlobalCooldownBanner.Parent then
		State.GlobalCooldownLoopVersion = State.GlobalCooldownLoopVersion + 1
		pcall(function() State.GlobalCooldownBanner:Destroy() end)
		State.GlobalCooldownBanner = nil
	end

	task.spawn(actionFunc)
end

State.ConfirmOverlay = Instance.new("Frame", State.ScreenGui)
State.ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
State.ConfirmOverlay.Position = UDim2.new(0, 0, 0, 0)
State.ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
State.ConfirmOverlay.BackgroundTransparency = 1
State.ConfirmOverlay.Visible = false
State.ConfirmOverlay.ZIndex = 400
State.ConfirmOverlay.Active = false

State.ConfirmBox = Instance.new("Frame", State.ConfirmOverlay)
State.ConfirmBox.Size = State.IsMobile and UDim2.new(0, 300, 0, 180) or UDim2.new(0, 360, 0, 190)
State.ConfirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
State.ConfirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
State.ConfirmBox.BackgroundColor3 = State.Theme.BackgroundSecondary
State.ConfirmBox.BorderSizePixel = 0
State.ConfirmBox.ClipsDescendants = true
State.ConfirmBox.ZIndex = 401
Instance.new("UICorner", State.ConfirmBox).CornerRadius = UDim.new(0, 12)
State.ConfirmBoxStroke = Instance.new("UIStroke", State.ConfirmBox)
State.ConfirmBoxStroke.Color = State.Theme.Stroke; State.ConfirmBoxStroke.Thickness = 1

State.ConfirmPadding = Instance.new("UIPadding", State.ConfirmBox)
State.ConfirmPadding.PaddingTop = UDim.new(0, 16); State.ConfirmPadding.PaddingBottom = UDim.new(0, 16)
State.ConfirmPadding.PaddingLeft = UDim.new(0, 20); State.ConfirmPadding.PaddingRight = UDim.new(0, 20)

State.ConfirmLayout = Instance.new("UIListLayout", State.ConfirmBox)
State.ConfirmLayout.SortOrder = Enum.SortOrder.LayoutOrder
State.ConfirmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
State.ConfirmLayout.VerticalAlignment = Enum.VerticalAlignment.Center; State.ConfirmLayout.Padding = UDim.new(0, 8)

State.ConfirmTitle = Instance.new("TextLabel", State.ConfirmBox)
State.ConfirmTitle.Size = UDim2.new(1, 0, 0, 22); State.ConfirmTitle.BackgroundTransparency = 1
State.ConfirmTitle.Text = "Execute Script"; State.ConfirmTitle.TextColor3 = State.Theme.TextPrimary
State.ConfirmTitle.Font = Enum.Font.GothamBold; State.ConfirmTitle.TextSize = State.IsMobile and 14 or 16
State.ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Center; State.ConfirmTitle.LayoutOrder = 1; State.ConfirmTitle.ZIndex = 402

State.ConfirmMessage = Instance.new("TextLabel", State.ConfirmBox)
State.ConfirmMessage.Size = UDim2.new(1, 0, 0, 18); State.ConfirmMessage.BackgroundTransparency = 1
State.ConfirmMessage.Text = "Are you sure you want to run this script?"
State.ConfirmMessage.TextColor3 = State.Theme.TextSecondary; State.ConfirmMessage.Font = Enum.Font.Gotham
State.ConfirmMessage.TextSize = State.IsMobile and 11 or 12; State.ConfirmMessage.TextXAlignment = Enum.TextXAlignment.Center
State.ConfirmMessage.TextWrapped = true; State.ConfirmMessage.LayoutOrder = 2; State.ConfirmMessage.ZIndex = 402

State.ConfirmScriptName = Instance.new("TextLabel", State.ConfirmBox)
State.ConfirmScriptName.Size = UDim2.new(1, 0, 0, 0); State.ConfirmScriptName.AutomaticSize = Enum.AutomaticSize.Y
State.ConfirmScriptName.BackgroundTransparency = 1; State.ConfirmScriptName.Text = ""
State.ConfirmScriptName.TextColor3 = State.Theme.Accent; State.ConfirmScriptName.Font = Enum.Font.GothamBold
State.ConfirmScriptName.TextSize = State.IsMobile and 12 or 13; State.ConfirmScriptName.TextXAlignment = Enum.TextXAlignment.Center
State.ConfirmScriptName.TextWrapped = true; State.ConfirmScriptName.LayoutOrder = 3; State.ConfirmScriptName.ZIndex = 402

State.ConfirmButtonRow = Instance.new("Frame", State.ConfirmBox)
State.ConfirmButtonRow.Size = UDim2.new(1, 0, 0, 34); State.ConfirmButtonRow.BackgroundTransparency = 1
State.ConfirmButtonRow.LayoutOrder = 4; State.ConfirmButtonRow.ZIndex = 402
State.ConfirmRowLayout = Instance.new("UIListLayout", State.ConfirmButtonRow)
State.ConfirmRowLayout.FillDirection = Enum.FillDirection.Horizontal
State.ConfirmRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
State.ConfirmRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
State.ConfirmRowLayout.SortOrder = Enum.SortOrder.LayoutOrder; State.ConfirmRowLayout.Padding = UDim.new(0, 12)

State.ConfirmCancelBtn = Instance.new("TextButton", State.ConfirmButtonRow)
State.ConfirmCancelBtn.Size = UDim2.new(0.5, -6, 1, 0); State.ConfirmCancelBtn.BackgroundColor3 = State.Theme.CardHover
State.ConfirmCancelBtn.Text = "Cancel"; State.ConfirmCancelBtn.TextColor3 = State.Theme.TextPrimary
State.ConfirmCancelBtn.Font = Enum.Font.GothamBold; State.ConfirmCancelBtn.TextSize = State.IsMobile and 11 or 12
State.ConfirmCancelBtn.AutoButtonColor = false; State.ConfirmCancelBtn.LayoutOrder = 1; State.ConfirmCancelBtn.ZIndex = 403
Instance.new("UICorner", State.ConfirmCancelBtn).CornerRadius = UDim.new(0, 6)
State.CancelStroke = Instance.new("UIStroke", State.ConfirmCancelBtn); State.CancelStroke.Color = State.Theme.Stroke

State.ConfirmExecuteBtn = Instance.new("TextButton", State.ConfirmButtonRow)
State.ConfirmExecuteBtn.Size = UDim2.new(0.5, -6, 1, 0); State.ConfirmExecuteBtn.BackgroundColor3 = State.Theme.Accent
State.ConfirmExecuteBtn.Text = "Execute"; State.ConfirmExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
State.ConfirmExecuteBtn.Font = Enum.Font.GothamBold; State.ConfirmExecuteBtn.TextSize = State.IsMobile and 11 or 12
State.ConfirmExecuteBtn.AutoButtonColor = false; State.ConfirmExecuteBtn.LayoutOrder = 2; State.ConfirmExecuteBtn.ZIndex = 403
Instance.new("UICorner", State.ConfirmExecuteBtn).CornerRadius = UDim.new(0, 6)

State.ApplyInteractiveAnimations(State.ConfirmCancelBtn, State.Theme.CardHover, Color3.fromRGB(40, 53, 75), Color3.fromRGB(20, 29, 45), State.CancelStroke, State.Theme.Stroke, State.Theme.Accent)
State.ApplyInteractiveAnimations(State.ConfirmExecuteBtn, State.Theme.Accent, Color3.fromRGB(120, 123, 245), Color3.fromRGB(79, 82, 221))

State.isConfirming = false
State.pendingExecuteCallback = nil

function State.OpenConfirmDialog(scriptName, onExecute)
	if State.isConfirming or State.isTransitioning then return end
	State.isConfirming = true
	State.pendingExecuteCallback = onExecute
	State.ConfirmScriptName.Text = scriptName
	State.ConfirmExecuteBtn.Active = true
	State.ConfirmExecuteBtn.AutoButtonColor = true
	State.ConfirmExecuteBtn.Text = "Execute"
	State.ConfirmOverlay.BackgroundTransparency = 0.5
	State.ConfirmOverlay.Visible = true
	State.ConfirmOverlay.Active = true
end

function State.CloseConfirmDialog(shouldExecute)
	if not State.isConfirming then return end
	State.ConfirmExecuteBtn.Active = false
	State.ConfirmOverlay.BackgroundTransparency = 1
	State.ConfirmOverlay.Visible = false
	State.ConfirmOverlay.Active = false
	State.isConfirming = false
	local cb = State.pendingExecuteCallback
	State.pendingExecuteCallback = nil
	if shouldExecute and type(cb) == "function" then task.spawn(cb) end
end

State.RegConn(State.ConfirmCancelBtn.Activated:Connect(State.CreateDebounce(0.1, function() State.CloseConfirmDialog(false) end)))
State.RegConn(State.ConfirmExecuteBtn.Activated:Connect(function()
	State.AttemptActionWithCooldown(function()
		State.CloseConfirmDialog(true)
	end)
end))

State.RegConn(State.ConfirmOverlay.InputBegan:Connect(function(input)
	if not State.isConfirming then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		local bPos, bSize = State.ConfirmBox.AbsolutePosition, State.ConfirmBox.AbsoluteSize
		local inside = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y
		if not inside then State.CloseConfirmDialog(false) end
	end
end))

State.ToggleKeybind = Enum.KeyCode.RightControl
pcall(function() if State.SavedData.ToggleKeybind then State.ToggleKeybind = Enum.KeyCode[State.SavedData.ToggleKeybind] end end)
State.KeybindButtonRef = nil

function State.BindToggleKey(keyCode)
	if State.ToggleKeybindConnection then
		State.UnregConn(State.ToggleKeybindConnection)
		State.ToggleKeybindConnection = nil
	end

	State.ToggleKeybindConnection = State.RegConn(State.UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or State.isConfirming or State.IsBindingKey or State.isTransitioning or State.isDestroying then return end

		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyCode then
			if State.SearchInput and State.SearchInput:IsFocused() then
				State.SearchInput:ReleaseFocus()
			end
			State.ToggleUI()
		end
	end))
end

State.BindToggleKey(State.ToggleKeybind)

State.RegConn(State.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if State.isConfirming then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
			State.CloseConfirmDialog(false)
			return
		end
	end
end))

function State.CloseUI()
	if State.isDestroying then return end
	if State.SearchInput and State.SearchInput.Parent then pcall(function() State.SearchInput:ReleaseFocus() end) end
	State.isDestroying = true
	State.GlobalEnv[State._G_Identifier]()
end

State.HeaderContainer = Instance.new("Frame", State.PanelGroup)
State.HeaderContainer.Size = UDim2.new(1, -32, 0, State.IsMobile and 48 or 56)
State.HeaderContainer.Position = UDim2.new(0, 16, 0, State.IsMobile and 6 or 10)
State.HeaderContainer.BackgroundTransparency = 1
State.HeaderContainer.Active = true

State.mainDragStart, State.mainStartPos = nil, nil

State.RegConn(State.HeaderContainer.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not State.activeMainDragInput then
		State.activeMainDragInput = input
		State.mainDragStart = input.Position
		State.mainStartPos = State.MainPanel.Position

		if State.mainDragConnection then State.mainDragConnection:Disconnect() end
		State.mainDragConnection = State.RegConn(State.UserInputService.InputChanged:Connect(function(moveInput)
			if State.isDestroying then return end
			if moveInput == State.activeMainDragInput or moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = moveInput.Position - State.mainDragStart
				local camera = workspace.CurrentCamera
				local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
				local targetX = State.mainStartPos.X.Scale * viewport.X + State.mainStartPos.X.Offset + delta.X
				local targetY = State.mainStartPos.Y.Scale * viewport.Y + State.mainStartPos.Y.Offset + delta.Y
				local halfX = State.MainPanel.AbsoluteSize.X * State.MainPanel.AnchorPoint.X
				local halfY = State.MainPanel.AbsoluteSize.Y * State.MainPanel.AnchorPoint.Y
				targetX = math.clamp(targetX, halfX, viewport.X - (State.MainPanel.AbsoluteSize.X - halfX))
				targetY = math.clamp(targetY, halfY, viewport.Y - (State.MainPanel.AbsoluteSize.Y - halfY))
				State.MainPanel.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end))

State.RegConn(State.UserInputService.InputEnded:Connect(function(input)
	if State.isDestroying then return end
	if State.activeMainDragInput and (input == State.activeMainDragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
		State.activeMainDragInput = nil
		if State.mainDragConnection then
			State.mainDragConnection:Disconnect()
			State.mainDragConnection = nil
		end
		if State.OriginalCache[State.MainPanel] then State.OriginalCache[State.MainPanel].Position = State.MainPanel.Position end
	end
	if State.activeFloatDragInput and (input == State.activeFloatDragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
		State.activeFloatDragInput = nil
		if State.floatDragConnection then
			State.floatDragConnection:Disconnect()
			State.floatDragConnection = nil
		end
		if State.floatStart then
			local dist = (input.Position - State.floatStart).Magnitude
			if dist < 12 then
				State.ToggleUI()
			else
				if State.OriginalCache[State.FloatingBtn] then State.OriginalCache[State.FloatingBtn].Position = State.FloatingBtn.Position end
			end
		end
	end
end))

State.LeftHeaderFrame = Instance.new("Frame", State.HeaderContainer)
State.LeftHeaderFrame.Size = UDim2.new(0.6, 0, 1, 0); State.LeftHeaderFrame.BackgroundTransparency = 1; State.LeftHeaderFrame.Active = false
State.LHLay = Instance.new("UIListLayout", State.LeftHeaderFrame)
State.LHLay.SortOrder = Enum.SortOrder.LayoutOrder; State.LHLay.Padding = UDim.new(0, 4); State.LHLay.VerticalAlignment = Enum.VerticalAlignment.Center

State.TopLeftRow = Instance.new("Frame", State.LeftHeaderFrame)
State.TopLeftRow.Size = UDim2.new(1, 0, 0, 24); State.TopLeftRow.BackgroundTransparency = 1; State.TopLeftRow.LayoutOrder = 1
State.TLRowLay = Instance.new("UIListLayout", State.TopLeftRow)
State.TLRowLay.FillDirection = Enum.FillDirection.Horizontal; State.TLRowLay.SortOrder = Enum.SortOrder.LayoutOrder; State.TLRowLay.Padding = UDim.new(0, 8); State.TLRowLay.VerticalAlignment = Enum.VerticalAlignment.Center

State.Title = Instance.new("TextLabel", State.TopLeftRow)
State.Title.AutomaticSize = Enum.AutomaticSize.X; State.Title.Size = UDim2.new(0, 0, 1, 0); State.Title.BackgroundTransparency = 1
State.Title.Text = "Velox Hub"; State.Title.TextColor3 = State.Theme.TextPrimary
State.Title.Font = Enum.Font.GothamBold; State.Title.TextSize = State.IsMobile and 16 or 19; State.Title.LayoutOrder = 1

State.StatusDot = Instance.new("Frame", State.TopLeftRow)
State.StatusDot.Size = UDim2.new(0, 8, 0, 8); State.StatusDot.LayoutOrder = 2
Instance.new("UICorner", State.StatusDot).CornerRadius = UDim.new(1, 0)

State.StatusText = Instance.new("TextLabel", State.TopLeftRow)
State.StatusText.AutomaticSize = Enum.AutomaticSize.X; State.StatusText.Size = UDim2.new(0, 0, 1, 0); State.StatusText.BackgroundTransparency = 1
State.StatusText.Font = Enum.Font.GothamBold; State.StatusText.TextSize = 11; State.StatusText.LayoutOrder = 3

State.BtmLeftRow = Instance.new("Frame", State.LeftHeaderFrame)
State.BtmLeftRow.Size = UDim2.new(1, 0, 0, 14); State.BtmLeftRow.BackgroundTransparency = 1; State.BtmLeftRow.LayoutOrder = 2
State.BLRowLay = Instance.new("UIListLayout", State.BtmLeftRow)
State.BLRowLay.FillDirection = Enum.FillDirection.Horizontal; State.BLRowLay.SortOrder = Enum.SortOrder.LayoutOrder; State.BLRowLay.Padding = UDim.new(0, 6)

State.VersionLabel = Instance.new("TextLabel", State.BtmLeftRow)
State.VersionLabel.AutomaticSize = Enum.AutomaticSize.X; State.VersionLabel.Size = UDim2.new(0, 0, 1, 0)
State.VersionLabel.BackgroundTransparency = 1; State.VersionLabel.Text = "v2.0.0 BETA | " .. getexecutor()
State.VersionLabel.TextColor3 = State.Theme.Accent; State.VersionLabel.Font = Enum.Font.GothamMedium; State.VersionLabel.TextSize = State.IsMobile and 10 or 12; State.VersionLabel.LayoutOrder = 1

State.DiagnosticsLabel = Instance.new("TextLabel", State.BtmLeftRow)
State.DiagnosticsLabel.AutomaticSize = Enum.AutomaticSize.X; State.DiagnosticsLabel.Size = UDim2.new(0, 0, 1, 0); State.DiagnosticsLabel.BackgroundTransparency = 1
State.DiagnosticsLabel.TextColor3 = State.Theme.TextSecondary; State.DiagnosticsLabel.Font = Enum.Font.GothamMedium; State.DiagnosticsLabel.TextSize = State.IsMobile and 9 or 11
State.DiagnosticsLabel.Text = "FPS: -- | Ping: --ms"; State.DiagnosticsLabel.LayoutOrder = 2

State.RightHeaderFrame = Instance.new("Frame", State.HeaderContainer)
State.RightHeaderFrame.Size = UDim2.new(0.4, 0, 1, 0); State.RightHeaderFrame.Position = UDim2.new(1, 0, 0, 0); State.RightHeaderFrame.AnchorPoint = Vector2.new(1, 0)
State.RightHeaderFrame.BackgroundTransparency = 1; State.RightHeaderFrame.Active = false
State.RHLay = Instance.new("UIListLayout", State.RightHeaderFrame)
State.RHLay.FillDirection = Enum.FillDirection.Horizontal; State.RHLay.SortOrder = Enum.SortOrder.LayoutOrder; State.RHLay.HorizontalAlignment = Enum.HorizontalAlignment.Right; State.RHLay.VerticalAlignment = Enum.VerticalAlignment.Center; State.RHLay.Padding = UDim.new(0, 8)

State.UserInfoFrame = Instance.new("Frame", State.RightHeaderFrame)
State.UserInfoFrame.Size = UDim2.new(0, State.IsMobile and 70 or 90, 1, 0); State.UserInfoFrame.BackgroundTransparency = 1; State.UserInfoFrame.LayoutOrder = 1
State.UILay = Instance.new("UIListLayout", State.UserInfoFrame)
State.UILay.SortOrder = Enum.SortOrder.LayoutOrder; State.UILay.VerticalAlignment = Enum.VerticalAlignment.Center

State.UI_DisplayName = Instance.new("TextLabel", State.UserInfoFrame)
State.UI_DisplayName.Size = UDim2.new(1, 0, 0, 0); State.UI_DisplayName.AutomaticSize = Enum.AutomaticSize.Y; State.UI_DisplayName.BackgroundTransparency = 1
State.UI_DisplayName.Text = State.LocalPlayer.DisplayName ~= "" and State.LocalPlayer.DisplayName or State.LocalPlayer.Name; State.UI_DisplayName.TextColor3 = State.Theme.TextPrimary
State.UI_DisplayName.Font = Enum.Font.GothamBold; State.UI_DisplayName.TextSize = State.IsMobile and 10 or 12
State.UI_DisplayName.TextXAlignment = Enum.TextXAlignment.Right; State.UI_DisplayName.LayoutOrder = 1

State.UI_Username = Instance.new("TextLabel", State.UserInfoFrame)
State.UI_Username.Size = UDim2.new(1, 0, 0, 0); State.UI_Username.AutomaticSize = Enum.AutomaticSize.Y; State.UI_Username.BackgroundTransparency = 1
State.UI_Username.Text = "@" .. LocalPlayer.Name; State.UI_Username.TextColor3 = State.Theme.TextSecondary
State.UI_Username.Font = Enum.Font.Gotham; State.UI_Username.TextSize = State.IsMobile and 9 or 10
State.UI_Username.TextXAlignment = Enum.TextXAlignment.Right; State.UI_Username.LayoutOrder = 2

State.AvatarFrame = Instance.new("ImageLabel", State.RightHeaderFrame)
State.AvatarFrame.Size = UDim2.new(0, State.IsMobile and 26 or 32, 0, State.IsMobile and 26 or 32); State.AvatarFrame.BackgroundColor3 = State.Theme.CardHover
State.AvatarFrame.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"; State.AvatarFrame.LayoutOrder = 2
Instance.new("UICorner", State.AvatarFrame).CornerRadius = UDim.new(0, 8)
State.AvatarStroke = Instance.new("UIStroke", State.AvatarFrame); State.AvatarStroke.Color = State.Theme.Accent; State.AvatarStroke.Thickness = 1.5

task.spawn(function()
	local attempts = 0
	while attempts < 3 and not State.isDestroying do
		attempts = attempts + 1
		local success, content = pcall(function() return State.Players:GetUserThumbnailAsync(State.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
		if success and content then
			if State.isDestroying then return end
			if State.AvatarFrame and State.AvatarFrame.Parent then State.AvatarFrame.Image = content end
			break
		else
			task.wait(2)
		end
	end
end)

State.MinBtn = Instance.new("TextButton", State.RightHeaderFrame)
State.MinBtn.Size = UDim2.new(0, 28, 0, 28); State.MinBtn.BackgroundTransparency = 1; State.MinBtn.Text = "—"
State.MinBtn.TextColor3 = State.Theme.TextSecondary; State.MinBtn.Font = Enum.Font.GothamBold; State.MinBtn.TextSize = State.IsMobile and 14 or 18; State.MinBtn.LayoutOrder = 3
State.MinBtn.ClipsDescendants = true
Instance.new("UICorner", State.MinBtn).CornerRadius = UDim.new(0, 6)
State.RegConn(State.MinBtn.Activated:Connect(function() State.ToggleUI() end))
State.ApplyInteractiveAnimations(State.MinBtn, nil, State.Theme.CardHover, State.Theme.CardHover, nil, nil, nil)

State.fpsCount = 0
State.diagnosticsElapsed = 0
State.RegConn(State.RunService.Heartbeat:Connect(function(deltaTime)
	if State.isDestroying then return end
	if State.isMinimized or State.isTransitioning then
		State.fpsCount = 0
		State.diagnosticsElapsed = 0
		return
	end
	State.fpsCount = State.fpsCount + 1
	State.diagnosticsElapsed = State.diagnosticsElapsed + deltaTime
	if State.diagnosticsElapsed < 1 then return end
	State.diagnosticsElapsed = State.diagnosticsElapsed - 1
	local success, ping = pcall(function()
		return math.floor(State.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
	end)
	if State.DiagnosticsLabel and State.DiagnosticsLabel.Parent then
		State.DiagnosticsLabel.Text = string.format("FPS: %d | Ping: %dms", State.fpsCount, success and ping or 0)
	end
	State.fpsCount = 0
end))

State.TabContainer = Instance.new("Frame", State.PanelGroup)
State.TabContainer.Size = UDim2.new(1, -32, 0, 24); State.TabContainer.Position = UDim2.new(0, 16, 0, State.IsMobile and 58 or 72); State.TabContainer.BackgroundTransparency = 1; State.TabContainer.Active = false

State.SectionHeaderLabel = Instance.new("TextLabel", State.PanelGroup)
State.SectionHeaderLabel.Size = UDim2.new(1, -32, 0, State.IsMobile and 16 or 20); State.SectionHeaderLabel.Position = UDim2.new(0, 16, 0, State.IsMobile and 88 or 104); State.SectionHeaderLabel.BackgroundTransparency = 1
State.SectionHeaderLabel.Text = "Updates"; State.SectionHeaderLabel.TextColor3 = State.Theme.TextPrimary
State.SectionHeaderLabel.Font = Enum.Font.GothamBold; State.SectionHeaderLabel.TextSize = State.IsMobile and 13 or 16; State.SectionHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

State.TabViews = {}
State.currentTab = "Changelogs"

function State.CreateCanvas(name)
	local scroll = Instance.new("ScrollingFrame", State.PanelGroup)
	scroll.Size = UDim2.new(1, -32, 1, State.IsMobile and -116 or -138)
	scroll.Position = UDim2.new(0, 16, 0, State.IsMobile and 108 or 128)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = State.Theme.Stroke
	scroll.Visible = (name == State.currentTab)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.Active = true
	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, State.IsMobile and 8 or 12); layout.SortOrder = Enum.SortOrder.LayoutOrder
	local pad = Instance.new("UIPadding", scroll)
	pad.PaddingRight = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 16)
	State.TabViews[name] = scroll
	return scroll
end

State.ChangelogsView = State.CreateCanvas("Changelogs")
State.ScriptsView = State.CreateCanvas("Scripts")
State.SettingsView = State.CreateCanvas("Settings")

State.ScriptsView.Position = State.IsMobile and UDim2.new(0, 16, 0, 144) or UDim2.new(0, 16, 0, 168)
State.ScriptsView.Size = State.IsMobile and UDim2.new(1, -32, 1, -152) or UDim2.new(1, -32, 1, -178)

State.EmptyStateMessage = Instance.new("TextLabel", State.ScriptsView)
State.EmptyStateMessage.Size = UDim2.new(1, 0, 0, 40); State.EmptyStateMessage.BackgroundTransparency = 1
State.EmptyStateMessage.TextColor3 = State.Theme.TextSecondary; State.EmptyStateMessage.Font = Enum.Font.GothamMedium
State.EmptyStateMessage.TextSize = 12; State.EmptyStateMessage.TextWrapped = true; State.EmptyStateMessage.LayoutOrder = -1

State.SearchRow = Instance.new("Frame", State.PanelGroup)
State.SearchRow.Size = UDim2.new(1, -32, 0, State.IsMobile and 28 or 32); State.SearchRow.Position = UDim2.new(0, 16, 0, State.IsMobile and 108 or 128)
State.SearchRow.BackgroundTransparency = 1; State.SearchRow.Visible = false; State.SearchRow.Active = false; State.SearchRow.ZIndex = 50

State.filterBtnWidth = State.IsMobile and 28 or 32
State.gap = 8

State.SearchContainer = Instance.new("Frame", State.SearchRow)
State.SearchContainer.Size = UDim2.new(1, -(State.filterBtnWidth * 2 + State.gap * 2), 1, 0); State.SearchContainer.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
State.SearchContainer.ClipsDescendants = true; State.SearchContainer.ZIndex = 51
Instance.new("UICorner", State.SearchContainer).CornerRadius = UDim.new(0, 6)
State.SearchStroke = Instance.new("UIStroke", State.SearchContainer); State.SearchStroke.Color = Color3.fromRGB(51, 65, 85); State.SearchStroke.Thickness = 1

State.SearchInput = Instance.new("TextBox", State.SearchContainer)
State.SearchInput.Size = UDim2.new(1, -40, 1, 0); State.SearchInput.Position = UDim2.new(0, 12, 0, 0); State.SearchInput.BackgroundTransparency = 1
State.SearchInput.Text = ""; State.SearchInput.PlaceholderText = "Search scripts by name..."
State.SearchInput.PlaceholderColor3 = Color3.fromRGB(148, 163, 184); State.SearchInput.TextColor3 = Color3.fromRGB(248, 250, 252)
State.SearchInput.Font = Enum.Font.Gotham; State.SearchInput.TextSize = 12; State.SearchInput.TextXAlignment = Enum.TextXAlignment.Left
State.SearchInput.ClearTextOnFocus = false; State.SearchInput.TextEditable = true; State.SearchInput.Interactable = true; State.SearchInput.ZIndex = 52
Instance.new("UIPadding", State.SearchInput).PaddingRight = UDim.new(0, 10)

State.ClearSearchBtn = Instance.new("TextButton", State.SearchContainer)
State.ClearSearchBtn.Size = UDim2.new(0, 24, 0, 24)
State.ClearSearchBtn.Position = UDim2.new(1, -28, 0.5, -12)
State.ClearSearchBtn.BackgroundTransparency = 1
State.ClearSearchBtn.Text = "×"
State.ClearSearchBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
State.ClearSearchBtn.TextSize = 18
State.ClearSearchBtn.Font = Enum.Font.GothamBold
State.ClearSearchBtn.ZIndex = 53
State.ClearSearchBtn.Visible = (State.SearchInput.Text ~= "")

State.RegConn(State.SearchInput.Focused:Connect(function() State.SearchStroke.Color = State.Theme.Accent end))
State.RegConn(State.SearchInput.FocusLost:Connect(function() State.SearchStroke.Color = State.Theme.Stroke end))

State.FavFilterBtn = Instance.new("TextButton", State.SearchRow)
State.FavFilterBtn.Size = UDim2.new(0, State.filterBtnWidth, 1, 0); State.FavFilterBtn.Position = UDim2.new(1, -(State.filterBtnWidth * 2 + State.gap), 0, 0)
State.FavFilterBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59); State.FavFilterBtn.Text = "☆"
State.FavFilterBtn.TextColor3 = Color3.fromRGB(148, 163, 184); State.FavFilterBtn.TextSize = 15
State.FavFilterBtn.Font = Enum.Font.GothamBold; State.FavFilterBtn.ZIndex = 51
Instance.new("UICorner", State.FavFilterBtn).CornerRadius = UDim.new(0, 6)
State.FavFilterStroke = Instance.new("UIStroke", State.FavFilterBtn); State.FavFilterStroke.Color = Color3.fromRGB(51, 65, 85)

State.SortDropdownBtn = Instance.new("TextButton", State.SearchRow)
State.SortDropdownBtn.Size = UDim2.new(0, State.filterBtnWidth, 1, 0); State.SortDropdownBtn.Position = UDim2.new(1, -State.filterBtnWidth, 0, 0)
State.SortDropdownBtn.BackgroundColor3 = Color3.fromRGB(38, 51, 74); State.SortDropdownBtn.Text = "↕"
State.SortDropdownBtn.TextColor3 = State.Theme.TextSecondary; State.SortDropdownBtn.TextSize = 15
State.SortDropdownBtn.Font = Enum.Font.GothamBold; State.SortDropdownBtn.ZIndex = 51; State.SortDropdownBtn.ClipsDescendants = true
Instance.new("UICorner", State.SortDropdownBtn).CornerRadius = UDim.new(0, 6)
State.SortBtnStroke = Instance.new("UIStroke", State.SortDropdownBtn); State.SortBtnStroke.Color = State.Theme.Stroke
State.ApplyInteractiveAnimations(State.SortDropdownBtn, Color3.fromRGB(38, 51, 74), Color3.fromRGB(50, 68, 96), State.Theme.BackgroundSecondary, State.SortBtnStroke, State.Theme.Stroke, State.Theme.Accent)

State.DropdownContainer = Instance.new("ScrollingFrame", State.ScreenGui)
State.DropdownContainer.Size = UDim2.new(0, 190, 0, 210); State.DropdownContainer.BackgroundColor3 = State.Theme.BackgroundMain
State.DropdownContainer.Visible = false; State.DropdownContainer.ZIndex = 1000; State.DropdownContainer.BorderSizePixel = 0
State.DropdownContainer.ScrollBarThickness = 2; State.DropdownContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", State.DropdownContainer).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", State.DropdownContainer).Color = State.Theme.Accent
State.DDLayout = Instance.new("UIListLayout", State.DropdownContainer); State.DDLayout.SortOrder = Enum.SortOrder.LayoutOrder

State.viewportConn = nil
function State.BindCamera()
	if State.viewportConn then State.viewportConn:Disconnect() end
	local cam = workspace.CurrentCamera
	if cam then
		State.viewportConn = State.RegConn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if State.DropdownContainer and State.DropdownContainer.Visible then
				State.DropdownContainer.Visible = false
			end
			if State.MainPanel and State.MainPanel.Parent then
				local viewport = cam.ViewportSize
				local halfX = State.MainPanel.AbsoluteSize.X * State.MainPanel.AnchorPoint.X
				local halfY = State.MainPanel.AbsoluteSize.Y * State.MainPanel.AnchorPoint.Y
				local currentOffsetX = State.MainPanel.Position.X.Offset
				local currentOffsetY = State.MainPanel.Position.Y.Offset
				if State.MainPanel.Position.X.Scale ~= 0 or State.MainPanel.Position.Y.Scale ~= 0 then
					currentOffsetX = State.MainPanel.Position.X.Scale * viewport.X + currentOffsetX
					currentOffsetY = State.MainPanel.Position.Y.Scale * viewport.Y + currentOffsetY
				end
				local targetX = math.clamp(currentOffsetX, halfX, viewport.X - (State.MainPanel.AbsoluteSize.X - halfX))
				local targetY = math.clamp(currentOffsetY, halfY, viewport.Y - (State.MainPanel.AbsoluteSize.Y - halfY))
				State.MainPanel.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end
State.RegConn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(State.BindCamera))
State.BindCamera()

State.FilterFavoritesActive = false
State.filterVersion = 0
State.SortMode = "Most Relevant"
State.SortOptions = {
	"Most Relevant", "A-Z", "Z-A", "Newest", "Oldest",
	"Updated Today", "Updated This Week", "Updated This Month",
	"Favorites", "Auto Execute: ON", "Auto Execute: OFF"
}

function State.UpdateFilter()
	if State.isDestroying then return end
	State.filterVersion = State.filterVersion + 1
	local currentVersion = State.filterVersion
	task.defer(function()
		if State.isDestroying or currentVersion ~= State.filterVersion then return end
		local queryText = State.SearchInput.Text or ""
		local query = string.lower(string.gsub(queryText, "^%s*(.-)%s*$", "%1"))
		local words = {}
		for word in string.gmatch(query, "%S+") do
			words[#words + 1] = word
		end
		local matches = {}
		local now = os.time()
		local activeFavorites = State.FilterFavoritesActive
		local currentSort = State.SortMode

		for _, scr in ipairs(State.RegisteredScripts) do
			if currentVersion ~= State.filterVersion then return end
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
				filterPass = State.SavedData.Favorites[scr.ExactName] == true
			end
			if filterPass then
				if currentSort == "Updated Today" then
					filterPass = age <= 86400
				elseif currentSort == "Updated This Week" then
					filterPass = age <= 604800
				elseif currentSort == "Updated This Month" then
					filterPass = age <= 2592000
				elseif currentSort == "Favorites" then
					filterPass = State.SavedData.Favorites[scr.ExactName] == true
				elseif currentSort == "Auto Execute: ON" then
					filterPass = State.SavedData.AutoExecutes[scr.ExactName] ~= nil
				elseif currentSort == "Auto Execute: OFF" then
					filterPass = State.SavedData.AutoExecutes[scr.ExactName] == nil
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

		if currentVersion ~= State.filterVersion then return end
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
				local aFav = State.SavedData.Favorites[a.ExactName] and 1 or 0
				local bFav = State.SavedData.Favorites[b.ExactName] and 1 or 0
				if aFav ~= bFav then return aFav > bFav end
			elseif currentSort == "Auto Execute: ON" or currentSort == "Auto Execute: OFF" then
				local aAuto = State.SavedData.AutoExecutes[a.ExactName] and 1 or 0
				local bAuto = State.SavedData.AutoExecutes[b.ExactName] and 1 or 0
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

		local shouldShowEmpty = #State.RegisteredScripts > 0 and #matches == 0
		if State.EmptyStateMessage.Visible ~= shouldShowEmpty then
			State.EmptyStateMessage.Visible = shouldShowEmpty
		end
		if shouldShowEmpty then
			State.EmptyStateMessage.Text = "No scripts matched your search or filters."
		end
		if State.ScriptsView and State.ScriptsView.Parent and query ~= "" then
			local canvasPosition = State.ScriptsView.CanvasPosition
			if canvasPosition.X ~= 0 or canvasPosition.Y ~= 0 then
				State.ScriptsView.CanvasPosition = Vector2.new(0, 0)
			end
		end
	end)
end

State.RegConn(State.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	State.ClearSearchBtn.Visible = (State.SearchInput.Text ~= "")
	if State.typingTask then task.cancel(State.typingTask) end
	State.typingTask = task.delay(0.2, function() State.UpdateFilter() end)
end))

State.RegConn(State.ClearSearchBtn.Activated:Connect(function()
	State.SearchInput.Text = ""
	if State.SearchInput:IsFocused() then State.SearchInput:ReleaseFocus() end
end))

State.RegConn(State.FavFilterBtn.MouseButton1Click:Connect(State.CreateDebounce(0.1, function()
	if State.isDestroying then return end
	State.FilterFavoritesActive = not State.FilterFavoritesActive
	if State.FilterFavoritesActive then
		State.FavFilterBtn.Text = "★"; State.FavFilterBtn.TextColor3 = Color3.fromRGB(250, 204, 21); State.FavFilterStroke.Color = Color3.fromRGB(250, 204, 21)
		State.ShowNotification("Showing your favorite scripts only.", "Info")
	else
		State.FavFilterBtn.Text = "☆"; State.FavFilterBtn.TextColor3 = Color3.fromRGB(148, 163, 184); State.FavFilterStroke.Color = Color3.fromRGB(51, 65, 85)
		State.ShowNotification("Showing all scripts.", "Info")
	end
	State.UpdateFilter()
end)))

for _, opt in ipairs(State.SortOptions) do
	local btn = Instance.new("TextButton", State.DropdownContainer)
	btn.Size = UDim2.new(1, 0, 0, 28); btn.BackgroundTransparency = 1
	btn.Text = "  " .. opt; btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = (opt == State.SortMode) and State.Theme.Accent or State.Theme.TextPrimary
	btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11; btn.ZIndex = 1001

	State.RegConn(btn.Activated:Connect(function()
		State.SortMode = opt
		State.DropdownContainer.Visible = false
		for _, child in ipairs(State.DropdownContainer:GetChildren()) do
			if child:IsA("TextButton") then child.TextColor3 = State.Theme.TextPrimary end
		end
		btn.TextColor3 = State.Theme.Accent
		State.ShowNotification("Sorted by: " .. opt, "Info")
		State.UpdateFilter()
	end))
end

State.RegConn(State.SortDropdownBtn.Activated:Connect(function()
	if State.DropdownContainer.Visible then
		State.DropdownContainer.Visible = false
	else
		local absPos = State.SortDropdownBtn.AbsolutePosition
		local absSize = State.SortDropdownBtn.AbsoluteSize
		local camera = workspace.CurrentCamera
		local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local dropWidth, dropHeight = 190, 210
		local posX = math.clamp(absPos.X + absSize.X - dropWidth, 10, viewportSize.X - dropWidth - 10)
		local posY = absPos.Y + absSize.Y + 4
		if posY + dropHeight > viewportSize.Y - 10 then
			posY = absPos.Y - dropHeight - 4
		end
		if posY < 10 then posY = 10 end
		State.DropdownContainer.Position = UDim2.new(0, posX, 0, posY)
		State.DropdownContainer.Visible = true
	end
end))

State.RegConn(State.UserInputService.InputBegan:Connect(function(input)
	if State.DropdownContainer.Visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local pos = input.Position
		local dPos, dSize = State.DropdownContainer.AbsolutePosition, State.DropdownContainer.AbsoluteSize
		local sPos, sSize = State.SortDropdownBtn.AbsolutePosition, State.SortDropdownBtn.AbsoluteSize
		local insideDrop = pos.X >= dPos.X and pos.X <= dPos.X + dSize.X and pos.Y >= dPos.Y and pos.Y <= dPos.Y + dSize.Y
		local insideBtn = pos.X >= sPos.X and pos.X <= sPos.X + sSize.X and pos.Y >= sPos.Y and pos.Y <= sPos.Y + sSize.Y
		if not insideDrop and not insideBtn then State.DropdownContainer.Visible = false end
	end
end))

State.TabIndicator = Instance.new("Frame", State.TabContainer)
State.TabIndicator.Size = UDim2.new(0, State.IsMobile and 80 or 100, 0, 2)
State.TabIndicator.Position = UDim2.new(0, 4, 1, -2)
State.TabIndicator.BackgroundColor3 = State.Theme.Accent
State.TabIndicator.BorderSizePixel = 0

State.TabButtonCache = {}
function State.CreateTab(name, index)
	local xOffset = (index - 1) * (State.IsMobile and 90 or 115)
	local btn = Instance.new("TextButton", State.TabContainer)
	btn.Size = UDim2.new(0, State.IsMobile and 85 or 105, 1, 0)
	btn.Position = UDim2.new(0, xOffset, 0, 0); btn.BackgroundTransparency = 1
	btn.Text = name; btn.Font = Enum.Font.GothamMedium; btn.TextSize = State.IsMobile and 11 or 13
	btn.TextColor3 = (name == State.currentTab) and State.Theme.TextPrimary or State.Theme.TextSecondary
	btn.ClipsDescendants = true; State.TabButtonCache[name] = btn
	if index > 1 then
		local div = Instance.new("Frame", State.TabContainer)
		div.Size = UDim2.new(0, 1, 0, 10); div.Position = UDim2.new(0, xOffset - 3, 0.5, -5)
		div.BackgroundColor3 = State.Theme.Stroke; div.BackgroundTransparency = 0.3
	end
	State.ApplyInteractiveAnimations(btn, nil, nil, nil, nil, nil, nil)
	State.RegConn(btn.Activated:Connect(function()
		if State.isDestroying or State.currentTab == name then return end
		State.currentTab = name; State.DropdownContainer.Visible = false
		State.TabIndicator.Size = UDim2.new(0, State.IsMobile and 80 or 100, 0, 2)
		State.TabIndicator.BackgroundTransparency = 0
		State.SafeTween(State.TabIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, xOffset + 4, 1, -2)})
		State.SectionHeaderLabel.Text = (name == "Changelogs") and "Updates" or (name == "Scripts") and "Scripts Catalog" or "Settings Hub"
		State.SearchRow.Visible = (name == "Scripts")
		if name == "Scripts" then
			State.UpdateFilter()
		elseif State.SearchInput and State.SearchInput.Parent then
			pcall(function() State.SearchInput:ReleaseFocus() end)
		end
		for tName, view in pairs(State.TabViews) do
			view.Visible = (tName == name)
			if view.Visible then view.CanvasPosition = Vector2.new(0, 0) end
		end
		for tName, tBtn in pairs(State.TabButtonCache) do
			tBtn.TextColor3 = (tName == State.currentTab) and State.Theme.TextPrimary or State.Theme.TextSecondary
		end
	end))
end
State.CreateTab("Changelogs", 1); State.CreateTab("Scripts", 2); State.CreateTab("Settings", 3)

function State.CreateParagraph(title, desc, parentView)
	local block = Instance.new("Frame", parentView)
	block.Size = UDim2.new(1, 0, 0, 0); block.AutomaticSize = Enum.AutomaticSize.Y
	block.BackgroundColor3 = State.Theme.CardHover
	Instance.new("UICorner", block).CornerRadius = UDim.new(0, 8)
	local blockStroke = Instance.new("UIStroke", block); blockStroke.Color = Color3.fromRGB(33, 43, 61)
	local pad = Instance.new("UIPadding", block)
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	local lay = Instance.new("UIListLayout", block)
	lay.Padding = UDim.new(0, 4); lay.SortOrder = Enum.SortOrder.LayoutOrder
	local tLbl = Instance.new("TextLabel", block)
	tLbl.Size = UDim2.new(1, 0, 0, 18); tLbl.BackgroundTransparency = 1; tLbl.Text = title
	tLbl.TextColor3 = State.Theme.TextPrimary; tLbl.Font = Enum.Font.GothamBold; tLbl.TextSize = 13
	tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.LayoutOrder = 1
	local dLbl = Instance.new("TextLabel", block)
	dLbl.Size = UDim2.new(1, 0, 0, 0); dLbl.AutomaticSize = Enum.AutomaticSize.Y
	dLbl.BackgroundTransparency = 1; dLbl.Text = desc; dLbl.TextColor3 = State.Theme.TextSecondary
	dLbl.Font = Enum.Font.Gotham; dLbl.TextSize = 12; dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.TextWrapped = true; dLbl.LayoutOrder = 2
end

State.CreateParagraph("Found a Bug?", "If you run into any bugs, issues, or anything that doesn't seem right, please report it on our Discord. It really helps me figure out what's going wrong and fix it faster. Even small details can be useful, so don't hesitate to report anything you notice!", State.ChangelogsView)
State.CreateParagraph("v2.0.1 - Executor Compatibility, Stability & Code Cleanup", "• Improved executor compatibility with safer environment detection and fallback handling.\n• Added safer getgenv handling with a standard global-environment fallback.\n• Improved dynamic script compilation with loadstring/load compatibility detection.\n• Improved handling of missing or unsupported executor APIs to prevent startup failures.\n• Removed unnecessary executor-specific hierarchy and metamethod interception that could cause compatibility issues.\n• Improved startup stability by reducing dependencies on executor-specific functionality.\n• Improved HTTP and request compatibility through safer API detection and fallback handling.\n• Improved GUI compatibility with safer GUI-parent and protection API handling.\n• Improved error handling for unsupported execution and compilation environments.\n• Removed unused variables and redundant cleanup operations.\n• Removed empty error-handling branches and other dead code without affecting callbacks or fallback systems.\n• Improved asynchronous task, connection, tween, and resource cleanup.\n• Preserved existing callbacks, fallback systems, configuration, Anti-AFK, catalog, and UI functionality.\n• Improved script execution reliability across different supported execution environments.\n• Reduced unnecessary dependencies and simplified compatibility-sensitive code paths.\n• Improved overall stability, reliability, compatibility, maintainability, and user experience across VeloxHub.", State.ChangelogsView)

function State.RefreshAllCardStates()
	for _, scrData in ipairs(State.RegisteredScripts) do
		if type(scrData.UpdateUI) == "function" then scrData.UpdateUI() end
		if scrData.TimeLabel and scrData.TimeLabel.Parent then
			scrData.TimeLabel.Text = State.GetRelativeTime(scrData.LastUpdatedNumber)
		end
	end
end

function State.ExecuteSandboxed(code, scriptName)
	if type(code) ~= "string" or code == "" then
		return false, "empty script"
	end

	local chunk, compileErr = State.CompileChunk(code, "=" .. tostring(scriptName))
	if type(chunk) ~= "function" then
		State.ShowNotification("Execution unavailable: this executor does not provide a compatible Lua compiler.", "Error")
		return false, compileErr or "no compatible Lua compiler"
	end

	State.TrackTask(function()
		local success, runtimeErr = pcall(chunk)
		if not success and not State.isDestroying then
			State.ShowNotification("Execution Error in [" .. tostring(scriptName) .. "]: Check F9 Console.", "Error")
		end
	end)

	return true, "Script dispatched successfully"
end

function State.CreateScriptCard(data, renderParent, registerImmediately, originalIndex)
	local tagType = State.NormalizeTagType(data and data.TagType)
	local tagConfig = State.TagTypeConfig[tagType]
	local exactName = type(data.Name) == "string" and data.Name or "Unnamed Script"
	local safeImageAssetId = type(data.ImageAssetId) == "string" and data.ImageAssetId or "rbxassetid://99657752206675"
	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0, 0); card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = tagConfig.CardColor; card.Text = ""
	card.AutoButtonColor = false; card.ClipsDescendants = true
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local cardStroke = State.GetOrCreateCardStroke(card)
	State.ApplyTagBorder(card, tagType, cardStroke)
	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	local img = Instance.new("ImageLabel", card)
	img.Size = UDim2.new(0, 68, 0, 68); img.BackgroundColor3 = State.Theme.BackgroundMain
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
	local metaWidth = State.IsMobile and 196 or 226
	local titleContainer = Instance.new("Frame", topRow)
	titleContainer.Size = UDim2.new(1, -metaWidth, 0, 0); titleContainer.AutomaticSize = Enum.AutomaticSize.Y
	titleContainer.BackgroundTransparency = 1; titleContainer.LayoutOrder = 1
	local titleLbl = Instance.new("TextLabel", titleContainer)
	titleLbl.Size = UDim2.new(1, 0, 0, 0); titleLbl.AutomaticSize = Enum.AutomaticSize.Y
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = data.Name or "Unnamed Script"
	titleLbl.TextColor3 = State.Theme.TextPrimary; titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = State.IsMobile and 12 or 13; titleLbl.TextWrapped = true; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
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
	dateLbl.Size = UDim2.new(0, State.IsMobile and 130 or 150, 1, 0)
	dateLbl.BackgroundTransparency = 1; dateLbl.Text = State.GetRelativeTime(data.LastUpdated)
	dateLbl.TextColor3 = State.Theme.TextSecondary; dateLbl.Font = Enum.Font.GothamMedium
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
	State.RegCardConn(topRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCardMetaLayout))
	UpdateCardMetaLayout()
	local descLbl = Instance.new("TextLabel", content)
	descLbl.Size = UDim2.new(1, 0, 0, 0); descLbl.AutomaticSize = Enum.AutomaticSize.Y
	descLbl.BackgroundTransparency = 1; descLbl.Text = type(data.Description) == "string" and data.Description or "No description provided."
	descLbl.TextColor3 = State.Theme.TextSecondary; descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 11
	descLbl.TextWrapped = true; descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.LayoutOrder = 2
	local btmRow = Instance.new("Frame", content)
	btmRow.Size = UDim2.new(1, 0, 0, 22); btmRow.BackgroundTransparency = 1; btmRow.LayoutOrder = 3
	local brLay = Instance.new("UIListLayout", btmRow)
	brLay.FillDirection = Enum.FillDirection.Horizontal; brLay.SortOrder = Enum.SortOrder.LayoutOrder; brLay.Padding = UDim.new(0, 8); brLay.VerticalAlignment = Enum.VerticalAlignment.Center
	local autoExecBtn = Instance.new("TextButton", btmRow)
	autoExecBtn.Size = UDim2.new(0, 120, 0, 22); autoExecBtn.BackgroundColor3 = State.Theme.BackgroundMain
	autoExecBtn.Text = ""; autoExecBtn.AutoButtonColor = false; autoExecBtn.ClipsDescendants = true; autoExecBtn.LayoutOrder = 1; autoExecBtn.ZIndex = 2
	Instance.new("UICorner", autoExecBtn).CornerRadius = UDim.new(0, 6)
	local aeLbl = Instance.new("TextLabel", autoExecBtn)
	aeLbl.Size = UDim2.new(1, -34, 1, 0); aeLbl.Position = UDim2.new(0, 6, 0, 0); aeLbl.BackgroundTransparency = 1
	aeLbl.Text = "Auto Execute"; aeLbl.TextColor3 = State.Theme.TextPrimary
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

	State.ApplyInteractiveAnimations(card, tagConfig.CardColor, tagConfig.HoverColor, Color3.fromRGB(20, 29, 45), nil, nil, nil, State.CardConnections)
	State.ApplyInteractiveAnimations(autoExecBtn, State.Theme.BackgroundMain, State.Theme.BackgroundSecondary, Color3.fromRGB(10, 15, 30), nil, nil, nil, State.CardConnections)
	State.ApplyInteractiveAnimations(starBtn, nil, nil, nil, nil, nil, nil, State.CardConnections)

	local description = type(data.Description) == "string" and data.Description or ""
	local tagSearch = tagType
	local scriptEntry = {
		Instance = card, SearchTitle = string.lower(exactName), SearchDesc = string.lower(description),
		SearchMeta = string.lower(table.concat({type(data.Category) == "string" and data.Category or "", type(data.Author) == "string" and data.Author or "", tagSearch}, " ")),
		ExactName = exactName, LastUpdated = data.LastUpdated, LastUpdatedNumber = State.GetSafeTimestamp(data.LastUpdated), TagType = tagType, TagPriority = tagConfig.Priority, OriginalIndex = originalIndex or (#State.RegisteredScripts + 1), EntryFingerprint = table.concat({ tostring(data.Name or ""), tostring(data.Description or ""), tostring(data.RawUrl or ""), tostring(data.ImageAssetId or ""), tostring(State.NormalizeTagType(data.TagType)), tostring(State.GetSafeTimestamp(data.LastUpdated)), tostring(tonumber(data.State.PlaceId) or 0), tostring(data.Category or ""), tostring(data.Author or "") }, "\31"), TimeLabel = dateLbl
	}

	local innerActionTime = 0

	scriptEntry.UpdateUI = function()
		State.ApplyTagBorder(card, tagType, cardStroke)
		local isFav = State.SavedData.Favorites[exactName]
		starBtn.Text = isFav and "★" or "☆"; starBtn.TextColor3 = isFav and Color3.fromRGB(250, 204, 21) or State.Theme.TextSecondary
		local isON = (State.SavedData.AutoExecutes[exactName] ~= nil)
		aeStateTxt.Text = isON and "ON" or "OFF"; aeState.BackgroundColor3 = isON and State.Theme.Success or State.Theme.Error
	end
	scriptEntry.UpdateUI()

	State.RegCardConn(starBtn.Activated:Connect(State.CreateDebounce(0.1, function()
		if State.isDestroying then return end
		innerActionTime = tick()
		if State.SavedData.Favorites[exactName] then
			State.SavedData.Favorites[exactName] = nil; State.ShowNotification("Removed '" .. exactName .. "' from favorites.", "Warning")
		else
			State.SavedData.Favorites[exactName] = true; State.ShowNotification("Added '" .. exactName .. "' to favorites!", "Success")
		end
		State.SaveConfiguration(); State.RefreshAllCardStates(); State.UpdateFilter()
	end)))

	State.RegCardConn(autoExecBtn.Activated:Connect(State.CreateDebounce(0.1, function()
		if State.isDestroying then return end
		innerActionTime = tick()
		if State.SavedData.AutoExecutes[exactName] then
			State.SavedData.AutoExecutes[exactName] = nil; State.ShowNotification("Disabled auto-execute for '" .. exactName .. "'.", "Warning")
		else
			State.SavedData.AutoExecutes[exactName] = {PlaceId = game.PlaceId, GameId = game.GameId}; State.ShowNotification("Enabled auto-execute for '" .. exactName .. "'.", "Success")
		end
		State.SaveConfiguration(); State.RefreshAllCardStates(); State.UpdateFilter()
	end)))

	State.RegCardConn(card.Activated:Connect(function()
		if State.isDestroying then return end
		if tick() - innerActionTime < 0.2 then return end

		local function executeScript()
			if type(State.CompileFunction) ~= "function" then
				State.ShowNotification("Execution disabled: this executor does not provide a compatible Lua compiler.", "Error")
				return
			end
			titleLbl.Text = "Running script..."; titleLbl.TextColor3 = State.Theme.Accent
			task.spawn(function()
				local raw = State.FetchWithRetry(type(data.RawUrl) == "string" and data.RawUrl or "", 2)
				if State.isDestroying then return end
				if not raw then
					State.ShowNotification("Failed to download script. Please check your connection.", "Error")
				elseif string.find(raw, "404: Not Found") then
					State.ShowNotification("The script link is broken or no longer available (404 Error).", "Error")
				else
					local success = State.ExecuteSandboxed(raw, exactName)
					if success then
						State.ShowNotification("Successfully executed [" .. exactName .. "]!", "Execution")
					end
				end

				if titleLbl and titleLbl.Parent then
					titleLbl.Text = exactName; titleLbl.TextColor3 = State.Theme.TextPrimary
				end
			end)
		end

		if State.SavedData.AutoExecutes[exactName] ~= nil then
			State.AttemptActionWithCooldown(executeScript)
		else
			State.OpenConfirmDialog(exactName, executeScript)
		end
	end))

	card.Parent = renderParent
	State.CacheInstanceAndDescendants(card)
	if registerImmediately ~= false then table.insert(State.RegisteredScripts, scriptEntry) end
	return scriptEntry
end

State.CATALOG_URL = "https://raw.githubusercontent.com/KingBacconnnn/VeloxScripts/refs/heads/main/catalog.json"
State.CATALOG_REFRESH_INTERVAL = 300
State.dbRefreshing = false
State.CatalogRefreshQueued = false
State.LastCatalogFingerprint = nil

function State.BuildCatalogFingerprint(entries)
	local parts = {}
	for index, entry in ipairs(entries) do
		if type(entry) == "table" then
			parts[#parts + 1] = table.concat({
				tostring(entry.Name or ""), tostring(entry.Description or ""), tostring(entry.RawUrl or ""),
				tostring(entry.ImageAssetId or ""), tostring(State.NormalizeTagType(entry.TagType)),
				tostring(State.GetSafeTimestamp(entry.LastUpdated)), tostring(tonumber(entry.PlaceId) or 0),
				tostring(entry.Category or ""), tostring(entry.Author or ""), tostring(index)
			}, "\31")
		end
	end
	return table.concat(parts, "\30")
end

State.PendingTasks.__LoadCatalog = function(force)
	if State.isDestroying then return false end
	if State.dbRefreshing then
		State.CatalogRefreshQueued = true
		State.PendingTasks.__CatalogRefreshForce = State.PendingTasks.__CatalogRefreshForce or force == true
		return false
	end
	local now = os.clock()
	if not force and now - State.LastCatalogRefreshAt < State.CatalogRefreshCooldown then
		State.CatalogRefreshQueued = true
		return false
	end

	State.LastCatalogRefreshAt = now
	State.dbRefreshing = true
	State.CatalogGeneration = State.CatalogGeneration + 1
	local generation = State.CatalogGeneration
	local savedScroll = State.ScriptsView.CanvasPosition
	State.ShowNotification("Fetching latest script catalog...", "System")
	State.StatusDot.BackgroundColor3 = State.Theme.Warning
	State.StatusText.Text = "Connecting..."
	State.StatusText.TextColor3 = State.Theme.Warning

	local function FinishRefresh()
		if generation ~= State.CatalogGeneration then return end
		State.dbRefreshing = false
		if State.CatalogRefreshQueued and not State.isDestroying then
			local queuedForce = State.PendingTasks.__CatalogRefreshForce == true
			State.CatalogRefreshQueued = false
			State.PendingTasks.__CatalogRefreshForce = false
			task.defer(function()
				if not State.isDestroying then State.PendingTasks.__LoadCatalog(queuedForce) end
			end)
		end
	end

	local function DisconnectEntryConnections()
		for i = #State.CardConnections, 1, -1 do
			local conn = State.CardConnections[i]
			if typeof(conn) == "RBXScriptConnection" and not conn.Connected then table.remove(State.CardConnections, i) end
		end
	end
	local activeBuildFolder = nil
	local activeNewEntries = {}

	State.TrackTask(function()
		local taskOk, taskErr = xpcall(function()
			local raw = State.FetchWithRetry(State.CATALOG_URL, 3, true)
			if not State.IsTaskCurrent(generation) then return end
			if not raw then
				if #State.RegisteredScripts == 0 then State.EmptyStateMessage.Visible = true; State.EmptyStateMessage.Text = "Unable to reach script catalog server." end
				State.StatusDot.BackgroundColor3 = State.Theme.Error
				State.StatusText.Text = "Offline"
				State.StatusText.TextColor3 = State.Theme.Error
				State.ShowNotification("Could not connect to the script catalog server.", "Error")
				FinishRefresh()
				return
			end

			local success, parsed = pcall(function() return State.HttpService:JSONDecode(raw) end)
			if not success or type(parsed) ~= "table" then
				if #State.RegisteredScripts == 0 then State.EmptyStateMessage.Visible = true; State.EmptyStateMessage.Text = "Failed to parse catalog data format." end
				State.StatusDot.BackgroundColor3 = State.Theme.Error
				State.StatusText.Text = "Data Error"
				State.StatusText.TextColor3 = State.Theme.Error
				State.ShowNotification("Catalog data format error.", "Error")
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
						TagType = State.NormalizeTagType(entry.TagType),
						LastUpdated = State.GetSafeTimestamp(entry.LastUpdated),
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

			local fingerprint = State.BuildCatalogFingerprint(validEntries)
			if fingerprint == State.LastCatalogFingerprint then
				State.RefreshAllCardStates()
				State.StatusDot.BackgroundColor3 = State.Theme.Success
				State.StatusText.Text = "Online"
				State.StatusText.TextColor3 = State.Theme.Success
				State.ShowNotification("Catalog is already up to date.", "Info")
				FinishRefresh()
				return
			end

			local previousByKey = State.RegisteredScripts.__ByKey or {}
			local nextByKey = {}
			local nextEntries = {}
			local nextKeys = {}
			local replacedEntries = {}
			table.clear(activeNewEntries)
			activeBuildFolder = Instance.new("Folder")
			activeBuildFolder.Name = "__VeloxCatalogBuild"
			activeBuildFolder.Parent = State.ScriptsView

			local function BuildEntryFingerprint(data)
				return table.concat({ tostring(data.Name or ""), tostring(data.Description or ""), tostring(data.RawUrl or ""), tostring(data.ImageAssetId or ""), tostring(State.NormalizeTagType(data.TagType)), tostring(State.GetSafeTimestamp(data.LastUpdated)), tostring(tonumber(data.State.PlaceId) or 0), tostring(data.Category or ""), tostring(data.Author or "") }, "\31")
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
				if not State.IsTaskCurrent(generation) then CleanupNewEntries(); FinishRefresh(); return end
				local key = tostring(scriptData.Name or "")
				local entryFingerprint = BuildEntryFingerprint(scriptData)
				local existing = previousByKey[key]
				local entry
				if existing and existing.EntryFingerprint == entryFingerprint and existing.Instance and existing.Instance.Parent then
					entry = existing
					entry.OriginalIndex = index
				else
					if existing then replacedEntries[#replacedEntries + 1] = existing end
					entry = State.CreateScriptCard(scriptData, activeBuildFolder, false, index)
					entry.EntryFingerprint = entryFingerprint
					entry.OriginalIndex = index
					activeNewEntries[#activeNewEntries + 1] = entry
				end
				nextEntries[#nextEntries + 1] = entry
				nextByKey[key] = entry
				nextKeys[key] = true
			end

			if not State.IsTaskCurrent(generation) then CleanupNewEntries(); FinishRefresh(); return end
			for key, oldEntry in pairs(previousByKey) do
				if not nextKeys[key] then DestroyEntry(oldEntry) end
			end
			for _, entry in ipairs(replacedEntries) do DestroyEntry(entry) end
			for _, entry in ipairs(nextEntries) do
				if entry.Instance and entry.Instance.Parent ~= State.ScriptsView then entry.Instance.Parent = State.ScriptsView end
				entry.Instance.LayoutOrder = entry.OriginalIndex
			end
			if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
			activeBuildFolder = nil
			table.clear(activeNewEntries)
			DisconnectEntryConnections()

			table.clear(State.RegisteredScripts)
			for _, entry in ipairs(nextEntries) do State.RegisteredScripts[#State.RegisteredScripts + 1] = entry end
			State.RegisteredScripts.__ByKey = nextByKey
			State.LastCatalogFingerprint = fingerprint
			State.RefreshAllCardStates()
			State.UpdateFilter()
			task.defer(function()
				if State.IsTaskCurrent(generation) and State.ScriptsView and State.ScriptsView.Parent then State.ScriptsView.CanvasPosition = savedScroll end
			end)

			local validMap = {}
			for _, scriptData in ipairs(validEntries) do validMap[scriptData.Name] = true end
			local cleaned = false
			for key in pairs(State.SavedData.AutoExecutes) do
				if not validMap[key] then State.SavedData.AutoExecutes[key] = nil; cleaned = true end
			end
			if cleaned then State.SaveConfiguration() end

			if not State.AutoExecuteRanThisSession then
				State.AutoExecuteRanThisSession = true
				local autoQueue = {}
				for _, scriptData in ipairs(validEntries) do
					local auto = State.SavedData.AutoExecutes[scriptData.Name]
					if type(auto) == "table" then
						local validPlace = auto.GameId and auto.GameId ~= 0 and auto.GameId == game.GameId
						if not validPlace then validPlace = auto.PlaceId == State.PlaceId or auto.PlaceId == 0 or not auto.PlaceId end
						if validPlace then autoQueue[#autoQueue + 1] = scriptData end
					end
				end
				if #autoQueue > 0 then
					State.TrackTask(function()
						if type(State.CompileFunction) ~= "function" then State.ShowNotification("Auto-execute skipped: this executor does not provide a compatible Lua compiler.", "Error"); return end
						local successList, failList = {}, {}
						State.ShowNotification("Processing " .. #autoQueue .. " auto-execute script(s)...", "Info")
						for _, scriptData in ipairs(autoQueue) do
							if not State.IsTaskCurrent(generation) then return end
							local scrRaw = State.FetchWithRetry(scriptData.RawUrl, 2)
							if not State.IsTaskCurrent(generation) then return end
							if scrRaw and not string.find(scrRaw, "404: Not Found") then
								if State.ExecuteSandboxed(scrRaw, scriptData.Name) then successList[#successList + 1] = scriptData.Name else failList[#failList + 1] = scriptData.Name end
							else
								failList[#failList + 1] = scriptData.Name
							end
							task.wait(0.3)
						end
						if #successList > 0 then State.ShowNotification("Auto-executed: " .. table.concat(successList, ", "), "Success") end
						if #failList > 0 then State.ShowNotification("Auto-execution failed for: " .. table.concat(failList, ", "), "Warning") end
					end)
				end
			end

			State.StatusDot.BackgroundColor3 = State.Theme.Success
			State.StatusText.Text = "Online"
			State.StatusText.TextColor3 = State.Theme.Success
			State.ShowNotification("Script catalog loaded successfully!", "Success")
		end, function(err) return tostring(err) end)

		if not taskOk then
			if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
			activeBuildFolder = nil
			table.clear(activeNewEntries)
			DisconnectEntryConnections()
		end
		if not taskOk and not State.isDestroying and generation == State.CatalogGeneration then
			State.StatusDot.BackgroundColor3 = State.Theme.Error
			State.StatusText.Text = "Catalog Error"
			State.StatusText.TextColor3 = State.Theme.Error
			State.ShowNotification("Catalog refresh failed safely.", "Error")
		end
		FinishRefresh()
	end)
	return true
end

State.PendingTasks.__LoadCatalog()

State.TrackTask(function()
	while not State.isDestroying do
		task.wait(State.CATALOG_REFRESH_INTERVAL)
		if State.isDestroying then break end
		State.PendingTasks.__LoadCatalog(false)
	end
end)

State.TrackTask(function()
	while not State.isDestroying do
		task.wait(60)
		if State.isDestroying then break end
		for _, scrData in ipairs(State.RegisteredScripts) do
			if scrData.TimeLabel and scrData.TimeLabel.Parent then
				scrData.TimeLabel.Text = State.GetRelativeTime(scrData.LastUpdatedNumber)
			end
		end
	end
end)

function State.CreateSettingsGroup(titleText, parentView, order)
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
	header.TextColor3 = State.Theme.TextSecondary
	header.Font = Enum.Font.GothamBold
	header.TextSize = 10
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = 1
	local card = Instance.new("Frame", container)
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = State.Theme.CardHover
	card.LayoutOrder = 2
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local cardGradient = Instance.new("UIGradient", card)
	cardGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, State.Theme.CardHover),
		ColorSequenceKeypoint.new(1, State.Theme.Card)
	})
	cardGradient.Rotation = 45
	local cardLayout = Instance.new("UIListLayout", card)
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 0)
	return card
end

function State.CreateSettingRowInGroup(groupCard, title, desc, iconAsset, order)
	if order > 1 then
		local divider = Instance.new("Frame", groupCard)
		divider.Size = UDim2.new(1, -24, 0, 1)
		divider.Position = UDim2.new(0, 12, 0, 0)
		divider.BackgroundColor3 = State.Theme.Stroke
		divider.BackgroundTransparency = 0.6
		divider.BorderSizePixel = 0
		divider.LayoutOrder = (order - 1) * 2
	end
	local row = Instance.new("Frame", groupCard)
	row.Size = UDim2.new(1, 0, 0, State.IsMobile and 56 or 60)
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
	iconContainer.BackgroundColor3 = State.Theme.Accent
	iconContainer.BackgroundTransparency = 0.85
	Instance.new("UICorner", iconContainer).CornerRadius = UDim.new(0, 8)
	local iconImg = Instance.new("ImageLabel", iconContainer)
	iconImg.Size = UDim2.new(0, 18, 0, 18)
	iconImg.Position = UDim2.new(0.5, -9, 0.5, -9)
	iconImg.BackgroundTransparency = 1
	iconImg.Image = iconAsset or "rbxassetid://10709782497"
	iconImg.ImageColor3 = State.Theme.Accent
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
	t.TextColor3 = State.Theme.TextPrimary
	t.Font = Enum.Font.GothamBold
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.LayoutOrder = 1
	local d = Instance.new("TextLabel", textContainer)
	d.Size = UDim2.new(1, 0, 0, 14)
	d.BackgroundTransparency = 1
	d.Text = desc
	d.TextColor3 = State.Theme.TextSecondary
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

function State.CreateToggleSettingInGroup(groupCard, title, desc, iconAsset, order, defaultValue, callback)
	local row, rightContainer = State.CreateSettingRowInGroup(groupCard, title, desc, iconAsset, order)
	local toggleBtn = Instance.new("TextButton", rightContainer)
	toggleBtn.Size = UDim2.new(0, 44, 0, 22)
	toggleBtn.Position = UDim2.new(1, -44, 0.5, -11)
	toggleBtn.BackgroundColor3 = defaultValue and State.Theme.Accent or State.Theme.BackgroundMain
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = false
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
	local toggleStroke = Instance.new("UIStroke", toggleBtn)
	toggleStroke.Color = defaultValue and State.Theme.Accent or State.Theme.Stroke
	toggleStroke.Thickness = 1
	local circle = Instance.new("Frame", toggleBtn)
	circle.Size = UDim2.new(0, 16, 0, 16)
	circle.Position = defaultValue and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
	local state = defaultValue
	State.RegConn(toggleBtn.Activated:Connect(State.CreateDebounce(0.1, function()
		if State.isDestroying then return end
		state = not state
		State.SafeTween(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = state and State.Theme.Accent or State.Theme.BackgroundMain
		})
		State.SafeTween(toggleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = state and State.Theme.Accent or State.Theme.Stroke
		})
		State.SafeTween(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		})
		if type(callback) == "function" then task.spawn(callback, state) end
	end)))
end

function State.CreateButtonSettingInGroup(groupCard, title, desc, iconAsset, btnText, order, isDestructive, callback)
	local row, rightContainer = State.CreateSettingRowInGroup(groupCard, title, desc, iconAsset, order)
	local btn = Instance.new("TextButton", rightContainer)
	btn.Size = UDim2.new(0, 95, 0, 26)
	btn.Position = UDim2.new(1, -95, 0.5, -13)
	btn.BackgroundColor3 = State.Theme.BackgroundMain
	btn.BackgroundTransparency = 0.4
	btn.Text = btnText
	btn.TextColor3 = isDestructive and State.Theme.Error or State.Theme.TextPrimary
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 11
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = isDestructive and State.Theme.Error or State.Theme.Stroke
	btnStroke.Thickness = 1
	local hoverColor = isDestructive and Color3.fromRGB(55, 25, 25) or State.Theme.CardHover
	local hoverStroke = isDestructive and State.Theme.Error or State.Theme.Accent
	State.ApplyInteractiveAnimations(btn, State.Theme.BackgroundMain, hoverColor, Color3.fromRGB(10, 15, 30), btnStroke, btnStroke.Color, hoverStroke)
	State.RegConn(btn.Activated:Connect(State.CreateDebounce(0.1, function()
		if State.isDestroying then return end
		if type(callback) == "function" then task.spawn(callback, btn) end
	end)))
	return btn
end

State.prefGroup = State.CreateSettingsGroup("User Preferences", State.SettingsView, 1)

State.kbRightContainer = select(2, State.CreateSettingRowInGroup(State.prefGroup, "Toggle UI", "Keybind to show or hide hub.", "rbxassetid://10709790537", 1))
State.KeybindButton = Instance.new("TextButton", State.kbRightContainer)
State.KeybindButton.Size = UDim2.new(0, 95, 0, 26)
State.KeybindButton.Position = UDim2.new(1, -95, 0.5, -13)
State.KeybindButton.BackgroundColor3 = State.Theme.BackgroundMain
State.KeybindButton.BackgroundTransparency = 0.4
State.KeybindButton.Text = State.ToggleKeybind.Name
State.KeybindButton.TextColor3 = State.Theme.TextPrimary
State.KeybindButton.Font = Enum.Font.GothamMedium
State.KeybindButton.TextSize = 11
State.KeybindButton.AutoButtonColor = false
Instance.new("UICorner", State.KeybindButton).CornerRadius = UDim.new(0, 6)
State.kbBtnStroke = Instance.new("UIStroke", State.KeybindButton)
State.kbBtnStroke.Color = State.Theme.Stroke
State.KeybindButtonRef = State.KeybindButton
State.ApplyInteractiveAnimations(State.KeybindButton, State.Theme.BackgroundMain, State.Theme.CardHover, Color3.fromRGB(10, 15, 30), State.kbBtnStroke, State.Theme.Stroke, State.Theme.Accent)

State.RegConn(State.KeybindButton.Activated:Connect(State.CreateDebounce(0.1, function()
	if State.isDestroying or State.IsBindingKey then return end
	State.IsBindingKey = true
	State.KeybindButton.Text = "Press Any..."
	State.ShowNotification("Press any key to bind (Press Escape to cancel).", "System")

	if State.KeybindCaptureConnection then
		State.UnregConn(State.KeybindCaptureConnection)
		State.KeybindCaptureConnection = nil
	end

	State.KeybindCaptureConnection = State.RegConn(State.UserInputService.InputBegan:Connect(function(input)
		if State.isDestroying then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				State.IsBindingKey = false
				if State.KeybindButtonRef then State.KeybindButtonRef.Text = State.ToggleKeybind.Name end
				State.ShowNotification("Keybind mapping canceled.", "Warning")
				if State.KeybindCaptureConnection then
					State.UnregConn(State.KeybindCaptureConnection)
					State.KeybindCaptureConnection = nil
				end
				return
			end
			if input.KeyCode.Name ~= "Unknown" then
				State.ToggleKeybind = input.KeyCode
				State.IsBindingKey = false
				State.SavedData.ToggleKeybind = State.ToggleKeybind.Name
				State.SaveConfiguration()
				if State.KeybindButtonRef then State.KeybindButtonRef.Text = State.ToggleKeybind.Name end
				State.ShowNotification("Keybind successfully updated to: " .. input.KeyCode.Name, "Success")

				State.BindToggleKey(State.ToggleKeybind)

				if State.KeybindCaptureConnection then
					State.UnregConn(State.KeybindCaptureConnection)
					State.KeybindCaptureConnection = nil
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			State.IsBindingKey = false
			if State.KeybindButtonRef then State.KeybindButtonRef.Text = State.ToggleKeybind.Name end
			State.ShowNotification("Keybind mapping canceled.", "Warning")
			if State.KeybindCaptureConnection then
				State.UnregConn(State.KeybindCaptureConnection)
				State.KeybindCaptureConnection = nil
			end
		end
	end))
end)))

function State.TriggerAntiAFKAction()
	if State.VirtualUser then
		pcall(function()
			State.VirtualUser:CaptureController()
			State.VirtualUser:ClickButton2(Vector2.new())
		end)
	elseif State.VirtualInputManager then
		pcall(function()
			State.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
			task.wait(0.1)
			State.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
		end)
	end
end

State.CreateToggleSettingInGroup(State.prefGroup, "Anti-AFK", "Prevents idle kicks.", "rbxassetid://10734898592", 2, State.SavedData.Settings.AntiAFK, function(val)
	State.SavedData.Settings.AntiAFK = val
	State.SaveConfiguration()
	if val then
		State.ShowNotification("Anti-AFK system engaged.", "Success")
		if not State.AfkConnections.Idled then
			State.AfkConnections.Idled = State.RegConn(State.LocalPlayer.Idled:Connect(State.TriggerAntiAFKAction))
		end
		if getconnections then
			pcall(function()
				for _, conn in pairs(getconnections(State.LocalPlayer.Idled)) do
					pcall(function()
						if type(conn) == "table" and conn.Disable then
							conn:Disable()
							table.insert(State.AfkConnections, conn)
						elseif typeof(conn) == "RBXScriptConnection" and conn.Disable then
							conn:Disable()
							table.insert(State.AfkConnections, conn)
						end
					end)
				end
			end)
		end
	else
		State.ShowNotification("Anti-AFK deactivated.", "Warning")
		if State.AfkConnections.Idled then State.AfkConnections.Idled:Disconnect(); State.AfkConnections.Idled = nil end
		for _, conn in ipairs(State.AfkConnections) do
			pcall(function()
				if type(conn) == "table" and conn.Enable then
					conn:Enable()
				elseif typeof(conn) == "RBXScriptConnection" and conn.Enable then
					conn:Enable()
				end
			end)
		end
		table.clear(State.AfkConnections)
	end
end)

State.actionGroup = State.CreateSettingsGroup("System Actions", State.SettingsView, 2)

State.CreateButtonSettingInGroup(State.actionGroup, "Refresh Catalog", "Fetches latest scripts.", "rbxassetid://10734976528", "Refresh", 1, false, function()
	State.AttemptActionWithCooldown(function()
		if State.dbRefreshing then
			State.CatalogRefreshQueued = true
			State.ShowNotification("Catalog refresh queued.", "Info")
			return
		end
		LoadDynamicCatalog(true)
	end)
end)

State.CreateButtonSettingInGroup(State.actionGroup, "Unload Hub", "Removes Velox Hub completely.", "rbxassetid://10709753149", "Unload", 2, true, function()
	State.ShowNotification("Unloading Velox Hub...", "Info")
	task.wait(0.3)
	State.CloseUI()
end)

if State.SavedData.Settings.AntiAFK then
	if not State.AfkConnections.Idled then
		State.AfkConnections.Idled = State.RegConn(State.LocalPlayer.Idled:Connect(State.TriggerAntiAFKAction))
	end
	if getconnections then
		pcall(function()
			for _, conn in pairs(getconnections(State.LocalPlayer.Idled)) do
				pcall(function()
					if type(conn) == "table" and conn.Disable then
						conn:Disable()
						table.insert(State.AfkConnections, conn)
					elseif typeof(conn) == "RBXScriptConnection" and conn.Disable then
						conn:Disable()
						table.insert(State.AfkConnections, conn)
					end
				end)
			end
		end)
	end
end

State.TabViews["Changelogs"].Visible = true
State.TabViews["Scripts"].Visible = false
State.TabViews["Settings"].Visible = false
State.TabIndicator.Position = UDim2.new(0, 4, 1, -2)
State.SectionHeaderLabel.Text = "Updates"
State.MainPanel.Visible = true
State.SearchRow.Visible = false
State.FloatingBtn.Visible = false

State.ShowNotification("Velox Hub is ready for use!", "Success")

if State.IsMobile then
	local UserDataGroup = State.CreateSettingsGroup("User Data", State.SettingsView, 3)
	State.CreateButtonSettingInGroup(UserDataGroup, "Clear UI Cache", "Resets layout position.", "rbxassetid://10734940376", "Reset", 1, true, function()
		if State.isDestroying then return end
		table.clear(State.OriginalCache)
		State.MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
		State.FloatingBtn.Position = UDim2.new(0.5, 0, 0, 42.5)
		State.CacheInstanceAndDescendants(State.MainPanel)
		State.CacheInstanceAndDescendants(State.FloatingBtn)
		State.ShowNotification("UI Cache cleared successfully.", "Success")
	end)
end
