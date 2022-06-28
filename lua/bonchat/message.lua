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

local msgOptions = enum {
  "CENTER_CONTENT", "CENTER_ATTACH",
  "NO_SELECT_CONTENT", "NO_SELECT_ATTACH",
  "NO_TOUCH_CONTENT", "NO_TOUCH_ATTACH",
  "SHOW_TIMESTAMP"
}

local objMessage = {}
objMessage.__index = objMessage
objMessage.__tostring = function() return "BonChat Message" end

function objMessage.SetSender(self, ply)
  self.sender = ply
  self.senderName = ply:IsPlayer() and ply:Nick() or "Console"
  self.senderID = ply:IsPlayer() and ply:SteamID() or "N/A"
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

function objMessage.SetCentered(self, set)
  self:UpdateOptions(set, "CENTER_CONTENT", "CENTER_ATTACH")
end

function objMessage.SetUnselectable(self)
  self:UpdateOptions(set, "NO_SELECT_CONTENT", "NO_SELECT_ATTACH")
end

function objMessage.SetUntouchable(self)
  self:UpdateOptions(set, "NO_TOUCH_CONTENT", "NO_TOUCH_ATTACH")
end

function objMessage.ShowTimestamp(self)
  self:UpdateOptions(set, "SHOW_TIMESTAMP")
end

function objMessage.GetArgs(self)
  return table.Copy(self.args)
end

function objMessage.GetOptions(self)
  return table.GetKeys(self.options)
end

function objMessage.GetSender(self)
  return self.sender, self.senderName, self.senderID
end

function objMessage.AppendData(self, type, value)
  if istable(value) then
    value.type = type
    table.insert(self.args, value)
  else
    table.insert(self.args, { type = type, value = value })
  end
end

function objMessage.AppendText(self, str)
  if not isstring(str) then return end
  self:AppendData(msgArgTypes.TEXT, str)
end

function objMessage.AppendColor(self, clr)
  if not istable(clr) then return end
  self:AppendData(msgArgTypes.COLOR, clr)
end

function objMessage.AppendEntity(self, ent)
  if not isentity(ent) then return end

  if ent == NULL then
    self:AppendData(msgArgTypes.TEXT, "NULL")
  elseif ent:IsPlayer() then
    self:AppendData(msgArgTypes.PLAYER, { name = ent:Nick(), color = hook.Run("GetTeamColor", ent), steamID = ent:SteamID() })
  else
    self:AppendData(msgArgTypes.TEXT, ent:GetClass())
  end
end

function objMessage.AppendType(self, any)
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
  self:AppendData(msgArgTypes.MARKDOWN, str)
end

function objMessage.AppendPlayer(self, name, color, steamID) -- color and steam id are optional
  if not isstring(name) or (color and not istable(color)) or (steamID and not isstring(steamID)) then return end
  self:AppendData(msgArgTypes.PLAYER, { name = name, color = color, steamID = steamID })
end

function objMessage.AppendArgs(self, ...)
  local tbl = {...}
  local len = #tbl
  for i = 1, len do
    self:AppendType(tbl[i])
  end
end

BonChat.msgArgTypes = msgArgTypes
BonChat.msgOptions = msgOptions

function BonChat.Message()
  return setmetatable({
    args = {},
    options = {}
  }, objMessage)
end

function BonChat.SendMessage(msg)
  if not IsValid(BonChat.frame) then return end
  BonChat.frame.chatbox:SendMessage(msg)
end