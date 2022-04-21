-- send client-side scripts
AddCSLuaFile("bonchat/message.lua")
AddCSLuaFile("bonchat/custom_chat.lua")
AddCSLuaFile("bonchat/resources/chatbox.html.lua")
AddCSLuaFile("bonchat/resources/emojis.json.lua")
AddCSLuaFile("bonchat/vgui/frame.lua")
AddCSLuaFile("bonchat/vgui/settings.lua")
AddCSLuaFile("bonchat/vgui/chatbox.lua")
AddCSLuaFile("bonchat/vgui/browser.lua")

util.AddNetworkString("BonChat_Say")
util.AddNetworkString("BonChat_PlayerConnect")
util.AddNetworkString("BonChat_PlayerJoin")
util.AddNetworkString("BonChat_PlayerLeave")

net.Receive("BonChat_Say", function(len, ply)
  -- check message send cooldown
  if ply.lastMsgTime and CurTime() - ply.lastMsgTime < BonChat.GetMsgCooldown() then return end

  local text = string.Left(net.ReadString(), BonChat.GetMsgMaxLen())
  local isTeam = net.ReadBool()

  text = hook.Run("PlayerSay", ply, text, isTeam)

  if text ~= "" then
    net.Start("BonChat_Say")
      net.WriteEntity(ply)
      net.WriteString(text)
      net.WriteBool(isTeam)
    if IsValid(ply) and isTeam then
      net.Send(team.GetPlayers(ply:Team()))
    else
      net.Broadcast()
    end
    ply.lastMsgTime = CurTime()
  end
end)

gameevent.Listen("player_connect")
hook.Add("player_connect", "BonChat_PlayerConnect", function(data)
  net.Start("BonChat_PlayerConnect")
    net.WriteString(data.name)
  net.Broadcast()
end)

hook.Add("PlayerInitialSpawn", "BonChat_PlayerJoin", function(ply)
  -- wait so the player team is set
  timer.Simple(0, function()
    local clr = team.GetColor(ply:Team())
    net.Start("BonChat_PlayerJoin")
      -- is a bot
      net.WriteBool(ply:IsBot())
      -- name
      net.WriteString(ply:Nick())
      -- name color
      net.WriteUInt(clr.r, 8)
      net.WriteUInt(clr.g, 8)
      net.WriteUInt(clr.b, 8)
      -- steam id
      net.WriteString(ply:SteamID())
    net.Broadcast()
  end)
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "BonChat_PlayerLeave", function(data)
  local ply = Player(data.userid)
  local clr = team.GetColor(ply:Team())
  net.Start("BonChat_PlayerLeave")
    -- is a bot
    net.WriteBool(ply:IsBot())
    -- name
    net.WriteString(ply:Nick())
    -- name color
    net.WriteUInt(clr.r, 8)
    net.WriteUInt(clr.g, 8)
    net.WriteUInt(clr.b, 8)
    -- steam id
    net.WriteString(ply:SteamID())
    -- disconnect reason
    net.WriteString(data.reason)
  net.Broadcast()
end)