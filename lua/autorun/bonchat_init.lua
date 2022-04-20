BonChat = BonChat or {}

BonChat.CVAR_ENABLED = "bonchat_enable"
BonChat.CVAR_MSG_MAX_LEN = "bonchat_msg_max_len"
BonChat.CVAR_MSG_COOLDOWN = "bonchat_msg_cooldown"

CreateClientConVar(BonChat.CVAR_ENABLED, 1, true, false, "Enable or disable BonChat", 0, 1)
CreateConVar(BonChat.CVAR_MSG_MAX_LEN, 300, { FCVAR_NOTIFY, FCVAR_REPLICATED }, "Message character limit when sent from the chatbox", 126, 2048)
CreateConVar(BonChat.CVAR_MSG_COOLDOWN, 1, { FCVAR_NOTIFY, FCVAR_REPLICATED }, "Message send cooldown in seconds", 0, 60)

function BonChat.GetEnabled()
  return GetConVar(BonChat.CVAR_ENABLED):GetBool()
end

function BonChat.GetMsgMaxLen()
  return GetConVar(BonChat.CVAR_MSG_MAX_LEN):GetInt()
end

function BonChat.GetMsgCooldown()
  return GetConVar(BonChat.CVAR_MSG_COOLDOWN):GetInt()
end

cvars.AddChangeCallback(BonChat.CVAR_ENABLED, function(_, _, new)
  local num = tonumber(new)
  if not num then return RunConsoleCommand(BonChat.CVAR_ENABLED, 1) end

  local enabled = num ~= 0
  if BonChat.enabled == enabled then return end
  
  if enabled then
    BonChat.EnableChatbox()
  else
    BonChat.DisableChatbox()
  end

  BonChat.enabled = enabled
end)

BonChat.enabled = BonChat.GetEnabled()

concommand.Add("bonchat_reload", function()
  BonChat.ReloadChat()
  if BonChat.enabled then
    BonChat.EnableChatbox()
  else
    BonChat.DisableChatbox()
  end
  BonChat.AppendMessage(
    {
      contentCentered = true,
      contentUnselectable = true
    },
    color_white,
    ":icon:cog: **Chatbox was reloaded**"
  )
end)

concommand.Add("bonchat_clear", function()
  BonChat.ClearChat()
  BonChat.AppendMessage(
    {
      contentCentered = true,
      contentUnselectable = true
    },
    color_white,
    ":icon:bin: **Chatbox was cleared**"
  )
end)

if SERVER then
  include("bonchat/base_sv.lua")
  AddCSLuaFile("bonchat/base_cl.lua")
else
  include("bonchat/base_cl.lua")
end