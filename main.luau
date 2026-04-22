-- Configuração do Repositório
local usuario = "johndke59-eng"
local repo    = "AI-perso"
local branch  = "main"

-- Ajustado: Agora as variáveis estão conectadas corretamente com ".."
local baseUrl = "https://raw.githubusercontent.com/" .. usuario .. "/" .. repo .. "/" .. branch .. "/"

local function carregar(arquivo)
    print("Baixando: " .. arquivo)
    
    local sucesso, conteudo = pcall(function()
        return game:HttpGet(baseUrl .. arquivo)
    end)
    
    if sucesso then
        -- Verifica se o GitHub não retornou um "404: Not Found" em vez do código
        if conteudo == "404: Not Found" then
            warn("Erro: Arquivo não encontrado no GitHub (" .. arquivo .. ")")
            return
        end

        local func, err = loadstring(conteudo)
        if func then
            return func()
        else
            warn("Erro de sintaxe em " .. arquivo .. ": " .. err)
        end
    else
        warn("Erro de conexão ao baixar " .. arquivo)
    end
end

-- ORDEM DE CARREGAMENTO
print("--- Iniciando Boot do Sistema ---")

-- 1. Configurações base
carregar("GroqConfig.luau")

-- 2. Módulos e Lógica
carregar("ClienteGroq.luau")
carregar("LeitorContextoAmbiental.luau")
carregar("CerebroNPC.luau")

-- 3. Controladores e Interface
carregar("NPCClientController.luau")
carregar("NPCDebugGui.client.luau")

-- 4. Inicialização Final
carregar("Bootstrap.client.luau")

print("--- Sistema carregado com sucesso! ---")
