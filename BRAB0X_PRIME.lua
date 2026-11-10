
-- BRAB0X PRIME V10 | PAINEL AZUL + AIM OPCIONAL
-- LocalScript para o seu proprio jogo.
-- StarterPlayer > StarterPlayerScripts
-- F = Fly | RightShift = Menu | Ctrl+K = Buscar
-- WASD = mover | Espaco/E = subir | Ctrl/Q = descer

local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Avatar = game:GetService("AvatarEditorService")
local Tween = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
if not player then return end

local pg = player:WaitForChild("PlayerGui")

-- LIMPEZA DE VERSOES ANTIGAS

for _, name in ipairs({
    "BRAB0X_V10_STOP",
    "BRAB0X_V9_STOP",
    "BRAB0X_V8_STOP",
    "BRAB0X_V7_STOP",
    "BRAB0X_V6_STOP",
    "BRAB0X_V5_STOP"
}) do
    if type(_G[name]) == "function" then
        pcall(_G[name])
    end
end

local previous = pg:FindFirstChild("BRAB0X_PRIME_V10")
if previous then previous:Destroy() end

-- CONFIGURACOES

local config = _G.BRAB0X_PRIME_PREFS or {}
config.scale = tonumber(config.scale) or 1
config.lang = config.lang or "pt"
-- Migracao de tema: cores antigas nao sao mais o padrao.
if config.theme == nil or config.theme == "violet" or config.theme == "rose" then
    config.theme = "blue"
end
if config.aimEnabled == nil then
    config.aimEnabled = false
end
_G.BRAB0X_PRIME_PREFS = config

local S = {
    fly = false,
    speed = 55,
    boost = false,
    boostX = 2,
    flat = false,
    vertical = 0,
    noclip = false,
    aim = false,
    aimHold = true,
    aimRadius = 150,
    aimSmooth = .16,
    aimCircle = true,
    saved = nil,
    glow = false,
    trail = false,
    frozen = false,
    emote = nil
}

local palette = {
    blue = Color3.fromRGB(0,163,255),
    cyan = Color3.fromRGB(0,220,235),
    teal = Color3.fromRGB(0,206,170),
    whiteblue = Color3.fromRGB(116,188,255)
}
local ink = Color3.fromRGB(5,10,19)
local card = Color3.fromRGB(10,19,32)
local control = Color3.fromRGB(18,34,52)
local white = Color3.fromRGB(238,248,255)
local muted = Color3.fromRGB(152,176,195)
local accent = palette[config.theme] or palette.blue

local connections = {}
local flyParts = {}
local collisions = {}
local fxParts = {}
local transparent = {}

local flyStep
local noclipStep
local danceStep
local animTrack

local oldHum
local oldRotate
local oldStand

local freezeRoot
local freezeOriginal
local glowEffect

local originalHum
local originalWalk
local originalJump
local originalJumpMode

local stopped = false

local old = {
    gravity = workspace.Gravity,
    clock = Lighting.ClockTime,
    brightness = Lighting.Brightness,
    fog = Lighting.FogEnd,
    mode = player.CameraMode,
    min = player.CameraMinZoomDistance,
    max = player.CameraMaxZoomDistance,
    fov = workspace.CurrentCamera
        and workspace.CurrentCamera.FieldOfView or 70
}

-- FUNCOES BASICAS

local function bind(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections+1] = c
    return c
end

local function obj(class, parent, values)
    local v = Instance.new(class)

    for k,x in pairs(values or {}) do
        v[k] = x
    end

    v.Parent = parent
    return v
end

local function round(p,n)
    obj("UICorner",p,{
        CornerRadius = UDim.new(0,n or 9)
    })
    return p
end

local function chars()
    local c = player.Character
    return c,
        c and c:FindFirstChildOfClass("Humanoid"),
        c and c:FindFirstChild("HumanoidRootPart")
end

local function txt(p,s,h,size,bold)
    return obj("TextLabel",p,{
        Size = UDim2.new(1,0,0,h or 24),
        BackgroundTransparency = 1,
        Text = s,
        TextColor3 = white,
        Font = bold and Enum.Font.GothamBold
            or Enum.Font.Gotham,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
end

local function btn(p,s,fn,h)
    local b = round(obj("TextButton",p,{
        Size = UDim2.new(1,0,0,h or 34),
        BackgroundColor3 = control,
        BorderSizePixel = 0,
        Text = s,
        TextColor3 = white,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = true
    }),8)

    if fn then
        bind(b.MouseButton1Click,fn)
    end

    return b
end

local function stack(p,gap)
    obj("UIListLayout",p,{
        Padding = UDim.new(0,gap or 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
end

local function clear(p)
    for _,v in ipairs(p:GetChildren()) do
        if v:IsA("GuiObject") then
            v:Destroy()
        end
    end
end

-- IDIOMAS

local L = {
    pt = {"Inicio","Voo","Jogador","Camera","Mundo","Emotes","Aim treino","Ajustes","Comandos"},
    en = {"Home","Flight","Player","Camera","World","Emotes","Training aim","Settings","Commands"},
    es = {"Inicio","Vuelo","Jugador","Camara","Mundo","Emotes","Punteria practica","Ajustes","Comandos"},
    fr = {"Accueil","Vol","Joueur","Camera","Monde","Emotes","Visee pratique","Options","Commandes"},
    de = {"Start","Flug","Spieler","Kamera","Welt","Emotes","Trainingsziel","Optionen","Befehle"},
    it = {"Inizio","Volo","Giocatore","Camera","Mondo","Emote","Mira pratica","Opzioni","Comandi"},
    ja = {"ホーム","飛行","プレイヤー","カメラ","世界","エモート","練習照準","設定","コマンド"},
    ko = {"홈","비행","플레이어","카메라","월드","이모트","연습 조준","설정","명령어"},
    zh = {"主页","飞行","玩家","相机","世界","动作","练习瞄准","设置","命令"},
    ru = {"Главная","Полет","Игрок","Камера","Мир","Эмоции","Прицел","Настройки","Команды"},
    tr = {"Ana sayfa","Ucus","Oyuncu","Kamera","Dunya","Emotlar","Antrenman","Ayarlar","Komutlar"},
    id = {"Beranda","Terbang","Pemain","Kamera","Dunia","Emote","Latihan","Pengaturan","Perintah"}
}

local sections = {
    "HOME","FLY","PLAYER","CAMERA",
    "WORLD","EMOTES","AIM",
    "SETTINGS","COMMANDS"
}

-- A unica categoria opcional e AIM; todas as outras permanecem juntas.
local navOrder = {"HOME", "COMMANDS", "AIM", "SETTINGS"}
local function moduleEnabled(name)
    return name ~= "AIM" or config.aimEnabled == true
end

local openModulePicker
local refreshCommandList

-- JANELA PRINCIPAL

local gui = obj("ScreenGui",pg,{
    Name = "BRAB0X_PRIME_V10",
    ResetOnSpawn = false,
    DisplayOrder = 100
})

local main = round(obj("Frame",gui,{
    Size = UDim2.fromOffset(800,530),
    Position = UDim2.new(.5,-400,.5,-265),
    BackgroundColor3 = ink,
    BorderSizePixel = 0,
    Active = true,
    Visible = false
}),15)

local stroke = obj("UIStroke",main,{
    Color = accent,
    Thickness = 1.6,
    Transparency = .05
})

local uiScale = obj("UIScale",main,{Scale=1})

local header = obj("Frame",main,{
    Size = UDim2.new(1,0,0,64),
    BackgroundColor3 = card,
    BorderSizePixel = 0,
    Active = true
})

round(header,15)

obj("UIGradient",header,{
    Color = ColorSequence.new(
        card,Color3.fromRGB(6,48,69)
    )
})

local brand = txt(
    header,"BRAB0X  /  PRIME",35,23,true
)
brand.Position = UDim2.fromOffset(16,4)
brand.Size = UDim2.fromOffset(340,34)

local sub = txt(
    header,
    "V10  •  BLUE EDITION   /   TODOS OS COMANDOS EM UM LUGAR",
    16,10
)
sub.TextColor3 = muted
sub.Position = UDim2.fromOffset(17,38)
sub.Size = UDim2.fromOffset(440,17)

local topState = txt(header,"FLY OFF",23,12,true)
topState.TextColor3 = accent
topState.TextXAlignment = Enum.TextXAlignment.Right
topState.Position = UDim2.new(1,-250,0,18)
topState.Size = UDim2.fromOffset(150,23)

local minimize = btn(header,"—",nil,30)
minimize.Size = UDim2.fromOffset(31,30)
minimize.Position = UDim2.new(1,-77,0,13)

local close = btn(header,"×",nil,30)
close.Size = UDim2.fromOffset(31,30)
close.Position = UDim2.new(1,-40,0,13)

local reopen = btn(gui,"BRAB0X +",nil,35)
reopen.Size = UDim2.fromOffset(150,35)
reopen.Position = UDim2.new(.5,-75,.09,0)
reopen.Visible = false

-- FPS

local fpsLabel = txt(gui,"FPS: --",21,12,true)
fpsLabel.Size = UDim2.fromOffset(100,23)
fpsLabel.Position = UDim2.new(1,-115,0,12)
fpsLabel.TextColor3 = accent
fpsLabel.Visible = false

local crosshair = txt(gui,"+",32,28,true)
crosshair.Size = UDim2.fromOffset(36,36)
crosshair.AnchorPoint = Vector2.new(.5,.5)
crosshair.Position = UDim2.fromScale(.5,.5)
crosshair.TextXAlignment = Enum.TextXAlignment.Center
crosshair.TextColor3 = accent
crosshair.Visible = false

local fpsStep

local function fpsToggle(enabled)
    if fpsStep then
        fpsStep:Disconnect()
        fpsStep = nil
    end

    fpsLabel.Visible = enabled

    if enabled then
        local count,elapsed = 0,0

        fpsStep = Run.RenderStepped:Connect(function(dt)
            count = count+1
            elapsed = elapsed+dt

            if elapsed >= .6 then
                fpsLabel.Text =
                    "FPS: "..math.floor(count/elapsed+.5)

                count,elapsed = 0,0
            end
        end)
    end
end

-- MENU LATERAL

local sidebar = round(obj("Frame",main,{
    Position = UDim2.fromOffset(12,76),
    Size = UDim2.fromOffset(174,393),
    BackgroundColor3 = card,
    BorderSizePixel = 0
}),11)

local nav = obj("Frame",sidebar,{
    Position = UDim2.fromOffset(8,8),
    Size = UDim2.new(1,-16,1,-16),
    BackgroundTransparency = 1
})
stack(nav,7)

local right = round(obj("Frame",main,{
    Position = UDim2.fromOffset(197,76),
    Size = UDim2.fromOffset(590,393),
    BackgroundColor3 = card,
    BorderSizePixel = 0
}),11)

local pages = {}
local navButtons = {}

for _,id in ipairs(sections) do
    pages[id] = obj("ScrollingFrame",right,{
        Size = UDim2.new(1,-22,1,-20),
        Position = UDim2.fromOffset(11,10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false
    })

    stack(pages[id],6)
end

for _,id in ipairs(navOrder) do
    navButtons[id] = btn(nav,id,nil,44)
end

local status = txt(
    main,
    "PRONTO | F = FLY • RSHIFT = MENU • CTRL+K = COMANDOS",
    17,11
)

status.TextColor3 = muted
status.Position = UDim2.fromOffset(15,480)
status.Size = UDim2.new(1,-28,0,17)

local cmdInput = round(obj("TextBox",main,{
    Position = UDim2.fromOffset(13,500),
    Size = UDim2.fromOffset(652,27),
    BackgroundColor3 = control,
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = white,
    PlaceholderText = "Digite: fly | speed 90 | emote dance | theme blue",
    PlaceholderColor3 = muted,
    ClearTextOnFocus = false,
    Font = Enum.Font.Code,
    TextSize = 12
}),7)

local execute = btn(main,"EXEC",nil,26)
execute.Position = UDim2.fromOffset(674,500)
execute.Size = UDim2.fromOffset(113,27)

local selected = "HOME"

local function notify(message)
    if not stopped and status.Parent then
        status.Text = tostring(message)
    end
end

local function show(page)
    if not moduleEnabled(page) then
        page = "HOME"
    end

    selected = page

    for name,p in pairs(pages) do
        p.Visible = name == page
    end

    for name,b in pairs(navButtons) do
        b.Visible = moduleEnabled(name)
        b.BackgroundColor3 =
            name == page and accent or control
        b.TextColor3 =
            name == page and ink or white
    end
end

for name,b in pairs(navButtons) do
    bind(b.MouseButton1Click,function()
        show(name)
    end)
end

local function relabel()
    local labels = L[config.lang] or L.en

    for _,name in ipairs(navOrder) do
        local i = table.find(sections,name)
        navButtons[name].Text = "   "..(labels[i] or name)
    end
end

local function responsive()
    local camera = workspace.CurrentCamera
    local view = camera and camera.ViewportSize
        or Vector2.new(1280,720)

    uiScale.Scale = math.clamp(
        math.min(view.X/825,view.Y/560),
        .5,1
    )*config.scale
end

responsive()

local function titleRow(p,message)
    local l = txt(p,message,25,13,true)
    l.TextColor3 = accent
    return l
end

local exec
local closeHub
local refresh

-- Comandos em duas colunas
local itemRowCache = {}
local function item(p,label,command)
    local row = itemRowCache[p]
    if not row or not row.Parent or #row:GetChildren() >= 3 then
        row = obj("Frame",p,{
            Size = UDim2.new(1,-8,0,39),
            BackgroundTransparency = 1
        })
        obj("UIListLayout",row,{
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0,8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        itemRowCache[p] = row
    end
    local b = btn(row,label,function()
        if command and exec then exec(command) end
    end,39)
    b.Size = UDim2.new(.5,-4,1,0)
    return b
end

local function line(p,a,ca,b,cb)
    local row = obj("Frame",p,{
        Size = UDim2.new(1,-8,0,35),
        BackgroundTransparency = 1
    })

    obj("UIListLayout",row,{
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0,8)
    })

    local x = btn(row,a,ca,35)
    x.Size = UDim2.new(.5,-4,1,0)

    local y = btn(row,b,cb,35)
    y.Size = UDim2.new(.5,-4,1,0)

    return row
end

-- SISTEMA DE VOO

local function stopFly()
    S.fly = false
    S.vertical = 0

    if flyStep then
        flyStep:Disconnect()
        flyStep = nil
    end

    for _,p in ipairs(flyParts) do
        if p.Parent then p:Destroy() end
    end
    flyParts = {}

    if oldHum and oldHum.Parent then
        oldHum.AutoRotate = oldRotate ~= false
        oldHum.PlatformStand = oldStand == true
    end

    oldHum = nil
end

local function startFly()
    if S.fly then return true end

    local _,h,r = chars()

    if not h or not r or r.Anchored
        or h.Health <= 0 then

        notify("Personagem indisponivel")
        return false
    end

    oldHum = h
    oldRotate = h.AutoRotate
    oldStand = h.PlatformStand

    h.AutoRotate = false
    h.PlatformStand = true
    h.Sit = false

    local att = obj("Attachment",r)

    local vel = obj("LinearVelocity",r,{
        Attachment0 = att,
        RelativeTo = Enum.ActuatorRelativeTo.World,
        VelocityConstraintMode =
            Enum.VelocityConstraintMode.Vector,
        ForceLimitsEnabled = false,
        VectorVelocity = Vector3.zero
    })

    local orient = obj("AlignOrientation",r,{
        Attachment0 = att,
        Mode = Enum.OrientationAlignmentMode.OneAttachment,
        MaxTorque = 1e9,
        Responsiveness = 35
    })

    flyParts = {att,vel,orient}

    r.AssemblyLinearVelocity = Vector3.zero
    S.fly = true

    flyStep = Run.Heartbeat:Connect(function()
        if not r.Parent or h.Health <= 0 then
            stopFly()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local cf = camera.CFrame
        local forward = cf.LookVector
        local right = cf.RightVector

        if S.flat then
            forward = Vector3.new(
                forward.X,0,forward.Z
            )

            right = Vector3.new(
                right.X,0,right.Z
            )

            if forward.Magnitude > .001 then
                forward = forward.Unit
            end

            if right.Magnitude > .001 then
                right = right.Unit
            end
        end

        local d = Vector3.new(0,S.vertical,0)

        if not UIS:GetFocusedTextBox() then
            if UIS:IsKeyDown(Enum.KeyCode.W) then
                d = d+forward
            end

            if UIS:IsKeyDown(Enum.KeyCode.S) then
                d = d-forward
            end

            if UIS:IsKeyDown(Enum.KeyCode.A) then
                d = d-right
            end

            if UIS:IsKeyDown(Enum.KeyCode.D) then
                d = d+right
            end

            if UIS:IsKeyDown(Enum.KeyCode.Space)
                or UIS:IsKeyDown(Enum.KeyCode.E) then
                d = d+Vector3.yAxis
            end

            if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
                or UIS:IsKeyDown(Enum.KeyCode.Q) then
                d = d-Vector3.yAxis
            end
        end

        if d.Magnitude > 1 then
            d = d.Unit
        end

        vel.VectorVelocity =
            d*S.speed*(S.boost and S.boostX or 1)

        orient.CFrame = cf.Rotation
    end)

    return true
end

-- NOCLIP

local function setNoclip(value)
    S.noclip = value

    if noclipStep then
        noclipStep:Disconnect()
        noclipStep = nil
    end

    if value then
        noclipStep = Run.PreSimulation:Connect(function()
            local ch = player.Character
            if not ch then return end

            for _,p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then
                    if collisions[p] == nil then
                        collisions[p] = p.CanCollide
                    end
                    p.CanCollide = false
                end
            end
        end)
    else
        for p,value0 in pairs(collisions) do
            if p.Parent then
                pcall(function()
                    p.CanCollide = value0
                end)
            end
        end
        collisions = {}
    end
end

-- CONGELAR E DESCONGELAR

local function freeze(value)
    if value then
        local _,_,root = chars()
        if not root then return end

        stopFly()

        if not S.frozen then
            freezeRoot = root
            freezeOriginal = root.Anchored
        end

        root.Anchored = true
        S.frozen = true
    else
        if freezeRoot and freezeRoot.Parent then
            freezeRoot.Anchored = freezeOriginal == true
        end

        freezeRoot = nil
        S.frozen = false
    end
end

-- EFEITOS

local function glow(value)
    if glowEffect then
        glowEffect:Destroy()
        glowEffect = nil
    end

    S.glow = value

    if value then
        local ch = player.Character

        if ch then
            glowEffect = obj("Highlight",ch,{
                FillColor = accent,
                OutlineColor = accent,
                FillTransparency = .82
            })
        end
    end
end

local function trail(value)
    for _,v in ipairs(fxParts) do
        if v.Parent then v:Destroy() end
    end

    fxParts = {}
    S.trail = value

    if value then
        local _,_,root = chars()
        if not root then return end

        local a = obj("Attachment",root,{
            Position = Vector3.new(0,1,0)
        })

        local b = obj("Attachment",root,{
            Position = Vector3.new(0,-1,0)
        })

        local t = obj("Trail",root,{
            Attachment0 = a,
            Attachment1 = b,
            Lifetime = .45,
            Color = ColorSequence.new(accent),
            LightEmission = .7
        })

        fxParts = {a,b,t}
    end
end

local function transparency(value)
    local ch = player.Character
    if not ch then return end

    for _,part in ipairs(ch:GetDescendants()) do
        if part:IsA("BasePart")
            and part.Name ~= "HumanoidRootPart" then

            if transparent[part] == nil then
                transparent[part] =
                    part.LocalTransparencyModifier
            end

            part.LocalTransparencyModifier = value
        end
    end
end

local function resetTransparency()
    for p,v in pairs(transparent) do
        if p.Parent then
            p.LocalTransparencyModifier = v
        end
    end
    transparent = {}
end

local function remember(h)
    if originalHum ~= h then
        originalHum = h
        originalWalk = h.WalkSpeed
        originalJump = h.JumpPower
        originalJumpMode = h.UseJumpPower
    end
end

local function cameraReset()
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMinZoomDistance = .5
    player.CameraMaxZoomDistance = math.max(30,old.max)

    local camera = workspace.CurrentCamera
    local _,h = chars()

    if camera then
        camera.CameraType = Enum.CameraType.Custom

        if h then
            camera.CameraSubject = h
        end

        camera.FieldOfView = old.fov
    end
end

-- EMOTES CLASSICOS

local classics = {
    wave = {128777973,507770239},
    point = {128853357,507770453},
    cheer = {129423030,507770677},
    laugh = {129423131,507770818},
    dance = {182435998,507771019},
    dance2 = {182436842,507776043},
    dance3 = {182436935,507777268}
}

local joints = {}

local function stopEmote()
    if danceStep then
        danceStep:Disconnect()
        danceStep = nil
    end

    for _,m in pairs(joints) do
        if m.Parent then
            m.Transform = CFrame.new()
        end
    end

    joints = {}
    S.emote = nil

    if animTrack then
        pcall(function()
            animTrack:Stop(.1)
            animTrack:Destroy()
        end)

        animTrack = nil
    end
end

local function equippedEmotes()
    local _,h = chars()
    if not h then return {} end

    local ok,description = pcall(function()
        return h:GetAppliedDescription()
    end)

    if not ok or not description then
        return {}
    end

    local okay,emotes = pcall(function()
        return description:GetEmotes()
    end)

    return okay and type(emotes) == "table"
        and emotes or {}
end

local function playEmote(name)
    local _,h = chars()
    if not h then return false end

    stopFly()
    stopEmote()

    h.Sit = false
    h.PlatformStand = false

    local equipped = equippedEmotes()
    local proper

    for n in pairs(equipped) do
        if n:lower() == name:lower() then
            proper = n
            break
        end
    end

    if proper then
        task.spawn(function()
            local ok,result = pcall(function()
                return h:PlayEmoteAsync(proper)
            end)

            notify(
                ok and result and ("Emote: "..proper)
                or ("Emote indisponivel: "..proper)
            )
        end)

        return true
    end

    local idPair = classics[name:lower()]

    if not idPair then
        notify("Emote nao equipado: "..name)
        return false
    end

    local animator = h:FindFirstChildOfClass("Animator")

    if not animator then
        notify("Animator indisponivel")
        return false
    end

    local id =
        h.RigType == Enum.HumanoidRigType.R6
        and idPair[1] or idPair[2]

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..id

    local ok,track = pcall(function()
        return animator:LoadAnimation(anim)
    end)

    anim:Destroy()

    if not ok or not track then
        notify("Animacao nao autorizada")
        return false
    end

    animTrack = track
    track.Looped = name:find("dance") ~= nil
    track.Priority = Enum.AnimationPriority.Action

    track:Play(.12)
    return true
end

-- DANCAS ORIGINAIS PARA MOTOR6D

local moves = {
    groove = {4,.55,.2},
    samba = {7,.8,.4},
    robot = {3,1,.1},
    disco = {6,1,.45},
    shuffle = {9,.55,.35},
    bounce = {6,.4,.23},
    wave = {5,.2,.1},
    party = {10,1,.4},
    moonwalk = {5,.35,.22},
    sway = {3,.38,.55},
    jive = {9,.9,.35},
    zombie = {3,.5,.13}
}

local function originalMove(name)
    local style = moves[name]
    if not style then return false end

    local ch,h = chars()
    if not ch or not h then return false end

    stopFly()
    stopEmote()

    for _,m in ipairs(ch:GetDescendants()) do
        if m:IsA("Motor6D") then
            joints[m.Name:lower():gsub("[^%w]","")] = m
        end
    end

    if not joints.rightshoulder
        or not joints.leftshoulder then

        notify("Rig incompatível: use emotes autorizados")
        return false
    end

    S.emote = name

    local t = 0

    danceStep = Run.PreSimulation:Connect(function(dt)
        if not ch.Parent or h.Health <= 0 then
            stopEmote()
            return
        end

        t = t+math.min(dt,.05)*style[1]

        local a = math.sin(t)
        local b = math.cos(t)

        local poses = {
            rightshoulder =
                CFrame.Angles(-.5-style[2]*a,0,.15*b),

            leftshoulder =
                CFrame.Angles(-.5+style[2]*a,0,-.15*b),

            righthip =
                CFrame.Angles(style[3]*b,0,0),

            lefthip =
                CFrame.Angles(-style[3]*b,0,0),

            waist =
                CFrame.Angles(0,style[3]*a,0),

            neck =
                CFrame.Angles(.08*b,0,0)
        }

        for part,cf in pairs(poses) do
            local motor = joints[part]

            if motor and motor.Parent then
                motor.Transform = cf
            end
        end
    end)

    return true
end

-- AIM DE TREINAMENTO
-- NPCs precisam ter PracticeTarget = true

local aimCircle = round(obj("Frame",gui,{
    AnchorPoint = Vector2.new(.5,.5),
    Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(300,300),
    BackgroundTransparency = 1,
    Visible = false
}),999)

local aimStroke = obj("UIStroke",aimCircle,{
    Color = accent,
    Thickness = 1.5
})

local aimKey = "BRAB0X_V10_AIM"
local npcCache = {}
local nextScan = 0

local function findTarget(camera)
    if os.clock() > nextScan then
        npcCache = {}
        nextScan = os.clock()+2

        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model")
                and v:GetAttribute("PracticeTarget") == true then

                npcCache[#npcCache+1] = v
            end
        end
    end

    local best
    local dist = S.aimRadius

    for _,model in ipairs(npcCache) do
        if model.Parent then
            local h = model:FindFirstChildOfClass("Humanoid")

            local p = model:FindFirstChild("Head")
                or model:FindFirstChild("HumanoidRootPart")

            if h and h.Health > 0 and p then
                local point,visible =
                    camera:WorldToViewportPoint(p.Position)

                local d = (
                    Vector2.new(point.X,point.Y)
                    - camera.ViewportSize/2
                ).Magnitude

                if visible and point.Z > 0 and d < dist then
                    best = p
                    dist = d
                end
            end
        end
    end

    return best
end

Run:BindToRenderStep(
    aimKey,
    Enum.RenderPriority.Camera.Value+1,
    function(dt)
        if not S.aim
            or UIS:GetFocusedTextBox()
            or (
                S.aimHold
                and not UIS:IsMouseButtonPressed(
                    Enum.UserInputType.MouseButton2
                )
            ) then
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local p = findTarget(camera)

        if p then
            local desired = CFrame.lookAt(
                camera.CFrame.Position,
                p.Position
            )

            camera.CFrame = camera.CFrame:Lerp(
                desired,
                math.clamp(
                    1-(1-S.aimSmooth)^(
                        math.max(0,dt)*60
                    ),
                    0,1
                )
            )
        end
    end
)

-- RESET GERAL

local function resetAll()
    stopFly()
    setNoclip(false)
    stopEmote()
    glow(false)
    trail(false)
    freeze(false)
    resetTransparency()

    S.aim = false
    S.speed = 55
    S.boost = false
    S.flat = false
    S.vertical = 0

    fpsToggle(false)
    crosshair.Visible = false

    workspace.Gravity = old.gravity
    Lighting.ClockTime = old.clock
    Lighting.Brightness = old.brightness
    Lighting.FogEnd = old.fog

    cameraReset()

    if originalHum and originalHum.Parent then
        originalHum.WalkSpeed = originalWalk
        originalHum.JumpPower = originalJump
        originalHum.UseJumpPower = originalJumpMode
    end
end

-- REGISTRO DE COMANDOS

local registered = {}
local byName = {}

local function register(name,category,description,handler,example)
    local entry = {
        name = name,
        category = category,
        description = description,
        run = handler,
        example = example or name
    }

    registered[#registered+1] = entry
    byName[name] = entry
end

local function num(s,default,min,max)
    local n = tonumber(s)
    return math.clamp(n or default,min,max)
end

-- FLY

register("fly","FLY","Ligar voo",function()
    startFly()
end)

register("unfly","FLY","Desligar voo",stopFly)

register("toggle","FLY","Alternar voo",function()
    if S.fly then stopFly() else startFly() end
end)

register("speed","FLY","Velocidade de voo",function(a)
    S.speed = num(a,S.speed,10,300)
end,"speed 100")

register("faster","FLY","Aumentar velocidade",function()
    S.speed = math.min(300,S.speed+25)
end)

register("slower","FLY","Diminuir velocidade",function()
    S.speed = math.max(10,S.speed-25)
end)

register("boost","FLY","Ligar turbo",function()
    S.boost = true
end)

register("unboost","FLY","Desligar turbo",function()
    S.boost = false
end)

register("boostmult","FLY","Potencia turbo",function(a)
    S.boostX = num(a,2,1,5)
end,"boostmult 3")

register("flat","FLY","Voo horizontal",function()
    S.flat = true
end)

register("flight3d","FLY","Voo livre 3D",function()
    S.flat = false
end)

register("up","FLY","Subida continua",function()
    if startFly() then S.vertical = 1 end
end)

register("down","FLY","Descida continua",function()
    if startFly() then S.vertical = -1 end
end)

register("hover","FLY","Parar subida e descida",function()
    S.vertical = 0
end)

register("noclip","FLY","Desativar colisao local",function()
    setNoclip(true)
end)

register("clip","FLY","Restaurar colisao",function()
    setNoclip(false)
end)

-- JOGADOR

register("walk","PLAYER","Velocidade de caminhada",function(a)
    local _,h = chars()
    if h then
        remember(h)
        h.WalkSpeed = num(a,16,0,100)
    end
end,"walk 24")

register("resetwalk","PLAYER","Restaurar caminhada",function()
    if originalHum and originalHum.Parent then
        originalHum.WalkSpeed = originalWalk
    end
end)

register("jump","PLAYER","Forca do pulo",function(a)
    local _,h = chars()
    if h then
        remember(h)
        h.UseJumpPower = true
        h.JumpPower = num(a,50,0,200)
    end
end,"jump 75")

register("resetjump","PLAYER","Restaurar pulo",function()
    if originalHum and originalHum.Parent then
        originalHum.JumpPower = originalJump
        originalHum.UseJumpPower = originalJumpMode
    end
end)

register("sit","PLAYER","Sentar",function()
    stopFly()
    local _,h = chars()
    if h then h.Sit = true end
end)

register("unsit","PLAYER","Levantar",function()
    local _,h = chars()
    if h then h.Sit = false end
end)

register("freeze","PLAYER","Congelar",function()
    freeze(true)
end)

register("unfreeze","PLAYER","Descongelar",function()
    freeze(false)
end)

register("savepos","PLAYER","Guardar posicao",function()
    local _,_,r = chars()
    if r then S.saved = r.CFrame end
end)

register("returnpos","PLAYER","Voltar para posicao",function()
    local _,_,r = chars()

    if r and S.saved then
        freeze(false)
        r.CFrame = S.saved
        r.AssemblyLinearVelocity = Vector3.zero
    end
end)

register("coords","PLAYER","Coordenadas",function()
    local _,_,r = chars()
    if r then notify(tostring(r.Position)) end
end)

register("glow","PLAYER","Destaque no avatar",function()
    glow(true)
end)

register("unglow","PLAYER","Desligar destaque",function()
    glow(false)
end)

register("trail","PLAYER","Rastro neon",function()
    trail(true)
end)

register("untrail","PLAYER","Desligar rastro",function()
    trail(false)
end)

register("transparent","PLAYER","Transparencia local",function(a)
    transparency(num(a,.5,0,1))
end,"transparent 0.5")

register("visible","PLAYER","Restaurar visual",resetTransparency)

-- CAMERA

register("first","CAMERA","Primeira pessoa",function()
    player.CameraMode = Enum.CameraMode.LockFirstPerson
end)

register("third","CAMERA","Terceira pessoa",cameraReset)

register("camreset","CAMERA","Restaurar camera",cameraReset)

register("fov","CAMERA","Campo de visao",function(a)
    local c = workspace.CurrentCamera
    if c then c.FieldOfView = num(a,70,40,120) end
end,"fov 90")

register("resetfov","CAMERA","Restaurar FOV",function()
    local c = workspace.CurrentCamera
    if c then c.FieldOfView = old.fov end
end)

register("zoom","CAMERA","Distancia da camera",function(a)
    local n = num(a,15,2,100)
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMinZoomDistance = .5
    player.CameraMaxZoomDistance = n
end,"zoom 20")

register("resetzoom","CAMERA","Restaurar zoom",function()
    player.CameraMinZoomDistance = old.min
    player.CameraMaxZoomDistance = old.max
end)

-- MUNDO

register("day","WORLD","Horario dia",function()
    Lighting.ClockTime = 14
end)

register("night","WORLD","Horario noite",function()
    Lighting.ClockTime = 0
end)

register("sunset","WORLD","Fim de tarde",function()
    Lighting.ClockTime = 18.3
end)

register("time","WORLD","Mudar horario",function(a)
    Lighting.ClockTime = num(a,12,0,24)
end,"time 18")

register("resettime","WORLD","Restaurar horario",function()
    Lighting.ClockTime = old.clock
end)

register("gravity","WORLD","Gravidade local",function(a)
    workspace.Gravity = num(a,196.2,0,500)
end,"gravity 120")

register("resetgravity","WORLD","Restaurar gravidade",function()
    workspace.Gravity = old.gravity
end)

register("brightness","WORLD","Brilho local",function(a)
    Lighting.Brightness = num(a,2,0,10)
end,"brightness 3")

register("resetbrightness","WORLD","Restaurar brilho",function()
    Lighting.Brightness = old.brightness
end)

register("fog","WORLD","Distancia da neblina",function(a)
    Lighting.FogEnd = num(a,100,20,100000)
end,"fog 100")

register("clearfog","WORLD","Tirar neblina",function()
    Lighting.FogEnd = 100000
end)

register("resetfog","WORLD","Restaurar neblina",function()
    Lighting.FogEnd = old.fog
end)

-- AIM DE TREINO

register("aim","AIM","Aim NPC treino ON/OFF",function(a)
    S.aim = a == "on"
        or (a ~= "off" and not S.aim)
end,"aim on")

register("aimfov","AIM","Area do Aim",function(a)
    S.aimRadius = num(a,150,30,350)
end,"aimfov 180")

register("smooth","AIM","Suavidade do Aim",function(a)
    S.aimSmooth = num(a,.16,.02,1)
end,"smooth 0.2")

register("aimhold","AIM","Segurar RMB on/off",function()
    S.aimHold = not S.aimHold
end)

-- EMOTES

register("emotes","EMOTES","Abrir lista de emotes",function()
    show("EMOTES")
end)

register("emote","EMOTES","Executar emote equipado",function(a)
    playEmote(a)
end,"emote dance")

register("dance","EMOTES","Danca original Motor6D",function(a)
    originalMove(a)
end,"dance groove")

register("stopemote","EMOTES","Parar emote",stopEmote)

-- CONFIGURACOES

register("theme","SETTINGS","Cor neon",function(a)
    if palette[a] then
        config.theme = a
        accent = palette[a]

        stroke.Color = accent
        aimStroke.Color = accent
        fpsLabel.TextColor3 = accent
        crosshair.TextColor3 = accent

        for _,p in pairs(pages) do
            p.ScrollBarImageColor3 = accent
        end

        if glowEffect then
            glowEffect.OutlineColor = accent
            glowEffect.FillColor = accent
        end

        show(selected)
    end
end,"theme ice")

register("scale","SETTINGS","Tamanho do painel",function(a)
    config.scale = num(a,1,.6,1.25)
    responsive()
end,"scale 0.8")

register("lang","SETTINGS","Idioma do menu",function(a)
    if L[a] then
        config.lang = a
        relabel()
    end
end,"lang en")

register("status","SETTINGS","Mostrar status",function()
    notify(
        "Fly "..tostring(S.fly)
        .." | Speed "..S.speed
        .." | Aim "..tostring(S.aim)
    )
end)

register("help","SETTINGS","Abrir lista",function()
    show("COMMANDS")
end)

register("hide","SETTINGS","Esconder menu",function()
    main.Visible = false
    reopen.Visible = true
end)

register("show","SETTINGS","Mostrar menu",function()
    main.Visible = true
    reopen.Visible = false
end)

register("resetall","SETTINGS","Restaurar tudo",resetAll)

register("close","SETTINGS","Fechar hub",function()
    if closeHub then closeHub() end
end)

-- COMANDOS EXTRAS

register("speedreset","FLY","Velocidade padrao 55",function()
    S.speed = 55
end)

register("flystatus","FLY","Estado do voo",function()
    notify(
        "Fly "..tostring(S.fly).." | speed "..S.speed
    )
end)

register("aimcircle","AIM","Circulo do Aim",function(a)
    if a == "on" then
        S.aimCircle = true
    elseif a == "off" then
        S.aimCircle = false
    else
        S.aimCircle = not S.aimCircle
    end
end,"aimcircle on")

register("aimholdmode","AIM","Mira pressionada ou continua",function(a)
    if a == "on" then
        S.aimHold = true
    elseif a == "off" then
        S.aimHold = false
    else
        S.aimHold = not S.aimHold
    end
end,"aimholdmode on")

register("crosshair","CAMERA","Mostrar mira visual",function(a)
    if a == "on" then
        crosshair.Visible = true
    elseif a == "off" then
        crosshair.Visible = false
    else
        crosshair.Visible = not crosshair.Visible
    end
end,"crosshair on")

register("fps","SETTINGS","Contador de FPS",function(a)
    fpsToggle(
        a == "on"
        or (a ~= "off" and not fpsLabel.Visible)
    )
end,"fps on")

register("emotewheel","EMOTES","Abrir roda oficial",function()
    local ok = pcall(function()
        GuiService:SetEmotesMenuOpen(true)
    end)

    if not ok then
        notify("Roda de emotes indisponivel")
    end
end)

register("modules","SETTINGS","Escolher categorias",function()
    if openModulePicker then openModulePicker() end
end)

register("aimmodule","SETTINGS","Exibir a aba AIM de treino",function(a)
    if a == "on" then
        config.aimEnabled = true
    elseif a == "off" then
        config.aimEnabled = false
        S.aim = false
    else
        config.aimEnabled = not config.aimEnabled
        if not config.aimEnabled then S.aim = false end
    end
    if not config.aimEnabled and selected == "AIM" then
        show("COMMANDS")
    else
        show(selected)
    end
    if refreshCommandList then refreshCommandList() end
end,"aimmodule on")

-- EXECUTAR COMANDO

exec = function(raw)
    local command,arg = tostring(raw):match(
        "^%s*/?(%S+)%s*(.-)%s*$"
    )

    if not command then return end
    command = command:lower()

    local entry = byName[command]

    if not entry then
        notify("Comando desconhecido: "..command)
        return
    end

    if not moduleEnabled(entry.category) then
        notify(
            "Ative a categoria "..entry.category
            .." em Ajustes > Modulos"
        )
        return
    end

    local ok,err = pcall(entry.run,arg)

    if not ok then
        notify("Erro em "..command..": "..tostring(err))
        return
    end

    if stopped then return end
    if command ~= "coords"
        and command ~= "status" then
        notify("OK: "..raw)
    end

    refresh()
end

-- ABA DE COMANDOS

local cmdPage = pages.COMMANDS

local search = round(obj("TextBox",cmdPage,{
    Size = UDim2.new(1,-10,0,35),
    BackgroundColor3 = control,
    Text = "",
    PlaceholderText = "Buscar comandos: fly, zoom, emote...",
    TextColor3 = white,
    PlaceholderColor3 = muted,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    TextSize = 13
}),8)

local filterRow = obj("Frame",cmdPage,{
    Size = UDim2.new(1,-8,0,36),
    BackgroundTransparency = 1
})
obj("UIListLayout",filterRow,{
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0,5),
    SortOrder = Enum.SortOrder.LayoutOrder
})
local activeFilter = "ALL"
local filters = {
    {"ALL","TODOS"},{"FLY","VOO"},{"PLAYER","JOGADOR"},
    {"CAMERA","CAMERA"},{"WORLD","MUNDO"},{"EMOTES","EMOTES"}
}
local filterButtons = {}
for _,entry in ipairs(filters) do
    local b = btn(filterRow,entry[2],nil,33)
    b.Size = UDim2.new(1/6,-5,0,33)
    filterButtons[entry[1]] = b
    bind(b.MouseButton1Click,function()
        activeFilter = entry[1]
        if refreshCommandList then refreshCommandList() end
    end)
end

local commandGrid = obj("Frame",cmdPage,{
    Size = UDim2.new(1,-8,0,0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1
})
local commandLayout = obj("UIGridLayout",commandGrid,{
    CellSize = UDim2.new(.5,-5,0,46),
    CellPadding = UDim2.fromOffset(9,8),
    SortOrder = Enum.SortOrder.LayoutOrder
})
local function sizeCommands()
    commandGrid.Size = UDim2.new(1,-8,0,commandLayout.AbsoluteContentSize.Y+12)
end
bind(commandLayout:GetPropertyChangedSignal("AbsoluteContentSize"),sizeCommands)
local commandRows = {}

for _,entry in ipairs(registered) do
    local b = btn(
        commandGrid,
        "["..entry.category.."]  "..entry.example.."  •  "..entry.description,
        function()
            exec(entry.example)
        end,
        42
    )
    b.TextXAlignment = Enum.TextXAlignment.Center

    commandRows[#commandRows+1] = {
        b = b,
        category = entry.category,
        lookup = (
            entry.name.." "
            ..entry.description.." "
            ..entry.category
        ):lower()
    }
end

refreshCommandList = function()
    local textQuery = search.Text:lower()
    for _,v in ipairs(commandRows) do
        v.b.Visible = moduleEnabled(v.category)
            and (activeFilter == "ALL" or v.category == activeFilter)
            and (textQuery == "" or v.lookup:find(textQuery,1,true) ~= nil)
    end
    for name,b in pairs(filterButtons) do
        local active = name == activeFilter
        b.BackgroundColor3 = active and accent or control
        b.TextColor3 = active and ink or white
    end
    sizeCommands()
end

bind(
    search:GetPropertyChangedSignal("Text"),
    refreshCommandList
)

-- HOME

local hero = round(obj("Frame",pages.HOME,{
    Size = UDim2.new(1,-9,0,174),
    BackgroundColor3 = Color3.fromRGB(8,36,58),
    BorderSizePixel = 0
}),14)
obj("UIGradient",hero,{
    Rotation = 12,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(5,34,57)),
        ColorSequenceKeypoint.new(.55,Color3.fromRGB(11,74,101)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(2,16,34))
    })
})
obj("UIStroke",hero,{Color=accent,Transparency=.35,Thickness=1.3})
round(obj("Frame",hero,{
    Position = UDim2.fromOffset(18,20),
    Size = UDim2.fromOffset(5,112),
    BackgroundColor3 = accent,
    BorderSizePixel = 0
}),3)
local code = txt(hero,"B",156,160,true)
code.Position = UDim2.new(1,-180,0,-13)
code.Size = UDim2.fromOffset(160,162)
code.TextColor3 = accent
code.TextTransparency = .84
code.TextXAlignment = Enum.TextXAlignment.Center
local bannerBrand = txt(hero,"BRAB0X PRIME",51,32,true)
bannerBrand.Position = UDim2.fromOffset(38,18)
bannerBrand.Size = UDim2.new(1,-75,0,52)
local bannerSub = txt(hero,"CONTROL CENTER  /  BLUE EDITION",26,13,true)
bannerSub.Position = UDim2.fromOffset(41,70)
bannerSub.Size = UDim2.new(1,-70,0,24)
bannerSub.TextColor3 = accent
local bannerDesc = txt(hero,"VOO  •  AVATAR  •  CAMERA  •  EMOTES  •  AIM OPCIONAL",42,12)
bannerDesc.Position = UDim2.fromOffset(41,102)
bannerDesc.Size = UDim2.new(1,-75,0,38)
bannerDesc.TextColor3 = white
local bannerTag = round(obj("TextLabel",hero,{
    Position = UDim2.new(1,-110,0,13),
    Size = UDim2.fromOffset(87,26),
    BackgroundColor3 = Color3.fromRGB(4,22,36),
    Text = "V10  /  ON",
    TextColor3 = accent,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}),9)

local live = titleRow(
    pages.HOME,
    "Fly OFF • Speed 55 • Aim OFF"
)

titleRow(
    pages.HOME,
    "ATALHOS  •  F = VOAR  |  RightShift = MENU  |  Ctrl+K = BUSCAR"
)

item(pages.HOME,"ABRIR COMANDOS","help")
item(pages.HOME,"ABRIR EMOTES","emotes")
item(pages.HOME,"CONFIGURAR ABA AIM","modules")

-- ABA FLY

titleRow(pages.FLY,"CONTROLE DE VOO")

line(
    pages.FLY,
    "FLY ON",
    function() exec("fly") end,
    "FLY OFF",
    function() exec("unfly") end
)

line(
    pages.FLY,
    "SPEED -",
    function() exec("slower") end,
    "SPEED +",
    function() exec("faster") end
)

line(
    pages.FLY,
    "BOOST",
    function()
        exec(S.boost and "unboost" or "boost")
    end,
    "NOCLIP",
    function()
        exec(S.noclip and "clip" or "noclip")
    end
)

for _,c in ipairs({
    "speed 50","speed 100","speed 150",
    "flat","flight3d","up","down","hover","clip"
}) do
    item(pages.FLY,c,c)
end

-- ABA JOGADOR

for _,c in ipairs({
    "walk 24","walk 32","resetwalk",
    "jump 75","resetjump","sit","unsit",
    "freeze","unfreeze","savepos","returnpos",
    "coords","glow","unglow","trail","untrail",
    "transparent 0.5","visible"
}) do
    item(pages.PLAYER,c,c)
end

-- ABA CAMERA

for _,c in ipairs({
    "first","third","camreset",
    "fov 60","fov 90","resetfov",
    "zoom 10","zoom 30","resetzoom",
    "crosshair on","crosshair off"
}) do
    item(pages.CAMERA,c,c)
end

-- ABA MUNDO

for _,c in ipairs({
    "day","night","sunset","time 9",
    "resettime","gravity 120","resetgravity",
    "brightness 3","resetbrightness",
    "fog 100","clearfog","resetfog"
}) do
    item(pages.WORLD,c,c)
end

-- ABA EMOTES

local emotesPage = pages.EMOTES

local function rebuildEmotes()
    clear(emotesPage)

    titleRow(
        emotesPage,
        "EMOTES EQUIPADOS NO AVATAR"
    )

    local names = {}

    for name in pairs(equippedEmotes()) do
        names[#names+1] = name
    end

    table.sort(names)

    if #names == 0 then
        local l = txt(
            emotesPage,
            "Nao ha emotes extras no avatar atual.",
            39,12
        )

        l.TextColor3 = muted
    end

    for _,name in ipairs(names) do
        btn(emotesPage,"▶ "..name,function()
            playEmote(name)
        end)
    end

    titleRow(
        emotesPage,
        "EMOTES CLASSICOS (SE PERMITIDOS)"
    )

    for _,name in ipairs({
        "wave","point","cheer","laugh",
        "dance","dance2","dance3"
    }) do
        btn(emotesPage,"▶ "..name,function()
            playEmote(name)
        end)
    end

    titleRow(
        emotesPage,
        "DANCAS ORIGINAIS (RIG MOTOR6D)"
    )

    for _,name in ipairs({
        "groove","samba","robot","disco",
        "shuffle","bounce","wave","party",
        "moonwalk","sway","jive","zombie"
    }) do
        btn(emotesPage,"♫ "..name,function()
            if originalMove(name) then
                notify("Danca: "..name)
            end
        end)
    end

    btn(emotesPage,"PARAR EMOTE",stopEmote)

    btn(
        emotesPage,
        "ATUALIZAR EMOTES",
        rebuildEmotes
    )

    titleRow(
        emotesPage,
        "CATALOGO ROBLOX"
    )

    local query = round(obj("TextBox",emotesPage,{
        Size = UDim2.new(1,-10,0,34),
        BackgroundColor3 = control,
        Text = "Jamal",
        TextColor3 = white,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        ClearTextOnFocus = false
    }),7)

    local results = obj("Frame",emotesPage,{
        Size = UDim2.new(1,-10,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    })

    stack(results,5)

    local pagesFound
    local catalogBusy = false

    local function renderCatalog(items)
        for _,info in ipairs(items) do
            local id = tonumber(info.Id)
            local name = tostring(info.Name or "Emote")

            if id then
                btn(
                    results,
                    name.." ["..id.."]",
                    function()
                        for equipped,ids in pairs(
                            equippedEmotes()
                        ) do
                            if type(ids) == "table" then
                                for _,ownedID in ipairs(ids) do
                                    if tonumber(ownedID) == id then
                                        playEmote(equipped)
                                        return
                                    end
                                end
                            end
                        end

                        notify(
                            "O emote "..name..
                            " precisa estar equipado e autorizado"
                        )
                    end
                )
            end
        end
    end

    btn(
        emotesPage,
        "PESQUISAR CATALOGO",
        function()
            if catalogBusy then return end

            catalogBusy = true
            clear(results)
            pagesFound = nil

            task.spawn(function()
                local ok,p = pcall(function()
                    local options = CatalogSearchParams.new()
                    options.SearchKeyword = query.Text
                    options.AssetTypes = {
                        Enum.AvatarAssetType.EmoteAnimation
                    }
                    options.Limit = 30

                    return Avatar:SearchCatalogAsync(options)
                end)

                if ok and p then
                    pagesFound = p

                    local ok2,items = pcall(function()
                        return p:GetCurrentPage()
                    end)

                    if ok2 then
                        renderCatalog(items)
                        notify("Catalogo carregado")
                    else
                        notify("Falha ao ler catalogo")
                    end
                else
                    notify("Busca indisponivel neste jogo")
                end

                catalogBusy = false
            end)
        end
    )

    btn(
        emotesPage,
        "CARREGAR MAIS RESULTADOS",
        function()
            if catalogBusy or not pagesFound then
                return
            end

            if pagesFound.IsFinished then
                notify("Fim dos resultados")
                return
            end

            catalogBusy = true

            task.spawn(function()
                local ok = pcall(function()
                    pagesFound:AdvanceToNextPageAsync()
                end)

                if ok then
                    local ok2,items = pcall(function()
                        return pagesFound:GetCurrentPage()
                    end)

                    if ok2 then
                        renderCatalog(items)
                    end
                else
                    notify("Falha ao carregar mais")
                end

                catalogBusy = false
            end)
        end
    )
end

-- ABA AIM

local aimTitle = titleRow(
    pages.AIM,
    "AIM PARA NPCs DE TREINO: OFF"
)

line(
    pages.AIM,
    "AIM ON",
    function() exec("aim on") end,
    "AIM OFF",
    function() exec("aim off") end
)

line(
    pages.AIM,
    "FOV -",
    function()
        exec("aimfov "..(S.aimRadius-25))
    end,
    "FOV +",
    function()
        exec("aimfov "..(S.aimRadius+25))
    end
)

line(
    pages.AIM,
    "SMOOTH -",
    function()
        exec("smooth "..(S.aimSmooth-.04))
    end,
    "SMOOTH +",
    function()
        exec("smooth "..(S.aimSmooth+.04))
    end
)

item(pages.AIM,"ALTERNAR RMB","aimhold")
item(pages.AIM,"CIRCULO DA MIRA ON","aimcircle on")
item(pages.AIM,"CIRCULO DA MIRA OFF","aimcircle off")

local aimExplain = txt(
    pages.AIM,
    "Requer NPC com atributo PracticeTarget=true. Nao mira em outros jogadores.",
    48,12
)

aimExplain.TextColor3 = muted

-- ABA CONFIGURACOES

local settingLabel = titleRow(
    pages.SETTINGS,
    "TAMANHO: 100%"
)

line(
    pages.SETTINGS,
    "MENOR",
    function()
        exec("scale "..(config.scale-.1))
    end,
    "MAIOR",
    function()
        exec("scale "..(config.scale+.1))
    end
)

for _,theme in ipairs({
    "blue","cyan","teal","whiteblue"
}) do
    item(
        pages.SETTINGS,
        "Tema "..theme,
        "theme "..theme
    )
end

titleRow(
    pages.SETTINGS,
    "IDIOMAS DO MENU"
)

for _,lang in ipairs({
    "pt","en","es","fr","de","it",
    "ja","ko","zh","ru","tr","id"
}) do
    item(
        pages.SETTINGS,
        "Idioma: "..lang,
        "lang "..lang
    )
end

item(
    pages.SETTINGS,
    "CONFIGURAR ABA AIM",
    "modules"
)

item(pages.SETTINGS,"MOSTRAR ABA AIM","aimmodule on")
item(pages.SETTINGS,"OCULTAR ABA AIM","aimmodule off")

item(pages.SETTINGS,"FPS ON","fps on")
item(pages.SETTINGS,"FPS OFF","fps off")
item(pages.SETTINGS,"RESETAR","resetall")
item(pages.SETTINGS,"FECHAR HUB","close")

-- ATUALIZAR MENU

refresh = function()
    live.Text = (
        "FLY %s • SPEED %d • AIM %s • EMOTE %s"
    ):format(
        S.fly and "ON" or "OFF",
        S.speed,
        S.aim and "ON" or "OFF",
        S.emote or "-"
    )

    topState.Text =
        S.fly and "● FLY ATIVO" or "○ FLY OFF"

    aimTitle.Text = (
        "AIM TREINO %s • FOV %d • SMOOTH %.2f"
    ):format(
        S.aim and "ON" or "OFF",
        S.aimRadius,
        S.aimSmooth
    )

    settingLabel.Text =
        "TAMANHO: "..
        math.floor(config.scale*100+.5).."%"

    aimCircle.Size = UDim2.fromOffset(
        S.aimRadius*2,
        S.aimRadius*2
    )

    aimCircle.Visible = config.aimEnabled and S.aim and S.aimCircle
end

-- EXECUCAO PELO CAMPO DE TEXTO

bind(execute.MouseButton1Click,function()
    if cmdInput.Text ~= "" then
        exec(cmdInput.Text)
        cmdInput.Text = ""
    end
end)

bind(cmdInput.FocusLost,function(enter)
    if enter and cmdInput.Text ~= "" then
        exec(cmdInput.Text)
        cmdInput.Text = ""
    end
end)

-- MINIMIZAR

bind(minimize.MouseButton1Click,function()
    main.Visible = false
    reopen.Visible = true
end)

bind(reopen.MouseButton1Click,function()
    main.Visible = true
    reopen.Visible = false
end)

-- ENCERRAMENTO

closeHub = function()
    if stopped then return end

    resetAll()
    stopped = true

    Run:UnbindFromRenderStep(aimKey)

    for _,c in ipairs(connections) do
        c:Disconnect()
    end

    gui:Destroy()

    if _G.BRAB0X_V10_STOP == closeHub then
        _G.BRAB0X_V10_STOP = nil
    end
end

bind(close.MouseButton1Click,closeHub)

-- ATALHOS

bind(UIS.InputBegan,function(key,used)
    if UIS:GetFocusedTextBox() then return end

    if key.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
        reopen.Visible = not main.Visible

    elseif key.KeyCode == Enum.KeyCode.F
        and not used then

        exec("toggle")

    elseif key.KeyCode == Enum.KeyCode.K
        and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then

        main.Visible = true
        reopen.Visible = false

        show("COMMANDS")
        search:CaptureFocus()
    end
end)

-- ARRASTAR MENU

local dragging = false
local startAt
local was

bind(header.InputBegan,function(k)
    if k.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        dragging = true
        startAt = k.Position
        was = main.Position
    end
end)

bind(UIS.InputChanged,function(k)
    if dragging and k.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local d = k.Position-startAt

        main.Position = UDim2.new(
            was.X.Scale,
            was.X.Offset+d.X,
            was.Y.Scale,
            was.Y.Offset+d.Y
        )
    end
end)

bind(UIS.InputEnded,function(k)
    if k.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        dragging = false
    end
end)

-- RESPAWN

bind(player.CharacterRemoving,function()
    stopFly()
    setNoclip(false)
    stopEmote()
    glow(false)
    trail(false)
    freeze(false)
    resetTransparency()
end)

_G.BRAB0X_V10_STOP = closeHub

-- ABERTURA ANIMADA

local gate = obj("Frame",gui,{
    Size = UDim2.fromScale(1,1),
    Position = UDim2.fromScale(0,0),
    BackgroundColor3 = ink,
    BackgroundTransparency = .42,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 50
})

local splash = round(obj("Frame",gate,{
    AnchorPoint = Vector2.new(.5,.5),
    Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(410,180),
    BackgroundColor3 = card,
    BorderSizePixel = 0,
    ZIndex = 51
}),15)

obj("UIStroke",splash,{
    Color = accent,
    Thickness = 2,
    Transparency = .25
})

local logo = txt(
    splash,"BRAB0X PRIME",45,27,true
)

logo.Position = UDim2.fromOffset(32,27)
logo.Size = UDim2.fromOffset(354,46)
logo.TextTransparency = 1
logo.ZIndex = 52
logo.TextXAlignment = Enum.TextXAlignment.Center

local splashSubtitle = txt(
    splash,"BLUE EDITION  •  CARREGANDO PAINEL",25,13
)

splashSubtitle.Position = UDim2.fromOffset(40,83)
splashSubtitle.Size = UDim2.fromOffset(330,28)
splashSubtitle.TextXAlignment = Enum.TextXAlignment.Center
splashSubtitle.TextColor3 = muted
splashSubtitle.ZIndex = 52

local progressBG = round(obj("Frame",splash,{
    Size = UDim2.fromOffset(330,8),
    Position = UDim2.fromOffset(40,142),
    BackgroundColor3 = control,
    BorderSizePixel = 0,
    ZIndex = 52
}),6)

local progress = round(obj("Frame",progressBG,{
    Size = UDim2.fromScale(0,1),
    BackgroundColor3 = accent,
    BorderSizePixel = 0,
    ZIndex = 53
}),6)

-- ESCOLHA DO AIM (OS DEMAIS COMANDOS ESTAO SEMPRE DISPONIVEIS)
local picker = round(obj("Frame",gate,{
    AnchorPoint = Vector2.new(.5,.5),
    Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(565,360),
    BackgroundColor3 = card,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 55
}),16)
obj("UIStroke",picker,{Color=accent,Thickness=1.7,Transparency=.12})
obj("Frame",picker,{
    Size = UDim2.new(1,0,0,4),
    BackgroundColor3 = accent,
    BorderSizePixel = 0,
    ZIndex = 56
})
local pickerTitle = txt(picker,"BRAB0X PRIME  /  MODO DE INICIO",36,22,true)
pickerTitle.Position = UDim2.fromOffset(24,18)
pickerTitle.Size = UDim2.fromOffset(510,34)
pickerTitle.ZIndex = 57
local pickerSubtitle = txt(picker,
    "Todos os comandos ficam juntos. Escolha apenas se quer AIM de treino.",
    38,12)
pickerSubtitle.Position = UDim2.fromOffset(24,61)
pickerSubtitle.Size = UDim2.fromOffset(520,36)
pickerSubtitle.TextColor3 = muted
pickerSubtitle.ZIndex = 57

local selectedAim = false
local function choiceCard(x,title,description)
    local b = btn(picker,"",nil,132)
    b.Position = UDim2.fromOffset(x,119)
    b.Size = UDim2.fromOffset(247,132)
    b.ZIndex = 57
    local head = txt(b,title,29,16,true)
    head.Position = UDim2.fromOffset(16,20)
    head.Size = UDim2.fromOffset(216,29)
    head.ZIndex = 58
    local sub = txt(b,description,61,12)
    sub.Position = UDim2.fromOffset(16,58)
    sub.Size = UDim2.fromOffset(214,62)
    sub.ZIndex = 58
    return b,head,sub
end
local commonCard,commonTitle,commonDesc = choiceCard(24,
    "MODO CLASSICO", "Voo, jogador, camera, mundo e emotes. Sem a aba AIM.")
local aimCard,aimTitleCard,aimDescCard = choiceCard(294,
    "AIM DE TREINO", "Os mesmos comandos, com uma aba AIM exclusiva para NPCs de treino.")

local function updateChoices()
    for _,it in ipairs({
        {commonCard,commonTitle,commonDesc,not selectedAim},
        {aimCard,aimTitleCard,aimDescCard,selectedAim}
    }) do
        it[1].BackgroundColor3 = it[4] and accent or control
        it[2].TextColor3 = it[4] and ink or white
        it[3].TextColor3 = it[4] and ink or muted
    end
end
bind(commonCard.MouseButton1Click,function()
    selectedAim = false
    updateChoices()
end)
bind(aimCard.MouseButton1Click,function()
    selectedAim = true
    updateChoices()
end)
local launch = btn(picker,"ENTRAR NO BRAB0X PRIME",nil,45)
launch.Position = UDim2.fromOffset(24,270)
launch.Size = UDim2.fromOffset(517,45)
launch.BackgroundColor3 = accent
launch.TextColor3 = ink
launch.ZIndex = 58
local note = txt(picker,"Voce pode mudar essa escolha em Ajustes > Configurar AIM.",24,11)
note.Position = UDim2.fromOffset(25,324)
note.Size = UDim2.fromOffset(515,24)
note.TextColor3 = muted
note.ZIndex = 57

openModulePicker = function()
    if stopped then return end
    selectedAim = config.aimEnabled == true
    updateChoices()
    gate.Visible = true
    picker.Visible = true
    splash.Visible = false
    main.Visible = false
    reopen.Visible = false
end

bind(launch.MouseButton1Click,function()
    config.aimEnabled = selectedAim
    if not selectedAim then S.aim = false end
    gate.Visible = false
    main.Visible = true
    reopen.Visible = false
    show("HOME")
    if refreshCommandList then refreshCommandList() end
    if refresh then refresh() end
    notify("BRAB0X V10 pronto! AIM: "..(selectedAim and "ATIVO" or "OCULTO"))
end)

-- ANIMACAO DE CARREGAMENTO

task.spawn(function()
    if stopped or not splash.Parent then return end

    Tween:Create(
        logo,
        TweenInfo.new(
            .48,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {TextTransparency=0}
    ):Play()

    Tween:Create(
        progress,
        TweenInfo.new(
            1.12,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {Size=UDim2.fromScale(1,1)}
    ):Play()

    task.wait(1.2)

    if not stopped and gate.Parent then
        openModulePicker()
    end
end)

-- INICIALIZAR

rebuildEmotes()
relabel()
show("HOME")
refresh()

if refreshCommandList then
    refreshCommandList()
end

notify(
    "BRAB0X PRIME V10 | "
    ..#registered.." comandos"
)
