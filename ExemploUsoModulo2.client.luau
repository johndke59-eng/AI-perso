local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeitorContextoAmbiental = require(script.Parent.LeitorContextoAmbiental)

local RemoteFunction = ReplicatedStorage:WaitForChild("SolicitarContextoNPC")

RemoteFunction.OnClientInvoke = function()
	local analise = LeitorContextoAmbiental.analisar()
	return analise
end
