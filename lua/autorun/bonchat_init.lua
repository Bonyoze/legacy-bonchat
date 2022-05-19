BonChat = BonChat or {}

BonChat.CVAR_ENABLED = "bonchat_enable"

CreateClientConVar(BonChat.CVAR_ENABLED, 1, true, false, "Enable or disable BonChat", 0, 1)

function BonChat.GetEnabled()
  return GetConVar(BonChat.CVAR_ENABLED):GetBool()
end

cvars.AddChangeCallback(BonChat.CVAR_ENABLED, function(_, _, new)
  local num = tonumber(new)
  if not num then return RunConsoleCommand(BonChat.CVAR_ENABLED, 1) end

  local enabled = num ~= 0
  if BonChat.enabled == enabled then return end
  
  if enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end

  BonChat.enabled = enabled
end)

BonChat.enabled = BonChat.GetEnabled()

if SERVER then
  include("bonchat/base_sv.lua")
  AddCSLuaFile("bonchat/base_cl.lua")
else
  include("bonchat/base_cl.lua")
end