local Players = game:GetService("Players")

local player = Players.LocalPlayer

local pastaProjeto = script.Parent
local guiScript = pastaProjeto:FindFirstChild("NPCDebugGui.client")

if not guiScript then
	guiScript = pastaProjeto:FindFirstChild("NPCDebugGui.client.luau")
end

if guiScript and guiScript:IsA("LocalScript") then
	guiScript.Enabled = true
	return
end

warn("Bootstrap client nao encontrou um LocalScript da interface para iniciar.")
