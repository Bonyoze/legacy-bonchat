include("bonchat/vgui/frame.lua")

function BonChat.Log(...)
  MsgC(Color(255, 0, 105), "[BonChat] ", color_white, ...)
  MsgN()
end

function BonChat.OpenChat(mode)
  if not IsValid(BonChat.frame) then BonChat.ReloadChat() end
  BonChat.frame:OpenChat(mode);
end

function BonChat.CloseChat()
  if not IsValid(BonChat.frame) then BonChat.ReloadChat() end
  BonChat.frame:CloseChat()
end

function BonChat.ReloadChat()
  if BonChat.frame ~= nil and BonChat.frame:IsValid() then BonChat.frame:Remove() end
  BonChat.frame = vgui.Create("BonChat_Frame")
  chat.AddText(color_white, "BonChat has successfully loaded!")
end

function BonChat.ClearChat()
  BonChat.frame:CallJS("chatbox.html('')")
end

function BonChat.Say(text)
  if not text or #text == 0 then return end

  net.Start("BonChat_say")
    net.WriteString(string.Left(text, BonChat.GetMsgMaxLen()))
    net.WriteBool(false)
  net.SendToServer()
end

function BonChat.OpenURL(url)
  if not url or #url == 0 then return end
  if not (string.StartWith(url, "https://") or string.StartWith(url, "http://")) then
    return BonChat.Log("Cannot open a URL unless it's using the protocol 'https' or 'http'!")
  end
  if #url > 512 then
    return BonChat.Log("Cannot open a URL more than 512 characters long!", Color(180, 180, 180), " (https://github.com/Facepunch/garrysmod-issues/issues/4663)")
  end
  BonChat.CloseChat()
  gui.OpenURL(url)
end

function BonChat.GetResource(name)
  return include("bonchat/resources/" .. name .. ".lua")
end

-- override to redirect to new chatbox
BonChat.oldAddText = BonChat.oldAddText or chat.AddText
function chat.AddText(...)
  if BonChat.frame ~= nil and BonChat.frame:IsValid() then
    BonChat.frame:AppendMessage(nil, ...)
  end
  BonChat.oldAddText(...)
end

local panelMeta = FindMetaTable("Panel")
local blur = Material("pp/blurscreen")

-- custom panel function
panelMeta.DrawBlur = function(self, layers, density, alpha)
  surface.SetDrawColor(255, 255, 255, alpha)
  surface.SetMaterial(blur)

  for i = 1, 3 do
    blur:SetFloat("$blur", i / layers * density)
    blur:Recompute()
    render.UpdateScreenEffectTexture()
    surface.DrawTexturedRect(-self:GetX(), -self:GetY(), ScrW(), ScrH())
  end
end

hook.Add("HUDShouldDraw", "BonChat_HideDefaultChat", function(name)
  if name == "CHudChat" then
    return false
  end
end)

hook.Add("PlayerBindPress", "BonChat_OpenChat", function(_, bind, pressed)
  if not pressed then return end
  
  if bind == "messagemode" then
    BonChat.OpenChat(1)
  elseif bind == "messagemode2" then
    BonChat.OpenChat(2)
  end
end)

-- receive player messages sent using the chatbox
net.Receive("BonChat_say", function()
  local ply = net.ReadEntity()
  local text = net.ReadString()
  local team = net.ReadBool()
  hook.Run("OnPlayerChat",
    ply,
    text,
    team,
    IsValid(ply) and not ply:Alive() or false
  )
end)

-- initializing

hook.Add("Initialize", "BonChat_Initialize", function()
  BonChat.ReloadChat()
end)

if GAMEMODE then
  BonChat.ReloadChat()
end