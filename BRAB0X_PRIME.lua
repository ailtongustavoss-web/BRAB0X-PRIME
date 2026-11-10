
-- BRAB0X PRIME V13 | PREMIUM MANAGER + 8 MODULOS
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
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
if not player then return end

local pg = player:WaitForChild("PlayerGui")

-- LIMPEZA DE VERSOES ANTIGAS

for _, name in ipairs({
    "BRAB0X_V13_STOP",
    "BRAB0X_V12_STOP",
    "BRAB0X_V11_STOP",
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

local previous = pg:FindFirstChild("BRAB0X_PRIME_V13")
if previous then previous:Destroy() end

-- CONFIGURACOES

local config = _G.BRAB0X_PRIME_PREFS or {}
config.scale = tonumber(config.scale) or 1
config.lang = config.lang or "pt"
-- Preferencia visual: vermelho neon sempre que a versao anterior era azul.
if config.theme == nil or config.theme == "blue" or config.theme == "cyan"
    or config.theme == "teal" or config.theme == "whiteblue"
    or config.theme == "violet" or config.theme == "rose" then
    config.theme = "red"
end
if config.aimEnabled == nil then
    config.aimEnabled = false
end
_G.BRAB0X_PRIME_PREFS = config

-- Preferencias locais em JSON quando o ambiente permite ler e gravar arquivos.
local dataFile="BRAB0X_PRIME_V13_PREFS.json"
local v13Data=_G.BRAB0X_V13_DATA
if type(v13Data)~="table" then v13Data={} end
if type(readfile)=="function" then
    local ok,raw=pcall(readfile,dataFile)
    if ok and type(raw)=="string" and #raw<150000 then
        local ok2,parsed=pcall(function() return HttpService:JSONDecode(raw) end)
        if ok2 and type(parsed)=="table" then v13Data=parsed end
    end
end
for _,field in ipairs({"favorites","keybinds","profiles","waypoints"}) do
    if type(v13Data[field])~="table" then v13Data[field]={} end
end
if type(v13Data.preferences)=="table" then
    for _,key in ipairs({"theme","lang","scale","aimEnabled","compact","animations","opacity","neon"}) do
        if v13Data.preferences[key]~=nil then config[key]=v13Data.preferences[key] end
    end
end
config.theme=type(config.theme)=="string" and config.theme or "red"
config.scale=math.clamp(tonumber(config.scale) or 1,.6,1.25)
config.compact=config.compact==true
config.animations=config.animations~=false
config.opacity=math.clamp(tonumber(config.opacity) or 0,0,.45)
config.neon=math.clamp(tonumber(config.neon) or 1,.25,2)
local defaultKeys={FLY="F",MENU="RightShift",NOCLIP="N",BOOST="B",INVIS="I"}
for name,key in pairs(defaultKeys) do
    if type(v13Data.keybinds[name])~="string" then v13Data.keybinds[name]=key end
end
_G.BRAB0X_V13_DATA=v13Data
local function saveV13()
    v13Data.preferences={
        theme=config.theme,scale=config.scale,lang=config.lang,
        aimEnabled=config.aimEnabled,compact=config.compact,
        animations=config.animations,opacity=config.opacity,neon=config.neon
    }
    if type(writefile)=="function" then
        pcall(function() writefile(dataFile,HttpService:JSONEncode(v13Data)) end)
    end
end
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
    emote = nil,
    invisible = false,
    infJump = false,
    spinning = false,
    spinSpeed = 5,
    noRotate = false,
    fullbright = false
}

local palette = {
    red = Color3.fromRGB(238,36,58),
    crimson = Color3.fromRGB(195,22,41),
    ember = Color3.fromRGB(255,87,55),
    ruby = Color3.fromRGB(255,66,97)
}
local ink = Color3.fromRGB(6,6,9)
local card = Color3.fromRGB(13,12,18)
local control = Color3.fromRGB(27,24,32)
local white = Color3.fromRGB(247,245,249)
local muted = Color3.fromRGB(164,155,166)
local accent = palette[config.theme] or palette.red

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
    obj("UIStroke",b,{
        Color = Color3.fromRGB(88,38,45),
        Transparency = .56,
        Thickness = 1
    })
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
    "HOME","FLY","PLAYER","CAMERA","WORLD","EMOTES",
    "AIM","SETTINGS","COMMANDS","PLAYERS","FAVORITES",
    "TELEPORT","CONSOLE","PROFILES","PERFORMANCE"
}

-- A unica categoria opcional e AIM; todas as outras permanecem juntas.
local navOrder = {"HOME","COMMANDS","PLAYERS","FAVORITES","TELEPORT","CONSOLE","PROFILES","PERFORMANCE","SETTINGS","AIM"}
local function moduleEnabled(name)
    return name ~= "AIM" or config.aimEnabled == true
end

local openModulePicker
local refreshCommandList
local refreshV13Page
local v13Log
local addHistory
local updatePlayerManager
local updateFavoritePanel
local updateTeleportPanel
local updateProfilePanel
local updateConsolePanel

-- JANELA PRINCIPAL

local gui = obj("ScreenGui",pg,{
    Name = "BRAB0X_PRIME_V13",
    ResetOnSpawn = false,
    DisplayOrder = 100
})

local main = round(obj("Frame",gui,{
    Size = UDim2.fromOffset(960,625),
    Position = UDim2.new(.5,-480,.5,-312),
    BackgroundColor3 = ink,
    BorderSizePixel = 0,
    Active = true,
    Visible = false
}),15)

local stroke = obj("UIStroke",main,{
    Color = accent,
    Thickness = 1.9,
    Transparency = .08
})

local uiScale = obj("UIScale",main,{Scale=1})

local header = obj("Frame",main,{
    Size = UDim2.new(1,0,0,69),
    BackgroundColor3 = card,
    BorderSizePixel = 0,
    Active = true
})

round(header,15)

obj("UIGradient",header,{
    Color = ColorSequence.new(
        card,Color3.fromRGB(65,12,22)
    )
})

local brand = txt(
    header,"♛  BRAB0X  PRIME",38,25,true
)
brand.Position = UDim2.fromOffset(19,4)
brand.Size = UDim2.fromOffset(390,38)

local sub = txt(
    header,
    "V13  •  RED NEON EDITION    /    PREMIUM CONTROL CENTER",
    16,10
)
sub.TextColor3 = muted
sub.Position = UDim2.fromOffset(25,43)
sub.Size = UDim2.fromOffset(520,17)

local topState = txt(header,"FLY OFF",23,12,true)
topState.TextColor3 = accent
topState.TextXAlignment = Enum.TextXAlignment.Right
topState.Position = UDim2.new(1,-280,0,22)
topState.Size = UDim2.fromOffset(171,23)

local minimize = btn(header,"—",nil,30)
minimize.Size = UDim2.fromOffset(31,30)
minimize.Position = UDim2.new(1,-78,0,19)

local close = btn(header,"×",nil,30)
close.Size = UDim2.fromOffset(31,30)
close.Position = UDim2.new(1,-40,0,19)

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
    Position = UDim2.fromOffset(13,82),
    Size = UDim2.fromOffset(195,463),
    BackgroundColor3 = card,
    BorderSizePixel = 0
}),11)

local nav = obj("ScrollingFrame",sidebar,{
    Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,1,-135),
    BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=accent,
    AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()
})
stack(nav,5)

local right = round(obj("Frame",main,{
    Position = UDim2.fromOffset(220,82),
    Size = UDim2.fromOffset(727,463),
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
    navButtons[id] = btn(nav,id,nil,39)
end

-- Identidade visual na base da barra lateral.
local sidePanel = round(obj("Frame",sidebar,{
    Position = UDim2.new(0,9,1,-121),
    Size = UDim2.new(1,-18,0,111),
    BackgroundColor3 = Color3.fromRGB(33,8,17),
    BorderSizePixel = 0
}),10)
obj("UIStroke",sidePanel,{Color=accent,Transparency=.4,Thickness=1})
local sideLogo = txt(sidePanel,"♛  BRAB0X",29,18,true)
sideLogo.Position = UDim2.fromOffset(12,12)
sideLogo.Size = UDim2.new(1,-24,0,29)
sideLogo.TextColor3 = accent
local sideSub = txt(sidePanel,"PRIME  •  RED EDITION",22,10,true)
sideSub.Position = UDim2.fromOffset(12,47)
sideSub.Size = UDim2.new(1,-24,0,22)
sideSub.TextColor3 = white
local sideTip = txt(sidePanel,"Comandos e ajustes no mesmo hub",29,10)
sideTip.Position = UDim2.fromOffset(12,77)
sideTip.Size = UDim2.new(1,-24,0,29)
sideTip.TextColor3 = muted

local status = txt(
    main,
    "PRONTO | F = FLY • RSHIFT = MENU • CTRL+K = COMANDOS",
    17,11
)

status.TextColor3 = muted
status.Position = UDim2.fromOffset(17,556)
status.Size = UDim2.new(1,-28,0,17)

local cmdInput = round(obj("TextBox",main,{
    Position = UDim2.fromOffset(14,585),
    Size = UDim2.fromOffset(790,29),
    BackgroundColor3 = control,
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = white,
    PlaceholderText = "Digite: fly | goto nearest | fav fly | saveprofile...",
    PlaceholderColor3 = muted,
    ClearTextOnFocus = false,
    Font = Enum.Font.Code,
    TextSize = 12
}),7)

local execute = btn(main,"EXEC",nil,26)
execute.Position = UDim2.fromOffset(816,585)
execute.Size = UDim2.fromOffset(130,29)

local selected = "HOME"

local function notify(message)
    if not stopped and status.Parent then
        status.Text=tostring(message)
        if v13Log then v13Log(tostring(message)) end
    end
end

local function show(page)
    if not moduleEnabled(page) then
        page = "HOME"
    end

    selected = page

    for name,p in pairs(pages) do
        local active = name == page
        p.Visible = active
        if active then
            if config.animations then
                p.Position=UDim2.fromOffset(24,10)
                Tween:Create(p,TweenInfo.new(.17,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                    Position=UDim2.fromOffset(11,10)
                }):Play()
            else p.Position=UDim2.fromOffset(11,10) end
        end
    end

    for name,b in pairs(navButtons) do
        b.Visible = moduleEnabled(name)
        b.BackgroundColor3 = name == page and Color3.fromRGB(112,13,31) or control
        b.TextColor3 = white
        local border = b:FindFirstChildOfClass("UIStroke")
        if border then
            border.Color = name == page and accent or Color3.fromRGB(88,38,45)
            border.Transparency = name == page and .08 or .56
        end
    end
    if refreshV13Page then refreshV13Page(page) end
end

for name,b in pairs(navButtons) do
    bind(b.MouseButton1Click,function()
        show(name)
    end)
end

local function relabel()
    local labels = L[config.lang] or L.en

    local more={
        pt={PLAYERS="Jogadores",FAVORITES="Favoritos",TELEPORT="Teleporte",CONSOLE="Console",PROFILES="Perfis",PERFORMANCE="Desempenho"},
        en={PLAYERS="Players",FAVORITES="Favorites",TELEPORT="Teleport",CONSOLE="Console",PROFILES="Profiles",PERFORMANCE="Performance"}
    }
    for _,name in ipairs(navOrder) do
        local i=table.find(sections,name)
        local label=more[config.lang] and more[config.lang][name] or nil
        navButtons[name].Text="   "..(label or (i and i<=9 and labels[i]) or name)
    end
end

local function responsive()
    local camera = workspace.CurrentCamera
    local view = camera and camera.ViewportSize
        or Vector2.new(1280,720)

    uiScale.Scale = math.clamp(
        math.min(view.X/983,view.Y/662),
        .5,1
    )*config.scale*(config.compact and .88 or 1)
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
local homeFilter

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
    S.invisible = false
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

local aimKey = "BRAB0X_V13_AIM"
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

local resetExtras = function() end
local function resetAll()
    resetExtras()
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
end,"theme red")

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

-- UTILITARIOS INSPIRADOS NOS COMANDOS PUBLICOS DO INFINITE YIELD
-- Implementacao propria; comandos com efeitos locais nao sao replicados no servidor.

local extraState = {
    originalHip = nil, originalSlope = nil,
    originalAmbient = Lighting.Ambient,
    originalOutdoorAmbient = Lighting.OutdoorAmbient,
    originalShadows = Lighting.GlobalShadows,
    originalExposure = Lighting.ExposureCompensation,
    originalFogStart = Lighting.FogStart,
    savedWaypoints = {},
    watched = {},
    spinConnection = nil,
    lastSpectated = nil,
    savedMouseIcon = UIS.MouseIconEnabled,
    colorFX = nil,
    originalSaturation = nil,
    originalContrast = nil,
    originalBlur = nil,
    fullbrightBefore = nil,
}
local function findPlayer(token)
    token = tostring(token or ""):gsub("^%s+",""):gsub("%s+$","")
    if token == "" then return nil end
    local q = token:lower()
    if q == "me" then return player end
    if q == "nearest" then
        local _,_,root = chars()
        if not root then return nil end
        local best,dist
        for _,p in ipairs(Players:GetPlayers()) do
            local part = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if p ~= player and part then
                local d = (part.Position-root.Position).Magnitude
                if not dist or d < dist then best,dist=p,d end
            end
        end
        return best
    end
    if q == "random" then
        local candidates = Players:GetPlayers()
        if #candidates==0 then return nil end
        return candidates[math.random(1,#candidates)]
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower()==q or p.DisplayName:lower()==q then return p end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1,#q)==q then return p end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.DisplayName:lower():sub(1,#q)==q then return p end
    end
    return nil
end
local function findRoot(target)
    local c=target and target.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function parseVector(raw)
    local parts={}
    for v in tostring(raw or ""):gmatch("[^,%s]+") do
        local numv=tonumber(v)
        if not numv then return nil end
        parts[#parts+1]=numv
    end
    if #parts~=3 then return nil end
    return Vector3.new(parts[1],parts[2],parts[3])
end
local function selfTeleport(cf)
    local _,_,r=chars()
    if not r then notify("Seu personagem nao esta pronto"); return false end
    freeze(false)
    stopFly()
    r.CFrame=cf
    r.AssemblyLinearVelocity=Vector3.zero
    return true
end
local function gotoPlayer(a)
    local target=findPlayer(a)
    if not target then notify("Jogador nao encontrado: "..tostring(a)); return false end
    local root=findRoot(target)
    if not root then notify("Alvo sem personagem ativo"); return false end
    return selfTeleport(root.CFrame*CFrame.new(3,0,3))
end
local function setAvatarInvisible(enabled)
    if enabled then
        transparency(1)
        S.invisible = true
        return "INVIS LOCAL: nao garante invisibilidade para outros jogadores."
    else
        resetTransparency()
    end
end
local function alias(name,category,description,target,example)
    register(name,category,description,function(a)
        local entry=byName[target]
        if not entry then notify("Comando principal nao encontrado"); return false end
        return entry.run(a)
    end,example or name)
end
local function updateSpin()
    if extraState.spinConnection then
        extraState.spinConnection:Disconnect()
        extraState.spinConnection=nil
    end
    if not S.spinning then
        local _,_,root=chars()
        if root then root.AssemblyAngularVelocity=Vector3.zero end
        return
    end
    extraState.spinConnection=Run.Heartbeat:Connect(function()
        local _,h,r=chars()
        if not r or not h or h.Health<=0 then return end
        if not r.Anchored then
            r.AssemblyAngularVelocity=Vector3.new(0,S.spinSpeed,0)
        end
    end)
end
bind(UIS.JumpRequest,function()
    if S.infJump then
        local _,h=chars()
        if h and h.Health>0 then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
local function colorEffect()
    if extraState.colorFX and extraState.colorFX.Parent then
        return extraState.colorFX
    end
    extraState.colorFX = obj("ColorCorrectionEffect",Lighting,{
        Name="BRAB0X_PRIME_LOCAL_COLOR",
        Saturation=0,
        Contrast=0
    })
    return extraState.colorFX
end
resetExtras=function()
    S.infJump=false
    S.spinning=false
    updateSpin()
    S.noRotate=false
    S.invisible=false
    if extraState.lastSpectated then cameraReset() end
    extraState.lastSpectated=nil
    if extraState.colorFX then
        extraState.colorFX:Destroy()
        extraState.colorFX=nil
    end
    extraState.watched={}
    Lighting.Ambient=extraState.originalAmbient
    Lighting.OutdoorAmbient=extraState.originalOutdoorAmbient
    Lighting.GlobalShadows=extraState.originalShadows
    Lighting.ExposureCompensation=extraState.originalExposure
    Lighting.FogStart=extraState.originalFogStart
    S.fullbright=false
    local _,h=chars()
    if h then
        if extraState.originalHip then h.HipHeight=extraState.originalHip end
        if extraState.originalSlope then h.MaxSlopeAngle=extraState.originalSlope end
        h.AutoRotate=true
    end
    UIS.MouseIconEnabled=extraState.savedMouseIcon
end

-- TELEPORTES E POSICOES
register("goto","PLAYER","Ir ate outro jogador (local)",gotoPlayer,"goto nearest")
alias("to","PLAYER","Alias para goto","goto","to nearest")
alias("tp","PLAYER","Alias para goto","goto","tp nearest")
register("tppos","PLAYER","Ir para coordenadas X Y Z",function(a)
    local pos=parseVector(a)
    if not pos then notify("Use: tppos X Y Z"); return false end
    return selfTeleport(CFrame.new(pos))
end,"tppos 0 10 0")
alias("tpposition","PLAYER","Alias para tppos","tppos","tppos 0 10 0")
register("offset","PLAYER","Mover X Y Z relativo",function(a)
    local delta=parseVector(a)
    local _,_,r=chars()
    if not delta or not r then notify("Use: offset X Y Z"); return false end
    return selfTeleport(r.CFrame+delta)
end,"offset 0 5 0")
register("thru","PLAYER","Mover alguns studs a frente",function(a)
    local _,_,r=chars()
    if not r then return false end
    local amount=num(a,5,-100,100)
    return selfTeleport(r.CFrame+r.CFrame.LookVector*amount)
end,"thru 5")
register("gotocam","PLAYER","Ir para posicao da camera",function()
    local c=workspace.CurrentCamera
    return c and selfTeleport(CFrame.new(c.CFrame.Position)) or false
end)
alias("gotocamera","PLAYER","Alias de gotocam","gotocam")
register("wp","PLAYER","Guardar waypoint por nome",function(a)
    local name=tostring(a or ""):gsub("%s+$",""):lower()
    local _,_,r=chars()
    if name=="" or not r then notify("Use: wp casa"); return false end
    extraState.savedWaypoints[name]=r.CFrame
    notify("Waypoint registrado: "..name)
end,"wp casa")
alias("waypoint","PLAYER","Alias para wp","wp","wp casa")
register("gowp","PLAYER","Ir para waypoint",function(a)
    local name=tostring(a or ""):lower():gsub("%s+$","")
    local cf=extraState.savedWaypoints[name]
    if not cf then notify("Waypoint nao encontrado: "..name); return false end
    return selfTeleport(cf)
end,"gowp casa")
alias("walktowaypoint","PLAYER","Alias de gowp","gowp","gowp casa")
register("delwp","PLAYER","Apagar waypoint",function(a)
    extraState.savedWaypoints[tostring(a or ""):lower()]=nil
end,"delwp casa")
register("clearwps","PLAYER","Apagar todos os waypoints",function()
    extraState.savedWaypoints={}
end)
register("listwps","PLAYER","Listar waypoints",function()
    local names={}
    for name in pairs(extraState.savedWaypoints) do names[#names+1]=name end
    table.sort(names)
    notify(#names>0 and ("Waypoints: "..table.concat(names,", ")) or "Nenhum waypoint salvo")
end)

-- AVATAR E MOVIMENTO
register("invisible","PLAYER","Invisibilidade local do avatar",function()
    return setAvatarInvisible(true)
end)
alias("invis","PLAYER","Alias para invisible","invisible")
alias("vis","PLAYER","Alias para visible","visible")
alias("uninvis","PLAYER","Restaurar visibilidade","visible")
register("halfinvis","PLAYER","Avatar 50% transparente local",function()
    S.invisible=false
    transparency(.5)
end)
register("ghost","PLAYER","Avatar transparente e sem colisao local",function()
    setAvatarInvisible(true)
    setNoclip(true)
end)
register("unghost","PLAYER","Restaurar avatar e colisao",function()
    setAvatarInvisible(false)
    setNoclip(false)
end)
alias("walkspeed","PLAYER","Alias para walk","walk","walkspeed 24")
alias("ws","PLAYER","Alias para walk","walk","ws 24")
alias("jumppower","PLAYER","Alias para jump","jump","jumppower 75")
alias("jp","PLAYER","Alias para jump","jump","jp 75")
register("jumpnow","PLAYER","Pular agora",function()
    local _,h=chars()
    if not h then return false end
    h:ChangeState(Enum.HumanoidStateType.Jumping)
end)
register("infjump","PLAYER","Pulo extra enquanto ativado",function()
    S.infJump=true
end)
alias("infinitejump","PLAYER","Alias de infjump","infjump")
register("uninfjump","PLAYER","Desativar pulo extra",function()
    S.infJump=false
end)
alias("uninfinitejump","PLAYER","Alias de uninfjump","uninfjump")
register("spin","PLAYER","Girar seu avatar localmente",function(a)
    S.spinSpeed=num(a,5,1,25)
    S.spinning=true
    updateSpin()
end,"spin 5")
register("unspin","PLAYER","Parar de girar",function()
    S.spinning=false
    updateSpin()
end)
register("hipheight","PLAYER","Altura do quadril",function(a)
    local _,h=chars()
    if not h then return false end
    extraState.originalHip=extraState.originalHip or h.HipHeight
    h.HipHeight=num(a,h.HipHeight,0,15)
end,"hipheight 3")
register("resethip","PLAYER","Restaurar altura do quadril",function()
    local _,h=chars()
    if h and extraState.originalHip then h.HipHeight=extraState.originalHip end
end)
register("slope","PLAYER","Inclinacao maxima",function(a)
    local _,h=chars()
    if not h then return false end
    extraState.originalSlope=extraState.originalSlope or h.MaxSlopeAngle
    h.MaxSlopeAngle=num(a,45,0,89)
end,"slope 70")
register("resetslope","PLAYER","Restaurar inclinacao",function()
    local _,h=chars()
    if h and extraState.originalSlope then h.MaxSlopeAngle=extraState.originalSlope end
end)
register("autorotate","PLAYER","Rotacao automatica",function()
    S.noRotate=false
    local _,h=chars()
    if h then h.AutoRotate=true end
end)
register("norotate","PLAYER","Desativar rotacao automatica",function()
    S.noRotate=true
    local _,h=chars()
    if h then h.AutoRotate=false end
end)
alias("anchor","PLAYER","Congelar seu personagem","freeze")
alias("unanchor","PLAYER","Descongelar personagem","unfreeze")
register("platformstand","PLAYER","Modo platformstand",function()
    stopFly()
    local _,h=chars()
    if h then h.PlatformStand=true end
end)
register("unplatformstand","PLAYER","Sair de platformstand",function()
    local _,h=chars()
    if h then h.PlatformStand=false end
end)
register("unsitnow","PLAYER","Levantar do assento",function()
    local _,h=chars()
    if h then h.Sit=false end
end)
register("resetchars","PLAYER","Restaurar status do avatar local",function()
    resetExtras()
    resetTransparency()
    setNoclip(false)
end)

-- CAMERA E JOGADORES
register("lookat","CAMERA","Olhar na direcao de um jogador",function(a)
    local p=findPlayer(a)
    local r=findRoot(p)
    local c=workspace.CurrentCamera
    if not r or not c then notify("Jogador indisponivel"); return false end
    c.CFrame=CFrame.lookAt(c.CFrame.Position,r.Position)
end,"lookat nearest")
register("spectate","CAMERA","Assistir jogador pela camera",function(a)
    local p=findPlayer(a)
    local c=workspace.CurrentCamera
    local h=p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if not h or not c then notify("Jogador indisponivel"); return false end
    stopFly()
    c.CameraType=Enum.CameraType.Custom
    c.CameraSubject=h
    extraState.lastSpectated=p
end,"spectate nearest")
alias("view","CAMERA","Alias para spectate","spectate","view nearest")
register("unspectate","CAMERA","Voltar camera ao seu avatar",function()
    extraState.lastSpectated=nil
    cameraReset()
end)
alias("unview","CAMERA","Alias para unspectate","unspectate")
register("maxzoom","CAMERA","Ajustar zoom maximo",function(a)
    local n=num(a,35,1,100)
    player.CameraMode=Enum.CameraMode.Classic
    player.CameraMinZoomDistance=math.min(player.CameraMinZoomDistance,n)
    player.CameraMaxZoomDistance=n
end,"maxzoom 40")
register("minzoom","CAMERA","Ajustar zoom minimo",function(a)
    local n=num(a,1,0.5,100)
    player.CameraMode=Enum.CameraMode.Classic
    player.CameraMaxZoomDistance=math.max(player.CameraMaxZoomDistance,n)
    player.CameraMinZoomDistance=n
end,"minzoom 4")
register("zoomout","CAMERA","Aumentar distancia maxima",function()
    local n=math.min(100,player.CameraMaxZoomDistance+5)
    player.CameraMaxZoomDistance=n
end)
register("zoomin","CAMERA","Diminuir distancia maxima",function()
    player.CameraMaxZoomDistance=math.max(player.CameraMinZoomDistance,player.CameraMaxZoomDistance-5)
end)
register("fovplus","CAMERA","Aumentar campo de visao",function()
    local c=workspace.CurrentCamera
    if c then c.FieldOfView=math.min(120,c.FieldOfView+5) end
end)
register("fovminus","CAMERA","Diminuir campo de visao",function()
    local c=workspace.CurrentCamera
    if c then c.FieldOfView=math.max(40,c.FieldOfView-5) end
end)
register("firstp","CAMERA","Alias primeira pessoa",function()
    byName.first.run()
end)
register("thirdp","CAMERA","Alias terceira pessoa",function()
    byName.third.run()
end)
register("fixcam","CAMERA","Restaurar a camera",cameraReset)
alias("restorecam","CAMERA","Alias fixcam","fixcam")
register("campos","CAMERA","Coordenadas da camera",function()
    local c=workspace.CurrentCamera
    if c then notify(tostring(c.CFrame.Position)) end
end)
register("crosshairsize","CAMERA","Tamanho da mira visual",function(a)
    local n=num(a,28,14,70)
    crosshair.TextSize=n
    crosshair.Size=UDim2.fromOffset(n+8,n+8)
end,"crosshairsize 32")
register("mouseicon","CAMERA","Mostrar cursor",function()
    UIS.MouseIconEnabled=true
end)
register("hidemouseicon","CAMERA","Ocultar cursor",function()
    UIS.MouseIconEnabled=false
end)

-- MUNDO / GRAFICOS LOCAIS
register("fullbright","WORLD","Iluminacao clara local",function()
    Lighting.ClockTime=12
    Lighting.Brightness=4
    Lighting.Ambient=Color3.fromRGB(170,170,170)
    Lighting.OutdoorAmbient=Color3.fromRGB(170,170,170)
    Lighting.GlobalShadows=false
    Lighting.FogEnd=100000
    S.fullbright=true
end)
register("unfullbright","WORLD","Restaurar iluminacao",function()
    Lighting.Ambient=extraState.originalAmbient
    Lighting.OutdoorAmbient=extraState.originalOutdoorAmbient
    Lighting.GlobalShadows=extraState.originalShadows
    Lighting.Brightness=old.brightness
    Lighting.ClockTime=old.clock
    Lighting.FogEnd=old.fog
    S.fullbright=false
end)
register("ambient","WORLD","Luz ambiente RGB",function(a)
    local v=parseVector(a)
    if not v then notify("Use: ambient 100 0 0"); return false end
    Lighting.Ambient=Color3.fromRGB(math.clamp(v.X,0,255),math.clamp(v.Y,0,255),math.clamp(v.Z,0,255))
end,"ambient 100 20 20")
register("resetambient","WORLD","Restaurar luz ambiente",function()
    Lighting.Ambient=extraState.originalAmbient
    Lighting.OutdoorAmbient=extraState.originalOutdoorAmbient
end)
register("shadows","WORLD","Habilitar sombras",function()
    Lighting.GlobalShadows=true
end)
register("noshadows","WORLD","Desabilitar sombras local",function()
    Lighting.GlobalShadows=false
end)
register("fogstart","WORLD","Inicio da neblina",function(a)
    Lighting.FogStart=num(a,0,0,100000)
end,"fogstart 100")
register("resetfogstart","WORLD","Restaurar inicio da neblina",function()
    Lighting.FogStart=extraState.originalFogStart
end)
register("exposure","WORLD","Compensacao de exposicao",function(a)
    Lighting.ExposureCompensation=num(a,0,-5,5)
end,"exposure 1")
register("resetexposure","WORLD","Restaurar exposicao",function()
    Lighting.ExposureCompensation=extraState.originalExposure
end)
register("saturation","WORLD","Saturacao visual",function(a)
    colorEffect().Saturation=num(a,0,-1,1)
end,"saturation 0.5")
register("contrast","WORLD","Contraste visual",function(a)
    colorEffect().Contrast=num(a,0,-1,1)
end,"contrast 0.2")
register("resetcolors","WORLD","Limpar ajustes de cor",function()
    if extraState.colorFX then extraState.colorFX:Destroy() extraState.colorFX=nil end
end)
register("worldreset","WORLD","Restaurar ambiente local",function()
    Lighting.ClockTime=old.clock
    Lighting.Brightness=old.brightness
    Lighting.FogEnd=old.fog
    Lighting.FogStart=extraState.originalFogStart
    Lighting.Ambient=extraState.originalAmbient
    Lighting.OutdoorAmbient=extraState.originalOutdoorAmbient
    Lighting.GlobalShadows=extraState.originalShadows
    Lighting.ExposureCompensation=extraState.originalExposure
    if extraState.colorFX then extraState.colorFX:Destroy() extraState.colorFX=nil end
end)

-- UTILIDADES E INFORMACOES
register("players","SETTINGS","Listar jogadores presentes",function()
    local list={}
    for _,p in ipairs(Players:GetPlayers()) do list[#list+1]=p.Name end
    table.sort(list)
    print("[BRAB0X] JOGADORES: "..table.concat(list,", "))
    notify("Jogadores: "..#list.." - veja os nomes no console (F9)")
end)
register("serverinfo","SETTINGS","Dados do servidor",function()
    notify("PlaceId "..game.PlaceId.." | JobId "..tostring(game.JobId):sub(1,12).." | Jogadores "..#Players:GetPlayers())
end)
register("placeid","SETTINGS","ID da experiencia",function()
    notify("PlaceId: "..tostring(game.PlaceId))
end)
register("jobid","SETTINGS","ID do servidor atual",function()
    notify("JobId: "..tostring(game.JobId))
end)
register("userid","SETTINGS","Seu ID Roblox",function()
    notify("UserId: "..tostring(player.UserId))
end)
register("username","SETTINGS","Seu usuario",function()
    notify("Usuario: "..player.Name.." | Nome visivel: "..player.DisplayName)
end)
register("playerinfo","SETTINGS","Dados de jogador",function(a)
    local p=findPlayer(a)
    if not p then notify("Jogador nao encontrado"); return false end
    notify(p.Name.." | ID "..p.UserId.." | Presente")
end,"playerinfo nearest")
register("posplayer","SETTINGS","Posicao de um jogador",function(a)
    local p=findPlayer(a)
    local r=findRoot(p)
    if not r then notify("Personagem nao encontrado"); return false end
    notify((p and p.Name or "Jogador")..": "..tostring(r.Position))
end,"posplayer nearest")
register("distance","SETTINGS","Distancia ate jogador",function(a)
    local p=findPlayer(a)
    local target=findRoot(p)
    local _,_,mine=chars()
    if not target or not mine then notify("Jogador indisponivel"); return false end
    notify(p.Name.." esta a "..math.floor((target.Position-mine.Position).Magnitude).." studs")
end,"distance nearest")
register("notify","SETTINGS","Mensagem local de status",function(a)
    notify(tostring(a or ""))
end,"notify Ola")
register("version","SETTINGS","Versao do BRAB0X PRIME",function()
    notify("BRAB0X PRIME V13 | Premium Manager")
end)
register("cmdcount","SETTINGS","Quantidade de comandos",function()
    notify("Comandos registrados: "..#registered)
end)
register("commands","SETTINGS","Abrir lista de comandos",function()
    show("COMMANDS")
end)
register("ping","SETTINGS","Informacoes de rede",function()
    local success,value=pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    notify(success and ("Ping: "..tostring(value)) or "Ping nao disponivel neste servidor")
end)
register("gameid","SETTINGS","ID do universo",function()
    notify("GameId: "..tostring(game.GameId))
end)
register("coordsme","SETTINGS","Suas coordenadas",function()
    byName.coords.run()
end)
register("listcmd","SETTINGS","Listar comandos no console",function()
    local list={}
    for _,entry in ipairs(registered) do list[#list+1]=entry.name end
    table.sort(list)
    print("[BRAB0X] COMANDOS: "..table.concat(list,", "))
    notify(#list.." comandos - lista enviada ao console (F9)")
end)
-- FIM DOS UTILITARIOS

-- EXECUTAR COMANDO

exec = function(raw)
    local command,arg = tostring(raw):match(
        "^%s*/?(%S+)%s*(.-)%s*$"
    )

    if not command then return end
    command = command:lower()

    local entry = byName[command]
    if addHistory then addHistory(tostring(raw)) end

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

    local ok,result = pcall(entry.run,arg)

    if not ok then
        local err = result
        notify("Erro em "..command..": "..tostring(err))
        return
    end
    if result == false then return end
    if type(result)=="string" then
        notify(result)
        return
    end

    if stopped then return end
    if command ~= "coords"
        and command ~= "status" then
        notify("OK: "..raw)
    end

    refresh()
end

-- COMANDOS / NOVA INTERFACE COM CONTROLES REAIS
local cmdPage = pages.COMMANDS
local cmdHeader = round(obj("Frame",cmdPage,{
    Size = UDim2.new(1,-8,0,66),
    BackgroundColor3 = Color3.fromRGB(33,10,19),BorderSizePixel=0
}),10)
obj("UIStroke",cmdHeader,{Color=accent,Thickness=1,Transparency=.3})
local cmdTitle = txt(cmdHeader,"▤  COMANDOS PREMIUM",29,19,true)
cmdTitle.Position=UDim2.fromOffset(16,7)
cmdTitle.Size=UDim2.new(1,-28,0,29)
local cmdHint = txt(cmdHeader,"Funcoes organizadas • Ajustes instantaneos",22,11)
cmdHint.Position=UDim2.fromOffset(17,37)
cmdHint.Size=UDim2.new(1,-28,0,22)
cmdHint.TextColor3=muted

local search = round(obj("TextBox",cmdPage,{
    Size=UDim2.new(1,-8,0,40),BackgroundColor3=control,
    Text="",PlaceholderText="⌕  Buscar comando...",
    TextColor3=white,PlaceholderColor3=muted,
    ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=13,
    BorderSizePixel=0
}),9)
obj("UIStroke",search,{Color=accent,Thickness=1,Transparency=.55})

local filterRow = obj("Frame",cmdPage,{Size=UDim2.new(1,-8,0,43),BackgroundTransparency=1})
obj("UIListLayout",filterRow,{
    FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),
    SortOrder=Enum.SortOrder.LayoutOrder
})
local activeFilter="ALL"
local filters={{"ALL","TODOS"},{"FLY","VOO"},{"PLAYER","JOGADOR"},
    {"CAMERA","CAMERA"},{"WORLD","MUNDO"},{"EMOTES","EMOTES"}}
local filterButtons={}
for _,entry in ipairs(filters) do
    local b=btn(filterRow,entry[2],nil,40)
    b.Size=UDim2.new(1/6,-5,0,40)
    filterButtons[entry[1]]=b
    bind(b.MouseButton1Click,function()
        activeFilter=entry[1]
        if refreshCommandList then refreshCommandList() end
    end)
end

local visualUpdates={}
local function trackVisual(fn)
    visualUpdates[#visualUpdates+1]=fn
end
local quickTitle=titleRow(cmdPage,"⚡  CONTROLES RAPIDOS")
local quickGrid=obj("Frame",cmdPage,{Size=UDim2.new(1,-8,0,0),BackgroundTransparency=1})
local quickLayout=obj("UIGridLayout",quickGrid,{
    CellSize=UDim2.new(.5,-6,0,90),
    CellPadding=UDim2.fromOffset(9,9),
    SortOrder=Enum.SortOrder.LayoutOrder
})
local function sizeQuick()
    quickGrid.Size=UDim2.new(1,-8,0,quickLayout.AbsoluteContentSize.Y+10)
end
bind(quickLayout:GetPropertyChangedSignal("AbsoluteContentSize"),sizeQuick)

local function controlCard(parent,name,desc,height)
    local isGrid=parent==quickGrid
    local p=round(obj("Frame",parent,{
        Size=isGrid and UDim2.fromOffset(340,90) or UDim2.new(1,-8,0,height or 86),
        BackgroundColor3=Color3.fromRGB(26,21,29),
        BorderSizePixel=0
    }),11)
    obj("UIStroke",p,{Color=accent,Thickness=1,Transparency=.65})
    local h=txt(p,name,27,13,true)
    h.Position=UDim2.fromOffset(14,9)
    h.Size=UDim2.new(1,-30,0,27)
    local d=txt(p,desc,25,10)
    d.Position=UDim2.fromOffset(14,34)
    d.Size=UDim2.new(1,-30,0,25)
    d.TextColor3=muted
    return p
end

local function toggleControl(parent,title,desc,get,onCmd,offCmd)
    local p=controlCard(parent,title,desc,77)
    local b=btn(p,"",nil,29)
    b.AnchorPoint=Vector2.new(1,.5)
    b.Position=UDim2.new(1,-12,.5,0)
    b.Size=UDim2.fromOffset(76,29)
    local function redraw()
        local on=get()
        b.Text=on and "● ON" or "○ OFF"
        b.BackgroundColor3=on and Color3.fromRGB(147,14,35) or control
    end
    trackVisual(redraw)
    redraw()
    bind(b.MouseButton1Click,function()
        exec(get() and offCmd or onCmd)
        redraw()
    end)
    return p
end

local function sliderControl(parent,title,desc,lo,hi,step,get,command,fmt)
    local p=controlCard(parent,title,desc,103)
    local valueText=txt(p,"",24,12,true)
    valueText.Position=UDim2.new(1,-88,1,-32)
    valueText.Size=UDim2.fromOffset(77,24)
    valueText.TextColor3=accent
    valueText.TextXAlignment=Enum.TextXAlignment.Right
    local bar=round(obj("Frame",p,{
        Position=UDim2.new(0,16,1,-25),
        Size=UDim2.new(1,-120,0,9),
        BackgroundColor3=Color3.fromRGB(69,54,63),
        BorderSizePixel=0,Active=true
    }),8)
    local fill=round(obj("Frame",bar,{
        Size=UDim2.fromScale(0,1),
        BackgroundColor3=accent,BorderSizePixel=0
    }),8)
    local dot=round(obj("Frame",bar,{
        AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(0,.5),
        Size=UDim2.fromOffset(16,16),
        BackgroundColor3=white,BorderSizePixel=0
    }),10)
    local dragging=false
    local draft
    local function display(value)
        local k=math.clamp((value-lo)/(hi-lo),0,1)
        fill.Size=UDim2.fromScale(k,1)
        dot.Position=UDim2.fromScale(k,.5)
        valueText.Text=string.format(fmt or "%.0f",value)
    end
    local function update()
        if not dragging then display(get()) end
    end
    local function move(x)
        local x0=bar.AbsolutePosition.X
        local width=math.max(1,bar.AbsoluteSize.X)
        local k=math.clamp((x-x0)/width,0,1)
        draft=math.clamp(math.floor((lo+k*(hi-lo))/step+.5)*step,lo,hi)
        display(draft)
    end
    trackVisual(update)
    update()
    bind(bar.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            move(input.Position.X)
        end
    end)
    bind(UIS.InputChanged,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
            or input.UserInputType==Enum.UserInputType.Touch) then
            move(input.Position.X)
        end
    end)
    bind(UIS.InputEnded,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch) then
            dragging=false
            if draft~=nil then exec(command.." "..tostring(draft)) end
            update()
        end
    end)
    return p
end

toggleControl(quickGrid,"↗  FLY","Voo livre",function()return S.fly end,"fly","unfly")
toggleControl(quickGrid,"◇  NOCLIP","Colisao local",function()return S.noclip end,"noclip","clip")
toggleControl(quickGrid,"⚡  BOOST","Turbo do voo",function()return S.boost end,"boost","unboost")
toggleControl(quickGrid,"✧  GLOW","Brilho no personagem",function()return S.glow end,"glow","unglow")
sliderControl(quickGrid,"➤  SPEED","Velocidade de voo",10,300,5,
    function()return S.speed end,"speed","%.0f")
sliderControl(quickGrid,"◉  FOV","Campo de visao",40,120,5,
    function()local c=workspace.CurrentCamera return c and c.FieldOfView or 70 end,
    "fov","%.0f")

-- ACESSO RAPIDO / GOTO E INVIS LOCAL
local utilityStrip=obj("Frame",cmdPage,{
    Size=UDim2.new(1,-8,0,46),BackgroundTransparency=1
})
local gotoBox=round(obj("TextBox",utilityStrip,{
    Position=UDim2.fromScale(0,0),
    Size=UDim2.new(.44,-4,1,0),
    BackgroundColor3=control,BorderSizePixel=0,
    PlaceholderText="Nome do jogador ou nearest...",
    PlaceholderColor3=muted,TextColor3=white,
    Font=Enum.Font.Gotham,TextSize=12,
    ClearTextOnFocus=false,Text=""
}),8)
local gotoBtn=btn(utilityStrip,"GOTO",function()
    local query=gotoBox.Text
    if query=="" then query="nearest" end
    exec("goto "..query)
end,46)
gotoBtn.Position=UDim2.new(.45,0,0,0)
gotoBtn.Size=UDim2.new(.17,-5,1,0)
local invisBtn=btn(utilityStrip,"INVIS LOCAL",function()
    exec(S.invisible and "visible" or "invisible")
end,46)
invisBtn.Position=UDim2.new(.62,0,0,0)
invisBtn.Size=UDim2.new(.2,-5,1,0)
local playerListBtn=btn(utilityStrip,"PLAYERS",function()
    exec("players")
end,46)
playerListBtn.Position=UDim2.new(.83,0,0,0)
playerListBtn.Size=UDim2.new(.17,-1,1,0)

local listHeading=titleRow(cmdPage,">  SECOES DE COMANDOS - TOQUE PARA ABRIR/FECHAR")
local categories={
    {"FLY","MOVIMENTO / VOO"},
    {"PLAYER","JOGADOR / TELEPORTE"},
    {"CAMERA","CAMERA / VISUAL"},
    {"WORLD","MUNDO / GRAFICOS"},
    {"EMOTES","EMOTES / ANIMACOES"},
    {"SETTINGS","SISTEMA / UTILIDADES"}
}
local accordion={}
local foldRows={}
local function foldedHeight(count)
    if count<=0 then return 0 end
    local rows=math.ceil(count/2)
    return rows*46+(rows-1)*8+12
end
for _,row in ipairs(categories) do
    local category,title=row[1],row[2]
    local section=obj("Frame",cmdPage,{
        Size=UDim2.new(1,-8,0,51),
        BackgroundTransparency=1,
        ClipsDescendants=true
    })
    local headerBtn=round(obj("TextButton",section,{
        Size=UDim2.new(1,0,0,47),
        Position=UDim2.fromOffset(0,0),
        BackgroundColor3=Color3.fromRGB(33,21,30),
        BorderSizePixel=0,
        Text="",
        AutoButtonColor=true
    }),10)
    obj("UIStroke",headerBtn,{Color=accent,Transparency=.45,Thickness=1})
    local name=txt(headerBtn,title,30,15,true)
    name.Position=UDim2.fromOffset(16,8)
    name.Size=UDim2.new(1,-100,0,30)
    local counter=txt(headerBtn,"",28,11,true)
    counter.Position=UDim2.new(1,-98,0,9)
    counter.Size=UDim2.fromOffset(52,28)
    counter.TextColor3=accent
    counter.TextXAlignment=Enum.TextXAlignment.Right
    local arrow=txt(headerBtn,">",34,23,true)
    arrow.Position=UDim2.new(1,-40,0,6)
    arrow.Size=UDim2.fromOffset(30,34)
    arrow.TextXAlignment=Enum.TextXAlignment.Center
    arrow.TextColor3=accent
    local content=obj("Frame",section,{
        Position=UDim2.fromOffset(0,53),
        Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1
    })
    obj("UIGridLayout",content,{
        CellSize=UDim2.new(.5,-6,0,46),
        CellPadding=UDim2.fromOffset(9,8),
        SortOrder=Enum.SortOrder.LayoutOrder
    })
    local g={
        category=category,
        section=section,
        header=headerBtn,
        arrow=arrow,
        counter=counter,
        content=content,
        items={},
        expanded=category=="PLAYER"
    }
    accordion[category]=g
    bind(headerBtn.MouseButton1Click,function()
        g.expanded=not g.expanded
        if refreshCommandList then refreshCommandList() end
    end)
end

for _,entry in ipairs(registered) do
    local g=accordion[entry.category]
    if g then
        local b=btn(g.content,
            entry.example.."  |  "..entry.description,
            function()
                local needsArgs=(entry.name=="goto" or entry.name=="to" or entry.name=="tp")
                if needsArgs then
                    local target=gotoBox.Text~="" and gotoBox.Text or "nearest"
                    exec(entry.name.." "..target)
                else
                    exec(entry.example)
                end
            end,46)
        b.TextWrapped=true
        b.TextSize=11
        g.items[#g.items+1]={
            button=b,
            lookup=(entry.name.." "..entry.description.." "..entry.category):lower()
        }
    end
end

refreshCommandList=function()
    local q=search.Text:lower()
    local anyResults=false
    for name,g in pairs(accordion) do
        local count=0
        local categoryAllowed=activeFilter=="ALL" or activeFilter==name
        for _,item in ipairs(g.items) do
            local match=categoryAllowed and (q=="" or item.lookup:find(q,1,true)~=nil)
            item.button.Visible=match
            if match then count=count+1 end
        end
        g.counter.Text=tostring(count)
        g.section.Visible=count>0
        if count>0 then anyResults=true end
        -- Quando ha pesquisa ou filtro, abre automaticamente a secao correspondente.
        local open=(q~="" or activeFilter~="ALL") and count>0 or
            (q=="" and activeFilter=="ALL" and g.expanded)
        g.arrow.Rotation=open and 90 or 0
        local h=open and foldedHeight(count) or 0
        g.content.Size=UDim2.new(1,0,0,h)
        local target=UDim2.new(1,-8,0,53+h)
        if g.section.Size~=target then
            Tween:Create(g.section,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                Size=target
            }):Play()
        end
    end
    for name,b in pairs(filterButtons) do
        local current=name==activeFilter
        b.BackgroundColor3=current and Color3.fromRGB(146,15,36) or control
        b.TextColor3=white
    end
    local showQuick=q=="" and activeFilter=="ALL"
    quickGrid.Visible=showQuick
    quickTitle.Visible=showQuick
    utilityStrip.Visible=showQuick
    listHeading.Text=q~="" and ("RESULTADOS DE BUSCA: "..q:upper()) or
        (activeFilter~="ALL" and ("FILTRO: "..activeFilter) or
        ">  SECOES DE COMANDOS - TOQUE PARA ABRIR/FECHAR")
    sizeQuick()
end
bind(search:GetPropertyChangedSignal("Text"),refreshCommandList)

homeFilter=function(filter)
    if filter=="SETTINGS" then
        show("SETTINGS")
    else
        activeFilter=filter or "ALL"
        search.Text=""
        show("COMMANDS")
        refreshCommandList()
    end
end

-- HOME / BANNER INTEGRADO COM DESENHO NATIVO (SEM ASSET EXTERNO)
local hero = round(obj("Frame",pages.HOME,{
    Size = UDim2.new(1,-9,0,202),
    BackgroundColor3 = Color3.fromRGB(29,6,15),
    ClipsDescendants = true,
    BorderSizePixel = 0
}),15)
obj("UIGradient",hero,{
    Rotation = 8,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(12,3,8)),
        ColorSequenceKeypoint.new(.40,Color3.fromRGB(90,9,24)),
        ColorSequenceKeypoint.new(.74,Color3.fromRGB(26,3,10)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(7,4,9))
    })
})
obj("UIStroke",hero,{Color=accent,Transparency=.15,Thickness=1.5})
for i=1,7 do
    local beam = obj("Frame",hero,{
        Size = UDim2.fromOffset(5+i*4,330),
        Position = UDim2.new(1,-i*48,-.3,-32),
        Rotation = 30,
        BackgroundColor3 = i%2==0 and accent or Color3.fromRGB(132,12,32),
        BackgroundTransparency = .77,
        BorderSizePixel = 0
    })
end
local crown = txt(hero,"♛",132,116,true)
crown.Position = UDim2.new(1,-190,0,-10)
crown.Size = UDim2.fromOffset(180,156)
crown.TextXAlignment = Enum.TextXAlignment.Center
crown.TextColor3 = accent
crown.TextTransparency = .13
local bannerSmall = txt(hero,"★  HUB PREMIUM  •  V13",22,12,true)
bannerSmall.Position = UDim2.fromOffset(27,24)
bannerSmall.Size = UDim2.fromOffset(425,22)
bannerSmall.TextColor3 = accent
local bannerBrand = txt(hero,"BRAB0X PRIME",59,36,true)
bannerBrand.Position = UDim2.fromOffset(26,59)
bannerBrand.Size = UDim2.new(1,-60,0,60)
local bannerSub = txt(hero,"RED NEON CONTROL CENTER",28,16,true)
bannerSub.Position = UDim2.fromOffset(29,120)
bannerSub.Size = UDim2.new(1,-60,0,28)
bannerSub.TextColor3 = accent
local bannerDesc = txt(hero,"VOO  •  JOGADOR  •  CAMERA  •  MUNDO  •  EMOTES",24,11,true)
bannerDesc.Position = UDim2.fromOffset(29,157)
bannerDesc.Size = UDim2.new(1,-58,0,24)
bannerDesc.TextColor3 = white

local live = titleRow(pages.HOME,"FLY OFF • SPEED 55 • AIM OFF")
titleRow(pages.HOME,"PAINEL DE ACOES RAPIDAS  /  ESCOLHA SUA FUNCAO")

local homeTiles = obj("Frame",pages.HOME,{
    Size = UDim2.new(1,-9,0,218),
    BackgroundTransparency = 1
})
obj("UIGridLayout",homeTiles,{
    CellSize = UDim2.new(.5,-7,0,65),
    CellPadding = UDim2.fromOffset(9,10),
    SortOrder = Enum.SortOrder.LayoutOrder
})
local function makeHomeTile(icon,title,desc,filter)
    local t = btn(homeTiles,"",function()
        if homeFilter then homeFilter(filter) end
    end,65)
    t.BackgroundColor3 = Color3.fromRGB(26,20,29)
    obj("UIStroke",t,{Color=accent,Thickness=1,Transparency=.48})
    local ico = txt(t,icon,39,29,true)
    ico.Position = UDim2.fromOffset(13,9)
    ico.Size = UDim2.fromOffset(46,42)
    ico.TextColor3 = accent
    local ttl = txt(t,title,24,15,true)
    ttl.Position = UDim2.fromOffset(62,10)
    ttl.Size = UDim2.new(1,-82,0,24)
    local sb = txt(t,desc,22,11)
    sb.Position = UDim2.fromOffset(62,35)
    sb.Size = UDim2.new(1,-82,0,22)
    sb.TextColor3 = muted
end
makeHomeTile("↗","MOVIMENTO","Fly, velocidade e noclip","FLY")
makeHomeTile("♙","JOGADOR","Pulo, visual e posicoes","PLAYER")
makeHomeTile("◉","CAMERA","FOV, zoom e mira","CAMERA")
makeHomeTile("◈","MUNDO","Tempo e iluminacao","WORLD")
makeHomeTile("♫","EMOTES","Animacoes autorizadas","EMOTES")
makeHomeTile("⚙","AJUSTES","Configuracoes do hub","SETTINGS")

local quickRow = obj("Frame",pages.HOME,{
    Size = UDim2.new(1,-9,0,43),
    BackgroundTransparency = 1
})
obj("UIListLayout",quickRow,{
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0,8),
    SortOrder = Enum.SortOrder.LayoutOrder
})
local function quick(label,command)
    local b = btn(quickRow,label,function()
        if exec then exec(command) end
    end,42)
    b.Size = UDim2.new(.25,-6,0,42)
    return b
end
quick("↗  FLY ON","fly")
quick("■  FLY OFF","unfly")
quick("⚡  BOOST","boost")
quick("⌖  AIM OPCIONAL","modules")

-- Atalhos da pagina inicial usam o filtro da aba Comandos.

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

-- AIM DE TREINO / SEPARADO DOS DEMAIS COMANDOS
local aimTitle=titleRow(pages.AIM,"◎  AIM PARA NPCs DE TREINO")
local info=txt(pages.AIM,
    "Camera assistida somente para NPCs com atributo PracticeTarget=true.",
    49,12)
info.TextColor3=muted
toggleControl(pages.AIM,"◎  AIM DE TREINO","Assistencia visual para NPCs",
    function()return S.aim end,"aim on","aim off")
toggleControl(pages.AIM,"◌  CIRCULO FOV","Exibir area de busca",
    function()return S.aimCircle end,"aimcircle on","aimcircle off")
toggleControl(pages.AIM,"▣  SEGURAR RMB","Requer botao direito pressionado",
    function()return S.aimHold end,"aimholdmode on","aimholdmode off")
sliderControl(pages.AIM,"◎  RAIO DO AIM","Raio da area de treino",30,350,10,
    function()return S.aimRadius end,"aimfov","%.0f")
sliderControl(pages.AIM,"≋  SUAVIDADE","Movimento suave da camera",.02,1,.02,
    function()return S.aimSmooth end,"smooth","%.2f")
local aimExplain=txt(pages.AIM,
    "Nao seleciona outros jogadores e nao dispara automaticamente.",
    45,12)
aimExplain.TextColor3=muted

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
    "red","crimson","ember","ruby"
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
        "◎  AIM NPC TREINO %s  |  RAIO %d  |  SMOOTH %.2f"
    ):format(S.aim and "ON" or "OFF",S.aimRadius,S.aimSmooth)
    for _,fn in ipairs(visualUpdates) do fn() end

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

    if _G.BRAB0X_V13_STOP == closeHub then
        _G.BRAB0X_V13_STOP = nil
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

_G.BRAB0X_V13_STOP = closeHub

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
    splash,"RED NEON EDITION  •  CARREGANDO",25,13
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
    notify("BRAB0X V13 pronto! AIM: "..(selectedAim and "ATIVO" or "OCULTO"))
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
    "BRAB0X PRIME V13 | "
    ..#registered.." comandos"
)
