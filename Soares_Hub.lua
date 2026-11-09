-- Soares Hub • By MiguelSoares
-- com participação DaviCaetano
-- Menu local para Murder Mystery 2 (Nikilis).

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    return
end
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
    return
end

local previous = playerGui:FindFirstChild("SoaresHub")
if previous then
    local closePrevious = previous:FindFirstChild("Encerrar")
    if closePrevious and closePrevious:IsA("BindableFunction") then
        pcall(function()
            closePrevious:Invoke()
        end)
    end
    if previous.Parent then
        previous:Destroy()
    end
end

local isMM2 = game.GameId == 66654135 or game.PlaceId == 142823291
local renderName = "SoaresHubCamera_" .. player.UserId
local state = {
    running = true,
    loading = true,
    aim = false,
    smoothAim = false,
    torsoAim = false,
    checkWalls = false,
    touchShift = false,
    esp = {Murderer = false, Sheriff = false, Innocent = false},
    espName = true,
    espDistance = false,
    espFill = true,
    espThrough = true,
    profile = "Original",
    graphics = {},
    showFps = false,
}
local connections = {}
local animations = {}
local ui = {}

local colors = {
    white = Color3.fromRGB(255, 255, 255),
    paper = Color3.fromRGB(248, 248, 250),
    line = Color3.fromRGB(220, 220, 225),
    ink = Color3.fromRGB(15, 15, 17),
    muted = Color3.fromRGB(82, 83, 91),
    darkMuted = Color3.fromRGB(187, 187, 197),
}
local roleInfo = {
    Murderer = {name = "Murder", color = Color3.fromRGB(255, 67, 80)},
    Sheriff = {name = "Sheriff", color = Color3.fromRGB(68, 150, 255)},
    Hero = {name = "Herói", color = Color3.fromRGB(98, 205, 255)},
    Innocent = {name = "Innocent", color = Color3.fromRGB(84, 231, 146)},
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function make(className, parent, properties)
    local object = Instance.new(className)
    for name, value in pairs(properties) do
        object[name] = value
    end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    make("UICorner", parent, {CornerRadius = UDim.new(0, radius)})
end

local function stroke(parent, color, transparency)
    make("UIStroke", parent, {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        Transparency = transparency or 0,
        Thickness = 1,
    })
end

local function label(parent, value, size, font, color)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Font = font or Enum.Font.GothamMedium,
        Text = value,
        TextColor3 = color or colors.ink,
        TextSize = size,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function button(parent, value, size)
    local object = make("TextButton", parent, {
        AutoButtonColor = true,
        BackgroundColor3 = colors.ink,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = value,
        TextColor3 = colors.white,
        TextSize = size or 12,
    })
    round(object, 9)
    return object
end

local function animate(object, tweenInfo, goal)
    local tween = TweenService:Create(object, tweenInfo, goal)
    table.insert(animations, tween)
    tween:Play()
    return tween
end

local function diagonal(parent, dark)
    local base = dark and Color3.fromRGB(5, 5, 7) or colors.white
    local band = dark and Color3.fromRGB(244, 244, 247) or colors.ink
    local gradient = make("UIGradient", parent, {
        Rotation = -28,
        Offset = Vector2.new(-1.25, 0.28),
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, base),
            ColorSequenceKeypoint.new(0.22, base),
            ColorSequenceKeypoint.new(0.25, band),
            ColorSequenceKeypoint.new(0.40, band),
            ColorSequenceKeypoint.new(0.44, base),
            ColorSequenceKeypoint.new(0.54, base),
            ColorSequenceKeypoint.new(0.57, band),
            ColorSequenceKeypoint.new(0.64, band),
            ColorSequenceKeypoint.new(0.67, base),
            ColorSequenceKeypoint.new(1, base),
        }),
    })
    return animate(gradient, TweenInfo.new(dark and 2.1 or 3.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        Offset = Vector2.new(1.25, -0.28),
    })
end

ui.gui = make("ScreenGui", playerGui, {
    Name = "SoaresHub",
    DisplayOrder = 50,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function()
    ui.gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)
local closeSignal = make("BindableFunction", ui.gui, {Name = "Encerrar"})
local visuals = make("Folder", Workspace, {Name = "SoaresHubVisuals"})

local screen = make("Frame", ui.gui, {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
})
local window = make("Frame", screen, {
    Name = "Menu",
    BackgroundColor3 = colors.white,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 5,
})
round(window, 18)
stroke(window, colors.ink, 0.18)
local menuMotion = diagonal(window, false)

local header = make("Frame", window, {
    BackgroundColor3 = colors.white,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(10, 10),
    Size = UDim2.new(1, -20, 0, 80),
})
round(header, 12)
stroke(header, colors.line)
local monogram = button(header, "S", 24)
monogram.Active = false
monogram.Selectable = false
monogram.AutoButtonColor = false
monogram.Position = UDim2.fromOffset(10, 12)
monogram.Size = UDim2.fromOffset(40, 40)

local title = label(header, "Soares Hub", 25, Enum.Font.GothamBlack)
title.Position = UDim2.fromOffset(58, 8)
title.Size = UDim2.new(1, -127, 0, 30)
local author = label(header, "By MiguelSoares", 11, Enum.Font.GothamBold)
author.Position = UDim2.fromOffset(59, 39)
author.Size = UDim2.new(1, -68, 0, 14)
local credit = label(header, "com participação DaviCaetano", 11, nil, colors.muted)
credit.Position = UDim2.fromOffset(59, 55)
credit.Size = UDim2.new(1, -68, 0, 14)

local dragZone = make("Frame", header, {
    Active = true,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -66, 1, 0),
    ZIndex = 3,
})
local minimize = button(header, "–", 18)
minimize.Position = UDim2.new(1, -60, 0, 10)
minimize.Size = UDim2.fromOffset(24, 26)
local exit = button(header, "×", 17)
exit.Position = UDim2.new(1, -31, 0, 10)
exit.Size = UDim2.fromOffset(24, 26)

local launcher = button(screen, "S  |  SOARES", 12)
launcher.Position = UDim2.fromOffset(12, 64)
launcher.Size = UDim2.fromOffset(112, 36)
launcher.Visible = false
stroke(launcher, colors.white, 0.18)

local shiftButton = button(screen, "SHIFT LOCK", 11)
shiftButton.Position = UDim2.fromOffset(12, 107)
shiftButton.Size = UDim2.fromOffset(108, 38)
shiftButton.Visible = false
stroke(shiftButton, colors.white, 0.18)

local nav = make("Frame", window, {
    BackgroundColor3 = colors.white,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(10, 97),
    Size = UDim2.new(1, -20, 0, 35),
})
round(nav, 10)
stroke(nav, colors.line)

local pages = {}
local tabs = {}
local function selectPage(key)
    for pageKey, page in pairs(pages) do
        local selected = pageKey == key
        page.Visible = selected
        tabs[pageKey].BackgroundColor3 = selected and colors.ink or colors.paper
        tabs[pageKey].TextColor3 = selected and colors.white or colors.ink
    end
end

for index, key in ipairs({"Combate", "ESP", "Gráficos"}) do
    local tab = button(nav, string.upper(key), 11)
    if key == "Gráficos" then
        tab.Text = "GRÁFICOS"
    end
    tab.Position = UDim2.new((index - 1) / 3, 5, 0, 4)
    tab.Size = UDim2.new(1 / 3, -10, 1, -8)
    tabs[key] = tab

    local page = make("ScrollingFrame", window, {
        Name = key,
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(10, 140),
        ScrollBarImageColor3 = colors.ink,
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Size = UDim2.new(1, -20, 1, -184),
        Visible = false,
    })
    make("UIListLayout", page, {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    make("UIPadding", page, {
        PaddingTop = UDim.new(0, 1),
        PaddingBottom = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 6),
    })
    pages[key] = page
    connect(tab.Activated, function()
        selectPage(key)
    end)
end

local footer = make("Frame", window, {
    BackgroundColor3 = colors.white,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 1, -36),
    Size = UDim2.new(1, -20, 0, 26),
})
round(footer, 8)
stroke(footer, colors.line)
ui.status = label(footer, "", 11, Enum.Font.GothamMedium, colors.muted)
ui.status.Position = UDim2.fromOffset(8, 0)
ui.status.Size = UDim2.new(1, -16, 1, 0)
ui.fps = label(footer, "", 10, Enum.Font.GothamBold)
ui.fps.Position = UDim2.new(1, -66, 0, 0)
ui.fps.Size = UDim2.fromOffset(58, 26)
ui.fps.TextXAlignment = Enum.TextXAlignment.Right

local function status(message)
    if state.running then
        ui.status.Text = message
    end
end

local function card(page, height)
    local row = make("Frame", page, {
        BackgroundColor3 = colors.white,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        LayoutOrder = #page:GetChildren(),
        Size = UDim2.new(1, 0, 0, height),
    })
    round(row, 10)
    stroke(row, colors.line, 0.13)
    return row
end

local function cardCopy(row, titleText, description, reserved)
    local heading = label(row, titleText, 13, Enum.Font.GothamBold)
    heading.Position = UDim2.fromOffset(10, 7)
    heading.Size = UDim2.new(1, -reserved, 0, 17)
    local detail = label(row, description, 11, nil, colors.muted)
    detail.Position = UDim2.fromOffset(10, 26)
    detail.Size = UDim2.new(1, -reserved, 0, 24)
    detail.TextTruncate = Enum.TextTruncate.None
    detail.TextWrapped = true
    detail.TextYAlignment = Enum.TextYAlignment.Top
    return detail
end

local function toggle(page, titleText, detail, read, write)
    local row = card(page, 55)
    cardCopy(row, titleText, detail, 72)
    local action = button(row, "", 10)
    action.Position = UDim2.new(1, -57, 0, 14)
    action.Size = UDim2.fromOffset(47, 27)
    local function refresh()
        local enabled = read()
        action.Text = enabled and "ON" or "OFF"
        action.BackgroundColor3 = enabled and colors.ink or colors.paper
        action.TextColor3 = enabled and colors.white or colors.muted
    end
    connect(action.Activated, function()
        write(not read())
        refresh()
    end)
    refresh()
    return refresh
end

local function option(page, key, titleText, detail, onChange)
    return toggle(page, titleText, detail, function()
        return state[key]
    end, function(value)
        state[key] = value
        if onChange then
            onChange(value)
        end
    end)
end

local function setMenu(visible)
    if state.loading or not state.running then
        return
    end
    window.Visible = visible
    launcher.Visible = not visible
    shiftButton.Visible = isMM2 and UserInputService.TouchEnabled and not visible
    if visible then
        menuMotion:Play()
    else
        menuMotion:Pause()
    end
end

connect(minimize.Activated, function()
    setMenu(false)
end)
connect(launcher.Activated, function()
    setMenu(true)
end)

local position
local function resizeMenu()
    local bounds = screen.AbsoluteSize
    if bounds.X < 1 or bounds.Y < 1 then
        return
    end
    local width = math.min(464, math.max(1, bounds.X - 16))
    local height = math.min(490, math.max(1, bounds.Y - 16))
    local xLimit = math.max(0, bounds.X - width)
    local yLimit = math.max(0, bounds.Y - height)
    window.Size = UDim2.fromOffset(width, height)
    local target = position or Vector2.new(xLimit / 2, yLimit / 2)
    local clamped = Vector2.new(math.clamp(target.X, 0, xLimit), math.clamp(target.Y, 0, yLimit))
    if position then
        position = clamped
    end
    window.Position = UDim2.fromOffset(clamped.X, clamped.Y)
end
connect(screen:GetPropertyChangedSignal("AbsoluteSize"), resizeMenu)
resizeMenu()

local dragInput
local dragOrigin
local startPosition
connect(dragZone.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
        dragOrigin = input.Position
        startPosition = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not dragInput then
        return
    end
    local mouseDrag = dragInput.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement
    if input == dragInput or mouseDrag then
        local delta = input.Position - dragOrigin
        position = startPosition + Vector2.new(delta.X, delta.Y)
        resizeMenu()
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input == dragInput then
        dragInput = nil
    end
end)
connect(UserInputService.WindowFocusReleased, function()
    dragInput = nil
end)
connect(UserInputService.InputBegan, function(input, handled)
    if not handled and input.KeyCode == Enum.KeyCode.RightControl and not UserInputService:GetFocusedTextBox() then
        setMenu(not window.Visible)
    end
end)

-- Estado da rodada e detecção auxiliar por equipamento.
local roundData = {}
local lastSnapshot = -math.huge
local roleRemote
local lastRemoteSearch = -math.huge
local queryBusy = false
local murderer
local espObjects = {}
local activeKill

local function aliveCharacter(other)
    local character = other.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if character and character.Parent and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        return character, humanoid, root
    end
end

local function playerTool(other, name)
    local character = other.Character
    local backpack = other:FindFirstChildOfClass("Backpack")
    local equipped = character and character:FindFirstChild(name)
    if equipped and equipped:IsA("Tool") then
        return equipped
    end
    local stored = backpack and backpack:FindFirstChild(name)
    if stored and stored:IsA("Tool") then
        return stored
    end
end

local function rowFor(other)
    if os.clock() - lastSnapshot <= 3.5 then
        local entry = roundData[other.Name]
        if type(entry) == "table" then
            return entry
        end
    end
end

local function isEliminated(entry)
    return entry and (entry.Killed == true or entry.Dead == true or entry.Alive == false)
end

local function roundRole(other, entry)
    if isEliminated(entry) then
        return nil
    end
    local role = entry and entry.Role
    if role == "Murder" then
        return "Murderer"
    end
    if type(role) == "string" and roleInfo[role] then
        return role
    end
    if playerTool(other, "Knife") then
        return "Murderer"
    end
    if playerTool(other, "Gun") then
        return "Sheriff"
    end
end

local function requestRoles()
    if not isMM2 or queryBusy then
        return
    end
    if not roleRemote or not roleRemote:IsDescendantOf(ReplicatedStorage) then
        local now = os.clock()
        if now - lastRemoteSearch < 5 then
            return
        end
        lastRemoteSearch = now
        local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        roleRemote = remote and remote:IsA("RemoteFunction") and remote or nil
    end
    if not roleRemote then
        return
    end

    queryBusy = true
    local remote = roleRemote
    task.spawn(function()
        local ok, result = pcall(function()
            return remote:InvokeServer()
        end)
        queryBusy = false
        if state.running and ok and type(result) == "table" then
            roundData = result
            lastSnapshot = os.clock()
        end
    end)
end

local function removeEsp(other)
    local visual = espObjects[other]
    if visual then
        visual.highlight:Destroy()
        visual.billboard:Destroy()
        espObjects[other] = nil
    end
end

local function updateEsp(other, character, root, role)
    local visual = espObjects[other]
    if not visual then
        local highlight = make("Highlight", visuals, {
            Name = "SoaresOutline",
        })
        local billboard = make("BillboardGui", visuals, {
            Name = "SoaresRole",
            MaxDistance = 500,
            Size = UDim2.fromOffset(180, 32),
            StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0),
        })
        local caption = label(billboard, "", 12, Enum.Font.GothamBold)
        caption.Size = UDim2.fromScale(1, 1)
        caption.TextXAlignment = Enum.TextXAlignment.Center
        caption.TextStrokeColor3 = colors.ink
        caption.TextStrokeTransparency = 0.15
        visual = {highlight = highlight, billboard = billboard, caption = caption}
        espObjects[other] = visual
    end

    local info = roleInfo[role]
    local highlight = visual.highlight
    highlight.Adornee = character
    highlight.DepthMode = state.espThrough and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.FillColor = info.color
    highlight.FillTransparency = state.espFill and 0.76 or 1
    highlight.OutlineColor = info.color
    highlight.OutlineTransparency = 0.1

    local billboard = visual.billboard
    billboard.Adornee = character:FindFirstChild("Head") or root
    billboard.AlwaysOnTop = state.espThrough
    billboard.Enabled = state.espName or state.espDistance
    local caption = state.espName and (other.DisplayName .. "  ·  " .. info.name) or info.name
    local camera = Workspace.CurrentCamera
    if state.espDistance and camera then
        local distance = (root.Position - camera.CFrame.Position).Magnitude
        caption = caption .. string.format("  [%d]", math.floor(distance + 0.5))
    end
    visual.caption.TextColor3 = info.color
    visual.caption.Text = caption
end

local function syncPlayers()
    murderer = nil
    if not isMM2 then
        return
    end
    for _, other in ipairs(Players:GetPlayers()) do
        local character, _, root = aliveCharacter(other)
        local role = character and roundRole(other, rowFor(other))
        if role == "Murderer" then
            murderer = other
        end
        local espRole = role == "Hero" and "Sheriff" or role
        if other ~= player and role and state.esp[espRole] then
            updateEsp(other, character, root, role)
        else
            removeEsp(other)
        end
    end
end
connect(Players.PlayerRemoving, removeEsp)

-- Mira de câmera após o controlador original do Roblox.
local cameraModule
task.defer(function()
    local scripts = player:FindFirstChild("PlayerScripts")
    local playerModule = scripts and scripts:FindFirstChild("PlayerModule")
    if playerModule and playerModule:IsA("ModuleScript") then
        local ok, module = pcall(require, playerModule)
        if ok and type(module) == "table" and type(module.GetCameras) == "function" then
            local camerasOk, cameras = pcall(module.GetCameras, module)
            if camerasOk and type(cameras) == "table" then
                cameraModule = cameras
            end
        end
    end
end)

local function nativeShift(camera)
    local controller = cameraModule and cameraModule.activeMouseLockController
    if type(controller) == "table" and type(controller.GetIsMouseLocked) == "function"
        and controller:GetIsMouseLocked() then
        return true
    end
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        and (camera.CFrame.Position - camera.Focus.Position).Magnitude > 1
end

local touchHumanoid
local touchOffset
local touchAutoRotate

local function releaseTouchShift()
    if touchHumanoid and touchHumanoid.Parent then
        touchHumanoid.CameraOffset = touchOffset
        touchHumanoid.AutoRotate = touchAutoRotate
    end
    touchHumanoid = nil
end

local function setTouchShift(enabled)
    state.touchShift = enabled
    shiftButton.Text = enabled and "SHIFT LOCK ON" or "SHIFT LOCK"
    shiftButton.BackgroundColor3 = enabled and colors.white or colors.ink
    shiftButton.TextColor3 = enabled and colors.ink or colors.white
    if not enabled then
        releaseTouchShift()
    end
end

connect(shiftButton.Activated, function()
    setTouchShift(not state.touchShift)
end)
connect(player.CharacterRemoving, function()
    setTouchShift(false)
end)

local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.IgnoreWater = true
local lastAimState
local frameCount, elapsed = 0, 0

local function render(dt)
    if state.showFps then
        frameCount = frameCount + 1
        elapsed = elapsed + dt
        if elapsed >= 0.55 then
            ui.fps.Text = string.format("%d FPS", math.floor(frameCount / elapsed + 0.5))
            frameCount, elapsed = 0, 0
        end
    end
    if not state.aim and not state.touchShift then
        return
    end
    local camera = Workspace.CurrentCamera
    local character, humanoid, root = aliveCharacter(player)
    if not camera or camera.CameraType == Enum.CameraType.Scriptable or not character then
        releaseTouchShift()
        return
    end
    local subject = camera.CameraSubject
    if subject ~= humanoid and (not subject or not subject:IsDescendantOf(character)) then
        releaseTouchShift()
        return
    end

    if state.touchShift and touchHumanoid ~= humanoid then
        releaseTouchShift()
        touchHumanoid = humanoid
        touchOffset = humanoid.CameraOffset
        touchAutoRotate = humanoid.AutoRotate
        humanoid.CameraOffset = touchOffset + Vector3.new(1.65, 0.15, 0)
        humanoid.AutoRotate = false
    end

    local notice
    if state.aim and isMM2 and not activeKill then
        if not (state.touchShift or nativeShift(camera)) then
            notice = "Mira armada. Ative o Shift Lock."
        elseif not murderer or murderer == player then
            notice = "Aguardando um Murder na rodada."
        else
            local target, _, targetRoot = aliveCharacter(murderer)
            if target then
                local aimPart
                if state.torsoAim then
                    aimPart = target:FindFirstChild("UpperTorso") or target:FindFirstChild("Torso")
                else
                    aimPart = target:FindFirstChild("Head")
                end
                aimPart = aimPart or targetRoot
                local origin = camera.CFrame.Position
                local direction = aimPart.Position - origin
                local clear = direction.Magnitude > 0.01
                if clear and state.checkWalls then
                    ray.FilterDescendantsInstances = {character}
                    local hit = Workspace:Raycast(origin, direction, ray)
                    clear = not hit or hit.Instance:IsDescendantOf(target)
                end
                if clear then
                    local locked = CFrame.lookAt(origin, aimPart.Position)
                    camera.CFrame = state.smoothAim and camera.CFrame:Lerp(locked, 1 - math.exp(-dt * 25)) or locked
                    notice = "Mira travada em " .. murderer.DisplayName
                else
                    notice = "Murder fora da linha de visão."
                end
            else
                notice = "Aguardando um Murder na rodada."
            end
        end
    end
    if notice and notice ~= lastAimState then
        lastAimState = notice
        status(notice)
    end

    if state.touchShift then
        local view = camera.CFrame.LookVector
        local horizontal = Vector3.new(view.X, 0, view.Z)
        if horizontal.Magnitude > 0.01 then
            root.CFrame = CFrame.lookAt(root.Position, root.Position + horizontal)
        end
    end
end
RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, render)

-- Kill All: sequência cancelável com a faca da rodada.
local combat = pages.Combate
local killRow = card(combat, 55)
local killHint = cardCopy(killRow, "Kill All", "Disponível quando você estiver de Murder.", 105)
local killButton = button(killRow, "KILL ALL", 10)
killButton.Position = UDim2.new(1, -91, 0, 13)
killButton.Size = UDim2.fromOffset(80, 29)

local function currentKnife()
    if not isMM2 then
        return nil
    end
    local character, humanoid, root = aliveCharacter(player)
    local entry = rowFor(player)
    local knife = character and playerTool(player, "Knife")
    if knife and not isEliminated(entry) and roundRole(player, entry) == "Murderer" then
        return knife, character, humanoid, root
    end
end

local function refreshKillButton()
    local available = currentKnife() ~= nil
    killButton.Text = activeKill and (activeKill.cancelled and "PARANDO" or "PARAR") or "KILL ALL"
    killButton.BackgroundColor3 = (available or activeKill) and colors.ink or colors.paper
    killButton.TextColor3 = (available or activeKill) and colors.white or colors.muted
    if activeKill then
        killHint.Text = string.format("Alvos concluídos: %d/%d", activeKill.done, activeKill.total)
    else
        killHint.Text = available and "Faca detectada. Toque para iniciar." or "Disponível quando você estiver de Murder."
    end
end

local function killTarget(other)
    if other.Parent ~= Players or other == player then
        return nil
    end
    local entry = rowFor(other)
    if isEliminated(entry) then
        return nil
    end
    local hasSnapshot = os.clock() - lastSnapshot <= 3.5 and next(roundData) ~= nil
    if hasSnapshot and not entry then
        return nil
    end
    local character, _, root = aliveCharacter(other)
    return root, character
end

local function canContinue(job)
    if not state.running or job.cancelled then
        return false
    end
    local knife, character = currentKnife()
    return knife == job.knife and character == job.character
end

local function returnFromKill(job)
    if job.restored then
        return
    end
    job.restored = true
    local character, humanoid, root = aliveCharacter(player)
    if character ~= job.character or root ~= job.root then
        return
    end
    if job.moved and playerTool(player, "Knife") == job.knife then
        root.CFrame = job.origin
    end
    if job.equipped and job.knife.Parent == character then
        local backpack = player:FindFirstChildOfClass("Backpack")
        if job.originalTool and job.originalTool.Parent == backpack then
            humanoid:EquipTool(job.originalTool)
        else
            humanoid:UnequipTools()
        end
    end
end

local simulateTouch = type(firetouchinterest) == "function" and firetouchinterest or nil

local function slashAt(job, other)
    local targetRoot = killTarget(other)
    if not targetRoot then
        return
    end
    local near = targetRoot.Position - targetRoot.CFrame.LookVector * 1.4
    job.root.CFrame = CFrame.lookAt(near, targetRoot.Position)
    job.moved = true
    task.wait(0.11)
    if not canContinue(job) or killTarget(other) ~= targetRoot then
        return
    end
    if (job.root.Position - targetRoot.Position).Magnitude > 6 then
        return
    end
    local stab = job.knife:FindFirstChild("Stab")
    if stab and stab:IsA("RemoteEvent") then
        stab:FireServer("Slash")
    else
        job.knife:Activate()
    end
    local handle = job.knife:FindFirstChild("Handle")
    if simulateTouch and handle and handle:IsA("BasePart") then
        task.wait(0.05)
        if canContinue(job) and killTarget(other) == targetRoot then
            pcall(simulateTouch, handle, targetRoot, 0)
            task.wait()
            pcall(simulateTouch, handle, targetRoot, 1)
        end
    end
    task.wait(0.34)
end

local function startKill()
    if activeKill then
        activeKill.cancelled = true
        refreshKillButton()
        return
    end
    local knife, character, humanoid, root = currentKnife()
    if not knife then
        status(isMM2 and "Kill All requer a faca da rodada." or "Abra o Murder Mystery 2.")
        return
    end

    local targets = {}
    for _, other in ipairs(Players:GetPlayers()) do
        local targetRoot, targetCharacter = killTarget(other)
        if targetRoot then
            local role = roundRole(other, rowFor(other))
            table.insert(targets, {
                player = other,
                character = targetCharacter,
                armed = role == "Sheriff" or role == "Hero",
                distance = (root.Position - targetRoot.Position).Magnitude,
            })
        end
    end
    if #targets == 0 then
        status("Nenhum alvo vivo encontrado.")
        return
    end
    table.sort(targets, function(a, b)
        if a.armed ~= b.armed then
            return a.armed
        end
        return a.distance < b.distance
    end)

    local job = {
        knife = knife,
        character = character,
        root = root,
        origin = root.CFrame,
        originalTool = character:FindFirstChildOfClass("Tool"),
        total = #targets,
        done = 0,
        confirmed = 0,
    }
    activeKill = job
    refreshKillButton()
    status("Kill All em andamento.")
    task.spawn(function()
        local ok = pcall(function()
            if knife.Parent ~= character then
                humanoid:EquipTool(knife)
                job.equipped = true
                task.wait(0.18)
            end
            for _, target in ipairs(targets) do
                if not canContinue(job) or knife.Parent ~= character then
                    break
                end
                for _ = 1, 2 do
                    local targetRoot, targetCharacter = killTarget(target.player)
                    if not canContinue(job) or not targetRoot or targetCharacter ~= target.character then
                        break
                    end
                    slashAt(job, target.player)
                end
                if not state.running or job.cancelled then
                    break
                end
                if target.player.Parent == Players then
                    local entry = rowFor(target.player)
                    local targetHumanoid = target.character:FindFirstChildOfClass("Humanoid")
                    if isEliminated(entry) or (targetHumanoid and targetHumanoid.Health <= 0) then
                        job.confirmed = job.confirmed + 1
                    end
                end
                job.done = job.done + 1
                refreshKillButton()
            end
        end)

        local restored = pcall(returnFromKill, job)
        activeKill = nil
        if not state.running then
            return
        end
        refreshKillButton()
        if not ok or not restored then
            status("Kill All interrompido durante a rodada.")
        elseif job.cancelled then
            status("Kill All cancelado.")
        else
            status(string.format("Kill All • %d/%d eliminações confirmadas", job.confirmed, job.total))
        end
    end)
end
connect(killButton.Activated, startKill)

-- Opções de combate e marcadores.
killRow.LayoutOrder = 100
option(combat, "aim", "Mira no Murder", "Acompanha o alvo com Shift Lock ligado.", function(enabled)
    if not isMM2 then
        state.aim = false
        status("Abra o Murder Mystery 2 para usar a mira.")
        return
    end
    lastAimState = nil
    if enabled then
        requestRoles()
        syncPlayers()
        status("Mira armada. Ative o Shift Lock.")
    else
        status("Mira desligada.")
    end
end)
option(combat, "smoothAim", "Movimento suave", "ON suaviza a mira. OFF gruda de uma vez.")
option(combat, "torsoAim", "Mirar no peito", "ON mira no peito. OFF mira na cabeça.")
option(combat, "checkWalls", "Checar paredes", "Trava a mira quando o Murder estiver visível.")

local espPage = pages.ESP
for _, role in ipairs({"Murderer", "Sheriff", "Innocent"}) do
    local info = roleInfo[role]
    local description = {
        Murderer = "Marca o Murder em vermelho.",
        Sheriff = "Marca o Sheriff e o Herói em azul.",
        Innocent = "Marca os Innocents vivos em verde.",
    }
    toggle(espPage, "ESP " .. info.name, description[role], function()
        return state.esp[role]
    end, function(value)
        if not isMM2 then
            status("Abra o Murder Mystery 2 para usar o ESP.")
            return
        end
        state.esp[role] = value
        if value then
            requestRoles()
        end
        syncPlayers()
        status("ESP " .. info.name .. (value and " ligado." or " desligado."))
    end)
end
option(espPage, "espName", "Nome e papel", "Mostra o nome do jogador acima do personagem.", syncPlayers)
option(espPage, "espDistance", "Distância", "Mostra a distância em studs.", syncPlayers)
option(espPage, "espFill", "Preenchimento", "Liga a cor no interior da silhueta.", syncPlayers)
option(espPage, "espThrough", "Através de paredes", "Exibe os contornos quando há obstáculos.", syncPlayers)

-- Perfis gráficos locais. Cada propriedade alterada é registrada para restauração.
local profiles = {
    Original = {},
    Alto = {shadows = true, specular = 1, diffuse = 1, quality = "Level21"},
    Baixo = {noShadows = true, noParticles = true, noPost = true, specular = 0, quality = "Level04"},
    Massinha = {
        noShadows = true,
        noParticles = true,
        noPost = true,
        noLights = true,
        noTextures = true,
        noFog = true,
        plastic = true,
        specular = 0,
        quality = "Level01",
    },
}
local originals = {}
local graphicsGeneration = 0
local graphicsRendering
pcall(function()
    graphicsRendering = settings().Rendering
end)

local function change(instance, key, value)
    if value == nil then
        return
    end
    local ok, before = pcall(function()
        return instance[key]
    end)
    if not ok or before == value then
        return
    end
    local applied = pcall(function()
        instance[key] = value
    end)
    if not applied then
        return
    end
    local fields = originals[instance]
    if not fields then
        fields = {}
        originals[instance] = fields
    end
    fields[key] = {before = before, set = value}
end

local function restore(instance)
    local fields = originals[instance]
    if not fields then
        return
    end
    originals[instance] = nil
    for key, record in pairs(fields) do
        pcall(function()
            if instance[key] == record.set then
                instance[key] = record.before
            end
        end)
    end
end

local function restoreAll()
    for instance in pairs(originals) do
        restore(instance)
    end
end

local function belongsToCharacter(instance)
    local model = instance:FindFirstAncestorOfClass("Model")
    while model do
        if model:FindFirstChildOfClass("Humanoid") then
            return true
        end
        model = model:FindFirstAncestorOfClass("Model")
    end
    return false
end

local function paint(instance)
    local graphics = state.graphics
    if graphics.noPost and instance:IsA("PostEffect") then
        change(instance, "Enabled", false)
    elseif graphics.noLights and instance:IsA("Light") then
        change(instance, "Enabled", false)
    elseif graphics.noParticles and (
        instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")
        or instance:IsA("Smoke") or instance:IsA("Sparkles") or instance:IsA("Fire")
    ) then
        change(instance, "Enabled", false)
    elseif graphics.noFog and instance:IsA("Atmosphere") then
        change(instance, "Density", 0)
        change(instance, "Haze", 0)
        change(instance, "Glare", 0)
    end

    if graphics.plastic and instance:IsA("BasePart") and not belongsToCharacter(instance) then
        change(instance, "MaterialVariant", "")
        change(instance, "Material", Enum.Material.SmoothPlastic)
        change(instance, "Reflectance", 0)
    end
    if graphics.noTextures then
        if (instance:IsA("Decal") or instance:IsA("Texture")) and not belongsToCharacter(instance) then
            change(instance, "Transparency", 1)
        elseif instance:IsA("MeshPart") and not belongsToCharacter(instance) then
            change(instance, "TextureID", "")
        elseif instance:IsA("SpecialMesh") and not belongsToCharacter(instance) then
            change(instance, "TextureId", "")
        end
    end
end

local function graphicsNeedScan()
    local g = state.graphics
    return g.noPost or g.noLights or g.noParticles or g.noFog or g.plastic or g.noTextures
end

local function applyGraphics()
    graphicsGeneration = graphicsGeneration + 1
    local generation = graphicsGeneration
    restoreAll()

    local graphics = state.graphics
    if graphics.noShadows then
        change(Lighting, "GlobalShadows", false)
    elseif graphics.shadows then
        change(Lighting, "GlobalShadows", true)
    end
    change(Lighting, "EnvironmentDiffuseScale", graphics.diffuse)
    change(Lighting, "EnvironmentSpecularScale", graphics.specular)
    if graphics.noFog then
        change(Lighting, "FogEnd", 100000)
    end
    if graphics.quality and graphicsRendering then
        change(graphicsRendering, "QualityLevel", Enum.QualityLevel[graphics.quality])
    end
    if not graphicsNeedScan() then
        return
    end

    task.spawn(function()
        for _, scope in ipairs({Lighting, Workspace}) do
            for index, instance in ipairs(scope:GetDescendants()) do
                if generation ~= graphicsGeneration or not state.running then
                    return
                end
                if instance:IsDescendantOf(scope) then
                    paint(instance)
                end
                if index % 200 == 0 then
                    task.wait()
                end
            end
        end
    end)
end

for _, scope in ipairs({Lighting, Workspace}) do
    connect(scope.DescendantAdded, function(instance)
        if graphicsNeedScan() then
            task.defer(function()
                if state.running and instance:IsDescendantOf(scope) then
                    paint(instance)
                end
            end)
        end
    end)
    connect(scope.DescendantRemoving, restore)
end

local graphicsPage = pages["Gráficos"]
local presetRow = card(graphicsPage, 77)
local presetTitle = label(presetRow, "Perfil gráfico", 13, Enum.Font.GothamBold)
presetTitle.Position = UDim2.fromOffset(10, 7)
presetTitle.Size = UDim2.new(1, -20, 0, 17)
local presetButtons = {}
local graphicsToggles = {}

local function refreshGraphicsControls()
    for key, action in pairs(presetButtons) do
        local selected = key == state.profile
        action.BackgroundColor3 = selected and colors.ink or colors.paper
        action.TextColor3 = selected and colors.white or colors.ink
    end
    for _, refresh in ipairs(graphicsToggles) do
        refresh()
    end
end

for index, name in ipairs({"Original", "Alto", "Baixo", "Massinha"}) do
    local action = button(presetRow, name, 11)
    action.Position = UDim2.new((index - 1) / 4, 7, 0, 35)
    action.Size = UDim2.new(1 / 4, -14, 0, 31)
    presetButtons[name] = action
    connect(action.Activated, function()
        state.profile = name
        state.graphics = {}
        for property, value in pairs(profiles[name]) do
            state.graphics[property] = value
        end
        applyGraphics()
        refreshGraphicsControls()
        status(name == "Original" and "Gráficos originais restaurados." or "Perfil " .. name .. " aplicado.")
    end)
end

for _, setting in ipairs({
    {"noShadows", "Reduzir sombras", "Desliga as sombras globais."},
    {"noParticles", "Ocultar partículas", "Esconde partículas, feixes e rastros."},
    {"noPost", "Ocultar pós-efeitos", "Desliga bloom, desfoque e filtros de cor."},
    {"noLights", "Ocultar luzes", "Desliga luzes dinâmicas do mapa."},
    {"noTextures", "Ocultar texturas", "Oculta texturas comuns do cenário."},
    {"noFog", "Reduzir névoa", "Reduz névoa e brilho da atmosfera."},
    {"plastic", "Material liso", "Troca os materiais do cenário por plástico."},
}) do
    local key = setting[1]
    table.insert(graphicsToggles, toggle(graphicsPage, setting[2], setting[3], function()
        return state.graphics[key] == true
    end, function(value)
        state.graphics[key] = value
        applyGraphics()
    end))
end

option(graphicsPage, "showFps", "Contador de FPS", "Mostra os FPS no rodapé do menu.", function(enabled)
    frameCount, elapsed = 0, 0
    ui.fps.Text = ""
    ui.status.Size = UDim2.new(1, enabled and -72 or -16, 1, 0)
end)
refreshGraphicsControls()

-- Fechamento limpo, inclusive quando o script é iniciado outra vez.
local function shutdown(destroyingGui)
    if not state.running then
        return
    end
    state.running = false
    graphicsGeneration = graphicsGeneration + 1
    if activeKill then
        activeKill.cancelled = true
        pcall(returnFromKill, activeKill)
    end
    releaseTouchShift()
    RunService:UnbindFromRenderStep(renderName)
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    for _, animation in ipairs(animations) do
        animation:Cancel()
    end
    for other in pairs(espObjects) do
        removeEsp(other)
    end
    visuals:Destroy()
    restoreAll()
    if destroyingGui ~= true then
        ui.gui:Destroy()
    end
end

closeSignal.OnInvoke = shutdown
connect(exit.Activated, shutdown)
connect(ui.gui.Destroying, function()
    shutdown(true)
end)

selectPage("Combate")
refreshKillButton()
status(isMM2 and "Pronto • Murder Mystery 2" or "Mira e ESP disponíveis no Murder Mystery 2.")

local nextQuery = 0
task.spawn(function()
    while state.running do
        if isMM2 then
            local track = state.aim or activeKill or state.esp.Murderer or state.esp.Sheriff or state.esp.Innocent
            if (track or playerTool(player, "Knife")) and os.clock() >= nextQuery then
                nextQuery = os.clock() + 1
                requestRoles()
            end
            if track then
                syncPlayers()
            end
            refreshKillButton()
        end
        task.wait(0.2)
    end
end)

-- Abertura animada em preto e branco.
local cover = make("CanvasGroup", screen, {
    BackgroundColor3 = colors.white,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 20,
    Active = true,
})
local openingMotion = diagonal(cover, true)
local intro = make("Frame", cover, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, -26, 0, 194),
    BackgroundColor3 = colors.ink,
    BorderSizePixel = 0,
})
make("UISizeConstraint", intro, {MaxSize = Vector2.new(390, 194)})
round(intro, 18)
stroke(intro, colors.white, 0.32)

local function introText(value, size, font, color, y, height)
    local object = label(intro, value, size, font, color)
    object.TextXAlignment = Enum.TextXAlignment.Center
    object.Position = UDim2.fromOffset(10, y)
    object.Size = UDim2.new(1, -20, 0, height)
    return object
end
introText("MURDER MYSTERY 2", 10, Enum.Font.GothamBold, colors.darkMuted, 17, 16)
introText("Soares Hub", 34, Enum.Font.GothamBlack, colors.white, 37, 42)
introText("By MiguelSoares", 13, Enum.Font.GothamBold, colors.white, 83, 18)
introText("com participação DaviCaetano", 11, nil, colors.darkMuted, 104, 16)
local progressText = introText("Abrindo o hub   0%", 10, Enum.Font.GothamBold, colors.darkMuted, 156, 19)

local track = make("Frame", intro, {
    Position = UDim2.fromOffset(21, 140),
    Size = UDim2.new(1, -42, 0, 5),
    BorderSizePixel = 0,
    BackgroundColor3 = Color3.fromRGB(61, 61, 68),
})
round(track, 3)
local progress = make("Frame", track, {
    Size = UDim2.fromScale(0, 1),
    BorderSizePixel = 0,
    BackgroundColor3 = colors.white,
})
round(progress, 3)
animate(progress, TweenInfo.new(1.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.fromScale(1, 1),
})

task.spawn(function()
    local started = os.clock()
    while state.running do
        local ratio = math.clamp((os.clock() - started) / 1.65, 0, 1)
        local visualRatio = 1 - (1 - ratio) ^ 4
        progressText.Text = string.format("Abrindo o hub   %d%%", math.floor(visualRatio * 100))
        if ratio >= 1 then
            break
        end
        task.wait(0.035)
    end
    if not state.running then
        return
    end
    state.loading = false
    setMenu(true)
    animate(cover, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        GroupTransparency = 1,
    }).Completed:Wait()
    if state.running then
        openingMotion:Cancel()
        cover:Destroy()
    end
end)
