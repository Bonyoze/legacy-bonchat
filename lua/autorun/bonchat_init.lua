BonChat = BonChat or {}

-- convars

BonChat.CVAR = {}

-- server cvars
BonChat.CVAR.MSG_MAX_LEN = "bonchat_msg_max_len"
BonChat.CVAR.MSG_COOLDOWN = "bonchat_msg_cooldown"

-- client cvars
BonChat.CVAR.ENABLED = "bonchat_enable"
BonChat.CVAR.CHAT_TICK = "bonchat_chat_tick"
BonChat.CVAR.MAX_MSGS = "bonchat_max_messages"
BonChat.CVAR.LINK_LEN = "bonchat_link_length"
BonChat.CVAR.SHOW_IMGS = "bonchat_show_images"
BonChat.CVAR.SHOW_TONE_EMOJIS = "bonchat_show_tone_emojis"


CreateConVar(BonChat.CVAR.MSG_MAX_LEN, 1000, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set the character limit of messages", 256, 3000)
CreateConVar(BonChat.CVAR.MSG_COOLDOWN, 0.5, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set the message send cooldown in seconds", 0, 60)

CreateClientConVar(BonChat.CVAR.ENABLED, 1, true, nil, "Enable or disable BonChat")
CreateClientConVar(BonChat.CVAR.CHAT_TICK, 1, true, nil, "Play the chat \"tick\" sound when a player sends a message")
CreateClientConVar(BonChat.CVAR.MAX_MSGS, 2000, true, nil, "Set the max amount of messages that can be visible in the chatbox", 100, 2000)
CreateClientConVar(BonChat.CVAR.LINK_LEN, 25, true, nil, "Set the character limit of links", 8, 256)
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

function BonChat.CVAR.GetLinkLength()
  return GetConVar(BonChat.CVAR.LINK_LEN):GetInt()
end

function BonChat.CVAR.GetShowImages()
  return GetConVar(BonChat.CVAR.SHOW_IMGS):GetBool()
end

function BonChat.CVAR.GetShowToneEmojis()
  return GetConVar(BonChat.CVAR.SHOW_TONE_EMOJIS):GetBool()
end

cvars.AddChangeCallback(BonChat.CVAR.ENABLED, function(_, _, new)
  local num = tonumber(new)
  if not num then return RunConsoleCommand(BonChat.CVAR.ENABLED, 1) end

  local enabled = num ~= 0
  if BonChat.enabled == enabled then return end
  
  if enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end

  BonChat.enabled = enabled
end)

BonChat.enabled = BonChat.CVAR.GetEnabled()

function BonChat.UpdateChatboxConVar(name, val)
  if not IsValid(BonChat.frame) or not IsValid(BonChat.frame.chatbox) then return end
  BonChat.frame.chatbox:UpdateConVar(name, val)
end

function BonChat.UpdateAllChatboxConVars()
  BonChat.UpdateChatboxConVar(BonChat.CVAR.MSG_MAX_LEN, GetConVar(BonChat.CVAR.MSG_MAX_LEN):GetInt())
  BonChat.UpdateChatboxConVar(BonChat.CVAR.MAX_MSGS, GetConVar(BonChat.CVAR.MAX_MSGS):GetInt())
  BonChat.UpdateChatboxConVar(BonChat.CVAR.LINK_LEN, GetConVar(BonChat.CVAR.LINK_LEN):GetInt())
  BonChat.UpdateChatboxConVar(BonChat.CVAR.SHOW_IMGS, GetConVar(BonChat.CVAR.SHOW_IMGS):GetInt())
end

-- updating convars needed by the chatbox
cvars.AddChangeCallback(BonChat.CVAR.MSG_MAX_LEN, function(name, _, val) BonChat.UpdateChatboxConVar(name, val) end)
cvars.AddChangeCallback(BonChat.CVAR.MAX_MSGS, function(name, _, val) BonChat.UpdateChatboxConVar(name, val) end)
cvars.AddChangeCallback(BonChat.CVAR.LINK_LEN, function(name, _, val) BonChat.UpdateChatboxConVar(name, val) end)
cvars.AddChangeCallback(BonChat.CVAR.SHOW_IMGS, function(name, _, val) BonChat.UpdateChatboxConVar(name, val) end)

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