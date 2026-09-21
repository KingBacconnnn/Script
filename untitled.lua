GlobalEnv = _G
if type(getgenv) == "function" then
	ok, env = pcall(getgenv)
	if ok and type(env) == "table" then
		GlobalEnv = env
	end
end
function _VH_GenerateRandomString(len)
	chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	str = ""
	for i = 1, len do
		r = math.random(1, #chars)
		str = str .. string.sub(chars, r, r)
	end
	return str
end
_G_Identifier = "VeloxHub_Core_Cleanup_V3_6"
if GlobalEnv[_G_Identifier] then
	pcall(function() GlobalEnv[_G_Identifier]() end)
end
Services = setmetatable({}, {
	__index = function(self, key)
		success, service = pcall(function() return game:GetService(key) end)
		if not success or not service then return nil end
		final = service
		if type(cloneref) == "function" then
			cloneOk, cloneResult = pcall(cloneref, service)
			if cloneOk and cloneResult then final = cloneResult end
		end
		self[key] = final
		return final
	end
})
Players = Services.Players
UserInputService = Services.UserInputService
HttpService = Services.HttpService
StarterGui = Services.StarterGui
RunService = Services.RunService
CoreGui = Services.CoreGui
TweenService = Services.TweenService
GuiService = Services.GuiService
LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	task.wait()
	LocalPlayer = Players.LocalPlayer
end
PlaceId = game.PlaceId
GameId = game.GameId
gethui = type(gethui) == "function" and gethui or function() return nil end
protectgui = type(protectgui) == "function" and protectgui or ((type(syn) == "table" and type(syn.protect_gui) == "function") and syn.protect_gui or function(...) return ... end)
exec_request = nil
if type(request) == "function" then
	exec_request = request
elseif type(http_request) == "function" then
	exec_request = http_request
elseif type(syn) == "table" and type(syn.request) == "function" then
	exec_request = syn.request
elseif type(fluxus) == "table" and type(fluxus.request) == "function" then
	exec_request = fluxus.request
elseif type(krnl) == "table" and type(krnl.request) == "function" then
	exec_request = krnl.request
end
write_file = type(writefile) == "function" and writefile or nil
read_file = type(readfile) == "function" and readfile or nil
is_file = type(isfile) == "function" and isfile or nil
CompileFunction = nil
function _VH_TryCompiler(fn, source, chunkName)
	if type(fn) ~= "function" then return false, nil end
	local ok, chunk, err = pcall(fn, source, chunkName)
	if ok and type(chunk) == "function" then
		return true, chunk, nil
	end
	local okSingle, chunkSingle, errSingle = pcall(fn, source)
	if okSingle and type(chunkSingle) == "function" then
		return true, chunkSingle, nil
	end
	return false, nil, tostring(err or errSingle or chunk or chunkSingle or "compiler rejected source")
end
if type(loadstring) == "function" then
	CompileFunction = function(source, chunkName)
		ok, chunk, err = _VH_TryCompiler(loadstring, source, chunkName)
		if ok then return chunk end
		return nil, err
	end
elseif type(load) == "function" then
	CompileFunction = function(source, chunkName)
		ok, chunk, err = _VH_TryCompiler(load, source, chunkName)
		if ok then return chunk end
		return nil, err
	end
end
Theme = {
	Accent = Color3.fromRGB(99, 102, 241),
	BackgroundMain = Color3.fromRGB(15, 23, 42),
	BackgroundSecondary = Color3.fromRGB(20, 29, 55),
	Card = Color3.fromRGB(24, 33, 50),
	CardHover = Color3.fromRGB(30, 41, 59),
	TextPrimary = Color3.fromRGB(248, 250, 252),
	TextSecondary = Color3.fromRGB(203, 213, 225),
	Success = Color3.fromRGB(16, 185, 129),
	Error = Color3.fromRGB(180, 50, 50),
	Warning = Color3.fromRGB(220, 140, 15),
	Info = Color3.fromRGB(56, 189, 248),
	System = Color3.fromRGB(168, 85, 247),
	Execution = Color3.fromRGB(190, 55, 110),
	Stroke = Color3.fromRGB(51, 65, 85),
	ToggleOff = Color3.fromRGB(71, 85, 105)
}
VeloxConnections = {}
RegisteredScripts = {}
PendingTasks = {}
ActiveTweens = setmetatable({}, { __mode = "k" })
CatalogGeneration = 0
LastCatalogRefreshAt = 0
RecommendationGeneration = 0
RecommendationItems = {}
RecommendationConnections = {}
RecommendationPanel = nil
RecommendationList = nil
RecommendationSubtitle = nil
RecommendationPage = 1
RecommendationPageSize = 3
RecommendationPageCount = 1
RecommendationRenderSignature = ""
FavoriteRecommendationLimit = 8
FavoriteRecommendationMaxBoost = 12
FavoriteRecommendationRefreshDelay = 0.35
FavoriteRecommendationRefreshGeneration = 0
AutoExecuteRanThisSession = false
InteractiveElements = setmetatable({}, { __mode = "k" })
isDestroying = false
isMinimized = false
isTransitioning = false
IsBindingKey = false
IsMobile = UserInputService.TouchEnabled and (not UserInputService.MouseEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y <= 800) or GuiService:IsTenFootInterface())
mainDragConnection, floatDragConnection = nil, nil
activeMainDragInput, activeFloatDragInput = nil, nil
ToggleKeybindConnection = nil
KeybindCaptureConnection = nil
DropdownContainer = nil
ToastContainer = nil
ConfirmOverlay = nil
ScriptDetailsOverlay = nil
ScriptDetailsUIScale = nil
GlobalCooldownBanner = nil
GlobalCooldownLoopVersion = 0
GlobalActionCooldownEndTime = 0
OriginalCache = setmetatable({}, { __mode = "k" })
AntiAFKConnection = nil
AntiAFKDisabledConnections = {}
DisableAntiAFK = nil
function _VH_CacheInstanceAndDescendants(root)
	local function CacheObj(obj)
		if not obj or OriginalCache[obj] then return end
		c = {}
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
function _VH_RegConn(connection)
	if connection and typeof(connection) == "RBXScriptConnection" then
		table.insert(VeloxConnections, connection)
	end
	return connection
end
function _VH_UnregConn(connection)
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
function _VH_TrackTask(fn)
	local thread = nil
	thread = task.spawn(function()
		pcall(fn)
		PendingTasks[thread] = nil
	end)
	PendingTasks[thread] = true
	return thread
end
function _VH_IsTaskCurrent(generation)
	return not isDestroying and generation == CatalogGeneration
end
function _VH_CancelTrackedTasks()
	for thread in pairs(PendingTasks) do
		if type(thread) == "thread" then pcall(task.cancel, thread) end
	end
	table.clear(PendingTasks)
end
typingTask = nil
function _VH_CleanUpMemory()
	isDestroying = true
	GlobalEnv[_G_Identifier] = nil
	if typingTask then pcall(task.cancel, typingTask); typingTask = nil end
	_VH_CancelTrackedTasks()
	if mainDragConnection then pcall(function() mainDragConnection:Disconnect() end) end
	if floatDragConnection then pcall(function() floatDragConnection:Disconnect() end) end
	if ToggleKeybindConnection then _VH_UnregConn(ToggleKeybindConnection); ToggleKeybindConnection = nil end
	if KeybindCaptureConnection then _VH_UnregConn(KeybindCaptureConnection); KeybindCaptureConnection = nil end
	if DisableAntiAFK then DisableAntiAFK() end
	for _, conn in ipairs(VeloxConnections) do
		if typeof(conn) == "RBXScriptConnection" and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(VeloxConnections)
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
	if ScriptDetailsOverlay and ScriptDetailsOverlay.Parent then pcall(function() ScriptDetailsOverlay:Destroy() end) end
	if GlobalCooldownBanner and GlobalCooldownBanner.Parent then pcall(function() GlobalCooldownBanner:Destroy() end) end
	for _, connection in ipairs(RecommendationConnections) do
		if typeof(connection) == "RBXScriptConnection" and connection.Connected then pcall(function() connection:Disconnect() end) end
	end
	table.clear(RecommendationConnections)
	if RecommendationPanel and RecommendationPanel.Parent then pcall(function() RecommendationPanel:Destroy() end) end
	table.clear(RegisteredScripts)
	table.clear(ActiveTweens)
	table.clear(InteractiveElements)
	table.clear(OriginalCache)
end
function _VH_SafeTween(instance, tweenInfo, properties)
	if not instance or not instance.Parent then return nil end
	local oldData
	local tween
	local conn
	if ActiveTweens[instance] then
		oldData = ActiveTweens[instance]
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
	tween = TweenService:Create(instance, tweenInfo, properties)
	conn = nil
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
function _VH_CreateDebounce(cooldown, func)
	local isRunning = false
	return function(...)
		if isRunning or isDestroying then return end
		isRunning = true
		local args = {...}
		task.spawn(function()
			xpcall(function()
				func(unpack(args))
			end, function() end)
			task.wait(cooldown)
			isRunning = false
		end)
	end
end
DATA_FILE = ".VeloxHub_Data_V3.1.json"
make_folder = type(makefolder) == "function" and makefolder or nil
SavedData = {
	Favorites = {},
	AutoExecutes = {},
	ToggleKeybind = "RightControl",
	Settings = { AntiAFK = false, UIScale = 1 }
}
SavedConfigExtras = {}
ConfigurationLoaded = false
ConfigurationLoadError = nil

function _VH_EnsureConfigDirectory(path)
	if type(make_folder) ~= "function" or type(path) ~= "string" then return true end
	local dir = string.match(path, "^(.*)[/\\][^/\\]+$")
	if not dir or dir == "" then return true end
	local ok = pcall(function() make_folder(dir) end)
	return ok
end

function _VH_SanitizeForJSON(data, seen, depth)
	depth = (tonumber(depth) or 0) + 1
	if depth > 64 then return nil end
	local valueType = type(data)
	if valueType == "string" or valueType == "boolean" then return data end
	if valueType == "number" then
		if data ~= data or data == math.huge or data == -math.huge then return nil end
		return data
	end
	if valueType ~= "table" then return nil end
	seen = seen or {}
	if seen[data] then return nil end
	seen[data] = true
	local out = {}
	for k, v in pairs(data) do
		local keyType = type(k)
		if keyType == "string" or keyType == "number" then
			local cleanVal = _VH_SanitizeForJSON(v, seen, depth)
			if cleanVal ~= nil then out[tostring(k)] = cleanVal end
		end
	end
	seen[data] = nil
	return out
end

function _VH_JsonEscapeString(value)
	local s = tostring(value)
	s = string.gsub(s, "\\", "\\\\")
	s = string.gsub(s, '"', '\\"')
	s = string.gsub(s, "\b", "\\b")
	s = string.gsub(s, "\f", "\\f")
	s = string.gsub(s, "\n", "\\n")
	s = string.gsub(s, "\r", "\\r")
	s = string.gsub(s, "\t", "\\t")
	return '"' .. s .. '"'
end

function _VH_NumberToJSON(value)
	local n = tonumber(value)
	if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
	local s = string.format("%.17g", n)
	if string.find(s, "[^%d%+%-%eE%.]", 1) then return nil end
	return s
end

function _VH_EncodeJSONFallback(value, stack, depth)
	depth = (tonumber(depth) or 0) + 1
	if depth > 64 then return nil end
	local t = type(value)
	if t == "nil" then return "null" end
	if t == "boolean" then return value and "true" or "false" end
	if t == "string" then return _VH_JsonEscapeString(value) end
	if t == "number" then return _VH_NumberToJSON(value) end
	if t ~= "table" then return nil end
	stack = stack or {}
	if stack[value] then return nil end
	stack[value] = true
	local parts = {}
	for k, v in pairs(value) do
		local keyType = type(k)
		if keyType ~= "string" and keyType ~= "number" then stack[value] = nil return nil end
		local encodedValue = _VH_EncodeJSONFallback(v, stack, depth)
		if not encodedValue then stack[value] = nil return nil end
		parts[#parts + 1] = _VH_JsonEscapeString(tostring(k)) .. ":" .. encodedValue
	end
	stack[value] = nil
	return "{" .. table.concat(parts, ",") .. "}"
end

function _VH_EncodeConfiguration(data)
	local sanitized = _VH_SanitizeForJSON(data)
	if type(sanitized) ~= "table" then return nil, "configuration sanitization failed" end
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(sanitized)
	end)
	if ok and type(encoded) == "string" and encoded ~= "" then return encoded, nil end
	local fallbackOk, fallback = pcall(function()
		return _VH_EncodeJSONFallback(sanitized)
	end)
	if fallbackOk and type(fallback) == "string" and fallback ~= "" then return fallback, nil end
	return nil, "configuration JSON encoding failed"
end

function _VH_BuildConfigurationData()
	local cleanData = _VH_SanitizeForJSON(SavedConfigExtras)
	if type(cleanData) ~= "table" then cleanData = {} end
	cleanData.Favorites = {}
	cleanData.AutoExecutes = {}
	cleanData.ToggleKeybind = tostring(SavedData.ToggleKeybind or "RightControl")
	cleanData.Settings = {
		AntiAFK = SavedData.Settings.AntiAFK == true,
		UIScale = math.clamp(tonumber(SavedData.Settings.UIScale) or 1, 0.8, 1.2)
	}
	for k, v in pairs(SavedData.Favorites) do
		if v then cleanData.Favorites[tostring(k)] = true end
	end
	for k, v in pairs(SavedData.AutoExecutes) do
		if type(v) == "table" then
			local place = tonumber(v.PlaceId)
			local gameId = tonumber(v.GameId)
			local entry = { Name = type(v.Name) == "string" and v.Name or nil }
			if place then entry.PlaceId = place end
			if gameId then entry.GameId = gameId end
			if entry.PlaceId or entry.GameId then cleanData.AutoExecutes[tostring(k)] = entry end
		end
	end
	return cleanData
end

function SaveConfiguration()
	if type(write_file) ~= "function" then
		return false, "this executor does not expose a usable writefile() API"
	end
	if not _VH_EnsureConfigDirectory(DATA_FILE) then
		return false, "the configuration directory could not be created"
	end
	local cleanData = _VH_BuildConfigurationData()
	local result, encodeError = _VH_EncodeConfiguration(cleanData)
	if not result then return false, encodeError end
	local writeOk, writeResult = pcall(function() return write_file(DATA_FILE, result) end)
	if not writeOk or writeResult == false then
		return false, "writefile() failed for " .. tostring(DATA_FILE)
	end
	if type(read_file) == "function" then
		local verifyOk, verifyResult = pcall(function()
			local check = read_file(DATA_FILE)
			if type(check) ~= "string" or check == "" then return false end
			local decoded = HttpService:JSONDecode(check)
			return type(decoded) == "table"
		end)
		if not verifyOk or verifyResult ~= true then
			return false, "writefile() completed but the saved configuration could not be verified"
		end
	end
	return true, nil
end

function LoadConfiguration()
	ConfigurationLoaded = false
	ConfigurationLoadError = nil
	if type(read_file) ~= "function" then
		ConfigurationLoadError = "this executor does not expose readfile()"
		return false, ConfigurationLoadError
	end
	local exists = nil
	if type(is_file) == "function" then
		local existsOk, existsResult = pcall(function() return is_file(DATA_FILE) end)
		if existsOk then exists = existsResult == true end
	end
	if exists == false then
		ConfigurationLoaded = true
		return true, nil
	end
	local readOk, raw = pcall(function() return read_file(DATA_FILE) end)
	if not readOk or type(raw) ~= "string" or raw == "" then
		if exists == nil then ConfigurationLoadError = "the configuration file could not be read" return false, ConfigurationLoadError end
		ConfigurationLoaded = true
		return true, nil
	end
	local decodeOk, result = pcall(function() return HttpService:JSONDecode(raw) end)
	if not decodeOk or type(result) ~= "table" then
		ConfigurationLoadError = "the configuration file contains invalid JSON"
		return false, ConfigurationLoadError
	end
	SavedConfigExtras = {}
	for k, v in pairs(result) do
		if k ~= "Favorites" and k ~= "AutoExecutes" and k ~= "ToggleKeybind" and k ~= "Settings" then
			SavedConfigExtras[tostring(k)] = _VH_SanitizeForJSON(v)
		end
	end
	SavedData.Favorites = {}
	SavedData.AutoExecutes = {}
	if type(result.Favorites) == "table" then
		for k, v in pairs(result.Favorites) do if v then SavedData.Favorites[tostring(k)] = true end end
	end
	if type(result.AutoExecutes) == "table" then
		for k, v in pairs(result.AutoExecutes) do
			if type(k) == "string" and type(v) == "table" then
				local savedPlace = tonumber(v.PlaceId)
				local savedGame = tonumber(v.GameId)
				local savedName = type(v.Name) == "string" and v.Name or nil
				if savedPlace or savedGame then
					SavedData.AutoExecutes[tostring(k)] = { PlaceId = savedPlace, GameId = savedGame, Name = savedName }
				end
			end
		end
	end
	if type(result.ToggleKeybind) == "string" then SavedData.ToggleKeybind = result.ToggleKeybind end
	if type(result.Settings) == "table" then
		for k, v in pairs(result.Settings) do if k == "AntiAFK" or k == "UIScale" then SavedData.Settings[k] = v end end
	end
	SavedData.Settings.AntiAFK = SavedData.Settings.AntiAFK == true
	SavedData.Settings.UIScale = math.clamp(tonumber(SavedData.Settings.UIScale) or 1, 0.8, 1.2)
	ConfigurationLoaded = true
	return true, nil
end

LoadConfiguration()

function UniversalHttpGet(url)
	if type(url) ~= "string" or url == "" then return nil, nil, "invalid url" end
	if type(exec_request) == "function" then
		reqSuccess, reqResult = pcall(function() return exec_request({Url = url, Method = "GET"}) end)
		if not reqSuccess or not reqResult then
			reqSuccess, reqResult = pcall(function() return exec_request({url = url, method = "GET"}) end)
		end
		if reqSuccess and reqResult then
			body = type(reqResult) == "table" and (reqResult.Body or reqResult.body or reqResult.ResponseBody or reqResult.Response or reqResult.response) or (type(reqResult) == "string" and reqResult or nil)
			status = type(reqResult) == "table" and tonumber(reqResult.StatusCode or reqResult.Status or reqResult.status_code or reqResult.Code) or 200
			if status == nil and body then status = 200 end
			if body and tostring(body) ~= "" and (status == nil or (status >= 200 and status < 300)) then return tostring(body), status or 200, nil end
		end
	end
	if type(httpget) == "function" then
		success, result = pcall(httpget, url)
		if success and type(result) == "string" and result ~= "" then return result, 200, nil end
	end
	success, result = pcall(function() return game:HttpGet(url) end)
	if success and type(result) == "string" and result ~= "" then return result, 200, nil end
	success, result = pcall(function() return game:HttpGetAsync(url) end)
	if success and type(result) == "string" and result ~= "" then return result, 200, nil end
	if HttpService and type(HttpService.GetAsync) == "function" then
		success, result = pcall(function() return HttpService:GetAsync(url, true) end)
		if success and type(result) == "string" and result ~= "" then return result, 200, nil end
	end
	return nil, nil, "request failed"
end
function AddCacheBuster(url)
	if type(url) ~= "string" or url == "" then return url end
	local separator = string.find(url, "?", 1, true) and "&" or "?"
	local nonce = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
	return url .. separator .. "velox_cache=" .. nonce
end
function FetchWithRetry(url, retries, cacheBust)
	retries = math.max(1, tonumber(retries) or 3)
	local lastStatus, lastError = nil, nil
	for i = 1, retries do
		local requestUrl = cacheBust and AddCacheBuster(url) or url
		local response, status, err = UniversalHttpGet(requestUrl)
		lastStatus, lastError = status, err
		if response and type(response) == "string" and #response > 0 then
			return response, status, nil
		end
		if i < retries then task.wait(math.pow(2, i - 1)) end
	end
	return nil, lastStatus, lastError
end
TagTypeConfig = {
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
function NormalizeTagType(value)
	if type(value) ~= "string" then return "NONE" end
	normalized = string.upper(string.gsub(value, "^%s*(.-)%s*$", "%1"))
	if TagTypeConfig[normalized] then return normalized end
	return "NONE"
end

function _VH_RecommendationListFingerprint(value)
	local list = _VH_NormalizeRecommendationList(value)
	table.sort(list)
	return table.concat(list, "|")
end

function _VH_NormalizeRecommendationList(value)
	local list = {}
	local seen = {}
	local function add(v)
		if type(v) ~= "string" then return end
		local cleaned = string.lower(string.gsub(v, "^%s*(.-)%s*$", "%1"))
		if cleaned == "" or seen[cleaned] then return end
		seen[cleaned] = true
		list[#list + 1] = cleaned
	end
	if type(value) == "string" then
		for item in string.gmatch(value, "[^,;|]+") do add(item) end
	elseif type(value) == "table" then
		for _, item in ipairs(value) do add(item) end
	end
	return list
end

function _VH_GetRecommendationTokenSet(data)
	local set = {}
	local stopWords = {
		"the", "and", "for", "with", "from", "this", "that", "your", "you", "are", "can", "into", "more",
		"script", "scripts", "roblox", "game", "games", "play", "playing", "player", "players", "auto", "beta",
		"currently", "features", "feature", "use", "using", "while", "through", "with", "convenient", "progress"
	}
	local function addText(value)
		if type(value) ~= "string" then return end
		value = string.lower(value)
		value = string.gsub(value, "[^%w%s]", " ")
		for word in string.gmatch(value, "%S+") do
			if #word >= 3 and not stopWords[word] then set[word] = true end
		end
	end
	addText(data and data.Name)
	addText(data and data.Description)
	addText(data and data.Category)
	addText(data and data.Author)
	addText(data and data.TagType)
	if data and type(data.Tags) == "table" then
		for _, tag in ipairs(data.Tags) do addText(tag) end
	elseif data and type(data.Tags) == "string" then
		addText(data.Tags)
	end
	return set
end

function _VH_GetRecommendationTopicSet(data)
	local topics = {}
	local textParts = {}
	local function add(value)
		if type(value) == "string" and value ~= "" then textParts[#textParts + 1] = string.lower(value) end
	end
	add(data and data.Name)
	add(data and data.Description)
	add(data and data.Category)
	add(data and data.Author)
	add(data and data.Tags)
	if data and type(data.Tags) == "table" then
		for _, tag in ipairs(data.Tags) do add(tag) end
	end
	local textValue = table.concat(textParts, " ")
	local topicKeywords = {
		combat = {"murder", "mystery", "rivals", "arsenal", "shooter", "shooting", "gun", "pvp", "combat", "sword", "katana", "hunter", "fight", "battle", "enemy"},
		eggs = {"egg", "eggs", "hatch", "hatching", "steal an egg", "lucky egg"},
		brainrot = {"brainrot", "brainrots"},
		anime = {"anime"},
		rng = {"rng", "luck", "lucky", "dice", "roll", "random"},
		obby = {"obby", "escape", "wall hop", "moonwalk", "keyboard escape", "backflip", "bottle flip", "web swing", "high jump", "jump crunch", "jump for"},
		speed = {"speed", "fast", "run", "running", "moonwalk", "high jump", "jump"},
		farming = {"farm", "farming", "grow", "garden", "collect", "collection", "bucket", "chicken farm", "tree", "axe", "pickaxe"},
		clicker = {"click", "clicker", "tap", "money", "followers", "per click", "per jump"},
		soccer = {"soccer", "football", "player squad", "squad"},
		tycoon = {"tycoon", "city", "build a", "building", "base", "party"},
		asmr = {"asmr"},
		paint = {"paint", "painting", "seek"},
		animals = {"animal", "animals", "chicken", "dino", "dinosaur", "crab", "fish"},
		crafting = {"craft", "crafting", "unbox", "loot", "card"},
	}
	for topic, keywords in pairs(topicKeywords) do
		for _, keyword in ipairs(keywords) do
			if string.find(textValue, keyword, 1, true) then
				topics[topic] = true
				break
			end
		end
	end
	return topics
end

function _VH_CountTopicOverlap(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return 0 end
	local count = 0
	for topic in pairs(a) do
		if b[topic] then count = count + 1 end
	end
	return count
end

function _VH_CountTokenOverlap(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return 0 end
	local count = 0
	for token in pairs(a) do
		if b[token] then count = count + 1 end
	end
	return count
end

function _VH_GetRecommendationContext(entries)
	local currentSet = {}
	local favoriteSet = {}
	local currentCategories = {}
	local currentTags = {}
	local currentTopics = {}
	local favoriteTopics = {}
	local favoriteEntries = {}
	local currentCount = 0
	for _, entry in ipairs(entries or {}) do
		local data = entry and entry.Data or entry
		if type(data) == "table" then
			local placeId = tonumber(data.PlaceId) or 0
			local tokens = _VH_GetRecommendationTokenSet(data)
			local topics = _VH_GetRecommendationTopicSet(data)
			if placeId ~= 0 and placeId == PlaceId then
				currentCount = currentCount + 1
				for token in pairs(tokens) do currentSet[token] = true end
				for topic in pairs(topics) do currentTopics[topic] = true end
				local category = type(data.Category) == "string" and string.lower(string.gsub(data.Category, "^%s*(.-)%s*$", "%1")) or ""
				if category ~= "" then currentCategories[category] = true end
				for _, tag in ipairs(_VH_NormalizeRecommendationList(data.Tags)) do currentTags[tag] = true end
			end
			local id = tostring(data.Id or StableScriptId(data) or "")
			if id ~= "" and SavedData.Favorites[id] then
				favoriteEntries[#favoriteEntries + 1] = { Id = id, Tokens = tokens, Topics = topics }
			end
		end
	end
	table.sort(favoriteEntries, function(a, b) return a.Id < b.Id end)
	local favoriteLimit = math.min(#favoriteEntries, FavoriteRecommendationLimit)
	for index = 1, favoriteLimit do
		local favorite = favoriteEntries[index]
		for token in pairs(favorite.Tokens) do favoriteSet[token] = true end
		for topic in pairs(favorite.Topics) do favoriteTopics[topic] = true end
	end
	return currentSet, favoriteSet, currentCategories, currentTags, currentTopics, favoriteTopics, currentCount
end
function GetOrCreateCardStroke(card)
	if not card or not card:IsA("GuiObject") then return nil end
	stroke = card:FindFirstChild("TagTypeStroke")
	if stroke and stroke:IsA("UIStroke") then return stroke end
	if stroke then pcall(function() stroke:Destroy() end) end
	stroke = Instance.new("UIStroke")
	stroke.Name = "TagTypeStroke"
	stroke.Parent = card
	return stroke
end
function ApplyTagBorder(card, tagType, stroke)
	if not card or not card.Parent then return end
	stroke = stroke or GetOrCreateCardStroke(card)
	if not stroke or not stroke.Parent then return end
	normalized = NormalizeTagType(tagType)
	config = TagTypeConfig[normalized] or TagTypeConfig.NONE
	stroke.Color = config.StrokeColor
	stroke.Transparency = 0
	stroke.Enabled = true
end
function GetSafeTimestamp(value)
	timestamp = tonumber(value)
	if type(timestamp) ~= "number" or timestamp ~= timestamp then return 0 end
	return timestamp
end
function GetRelativeTime(timestamp)
	local value = tonumber(timestamp)
	if type(value) ~= "number" or value ~= value then return "Now" end
	local diff = os.time() - value
	if diff <= 0 or diff < 60 then return "Now" end
	local minutes = math.floor(diff / 60)
	if minutes < 60 then return tostring(minutes) .. "m ago" end
	local hours = math.floor(diff / 3600)
	if hours < 24 then return tostring(hours) .. "h ago" end
	local days = math.floor(diff / 86400)
	if days == 1 then return "1d ago" end
	if days < 7 then return tostring(days) .. "d ago" end
	local weeks = math.floor(days / 7)
	if weeks < 4 then return tostring(weeks) .. "w ago" end
	local months = math.floor(days / 30.44)
	if months < 12 then return tostring(months) .. "mo ago" end
	local years = math.floor(days / 365.25)
	return tostring(years) .. "y ago"
end
function FormatLastUpdatedLabel(value)
	local compact = nil
	if type(value) == "number" or tonumber(value) then
		compact = GetRelativeTime(value)
	else
		local text = tostring(value or "")
		text = string.gsub(text, "^%s*[Uu]pdated%s+", "")
		text = string.gsub(text, "^%s*(.-)%s*$", "%1")
		local n = string.match(text, "^(%d+)%s+minutes?%s+ago$")
		if n then compact = n .. "m ago" end
		if not compact then
			n = string.match(text, "^(%d+)%s+hours?%s+ago$")
			if n then compact = n .. "h ago" end
		end
		if not compact then
			n = string.match(text, "^(%d+)%s+days?%s+ago$")
			if n then compact = n .. "d ago" end
		end
		if not compact then
			n = string.match(text, "^(%d+)%s+weeks?%s+ago$")
			if n then compact = n .. "w ago" end
		end
		if not compact then
			n = string.match(text, "^(%d+)%s+months?%s+ago$")
			if n then compact = n .. "mo ago" end
		end
		if not compact then
			n = string.match(text, "^(%d+)%s+years?%s+ago$")
			if n then compact = n .. "y ago" end
		end
		if not compact and (text == "Now" or text == "now") then compact = "Now" end
		if not compact then
			local compactMatch = string.match(text, "^(%d+[mhdw])%s+ago$") or string.match(text, "^(%d+mo)%s+ago$") or string.match(text, "^(%d+y)%s+ago$")
			if compactMatch then compact = compactMatch .. " ago" end
		end
	end
	compact = compact or "Now"
	if compact == "Now" then return "Updated Now" end
	local amount, shortUnit = string.match(compact, "^(%d+)(m|h|d|w|mo|y)%s+ago$")
	if amount and shortUnit then
		local unitNames = { m = "Minute", h = "Hour", d = "Day", w = "Week", mo = "Month", y = "Year" }
		local unitName = unitNames[shortUnit] or "Time"
		if tonumber(amount) ~= 1 then unitName = unitName .. "s" end
		return "Updated " .. amount .. " " .. unitName .. " Ago"
	end
	return "Updated " .. compact
end
function GetSecureParent()
	huiSuccess, huiTarget = pcall(gethui)
	if huiSuccess and huiTarget and typeof(huiTarget) == "Instance" then return huiTarget end
	coreTarget = CoreGui
	if coreTarget then
		testAccess = pcall(function()
		t = Instance.new("Folder")
		t.Parent = coreTarget
		t:Destroy()
		end)
		if testAccess then return coreTarget end
	end
	if LocalPlayer then
		playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then return playerGui end
	end
	return nil
end
TargetParent = GetSecureParent()
if not TargetParent then return end
for _, child in ipairs(TargetParent:GetChildren()) do
	if child:IsA("ScreenGui") and (child.Name == "VeloxHub_Main" or child:GetAttribute("VeloxHubManaged") == true) then
		pcall(function() child:Destroy() end)
	end
end
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VeloxHub_Main"
ScreenGui:SetAttribute("VeloxHubManaged", true)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = TargetParent
function _VH_DisableTextOutline(object)
	if object and (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) then
		object.TextStrokeTransparency = 1
	end
end
function _VH_ClearTextOutlines(root)
	if not root then return end
	_VH_DisableTextOutline(root)
	for _, object in ipairs(root:GetDescendants()) do
		_VH_DisableTextOutline(object)
	end
end
_VH_ClearTextOutlines(ScreenGui)
_VH_RegConn(ScreenGui.DescendantAdded:Connect(_VH_DisableTextOutline))
pcall(function() protectgui(ScreenGui) end)
GlobalEnv[_G_Identifier] = function()
	_VH_CleanUpMemory()
	if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end
function GetPanelSize()
	camera = workspace.CurrentCamera
	viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
	maxWidth = IsMobile and 480 or 560
	maxHeight = IsMobile and 360 or 515
	return UDim2.fromOffset(math.max(320, math.min(maxWidth, viewport.X - 20)), math.max(300, math.min(maxHeight, viewport.Y - 20)))
end
PANEL_SIZE = GetPanelSize()
function ApplyInteractiveAnimations(gui, originalColor, hoverColor, clickColor, strokeObj, originalStroke, hoverStroke, connectionRegistry)
	if not gui:IsA("GuiObject") then return end
	connectionRegistry = connectionRegistry or VeloxConnections
	InteractiveElements[gui] = {BaseColor = originalColor, BaseStroke = originalStroke, StrokeObj = strokeObj}
	local function RegInteractive(connection)
		if type(connectionRegistry) == "table" then
			connectionRegistry[#connectionRegistry + 1] = connection
			return connection
		end
		return _VH_RegConn(connection)
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
_VH_RegConn(UserInputService.WindowFocusReleased:Connect(function()
	if isDestroying then return end
	for element, data in pairs(InteractiveElements) do
		if element and element.Parent then
			if data.BaseColor then pcall(function() element.BackgroundColor3 = data.BaseColor end) end
			if data.StrokeObj and data.BaseStroke then pcall(function() data.StrokeObj.Color = data.BaseStroke end) end
		end
	end
end))
FloatingBtn = Instance.new("ImageButton", ScreenGui)
FloatingBtn.Name = "VeloxHub_Float"
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
FloatPadding = Instance.new("UIPadding", FloatingBtn)
FloatPadding.PaddingLeft = UDim.new(0, 6); FloatPadding.PaddingRight = UDim.new(0, 6)
FloatPadding.PaddingTop = UDim.new(0, 6); FloatPadding.PaddingBottom = UDim.new(0, 6)
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = Theme.Accent; FloatStroke.Thickness = 2
floatStart, floatPos = nil, nil
_VH_RegConn(FloatingBtn.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeFloatDragInput then
		activeFloatDragInput = input
		floatStart = input.Position
		floatPos = FloatingBtn.Position
		if floatDragConnection then floatDragConnection:Disconnect() end
		floatDragConnection = _VH_RegConn(UserInputService.InputChanged:Connect(function(moveInput)
			if isDestroying then return end
			if moveInput == activeFloatDragInput or moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				delta = moveInput.Position - floatStart
				camera = workspace.CurrentCamera
				viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
				targetX = floatPos.X.Scale * viewport.X + floatPos.X.Offset + delta.X
				targetY = floatPos.Y.Scale * viewport.Y + floatPos.Y.Offset + delta.Y
				halfX = FloatingBtn.AbsoluteSize.X * FloatingBtn.AnchorPoint.X
				halfY = FloatingBtn.AbsoluteSize.Y * FloatingBtn.AnchorPoint.Y
				targetX = math.clamp(targetX, halfX, viewport.X - (FloatingBtn.AbsoluteSize.X - halfX))
				targetY = math.clamp(targetY, halfY, viewport.Y - (FloatingBtn.AbsoluteSize.Y - halfY))
				FloatingBtn.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end))
MainPanel = Instance.new("Frame", ScreenGui)
MainPanel.Size = PANEL_SIZE
MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
MainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
MainPanel.BackgroundColor3 = Theme.BackgroundMain
MainPanel.BorderSizePixel = 0
MainPanel.ClipsDescendants = true
MainPanel.Visible = true
MainPanel.Active = true
MainPanel.ZIndex = 1
MainModalBtn = Instance.new("TextButton", MainPanel)
MainModalBtn.Size = UDim2.new(0, 0, 0, 0)
MainModalBtn.Visible = true
MainModalBtn.Modal = true
MainModalBtn.Text = ""
MainGradient = Instance.new("UIGradient", MainPanel)
MainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.BackgroundMain),
	ColorSequenceKeypoint.new(1, Theme.BackgroundSecondary)
})
MainGradient.Rotation = 45
PanelGroup = Instance.new("Frame", MainPanel)
PanelGroup.Size = UDim2.new(1, 0, 1, 0)
PanelGroup.BackgroundTransparency = 1
PanelGroup.Active = false
Instance.new("UICorner", MainPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MainPanel).Color = Theme.Stroke
PanelUIScale = Instance.new("UIScale", MainPanel)
PanelUIScale.Scale = math.clamp(tonumber(SavedData.Settings.UIScale) or 1, 0.8, 1.2)
function ApplyPanelUIScale(scaleValue)
	nextScale = math.clamp(tonumber(scaleValue) or 1, 0.8, 1.2)
	SavedData.Settings.UIScale = nextScale
	if PanelUIScale and PanelUIScale.Parent then
		_VH_SafeTween(PanelUIScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = nextScale})
	end
	if ScriptDetailsUIScale and ScriptDetailsUIScale.Parent then
		_VH_SafeTween(ScriptDetailsUIScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = nextScale})
	end
	task.defer(function()
		if isDestroying or not MainPanel or not MainPanel.Parent then return end
		camera = workspace.CurrentCamera
		viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
		task.wait(0.24)
		if isDestroying or not MainPanel or not MainPanel.Parent then return end
		halfX = MainPanel.AbsoluteSize.X * MainPanel.AnchorPoint.X
		halfY = MainPanel.AbsoluteSize.Y * MainPanel.AnchorPoint.Y
		currentX = MainPanel.Position.X.Scale * viewport.X + MainPanel.Position.X.Offset
		currentY = MainPanel.Position.Y.Scale * viewport.Y + MainPanel.Position.Y.Offset
		currentX = math.clamp(currentX, halfX, viewport.X - (MainPanel.AbsoluteSize.X - halfX))
		currentY = math.clamp(currentY, halfY, viewport.Y - (MainPanel.AbsoluteSize.Y - halfY))
		MainPanel.Position = UDim2.new(0, currentX, 0, currentY)
	end)
end
SearchInput = nil
function RestoreCachedProperties()
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
function ToggleUI()
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
ToastContainer.Size = UDim2.new(0, IsMobile and 235 or 280, 1, -32)
ToastContainer.Position = UDim2.new(1, IsMobile and -247 or -292, 0, 16)
ToastContainer.BackgroundTransparency = 1
ToastContainer.ZIndex = 2000
ToastContainer.ClipsDescendants = false

ToastLayout = Instance.new("UIListLayout", ToastContainer)
ToastLayout.Name = "NotificationLayout"
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ToastLayout.Padding = UDim.new(0, 8)
ToastLayout.FillDirection = Enum.FillDirection.Vertical

NOTIF_DURATION = 3.5
MAX_VISIBLE_NOTIFICATIONS = IsMobile and 3 or 5
NotificationSequence = 0

NotificationTypeInfo = {
	Success = {
		Label = "SUCCESS",
		Title = "Completed",
		Color = Theme.Success
	},
	Error = {
		Label = "ERROR",
		Title = "Something went wrong",
		Color = Theme.Error
	},
	Warning = {
		Label = "WARNING",
		Title = "Needs your attention",
		Color = Theme.Warning
	},
	Info = {
		Label = "INFO",
		Title = "Information",
		Color = Theme.Info
	},
	System = {
		Label = "SYSTEM",
		Title = "System update",
		Color = Theme.System
	},
	Execution = {
		Label = "EXECUTION",
		Title = "Script execution",
		Color = Theme.Execution
	}
}

function NormalizeNotificationType(value)
	if type(value) == "boolean" then
		return value and "Success" or "Error"
	end
	if type(value) ~= "string" then
		return "Info"
	end
	if NotificationTypeInfo[value] then
		return value
	end
	local normalized = string.lower(string.gsub(value, "^%s*(.-)%s*$", "%1"))
	for key, _ in pairs(NotificationTypeInfo) do
		if string.lower(key) == normalized then
			return key
		end
	end
	return "Info"
end

function GetNotificationMessage(msg)
	local message = tostring(msg == nil and "" or msg)
	message = string.gsub(message, "^%s+", "")
	message = string.gsub(message, "%s+$", "")
	if message == "" then
		return "No additional details were provided."
	end
	return message
end

function GetNotificationTitle(notifType, message)
	local info = NotificationTypeInfo[notifType] or NotificationTypeInfo.Info

	local lowerMessage = string.lower(message)
	if notifType == "Success" then
		if string.find(lowerMessage, "execut") then return "Execution complete" end
		if string.find(lowerMessage, "refresh") or string.find(lowerMessage, "catalog") then
			return "Update complete"
		end
	elseif notifType == "Error" then
		if string.find(lowerMessage, "download") or string.find(lowerMessage, "connect") then
			return "Connection failed"
		end
		if string.find(lowerMessage, "compile") or string.find(lowerMessage, "loadstring") then
			return "Execution unavailable"
		end
	elseif notifType == "Warning" then
		if string.find(lowerMessage, "cancel") then return "Action canceled" end
		if string.find(lowerMessage, "compatible") then return "Compatibility warning" end
	elseif notifType == "System" then
		if string.find(lowerMessage, "catalog") then return "Catalog update" end
	elseif notifType == "Execution" then
		if string.find(lowerMessage, "execut") then return "Script executed" end
	end

	return info.Title
end

function TrimNotificationStack()
	if not ToastContainer or not ToastContainer.Parent then return end
	local active = {}
	for _, child in ipairs(ToastContainer:GetChildren()) do
		if child:IsA("Frame") and child:GetAttribute("VeloxNotification") == true then
			table.insert(active, child)
		end
	end
	table.sort(active, function(a, b)
		return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
	end)
	while #active > MAX_VISIBLE_NOTIFICATIONS do
		oldest = table.remove(active, 1)
		if oldest and oldest.Parent then
			pcall(function() oldest:Destroy() end)
		end
	end
end

function EmergencyFallbackNotification(msg, title)
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

function StandaloneBannerNotification(msg, notifType)
	local parent = GetSecureParent()
	if not parent then
		EmergencyFallbackNotification(msg, GetNotificationTitle(notifType, GetNotificationMessage(msg)))
		return
	end

	local success = pcall(function()
		local message = GetNotificationMessage(msg)
		local typeInfo = NotificationTypeInfo[NormalizeNotificationType(notifType)] or NotificationTypeInfo.Info
		local title = GetNotificationTitle(NormalizeNotificationType(notifType), message)

		local bannerGui = Instance.new("ScreenGui")
		bannerGui.Name = "VeloxBanner_" .. _VH_GenerateRandomString(8)
		bannerGui.DisplayOrder = 9999
		bannerGui.ResetOnSpawn = false
		bannerGui.IgnoreGuiInset = true
		bannerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		bannerGui.Parent = parent

		local frame = Instance.new("Frame", bannerGui)
		frame.Size = UDim2.new(0, IsMobile and 225 or 280, 0, IsMobile and 68 or 72)
		frame.Position = UDim2.new(0.5, 0, 0, -95)
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.BackgroundColor3 = Theme.BackgroundSecondary
		frame.BorderSizePixel = 0
		frame.ZIndex = 1
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = typeInfo.Color
		stroke.Thickness = 1.5
		stroke.Transparency = 0.15

		local titleLabel = Instance.new("TextLabel", frame)
		titleLabel.Size = UDim2.new(1, -24, 0, 18)
		titleLabel.Position = UDim2.new(0, 12, 0, 8)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = Theme.TextPrimary
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = IsMobile and 12 or 13
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.ZIndex = 3

		local desc = Instance.new("TextLabel", frame)
		desc.Size = UDim2.new(1, -24, 0, 36)
		desc.Position = UDim2.new(0, 12, 0, 27)
		desc.BackgroundTransparency = 1
		desc.Text = message
		desc.TextColor3 = Theme.TextSecondary
		desc.Font = Enum.Font.Gotham
		desc.TextSize = IsMobile and 10 or 11
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.ZIndex = 3

		TweenService:Create(frame, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 18)
		}):Play()

		task.delay(NOTIF_DURATION, function()
			if not frame or not frame.Parent then return end
			local outro = TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -95)
			})
			outro:Play()
			outro.Completed:Connect(function()
				if bannerGui and bannerGui.Parent then
					bannerGui:Destroy()
				end
			end)
		end)
	end)

	if not success then
		EmergencyFallbackNotification(msg, GetNotificationTitle(notifType, GetNotificationMessage(msg)))
	end
end

function ShowNotification(msg, notifType)
	if isDestroying then return end
	local nType = NormalizeNotificationType(notifType)
	local typeInfo = NotificationTypeInfo[nType] or NotificationTypeInfo.Info
	local message = GetNotificationMessage(msg)
	local title = GetNotificationTitle(nType, message)
	local indicatorColor = typeInfo.Color

	if not ToastContainer or not ToastContainer.Parent then
		StandaloneBannerNotification(message, nType)
		return
	end

	local success = pcall(function()
		NotificationSequence = NotificationSequence + 1
		local wrapper = Instance.new("Frame", ToastContainer)
		wrapper.Name = "Notification_" .. tostring(NotificationSequence)
		wrapper:SetAttribute("VeloxNotification", true)
		wrapper.LayoutOrder = NotificationSequence
		wrapper.Size = UDim2.new(1, 0, 0, IsMobile and 66 or 70)
		wrapper.BackgroundTransparency = 1
		wrapper.ZIndex = 2001

		local box = Instance.new("Frame", wrapper)
		box.Name = "Card"
		box.Size = UDim2.new(1, 0, 1, 0)
		box.Position = UDim2.new(1.08, 0, 0, 0)
		box.BackgroundColor3 = Theme.Card
		box.BorderSizePixel = 0
		box.ClipsDescendants = true
		box.ZIndex = 2002
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke", box)
		stroke.Color = Theme.Stroke
		stroke.Thickness = 1
		stroke.Transparency = 0.2

		local iconCircle = Instance.new("Frame", box)
		iconCircle.Size = UDim2.new(0, 22, 0, 22)
		iconCircle.Position = UDim2.new(0, 10, 0, 9)
		iconCircle.BackgroundColor3 = indicatorColor
		iconCircle.BackgroundTransparency = 0.84
		iconCircle.BorderSizePixel = 0
		iconCircle.ZIndex = 2004
		Instance.new("UICorner", iconCircle).CornerRadius = UDim.new(1, 0)

		local icon = Instance.new("TextLabel", iconCircle)
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = ({Success = "✓", Error = "!", Warning = "!", Info = "i", System = "•", Execution = "▶"})[nType] or "i"
		icon.TextColor3 = indicatorColor
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = IsMobile and 10 or 11
		icon.ZIndex = 2005

		local typeLabel = Instance.new("TextLabel", box)
		typeLabel.Size = UDim2.new(1, -72, 0, 11)
		typeLabel.Position = UDim2.new(0, 40, 0, 7)
		typeLabel.BackgroundTransparency = 1
		typeLabel.Text = typeInfo.Label
		typeLabel.TextColor3 = indicatorColor
		typeLabel.Font = Enum.Font.GothamBold
		typeLabel.TextSize = IsMobile and 6 or 7
		typeLabel.TextXAlignment = Enum.TextXAlignment.Left
		typeLabel.ZIndex = 2004

		local titleLabel = Instance.new("TextLabel", box)
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(1, -72, 0, 18)
		titleLabel.Position = UDim2.new(0, 40, 0, 17)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = Theme.TextPrimary
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = IsMobile and 10 or 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.ZIndex = 2004

		local closeButton = Instance.new("TextButton", box)
		closeButton.Name = "Close"
		closeButton.Size = UDim2.new(0, 20, 0, 20)
		closeButton.Position = UDim2.new(1, -27, 0, 5)
		closeButton.BackgroundTransparency = 1
		closeButton.AutoButtonColor = false
		closeButton.Text = "×"
		closeButton.TextColor3 = Theme.TextSecondary
		closeButton.Font = Enum.Font.GothamBold
		closeButton.TextSize = 14
		closeButton.ZIndex = 2006

		local description = Instance.new("TextLabel", box)
		description.Name = "Description"
		description.Size = UDim2.new(1, -60, 0, IsMobile and 24 or 26)
		description.Position = UDim2.new(0, 40, 0, 34)
		description.BackgroundTransparency = 1
		description.Text = message
		description.TextColor3 = Theme.TextSecondary
		description.Font = Enum.Font.Gotham
		description.TextSize = IsMobile and 8 or 9
		description.TextWrapped = true
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.ZIndex = 2004

		local progressTrack = Instance.new("Frame", box)
		progressTrack.Name = "TimerProgressTrack"
		progressTrack.Size = UDim2.new(1, -18, 0, 3)
		progressTrack.Position = UDim2.new(0, 9, 1, -6)
		progressTrack.BackgroundColor3 = Theme.BackgroundMain
		progressTrack.BackgroundTransparency = 0.3
		progressTrack.BorderSizePixel = 0
		progressTrack.ZIndex = 2005
		Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(1, 0)

		local progressFill = Instance.new("Frame", progressTrack)
		progressFill.Name = "TimerProgress"
		progressFill.Size = UDim2.new(1, 0, 1, 0)
		progressFill.BackgroundColor3 = indicatorColor
		progressFill.BorderSizePixel = 0
		progressFill.ZIndex = 2006
		Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

		local closeRequested = false
		local progressTween = nil
		local dismissTween = nil
		local function Dismiss()
			if closeRequested then return end
			closeRequested = true
			if progressTween then
				pcall(function() progressTween:Cancel() end)
			end
			if not wrapper or not wrapper.Parent then return end
			dismissTween = TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1.08, 0, 0, 0)
			})
			dismissTween:Play()
			dismissTween.Completed:Connect(function()
				if wrapper and wrapper.Parent then wrapper:Destroy() end
			end)
		end

		closeButton.MouseEnter:Connect(function()
			closeButton.TextColor3 = Theme.TextPrimary
		end)
		closeButton.MouseLeave:Connect(function()
			if not closeRequested then closeButton.TextColor3 = Theme.TextSecondary end
		end)
		closeButton.Activated:Connect(Dismiss)

		box.MouseEnter:Connect(function()
			_VH_SafeTween(box, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.CardHover})
		end)
		box.MouseLeave:Connect(function()
			if not closeRequested then
				_VH_SafeTween(box, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Card})
			end
		end)

		TrimNotificationStack()
		local introTween = TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		})
		introTween:Play()
		introTween.Completed:Connect(function() pcall(function() introTween:Destroy() end) end)

		_VH_ClearTextOutlines(bannerGui)

		progressTween = TweenService:Create(progressFill, TweenInfo.new(NOTIF_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 0, 1, 0)
		})
		progressTween:Play()

		task.delay(NOTIF_DURATION, function()
			if not wrapper or not wrapper.Parent or closeRequested then return end
			Dismiss()
		end)
	end)

	if not success then
		StandaloneBannerNotification(message, nType)
	end
end

function AttemptActionWithCooldown(actionFunc)
	local now = tick()
	if now < GlobalActionCooldownEndTime then
		if not GlobalCooldownBanner or not GlobalCooldownBanner.Parent then
			GlobalCooldownLoopVersion = GlobalCooldownLoopVersion + 1
			local currentLoop = GlobalCooldownLoopVersion
			local parent = GetSecureParent()
			if not parent then return end
			local bannerGui = Instance.new("ScreenGui")
			bannerGui.Name = "VeloxCooldown_" .. _VH_GenerateRandomString(8)
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
			_VH_ClearTextOutlines(bannerGui)
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
ConfirmBox = Instance.new("Frame", ConfirmOverlay)
ConfirmBox.Size = IsMobile and UDim2.new(0, 300, 0, 180) or UDim2.new(0, 360, 0, 190)
ConfirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmBox.BackgroundColor3 = Theme.BackgroundSecondary
ConfirmBox.BorderSizePixel = 0
ConfirmBox.ClipsDescendants = true
ConfirmBox.ZIndex = 401
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 12)
ConfirmBoxStroke = Instance.new("UIStroke", ConfirmBox)
ConfirmBoxStroke.Color = Theme.Stroke; ConfirmBoxStroke.Thickness = 1
ConfirmPadding = Instance.new("UIPadding", ConfirmBox)
ConfirmPadding.PaddingTop = UDim.new(0, 16); ConfirmPadding.PaddingBottom = UDim.new(0, 16)
ConfirmPadding.PaddingLeft = UDim.new(0, 20); ConfirmPadding.PaddingRight = UDim.new(0, 20)
ConfirmLayout = Instance.new("UIListLayout", ConfirmBox)
ConfirmLayout.SortOrder = Enum.SortOrder.LayoutOrder
ConfirmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ConfirmLayout.VerticalAlignment = Enum.VerticalAlignment.Center; ConfirmLayout.Padding = UDim.new(0, 8)
ConfirmTitle = Instance.new("TextLabel", ConfirmBox)
ConfirmTitle.Size = UDim2.new(1, 0, 0, 22); ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "Execute Script"; ConfirmTitle.TextColor3 = Theme.TextPrimary
ConfirmTitle.Font = Enum.Font.GothamBold; ConfirmTitle.TextSize = IsMobile and 14 or 16
ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Center; ConfirmTitle.LayoutOrder = 1; ConfirmTitle.ZIndex = 402
ConfirmMessage = Instance.new("TextLabel", ConfirmBox)
ConfirmMessage.Size = UDim2.new(1, 0, 0, 18); ConfirmMessage.BackgroundTransparency = 1
ConfirmMessage.Text = "Are you sure you want to run this script?"
ConfirmMessage.TextColor3 = Theme.TextSecondary; ConfirmMessage.Font = Enum.Font.Gotham
ConfirmMessage.TextSize = IsMobile and 11 or 12; ConfirmMessage.TextXAlignment = Enum.TextXAlignment.Center
ConfirmMessage.TextWrapped = true; ConfirmMessage.LayoutOrder = 2; ConfirmMessage.ZIndex = 402
ConfirmScriptName = Instance.new("TextLabel", ConfirmBox)
ConfirmScriptName.Size = UDim2.new(1, 0, 0, 0); ConfirmScriptName.AutomaticSize = Enum.AutomaticSize.Y
ConfirmScriptName.BackgroundTransparency = 1; ConfirmScriptName.Text = ""
ConfirmScriptName.TextColor3 = Theme.Accent; ConfirmScriptName.Font = Enum.Font.GothamBold
ConfirmScriptName.TextSize = IsMobile and 12 or 13; ConfirmScriptName.TextXAlignment = Enum.TextXAlignment.Center
ConfirmScriptName.TextWrapped = true; ConfirmScriptName.LayoutOrder = 3; ConfirmScriptName.ZIndex = 402
ConfirmButtonRow = Instance.new("Frame", ConfirmBox)
ConfirmButtonRow.Size = UDim2.new(1, 0, 0, 34); ConfirmButtonRow.BackgroundTransparency = 1
ConfirmButtonRow.LayoutOrder = 4; ConfirmButtonRow.ZIndex = 402
ConfirmRowLayout = Instance.new("UIListLayout", ConfirmButtonRow)
ConfirmRowLayout.FillDirection = Enum.FillDirection.Horizontal
ConfirmRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ConfirmRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ConfirmRowLayout.SortOrder = Enum.SortOrder.LayoutOrder; ConfirmRowLayout.Padding = UDim.new(0, 12)
ConfirmCancelBtn = Instance.new("TextButton", ConfirmButtonRow)
ConfirmCancelBtn.Size = UDim2.new(0.5, -6, 1, 0); ConfirmCancelBtn.BackgroundColor3 = Theme.CardHover
ConfirmCancelBtn.Text = "Cancel"; ConfirmCancelBtn.TextColor3 = Theme.TextPrimary
ConfirmCancelBtn.Font = Enum.Font.GothamBold; ConfirmCancelBtn.TextSize = IsMobile and 11 or 12
ConfirmCancelBtn.AutoButtonColor = false; ConfirmCancelBtn.LayoutOrder = 1; ConfirmCancelBtn.ZIndex = 403
Instance.new("UICorner", ConfirmCancelBtn).CornerRadius = UDim.new(0, 6)
CancelStroke = Instance.new("UIStroke", ConfirmCancelBtn); CancelStroke.Color = Theme.Stroke
ConfirmExecuteBtn = Instance.new("TextButton", ConfirmButtonRow)
ConfirmExecuteBtn.Size = UDim2.new(0.5, -6, 1, 0); ConfirmExecuteBtn.BackgroundColor3 = Theme.Accent
ConfirmExecuteBtn.Text = "Execute"; ConfirmExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmExecuteBtn.Font = Enum.Font.GothamBold; ConfirmExecuteBtn.TextSize = IsMobile and 11 or 12
ConfirmExecuteBtn.AutoButtonColor = false; ConfirmExecuteBtn.LayoutOrder = 2; ConfirmExecuteBtn.ZIndex = 403
Instance.new("UICorner", ConfirmExecuteBtn).CornerRadius = UDim.new(0, 6)
ApplyInteractiveAnimations(ConfirmCancelBtn, Theme.CardHover, Color3.fromRGB(40, 53, 75), Color3.fromRGB(20, 29, 45), CancelStroke, Theme.Stroke, Theme.Accent)
ApplyInteractiveAnimations(ConfirmExecuteBtn, Theme.Accent, Color3.fromRGB(120, 123, 245), Color3.fromRGB(79, 82, 221))
isConfirming = false
pendingExecuteCallback = nil
function OpenConfirmDialog(scriptName, onExecute)
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
function CloseConfirmDialog(shouldExecute)
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
_VH_RegConn(ConfirmCancelBtn.Activated:Connect(_VH_CreateDebounce(0.1, function() CloseConfirmDialog(false) end)))
_VH_RegConn(ConfirmExecuteBtn.Activated:Connect(function()
	AttemptActionWithCooldown(function()
		CloseConfirmDialog(true)
	end)
end))
_VH_RegConn(ConfirmOverlay.InputBegan:Connect(function(input)
	if not isConfirming then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		pos = input.Position
		bPos, bSize = ConfirmBox.AbsolutePosition, ConfirmBox.AbsoluteSize
		inside = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y
		if not inside then CloseConfirmDialog(false) end
	end
end))
ScriptDetailsOverlay = Instance.new("Frame", ScreenGui)
ScriptDetailsOverlay.Name = "ScriptDetailsOverlay"
ScriptDetailsOverlay.Size = UDim2.new(1, 0, 1, 0)
ScriptDetailsOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ScriptDetailsOverlay.BackgroundTransparency = 1
ScriptDetailsOverlay.Visible = false
ScriptDetailsOverlay.Active = false
ScriptDetailsOverlay.ZIndex = 500
ScriptDetailsBox = Instance.new("Frame", ScriptDetailsOverlay)
ScriptDetailsBox.Size = IsMobile and UDim2.new(0, 322, 0, 438) or UDim2.new(0, 420, 0, 468)
ScriptDetailsBox.Position = UDim2.new(0.5, 0, 0.5, 0)
ScriptDetailsBox.AnchorPoint = Vector2.new(0.5, 0.5)
ScriptDetailsBox.BackgroundColor3 = Theme.BackgroundSecondary
ScriptDetailsBox.BorderSizePixel = 0
ScriptDetailsBox.ClipsDescendants = true
ScriptDetailsBox.ZIndex = 501
Instance.new("UICorner", ScriptDetailsBox).CornerRadius = UDim.new(0, 14)
ScriptDetailsStroke = Instance.new("UIStroke", ScriptDetailsBox)
ScriptDetailsStroke.Color = Theme.Accent
ScriptDetailsStroke.Transparency = 0.2
ScriptDetailsStroke.Thickness = 1
ScriptDetailsGradient = Instance.new("UIGradient", ScriptDetailsBox)
ScriptDetailsGradient.Rotation = 135
ScriptDetailsGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 32, 60)),
	ColorSequenceKeypoint.new(0.55, Theme.BackgroundSecondary),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 18, 32))
})
ScriptDetailsAccent = Instance.new("Frame", ScriptDetailsBox)
ScriptDetailsAccent.Size = UDim2.new(1, -28, 0, 3)
ScriptDetailsAccent.Position = UDim2.new(0, 14, 0, 10)
ScriptDetailsAccent.BackgroundColor3 = Theme.Accent
ScriptDetailsAccent.BorderSizePixel = 0
ScriptDetailsAccent.ZIndex = 503
Instance.new("UICorner", ScriptDetailsAccent).CornerRadius = UDim.new(1, 0)
ScriptDetailsUIScale = Instance.new("UIScale", ScriptDetailsBox)
ScriptDetailsUIScale.Scale = math.clamp(tonumber(SavedData.Settings.UIScale) or 1, 0.8, 1.2)
ScriptDetailsHeader = Instance.new("Frame", ScriptDetailsBox)
ScriptDetailsHeader.Size = UDim2.new(1, -28, 0, IsMobile and 94 or 100)
ScriptDetailsHeader.Position = UDim2.new(0, 14, 0, 20)
ScriptDetailsHeader.BackgroundTransparency = 1
ScriptDetailsImage = Instance.new("ImageLabel", ScriptDetailsHeader)
ScriptDetailsImage.Size = UDim2.new(0, IsMobile and 58 or 66, 0, IsMobile and 58 or 66)
ScriptDetailsImage.Position = UDim2.new(0, 0, 0.5, -(IsMobile and 29 or 33))
ScriptDetailsImage.BackgroundColor3 = Theme.BackgroundMain
ScriptDetailsImage.BorderSizePixel = 0
ScriptDetailsImage.ScaleType = Enum.ScaleType.Crop
Instance.new("UICorner", ScriptDetailsImage).CornerRadius = UDim.new(0, 10)
ScriptDetailsImageStroke = Instance.new("UIStroke", ScriptDetailsImage)
ScriptDetailsImageStroke.Color = Theme.Stroke
ScriptDetailsImageStroke.Transparency = 0.15
ScriptDetailsImageStroke.Thickness = 1
ScriptDetailsName = Instance.new("TextLabel", ScriptDetailsHeader)
ScriptDetailsName.Size = UDim2.new(1, -(IsMobile and 108 or 124), 0, IsMobile and 34 or 40)
ScriptDetailsName.Position = UDim2.new(0, IsMobile and 70 or 80, 0.5, 0)
ScriptDetailsName.AnchorPoint = Vector2.new(0, 0.5)
ScriptDetailsName.BackgroundTransparency = 1
ScriptDetailsName.Text = "Script Details"
ScriptDetailsName.TextColor3 = Theme.TextPrimary
ScriptDetailsName.Font = Enum.Font.GothamBold
ScriptDetailsName.TextSize = IsMobile and 13 or 16
ScriptDetailsName.TextWrapped = true
ScriptDetailsName.TextTruncate = Enum.TextTruncate.AtEnd
ScriptDetailsName.TextXAlignment = Enum.TextXAlignment.Left
ScriptDetailsName.TextYAlignment = Enum.TextYAlignment.Center
ScriptDetailsBadge = Instance.new("Frame", ScriptDetailsHeader)
ScriptDetailsBadge.Size = UDim2.new(0, IsMobile and 88 or 96, 0, 20)
ScriptDetailsBadge.Position = UDim2.new(0, IsMobile and 70 or 80, 0, IsMobile and 55 or 58)
ScriptDetailsBadge.BackgroundColor3 = Color3.fromRGB(79, 70, 229)
ScriptDetailsBadge.BorderSizePixel = 0
ScriptDetailsBadge.Visible = false
Instance.new("UICorner", ScriptDetailsBadge).CornerRadius = UDim.new(0, 7)
ScriptDetailsBadgeText = Instance.new("TextLabel", ScriptDetailsBadge)
ScriptDetailsBadgeText.Size = UDim2.new(1, 0, 1, 0)
ScriptDetailsBadgeText.BackgroundTransparency = 1
ScriptDetailsBadgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
ScriptDetailsBadgeText.Font = Enum.Font.GothamBold
ScriptDetailsBadgeText.TextSize = 8
ScriptDetailsBadgeText.TextXAlignment = Enum.TextXAlignment.Center
ScriptDetailsTagBadge = Instance.new("Frame", ScriptDetailsHeader)
ScriptDetailsTagBadge.Size = UDim2.new(0, IsMobile and 78 or 86, 0, 20)
ScriptDetailsTagBadge.Position = UDim2.new(0, IsMobile and 153 or 170, 0, IsMobile and 55 or 58)
ScriptDetailsTagBadge.BackgroundColor3 = Color3.fromRGB(50, 62, 82)
ScriptDetailsTagBadge.BorderSizePixel = 0
ScriptDetailsTagBadge.Visible = false
Instance.new("UICorner", ScriptDetailsTagBadge).CornerRadius = UDim.new(0, 7)
ScriptDetailsTagBadgeText = Instance.new("TextLabel", ScriptDetailsTagBadge)
ScriptDetailsTagBadgeText.Size = UDim2.new(1, 0, 1, 0)
ScriptDetailsTagBadgeText.BackgroundTransparency = 1
ScriptDetailsTagBadgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
ScriptDetailsTagBadgeText.Font = Enum.Font.GothamBold
ScriptDetailsTagBadgeText.TextSize = 8
ScriptDetailsTagBadgeText.TextXAlignment = Enum.TextXAlignment.Center
ScriptDetailsQuickInfo = Instance.new("Frame", ScriptDetailsHeader)
ScriptDetailsQuickInfo.Size = UDim2.new(1, -(IsMobile and 108 or 124), 0, 18)
ScriptDetailsQuickInfo.Position = UDim2.new(0, IsMobile and 70 or 80, 0, IsMobile and 74 or 78)
ScriptDetailsQuickInfo.BackgroundTransparency = 1
ScriptDetailsQuickInfo.Visible = false
ScriptDetailsQuickInfoLayout = Instance.new("UIListLayout", ScriptDetailsQuickInfo)
ScriptDetailsQuickInfoLayout.FillDirection = Enum.FillDirection.Horizontal
ScriptDetailsQuickInfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScriptDetailsQuickInfoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ScriptDetailsQuickInfoLayout.Padding = UDim.new(0, 5)
ScriptDetailsQuickCategory = Instance.new("TextLabel", ScriptDetailsQuickInfo)
ScriptDetailsQuickCategory.Size = UDim2.new(0, IsMobile and 92 or 110, 0, 18)
ScriptDetailsQuickCategory.BackgroundColor3 = Color3.fromRGB(40, 48, 88)
ScriptDetailsQuickCategory.TextColor3 = Color3.fromRGB(224, 228, 255)
ScriptDetailsQuickCategory.Font = Enum.Font.GothamBold
ScriptDetailsQuickCategory.TextSize = 8
ScriptDetailsQuickCategory.TextTruncate = Enum.TextTruncate.AtEnd
ScriptDetailsQuickCategory.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", ScriptDetailsQuickCategory).CornerRadius = UDim.new(0, 6)
ScriptDetailsQuickStatus = Instance.new("TextLabel", ScriptDetailsQuickInfo)
ScriptDetailsQuickStatus.Size = UDim2.new(0, IsMobile and 82 or 96, 0, 18)
ScriptDetailsQuickStatus.BackgroundColor3 = Color3.fromRGB(39, 64, 88)
ScriptDetailsQuickStatus.TextColor3 = Color3.fromRGB(224, 255, 244)
ScriptDetailsQuickStatus.Font = Enum.Font.GothamBold
ScriptDetailsQuickStatus.TextSize = 8
ScriptDetailsQuickStatus.TextTruncate = Enum.TextTruncate.AtEnd
ScriptDetailsQuickStatus.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", ScriptDetailsQuickStatus).CornerRadius = UDim.new(0, 6)
ScriptDetailsClose = Instance.new("TextButton", ScriptDetailsHeader)
ScriptDetailsClose.Size = UDim2.new(0, 28, 0, 28)
ScriptDetailsClose.Position = UDim2.new(1, -28, 0, 0)
ScriptDetailsClose.BackgroundColor3 = Theme.Card
ScriptDetailsClose.BorderSizePixel = 0
ScriptDetailsClose.AutoButtonColor = false
ScriptDetailsClose.Text = "×"
ScriptDetailsClose.TextColor3 = Theme.TextPrimary
ScriptDetailsClose.Font = Enum.Font.GothamBold
ScriptDetailsClose.TextSize = 20
Instance.new("UICorner", ScriptDetailsClose).CornerRadius = UDim.new(1, 0)
ScriptDetailsCloseStroke = Instance.new("UIStroke", ScriptDetailsClose)
ScriptDetailsCloseStroke.Color = Theme.Stroke
ApplyInteractiveAnimations(ScriptDetailsClose, Theme.Card, Theme.CardHover, Theme.BackgroundMain, ScriptDetailsCloseStroke, Theme.Stroke, Theme.Accent)
ScriptDetailsContent = Instance.new("ScrollingFrame", ScriptDetailsBox)
ScriptDetailsContent.Size = UDim2.new(1, -28, 1, -(IsMobile and 154 or 162))
ScriptDetailsContent.Position = UDim2.new(0, 14, 0, IsMobile and 108 or 114)
ScriptDetailsContent.BackgroundTransparency = 1
ScriptDetailsContent.BorderSizePixel = 0
ScriptDetailsContent.ScrollBarThickness = 2
ScriptDetailsContent.ScrollBarImageColor3 = Theme.Stroke
ScriptDetailsContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScriptDetailsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptDetailsContent.ClipsDescendants = true
ScriptDetailsLayout = Instance.new("UIListLayout", ScriptDetailsContent)
ScriptDetailsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScriptDetailsLayout.Padding = UDim.new(0, 8)
ScriptDetailsDescription = Instance.new("TextLabel", ScriptDetailsContent)
ScriptDetailsDescription.Size = UDim2.new(1, -2, 0, 0)
ScriptDetailsDescription.AutomaticSize = Enum.AutomaticSize.Y
ScriptDetailsDescription.BackgroundTransparency = 1
ScriptDetailsDescription.TextColor3 = Theme.TextSecondary
ScriptDetailsDescription.Font = Enum.Font.Gotham
ScriptDetailsDescription.TextSize = IsMobile and 10 or 11
ScriptDetailsDescription.TextWrapped = true
ScriptDetailsDescription.TextXAlignment = Enum.TextXAlignment.Left
ScriptDetailsDescription.TextYAlignment = Enum.TextYAlignment.Top
ScriptDetailsDescription.LayoutOrder = 1
ScriptDetailsMeta = Instance.new("Frame", ScriptDetailsContent)
ScriptDetailsMeta.Size = UDim2.new(1, -2, 0, 0)
ScriptDetailsMeta.AutomaticSize = Enum.AutomaticSize.Y
ScriptDetailsMeta.BackgroundColor3 = Theme.Card
ScriptDetailsMeta.BorderSizePixel = 0
ScriptDetailsMeta.LayoutOrder = 2
Instance.new("UICorner", ScriptDetailsMeta).CornerRadius = UDim.new(0, 9)
ScriptDetailsMetaPad = Instance.new("UIPadding", ScriptDetailsMeta)
ScriptDetailsMetaPad.PaddingTop = UDim.new(0, 8)
ScriptDetailsMetaPad.PaddingBottom = UDim.new(0, 8)
ScriptDetailsMetaPad.PaddingLeft = UDim.new(0, 10)
ScriptDetailsMetaPad.PaddingRight = UDim.new(0, 10)
ScriptDetailsMetaLayout = Instance.new("UIListLayout", ScriptDetailsMeta)
ScriptDetailsMetaLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScriptDetailsMetaLayout.Padding = UDim.new(0, 4)
function _VH_SetDetailsMetaRow(order, labelText, valueText, valueColor)
	local row = Instance.new("Frame", ScriptDetailsMeta)
	row.Size = UDim2.new(1, 0, 0, 19)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	local label = Instance.new("TextLabel", row)
	label.Size = UDim2.new(0.35, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Theme.TextSecondary
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 9
	label.TextXAlignment = Enum.TextXAlignment.Left
	local value = Instance.new("TextLabel", row)
	value.Size = UDim2.new(0.65, 0, 1, 0)
	value.Position = UDim2.new(0.35, 0, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = valueText
	value.TextColor3 = valueColor or Theme.TextPrimary
	value.Font = Enum.Font.GothamMedium
	value.TextSize = 9
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.TextTruncate = Enum.TextTruncate.AtEnd
	return row
end
ScriptDetailsTagsFrame = Instance.new("Frame", ScriptDetailsContent)
ScriptDetailsTagsFrame.Size = UDim2.new(1, -2, 0, 0)
ScriptDetailsTagsFrame.AutomaticSize = Enum.AutomaticSize.Y
ScriptDetailsTagsFrame.BackgroundColor3 = Theme.Card
ScriptDetailsTagsFrame.BorderSizePixel = 0
ScriptDetailsTagsFrame.LayoutOrder = 3
Instance.new("UICorner", ScriptDetailsTagsFrame).CornerRadius = UDim.new(0, 9)
ScriptDetailsTagsPad = Instance.new("UIPadding", ScriptDetailsTagsFrame)
ScriptDetailsTagsPad.PaddingTop = UDim.new(0, 8)
ScriptDetailsTagsPad.PaddingBottom = UDim.new(0, 8)
ScriptDetailsTagsPad.PaddingLeft = UDim.new(0, 10)
ScriptDetailsTagsPad.PaddingRight = UDim.new(0, 10)
ScriptDetailsTagsLabel = Instance.new("TextLabel", ScriptDetailsTagsFrame)
ScriptDetailsTagsLabel.Size = UDim2.new(0, 42, 0, 18)
ScriptDetailsTagsLabel.BackgroundTransparency = 1
ScriptDetailsTagsLabel.Text = "Tags"
ScriptDetailsTagsLabel.TextColor3 = Theme.TextSecondary
ScriptDetailsTagsLabel.Font = Enum.Font.GothamMedium
ScriptDetailsTagsLabel.TextSize = 9
ScriptDetailsTagsLabel.TextXAlignment = Enum.TextXAlignment.Left
ScriptDetailsTagsText = Instance.new("TextLabel", ScriptDetailsTagsFrame)
ScriptDetailsTagsText.Size = UDim2.new(1, -48, 0, 0)
ScriptDetailsTagsText.Position = UDim2.new(0, 48, 0, 0)
ScriptDetailsTagsText.AutomaticSize = Enum.AutomaticSize.Y
ScriptDetailsTagsText.BackgroundTransparency = 1
ScriptDetailsTagsText.TextColor3 = Theme.TextPrimary
ScriptDetailsTagsText.Font = Enum.Font.GothamMedium
ScriptDetailsTagsText.TextSize = 9
ScriptDetailsTagsText.TextWrapped = true
ScriptDetailsTagsText.TextXAlignment = Enum.TextXAlignment.Left
ScriptDetailsTagsText.TextYAlignment = Enum.TextYAlignment.Top
ScriptDetailsActions = Instance.new("Frame", ScriptDetailsBox)
ScriptDetailsActions.Size = UDim2.new(1, -28, 0, 34)
ScriptDetailsActions.Position = UDim2.new(0, 14, 1, -48)
ScriptDetailsActions.BackgroundTransparency = 1
ScriptDetailsCloseBottom = Instance.new("TextButton", ScriptDetailsActions)
ScriptDetailsCloseBottom.Size = UDim2.new(1, 0, 1, 0)
ScriptDetailsCloseBottom.BackgroundColor3 = Theme.Accent
ScriptDetailsCloseBottom.BorderSizePixel = 0
ScriptDetailsCloseBottom.AutoButtonColor = false
ScriptDetailsCloseBottom.Text = "Close"
ScriptDetailsCloseBottom.TextColor3 = Color3.fromRGB(255, 255, 255)
ScriptDetailsCloseBottom.Font = Enum.Font.GothamBold
ScriptDetailsCloseBottom.TextSize = 10
Instance.new("UICorner", ScriptDetailsCloseBottom).CornerRadius = UDim.new(0, 7)
ScriptDetailsCloseBottomStroke = Instance.new("UIStroke", ScriptDetailsCloseBottom)
ScriptDetailsCloseBottomStroke.Color = Theme.Accent
ApplyInteractiveAnimations(ScriptDetailsCloseBottom, Theme.Accent, Color3.fromRGB(120, 123, 245), Color3.fromRGB(79, 82, 221), ScriptDetailsCloseBottomStroke, Theme.Accent, Theme.Accent)
CurrentScriptDetails = nil
function _VH_ClearDetailsMetadata()
	for _, child in ipairs(ScriptDetailsMeta:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end
function _VH_CloseScriptDetails()
	CurrentScriptDetails = nil
	ScriptDetailsQuickInfo.Visible = false
	ScriptDetailsOverlay.Visible = false
	ScriptDetailsOverlay.Active = false
	ScriptDetailsOverlay.BackgroundTransparency = 1
end
function _VH_OpenScriptDetails(data, entry)
	if isDestroying or type(data) ~= "table" or not ScriptDetailsOverlay then return end
	CurrentScriptDetails = entry
	ScriptDetailsImage.Image = type(data.ImageAssetId) == "string" and data.ImageAssetId or ""
	ScriptDetailsName.Text = tostring(data.Name or "Unnamed Script")
	local recommendationKind = entry and tostring(entry.RecommendationType or "") or ""
	local recommended = entry and entry.Recommended == true
	ScriptDetailsBadge.Visible = recommended
	ScriptDetailsBadgeText.Text = recommendationKind == "SMART" and "YOU MAY LIKE" or "FOR YOU"
	ScriptDetailsBadge.BackgroundColor3 = recommendationKind == "SMART" and Color3.fromRGB(79, 70, 229) or Color3.fromRGB(67, 56, 202)
	local categoryText = type(data.Category) == "string" and data.Category ~= "" and data.Category or "General"
	local quickStatus = NormalizeTagType(data.TagType)
	ScriptDetailsTagBadgeText.Text = quickStatus ~= "NONE" and quickStatus or "STANDARD"
	ScriptDetailsTagBadge.Visible = quickStatus ~= "NONE"
	local tagBadgeConfig = TagTypeConfig[quickStatus] or TagTypeConfig.NONE
	ScriptDetailsTagBadge.BackgroundColor3 = tagBadgeConfig.BadgeColor
	ScriptDetailsQuickCategory.Text = categoryText
	ScriptDetailsQuickStatus.Text = quickStatus ~= "NONE" and quickStatus or "STANDARD"
	ScriptDetailsQuickStatus.BackgroundColor3 = tagBadgeConfig.BadgeColor
	ScriptDetailsQuickInfo.Visible = false
	ScriptDetailsDescription.Text = type(data.Description) == "string" and data.Description ~= "" and data.Description or "No description provided."
	_VH_ClearDetailsMetadata()
	local compatibility = IsScriptCompatible(data)
	local placeId = tonumber(data.PlaceId) or 0
	local gameText = placeId == 0 and "Any game" or (placeId == PlaceId and "Current game" or "PlaceId " .. tostring(placeId))
	_VH_SetDetailsMetaRow(1, "Category", type(data.Category) == "string" and data.Category ~= "" and data.Category or "General")
	_VH_SetDetailsMetaRow(2, "Author", type(data.Author) == "string" and data.Author ~= "" and data.Author or "Not specified")
	_VH_SetDetailsMetaRow(3, "Updated", FormatLastUpdatedLabel(data.LastUpdated))
	_VH_SetDetailsMetaRow(4, "Game", gameText, placeId == 0 and Theme.Success or (placeId == PlaceId and Theme.Success or Theme.Warning))
	_VH_SetDetailsMetaRow(5, "Compatibility", compatibility and "Compatible" or "Configured for another game", compatibility and Theme.Success or Theme.Warning)
	_VH_SetDetailsMetaRow(6, "Favorite", SavedData.Favorites[entry.Id] and "Favorited" or "Not favorited", SavedData.Favorites[entry.Id] and Color3.fromRGB(250, 204, 21) or Theme.TextPrimary)
	local autoOn = compatibility and SavedData.AutoExecutes[entry.Id] ~= nil
	_VH_SetDetailsMetaRow(7, "Auto Execute", autoOn and "ON" or "OFF", autoOn and Theme.Success or Theme.TextPrimary)
	local tagTypeValue = NormalizeTagType(data.TagType)
	_VH_SetDetailsMetaRow(8, "Status", tagTypeValue ~= "NONE" and tagTypeValue or "Standard")
	local tagValues = _VH_NormalizeRecommendationList(data.Tags)
	ScriptDetailsTagsText.Text = #tagValues > 0 and table.concat(tagValues, "  •  ") or "No tags"
	ScriptDetailsTagsText.TextColor3 = #tagValues > 0 and Theme.TextPrimary or Theme.TextSecondary
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
	local uiScale = math.max(0.8, math.min(1.2, tonumber(ScriptDetailsUIScale.Scale) or 1))
	local baseWidth = IsMobile and 322 or 420
	local baseHeight = IsMobile and 438 or 468
	local fittedWidth = math.min(baseWidth, math.max(240, (viewport.X - 24) / uiScale))
	local fittedHeight = math.min(baseHeight, math.max(260, (viewport.Y - 24) / uiScale))
	ScriptDetailsBox.Size = UDim2.fromOffset(fittedWidth, fittedHeight)
	ScriptDetailsOverlay.BackgroundTransparency = 0.5
	ScriptDetailsOverlay.Visible = true
	ScriptDetailsOverlay.Active = true
end
_VH_RegConn(ScriptDetailsClose.Activated:Connect(_VH_CreateDebounce(0.1, _VH_CloseScriptDetails)))
_VH_RegConn(ScriptDetailsCloseBottom.Activated:Connect(_VH_CreateDebounce(0.1, _VH_CloseScriptDetails)))
_VH_RegConn(ScriptDetailsOverlay.InputBegan:Connect(function(input)
	if not ScriptDetailsOverlay.Visible then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		local bPos, bSize = ScriptDetailsBox.AbsolutePosition, ScriptDetailsBox.AbsoluteSize
		local inside = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y
		if not inside then _VH_CloseScriptDetails() end
	end
end))
ToggleKeybind = Enum.KeyCode.RightControl
savedKeyCode = type(SavedData.ToggleKeybind) == "string" and Enum.KeyCode[SavedData.ToggleKeybind] or nil
if savedKeyCode then ToggleKeybind = savedKeyCode else SavedData.ToggleKeybind = ToggleKeybind.Name end
KeybindButtonRef = nil
function BindToggleKey(keyCode)
	if ToggleKeybindConnection then
		_VH_UnregConn(ToggleKeybindConnection)
		ToggleKeybindConnection = nil
	end
	ToggleKeybindConnection = _VH_RegConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
_VH_RegConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isConfirming then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
			CloseConfirmDialog(false)
			return
		end
	end
end))
function CloseUI()
	if isDestroying then return end
	if SearchInput and SearchInput.Parent then pcall(function() SearchInput:ReleaseFocus() end) end
	isDestroying = true
	GlobalEnv[_G_Identifier]()
end
HeaderContainer = Instance.new("Frame", PanelGroup)
HeaderContainer.Size = UDim2.new(1, -32, 0, IsMobile and 48 or 56)
HeaderContainer.Position = UDim2.new(0, 16, 0, IsMobile and 6 or 10)
HeaderContainer.BackgroundTransparency = 1
HeaderContainer.Active = true
mainDragStart, mainStartPos = nil, nil
_VH_RegConn(HeaderContainer.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeMainDragInput then
		activeMainDragInput = input
		mainDragStart = input.Position
		mainStartPos = MainPanel.Position
		if mainDragConnection then mainDragConnection:Disconnect() end
		mainDragConnection = _VH_RegConn(UserInputService.InputChanged:Connect(function(moveInput)
			if isDestroying then return end
			if moveInput == activeMainDragInput or moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				delta = moveInput.Position - mainDragStart
				camera = workspace.CurrentCamera
				viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
				targetX = mainStartPos.X.Scale * viewport.X + mainStartPos.X.Offset + delta.X
				targetY = mainStartPos.Y.Scale * viewport.Y + mainStartPos.Y.Offset + delta.Y
				halfX = MainPanel.AbsoluteSize.X * MainPanel.AnchorPoint.X
				halfY = MainPanel.AbsoluteSize.Y * MainPanel.AnchorPoint.Y
				targetX = math.clamp(targetX, halfX, viewport.X - (MainPanel.AbsoluteSize.X - halfX))
				targetY = math.clamp(targetY, halfY, viewport.Y - (MainPanel.AbsoluteSize.Y - halfY))
				MainPanel.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end))
_VH_RegConn(UserInputService.InputEnded:Connect(function(input)
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
			dist = (input.Position - floatStart).Magnitude
			if dist < 12 then
				ToggleUI()
			else
				if OriginalCache[FloatingBtn] then OriginalCache[FloatingBtn].Position = FloatingBtn.Position end
			end
		end
	end
end))
LeftHeaderFrame = Instance.new("Frame", HeaderContainer)
LeftHeaderFrame.Size = UDim2.new(0.6, 0, 1, 0); LeftHeaderFrame.BackgroundTransparency = 1; LeftHeaderFrame.Active = false
LHLay = Instance.new("UIListLayout", LeftHeaderFrame)
LHLay.SortOrder = Enum.SortOrder.LayoutOrder; LHLay.Padding = UDim.new(0, 4); LHLay.VerticalAlignment = Enum.VerticalAlignment.Center
TopLeftRow = Instance.new("Frame", LeftHeaderFrame)
TopLeftRow.Size = UDim2.new(1, 0, 0, 24); TopLeftRow.BackgroundTransparency = 1; TopLeftRow.LayoutOrder = 1
TLRowLay = Instance.new("UIListLayout", TopLeftRow)
TLRowLay.FillDirection = Enum.FillDirection.Horizontal; TLRowLay.SortOrder = Enum.SortOrder.LayoutOrder; TLRowLay.Padding = UDim.new(0, 8); TLRowLay.VerticalAlignment = Enum.VerticalAlignment.Center
Title = Instance.new("TextLabel", TopLeftRow)
Title.AutomaticSize = Enum.AutomaticSize.X; Title.Size = UDim2.new(0, 0, 1, 0); Title.BackgroundTransparency = 1
Title.Text = "Velox Hub"; Title.TextColor3 = Theme.TextPrimary
Title.Font = Enum.Font.GothamBold; Title.TextSize = IsMobile and 16 or 19; Title.LayoutOrder = 1
StatusDot = Instance.new("Frame", TopLeftRow)
StatusDot.Size = UDim2.new(0, 8, 0, 8); StatusDot.LayoutOrder = 2
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
StatusText = Instance.new("TextLabel", TopLeftRow)
StatusText.AutomaticSize = Enum.AutomaticSize.X; StatusText.Size = UDim2.new(0, 0, 1, 0); StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.GothamBold; StatusText.TextSize = 11; StatusText.LayoutOrder = 3
BtmLeftRow = Instance.new("Frame", LeftHeaderFrame)
BtmLeftRow.Size = UDim2.new(1, 0, 0, 14); BtmLeftRow.BackgroundTransparency = 1; BtmLeftRow.LayoutOrder = 2
BLRowLay = Instance.new("UIListLayout", BtmLeftRow)
BLRowLay.FillDirection = Enum.FillDirection.Horizontal; BLRowLay.SortOrder = Enum.SortOrder.LayoutOrder; BLRowLay.Padding = UDim.new(0, 6)
VersionLabel = Instance.new("TextLabel", BtmLeftRow)
VersionLabel.AutomaticSize = Enum.AutomaticSize.X; VersionLabel.Size = UDim2.new(0, 0, 1, 0)
VersionLabel.BackgroundTransparency = 1; VersionLabel.Text = "v2.0.4 BETA | " .. (type(identifyexecutor) == "function" and identifyexecutor() or (type(getexecutorname) == "function" and getexecutorname() or "Unknown Executor"))
VersionLabel.TextColor3 = Theme.Accent; VersionLabel.Font = Enum.Font.GothamMedium; VersionLabel.TextSize = IsMobile and 10 or 12; VersionLabel.LayoutOrder = 1
DiagnosticsLabel = Instance.new("TextLabel", BtmLeftRow)
DiagnosticsLabel.AutomaticSize = Enum.AutomaticSize.X; DiagnosticsLabel.Size = UDim2.new(0, 0, 1, 0); DiagnosticsLabel.BackgroundTransparency = 1
DiagnosticsLabel.TextColor3 = Theme.TextSecondary; DiagnosticsLabel.Font = Enum.Font.GothamMedium; DiagnosticsLabel.TextSize = IsMobile and 9 or 11
DiagnosticsLabel.Text = "FPS: -- | Ping: --ms"; DiagnosticsLabel.LayoutOrder = 2
RightHeaderFrame = Instance.new("Frame", HeaderContainer)
RightHeaderFrame.Size = UDim2.new(0.4, 0, 1, 0); RightHeaderFrame.Position = UDim2.new(1, 0, 0, 0); RightHeaderFrame.AnchorPoint = Vector2.new(1, 0)
RightHeaderFrame.BackgroundTransparency = 1; RightHeaderFrame.Active = false
RHLay = Instance.new("UIListLayout", RightHeaderFrame)
RHLay.FillDirection = Enum.FillDirection.Horizontal; RHLay.SortOrder = Enum.SortOrder.LayoutOrder; RHLay.HorizontalAlignment = Enum.HorizontalAlignment.Right; RHLay.VerticalAlignment = Enum.VerticalAlignment.Center; RHLay.Padding = UDim.new(0, 8)
UserInfoFrame = Instance.new("Frame", RightHeaderFrame)
UserInfoFrame.Size = UDim2.new(0, IsMobile and 70 or 90, 1, 0); UserInfoFrame.BackgroundTransparency = 1; UserInfoFrame.LayoutOrder = 1
UILay = Instance.new("UIListLayout", UserInfoFrame)
UILay.SortOrder = Enum.SortOrder.LayoutOrder; UILay.VerticalAlignment = Enum.VerticalAlignment.Center
UI_DisplayName = Instance.new("TextLabel", UserInfoFrame)
UI_DisplayName.Size = UDim2.new(1, 0, 0, 0); UI_DisplayName.AutomaticSize = Enum.AutomaticSize.Y; UI_DisplayName.BackgroundTransparency = 1
UI_DisplayName.Text = LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name; UI_DisplayName.TextColor3 = Theme.TextPrimary
UI_DisplayName.Font = Enum.Font.GothamBold; UI_DisplayName.TextSize = IsMobile and 10 or 12
UI_DisplayName.TextXAlignment = Enum.TextXAlignment.Right; UI_DisplayName.LayoutOrder = 1
UI_Username = Instance.new("TextLabel", UserInfoFrame)
UI_Username.Size = UDim2.new(1, 0, 0, 0); UI_Username.AutomaticSize = Enum.AutomaticSize.Y; UI_Username.BackgroundTransparency = 1
UI_Username.Text = "@" .. LocalPlayer.Name; UI_Username.TextColor3 = Theme.TextSecondary
UI_Username.Font = Enum.Font.Gotham; UI_Username.TextSize = IsMobile and 9 or 10
UI_Username.TextXAlignment = Enum.TextXAlignment.Right; UI_Username.LayoutOrder = 2
AvatarFrame = Instance.new("ImageLabel", RightHeaderFrame)
AvatarFrame.Size = UDim2.new(0, IsMobile and 26 or 32, 0, IsMobile and 26 or 32); AvatarFrame.BackgroundColor3 = Theme.CardHover
AvatarFrame.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"; AvatarFrame.LayoutOrder = 2
Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(0, 8)
AvatarStroke = Instance.new("UIStroke", AvatarFrame); AvatarStroke.Color = Theme.Accent; AvatarStroke.Thickness = 1.5
task.spawn(function()
	attempts = 0
	while attempts < 3 and not isDestroying do
		attempts = attempts + 1
		success, content = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
		if success and content then
			if isDestroying then return end
			if AvatarFrame and AvatarFrame.Parent then AvatarFrame.Image = content end
			break
		else
			task.wait(2)
		end
	end
end)
MinBtn = Instance.new("TextButton", RightHeaderFrame)
MinBtn.Size = UDim2.new(0, 28, 0, 28); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TextSecondary; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = IsMobile and 14 or 18; MinBtn.LayoutOrder = 3
MinBtn.ClipsDescendants = true
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
_VH_RegConn(MinBtn.Activated:Connect(function() ToggleUI() end))
ApplyInteractiveAnimations(MinBtn, nil, Theme.CardHover, Theme.CardHover, nil, nil, nil)
fpsCount = 0
diagnosticsElapsed = 0
_VH_RegConn(RunService.Heartbeat:Connect(function(deltaTime)
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
	success, ping = pcall(function()
		return math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
	end)
	if DiagnosticsLabel and DiagnosticsLabel.Parent then
		DiagnosticsLabel.Text = string.format("FPS: %d | Ping: %dms", fpsCount, success and ping or 0)
	end
	fpsCount = 0
end))
TabContainer = Instance.new("Frame", PanelGroup)
TabContainer.Size = UDim2.new(1, -32, 0, 24); TabContainer.Position = UDim2.new(0, 16, 0, IsMobile and 58 or 72); TabContainer.BackgroundTransparency = 1; TabContainer.Active = false
SectionHeaderLabel = Instance.new("TextLabel", PanelGroup)
SectionHeaderLabel.Size = UDim2.new(1, -32, 0, IsMobile and 16 or 20); SectionHeaderLabel.Position = UDim2.new(0, 16, 0, IsMobile and 88 or 104); SectionHeaderLabel.BackgroundTransparency = 1
SectionHeaderLabel.Text = "Updates"; SectionHeaderLabel.TextColor3 = Theme.TextPrimary
SectionHeaderLabel.Font = Enum.Font.GothamBold; SectionHeaderLabel.TextSize = IsMobile and 13 or 16; SectionHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
TabViews = {}
currentTab = "Changelogs"
function CreateCanvas(name)
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
ChangelogsView = CreateCanvas("Changelogs")
ScriptsView = CreateCanvas("Scripts")
SettingsView = CreateCanvas("Settings")
ScriptsView.Position = IsMobile and UDim2.new(0, 16, 0, 144) or UDim2.new(0, 16, 0, 168)
ScriptsView.Size = IsMobile and UDim2.new(1, -32, 1, -152) or UDim2.new(1, -32, 1, -178)
EmptyStateMessage = Instance.new("TextLabel", ScriptsView)
EmptyStateMessage.Size = UDim2.new(1, 0, 0, 40); EmptyStateMessage.BackgroundTransparency = 1
EmptyStateMessage.TextColor3 = Theme.TextSecondary; EmptyStateMessage.Font = Enum.Font.GothamMedium
EmptyStateMessage.TextSize = 12; EmptyStateMessage.TextWrapped = true; EmptyStateMessage.LayoutOrder = -1
SearchRow = Instance.new("Frame", PanelGroup)
SearchRow.Size = UDim2.new(1, -32, 0, IsMobile and 28 or 32); SearchRow.Position = UDim2.new(0, 16, 0, IsMobile and 108 or 128)
SearchRow.BackgroundTransparency = 1; SearchRow.Visible = false; SearchRow.Active = false; SearchRow.ZIndex = 50
filterBtnWidth = IsMobile and 28 or 32
gap = 8
SearchContainer = Instance.new("Frame", SearchRow)
SearchContainer.Size = UDim2.new(1, -(filterBtnWidth * 2 + gap * 2), 1, 0); SearchContainer.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
SearchContainer.ClipsDescendants = true; SearchContainer.ZIndex = 51
Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 6)
SearchStroke = Instance.new("UIStroke", SearchContainer); SearchStroke.Color = Color3.fromRGB(51, 65, 85); SearchStroke.Thickness = 1
SearchInput = Instance.new("TextBox", SearchContainer)
SearchInput.Size = UDim2.new(1, -40, 1, 0); SearchInput.Position = UDim2.new(0, 12, 0, 0); SearchInput.BackgroundTransparency = 1
SearchInput.Text = ""; SearchInput.PlaceholderText = "Search scripts by name..."
SearchInput.PlaceholderColor3 = Color3.fromRGB(203, 213, 225); SearchInput.TextColor3 = Color3.fromRGB(248, 250, 252)
SearchInput.Font = Enum.Font.Gotham; SearchInput.TextSize = 12; SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false; SearchInput.TextEditable = true; SearchInput.Interactable = true; SearchInput.ZIndex = 52
Instance.new("UIPadding", SearchInput).PaddingRight = UDim.new(0, 10)
ClearSearchBtn = Instance.new("TextButton", SearchContainer)
ClearSearchBtn.Size = UDim2.new(0, 24, 0, 24)
ClearSearchBtn.Position = UDim2.new(1, -28, 0.5, -12)
ClearSearchBtn.BackgroundTransparency = 1
ClearSearchBtn.Text = "×"
ClearSearchBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
ClearSearchBtn.TextSize = 18
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.ZIndex = 53
ClearSearchBtn.Visible = (SearchInput.Text ~= "")
_VH_RegConn(SearchInput.Focused:Connect(function() SearchStroke.Color = Theme.Accent end))
_VH_RegConn(SearchInput.FocusLost:Connect(function() SearchStroke.Color = Theme.Stroke end))
FavFilterBtn = Instance.new("TextButton", SearchRow)
FavFilterBtn.Size = UDim2.new(0, filterBtnWidth, 1, 0); FavFilterBtn.Position = UDim2.new(1, -(filterBtnWidth * 2 + gap), 0, 0)
FavFilterBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59); FavFilterBtn.Text = "☆"
FavFilterBtn.TextColor3 = Color3.fromRGB(203, 213, 225); FavFilterBtn.TextSize = 15
FavFilterBtn.Font = Enum.Font.GothamBold; FavFilterBtn.ZIndex = 51
Instance.new("UICorner", FavFilterBtn).CornerRadius = UDim.new(0, 6)
FavFilterStroke = Instance.new("UIStroke", FavFilterBtn); FavFilterStroke.Color = Color3.fromRGB(51, 65, 85)
SortDropdownBtn = Instance.new("TextButton", SearchRow)
SortDropdownBtn.Size = UDim2.new(0, filterBtnWidth, 1, 0); SortDropdownBtn.Position = UDim2.new(1, -filterBtnWidth, 0, 0)
SortDropdownBtn.BackgroundColor3 = Color3.fromRGB(38, 51, 74); SortDropdownBtn.Text = "↕"
SortDropdownBtn.TextColor3 = Theme.TextSecondary; SortDropdownBtn.TextSize = 15
SortDropdownBtn.Font = Enum.Font.GothamBold; SortDropdownBtn.ZIndex = 51; SortDropdownBtn.ClipsDescendants = true
Instance.new("UICorner", SortDropdownBtn).CornerRadius = UDim.new(0, 6)
SortBtnStroke = Instance.new("UIStroke", SortDropdownBtn); SortBtnStroke.Color = Theme.Stroke
ApplyInteractiveAnimations(SortDropdownBtn, Color3.fromRGB(38, 51, 74), Color3.fromRGB(50, 68, 96), Theme.BackgroundSecondary, SortBtnStroke, Theme.Stroke, Theme.Accent)

RecommendationPanel = Instance.new("Frame", ScriptsView)
RecommendationPanel.Name = "RecommendedForYouPanel"
RecommendationPanel.Size = UDim2.new(1, -4, 0, IsMobile and 136 or 148)
RecommendationPanel.Position = UDim2.new(0, 2, 0, 0)
RecommendationPanel.BackgroundColor3 = Color3.fromRGB(10, 15, 28)
RecommendationPanel.BorderSizePixel = 0
RecommendationPanel.LayoutOrder = 0
RecommendationPanel.Visible = false
RecommendationPanel.ClipsDescendants = true
Instance.new("UICorner", RecommendationPanel).CornerRadius = UDim.new(0, 12)

RecommendationBorder = Instance.new("Frame", RecommendationPanel)
RecommendationBorder.Name = "InsetBorder"
RecommendationBorder.Size = UDim2.new(1, -2, 1, -2)
RecommendationBorder.Position = UDim2.new(0, 1, 0, 1)
RecommendationBorder.BackgroundTransparency = 1
RecommendationBorder.BorderSizePixel = 0
RecommendationBorder.ZIndex = 3
Instance.new("UICorner", RecommendationBorder).CornerRadius = UDim.new(0, 11)
RecommendationPanelStroke = Instance.new("UIStroke", RecommendationBorder)
RecommendationPanelStroke.Color = Color3.fromRGB(93, 88, 225)
RecommendationPanelStroke.Transparency = 0.32
RecommendationPanelStroke.Thickness = 1

RecommendationPanelGradient = Instance.new("UIGradient", RecommendationPanel)
RecommendationPanelGradient.Rotation = 90
RecommendationPanelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 25, 47)),
	ColorSequenceKeypoint.new(0.52, Color3.fromRGB(11, 18, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 14, 26))
})

RecommendationAccent = Instance.new("Frame", RecommendationPanel)
RecommendationAccent.Size = UDim2.new(1, -28, 0, 2)
RecommendationAccent.Position = UDim2.new(0, 14, 0, 10)
RecommendationAccent.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
RecommendationAccent.BorderSizePixel = 0
RecommendationAccent.ZIndex = 5
Instance.new("UICorner", RecommendationAccent).CornerRadius = UDim.new(1, 0)

RecommendationIcon = Instance.new("Frame", RecommendationPanel)
RecommendationIcon.Size = UDim2.new(0, IsMobile and 26 or 30, 0, IsMobile and 26 or 30)
RecommendationIcon.Position = UDim2.new(0, 12, 0, IsMobile and 18 or 20)
RecommendationIcon.BackgroundColor3 = Color3.fromRGB(33, 38, 91)
RecommendationIcon.BorderSizePixel = 0
RecommendationIcon.ZIndex = 6
Instance.new("UICorner", RecommendationIcon).CornerRadius = UDim.new(0, 8)
RecommendationIconStroke = Instance.new("UIStroke", RecommendationIcon)
RecommendationIconStroke.Color = Color3.fromRGB(109, 113, 255)
RecommendationIconStroke.Transparency = 0.14
RecommendationIconStroke.Thickness = 1
RecommendationSparkBack = Instance.new("Frame", RecommendationIcon)
RecommendationSparkBack.Size = UDim2.new(0, IsMobile and 10 or 12, 0, IsMobile and 10 or 12)
RecommendationSparkBack.Position = UDim2.new(0.5, -(IsMobile and 5 or 6), 0.5, -(IsMobile and 5 or 6))
RecommendationSparkBack.BackgroundColor3 = Color3.fromRGB(188, 193, 255)
RecommendationSparkBack.BorderSizePixel = 0
RecommendationSparkBack.Rotation = 45
RecommendationSparkBack.ZIndex = 7
Instance.new("UICorner", RecommendationSparkBack).CornerRadius = UDim.new(0, 3)
RecommendationSparkCore = Instance.new("Frame", RecommendationIcon)
RecommendationSparkCore.Size = UDim2.new(0, IsMobile and 4 or 5, 0, IsMobile and 4 or 5)
RecommendationSparkCore.Position = UDim2.new(0.5, -(IsMobile and 2 or 2.5), 0.5, -(IsMobile and 2 or 2.5))
RecommendationSparkCore.BackgroundColor3 = Color3.fromRGB(68, 74, 160)
RecommendationSparkCore.BorderSizePixel = 0
RecommendationSparkCore.ZIndex = 8
Instance.new("UICorner", RecommendationSparkCore).CornerRadius = UDim.new(1, 0)

RecommendationTitle = Instance.new("TextLabel", RecommendationPanel)
RecommendationTitle.Size = UDim2.new(1, -(IsMobile and 150 or 170), 0, 18)
RecommendationTitle.Position = UDim2.new(0, IsMobile and 46 or 50, 0, IsMobile and 17 or 19)
RecommendationTitle.BackgroundTransparency = 1
RecommendationTitle.Text = "Recommended for You"
RecommendationTitle.TextColor3 = Theme.TextPrimary
RecommendationTitle.Font = Enum.Font.GothamBold
RecommendationTitle.TextSize = IsMobile and 12 or 14
RecommendationTitle.TextXAlignment = Enum.TextXAlignment.Left
RecommendationTitle.TextTruncate = Enum.TextTruncate.AtEnd
RecommendationTitle.ZIndex = 6

RecommendationSubtitle = Instance.new("TextLabel", RecommendationPanel)
RecommendationSubtitle.Size = UDim2.new(1, -(IsMobile and 155 or 175), 0, 15)
RecommendationSubtitle.Position = UDim2.new(0, IsMobile and 46 or 50, 0, IsMobile and 35 or 37)
RecommendationSubtitle.BackgroundTransparency = 1
RecommendationSubtitle.Text = "Based on your current game"
RecommendationSubtitle.TextColor3 = Color3.fromRGB(203, 213, 225)
RecommendationSubtitle.Font = Enum.Font.GothamMedium
RecommendationSubtitle.TextSize = IsMobile and 8 or 9
RecommendationSubtitle.TextXAlignment = Enum.TextXAlignment.Left
RecommendationSubtitle.TextTruncate = Enum.TextTruncate.AtEnd
RecommendationSubtitle.ZIndex = 6

RecommendationSeeMoreButton = Instance.new("TextButton", RecommendationPanel)
RecommendationSeeMoreButton.Size = UDim2.new(0, IsMobile and 76 or 88, 0, IsMobile and 24 or 26)
RecommendationSeeMoreButton.Position = UDim2.new(1, -(IsMobile and 88 or 100), 0, IsMobile and 18 or 20)
RecommendationSeeMoreButton.BackgroundColor3 = Color3.fromRGB(40, 34, 105)
RecommendationSeeMoreButton.BorderSizePixel = 0
RecommendationSeeMoreButton.AutoButtonColor = false
RecommendationSeeMoreButton.Text = "See More >"
RecommendationSeeMoreButton.TextColor3 = Color3.fromRGB(216, 218, 255)
RecommendationSeeMoreButton.Font = Enum.Font.GothamBold
RecommendationSeeMoreButton.TextSize = IsMobile and 8 or 9
RecommendationSeeMoreButton.ZIndex = 7
Instance.new("UICorner", RecommendationSeeMoreButton).CornerRadius = UDim.new(0, 8)
RecommendationSeeMoreStroke = Instance.new("UIStroke", RecommendationSeeMoreButton)
RecommendationSeeMoreStroke.Color = Color3.fromRGB(105, 109, 240)
RecommendationSeeMoreStroke.Transparency = 0.18
RecommendationSeeMoreStroke.Thickness = 1

RecommendationList = Instance.new("Frame", RecommendationPanel)
RecommendationList.Size = UDim2.new(1, IsMobile and -80 or -88, 0, IsMobile and 66 or 76)
RecommendationList.Position = UDim2.new(0, IsMobile and 40 or 44, 0, IsMobile and 58 or 61)
RecommendationList.BackgroundTransparency = 1
RecommendationList.BorderSizePixel = 0
RecommendationList.ClipsDescendants = true
RecommendationList.ZIndex = 5
RecommendationListLayout = Instance.new("UIListLayout", RecommendationList)
RecommendationListLayout.FillDirection = Enum.FillDirection.Horizontal
RecommendationListLayout.SortOrder = Enum.SortOrder.LayoutOrder
RecommendationListLayout.Padding = UDim.new(0, IsMobile and 7 or 8)
RecommendationListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
RecommendationListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
RecommendationListPadding = Instance.new("UIPadding", RecommendationList)
RecommendationListPadding.PaddingLeft = UDim.new(0, 0)
RecommendationListPadding.PaddingRight = UDim.new(0, 0)

RecommendationPrevButton = Instance.new("TextButton", RecommendationPanel)
RecommendationPrevButton.Size = UDim2.new(0, IsMobile and 24 or 28, 0, IsMobile and 24 or 28)
RecommendationPrevButton.Position = UDim2.new(0, IsMobile and 6 or 7, 0, IsMobile and 79 or 85)
RecommendationPrevButton.BackgroundColor3 = Color3.fromRGB(26, 34, 57)
RecommendationPrevButton.BorderSizePixel = 0
RecommendationPrevButton.AutoButtonColor = false
RecommendationPrevButton.Text = "<"
RecommendationPrevButton.TextColor3 = Color3.fromRGB(222, 227, 245)
RecommendationPrevButton.Font = Enum.Font.GothamBold
RecommendationPrevButton.TextSize = IsMobile and 12 or 14
RecommendationPrevButton.ZIndex = 10
Instance.new("UICorner", RecommendationPrevButton).CornerRadius = UDim.new(1, 0)
RecommendationPrevStroke = Instance.new("UIStroke", RecommendationPrevButton)
RecommendationPrevStroke.Color = Color3.fromRGB(69, 82, 118)
RecommendationPrevStroke.Transparency = 0.18
RecommendationPrevStroke.Thickness = 1

RecommendationNextButton = Instance.new("TextButton", RecommendationPanel)
RecommendationNextButton.Size = UDim2.new(0, IsMobile and 24 or 28, 0, IsMobile and 24 or 28)
RecommendationNextButton.Position = UDim2.new(1, -(IsMobile and 30 or 35), 0, IsMobile and 79 or 85)
RecommendationNextButton.BackgroundColor3 = Color3.fromRGB(26, 34, 57)
RecommendationNextButton.BorderSizePixel = 0
RecommendationNextButton.AutoButtonColor = false
RecommendationNextButton.Text = ">"
RecommendationNextButton.TextColor3 = Color3.fromRGB(222, 227, 245)
RecommendationNextButton.Font = Enum.Font.GothamBold
RecommendationNextButton.TextSize = IsMobile and 12 or 14
RecommendationNextButton.ZIndex = 10
Instance.new("UICorner", RecommendationNextButton).CornerRadius = UDim.new(1, 0)
RecommendationNextStroke = Instance.new("UIStroke", RecommendationNextButton)
RecommendationNextStroke.Color = Color3.fromRGB(69, 82, 118)
RecommendationNextStroke.Transparency = 0.18
RecommendationNextStroke.Thickness = 1

RecommendationPageLabel = Instance.new("TextLabel", RecommendationPanel)
RecommendationPageLabel.Size = UDim2.new(0, 60, 0, 11)
RecommendationPageLabel.Position = UDim2.new(0.5, -30, 1, -(IsMobile and 13 or 14))
RecommendationPageLabel.BackgroundTransparency = 1
RecommendationPageLabel.Text = ""
RecommendationPageLabel.TextColor3 = Color3.fromRGB(190, 200, 215)
RecommendationPageLabel.Font = Enum.Font.GothamMedium
RecommendationPageLabel.TextSize = 8
RecommendationPageLabel.TextXAlignment = Enum.TextXAlignment.Center
RecommendationPageLabel.ZIndex = 6

ApplyInteractiveAnimations(RecommendationSeeMoreButton, RecommendationSeeMoreButton.BackgroundColor3, Color3.fromRGB(55, 48, 130), Color3.fromRGB(27, 22, 70), RecommendationSeeMoreStroke, RecommendationSeeMoreStroke.Color, Theme.Accent)
ApplyInteractiveAnimations(RecommendationPrevButton, RecommendationPrevButton.BackgroundColor3, Color3.fromRGB(40, 52, 84), Color3.fromRGB(17, 24, 42), RecommendationPrevStroke, RecommendationPrevStroke.Color, Theme.Accent)
ApplyInteractiveAnimations(RecommendationNextButton, RecommendationNextButton.BackgroundColor3, Color3.fromRGB(40, 52, 84), Color3.fromRGB(17, 24, 42), RecommendationNextStroke, RecommendationNextStroke.Color, Theme.Accent)

DropdownContainer = Instance.new("ScrollingFrame", ScreenGui)
DropdownContainer.Size = UDim2.new(0, 190, 0, 210); DropdownContainer.BackgroundColor3 = Theme.BackgroundMain
DropdownContainer.Visible = false; DropdownContainer.ZIndex = 1000; DropdownContainer.BorderSizePixel = 0
DropdownContainer.ScrollBarThickness = 2; DropdownContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", DropdownContainer).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", DropdownContainer).Color = Theme.Accent
DDLayout = Instance.new("UIListLayout", DropdownContainer); DDLayout.SortOrder = Enum.SortOrder.LayoutOrder
viewportConn = nil
function BindCamera()
	if viewportConn then viewportConn:Disconnect() end
	cam = workspace.CurrentCamera
	if cam then
		viewportConn = _VH_RegConn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if DropdownContainer and DropdownContainer.Visible then
				DropdownContainer.Visible = false
			end
			if MainPanel and MainPanel.Parent then
				viewport = cam.ViewportSize
				halfX = MainPanel.AbsoluteSize.X * MainPanel.AnchorPoint.X
				halfY = MainPanel.AbsoluteSize.Y * MainPanel.AnchorPoint.Y
				currentOffsetX = MainPanel.Position.X.Offset
				currentOffsetY = MainPanel.Position.Y.Offset
				if MainPanel.Position.X.Scale ~= 0 or MainPanel.Position.Y.Scale ~= 0 then
					currentOffsetX = MainPanel.Position.X.Scale * viewport.X + currentOffsetX
					currentOffsetY = MainPanel.Position.Y.Scale * viewport.Y + currentOffsetY
				end
				targetX = math.clamp(currentOffsetX, halfX, viewport.X - (MainPanel.AbsoluteSize.X - halfX))
				targetY = math.clamp(currentOffsetY, halfY, viewport.Y - (MainPanel.AbsoluteSize.Y - halfY))
				MainPanel.Position = UDim2.new(0, targetX, 0, targetY)
			end
		end))
	end
end
_VH_RegConn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCamera))
BindCamera()
function RefreshViewportLayout()
	if isDestroying or not MainPanel or not MainPanel.Parent then return end
	MainPanel.Size = GetPanelSize()
	camera = workspace.CurrentCamera
	viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
	halfX = MainPanel.AbsoluteSize.X * MainPanel.AnchorPoint.X
	halfY = MainPanel.AbsoluteSize.Y * MainPanel.AnchorPoint.Y
	currentX = MainPanel.Position.X.Scale * viewport.X + MainPanel.Position.X.Offset
	currentY = MainPanel.Position.Y.Scale * viewport.Y + MainPanel.Position.Y.Offset
	currentX = math.clamp(currentX, halfX, viewport.X - (MainPanel.AbsoluteSize.X - halfX))
	currentY = math.clamp(currentY, halfY, viewport.Y - (MainPanel.AbsoluteSize.Y - halfY))
	MainPanel.Position = UDim2.new(0, currentX, 0, currentY)
end
function BindViewportSizeChanged(camera)
	if not camera then return end
	_VH_RegConn(camera:GetPropertyChangedSignal("ViewportSize"):Connect(RefreshViewportLayout))
	RefreshViewportLayout()
end
BindViewportSizeChanged(workspace.CurrentCamera)
FilterFavoritesActive = false
filterVersion = 0
SortMode = "Most Relevant"
SortOptions = {
	"Most Relevant", "A-Z", "Z-A", "Newest", "Oldest",
	"Updated Today", "Updated This Week", "Updated This Month",
	"Favorites", "Auto Execute: ON", "Auto Execute: OFF"
}
function UpdateFilter()
	if isDestroying then return end
	filterVersion = filterVersion + 1
	local currentVersion = filterVersion
	task.defer(function()
		if isDestroying or currentVersion ~= filterVersion then return end
		local query = string.lower(string.gsub(SearchInput.Text or "", "^%s*(.-)%s*$", "%1"))
		if RecommendationPanel and RecommendationPanel.Parent then
			RecommendationPanel.Visible = #RecommendationItems > 0 and currentTab == "Scripts" and query == "" and not FilterFavoritesActive
		end
		local words = {}
		for word in string.gmatch(query, "%S+") do words[#words + 1] = word end
		local matches = {}
		local currentSort = SortMode
		for _, scr in ipairs(RegisteredScripts) do
			if currentVersion ~= filterVersion then return end
			local isMatch = true
			if query ~= "" then
				for _, word in ipairs(words) do
					if not string.find(scr.SearchTitle, word, 1, true) and not string.find(scr.SearchDesc, word, 1, true) and not string.find(scr.SearchMeta, word, 1, true) then
						isMatch = false
						break
					end
				end
			end
			local filterPass = not FilterFavoritesActive or SavedData.Favorites[scr.Id] == true
			if filterPass then
				if currentSort == "Updated Today" then
					filterPass = IsCalendarDay(scr.LastUpdatedNumber)
				elseif currentSort == "Updated This Week" then
					filterPass = IsCalendarWeek(scr.LastUpdatedNumber)
				elseif currentSort == "Updated This Month" then
					filterPass = IsCalendarMonth(scr.LastUpdatedNumber)
				elseif currentSort == "Favorites" then
					filterPass = SavedData.Favorites[scr.Id] == true
				elseif currentSort == "Auto Execute: ON" then
					filterPass = SavedData.AutoExecutes[scr.Id] ~= nil
				elseif currentSort == "Auto Execute: OFF" then
					filterPass = SavedData.AutoExecutes[scr.Id] == nil
				end
			end
			local visible = isMatch and filterPass
			if scr.Instance.Visible ~= visible then scr.Instance.Visible = visible end
			if visible then matches[#matches + 1] = scr end
		end
		if currentVersion ~= filterVersion then return end
		table.sort(matches, function(a, b)
			if currentSort == "Most Relevant" then
				if a.Recommended ~= b.Recommended then return a.Recommended == true end
				if a.RecommendationScore ~= b.RecommendationScore then return a.RecommendationScore > b.RecommendationScore end
				if a.RecommendationRank ~= b.RecommendationRank then return a.RecommendationRank < b.RecommendationRank end
			end
			if currentSort == "A-Z" then
				if a.SearchTitle ~= b.SearchTitle then return a.SearchTitle < b.SearchTitle end
			elseif currentSort == "Z-A" then
				if a.SearchTitle ~= b.SearchTitle then return a.SearchTitle > b.SearchTitle end
			elseif currentSort == "Oldest" then
				if a.LastUpdatedNumber ~= b.LastUpdatedNumber then return a.LastUpdatedNumber < b.LastUpdatedNumber end
			elseif currentSort == "Newest" or currentSort == "Updated Today" or currentSort == "Updated This Week" or currentSort == "Updated This Month" then
				if a.LastUpdatedNumber ~= b.LastUpdatedNumber then return a.LastUpdatedNumber > b.LastUpdatedNumber end
			else
				if a.TagPriority ~= b.TagPriority then return a.TagPriority > b.TagPriority end
				if a.LastUpdatedNumber ~= b.LastUpdatedNumber then return a.LastUpdatedNumber > b.LastUpdatedNumber end
			end
			if a.SearchTitle ~= b.SearchTitle then return a.SearchTitle < b.SearchTitle end
			return a.Id < b.Id
		end)
		for order, scr in ipairs(matches) do scr.Instance.LayoutOrder = order end
		local shouldShowEmpty = #RegisteredScripts > 0 and #matches == 0
		if EmptyStateMessage.Visible ~= shouldShowEmpty then EmptyStateMessage.Visible = shouldShowEmpty end
		if shouldShowEmpty then EmptyStateMessage.Text = "No scripts matched your search or filters." end
		if query == "" and shouldShowEmpty == false and EmptyStateMessage.Text == "No scripts matched your search or filters." then EmptyStateMessage.Text = "" end
	end)
end
_VH_RegConn(SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	ClearSearchBtn.Visible = (SearchInput.Text ~= "")
	if typingTask then task.cancel(typingTask) end
	typingTask = task.delay(0.2, function() UpdateFilter() end)
end))
_VH_RegConn(ClearSearchBtn.Activated:Connect(function()
	SearchInput.Text = ""
	if SearchInput:IsFocused() then SearchInput:ReleaseFocus() end
end))
_VH_RegConn(FavFilterBtn.MouseButton1Click:Connect(_VH_CreateDebounce(0.1, function()
	if isDestroying then return end
	FilterFavoritesActive = not FilterFavoritesActive
	if FilterFavoritesActive then
		FavFilterBtn.Text = "★"; FavFilterBtn.TextColor3 = Color3.fromRGB(250, 204, 21); FavFilterStroke.Color = Color3.fromRGB(250, 204, 21)
		ShowNotification("Showing your favorite scripts only.", "Info")
	else
		FavFilterBtn.Text = "☆"; FavFilterBtn.TextColor3 = Color3.fromRGB(203, 213, 225); FavFilterStroke.Color = Color3.fromRGB(51, 65, 85)
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
	_VH_RegConn(btn.Activated:Connect(function()
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
_VH_RegConn(SortDropdownBtn.Activated:Connect(function()
	if DropdownContainer.Visible then
		DropdownContainer.Visible = false
	else
		absPos = SortDropdownBtn.AbsolutePosition
		absSize = SortDropdownBtn.AbsoluteSize
		camera = workspace.CurrentCamera
		viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		dropWidth, dropHeight = 190, 210
		posX = math.clamp(absPos.X + absSize.X - dropWidth, 10, viewportSize.X - dropWidth - 10)
		posY = absPos.Y + absSize.Y + 4
		if posY + dropHeight > viewportSize.Y - 10 then
			posY = absPos.Y - dropHeight - 4
		end
		if posY < 10 then posY = 10 end
		DropdownContainer.Position = UDim2.new(0, posX, 0, posY)
		DropdownContainer.Visible = true
	end
end))
_VH_RegConn(UserInputService.InputBegan:Connect(function(input)
	if DropdownContainer.Visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		pos = input.Position
		dPos, dSize = DropdownContainer.AbsolutePosition, DropdownContainer.AbsoluteSize
		sPos, sSize = SortDropdownBtn.AbsolutePosition, SortDropdownBtn.AbsoluteSize
		insideDrop = pos.X >= dPos.X and pos.X <= dPos.X + dSize.X and pos.Y >= dPos.Y and pos.Y <= dPos.Y + dSize.Y
		insideBtn = pos.X >= sPos.X and pos.X <= sPos.X + sSize.X and pos.Y >= sPos.Y and pos.Y <= sPos.Y + sSize.Y
		if not insideDrop and not insideBtn then DropdownContainer.Visible = false end
	end
end))
TabIndicator = Instance.new("Frame", TabContainer)
TabIndicator.Size = UDim2.new(0, IsMobile and 80 or 100, 0, 2)
TabIndicator.Position = UDim2.new(0, 4, 1, -2)
TabIndicator.BackgroundColor3 = Theme.Accent
TabIndicator.BorderSizePixel = 0
TabButtonCache = {}
function CreateTab(name, index)
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
	_VH_RegConn(btn.Activated:Connect(function()
		if isDestroying or currentTab == name then return end
		currentTab = name; DropdownContainer.Visible = false
		TabIndicator.Size = UDim2.new(0, IsMobile and 80 or 100, 0, 2)
		TabIndicator.BackgroundTransparency = 0
		_VH_SafeTween(TabIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, xOffset + 4, 1, -2)})
		SectionHeaderLabel.Text = (name == "Changelogs") and "Updates" or (name == "Scripts") and "Scripts Catalog" or "Settings Hub"
		SearchRow.Visible = (name == "Scripts")
		if name == "Scripts" then
			UpdateFilter()
			SearchRow.BackgroundTransparency = 1
			_VH_SafeTween(SearchRow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
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
function CreateParagraph(title, desc, parentView)
	block = Instance.new("Frame", parentView)
	block.Size = UDim2.new(1, 0, 0, 0); block.AutomaticSize = Enum.AutomaticSize.Y
	block.BackgroundColor3 = Theme.CardHover
	Instance.new("UICorner", block).CornerRadius = UDim.new(0, 8)
	blockStroke = Instance.new("UIStroke", block); blockStroke.Color = Color3.fromRGB(33, 43, 61)
	pad = Instance.new("UIPadding", block)
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	lay = Instance.new("UIListLayout", block)
	lay.Padding = UDim.new(0, 4); lay.SortOrder = Enum.SortOrder.LayoutOrder
	tLbl = Instance.new("TextLabel", block)
	tLbl.Size = UDim2.new(1, 0, 0, 18); tLbl.BackgroundTransparency = 1; tLbl.Text = title
	tLbl.TextColor3 = Theme.TextPrimary; tLbl.Font = Enum.Font.GothamBold; tLbl.TextSize = 13
	tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.LayoutOrder = 1
	dLbl = Instance.new("TextLabel", block)
	dLbl.Size = UDim2.new(1, 0, 0, 0); dLbl.AutomaticSize = Enum.AutomaticSize.Y
	dLbl.BackgroundTransparency = 1; dLbl.Text = desc; dLbl.TextColor3 = Theme.TextSecondary
	dLbl.Font = Enum.Font.Gotham; dLbl.TextSize = 12; dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.TextWrapped = true; dLbl.LayoutOrder = 2
end
CreateParagraph("Found a Bug?", "If you run into any bugs, issues, or anything that doesn't seem right, please report it on our Discord. It really helps me figure out what's going wrong and fix it faster. Even small details can be useful, so don't hesitate to report anything you notice!", ChangelogsView)
CreateParagraph("v2.0.4 - Final Cleanup, Compatibility & UI Fixes", "• Hardened HTTP and compiler fallbacks for broader executor compatibility without depending on one request or load API.\n• Added safer service references and GUI protection fallbacks for executors with different APIs.\n• Kept Recommended for You cards proportional under UI scaling and preserved balanced three-card spacing.\n• Kept navigation arrows separated from recommendation cards to reduce missed touches on mobile.\n• Normal script cards use full Updated 2 Hours Ago labels while Recommended for You keeps compact 2h ago labels.\n• Limited favorite-derived recommendation context to a small bounded sample and capped its scoring influence so favorites cannot overpower current-game relevance.\n• Batched favorite changes before saving and refreshing recommendations to reduce repeated local I/O and recommendation churn from rapid toggling.\n• Raised secondary and muted UI text contrast for clearer readability without adding a settings toggle.\n• Added a themed script details panel with metadata, tags, compatibility, favorites, auto-execute state, and update information.\n• Adjusted the details header to use the previously empty vertical space more efficiently and reduced the Details button to a borderless themed control.\n• Preserved the PlaceId-based FOR YOU backbone and all critical fallback behavior.", ChangelogsView)
CreateParagraph("v2.0.3 - UI, Notifications & Catalog Improvements", "• Added adjustable UI scaling from 80% to 120% with saved scale settings.\n• Redesigned notifications with improved types, titles, close controls, animations, and countdown progress bars.\n• Improved notification stacking and mobile positioning/sizing.\n• Improved catalog refresh performance to reduce unnecessary UI recreation and frame spikes.\n• Improved automatic catalog refresh handling and refresh button feedback.\n• Updated script recommendation badges and card presentation.\n• Added testing-phase Recommended for You suggestions that surface other games using catalog metadata, favorites, game types, and recent updates.\n• Kept the PlaceId-based FOR YOU system as the primary current-game recommendation while adding separate Recommended for You suggestions.\n• Added additional UI and mobile performance refinements.", ChangelogsView)
function StableScriptId(data)
	if type(data) ~= "table" then return nil end
	if type(data.Id) == "string" and string.gsub(data.Id, "^%s*(.-)%s*$", "%1") ~= "" then
		return string.gsub(data.Id, "^%s*(.-)%s*$", "%1")
	end
	local source = type(data.RawUrl) == "string" and string.gsub(data.RawUrl, "^%s*(.-)%s*$", "%1") or ""
	if source ~= "" then return "url:" .. source end
	local name = type(data.Name) == "string" and string.gsub(data.Name, "^%s*(.-)%s*$", "%1") or "Unnamed Script"
	return "name:" .. string.lower(name) .. ":" .. tostring(tonumber(data.PlaceId) or 0)
end
function IsScriptCompatible(data)
	local allowedPlaceId = tonumber(data and data.PlaceId) or 0
	return allowedPlaceId == 0 or allowedPlaceId == PlaceId
end
function IsRecommendedForCurrentPlace(data)
	local allowedPlaceId = tonumber(data and data.PlaceId) or 0
	return PlaceId ~= 0 and allowedPlaceId == PlaceId
end

function _VH_GetRecommendationReason(reasonType, overlapCount, favoriteOverlap, topicOverlap, favoriteTopicOverlap, isRecent, tagType)
	if reasonType == "CURRENT" then return "Matches your current game" end
	if topicOverlap and topicOverlap > 0 then return "Similar to your current game" end
	if favoriteTopicOverlap and favoriteTopicOverlap > 0 then return "Related to your favorites" end
	if favoriteOverlap and favoriteOverlap > 0 then return "Similar to your favorites" end
	if overlapCount and overlapCount > 0 then return "Shares similar game details" end
	if tagType == "HOT" or tagType == "FEATURED" then return "Featured in Velox Hub" end
	if isRecent then return "Recently updated" end
	return "More games in Velox Hub"
end

function _VH_BuildRecommendationState()
	RecommendationGeneration = RecommendationGeneration + 1
	local generation = RecommendationGeneration
	local currentSet, favoriteSet, currentCategories, currentTags, currentTopics, favoriteTopics, currentCount = _VH_GetRecommendationContext(RegisteredScripts)
	local candidates = {}
	local selected = {}
	local selectedPlaces = {}
	local otherCandidates = {}
	local now = os.time()

	for _, entry in ipairs(RegisteredScripts) do
		if generation ~= RecommendationGeneration then return {}, nil end
		local data = entry and entry.Data or nil
		if type(data) == "table" then
			local placeId = tonumber(data.PlaceId) or 0
			local samePlace = PlaceId ~= 0 and placeId ~= 0 and placeId == PlaceId
			local score = 0
			local reasonType = "FALLBACK"
			local tokens = _VH_GetRecommendationTokenSet(data)
			local topics = _VH_GetRecommendationTopicSet(data)
			local overlapCount = _VH_CountTokenOverlap(tokens, currentSet)
			local favoriteOverlap = _VH_CountTokenOverlap(tokens, favoriteSet)
			local topicOverlap = _VH_CountTopicOverlap(topics, currentTopics)
			local favoriteTopicOverlap = _VH_CountTopicOverlap(topics, favoriteTopics)
			local category = type(data.Category) == "string" and string.lower(string.gsub(data.Category, "^%s*(.-)%s*$", "%1")) or ""
			local categoryMatch = category ~= "" and currentCategories[category] == true
			local isRecent = false
			local tagType = NormalizeTagType(data.TagType)

			if samePlace then
				score = 1000
				reasonType = "CURRENT"
			else
				if topicOverlap > 0 then
					score = score + math.min(topicOverlap * 32, 96)
					reasonType = "TOPIC"
				end
				if categoryMatch then score = score + 28; reasonType = reasonType == "FALLBACK" and "CATEGORY" or reasonType end
				if overlapCount > 0 then score = score + math.min(overlapCount * 5, 35) end
				local favoriteBoost = 0
				if favoriteTopicOverlap > 0 then favoriteBoost = favoriteBoost + math.min(favoriteTopicOverlap * 2, 6); if reasonType == "FALLBACK" then reasonType = "FAVORITE_TOPIC" end end
				if favoriteOverlap > 0 then favoriteBoost = favoriteBoost + math.min(favoriteOverlap, 6); if reasonType == "FALLBACK" then reasonType = "FAVORITE" end end
				score = score + math.min(favoriteBoost, FavoriteRecommendationMaxBoost)
				local tags = _VH_NormalizeRecommendationList(data.Tags)
				local matchingTags = 0
				for _, tag in ipairs(tags) do
					if currentTags[tag] then matchingTags = matchingTags + 1 end
				end
				if matchingTags > 0 then score = score + math.min(matchingTags * 12, 24) end
				local age = now - GetSafeTimestamp(data.LastUpdated)
				if age >= 0 and age <= 7 * 86400 then score = score + 12; isRecent = true
				elseif age > 7 * 86400 and age <= 30 * 86400 then score = score + 5; isRecent = true end
				if tagType == "HOT" then score = score + 10
				elseif tagType == "FEATURED" then score = score + 9
				elseif tagType == "UPDATED" then score = score + 7
				elseif tagType == "NEW" then score = score + 6 end
				if placeId ~= 0 then score = score + 2 end
				if score <= 0 then score = 1 end
			end
			local reason = _VH_GetRecommendationReason(reasonType, overlapCount, favoriteOverlap, topicOverlap, favoriteTopicOverlap, isRecent, tagType)
			if reason == "Recently updated" then
				reason = GetRelativeTime(data.LastUpdated)
			end
			entry.RecommendationScore = score
			entry.RecommendationReason = reason
			entry.RecommendationType = samePlace and "CURRENT" or "OTHER"
			entry.Recommended = samePlace
			if not samePlace then
				otherCandidates[#otherCandidates + 1] = {
					Entry = entry,
					Score = score,
					PlaceId = placeId,
					Reason = reason,
					TopicOverlap = topicOverlap,
					FavoriteTopicOverlap = favoriteTopicOverlap,
					LastUpdated = GetSafeTimestamp(data.LastUpdated),
				}
			end
		end
	end

	table.sort(otherCandidates, function(a, b)
		if a.Score ~= b.Score then return a.Score > b.Score end
		if a.TopicOverlap ~= b.TopicOverlap then return a.TopicOverlap > b.TopicOverlap end
		if a.LastUpdated ~= b.LastUpdated then return a.LastUpdated > b.LastUpdated end
		return a.Entry.SearchTitle < b.Entry.SearchTitle
	end)

	for _, candidate in ipairs(otherCandidates) do
		if #selected < 6 and (candidate.PlaceId == 0 or not selectedPlaces[candidate.PlaceId]) then
			if candidate.PlaceId ~= 0 then selectedPlaces[candidate.PlaceId] = true end
			selected[#selected + 1] = candidate
		end
		if #selected >= 6 then break end
	end

	for index, candidate in ipairs(selected) do
		if candidate and candidate.Entry then
			candidate.Entry.RecommendationRank = index
			candidate.Entry.RecommendationScore = candidate.Score
			candidate.Entry.RecommendationReason = candidate.Reason
			candidate.Entry.RecommendationType = "SMART"
			candidate.Entry.Recommended = true
			candidates[#candidates + 1] = candidate
		end
	end

	return candidates, currentCount
end

function _VH_GetRecommendationShortReason(reason)
	local text = tostring(reason or "")
	if text == "Similar to your current game" then return "Similar game" end
	if text == "Matches your current game" then return "Current game" end
	if text == "Related to your favorites" then return "From favorites" end
	if text == "Similar to your favorites" then return "Similar favorites" end
	if text == "Shares similar game details" then return "Similar" end
	if text == "Featured in Velox Hub" then return "Featured" end
	if text == "More games in Velox Hub" then return "Explore" end
	if text == "No other recommendations found yet" then return "No matches" end
	if text == "Now" then return "Now" end
	if string.match(text, "^%d+[mhdw] ago$") or string.match(text, "^%d+mo ago$") or string.match(text, "^%d+y ago$") then return text end
	return "Explore"
end
function _VH_RefreshRecommendationPanel(items, currentCount)
	if not RecommendationPanel or not RecommendationPanel.Parent or not RecommendationList then return end

	local allItems = {}
	for _, item in ipairs(items or {}) do
		if item and item.Entry and item.Entry.Instance and item.Entry.Instance.Parent then
			allItems[#allItems + 1] = item
		end
	end

	local pageSize = math.max(1, tonumber(RecommendationPageSize) or 3)
	RecommendationPageCount = math.max(1, math.ceil(#allItems / pageSize))
	RecommendationPage = math.clamp(tonumber(RecommendationPage) or 1, 1, RecommendationPageCount)
	local previewStart = ((RecommendationPage - 1) * pageSize) + 1
	local previewEnd = math.min(previewStart + pageSize - 1, #allItems)
	local previewParts = { tostring(RecommendationPage), tostring(RecommendationPageCount), tostring(currentCount or 0), tostring(math.floor(RecommendationList.AbsoluteSize.X)) }
	for index = previewStart, previewEnd do
		local item = allItems[index]
		if item then
			previewParts[#previewParts + 1] = tostring(item.Entry and (item.Entry.Id or item.Entry.EntryFingerprint or item.Entry.Name) or "")
			previewParts[#previewParts + 1] = tostring(item.Reason or "")
		end
	end
	local previewSignature = table.concat(previewParts, "\31")
	if RecommendationRenderSignature == previewSignature then
		local visible = #allItems > 0 and currentTab == "Scripts" and string.gsub(SearchInput.Text or "", "%s", "") == "" and not FilterFavoritesActive
		RecommendationPanel.Visible = visible
		RecommendationPrevButton.Visible = RecommendationPageCount > 1 and #allItems > 0
		RecommendationNextButton.Visible = RecommendationPageCount > 1 and #allItems > 0
		RecommendationSeeMoreButton.Visible = RecommendationPageCount > 1 and #allItems > 0
		RecommendationPageLabel.Visible = RecommendationPageCount > 1 and #allItems > 0
		RecommendationPageLabel.Text = RecommendationPageCount > 1 and (tostring(RecommendationPage) .. " / " .. tostring(RecommendationPageCount)) or ""
		if currentCount and currentCount > 0 then
			RecommendationSubtitle.Text = "Based on your current game"
		elseif #allItems > 0 then
			RecommendationSubtitle.Text = "Discover other games in Velox Hub"
		else
			RecommendationSubtitle.Text = "No other recommendations found yet"
		end
		return
	end

	for _, connection in ipairs(RecommendationConnections) do
		if typeof(connection) == "RBXScriptConnection" and connection.Connected then
			pcall(function() connection:Disconnect() end)
		end
	end
	table.clear(RecommendationConnections)

	for _, child in ipairs(RecommendationList:GetChildren()) do
		if child:IsA("GuiButton") or child:IsA("TextLabel") or child:IsA("Frame") or child:IsA("ImageLabel") then
			child:Destroy()
		end
	end
	table.clear(RecommendationItems)

	local startIndex = ((RecommendationPage - 1) * pageSize) + 1
	local endIndex = math.min(startIndex + pageSize - 1, #allItems)
	local visibleCount = math.max(0, endIndex - startIndex + 1)
	local visibleIndex = 0

	local gap = IsMobile and 7 or 8
	local totalGaps = math.max(0, visibleCount - 1) * gap
	local cardHeight = IsMobile and 64 or 72
	local cardWidthScale = visibleCount > 0 and (1 / visibleCount) or 1
	local cardWidthOffset = visibleCount > 0 and -(totalGaps / visibleCount) or 0

	for index = startIndex, endIndex do
		local item = allItems[index]
		local entry = item.Entry
		if entry and entry.Instance and entry.Instance.Parent then
			visibleIndex = visibleIndex + 1
			RecommendationItems[visibleIndex] = entry

			local button = Instance.new("TextButton", RecommendationList)
			button.Size = UDim2.new(cardWidthScale, cardWidthOffset, 0, cardHeight)
			button.BackgroundColor3 = Color3.fromRGB(18, 27, 46)
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			button.Text = ""
			button.LayoutOrder = visibleIndex
			button.ClipsDescendants = true
			button.ZIndex = 6
			Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
			local buttonStroke = Instance.new("UIStroke", button)
			buttonStroke.Color = Color3.fromRGB(57, 70, 104)
			buttonStroke.Transparency = 0.1
			buttonStroke.Thickness = 1

			local imageSize = IsMobile and 42 or 50
			local image = Instance.new("ImageLabel", button)
			image.Size = UDim2.new(0, imageSize, 0, imageSize)
			image.Position = UDim2.new(0, 7, 0.5, -(imageSize / 2))
			image.BackgroundColor3 = Color3.fromRGB(27, 37, 59)
			image.BorderSizePixel = 0
			image.Image = type(entry.Data) == "table" and tostring(entry.Data.ImageAssetId or "") or ""
			image.ScaleType = Enum.ScaleType.Crop
			image.ZIndex = 7
			Instance.new("UICorner", image).CornerRadius = UDim.new(0, 7)
			local imageStroke = Instance.new("UIStroke", image)
			imageStroke.Color = Color3.fromRGB(72, 86, 121)
			imageStroke.Transparency = 0.2
			imageStroke.Thickness = 1

			local textX = imageSize + 15
			local nameLabel = Instance.new("TextLabel", button)
			nameLabel.Size = UDim2.new(1, -textX - 7, 0, IsMobile and 25 or 28)
			nameLabel.Position = UDim2.new(0, textX, 0, 7)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = tostring(entry.ExactName or entry.Name or "Unknown Game")
			nameLabel.TextColor3 = Theme.TextPrimary
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = IsMobile and 8 or 10
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			nameLabel.TextWrapped = true
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextYAlignment = Enum.TextYAlignment.Top
			nameLabel.ZIndex = 7

			local reasonChip = Instance.new("Frame", button)
			reasonChip.Size = UDim2.new(1, -textX - 8, 0, IsMobile and 17 or 19)
			reasonChip.Position = UDim2.new(0, textX, 1, -(IsMobile and 22 or 24))
			reasonChip.BackgroundColor3 = Color3.fromRGB(27, 37, 62)
			reasonChip.BorderSizePixel = 0
			reasonChip.ZIndex = 7
			Instance.new("UICorner", reasonChip).CornerRadius = UDim.new(0, 5)
			local reasonStroke = Instance.new("UIStroke", reasonChip)
			reasonStroke.Color = Color3.fromRGB(72, 84, 124)
			reasonStroke.Transparency = 0.2
			reasonStroke.Thickness = 1

			local reasonDot = Instance.new("Frame", reasonChip)
			reasonDot.Size = UDim2.new(0, 5, 0, 5)
			reasonDot.Position = UDim2.new(0, 6, 0.5, -2.5)
			local reasonTextValue = tostring(item.Reason or "")
			local reasonDotColor = Color3.fromRGB(129, 140, 248)
			if reasonTextValue == "Related to your favorites" or reasonTextValue == "Similar to your favorites" then
				reasonDotColor = Color3.fromRGB(250, 204, 21)
			elseif reasonTextValue == "Now" or string.match(reasonTextValue, "^%d+[mhdw] ago$") or string.match(reasonTextValue, "^%d+mo ago$") or string.match(reasonTextValue, "^%d+y ago$") then
				reasonDotColor = Color3.fromRGB(52, 211, 153)
			elseif reasonTextValue == "Featured in Velox Hub" then
				reasonDotColor = Color3.fromRGB(168, 85, 247)
			end
			reasonDot.BackgroundColor3 = reasonDotColor
			reasonDot.BorderSizePixel = 0
			reasonDot.ZIndex = 8
			Instance.new("UICorner", reasonDot).CornerRadius = UDim.new(1, 0)

			local reasonLabel = Instance.new("TextLabel", reasonChip)
			reasonLabel.Size = UDim2.new(1, -18, 1, 0)
			reasonLabel.Position = UDim2.new(0, 15, 0, 0)
			reasonLabel.BackgroundTransparency = 1
			reasonLabel.Text = _VH_GetRecommendationShortReason(item.Reason)
			reasonLabel.TextColor3 = Color3.fromRGB(215, 223, 236)
			reasonLabel.Font = Enum.Font.GothamMedium
			reasonLabel.TextSize = IsMobile and 7 or 8
			reasonLabel.TextTruncate = Enum.TextTruncate.AtEnd
			reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
			reasonLabel.ZIndex = 8

			RecommendationConnections[#RecommendationConnections + 1] = button.Activated:Connect(function()
				if isDestroying or not entry.Instance or not entry.Instance.Parent then return end
				local offset = entry.Instance.AbsolutePosition.Y - ScriptsView.AbsolutePosition.Y + ScriptsView.CanvasPosition.Y - 10
				ScriptsView.CanvasPosition = Vector2.new(0, math.max(0, offset))
			end)
		end
	end

	local hasMultiplePages = RecommendationPageCount > 1
	RecommendationPrevButton.Visible = hasMultiplePages and #RecommendationItems > 0
	RecommendationNextButton.Visible = hasMultiplePages and #RecommendationItems > 0
	RecommendationSeeMoreButton.Visible = hasMultiplePages and #RecommendationItems > 0
	RecommendationPageLabel.Visible = hasMultiplePages and #RecommendationItems > 0
	RecommendationPageLabel.Text = hasMultiplePages and (tostring(RecommendationPage) .. " / " .. tostring(RecommendationPageCount)) or ""

	local visible = #RecommendationItems > 0 and currentTab == "Scripts" and string.gsub(SearchInput.Text or "", "%s", "") == "" and not FilterFavoritesActive
	RecommendationPanel.Visible = visible
	if currentCount and currentCount > 0 then
		RecommendationSubtitle.Text = "Based on your current game"
	elseif #RecommendationItems > 0 then
		RecommendationSubtitle.Text = "Discover other games in Velox Hub"
	else
		RecommendationSubtitle.Text = "No other recommendations found yet"
	end

	RecommendationRenderSignature = previewSignature

	local function GoToRecommendationPage(nextPage)
		if RecommendationPageCount <= 1 then return end
		RecommendationPage = math.clamp(nextPage, 1, RecommendationPageCount)
		_VH_RefreshRecommendationPanel(allItems, currentCount)
	end
	RecommendationConnections[#RecommendationConnections + 1] = RecommendationPrevButton.Activated:Connect(function()
		if RecommendationPageCount <= 1 then return end
		local target = RecommendationPage - 1
		if target < 1 then target = RecommendationPageCount end
		GoToRecommendationPage(target)
	end)
	RecommendationConnections[#RecommendationConnections + 1] = RecommendationNextButton.Activated:Connect(function()
		if RecommendationPageCount <= 1 then return end
		local target = RecommendationPage + 1
		if target > RecommendationPageCount then target = 1 end
		GoToRecommendationPage(target)
	end)
	RecommendationConnections[#RecommendationConnections + 1] = RecommendationSeeMoreButton.Activated:Connect(function()
		if RecommendationPageCount <= 1 then return end
		local target = RecommendationPage + 1
		if target > RecommendationPageCount then target = 1 end
		GoToRecommendationPage(target)
	end)
end

function _VH_RefreshRecommendations()
	RecommendationRenderSignature = ""
	local items, currentCount = _VH_BuildRecommendationState()
	for _, entry in ipairs(RegisteredScripts) do
		if type(entry.SetRecommendation) == "function" then
			entry.SetRecommendation(entry.Recommended == true, entry.RecommendationReason or "", entry.RecommendationType or "OTHER", entry.RecommendationScore or 0)
		end
	end
	_VH_RefreshRecommendationPanel(items, currentCount)
end
function _VH_NormalizeAutoExecuteName(value)
	if type(value) ~= "string" then return "" end
	return string.lower(string.gsub(value, "^%s*(.-)%s*$", "%1"))
end
function _VH_GetSavedAutoExecute(scriptData)
	if type(scriptData) ~= "table" then return nil, false end
	local scriptId = tostring(scriptData.Id or "")
	local direct = scriptId ~= "" and SavedData.AutoExecutes[scriptId] or nil
	if type(direct) == "table" then
		return direct, false
	end
	local stableId = StableScriptId(scriptData)
	if type(stableId) == "string" and SavedData.AutoExecutes[stableId] then
		local entry = SavedData.AutoExecutes[stableId]
		if scriptId ~= "" and stableId ~= scriptId then
			SavedData.AutoExecutes[scriptId] = entry
			SavedData.AutoExecutes[stableId] = nil
			entry.Name = entry.Name or scriptData.ExactName or scriptData.Name
			return entry, true
		end
		return entry, false
	end
	local targetName = _VH_NormalizeAutoExecuteName(scriptData.ExactName or scriptData.Name)
	if targetName == "" then return nil, false end
	for key, entry in pairs(SavedData.AutoExecutes) do
		if type(entry) == "table" then
			local savedName = _VH_NormalizeAutoExecuteName(entry.Name)
			local keyName = _VH_NormalizeAutoExecuteName(key)
			if (savedName ~= "" and savedName == targetName) or keyName == targetName then
				if scriptId ~= "" then
					SavedData.AutoExecutes[scriptId] = entry
					SavedData.AutoExecutes[key] = nil
					entry.Name = scriptData.ExactName or scriptData.Name
				end
				return entry, true
			end
		end
	end
	return nil, false
end
function _VH_AutoExecuteGameMatches(entry)
	if type(entry) ~= "table" then return false end
	local savedGame = tonumber(entry.GameId)
	local savedPlace = tonumber(entry.PlaceId)
	if savedGame and savedGame ~= 0 and savedGame == GameId then return true end
	if savedPlace and savedPlace ~= 0 and savedPlace == PlaceId then return true end
	return false
end
function IsCalendarDay(timestamp)
	local value = tonumber(timestamp)
	if not value or value <= 0 then return false end
	local nowDate = os.date("*t", os.time())
	local valueDate = os.date("*t", value)
	return nowDate.year == valueDate.year and nowDate.month == valueDate.month and nowDate.day == valueDate.day
end
function IsCalendarWeek(timestamp)
	local value = tonumber(timestamp)
	if not value or value <= 0 then return false end
	local now = os.time()
	local nowDate = os.date("*t", now)
	local currentDay = nowDate.wday == 1 and 7 or nowDate.wday - 1
	local start = os.time({year = nowDate.year, month = nowDate.month, day = nowDate.day, hour = 0, min = 0, sec = 0}) - ((currentDay - 1) * 86400)
	return value >= start and value <= now
end
function IsCalendarMonth(timestamp)
	local value = tonumber(timestamp)
	if not value or value <= 0 then return false end
	local nowDate = os.date("*t", os.time())
	local valueDate = os.date("*t", value)
	return nowDate.year == valueDate.year and nowDate.month == valueDate.month and value <= os.time()
end
function _VH_ScheduleFavoriteRecommendationRefresh()
	FavoriteRecommendationRefreshGeneration = FavoriteRecommendationRefreshGeneration + 1
	local generation = FavoriteRecommendationRefreshGeneration
	task.delay(FavoriteRecommendationRefreshDelay, function()
		if isDestroying or generation ~= FavoriteRecommendationRefreshGeneration then return end
		SaveConfiguration()
		_VH_RefreshRecommendations()
		RefreshAllCardStates()
		UpdateFilter()
	end)
end
function MigrateSavedEntries(entries)
	for _, data in ipairs(entries) do
		id = data.Id
		name = data.Name
		if id and name and id ~= name then
			if SavedData.Favorites[id] == nil and SavedData.Favorites[name] ~= nil then
				SavedData.Favorites[id] = SavedData.Favorites[name]
				SavedData.Favorites[name] = nil
			end
			if SavedData.AutoExecutes[id] == nil and SavedData.AutoExecutes[name] ~= nil then
				SavedData.AutoExecutes[id] = SavedData.AutoExecutes[name]
				SavedData.AutoExecutes[name] = nil
			end
		end
	end
end
function RefreshAllCardStates()
	for _, scrData in ipairs(RegisteredScripts) do
		if type(scrData.UpdateUI) == "function" then scrData.UpdateUI() end
		if scrData.TimeLabel and scrData.TimeLabel.Parent then
			scrData.TimeLabel.Text = FormatLastUpdatedLabel(scrData.LastUpdatedNumber)
		end
	end
end
function ExecuteSandboxed(code, scriptName)
	if type(CompileFunction) ~= "function" then
		ShowNotification("Execution unavailable: this executor does not provide loadstring/load.", "Error")
		return false, "no compatible Lua compiler"
	end
	if type(code) ~= "string" or code == "" then
		ShowNotification("Execution unavailable: empty script source.", "Error")
		return false, "empty script source"
	end

	local ok, chunk, compileErr = pcall(CompileFunction, code, "=" .. tostring(scriptName))
	if ok and type(chunk) == "function" then
		_VH_TrackTask(function()
			local success, runtimeErr = pcall(chunk)
			if not success and not isDestroying then
				ShowNotification("Execution Error in [" .. tostring(scriptName) .. "]: Check F9 Console.", "Error")
			end
		end)
		return true, "Script dispatched successfully"
	end

	local detail = tostring(compileErr or chunk or "unknown compiler error")
	local normalized = string.lower(detail)
	if string.find(normalized, "out of local", 1, true)
		or string.find(normalized, "registers", 1, true)
		or (string.find(normalized, "register", 1, true) and string.find(normalized, "limit", 1, true)) then
		ShowNotification("Compile Error in [" .. tostring(scriptName) .. "]: executor compiler local-register limit was exceeded.", "Error")
		return false, detail
	end

	ShowNotification("Compile Error in [" .. tostring(scriptName) .. "]: " .. detail, "Error")
	return false, detail
end
function CreateScriptCard(data, renderParent, registerImmediately, originalIndex)
	local tagType = NormalizeTagType(data and data.TagType)
	local tagConfig = TagTypeConfig[tagType]
	local exactName = type(data.Name) == "string" and data.Name or "Unnamed Script"
	local isRecommended = IsRecommendedForCurrentPlace(data)
	local recommendationReason = isRecommended and "Matches your current game" or ""
	local recommendationType = isRecommended and "CURRENT" or "OTHER"
	local recommendationScore = isRecommended and 1000 or 0
	local scriptId = StableScriptId(data) or ("name:" .. string.lower(exactName))
	local safeImageAssetId = type(data.ImageAssetId) == "string" and data.ImageAssetId or "rbxassetid://99657752206675"
	local entryConnections = {}
	local function RegEntryConn(connection)
		if connection and typeof(connection) == "RBXScriptConnection" then entryConnections[#entryConnections + 1] = connection end
		return connection
	end
	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0, 0); card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = tagConfig.CardColor; card.Text = ""
	card.AutoButtonColor = false; card.ClipsDescendants = true
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local cardStroke = GetOrCreateCardStroke(card)
	ApplyTagBorder(card, tagType, cardStroke)
	if isRecommended then
		card.BackgroundColor3 = Color3.fromRGB(31, 42, 55)
	end
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
	local metaWidth = IsMobile and 212 or 250
	local titleContainer = Instance.new("Frame", topRow)
	titleContainer.Size = UDim2.new(1, -metaWidth, 0, 0); titleContainer.AutomaticSize = Enum.AutomaticSize.Y
	titleContainer.BackgroundTransparency = 1; titleContainer.LayoutOrder = 1
	local titleContainerLay = Instance.new("UIListLayout", titleContainer)
	titleContainerLay.FillDirection = Enum.FillDirection.Vertical
	titleContainerLay.HorizontalAlignment = Enum.HorizontalAlignment.Left
	titleContainerLay.VerticalAlignment = Enum.VerticalAlignment.Top
	titleContainerLay.SortOrder = Enum.SortOrder.LayoutOrder
	titleContainerLay.Padding = UDim.new(0, 5)

	local titleLine = Instance.new("Frame", titleContainer)
	titleLine.Size = UDim2.new(1, 0, 0, 0); titleLine.AutomaticSize = Enum.AutomaticSize.Y
	titleLine.BackgroundTransparency = 1; titleLine.LayoutOrder = 1
	local titleLineLay = Instance.new("UIListLayout", titleLine)
	titleLineLay.FillDirection = Enum.FillDirection.Horizontal
	titleLineLay.HorizontalAlignment = Enum.HorizontalAlignment.Left
	titleLineLay.VerticalAlignment = Enum.VerticalAlignment.Top
	titleLineLay.SortOrder = Enum.SortOrder.LayoutOrder
	titleLineLay.Padding = UDim.new(0, 6)

	local titleLbl = Instance.new("TextLabel", titleLine)
	titleLbl.Size = UDim2.new(1, 0, 0, 0); titleLbl.AutomaticSize = Enum.AutomaticSize.Y
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = data.Name or "Unnamed Script"
	titleLbl.TextColor3 = Theme.TextPrimary; titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = IsMobile and 12 or 13; titleLbl.TextWrapped = true; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.LayoutOrder = 1; titleLbl.ZIndex = 3

	local recommendBadge = Instance.new("Frame", titleContainer)
	recommendBadge.Size = UDim2.new(0, IsMobile and 88 or 96, 0, 20)
	recommendBadge.BackgroundColor3 = Color3.fromRGB(79, 70, 229)
	recommendBadge.Visible = isRecommended
	recommendBadge.LayoutOrder = 2
	recommendBadge.ZIndex = 4
	Instance.new("UICorner", recommendBadge).CornerRadius = UDim.new(0, 7)
	local recommendStroke = Instance.new("UIStroke", recommendBadge)
	recommendStroke.Color = Color3.fromRGB(165, 180, 252)
	recommendStroke.Transparency = 0.05
	recommendStroke.Thickness = 1
	local recommendGradient = Instance.new("UIGradient", recommendBadge)
	recommendGradient.Rotation = 0
	recommendGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(129, 140, 248)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 70, 229))
	})
	local recommendText = Instance.new("TextLabel", recommendBadge)
	recommendText.Size = UDim2.new(1, 0, 1, 0)
	recommendText.BackgroundTransparency = 1
	recommendText.Text = recommendationType == "SMART" and "YOU MAY LIKE" or "FOR YOU"
	recommendText.TextColor3 = Color3.fromRGB(255, 255, 255)
	recommendText.Font = Enum.Font.GothamBold
	recommendText.TextSize = IsMobile and 8 or 9
	recommendText.TextXAlignment = Enum.TextXAlignment.Center
	recommendText.ZIndex = 5

	local badgeRow = Instance.new("Frame", titleContainer)
	badgeRow.Size = UDim2.new(1, 0, 0, 20)
	badgeRow.BackgroundTransparency = 1
	badgeRow.LayoutOrder = 2
	badgeRow.Visible = isRecommended or tagType ~= "NONE"
	local badgeLay = Instance.new("UIListLayout", badgeRow)
	badgeLay.FillDirection = Enum.FillDirection.Horizontal
	badgeLay.HorizontalAlignment = Enum.HorizontalAlignment.Left
	badgeLay.VerticalAlignment = Enum.VerticalAlignment.Center
	badgeLay.SortOrder = Enum.SortOrder.LayoutOrder
	badgeLay.Padding = UDim.new(0, 5)
	recommendBadge.Parent = badgeRow
	recommendBadge.LayoutOrder = 1

	if tagType ~= "NONE" then
		tag = Instance.new("Frame", badgeRow)
		tag.AutomaticSize = Enum.AutomaticSize.X; tag.Size = UDim2.new(0, 0, 0, 20)
		Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 6)
		tPad = Instance.new("UIPadding", tag)
		tPad.PaddingLeft = UDim.new(0, 7); tPad.PaddingRight = UDim.new(0, 7)
		tText = Instance.new("TextLabel", tag)
		tText.AutomaticSize = Enum.AutomaticSize.X; tText.Size = UDim2.new(0, 0, 1, 0)
		tText.BackgroundTransparency = 1; tText.Text = tagType
		tText.TextColor3 = Color3.fromRGB(255, 255, 255); tText.Font = Enum.Font.GothamBold; tText.TextSize = IsMobile and 8 or 9
		tag.BackgroundColor3 = tagConfig.BadgeColor
		tag.LayoutOrder = 2
		tag.ZIndex = 4
	end

	local metaRightContainer = Instance.new("Frame", topRow)
	metaRightContainer.Size = UDim2.new(0, metaWidth, 0, 18); metaRightContainer.BackgroundTransparency = 1; metaRightContainer.LayoutOrder = 2
	local mrLay = Instance.new("UIListLayout", metaRightContainer)
	mrLay.FillDirection = Enum.FillDirection.Horizontal; mrLay.HorizontalAlignment = Enum.HorizontalAlignment.Right; mrLay.VerticalAlignment = Enum.VerticalAlignment.Center; mrLay.SortOrder = Enum.SortOrder.LayoutOrder; mrLay.Padding = UDim.new(0, 3)
	local dateLbl = Instance.new("TextLabel", metaRightContainer)
	dateLbl.Size = UDim2.new(0, IsMobile and 130 or 150, 1, 0)
	dateLbl.BackgroundTransparency = 1; dateLbl.Text = FormatLastUpdatedLabel(data.LastUpdated)
	dateLbl.TextColor3 = Theme.TextSecondary; dateLbl.Font = Enum.Font.GothamMedium
	dateLbl.TextSize = 9; dateLbl.LayoutOrder = 1; dateLbl.TextXAlignment = Enum.TextXAlignment.Right
	dateLbl.TextWrapped = false; dateLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local function UpdateCardMetaLayout()
		local available = topRow.AbsoluteSize.X
		if available <= 0 then return end
		local target = metaWidth
		if available < 440 then target = math.min(target, math.max(145, math.floor(available * 0.46))) end
		if tagType == "NONE" then target = math.max(125, target - 34) end
		titleContainer.Size = UDim2.new(1, -target, 0, 0)
		metaRightContainer.Size = UDim2.new(0, target, 0, 18)

		titleLine.Size = UDim2.new(1, 0, 0, 0)
		titleLbl.Size = UDim2.new(1, 0, 0, 0)
		recommendBadge.Visible = isRecommended
		badgeRow.Visible = isRecommended or tagType ~= "NONE"
	end
	RegEntryConn(topRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCardMetaLayout))
	UpdateCardMetaLayout()
	local descLbl = Instance.new("TextLabel", content)
	descLbl.Size = UDim2.new(1, 0, 0, 0); descLbl.AutomaticSize = Enum.AutomaticSize.Y
	descLbl.BackgroundTransparency = 1; descLbl.Text = type(data.Description) == "string" and data.Description or "No description provided."
	descLbl.TextColor3 = Theme.TextSecondary; descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 11
	descLbl.TextWrapped = true; descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.LayoutOrder = 2
	local btmRow = Instance.new("Frame", content)
	btmRow.Size = UDim2.new(1, 0, 0, 22); btmRow.BackgroundTransparency = 1; btmRow.LayoutOrder = 3
	local brLay = Instance.new("UIListLayout", btmRow)
	brLay.FillDirection = Enum.FillDirection.Horizontal; brLay.SortOrder = Enum.SortOrder.LayoutOrder; brLay.Padding = UDim.new(0, IsMobile and 6 or 8); brLay.VerticalAlignment = Enum.VerticalAlignment.Center
	local autoExecBtn = Instance.new("TextButton", btmRow)
	autoExecBtn.Size = UDim2.new(0, IsMobile and 108 or 120, 0, 22); autoExecBtn.BackgroundColor3 = Theme.BackgroundMain
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
	local detailsBtn = Instance.new("TextButton", btmRow)
	detailsBtn.Size = UDim2.new(0, IsMobile and 84 or 94, 0, 22)
	detailsBtn.BackgroundColor3 = Theme.BackgroundMain
	detailsBtn.Text = "View Details"
	detailsBtn.TextColor3 = Theme.TextPrimary
	detailsBtn.Font = Enum.Font.GothamBold
	detailsBtn.TextSize = IsMobile and 9 or 10
	detailsBtn.AutoButtonColor = false
	detailsBtn.LayoutOrder = 2
	detailsBtn.ZIndex = 2
	Instance.new("UICorner", detailsBtn).CornerRadius = UDim.new(0, 6)
	local detailsBtnStroke = Instance.new("UIStroke", detailsBtn)
	detailsBtnStroke.Color = Theme.Stroke
	detailsBtnStroke.Transparency = 0.45
	detailsBtnStroke.Thickness = 0.75
	local starBtn = Instance.new("TextButton", btmRow)
	starBtn.Size = UDim2.new(0, 22, 0, 22); starBtn.BackgroundTransparency = 1
	starBtn.Font = Enum.Font.GothamBold; starBtn.TextSize = 15; starBtn.LayoutOrder = 3; starBtn.ZIndex = 2
	ApplyInteractiveAnimations(card, tagConfig.CardColor, tagConfig.HoverColor, Color3.fromRGB(20, 29, 45), nil, nil, nil, entryConnections)
	ApplyInteractiveAnimations(autoExecBtn, Theme.BackgroundMain, Theme.BackgroundSecondary, Color3.fromRGB(10, 15, 30), nil, nil, nil, entryConnections)
	ApplyInteractiveAnimations(detailsBtn, Theme.BackgroundMain, Theme.BackgroundSecondary, Theme.Card, detailsBtnStroke, detailsBtnStroke.Color, Theme.Accent, entryConnections)
	ApplyInteractiveAnimations(starBtn, nil, nil, nil, nil, nil, nil, entryConnections)
	local description = type(data.Description) == "string" and data.Description or ""
	local tagSearch = tagType
	local scriptEntry = {
		Instance = card, SearchTitle = string.lower(exactName), SearchDesc = string.lower(description),
		SearchMeta = string.lower(table.concat({type(data.Category) == "string" and data.Category or "", type(data.Author) == "string" and data.Author or "", tagSearch, type(data.Tags) == "table" and table.concat(data.Tags, " ") or type(data.Tags) == "string" and data.Tags or "", IsScriptCompatible(data) and "compatible" or "game-only", isRecommended and "recommended for you" or "you may like"}, " ")),
		Data = data,
		Id = scriptId, ExactName = exactName, PlaceId = tonumber(data.PlaceId) or 0, Compatible = IsScriptCompatible(data), Recommended = isRecommended, RecommendationReason = recommendationReason, RecommendationType = recommendationType, RecommendationScore = recommendationScore, RecommendationRank = 999, LastUpdated = data.LastUpdated, LastUpdatedNumber = GetSafeTimestamp(data.LastUpdated), TagType = tagType, TagPriority = tagConfig.Priority, OriginalIndex = originalIndex or (#RegisteredScripts + 1), EntryFingerprint = table.concat({ tostring(data.Id or StableScriptId(data) or ""), tostring(data.Name or ""), tostring(data.Description or ""), tostring(data.RawUrl or ""), tostring(data.ImageAssetId or ""), tostring(NormalizeTagType(data.TagType)), tostring(GetSafeTimestamp(data.LastUpdated)), tostring(tonumber(data.PlaceId) or 0), tostring(data.Category or ""), tostring(data.Author or ""), _VH_RecommendationListFingerprint(data.Tags) }, "\31"), TimeLabel = dateLbl
	}
	scriptEntry.DisconnectConnections = function()
		for i = #entryConnections, 1, -1 do
			local connection = entryConnections[i]
			if typeof(connection) == "RBXScriptConnection" and connection.Connected then pcall(function() connection:Disconnect() end) end
			entryConnections[i] = nil
		end
	end
	local innerActionTime = 0
	scriptEntry.UpdateUI = function()
		local isFav = SavedData.Favorites[scriptId]
		local compatible = IsScriptCompatible(data)
		local isON = compatible and SavedData.AutoExecutes[scriptId] ~= nil
		ApplyTagBorder(card, tagType, cardStroke)
		card.BackgroundColor3 = isRecommended and Color3.fromRGB(31, 42, 55) or tagConfig.CardColor
		cardStroke.Thickness = isRecommended and 1.5 or 1
		if isRecommended then cardStroke.Color = Color3.fromRGB(129, 140, 248) end
		recommendBadge.Visible = isRecommended
		recommendText.Text = recommendationType == "SMART" and "YOU MAY LIKE" or "FOR YOU"
		badgeRow.Visible = isRecommended or tagType ~= "NONE"
		scriptEntry.SearchMeta = string.lower(table.concat({type(data.Category) == "string" and data.Category or "", type(data.Author) == "string" and data.Author or "", tagType, type(data.Tags) == "table" and table.concat(data.Tags, " ") or type(data.Tags) == "string" and data.Tags or "", compatible and "compatible" or "game-only", isRecommended and (recommendationType == "SMART" and "you may like" or "recommended for you") or ""}, " "))
		starBtn.Text = isFav and "★" or "☆"; starBtn.TextColor3 = isFav and Color3.fromRGB(250, 204, 21) or Theme.TextSecondary
		aeLbl.Text = compatible and "Auto Execute" or "Wrong Game"
		aeStateTxt.Text = compatible and (isON and "ON" or "OFF") or "X"
		aeState.BackgroundColor3 = compatible and (isON and Theme.Success or Theme.Error) or Theme.Warning
	end
	scriptEntry.SetRecommendation = function(enabled, reason, kind, score)
		isRecommended = enabled == true
		recommendationReason = tostring(reason or "")
		recommendationType = tostring(kind or "OTHER")
		recommendationScore = tonumber(score) or 0
		scriptEntry.Recommended = isRecommended
		scriptEntry.RecommendationReason = recommendationReason
		scriptEntry.RecommendationType = recommendationType
		scriptEntry.RecommendationScore = recommendationScore
		if type(scriptEntry.UpdateUI) == "function" then scriptEntry.UpdateUI() end
	end
	scriptEntry.UpdateUI()
	local detailsBtnScale = Instance.new("UIScale", detailsBtn)
	detailsBtnScale.Scale = 1
	RegEntryConn(detailsBtn.Activated:Connect(_VH_CreateDebounce(0.1, function()
		if isDestroying then return end
		innerActionTime = tick()
		_VH_SafeTween(detailsBtnScale, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.95})
		task.delay(0.07, function()
			if detailsBtnScale and detailsBtnScale.Parent and not isDestroying then
				_VH_SafeTween(detailsBtnScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
			end
		end)
		_VH_OpenScriptDetails(data, scriptEntry)
	end)))
	RegEntryConn(starBtn.Activated:Connect(_VH_CreateDebounce(0.1, function()
		if isDestroying then return end
		innerActionTime = tick()
		if SavedData.Favorites[scriptId] then
			SavedData.Favorites[scriptId] = nil; ShowNotification("Removed '" .. exactName .. "' from favorites.", "Warning")
		else
			SavedData.Favorites[scriptId] = true; ShowNotification("Added '" .. exactName .. "' to favorites!", "Success")
		end
		_VH_ScheduleFavoriteRecommendationRefresh()
	end)))
	RegEntryConn(autoExecBtn.Activated:Connect(_VH_CreateDebounce(0.1, function()
		if isDestroying then return end
		innerActionTime = tick()
		if not IsScriptCompatible(data) then
			ShowNotification("This script is only compatible with its configured Roblox experience.", "Warning")
			return
		end
		local previousEntry = SavedData.AutoExecutes[scriptId]
		if previousEntry then
			SavedData.AutoExecutes[scriptId] = nil
		else
			SavedData.AutoExecutes[scriptId] = {
				PlaceId = PlaceId,
				GameId = GameId,
				Name = exactName
			}
		end
		local saveOk, saveError = SaveConfiguration()
		if not saveOk then
			SavedData.AutoExecutes[scriptId] = previousEntry
			ShowNotification("Auto-execute setting could not be saved: " .. tostring(saveError), "Error")
		else
			ShowNotification(previousEntry and "Disabled auto-execute for '" .. exactName .. "'." or "Enabled auto-execute for '" .. exactName .. "'.", previousEntry and "Warning" or "Success")
		end
		RefreshAllCardStates()
		UpdateFilter()
	end)))
	RegEntryConn(card.Activated:Connect(function()
		if isDestroying then return end
		if tick() - innerActionTime < 0.2 then return end
		local function executeScript()
			if not IsScriptCompatible(data) then
				ShowNotification("This script is not compatible with this game.", "Warning")
				return
			end
			if type(CompileFunction) ~= "function" then
				ShowNotification("Execution disabled: this executor does not provide loadstring/load.", "Error")
				return
			end
			titleLbl.Text = "Running script..."; titleLbl.TextColor3 = Theme.Accent
			task.spawn(function()
				local raw, status = FetchWithRetry(type(data.RawUrl) == "string" and data.RawUrl or "", 2)
				if isDestroying then return end
				if not raw then
					ShowNotification("Failed to download script" .. (status and " (HTTP " .. tostring(status) .. ")" or "") .. ".", "Error")
				elseif #string.gsub(raw, "%s+", "") == 0 then
					ShowNotification("The script returned an empty response.", "Error")
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
		if SavedData.AutoExecutes[scriptId] ~= nil then
			AttemptActionWithCooldown(executeScript)
		else
			OpenConfirmDialog(exactName, executeScript)
		end
	end))
	card.Parent = renderParent

	_VH_CacheInstanceAndDescendants(card)
	if registerImmediately ~= false then table.insert(RegisteredScripts, scriptEntry) end
	return scriptEntry
end
CATALOG_URL = "https://raw.githubusercontent.com/KingBacconnnn/VeloxScripts/refs/heads/main/catalog.json"
CATALOG_REFRESH_INTERVAL = 300
dbRefreshing = false
CatalogRefreshQueued = false
LastCatalogFingerprint = nil
function BuildCatalogFingerprint(entries)
	local parts = {}
	for index, entry in ipairs(entries) do
		if type(entry) == "table" then
			parts[#parts + 1] = table.concat({
				tostring(entry.Id or StableScriptId(entry) or ""), tostring(entry.Name or ""), tostring(entry.Description or ""), tostring(entry.RawUrl or ""),
				tostring(entry.ImageAssetId or ""), tostring(NormalizeTagType(entry.TagType)),
				tostring(GetSafeTimestamp(entry.LastUpdated)), tostring(tonumber(entry.PlaceId) or 0),
				tostring(entry.Category or ""), tostring(entry.Author or ""), _VH_RecommendationListFingerprint(entry.Tags), tostring(index)
			}, "\31")
		end
	end
	return table.concat(parts, "\30")
end
function ClearCatalogCardsForRefresh()

	filterVersion = filterVersion + 1
	for _, entry in ipairs(RegisteredScripts) do
		if entry and entry.Instance and entry.Instance.Parent then
			entry.Instance.Visible = false
		end
	end
	EmptyStateMessage.Visible = false
	EmptyStateMessage.Text = ""
	if RecommendationPanel then RecommendationPanel.Visible = false end
	ScriptsView.CanvasPosition = Vector2.new(0, 0)
end
function RestoreCatalogCardsAfterRefreshFailure()
	for _, entry in ipairs(RegisteredScripts) do
		if entry and entry.Instance and entry.Instance.Parent then
			entry.Instance.Visible = true
		end
	end
	UpdateFilter()
end
PendingTasks.__LoadCatalog = function(force, isAutoRefresh)
	if isDestroying then return false end
	if dbRefreshing then
		CatalogRefreshQueued = true
		PendingTasks.__CatalogRefreshForce = PendingTasks.__CatalogRefreshForce or force == true
		PendingTasks.__CatalogRefreshAuto = PendingTasks.__CatalogRefreshAuto or isAutoRefresh == true
		return false
	end
	local now = os.clock()
	if not force and now - LastCatalogRefreshAt < 5 then
		CatalogRefreshQueued = true
		return false
	end
	LastCatalogRefreshAt = now
	dbRefreshing = true
	CatalogGeneration += 1
	local generation = CatalogGeneration
	local savedScroll = ScriptsView.CanvasPosition
	if force == true then
		ClearCatalogCardsForRefresh()
	end
	ShowNotification("Fetching latest script catalog...", "System")
	StatusDot.BackgroundColor3 = Theme.Warning
	StatusText.Text = "Connecting..."
	StatusText.TextColor3 = Theme.Warning
	local function FinishRefresh()
		if generation ~= CatalogGeneration then return end
		dbRefreshing = false

		if not isAutoRefresh then
			LastCatalogRefreshAt = os.clock()
		end
		if CatalogRefreshQueued and not isDestroying then
			local queuedForce = PendingTasks.__CatalogRefreshForce == true
			local queuedAuto = PendingTasks.__CatalogRefreshAuto == true
			CatalogRefreshQueued = false
			PendingTasks.__CatalogRefreshForce = false
			PendingTasks.__CatalogRefreshAuto = false
			task.defer(function()
				if not isDestroying then PendingTasks.__LoadCatalog(queuedForce, queuedAuto) end
			end)
		end
	end
	activeBuildFolder = nil
	activeNewEntries = {}
	_VH_TrackTask(function()
		taskOk, taskErr = xpcall(function()
			raw, catalogStatus = FetchWithRetry(CATALOG_URL, 3, true)
			if not _VH_IsTaskCurrent(generation) then return end
			if not raw then
				RestoreCatalogCardsAfterRefreshFailure()
				if #RegisteredScripts == 0 then EmptyStateMessage.Visible = true; EmptyStateMessage.Text = "Unable to reach script catalog server." end
				StatusDot.BackgroundColor3 = Theme.Error
				StatusText.Text = catalogStatus and ("HTTP " .. tostring(catalogStatus)) or "Offline"
				StatusText.TextColor3 = Theme.Error
				ShowNotification("Could not connect to the script catalog server.", "Error")
				FinishRefresh()
				return
			end
			success, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
			if not success or type(parsed) ~= "table" then
				RestoreCatalogCardsAfterRefreshFailure()
				if #RegisteredScripts == 0 then EmptyStateMessage.Visible = true; EmptyStateMessage.Text = "Failed to parse catalog data format." end
				StatusDot.BackgroundColor3 = Theme.Error
				StatusText.Text = "Data Error"
				StatusText.TextColor3 = Theme.Error
				ShowNotification("Catalog data format error.", "Error")
				FinishRefresh()
				return
			end
			catalogVersion = 0
			catalogEntries = parsed
			if type(parsed.Scripts) == "table" then
				catalogEntries = parsed.Scripts
				catalogVersion = tonumber(parsed.CatalogVersion) or 0
			end
			validEntries = {}
			seenIds = {}
			validationIssueCount = 0
			for index, entry in ipairs(catalogEntries) do
				if type(entry) ~= "table" then
					validationIssueCount = validationIssueCount + 1
				else
					name = type(entry.Name) == "string" and string.gsub(entry.Name, "^%s*(.-)%s*$", "%1") or ""
					rawUrl = type(entry.RawUrl) == "string" and string.gsub(entry.RawUrl, "^%s*(.-)%s*$", "%1") or ""
					id = StableScriptId(entry)
					placeId = tonumber(entry.PlaceId) or 0
					validUrl = rawUrl:match("^https?://") ~= nil
					if name == "" then validationIssueCount = validationIssueCount + 1 end
					if rawUrl == "" or not validUrl then validationIssueCount = validationIssueCount + 1 end
					if type(id) ~= "string" or id == "" then validationIssueCount = validationIssueCount + 1 end
					if tonumber(entry.PlaceId) == nil and entry.PlaceId ~= nil then validationIssueCount = validationIssueCount + 1 end
					if id and not seenIds[id] and name ~= "" and validUrl then
						seenIds[id] = true
						validEntries[#validEntries + 1] = {
							Id = id,
							Name = name,
							Description = type(entry.Description) == "string" and entry.Description or "No description provided.",
							RawUrl = rawUrl,
							ImageAssetId = type(entry.ImageAssetId) == "string" and entry.ImageAssetId or "rbxassetid://99657752206675",
							TagType = NormalizeTagType(entry.TagType),
							LastUpdated = GetSafeTimestamp(entry.LastUpdated),
							PlaceId = placeId,
							Category = type(entry.Category) == "string" and entry.Category or "",
							Author = type(entry.Author) == "string" and entry.Author or "",
							Tags = _VH_NormalizeRecommendationList(entry.Tags),
							Source = rawUrl:match("^https?://([^/]+)") or ""
						}
					elseif id and seenIds[id] then
						validationIssueCount = validationIssueCount + 1
					end
				end
			end
			MigrateSavedEntries(validEntries)
			if validationIssueCount > 0 and #validEntries == 0 then
				ShowNotification("Catalog validation failed: no usable scripts were found.", "Error")
			end
			fingerprint = BuildCatalogFingerprint(validEntries) .. "\30" .. tostring(catalogVersion)
			if fingerprint == LastCatalogFingerprint and force ~= true then
				for _, existingEntry in ipairs(RegisteredScripts) do
					if existingEntry and existingEntry.Instance and existingEntry.Instance.Parent then existingEntry.Instance.Visible = true end
				end
				_VH_RefreshRecommendations()
				RefreshAllCardStates()
				StatusDot.BackgroundColor3 = Theme.Success
				StatusText.Text = "Online"
				StatusText.TextColor3 = Theme.Success
				if not isAutoRefresh then
					ShowNotification("Catalog is already up to date.", "Info")
				end
				FinishRefresh()
				return
			end
			previousByKey = RegisteredScripts.__ByKey or {}
			nextByKey = {}
			nextEntries = {}
			nextKeys = {}
			replacedEntries = {}
			table.clear(activeNewEntries)
			activeBuildFolder = Instance.new("Folder")
			activeBuildFolder.Name = "__VeloxCatalogBuild"
			activeBuildFolder.Parent = ScriptsView
			local function BuildEntryFingerprint(data)
				return table.concat({ tostring(data.Id or StableScriptId(data) or ""), tostring(data.Name or ""), tostring(data.Description or ""), tostring(data.RawUrl or ""), tostring(data.ImageAssetId or ""), tostring(NormalizeTagType(data.TagType)), tostring(GetSafeTimestamp(data.LastUpdated)), tostring(tonumber(data.PlaceId) or 0), tostring(data.Category or ""), tostring(data.Author or ""), _VH_RecommendationListFingerprint(data.Tags) }, "\31")
			end
			local function DestroyEntry(entry)
				if not entry or not entry.Instance then return end
				if entry.DisconnectConnections then pcall(entry.DisconnectConnections) end
				if entry.Instance.Parent then pcall(function() entry.Instance:Destroy() end) end
			end
			local function CleanupNewEntries()
				for _, entry in ipairs(activeNewEntries) do DestroyEntry(entry) end
				if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
				activeBuildFolder = nil
				table.clear(activeNewEntries)
				RestoreCatalogCardsAfterRefreshFailure()
			end
			for index, scriptData in ipairs(validEntries) do
				if not _VH_IsTaskCurrent(generation) then CleanupNewEntries(); FinishRefresh(); return end
				key = tostring(scriptData.Id or StableScriptId(scriptData) or scriptData.Name or "")
				entryFingerprint = BuildEntryFingerprint(scriptData)
				existing = previousByKey[key]
				entry = nil
				if existing and existing.EntryFingerprint == entryFingerprint and existing.Instance and existing.Instance.Parent then
					entry = existing
					entry.OriginalIndex = index
				else
					if existing then replacedEntries[#replacedEntries + 1] = existing end
					entry = CreateScriptCard(scriptData, activeBuildFolder, false, index)
					if entry and entry.Instance then
						entry.Instance.Visible = false
					end
					entry.EntryFingerprint = entryFingerprint
					entry.OriginalIndex = index
					activeNewEntries[#activeNewEntries + 1] = entry
				end
				nextEntries[#nextEntries + 1] = entry
				nextByKey[key] = entry
				nextKeys[key] = true
			end
			if not _VH_IsTaskCurrent(generation) then CleanupNewEntries(); FinishRefresh(); return end
			for key, oldEntry in pairs(previousByKey) do
				if not nextKeys[key] then DestroyEntry(oldEntry) end
			end
			for _, entry in ipairs(replacedEntries) do DestroyEntry(entry) end
			for _, entry in ipairs(nextEntries) do
				if entry.Instance and entry.Instance.Parent ~= ScriptsView then entry.Instance.Parent = ScriptsView end
				entry.Instance.LayoutOrder = entry.OriginalIndex
				entry.Instance.Visible = true
			end
			if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
			activeBuildFolder = nil
			table.clear(activeNewEntries)
			table.clear(RegisteredScripts)
			for _, entry in ipairs(nextEntries) do RegisteredScripts[#RegisteredScripts + 1] = entry end
			RegisteredScripts.__ByKey = nextByKey
			LastCatalogFingerprint = fingerprint
			_VH_RefreshRecommendations()
			RefreshAllCardStates()
			UpdateFilter()
			task.defer(function()
				if _VH_IsTaskCurrent(generation) and ScriptsView and ScriptsView.Parent then ScriptsView.CanvasPosition = savedScroll end
			end)
			if not AutoExecuteRanThisSession then
				AutoExecuteRanThisSession = true
				autoQueue = {}
				autoConfigMigrated = false
				if ConfigurationLoaded then
					for _, scriptData in ipairs(validEntries) do
						auto, migrated = _VH_GetSavedAutoExecute(scriptData)
						if migrated then autoConfigMigrated = true end
						if type(auto) == "table" and _VH_AutoExecuteGameMatches(auto) and IsScriptCompatible(scriptData) then
							autoQueue[#autoQueue + 1] = scriptData
						end
					end
					if autoConfigMigrated then
						local migrationSaved = SaveConfiguration()
						if not migrationSaved then
							ShowNotification("Auto-execute migration could not be persisted; the current session can still use the saved entry.", "Warning")
						end
					end
				end
				if #autoQueue > 0 then
					_VH_TrackTask(function()
						if type(CompileFunction) ~= "function" then ShowNotification("Auto-execute skipped: executor lacks loadstring/load support.", "Error"); return end
						successList, failList = {}, {}
						ShowNotification("Processing " .. #autoQueue .. " auto-execute script(s)...", "Info")
						for _, scriptData in ipairs(autoQueue) do
							if not _VH_IsTaskCurrent(generation) then return end
							scrRaw, scrStatus = FetchWithRetry(scriptData.RawUrl, 2)
							if not _VH_IsTaskCurrent(generation) then return end
							if scrRaw and #string.gsub(scrRaw, "%s+", "") > 0 then
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
			if isAutoRefresh then
				ShowNotification("Catalog updated.", "Success")
			else
				ShowNotification("Script catalog loaded successfully!", "Success")
			end
		end, function(err) return tostring(err) end)
		if not taskOk then
			if activeBuildFolder and activeBuildFolder.Parent then activeBuildFolder:Destroy() end
			activeBuildFolder = nil
			table.clear(activeNewEntries)
			RestoreCatalogCardsAfterRefreshFailure()
		end
		if not taskOk and not isDestroying and generation == CatalogGeneration then
			StatusDot.BackgroundColor3 = Theme.Error
			StatusText.Text = "Catalog Error"
			StatusText.TextColor3 = Theme.Error
			ShowNotification("Catalog refresh failed safely.", "Error")
		end
		FinishRefresh()
	end)
	return true
end

PendingTasks.__LoadCatalog()

_VH_TrackTask(function()
	while not isDestroying do
		remaining = CATALOG_REFRESH_INTERVAL - (os.clock() - LastCatalogRefreshAt)
		if remaining > 0 then
			task.wait(math.min(remaining, 1))
		else
			if not dbRefreshing then
				PendingTasks.__LoadCatalog(false, true)
			else

				task.wait(1)
			end
		end
	end
end)
_VH_TrackTask(function()
	while not isDestroying do
		task.wait(60)
		if isDestroying then break end
		for _, scrData in ipairs(RegisteredScripts) do
			if scrData.TimeLabel and scrData.TimeLabel.Parent then
				scrData.TimeLabel.Text = FormatLastUpdatedLabel(scrData.LastUpdatedNumber)
			end
		end
	end
end)
function CreateSettingsGroup(titleText, parentView, order)
	container = Instance.new("Frame", parentView)
	container.Size = UDim2.new(1, 0, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	groupLayout = Instance.new("UIListLayout", container)
	groupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	groupLayout.Padding = UDim.new(0, 6)
	header = Instance.new("TextLabel", container)
	header.Size = UDim2.new(1, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.Text = string.upper(titleText)
	header.TextColor3 = Theme.TextSecondary
	header.Font = Enum.Font.GothamBold
	header.TextSize = 10
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = 1
	card = Instance.new("Frame", container)
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.CardHover
	card.LayoutOrder = 2
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	cardGradient = Instance.new("UIGradient", card)
	cardGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.CardHover),
		ColorSequenceKeypoint.new(1, Theme.Card)
	})
	cardGradient.Rotation = 45
	cardLayout = Instance.new("UIListLayout", card)
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 0)
	return card
end
function CreateSettingRowInGroup(groupCard, title, desc, iconAsset, order)
	if order > 1 then
		divider = Instance.new("Frame", groupCard)
		divider.Size = UDim2.new(1, -24, 0, 1)
		divider.Position = UDim2.new(0, 12, 0, 0)
		divider.BackgroundColor3 = Theme.Stroke
		divider.BackgroundTransparency = 0.6
		divider.BorderSizePixel = 0
		divider.LayoutOrder = (order - 1) * 2
	end
	row = Instance.new("Frame", groupCard)
	row.Size = UDim2.new(1, 0, 0, IsMobile and 56 or 60)
	row.BackgroundTransparency = 1
	row.LayoutOrder = (order * 2) - 1
	rowPad = Instance.new("UIPadding", row)
	rowPad.PaddingLeft = UDim.new(0, 12)
	rowPad.PaddingRight = UDim.new(0, 12)
	rowPad.PaddingTop = UDim.new(0, 8)
	rowPad.PaddingBottom = UDim.new(0, 8)
	iconContainer = Instance.new("Frame", row)
	iconContainer.Size = UDim2.new(0, 32, 0, 32)
	iconContainer.Position = UDim2.new(0, 0, 0.5, -16)
	iconContainer.BackgroundColor3 = Theme.Accent
	iconContainer.BackgroundTransparency = 0.85
	Instance.new("UICorner", iconContainer).CornerRadius = UDim.new(0, 8)
	iconImg = Instance.new("ImageLabel", iconContainer)
	iconImg.Size = UDim2.new(0, 18, 0, 18)
	iconImg.Position = UDim2.new(0.5, -9, 0.5, -9)
	iconImg.BackgroundTransparency = 1
	iconImg.Image = iconAsset or "rbxassetid://10709782497"
	iconImg.ImageColor3 = Theme.Accent
	textContainer = Instance.new("Frame", row)
	textContainer.Size = UDim2.new(1, -165, 1, 0)
	textContainer.Position = UDim2.new(0, 42, 0, 0)
	textContainer.BackgroundTransparency = 1
	tLay = Instance.new("UIListLayout", textContainer)
	tLay.SortOrder = Enum.SortOrder.LayoutOrder
	tLay.Padding = UDim.new(0, 2)
	tLay.VerticalAlignment = Enum.VerticalAlignment.Center
	t = Instance.new("TextLabel", textContainer)
	t.Size = UDim2.new(1, 0, 0, 16)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = Theme.TextPrimary
	t.Font = Enum.Font.GothamBold
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.LayoutOrder = 1
	d = Instance.new("TextLabel", textContainer)
	d.Size = UDim2.new(1, 0, 0, 14)
	d.BackgroundTransparency = 1
	d.Text = desc
	d.TextColor3 = Theme.TextSecondary
	d.Font = Enum.Font.Gotham
	d.TextSize = 10
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.LayoutOrder = 2
	d.TextWrapped = true
	rightContainer = Instance.new("Frame", row)
	rightContainer.Size = UDim2.new(0, 110, 1, 0)
	rightContainer.Position = UDim2.new(1, -110, 0, 0)
	rightContainer.BackgroundTransparency = 1
	return row, rightContainer
end
function CreateToggleSettingInGroup(groupCard, title, desc, iconAsset, order, defaultValue, callback)
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
	_VH_RegConn(toggleBtn.Activated:Connect(_VH_CreateDebounce(0.1, function()
		if isDestroying then return end
		state = not state
		_VH_SafeTween(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = state and Theme.Accent or Theme.BackgroundMain
		})
		_VH_SafeTween(toggleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = state and Theme.Accent or Theme.Stroke
		})
		_VH_SafeTween(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		})
		if type(callback) == "function" then task.spawn(callback, state) end
	end)))
end
function CreateButtonSettingInGroup(groupCard, title, desc, iconAsset, btnText, order, isDestructive, callback)
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
	_VH_RegConn(btn.Activated:Connect(_VH_CreateDebounce(0.1, function()
		if isDestroying then return end
		if type(callback) == "function" then task.spawn(callback, btn) end
	end)))
	return btn
end
function AnimateRefreshButton(button, state)
	if not button or not button.Parent then return end
	scaleObj = button:FindFirstChild("VeloxRefreshScale")
	if not scaleObj then
		scaleObj = Instance.new("UIScale")
		scaleObj.Name = "VeloxRefreshScale"
		scaleObj.Scale = 1
		scaleObj.Parent = button
	end
	if state == true or state == "refreshing" then
		button.Text = "Refreshing"
		_VH_SafeTween(scaleObj, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.96})
		_VH_SafeTween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1})
	elseif state == "success" then
		button.Text = "Refresh"
		_VH_SafeTween(scaleObj, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
		_VH_SafeTween(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.4})
	elseif state == "error" then
		button.Text = "Retry"
		_VH_SafeTween(scaleObj, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
		_VH_SafeTween(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.25})
	else
		button.Text = "Refresh"
		_VH_SafeTween(scaleObj, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
		_VH_SafeTween(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.4})
	end
end
function BuildSettings()
prefGroup = CreateSettingsGroup("User Preferences", SettingsView, 1)
_, kbRightContainer = CreateSettingRowInGroup(prefGroup, "Toggle UI", "Keybind to show or hide hub.", "rbxassetid://10709790537", 1)
KeybindButton = Instance.new("TextButton", kbRightContainer)
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
kbBtnStroke = Instance.new("UIStroke", KeybindButton)
kbBtnStroke.Color = Theme.Stroke
KeybindButtonRef = KeybindButton
ApplyInteractiveAnimations(KeybindButton, Theme.BackgroundMain, Theme.CardHover, Color3.fromRGB(10, 15, 30), kbBtnStroke, Theme.Stroke, Theme.Accent)
_VH_RegConn(KeybindButton.Activated:Connect(_VH_CreateDebounce(0.1, function()
	if isDestroying or IsBindingKey then return end
	IsBindingKey = true
	KeybindButton.Text = "Press Any..."
	ShowNotification("Press any key to bind (Press Escape to cancel).", "System")
	if KeybindCaptureConnection then
		_VH_UnregConn(KeybindCaptureConnection)
		KeybindCaptureConnection = nil
	end
	KeybindCaptureConnection = _VH_RegConn(UserInputService.InputBegan:Connect(function(input)
		if isDestroying then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				IsBindingKey = false
				if KeybindButtonRef then KeybindButtonRef.Text = ToggleKeybind.Name end
				ShowNotification("Keybind mapping canceled.", "Warning")
				if KeybindCaptureConnection then
					_VH_UnregConn(KeybindCaptureConnection)
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
					_VH_UnregConn(KeybindCaptureConnection)
					KeybindCaptureConnection = nil
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			IsBindingKey = false
			if KeybindButtonRef then KeybindButtonRef.Text = ToggleKeybind.Name end
			ShowNotification("Keybind mapping canceled.", "Warning")
			if KeybindCaptureConnection then
				_VH_UnregConn(KeybindCaptureConnection)
				KeybindCaptureConnection = nil
			end
		end
	end))
end)))
function ApplyAntiAFK()
	if AntiAFKConnection and AntiAFKConnection.Connected then return end
	player = Players.LocalPlayer
	GC = getconnections or get_signal_cons
	if type(GC) == "function" then
		table.clear(AntiAFKDisabledConnections)
		ok, connections = pcall(function() return GC(player.Idled) end)
		if ok and type(connections) == "table" then
			for _, connection in pairs(connections) do
				if connection.Disable then
					disabled = pcall(function() connection:Disable() end)
					if disabled then AntiAFKDisabledConnections[#AntiAFKDisabledConnections + 1] = connection end
				end
			end
		end
	end
	if type(GC) ~= "function" or #AntiAFKDisabledConnections == 0 then
		AntiAFKConnection = player.Idled:Connect(function()
			if isDestroying then return end
			pcall(function()
				virtualUser = Services.VirtualUser
				if virtualUser then
					virtualUser:CaptureController()
					virtualUser:ClickButton2(Vector2.new())
				end
			end)
		end)
	end
end
DisableAntiAFK = function()
	if AntiAFKConnection then
		pcall(function() AntiAFKConnection:Disconnect() end)
		AntiAFKConnection = nil
	end
	for i = #AntiAFKDisabledConnections, 1, -1 do
		connection = AntiAFKDisabledConnections[i]
		if connection and connection.Enable then pcall(function() connection:Enable() end) end
		AntiAFKDisabledConnections[i] = nil
	end
end
CreateToggleSettingInGroup(prefGroup, "Anti-AFK", "Prevents idle kicks.", "rbxassetid://10734898592", 2, SavedData.Settings.AntiAFK, function(val)
	SavedData.Settings.AntiAFK = val
	SaveConfiguration()
	if val then
		ApplyAntiAFK()
		ShowNotification("Anti-AFK system engaged.", "Success")
	else
		DisableAntiAFK()
		ShowNotification("Anti-AFK deactivated.", "Warning")
	end
end)

scaleRow, scaleRight = CreateSettingRowInGroup(prefGroup, "UI Scale", "Adjust the hub size from 80% to 120%.", "rbxassetid://10734940376", 3)
scaleValue = math.clamp(tonumber(SavedData.Settings.UIScale) or 1, 0.8, 1.2)
scaleFrame = Instance.new("Frame", scaleRight)
scaleFrame.Size = UDim2.new(1, 0, 1, 0)
scaleFrame.BackgroundTransparency = 1
scaleMinus = Instance.new("TextButton", scaleFrame)
scaleMinus.Size = UDim2.new(0, 28, 0, 26)
scaleMinus.Position = UDim2.new(0, 0, 0.5, -13)
scaleMinus.BackgroundColor3 = Theme.BackgroundMain
scaleMinus.Text = "−"
scaleMinus.TextColor3 = Theme.TextPrimary
scaleMinus.Font = Enum.Font.GothamBold
scaleMinus.TextSize = 15
scaleMinus.AutoButtonColor = false
Instance.new("UICorner", scaleMinus).CornerRadius = UDim.new(0, 6)
scaleMinusStroke = Instance.new("UIStroke", scaleMinus)
scaleMinusStroke.Color = Theme.Stroke
scaleLabel = Instance.new("TextLabel", scaleFrame)
scaleLabel.Size = UDim2.new(0, 48, 0, 26)
scaleLabel.Position = UDim2.new(0.5, -24, 0.5, -13)
scaleLabel.BackgroundTransparency = 1
scaleLabel.TextColor3 = Theme.Accent
scaleLabel.Font = Enum.Font.GothamBold
scaleLabel.TextSize = 11
scaleLabel.TextXAlignment = Enum.TextXAlignment.Center
scalePlus = Instance.new("TextButton", scaleFrame)
scalePlus.Size = UDim2.new(0, 28, 0, 26)
scalePlus.Position = UDim2.new(1, -28, 0.5, -13)
scalePlus.BackgroundColor3 = Theme.BackgroundMain
scalePlus.Text = "+"
scalePlus.TextColor3 = Theme.TextPrimary
scalePlus.Font = Enum.Font.GothamBold
scalePlus.TextSize = 15
scalePlus.AutoButtonColor = false
Instance.new("UICorner", scalePlus).CornerRadius = UDim.new(0, 6)
scalePlusStroke = Instance.new("UIStroke", scalePlus)
scalePlusStroke.Color = Theme.Stroke
function RefreshScaleLabel()
	scaleLabel.Text = tostring(math.floor(scaleValue * 100 + 0.5)) .. "%"
end
function SetUIScaleFromSetting(nextValue, source)
	scaleValue = math.clamp(math.round((tonumber(nextValue) or 1) * 20) / 20, 0.8, 1.2)
	SavedData.Settings.UIScale = scaleValue
	RefreshScaleLabel()
	ApplyPanelUIScale(scaleValue)
	SaveConfiguration()
	ShowNotification("UI Scale set to " .. tostring(math.floor(scaleValue * 100 + 0.5)) .. "%.", "Success")
end
RefreshScaleLabel()
ApplyInteractiveAnimations(scaleMinus, Theme.BackgroundMain, Theme.CardHover, Color3.fromRGB(10, 15, 30), scaleMinusStroke, Theme.Stroke, Theme.Accent)
ApplyInteractiveAnimations(scalePlus, Theme.BackgroundMain, Theme.CardHover, Color3.fromRGB(10, 15, 30), scalePlusStroke, Theme.Stroke, Theme.Accent)
_VH_RegConn(scaleMinus.Activated:Connect(_VH_CreateDebounce(0.08, function() SetUIScaleFromSetting(scaleValue - 0.05) end)))
_VH_RegConn(scalePlus.Activated:Connect(_VH_CreateDebounce(0.08, function() SetUIScaleFromSetting(scaleValue + 0.05) end)))

actionGroup = CreateSettingsGroup("System Actions", SettingsView, 2)
CreateButtonSettingInGroup(actionGroup, "Refresh Catalog", "Fetches latest scripts.", "rbxassetid://10734976528", "Refresh", 1, false, function(btn)
	AttemptActionWithCooldown(function()
		if dbRefreshing then
			ShowNotification("Catalog is already refreshing.", "Info")
			return
		end
		AnimateRefreshButton(btn, true)
		ShowNotification("Refreshing script catalog...", "System")
		started = false
		ok = pcall(function()
			started = PendingTasks.__LoadCatalog(true) == true
		end)
		if not ok or (not started and not dbRefreshing) then
			if btn and btn.Parent and not isDestroying then
				AnimateRefreshButton(btn, "error")
				ShowNotification("Could not start catalog refresh.", "Error")
			end
			return
		end
		_VH_TrackTask(function()
			while not isDestroying and dbRefreshing do
				task.wait(0.1)
			end
			if btn and btn.Parent and not isDestroying then
				if StatusText.Text == "Online" then
					AnimateRefreshButton(btn, "success")
					ShowNotification("Successfully refreshed latest script.", "Success")
				else
					AnimateRefreshButton(btn, "error")
					ShowNotification("Catalog refresh failed.", "Error")
				end
			end
		end)
	end)
end)
CreateButtonSettingInGroup(actionGroup, "Unload Hub", "Removes Velox Hub completely.", "rbxassetid://10709753149", "Unload", 2, true, function()
	ShowNotification("Unloading Velox Hub...", "Info")
	task.wait(0.3)
	CloseUI()
end)
if SavedData.Settings.AntiAFK then
	ApplyAntiAFK()
end
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
	UserDataGroup = CreateSettingsGroup("User Data", SettingsView, 3)
	CreateButtonSettingInGroup(UserDataGroup, "Clear UI Cache", "Resets layout position.", "rbxassetid://10734940376", "Reset", 1, true, function()
		if isDestroying then return end
		table.clear(OriginalCache)
		MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
		FloatingBtn.Position = UDim2.new(0.5, 0, 0, 42.5)
		_VH_CacheInstanceAndDescendants(MainPanel)
		_VH_CacheInstanceAndDescendants(FloatingBtn)
		ShowNotification("UI Cache cleared successfully.", "Success")
	end)
end
end
BuildSettings()
