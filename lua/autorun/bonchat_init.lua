BonChat = BonChat or {}

-- convars

BonChat.CVAR = {}

-- server cvars
BonChat.CVAR.MSG_MAX_LEN = "bonchat_msg_max_len"
BonChat.CVAR.MSG_COOLDOWN = "bonchat_msg_cooldown"

-- client cvars
BonChat.CVAR.ENABLED = "bonchat_enable"
BonChat.CVAR.CHAT_TICK = "bonchat_chat_tick"
BonChat.CVAR.MAX_MSGS = "bonchat_max_msgs"
BonChat.CVAR.LINK_MAX_LEN = "bonchat_link_max_len"
BonChat.CVAR.SHOW_IMGS = "bonchat_show_images"
BonChat.CVAR.SHOW_TONE_EMOJIS = "bonchat_show_tone_emojis"


CreateConVar(BonChat.CVAR.MSG_MAX_LEN, 1000, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set the character limit of messages", 256, 3000)
CreateConVar(BonChat.CVAR.MSG_COOLDOWN, 0.75, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set the message send cooldown in seconds", 0.1, 60)

CreateClientConVar(BonChat.CVAR.ENABLED, 1, true, nil, "Enable or disable BonChat")
CreateClientConVar(BonChat.CVAR.CHAT_TICK, 1, true, nil, "Play the chat \"tick\" sound when a player sends a message")
CreateClientConVar(BonChat.CVAR.MAX_MSGS, 1000, true, nil, "Set the max amount of messages that can be loaded in the chatbox", 100, 1000)
CreateClientConVar(BonChat.CVAR.LINK_MAX_LEN, 25, true, nil, "Set the character limit of links", 8, 256)
CreateClientConVar(BonChat.CVAR.SHOW_IMGS, 1, true, nil, "Show image attachments")
CreateClientConVar(BonChat.CVAR.SHOW_TONE_EMOJIS, 0, true, nil, "Show results for skin tone emojis when searching in the catalog")

function BonChat.CVAR.GetMsgMaxLen()
  return GetConVar(BonChat.CVAR.MSG_MAX_LEN):GetInt()
end

function BonChat.CVAR.GetMsgCooldown()
  return GetConVar(BonChat.CVAR.MSG_COOLDOWN):GetFloat()
end

function BonChat.CVAR.GetEnabled()
  return GetConVar(BonChat.CVAR.ENABLED):GetBool()
end

function BonChat.CVAR.GetChatTick()
  return GetConVar(BonChat.CVAR.CHAT_TICK):GetBool()
end

function BonChat.CVAR.GetMaxMsgs()
  return GetConVar(BonChat.CVAR.MAX_MSGS):GetInt()
end

function BonChat.CVAR.GetLinkMaxLen()
  return GetConVar(BonChat.CVAR.LINK_MAX_LEN):GetInt()
end

function BonChat.CVAR.GetShowImages()
  return GetConVar(BonChat.CVAR.SHOW_IMGS):GetBool()
end

function BonChat.CVAR.GetShowToneEmojis()
  return GetConVar(BonChat.CVAR.SHOW_TONE_EMOJIS):GetBool()
end

function BonChat.AddConvarCallback(name, callback)
  cvars.AddChangeCallback(name, callback, "bonchat")
end

function BonChat.RemoveConvarCallback(name)
  cvars.RemoveChangeCallback(name, "bonchat")
end

local plyMeta = FindMetaTable("Player")

BonChat.oldPlyIsTyping = BonChat.oldPlyIsTyping or plyMeta.IsTyping
function plyMeta:IsTyping()
  return BonChat.oldPlyIsTyping(self) or self.bonchatIsTyping
end

if SERVER then
  include("bonchat/base_sv.lua")
  AddCSLuaFile("bonchat/base_cl.lua")
else
  include("bonchat/base_cl.lua")
end