local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")

local LeitorContextoAmbiental = {}

local PERSONALIDADE_BASE = {
	nome = "Sistema de Navegacao Operacional Atlas",
	estilo = "operacional",
}

local PALAVRAS_AREA = {
	reator = "Perto do reator",
	reactor = "Perto do reator",
	corridor = "No corredor",
	corredor = "No corredor",
	entrada = "Ao lado da entrada",
	entrance = "Ao lado da entrada",
	lobby = "No lobby",
	control = "Na area de controle",
	ponte = "Na ponte de acesso",
	bridge = "Na ponte de acesso",
	lab = "Proximo ao laboratorio",
	laboratorio = "Proximo ao laboratorio",
	garagem = "Na area da garagem",
	hangar = "No hangar",
	core = "Proximo ao nucleo central",
	centro = "Na regiao central",
}

local PALAVRAS_ALERTA = {
	alarm = true,
	alarme = true,
	siren = true,
	alert = true,
	alerta = true,
	evacuate = true,
	emergency = true,
}

local function arredondar(valor, casas)
	local multiplicador = 10 ^ (casas or 0)
	return math.round(valor * multiplicador) / multiplicador
end

local function obterCharacterLocal()
	local player = Players.LocalPlayer
	if not player then
		return nil, "LocalPlayer indisponivel"
	end

	local character = player.Character or player.CharacterAdded:Wait()
	if not character then
		return nil, "Character indisponivel"
	end

	return character
end

local function obterRootPart(character)
	return character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart
		or character:FindFirstChildWhichIsA("BasePart")
end

local function normalizarNome(nome)
	return string.lower(nome:gsub("[%p_]+", " "))
end

local function descreverObjetoPorNome(nome)
	local nomeNormalizado = normalizarNome(nome)

	for palavraChave, descricao in PALAVRAS_AREA do
		if string.find(nomeNormalizado, palavraChave, 1, true) then
			if descricao == "No corredor" then
				local sufixo = nome:match("[Cc]orredor%s*([%w%-]+)") or nome:match("[Cc]orridor%s*([%w%-]+)")
				if sufixo then
					return string.format("%s %s", descricao, sufixo)
				end
			end

			return descricao
		end
	end

	return nil
end

local function encontrarModeloRaiz(instancia)
	local atual = instancia
	while atual and atual ~= Workspace do
		if atual:IsA("Model") and atual.Parent == Workspace then
			return atual
		end
		atual = atual.Parent
	end

	return nil
end

local function obterNomeMapa()
	local candidatos = {}

	local sucessoInfo, infoLugar = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)

	if sucessoInfo and type(infoLugar) == "table" then
		if infoLugar.Name and infoLugar.Name ~= "" then
			table.insert(candidatos, {
				nome = infoLugar.Name,
				peso = 100,
				fonte = "MarketplaceService.PlaceId",
			})
		end
	end

	local sucessoExperiencia, infoExperiencia = pcall(function()
		return MarketplaceService:GetProductInfo(game.GameId, Enum.InfoType.Asset)
	end)

	if sucessoExperiencia and type(infoExperiencia) == "table" then
		if infoExperiencia.Name and infoExperiencia.Name ~= "" then
			table.insert(candidatos, {
				nome = infoExperiencia.Name,
				peso = 90,
				fonte = "MarketplaceService.GameId",
			})
		end
	end

	if game.Name and game.Name ~= "" then
		table.insert(candidatos, {
			nome = game.Name,
			peso = 70,
			fonte = "DataModel.Name",
		})
	end

	for _, child in Workspace:GetChildren() do
		if child:IsA("Model") or child:IsA("Folder") then
			local nomeNormalizado = normalizarNome(child.Name)
			local peso = 0

			if string.find(nomeNormalizado, "map", 1, true) then
				peso += 55
			end

			if string.find(nomeNormalizado, "arena", 1, true) then
				peso += 45
			end

			if string.find(nomeNormalizado, "city", 1, true) or string.find(nomeNormalizado, "cidade", 1, true) then
				peso += 45
			end

			if string.find(nomeNormalizado, "facility", 1, true) or string.find(nomeNormalizado, "base", 1, true) then
				peso += 40
			end

			if #child:GetChildren() >= 10 then
				peso += 20
			end

			if peso > 0 then
				table.insert(candidatos, {
					nome = child.Name,
					peso = peso,
					fonte = "Workspace." .. child.ClassName,
				})
			end
		end
	end

	table.sort(candidatos, function(a, b)
		return a.peso > b.peso
	end)

	if candidatos[1] then
		return candidatos[1]
	end

	return {
		nome = "Mapa nao identificado",
		peso = 0,
		fonte = "Fallback",
	}
end

local function coletarReferenciasProximas(character, posicao)
	local referencias = {}
	local raioMaximo = 80

	for _, instancia in Workspace:GetDescendants() do
		if not instancia:IsA("BasePart") then
			continue
		end

		if instancia:IsDescendantOf(character) then
			continue
		end

		local distancia = (instancia.Position - posicao).Magnitude
		if distancia > raioMaximo then
			continue
		end

		local modeloRaiz = encontrarModeloRaiz(instancia)
		local nomeBase = if modeloRaiz then modeloRaiz.Name else instancia.Name
		local descricaoInterpretada = descreverObjetoPorNome(nomeBase) or descreverObjetoPorNome(instancia.Name)
		local prioridade = descricaoInterpretada and 100 or 0

		if CollectionService:HasTag(instancia, "PointOfInterest") then
			prioridade += 50
		end

		if modeloRaiz and CollectionService:HasTag(modeloRaiz, "PointOfInterest") then
			prioridade += 50
		end

		if string.find(normalizarNome(nomeBase), "spawn", 1, true) then
			prioridade += 30
		end

		if descricaoInterpretada or prioridade > 0 or distancia <= 20 then
			table.insert(referencias, {
				nome = nomeBase,
				distancia = arredondar(distancia, 1),
				descricao = descricaoInterpretada or ("Proximo de " .. nomeBase),
				prioridade = prioridade - distancia,
			})
		end
	end

	table.sort(referencias, function(a, b)
		return a.prioridade > b.prioridade
	end)

	local proximas = {}
	for indice = 1, math.min(5, #referencias) do
		table.insert(proximas, referencias[indice])
	end

	return proximas
end

local function descreverPosicao(posicao, referencias)
	local textoCoordenadas = string.format(
		"(X: %.1f, Y: %.1f, Z: %.1f)",
		arredondar(posicao.X, 1),
		arredondar(posicao.Y, 1),
		arredondar(posicao.Z, 1)
	)

	if referencias[1] then
		return string.format("%s %s", referencias[1].descricao, textoCoordenadas)
	end

	return "Sem referencia espacial clara " .. textoCoordenadas
end

local function identificarPeriodoDoDia()
	local horario = Lighting.ClockTime
	if horario >= 6 and horario < 12 then
		return "manha"
	elseif horario >= 12 and horario < 18 then
		return "tarde"
	elseif horario >= 18 and horario < 20 then
		return "entardecer"
	end

	return "noite"
end

local function inferirClima()
	local climaDetectado = {}

	if Workspace:FindFirstChildOfClass("Clouds") then
		table.insert(climaDetectado, "ceu com nuvens")
	end

	for _, instancia in Workspace:GetDescendants() do
		if instancia:IsA("ParticleEmitter") and instancia.Enabled then
			local nome = normalizarNome(instancia.Name)

			if string.find(nome, "rain", 1, true) or string.find(nome, "chuva", 1, true) then
				table.insert(climaDetectado, "chuva")
			elseif string.find(nome, "snow", 1, true) or string.find(nome, "neve", 1, true) then
				table.insert(climaDetectado, "neve")
			elseif string.find(nome, "fog", 1, true) or string.find(nome, "neblina", 1, true) then
				table.insert(climaDetectado, "neblina")
			end
		end
	end

	if #climaDetectado == 0 then
		if Lighting.FogEnd > 0 and Lighting.FogEnd < 250 then
			table.insert(climaDetectado, "neblina leve")
		else
			table.insert(climaDetectado, "clima estavel")
		end
	end

	return climaDetectado
end

local function inferirIluminacao()
	local brilho = Lighting.Brightness
	local ambiente = Lighting.Ambient
	local exposicao = brilho >= 3 and "forte" or brilho >= 1.5 and "moderada" or "baixa"

	return {
		intensidade = exposicao,
		brightness = brilho,
		ambient = ambiente,
		descricao = string.format(
			"Iluminacao %s, ambiente RGB(%d, %d, %d)",
			exposicao,
			ambiente.R,
			ambiente.G,
			ambiente.B
		),
	}
end

local function detectarAlertas()
	local alertas = {}

	for _, instancia in Workspace:GetDescendants() do
		local nomeNormalizado = normalizarNome(instancia.Name)
		local encontrouPalavra = false

		for palavra, _ in PALAVRAS_ALERTA do
			if string.find(nomeNormalizado, palavra, 1, true) then
				encontrouPalavra = true
				break
			end
		end

		if not encontrouPalavra then
			continue
		end

		if instancia:IsA("Sound") and instancia.IsPlaying then
			table.insert(alertas, "alarme sonoro ativo: " .. instancia.Name)
		elseif instancia:IsA("BoolValue") and instancia.Value then
			table.insert(alertas, "estado de alerta ativo: " .. instancia.Name)
		elseif instancia:GetAttribute("Active") == true or instancia:GetAttribute("Enabled") == true then
			table.insert(alertas, "sinal de alerta ativo: " .. instancia.Name)
		end
	end

	for _, som in SoundService:GetDescendants() do
		if som:IsA("Sound") and som.IsPlaying then
			local nomeNormalizado = normalizarNome(som.Name)
			for palavra, _ in PALAVRAS_ALERTA do
				if string.find(nomeNormalizado, palavra, 1, true) then
					table.insert(alertas, "audio critico em execucao: " .. som.Name)
					break
				end
			end
		end
	end

	return alertas
end

local function detectarEfeitosVisuais()
	local efeitos = {}

	for _, instancia in Workspace:GetDescendants() do
		if instancia:IsA("ParticleEmitter") and instancia.Enabled then
			table.insert(efeitos, "particulas ativas: " .. instancia.Name)
		elseif instancia:IsA("Beam") and instancia.Enabled then
			table.insert(efeitos, "feixe visual ativo: " .. instancia.Name)
		elseif instancia:IsA("PointLight") or instancia:IsA("SpotLight") or instancia:IsA("SurfaceLight") then
			if instancia.Enabled and instancia.Brightness >= 3 then
				table.insert(efeitos, "luz de destaque ativa: " .. instancia.Name)
			end
		end

		if #efeitos >= 5 then
			break
		end
	end

	return efeitos
end

local function gerarInterpretacaoFinal(analise)
	local referenciaPrincipal = analise.proximidades[1] and analise.proximidades[1].descricao or "setor nao classificado"
	local alerta = analise.ambiente.alertas[1] or "sem alarmes ativos"
	local clima = analise.ambiente.clima[1] or "clima estavel"

	return string.format(
		"[%s] Leitura operacional concluida. Unidade local posicionada em %s. Mapa principal: %s. Janela ambiental indica %s durante a %s, com %s.",
		PERSONALIDADE_BASE.nome,
		referenciaPrincipal,
		analise.mapa.nome,
		clima,
		analise.ambiente.periodo,
		alerta
	)
end

local function gerarResumoFormatado(analise)
	local linhas = {
		"Resumo do mapa atual: " .. analise.mapa.nome .. " (" .. analise.mapa.fonte .. ")",
		"Posicao atual do NPC/jogador: " .. analise.posicao.descricao,
		"Objetos ou areas relevantes proximas:",
	}

	if #analise.proximidades == 0 then
		table.insert(linhas, "- Nenhuma referencia relevante encontrada nas proximidades imediatas.")
	else
		for _, item in analise.proximidades do
			table.insert(linhas, string.format("- %s a %.1f studs", item.descricao, item.distancia))
		end
	end

	table.insert(linhas, "Estado do ambiente:")
	table.insert(linhas, "- Periodo: " .. analise.ambiente.periodo)
	table.insert(linhas, "- Clima: " .. table.concat(analise.ambiente.clima, ", "))
	table.insert(linhas, "- Iluminacao: " .. analise.ambiente.iluminacao.descricao)

	if #analise.ambiente.alertas > 0 then
		table.insert(linhas, "- Alertas: " .. table.concat(analise.ambiente.alertas, ", "))
	end

	if #analise.ambiente.efeitosVisuais > 0 then
		table.insert(linhas, "- Efeitos visuais: " .. table.concat(analise.ambiente.efeitosVisuais, ", "))
	end

	table.insert(linhas, "Interpretacao final: " .. analise.interpretacaoFinal)

	return table.concat(linhas, "\n")
end

function LeitorContextoAmbiental.analisar()
	local character, erro = obterCharacterLocal()
	if not character then
		return {
			sucesso = false,
			erro = erro,
			personalidade = PERSONALIDADE_BASE,
		}
	end

	local rootPart = obterRootPart(character)
	if not rootPart then
		return {
			sucesso = false,
			erro = "Nao foi possivel localizar uma BasePart raiz do Character",
			personalidade = PERSONALIDADE_BASE,
		}
	end

	local posicao = rootPart.Position
	local mapa = obterNomeMapa()
	local proximidades = coletarReferenciasProximas(character, posicao)

	local analise = {
		sucesso = true,
		personalidade = PERSONALIDADE_BASE,
		mapa = mapa,
		posicao = {
			vector = posicao,
			descricao = descreverPosicao(posicao, proximidades),
		},
		proximidades = proximidades,
		ambiente = {
			periodo = identificarPeriodoDoDia(),
			clima = inferirClima(),
			iluminacao = inferirIluminacao(),
			alertas = detectarAlertas(),
			efeitosVisuais = detectarEfeitosVisuais(),
		},
	}

	analise.interpretacaoFinal = gerarInterpretacaoFinal(analise)
	analise.resumoFormatado = gerarResumoFormatado(analise)

	return analise
end

return LeitorContextoAmbiental
