BonChat = BonChat or {}

-- convars

BonChat.CVAR = {}

-- server cvars
BonChat.CVAR.MSG_MAX_LENGTH = "bonchat_msg_max_length"
BonChat.CVAR.MSG_MAX_ATTACHS = "bonchat_msg_max_attachments"
BonChat.CVAR.MSG_COOLDOWN = "bonchat_msg_cooldown"

-- client cvars
BonChat.CVAR.ENABLED = "bonchat_enable"
BonChat.CVAR.CHAT_TICK = "bonchat_chat_tick"
BonChat.CVAR.MAX_MSGS = "bonchat_max_messages"
BonChat.CVAR.AUTO_DISMISS = "bonchat_auto_dismiss"
BonChat.CVAR.LINK_MAX_LENGTH = "bonchat_link_max_length"
BonChat.CVAR.LOAD_ATTACHMENTS = "bonchat_load_attachments"
BonChat.CVAR.ATTACH_MAX_HEIGHT = "bonchat_attach_max_height"
BonChat.CVAR.SHOW_TONE_EMOJIS = "bonchat_show_tone_emojis"


CreateConVar(BonChat.CVAR.MSG_MAX_LENGTH, 1000, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set the character limit of messages", 256, 3000)
CreateConVar(BonChat.CVAR.MSG_MAX_ATTACHS, 5, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set the attachment limit of messages", 0, 15)
CreateConVar(BonChat.CVAR.MSG_COOLDOWN, 0.75, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set the message send cooldown in seconds", 0.1, 60)

CreateClientConVar(BonChat.CVAR.ENABLED, 1, true, nil, "Enable or disable BonChat")
CreateClientConVar(BonChat.CVAR.CHAT_TICK, 1, true, nil, "Play the chat \"tick\" sound when a player sends a message")
CreateClientConVar(BonChat.CVAR.MAX_MSGS, 1000, true, nil, "Set the max amount of messages that can be loaded in the chatbox", 100, 1000)
CreateClientConVar(BonChat.CVAR.AUTO_DISMISS, 1, true, nil, "Automatically dismiss messages upon closing the chatbox")
CreateClientConVar(BonChat.CVAR.LINK_MAX_LENGTH, 64, true, nil, "Set the character limit of links", 8, 256)
CreateClientConVar(BonChat.CVAR.LOAD_ATTACHMENTS, 1, true, nil, "Automatically load attachments")
CreateClientConVar(BonChat.CVAR.ATTACH_MAX_HEIGHT, 25, true, nil, "Set the max height for attachments", 1, 100)
CreateClientConVar(BonChat.CVAR.SHOW_TONE_EMOJIS, 0, true, nil, "Show results for skin tone emojis when searching in the catalog")

function BonChat.CVAR.GetMsgMaxLength()
  return GetConVar(BonChat.CVAR.MSG_MAX_LENGTH):GetInt()
end

function BonChat.CVAR.GetMsgMaxAttachs()
  return GetConVar(BonChat.CVAR.MSG_MAX_ATTACHS):GetInt()
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

function BonChat.CVAR.GetAutoDismiss()
  return GetConVar(BonChat.CVAR.AUTO_DISMISS):GetBool()
end

function BonChat.CVAR.GetLinkMaxLength()
  return GetConVar(BonChat.CVAR.LINK_MAX_LENGTH):GetInt()
end

function BonChat.CVAR.GetLoadAttachments()
  return GetConVar(BonChat.CVAR.LOAD_ATTACHMENTS):GetBool()
end

function BonChat.CVAR.GetAttachMaxHeight()
  return GetConVar(BonChat.CVAR.GET_ATTACH_MAX_HEIGHT):GetInt()
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