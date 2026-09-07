local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

--- Builds the entire UI from code (no Studio-authored GuiObjects) so the whole game is
-- reviewable/diffable as text. Mobile-first: everything uses Scale sizing/position and
-- TextScaled labels rather than fixed pixel offsets.
local UIController = {}

local function newFrame(props)
	local frame = Instance.new("Frame")
	for key, value in props do
		frame[key] = value
	end
	return frame
end

local function newCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	return corner
end

local function newButton(text, size, position, anchorPoint)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.BackgroundColor3 = Color3.fromRGB(60, 140, 220)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	newCorner(8).Parent = button
	return button
end

function UIController.init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainUI"
	screenGui.ResetOnSpawnGui = false
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Top bar: Coins
	local topBar = newFrame({
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0.07, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 30),
		BackgroundTransparency = 0.3,
		Parent = screenGui,
	})

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0.4, 0, 1, 0)
	coinsLabel.Position = UDim2.new(0.02, 0, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "Coins: 0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextScaled = true
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = topBar

	-- Toggle buttons (bottom right)
	local shopButton = newButton("Shop", UDim2.new(0.14, 0, 0.06, 0), UDim2.new(0.98, 0, 0.9, 0), Vector2.new(1, 1))
	shopButton.Parent = screenGui

	local tankButton = newButton("Tank", UDim2.new(0.14, 0, 0.06, 0), UDim2.new(0.98, 0.75, 0.9, 0), Vector2.new(1, 1))
	tankButton.Position = UDim2.new(0.98, 0, 0.82, 0)
	tankButton.Parent = screenGui

	-- Reel minigame bar (hidden by default)
	local reelFrame = newFrame({
		Name = "ReelFrame",
		Size = UDim2.new(0.5, 0, 0.08, 0),
		Position = UDim2.new(0.5, 0, 0.72, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 30),
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = screenGui,
	})
	newCorner(10).Parent = reelFrame

	local reelIndicator = newFrame({
		Name = "Indicator",
		Size = UDim2.new(0.04, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 220, 90),
		Parent = reelFrame,
	})
	newCorner(6).Parent = reelIndicator

	local tapButton = newButton("TAP TO REEL!", UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.5, 0, 0.86, 0), Vector2.new(0.5, 0.5))
	tapButton.Visible = false
	tapButton.BackgroundColor3 = Color3.fromRGB(230, 90, 70)
	tapButton.Parent = screenGui

	-- Catch notification (transient)
	local catchLabel = Instance.new("TextLabel")
	catchLabel.Name = "CatchNotification"
	catchLabel.Size = UDim2.new(0.6, 0, 0.06, 0)
	catchLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
	catchLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	catchLabel.BackgroundTransparency = 1
	catchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	catchLabel.Font = Enum.Font.GothamBold
	catchLabel.TextScaled = true
	catchLabel.TextTransparency = 1
	catchLabel.Text = ""
	catchLabel.Parent = screenGui

	-- Rare catch server-wide banner
	local rareBanner = Instance.new("TextLabel")
	rareBanner.Name = "RareBanner"
	rareBanner.Size = UDim2.new(0.7, 0, 0.06, 0)
	rareBanner.Position = UDim2.new(0.5, 0, -0.1, 0)
	rareBanner.AnchorPoint = Vector2.new(0.5, 0.5)
	rareBanner.BackgroundColor3 = Color3.fromRGB(250, 200, 60)
	rareBanner.BackgroundTransparency = 0.1
	rareBanner.TextColor3 = Color3.fromRGB(30, 20, 0)
	rareBanner.Font = Enum.Font.GothamBold
	rareBanner.TextScaled = true
	rareBanner.Text = ""
	rareBanner.Parent = screenGui
	newCorner(8).Parent = rareBanner

	-- Shop panel
	local shopFrame = newFrame({
		Name = "ShopFrame",
		Size = UDim2.new(0.5, 0, 0.7, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 40),
		Visible = false,
		Parent = screenGui,
	})
	newCorner(12).Parent = shopFrame

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(1, 0, 0.08, 0)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "Shop"
	shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextScaled = true
	shopTitle.Parent = shopFrame

	local shopCloseButton = newButton("X", UDim2.new(0.08, 0, 0.06, 0), UDim2.new(0.98, 0, 0.02, 0), Vector2.new(1, 0))
	shopCloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	shopCloseButton.Parent = shopFrame

	local shopList = Instance.new("ScrollingFrame")
	shopList.Name = "ShopList"
	shopList.Size = UDim2.new(0.96, 0, 0.88, 0)
	shopList.Position = UDim2.new(0.02, 0, 0.1, 0)
	shopList.BackgroundTransparency = 1
	shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopList.ScrollBarThickness = 6
	shopList.Parent = shopFrame

	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 6)
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Parent = shopList

	-- Tank / inventory panel
	local tankFrame = newFrame({
		Name = "TankFrame",
		Size = UDim2.new(0.5, 0, 0.7, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 40),
		Visible = false,
		Parent = screenGui,
	})
	newCorner(12).Parent = tankFrame

	local tankTitle = Instance.new("TextLabel")
	tankTitle.Size = UDim2.new(1, 0, 0.08, 0)
	tankTitle.BackgroundTransparency = 1
	tankTitle.Text = "Your Tank"
	tankTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	tankTitle.Font = Enum.Font.GothamBold
	tankTitle.TextScaled = true
	tankTitle.Parent = tankFrame

	local tankCloseButton = newButton("X", UDim2.new(0.08, 0, 0.06, 0), UDim2.new(0.98, 0, 0.02, 0), Vector2.new(1, 0))
	tankCloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	tankCloseButton.Parent = tankFrame

	local sellAllButton = newButton("Sell All", UDim2.new(0.3, 0, 0.06, 0), UDim2.new(0.5, 0, 0.02, 0), Vector2.new(0.5, 0))
	sellAllButton.BackgroundColor3 = Color3.fromRGB(90, 190, 110)
	sellAllButton.Parent = tankFrame

	local tankList = Instance.new("ScrollingFrame")
	tankList.Name = "TankList"
	tankList.Size = UDim2.new(0.96, 0, 0.78, 0)
	tankList.Position = UDim2.new(0.02, 0, 0.2, 0)
	tankList.BackgroundTransparency = 1
	tankList.CanvasSize = UDim2.new(0, 0, 0, 0)
	tankList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tankList.ScrollBarThickness = 6
	tankList.Parent = tankFrame

	local tankLayout = Instance.new("UIListLayout")
	tankLayout.Padding = UDim.new(0, 6)
	tankLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tankLayout.Parent = tankList

	-- Daily reward popup
	local dailyFrame = newFrame({
		Name = "DailyFrame",
		Size = UDim2.new(0.3, 0, 0.22, 0),
		Position = UDim2.new(0.5, 0, 0.4, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 40),
		Visible = false,
		Parent = screenGui,
	})
	newCorner(12).Parent = dailyFrame

	local dailyLabel = Instance.new("TextLabel")
	dailyLabel.Size = UDim2.new(1, 0, 0.6, 0)
	dailyLabel.Position = UDim2.new(0, 0, 0.05, 0)
	dailyLabel.BackgroundTransparency = 1
	dailyLabel.Text = "Daily Reward Ready!"
	dailyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	dailyLabel.Font = Enum.Font.GothamBold
	dailyLabel.TextScaled = true
	dailyLabel.Parent = dailyFrame

	local claimButton = newButton("Claim", UDim2.new(0.6, 0, 0.25, 0), UDim2.new(0.5, 0, 0.98, 0), Vector2.new(0.5, 1))
	claimButton.BackgroundColor3 = Color3.fromRGB(90, 190, 110)
	claimButton.Parent = dailyFrame

	shopButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
		tankFrame.Visible = false
	end)
	shopCloseButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = false
	end)
	tankButton.MouseButton1Click:Connect(function()
		tankFrame.Visible = not tankFrame.Visible
		shopFrame.Visible = false
	end)
	tankCloseButton.MouseButton1Click:Connect(function()
		tankFrame.Visible = false
	end)

	return {
		gui = screenGui,
		coinsLabel = coinsLabel,
		reelFrame = reelFrame,
		reelIndicator = reelIndicator,
		tapButton = tapButton,
		catchLabel = catchLabel,
		rareBanner = rareBanner,
		shopList = shopList,
		tankList = tankList,
		sellAllButton = sellAllButton,
		dailyFrame = dailyFrame,
		claimButton = claimButton,
	}
end

--- Shows a transient message that fades in, holds, then fades out.
function UIController.flashLabel(label, text, holdSeconds)
	label.Text = text
	label.TextTransparency = 0
	TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	task.delay(holdSeconds or 1.5, function()
		local tween = TweenService:Create(label, TweenInfo.new(0.6), { TextTransparency = 1 })
		tween:Play()
	end)
end

function UIController.slideInBanner(banner, text)
	banner.Text = text
	TweenService:Create(banner, TweenInfo.new(0.4), { Position = UDim2.new(0.5, 0, 0.08, 0) }):Play()
	task.delay(3, function()
		TweenService:Create(banner, TweenInfo.new(0.4), { Position = UDim2.new(0.5, 0, -0.1, 0) }):Play()
	end)
end

return UIController
