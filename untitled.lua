-- ====================================================== --
-- VELOX HUB: MEGA SCAN ASSET ID VERIFICATION TESTER (100)
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
frame.Size = UDim2.new(0, 450, 0, 400)
frame.Position = UDim2.new(0.5, -225, 0.5, -200)
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

-- Auto-resize scroll canvas to fit all 100 icons
grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    frame.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
end)

-- ====================================================== --
-- THE MEGA SCAN CATALOG (100 Asset IDs)
-- ====================================================== --
local iconList = {
    -- [1-9] Original Test Batch 
    "10709782230", "10709782582", "10709782758", "10709782136", "10709782497", 
    "10709782330", "10709781820", "10709782630", "10709781488",

    -- [10-20] Core Working UI Replacements
    "10747373176", "10723343301", "10709819149", "10734898592", "10709808945", 
    "10723354562", "10709810033", "10709819385", "10747372702", "10709780508", "10709822005",

    -- [21-30] Navigation & Directional Arrows
    "10709790948", "10709791523", "10709791281", "10709791437", "10709767827", 
    "10709768939", "7733720483", "10709768285", "10709768480", "10709768759",

    -- [31-40] Status, Alerts, Checks & Crosses
    "10709790644", "10709790387", "7733765224", "10709752996", "10709753149", 
    "10709790537", "10709825121", "10709792019", "10709792257", "10709805908",

    -- [41-50] General Tools & Hardware
    "10747373059", "10723341499", "7733701545", "10734977012", "10734976528", 
    "7733942651", "10709806459", "10709774214", "10709774959", "10709775336",

    -- [51-60] Documents, Folders & Files
    "10709776851", "10709777507", "10709778213", "10709778943", "10709779586", 
    "10709780231", "10709786650", "10709786835", "10709787053", "10709787262",

    -- [61-70] Media, Audio & Vision
    "10709795092", "10709795325", "10709795551", "10709795738", "10709803159", 
    "10709803444", "10709803657", "10709803870", "10709813233", "10709813476",

    -- [71-80] Locks, Keys & Security
    "10709799276", "10709799602", "10709799863", "10709800049", "10709814467", 
    "10709814725", "10709814986", "10709815234", "10709823027", "10709823293",

    -- [81-90] Shopping, Commerce & Graphs
    "10709788092", "10709788323", "10709788574", "10709788812", "10709812239", 
    "10709812499", "10709812759", "10709812999", "10709784381", "10709784651",

    -- [91-100] Extra Interface & Abstract Elements
    "10709783939", "10709784180", "10709796016", "10709796219", "10709796440", 
    "10709796696", "10709824058", "10709824317", "10709824558", "10709824818"
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
closeBtn.Size = UDim2.new(0, 450, 0, 40)
closeBtn.Position = UDim2.new(0.5, -225, 0.5, 210)
closeBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241) -- Indigo 500
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "Close Mega Tester"
closeBtn.BorderSizePixel = 0
closeBtn.Parent = testGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = closeBtn

-- Destroy GUI on click
closeBtn.MouseButton1Click:Connect(function()
    testGui:Destroy()
end)
