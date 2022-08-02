local function enum(tbl)
  local len = #tbl
  for i = 1, len do
    local v = tbl[i]
    tbl[v] = i
  end
  return tbl
end

local msgArgTypes = enum {
  -- default
  "TEXT",
  "COLOR",
  "ENTITY",
  -- custom
  "MARKDOWN", -- text but with markdown support
  "PLAYER" -- mimics the styling for a player, but the name, color, and steam id can be specified
}

local msgAttachTypes = enum {
  // media
  "IMAGE",
  "VIDEO",
  "AUDIO",
  // game stuff
  "MODEL",
  "TEXTURE",
  "SOUND",
  // other
  "CODE"
}

local msgOptions = enum {
  "DISMISSIBLE",
  "CENTER_CONTENT", "CENTER_ATTACH",
  "NO_SELECT_CONTENT", "NO_SELECT_ATTACH",
  "NO_TOUCH_CONTENT", "NO_TOUCH_ATTACH",
  "SHOW_TIMESTAMP"
}

local objMessage = {}
objMessage.__index = objMessage
objMessage.__tostring = function() return "BonChat Message" end

function objMessage.SetSender(self, ply)
  if not isentity(ply) then return end
  self.sender = ply
  self.senderName = ply:IsPlayer() and ply:Nick() or "Console"
  self.senderID = ply:IsPlayer() and ply:SteamID() or "N/A"
end

function objMessage.SetID(self, id)
  if not isnumber(id) then return end
  self.id = id
end

function objMessage.SetAttachments(self, attachments)
  if not istable(attachments) then return end
  self.attachments = attachments
end

function objMessage.AppendAttachment(self, type, value)
  table.insert(self.attachments, { type = type, value = value })
end

function objMessage.SetOptions(self, ...)
  local opts = {...}
  local len = #opts
  for i = 1, len do
    local opt = opts[i]
    if msgOptions[opt] then
      self.options[opt] = true
    end
  end
end

function objMessage.RemoveOptions(self, ...)
  local opts = {...}
  local len = #opts
  for i = 1, len do
    local opt = opts[i]
    if msgOptions[opt] then
      self.options[opt] = nil
    end
  end
end

function objMessage.UpdateOptions(self, method, ...)
  if method == nil then method = true end
  local func = method and self.SetOptions or self.RemoveOptions
  func(self, ...)
end

function objMessage.SetDismissible(self, set)
  self:UpdateOptions(set, "DISMISSIBLE")
end

function objMessage.SetCentered(self, set)
  self:UpdateOptions(set, "CENTER_CONTENT", "CENTER_ATTACH")
end

function objMessage.SetUnselectable(self, set)
  self:UpdateOptions(set, "NO_SELECT_CONTENT", "NO_SELECT_ATTACH")
end

function objMessage.SetUntouchable(self, set)
  self:UpdateOptions(set, "NO_TOUCH_CONTENT", "NO_TOUCH_ATTACH")
end

function objMessage.ShowTimestamp(self, set)
  self:UpdateOptions(set, "SHOW_TIMESTAMP")
end

function objMessage.GetSender(self)
  return self.sender, self.senderName, self.senderID
end

function objMessage.GetID(self)
  return self.id
end

function objMessage.GetArgs(self)
  return table.Copy(self.args)
end

function objMessage.GetAttachments(self)
  return table.Copy(self.attachments)
end

function objMessage.GetOptions(self)
  return table.GetKeys(self.options)
end

function objMessage.AppendArg(self, type, value)
  table.insert(self.args, { type = type, value = value })
end

function objMessage.AppendText(self, str)
  if not isstring(str) then return end
  self:AppendArg(msgArgTypes.TEXT, str)
end

function objMessage.AppendColor(self, clr)
  if not istable(clr) then return end
  self:AppendArg(msgArgTypes.COLOR, clr)
end

function objMessage.AppendEntity(self, ent)
  if not isentity(ent) then return end

  if ent == NULL then
    self:AppendArg(msgArgTypes.TEXT, "NULL")
  elseif ent:IsPlayer() then
    self:AppendArg(msgArgTypes.PLAYER, { name = ent:Nick(), color = hook.Run("GetTeamColor", ent), steamID = ent:SteamID() })
  else
    self:AppendArg(msgArgTypes.TEXT, ent:GetClass())
  end
end

function objMessage.AppendArgAny(self, any)
  if isstring(any) then
    self:AppendText(any)
  elseif istable(any) then
    self:AppendColor(any)
  elseif isentity(any) then
    self:AppendEntity(any)
  else
    self:AppendText(tostring(any))
  end
end

function objMessage.AppendMarkdown(self, str)
  if not isstring(str) then return end
  self:AppendArg(msgArgTypes.MARKDOWN, str)
end

function objMessage.AppendPlayer(self, name, color, steamID) -- color and steam id are optional
  if not isstring(name) or (color and not istable(color)) or (steamID and not isstring(steamID)) then return end
  self:AppendArg(msgArgTypes.PLAYER, { name = name, color = color, steamID = steamID })
end

function objMessage.AppendArgs(self, ...)
  local tbl = {...}
  local len = #tbl
  for i = 1, len do
    self:AppendArgAny(tbl[i])
  end
end

BonChat.msgArgTypes = msgArgTypes
BonChat.msgAttachTypes = msgAttachTypes
BonChat.msgOptions = msgOptions

function BonChat.Message()
  return setmetatable({
    args = {},
    attachments = {},
    options = {}
  }, objMessage)
end

function BonChat.SendMessage(msg)
  if not IsValid(BonChat.frame) then return end
  BonChat.frame.chatbox:SendMessage(msg)
end