-- ====================================================== --
-- VELOX HUB: ASSET ID VERIFICATION TESTER
-- ====================================================== --

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Safely determine where to parent the UI (Supports both Executors and Studio)
local success, guiContainer = pcall(function() return CoreGui end)
if not success or not guiContainer then
    guiContainer = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Create ScreenGui
local testGui = Instance.new("ScreenGui")
testGui.Name = "AssetIdTester"
testGui.Parent = guiContainer

-- Create Main Background Frame
local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(0, 420, 0, 300)
frame.Position = UDim2.new(0.5, -210, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(15, 23, 42) -- Slate 900
frame.BorderSizePixel = 0
frame.ScrollBarThickness = 6
frame.Parent = testGui

-- Create Grid Layout
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 90, 0, 110)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = frame

-- Padding for the grid
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = frame

-- List of IDs to test
local iconList = {
    "10709782230", -- Expected: Refresh
    "10709782582", -- Expected: Power / Unload
    "10709782758", -- Expected: Trash / Clear
    "10709782136", -- Expected: Shield
    "10709782497", -- Expected: Settings / Sliders
    "10709782330", -- Expected: Search Glass
    "10709781820", -- Expected: Code / File
    "10709782630", -- Expected: Star
    "10709781488"  -- Expected: Bell
}

-- Generate an ImageLabel for each ID
for i, id in ipairs(iconList) do
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.LayoutOrder = i
    container.Parent = frame

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, 0, 0, 80)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://" .. id
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = container

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 20)
    txt.Position = UDim2.new(0, 0, 1, -20)
    txt.Text = id
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.Code
    txt.BackgroundTransparency = 1
    txt.TextScaled = true
    txt.Parent = container
end

-- Create a Close Button underneath
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 420, 0, 40)
closeBtn.Position = UDim2.new(0.5, -210, 0.5, 160)
closeBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241) -- Indigo 500
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "Close Tester"
closeBtn.BorderSizePixel = 0
closeBtn.Parent = testGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = closeBtn

-- Destroy GUI on click
closeBtn.MouseButton1Click:Connect(function()
    testGui:Destroy()
end)
