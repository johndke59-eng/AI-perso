local GroqConfig = {
	-- Copie este arquivo para `GroqConfig.luau` e preencha os campos.
	apiKey = "SUA_GROQ_API_KEY_AQUI",
	baseUrl = "https://api.groq.com/openai/v1",
	model = "llama-3.3-70b-versatile",
	temperature = 0.7,
	maxTokens = 300,
	timeoutSeconds = 20,
	systemPrompt = table.concat({
		"Voce e o cerebro de um NPC em Roblox.",
		"Responda sempre em JSON valido.",
		"Considere o jogador local como a entidade central observada.",
		"Gere respostas uteis para navegacao, comportamento, fala e interpretacao de contexto.",
		"Evite floreios desnecessarios e prefira decisoes curtas, consistentes e acionaveis.",
	}, " "),
}

return GroqConfig
