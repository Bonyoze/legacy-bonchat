-- send client-side scripts
AddCSLuaFile("bonchat/message.lua")
AddCSLuaFile("bonchat/custom_chat.lua")

AddCSLuaFile("bonchat/resources/browser_image.html.lua")
AddCSLuaFile("bonchat/resources/chatbox.html.lua")
AddCSLuaFile("bonchat/resources/emojis.html.lua")
AddCSLuaFile("bonchat/resources/attachments.html.lua")
AddCSLuaFile("bonchat/resources/emoji_data.json.lua")

AddCSLuaFile("bonchat/vgui/dhtml.lua")
AddCSLuaFile("bonchat/vgui/browser.lua")
AddCSLuaFile("bonchat/vgui/chatbox.lua")
AddCSLuaFile("bonchat/vgui/settings.lua")
AddCSLuaFile("bonchat/vgui/emojis.lua")
AddCSLuaFile("bonchat/vgui/attachments.lua")
AddCSLuaFile("bonchat/vgui/frame.lua")

util.AddNetworkString("bonchat_say")
util.AddNetworkString("bonchat_istyping")

net.Receive("bonchat_say", function(_, ply)
  if ply.bonchatLastMsgTime and CurTime() - ply.bonchatLastMsgTime < BonChat.CVAR.GetMsgCooldown() then return end

  local text = string.Left(net.ReadString(), BonChat.CVAR.GetMsgMaxLength())
  local teamChat = net.ReadBool()

  if not IsValid(ply) and teamChat then return end
  
  text = hook.Run("PlayerSay", ply, text, teamChat)
  if #text == 0 then return end

  local totalAttachs = net.ReadUInt(4)
  local attachments = {}
  for i = 1, totalAttachs do
    local type, value = net.ReadUInt(4), net.ReadString()
    table.insert(attachments, { type = type, value = value })
  end

  MsgN(ply:Nick() .. ": " .. text)

  local newData = util.Compress(text)

  net.Start("bonchat_say")
    net.WriteEntity(ply)
    net.WriteString(text)
    net.WriteBool(teamChat)
    net.WriteBool(not ply:Alive())

    net.WriteUInt(totalAttachs, 4)
    for i = 1, totalAttachs do
      local attachment = attachments[i]
      net.WriteUInt(attachment.type, 4)
      net.WriteString(attachment.value)
    end
    --[[net.WriteUInt(15, 4)
    net.WriteUInt(1, 4)
    net.WriteString("https://trello.com/1/cards/61a3f318fd73b114ecc12ad4/attachments/61a3f7e943eccc53a5e60fbc/previews/61a3f7eb43eccc53a5e60fc7/download/CharBanner-Update.png")
    for i = 1, 14 do
      net.WriteUInt(1, 4)
      net.WriteString("https://media.discordapp.net/attachments/292328649711943680/883812645105446922/25.gif")
    end]]
  if teamChat then
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