-- send client-side scripts
AddCSLuaFile("bonchat/message.lua")
AddCSLuaFile("bonchat/custom_chat.lua")

AddCSLuaFile("bonchat/resources/chatbox.html.lua")
AddCSLuaFile("bonchat/resources/emojis.html.lua")
AddCSLuaFile("bonchat/resources/browser_image.html.lua")
AddCSLuaFile("bonchat/resources/emoji_data.json.lua")

AddCSLuaFile("bonchat/vgui/dhtml.lua")
AddCSLuaFile("bonchat/vgui/chatbox.lua")
AddCSLuaFile("bonchat/vgui/emojis.lua")
AddCSLuaFile("bonchat/vgui/browser.lua")
AddCSLuaFile("bonchat/vgui/settings.lua")
AddCSLuaFile("bonchat/vgui/frame.lua")

util.AddNetworkString("bonchat_say")
util.AddNetworkString("bonchat_istyping")

net.Receive("bonchat_say", function(_, ply)
  if ply.bonchatLastMsgTime and CurTime() - ply.bonchatLastMsgTime < BonChat.CVAR.GetMsgCooldown() then return end

  local len = net.ReadUInt(12)
  local data = net.ReadData(len)
  local text = string.Left(util.Decompress(data), BonChat.CVAR.GetMsgMaxLen())
  local teamChat = net.ReadBool()

  text = hook.Run("PlayerSay", ply, text, teamChat)

  if #text == 0 then return end

  net.Start("bonchat_say")
    net.WriteEntity(ply)
    net.WriteUInt(len, 12)
    net.WriteData(data)
    net.WriteBool(teamChat)
    net.WriteBool(not ply:Alive())
  if IsValid(ply) and teamChat then
    net.Send(team.GetPlayers(ply:Team()))
  else
    net.Broadcast()
  end
  ply.bonchatLastMsgTime = CurTime()
end)

net.Receive("bonchat_istyping", function(_, ply)
  local typing = net.ReadBool()
  ply.bonchatIsTyping = typing

  net.Start("bonchat_istyping")
    net.WriteEntity(ply)
    net.WriteBool(typing)
  net.SendOmit(ply)
end)

-- custom game messages for BonChat
include("bonchat/custom_chat.lua")