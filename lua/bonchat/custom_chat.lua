-- this script adds custom game messages to BonChat
-- (connecting, joining, leaving, name change, cvar change, achievement get, player chat)

if SERVER then
  util.AddNetworkString("BonChat_ConnectDisconnect")
  util.AddNetworkString("BonChat_JoinLeave")

  gameevent.Listen("player_connect")
  hook.Add("player_connect", "BonChat_PlayerConnect", function(data)
    net.Start("BonChat_ConnectDisconnect")
      net.WriteBool(true)
      net.WriteString(data.name)
    net.Broadcast()
  end)

  hook.Add("PlayerInitialSpawn", "BonChat_PlayerJoin", function(ply)
    -- wait so the player team is set
    timer.Simple(0, function()
      if not IsValid(ply) then return end
      local clr = team.GetColor(ply:Team())
      net.Start("BonChat_JoinLeave")
        net.WriteBool(true)
        net.WriteBool(ply:IsBot())
        net.WriteString(ply:Nick())
        net.WriteUInt(clr.r, 8)
        net.WriteUInt(clr.g, 8)
        net.WriteUInt(clr.b, 8)
        net.WriteString(ply:SteamID())
      net.Broadcast()
    end)
  end)
  
  gameevent.Listen("player_disconnect")
  hook.Add("player_disconnect", "BonChat_PlayerLeaveDisconnect", function(data)
    local ply = Player(data.userid)
    if IsValid(ply) then
      local clr = team.GetColor(ply:Team())
      net.Start("BonChat_JoinLeave")
        net.WriteBool(false)
        net.WriteBool(ply:IsBot())
        net.WriteString(ply:Nick())
        net.WriteUInt(clr.r, 8)
        net.WriteUInt(clr.g, 8)
        net.WriteUInt(clr.b, 8)
        net.WriteString(ply:SteamID())
        net.WriteString(data.reason)
      net.Broadcast()
    else
      net.Start("BonChat_ConnectDisconnect")
        net.WriteBool(false)
        net.WriteString(data.name)
      net.Broadcast()
    end
  end)

  return
end

local color_connecting = Color(162, 255, 162)

-- player connecting/disconnecting messages
net.Receive("BonChat_ConnectDisconnect", function()
  local connecting = net.ReadBool()
  local name = net.ReadString()

  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendColor(color_connecting)
  msg:AppendMarkdown(
    ":icon:status_"
    .. (connecting and "online" or "offline")
    .. ": **Player "
    .. name
    .. " "
    .. (connecting and "is" or "stopped")
    .. " connecting**"
  )
  BonChat.SendMessage(msg)
end)

-- player join/leave messages
net.Receive("BonChat_JoinLeave", function()
  local joined = net.ReadBool()
  local isBot = net.ReadBool()
  local name = net.ReadString()
  local color = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
  local steamID = net.ReadString()
  local reason = net.ReadString()

  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendMarkdown(
    ":icon:status_"
    .. (joined and "online" or "offline")
    .. ": "
  )
  msg:AppendPlayer(name, color, not isBot and steamID)
  msg:AppendColor(color_white)
  msg:AppendText(" has " .. (joined and "joined" or "left") .. " the server")
  if not joined then
    msg:AppendMarkdown(" **(" .. reason .. ")**")
  end
  BonChat.SendMessage(msg)
end)

-- player name change messages
gameevent.Listen("player_changename")
hook.Add("player_changename", "BonChat_PlayerNameChange", function(data)
  local ply = Player(data.userid)
  if not ply:IsValid() then return end

  local clr = hook.Run("GetTeamColor", ply)
  local steamID = ply:SteamID()

  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendMarkdown(":icon:user_edit: ")
  msg:AppendPlayer(data.oldname, clr, steamID)
  msg:AppendColor(color_white)
  msg:AppendText(" changed their name to ")
  msg:AppendPlayer(data.newname, clr, steamID)
  BonChat.SendMessage(msg)
end)

-- server and misc messages
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
    -- prevent the other default messages
    BonChat.SuppressDefaultMsg()
  end
end)

local color_achieve = Color(255, 200, 0)

-- achievement messages
hook.Add("OnAchievementAchieved", "BonChat_AchieveMessages", function(ply, achid)
  local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendMarkdown(":icon:award_star_gold_3: ")
  msg:AppendEntity(ply)
  msg:AppendColor(color_white)
  msg:AppendText(" earned the achievement ")
  msg:AppendColor(color_achieve)
  msg:AppendMarkdown("**" .. achievements.GetName(achid) .. "**")
  BonChat.SendMessage(msg)

  BonChat.SuppressDefaultMsg()
end)

local color_dead = Color(255, 0, 0) -- *DEAD*
local color_team = Color(24, 162, 35) -- (TEAM)

-- player chat messages
hook.Add("OnPlayerChat", "BonChat_PlayerMessages", function(ply, text, teamChat, isDead)
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
  
  -- prevent default so we don't get duplicates
  BonChat.SuppressDefaultMsg()
end)