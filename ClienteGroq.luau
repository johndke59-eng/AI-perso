local HttpService = game:GetService("HttpService")

local ClienteGroq = {}
ClienteGroq.__index = ClienteGroq

local function validarConfiguracao(config)
	assert(type(config) == "table", "Config da Groq deve ser uma tabela")
	assert(type(config.apiKey) == "string" and config.apiKey ~= "", "apiKey da Groq e obrigatoria")
	assert(type(config.baseUrl) == "string" and config.baseUrl ~= "", "baseUrl da Groq e obrigatoria")
	assert(type(config.model) == "string" and config.model ~= "", "model da Groq e obrigatorio")
end

local function montarUrl(baseUrl, path)
	if string.sub(baseUrl, -1) == "/" then
		return baseUrl .. path
	end

	return baseUrl .. "/" .. path
end

function ClienteGroq.new(config)
	validarConfiguracao(config)

	local self = setmetatable({}, ClienteGroq)
	self._config = config
	self._endpoint = montarUrl(config.baseUrl, "chat/completions")

	return self
end

function ClienteGroq:estaConfigurado()
	local apiKey = self._config.apiKey
	return type(apiKey) == "string"
		and apiKey ~= ""
		and apiKey ~= "SUA_GROQ_API_KEY_AQUI"
end

function ClienteGroq:_criarPayload(messages, overrides)
	overrides = overrides or {}

	return {
		model = overrides.model or self._config.model,
		messages = messages,
		temperature = overrides.temperature or self._config.temperature or 0.7,
		max_tokens = overrides.maxTokens or self._config.maxTokens or 300,
		response_format = overrides.responseFormat,
	}
end

function ClienteGroq:_enviarRequest(payload)
	local body = HttpService:JSONEncode(payload)

	local response = HttpService:RequestAsync({
		Url = self._endpoint,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. self._config.apiKey,
		},
		Body = body,
	})

	if not response.Success then
		return nil, string.format("Falha HTTP %s: %s", tostring(response.StatusCode), tostring(response.StatusMessage))
	end

	local sucessoDecode, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)

	if not sucessoDecode then
		return nil, "Nao foi possivel decodificar a resposta da Groq"
	end

	return data
end

function ClienteGroq:criarChatCompletion(messages, overrides)
	assert(type(messages) == "table" and #messages > 0, "messages deve conter ao menos uma mensagem")

	if not self:estaConfigurado() then
		return nil, "Groq API key ainda nao foi configurada"
	end

	local payload = self:_criarPayload(messages, overrides)
	local data, erro = self:_enviarRequest(payload)
	if not data then
		return nil, erro
	end

	local choices = data.choices
	if type(choices) ~= "table" or not choices[1] or not choices[1].message then
		return nil, "Resposta da Groq nao possui choices validas"
	end

	return {
		raw = data,
		content = choices[1].message.content,
		finishReason = choices[1].finish_reason,
		usage = data.usage,
	}
end

function ClienteGroq:criarJSON(messages, overrides)
	overrides = overrides or {}
	overrides.responseFormat = {
		type = "json_object",
	}

	local resultado, erro = self:criarChatCompletion(messages, overrides)
	if not resultado then
		return nil, erro
	end

	local sucessoDecode, json = pcall(function()
		return HttpService:JSONDecode(resultado.content)
	end)

	if not sucessoDecode then
		return nil, "A Groq respondeu, mas o conteudo nao era JSON valido"
	end

	resultado.json = json
	return resultado
end

return ClienteGroq
