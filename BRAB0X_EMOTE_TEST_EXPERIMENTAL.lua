-- BRAB0X PRIME - TESTE DE EMOTES V6 | BUSCA EM TODO O CATALOGO
-- Nao modifica o hub principal nem altera o avatar no servidor.
-- Busca emotes de catalogo e tenta a API oficial no boneco de previa.
-- Resultados no painel e no console F9.

local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local player = Players.LocalPlayer
if not player then return end

local BUILD_ID="BRAB0X_EMOTE_V6_BUSCA_GERAL"
if type(_G.BRAB0X_EMOTE_TEST_STOP) == "function" then
    pcall(_G.BRAB0X_EMOTE_TEST_STOP)
end

local playerGui=player:WaitForChild("PlayerGui")
-- Limpa paineis antigos, inclusive se o executor isolar _G entre scripts.
for _,existing in ipairs(playerGui:GetChildren()) do
    if existing.Name=="BRAB0X_EMOTE_TEST_ISOLADO"
        or existing.Name=="BRAB0X_EMOTE_TEST_V5"
        or existing.Name=="BRAB0X_EMOTE_TEST_V6" then
        existing:Destroy()
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "BRAB0X_EMOTE_TEST_V6"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = playerGui

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(1, .5)
root.Position = UDim2.new(1, -14, .5, 0)
root.Size = UDim2.fromOffset(354, 623)
root.BackgroundColor3 = Color3.fromRGB(17, 16, 22)
root.BorderSizePixel = 0
root.Parent = gui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 12)

local function label(parent, content, height)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Size = UDim2.new(1, -16, 0, height)
    item.Font = Enum.Font.Gotham
    item.TextSize = 12
    item.TextColor3 = Color3.fromRGB(240, 226, 232)
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextWrapped = true
    item.Text = content
    item.Parent = parent
    return item
end

local title = label(root, "BRAB0X | TODOS OS EMOTES V6", 32)
title.Position = UDim2.fromOffset(10, 7)
title.Font = Enum.Font.GothamBold

local close = Instance.new("TextButton")
close.Text = "X"
close.Size = UDim2.fromOffset(28, 26)
close.Position = UDim2.new(1, -33, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(106, 24, 43)
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = root
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local viewport = Instance.new("ViewportFrame")
viewport.Name = "Preview3D"
viewport.Position = UDim2.fromOffset(11, 46)
viewport.Size = UDim2.new(1, -22, 0, 190)
viewport.BackgroundColor3 = Color3.fromRGB(30, 28, 36)
viewport.LightColor = Color3.fromRGB(255, 255, 255)
viewport.Ambient = Color3.fromRGB(200, 200, 200)
viewport.Parent = root
Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 8)

local avatarHint = Instance.new("TextLabel")
avatarHint.Name = "TesteNoSeuAvatar"
avatarHint.BackgroundTransparency = 1
avatarHint.Size = UDim2.new(1, -30, 0, 72)
avatarHint.AnchorPoint = Vector2.new(.5, .5)
avatarHint.Position = UDim2.fromScale(.5, .5)
avatarHint.Font = Enum.Font.GothamBold
avatarHint.TextSize = 14
avatarHint.TextWrapped = true
avatarHint.TextColor3 = Color3.fromRGB(255, 228, 235)
avatarHint.Text = "TESTE V6\nBUSQUE QUALQUER EMOTE\nDANCA NO SEU AVATAR"
avatarHint.Parent = viewport

local status = label(root, "V6: pesquisa em todo o catalogo.\nEscolha uma danca abaixo.", 112)
status.Position = UDim2.fromOffset(12, 246)
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(224, 211, 215)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(11, 411)
scroll.Size = UDim2.new(1, -22, 0, 162)
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BackgroundColor3 = Color3.fromRGB(27, 23, 32)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.Parent = root
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 7)
local stack = Instance.new("UIListLayout")
stack.Padding = UDim.new(0, 4)
stack.Parent = scroll

local currentWorld
local busy = false
local closed = false
local activeRestore = nil
local testMessages = {"VERSAO V6 | BUSCA GERAL | "..BUILD_ID}

local function log(msg)
    if closed then return end
    local message = tostring(msg)
    print("[BRAB0X EMOTE TEST] " .. message)
    testMessages[#testMessages + 1] = message
    while #testMessages > 7 do table.remove(testMessages, 1) end
    status.Text = table.concat(testMessages, "\n")
end

local function beginTest()
    testMessages = {"VERSAO V6 | EMOTES DO CATALOGO"}
    status.Text = testMessages[1]
end

local function shortError(value)
    local message = tostring(value)
    message = message:gsub("^.*:%d+:%s*", "")
    return message:sub(1, 220)
end

local copy = Instance.new("TextButton")
copy.Text = "COPIAR LOG"
copy.Size = UDim2.fromOffset(79, 24)
copy.Position = UDim2.new(1, -119, 0, 10)
copy.BackgroundColor3 = Color3.fromRGB(68, 24, 40)
copy.TextColor3 = Color3.fromRGB(255, 235, 239)
copy.Font = Enum.Font.Gotham
copy.TextSize = 10
copy.Parent = root
Instance.new("UICorner", copy).CornerRadius = UDim.new(0, 5)
copy.MouseButton1Click:Connect(function()
    local message = table.concat(testMessages, "\n")
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, message)
        if ok then log("Log copiado.") return end
    end
    print("[BRAB0X EMOTE TEST] Copie estas linhas: " .. message)
    log("Nao foi possivel copiar; veja o painel ou F9.")
end)

local function clearPreview()
    if currentWorld then
        currentWorld:Destroy()
        currentWorld = nil
    end
    viewport.CurrentCamera = nil
    for _,child in ipairs(viewport:GetChildren()) do
        if child:IsA("Camera") then child:Destroy() end
    end
end

local function stop()
    if closed then return end
    closed = true
    clearPreview()
    gui:Destroy()
    if activeRestore then task.spawn(activeRestore) end
    if _G.BRAB0X_EMOTE_TEST_STOP == stop then
        _G.BRAB0X_EMOTE_TEST_STOP = nil
    end
end
_G.BRAB0X_EMOTE_TEST_STOP = stop
close.MouseButton1Click:Connect(stop)

-- Testa no Humanoid do LocalPlayer, pois PlayEmoteAsync rejeita
-- Humanoids de bonecos de preview, mesmo com descricao aplicada.
local function testId(id,name)
    if busy or closed then return end
    busy=true
    beginTest()
    log("TESTE LOCAL V6: "..name.." | ID "..tostring(id))
    log("A danca sera testada no SEU personagem, nao no boneco da janela.")

    task.spawn(function()
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health<=0 then
            log("Avatar local indisponivel. Entre no jogo e tente de novo.")
            busy=false
            return
        end
        if humanoid.RigType~=Enum.HumanoidRigType.R15 then
            log("Rig atual: "..humanoid.RigType.Name..
                ". Emotes modernos normalmente exigem R15.")
            busy=false
            return
        end
        local animator=humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            log("Seu Humanoid nao tem Animator.")
            busy=false
            return
        end

        -- Metodo documentado para LocalScript: mudar somente a lista
        -- de emotes do HumanoidDescription local, sem ApplyDescriptionAsync.
        local description=humanoid:FindFirstChildOfClass("HumanoidDescription")
        if not description then
            log("Sem HumanoidDescription no avatar atual.")
            log("Esse jogo nao expos a lista local necessaria para o teste.")
            busy=false
            return
        end

        local okEmotes,allEmotes=pcall(function()
            return description:GetEmotes()
        end)
        local okEquipped,equipped=pcall(function()
            return description:GetEquippedEmotes()
        end)
        if not okEmotes or not okEquipped or type(allEmotes)~="table"
            or type(equipped)~="table" then
            log("Nao foi possivel ler a lista de emotes locais.")
            busy=false
            return
        end
        -- Copias independentes para garantir restauracao da lista.
        local originalEmotes={}
        local testEmotes={}
        for key,ids in pairs(allEmotes) do
            if type(ids)=="table" then
                local copy={}
                for i,value in ipairs(ids) do copy[i]=value end
                originalEmotes[key]=copy
                local updated={}
                for i,value in ipairs(ids) do updated[i]=value end
                testEmotes[key]=updated
            end
        end
        local originalEquipped={}
        for i,entry in ipairs(equipped) do
            if type(entry)=="table" then
                local copied={}
                for k,v in pairs(entry) do copied[k]=v end
                originalEquipped[i]=copied
            else
                originalEquipped[i]=entry
            end
        end

        local testName="BRAB0X_TESTE_TEMPORARIO"
        testEmotes[testName]={id}
        local restored=false
        local function restore()
            if restored then return end
            restored=true
            if description.Parent and player.Character==character then
                local okA,errA=pcall(function()
                    description:SetEmotes(originalEmotes)
                end)
                local okB,errB=pcall(function()
                    description:SetEquippedEmotes(originalEquipped)
                end)
                if not closed then
                    if okA and okB then
                        log("Emotes anteriores restaurados.")
                    else
                        log("Falha ao restaurar: "..
                            shortError((not okA and errA) or errB))
                    end
                end
            end
            if activeRestore==restore then activeRestore=nil end
        end
        activeRestore=restore

        local setupOk,setupErr=pcall(function()
            description:SetEmotes(testEmotes)
            description:SetEquippedEmotes({testName})
        end)
        if not setupOk then
            log("SetEmotes/SetEquippedEmotes ERRO: "..shortError(setupErr))
            restore()
            busy=false
            return
        end
        if closed then restore() busy=false return end
        log("Lista local de emotes alterada temporariamente.")
        local checked,now=pcall(function()
            return description:GetEmotes()
        end)
        log("Emote registrado no avatar: "..
            tostring(checked and type(now)=="table" and
                type(now[testName])=="table"))
        local previous={}
        for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
            previous[track]=true
        end

        local played,playResult=pcall(function()
            return humanoid:PlayEmoteAsync(testName)
        end)
        if played then
            log("PlayEmoteAsync: "..tostring(playResult))
        else
            log("PlayEmoteAsync ERRO: "..shortError(playResult))
        end

        local fallbackOk,fallbackResult=false,nil
        if not played or playResult~=true then
            fallbackOk,fallbackResult=pcall(function()
                return humanoid:PlayEmote(testName)
            end)
            if fallbackOk then
                log("PlayEmote: "..tostring(fallbackResult))
            else
                log("PlayEmote ERRO: "..shortError(fallbackResult))
            end
        end

        local freshTracks={}
        for _,delay in ipairs({.35,.6,.9}) do
            task.wait(delay)
            if closed or not humanoid.Parent or character~=player.Character then
                break
            end
            for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
                local ok,valid=pcall(function()
                    return not previous[track] and track.IsPlaying and track.Length>0
                end)
                if ok and valid then freshTracks[track]=true end
            end
            if next(freshTracks) then break end
        end
        local count=0
        for _ in pairs(freshTracks) do count+=1 end
        if not closed then
            log("Novas tracks carregadas: "..count)
            if count>0 then
                log("RESULTADO: emote tocou no SEU personagem.")
            elseif played and playResult==true then
                log("API aceitou, mas nenhum movimento novo foi confirmado.")
            else
                log("RESULTADO: emote nao reproduzido neste jogo.")
            end
        end

        -- Alguns emotes sao curtos; deixe a animacao terminar antes de restaurar.
        if count>0 and not closed then task.wait(2.5) end
        for track in pairs(freshTracks) do
            pcall(function() track:Stop(.1) end)
        end
        restore()
        busy=false
    end)
end

local function makeButton(text,parent)
    local button=Instance.new("TextButton")
    button.BackgroundColor3=Color3.fromRGB(84,25,42)
    button.BorderSizePixel=0
    button.TextColor3=Color3.fromRGB(255,238,242)
    button.Font=Enum.Font.GothamBold
    button.TextSize=11
    button.Text=text
    button.Parent=parent
    Instance.new("UICorner",button).CornerRadius=UDim.new(0,6)
    return button
end

local searchInput=Instance.new("TextBox")
searchInput.Name="PesquisarQualquerEmote"
searchInput.Position=UDim2.fromOffset(11,365)
searchInput.Size=UDim2.new(1,-119,0,37)
searchInput.BackgroundColor3=Color3.fromRGB(38,31,43)
searchInput.BorderSizePixel=0
searchInput.Text=""
searchInput.PlaceholderText="Todos os emotes • ou digite nome"
searchInput.PlaceholderColor3=Color3.fromRGB(180,160,171)
searchInput.TextColor3=Color3.new(1,1,1)
searchInput.ClearTextOnFocus=false
searchInput.Font=Enum.Font.Gotham
searchInput.TextSize=12
searchInput.Parent=root
Instance.new("UICorner",searchInput).CornerRadius=UDim.new(0,6)

local searchButton=makeButton("PESQUISAR",root)
searchButton.Position=UDim2.new(1,-101,0,365)
searchButton.Size=UDim2.fromOffset(90,37)

local moreButton=makeButton("CARREGAR MAIS RESULTADOS",root)
moreButton.Position=UDim2.fromOffset(11,580)
moreButton.Size=UDim2.new(1,-22,0,32)

local catalogPages
local catalogBusy=false
local catalogSearchToken=0
local shownIds={}
local foundCount=0

local function clearResults()
    for _,child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    shownIds={}
    foundCount=0
end

local function addResult(id, name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 31)
    b.BackgroundColor3 = Color3.fromRGB(56, 21, 32)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(255, 237, 240)
    b.Text = (name .. "  [" .. tostring(id) .. "]"):sub(1, 70)
    b.Parent = scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() testId(id, name) end)
end

local function appendPage(items)
    local appended=0
    for _,item in ipairs(items) do
        local id=tonumber(item.Id)
        if id and not shownIds[id] then
            shownIds[id]=true
            appended+=1
            foundCount+=1
            addResult(id,tostring(item.Name or ("Emote "..id)))
        end
    end
    moreButton.Text=catalogPages and not catalogPages.IsFinished
        and ("CARREGAR MAIS RESULTADOS ("..foundCount..")")
        or ("FIM DOS RESULTADOS ("..foundCount..")")
    moreButton.Active=catalogPages and not catalogPages.IsFinished or false
    moreButton.AutoButtonColor=moreButton.Active
    moreButton.BackgroundColor3=moreButton.Active
        and Color3.fromRGB(84,25,42) or Color3.fromRGB(50,38,47)
    return appended
end

local function searchEmotes()
    if catalogBusy or closed then return end
    catalogSearchToken+=1
    local token=catalogSearchToken
    local keyword=searchInput.Text:gsub("^%s+",""):gsub("%s+$","")
    catalogBusy=true
    catalogPages=nil
    clearResults()
    -- Mantem um emote de referencia acessivel para comparar com os resultados.
    shownIds[3360689775]=true
    foundCount=1
    addResult(3360689775,"Salute (controle oficial)")
    moreButton.Text="CONSULTANDO CATALOGO..."
    searchButton.Text="..."
    log(keyword=="" and "Buscando TODOS os emotes disponiveis..."
        or "Buscando emotes: "..keyword)
    task.spawn(function()
        local ok,pages=pcall(function()
            local params=CatalogSearchParams.new()
            params.SearchKeyword=keyword
            params.AssetTypes={Enum.AvatarAssetType.EmoteAnimation}
            params.Limit=30
            return AvatarEditorService:SearchCatalogAsync(params)
        end)
        if closed or token~=catalogSearchToken then
            catalogBusy=false
            return
        end
        if not ok or not pages then
            log("Erro ao pesquisar o catalogo: "..shortError(pages))
            log("Se a busca vazia for bloqueada, digite parte do nome do emote.")
            moreButton.Text="BUSCA INDISPONIVEL"
        else
            catalogPages=pages
            local read,results=pcall(function()
                return pages:GetCurrentPage()
            end)
            if read and type(results)=="table" then
                local quantity=appendPage(results)
                log("Exibindo "..quantity.." emotes. Use CARREGAR MAIS.")
            else
                log("Nao foi possivel ler a pagina: "..shortError(results))
            end
        end
        searchButton.Text="PESQUISAR"
        catalogBusy=false
    end)
end

searchButton.MouseButton1Click:Connect(searchEmotes)
searchInput.FocusLost:Connect(function(enter)
    if enter then searchEmotes() end
end)
moreButton.MouseButton1Click:Connect(function()
    if catalogBusy or not catalogPages or catalogPages.IsFinished then return end
    catalogBusy=true
    moreButton.Text="CARREGANDO..."
    local pages=catalogPages
    task.spawn(function()
        local ok,err=pcall(function()
            pages:AdvanceToNextPageAsync()
        end)
        if not closed then
            if ok and pages==catalogPages then
                local read,items=pcall(function()return pages:GetCurrentPage()end)
                if read and type(items)=="table" then
                    log("Mais "..appendPage(items).." emotes carregados.")
                else
                    log("Falha na pagina: "..shortError(items))
                end
            elseif not ok then
                log("Falha ao avancar pagina: "..shortError(err))
            end
        end
        catalogBusy=false
    end)
end)

-- Salute continua como controle, mas nao limita a busca.
addResult(3360689775,"Salute (controle oficial)")
task.defer(searchEmotes)
