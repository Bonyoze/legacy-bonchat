AddCSLuaFile("bonchat/resources/chatbox.html.lua")
AddCSLuaFile("bonchat/resources/emojis.json.lua")

AddCSLuaFile("bonchat/vgui/frame.lua")
AddCSLuaFile("bonchat/vgui/chatbox.lua")
AddCSLuaFile("bonchat/vgui/settings.lua")

util.AddNetworkString("BonChat_say")

net.Receive("BonChat_say", function(len, ply)
  if ply.lastMsgTime and CurTime() - ply.lastMsgTime < BonChat.GetMsgCooldown() then return end

  local text = string.Left(net.ReadString(), BonChat.GetMsgMaxLen())
  local team = net.ReadBool()

  hook.Run("PlayerSay", ply, text, team)

  net.Start("BonChat_say")
    net.WriteEntity(ply)
    net.WriteString(text)
    net.WriteBool(team)
  net.Broadcast()

  ply.lastMsgTime = CurTime()
end)