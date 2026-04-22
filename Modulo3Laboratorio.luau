local Modulo3Laboratorio = {}
Modulo3Laboratorio.__index = Modulo3Laboratorio

local TEMAS = {
	azul = {
		nome = "Azul Operacional",
		root = Color3.fromRGB(14, 18, 24),
		painel = Color3.fromRGB(18, 25, 37),
		botao = Color3.fromRGB(24, 33, 48),
		borda = Color3.fromRGB(78, 139, 255),
		texto = Color3.fromRGB(232, 240, 255),
	},
	amber = {
		nome = "Amber Tatico",
		root = Color3.fromRGB(26, 19, 10),
		painel = Color3.fromRGB(39, 28, 14),
		botao = Color3.fromRGB(61, 42, 18),
		borda = Color3.fromRGB(255, 176, 68),
		texto = Color3.fromRGB(255, 242, 216),
	},
	neon = {
		nome = "Neon Arcade",
		root = Color3.fromRGB(12, 10, 18),
		painel = Color3.fromRGB(22, 17, 35),
		botao = Color3.fromRGB(37, 27, 58),
		borda = Color3.fromRGB(82, 255, 201),
		texto = Color3.fromRGB(222, 255, 248),
	},
}

local AJUDA = table.concat({
	"Comandos do laboratorio:",
	"HELP",
	"SCAN",
	"CYCLE",
	"SPEAK texto livre",
	"ACT",
	"AUTOSCAN ON",
	"AUTOSCAN OFF",
	"THEME azul|amber|neon",
	"KEY F4",
	"MOOD",
	"JUMP",
	"SPIN",
	"DASH",
}, "\n")

local FRASES_MOOD = {
	"Diagnostico alegre: todos os subsistemas parecem animados.",
	"Leitura casual: o ambiente parece propicio para experimentar comandos.",
	"Estado tatico: foco alto e curiosidade operacional em crescimento.",
	"Humor do nucleo: confiante o bastante para testar algo novo.",
}

function Modulo3Laboratorio.new(controller)
	local self = setmetatable({}, Modulo3Laboratorio)
	self._controller = controller
	self._temaAtual = "azul"

	return self
end

function Modulo3Laboratorio:obterTema(nomeTema)
	return TEMAS[nomeTema or self._temaAtual] or TEMAS.azul
end

function Modulo3Laboratorio:listarTemas()
	return TEMAS
end

function Modulo3Laboratorio:aplicarTema(nomeTema)
	if not TEMAS[nomeTema] then
		return nil, "Tema invalido. Use azul, amber ou neon."
	end

	self._temaAtual = nomeTema
	return {
		ok = true,
		tipo = "theme",
		tema = TEMAS[nomeTema],
		texto = "Tema alterado para " .. TEMAS[nomeTema].nome,
	}
end

function Modulo3Laboratorio:_obterHumanoid()
	local player = game.Players.LocalPlayer
	local character = player and (player.Character or player.CharacterAdded:Wait())
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

function Modulo3Laboratorio:_obterRootPart()
	local player = game.Players.LocalPlayer
	local character = player and (player.Character or player.CharacterAdded:Wait())
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart
		or character:FindFirstChildWhichIsA("BasePart")
end

function Modulo3Laboratorio:_acaoPulo()
	local humanoid = self:_obterHumanoid()
	if not humanoid then
		return nil, "Humanoid nao encontrado"
	end

	humanoid.Jump = true
	return {
		ok = true,
		tipo = "action",
		texto = "Salto executado.",
	}
end

function Modulo3Laboratorio:_acaoSpin()
	local root = self:_obterRootPart()
	if not root then
		return nil, "RootPart nao encontrado"
	end

	task.spawn(function()
		for _ = 1, 12 do
			root.CFrame *= CFrame.Angles(0, math.rad(30), 0)
			task.wait(0.03)
		end
	end)

	return {
		ok = true,
		tipo = "action",
		texto = "Rotacao rapida iniciada.",
	}
end

function Modulo3Laboratorio:_acaoDash()
	local root = self:_obterRootPart()
	if not root then
		return nil, "RootPart nao encontrado"
	end

	root.CFrame += root.CFrame.LookVector * 10
	return {
		ok = true,
		tipo = "action",
		texto = "Dash local executado.",
	}
end

function Modulo3Laboratorio:executarComando(entrada)
	local texto = tostring(entrada or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if texto == "" then
		return nil, "Digite um comando."
	end

	local partes = {}
	for parte in string.gmatch(texto, "%S+") do
		table.insert(partes, parte)
	end

	local comando = string.upper(partes[1])
	local argumento = texto:sub(#partes[1] + 2)

	if comando == "HELP" then
		return { ok = true, tipo = "help", texto = AJUDA }
	end

	if comando == "SCAN" then
		local contexto = self._controller:capturarContexto()
		return {
			ok = true,
			tipo = "contexto",
			texto = contexto.resumoFormatado,
		}
	end

	if comando == "CYCLE" then
		local ciclo = self._controller:executarCiclo()
		return {
			ok = true,
			tipo = "ciclo",
			texto = ciclo.resultado.summary,
		}
	end

	if comando == "SPEAK" then
		local fala, erro = self._controller:forcarFala(argumento ~= "" and argumento or "Produza uma fala breve e divertida.")
		if not fala then
			return nil, erro
		end

		return {
			ok = true,
			tipo = "fala",
			texto = fala.speech,
		}
	end

	if comando == "ACT" then
		local sucesso, erro = self._controller:executarAcaoAtual()
		if not sucesso then
			return nil, erro
		end

		return {
			ok = true,
			tipo = "action",
			texto = "Acao atual processada.",
		}
	end

	if comando == "AUTOSCAN" then
		local modo = string.upper(partes[2] or "")
		if modo == "ON" then
			self._controller:iniciarAutoScan(8)
			return { ok = true, tipo = "config", texto = "Auto scan ativado." }
		elseif modo == "OFF" then
			self._controller:pararAutoScan()
			return { ok = true, tipo = "config", texto = "Auto scan desativado." }
		end

		return nil, "Use AUTOSCAN ON ou AUTOSCAN OFF."
	end

	if comando == "THEME" then
		return self:aplicarTema(string.lower(partes[2] or ""))
	end

	if comando == "KEY" then
		local keyName = partes[2]
		if not keyName or not Enum.KeyCode[keyName] then
			return nil, "Tecla invalida."
		end

		local ok, erro = self._controller:definirTeclaToggle(Enum.KeyCode[keyName])
		if not ok then
			return nil, erro
		end

		return {
			ok = true,
			tipo = "config",
			texto = "Tecla alterada para " .. keyName,
		}
	end

	if comando == "MOOD" then
		return {
			ok = true,
			tipo = "mood",
			texto = FRASES_MOOD[math.random(1, #FRASES_MOOD)],
		}
	end

	if comando == "JUMP" then
		return self:_acaoPulo()
	end

	if comando == "SPIN" then
		return self:_acaoSpin()
	end

	if comando == "DASH" then
		return self:_acaoDash()
	end

	return nil, "Comando desconhecido. Use HELP."
end

return Modulo3Laboratorio
