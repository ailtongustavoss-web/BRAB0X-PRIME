-- BRAB0X PRIME - TESTE ISOLADO DE EMOTES ORIGINAIS V2 (DIAGNOSTICO VISIVEL)
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

local title = label(root, "BRAB0X  |  TESTE JAMAL ORIGINAL", 32)
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

local status = label(root, "Buscando emotes Jamal no catalogo...", 128)
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
    if _G.BRAB0X_EMOTE_TEST_STOP == stop then
        _G.BRAB0X_EMOTE_TEST_STOP = nil
    end
end
_G.BRAB0X_EMOTE_TEST_STOP = stop
close.MouseButton1Click:Connect(stop)

local function testId(id, name)
    if busy or closed then return end
    busy = true
    beginTest()
    clearPreview()
    log("TESTE: " .. name .. " | ID " .. tostring(id))

    task.spawn(function()
        local emoteName = "BRAB0X_TEST_JAMAL"
        local okDesc, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
        end)
        if not okDesc or not desc then
            log("Nao foi possivel obter seu avatar: " .. tostring(desc))
            busy = false
            return
        end

        local okSetup, setupErr = pcall(function()
            -- O numero do catalogo representa um EMOTE, nao
            -- necessariamente o AnimationId interno.
            desc:AddEmote(emoteName, id)
            desc:SetEquippedEmotes({emoteName})
        end)
        if not okSetup then
            desc:Destroy()
            log("Falha no cadastro do emote: " .. tostring(setupErr))
            busy = false
            return
        end

        local configured, registered = pcall(function()
            local e = desc:GetEmotes()
            return e[emoteName]
        end)
        log("Descricao: "..(configured and type(registered)=="table"
            and "emote registrado" or "emote NAO registrado"))
        local okModel, model = pcall(function()
            return Players:CreateHumanoidModelFromDescriptionAsync(
                desc, Enum.HumanoidRigType.R15)
        end)
        if not okModel or not model then
            desc:Destroy()
            log("Falha ao criar a previa: " .. tostring(model))
            busy = false
            return
        end
        if closed then model:Destroy() desc:Destroy() busy = false return end

        local world = Instance.new("WorldModel")
        world.Parent = viewport
        currentWorld = world
        for _,object in ipairs(model:GetDescendants()) do
            if object:IsA("LuaSourceContainer") then object:Destroy() end
            if object:IsA("BasePart") then
                object.CanCollide = false
                object.CanTouch = false
            end
        end
        model.Parent = world
        model:PivotTo(CFrame.new())
        local rootPart = model:FindFirstChild("HumanoidRootPart")
        if rootPart then rootPart.Anchored = true end

        local camera = Instance.new("Camera")
        camera.FieldOfView = 35
        camera.CFrame = CFrame.lookAt(Vector3.new(0, 2.1, -8.5), Vector3.new(0, 1.5, 0))
        camera.Parent = viewport
        viewport.CurrentCamera = camera

        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            desc:Destroy()
            log("Erro: o modelo nao tem Humanoid.")
            busy = false
            return
        end

        local appliedOk, appliedDesc = pcall(function()
            return humanoid:GetAppliedDescription()
        end)
        local appliedName
        if appliedOk and appliedDesc then
            local ok, owned = pcall(function() return appliedDesc:GetEmotes() end)
            if ok and type(owned) == "table" then
                appliedName = owned[emoteName]
            end
            appliedDesc:Destroy()
        end

        log("Avatar R15: "..(appliedName and "emote aplicado" or "emote nao aplicado"))
        if not appliedName then
            local okApply, applyErr = pcall(function()
                humanoid:ApplyDescriptionAsync(desc)
            end)
            log(okApply and "Descricao aplicada novamente." or
                "ApplyDescription: "..shortError(applyErr))
        end
        desc:Destroy()

        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
            log("Animator criado na previa.")
        end

        local playedOk, playedResult = pcall(function()
            return humanoid:PlayEmoteAsync(emoteName)
        end)
        if playedOk then
            log("PlayEmoteAsync retornou "..tostring(playedResult))
        else
            log("PlayEmoteAsync ERRO: "..shortError(playedResult))
        end

        local fallbackOk, fallbackValue = false, nil
        if not playedOk or playedResult ~= true then
            fallbackOk, fallbackValue = pcall(function()
                return humanoid:PlayEmote(emoteName)
            end)
            if fallbackOk then
                log("PlayEmote retornou "..tostring(fallbackValue))
            else
                log("PlayEmote ERRO: "..shortError(fallbackValue))
            end
        end

        local trackCount, loadedCount = 0, 0
        -- Algumas animacoes demoram para transmitir dados ao WorldModel.
        for _, delay in ipairs({.45, .9, 1.2}) do
            task.wait(delay)
            if closed or currentWorld ~= world then
                busy = false
                return
            end
            local ok, tracks = pcall(function()
                return animator:GetPlayingAnimationTracks()
            end)
            trackCount, loadedCount = 0, 0
            if ok and type(tracks) == "table" then
                trackCount = #tracks
                for _, track in ipairs(tracks) do
                    local infoOk, valid = pcall(function()
                        return track.IsPlaying and track.Length > 0
                    end)
                    if infoOk and valid then loadedCount += 1 end
                end
            end
            if loadedCount > 0 then break end
        end

        log("Tracks: "..trackCount.." | carregadas: "..loadedCount)
        if loadedCount > 0 and
            ((playedOk and playedResult == true) or
             (fallbackOk and fallbackValue == true)) then
            log("RESULTADO: animacao carregada na previa!")
        elseif not playedOk and not fallbackOk then
            log("RESULTADO: APIs rejeitadas. Veja a mensagem acima.")
        elseif loadedCount == 0 then
            log("RESULTADO: nenhuma animacao carregou neste jogo.")
        else
            log("RESULTADO: API nao confirmou o emote.")
        end
        busy = false
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
    log("Teste SALUTE para comparar; clique em Jamal depois.")
    log("O painel agora mostra os erros detalhados.")
end)
