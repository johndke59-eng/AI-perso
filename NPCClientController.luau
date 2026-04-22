local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LeitorContextoAmbiental = require(script.Parent.LeitorContextoAmbiental)
local CerebroNPC = require(script.Parent.CerebroNPC)
local GroqConfig = require(script.Parent.GroqConfig)

local NPCClientController = {}
NPCClientController.__index = NPCClientController

local function criarSignal()
	local bindable = Instance.new("BindableEvent")

	return {
		Fire = function(_, ...)
			bindable:Fire(...)
		end,
		Connect = function(_, callback)
			return bindable.Event:Connect(callback)
		end,
		Destroy = function()
			bindable:Destroy()
		end,
	}
end

local function serializarSeguro(valor)
	local tipo = typeof(valor)

	if tipo == "Vector3" then
		return string.format("(%.1f, %.1f, %.1f)", valor.X, valor.Y, valor.Z)
	end

	if tipo == "Color3" then
		return string.format("Color3(%.2f, %.2f, %.2f)", valor.R, valor.G, valor.B)
	end

	if tipo == "table" then
		local sucesso, json = pcall(function()
			return HttpService:JSONEncode(valor)
		end)

		if sucesso then
			return json
		end
	end

	return tostring(valor)
end

local function obterCharacter()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	return player.Character or player.CharacterAdded:Wait()
end

function NPCClientController.new(config)
	local self = setmetatable({}, NPCClientController)
	self._config = config or {}
	self._debugSignal = criarSignal()
	self._toggleSignal = criarSignal()
	self._estado = {
		guiAberta = true,
		autoScanAtivo = false,
		teclaToggle = self._config.teclaToggle or Enum.KeyCode.F4,
		ultimoContexto = nil,
		ultimoCiclo = nil,
		ultimoErro = nil,
	}
	self._cerebro = CerebroNPC.new({
		groq = GroqConfig,
		forceLocal = true,
		objetivoAtual = "Responder ao ambiente do personagem local com acoes e falas curtas.",
		limiteMemoria = 15,
		personalidade = {
			nome = "Nucleo Cognitivo Hermes",
			estilo = "tatico-operacional",
			voz = "objetiva e clara",
		},
	})
	self._conexoes = {}

	self:_registrarInput()
	self:log("controlador", "NPC client controller inicializado.")
	self:log("seguranca", "Modo client-only ativo. Integracoes HTTP externas foram desabilitadas por seguranca e compatibilidade.")

	return self
end

function NPCClientController:_registrarInput()
	table.insert(self._conexoes, UserInputService.InputBegan:Connect(function(input, processado)
		if processado then
			return
		end

		if input.KeyCode == self._estado.teclaToggle then
			self:alternarGUI()
		end
	end))
end

function NPCClientController:_obterHumanoidRootPart()
	local character = obterCharacter()
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart
		or character:FindFirstChildWhichIsA("BasePart")
end

function NPCClientController:_moverParaAlvo(nomeAlvo)
	if type(nomeAlvo) ~= "string" or nomeAlvo == "" then
		return false, "Alvo invalido para movimento"
	end

	local rootPart = self:_obterHumanoidRootPart()
	if not rootPart then
		return false, "HumanoidRootPart nao encontrado"
	end

	for _, instancia in Workspace:GetDescendants() do
		if instancia.Name == nomeAlvo and instancia:IsA("BasePart") then
			rootPart.CFrame = instancia.CFrame + Vector3.new(0, 3, 0)
			return true
		end
	end

	return false, "Nenhum objeto com esse nome foi encontrado"
end

function NPCClientController:log(canal, mensagem, dados)
	local evento = {
		timestamp = os.date("%H:%M:%S"),
		canal = canal or "sistema",
		mensagem = mensagem or "",
		dados = dados,
	}

	self._debugSignal:Fire(evento)
end

function NPCClientController:definirTeclaToggle(novaTecla)
	if typeof(novaTecla) ~= "EnumItem" or novaTecla.EnumType ~= Enum.KeyCode then
		return false, "A tecla precisa ser um Enum.KeyCode"
	end

	self._estado.teclaToggle = novaTecla
	self:log("config", "Tecla de toggle alterada para " .. novaTecla.Name)

	return true
end

function NPCClientController:obterTeclaToggle()
	return self._estado.teclaToggle
end

function NPCClientController:alternarGUI()
	self._estado.guiAberta = not self._estado.guiAberta
	self._toggleSignal:Fire(self._estado.guiAberta)
	self:log("ui", "GUI " .. (self._estado.guiAberta and "aberta" or "fechada"))
end

function NPCClientController:capturarContexto()
	local contexto = LeitorContextoAmbiental.analisar()
	self._estado.ultimoContexto = contexto
	self:log("contexto", "Leitura contextual concluida.", {
		mapa = contexto.mapa and contexto.mapa.nome,
		posicao = contexto.posicao and contexto.posicao.descricao,
	})

	return contexto
end

function NPCClientController:executarCiclo()
	local contexto = self:capturarContexto()
	local ciclo = self._cerebro:executarCiclo(contexto, {
		playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Desconhecido",
	})

	self._estado.ultimoCiclo = ciclo
	self._estado.ultimoErro = ciclo.erro

	self:log("cerebro", "Ciclo cognitivo executado.", {
		origem = ciclo.origem,
		resumo = ciclo.resultado.summary,
		acao = ciclo.resultado.action and ciclo.resultado.action.tipo,
	})

	return ciclo
end

function NPCClientController:forcarFala(instrucaoExtra)
	local contexto = self._estado.ultimoContexto or self:capturarContexto()
	local fala, erro = self._cerebro:gerarFala(contexto, instrucaoExtra)
	if not fala then
		self:log("erro", "Falha ao gerar fala.", erro)
		return nil, erro
	end

	self:log("fala", fala.speech, fala)
	return fala
end

function NPCClientController:executarAcaoAtual()
	local ciclo = self._estado.ultimoCiclo or self:executarCiclo()
	local action = ciclo.resultado and ciclo.resultado.action
	if not action then
		return false, "Nenhuma acao disponivel"
	end

	if action.tipo == "ObservarArea" or action.tipo == "InvestigarAlerta" then
		local sucesso, erro = self:_moverParaAlvo(action.alvo)
		if sucesso then
			self:log("acao", "Movimento executado para " .. tostring(action.alvo))
		else
			self:log("acao", "Acao sem movimento efetivo.", erro)
		end

		return sucesso, erro
	end

	self:log("acao", action.mensagem or "Acao processada sem movimento.")
	return true
end

function NPCClientController:definirAutoScan(ativo)
	self._estado.autoScanAtivo = ativo == true
	self:log("config", "Auto scan " .. (self._estado.autoScanAtivo and "ativado" or "desativado"))

	return self._estado.autoScanAtivo
end

function NPCClientController:iniciarAutoScan(intervalo)
	intervalo = math.max(intervalo or 6, 1)
	self:definirAutoScan(true)

	if self._loopAutoScan then
		task.cancel(self._loopAutoScan)
	end

	self._loopAutoScan = task.spawn(function()
		while self._estado.autoScanAtivo do
			local sucesso, erro = pcall(function()
				self:executarCiclo()
			end)

			if not sucesso then
				self:log("erro", "Falha durante auto scan.", erro)
			end

			task.wait(intervalo)
		end
	end)
end

function NPCClientController:pararAutoScan()
	self:definirAutoScan(false)
end

function NPCClientController:obterEstado()
	return self._estado
end

function NPCClientController:conectarDebug(callback)
	return self._debugSignal:Connect(callback)
end

function NPCClientController:conectarToggle(callback)
	return self._toggleSignal:Connect(callback)
end

function NPCClientController:dumpEstadoTexto()
	local estado = self._estado
	local linhas = {
		"GUI aberta: " .. tostring(estado.guiAberta),
		"Auto scan: " .. tostring(estado.autoScanAtivo),
		"Tecla toggle: " .. estado.teclaToggle.Name,
		"Ultimo erro: " .. tostring(estado.ultimoErro),
	}

	if estado.ultimoContexto and estado.ultimoContexto.resumoFormatado then
		table.insert(linhas, "Resumo contexto: " .. estado.ultimoContexto.resumoFormatado)
	end

	if estado.ultimoCiclo and estado.ultimoCiclo.resultado then
		table.insert(linhas, "Resumo cerebro: " .. tostring(estado.ultimoCiclo.resultado.summary))
	end

	return table.concat(linhas, "\n")
end

function NPCClientController:destruir()
	self:pararAutoScan()

	for _, conexao in ipairs(self._conexoes) do
		conexao:Disconnect()
	end

	self._debugSignal:Destroy()
	self._toggleSignal:Destroy()
end

return NPCClientController
