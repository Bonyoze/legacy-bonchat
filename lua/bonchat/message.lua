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
objMessage.__tostring = function(self) return "BonChat Message" end

function objMessage.SetPlayer(self, ply)
  if ply ~= NULL and not ply:IsPlayer() then return end
  self.sender = ply
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

function objMessage.SetCentered(self)
  self:SetOptions("CENTER_CONTENT", "CENTER_ATTACH")
end

function objMessage.SetUnselectable(self)
  self:SetOptions("NO_SELECT_CONTENT", "NO_SELECT_ATTACH")
end

function objMessage.SetUntouchable(self)
  self:SetOptions("NO_TOUCH_CONTENT", "NO_TOUCH_ATTACH")
end

function objMessage.ShowTimestamp(self)
  self:SetOptions("SHOW_TIMESTAMP")
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

function objMessage.GetArgs(self)
  return self.args
end

function objMessage.GetOptions(self)
  return table.GetKeys(self.options)
end

function objMessage.GetPlayer(self)
  return self.sender
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
  self:AppendData(msgArgTypes.ENTITY, ent)
end

function objMessage.AppendType(self, any)
  if isstring(any) then
    self:AppendData(msgArgTypes.TEXT, any)
  elseif istable(any) then
    self:AppendData(msgArgTypes.COLOR, any)
  elseif isentity(any) then
    self:AppendData(msgArgTypes.ENTITY, any)
  else
    self:AppendData(msgArgTypes.TEXT, tostring(any))
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
  BonChat.frame:SendMessage(msg)
end