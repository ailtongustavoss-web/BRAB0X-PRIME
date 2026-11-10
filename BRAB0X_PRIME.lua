
-- BRAB0X PRIME V17.1 | INTERFACE CORRIGIDA + MENU FUNCIONAL
-- Criado por @wendezao05153nh
--
-- INDICE DE MANUTENCAO (SCRIPT COMPLETO, MESMO LOADSTRING):
-- 01. SERVICOS E DADOS      = inicio do arquivo, configuracoes e persistencia
-- 02. DESIGN E NAVEGACAO    = paleta, janela, menu em 4 categorias, busca
-- 03. SISTEMAS LOCAIS      = movimento, camera, mundo, visual e emotes
-- 04. REGISTRO DE COMANDOS  = register/alias, validação e exec
-- 05. MODULOS PREMIUM      = painel de comandos, favoritos, console e perfis
-- 06. UNIVERSAL MULTIJOGOS = perfis e reconhecimento via PlaceId
-- 07. PAGINAS E AJUSTES    = paginas V14/V15, temas, teclas e controles
-- 08. INICIALIZACAO        = interface pronta para mostrar
--
-- Instalar como LocalScript no seu proprio jogo:
-- StarterPlayer > StarterPlayerScripts
-- F = Fly | RightShift = Menu | Ctrl+K = Buscar | F1 = Ajuda
-- F2 = Command Wheel | F6 = Cinema
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
    "BRAB0X_V17_1_STOP",
    "BRAB0X_V17_STOP",
    "BRAB0X_V16_STOP",
    "BRAB0X_V15_STOP",
    "BRAB0X_V14_STOP",
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

local previous = pg:FindFirstChild("BRAB0X_PRIME_V17_1")
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
for _,field in ipairs({"favorites","keybinds","profiles","waypoints","macros","routes","dashboard","stats","gameProfiles"}) do
    if type(v13Data[field])~="table" then v13Data[field]={} end
end
-- V15: o mesmo script seleciona o perfil pelo game.PlaceId. Sem baixar Lua externo.
-- Preferencias universais sao separadas dos perfis de cada jogo.
local v15PrefsKeys={"theme","lang","scale","aimEnabled","compact","animations","opacity","neon","notifications"}
if type(v13Data.universalPrefs)~="table" then
    v13Data.universalPrefs=type(v13Data.preferences)=="table" and v13Data.preferences or {}
end
local v15PlaceId=tostring(game.PlaceId)
local v15UniverseId=tostring(game.GameId)
local v15GameProfile=v13Data.gameProfiles[v15PlaceId]
if type(v15GameProfile)~="table" then
    v15GameProfile={
        label=(tostring(game.Name)~="Game" and tostring(game.Name):sub(1,32))
            or ("Jogo "..v15PlaceId),
        universeId=v15UniverseId,
        mode="universal",
        quick={"fly","unfly","noclip","manual"},
        created=os.time()
    }
    v13Data.gameProfiles[v15PlaceId]=v15GameProfile
end
v15GameProfile.lastVisit=os.time()
v15GameProfile.universeId=v15UniverseId
if v15GameProfile.mode~="custom" then v15GameProfile.mode="universal" end
if type(v15GameProfile.quick)~="table" then
    v15GameProfile.quick={"fly","unfly","noclip","manual"}
end
local startupPrefs=(v15GameProfile.mode=="custom"
    and type(v15GameProfile.preferences)=="table")
    and v15GameProfile.preferences or v13Data.universalPrefs
for _,key in ipairs(v15PrefsKeys) do
    if startupPrefs[key]~=nil then config[key]=startupPrefs[key] end
end
config.theme=type(config.theme)=="string" and config.theme or "red"
config.scale=math.clamp(tonumber(config.scale) or 1,.6,1.25)
config.compact=config.compact==true
config.animations=config.animations~=false
config.notifications=config.notifications~=false
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
        animations=config.animations,opacity=config.opacity,neon=config.neon,
        notifications=config.notifications
    }
    if v15GameProfile.mode=="custom" then
        v15GameProfile.preferences=v13Data.preferences
    else
        v13Data.universalPrefs=v13Data.preferences
    end
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
    "TELEPORT","CONSOLE","PROFILES","PERFORMANCE","HELP","GAMES",
    "RECENT","MACROS","CINEMA","ROUTES","AVATAR","AUDIO","STATS","DASHBOARD",
    "PALETTE","COMPASS","NOTES","BACKUP","DIAGNOSTICS","GUIDE","BOOKMARKS"
}

-- A unica categoria opcional e AIM; todas as outras permanecem juntas.
local navOrder = {
    "HOME","GAMES","COMMANDS","PALETTE","DASHBOARD","RECENT","MACROS","CINEMA","ROUTES",
    "AVATAR","AUDIO","STATS","PLAYERS","FAVORITES","BOOKMARKS","TELEPORT",
    "COMPASS","NOTES","BACKUP","DIAGNOSTICS","GUIDE","CONSOLE","PROFILES",
    "PERFORMANCE","HELP","SETTINGS","AIM"
}
local function moduleEnabled(name)
    return name ~= "AIM" or config.aimEnabled==true
end

local applyV13Appearance
local openModulePicker
local refreshCommandList
local keyCaptureHandler
local refreshV13Page
local actionRow
local live
local search
local toggleControl
local sliderControl
local visualUpdates
local v13Log
local addHistory
local updatePlayerManager
local updateFavoritePanel
local updateTeleportPanel
local updateProfilePanel
local updateConsolePanel
local premiumNotify
local openCommandHelp
local refreshHelpPage
-- Estado unico V14: evita excesso de variaveis locais no script extenso.
local v14={
    router={
        placeId=v15PlaceId,universeId=v15UniverseId,
        profile=v15GameProfile,profiles=v13Data.gameProfiles,
        modules={},detected="UNIVERSAL"
    },
    recent={}, commandsInSession=0, sessionStarted=os.clock(),
    safe=true, macroRunning=false, cinematic=false,
    cinemaConnection=nil, cinemaSaved=nil, music=nil, musicId="",
    avatarParts={}, wheelOpen=false, selectedRoute=nil,
    controllerMode=false
}
for _,key in ipairs({"commandCount","totalSessions","frequency"}) do
    if key=="frequency" and type(v13Data.stats[key])~="table" then
        v13Data.stats[key]={}
    elseif key~="frequency" then
        v13Data.stats[key]=tonumber(v13Data.stats[key]) or 0
    end
end
v13Data.stats.totalSessions=v13Data.stats.totalSessions+1
v14.stats=v13Data.stats
v14.dashboard=v13Data.dashboard
v14.routes=v13Data.routes
v14.macros=v13Data.macros
local noticeCounter=0

-- JANELA PRINCIPAL

local gui = obj("ScreenGui",pg,{
    Name = "BRAB0X_PRIME_V17_1",
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
    header,"B  BRAB0X  PRIME",38,25,true
)
brand.Position = UDim2.fromOffset(19,4)
brand.Size = UDim2.fromOffset(390,38)

local sub = txt(
    header,
    "V17.1  |  ULTIMATE TOOLKIT   /   BY @wendezao05153nh",
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

-- V16 / NAVEGACAO ORGANIZADA: GRUPOS RECOLHIVEIS + BUSCA POR PAGINA
do
    nav.Position=UDim2.fromOffset(8,48)
    nav.Size=UDim2.new(1,-16,1,-176)
    local navSearch=round(obj("TextBox",sidebar,{
        Position=UDim2.fromOffset(8,8),
        Size=UDim2.new(1,-16,0,33),
        BackgroundColor3=Color3.fromRGB(37,16,26),
        BorderSizePixel=0,
        Text="",PlaceholderText="Buscar aba...",
        TextColor3=white,PlaceholderColor3=muted,
        TextSize=11,Font=Enum.Font.Gotham,
        ClearTextOnFocus=false
    }),8)
    obj("UIStroke",navSearch,{Color=accent,Transparency=.6,Thickness=1})
    v14.navigation={groups={},byPage={},searchBox=navSearch}
    if type(v13Data.layout)~="table" then v13Data.layout={} end
    if type(v13Data.layout.groups)~="table" then v13Data.layout.groups={} end
    local navGroupData={
        {key="MAIN",pt="PRINCIPAL",en="MAIN",es="PRINCIPAL",
            pages={"HOME","COMMANDS","PALETTE","GAMES","DASHBOARD"}},
        {key="PLAYER",pt="JOGADOR",en="PLAYER",es="JUGADOR",
            pages={"PLAYERS","TELEPORT","COMPASS","FAVORITES","BOOKMARKS","RECENT","ROUTES"}},
        {key="TOOLS",pt="FERRAMENTAS",en="TOOLS",es="HERRAMIENTAS",
            pages={"MACROS","CINEMA","AVATAR","AUDIO","PERFORMANCE","NOTES"}},
        {key="SYSTEM",pt="SISTEMA",en="SYSTEM",es="SISTEMA",
            pages={"CONSOLE","PROFILES","STATS","BACKUP","DIAGNOSTICS","GUIDE","HELP","SETTINGS","AIM"}}
    }
    for index,definition in ipairs(navGroupData) do
        local shell=obj("Frame",nav,{
            Size=UDim2.new(1,-6,0,32),
            BackgroundTransparency=1,
            LayoutOrder=index
        })
        stack(shell,4)
        local head=btn(shell,"",nil,32)
        head.Size=UDim2.new(1,0,0,32)
        head.LayoutOrder=1
        head.BackgroundColor3=Color3.fromRGB(45,14,27)
        head.TextColor3=accent
        head.TextSize=11
        local list=obj("Frame",shell,{
            Size=UDim2.new(1,0,0,0),
            BackgroundTransparency=1,
            LayoutOrder=2
        })
        stack(list,3)
        local group={
            definition=definition,button=head,frame=shell,content=list,
            expanded=v13Data.layout.groups[definition.key]==nil and index==1
                or v13Data.layout.groups[definition.key]==true,items={}
        }
        v14.navigation.groups[#v14.navigation.groups+1]=group
        for order,id in ipairs(definition.pages) do
            local tab=btn(list,id,nil,35)
            tab.LayoutOrder=order
            tab.Size=UDim2.new(1,0,0,35)
            tab.TextSize=11
            navButtons[id]=tab
            group.items[#group.items+1]=id
            v14.navigation.byPage[id]=group
        end
        bind(head.MouseButton1Click,function()
            if navSearch.Text~="" then navSearch.Text="" end
            group.expanded=not group.expanded
            v13Data.layout.groups[definition.key]=group.expanded
            saveV13()
            if v14.navigation.update then v14.navigation.update() end
        end)
    end
    v14.navigation.update=function(page)
        local query=navSearch.Text:lower():gsub("^%s+",""):gsub("%s+$","")
        for _,group in ipairs(v14.navigation.groups) do
            if query=="" and page and v14.navigation.byPage[page]==group then
                group.expanded=true
            end
            local matching=0
            for _,id in ipairs(group.items) do
                local b=navButtons[id]
                local match=(query==""
                    or id:lower():find(query,1,true)~=nil
                    or b.Text:lower():find(query,1,true)~=nil)
                    and moduleEnabled(id)
                b.Visible=match
                if match then matching=matching+1 end
            end
            group.frame.Visible=matching>0
            local open=(query~="" or group.expanded) and matching>0
            group.content.Visible=open
            -- Alturas explicitas: AutomaticSize nao expandia em alguns clientes.
            local contentHeight=open and
                (matching*35+math.max(0,matching-1)*3) or 0
            group.content.Size=UDim2.new(1,0,0,contentHeight)
            group.frame.Size=UDim2.new(1,-6,0,32+(open and 4+contentHeight or 0))
            local def=group.definition
            local language=config.lang
            local name=def[language] or def.en
            group.button.Text=(open and "[-]  " or "[+]  ")..name..
                "  ("..matching..")"
        end
    end
    bind(navSearch:GetPropertyChangedSignal("Text"),function()
        if v14.navigation.update then v14.navigation.update() end
    end)
    v14.navigation.update("HOME")
end

-- Identidade visual na base da barra lateral.
local sidePanel = round(obj("Frame",sidebar,{
    Position = UDim2.new(0,9,1,-121),
    Size = UDim2.new(1,-18,0,111),
    BackgroundColor3 = Color3.fromRGB(33,8,17),
    BorderSizePixel = 0
}),10)
obj("UIStroke",sidePanel,{Color=accent,Transparency=.4,Thickness=1})
local sideLogo = txt(sidePanel,"B  BRAB0X",29,18,true)
sideLogo.Position = UDim2.fromOffset(12,12)
sideLogo.Size = UDim2.new(1,-24,0,29)
sideLogo.TextColor3 = accent
local sideSub = txt(sidePanel,"PRIME  •  RED EDITION",22,10,true)
sideSub.Position = UDim2.fromOffset(12,47)
sideSub.Size = UDim2.new(1,-24,0,22)
sideSub.TextColor3 = white
local sideTip = txt(sidePanel,"CRIADOR: @wendezao05153nh",29,10)
sideTip.Position = UDim2.fromOffset(12,77)
sideTip.Size = UDim2.new(1,-24,0,29)
sideTip.TextColor3 = muted

local status = txt(
    main,
    "PRONTO  •  MESMO LOADER EM TODOS OS JOGOS  •  F1 AJUDA  •  CTRL+K COMANDOS",
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

local function notify(message,kind)
    if not stopped and status.Parent then
        local text=tostring(message)
        status.Text=text
        noticeCounter=noticeCounter+1
        if v13Log then v13Log(text) end
        if premiumNotify then premiumNotify(text,kind) end
    end
end

-- NOTIFICACOES PREMIUM V13.2 / TOASTS SOBREPOSTOS, REMOVIDOS AUTOMATICAMENTE
do
    local toastHost=obj("Frame",gui,{
        AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,-15,0,85),
        Size=UDim2.fromOffset(322,330),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ZIndex=86
    })
    obj("UIListLayout",toastHost,{
        FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Right,
        Padding=UDim.new(0,8),
        SortOrder=Enum.SortOrder.LayoutOrder
    })
    local scale=obj("UIScale",toastHost,{Scale=1})
    local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
    if viewport then scale.Scale=math.clamp(viewport.X/850,.72,1) end
    local visible={}
    local sequence=0
    local previousText,previousAt=nil,0

    local function removeToast(frame)
        for i,item in ipairs(visible) do
            if item==frame then
                table.remove(visible,i)
                break
            end
        end
        if not frame.Parent then return end
        local animation=Tween:Create(frame,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
            Size=UDim2.new(1,0,0,0),
            BackgroundTransparency=1
        })
        animation:Play()
        task.delay(.22,function()
            if frame.Parent then frame:Destroy() end
        end)
    end

    premiumNotify=function(message,kind)
        if stopped or config.notifications==false or not gui.Parent then return end
        local full=tostring(message or "")
        if full=="" then return end
        local now=os.clock()
        if full==previousText and now-previousAt<.75 then return end
        previousText,previousAt=full,now
        local low=full:lower()
        if kind~="success" and kind~="error" and kind~="info" then
            if low:find("erro",1,true) or low:find("indispon",1,true)
                or low:find("nao encontrado",1,true) or low:find("desconhecido",1,true) then
                kind="error"
            elseif full:sub(1,3)=="OK:" then
                kind="success"
            else
                kind="info"
            end
        end
        local title=kind=="success" and "✓  COMANDO EXECUTADO"
            or kind=="error" and "!  ATENCAO"
            or "✦  BRAB0X PRIME"
        local tone=kind=="error" and Color3.fromRGB(255,75,83)
            or kind=="success" and Color3.fromRGB(255,48,72)
            or accent

        if #visible>=3 then
            local oldest=table.remove(visible,1)
            if oldest and oldest.Parent then oldest:Destroy() end
        end
        sequence=sequence+1
        local frame=round(obj("Frame",toastHost,{
            Size=UDim2.new(1,0,0,0),
            BackgroundColor3=Color3.fromRGB(15,12,19),
            BackgroundTransparency=.08,
            BorderSizePixel=0,
            ClipsDescendants=true,
            LayoutOrder=sequence,
            ZIndex=87
        }),12)
        obj("UIStroke",frame,{Color=tone,Thickness=1.3,Transparency=.2})
        local bar=obj("Frame",frame,{
            Size=UDim2.fromOffset(4,70),
            Position=UDim2.fromOffset(0,0),
            BackgroundColor3=tone,BorderSizePixel=0,ZIndex=88
        })
        local label=txt(frame,title,23,12,true)
        label.Position=UDim2.fromOffset(17,8)
        label.Size=UDim2.new(1,-49,0,23)
        label.TextColor3=tone
        label.ZIndex=88
        local body=txt(frame,full:sub(1,155),34,11)
        body.Position=UDim2.fromOffset(17,31)
        body.Size=UDim2.new(1,-31,0,34)
        body.TextColor3=white
        body.ZIndex=88
        local dismiss=obj("TextButton",frame,{
            Size=UDim2.fromOffset(25,22),
            Position=UDim2.new(1,-29,0,7),
            BackgroundTransparency=1,
            Text="×",
            Font=Enum.Font.GothamBold,
            TextSize=17,
            TextColor3=muted,
            ZIndex=89
        })
        bind(dismiss.MouseButton1Click,function()
            removeToast(frame)
        end)
        local duration=obj("Frame",frame,{
            Position=UDim2.new(0,4,1,-3),
            Size=UDim2.new(1,-4,0,3),
            BackgroundColor3=tone,
            BorderSizePixel=0,
            ZIndex=88
        })
        visible[#visible+1]=frame
        Tween:Create(frame,TweenInfo.new(.23,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
            Size=UDim2.new(1,0,0,72)
        }):Play()
        Tween:Create(duration,TweenInfo.new(3.55,Enum.EasingStyle.Linear),{
            Size=UDim2.new(0,0,0,3)
        }):Play()
        task.delay(3.6,function()
            if not stopped then removeToast(frame) end
        end)
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
        b.BackgroundColor3 = name == page and Color3.fromRGB(112,13,31) or control
        b.TextColor3 = white
        local border = b:FindFirstChildOfClass("UIStroke")
        if border then
            border.Color = name == page and accent or Color3.fromRGB(88,38,45)
            border.Transparency = name == page and .08 or .56
        end
    end
    if v14.navigation and v14.navigation.update then
        v14.navigation.update(page)
    end
    if refreshV13Page then refreshV13Page(page) end
    if page=="HELP" and refreshHelpPage then refreshHelpPage() end
    if v14.refresh then v14.refresh(page) end
    if v14.v17 and v14.v17.refresh then v14.v17.refresh(page) end
end

for name,b in pairs(navButtons) do
    bind(b.MouseButton1Click,function()
        show(name)
    end)
end

local function relabel()
    local labels = L[config.lang] or L.en

    local more={
        pt={PLAYERS="Jogadores",FAVORITES="Favoritos",TELEPORT="Teleporte",CONSOLE="Console",PROFILES="Perfis",PERFORMANCE="Desempenho",HELP="Ajuda",RECENT="Recentes",MACROS="Macros",CINEMA="Cinema",ROUTES="Rotas",AVATAR="Avatar",AUDIO="Audio",STATS="Estatisticas",DASHBOARD="Dashboard",GAMES="Jogos",PALETTE="Busca rapida",COMPASS="Bussola",NOTES="Notas",BACKUP="Backup",DIAGNOSTICS="Diagnostico",GUIDE="Guia",BOOKMARKS="Fav. do jogo"},
        en={PLAYERS="Players",FAVORITES="Favorites",TELEPORT="Teleport",CONSOLE="Console",PROFILES="Profiles",PERFORMANCE="Performance",HELP="Help",RECENT="Recent",MACROS="Macros",CINEMA="Cinema",ROUTES="Routes",AVATAR="Avatar",AUDIO="Audio",STATS="Statistics",DASHBOARD="Dashboard",GAMES="Games",PALETTE="Quick search",COMPASS="Compass",NOTES="Notes",BACKUP="Backup",DIAGNOSTICS="Diagnostics",GUIDE="Guide",BOOKMARKS="Game favorites"},
        es={PLAYERS="Jugadores",FAVORITES="Favoritos",TELEPORT="Teletransporte",CONSOLE="Consola",PROFILES="Perfiles",PERFORMANCE="Rendimiento",HELP="Ayuda",RECENT="Recientes",MACROS="Macros",CINEMA="Cine",ROUTES="Rutas",AVATAR="Avatar",AUDIO="Audio",STATS="Estadisticas",DASHBOARD="Panel",GAMES="Juegos",PALETTE="Busqueda",COMPASS="Brujula",NOTES="Notas",BACKUP="Backup",DIAGNOSTICS="Diagnostico",GUIDE="Guia",BOOKMARKS="Favoritos juego"},
    }
    for _,name in ipairs(navOrder) do
        local i=table.find(sections,name)
        local label=more[config.lang] and more[config.lang][name] or nil
        navButtons[name].Text="   "..(label or (i and i<=9 and labels[i]) or name)
    end
    if v14.navigation and v14.navigation.update then
        v14.navigation.update()
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

local aimKey = "BRAB0X_V17_1_AIM"
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
        if applyV13Appearance then applyV13Appearance() end
        saveV13()
    end
end,"theme red")

register("scale","SETTINGS","Tamanho do painel",function(a)
    config.scale = num(a,1,.6,1.25)
    responsive()
    saveV13()
end,"scale 0.8")

register("lang","SETTINGS","Idioma do menu",function(a)
    if L[a] then
        config.lang = a
        relabel()
        if v14.translate then v14.translate() end
        saveV13()
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
    saveV13()
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
    lastPosition=nil,
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
-- Waypoints persistentes armazenados como coordenadas locais.
for name,coords in pairs(v13Data.waypoints) do
    if type(name)=="string" and type(coords)=="table" and
        tonumber(coords[1]) and tonumber(coords[2]) and tonumber(coords[3]) then
        extraState.savedWaypoints[name]=CFrame.new(coords[1],coords[2],coords[3])
    end
end
local function syncWaypoints()
    local saved={}
    for name,cf in pairs(extraState.savedWaypoints) do
        local pos=cf.Position
        saved[name]={pos.X,pos.Y,pos.Z}
    end
    v13Data.waypoints=saved
    saveV13()
    if updateTeleportPanel then updateTeleportPanel() end
end
local lowFXState={}
local lowFXActive=false
local function restoreLowFX()
    if not lowFXActive then return end
    for effect,enabled in pairs(lowFXState) do
        if effect.Parent then pcall(function() effect.Enabled=enabled end) end
    end
    lowFXState={}
    lowFXActive=false
end
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
    extraState.lastPosition=r.CFrame
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
    restoreLowFX()
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
    syncWaypoints()
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
    syncWaypoints()
end,"delwp casa")
register("clearwps","PLAYER","Apagar todos os waypoints",function()
    extraState.savedWaypoints={}
    syncWaypoints()
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
    notify("BRAB0X PRIME V17.1 | Criador: @wendezao05153nh")
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

-- V13: comandos para favoritos, perfis, teclas e desempenho.
local function favoritesChanged()
    saveV13()
    if updateFavoritePanel then updateFavoritePanel() end
    if refreshCommandList then refreshCommandList() end
end
local function profileSnapshot()
    local _,hum=chars()
    local camera=workspace.CurrentCamera
    return {
        speed=S.speed,boost=S.boost,boostX=S.boostX,
        fov=camera and camera.FieldOfView or 70,
        walk=hum and hum.WalkSpeed or 16,
        jump=hum and hum.JumpPower or 50,
        theme=config.theme,scale=config.scale,
        compact=config.compact,opacity=config.opacity,
        neon=config.neon,animations=config.animations,
        aimEnabled=config.aimEnabled
    }
end
local function profileName(a)
    local name=tostring(a or ""):gsub("^%s+",""):gsub("%s+$","")
    if #name<1 or #name>24 or not name:match("^[%w_%-]+$") then
        notify("Nome do perfil: 1 a 24 caracteres (letras, numeros, _ ou -)")
        return nil
    end
    return name:lower()
end
local function saveProfile(a)
    local name=profileName(a)
    if not name then return false end
    v13Data.profiles[name]=profileSnapshot()
    saveV13()
    if updateProfilePanel then updateProfilePanel() end
    notify("Perfil salvo: "..name)
    return false
end
local function loadProfile(a)
    local name=profileName(a)
    if not name then return false end
    local p=v13Data.profiles[name]
    if type(p)~="table" then notify("Perfil nao encontrado: "..name); return false end
    config.theme=palette[p.theme] and p.theme or "red"
    config.scale=math.clamp(tonumber(p.scale) or 1,.6,1.25)
    config.compact=p.compact==true
    config.opacity=math.clamp(tonumber(p.opacity) or 0,0,.45)
    config.neon=math.clamp(tonumber(p.neon) or 1,.25,2)
    config.animations=p.animations~=false
    config.aimEnabled=p.aimEnabled==true
    S.speed=math.clamp(tonumber(p.speed) or S.speed,10,300)
    S.boost=p.boost==true
    S.boostX=math.clamp(tonumber(p.boostX) or S.boostX,1,5)
    local camera=workspace.CurrentCamera
    if camera then camera.FieldOfView=math.clamp(tonumber(p.fov) or 70,40,120) end
    local _,hum=chars()
    if hum then
        remember(hum)
        hum.WalkSpeed=math.clamp(tonumber(p.walk) or 16,0,100)
        hum.UseJumpPower=true
        hum.JumpPower=math.clamp(tonumber(p.jump) or 50,0,200)
    end
    if applyV13Appearance then applyV13Appearance() end
    responsive()
    show("HOME")
    saveV13()
    notify("Perfil aplicado: "..name)
    return false
end
register("favorite","SETTINGS","Adicionar comando aos favoritos",function(a)
    local name=tostring(a or ""):lower():match("^%s*(%S+)")
    if not name or not byName[name] then notify("Use: favorite fly"); return false end
    v13Data.favorites[name]=true
    favoritesChanged()
    notify("Favorito: "..name)
    return false
end,"favorite fly")
alias("fav","SETTINGS","Alias favorito","favorite","fav fly")
register("unfavorite","SETTINGS","Remover favorito",function(a)
    local name=tostring(a or ""):lower():match("^%s*(%S+)")
    if not name then return false end
    v13Data.favorites[name]=nil
    favoritesChanged()
    notify("Favorito removido: "..name)
    return false
end,"unfavorite fly")
register("favorites","SETTINGS","Abrir favoritos",function()show("FAVORITES")end)
register("openplayers","SETTINGS","Abrir lista de jogadores",function()show("PLAYERS")end)
register("openteleport","SETTINGS","Abrir waypoints",function()show("TELEPORT")end)
register("openconsole","SETTINGS","Abrir console",function()show("CONSOLE")end)
register("openprofiles","SETTINGS","Abrir perfis",function()show("PROFILES")end)
register("openperformance","SETTINGS","Abrir painel de FPS e ping",function()show("PERFORMANCE")end)
register("saveprofile","SETTINGS","Salvar perfil",saveProfile,"saveprofile explorer")
register("loadprofile","SETTINGS","Carregar perfil",loadProfile,"loadprofile explorer")
register("deleteprofile","SETTINGS","Apagar perfil",function(a)
    local name=profileName(a)
    if not name then return false end
    v13Data.profiles[name]=nil
    saveV13()
    if updateProfilePanel then updateProfilePanel() end
    notify("Perfil excluido: "..name)
    return false
end,"deleteprofile explorer")
register("bindkey","SETTINGS","Associar tecla a funcao",function(a)
    local action,key=tostring(a or ""):match("^(%S+)%s+(%S+)$")
    action=action and action:upper()
    if not action or not defaultKeys[action] or not key or not Enum.KeyCode[key] then
        notify("Use: bindkey FLY G (FLY, MENU, NOCLIP, BOOST, INVIS)")
        return false
    end
    for other,bound in pairs(v13Data.keybinds) do
        if other~=action and bound==key then
            notify("Tecla em uso por "..other)
            return false
        end
    end
    v13Data.keybinds[action]=key
    saveV13()
    notify("Tecla "..key.." atribuida a "..action)
    return false
end,"bindkey FLY G")
register("resetkeys","SETTINGS","Restaurar atalhos padrao",function()
    for name,key in pairs(defaultKeys) do v13Data.keybinds[name]=key end
    saveV13()
    notify("Atalhos restaurados")
    return false
end)
register("back","PLAYER","Voltar a posicao antes do ultimo teleporte",function()
    if not extraState.lastPosition then notify("Nenhum teleporte anterior"); return false end
    return selfTeleport(extraState.lastPosition)
end)
register("lowgfx","WORLD","Reduzir efeitos visuais locais",function()
    if not lowFXActive then
        lowFXActive=true
        lowFXState={}
        for _,effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect")
                or effect:IsA("SunRaysEffect") then
                lowFXState[effect]=effect.Enabled
                effect.Enabled=false
            end
        end
    end
    Lighting.GlobalShadows=false
end)
register("resetgfx","WORLD","Restaurar efeitos visuais",function()
    restoreLowFX()
    Lighting.GlobalShadows=extraState.originalShadows
end)
register("compact","SETTINGS","Alternar modo compacto",function()
    config.compact=not config.compact
    responsive()
    saveV13()
end)
register("animations","SETTINGS","Animacoes do menu on/off",function(a)
    config.animations=a~="off"
    saveV13()
end,"animations off")
register("opacity","SETTINGS","Transparencia da interface",function(a)
    config.opacity=math.clamp(tonumber(a) or 0,0,.45)
    if applyV13Appearance then applyV13Appearance() end
    saveV13()
end,"opacity 0.2")
register("neon","SETTINGS","Intensidade de neon",function(a)
    config.neon=math.clamp(tonumber(a) or 1,.25,2)
    if applyV13Appearance then applyV13Appearance() end
    saveV13()
end,"neon 1.5")

register("creator","SETTINGS","Mostrar criador do BRAB0X PRIME",function()
    notify("BRAB0X PRIME | Criado por @wendezao05153nh")
    return false
end)
alias("author","SETTINGS","Alias de creator","creator")
register("manual","SETTINGS","Abrir central de ajuda",function()
    show("HELP")
end)
register("helpcommand","SETTINGS","Ver explicacao de um comando",function(a)
    local name=tostring(a or ""):lower():match("^%s*(%S+)")
    if name and byName[name] and openCommandHelp then
        openCommandHelp(name)
    else
        notify("Use: helpcommand fly ou pesquise na aba Ajuda","info")
    end
    return false
end,"helpcommand goto")
register("notifications","SETTINGS","Ligar ou desligar notificacoes premium",function(a)
    if a=="on" then config.notifications=true
    elseif a=="off" then config.notifications=false
    else config.notifications=not config.notifications end
    saveV13()
    notify("Notificacoes premium: "..(config.notifications and "ON" or "OFF"),"info")
    return false
end,"notifications on")
register("notifytest","SETTINGS","Testar uma notificacao",function()
    notify("BRAB0X PRIME • Notificacoes funcionando!","success")
    return false
end)
-- V16 / LOCALIZACAO RAPIDA DE FERRAMENTAS, SEM MUDAR AS FUNCOES ANTERIORES
register("tab","SETTINGS","Abrir aba pelo nome",function(arg)
    local id=tostring(arg or ""):upper():gsub("^%s+",""):gsub("%s+$","")
    if pages[id] and moduleEnabled(id) then
        if v14.navigation and v14.navigation.searchBox then
            v14.navigation.searchBox.Text=""
        end
        show(id)
        notify("Aba aberta: "..id,"success")
    else
        notify("Aba nao encontrada. Use: tab games, tab macros, tab help","error")
    end
    return false
end,"tab macros")
register("findtab","SETTINGS","Pesquisar abas pelo menu lateral",function()
    main.Visible=true
    reopen.Visible=false
    if v14.navigation and v14.navigation.searchBox then
        v14.navigation.searchBox:CaptureFocus()
    end
    return false
end)

-- V14 / NUCLEO DOS RECURSOS (SEM CODIGO REMOTO NEM EFEITO EM OUTROS JOGADORES)
do
    local function trimmed(a)
        return tostring(a or ""):gsub("^%s+",""):gsub("%s+$","")
    end
    local function argParts(raw)
        local pieces={}
        for part in tostring(raw or ""):gmatch("%S+") do pieces[#pieces+1]=part end
        return pieces
    end
    local function validName(x)
        x=trimmed(x):lower()
        return #x>0 and #x<=26 and x:match("^[%w_%-]+$") and x or nil
    end
    local function save()
        saveV13()
        if v14.refresh then v14.refresh(selected) end
    end
    local blocked={
        resetall=true,clearwps=true,worldreset=true,close=true,
        resetgfx=false,delwp=true,deleteprofile=true,resetkeys=true
    }
    v14.pending=nil
    v14.requiresConfirmation=function(name,arg)
        if not v14.safe or not blocked[name] then return false end
        local token=name.." "..tostring(arg or "")
        if v14.pending and v14.pending.token==token
            and os.clock()-v14.pending.time<=8 then
            v14.pending=nil
            return false
        end
        v14.pending={token=token,time=os.clock()}
        notify("MODO SEGURO: repita "..token.." em ate 8 segundos para confirmar.","info")
        return true
    end
    v14.trackCommand=function(name,raw)
        v14.commandsInSession=v14.commandsInSession+1
        v14.stats.commandCount=(tonumber(v14.stats.commandCount) or 0)+1
        v14.stats.frequency[name]=(tonumber(v14.stats.frequency[name]) or 0)+1
        table.insert(v14.recent,1,{command=name,raw=raw,time=os.date("%H:%M:%S")})
        if #v14.recent>35 then table.remove(v14.recent) end
        if v14.commandsInSession%5==0 then saveV13() end
        if v14.refresh and (selected=="RECENT" or selected=="STATS" or selected=="DASHBOARD") then
            v14.refresh(selected)
        end
    end
    v14.macroActions={
        fly=true,unfly=true,flystatus=true,speed=true,speedreset=true,
        boost=true,unboost=true,glow=true,unglow=true,trail=true,untrail=true,
        crosshair=true,zoomout=true,zoomin=true,fov=true,first=true,third=true,
        brightness=true,day=true,night=true,sunset=true,fullbright=true,
        unfullbright=true,walk=true,jump=true,savepos=true,
        transparency=true,visible=true
    }
    v14.macroSave=function(name,list)
        name=validName(name)
        if not name then notify("Nome da macro: letras/numeros, 1 a 26 caracteres.","error");return false end
        local cmds={}
        for chunk in tostring(list or ""):gmatch("[^;]+") do
            local cmd=trimmed(chunk)
            local first=cmd:match("^(%S+)")
            if first and cmd~="" then
                if not v14.macroActions[first:lower()] or not byName[first:lower()] then
                    notify("Macro: comando nao permitido ou desconhecido: "..first,"error")
                    return false
                end
                cmds[#cmds+1]=cmd
            end
        end
        if #cmds<1 or #cmds>12 then
            notify("Macros precisam de 1 a 12 comandos, separados por ;","error")
            return false
        end
        v14.macros[name]=cmds
        save()
        notify("Macro "..name.." salva com "..#cmds.." comandos.","success")
        return true
    end
    v14.macroRun=function(name)
        name=validName(name)
        local cmds=name and v14.macros[name]
        if type(cmds)~="table" then notify("Macro nao encontrada.","error");return false end
        if v14.macroRunning then notify("Ja existe uma macro em execucao.","error");return false end
        v14.macroRunning=true
        for i,command in ipairs(cmds) do
            if stopped then break end
            local first=command:match("^(%S+)")
            if first and byName[first:lower()] and v14.macroActions[first:lower()] then
                exec(command)
            end
        end
        v14.macroRunning=false
        notify("Macro executada: "..name,"success")
        return true
    end
    v14.macroDelete=function(name)
        name=validName(name)
        if not name or not v14.macros[name] then return false end
        v14.macros[name]=nil
        save()
        return true
    end
    v14.routeSave=function(raw)
        local parts=argParts(raw)
        local route=validName(table.remove(parts,1))
        if not route or #parts==0 or #parts>20 then
            notify("Use: routesave rota ponto1 ponto2 (1 a 20 pontos salvos).","error")
            return false
        end
        local steps={}
        for _,name in ipairs(parts) do
            name=validName(name)
            if not name or not extraState.savedWaypoints[name] then
                notify("Waypoint nao encontrado: "..tostring(name),"error")
                return false
            end
            steps[#steps+1]=name
        end
        v14.routes[route]=steps
        v14.selectedRoute=route
        v14.routeIndex=1
        save()
        notify("Rota salva: "..route.." ("..#steps.." pontos).","success")
        return true
    end
    v14.routeStart=function(name)
        name=validName(name)
        local route=name and v14.routes[name]
        if type(route)~="table" or #route<1 then
            notify("Rota nao encontrada.","error")
            return false
        end
        v14.selectedRoute=name
        v14.routeIndex=1
        notify("Rota "..name..": proximo ponto "..route[1]..". Use routenext.","info")
        if v14.refresh then v14.refresh("ROUTES") end
        return true
    end
    v14.routeNext=function()
        local route=v14.selectedRoute and v14.routes[v14.selectedRoute]
        if type(route)~="table" then
            notify("Abra uma rota com routestart nome.","error")
            return false
        end
        local index=v14.routeIndex or 1
        if index>#route then notify("Rota concluida!","success");return false end
        local wp=route[index]
        if not extraState.savedWaypoints[wp] then
            notify("Ponto removido: "..wp,"error");return false
        end
        local entry=byName.gowp
        if not entry then return false end
        local success,result=pcall(entry.run,wp)
        if not success or result==false then
            notify("Falha ao acessar waypoint: "..tostring(result),"error")
            return false
        end
        v14.routeIndex=index+1
        notify("Rota: "..wp.." ("..index.."/"..#route..")","success")
        return true
    end
    v14.routeDelete=function(name)
        name=validName(name)
        if not name or not v14.routes[name] then return false end
        v14.routes[name]=nil
        if v14.selectedRoute==name then v14.selectedRoute=nil end
        save()
        return true
    end
    v14.cinemaSpeed=18
    v14.cinemaLook=nil
    v14.startCinema=function()
        if v14.cinematic then return true end
        local cam=workspace.CurrentCamera
        if not cam then return false end
        v14.cinemaSaved={type=cam.CameraType,cf=cam.CFrame,subject=cam.CameraSubject,fov=cam.FieldOfView}
        v14.cinematic=true
        cam.CameraType=Enum.CameraType.Scriptable
        -- Segurar botao direito do mouse gira a camera, sem mover o avatar.
        v14.cinemaLook=UIS.InputChanged:Connect(function(input)
            if not v14.cinematic or not workspace.CurrentCamera then return end
            if input.UserInputType==Enum.UserInputType.MouseMovement
                and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local delta=input.Delta
                local current=workspace.CurrentCamera
                local rotation=CFrame.Angles(0,-delta.X*.003,0)
                local tilt=CFrame.Angles(-delta.Y*.003,0,0)
                current.CFrame=current.CFrame*rotation*tilt
            end
        end)
        v14.cinemaConnection=Run.RenderStepped:Connect(function(dt)
            if stopped or not v14.cinematic then return end
            local current=workspace.CurrentCamera
            if not current then return end
            local vec=Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then vec=vec+current.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then vec=vec-current.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then vec=vec-current.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then vec=vec+current.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.E) then vec=vec+Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.Q) then vec=vec-Vector3.yAxis end
            if vec.Magnitude>0 then
                local speed=v14.cinemaSpeed*(UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 2.5 or 1)
                current.CFrame=current.CFrame+vec.Unit*speed*math.min(dt,.1)
            end
        end)
        main.Visible=false
        reopen.Visible=false
        notify("Modo cinema: WASD para mover, E/Q altura, Shift acelera, F6 sai.","info")
        return true
    end
    v14.stopCinema=function()
        if not v14.cinematic then return end
        v14.cinematic=false
        if v14.cinemaConnection then v14.cinemaConnection:Disconnect() v14.cinemaConnection=nil end
        if v14.cinemaLook then v14.cinemaLook:Disconnect() v14.cinemaLook=nil end
        local cam=workspace.CurrentCamera
        if cam then
            cam.CameraType=Enum.CameraType.Custom
            local _,hum=chars()
            cam.CameraSubject=hum or (v14.cinemaSaved and v14.cinemaSaved.subject) or cam.CameraSubject
            if v14.cinemaSaved then cam.FieldOfView=v14.cinemaSaved.fov end
        end
        v14.cinemaSaved=nil
        main.Visible=true
        reopen.Visible=false
    end
    v14.avatarRestore=function()
        for part,oldStyle in pairs(v14.avatarParts) do
            if part.Parent then
                pcall(function()
                    part.Color=oldStyle.color
                    part.Material=oldStyle.material
                    part.LocalTransparencyModifier=oldStyle.transparency
                end)
            end
        end
        v14.avatarParts={}
    end
    v14.avatarApply=function(colorName)
        v14.avatarRestore()
        if colorName=="restore" then return true end
        local colors={
            red=Color3.fromRGB(230,32,59),
            black=Color3.fromRGB(27,25,30),
            white=Color3.fromRGB(230,230,230),
            blue=Color3.fromRGB(40,125,245),
            gold=Color3.fromRGB(255,191,52)
        }
        local target=colors[colorName]
        if not target then return false end
        local character=player.Character
        if not character then return false end
        for _,part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                v14.avatarParts[part]={
                    color=part.Color,material=part.Material,
                    transparency=part.LocalTransparencyModifier
                }
                part.Color=target
            end
        end
        notify("Avatar "..colorName.." aplicado apenas no seu cliente.","info")
        return true
    end
    v14.musicStop=function()
        if v14.music then
            pcall(function()v14.music:Stop()v14.music:Destroy()end)
            v14.music=nil
        end
    end
    v14.musicPlay=function(raw)
        local id=tostring(raw or ""):match("(%d+)")
        if not id or #id>18 or tonumber(id)<=0 then
            notify("Insira um ID de audio do Roblox autorizado para seu jogo.","error")
            return false
        end
        v14.musicStop()
        local sound=obj("Sound",game:GetService("SoundService"),{
            Name="BRAB0X_V14_LOCAL_AUDIO",
            SoundId="rbxassetid://"..id,
            Volume=math.clamp(tonumber(v14.musicVolume) or .35,0,1),
            Looped=true
        })
        v14.music=sound
        v14.musicId=id
        sound:Play()
        notify("Tentando reproduzir audio autorizado ID "..id.." (depende de permissao).","info")
        return true
    end
    v14.musicVolume=.35
    v14.cleanup=function()
        v14.stopCinema()
        v14.avatarRestore()
        v14.musicStop()
        if v14.wheelFrame and v14.wheelFrame.Parent then v14.wheelFrame:Destroy() end
        v14.wheelOpen=false
    end

    register("recent","SETTINGS","Abrir comandos recentes",function()show("RECENT")end)
    register("wheel","SETTINGS","Abrir Command Wheel",function()
        if v14.toggleWheel then v14.toggleWheel() end
    end)
    register("macros","SETTINGS","Abrir gerenciador de macros",function()show("MACROS")end)
    register("macrosave","SETTINGS","Salvar macro: nome e comandos separados por ;",function(a)
        local name,body=tostring(a or ""):match("^(%S+)%s+(.+)$")
        if not name then notify("Use: macrosave nome speed 60; fov 80","error");return false end
        return v14.macroSave(name,body)
    end,"macrosave explorar speed 65; fov 80")
    register("macrorun","SETTINGS","Executar macro salva",function(a)
        return v14.macroRun(a)
    end,"macrorun explorar")
    register("macrodelete","SETTINGS","Excluir macro salva",function(a)
        return v14.macroDelete(a)
    end,"macrodelete explorar")
    register("cinema","CAMERA","Ativar modo cinematografico livre",function()
        return v14.startCinema()
    end)
    register("uncinema","CAMERA","Voltar a camera do avatar",function()
        v14.stopCinema()
    end)
    register("cinemaspeed","CAMERA","Ajustar velocidade da camera livre",function(a)
        v14.cinemaSpeed=math.clamp(tonumber(a) or 18,2,70)
    end,"cinemaspeed 20")
    register("routes","PLAYER","Abrir rotas de exploracao",function()show("ROUTES")end)
    register("routesave","PLAYER","Salvar rota de waypoints",function(a)
        return v14.routeSave(a)
    end,"routesave passeio casa loja")
    register("routestart","PLAYER","Selecionar rota de exploracao",function(a)
        return v14.routeStart(a)
    end,"routestart passeio")
    register("routenext","PLAYER","Avancar para proximo waypoint",function()
        return v14.routeNext()
    end)
    register("routedelete","PLAYER","Excluir rota",function(a)
        return v14.routeDelete(a)
    end,"routedelete passeio")
    register("avatarlocal","PLAYER","Cor local do avatar",function(a)
        return v14.avatarApply(trimmed(a):lower())
    end,"avatarlocal red")
    register("restoreavatar","PLAYER","Restaurar visual local",function()
        return v14.avatarApply("restore")
    end)
    register("music","SETTINGS","Reproduzir audio autorizado por ID",function(a)
        return v14.musicPlay(a)
    end,"music 123456789")
    register("stopmusic","SETTINGS","Parar audio local",function()
        v14.musicStop()
    end)
    register("musicvolume","SETTINGS","Ajustar volume local de 0 a 1",function(a)
        v14.musicVolume=math.clamp(tonumber(a) or .35,0,1)
        if v14.music then v14.music.Volume=v14.musicVolume end
    end,"musicvolume 0.4")
    register("safemode","SETTINGS","Modo seguro para comandos destrutivos",function(a)
        v14.safe=a=="on" or (a~="off" and not v14.safe)
        notify("Modo seguro: "..(v14.safe and "ON" or "OFF"))
        return false
    end,"safemode on")
    register("dashboard","SETTINGS","Dashboard de atalhos",function()show("DASHBOARD")end)
    register("hubstats","SETTINGS","Estatisticas do hub",function()show("STATS")end)
    register("gamepad","SETTINGS","Modo navegacao por controle",function(a)
        v14.controllerMode=a=="on" or (a~="off" and not v14.controllerMode)
        notify("Gamepad: "..(v14.controllerMode and "ON" or "OFF"))
        return false
    end,"gamepad on")
end

-- V15 / SISTEMA UNIVERSAL DE JOGOS - ROTAS DECLARATIVAS, SEM EXECUCAO REMOTA
-- O mesmo arquivo BRAB0X_PRIME.lua escolhe o perfil pelo PlaceId.
-- API opcional para futuras atualizacoes:
-- v14.router.registerModule("123456789",{
--     name="Modulo de Meu Jogo",
--     description="Recursos permitidos do meu proprio jogo",
--     quick={"fly","unfly","manual","gameinfo"}
-- })
-- Nunca importar codigo desconhecido por URL nem contornar a logica do servidor.
do
    local router=v14.router
    local forbiddenQuick={
        close=true, resetall=true, clearwps=true, delwp=true,
        deleteprofile=true, resetkeys=true, worldreset=true,
        macrodelete=true, routedelete=true, gameremove=true,
        gameprofile=true
    }
    local prefKeys={"theme","lang","scale","aimEnabled","compact","animations",
        "opacity","neon","notifications"}

    local function cleaned(text,maxLen)
        return tostring(text or ""):gsub("[%c]",""):gsub("^%s+","")
            :gsub("%s+$",""):sub(1,maxLen or 38)
    end
    local function validPlace(text)
        local id=cleaned(text,22)
        if #id<1 or #id>19 or id:match("^%d+$")==nil then return nil end
        -- Evita arredondar PlaceIds grandes convertendo-os para number.
        id=id:gsub("^0+","")
        return id~="" and id or "0"
    end
    local function currentSnapshot()
        local camera=workspace.CurrentCamera
        return {
            speed=S.speed,boostX=S.boostX,
            fov=camera and camera.FieldOfView or 70,
            focus=selected,
            updated=os.time()
        }
    end
    local function capturePrefs()
        local output={}
        for _,key in ipairs(prefKeys) do output[key]=config[key] end
        return output
    end
    local function safeQuick(input)
        local cmd=cleaned(input,90)
        if #cmd==0 then return nil end
        local first=cmd:match("^(%S+)")
        if not first or not byName[first:lower()] or forbiddenQuick[first:lower()] then
            return nil
        end
        if first:lower()=="aim" and not config.aimEnabled then return nil end
        return cmd
    end
    router.safeQuick=safeQuick
    router.registerModule=function(placeId,module)
        local raw=tostring(placeId or "")
        local universe=raw:match("^universe:(%d+)$")
        local id=universe and ("universe:"..(validPlace(universe) or ""))
            or validPlace(raw)
        if not id or id=="universe:" or type(module)~="table"
            or type(module.name)~="string" then
            return false
        end
        local desc={
            name=cleaned(module.name,42),
            description=cleaned(module.description or "",110),
            quick={}
        }
        if type(module.quick)=="table" then
            for _,cmd in ipairs(module.quick) do
                local safe=safeQuick(cmd)
                if safe and #desc.quick<6 then desc.quick[#desc.quick+1]=safe end
            end
        end
        router.modules[id]=desc
        if router.detect then router.detect() end
        return true
    end
    router.detect=function()
        local mod=router.modules[router.placeId]
        if not mod and router.universeId~="0" then
            mod=router.modules["universe:"..router.universeId]
        end
        router.currentModule=mod
        router.moduleQuick=mod and mod.quick or nil
        router.detected=mod and mod.name or
            (router.profile.mode=="custom" and "PERFIL DO JOGO" or "MODO UNIVERSAL")
        return router.detected
    end
    -- Modulos incluidos neste arquivo podem ser registrados ANTES do initialize.
    -- Exemplo: v14.router.registerModule("SEU_PLACE_ID",{name="Meu Jogo",quick={"fly"}})
    -- Sem PlaceId fornecido, nao ha modulo personalizado predefinido.
    router.detect()
    router.capture=currentSnapshot
    router.save=function()
        saveV13()
        if v14.refresh then v14.refresh("GAMES") end
    end
    router.setLabel=function(newName)
        local name=cleaned(newName,36)
        if name=="" then
            notify("Digite um nome de 1 a 36 caracteres para este jogo.","error")
            return false
        end
        router.profile.label=name
        router.save()
        notify("Nome do jogo salvo: "..name,"success")
        return true
    end
    router.setMode=function(mode)
        if mode~="universal" and mode~="custom" then return false end
        router.profile.mode=mode
        if mode=="custom" then
            router.profile.preferences=capturePrefs()
            router.profile.runtime=currentSnapshot()
        end
        router.detect()
        router.save()
        notify("Jogo "..router.placeId.." agora usa "..router.detected,"success")
        return true
    end
    router.saveProfile=function()
        router.profile.mode="custom"
        router.profile.preferences=capturePrefs()
        router.profile.runtime=currentSnapshot()
        router.detect()
        router.save()
        notify("Preferencias e velocidade salvas para o jogo "..router.placeId,"success")
        return true
    end
    router.applyProfile=function()
        if type(router.profile.preferences)~="table" then
            notify("Salve um perfil para este jogo antes de carregar.","info")
            return false
        end
        router.profile.mode="custom"
        for _,key in ipairs(prefKeys) do
            if router.profile.preferences[key]~=nil then
                config[key]=router.profile.preferences[key]
            end
        end
        local runtime=router.profile.runtime
        if type(runtime)=="table" then
            S.speed=math.clamp(tonumber(runtime.speed) or S.speed,10,300)
            S.boostX=math.clamp(tonumber(runtime.boostX) or S.boostX,1,5)
            local camera=workspace.CurrentCamera
            if camera then
                camera.FieldOfView=math.clamp(tonumber(runtime.fov) or camera.FieldOfView,40,120)
            end
        end
        relabel()
        if v14.translate then v14.translate() end
        router.detect()
        router.save()
        if applyV13Appearance then applyV13Appearance() end
        if refresh then refresh() end
        notify("Perfil carregado para o jogo "..router.placeId,"info")
        return true
    end
    router.useUniversal=function()
        router.profile.mode="universal"
        for _,key in ipairs(prefKeys) do
            if v13Data.universalPrefs[key]~=nil then
                config[key]=v13Data.universalPrefs[key]
            end
        end
        router.detect()
        router.save()
        relabel()
        if v14.translate then v14.translate() end
        if applyV13Appearance then applyV13Appearance() end
        if refresh then refresh() end
        notify("BRAB0X universal ativado. Comandos antigos preservados.","success")
        return true
    end
    router.setQuicks=function(commands)
        if type(commands)~="table" then return false end
        local out={}
        for _,command in ipairs(commands) do
            local cmd=safeQuick(command)
            if not cmd then
                notify("Atalho invalido: "..tostring(command),"error")
                return false
            end
            out[#out+1]=cmd
            if #out>=6 then break end
        end
        if #out<1 then return false end
        router.profile.quick=out
        router.profile.customQuick=true
        router.save()
        notify("Atalhos salvos para "..router.profile.label,"success")
        return true
    end
    router.registerGame=function(placeId,label)
        local id=validPlace(placeId)
        local name=cleaned(label,38)
        if not id or name=="" then
            notify("Use gameadd PlaceId NomeDoJogo, com ID numerico.","error")
            return false
        end
        if type(router.profiles[id])~="table" then
            router.profiles[id]={
                label=name,universeId="",
                quick={"fly","unfly","noclip","manual"},
                mode="universal",created=os.time(),lastVisit=0
            }
        else
            router.profiles[id].label=name
        end
        router.save()
        notify("Jogo cadastrado: "..name.." ("..id..").","success")
        return true
    end
    router.removeGame=function(placeId)
        local id=validPlace(placeId)
        if not id or id==router.placeId then
            notify("Nao e possivel remover o jogo atualmente aberto.","error")
            return false
        end
        if not router.profiles[id] then
            notify("PlaceId nao cadastrado.","error")
            return false
        end
        if v14.safe then
            local pending=router.pendingRemove
            if not pending or pending.id~=id or os.clock()-pending.time>8 then
                router.pendingRemove={id=id,time=os.clock()}
                notify("Confirme a exclusao clicando novamente em ate 8 segundos.","info")
                return false
            end
        end
        router.pendingRemove=nil
        router.profiles[id]=nil
        router.save()
        notify("Jogo removido da lista local: "..id,"info")
        return true
    end
    router.info=function()
        notify("JOGO: "..router.profile.label..
            " | PlaceId "..router.placeId.." | UniverseId "..router.universeId..
            " | "..router.detected,"info")
    end
    router.initialize=function()
        router.detect()
        if router.profile.mode=="custom" then router.applyProfile() end
        router.ready=true
    end
    register("games","SETTINGS","Abrir Gerenciador Universal de Jogos",function()
        show("GAMES")
    end)
    register("gameinfo","SETTINGS","PlaceId, UniverseId e modulo atual",function()
        router.info()
        return false
    end)
    register("gameadd","SETTINGS","Cadastrar PlaceId de outro jogo",function(arg)
        local id,label=tostring(arg or ""):match("^(%S+)%s+(.+)$")
        return router.registerGame(id,label)
    end,"gameadd 12345678 MeuJogo")
    register("gamelabel","SETTINGS","Alterar nome do jogo atual",function(arg)
        return router.setLabel(arg)
    end,"gamelabel MeuJogo")
    register("gameprofile","SETTINGS","Perfil: save, load ou universal",function(arg)
        local mode=cleaned(arg,18):lower()
        if mode=="save" then return router.saveProfile()
        elseif mode=="load" then return router.applyProfile()
        elseif mode=="universal" then return router.useUniversal()
        else
            notify("Use: gameprofile save | load | universal","info")
            return false
        end
    end,"gameprofile save")
    register("gamequick","SETTINGS","Configurar atalho do jogo atual",function(arg)
        local pos,command=tostring(arg or ""):match("^(%d+)%s+(.+)$")
        local index=tonumber(pos)
        if not index or index<1 or index>6 or not safeQuick(command) then
            notify("Use: gamequick 1 fly (slots de 1 a 6)","error")
            return false
        end
        local quick=router.profile.quick
        quick[index]=safeQuick(command)
        router.profile.customQuick=true
        router.save()
        notify("Atalho "..index.." definido para "..quick[index],"success")
        return true
    end,"gamequick 1 fly")
    register("gameremove","SETTINGS","Remover jogo cadastrado que nao esta aberto",function(arg)
        return router.removeGame(arg)
    end,"gameremove 12345678")
end

-- V17 / NUCLEO ULTIMATE: FAVORITOS POR JOGO, NOTAS, BACKUP, BUSSOLA, PRESETS E DIAGNOSTICO
-- Todos os recursos desta secao sao locais ou trabalham com preferencias do usuario.
do
    local m={
        placeId=v15PlaceId,
        install=nil,
        pages={},
        isOpen=false,
        compassTarget=nil,
        compassEnabled=false,
        compassUpdated=0,
        paletteOpened=0,
        sessionErrors={},
        guideVersion="V17",
        navigationOrder=navOrder
    }
    v14.v17=m
    for _,key in ipairs({"gameFavorites","gameNotes","gameSessions","layout"}) do
        if type(v13Data[key])~="table" then v13Data[key]={} end
    end
    local function trim(v)
        return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","")
    end
    local function singleWord(v)
        local result=trim(v):lower():match("^(%S+)")
        return result and result:sub(1,40) or nil
    end
    local favs=v13Data.gameFavorites[v15PlaceId]
    if type(favs)~="table" then
        favs={}
        v13Data.gameFavorites[v15PlaceId]=favs
    end
    m.favorites=favs
    if type(v13Data.gameNotes[v15PlaceId])~="string" then
        v13Data.gameNotes[v15PlaceId]=""
    end
    local session=v13Data.gameSessions[v15PlaceId]
    if type(session)~="table" then session={visits=0,last=0,commands=0} end
    session.visits=math.clamp((tonumber(session.visits) or 0)+1,0,1e9)
    session.last=os.time()
    session.commands=math.clamp(tonumber(session.commands) or 0,0,1e9)
    v13Data.gameSessions[v15PlaceId]=session
    m.session=session
    m.reportError=function(command,message)
        local record={
            time=os.date("%H:%M:%S"),
            command=tostring(command or "?"):sub(1,35),
            message=tostring(message or ""):sub(1,180)
        }
        table.insert(m.sessionErrors,1,record)
        if #m.sessionErrors>15 then table.remove(m.sessionErrors) end
    end

    m.favoriteAdd=function(raw)
        local name=singleWord(raw)
        if not name or not byName[name] then
            notify("Use: gamefav fly (comando valido).","error")
            return false
        end
        if not moduleEnabled(byName[name].category) then
            notify("Categoria "..byName[name].category.." desabilitada.","error")
            return false
        end
        favs[name]=true
        saveV13()
        if m.refresh then m.refresh("BOOKMARKS") end
        notify("Favorito salvo so neste jogo: "..name,"success")
        return true
    end
    m.favoriteRemove=function(raw)
        local name=singleWord(raw)
        if not name then return false end
        favs[name]=nil
        saveV13()
        if m.refresh then m.refresh("BOOKMARKS") end
        return true
    end
    m.noteSave=function(text)
        text=tostring(text or "")
        if #text>3000 then text=text:sub(1,3000) end
        text=text:gsub("%z","")
        v13Data.gameNotes[v15PlaceId]=text
        saveV13()
        notify("Nota deste jogo salva ("..#text.." caracteres).","success")
        return true
    end
    m.noteClear=function()
        v13Data.gameNotes[v15PlaceId]=""
        saveV13()
        if m.refresh then m.refresh("NOTES") end
        return true
    end
    m.setCompass=function(raw)
        local waypoint=singleWord(raw)
        if waypoint=="off" or waypoint=="stop" or waypoint==nil then
            m.compassEnabled=false
            m.compassTarget=nil
            if m.compassWidget then m.compassWidget.Visible=false end
            if m.refresh then m.refresh("COMPASS") end
            notify("Bussola desativada.","info")
            return true
        end
        if not extraState.savedWaypoints[waypoint] then
            notify("Ponto inexistente: "..waypoint..". Salve-o em Teleporte.","error")
            return false
        end
        m.compassTarget=waypoint
        m.compassEnabled=true
        if m.compassWidget then m.compassWidget.Visible=true end
        if m.refresh then m.refresh("COMPASS") end
        notify("Bussola aponta para: "..waypoint,"success")
        return true
    end
    m.layoutReset=function()
        v13Data.layout.groups={}
        if v14.navigation then
            for i,group in ipairs(v14.navigation.groups) do
                group.expanded=i==1
            end
            v14.navigation.searchBox.Text=""
            v14.navigation.update("HOME")
        end
        main.Position=UDim2.new(.5,-480,.5,-312)
        show("HOME")
        saveV13()
        notify("Menu e grupos restaurados ao layout padrao.","success")
        return true
    end
    m.presets={
        visual={"fov 85","crosshair on"},
        claro={"day","fullbright"},
        noite={"night","unfullbright"},
        leve={"lowgfx","fps on"},
        restaurar={"resetgfx","resetfov","crosshair off"},
        exploracao={"fov 90","fps on"}
    }
    m.presetApply=function(raw)
        local name=singleWord(raw)
        local list=name and m.presets[name]
        if not list then
            notify("Presets: visual, claro, noite, leve, restaurar, exploracao","info")
            return false
        end
        for _,command in ipairs(list) do
            local verb=command:match("^(%S+)")
            if verb and byName[verb:lower()] and moduleEnabled(byName[verb:lower()].category) then
                exec(command)
            end
        end
        notify("Preset aplicado: "..name,"success")
        return true
    end
    m.diagnostic=function()
        local camera=workspace.CurrentCamera
        local _,hum,root=chars()
        return {
            version="V17",
            placeId=v15PlaceId,
            players=#Players:GetPlayers(),
            gui=(gui and gui.Parent)~=nil,
            camera=camera~=nil,
            character=root~=nil and hum~=nil,
            fileRead=type(readfile)=="function",
            fileWrite=type(writefile)=="function",
            clipboard=type(setclipboard)=="function",
            bookmarks=(function()local n=0 for _,v in pairs(favs) do if v then n=n+1 end end return n end)(),
            notesSize=#(v13Data.gameNotes[v15PlaceId] or ""),
            waypoints=(function()local n=0 for _ in pairs(extraState.savedWaypoints) do n=n+1 end return n end)(),
            totalCommands=#registered,
            sessionCount=m.session.visits,
            totalUserCommands=m.session.commands
        }
    end
    m.backupExport=function()
        local export={
            version="BRAB0X-USER-BACKUP-V17",
            date=os.time(),
            favorites={},
            gameFavorites={},
            gameNotes={},
            macros={},
            profiles={}
        }
        local total=0
        for name,on in pairs(v13Data.favorites) do
            if on and byName[name] and total<100 then
                export.favorites[name]=true total=total+1
            end
        end
        local count=0
        for id,entries in pairs(v13Data.gameFavorites) do
            if count>=60 then break end
            if type(id)=="string" and id:match("^%d+$") and type(entries)=="table" then
                local keep={}
                for name,on in pairs(entries) do
                    if on and byName[name] then keep[name]=true end
                end
                export.gameFavorites[id]=keep
                count=count+1
            end
        end
        count=0
        for id,note in pairs(v13Data.gameNotes) do
            if count>=60 then break end
            if type(id)=="string" and id:match("^%d+$") and type(note)=="string" then
                export.gameNotes[id]=note:sub(1,3000)
                count=count+1
            end
        end
        count=0
        for name,sequence in pairs(v14.macros) do
            if count>=35 then break end
            if type(name)=="string" and type(sequence)=="table" then
                local safe={}
                for _,command in ipairs(sequence) do
                    local first=tostring(command):match("^(%S+)")
                    if first and v14.macroActions[first:lower()] and byName[first:lower()] then
                        safe[#safe+1]=tostring(command):sub(1,130)
                    end
                    if #safe>=12 then break end
                end
                if #safe>0 then export.macros[name:sub(1,26)]=safe count=count+1 end
            end
        end
        local ok,json=pcall(function() return HttpService:JSONEncode(export) end)
        if not ok or #json>55000 then
            notify("Backup muito grande para exportar.","error")
            return nil
        end
        return json
    end
    m.backupImport=function(raw)
        if type(raw)~="string" or #raw<10 or #raw>60000 then
            notify("JSON do backup vazio ou grande demais.","error")
            return false
        end
        local ok,result=pcall(function()return HttpService:JSONDecode(raw)end)
        if not ok or type(result)~="table"
            or result.version~="BRAB0X-USER-BACKUP-V17" then
            notify("Backup invalido. Aceita formato BRAB0X-V17.","error")
            return false
        end
        local added={favorites=0,notes=0,macros=0}
        if type(result.favorites)=="table" then
            for name,on in pairs(result.favorites) do
                if type(name)=="string" and byName[name] and on==true
                    and added.favorites<100 then
                    v13Data.favorites[name]=true
                    added.favorites=added.favorites+1
                end
            end
        end
        if type(result.gameFavorites)=="table" then
            local games=0
            for id,entry in pairs(result.gameFavorites) do
                if games>=60 then break end
                if type(id)=="string" and id:match("^%d+$") and type(entry)=="table" then
                    local dest=v13Data.gameFavorites[id]
                    if type(dest)~="table" then dest={} v13Data.gameFavorites[id]=dest end
                    for name,on in pairs(entry) do
                        if type(name)=="string" and byName[name] and on==true then
                            dest[name]=true
                        end
                    end
                    games=games+1
                end
            end
        end
        if type(result.gameNotes)=="table" then
            for id,note in pairs(result.gameNotes) do
                if added.notes>=60 then break end
                if type(id)=="string" and id:match("^%d+$") and type(note)=="string" then
                    v13Data.gameNotes[id]=note:sub(1,3000):gsub("%z","")
                    added.notes=added.notes+1
                end
            end
        end
        if type(result.macros)=="table" then
            for name,sequence in pairs(result.macros) do
                if added.macros>=35 then break end
                if type(name)=="string" and name:match("^[%w_%-]+$")
                    and #name<=26 and type(sequence)=="table" and #sequence<=12
                    and #sequence>=1 then
                    local safe={}
                    local valid=true
                    for _,command in ipairs(sequence) do
                        if type(command)~="string" or #command>130 then valid=false break end
                        local first=command:match("^(%S+)")
                        if not first or not byName[first:lower()]
                            or not v14.macroActions[first:lower()] then
                            valid=false break
                        end
                        safe[#safe+1]=command
                    end
                    if valid then
                        v14.macros[name]=safe added.macros=added.macros+1
                    end
                end
            end
        end
        saveV13()
        if refreshCommandList then refreshCommandList() end
        if updateFavoritePanel then updateFavoritePanel() end
        if m.refresh then m.refresh(selected) end
        notify(("Backup importado: %d favoritos, %d notas, %d macros."):format(
            added.favorites,added.notes,added.macros),"success")
        return true
    end
    m.onCommand=function(name)
        m.session.commands=math.clamp((tonumber(m.session.commands) or 0)+1,0,1e9)
        if m.refresh and (selected=="DIAGNOSTICS" or selected=="BOOKMARKS") then
            m.refresh(selected)
        end
    end

    register("palette","SETTINGS","Abrir paleta de comandos Ctrl+Shift+P",function()
        if m.openPalette then m.openPalette()end
        return false
    end)
    register("gamefav","SETTINGS","Salvar favorito exclusivo do jogo",function(arg)
        return m.favoriteAdd(arg)
    end,"gamefav fly")
    register("gameunfav","SETTINGS","Remover favorito do jogo",function(arg)
        return m.favoriteRemove(arg)
    end,"gameunfav fly")
    register("gamefavs","SETTINGS","Abrir lista de favoritos do jogo",function()
        show("BOOKMARKS")
        return false
    end)
    register("notes","SETTINGS","Abrir bloco de notas por jogo",function()
        show("NOTES")
        return false
    end)
    register("note","SETTINGS","Salvar nota simples deste jogo",function(arg)
        return m.noteSave(arg)
    end,"note treino no mapa 1")
    register("noteclear","SETTINGS","Apagar nota deste jogo",function()
        return m.noteClear()
    end)
    register("compass","PLAYER","Bussola para waypoint salvo",function(arg)
        return m.setCompass(arg)
    end,"compass casa")
    register("compassoff","PLAYER","Desligar bussola local",function()
        return m.setCompass("off")
    end)
    register("layoutreset","SETTINGS","Restaurar painel e categorias",function()
        return m.layoutReset()
    end)
    register("presets","SETTINGS","Abrir presets configurados",function()
        show("GUIDE")
        return false
    end)
    register("preset","SETTINGS","Aplicar preset: visual, leve, claro...",function(arg)
        return m.presetApply(arg)
    end,"preset visual")
    register("errorlog","SETTINGS","Ver falhas de comandos desta sessao",function()
        show("DIAGNOSTICS")
        if #m.sessionErrors==0 then
            notify("Sem falhas registradas nesta sessao.","success")
        else
            notify(#m.sessionErrors.." falha(s) no diagnostico.","info")
        end
        return false
    end)
    register("diagnose","SETTINGS","Abrir verificacoes de compatibilidade",function()
        show("DIAGNOSTICS")
        return false
    end)
    register("backup","SETTINGS","Abrir backup seguro de preferenciais",function()
        show("BACKUP")
        return false
    end)
    register("guide","SETTINGS","Abrir guia completo de inicio",function()
        show("GUIDE")
        return false
    end)
end

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
        if v14.v17 and v14.v17.reportError then
            v14.v17.reportError(command,"Comando desconhecido")
        end
        notify("Comando desconhecido: "..command,"error")
        return
    end

    if not moduleEnabled(entry.category) then
        notify(
            "Ative a categoria "..entry.category
            .." em Ajustes > Modulos"
        )
        return
    end

    local noticesBefore=noticeCounter
    if v14.safe and v14.requiresConfirmation and v14.requiresConfirmation(command,arg) then
        return
    end
    local ok,result = pcall(entry.run,arg)

    if not ok then
        local err = result
        if v14.v17 and v14.v17.reportError then
            v14.v17.reportError(command,tostring(err))
        end
        notify("Erro em "..command..": "..tostring(err),"error")
        return
    end
    if ok and v14.trackCommand then v14.trackCommand(command,tostring(raw)) end
    if ok and v14.v17 and v14.v17.onCommand then v14.v17.onCommand(command) end
    if result == false then return end
    if type(result)=="string" then
        notify(result)
        return
    end

    if stopped then return end
    if command ~= "coords"
        and command ~= "status" and noticeCounter==noticesBefore then
        notify("OK: "..raw,"success")
    end

    refresh()
end

-- COMANDOS / NOVA INTERFACE COM CONTROLES REAIS
do
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

search = round(obj("TextBox",cmdPage,{
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

visualUpdates={}
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

toggleControl=function(parent,title,desc,get,onCmd,offCmd)
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

sliderControl=function(parent,title,desc,lo,hi,step,get,command,fmt)
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
        local cell=obj("Frame",g.content,{
            BackgroundTransparency=1
        })
        local b=btn(cell,
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
        b.Size=UDim2.new(1,-81,1,0)
        b.TextWrapped=true
        b.TextSize=10
        local star=btn(cell,"",nil,46)
        star.Position=UDim2.new(1,-78,0,0)
        star.Size=UDim2.fromOffset(37,46)
        star.TextSize=18
        local helpButton=btn(cell,"?",function()
            if openCommandHelp then openCommandHelp(entry.name) end
        end,46)
        helpButton.Position=UDim2.new(1,-38,0,0)
        helpButton.Size=UDim2.fromOffset(37,46)
        helpButton.TextSize=18
        bind(star.MouseButton1Click,function()
            v13Data.favorites[entry.name]=not (v13Data.favorites[entry.name]==true)
            if v13Data.favorites[entry.name]==false then
                v13Data.favorites[entry.name]=nil
            end
            favoritesChanged()
        end)
        g.items[#g.items+1]={
            button=cell,
            favoriteButton=star,
            commandName=entry.name,
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
            item.favoriteButton.Text=v13Data.favorites[item.commandName] and "★" or "☆"
            item.favoriteButton.TextColor3=v13Data.favorites[item.commandName] and accent or muted
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

end -- fim do escopo COMANDOS
-- CENTRAL DE AJUDA V13.2 / DETALHES E BUSCA PARA TODO O CATALOGO
do
    local helpPage=pages.HELP
    local heroHelp=round(obj("Frame",helpPage,{
        Size=UDim2.new(1,-8,0,74),
        BackgroundColor3=Color3.fromRGB(39,10,21),
        BorderSizePixel=0
    }),11)
    obj("UIStroke",heroHelp,{Color=accent,Transparency=.24,Thickness=1.2})
    local helpName=txt(heroHelp,"?  CENTRAL DE AJUDA",30,20,true)
    helpName.Position=UDim2.fromOffset(18,8)
    helpName.Size=UDim2.new(1,-34,0,30)
    local helpSub=txt(heroHelp,"Como usar os comandos e quais recursos sao locais",25,11)
    helpSub.Position=UDim2.fromOffset(19,43)
    helpSub.Size=UDim2.new(1,-36,0,24)
    helpSub.TextColor3=muted

    local query=round(obj("TextBox",helpPage,{
        Size=UDim2.new(1,-8,0,41),
        BackgroundColor3=control,
        BorderSizePixel=0,
        Text="",ClearTextOnFocus=false,
        PlaceholderText="Pesquisar: goto, invisible, emote, zoom...",
        PlaceholderColor3=muted,
        TextColor3=white,
        Font=Enum.Font.Gotham,
        TextSize=13
    }),8)
    obj("UIStroke",query,{Color=accent,Transparency=.6,Thickness=1})

    local details=round(obj("Frame",helpPage,{
        Size=UDim2.new(1,-8,0,202),
        BackgroundColor3=Color3.fromRGB(25,21,30),
        BorderSizePixel=0
    }),11)
    obj("UIStroke",details,{Color=accent,Thickness=1,Transparency=.5})
    local detailTitle=txt(details,"COMO USAR",30,18,true)
    detailTitle.Position=UDim2.fromOffset(16,11)
    detailTitle.Size=UDim2.new(1,-28,0,30)
    detailTitle.TextColor3=accent
    local detailDescription=txt(details,"Selecione um comando abaixo para ver a explicacao.",36,12)
    detailDescription.Position=UDim2.fromOffset(17,45)
    detailDescription.Size=UDim2.new(1,-33,0,36)
    local detailExample=txt(details,"Exemplo:",29,12,true)
    detailExample.Position=UDim2.fromOffset(17,83)
    detailExample.Size=UDim2.new(1,-34,0,29)
    local detailNote=txt(details,"As funcoes dependem das permissoes do jogo.",39,11)
    detailNote.Position=UDim2.fromOffset(17,114)
    detailNote.Size=UDim2.new(1,-33,0,40)
    detailNote.TextColor3=muted
    local prepareButton=btn(details,"USAR EXEMPLO",nil,32)
    prepareButton.Position=UDim2.new(0,16,1,-42)
    prepareButton.Size=UDim2.new(.5,-23,0,32)
    local favoriteButton=btn(details,"☆  FAVORITAR",nil,32)
    favoriteButton.Position=UDim2.new(.5,5,1,-42)
    favoriteButton.Size=UDim2.new(.5,-23,0,32)

    local resultLabel=txt(helpPage,"COMANDOS DISPONIVEIS",27,13,true)
    resultLabel.TextColor3=accent
    local results=obj("Frame",helpPage,{
        Size=UDim2.new(1,-8,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1
    })
    stack(results,5)

    local customText={
        invisible="Deixa seu avatar invisivel SOMENTE na sua tela. Nao esconde voce dos outros.",
        invis="Alias do invisible; invisibilidade SOMENTE local.",
        visible="Restaura a aparencia local do avatar.",
        ghost="Aplica transparência local e desativa colisoes locais.",
        fly="Ativa o voo local com movimento pelas teclas WASD.",
        unfly="Desliga o voo e restaura os controles do personagem.",
        noclip="Desativa colisoes no seu cliente; o servidor pode reverter.",
        clip="Restaura as colisoes originais do personagem.",
        aim="Assistencia visual de camera somente para NPCs de treino com PracticeTarget=true.",
        aimfov="Ajusta o raio, em pixels, de NPCs detectados no treino.",
        smooth="Ajusta a suavidade do movimento visual da camera no treino.",
        spectate="Muda a camera para acompanhar o jogador informado.",
        goto="Tenta levar seu personagem perto do alvo informado; o jogo pode restringir teleporte.",
        wp="Salva a posicao atual com um nome para voltar depois.",
        gowp="Retorna ate o waypoint informado, se estiver salvo.",
        emote="Tenta tocar emote equipado e autorizado no avatar.",
        dance="Executa uma animacao local quando o rig suporta a tecnica.",
        saveprofile="Salva ajustes de voo, camera, tema e visual em um perfil.",
        loadprofile="Aplica as configuracoes de um perfil salvo.",
        bindkey="Muda o atalho para uma das acoes aceitas: FLY, MENU, NOCLIP, BOOST ou INVIS.",
        manual="Abre a central de ajuda e seus exemplos.",
        notifications="Liga ou desliga as mensagens animadas na tela.",
        notifytest="Mostra uma notificacao de teste, se estiverem ligadas."
    }
    local notes={
        FLY="Movimento local: a experiencia ou o servidor pode limitar o efeito.",
        PLAYER="Aparencia, posicao ou movimento podem ser locais ou limitados pelo jogo.",
        CAMERA="Ajustes de camera sao visuais e feitos no seu cliente.",
        WORLD="Mudancas visuais locais, sem controlar o mundo dos outros jogadores.",
        EMOTES="Emotes de catalogo precisam de permissao e compatibilidade do avatar.",
        AIM="Somente NPCs de treino marcados; nao mira em jogadores nem dispara.",
        SETTINGS="Opcao do painel. Salvamento entre sessoes depende do ambiente."
    }
    local current=byName["fly"] or registered[1]
    local function detailFor(entry)
        if not entry then return end
        current=entry
        detailTitle.Text=entry.name:upper().."  /  "..entry.category
        detailDescription.Text=customText[entry.name] or entry.description
        detailExample.Text="EXEMPLO:  "..entry.example
        detailNote.Text=notes[entry.category] or "Consulte os limites e permissoes do jogo."
        favoriteButton.Text=v13Data.favorites[entry.name] and "★  REMOVER FAVORITO" or "☆  FAVORITAR"
    end
    bind(prepareButton.MouseButton1Click,function()
        if not current then return end
        cmdInput.Text=current.example
        show("COMMANDS")
        cmdInput:CaptureFocus()
        notify("Exemplo pronto para editar ou executar: "..current.example,"info")
    end)
    bind(favoriteButton.MouseButton1Click,function()
        if not current then return end
        local name=current.name
        if v13Data.favorites[name] then v13Data.favorites[name]=nil
        else v13Data.favorites[name]=true end
        favoritesChanged()
        detailFor(current)
        notify("Favorito atualizado: "..name,"success")
    end)

    refreshHelpPage=function()
        if stopped or not helpPage.Parent then return end
        if not helpPage.Visible then return end
        clear(results)
        local term=query.Text:lower():gsub("^%s+",""):gsub("%s+$","")
        local matches={}
        for _,entry in ipairs(registered) do
            if moduleEnabled(entry.category) and (
                term=="" or entry.name:lower():find(term,1,true)
                or entry.description:lower():find(term,1,true)
                or entry.category:lower():find(term,1,true)
            ) then matches[#matches+1]=entry end
        end
        table.sort(matches,function(a,b) return a.name<b.name end)
        local count=#matches
        resultLabel.Text="COMANDOS ENCONTRADOS: "..count.."  /  "..#registered
        for i=1,math.min(count,32) do
            local entry=matches[i]
            local b=btn(results,"?  "..entry.name.."    •    "..entry.description,function()
                detailFor(entry)
            end,35)
            b.TextXAlignment=Enum.TextXAlignment.Left
            b.TextSize=11
            b.TextWrapped=true
            b.BackgroundColor3=entry==current and Color3.fromRGB(85,19,35) or control
        end
        if count==0 then
            local empty=txt(results,"Nenhum resultado. Tente outro nome de comando.",42,12)
            empty.TextColor3=muted
        elseif count>32 then
            local remaining=txt(results,"Mostrando 32 de "..count..". Digite para filtrar.",33,11)
            remaining.TextColor3=muted
        end
        detailFor(current)
    end
    bind(query:GetPropertyChangedSignal("Text"),refreshHelpPage)
    openCommandHelp=function(name)
        local entry=byName[tostring(name or ""):lower()]
        if not entry then
            notify("Comando nao encontrado na ajuda: "..tostring(name),"error")
            return
        end
        current=entry
        query.Text=entry.name
        show("HELP")
        detailFor(entry)
    end
end

-- HOME / BANNER INTEGRADO COM DESENHO NATIVO (SEM ASSET EXTERNO)
do
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
-- Emblema feito com componentes Roblox: nao depende de glifo Unicode.
local emblem=round(obj("Frame",hero,{
    Position=UDim2.new(1,-154,0,22),
    Size=UDim2.fromOffset(92,106),
    BackgroundColor3=Color3.fromRGB(37,7,20),
    BackgroundTransparency=.15,BorderSizePixel=0
}),17)
obj("UIStroke",emblem,{Color=accent,Thickness=3,Transparency=.05})
local emblemLetter=txt(emblem,"B",91,70,true)
emblemLetter.Position=UDim2.fromOffset(3,4)
emblemLetter.Size=UDim2.new(1,-6,1,-8)
emblemLetter.TextColor3=accent
emblemLetter.TextXAlignment=Enum.TextXAlignment.Center
local bannerSmall = txt(hero,"HUB PREMIUM  |  V17.1 / ULTIMATE",22,12,true)
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
local creatorBanner = txt(hero,"✦  CRIADO POR @wendezao05153nh",18,11,true)
creatorBanner.Position = UDim2.fromOffset(29,180)
creatorBanner.Size = UDim2.new(1,-56,0,18)
creatorBanner.TextColor3 = accent

live = titleRow(pages.HOME,"FLY OFF • SPEED 55 • AIM OFF")
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
makeHomeTile("F","MOVIMENTO","Fly, velocidade e noclip","FLY")
makeHomeTile("P","JOGADOR","Pulo, visual e posicoes","PLAYER")
makeHomeTile("C","CAMERA","FOV, zoom e mira","CAMERA")
makeHomeTile("M","MUNDO","Tempo e iluminacao","WORLD")
makeHomeTile("E","EMOTES","Animacoes autorizadas","EMOTES")
makeHomeTile("S","AJUSTES","Configuracoes do hub","SETTINGS")

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
item(pages.HOME,"?  CENTRAL DE AJUDA","manual")
item(pages.HOME,"▣  GERENCIADOR DE JOGOS","games")
item(pages.HOME,"⌕  BUSCA RAPIDA DE COMANDOS","palette")
item(pages.HOME,"★  FAVORITOS DESTE JOGO","gamefavs")
item(pages.HOME,"⌖  BUSSOLA DE WAYPOINTS","tab compass")
item(pages.HOME,"▣  BACKUP E RESTAURACAO","backup")

-- Atalhos da pagina inicial usam o filtro da aba Comandos.

end -- fim do escopo HOME
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

-- V13 / PAINEIS INTERATIVOS
do
local function heading(page,title,subtitle)
    local h=round(obj("Frame",page,{
        Size=UDim2.new(1,-9,0,69),
        BackgroundColor3=Color3.fromRGB(33,11,19),
        BorderSizePixel=0
    }),11)
    obj("UIStroke",h,{Color=accent,Transparency=.4,Thickness=1})
    local a=txt(h,title,32,19,true)
    a.Position=UDim2.fromOffset(17,8)
    a.Size=UDim2.new(1,-32,0,30)
    local b=txt(h,subtitle,22,11)
    b.Position=UDim2.fromOffset(17,39)
    b.Size=UDim2.new(1,-32,0,22)
    b.TextColor3=muted
    return h
end
local function editBox(parent,placeholder,height)
    local b=round(obj("TextBox",parent,{
        Size=UDim2.new(1,-10,0,height or 37),
        BackgroundColor3=control,BorderSizePixel=0,
        Text="",PlaceholderText=placeholder,
        PlaceholderColor3=muted,TextColor3=white,
        Font=Enum.Font.Gotham,TextSize=13,ClearTextOnFocus=false
    }),9)
    obj("UIStroke",b,{Color=accent,Transparency=.72,Thickness=1})
    return b
end
actionRow=function(page,items)
    local row=obj("Frame",page,{Size=UDim2.new(1,-10,0,40),BackgroundTransparency=1})
    for i,item in ipairs(items) do
        local b=btn(row,item[1],item[2],39)
        b.Size=UDim2.new(1/#items,-7,0,39)
        b.Position=UDim2.new((i-1)/#items,3,0,0)
    end
    return row
end
local function dynamicHolder(page)
    local holder=obj("Frame",page,{
        Size=UDim2.new(1,-10,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1
    })
    stack(holder,7)
    return holder
end
local function emptyMessage(holder,message)
    local t=txt(holder,message,42,12)
    t.TextColor3=muted
    return t
end

-- PLAYER MANAGER: imagens de avatar e botoes por jogador.
heading(pages.PLAYERS,"♙  PLAYER MANAGER","Goto, espectar, distancia e copia de usuario")
local playerSearch=editBox(pages.PLAYERS,"Buscar jogador pelo nome ou apelido...")
local playersActions=actionRow(pages.PLAYERS,{
    {"ATUALIZAR",function() if updatePlayerManager then updatePlayerManager() end end},
    {"IR AO MAIS PROXIMO",function() exec("goto nearest") end}
})
local playersHolder=dynamicHolder(pages.PLAYERS)
updatePlayerManager=function()
    if stopped or not playersHolder.Parent then return end
    clear(playersHolder)
    local query=playerSearch.Text:lower()
    local users=Players:GetPlayers()
    table.sort(users,function(a,b)return a.Name:lower()<b.Name:lower() end)
    local total=0
    for _,user in ipairs(users) do
        if query=="" or user.Name:lower():find(query,1,true)
            or user.DisplayName:lower():find(query,1,true) then
            total=total+1
            local row=round(obj("Frame",playersHolder,{
                Size=UDim2.new(1,-8,0,105),
                BackgroundColor3=Color3.fromRGB(27,22,30),
                BorderSizePixel=0
            }),11)
            obj("UIStroke",row,{Color=accent,Thickness=1,Transparency=.7})
            local portrait=round(obj("ImageLabel",row,{
                Position=UDim2.fromOffset(12,12),
                Size=UDim2.fromOffset(80,80),
                BackgroundColor3=control,BorderSizePixel=0,
                Image=""
            }),9)
            task.spawn(function()
                local ok,url=pcall(function()
                    return Players:GetUserThumbnailAsync(
                        user.UserId,Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size150x150)
                end)
                if ok and portrait.Parent then portrait.Image=url end
            end)
            local name=txt(row,user.DisplayName.."  (@"..user.Name..")",28,15,true)
            name.Position=UDim2.fromOffset(106,9)
            name.Size=UDim2.new(1,-122,0,27)
            local subtitle=txt(row,"UserId: "..user.UserId,23,11)
            subtitle.Position=UDim2.fromOffset(108,38)
            subtitle.Size=UDim2.new(1,-124,0,23)
            subtitle.TextColor3=muted
            local labels={
                {"GOTO",function()exec("goto "..user.Name)end},
                {"ESPECTAR",function()exec("spectate "..user.Name)end},
                {"DISTANCIA",function()exec("distance "..user.Name)end},
                {"COPIAR NOME",function()
                    if type(setclipboard)=="function" then
                        local ok=pcall(setclipboard,user.Name)
                        if ok then notify("Copiado: "..user.Name);return end
                    end
                    cmdInput.Text=user.Name
                    cmdInput:CaptureFocus()
                    notify("Nome no campo inferior: Ctrl+A / Ctrl+C")
                end}
            }
            for i,entry in ipairs(labels) do
                local b=btn(row,entry[1],entry[2],30)
                b.Position=UDim2.new(0,106,0,66)+UDim2.fromOffset((i-1)*145,0)
                b.Size=UDim2.fromOffset(137,29)
                b.TextSize=10
            end
        end
    end
    if total==0 then emptyMessage(playersHolder,"Nenhum jogador corresponde a busca.") end
end
bind(playerSearch:GetPropertyChangedSignal("Text"),function()
    if pages.PLAYERS.Visible then updatePlayerManager() end
end)
bind(Players.PlayerAdded,function() if pages.PLAYERS.Visible then updatePlayerManager() end end)
bind(Players.PlayerRemoving,function() if pages.PLAYERS.Visible then task.defer(updatePlayerManager) end end)

-- FAVORITOS: comandos com execucao imediata e remocao.
heading(pages.FAVORITES,"★  MEUS FAVORITOS","Marque a estrela dos comandos e acesse aqui")
actionRow(pages.FAVORITES,{
    {"VER TODOS OS COMANDOS",function()show("COMMANDS")end},
    {"LIMPAR FAVORITOS",function()
        v13Data.favorites={}
        favoritesChanged()
    end}
})
local favoriteHolder=dynamicHolder(pages.FAVORITES)
updateFavoritePanel=function()
    if stopped or not favoriteHolder.Parent then return end
    if not pages.FAVORITES.Visible then return end
    clear(favoriteHolder)
    local names={}
    for name,value in pairs(v13Data.favorites) do
        if value==true and byName[name] then names[#names+1]=name end
    end
    table.sort(names)
    if #names==0 then
        emptyMessage(favoriteHolder,"Nenhum favorito. Abra Comandos e clique em ★.")
        return
    end
    for _,name in ipairs(names) do
        local entry=byName[name]
        local row=round(obj("Frame",favoriteHolder,{
            Size=UDim2.new(1,-8,0,52),
            BackgroundColor3=control,BorderSizePixel=0
        }),8)
        local desc=txt(row,"★  "..name.."  |  "..entry.description,30,12,true)
        desc.Position=UDim2.fromOffset(12,10)
        desc.Size=UDim2.new(1,-218,0,31)
        local run=btn(row,"EXECUTAR",function()exec(entry.example)end,32)
        run.Position=UDim2.new(1,-199,0,10)
        run.Size=UDim2.fromOffset(105,32)
        local remove=btn(row,"REMOVER",function()
            v13Data.favorites[name]=nil
            favoritesChanged()
        end,32)
        remove.Position=UDim2.new(1,-89,0,10)
        remove.Size=UDim2.fromOffset(79,32)
    end
end

-- TELEPORTE: nomes para waypoints, ultima posicao e retorno.
heading(pages.TELEPORT,"⌾  GERENCIADOR DE TELEPORTE","Posicoes salvas, retorno e atalhos")
local wpName=editBox(pages.TELEPORT,"Nome do ponto: casa, escola, spawn...")
actionRow(pages.TELEPORT,{
    {"SALVAR POSICAO",function()exec("wp "..wpName.Text)end},
    {"VOLTAR",function()exec("back")end},
    {"CAMERA",function()exec("gotocam")end}
})
local wpSearch=editBox(pages.TELEPORT,"Pesquisar waypoint...")
local waypointHolder=dynamicHolder(pages.TELEPORT)
updateTeleportPanel=function()
    if stopped or not waypointHolder.Parent then return end
    if not pages.TELEPORT.Visible then return end
    clear(waypointHolder)
    local names={}
    for name in pairs(extraState.savedWaypoints) do names[#names+1]=name end
    table.sort(names)
    local shown=0
    for _,name in ipairs(names) do
        if wpSearch.Text=="" or name:lower():find(wpSearch.Text:lower(),1,true) then
            shown=shown+1
            local pos=extraState.savedWaypoints[name].Position
            local row=round(obj("Frame",waypointHolder,{
                Size=UDim2.new(1,-8,0,61),
                BackgroundColor3=control,BorderSizePixel=0
            }),9)
            local label=txt(row,"⌾  "..name,26,13,true)
            label.Position=UDim2.fromOffset(13,6)
            label.Size=UDim2.new(1,-244,0,26)
            local coords=txt(row,string.format("X %.0f  |  Y %.0f  |  Z %.0f",pos.X,pos.Y,pos.Z),22,11)
            coords.Position=UDim2.fromOffset(14,33)
            coords.Size=UDim2.new(1,-244,0,22)
            coords.TextColor3=muted
            local go=btn(row,"IR",function()exec("gowp "..name)end,36)
            go.Position=UDim2.new(1,-218,0,12)
            go.Size=UDim2.fromOffset(99,36)
            local del=btn(row,"EXCLUIR",function()exec("delwp "..name)end,36)
            del.Position=UDim2.new(1,-109,0,12)
            del.Size=UDim2.fromOffset(97,36)
        end
    end
    if shown==0 then emptyMessage(waypointHolder,"Nenhuma posicao salva.") end
end
bind(wpSearch:GetPropertyChangedSignal("Text"),function()
    if pages.TELEPORT.Visible then updateTeleportPanel() end
end)

-- PERFIS: colecao de configuracoes sem alterar a conta Roblox.
heading(pages.PROFILES,"▣  PERFIS PERSONALIZADOS","Salve velocidade, camera, tema, tamanho e preferencia AIM")
local profileName=editBox(pages.PROFILES,"Nome curto do perfil, ex.: explorar")
actionRow(pages.PROFILES,{
    {"SALVAR PERFIL",function()exec("saveprofile "..profileName.Text)end},
    {"CARREGAR PERFIL",function()exec("loadprofile "..profileName.Text)end}
})
local profileNote=txt(pages.PROFILES,
    type(writefile)=="function"
        and "Salvamento em arquivo local disponivel neste ambiente."
        or "Perfis em memoria: podem desaparecer ao fechar o jogo.",
    36,11)
profileNote.TextColor3=muted
local profilesHolder=dynamicHolder(pages.PROFILES)
updateProfilePanel=function()
    if stopped or not profilesHolder.Parent then return end
    if not pages.PROFILES.Visible then return end
    clear(profilesHolder)
    local names={}
    for name in pairs(v13Data.profiles) do names[#names+1]=name end
    table.sort(names)
    if #names==0 then emptyMessage(profilesHolder,"Nenhum perfil salvo.") end
    for _,name in ipairs(names) do
        local row=round(obj("Frame",profilesHolder,{
            Size=UDim2.new(1,-8,0,54),
            BackgroundColor3=control,BorderSizePixel=0
        }),9)
        local label=txt(row,"▣  "..name,31,14,true)
        label.Position=UDim2.fromOffset(13,10)
        label.Size=UDim2.new(1,-237,0,31)
        local use=btn(row,"APLICAR",function()exec("loadprofile "..name)end,34)
        use.Position=UDim2.new(1,-216,0,10)
        use.Size=UDim2.fromOffset(100,34)
        local remove=btn(row,"EXCLUIR",function()exec("deleteprofile "..name)end,34)
        remove.Position=UDim2.new(1,-107,0,10)
        remove.Size=UDim2.fromOffset(95,34)
    end
end

-- CONSOLE: sugestoes, pesquisa e historico de comandos.
heading(pages.CONSOLE,"⌘  CONSOLE INTELIGENTE","Busca, autocomplete, historico e retorno de comandos")
local consoleInput=editBox(pages.CONSOLE,"Escreva um comando: goto nearest, fly, speed 75...")
local v13History={}
local v13HistoryIndex=0
local v13Logs={}
actionRow(pages.CONSOLE,{
    {"EXECUTAR",function()if consoleInput.Text~="" then exec(consoleInput.Text) end end},
    {"ANTERIOR",function()
        if #v13History>0 then
            v13HistoryIndex=math.min(#v13History,v13HistoryIndex+1)
            consoleInput.Text=v13History[v13HistoryIndex] or ""
        end
    end},
    {"LIMPAR",function()v13Logs={} if updateConsolePanel then updateConsolePanel()end end}
})
local suggestionTitle=titleRow(pages.CONSOLE,"SUGESTOES")
local suggestionHolder=dynamicHolder(pages.CONSOLE)
local consoleLogsTitle=titleRow(pages.CONSOLE,"HISTORICO DE EXECUCAO")
local consoleLogsHolder=dynamicHolder(pages.CONSOLE)
addHistory=function(raw)
    if raw=="" then return end
    table.insert(v13History,1,raw)
    if #v13History>65 then table.remove(v13History) end
    v13HistoryIndex=0
    if pages.CONSOLE.Visible then updateConsolePanel() end
end
v13Log=function(message)
    table.insert(v13Logs,1,os.date("%H:%M:%S").."  "..message)
    if #v13Logs>36 then table.remove(v13Logs) end
    if pages.CONSOLE.Visible then updateConsolePanel() end
end
local function suggestions()
    clear(suggestionHolder)
    local q=consoleInput.Text:lower()
    local prefix=q:match("^%s*(%S*)") or ""
    if prefix=="" then
        emptyMessage(suggestionHolder,"Digite o inicio de um comando para ver sugestoes.")
        return
    end
    local found=0
    for _,entry in ipairs(registered) do
        if entry.name:sub(1,#prefix)==prefix then
            found=found+1
            local b=btn(suggestionHolder,entry.example.."  •  "..entry.description,function()
                consoleInput.Text=entry.example
                consoleInput:CaptureFocus()
            end,32)
            b.TextSize=11
            if found>=5 then break end
        end
    end
    if found==0 then emptyMessage(suggestionHolder,"Nenhum comando com esse nome.") end
end
updateConsolePanel=function()
    if stopped or not pages.CONSOLE.Visible then return end
    clear(consoleLogsHolder)
    for i=1,math.min(#v13Logs,17) do
        local line=txt(consoleLogsHolder,v13Logs[i],26,11)
        line.TextColor3=i==1 and accent or muted
    end
    if #v13Logs==0 then emptyMessage(consoleLogsHolder,"Os comandos executados aparecerao aqui.") end
    suggestions()
end
bind(consoleInput:GetPropertyChangedSignal("Text"),function()
    if pages.CONSOLE.Visible then suggestions() end
end)
bind(consoleInput.FocusLost,function(enter)
    if enter and consoleInput.Text~="" then exec(consoleInput.Text) end
end)

-- DESEMPENHO: informacoes de sessao e grafico amostrado.
heading(pages.PERFORMANCE,"▥  PERFORMANCE","FPS, ping, memoria e ajustes visuais locais")
local performanceDetails=txt(pages.PERFORMANCE,"FPS: --    PING: --    MEMORIA: --",50,17,true)
performanceDetails.TextColor3=accent
actionRow(pages.PERFORMANCE,{
    {"FPS NA TELA",function()exec(fpsLabel.Visible and "fps off" or "fps on")end},
    {"MODO LEVE",function()exec("lowgfx")end},
    {"RESTAURAR GRAFICOS",function()exec("resetgfx")end}
})
titleRow(pages.PERFORMANCE,"FPS DOS ULTIMOS SEGUNDOS")
local graph=round(obj("Frame",pages.PERFORMANCE,{
    Size=UDim2.new(1,-10,0,167),
    BackgroundColor3=Color3.fromRGB(26,20,28),
    BorderSizePixel=0
}),10)
local graphBars={}
for i=1,24 do
    graphBars[i]=round(obj("Frame",graph,{
        AnchorPoint=Vector2.new(0,1),
        Position=UDim2.new((i-1)/24,4,1,-8),
        Size=UDim2.new(1/24,-7,0,12),
        BackgroundColor3=accent,
        BorderSizePixel=0
    }),4)
end
local performanceFrames,performanceElapsed=0,0
bind(Run.RenderStepped,function(dt)
    if stopped then return end
    performanceFrames=performanceFrames+1
    performanceElapsed=performanceElapsed+dt
    if performanceElapsed<.8 then return end
    local fps=math.floor(performanceFrames/math.max(performanceElapsed,.001)+.5)
    performanceFrames,performanceElapsed=0,0
    if not pages.PERFORMANCE.Visible then return end
    local ping="--"
    local ok,value=pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    if ok then ping=tostring(value) end
    local memory="--"
    local okMemory,used=pcall(function() return Stats:GetTotalMemoryUsageMb() end)
    if okMemory then memory=string.format("%.0f MB",used) end
    performanceDetails.Text="FPS: "..fps.."    PING: "..ping.."    MEMORIA: "..memory..
        "    JOGADORES: "..#Players:GetPlayers()
    for i=1,#graphBars-1 do
        graphBars[i].Size=graphBars[i+1].Size
    end
    graphBars[#graphBars].Size=UDim2.new(1/24,-7,0,math.clamp(math.floor(fps*1.25),7,145))
end)

-- Atualizacao somente da pagina aberta, evitando trabalho desnecessario.
refreshV13Page=function(page)
    if page=="PLAYERS" and updatePlayerManager then updatePlayerManager()
    elseif page=="FAVORITES" and updateFavoritePanel then updateFavoritePanel()
    elseif page=="TELEPORT" and updateTeleportPanel then updateTeleportPanel()
    elseif page=="PROFILES" and updateProfilePanel then updateProfilePanel()
    elseif page=="CONSOLE" and updateConsolePanel then updateConsolePanel()
    end
end

end -- fim do escopo V13
-- V14 / COMPONENTES DE INTERFACE + RECENTES, MACROS E ROTAS
do
    v14.panelRefresh={}
    v14.localeLabels={}
    v14.localePlaceholders={}
    local dictionary={
        ["RECENTES"]={en="RECENT COMMANDS",es="COMANDOS RECIENTES"},
        ["Ultimos comandos executados na sessao"]={en="Recently executed commands this session",es="Comandos recientes de esta sesion"},
        ["Ainda nao ha comandos recentes."]={en="No recent commands yet.",es="Aun no hay comandos recientes."},
        ["EXECUTAR"]={en="RUN",es="EJECUTAR"},
        ["FAVORITO"]={en="FAVORITE",es="FAVORITO"},
        ["MACROS DE COMANDOS"]={en="COMMAND MACROS",es="MACROS DE COMANDOS"},
        ["Apenas comandos locais permitidos, separados por ponto e virgula"]={en="Only permitted local commands, separated by semicolons",es="Solo comandos locales permitidos, separados por punto y coma"},
        ["Nome da macro"]={en="Macro name",es="Nombre de macro"},
        ["Exemplo: speed 60; fov 80; crosshair on"]={en="Example: speed 60; fov 80; crosshair on",es="Ejemplo: speed 60; fov 80; crosshair on"},
        ["SALVAR MACRO"]={en="SAVE MACRO",es="GUARDAR MACRO"},
        ["Nenhuma macro salva."]={en="No saved macros.",es="No hay macros guardadas."},
        ["ROTAS DE EXPLORACAO"]={en="EXPLORATION ROUTES",es="RUTAS DE EXPLORACION"},
        ["Crie rotas utilizando waypoints salvos no Gerenciador de Teleporte"]={en="Build routes from saved waypoints in the Teleport Manager",es="Crea rutas con puntos guardados en Teletransporte"},
        ["Nome da rota"]={en="Route name",es="Nombre de la ruta"},
        ["Waypoints separados por espaco: casa spawn loja"]={en="Waypoints separated by spaces: home spawn shop",es="Puntos separados por espacios: casa spawn tienda"},
        ["SALVAR ROTA"]={en="SAVE ROUTE",es="GUARDAR RUTA"},
        ["PROXIMO PONTO"]={en="NEXT POINT",es="SIGUIENTE PUNTO"},
        ["Nenhuma rota salva. Salve waypoints primeiro."]={en="No routes. Save waypoints first.",es="No hay rutas. Guarda puntos primero."},
        ["ABRIR TELEPORTE"]={en="OPEN TELEPORT",es="ABRIR TELETRANSPORTE"},
        ["INICIAR"]={en="START",es="INICIAR"},
        ["EXCLUIR"]={en="DELETE",es="BORRAR"},
        ["SELECIONADA"]={en="SELECTED",es="SELECCIONADA"},
        ["PRESSIONE F2 OU ABRA PELO COMANDO WHEEL"]={en="PRESS F2 OR USE THE WHEEL COMMAND",es="PULSA F2 O USA EL COMANDO WHEEL"},
        ["Dashboard"]={en="Dashboard",es="Panel"},
        ["Rotas"]={en="Routes",es="Rutas"},
        ["Recentes"]={en="Recent",es="Recientes"},
        ["Avatar"]={en="Avatar",es="Avatar"},
        ["Audio"]={en="Audio",es="Audio"},
        ["Estatisticas"]={en="Statistics",es="Estadisticas"},
        ["Cinema"]={en="Cinema",es="Cine"},
        ["Macros"]={en="Macros",es="Macros"},
        ["Ajuda"]={en="Help",es="Ayuda"},
        ["Comandos"]={en="Commands",es="Comandos"},
        ["Jogadores"]={en="Players",es="Jugadores"},
        ["Favoritos"]={en="Favorites",es="Favoritos"},
        ["Teleporte"]={en="Teleport",es="Teletransporte"},
        ["Desempenho"]={en="Performance",es="Rendimiento"},
        ["Ajustes"]={en="Settings",es="Ajustes"}
    }
    v14.t=function(key)
        local lang=config.lang
        if lang=="pt" then return key end
        local item=dictionary[key]
        return item and item[lang] or key
    end
    v14.addTranslation=function(key,translations)
        dictionary[key]=translations
    end
    v14.tr=function(component,key)
        v14.localeLabels[#v14.localeLabels+1]={obj=component,key=key}
        component.Text=v14.t(key)
        return component
    end
    v14.translate=function()
        for _,entry in ipairs(v14.localeLabels) do
            if entry.obj.Parent then entry.obj.Text=v14.t(entry.key) end
        end
        for _,entry in ipairs(v14.localePlaceholders) do
            if entry.obj.Parent then entry.obj.PlaceholderText=v14.t(entry.key) end
        end
        if v14.refresh then v14.refresh(selected) end
    end
    local function box(parent,textPlaceholder,h,multi)
        local b=round(obj("TextBox",parent,{
            Size=UDim2.new(1,-8,0,h or 37),
            Text="",PlaceholderText=v14.t(textPlaceholder),
            PlaceholderColor3=muted,TextColor3=white,
            BackgroundColor3=control,BorderSizePixel=0,
            ClearTextOnFocus=false,
            Font=Enum.Font.Gotham,TextSize=12,
            TextWrapped=multi==true,MultiLine=multi==true,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        }),8)
        obj("UIStroke",b,{Color=accent,Transparency=.65,Thickness=1})
        v14.localePlaceholders[#v14.localePlaceholders+1]={obj=b,key=textPlaceholder}
        return b
    end
    local function title(page,titleText,desc)
        local c=round(obj("Frame",page,{
            Size=UDim2.new(1,-8,0,69),
            BackgroundColor3=Color3.fromRGB(38,11,21),BorderSizePixel=0
        }),10)
        obj("UIStroke",c,{Color=accent,Transparency=.4,Thickness=1})
        local heading=txt(c,v14.t(titleText),30,18,true)
        heading.Position=UDim2.fromOffset(16,8)
        heading.Size=UDim2.new(1,-31,0,29)
        heading.TextColor3=accent
        v14.tr(heading,titleText)
        local small=txt(c,v14.t(desc),23,11)
        small.Position=UDim2.fromOffset(16,40)
        small.Size=UDim2.new(1,-31,0,24)
        small.TextColor3=muted
        v14.tr(small,desc)
        return c
    end
    local function section(page,label)
        return v14.tr(titleRow(page,v14.t(label)),label)
    end
    local function holder(page)
        local c=obj("Frame",page,{
            Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1
        })
        stack(c,7)
        return c
    end
    local function row(parent,label,options)
        local cell=round(obj("Frame",parent,{
            Size=UDim2.new(1,-8,0,55),BackgroundColor3=control,
            BorderSizePixel=0
        }),9)
        local items=options or {}
        local reserve=12
        for _,entry in ipairs(items) do
            reserve=reserve+(entry[3] or 77)+7
        end
        local textLabel=txt(cell,label,33,12,true)
        textLabel.Position=UDim2.fromOffset(11,6)
        textLabel.Size=UDim2.new(1,-reserve-14,0,42)
        textLabel.TextColor3=white
        local cursor=12
        for i=#items,1,-1 do
            local entry=items[i]
            local w=entry[3] or 77
            local b=btn(cell,v14.t(entry[1]),entry[2],32)
            b.Position=UDim2.new(1,-cursor-w,0,11)
            b.Size=UDim2.fromOffset(w,32)
            b.TextSize=10
            if not entry[4] then v14.tr(b,entry[1]) end
            cursor=cursor+w+7
        end
        return cell
    end
    v14.ui={box=box,title=title,section=section,holder=holder,row=row}

    -- Command Wheel acessivel por F2, gamepad R1 ou comando 'wheel'.
    local wheelDefaults={"fly","unfly","noclip","clip","invisible","visible","goto nearest","manual"}
    v14.wheelCommands={}
    v14.wheelRefresh=function()
        local seen={}
        local list={}
        local fav={}
        for name,on in pairs(v13Data.favorites) do
            if on and byName[name] then fav[#fav+1]=name end
        end
        table.sort(fav)
        for _,command in ipairs(fav) do
            if not seen[command] then list[#list+1]=command seen[command]=true end
        end
        for _,command in ipairs(wheelDefaults) do
            if not seen[command] then list[#list+1]=command seen[command]=true end
        end
        v14.wheelCommands={}
        for i=1,math.min(8,#list) do v14.wheelCommands[i]=list[i] end
    end
    v14.toggleWheel=function()
        if stopped then return end
        if v14.wheelOpen then
            v14.wheelOpen=false
            if v14.wheelFrame and v14.wheelFrame.Parent then v14.wheelFrame:Destroy() end
            v14.wheelFrame=nil
            return
        end
        v14.wheelRefresh()
        v14.wheelOpen=true
        local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
        local wheelX=math.clamp((view.X-180)/2,114,235)
        local wheelY=math.clamp((view.Y-130)/2,88,200)
        local overlay=obj("Frame",gui,{
            Size=UDim2.fromScale(1,1),BackgroundColor3=ink,
            BackgroundTransparency=.22,Active=true,ZIndex=70,
            BorderSizePixel=0
        })
        v14.wheelFrame=overlay
        local center=round(obj("Frame",overlay,{
            AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
            Size=UDim2.fromOffset(156,156),
            BackgroundColor3=Color3.fromRGB(35,7,17),
            BorderSizePixel=0,ZIndex=71
        }),75)
        obj("UIStroke",center,{Color=accent,Thickness=2,Transparency=.08})
        local logo=txt(center,"B\nBRAB0X\nWHEEL",100,17,true)
        logo.TextXAlignment=Enum.TextXAlignment.Center
        logo.Position=UDim2.fromOffset(9,24)
        logo.Size=UDim2.new(1,-18,0,109)
        logo.TextColor3=accent
        logo.ZIndex=72
        for i,cmd in ipairs(v14.wheelCommands) do
            local angle=(i-1)*math.pi/4-math.pi/2
            local x=math.cos(angle)*wheelX
            local y=math.sin(angle)*wheelY
            local label=cmd:upper()
            local b=btn(overlay,label,function()
                v14.toggleWheel()
                exec(cmd)
            end,44)
            b.AnchorPoint=Vector2.new(.5,.5)
            b.Position=UDim2.new(.5,x,.5,y)
            b.Size=UDim2.fromOffset(view.X<700 and 110 or 142,44)
            b.BackgroundColor3=Color3.fromRGB(50,14,26)
            b.TextSize=11
            b.ZIndex=75
            obj("UIStroke",b,{Color=accent,Thickness=1.2,Transparency=.18})
        end
        local close=btn(overlay,"✕",v14.toggleWheel,35)
        close.Position=UDim2.new(.5,87,.5,-17)
        close.Size=UDim2.fromOffset(38,38)
        close.ZIndex=75
    end

    v14.buildCore=function()
        -- Recentes: acesso imediato e repeticao sem duplicar comandos.
        title(pages.RECENT,"RECENTES","Ultimos comandos executados na sessao")
        section(pages.RECENT,"PRESSIONE F2 OU ABRA PELO COMANDO WHEEL")
        local recentHolder=holder(pages.RECENT)
        v14.panelRefresh.RECENT=function()
            clear(recentHolder)
            if #v14.recent==0 then
                local none=txt(recentHolder,v14.t("Ainda nao ha comandos recentes."),44,12)
                none.TextColor3=muted
                return
            end
            for i=1,math.min(18,#v14.recent) do
                local item=v14.recent[i]
                row(recentHolder,item.time.."  |  "..item.raw,{
                    {"EXECUTAR",function()exec(item.raw)end,90},
                    {"FAVORITO",function()
                        v13Data.favorites[item.command]=true
                        saveV13()
                        if refreshCommandList then refreshCommandList() end
                        notify("Adicionado aos favoritos: "..item.command)
                    end,83}
                })
            end
        end

        -- Macros: apenas lista segura de comandos predefinidos, sem Lua arbitrario.
        title(pages.MACROS,"MACROS DE COMANDOS","Apenas comandos locais permitidos, separados por ponto e virgula")
        local macroName=box(pages.MACROS,"Nome da macro",38)
        local macroBody=box(pages.MACROS,"Exemplo: speed 60; fov 80; crosshair on",74,true)
        local macroControls=obj("Frame",pages.MACROS,{Size=UDim2.new(1,-8,0,42),BackgroundTransparency=1})
        local saveMacroButton=btn(macroControls,"SALVAR MACRO",function()
            v14.macroSave(macroName.Text,macroBody.Text)
        end,41)
        saveMacroButton.Size=UDim2.new(.5,-4,1,0)
        v14.tr(saveMacroButton,"SALVAR MACRO")
        local demo=btn(macroControls,"EXEMPLO",function()
            macroName.Text="explorar"
            macroBody.Text="speed 65; fov 80; crosshair on"
        end,41)
        demo.Position=UDim2.new(.5,4,0,0)
        demo.Size=UDim2.new(.5,-4,1,0)
        section(pages.MACROS,"MACROS")
        local macroHolder=holder(pages.MACROS)
        v14.panelRefresh.MACROS=function()
            clear(macroHolder)
            local names={}
            for name in pairs(v14.macros) do names[#names+1]=name end
            table.sort(names)
            if #names==0 then
                local none=txt(macroHolder,v14.t("Nenhuma macro salva."),44,12)
                none.TextColor3=muted
            end
            for _,name in ipairs(names) do
                local commands=v14.macros[name]
                row(macroHolder,name.."  •  "..(type(commands)=="table" and #commands or 0).." comandos",{
                    {"EXECUTAR",function()v14.macroRun(name)end,91},
                    {"EXCLUIR",function()v14.macroDelete(name)end,83}
                })
            end
        end

        -- Rotas: waypoint existentes; o usuario avanca manualmente.
        title(pages.ROUTES,"ROTAS DE EXPLORACAO",
            "Crie rotas utilizando waypoints salvos no Gerenciador de Teleporte")
        local routeName=box(pages.ROUTES,"Nome da rota",36)
        local routeBody=box(pages.ROUTES,"Waypoints separados por espaco: casa spawn loja",36)
        local routeControls=obj("Frame",pages.ROUTES,{Size=UDim2.new(1,-8,0,42),BackgroundTransparency=1})
        local saveRoute=btn(routeControls,"SALVAR ROTA",function()
            v14.routeSave(routeName.Text.." "..routeBody.Text)
        end,41)
        saveRoute.Size=UDim2.new(1/3,-5,1,0)
        v14.tr(saveRoute,"SALVAR ROTA")
        local nextPoint=btn(routeControls,"PROXIMO PONTO",function()
            v14.routeNext()
        end,41)
        nextPoint.Position=UDim2.new(1/3,2,0,0)
        nextPoint.Size=UDim2.new(1/3,-5,1,0)
        v14.tr(nextPoint,"PROXIMO PONTO")
        local openTeleport=btn(routeControls,"ABRIR TELEPORTE",function()show("TELEPORT")end,41)
        openTeleport.Position=UDim2.new(2/3,3,0,0)
        openTeleport.Size=UDim2.new(1/3,-4,1,0)
        v14.tr(openTeleport,"ABRIR TELEPORTE")
        local routeStatus=titleRow(pages.ROUTES,"Rota nao selecionada.")
        local routeHolder=holder(pages.ROUTES)
        v14.panelRefresh.ROUTES=function()
            clear(routeHolder)
            local names={}
            for name in pairs(v14.routes) do names[#names+1]=name end
            table.sort(names)
            if #names==0 then
                local none=txt(routeHolder,v14.t("Nenhuma rota salva. Salve waypoints primeiro."),47,12)
                none.TextColor3=muted
            end
            local chosen=v14.selectedRoute and v14.routes[v14.selectedRoute]
            local nextName=chosen and chosen[v14.routeIndex or 1] or nil
            local dist=""
            if nextName and extraState.savedWaypoints[nextName] then
                local _,_,root=chars()
                if root then
                    dist="  •  "..math.floor((root.Position-extraState.savedWaypoints[nextName].Position).Magnitude).." studs"
                end
            end
            routeStatus.Text=chosen and
                ("Rota: "..v14.selectedRoute.."  |  "..(v14.routeIndex or 1).."/"..#chosen..dist)
                or "Nenhuma rota selecionada"
            for _,name in ipairs(names) do
                local route=v14.routes[name]
                row(routeHolder,name.."  •  "..#route.." pontos",{
                    {"INICIAR",function()v14.routeStart(name)end,88},
                    {"EXCLUIR",function()v14.routeDelete(name)end,83}
                })
            end
        end
    end
end

-- V14 / CINEMA, AVATAR, AUDIO, DASHBOARD, ESTATISTICAS E GAMEPAD
do
    local function addTranslations()
        local words={
            ["MODO CINEMATOGRAFICO"]={en="CINEMATIC MODE",es="MODO CINEMATOGRAFICO"},
            ["Camera livre local para gravacoes no seu proprio mapa"]={en="Local free camera for recordings in your own map",es="Camara libre local para grabar tu mapa"},
            ["ATIVE O CINEMA PARA VOAR COM A CAMERA. F6 PARA SAIR."]={en="ENABLE CINEMA FOR FREE CAMERA. PRESS F6 TO EXIT.",es="ACTIVA EL CINE PARA CAMARA LIBRE. F6 PARA SALIR."},
            ["INICIAR CINEMA"]={en="START CINEMA",es="INICIAR CINE"},
            ["PARAR CINEMA"]={en="STOP CINEMA",es="DETENER CINE"},
            ["VELOCIDADE DA CAMERA"]={en="CAMERA SPEED",es="VELOCIDAD DE CAMARA"},
            ["MOVIMENTOS: WASD / E / Q  •  SHIFT ACELERA"]={en="WASD / E / Q • SHIFT BOOST • RMB LOOK",es="WASD / E / Q • SHIFT ACELERA • BOTON DERECHO MIRA"},
            ["EDITOR DE AVATAR LOCAL"]={en="LOCAL AVATAR EDITOR",es="EDITOR DE AVATAR LOCAL"},
            ["Mudancas de cor visiveis apenas na sua tela, com restauracao"]={en="Color changes visible only to you, with restore",es="Cambios de color solo visibles para ti, con restauracion"},
            ["RESTAURAR AVATAR"]={en="RESTORE AVATAR",es="RESTAURAR AVATAR"},
            ["BRILHO"]={en="GLOW",es="BRILLO"},
            ["RASTRO"]={en="TRAIL",es="RASTRO"},
            ["VERMELHO"]={en="RED",es="ROJO"},
            ["PRETO"]={en="BLACK",es="NEGRO"},
            ["BRANCO"]={en="WHITE",es="BLANCO"},
            ["AZUL"]={en="BLUE",es="AZUL"},
            ["DOURADO"]={en="GOLD",es="DORADO"},
            ["AUDIO E MUSICA"]={en="AUDIO & MUSIC",es="AUDIO Y MUSICA"},
            ["Use IDs de sons autorizados para esta experiencia"]={en="Use sound IDs authorized for this experience",es="Usa IDs de sonidos autorizados en este juego"},
            ["ID do som Roblox autorizado"]={en="Authorized Roblox sound ID",es="ID de sonido Roblox autorizado"},
            ["REPRODUZIR"]={en="PLAY",es="REPRODUCIR"},
            ["PAUSAR/CONTINUAR"]={en="PAUSE/RESUME",es="PAUSAR/REANUDAR"},
            ["PARAR AUDIO"]={en="STOP AUDIO",es="DETENER AUDIO"},
            ["EFEITO UNICO"]={en="ONE-SHOT SOUND",es="EFECTO UNICO"},
            ["VOLUME"]={en="VOLUME",es="VOLUMEN"},
            ["O audio pode falhar por privacidade ou permissao do asset."]={en="Audio may fail due to asset privacy or permissions.",es="El sonido puede fallar por privacidad o permisos."},
            ["ESTATISTICAS DO HUB"]={en="HUB STATISTICS",es="ESTADISTICAS DEL HUB"},
            ["Uso nesta sessao, totais locais e comandos frequentes"]={en="Session usage, local totals and most-used commands",es="Uso de esta sesion, totales y comandos frecuentes"},
            ["DASHBOARD PERSONALIZAVEL"]={en="CUSTOM DASHBOARD",es="PANEL PERSONALIZABLE"},
            ["Quatro atalhos editaveis com acesso direto"]={en="Four editable shortcuts with direct access",es="Cuatro accesos directos editables"},
            ["ALTERAR"]={en="CHANGE",es="CAMBIAR"},
            ["ULTIMOS"]={en="RECENT",es="RECIENTES"},
            ["ABRIR WHEEL"]={en="OPEN WHEEL",es="ABRIR RUEDA"},
            ["MODO SEGURO"]={en="SAFE MODE",es="MODO SEGURO"},
            ["Confirme duas vezes comandos que apagam ou restauram configuracoes"]={en="Confirm destructive commands twice",es="Confirma dos veces los comandos de borrado"},
            ["ATIVADO"]={en="ENABLED",es="ACTIVADO"},
            ["DESATIVADO"]={en="DISABLED",es="DESACTIVADO"},
            ["CONTROLE / GAMEPAD"]={en="CONTROLLER / GAMEPAD",es="MANDO / GAMEPAD"},
            ["START menu, R1 wheel, B voltar, Y recentes, X favoritos"]={en="START menu, R1 wheel, B back, Y recent, X favorites",es="START menu, R1 rueda, B volver, Y recientes, X favoritos"}
        }
        for key,value in pairs(words) do v14.addTranslation(key,value) end
    end
    v14.buildExtras=function()
        addTranslations()
        local ui=v14.ui
        local function note(parent,description,height)
            local t=txt(parent,v14.t(description),height or 35,12)
            t.TextColor3=muted
            v14.tr(t,description)
            return t
        end
        local function controls(parent,options)
            local bar=obj("Frame",parent,{
                Size=UDim2.new(1,-8,0,44),BackgroundTransparency=1
            })
            for i,entry in ipairs(options) do
                local b=btn(bar,v14.t(entry[1]),entry[2],42)
                b.Position=UDim2.new((i-1)/#options,3,0,0)
                b.Size=UDim2.new(1/#options,-7,0,42)
                b.TextSize=10
                v14.tr(b,entry[1])
            end
            return bar
        end

        -- Cinema: camera Scriptable, sem mover o personagem.
        ui.title(pages.CINEMA,"MODO CINEMATOGRAFICO",
            "Camera livre local para gravacoes no seu proprio mapa")
        note(pages.CINEMA,"ATIVE O CINEMA PARA VOAR COM A CAMERA. F6 PARA SAIR.",38)
        controls(pages.CINEMA,{
            {"INICIAR CINEMA",function()exec("cinema")end},
            {"PARAR CINEMA",function()exec("uncinema")end}
        })
        sliderControl(pages.CINEMA,"VELOCIDADE DA CAMERA",
            "Ajuste de 2 a 70 studs por segundo",2,70,2,
            function()return v14.cinemaSpeed end,"cinemaspeed","%.0f")
        note(pages.CINEMA,"MOVIMENTOS: WASD / E / Q  •  SHIFT ACELERA",50)
        note(pages.CINEMA,"Segure o botao direito do mouse para girar a camera.",38)
        local camState=ui.section(pages.CINEMA,"MODO CINEMATOGRAFICO")
        v14.panelRefresh.CINEMA=function()
            camState.Text="CAMERA LIVRE: "..(v14.cinematic and "ON" or "OFF")
        end

        -- Editor local: cores e efeitos; restaura estado original.
        ui.title(pages.AVATAR,"EDITOR DE AVATAR LOCAL",
            "Mudancas de cor visiveis apenas na sua tela, com restauracao")
        local colors={
            {"VERMELHO","red"},{"PRETO","black"},{"BRANCO","white"},
            {"AZUL","blue"},{"DOURADO","gold"}
        }
        local grid=obj("Frame",pages.AVATAR,{
            Size=UDim2.new(1,-8,0,132),BackgroundTransparency=1
        })
        for i,entry in ipairs(colors) do
            local b=btn(grid,v14.t(entry[1]),function()
                v14.avatarApply(entry[2])
            end,52)
            local col=(i-1)%3
            local row=math.floor((i-1)/3)
            b.Position=UDim2.new(col/3,3,row/2,3)
            b.Size=UDim2.new(1/3,-8,.5,-7)
            v14.tr(b,entry[1])
        end
        controls(pages.AVATAR,{
            {"RESTAURAR AVATAR",function()
                v14.avatarRestore()
                notify("Visual local restaurado.","success")
            end},
            {"BRILHO",function()exec(S.glow and "unglow" or "glow")end},
            {"RASTRO",function()exec(S.trail and "untrail" or "trail")end}
        })
        note(pages.AVATAR,"Efeitos sao locais e podem nao aparecer para outros jogadores.",39)

        -- Audio: ID fornecido pelo usuario, sem buscar musica protegida.
        ui.title(pages.AUDIO,"AUDIO E MUSICA",
            "Use IDs de sons autorizados para esta experiencia")
        local audioId=ui.box(pages.AUDIO,"ID do som Roblox autorizado",40)
        controls(pages.AUDIO,{
            {"REPRODUZIR",function()exec("music "..audioId.Text)end},
            {"PAUSAR/CONTINUAR",function()
                if not v14.music then return end
                if v14.music.IsPlaying then v14.music:Pause()
                else v14.music:Resume() end
            end},
            {"PARAR AUDIO",function()exec("stopmusic")end}
        })
        controls(pages.AUDIO,{
            {"EFEITO UNICO",function()
                if v14.musicPlay(audioId.Text) and v14.music then
                    v14.music.Looped=false
                end
            end}
        })
        sliderControl(pages.AUDIO,"VOLUME","Volume do som local (0 a 1)",0,1,.05,
            function()return v14.musicVolume end,"musicvolume","%.2f")
        note(pages.AUDIO,"O audio pode falhar por privacidade ou permissao do asset.",40)
        local songStatus=ui.section(pages.AUDIO,"AUDIO E MUSICA")
        v14.panelRefresh.AUDIO=function()
            songStatus.Text=v14.music and
                ("ID "..v14.musicId.." • "..(v14.music.IsPlaying and "TOCANDO" or "PAUSADO"))
                or "SEM AUDIO ATIVO"
        end

        -- Estatisticas persistentes, se o ambiente permite gravar JSON.
        ui.title(pages.STATS,"ESTATISTICAS DO HUB",
            "Uso nesta sessao, totais locais e comandos frequentes")
        local statsHeader=ui.section(pages.STATS,"ESTATISTICAS DO HUB")
        local statsHolder=ui.holder(pages.STATS)
        v14.panelRefresh.STATS=function()
            if not pages.STATS.Visible then return end
            clear(statsHolder)
            local seconds=math.max(0,math.floor(os.clock()-v14.sessionStarted))
            local seen=v14.commandsInSession
            statsHeader.Text=string.format(
                "SESSAO: %dm %ds  |  COMANDOS: %d  |  TOTAL: %d",
                math.floor(seconds/60),seconds%60,seen,v14.stats.commandCount or 0)
            local favCount=0
            for _,active in pairs(v13Data.favorites) do if active then favCount=favCount+1 end end
            ui.row(statsHolder,
                "SESSOES: "..tostring(v14.stats.totalSessions).."  |  FAVORITOS: "..favCount,{})
            local order={}
            for name,count in pairs(v14.stats.frequency) do
                if byName[name] and type(count)=="number" then
                    order[#order+1]={name=name,count=count}
                end
            end
            table.sort(order,function(a,b) return a.count>b.count end)
            for i=1,math.min(10,#order) do
                local item=order[i]
                ui.row(statsHolder,
                    tostring(i)..". "..item.name.."  •  "..item.count.." vezes",{
                    {"EXECUTAR",function()exec(byName[item.name].example)end,90}
                })
            end
        end

        -- Dashboard: quatro botoes com atalhos selecionaveis, salvos em JSON.
        ui.title(pages.DASHBOARD,"DASHBOARD PERSONALIZAVEL",
            "Quatro atalhos editaveis com acesso direto")
        local available={
            "fly","unfly","noclip","clip","boost","unboost",
            "invisible","visible","goto nearest","manual","wheel",
            "favorites","recent","cinema","uncinema","fullbright","unfullbright"
        }
        local defaults={"fly","noclip","wheel","favorites"}
        local saved=v14.dashboard.slots
        if type(saved)~="table" then saved={} v14.dashboard.slots=saved end
        for i=1,4 do if type(saved[i])~="string" then saved[i]=defaults[i] end end
        local dashboardStats=ui.section(pages.DASHBOARD,"DASHBOARD PERSONALIZAVEL")
        local dashHolder=ui.holder(pages.DASHBOARD)
        controls(pages.DASHBOARD,{
            {"ABRIR WHEEL",function()v14.toggleWheel()end},
            {"ULTIMOS",function()show("RECENT")end},
            {"MODO SEGURO",function()
                v14.safe=not v14.safe
                notify("Modo seguro "..(v14.safe and "ON" or "OFF"))
            end}
        })
        v14.panelRefresh.DASHBOARD=function()
            if not pages.DASHBOARD.Visible then return end
            clear(dashHolder)
            dashboardStats.Text="V17.1  •  "..v14.commandsInSession.." comandos nesta sessao  •  @wendezao05153nh"
            for i=1,4 do
                local command=saved[i]
                ui.row(dashHolder,"ATALHO "..i..": "..command:upper(),{
                    {"EXECUTAR",function()exec(saved[i])end,87},
                    {"ALTERAR",function()
                        local at=table.find(available,saved[i]) or 0
                        saved[i]=available[at%#available+1]
                        saveV13()
                        v14.panelRefresh.DASHBOARD()
                    end,80}
                })
            end
        end
        -- Indicador do modo seguro e gamepad em Ajustes.
        ui.section(pages.SETTINGS,"MODO SEGURO")
        note(pages.SETTINGS,
            "Confirme duas vezes comandos que apagam ou restauram configuracoes",42)
        toggleControl(pages.SETTINGS,"MODO SEGURO","Confirmacao para acoes de apagar",
            function()return v14.safe end,"safemode on","safemode off")
        ui.section(pages.SETTINGS,"CONTROLE / GAMEPAD")
        note(pages.SETTINGS,
            "START menu, R1 wheel, B voltar, Y recentes, X favoritos",40)
        toggleControl(pages.SETTINGS,"ATIVAR GAMEPAD","Atalho Start, R1, X, Y",
            function()return v14.controllerMode end,"gamepad on","gamepad off")
        controls(pages.SETTINGS,{
            {"ABRIR WHEEL",function()v14.toggleWheel()end},
            {"MACROS",function()show("MACROS")end},
            {"DASHBOARD",function()show("DASHBOARD")end}
        })
    end

    v14.install=function()
        if v14.buildCore then v14.buildCore() end
        if v14.buildExtras then v14.buildExtras() end
        if v14.buildGameRouter then v14.buildGameRouter() end
        if v14.v17 and v14.v17.install then v14.v17.install() end
        v14.refresh=function(page)
            local update=v14.panelRefresh and v14.panelRefresh[page]
            if update and pages[page] and pages[page].Visible then
                local ok,err=pcall(update)
                if not ok then warn("[BRAB0X V17.1] Falha no painel "..page..": "..tostring(err)) end
            end
        end
        if v14.translate then v14.translate() end
        if v14.router and v14.router.initialize then
            v14.router.initialize()
        end
        task.spawn(function()
            while not stopped and gui.Parent do
                task.wait(3)
                if (selected=="STATS" or selected=="DASHBOARD") and v14.refresh then
                    v14.refresh(selected)
                end
            end
        end)
    end

    -- F2 Wheel, F6 Cinema, gamepad Start/R1/B, botoes nativos do Roblox.
    v14.onInput=function(input,used)
        local key=input.KeyCode
        if v14.v17 and v14.v17.onInput and v14.v17.onInput(input,used) then return true end
        if UIS:GetFocusedTextBox() and key~=Enum.KeyCode.ButtonStart then return false end
        if v14.v17 and v14.v17.onInput and v14.v17.onInput(input,used) then return true end
        if key==Enum.KeyCode.F6 and not used then
            if v14.cinematic then v14.stopCinema() else v14.startCinema() end
            return true
        end
        if key==Enum.KeyCode.F2 and not used then
            v14.toggleWheel()
            return true
        end
        if key==Enum.KeyCode.ButtonStart or key==Enum.KeyCode.ButtonR1
            or key==Enum.KeyCode.ButtonB or key==Enum.KeyCode.ButtonX
            or key==Enum.KeyCode.ButtonY then
            v14.controllerMode=true
            if key==Enum.KeyCode.ButtonStart then
                if v14.cinematic then v14.stopCinema() end
                main.Visible=not main.Visible
                reopen.Visible=not main.Visible
                if main.Visible then
                    pcall(function() GuiService.SelectedObject=navButtons[selected] or navButtons.HOME end)
                end
                return true
            elseif key==Enum.KeyCode.ButtonR1 then
                if main.Visible or v14.wheelOpen then
                    v14.toggleWheel()
                    return true
                end
            elseif key==Enum.KeyCode.ButtonB then
                if v14.wheelOpen then v14.toggleWheel()
                elseif v14.cinematic then v14.stopCinema()
                elseif main.Visible and selected~="HOME" then show("HOME")
                elseif main.Visible then main.Visible=false reopen.Visible=true
                else return false end
                return true
            elseif key==Enum.KeyCode.ButtonY and main.Visible then
                show("RECENT")
                return true
            elseif key==Enum.KeyCode.ButtonX and main.Visible then
                show("FAVORITES")
                return true
            end
        end
        return false
    end
end

-- V15 / GERENCIADOR VISUAL DE JOGOS
-- Um unico loadstring: usa game.PlaceId para reconhecer e aplicar perfis de forma automatica.
do
    local router=v14.router
    local ui=v14.ui
    v14.buildGameRouter=function()
        local page=pages.GAMES
        local header=ui.title(page,"GERENCIADOR UNIVERSAL DE JOGOS",
            "O mesmo carregador detecta automaticamente o PlaceId de cada jogo.")
        local mode=round(obj("Frame",page,{
            Size=UDim2.new(1,-8,0,156),
            BackgroundColor3=Color3.fromRGB(28,18,27),
            BorderSizePixel=0
        }),10)
        obj("UIStroke",mode,{Color=accent,Thickness=1,Transparency=.3})
        local gameName=txt(mode,"JOGO: --",37,19,true)
        gameName.Position=UDim2.fromOffset(15,10)
        gameName.Size=UDim2.new(1,-30,0,36)
        gameName.TextColor3=accent
        local placeInfo=txt(mode,"PLACE ID: --",28,13,true)
        placeInfo.Position=UDim2.fromOffset(16,46)
        placeInfo.Size=UDim2.new(1,-32,0,29)
        local moduleInfo=txt(mode,"MODULO: UNIVERSAL",35,12,true)
        moduleInfo.Position=UDim2.fromOffset(16,78)
        moduleInfo.Size=UDim2.new(1,-32,0,28)
        moduleInfo.TextColor3=white
        local modeNote=txt(mode,
            "Modulos exclusivos so serao habilitados para jogos cadastrados no codigo.",
            46,11)
        modeNote.Position=UDim2.fromOffset(16,107)
        modeNote.Size=UDim2.new(1,-32,0,42)
        modeNote.TextColor3=muted

        ui.section(page,"NOME DESTE JOGO")
        local labelBox=ui.box(page,"Nome do jogo ou apelido personalizado",39)
        local function buttons(items)
            local frame=obj("Frame",page,{
                Size=UDim2.new(1,-8,0,42),
                BackgroundTransparency=1
            })
            for i,entry in ipairs(items) do
                local b=btn(frame,entry[1],entry[2],40)
                b.Position=UDim2.new((i-1)/#items,3,0,0)
                b.Size=UDim2.new(1/#items,-8,1,0)
                b.TextSize=10
            end
            return frame
        end
        buttons({
            {"SALVAR NOME",function()router.setLabel(labelBox.Text)end},
            {"PERFIL DESTE JOGO",function()router.saveProfile()end}
        })
        ui.section(page,"MODOS DO CARREGADOR")
        buttons({
            {"SALVAR PERFIL",function()router.saveProfile()end},
            {"APLICAR PERFIL",function()router.applyProfile()end},
            {"UNIVERSAL",function()router.useUniversal()end}
        })
        local explanation=txt(page,
            "UNIVERSAL = todos os comandos normais. PERFIL = suas preferencias, FOV, velocidade e atalhos para este PlaceId.",
            48,12)
        explanation.TextColor3=muted

        ui.section(page,"ATALHOS ESPECIFICOS PARA ESTE JOGO")
        local inputs={}
        for index=1,4 do
            local cell=round(obj("Frame",page,{
                Size=UDim2.new(1,-8,0,49),
                BackgroundColor3=control,
                BorderSizePixel=0
            }),8)
            local num=txt(cell,tostring(index)..".",24,13,true)
            num.Position=UDim2.fromOffset(9,10)
            num.Size=UDim2.fromOffset(34,30)
            num.TextColor3=accent
            local field=round(obj("TextBox",cell,{
                Position=UDim2.fromOffset(42,8),
                Size=UDim2.new(1,-166,0,34),
                Text=tostring(router.profile.quick[index] or ""),
                PlaceholderText="ex.: fly, fov 80, goto nearest",
                BackgroundColor3=Color3.fromRGB(39,28,38),
                TextColor3=white,PlaceholderColor3=muted,
                BorderSizePixel=0,Font=Enum.Font.Code,
                TextSize=12,ClearTextOnFocus=false
            }),7)
            inputs[index]=field
            local execute=btn(cell,"EXECUTAR",function()
                local command=router.safeQuick(field.Text)
                if not command then
                    notify("Atalho desconhecido ou nao permitido.","error")
                    return
                end
                exec(command)
            end,34)
            execute.Position=UDim2.new(1,-118,0,8)
            execute.Size=UDim2.fromOffset(109,34)
            execute.TextSize=10
        end
        buttons({
            {"SALVAR OS 4 ATALHOS",function()
                local result={}
                for _,field in ipairs(inputs) do result[#result+1]=field.Text end
                router.setQuicks(result)
            end},
            {"ABRIR COMANDOS",function()show("COMMANDS")end},
            {"AJUDA",function()show("HELP")end}
        })
        ui.section(page,"CADASTRAR OUTRO JOGO")
        local newId=ui.box(page,"PlaceId do outro jogo (somente numeros)",38)
        local newName=ui.box(page,"Nome do jogo cadastrado",38)
        buttons({
            {"CADASTRAR PLACEID",function()
                router.registerGame(newId.Text,newName.Text)
            end},
            {"LIMPAR CAMPOS",function()
                newId.Text=""
                newName.Text=""
            end}
        })
        local listCaption=txt(page,
            "Jogos registrados no seu BRAB0X PRIME (apenas perfis; nenhuma falha e explorada).",
            35,11)
        listCaption.TextColor3=muted

        ui.section(page,"JOGOS CADASTRADOS")
        local holder=ui.holder(page)
        local listHelp=txt(page,
            "Ao entrar em outro jogo e executar o mesmo loadstring, ele sera identificado automaticamente. Seus perfis sao locais.",
            43,11)
        listHelp.TextColor3=muted
        v14.panelRefresh.GAMES=function()
            if not page.Visible then return end
            router.detect()
            local profile=router.profile
            gameName.Text="JOGO: "..tostring(profile.label or "Desconhecido"):sub(1,45)
            placeInfo.Text="PlaceId: "..router.placeId.."     |     UniverseId: "..router.universeId
            moduleInfo.Text="MODO: "..(profile.mode=="custom" and "PERFIL DO JOGO" or "UNIVERSAL")..
                "     |     MODULO: "..(router.currentModule and router.currentModule.name or "PADRAO")
            if UIS:GetFocusedTextBox()~=labelBox then labelBox.Text=profile.label or "" end
            local selectedQuicks=(router.currentModule
                and not profile.customQuick and router.moduleQuick
                and #router.moduleQuick>0) and router.moduleQuick or profile.quick
            for index,field in ipairs(inputs) do
                if UIS:GetFocusedTextBox()~=field then
                    field.Text=tostring(selectedQuicks[index] or "")
                end
            end
            clear(holder)
            local names={}
            for id,value in pairs(router.profiles) do
                if type(value)=="table" and tostring(id):match("^%d+$") then
                    names[#names+1]=id
                end
            end
            table.sort(names,function(a,b)
                if a==router.placeId then return true end
                if b==router.placeId then return false end
                return (router.profiles[a].lastVisit or 0)>
                    (router.profiles[b].lastVisit or 0)
            end)
            for i=1,math.min(#names,35) do
                local id=names[i]
                local entry=router.profiles[id]
                local label=(entry.label or ("Jogo "..id)):sub(1,34)
                local mark=id==router.placeId and " ● ATUAL" or ""
                ui.row(holder,label.."  |  "..id..mark,{
                    {"MOSTRAR ID",function()
                        if type(setclipboard)=="function" then
                            local ok=pcall(setclipboard,id)
                            if ok then notify("PlaceId copiado: "..id);return end
                        end
                        cmdInput.Text=id
                        notify("PlaceId colocado no campo inferior: "..id)
                    end,99},
                    {id==router.placeId and "ATUAL" or "REMOVER",function()
                        if id==router.placeId then
                            router.info()
                        else
                            router.removeGame(id)
                        end
                    end,85}
                })
            end
        end
        v14.gamePageReady=true
        v14.panelRefresh.GAMES()
    end
end

-- V17 / ULTIMATE INTERFACE - PALETA, FAVORITOS POR JOGO, NOTAS, BUSSOLA, BACKUP E GUIA
do
    local m=v14.v17
    if m then
        local function info(parent,message,height)
            local t=txt(parent,message,height or 42,12)
            t.TextColor3=muted
            return t
        end
        local function groupButtons(parent,items)
            local bar=obj("Frame",parent,{
                Size=UDim2.new(1,-8,0,40),BackgroundTransparency=1
            })
            for i,entry in ipairs(items) do
                local button=btn(bar,entry[1],entry[2],39)
                button.Position=UDim2.new((i-1)/#items,3,0,0)
                button.Size=UDim2.new(1/#items,-7,0,39)
                button.TextSize=10
            end
            return bar
        end
        local function listBlock(parent,label,subtext)
            v14.ui.title(parent,label,subtext)
            return v14.ui.holder(parent)
        end
        local function copyText(text)
            if type(setclipboard)=="function" then
                local ok=pcall(setclipboard,text)
                if ok then
                    notify("Conteudo copiado para a area de transferencia.","success")
                    return true
                end
            end
            notify("Copie o texto manualmente (Ctrl+A, Ctrl+C).","info")
            return false
        end
        m.install=function()
            local ui=v14.ui
            m.pages={}

            -- Busca global: nenhum comando e executado sem selecao explicita.
            ui.title(pages.PALETTE,"⌕  PALETA DE COMANDOS",
                "Pesquise tudo com Ctrl+Shift+P e execute pela lista")
            info(pages.PALETTE,
                "Procure nomes, categorias ou descricoes. Clique em EXECUTAR para usar o comando. Atalho: Ctrl+Shift+P.",58)
            groupButtons(pages.PALETTE,{
                {"ABRIR BUSCA RAPIDA",function()m.openPalette()end},
                {"VER TODOS OS COMANDOS",function()show("COMMANDS")end}
            })
            ui.section(pages.PALETTE,"ULTIMOS EXECUTADOS")
            local paletteHistory=ui.holder(pages.PALETTE)
            m.pages.PALETTE=function()
                clear(paletteHistory)
                for i=1,math.min(8,#v14.recent) do
                    local row=v14.recent[i]
                    ui.row(paletteHistory,row.raw,{
                        {"EXECUTAR",function()exec(row.raw)end,87}
                    })
                end
                if #v14.recent==0 then info(paletteHistory,"Nenhum comando usado nesta sessao.",35) end
            end

            -- Favoritos separados do conjunto global.
            ui.title(pages.BOOKMARKS,"★  FAVORITOS POR JOGO",
                "Cada PlaceId possui uma lista independente de comandos favoritos")
            info(pages.BOOKMARKS,
                "Use gamefav fly para salvar um comando apenas neste jogo, ou adicione pela lista abaixo.",49)
            local favText=ui.box(pages.BOOKMARKS,"Nome do comando (ex.: fly)",39)
            groupButtons(pages.BOOKMARKS,{
                {"SALVAR NESTE JOGO",function()m.favoriteAdd(favText.Text)end},
                {"FAVORITOS GLOBAIS",function()show("FAVORITES")end}
            })
            ui.section(pages.BOOKMARKS,"COMANDOS MARCADOS")
            local bookmarkList=ui.holder(pages.BOOKMARKS)
            m.pages.BOOKMARKS=function()
                clear(bookmarkList)
                local names={}
                for name,on in pairs(m.favorites) do
                    if on and byName[name] then names[#names+1]=name end
                end
                table.sort(names)
                for _,name in ipairs(names) do
                    local entry=byName[name]
                    ui.row(bookmarkList,"★  "..name.."  •  "..entry.category,{
                        {"USAR",function()exec(entry.example)end,76},
                        {"TIRAR",function()m.favoriteRemove(name)end,72}
                    })
                end
                if #names==0 then info(bookmarkList,"Nenhum favorito deste jogo.",35) end
            end

            -- Bloco de notas separado e persistente por PlaceId.
            ui.title(pages.NOTES,"✎  NOTAS DO JOGO",
                "Guarde lembretes diferentes para cada experiencia")
            info(pages.NOTES,"Notas locais com ate 3000 caracteres. Nao sao enviadas para outros jogadores.",42)
            local noteField=ui.box(pages.NOTES,"Escreva suas notas aqui...",186,true)
            noteField.TextWrapped=true
            noteField.TextYAlignment=Enum.TextYAlignment.Top
            noteField.Text=type(v13Data.gameNotes[v15PlaceId])=="string"
                and v13Data.gameNotes[v15PlaceId] or ""
            local askNoteClear=false
            groupButtons(pages.NOTES,{
                {"SALVAR NOTA",function()
                    m.noteSave(noteField.Text)
                    askNoteClear=false
                end},
                {"APAGAR NOTA",function()
                    if v14.safe and not askNoteClear then
                        askNoteClear=true
                        notify("Clique em APAGAR NOTA novamente para confirmar.","info")
                        return
                    end
                    askNoteClear=false
                    m.noteClear()
                    noteField.Text=""
                end}
            })
            ui.section(pages.NOTES,"STATUS DA NOTA")
            local noteStatus=info(pages.NOTES,"",34)
            m.pages.NOTES=function()
                if UIS:GetFocusedTextBox()~=noteField then
                    noteField.Text=v13Data.gameNotes[v15PlaceId] or ""
                end
                noteStatus.Text="JOGO "..v15PlaceId.." | "..#noteField.Text..
                    " / 3000 caracteres salvos localmente"
            end

            -- Bússola: direcao e distancia ate waypoint existente.
            ui.title(pages.COMPASS,"⌖  BUSSOLA DE EXPLORACAO",
                "Direcao e distancia ate seus waypoints salvos")
            info(pages.COMPASS,
                "A bussola so mostra orientacao. Nao teleporta automaticamente.",34)
            local compassLine=ui.section(pages.COMPASS,"BUSSOLA DESLIGADA")
            groupButtons(pages.COMPASS,{
                {"DESLIGAR",function()m.setCompass("off")end},
                {"SALVAR POSICAO",function()show("TELEPORT")end},
                {"REABRIR BUSSOLA",function()
                    m.setCompass(m.compassTarget or "off")
                end}
            })
            ui.section(pages.COMPASS,"WAYPOINTS DISPONIVEIS")
            local points=ui.holder(pages.COMPASS)
            m.pages.COMPASS=function()
                clear(points)
                local names={}
                for name in pairs(extraState.savedWaypoints) do names[#names+1]=name end
                table.sort(names)
                for _,name in ipairs(names) do
                    ui.row(points,"⌖  "..name,{
                        {"APONTAR",function()m.setCompass(name)end,88}
                    })
                end
                compassLine.Text=m.compassEnabled and
                    ("DESTINO: "..tostring(m.compassTarget)) or "BUSSOLA DESLIGADA"
                if #names==0 then info(points,"Salve pelo menos um ponto na aba Teleporte.",39) end
            end
            local compassHUD=round(obj("Frame",gui,{
                Size=UDim2.fromOffset(294,90),
                Position=UDim2.new(0,15,0,86),
                BackgroundColor3=Color3.fromRGB(20,12,23),
                BackgroundTransparency=.09,
                BorderSizePixel=0,
                Visible=m.compassEnabled,ZIndex=87
            }),11)
            obj("UIStroke",compassHUD,{Color=accent,Thickness=1.5,Transparency=.28})
            local hudHeading=txt(compassHUD,"⌖  BRAB0X / BUSSOLA",25,13,true)
            hudHeading.Position=UDim2.fromOffset(11,6)
            hudHeading.Size=UDim2.new(1,-22,0,25)
            hudHeading.TextColor3=accent
            hudHeading.ZIndex=88
            local direction=txt(compassHUD,"↑  Aguarde...",46,16,true)
            direction.Position=UDim2.fromOffset(11,31)
            direction.Size=UDim2.new(1,-22,0,46)
            direction.ZIndex=88
            m.compassWidget=compassHUD
            local arrow={"↑","↗","→","↘","↓","↙","←","↖"}
            m.updateCompass=function()
                if not m.compassEnabled then
                    compassHUD.Visible=false
                    return
                end
                local point=m.compassTarget and extraState.savedWaypoints[m.compassTarget]
                local _,_,root=chars()
                if not point or not root then
                    compassHUD.Visible=true
                    direction.Text="Waypoint ou personagem indisponivel"
                    return
                end
                local delta=point.Position-root.Position
                local distance=math.floor(delta.Magnitude+.5)
                local localDirection=root.CFrame:VectorToObjectSpace(delta)
                local angle=math.deg(math.atan2(localDirection.X,-localDirection.Z))
                local index=math.floor(((angle+22.5)%360)/45)+1
                compassHUD.Visible=true
                direction.Text=arrow[index].."  "..m.compassTarget:upper()..
                    "  •  "..distance.." studs"
            end

            -- Backup de FAVORITOS, NOTAS e MACROS. Limites e whitelist no import.
            ui.title(pages.BACKUP,"▣  BACKUP DE PREFERENCIAS",
                "Exporte e importe notas, favoritos e macros seguras")
            info(pages.BACKUP,
                "Backup em JSON V17. Ele nao contem senhas, executores, codigo remoto nem dados do servidor.",57)
            ui.section(pages.BACKUP,"EXPORTAR")
            local exportField=ui.box(pages.BACKUP,"Clique em GERAR JSON para exportar",127,true)
            exportField.ClearTextOnFocus=false
            groupButtons(pages.BACKUP,{
                {"GERAR JSON",function()
                    exportField.Text=m.backupExport() or ""
                end},
                {"COPIAR JSON",function()copyText(exportField.Text)end}
            })
            ui.section(pages.BACKUP,"IMPORTAR")
            local importField=ui.box(pages.BACKUP,"Cole aqui o backup BRAB0X-V17...",130,true)
            importField.ClearTextOnFocus=false
            local pendingImport=false
            bind(importField:GetPropertyChangedSignal("Text"),function()
                pendingImport=false
            end)
            groupButtons(pages.BACKUP,{
                {"IMPORTAR BACKUP",function()
                    if not pendingImport then
                        pendingImport=true
                        notify("Clique novamente em IMPORTAR para confirmar a mesclagem.","info")
                        return
                    end
                    pendingImport=false
                    m.backupImport(importField.Text)
                end},
                {"LIMPAR CAMPOS",function()
                    importField.Text=""
                    exportField.Text=""
                    pendingImport=false
                end}
            })
            info(pages.BACKUP,
                "A importacao mescla os itens aceitos com os atuais. Os macros sao validados contra comandos locais conhecidos.",49)
            m.pages.BACKUP=function()end

            -- Diagnostico de compatibilidade + historico de jogos.
            ui.title(pages.DIAGNOSTICS,"◎  DIAGNOSTICO DO HUB",
                "Informacoes locais, dados salvos e compatibilidade")
            local diagnosticsInfo=ui.section(pages.DIAGNOSTICS,"DIAGNOSTICO ATIVO")
            groupButtons(pages.DIAGNOSTICS,{
                {"ATUALIZAR TESTES",function()
                    if m.refresh then m.refresh("DIAGNOSTICS")end
                end},
                {"ABRIR BACKUP",function()show("BACKUP")end},
                {"GUIA",function()show("GUIDE")end}
            })
            local details=ui.holder(pages.DIAGNOSTICS)
            m.pages.DIAGNOSTICS=function()
                clear(details)
                local d=m.diagnostic()
                diagnosticsInfo.Text=("VERSAO %s  •  PLACE ID %s"):format(d.version,d.placeId)
                local rows={
                    "GUI: "..(d.gui and "OK" or "FALHA")..
                        "  |  CAMERA: "..(d.camera and "OK" or "INDISPONIVEL"),
                    "PERSONAGEM: "..(d.character and "OK" or "AGUARDANDO")..
                        "  |  JOGADORES: "..d.players,
                    "ARQUIVO LOCAL: "..(d.fileRead and "LEITURA" or "N/A")..
                        " / "..(d.fileWrite and "GRAVACAO" or "N/A"),
                    "CLIPBOARD: "..(d.clipboard and "DISPONIVEL" or "MANUAL"),
                    "COMANDOS: "..d.totalCommands.."  |  WAYPOINTS: "..d.waypoints,
                    "FAVORITOS DO JOGO: "..d.bookmarks.."  |  NOTAS: "..d.notesSize.." caracteres",
                    "SESSOES NESTE JOGO: "..d.sessionCount..
                        "  |  COMANDOS NESTE JOGO: "..d.totalUserCommands
                }
                for _,row in ipairs(rows) do info(details,row,34) end
                ui.section(details,"HISTORICO DE JOGOS")
                local order={}
                for id,entry in pairs(v13Data.gameSessions) do
                    if type(entry)=="table" and tostring(id):match("^%d+$") then
                        order[#order+1]={id=id,entry=entry}
                    end
                end
                table.sort(order,function(a,b)
                    return (tonumber(a.entry.last) or 0)>(tonumber(b.entry.last) or 0)
                end)
                for i=1,math.min(#order,15) do
                    local e=order[i]
                    local profile=v13Data.gameProfiles[e.id]
                    local name=profile and profile.label or ("Jogo "..e.id)
                    info(details,tostring(name).."  |  "..e.id.."  |  "..
                        tostring(e.entry.visits or 0).." visitas",32)
                end
                ui.section(details,"REGISTRO DE FALHAS DESTA SESSAO")
                if #m.sessionErrors==0 then
                    info(details,"Nenhum comando apresentou erro nesta sessao.",34)
                end
                for i=1,math.min(8,#m.sessionErrors) do
                    local issue=m.sessionErrors[i]
                    info(details,issue.time.." / "..issue.command..
                        ": "..issue.message,51)
                end
            end

            -- Guia e presets pre-definidos, sem execucao de codigo externo.
            ui.title(pages.GUIDE,"GUIA COMPLETO DO BRAB0X",
                "Recursos essenciais, atalhos e exemplos para a versao V17")
            local tips={
                {"BUSCA RAPIDA","Ctrl+Shift+P abre a paleta. Escreva nome ou descricao, e escolha um resultado."},
                {"MENU","RightShift abre/fecha. Use a busca na barra lateral e os grupos recolhiveis."},
                {"COMANDOS","Ctrl+K procura na lista de comandos. 'tab games' abre uma aba."},
                {"FAVORITOS DO JOGO","'gamefav fly' marca apenas neste PlaceId. 'gamefavs' mostra a lista."},
                {"NOTAS","'notes' abre suas anotacoes deste jogo. Elas nao aparecem para outros jogadores."},
                {"BUSSOLA","Salve um waypoint na aba Teleporte. Depois digite 'compass nome'."},
                {"BACKUP","'backup' abre a exportacao e importacao segura em JSON."},
                {"CONTROLES","F1 = Ajuda; F2 = Wheel; F6 = Cinema (WASD/E/Q)."},
                {"MACROS","Na aba Macros use comandos locais permitidos separados por ponto e virgula."},
                {"LIMITES","Comandos locais dependem do jogo. O hub nao altera a logica do servidor."}
            }
            for _,entry in ipairs(tips) do
                ui.section(pages.GUIDE,entry[1])
                info(pages.GUIDE,entry[2],39)
            end
            ui.section(pages.GUIDE,"PRESETS DE UM CLIQUE")
            local presetsList=ui.holder(pages.GUIDE)
            for _,name in ipairs({"visual","claro","noite","leve","restaurar","exploracao"}) do
                ui.row(presetsList,name:upper().."  •  "..table.concat(m.presets[name],"; "),{
                    {"USAR",function()m.presetApply(name)end,80}
                })
            end
            groupButtons(pages.GUIDE,{
                {"BUSCAR COMANDOS",function()m.openPalette()end},
                {"CENTRAL DE AJUDA",function()show("HELP")end},
                {"DIAGNOSTICO",function()show("DIAGNOSTICS")end}
            })
            m.pages.GUIDE=function()end

            -- Paleta flutuante com resultados reais do catalogo.
            local overlay=obj("Frame",gui,{
                Size=UDim2.fromScale(1,1),
                BackgroundColor3=Color3.fromRGB(6,3,9),
                BackgroundTransparency=.16,
                BorderSizePixel=0,
                Visible=false,Active=true,ZIndex=95
            })
            local dialog=round(obj("Frame",overlay,{
                AnchorPoint=Vector2.new(.5,0),
                Position=UDim2.new(.5,0,.17,0),
                Size=UDim2.fromOffset(552,461),
                BackgroundColor3=Color3.fromRGB(23,12,24),
                BorderSizePixel=0,ZIndex=96
            }),13)
            obj("UIStroke",dialog,{Color=accent,Thickness=2,Transparency=.12})
            local heading=txt(dialog,"⌕  BRAB0X  /  BUSCA RAPIDA",34,19,true)
            heading.Position=UDim2.fromOffset(15,8)
            heading.Size=UDim2.new(1,-60,0,33)
            heading.TextColor3=accent
            heading.ZIndex=97
            local quit=btn(dialog,"✕",function()m.closePalette()end,30)
            quit.Position=UDim2.new(1,-43,0,9)
            quit.Size=UDim2.fromOffset(32,30)
            quit.ZIndex=99
            local box=round(obj("TextBox",dialog,{
                Position=UDim2.fromOffset(13,49),
                Size=UDim2.new(1,-26,0,40),
                BackgroundColor3=Color3.fromRGB(45,27,39),
                BorderSizePixel=0,
                Text="",PlaceholderText="Busque comandos, nomes, categorias...",
                PlaceholderColor3=muted,TextColor3=white,
                TextSize=14,Font=Enum.Font.Gotham,
                ClearTextOnFocus=false,ZIndex=97
            }),8)
            obj("UIStroke",box,{Color=accent,Transparency=.5,Thickness=1})
            local results=obj("ScrollingFrame",dialog,{
                Position=UDim2.fromOffset(12,100),
                Size=UDim2.new(1,-24,1,-143),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                CanvasSize=UDim2.new(),
                ScrollBarThickness=3,
                ScrollBarImageColor3=accent,
                BackgroundTransparency=1,BorderSizePixel=0,ZIndex=97
            })
            stack(results,5)
            local helpText=txt(dialog,
                "ENTER executa o primeiro resultado  •  ESC fecha a paleta",25,10)
            helpText.Position=UDim2.new(0,14,1,-34)
            helpText.Size=UDim2.new(1,-28,0,26)
            helpText.TextColor3=muted
            helpText.ZIndex=97
            m.paletteOverlay=overlay
            m.paletteInput=box
            local best=nil
            local function paletteSearch()
                clear(results)
                best=nil
                local query=trim(box.Text):lower()
                local matches={}
                for _,entry in ipairs(registered) do
                    if moduleEnabled(entry.category) then
                        local blob=(entry.name.." "..entry.category.." "..entry.description):lower()
                        local score=entry.name==query and 0 or
                            entry.name:sub(1,#query)==query and 1 or
                            blob:find(query,1,true) and 2 or nil
                        if query=="" then
                            if m.favorites[entry.name] or v13Data.favorites[entry.name] then
                                score=0
                            else score=3 end
                        end
                        if score then matches[#matches+1]={entry=entry,score=score} end
                    end
                end
                table.sort(matches,function(a,b)
                    if a.score~=b.score then return a.score<b.score end
                    return a.entry.name<b.entry.name
                end)
                for i=1,math.min(#matches,30) do
                    local entry=matches[i].entry
                    if not best then best=entry end
                    local label=entry.name:upper().."  •  "..entry.category..
                        "\n"..entry.description
                    local result=btn(results,label,function()
                        m.closePalette()
                        exec(entry.example)
                    end,48)
                    result.Size=UDim2.new(1,-9,0,48)
                    result.TextWrapped=true
                    result.TextXAlignment=Enum.TextXAlignment.Left
                    result.TextSize=11
                    result.ZIndex=98
                end
                if #matches==0 then
                    local none=info(results,"Nenhum comando encontrado.",35)
                    none.ZIndex=98
                end
            end
            m.paletteSearch=paletteSearch
            bind(box:GetPropertyChangedSignal("Text"),paletteSearch)
            m.closePalette=function()
                overlay.Visible=false
                m.isOpen=false
                box:ReleaseFocus()
            end
            m.openPalette=function()
                if stopped then return end
                m.isOpen=true
                overlay.Visible=true
                box.Text=""
                paletteSearch()
                box:CaptureFocus()
            end
            m.onInput=function(input,used)
                local key=input.KeyCode
                if m.isOpen then
                    if key==Enum.KeyCode.Escape then
                        m.closePalette()
                        return true
                    end
                    if key==Enum.KeyCode.Return or key==Enum.KeyCode.KeypadEnter then
                        local entry=best
                        m.closePalette()
                        if entry then exec(entry.example) end
                        return true
                    end
                end
                if key==Enum.KeyCode.P and not used and
                    (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or
                        UIS:IsKeyDown(Enum.KeyCode.RightControl)) and
                    (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or
                        UIS:IsKeyDown(Enum.KeyCode.RightShift)) then
                    if m.isOpen then m.closePalette() else m.openPalette() end
                    return true
                end
                return false
            end
            m.refresh=function(page)
                if m.pages[page] and pages[page] and pages[page].Visible then
                    local ok,err=pcall(m.pages[page])
                    if not ok then warn("[BRAB0X V17] Falha em "..page..": "..tostring(err)) end
                end
            end
            m.renderConnection=Run.Heartbeat:Connect(function()
                if stopped or not gui.Parent then return end
                local now=os.clock()
                if now-m.compassUpdated<.32 then return end
                m.compassUpdated=now
                if m.compassEnabled then m.updateCompass() end
            end)
            local oldCleanup=v14.cleanup
            v14.cleanup=function()
                if m.renderConnection then
                    m.renderConnection:Disconnect()
                    m.renderConnection=nil
                end
                if oldCleanup then oldCleanup() end
            end
        end
    end
end

-- ABA CONFIGURACOES

do
-- Personalizacao premium, teclas e atalhos.
local advancedTitle=titleRow(pages.SETTINGS,"✦  PERSONALIZACAO PREMIUM")
toggleControl(pages.SETTINGS,"ANIMACOES DA INTERFACE","Transicoes suaves entre paginas",
    function()return config.animations end,"animations on","animations off")
toggleControl(pages.SETTINGS,"MODO COMPACTO","Painel menor sem perder comandos",
    function()return config.compact end,"compact","compact")
sliderControl(pages.SETTINGS,"TRANSPARENCIA","Transparencia do fundo do hub",
    0,.45,.05,function()return config.opacity end,"opacity","%.2f")
sliderControl(pages.SETTINGS,"INTENSIDADE DO NEON","Bordas vermelhas ajustaveis",
    .25,2,.05,function()return config.neon end,"neon","%.2f")
actionRow(pages.SETTINGS,{
    {"PERFIS",function()show("PROFILES")end},
    {"DESEMPENHO",function()show("PERFORMANCE")end},
    {"FAVORITOS",function()show("FAVORITES")end}
})
titleRow(pages.SETTINGS,"✦  NOTIFICACOES")
toggleControl(pages.SETTINGS,"AVISOS PREMIUM","Mostra mensagens animadas ao usar comandos",
    function()return config.notifications end,"notifications on","notifications off")
actionRow(pages.SETTINGS,{
    {"ABRIR CENTRAL DE AJUDA",function()show("HELP")end},
    {"TESTAR NOTIFICACAO",function()exec("notifytest")end}
})
titleRow(pages.SETTINGS,"⌨  KEYBINDS PERSONALIZADOS")
local keyButtons={}
local captureAction=nil
local actions={
    {"FLY","Voar"},{"MENU","Abrir menu"},{"NOCLIP","Noclip"},
    {"BOOST","Boost"},{"INVIS","Invisibilidade local"}
}
for _,entry in ipairs(actions) do
    local name=entry[1]
    local row=round(obj("Frame",pages.SETTINGS,{
        Size=UDim2.new(1,-8,0,50),
        BackgroundColor3=control,BorderSizePixel=0
    }),8)
    local label=txt(row,entry[2],27,13,true)
    label.Position=UDim2.fromOffset(14,11)
    label.Size=UDim2.new(1,-230,0,27)
    local keyButton=btn(row,v13Data.keybinds[name],function()
        captureAction=name
        keyButtons[name].Text="PRESSIONE..."
        notify("Pressione uma tecla para "..name.." (Esc cancela)")
    end,34)
    keyButton.Position=UDim2.new(1,-190,0,8)
    keyButton.Size=UDim2.fromOffset(175,34)
    keyButtons[name]=keyButton
end
local function updateKeyLabels()
    for name,b in pairs(keyButtons) do
        if b.Parent then b.Text="⌨  "..(v13Data.keybinds[name] or "SEM TECLA") end
    end
end
keyCaptureHandler=function(input)
    if not captureAction then return false end
    if input.UserInputType~=Enum.UserInputType.Keyboard then return false end
    local action=captureAction
    captureAction=nil
    if input.KeyCode==Enum.KeyCode.Escape then
        updateKeyLabels()
        notify("Alteracao de tecla cancelada")
        return true
    end
    local key=input.KeyCode.Name
    if input.KeyCode==Enum.KeyCode.Backspace then
        key=defaultKeys[action]
    end
    if input.KeyCode==Enum.KeyCode.Unknown then return true end
    for other,bound in pairs(v13Data.keybinds) do
        if other~=action and bound==key then
            notify("Tecla "..key.." ja usada por "..other)
            updateKeyLabels()
            return true
        end
    end
    v13Data.keybinds[action]=key
    saveV13()
    updateKeyLabels()
    notify("Tecla "..key.." configurada para "..action)
    return true
end
actionRow(pages.SETTINGS,{
    {"RESTAURAR TECLAS",function()exec("resetkeys") updateKeyLabels()end},
    {"COMANDOS",function()show("COMMANDS")end}
})
applyV13Appearance=function()
    accent=palette[config.theme] or palette.red
    main.BackgroundTransparency=config.opacity
    right.BackgroundTransparency=math.clamp(config.opacity*.55,0,.4)
    sidebar.BackgroundTransparency=math.clamp(config.opacity*.55,0,.4)
    stroke.Color=accent
    stroke.Thickness=1.9*config.neon
    stroke.Transparency=math.clamp(.18/config.neon,0,.65)
    topState.TextColor3=accent
    fpsLabel.TextColor3=accent
    crosshair.TextColor3=accent
    for _,frame in pairs(pages) do
        frame.ScrollBarImageColor3=accent
    end
    for _,node in ipairs(gui:GetDescendants()) do
        if node:IsA("UIStroke") and node~=stroke then
            if node:GetAttribute("V13BaseTransparency")==nil then
                node:SetAttribute("V13BaseTransparency",node.Transparency)
            end
            local base=node:GetAttribute("V13BaseTransparency") or .5
            node.Color=accent
            node.Transparency=math.clamp(1-(1-base)*config.neon,0,.98)
        end
    end
    responsive()
end

end -- fim do escopo visual / teclas
titleRow(pages.SETTINGS,"CREDITOS DO PROJETO")
btn(pages.SETTINGS,"✦  CRIADO POR @wendezao05153nh",function()
    exec("creator")
end,43)
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

    if v14.cleanup then pcall(v14.cleanup) end
    saveV13()
    resetAll()
    stopped = true

    Run:UnbindFromRenderStep(aimKey)

    for _,c in ipairs(connections) do
        c:Disconnect()
    end

    gui:Destroy()

    if _G.BRAB0X_V17_1_STOP == closeHub then
        _G.BRAB0X_V17_1_STOP = nil
    end
end

bind(close.MouseButton1Click,closeHub)

-- ATALHOS

bind(UIS.InputBegan,function(key,used)
    if keyCaptureHandler and keyCaptureHandler(key) then return end
    if v14.onInput and v14.onInput(key,used) then return end
    if UIS:GetFocusedTextBox() then return end
    local name=key.KeyCode.Name
    if name=="F1" and not used then
        main.Visible=true
        reopen.Visible=false
        show("HELP")
    elseif name=="K" and (UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
        main.Visible=true
        reopen.Visible=false
        show("COMMANDS")
        search:CaptureFocus()
    elseif name==v13Data.keybinds.MENU then
        main.Visible=not main.Visible
        reopen.Visible=not main.Visible
    elseif not used then
        if name==v13Data.keybinds.FLY then exec("toggle")
        elseif name==v13Data.keybinds.NOCLIP then
            exec(S.noclip and "clip" or "noclip")
        elseif name==v13Data.keybinds.BOOST then
            exec(S.boost and "unboost" or "boost")
        elseif name==v13Data.keybinds.INVIS then
            exec(S.invisible and "visible" or "invisible")
        end
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

_G.BRAB0X_V17_1_STOP = closeHub

-- ABERTURA ANIMADA
do

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
    splash,"CRIADO POR @wendezao05153nh",25,12
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
    saveV13()
    gate.Visible = false
    main.Visible = true
    reopen.Visible = false
    show("HOME")
    if refreshCommandList then refreshCommandList() end
    if refresh then refresh() end
    notify("BRAB0X V17.1 pronto! AIM: "..(selectedAim and "ATIVO" or "OCULTO"))
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

end -- fim do escopo abertura
-- INICIALIZAR

rebuildEmotes()
relabel()
if v14.install then v14.install() end
if applyV13Appearance then applyV13Appearance() end
show("HOME")
refresh()

if refreshCommandList then
    refreshCommandList()
end

notify(
    "BRAB0X PRIME V17.1 | "
    ..#registered.." comandos | PlaceId "..v15PlaceId
)
