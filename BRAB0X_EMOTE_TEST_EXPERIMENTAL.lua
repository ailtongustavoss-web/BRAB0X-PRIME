-- BRAB0X PRIME - TESTE DE EMOTES NO LOCALPLAYER V3
-- Nao modifica o hub principal nem altera o avatar no servidor.
-- Busca emotes de catalogo e tenta a API oficial no boneco de previa.
-- Resultados no painel e no console F9.

local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")
local player = Players.LocalPlayer
if not player then return end

if type(_G.BRAB0X_EMOTE_TEST_STOP) == "function" then
    pcall(_G.BRAB0X_EMOTE_TEST_STOP)
end

local gui = Instance.new("ScreenGui")
gui.Name = "BRAB0X_EMOTE_TEST_ISOLADO"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(1, .5)
root.Position = UDim2.new(1, -14, .5, 0)
root.Size = UDim2.fromOffset(340, 565)
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

local title = label(root, "BRAB0X | TESTE NO PERSONAGEM", 32)
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

local status = label(root, "Selecione o emote: ele toca no seu personagem do jogo.", 128)
status.Position = UDim2.fromOffset(12, 246)
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(224, 211, 215)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(11, 380)
scroll.Size = UDim2.new(1, -22, 0, 173)
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
local testMessages = {}

local function log(msg)
    if closed then return end
    local message = tostring(msg)
    print("[BRAB0X EMOTE TEST] " .. message)
    testMessages[#testMessages + 1] = message
    while #testMessages > 7 do table.remove(testMessages, 1) end
    status.Text = table.concat(testMessages, "\n")
end

local function beginTest()
    testMessages = {}
    status.Text = ""
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
local activeRestore=nil

local function testId(id,name)
    if busy or closed then return end
    busy=true
    beginTest()
    log("TESTE LOCAL: "..name.." | ID "..tostring(id))
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

        local gotOriginal,original=pcall(function()
            return humanoid:GetAppliedDescription()
        end)
        if not gotOriginal or not original then
            log("Nao foi possivel salvar seu avatar: "..shortError(original))
            busy=false
            return
        end
        local temporary=original:Clone()
        local testName="BRAB0X_TESTE_TEMPORARIO"
        local created,creationError=pcall(function()
            temporary:AddEmote(testName,id)
            temporary:SetEquippedEmotes({testName})
        end)
        if not created then
            log("Registro recusado: "..shortError(creationError))
            temporary:Destroy()
            original:Destroy()
            busy=false
            return
        end
        log("Emote registrado na descricao temporaria.")
        local applying=true
        local restored=false
        local function restore()
            if restored then return end
            restored=true
            while applying do task.wait(.1) end
            if humanoid.Parent and character==player.Character then
                local ok,err=pcall(function()
                    humanoid:ApplyDescriptionAsync(original)
                end)
                if not closed then
                    log(ok and "Avatar original restaurado." or
                        "Restauracao falhou: "..shortError(err))
                end
            end
            original:Destroy()
            temporary:Destroy()
            if activeRestore==restore then activeRestore=nil end
        end
        activeRestore=restore

        -- Modificacao temporaria apenas neste personagem, revertida depois.
        local applied,applyErr=pcall(function()
            humanoid:ApplyDescriptionAsync(temporary)
        end)
        applying=false
        if not applied then
            log("ApplyDescriptionAsync ERRO: "..shortError(applyErr))
            restore()
            busy=false
            return
        end
        if closed then restore() busy=false return end
        log("Descricao temporaria aplicada ao LocalPlayer.")

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

task.spawn(function()
    local ok, pages = pcall(function()
        local params = CatalogSearchParams.new()
        params.SearchKeyword = "Jamal"
        params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
        params.Limit = 30
        return AvatarEditorService:SearchCatalogAsync(params)
    end)
    if not ok or not pages then
        log("Busca do catalogo bloqueada: " .. tostring(pages))
        -- Controle para testar um emote de exemplo da documentacao Roblox.
        addResult(3360689775, "Salute (controle)")
        return
    end
    local okay, results = pcall(function() return pages:GetCurrentPage() end)
    if not okay or type(results) ~= "table" then
        log("Nao consegui ler resultados: " .. tostring(results))
        return
    end
    local count = 0
    for _,item in ipairs(results) do
        local id = tonumber(item.Id)
        if id then
            count += 1
            addResult(id, tostring(item.Name or "Emote"))
        end
    end
    addResult(3360689775, "Salute (controle oficial)")
    log(tostring(count) .. " Jamals encontrados.")
    log("Teste SALUTE primeiro; o teste usa o avatar dentro do jogo.")
    log("A aparencia do personagem sera restaurada apos cada teste.")
end)
