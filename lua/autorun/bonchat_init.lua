BonChat = BonChat or {}

BonChat.CVAR_MSG_MAX_LEN = "bonchat_msg_max_len"
BonChat.CVAR_MSG_COOLDOWN = "bonchat_msg_cooldown"

CreateConVar(BonChat.CVAR_MSG_MAX_LEN, 300, { FCVAR_NOTIFY, FCVAR_REPLICATED }, "Message character limit when sent from the chatbox", 126, 2048)
CreateConVar(BonChat.CVAR_MSG_COOLDOWN, 1, { FCVAR_NOTIFY, FCVAR_REPLICATED }, "Message send cooldown in seconds", 0, 60)

function BonChat.GetMsgMaxLen()
  return GetConVar(BonChat.CVAR_MSG_MAX_LEN):GetInt()
end

function BonChat.GetMsgCooldown()
  return GetConVar(BonChat.CVAR_MSG_COOLDOWN):GetInt()
end

if SERVER then
  include("bonchat/base_sv.lua")
  AddCSLuaFile("bonchat/base_cl.lua")
else
  include("bonchat/base_cl.lua")
end