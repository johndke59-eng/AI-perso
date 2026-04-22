local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GroqConfig = require(ServerScriptService.NPCIA.GroqConfig)
local CerebroNPC = require(ServerScriptService.NPCIA.CerebroNPC)

local RemoteFunction = ReplicatedStorage:FindFirstChild("SolicitarContextoNPC")
if not RemoteFunction then
	RemoteFunction = Instance.new("RemoteFunction")
	RemoteFunction.Name = "SolicitarContextoNPC"
	RemoteFunction.Parent = ReplicatedStorage
end

local cerebro = CerebroNPC.new({
	groq = GroqConfig,
	objetivoAtual = "Interpretar o ambiente e orientar o NPC com respostas curtas e coerentes.",
	limiteMemoria = 12,
	personalidade = {
		nome = "Nucleo Cognitivo Hermes",
		estilo = "tatico-conversacional",
		voz = "clara e operacional",
	},
})

local function solicitarContextoDoCliente(player)
	local sucesso, resposta = pcall(function()
		return RemoteFunction:InvokeClient(player)
	end)

	if not sucesso then
		return nil, "Falha ao solicitar contexto do cliente: " .. tostring(resposta)
	end

	return resposta
end

local function processarJogador(player)
	local contexto, erro = solicitarContextoDoCliente(player)
	if not contexto then
		warn(erro)
		return
	end

	local ciclo = cerebro:executarCiclo(contexto, {
		playerUserId = player.UserId,
		playerName = player.Name,
	})

	print("Origem da decisao:", ciclo.origem)
	print("Resumo:", ciclo.resultado.summary)
	print("Fala:", ciclo.resultado.speech)
	print("Acao:", ciclo.resultado.action.tipo, ciclo.resultado.action.alvo)
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(3)
		processarJogador(player)
	end)
end)
