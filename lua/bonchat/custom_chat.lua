-- this script customizes current game messages (connecting, joining, leaving, name change, cvar change, player chat)

local color_connecting = Color(150, 255, 150)

-- player connecting messages

net.Receive("BonChat_PlayerConnect", function()
  local name = net.ReadString()

  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendColor(color_connecting)
  msg:AppendMarkdown(":icon:status_away: **" .. name .. " is connecting to the server...**")
  BonChat.SendMessage(msg)

  -- keep functionality in the old chatbox
  BonChat.SendOldChatMessage(color_connecting, name .. " is connecting to the server...")
end)

-- player join messages
net.Receive("BonChat_PlayerJoin", function()
  local isBot = net.ReadBool()
  local name = net.ReadString()
  local color = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
  local steamID = net.ReadString()

  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendMarkdown(":icon:status_online: ")
  msg:AppendPlayer(name, color, not isBot and steamID)
  msg:AppendColor(color_white)
  msg:AppendText(" has joined the server")
  BonChat.SendMessage(msg)

  -- keep functionality in the old chatbox
  BonChat.SendOldChatMessage(
    color,
    name,
    color_white,
    " has joined the server"
  )
end)

-- player leave messages
net.Receive("BonChat_PlayerLeave", function()
  local isBot = net.ReadBool()
  local name = net.ReadString()
  local color = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
  local steamID = net.ReadString()
  local reason = net.ReadString()

  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendMarkdown(":icon:status_offline: ")
  msg:AppendPlayer(name, color, not isBot and steamID)
  msg:AppendColor(color_white)
  msg:AppendText(" has left the server ")
  msg:AppendMarkdown("**(" .. reason .. ")**")
  BonChat.SendMessage(msg)

  -- keep functionality in the old chatbox
  BonChat.SendOldChatMessage(
    color,
    name,
    color_white,
    " has left the server (" .. reason .. ")"
  )
end)

-- player changed name messages
gameevent.Listen("player_changename")
hook.Add("player_changename", "BonChat_PlayerNameChange", function(data)
  local ply = Player(data.userid)
  if not ply:IsValid() then return end

  local clr = hook.Run("GetTeamColor", ply)

  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendMarkdown(":icon:pencil: ")
  msg:AppendPlayer(data.oldname, clr, ply:SteamID())
  msg:AppendColor(color_white)
  msg:AppendText(" changed their name to ")
  msg:AppendPlayer(data.newname, clr, ply:SteamID())
  BonChat.SendMessage(msg)

  -- keep functionality in the old chatbox
  BonChat.SendOldChatMessage(clr, data.oldname, color_white, " changed their name to ", clr, data.newname)
end)

-- add server and misc messages to the chatbox
hook.Add("ChatText", "BonChat_ServerMiscMessages", function(_, _, text, type)
  if type == "servermsg" then
    local msg = BonChat.Message()
    msg:ShowTimestamp()
    msg:AppendMarkdown(":icon:server: **" .. text .. "**")
    BonChat.SendMessage(msg)
  elseif type == "none" then -- just send this as a normal message
    local msg = BonChat.Message()
    msg:AppendText(text)
    BonChat.SendMessage(msg)
  else
    return true -- prevent the other default messages since we customized those
  end
end)

local color_dead = Color(255, 0, 0) -- *DEAD*
local color_team = Color(24, 162, 35) -- (TEAM)

-- player chat messages
hook.Add("OnPlayerChat", "BonChat_PlayerMessages", function(ply, text, teamChat, isDead)
  do
    local msg = BonChat.Message()
    msg:ShowTimestamp()
    if isDead then
      msg:AppendColor(color_dead)
      msg:AppendText("*DEAD* ")
    end
    if teamChat then
      msg:AppendColor(color_team)
      msg:AppendText("(TEAM) ")
    end
    if IsValid(ply) then
      msg:AppendEntity(ply)
    else
      -- send 'Console' as if it were a player
      msg:AppendPlayer("Console")
    end
    msg:AppendColor(color_white)
    msg:AppendText(": ")
    msg:AppendMarkdown(text)
    BonChat.SendMessage(msg)
  end

  -- keep functionality in the old chatbox
  do
    local msg = {}
    if isDead then
      table.Add(msg, { color_dead, "*DEAD* " })
    end
    if teamChat then
      table.Add(msg, { color_team, "(TEAM) " })
    end
    if IsValid(ply) then
      table.insert(msg, ply)
    else
      table.insert(msg, "Console")
    end
    table.Add(msg, { color_white, ": " .. text })
    
    BonChat.SendOldChatMessage(unpack(msg))
  end
  
  return true
end)