local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local ClienteGroq = require(script.Parent.ClienteGroq)

local CerebroNPC = {}
CerebroNPC.__index = CerebroNPC

local ACAO_PADRAO = {
	tipo = "Idle",
	alvo = nil,
	mensagem = "Aguardando nova leitura contextual.",
	prioridade = 1,
}

local function converterValor(valor)
	local tipo = typeof(valor)

	if tipo == "Vector3" then
		return {
			x = valor.X,
			y = valor.Y,
			z = valor.Z,
			tipo = "Vector3",
		}
	end

	if tipo == "Color3" then
		return {
			r = valor.R,
			g = valor.G,
			b = valor.B,
			tipo = "Color3",
		}
	end

	if tipo == "CFrame" then
		local componentes = { valor:GetComponents() }
		return {
			componentes = componentes,
			tipo = "CFrame",
		}
	end

	if tipo == "EnumItem" then
		return tostring(valor)
	end

	if tipo == "Instance" then
		return valor:GetFullName()
	end

	if type(valor) == "table" then
		local convertido = {}
		for chave, item in pairs(valor) do
			convertido[chave] = converterValor(item)
		end
		return convertido
	end

	return valor
end

local function clonarTabela(origem)
	local copia = {}
	for chave, valor in pairs(origem) do
		if type(valor) == "table" then
			copia[chave] = clonarTabela(valor)
		else
			copia[chave] = valor
		end
	end
	return copia
end

local function serializarContexto(contexto)
	return HttpService:JSONEncode(converterValor(contexto))
end

local function montarMensagemSistema(config)
	return {
		role = "system",
		content = config.systemPrompt,
	}
end

local function montarMensagemUsuario(contexto, objetivo)
	local instrucao = {
		"Analise o contexto abaixo e defina o melhor comportamento para o NPC.",
		"Responda em JSON com os campos:",
		"thought, speech, actionType, actionTarget, priority, mood, summary.",
		"Objetivo atual do NPC: " .. (objetivo or "manter consciencia ambiental e agir com coerencia."),
		"Contexto:",
		serializarContexto(contexto),
	}

	return {
		role = "user",
		content = table.concat(instrucao, "\n"),
	}
end

function CerebroNPC.new(config)
	assert(type(config) == "table", "Config do CerebroNPC e obrigatoria")

	local self = setmetatable({}, CerebroNPC)
	self._config = config
	self._clienteGroq = config.clienteGroq or ClienteGroq.new(config.groq)
	self._memoriaCurta = {}
	self._ultimoEstado = nil

	return self
end

function CerebroNPC:registrarMemoria(evento)
	if type(evento) ~= "table" then
		return
	end

	table.insert(self._memoriaCurta, evento)
	if #self._memoriaCurta > (self._config.limiteMemoria or 10) then
		table.remove(self._memoriaCurta, 1)
	end
end

function CerebroNPC:_criarPacoteContexto(contexto, estadoInterno)
	local pacote = {
		contexto = contexto,
		memoriaCurta = self._memoriaCurta,
		estadoInterno = estadoInterno or {},
		personalidade = self._config.personalidade or {
			nome = "Nucleo Cognitivo Hermes",
			estilo = "tatico-conversacional",
			voz = "calma e objetiva",
		},
	}

	return pacote
end

function CerebroNPC:avaliarContexto(contexto, estadoInterno)
	assert(type(contexto) == "table", "contexto deve ser uma tabela")

	local pacote = self:_criarPacoteContexto(contexto, estadoInterno)
	local messages = {
		montarMensagemSistema(self._config.groq),
		montarMensagemUsuario(pacote, self._config.objetivoAtual),
	}

	local resposta, erro = self._clienteGroq:criarJSON(messages, {
		temperature = self._config.groq.temperature,
		maxTokens = self._config.groq.maxTokens,
	})

	if not resposta then
		return nil, erro
	end

	local json = resposta.json
	local resultado = {
		thought = json.thought or "Contexto recebido, sem pensamento explicito.",
		speech = json.speech or "Mantendo observacao do ambiente.",
		action = {
			tipo = json.actionType or ACAO_PADRAO.tipo,
			alvo = json.actionTarget,
			mensagem = json.speech or ACAO_PADRAO.mensagem,
			prioridade = tonumber(json.priority) or ACAO_PADRAO.prioridade,
		},
		mood = json.mood or "neutro",
		summary = json.summary or "Sem resumo adicional.",
		usage = resposta.usage,
		raw = resposta.raw,
	}

	self._ultimoEstado = resultado
	self:registrarMemoria({
		timestamp = os.time(),
		resumo = resultado.summary,
		acao = resultado.action.tipo,
		humor = resultado.mood,
	})

	return resultado
end

function CerebroNPC:gerarFala(contexto, instrucaoExtra)
	if self._config.forceLocal == true or RunService:IsClient() then
		local referencia = contexto
			and contexto.proximidades
			and contexto.proximidades[1]
			and contexto.proximidades[1].descricao
			or "setor atual"

		local resumo = contexto
			and contexto.interpretacaoFinal
			or "Sem leitura contextual detalhada."

		return {
			speech = string.format(
				"[%s] Mantendo observacao em %s. %s",
				(self._config.personalidade and self._config.personalidade.nome) or "Nucleo Local",
				referencia,
				instrucaoExtra or "Pronto para novos comandos."
			),
			mood = "focado",
			summary = resumo,
		}
	end

	local pacote = self:_criarPacoteContexto(contexto, {
		modo = "fala",
		instrucaoExtra = instrucaoExtra,
	})

	local messages = {
		montarMensagemSistema(self._config.groq),
		{
			role = "user",
			content = table.concat({
				"Gere uma fala curta para o NPC com base no contexto.",
				"Responda em JSON com os campos speech, mood e summary.",
				serializarContexto(pacote),
			}, "\n"),
		},
	}

	local resposta, erro = self._clienteGroq:criarJSON(messages, {
		temperature = 0.9,
		maxTokens = 120,
	})

	if not resposta then
		return nil, erro
	end

	return {
		speech = resposta.json.speech or "Sem fala gerada.",
		mood = resposta.json.mood or "neutro",
		summary = resposta.json.summary or "Sem resumo.",
	}
end

function CerebroNPC:decidirAcaoLocal(contexto)
	assert(type(contexto) == "table", "contexto deve ser uma tabela")

	local acao = clonarTabela(ACAO_PADRAO)
	local ambiente = contexto.ambiente or {}
	local proximidades = contexto.proximidades or {}
	local referencia = proximidades[1]

	if ambiente.alertas and #ambiente.alertas > 0 then
		acao.tipo = "InvestigarAlerta"
		acao.alvo = referencia and referencia.nome or "origem_do_alerta"
		acao.mensagem = "Sinal de alerta detectado. Iniciando verificacao."
		acao.prioridade = 10
		return acao
	end

	if referencia then
		acao.tipo = "ObservarArea"
		acao.alvo = referencia.nome
		acao.mensagem = "Executando leitura detalhada da area proxima."
		acao.prioridade = 6
		return acao
	end

	if ambiente.periodo == "noite" then
		acao.tipo = "PatrulharComCautela"
		acao.mensagem = "Baixa visibilidade detectada. Patrulha cautelosa recomendada."
		acao.prioridade = 5
		return acao
	end

	return acao
end

function CerebroNPC:executarCiclo(contexto, estadoInterno)
	if self._config.forceLocal == true or RunService:IsClient() then
		return {
			origem = "fallback_local",
			erro = "Modo client-only ativo: chamadas externas desabilitadas",
			resultado = {
				thought = "Ambiente client-only detectado. Mantendo somente heuristica local.",
				speech = "Operando com o cerebro local e leitura direta do ambiente.",
				action = self:decidirAcaoLocal(contexto),
				mood = "focado",
				summary = "Ciclo local executado sem acessar servicos externos.",
			},
		}
	end

	if not self._clienteGroq:estaConfigurado() then
		return {
			origem = "fallback_local",
			erro = "Groq API key nao configurada",
			resultado = {
				thought = "Chave da API ausente. Mantendo o cerebro em modo local.",
				speech = "Operando apenas com logica local ate a integracao externa ser habilitada.",
				action = self:decidirAcaoLocal(contexto),
				mood = "prudente",
				summary = "Fallback local acionado porque a Groq ainda nao foi configurada.",
			},
		}
	end

	local pensamentoIA, erro = self:avaliarContexto(contexto, estadoInterno)
	if pensamentoIA then
		return {
			origem = "groq",
			resultado = pensamentoIA,
		}
	end

	return {
		origem = "fallback_local",
		erro = erro,
		resultado = {
			thought = "Falha na consulta externa. Usando heuristica local.",
			speech = "Continuo operando com base nos sinais locais.",
			action = self:decidirAcaoLocal(contexto),
			mood = "prudente",
			summary = "Fallback local acionado por indisponibilidade da API.",
		},
	}
end

function CerebroNPC:obterUltimoEstado()
	return self._ultimoEstado
end

return CerebroNPC
