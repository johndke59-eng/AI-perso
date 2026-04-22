local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local NPCClientController = require(script.Parent.NPCClientController)
local Modulo3Laboratorio = require(script.Parent.Modulo3Laboratorio)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local controller = NPCClientController.new({
	teclaToggle = Enum.KeyCode.F4,
})
local laboratorio = Modulo3Laboratorio.new(controller)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NPCDebugInterface"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(1, 0)
root.Position = UDim2.new(1, -18, 0, 18)
root.Size = UDim2.new(0, 430, 0, 520)
root.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
root.BorderSizePixel = 0
root.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(78, 139, 255)
stroke.Thickness = 1
stroke.Transparency = 0.15
stroke.Parent = root

local header = Instance.new("TextLabel")
header.Name = "Header"
header.BackgroundTransparency = 1
header.Position = UDim2.new(0, 16, 0, 12)
header.Size = UDim2.new(1, -32, 0, 28)
header.Font = Enum.Font.GothamBold
header.TextSize = 19
header.TextXAlignment = Enum.TextXAlignment.Left
header.TextColor3 = Color3.fromRGB(235, 241, 255)
header.Text = "Console Operacional do NPC"
header.Parent = root

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 16, 0, 42)
statusLabel.Size = UDim2.new(1, -32, 0, 18)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(150, 168, 194)
statusLabel.Text = "Toggle atual: F4"
statusLabel.Parent = root

local buttonRow = Instance.new("Frame")
buttonRow.BackgroundTransparency = 1
buttonRow.Position = UDim2.new(0, 16, 0, 74)
buttonRow.Size = UDim2.new(1, -32, 0, 76)
buttonRow.Parent = root

local buttonLayout = Instance.new("UIGridLayout")
buttonLayout.CellPadding = UDim2.new(0, 8, 0, 8)
buttonLayout.CellSize = UDim2.new(0.5, -4, 0, 34)
buttonLayout.Parent = buttonRow

local function criarBotao(texto)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.fromRGB(24, 33, 48)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamSemibold
	button.TextColor3 = Color3.fromRGB(232, 240, 255)
	button.TextSize = 13
	button.Text = texto

	local localCorner = Instance.new("UICorner")
	localCorner.CornerRadius = UDim.new(0, 10)
	localCorner.Parent = button

	return button
end

local botaoEscanear = criarBotao("Escanear Contexto")
botaoEscanear.Parent = buttonRow

local botaoCiclo = criarBotao("Executar Ciclo")
botaoCiclo.Parent = buttonRow

local botaoFala = criarBotao("Gerar Fala")
botaoFala.Parent = buttonRow

local botaoAcao = criarBotao("Executar Acao")
botaoAcao.Parent = buttonRow

local botaoAutoScan = criarBotao("Alternar Auto Scan")
botaoAutoScan.Parent = buttonRow

local botaoLimpar = criarBotao("Limpar Console")
botaoLimpar.Parent = buttonRow

local toggleConfig = Instance.new("Frame")
toggleConfig.BackgroundTransparency = 1
toggleConfig.Position = UDim2.new(0, 16, 0, 162)
toggleConfig.Size = UDim2.new(1, -32, 0, 70)
toggleConfig.Parent = root

local configLabel = Instance.new("TextLabel")
configLabel.BackgroundTransparency = 1
configLabel.Size = UDim2.new(1, 0, 0, 16)
configLabel.Font = Enum.Font.GothamSemibold
configLabel.TextSize = 13
configLabel.TextColor3 = Color3.fromRGB(215, 225, 245)
configLabel.TextXAlignment = Enum.TextXAlignment.Left
configLabel.Text = "Tecla para abrir/fechar GUI"
configLabel.Parent = toggleConfig

local keyBox = Instance.new("TextBox")
keyBox.Position = UDim2.new(0, 0, 0, 24)
keyBox.Size = UDim2.new(0, 170, 0, 34)
keyBox.BackgroundColor3 = Color3.fromRGB(24, 33, 48)
keyBox.BorderSizePixel = 0
keyBox.Font = Enum.Font.Gotham
keyBox.PlaceholderText = "Ex: F4, RightBracket"
keyBox.Text = controller:obterTeclaToggle().Name
keyBox.TextColor3 = Color3.fromRGB(237, 242, 255)
keyBox.TextSize = 14
keyBox.Parent = toggleConfig

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 10)
keyCorner.Parent = keyBox

local applyButton = criarBotao("Aplicar Tecla")
applyButton.Size = UDim2.new(0, 140, 0, 34)
applyButton.Position = UDim2.new(0, 182, 0, 24)
applyButton.Parent = toggleConfig

local summaryLabel = Instance.new("TextLabel")
summaryLabel.BackgroundTransparency = 1
summaryLabel.Position = UDim2.new(0, 16, 0, 236)
summaryLabel.Size = UDim2.new(1, -32, 0, 18)
summaryLabel.Font = Enum.Font.GothamSemibold
summaryLabel.TextSize = 13
summaryLabel.TextColor3 = Color3.fromRGB(215, 225, 245)
summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
summaryLabel.Text = "Resumo Atual"
summaryLabel.Parent = root

local summaryBox = Instance.new("TextLabel")
summaryBox.BackgroundColor3 = Color3.fromRGB(18, 25, 37)
summaryBox.BorderSizePixel = 0
summaryBox.Position = UDim2.new(0, 16, 0, 260)
summaryBox.Size = UDim2.new(1, -32, 0, 90)
summaryBox.Font = Enum.Font.Code
summaryBox.TextSize = 13
summaryBox.TextColor3 = Color3.fromRGB(208, 226, 255)
summaryBox.TextXAlignment = Enum.TextXAlignment.Left
summaryBox.TextYAlignment = Enum.TextYAlignment.Top
summaryBox.TextWrapped = true
summaryBox.Text = "Nenhum ciclo executado ainda."
summaryBox.Parent = root

local summaryCorner = Instance.new("UICorner")
summaryCorner.CornerRadius = UDim.new(0, 10)
summaryCorner.Parent = summaryBox

local commandLabel = Instance.new("TextLabel")
commandLabel.BackgroundTransparency = 1
commandLabel.Position = UDim2.new(0, 16, 0, 356)
commandLabel.Size = UDim2.new(1, -32, 0, 18)
commandLabel.Font = Enum.Font.GothamSemibold
commandLabel.TextSize = 13
commandLabel.TextColor3 = Color3.fromRGB(215, 225, 245)
commandLabel.TextXAlignment = Enum.TextXAlignment.Left
commandLabel.Text = "Laboratorio de Comandos"
commandLabel.Parent = root

local commandBox = Instance.new("TextBox")
commandBox.Position = UDim2.new(0, 16, 0, 380)
commandBox.Size = UDim2.new(1, -128, 0, 34)
commandBox.BackgroundColor3 = Color3.fromRGB(24, 33, 48)
commandBox.BorderSizePixel = 0
commandBox.Font = Enum.Font.Code
commandBox.PlaceholderText = "Digite HELP, THEME neon, SPIN, DASH, SPEAK ola..."
commandBox.Text = ""
commandBox.TextColor3 = Color3.fromRGB(237, 242, 255)
commandBox.TextSize = 14
commandBox.Parent = root

local commandCorner = Instance.new("UICorner")
commandCorner.CornerRadius = UDim.new(0, 10)
commandCorner.Parent = commandBox

local commandButton = criarBotao("Executar")
commandButton.Size = UDim2.new(0, 96, 0, 34)
commandButton.Position = UDim2.new(1, -112, 0, 380)
commandButton.Parent = root

local consoleLabel = Instance.new("TextLabel")
consoleLabel.BackgroundTransparency = 1
consoleLabel.Position = UDim2.new(0, 16, 0, 424)
consoleLabel.Size = UDim2.new(1, -32, 0, 18)
consoleLabel.Font = Enum.Font.GothamSemibold
consoleLabel.TextSize = 13
consoleLabel.TextColor3 = Color3.fromRGB(215, 225, 245)
consoleLabel.TextXAlignment = Enum.TextXAlignment.Left
consoleLabel.Text = "Debug Console"
consoleLabel.Parent = root

local consoleFrame = Instance.new("ScrollingFrame")
consoleFrame.Position = UDim2.new(0, 16, 0, 448)
consoleFrame.Size = UDim2.new(1, -32, 1, -464)
consoleFrame.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
consoleFrame.BorderSizePixel = 0
consoleFrame.ScrollBarThickness = 6
consoleFrame.CanvasSize = UDim2.new()
consoleFrame.Parent = root

local consoleCorner = Instance.new("UICorner")
consoleCorner.CornerRadius = UDim.new(0, 10)
consoleCorner.Parent = consoleFrame

local consoleLayout = Instance.new("UIListLayout")
consoleLayout.Padding = UDim.new(0, 6)
consoleLayout.Parent = consoleFrame

local entries = {}
local aguardandoTecla = false

local function aplicarTema(tema)
	root.BackgroundColor3 = tema.root
	stroke.Color = tema.borda
	header.TextColor3 = tema.texto
	statusLabel.TextColor3 = tema.texto:Lerp(Color3.new(0, 0, 0), 0.35)
	configLabel.TextColor3 = tema.texto
	summaryLabel.TextColor3 = tema.texto
	commandLabel.TextColor3 = tema.texto
	consoleLabel.TextColor3 = tema.texto
	summaryBox.BackgroundColor3 = tema.painel
	summaryBox.TextColor3 = tema.texto
	consoleFrame.BackgroundColor3 = tema.painel:Lerp(Color3.new(0, 0, 0), 0.45)
	keyBox.BackgroundColor3 = tema.botao
	keyBox.TextColor3 = tema.texto
	commandBox.BackgroundColor3 = tema.botao
	commandBox.TextColor3 = tema.texto

	for _, guiObject in ipairs(buttonRow:GetChildren()) do
		if guiObject:IsA("TextButton") then
			guiObject.BackgroundColor3 = tema.botao
			guiObject.TextColor3 = tema.texto
		end
	end

	applyButton.BackgroundColor3 = tema.botao
	applyButton.TextColor3 = tema.texto
	commandButton.BackgroundColor3 = tema.botao
	commandButton.TextColor3 = tema.texto
end

local function atualizarStatus()
	statusLabel.Text = string.format(
		"Toggle atual: %s | GUI: %s | Auto scan: %s",
		controller:obterTeclaToggle().Name,
		controller:obterEstado().guiAberta and "aberta" or "fechada",
		controller:obterEstado().autoScanAtivo and "ligado" or "desligado"
	)
end

local function atualizarResumo()
	local estado = controller:obterEstado()
	if estado.ultimoCiclo and estado.ultimoCiclo.resultado then
		summaryBox.Text = table.concat({
			"Origem: " .. tostring(estado.ultimoCiclo.origem),
			"Resumo: " .. tostring(estado.ultimoCiclo.resultado.summary),
			"Fala: " .. tostring(estado.ultimoCiclo.resultado.speech),
			"Acao: " .. tostring(estado.ultimoCiclo.resultado.action and estado.ultimoCiclo.resultado.action.tipo),
		}, "\n")
	elseif estado.ultimoContexto and estado.ultimoContexto.resumoFormatado then
		summaryBox.Text = estado.ultimoContexto.resumoFormatado
	else
		summaryBox.Text = "Nenhum ciclo executado ainda."
	end
end

local function adicionarLinhaConsole(texto)
	local label = Instance.new("TextLabel")
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, -12, 0, 20)
	label.BackgroundColor3 = laboratorio:obterTema().botao
	label.BorderSizePixel = 0
	label.Font = Enum.Font.Code
	label.TextSize = 12
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = laboratorio:obterTema().texto
	label.Text = texto
	label.Parent = consoleFrame

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 8)
	itemCorner.Parent = label

	table.insert(entries, label)
	while #entries > 60 do
		entries[1]:Destroy()
		table.remove(entries, 1)
	end

	task.defer(function()
		consoleFrame.CanvasSize = UDim2.new(0, 0, 0, consoleLayout.AbsoluteContentSize.Y + 8)
		consoleFrame.CanvasPosition = Vector2.new(0, math.max(consoleLayout.AbsoluteContentSize.Y, 0))
	end)
end

local function executarComandoLaboratorio()
	local texto = commandBox.Text
	local resultado, erro = laboratorio:executarComando(texto)
	if not resultado then
		controller:log("erro", "Falha no laboratorio.", erro)
		return
	end

	if resultado.tipo == "theme" then
		aplicarTema(resultado.tema)
	end

	controller:log("lab", resultado.texto)
	commandBox.Text = ""
	atualizarStatus()
	atualizarResumo()
end

controller:conectarDebug(function(evento)
	local linha = string.format("[%s] [%s] %s", evento.timestamp, string.upper(evento.canal), evento.mensagem)
	if evento.dados ~= nil then
		linha ..= " | " .. tostring(evento.dados)
	end

	adicionarLinhaConsole(linha)
	atualizarStatus()
	atualizarResumo()
end)

controller:conectarToggle(function(estaAberta)
	root.Visible = estaAberta
	atualizarStatus()
end)

botaoEscanear.MouseButton1Click:Connect(function()
	controller:capturarContexto()
	atualizarResumo()
end)

botaoCiclo.MouseButton1Click:Connect(function()
	controller:executarCiclo()
	atualizarResumo()
end)

botaoFala.MouseButton1Click:Connect(function()
	controller:forcarFala("Produza uma fala curta de debug para a interface.")
	atualizarResumo()
end)

botaoAcao.MouseButton1Click:Connect(function()
	controller:executarAcaoAtual()
	atualizarResumo()
end)

botaoAutoScan.MouseButton1Click:Connect(function()
	if controller:obterEstado().autoScanAtivo then
		controller:pararAutoScan()
	else
		controller:iniciarAutoScan(8)
	end

	atualizarStatus()
end)

botaoLimpar.MouseButton1Click:Connect(function()
	for _, entry in ipairs(entries) do
		entry:Destroy()
	end
	table.clear(entries)
	consoleFrame.CanvasSize = UDim2.new()
	controller:log("ui", "Console limpo manualmente.")
end)

applyButton.MouseButton1Click:Connect(function()
	local texto = keyBox.Text:gsub("%s+", "")
	local keyCode = Enum.KeyCode[texto]
	if keyCode then
		controller:definirTeclaToggle(keyCode)
		atualizarStatus()
	else
		controller:log("erro", "Tecla invalida: " .. texto)
	end
end)

commandButton.MouseButton1Click:Connect(executarComandoLaboratorio)

commandBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		executarComandoLaboratorio()
	end
end)

UserInputService.InputBegan:Connect(function(input, processado)
	if processado then
		return
	end

	if aguardandoTecla then
		aguardandoTecla = false
		keyBox.Text = input.KeyCode.Name
		controller:definirTeclaToggle(input.KeyCode)
		atualizarStatus()
	end
end)

keyBox.Focused:Connect(function()
	aguardandoTecla = true
	keyBox.Text = ""
end)

keyBox.FocusLost:Connect(function()
	aguardandoTecla = false
	if keyBox.Text == "" then
		keyBox.Text = controller:obterTeclaToggle().Name
	end
end)

atualizarStatus()
atualizarResumo()
aplicarTema(laboratorio:obterTema())
controller:log("ui", "Interface pronta. Use a tecla configurada para abrir ou fechar.")
