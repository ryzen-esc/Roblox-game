local Workspace = game:GetService("Workspace")

-- Matches a typical default Max Players setting so a full server never runs out of
-- plots; MapBuilderService.assignPlot warns (rather than erroring) if it ever does.
local PLOT_COUNT = 50
local PLOT_SPACING = 14
local PLOTS_PER_ROW = 10
local TANK_SIZE = Vector3.new(10, 7, 8)

--- Procedurally builds the entire minimal environment (baseplate, water, dock, spawn,
-- and a grid of per-player tank plots) from plain parts at server start. This means the
-- MVP needs zero manual building in Studio and zero uploaded assets -- sync with Rojo
-- and press Play.
local MapBuilderService = {}

local freePlots = {}
local plotByUserId = {}

local function buildBaseplate()
	local baseplate = Instance.new("Part")
	baseplate.Name = "Baseplate"
	baseplate.Size = Vector3.new(400, 4, 400)
	baseplate.Position = Vector3.new(0, -2, 0)
	baseplate.Anchored = true
	baseplate.Material = Enum.Material.Grass
	baseplate.Color = Color3.fromRGB(90, 150, 90)
	baseplate.Parent = Workspace
	return baseplate
end

local function buildDockAndWater()
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Size = Vector3.new(120, 2, 80)
	-- Top surface (Position.Y + Size.Y/2) must sit clearly below the dock's walking
	-- surface, or a player standing at the dock's edge ends up with the camera inside
	-- the water part, which triggers Roblox's underwater fog/tint even though the part
	-- is non-collidable. Top surface here: 0.4 studs, vs. the dock's 1 stud.
	water.Position = Vector3.new(0, -0.6, -70)
	water.Anchored = true
	water.CanCollide = false
	water.Material = Enum.Material.Water
	water.Color = Color3.fromRGB(40, 120, 180)
	water.Transparency = 0.15
	water.Parent = Workspace

	local dock = Instance.new("Part")
	dock.Name = "Dock"
	dock.Size = Vector3.new(30, 1, 16)
	dock.Position = Vector3.new(0, 0.5, -35)
	dock.Anchored = true
	dock.Material = Enum.Material.WoodPlanks
	dock.Color = Color3.fromRGB(120, 85, 55)
	dock.Parent = Workspace

	local castPrompt = Instance.new("Part")
	castPrompt.Name = "CastSpot"
	castPrompt.Size = Vector3.new(4, 1, 4)
	-- Must sit within the dock's footprint (Z from -43 to -27) and on top of its
	-- walking surface (dock top = 1, so this part's center = 1 + Size.Y/2 = 1.5) --
	-- previously this was placed past the dock's edge, out over the water.
	castPrompt.Position = Vector3.new(0, 1.5, -40)
	castPrompt.Anchored = true
	castPrompt.CanCollide = false
	castPrompt.Material = Enum.Material.Neon
	castPrompt.Color = Color3.fromRGB(255, 220, 90)
	castPrompt.Transparency = 0.3
	castPrompt.Parent = Workspace

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "CastPrompt"
	proximityPrompt.ActionText = "Cast Line"
	proximityPrompt.ObjectText = "Fishing Spot"
	proximityPrompt.HoldDuration = 0
	proximityPrompt.MaxActivationDistance = 12
	proximityPrompt.Parent = castPrompt

	return dock
end

local function buildSpawn()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, -20)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Color = Color3.fromRGB(140, 100, 65)
	spawn.Duration = 0
	spawn.Parent = Workspace
end

local function buildPlot(index: number)
	local row = math.floor((index - 1) / PLOTS_PER_ROW)
	local col = (index - 1) % PLOTS_PER_ROW

	local originX = (col - (PLOTS_PER_ROW - 1) / 2) * PLOT_SPACING
	local originZ = 40 + row * PLOT_SPACING

	local plot = Instance.new("Model")
	plot.Name = "TankPlot_" .. index

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(TANK_SIZE.X + 2, 1, TANK_SIZE.Z + 2)
	base.Position = Vector3.new(originX, 0.5, originZ)
	base.Anchored = true
	base.Material = Enum.Material.Slate
	base.Color = Color3.fromRGB(160, 160, 170)
	base.Parent = plot

	local tank = Instance.new("Part")
	tank.Name = "TankPart"
	tank.Size = TANK_SIZE
	tank.Position = base.Position + Vector3.new(0, TANK_SIZE.Y / 2 + 0.5, 0)
	tank.Anchored = true
	tank.CanCollide = false
	tank.CanQuery = false
	tank.Material = Enum.Material.Glass
	tank.Color = Color3.fromRGB(120, 200, 230)
	tank.Transparency = 0.75
	tank.Parent = plot

	local fishContainer = Instance.new("Folder")
	fishContainer.Name = "FishContainer"
	fishContainer.Parent = plot

	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(4, 1.5, 0.3)
	sign.Position = base.Position + Vector3.new(0, TANK_SIZE.Y + 1.2, -TANK_SIZE.Z / 2 - 1)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Material = Enum.Material.SmoothPlastic
	sign.Color = Color3.fromRGB(255, 255, 255)
	sign.Parent = plot

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.MaxDistance = 40 -- only render when a player is actually near this plot
	-- Not AlwaysOnTop: with 50 plots in a grid, an always-on-top label renders through
	-- everything regardless of distance/occlusion, so any view that catches more than a
	-- few plots turns into a wall of overlapping text. Disabled starts (Enabled = false)
	-- for the same reason -- an empty plot has nothing useful to announce, and with most
	-- plots unclaimed on a lightly populated server this alone removes most of the clutter.
	billboard.Enabled = false
	billboard.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Empty Tank"
	label.TextColor3 = Color3.fromRGB(30, 30, 30)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	plot.PrimaryPart = tank
	plot.Parent = Workspace

	return plot
end

function MapBuilderService.init()
	buildBaseplate()
	buildDockAndWater()
	buildSpawn()

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "TankPlots"
	plotsFolder.Parent = Workspace

	for i = 1, PLOT_COUNT do
		local plot = buildPlot(i)
		plot.Parent = plotsFolder
		table.insert(freePlots, plot)
	end
end

--- Assigns a free plot to a player (or returns their existing one on rejoin-before-cleanup).
function MapBuilderService.assignPlot(player: Player)
	if plotByUserId[player.UserId] then
		return plotByUserId[player.UserId]
	end

	local plot = table.remove(freePlots)
	if not plot then
		warn("MapBuilderService: no free tank plots available for", player.Name)
		return nil
	end

	plotByUserId[player.UserId] = plot
	local sign = plot:FindFirstChild("Sign", true)
	local label = sign and sign:FindFirstChild("OwnerLabel", true)
	if label then
		label.Text = player.Name .. "'s Tank"
	end
	local billboard = sign and sign:FindFirstChild("NameTag")
	if billboard then
		billboard.Enabled = true
	end

	-- Player instance Attributes replicate to clients automatically, so the client can
	-- find its own plot without a dedicated remote.
	player:SetAttribute("TankPlotName", plot.Name)

	return plot
end

function MapBuilderService.getPlot(player: Player)
	return plotByUserId[player.UserId]
end

function MapBuilderService.releasePlot(player: Player)
	local plot = plotByUserId[player.UserId]
	if not plot then
		return
	end

	local fishContainer = plot:FindFirstChild("FishContainer")
	if fishContainer then
		fishContainer:ClearAllChildren()
	end

	local sign = plot:FindFirstChild("Sign", true)
	local label = sign and sign:FindFirstChild("OwnerLabel", true)
	if label then
		label.Text = "Empty Tank"
	end
	local billboard = sign and sign:FindFirstChild("NameTag")
	if billboard then
		billboard.Enabled = false
	end

	plotByUserId[player.UserId] = nil
	player:SetAttribute("TankPlotName", nil)
	table.insert(freePlots, plot)
end

return MapBuilderService
