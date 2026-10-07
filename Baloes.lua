-- ============================================
-- AUTO ESTOURAR BALÕES - Script Completo
-- Hospedado via ivyy.lol
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ================= CONFIG =================
local CONFIG = {
    RaioArea         = 130,
    LinhasVarredura  = 8,
    DistanciaChegada = 4,
    TimeoutPorTrecho = 8,
}

-- ================= ESTADO GLOBAL =================
getgenv().AB_Estado = {
    Ativo = false,
    Centro = nil,
}
getgenv().AB_UI = {}
getgenv().AB_Rodando = false

-- ================= PARENT DA GUI =================
local function obterParentGUI()
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    if get_hidden_gui then
        local ok, res = pcall(get_hidden_gui)
        if ok and res then return res end
    end
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then pg = LocalPlayer:WaitForChild("PlayerGui", 5) end
    return pg or game:GetService("CoreGui")
end

local GUI_PARENT = obterParentGUI()

-- ================= CRIA PAINEL =================
local function criarPainel()
    local antigo = GUI_PARENT:FindFirstChild("AutoBalõesUI")
    if antigo then antigo:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoBalõesUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = GUI_PARENT

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 250, 0, 140)
    Main.Position = UDim2.new(0, 20, 0, 100)
    Main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(60, 130, 255)
    Stroke.Thickness = 1.5
    Stroke.Transparency = 0.3
    Stroke.Parent = Main

    local Titulo = Instance.new("TextLabel")
    Titulo.Size = UDim2.new(1, -20, 0, 28)
    Titulo.Position = UDim2.new(0, 12, 0, 8)
    Titulo.BackgroundTransparency = 1
    Titulo.Text = "🎈 Auto Estourar Balões"
    Titulo.TextColor3 = Color3.fromRGB(240, 245, 255)
    Titulo.TextSize = 15
    Titulo.Font = Enum.Font.GothamBold
    Titulo.TextXAlignment = Enum.TextXAlignment.Left
    Titulo.Parent = Main

    local StatusFrame = Instance.new("Frame")
    StatusFrame.Size = UDim2.new(1, -24, 0, 28)
    StatusFrame.Position = UDim2.new(0, 12, 0, 42)
    StatusFrame.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
    StatusFrame.BorderSizePixel = 0
    StatusFrame.Parent = Main
    Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 8, 0, 8)
    Dot.Position = UDim2.new(0, 10, 0.5, -4)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
    Dot.BorderSizePixel = 0
    Dot.Parent = StatusFrame
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local StatusTexto = Instance.new("TextLabel")
    StatusTexto.Size = UDim2.new(1, -30, 1, 0)
    StatusTexto.Position = UDim2.new(0, 26, 0, 0)
    StatusTexto.BackgroundTransparency = 1
    StatusTexto.Text = "Aguardando balões..."
    StatusTexto.TextColor3 = Color3.fromRGB(200, 210, 230)
    StatusTexto.TextSize = 12
    StatusTexto.Font = Enum.Font.Gotham
    StatusTexto.TextXAlignment = Enum.TextXAlignment.Left
    StatusTexto.Parent = StatusFrame

    local Botao = Instance.new("TextButton")
    Botao.Size = UDim2.new(1, -24, 0, 40)
    Botao.Position = UDim2.new(0, 12, 0, 84)
    Botao.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    Botao.BorderSizePixel = 0
    Botao.Text = "Auto Coletar: OFF"
    Botao.TextColor3 = Color3.fromRGB(255, 255, 255)
    Botao.TextSize = 14
    Botao.Font = Enum.Font.GothamBold
    Botao.AutoButtonColor = false
    Botao.Parent = Main
    Instance.new("UICorner", Botao).CornerRadius = UDim.new(0, 10)

    getgenv().AB_UI = {
        Botao = Botao,
        StatusTexto = StatusTexto,
        Dot = Dot,
    }

    Botao.MouseButton1Click:Connect(function()
        local E = getgenv().AB_Estado
        E.Ativo = not E.Ativo
        if E.Ativo then
            Botao.Text = "Auto Coletar: ON"
            TweenService:Create(Botao, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 200, 110)}):Play()
            Dot.BackgroundColor3 = Color3.fromRGB(80, 255, 140)
            if getgenv().AB_Iniciar then getgenv().AB_Iniciar() end
        else
            Botao.Text = "Auto Coletar: OFF"
            TweenService:Create(Botao, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 60, 60)}):Play()
            Dot.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
            StatusTexto.Text = "Aguardando balões..."
            if getgenv().AB_Parar then getgenv().AB_Parar() end
        end
    end)
end

-- ================= UTIL =================
local function obterHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function obterHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildWhichIsA("Humanoid") or nil
end

local function setStatus(txt)
    local ui = getgenv().AB_UI
    if ui and ui.StatusTexto then ui.StatusTexto.Text = txt end
end

local function parar()
    local h = obterHum()
    if h then h:Move(Vector3.zero) end
end

-- ================= DETECÇÃO =================
local function contarBalões(raio)
    local hrp = obterHRP()
    if not hrp then return 0 end
    local minha = hrp.Position
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local pertence = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and obj:IsDescendantOf(p.Character) then
                    pertence = true
                    break
                end
            end
            if not pertence then
                local n = obj.Name:lower()
                if n ~= "base" and n ~= "handle" and n ~= "mesh" and n ~= "head" then
                    if (obj.Position - minha).Magnitude <= raio then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

-- ================= ROTA =================
local function gerarRota(centro)
    local pts = {}
    local r = CONFIG.RaioArea
    local passo = (r * 2) / CONFIG.LinhasVarredura
    for i = 0, CONFIG.LinhasVarredura do
        local z = centro.Z - r + (i * passo)
        if i % 2 == 0 then
            table.insert(pts, Vector3.new(centro.X - r, centro.Y, z))
            table.insert(pts, Vector3.new(centro.X + r, centro.Y, z))
        else
            table.insert(pts, Vector3.new(centro.X + r, centro.Y, z))
            table.insert(pts, Vector3.new(centro.X - r, centro.Y, z))
        end
    end
    return pts
end

-- ================= MOVIMENTO =================
local function andarAté(posAlvo)
    local hrp = obterHRP()
    local hum = obterHum()
    if not hrp or not hum then return false end
    local inicio = tick()
    while getgenv().AB_Estado.Ativo do
        hrp = obterHRP()
        hum = obterHum()
        if not hrp or not hum then return false end
        local minha = hrp.Position
        local alvo = Vector3.new(posAlvo.X, minha.Y, posAlvo.Z)
        local delta = Vector3.new(alvo.X - minha.X, 0, alvo.Z - minha.Z)
        if delta.Magnitude <= CONFIG.DistanciaChegada then
            hum:Move(Vector3.zero)
            return true
        end
        if tick() - inicio > CONFIG.TimeoutPorTrecho then
            hum:Move(Vector3.zero)
            return false
        end
        hum:MoveTo(alvo)
        RunService.Heartbeat:Wait()
    end
    return false
end

-- ================= LOOP PRINCIPAL =================
getgenv().AB_Iniciar = function()
    if getgenv().AB_Rodando then return end
    getgenv().AB_Rodando = true
    local hrp = obterHRP()
    if hrp then getgenv().AB_Estado.Centro = hrp.Position end

    task.spawn(function()
        while getgenv().AB_Estado.Ativo do
            local E = getgenv().AB_Estado
            if not E.Centro then
                local h = obterHRP()
                if h then E.Centro = h.Position end
            end

            local balões = contarBalões(CONFIG.RaioArea)

            if balões == 0 then
                setStatus("Aguardando balões...")
                parar()
                task.wait(1.2)
                local h = obterHRP()
                if h then E.Centro = h.Position end
            else
                setStatus("Coletando...")
                local rota = gerarRota(E.Centro)
                for _, p in ipairs(rota) do
                    if not E.Ativo then break end
                    local h = obterHRP()
                    if h then
                        local d = (Vector3.new(h.Position.X, E.Centro.Y, h.Position.Z)
                                 - Vector3.new(E.Centro.X, E.Centro.Y, E.Centro.Z)).Magnitude
                        if d > CONFIG.RaioArea * 2 then
                            E.Centro = h.Position
                            break
                        end
                    end
                    andarAté(p)
                    task.wait(0.05)
                end
                setStatus("Procurando balões...")
                task.wait(0.3)
            end
        end
        getgenv().AB_Rodando = false
    end)
end

getgenv().AB_Parar = function()
    parar()
end

-- ================= INICIALIZA =================
criarPainel()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    if getgenv().AB_Estado.Ativo then
        local h = obterHRP()
        if h then getgenv().AB_Estado.Centro = h.Position end
        setStatus("Procurando balões...")
    end
end)

print("[AutoBalões] Carregado com sucesso!")
