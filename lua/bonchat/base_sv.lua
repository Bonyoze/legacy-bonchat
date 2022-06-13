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

util.AddNetworkString("bonchat_istyping")

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